local addonName, OUS = ...
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN") 

local LSM = LibStub("LibSharedMedia-3.0")

local isFlying = false
local startTime = 0

local currentDestFull = "Unknown"
local currentStartFull = "Unknown"
local currentDestShort = "Unknown"
local currentStartShort = "Unknown"

OUS.isFlightBarUnlocked = false

local function GetShortName(name)
    if not name then return "Unknown" end
    local shortName = string.match(name, "^([^,]+)")
    return shortName and strtrim(shortName) or name
end

-- ==========================================
-- 1. CREATE THE VISUAL TIMER BAR
-- ==========================================
OUS.timerBar = CreateFrame("StatusBar", nil, UIParent)
local timerBar = OUS.timerBar
timerBar:SetSize(200, 20)
timerBar:SetPoint("TOP", UIParent, "TOP", 0, -150)
timerBar:Hide()

local bg = timerBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0, 0, 0, 0.5)

OUS.timerBorderFrame = CreateFrame("Frame", nil, timerBar, "BackdropTemplate")
local borderFrame = OUS.timerBorderFrame
borderFrame:SetFrameLevel(timerBar:GetFrameLevel() + 2) 

OUS.timerText = timerBar:CreateFontString(nil, "OVERLAY")
OUS.timerText:SetPoint("CENTER")

OUS.timerTopText = timerBar:CreateFontString(nil, "OVERLAY")
OUS.timerTopText:SetPoint("BOTTOM", timerBar, "TOP", 0, 4)

function OUS.ApplyFlightFonts()
    local fName = OdysseusDB.flightSettings.fontName or "Friz Quadrata TT"
    local fPath = LSM:Fetch("font", fName) or LSM:Fetch("font", "Friz Quadrata TT")
    local fSize = OdysseusDB.flightSettings.fontSize or 12
    OUS.timerText:SetFont(fPath, fSize, "OUTLINE")
    OUS.timerTopText:SetFont(fPath, math.max(8, fSize - 3), "OUTLINE") 
end

function OUS.ApplyFlightTexture()
    local tName = OdysseusDB.flightSettings.textureName or "Blizzard"
    local tPath = LSM:Fetch("statusbar", tName) or LSM:Fetch("statusbar", "Blizzard")
    timerBar:SetStatusBarTexture(tPath)
end

function OUS.ApplyFlightBorder()
    local bName = OdysseusDB.flightSettings.borderName or "None"
    local bPath = LSM:Fetch("border", bName)
    local bSize = OdysseusDB.flightSettings.borderSize or 16
    
    if bPath and bName ~= "None" then
        borderFrame:SetBackdrop({ edgeFile = bPath, edgeSize = bSize })
        local offset = math.floor(bSize / 3)
        borderFrame:ClearAllPoints()
        borderFrame:SetPoint("TOPLEFT", timerBar, "TOPLEFT", -offset, offset)
        borderFrame:SetPoint("BOTTOMRIGHT", timerBar, "BOTTOMRIGHT", offset, -offset)
    else
        borderFrame:SetBackdrop(nil)
        borderFrame:ClearAllPoints()
        borderFrame:SetAllPoints(timerBar) 
    end
end

timerBar:SetMovable(true)
timerBar:EnableMouse(false)
timerBar:RegisterForDrag("LeftButton")
timerBar:SetScript("OnDragStart", timerBar.StartMoving)
timerBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    OdysseusDB.flightSettings.pos = {point, relativePoint, xOfs, yOfs}
end)

-- ==========================================
-- 2. SECURELY GET DESTINATION & START
-- ==========================================
local cachedStartFull = "Unknown"

-- Aggressively strip color codes, newlines, and trailing spaces
local function CleanString(str)
    if not str then return "Unknown" end
    str = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
    str = string.gsub(str, "|r", "")
    str = string.gsub(str, "[\r\n]", "")
    return string.match(str, "^%s*(.-)%s*$")
end

hooksecurefunc("TakeTaxiNode", function(slot)
    if TaxiNodeName(slot) then
        currentDestFull = CleanString(TaxiNodeName(slot))
        currentDestShort = GetShortName(currentDestFull)
        
        local foundStart = false
        for i = 1, NumTaxiNodes() do
            if TaxiNodeGetType(i) == "CURRENT" then
                currentStartFull = CleanString(TaxiNodeName(i))
                foundStart = true
                break
            end
        end
        
        if not foundStart then
            if cachedStartFull ~= "Unknown" then
                currentStartFull = cachedStartFull
            else
                currentStartFull = CleanString(GetMinimapZoneText() or GetZoneText())
            end
        end
        
        currentStartShort = GetShortName(currentStartFull)
    end
end)

