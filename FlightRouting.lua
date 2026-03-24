local addonName, OUS = ...

-- Ensure our routing database exists before proceeding
if not OUS.TaxiNodes or not OUS.TaxiRoutes then return end

-- Initialize Session table if it doesn't exist yet (just to be safe)
OUS.Session = OUS.Session or {}

-- ==========================================
-- 1. THE ROUTING ENGINE (Dijkstra's Algorithm)
-- ==========================================
function OUS.FindShortestRoute(startNodeID, endNodeID)
    if OUS.LogDebug then
        OUS.LogDebug(string.format("[Routing] Starting path calculation: %s -> %s", OUS.TaxiNodes[startNodeID] or "Unknown", OUS.TaxiNodes[endNodeID] or "Unknown"))
    end
    
    local distances = {}
    local previous = {}
    local unvisited = {}
    local iterations = 0 -- For performance tracking

    for nodeID in pairs(OUS.TaxiNodes) do
        distances[nodeID] = math.huge
        unvisited[nodeID] = true
    end

    distances[startNodeID] = 0

    while next(unvisited) do
        iterations = iterations + 1
        
        local currentNode = nil
        local minDistance = math.huge
        for nodeID in pairs(unvisited) do
            if distances[nodeID] < minDistance then
                currentNode = nodeID
                minDistance = distances[nodeID]
            end
        end

        if not currentNode or currentNode == endNodeID then 
            if OUS.LogDebug then OUS.LogDebug("[Routing] Target reached or network exhausted after " .. iterations .. " iterations.") end
            break 
        end

        unvisited[currentNode] = nil

        if OUS.TaxiRoutes[currentNode] then
            for neighborID, edgeData in pairs(OUS.TaxiRoutes[currentNode]) do
                if unvisited[neighborID] then

                    -- THE FIX: Use Blizzard's copper cost as the physical distance metric!
                    -- If a dev node has a cost of 0, we artificially penalize it with 99999 
                    -- so the algorithm avoids it like the plague.
                    local hopWeight = 1 
                    
                    local newDistance = distances[currentNode] + hopWeight 
                    
                    if newDistance < distances[neighborID] then
                        distances[neighborID] = newDistance
                        previous[neighborID] = currentNode
                    end
                end
            end
        end
    end

    local path = {}
    local current = endNodeID
    if previous[current] or current == startNodeID then
        while current do
            table.insert(path, 1, current)
            current = previous[current]
        end
    end

    if OUS.LogDebug then 
        OUS.LogDebug("[Routing] Calculation complete. Path length: " .. (#path > 0 and (#path - 1) or "0") .. " hops.")
    end
    
    return path
end

-- ==========================================
-- 2. HELPER FUNCTION (Find ALL Matching IDs)
-- ==========================================
local function GetNodeIDsByName(searchName)
    searchName = string.lower(strtrim(searchName))
    local matches = {}
    
    -- Pass 1: Look for exact matches
    for id, name in pairs(OUS.TaxiNodes) do
        if string.lower(name) == searchName then
            table.insert(matches, id)
        end
    end
    
    if #matches > 0 then return matches end
    
    -- Pass 2: Look for fuzzy matches if no exact match found
    for id, name in pairs(OUS.TaxiNodes) do
        if string.find(string.lower(name), searchName, 1, true) then
            table.insert(matches, id)
        end
    end
    
    return matches
end

-- ==========================================
-- 3. THE CHAT COMMAND (Test the Engine!)
-- ==========================================
SLASH_ODYSSEUSROUTE1 = "/route"
SlashCmdList["ODYSSEUSROUTE"] = function(msg)
    local startName, endName = string.match(msg, "^([^,]+),%s*(.+)$")
    
    if not startName or not endName then
        print("|cFF00FFFF[Odysseus]|r Format: /route Start Node, End Node")
        return
    end

    local startIDs = GetNodeIDsByName(startName)
    local endIDs = GetNodeIDsByName(endName)

    if #startIDs == 0 then print("|cFFFF0000[Error]|r Could not find start: " .. startName) return end
    if #endIDs == 0 then print("|cFFFF0000[Error]|r Could not find end: " .. endName) return end

    -- Temporarily force debug mode ON
    local oldDebugState = OUS.Session.isDebugOn
    OUS.Session.isDebugOn = true

    if OUS.LogDebug then 
        OUS.LogDebug(string.format("[Routing] Found %d start nodes and %d end nodes. Testing combinations...", #startIDs, #endIDs))
    end

    local bestPath = {}
    local bestStartID = nil
    local bestEndID = nil
    
    -- Try every combination of Start and End nodes (solves the Faction/Orphan issue)
    for _, sID in ipairs(startIDs) do
        for _, eID in ipairs(endIDs) do
            local path = OUS.FindShortestRoute(sID, eID)
            
            -- If we found a path, and it's shorter than any previous path we found
            if #path > 0 and (#bestPath == 0 or #path < #bestPath) then
                bestPath = path
                bestStartID = sID
                bestEndID = eID
            end
        end
    end
    
    -- Restore original debug state
    OUS.Session.isDebugOn = oldDebugState
    
    if #bestPath > 0 then
        print(string.format("|cFF00FF00[Odysseus Routing]|r Itinerary for %s to %s:", OUS.TaxiNodes[bestStartID], OUS.TaxiNodes[bestEndID]))
        for i, nodeID in ipairs(bestPath) do
            print(string.format("  |cFFFFFF00Hop %d:|r %s", i, OUS.TaxiNodes[nodeID]))
        end
        print(string.format("|cFF00FFFFTotal Hops:|r %d", #bestPath - 1))
    else
        print(string.format("|cFFFF0000[Error]|r Path blocked. Faction mismatch or unconnected nodes between '%s' and '%s'.", startName, endName))
    end
end

-- ==========================================
-- 4. THE UI: SIDEBAR ITINERARY
-- ==========================================
-- Create the main Sidebar Frame
local itineraryFrame = CreateFrame("Frame", "OdysseusItineraryFrame", UIParent, "BackdropTemplate")
itineraryFrame:SetSize(220, 300)
itineraryFrame:Hide() -- Hidden by default

-- Give it that premium Odysseus dark styling
itineraryFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
itineraryFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
itineraryFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1) -- Cyan border!

-- Header Background
itineraryFrame.headerBg = itineraryFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
itineraryFrame.headerBg:SetPoint("TOPLEFT", 4, -4)
itineraryFrame.headerBg:SetPoint("TOPRIGHT", -4, -4)
itineraryFrame.headerBg:SetHeight(30)
itineraryFrame.headerBg:SetColorTexture(1, 1, 1, 1)
itineraryFrame.headerBg:SetGradient("HORIZONTAL", CreateColor(0.0, 0.4, 0.6, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

-- Title Text
itineraryFrame.title = itineraryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
itineraryFrame.title:SetPoint("TOP", itineraryFrame, "TOP", 10, -12) -- Shifted right to make room
itineraryFrame.title:SetText("Flight Itinerary")
itineraryFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

-- NEW: The Drake Icon!
itineraryFrame.icon = itineraryFrame:CreateTexture(nil, "OVERLAY")
itineraryFrame.icon:SetSize(18, 18)
itineraryFrame.icon:SetPoint("RIGHT", itineraryFrame.title, "LEFT", -6, 0)
-- THE FIX: Use the literal string path so the patch version doesn't matter!
itineraryFrame.icon:SetTexture("Interface\\Icons\\ability_mount_drake_blue") 
itineraryFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
-- The list of hops (FontString)
itineraryFrame.routeList = itineraryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itineraryFrame.routeList:SetPoint("TOPLEFT", itineraryFrame, "TOPLEFT", 15, -45)
itineraryFrame.routeList:SetJustifyH("LEFT")
itineraryFrame.routeList:SetJustifyV("TOP")
itineraryFrame.routeList:SetWidth(190)

-- ==========================================
-- 5. THE UI: SIDEBAR HOVER LOGIC
-- ==========================================
local function GetNodeDetails(raw)
    if not raw then return "Unknown Node", "" end
    local s = string.gsub(raw, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    local name, zone = strsplit(",", s, 2)
    return strtrim(name or s), strtrim(zone or "")
end

-- ==========================================
-- 6. MAP LINE DRAWING ENGINE (INVISIBLE ANCHORS)
-- ==========================================
local linePool = {}
local anchorPool = {}
local lineContainer = CreateFrame("Frame", "OdysseusRouteLineContainer", UIParent)

local function ClearRouteLines()
    for _, line in ipairs(linePool) do line:Hide() end
    for _, anchor in ipairs(anchorPool) do anchor:Hide() end
    lineContainer:Hide()
end

-- Generates invisible 1x1 pixel frames to act as our bulletproof anchors
local function GetAnchor(index, parentCanvas)
    if not anchorPool[index] then
        local f = CreateFrame("Frame", nil, parentCanvas)
        f:SetSize(1, 1) 
        anchorPool[index] = f
    end
    anchorPool[index]:SetParent(parentCanvas)
    return anchorPool[index]
end

local function GetMapLine(index, parentCanvas)
    if not linePool[index] then
        local line = parentCanvas:CreateLine()
        line:SetColorTexture(0.0, 0.8, 1.0, 1) -- Premium Odysseus Cyan
        line:SetThickness(5) -- Thick enough to eclipse the black dots
        line:SetDrawLayer("OVERLAY", 7) 
        linePool[index] = line
    end
    linePool[index]:SetParent(parentCanvas)
    return linePool[index]
end

local function DrawRouteLines(destSlot, numHops)
    ClearRouteLines()

    local mapCanvas
    if FlightMapFrame and FlightMapFrame:IsShown() then
        mapCanvas = FlightMapFrame.ScrollContainer.Child
    elseif TaxiFrame and TaxiFrame:IsShown() then
        mapCanvas = TaxiRouteMap
    else 
        return 
    end

    -- 1. Setup the High-Elevation Container
    lineContainer:SetParent(mapCanvas)
    lineContainer:ClearAllPoints()
    lineContainer:SetAllPoints(mapCanvas)
    -- Blast the FrameLevel to 200 so our cyan lines draw ABOVE Blizzard's black paths!
    lineContainer:SetFrameLevel(mapCanvas:GetFrameLevel() + 200)
    lineContainer:Show()

    local width, height = mapCanvas:GetSize()
    if not width or width == 0 then return end

    -- 2. Gather EXACT Coordinates for every single hop (No missing gaps!)
    local routePoints = {}
    
    -- Start Point
    for i = 1, NumTaxiNodes() do
        if TaxiNodeGetType(i) == "CURRENT" then
            local sx, sy = TaxiNodePosition(i)
            table.insert(routePoints, {x = sx, y = sy})
            break
        end
    end

    -- Intermediate Points (Forces the line to hit every single hop)
    for hopIndex = 1, numHops - 1 do
        local hx = TaxiGetDestX(destSlot, hopIndex)
        local hy = TaxiGetDestY(destSlot, hopIndex)
        table.insert(routePoints, {x = hx, y = hy})
    end

    -- End Point
    local dx, dy = TaxiNodePosition(destSlot)
    table.insert(routePoints, {x = dx, y = dy})

    -- 3. Position our Invisible Anchors precisely on the map
    for i = 1, #routePoints do
        local pt = routePoints[i]
        local anchor = GetAnchor(i, lineContainer)
        anchor:ClearAllPoints()
        -- Precise map positioning: X moves right, Y moves down (negative)
        anchor:SetPoint("CENTER", lineContainer, "TOPLEFT", pt.x * width, -pt.y * height)
        anchor:Show()
    end

    -- 4. Draw Lines snapping between our foolproof anchors
    for i = 1, #routePoints - 1 do
        local anchorA = GetAnchor(i, lineContainer)
        local anchorB = GetAnchor(i + 1, lineContainer)
        local line = GetMapLine(i, lineContainer)
        
        -- Lines attached to Frames automatically inherit zoom scaling natively!
        line:SetStartPoint("CENTER", anchorA, "CENTER")
        line:SetEndPoint("CENTER", anchorB, "CENTER")
        line:Show()
    end
end

-- ==========================================
-- 7. TRIGGERING THE ENGINES ON HOVER
-- ==========================================
hooksecurefunc(GameTooltip, "Show", function(self)
    local flightMapOpen = (FlightMapFrame and FlightMapFrame:IsShown()) or (TaxiFrame and TaxiFrame:IsShown())
    if not flightMapOpen then 
        itineraryFrame:Hide()
        ClearRouteLines()
        return 
    end

    local rawDest = _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText()
    if not rawDest then return end

    local destSlot = nil
    for i = 1, NumTaxiNodes() do
        if TaxiNodeName(i) == rawDest then
            destSlot = i
            break
        end
    end

    if not destSlot then return end

    local numHops = GetNumRoutes(destSlot)
    
    if numHops and numHops > 0 then
        -- 1. DRAW THE MAP LINES
        DrawRouteLines(destSlot, numHops)

        -- 2. BUILD THE SIDEBAR
        local startName, startZone = "Unknown Start", ""
        for i = 1, NumTaxiNodes() do
            if TaxiNodeGetType(i) == "CURRENT" then
                startName, startZone = GetNodeDetails(TaxiNodeName(i))
                break
            end
        end

        local destNameShort, destZone = GetNodeDetails(rawDest)
        
        local listText = "|cFF00FF00Start:|r " .. startName
        if startZone ~= "" then listText = listText .. "\n  |cFF999999" .. startZone .. "|r" end
        listText = listText .. "\n\n"
        
        for hopIndex = 1, numHops - 1 do 
            local hX = TaxiGetDestX(destSlot, hopIndex)
            local hY = TaxiGetDestY(destSlot, hopIndex)
            
            local hopName, hopZone = "Unknown Hop", ""
            for i = 1, NumTaxiNodes() do
                local nx, ny = TaxiNodePosition(i)
                if nx and ny and math.abs(nx - hX) < 0.001 and math.abs(ny - hY) < 0.001 then
                    hopName, hopZone = GetNodeDetails(TaxiNodeName(i))
                    break
                end
            end
            
            listText = listText .. "|cFFFFD100Hop " .. hopIndex .. ":|r " .. hopName
            if hopZone ~= "" then listText = listText .. "\n  |cFF999999" .. hopZone .. "|r" end
            listText = listText .. "\n\n"
        end
        
        listText = listText .. "|cFF00FFFFDest:|r " .. destNameShort
        if destZone ~= "" then listText = listText .. "\n  |cFF999999" .. destZone .. "|r" end
        listText = listText .. "\n\n|cFF888888Total Hops: " .. numHops .. "|r"
        
        itineraryFrame.routeList:SetText(listText)
        
        itineraryFrame:ClearAllPoints()
        if FlightMapFrame and FlightMapFrame:IsShown() then
            itineraryFrame:SetPoint("TOPLEFT", FlightMapFrame, "TOPRIGHT", 5, 0)
        elseif TaxiFrame and TaxiFrame:IsShown() then
            itineraryFrame:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", 5, -20)
        end
        
        itineraryFrame:SetHeight(70 + itineraryFrame.routeList:GetStringHeight())
        itineraryFrame:Show()
    else
        itineraryFrame:Hide()
        ClearRouteLines()
    end
end)

hooksecurefunc(GameTooltip, "Hide", function()
    itineraryFrame:Hide()
    ClearRouteLines()
end)

if FlightMapFrame then
    FlightMapFrame:HookScript("OnHide", function() 
        itineraryFrame:Hide() 
        ClearRouteLines() 
    end)
end
if TaxiFrame then
    TaxiFrame:HookScript("OnHide", function() 
        itineraryFrame:Hide() 
        ClearRouteLines() 
    end)
end