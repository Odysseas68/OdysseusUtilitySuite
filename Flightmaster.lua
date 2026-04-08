-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: FLIGHT MASTER
-- ==========================================
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
local activeKnownTime = nil

OUS.isFlightBarUnlocked = false

OUS.flightDefaults = {
    width = 200,
    height = 20,
    scale = 1.0,
    fontSize = 12,
    borderSize = 16,
    borderName = "None",
    fontName = "Friz Quadrata TT",
    textureName = "Blizzard",
    color = {r = 1, g = 0.7, b = 0},
    showTooltips = true,
}

local function GetShortName(name)
    if not name then return "Unknown" end
    local shortName = string.match(name, "^([^,]+)")
    return shortName and strtrim(shortName) or name
end

-- ==========================================
-- 2. CREATE THE VISUAL TIMER BAR
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
    if OdysseusDB and OdysseusDB.flightSettings then
        OdysseusDB.flightSettings.pos = {point, relativePoint, xOfs, yOfs}
    end
end)

-- ==========================================
-- 3. SECURELY GET DESTINATION & START
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
        OUS.LogDebug("Flight", string.format("Hooked TakeTaxiNode: [%s] -> [%s]", currentStartFull, currentDestFull))
    end
end)

-- ==========================================
-- 4. THE CUSTOM MAP TOOLTIP & LOOKUP
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

    local bundled = SearchTable(SFT_FlightData)
    if bundled then
        return bundled
    end

    local fallback = SearchTable(OUS and OUS.FlightData)
    if fallback then
        return fallback
    end

    return nil
end

hooksecurefunc(GameTooltip, "Show", function(self)
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.flightMaster then return end

    -- Safety Check: Ensure tooltips default to TRUE if the config hasn't been saved yet.
    if OdysseusDB.flightSettings.showTooltips == false then return end

    local flightMapOpen = (FlightMapFrame and FlightMapFrame:IsShown()) or (TaxiFrame and TaxiFrame:IsShown())
    if not flightMapOpen then
        mapTooltip:Hide()
        return
    end

    local rawDest = _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText()

    -- Debug Radar: Tell us what the engine sees!
    if IsAltKeyDown() then
        OUS.LogDebug("Flight", "Tooltip Hovered! Text found: " .. tostring(rawDest))
    end

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

    if startFull == "Unknown" and cachedStartFull ~= "Unknown" then startFull = cachedStartFull end
    if startFull == "Unknown" then startFull = CleanString(GetMinimapZoneText() or GetZoneText()) end

    if not nodeID then
        if IsAltKeyDown() then OUS.LogDebug("Flight", "Failed to find matching nodeID for: " .. destFull) end
        return
    end

    local destShort = GetShortName(destFull)
    local startShort = GetShortName(startFull)

    if IsAltKeyDown() then
        OUS.LogDebug("Flight", string.format("DB Search: [%s] -> [%s]", startFull, destFull))
    end

local knownTime = GetKnownTimeFromDB(startFull, destFull, startShort, destShort)
local showCost = false
local costString = ""

    -- Defensive handling: TaxiNodeCost() can sometimes surface a secret/tainted
    -- numeric value in odd post-instance states. Never let that break the tooltip.
    do
        local okCost, rawCost = pcall(TaxiNodeCost, nodeID)
        if okCost and rawCost ~= nil then
            local okNumber, cost = pcall(tonumber, rawCost)
            if okNumber and type(cost) == "number" and cost > 0 then
                local getCoinStr = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
                if getCoinStr then
                    local okCoin, result = pcall(getCoinStr, cost)
                    if okCoin and result then
                        showCost = true
                        costString = result
                    end
                else
                    showCost = true
                    costString = tostring(cost) .. "c"
                end
            end
        end
    end

    -- FIX 1: We removed the 'if knownTime or showCost then' wrapper.
    -- If we successfully found a nodeID, we ALWAYS show the tooltip!
    if knownTime then
        mapTooltip.timeText:SetText(string.format("Flight Time: %d:%02d", math.floor(knownTime / 60), knownTime % 60))
        mapTooltip.timeText:SetTextColor(0.2, 1, 0.2)
    else
        mapTooltip.timeText:SetText("Flight Time: Unknown")
        mapTooltip.timeText:SetTextColor(0.5, 0.5, 0.5)
    end

    if showCost then
        mapTooltip.costText:SetText("Cost: " .. costString)
    else
        mapTooltip.costText:SetText("")
    end

    mapTooltip:SetWidth(220)
    mapTooltip:SetHeight(showCost and 65 or 48)

    mapTooltip:ClearAllPoints()
    mapTooltip:SetPoint("TOP", GameTooltip, "BOTTOM", 0, -2)
    mapTooltip:Show()
end)

hooksecurefunc(GameTooltip, "Hide", function() mapTooltip:Hide() end)