-- ==========================================
-- 3. THE CUSTOM MAP TOOLTIP & LOOKUP
-- ==========================================
local mapTooltip = CreateFrame("Frame", "OdysseusMapTooltip", UIParent, "BackdropTemplate")
mapTooltip:SetFrameStrata("TOOLTIP")
mapTooltip:SetSize(180, 65)
mapTooltip:Hide()

mapTooltip:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
mapTooltip:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
mapTooltip:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

mapTooltip.headerBg = mapTooltip:CreateTexture(nil, "BACKGROUND", nil, 2)
mapTooltip.headerBg:SetPoint("TOPLEFT", 4, -4)
mapTooltip.headerBg:SetPoint("TOPRIGHT", -4, -4)
mapTooltip.headerBg:SetHeight(22)
mapTooltip.headerBg:SetColorTexture(1, 1, 1, 1)
mapTooltip.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

mapTooltip.title = mapTooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mapTooltip.title:SetPoint("TOP", mapTooltip, "TOP", 0, -8)
mapTooltip.title:SetText("Odysseus Flight Timer")
mapTooltip.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

mapTooltip.timeText = mapTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mapTooltip.timeText:SetPoint("TOP", mapTooltip.title, "BOTTOM", 0, -6)

mapTooltip.costText = mapTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mapTooltip.costText:SetPoint("TOP", mapTooltip.timeText, "BOTTOM", 0, -4)

-- Exhaustive Database Lookup
local function GetKnownTimeFromDB(startFull, destFull, startShort, destShort)
    local function SearchTable(db)
        if type(db) ~= "table" then return nil end
        if db[startFull] and db[startFull][destFull] then return db[startFull][destFull] end
        if db[startShort] and db[startShort][destShort] then return db[startShort][destShort] end
        if db[startFull] and db[startFull][destShort] then return db[startFull][destShort] end
        if db[startShort] and db[startShort][destFull] then return db[startShort][destFull] end
        return nil
    end

    local time = SearchTable(OdysseusDB and OdysseusDB.flightSettings and OdysseusDB.flightSettings.times)
    if time then return time end
    
    time = SearchTable(SFT_FlightData)
    if time then return time end
    
    time = SearchTable(OUS and OUS.FlightData) -- Fallback just in case your generated file uses OUS
    if time then return time end
    
    return nil
end

hooksecurefunc(GameTooltip, "Show", function(self)
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.flightMaster then return end
    if not OdysseusDB.flightSettings.showTooltips then return end

    local flightMapOpen = (FlightMapFrame and FlightMapFrame:IsShown()) or (TaxiFrame and TaxiFrame:IsShown())
    if not flightMapOpen then 
        mapTooltip:Hide()
        return 
    end

    local rawDest = _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText()
    if not rawDest then return end

    local destFull = CleanString(rawDest)
    local nodeID = nil
    local startFull = "Unknown"

    for i = 1, NumTaxiNodes() do
        local rawNode = TaxiNodeName(i)
        if rawNode then
            local nodeName = CleanString(rawNode)
            if TaxiNodeGetType(i) == "CURRENT" then
                startFull = nodeName
                cachedStartFull = nodeName
            elseif nodeName == destFull or string.find(destFull, nodeName, 1, true) then
                nodeID = i
                destFull = nodeName -- Force exact sync
            end
        end
    end

    if startFull == "Unknown" and cachedStartFull ~= "Unknown" then
        startFull = cachedStartFull
    end

    if startFull == "Unknown" then
        startFull = CleanString(GetMinimapZoneText() or GetZoneText())
    end

    if not nodeID then return end

    local destShort = GetShortName(destFull)
    local startShort = GetShortName(startFull)

    -- DIAGNOSTIC TOOL: Hold ALT to see exactly what the addon is searching for!
    if IsAltKeyDown() then
        print("|cFF00FFFF[Odysseus Debug]|r DB Search: [" .. startFull .. "] -> [" .. destFull .. "]")
    end

    local knownTime = GetKnownTimeFromDB(startFull, destFull, startShort, destShort)
    local cost = TaxiNodeCost(nodeID)
    local showCost = false
    local costString = ""

    if cost then
        local success, isGreaterThanZero = pcall(function() return cost > 0 end)
        if success and isGreaterThanZero then
            local strSuccess, strVal = pcall(GetCoinTextureString, cost)
            if strSuccess and strVal then
                showCost = true
                costString = strVal
            end
        end
    end

    if knownTime or showCost then
        if knownTime then
            mapTooltip.timeText:SetText(string.format("Flight Time: %d:%02d", math.floor(knownTime / 60), knownTime % 60))
            mapTooltip.timeText:SetTextColor(0.2, 1, 0.2) 
        else
            mapTooltip.timeText:SetText("Flight Time: Unknown")
            mapTooltip.timeText:SetTextColor(0.5, 0.5, 0.5) 
        end
        
        if showCost then mapTooltip.costText:SetText("Cost: " .. costString) else mapTooltip.costText:SetText("") end
        
        local w1 = mapTooltip.timeText:GetStringWidth()
        local w2 = mapTooltip.costText:GetStringWidth()
        local maxW = math.max(w1, w2, 130)
        mapTooltip:SetWidth(maxW + 30)
        mapTooltip:SetHeight(showCost and 65 or 48)
        
        mapTooltip:ClearAllPoints()
        mapTooltip:SetPoint("TOP", GameTooltip, "BOTTOM", 0, -2)
        mapTooltip:Show()
    end
end)

