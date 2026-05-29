-- Addon   : OdysseusUtilitySuite
-- File    : FlightRouting.lua
-- Version : 2026.05.29
-- Desc    : Multi-hop flight routing engine, itinerary panel, and map line drawing
-- ============================================================

local addonName, OUS = ...

-- Ensure our routing database exists before proceeding
if not OUS.TaxiNodes or not OUS.TaxiRoutes then return end

-- Initialize Session table if it doesn't exist yet (just to be safe)
OUS.Session = OUS.Session or {}

-- ==========================================
-- 1. THE ROUTING ENGINE (Dijkstra's Algorithm)
-- ==========================================
function OUS.FindShortestRoute(startNodeID, endNodeID)
    if not startNodeID or not endNodeID then
        return {}
    end

    if not OUS.TaxiNodes[startNodeID] or not OUS.TaxiNodes[endNodeID] then
        return {}
    end

    if OUS.LogDebug then
        OUS.LogDebug(string.format("[Routing] Starting path calculation: %s -> %s", OUS.TaxiNodes[startNodeID] or "Unknown", OUS.TaxiNodes[endNodeID] or "Unknown"))
    end

    local distances = {}
    local previous = {}
    local unvisited = {}
    local iterations = 0

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
            if OUS.LogDebug then
                OUS.LogDebug("[Routing] Target reached or network exhausted after " .. iterations .. " iterations.")
            end
            break
        end

        unvisited[currentNode] = nil

        if OUS.TaxiRoutes[currentNode] then
            for neighborID in pairs(OUS.TaxiRoutes[currentNode]) do
                if unvisited[neighborID] then
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

local function GetKnownLegTime(startFull, destFull, startShort, destShort)
    local function SearchTable(db)
        if type(db) ~= "table" then
            return nil
        end

        local row = db[startFull]
        if type(row) == "table" then
            if row[destFull] then return row[destFull] end
            if row[destShort] then return row[destShort] end
        end

        row = db[startShort]
        if type(row) == "table" then
            if row[destShort] then return row[destShort] end
            if row[destFull] then return row[destFull] end
        end

        return nil
    end

    local saved = SearchTable(OdysseusDB and OdysseusDB.flightSettings and OdysseusDB.flightSettings.times)
    if saved then
        return saved
    end

    local bundled = SearchTable(rawget(_G, "SFT_FlightData"))
    if bundled then
        return bundled
    end

    local fallback = SearchTable(OUS and OUS.FlightData)
    if fallback then
        return fallback
    end

    return nil
end

local function FormatFlightTime(seconds)
    if not seconds or seconds <= 0 then
        return "Unknown"
    end

    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

local YARDS_TO_METERS = 0.9144

--- Formats a yard distance as meters or km for display.
local function FormatRouteDist(yards)
    local meters = math.floor(yards * YARDS_TO_METERS)
    if meters >= 1000 then
        local km  = math.floor(meters / 1000)
        local rem = meters % 1000
        return string.format("%dkm %dm", km, rem)
    end
    return string.format("%dm", meters)
end

--- Returns straight-line distance in yards between two world positions.
local function CalcWorldDist(wx1, wy1, wx2, wy2)
    local dx = wx2 - wx1
    local dy = wy2 - wy1
    return math.sqrt(dx * dx + dy * dy)
end

--- Returns total route distance in yards by matching node names to
--- C_TaxiMap world positions and summing segment distances.
local function CalcTotalRouteDist(nodeNames)
    if not nodeNames or #nodeNames < 2 then return nil end
    local uiMapID  = C_Map.GetBestMapForUnit("player")
    local allNodes = C_TaxiMap.GetAllTaxiNodes(uiMapID)
    if not allNodes then return nil end

    -- Build name -> world position lookup
    local posLookup = {}
    for _, node in ipairs(allNodes) do
        if node.name and node.position then
            local _, worldPos = C_Map.GetWorldPosFromMapPos(uiMapID, node.position)
            if worldPos then
                -- strip color codes for matching
                local clean = node.name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                posLookup[clean] = worldPos
            end
        end
    end

    local total = 0
    for i = 1, #nodeNames - 1 do
        local fromName = nodeNames[i]:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        local toName   = nodeNames[i + 1]:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        local fromPos  = posLookup[fromName]
        local toPos    = posLookup[toName]
        if fromPos and toPos then
            total = total + CalcWorldDist(fromPos.x, fromPos.y, toPos.x, toPos.y)
        else
            return nil   -- missing position = can't compute total
        end
    end
    return total
end

-- ==========================================
-- 6. MAP LINE DRAWING ENGINE (INVISIBLE ANCHORS)
-- ==========================================
local linePool = {}
local anchorPool = {}
local lastTooltipDest = nil
local lastTooltipMapMode = nil
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

    lineContainer:SetParent(mapCanvas)
    lineContainer:ClearAllPoints()
    lineContainer:SetAllPoints(mapCanvas)
    lineContainer:SetFrameLevel(mapCanvas:GetFrameLevel() + 200)
    lineContainer:Show()

    local width, height = mapCanvas:GetSize()
    if not width or width == 0 or not height or height == 0 then
        return
    end

    local routePoints = {}

    for i = 1, NumTaxiNodes() do
        if TaxiNodeGetType(i) == "CURRENT" then
            local sx, sy = TaxiNodePosition(i)
            if sx and sy then
                table.insert(routePoints, { x = sx, y = sy })
            end
            break
        end
    end

    for hopIndex = 1, numHops - 1 do
        local hx = TaxiGetDestX(destSlot, hopIndex)
        local hy = TaxiGetDestY(destSlot, hopIndex)
        if hx and hy then
            table.insert(routePoints, { x = hx, y = hy })
        end
    end

    local dx, dy = TaxiNodePosition(destSlot)
    if dx and dy then
        table.insert(routePoints, { x = dx, y = dy })
    end

    if #routePoints < 2 then
        ClearRouteLines()
        return
    end

    for i = 1, #routePoints do
        local pt = routePoints[i]
        if pt and pt.x and pt.y then
            local anchor = GetAnchor(i, lineContainer)
            anchor:ClearAllPoints()
            anchor:SetPoint("CENTER", lineContainer, "TOPLEFT", pt.x * width, -pt.y * height)
            anchor:Show()
        end
    end

    for i = 1, #routePoints - 1 do
        local anchorA = GetAnchor(i, lineContainer)
        local anchorB = GetAnchor(i + 1, lineContainer)
        local line = GetMapLine(i, lineContainer)

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
        lastTooltipDest = nil
        lastTooltipMapMode = nil
        itineraryFrame:Hide()
        ClearRouteLines()
        return
    end

    local rawDest = _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText()
    if not rawDest then
        return
    end

    local mapMode = (FlightMapFrame and FlightMapFrame:IsShown()) and "flightmap" or "taxiframe"
    if rawDest == lastTooltipDest and mapMode == lastTooltipMapMode and itineraryFrame:IsShown() then
        return
    end

    local destSlot = nil
    for i = 1, NumTaxiNodes() do
        if TaxiNodeName(i) == rawDest then
            destSlot = i
            break
        end
    end

    if not destSlot then
        lastTooltipDest = nil
        lastTooltipMapMode = nil
        itineraryFrame:Hide()
        ClearRouteLines()
        return
    end

    local numHops = GetNumRoutes(destSlot)
    if not numHops or numHops <= 0 then
        lastTooltipDest = nil
        lastTooltipMapMode = nil
        itineraryFrame:Hide()
        ClearRouteLines()
        return
    end

    lastTooltipDest = rawDest
    lastTooltipMapMode = mapMode

    DrawRouteLines(destSlot, numHops)

    local startName, startZone = "Unknown Start", ""
    for i = 1, NumTaxiNodes() do
        if TaxiNodeGetType(i) == "CURRENT" then
            startName, startZone = GetNodeDetails(TaxiNodeName(i))
            break
        end
    end

    local destNameShort, destZone = GetNodeDetails(rawDest)

    local routeNodeNames = {}
for i = 1, NumTaxiNodes() do
    if TaxiNodeGetType(i) == "CURRENT" then
        table.insert(routeNodeNames, TaxiNodeName(i))
        break
    end
end

for hopIndex = 1, numHops - 1 do
    local hX = TaxiGetDestX(destSlot, hopIndex)
    local hY = TaxiGetDestY(destSlot, hopIndex)

    if hX and hY then
        for i = 1, NumTaxiNodes() do
            local nx, ny = TaxiNodePosition(i)
            if nx and ny and math.abs(nx - hX) < 0.001 and math.abs(ny - hY) < 0.001 then
                table.insert(routeNodeNames, TaxiNodeName(i))
                break
            end
        end
    end
end

table.insert(routeNodeNames, rawDest)

local totalRouteTime = 0
local totalRouteTimeKnown = true

for i = 1, #routeNodeNames - 1 do
    local fromFull = routeNodeNames[i]
    local toFull = routeNodeNames[i + 1]

    local fromShort = GetNodeDetails(fromFull)
    local toShort = GetNodeDetails(toFull)

    local legTime = GetKnownLegTime(fromFull, toFull, fromShort, toShort)
    if legTime then
        totalRouteTime = totalRouteTime + legTime
    else
        totalRouteTimeKnown = false
        break
    end
end

local totalRouteDist = CalcTotalRouteDist(routeNodeNames)

    local listText = "|cFF00FF00Start:|r " .. startName
    if startZone ~= "" then
        listText = listText .. "\n  |cFF999999" .. startZone .. "|r"
    end
    listText = listText .. "\n\n"

    for hopIndex = 1, numHops - 1 do
        local hX = TaxiGetDestX(destSlot, hopIndex)
        local hY = TaxiGetDestY(destSlot, hopIndex)

        local hopName, hopZone = "Unknown Hop", ""
        if hX and hY then
            for i = 1, NumTaxiNodes() do
                local nx, ny = TaxiNodePosition(i)
                if nx and ny and math.abs(nx - hX) < 0.001 and math.abs(ny - hY) < 0.001 then
                    hopName, hopZone = GetNodeDetails(TaxiNodeName(i))
                    break
                end
            end
        end

        listText = listText .. "|cFFFFD100Hop " .. hopIndex .. ":|r " .. hopName
        if hopZone ~= "" then
            listText = listText .. "\n  |cFF999999" .. hopZone .. "|r"
        end
        listText = listText .. "\n\n"
    end

    listText = listText .. "|cFF00FFFFDest:|r " .. destNameShort
    if destZone ~= "" then
        listText = listText .. "\n  |cFF999999" .. destZone .. "|r"
    end
    listText = listText .. "\n\n|cFFFFD100Total Hops: " .. numHops .. "|r"

    if totalRouteTimeKnown then
        listText = listText .. "\n|cFF00CC44Estimated Time: " .. FormatFlightTime(totalRouteTime) .. "|r"
    else
        listText = listText .. "\n|cFF00CC44Estimated Time: Unknown|r"
    end

    if totalRouteDist then
        listText = listText .. "\n|cFF66CCFFDistance: " .. FormatRouteDist(totalRouteDist) .. "|r"
    else
        listText = listText .. "\n|cFF66CCFFDistance: Unknown|r"
    end

    itineraryFrame.routeList:SetText(listText)

    itineraryFrame:ClearAllPoints()
    if FlightMapFrame and FlightMapFrame:IsShown() then
        itineraryFrame:SetPoint("TOPLEFT", FlightMapFrame, "TOPRIGHT", 5, 0)
    elseif TaxiFrame and TaxiFrame:IsShown() then
        itineraryFrame:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", 5, -20)
    end

    itineraryFrame:SetHeight(70 + itineraryFrame.routeList:GetStringHeight())
    itineraryFrame:Show()
end)

hooksecurefunc(GameTooltip, "Hide", function()
    lastTooltipDest = nil
    lastTooltipMapMode = nil
    itineraryFrame:Hide()
    ClearRouteLines()
end)

if FlightMapFrame then
    FlightMapFrame:HookScript("OnHide", function()
        lastTooltipDest = nil
        lastTooltipMapMode = nil
        itineraryFrame:Hide()
        ClearRouteLines()
    end)
end

if TaxiFrame then
    TaxiFrame:HookScript("OnHide", function()
        lastTooltipDest = nil
        lastTooltipMapMode = nil
        itineraryFrame:Hide()
        ClearRouteLines()
    end)
end