-- ==========================================
-- 5. FLIGHT DETECTION & UPGRADE UPDATE
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

        activeKnownTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)
        OUS.LogDebug("Flight", "Liftoff! Known Time: " .. (activeKnownTime and tostring(math.floor(activeKnownTime)) .. "s" or "Unknown"))

        if activeKnownTime then
            timerBar:SetMinMaxValues(0, activeKnownTime)
        else
            timerBar:SetMinMaxValues(0, 1)
            timerBar:SetValue(1)
        end

    elseif not onTaxi and isFlying then
        isFlying = false
        OUS.timerText:SetText("")
        OUS.timerTopText:SetText("")
        timerBar:SetValue(0)

        if not OUS.isFlightBarUnlocked then
            timerBar:Hide()
        end

        local duration = math.floor((GetTime() - startTime) + 0.5)
        OUS.LogDebug("Flight", string.format("Landed. Total duration: %d seconds.", duration))

        if duration > 10 and currentDestFull ~= "Unknown" then
            OdysseusDB.flightSettings.times = OdysseusDB.flightSettings.times or {}
            local oldTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)

            if not oldTime or math.abs(oldTime - duration) > 5 then
                OdysseusDB.flightSettings.times[currentStartFull] = OdysseusDB.flightSettings.times[currentStartFull] or {}
                OdysseusDB.flightSettings.times[currentStartFull][currentDestFull] = duration

                if not oldTime then
                    print("|cFF00CCFFOdysseus:|r |cFF33FF33Learned|r flight from |cFFFFD100" .. currentStartFull .. "|r to |cFFFFD100" .. currentDestFull .. "|r.")
                    OUS.LogDebug("Flight", "Saved new flight time to database.")
                else
                    print("|cFF00CCFFOdysseus:|r |cFFFFAA00Updated|r flight from |cFFFFD100" .. currentStartFull .. "|r to |cFFFFD100" .. currentDestFull .. "|r.")
                    OUS.LogDebug("Flight", "Updated existing flight time in database.")
                end
            end
        end

        activeKnownTime = nil
        currentDestFull = "Unknown"
        currentStartFull = "Unknown"
        currentDestShort = "Unknown"
        currentStartShort = "Unknown"
        startTime = 0
    end

    if isFlying and not OUS.isFlightBarUnlocked then
        local timeElapsed = GetTime() - startTime
        local knownTime = activeKnownTime

        if knownTime then
            local timeLeft = knownTime - timeElapsed
            if timeLeft > 0 then
                timerBar:SetValue(timeLeft)
                OUS.timerText:SetText(string.format("Flying: %d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60)))
            else
                OUS.timerText:SetText("Arrival Imminent")
                timerBar:SetValue(0)
            end
        else
            OUS.timerText:SetText(string.format("Flying: %d:%02d", math.floor(timeElapsed / 60), math.floor(timeElapsed % 60)))
            timerBar:SetValue(1)
        end
    end
end)

-- ==========================================
-- 6. LOAD SAVED DATA
-- ==========================================
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}

        -- Merge in any missing defaults
        for k, v in pairs(OUS.flightDefaults) do
            if OdysseusDB.flightSettings[k] == nil then
                if type(v) == "table" then
                    OdysseusDB.flightSettings[k] = OUS.DeepCopyTable(v)
                else
                    OdysseusDB.flightSettings[k] = v
                end
            end
        end
        OdysseusDB.flightSettings.times = OdysseusDB.flightSettings.times or {}

        if OdysseusDB.flightSettings.pos then
            local p = OdysseusDB.flightSettings.pos
            timerBar:ClearAllPoints()
            timerBar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end

        -- Data Migration & Defaulting for color table
        local c = OdysseusDB.flightSettings.color
        if not c then
            -- Fresh install, set default keyed table
            OdysseusDB.flightSettings.color = {r = 1, g = 0.7, b = 0}
        elseif c[1] and not c.r then
            -- Old numeric array format detected, migrate it
            OdysseusDB.flightSettings.color = {r = c[1], g = c[2], b = c[3]}
        end

        -- Now we can safely apply the color from the (now guaranteed) keyed table
        local finalColor = OdysseusDB.flightSettings.color
        timerBar:SetStatusBarColor(finalColor.r, finalColor.g, finalColor.b)

        OUS.LogDebug("Flight", "Database loaded successfully.")
    end

    if event == "PLAYER_LOGIN" then
        OUS.ApplyFlightFonts()
        OUS.ApplyFlightTexture()
        OUS.ApplyFlightBorder()

        if OdysseusDB.flightSettings.width then timerBar:SetWidth(OdysseusDB.flightSettings.width) end
        if OdysseusDB.flightSettings.height then timerBar:SetHeight(OdysseusDB.flightSettings.height) end
        if OdysseusDB.flightSettings.scale then timerBar:SetScale(OdysseusDB.flightSettings.scale) end
    end
end)