hooksecurefunc(GameTooltip, "Hide", function()
    mapTooltip:Hide()
end)

-- ==========================================
-- 4. FLIGHT DETECTION & UPGRADE UPDATE
-- ==========================================
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.flightMaster then return end

    local onTaxi = UnitOnTaxi("player")
    
    if onTaxi and not isFlying then
        isFlying = true
        startTime = GetTime()
        OUS.ApplyFlightBorder() 
        timerBar:Show()
        OUS.timerTopText:SetText(currentStartFull .. " -> " .. currentDestFull)
        
        local knownTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)
        
        if knownTime then
            timerBar:SetMinMaxValues(0, knownTime)
        else
            timerBar:SetMinMaxValues(0, 1)
            timerBar:SetValue(1)
        end
        
    elseif not onTaxi and isFlying then
        isFlying = false
        if not OUS.isFlightBarUnlocked then timerBar:Hide() end
        
        local duration = GetTime() - startTime
        
        if duration > 10 and currentDestFull ~= "Unknown" then 
            OdysseusDB.flightSettings.times = OdysseusDB.flightSettings.times or {}
            local oldTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)
            
            if not oldTime or math.abs(oldTime - duration) > 3 then
                OdysseusDB.flightSettings.times[currentStartFull] = OdysseusDB.flightSettings.times[currentStartFull] or {}
                OdysseusDB.flightSettings.times[currentStartFull][currentDestFull] = duration
                
                if not oldTime then
                    print("|cFF00CCFFOdysseus:|r |cFF33FF33Learned|r flight from |cFFFFD100" .. currentStartFull .. "|r to |cFFFFD100" .. currentDestFull .. "|r.")
                else 
                    print("|cFF00CCFFOdysseus:|r |cFFFFAA00Updated|r flight from |cFFFFD100" .. currentStartFull .. "|r to |cFFFFD100" .. currentDestFull .. "|r.")
                end
            end
        end
    end

    if isFlying and not OUS.isFlightBarUnlocked then
        local timeElapsed = GetTime() - startTime
        local knownTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)
        
        if knownTime then
            local timeLeft = knownTime - timeElapsed
            if timeLeft > 0 then
                timerBar:SetValue(timeLeft) 
                OUS.timerText:SetText(string.format("Flying: %d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60)))
            else
                OUS.timerText:SetText("Arriving soon...")
                timerBar:SetValue(0)
            end
        else
            OUS.timerText:SetText(string.format("Learning... %d:%02d", math.floor(timeElapsed / 60), math.floor(timeElapsed % 60)))
        end
    end
end)

-- ==========================================
-- 5. LOAD SAVED DATA
-- ==========================================
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
        OdysseusDB.flightSettings.times = OdysseusDB.flightSettings.times or {}
        
        if OdysseusDB.flightSettings.pos then
            local p = OdysseusDB.flightSettings.pos
            timerBar:ClearAllPoints()
            timerBar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end
        if OdysseusDB.flightSettings.color then timerBar:SetStatusBarColor(unpack(OdysseusDB.flightSettings.color)) else timerBar:SetStatusBarColor(1, 0.7, 0) end
    end
    
    if event == "PLAYER_LOGIN" then
        -- Apply visuals
        OUS.ApplyFlightFonts()
        OUS.ApplyFlightTexture()
        OUS.ApplyFlightBorder()

        -- Apply saved dimensions & scale
        if OdysseusDB.flightSettings.width then
            timerBar:SetWidth(OdysseusDB.flightSettings.width)
        end
        if OdysseusDB.flightSettings.height then
            timerBar:SetHeight(OdysseusDB.flightSettings.height)
        end
        if OdysseusDB.flightSettings.scale then
            timerBar:SetScale(OdysseusDB.flightSettings.scale)
        end
    end
end)