-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Flightmaster.lua
-- Version : 2026.08.19
-- Desc    : Flight timer bar, distance display, taxi map tooltip with time and cost
-- ============================================================

-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: FLIGHT MASTER
-- ==========================================
local addonName, OUS = ...
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("TAXIMAP_OPENED")
f:RegisterEvent("TAXIMAP_CLOSED")
f:RegisterUnitEvent("UNIT_FLAGS", "player")

local LSM = LibStub("LibSharedMedia-3.0")

local isFlying = false
local startTime = 0

local currentDestFull = "Unknown"
local currentStartFull = "Unknown"
local currentDestShort = "Unknown"
local currentStartShort = "Unknown"
local activeKnownTime = nil

local cachedTotalDist = nil   -- total distance in map units (0-1 space), set at tooltip hover

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

local function GetTaxiCostString(cost)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        local ok, result = pcall(C_CurrencyInfo.GetCoinTextureString, cost)
        if ok and type(result) == "string" and result ~= "" then
            return result
        end
    end

    local copper = cost % 100
    local silverTotal = math.floor(cost / 100)
    local silver = silverTotal % 100
    local gold = math.floor(silverTotal / 100)

    if gold > 0 then
        return string.format("%dg %ds %dc", gold, silver, copper)
    end
    if silver > 0 then
        return string.format("%ds %dc", silver, copper)
    end
    return string.format("%dc", copper)
end

-- ==========================================
-- 2. CREATE THE VISUAL TIMER BAR
-- ==========================================
OUS.timerBar = CreateFrame("Frame", nil, UIParent)
local timerBar = OUS.timerBar
timerBar:SetSize(200, 20)
timerBar:SetPoint("TOP", UIParent, "TOP", 0, -150)
timerBar:Hide()

local bg = timerBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(timerBar)
bg:SetColorTexture(0, 0, 0, 0.5)

-- Plain texture fill — resized manually each frame for smooth animation
local barFill = timerBar:CreateTexture(nil, "BORDER")
barFill:SetPoint("TOPLEFT", timerBar, "TOPLEFT", 0, 0)
barFill:SetPoint("BOTTOMLEFT", timerBar, "BOTTOMLEFT", 0, 0)
barFill:SetWidth(200)
local barMaxWidth = 200

OUS.timerBorderFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
local borderFrame = OUS.timerBorderFrame
borderFrame:SetFrameLevel(timerBar:GetFrameLevel() + 2)
borderFrame:SetPoint("TOPLEFT", timerBar, "TOPLEFT", 0, 0)
borderFrame:SetPoint("BOTTOMRIGHT", timerBar, "BOTTOMRIGHT", 0, 0)

-- Text frames parented to UIParent and anchored to timerBar
-- Decoupled from StatusBar redraws for smooth independent updates
local timerTextFrame = CreateFrame("Frame", nil, UIParent)
timerTextFrame:SetAllPoints(timerBar)
timerTextFrame:SetFrameLevel(timerBar:GetFrameLevel() + 3)

OUS.timerText = timerTextFrame:CreateFontString(nil, "OVERLAY")
OUS.timerText:SetPoint("CENTER", timerBar, "CENTER", 0, 0)

local timerTopFrame = CreateFrame("Frame", nil, UIParent)
timerTopFrame:SetPoint("BOTTOM", timerBar, "TOP", 0, 0)
timerTopFrame:SetSize(300, 20)
timerTopFrame:SetFrameLevel(timerBar:GetFrameLevel() + 3)

OUS.timerTopText = timerTopFrame:CreateFontString(nil, "OVERLAY")
OUS.timerTopText:SetPoint("CENTER", timerTopFrame, "CENTER", 0, 0)

local timerBottomFrame = CreateFrame("Frame", nil, UIParent)
timerBottomFrame:SetPoint("TOP", timerBar, "BOTTOM", 0, 0)
timerBottomFrame:SetSize(300, 20)
timerBottomFrame:SetFrameLevel(timerBar:GetFrameLevel() + 3)

OUS.timerBottomText = timerBottomFrame:CreateFontString(nil, "OVERLAY")
OUS.timerBottomText:SetPoint("CENTER", timerBottomFrame, "CENTER", 0, 0)
OUS.timerBottomText:SetTextColor(0.4, 0.8, 1.0)
OUS.timerBottomText:Hide()

borderFrame:Hide()
timerTextFrame:Hide()
timerTopFrame:Hide()
timerBottomFrame:Hide()

function OUS.ApplyFlightTexture()
    local tName = OdysseusDB.flightSettings.textureName or "Blizzard"
    local tPath = LSM:Fetch("statusbar", tName) or LSM:Fetch("statusbar", "Blizzard") or "Interface\\TargetingFrame\\UI-StatusBar"
    barFill:SetTexture(tPath)
end

--- Sets bar fill color — called from Config color picker.
function OUS.SetFlightBarColor(r, g, b)
    barFill:SetVertexColor(r, g, b)
end

--- Sets border color — called from Config border color picker.
function OUS.SetFlightBorderColor(r, g, b)
    OdysseusDB.flightSettings.borderColor = OdysseusDB.flightSettings.borderColor or {}
    local bc = OdysseusDB.flightSettings.borderColor
    bc.r, bc.g, bc.b = r, g, b
    borderFrame:SetBackdropBorderColor(r, g, b, 1)
end

--- Shows bar at full width for unlock/preview mode in Config.
function OUS.PreviewFlightBar()
    barMaxWidth = timerBar:GetWidth() or 200
    barFill:SetWidth(barMaxWidth)
end

--- Shows all decoupled text frames — called from Config unlock mode.
function OUS.ShowFlightTextFrames()
    timerTextFrame:Show()
    timerTopFrame:Show()
    timerBottomFrame:Show()
end

--- Hides all decoupled text frames — called from Config lock mode.
function OUS.HideFlightTextFrames()
    timerTextFrame:Hide()
    timerTopFrame:Hide()
    timerBottomFrame:Hide()
end

local function ApplyFlightDimensions()
    local db = OdysseusDB and OdysseusDB.flightSettings
    if not db then return end

    local scale = db.scale or OUS.flightDefaults.scale
    local width = (db.width or OUS.flightDefaults.width) * scale
    local height = (db.height or OUS.flightDefaults.height) * scale

    timerBar:SetScale(1)
    timerBar:SetWidth(width)
    timerBar:SetHeight(height)

    timerTopFrame:SetSize(width + 100, 20 * scale)
    timerBottomFrame:SetSize(width + 100, 20 * scale)

    local fontScale = math.max(0.5, scale)
    local fName = db.fontName or "Friz Quadrata TT"
    local fPath = LSM:Fetch("font", fName) or LSM:Fetch("font", "Friz Quadrata TT") or "Fonts\\FRIZQT__.TTF"
    local fSize = db.fontSize or OUS.flightDefaults.fontSize

    OUS.timerText:SetFont(fPath, math.max(6, fSize * fontScale), "OUTLINE")
    OUS.timerTopText:SetFont(fPath, math.max(6, (fSize - 3) * fontScale), "OUTLINE")
    OUS.timerBottomText:SetFont(fPath, math.max(6, (fSize - 3) * fontScale), "OUTLINE")

    barMaxWidth = timerBar:GetWidth() or width
    if not isFlying then
        barFill:SetWidth(barMaxWidth)
    end
end

function OUS.ApplyFlightFonts()
    ApplyFlightDimensions()
end

function OUS.ApplyFlightSettings()
    local db = OdysseusDB and OdysseusDB.flightSettings
    if not db then return end

    ApplyFlightDimensions()
    OUS.ApplyFlightTexture()
    OUS.ApplyFlightBorder()

    local c = db.color or OUS.flightDefaults.color
    barFill:SetVertexColor(c.r or 1, c.g or 0.7, c.b or 0)
end

function OUS.SetFlightBarUnlocked(unlocked)
    OUS.isFlightBarUnlocked = unlocked == true
    timerBar:EnableMouse(OUS.isFlightBarUnlocked)

    if OUS.isFlightBarUnlocked then
        OUS.ApplyFlightSettings()
        OUS.PreviewFlightBar()
        OUS.timerTopText:SetText("Flight Master Preview")
        OUS.timerText:SetText("Drag to move")
        OUS.timerBottomText:SetText("Lock the bar when finished")
        timerBar:Show()
        borderFrame:Show()
        OUS.ShowFlightTextFrames()
    elseif not isFlying then
        timerBar:Hide()
        borderFrame:Hide()
        OUS.HideFlightTextFrames()
        OUS.timerText:SetText("")
        OUS.timerTopText:SetText("")
        OUS.timerBottomText:SetText("")
    end
end

function OUS.ResetFlightBarPosition()
    if not OdysseusDB or not OdysseusDB.flightSettings then return end

    timerBar:ClearAllPoints()
    timerBar:SetPoint("TOP", UIParent, "TOP", 0, -150)
    OdysseusDB.flightSettings.pos = {"TOP", "TOP", 0, -150}
    OUS.ApplyFlightBorder()
end

function OUS.ResetFlightBarAppearance()
    local db = OdysseusDB and OdysseusDB.flightSettings
    if not db then return end

    db.width = OUS.flightDefaults.width
    db.height = OUS.flightDefaults.height
    db.scale = OUS.flightDefaults.scale
    db.fontSize = OUS.flightDefaults.fontSize
    db.borderSize = OUS.flightDefaults.borderSize
    db.borderName = OUS.flightDefaults.borderName
    db.fontName = OUS.flightDefaults.fontName
    db.textureName = OUS.flightDefaults.textureName
    db.color = db.color or {}
    db.color.r = OUS.flightDefaults.color.r
    db.color.g = OUS.flightDefaults.color.g
    db.color.b = OUS.flightDefaults.color.b
    db.borderColor = db.borderColor or {}
    db.borderColor.r = OUS.flightDefaults.borderColor and OUS.flightDefaults.borderColor.r or 1
    db.borderColor.g = OUS.flightDefaults.borderColor and OUS.flightDefaults.borderColor.g or 1
    db.borderColor.b = OUS.flightDefaults.borderColor and OUS.flightDefaults.borderColor.b or 1

    OUS.ApplyFlightSettings()
end

function OUS.ApplyFlightBorder()
    local bName = OdysseusDB.flightSettings.borderName or "None"
    local bPath = LSM:Fetch("border", bName)
    local bSize = OdysseusDB.flightSettings.borderSize or 16
    local bc    = OdysseusDB.flightSettings.borderColor or { r = 1, g = 1, b = 1 }

    if bPath and bName ~= "None" then
        borderFrame:SetBackdrop({ edgeFile = bPath, edgeSize = bSize })
        borderFrame:SetBackdropBorderColor(bc.r, bc.g, bc.b, 1)
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
timerBar:SetClampedToScreen(true)
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

-- Tracks whether the taxi map is genuinely open, set by TAXIMAP_OPENED/CLOSED.
-- Guards against spurious TAXIMAP_OPENED fires during instance exit cleanup.
local taxiMapOpen = false

local mapTooltip = CreateFrame("Frame", "OdysseusMapTooltip", UIParent)
mapTooltip:SetFrameStrata("TOOLTIP")
mapTooltip:SetSize(180, 65)
mapTooltip:Hide()

-- Anchored textures avoid BackdropTemplate geometry arithmetic on secret dimensions.
mapTooltip.background = mapTooltip:CreateTexture(nil, "BACKGROUND")
mapTooltip.background:SetAllPoints()
mapTooltip.background:SetColorTexture(0.07, 0.05, 0.1, 0.95)

mapTooltip.borderTop = mapTooltip:CreateTexture(nil, "BORDER")
mapTooltip.borderTop:SetPoint("TOPLEFT")
mapTooltip.borderTop:SetPoint("TOPRIGHT")
mapTooltip.borderTop:SetHeight(1)
mapTooltip.borderTop:SetColorTexture(0.5, 0.3, 0.7, 1)

mapTooltip.borderBottom = mapTooltip:CreateTexture(nil, "BORDER")
mapTooltip.borderBottom:SetPoint("BOTTOMLEFT")
mapTooltip.borderBottom:SetPoint("BOTTOMRIGHT")
mapTooltip.borderBottom:SetHeight(1)
mapTooltip.borderBottom:SetColorTexture(0.5, 0.3, 0.7, 1)

mapTooltip.borderLeft = mapTooltip:CreateTexture(nil, "BORDER")
mapTooltip.borderLeft:SetPoint("TOPLEFT")
mapTooltip.borderLeft:SetPoint("BOTTOMLEFT")
mapTooltip.borderLeft:SetWidth(1)
mapTooltip.borderLeft:SetColorTexture(0.5, 0.3, 0.7, 1)

mapTooltip.borderRight = mapTooltip:CreateTexture(nil, "BORDER")
mapTooltip.borderRight:SetPoint("TOPRIGHT")
mapTooltip.borderRight:SetPoint("BOTTOMRIGHT")
mapTooltip.borderRight:SetWidth(1)
mapTooltip.borderRight:SetColorTexture(0.5, 0.3, 0.7, 1)

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

mapTooltip.distText = mapTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mapTooltip.distText:SetPoint("TOP", mapTooltip.costText, "BOTTOM", 0, -4)
mapTooltip.distText:SetTextColor(0.4, 0.8, 1.0)

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

--- Formats a yard distance as meters or km for display.
--- 1 yard = 0.9144 meters.
local YARDS_TO_METERS = 0.9144

local function FormatDist(yards)
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

local function UpdateCustomFlightTooltip()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.flightMaster then
        mapTooltip:Hide()
        return
    end

    if OdysseusDB.flightSettings.showTooltips == false then
        mapTooltip:Hide()
        return
    end

    if not taxiMapOpen then
        mapTooltip:Hide()
        return
    end

    local rawDest = _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"]:GetText()
    if not rawDest or rawDest == "" then
        mapTooltip:Hide()
        return
    end

    if IsAltKeyDown() then
        OUS.LogDebug("Flight", "Tooltip Hovered! Text found: " .. tostring(rawDest))
    end

    local destFull = CleanString(rawDest)
    local nodeID = nil
    local startFull = "Unknown"

    local startNodeIdx = nil
    local destNodeIdx  = nil
    for i = 1, NumTaxiNodes() do
        local rawNode = TaxiNodeName(i)
        if rawNode then
            local nodeName = CleanString(rawNode)
            if TaxiNodeGetType(i) == "CURRENT" then
                startFull = nodeName
                cachedStartFull = nodeName
                startNodeIdx = i
            elseif nodeName == destFull or string.find(destFull, nodeName, 1, true) then
                nodeID = i
                destNodeIdx = i
                destFull = nodeName
            end
        end
    end

    -- Cache node positions for distance display while taxi map is open
    cachedTotalDist = nil
    if startNodeIdx and destNodeIdx then
        local uiMapID = C_Map.GetBestMapForUnit("player")
        local allNodes = C_TaxiMap.GetAllTaxiNodes(uiMapID)
        if allNodes then
            local sPos, dPos
            for _, node in ipairs(allNodes) do
                if node.name then
                    local nn = CleanString(node.name)
                    if nn == startFull and node.position then
                        sPos = node.position
                    elseif nn == destFull and node.position then
                        dPos = node.position
                    end
                end
            end
            if sPos and dPos then
                -- Convert 0-1 map positions to world yards via Blizzard API
                local _, sWorld = C_Map.GetWorldPosFromMapPos(uiMapID, sPos)
                local _, dWorld = C_Map.GetWorldPosFromMapPos(uiMapID, dPos)
                if sWorld and dWorld then
                    cachedTotalDist = CalcWorldDist(sWorld.x, sWorld.y, dWorld.x, dWorld.y)
                end
            end
        end
    end

    if startFull == "Unknown" and cachedStartFull ~= "Unknown" then
        startFull = cachedStartFull
    end
    if startFull == "Unknown" then
        startFull = CleanString(GetMinimapZoneText() or GetZoneText())
    end

    if not nodeID then
        mapTooltip:Hide()
        if IsAltKeyDown() then
            OUS.LogDebug("Flight", "Failed to find matching nodeID for: " .. destFull)
        end
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

    do
        local okCost, rawCost = pcall(TaxiNodeCost, nodeID)
        if okCost and rawCost ~= nil then
            local okNumber, cost = pcall(tonumber, rawCost)
            if okNumber and type(cost) == "number" and cost > 0 then
                showCost = true
                costString = GetTaxiCostString(cost)
            end
        end
    end

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

    local distLine = cachedTotalDist and FormatDist(cachedTotalDist) or "Unknown"
    mapTooltip.distText:SetText("Distance: " .. distLine)

    local tooltipHeight = 48
    if showCost then tooltipHeight = tooltipHeight + 17 end
    tooltipHeight = tooltipHeight + 17   -- always show distance line
    mapTooltip:SetWidth(220)
    mapTooltip:SetHeight(tooltipHeight)

    mapTooltip:ClearAllPoints()

    if GameTooltip and GameTooltip:IsShown() then
        mapTooltip:SetPoint("TOP", GameTooltip, "BOTTOM", 0, -2)
    else
        local scale = UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        mapTooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale + 10)
    end

    mapTooltip:Show()
end

hooksecurefunc(GameTooltip, "Show", function()
    UpdateCustomFlightTooltip()
end)

hooksecurefunc(GameTooltip, "Hide", function()
    if taxiMapOpen then
        mapTooltip:Hide()
    end
end)

-- ==========================================
-- 5. FLIGHT DETECTION & TIMER UPDATE
-- ==========================================
local timerUpdateFrame = CreateFrame("Frame")
local lastTextUpdate = 0
local lastDistUpdate = 0

timerUpdateFrame:SetScript("OnUpdate", function()
    if not isFlying or OUS.isFlightBarUnlocked then return end
    local now         = GetTime()
    local timeElapsed = now - startTime
    local knownTime   = activeKnownTime

    if knownTime then
        local timeLeft = knownTime - timeElapsed
        if timeLeft > 0 then
            -- smooth fill: resize texture width directly each frame
            local ratio = math.max(0, math.min(1, timeLeft / knownTime))
            barFill:SetWidth(math.max(1, barMaxWidth * ratio))
            -- timer text updates once per second
            if now - lastTextUpdate >= 1.0 then
                lastTextUpdate = now
                OUS.timerText:SetText(string.format("Flying: %d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60)))
            end
            -- distance text updates every 0.1s
            if cachedTotalDist and now - lastDistUpdate >= 0.1 then
                lastDistUpdate = now
                local remaining = cachedTotalDist * ratio
                OUS.timerBottomText:SetText("Distance: " .. FormatDist(remaining))
            end
        else
            barFill:SetWidth(1)
            OUS.timerText:SetText("Arrival Imminent")
            if cachedTotalDist then
                OUS.timerBottomText:SetText("Distance: 0m")
            end
        end
    else
        -- unknown time — fill stays full
        barFill:SetWidth(barMaxWidth)
        if now - lastTextUpdate >= 1.0 then
            lastTextUpdate = now
            OUS.timerText:SetText(string.format("Flying: %d:%02d", math.floor(timeElapsed / 60), math.floor(timeElapsed % 60)))
        end
        if cachedTotalDist and now - lastDistUpdate >= 0.1 then
            lastDistUpdate = now
            local covered   = timeElapsed * 28
            local remaining = math.max(0, cachedTotalDist - covered)
            OUS.timerBottomText:SetText("Distance: " .. FormatDist(remaining))
        end
    end
end)
timerUpdateFrame:Hide() -- activated only while on taxi

local function HandleLiftoff()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.flightMaster then return end
    isFlying = true
    startTime = GetTime()
    OUS.ApplyFlightBorder()
    timerBar:Show()
    borderFrame:Show()
    timerTextFrame:Show()
    timerTopFrame:Show()
    timerBottomFrame:Show()
    OUS.timerTopText:SetText(currentStartFull .. " -> " .. currentDestFull)

    activeKnownTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)
    OUS.LogDebug("Flight", "Liftoff! Known Time: " .. (activeKnownTime and tostring(math.floor(activeKnownTime)) .. "s" or "Unknown"))

    if cachedTotalDist then
        OUS.timerBottomText:SetText("Distance: " .. FormatDist(cachedTotalDist))
        OUS.timerBottomText:Show()
    else
        OUS.timerBottomText:Hide()
    end

    -- barMaxWidth set at liftoff from actual rendered width
    barMaxWidth = timerBar:GetWidth() or 200
    barFill:SetWidth(barMaxWidth)

    timerUpdateFrame:Show()
end

local function HandleLanding()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.flightMaster then return end
    timerUpdateFrame:Hide()
    isFlying = false
    OUS.timerText:SetText("")
    OUS.timerTopText:SetText("")
    barFill:SetWidth(1)

    if not OUS.isFlightBarUnlocked then
        timerBar:Hide()
        borderFrame:Hide()
        timerTextFrame:Hide()
        timerTopFrame:Hide()
        timerBottomFrame:Hide()
    end

    local duration = math.floor((GetTime() - startTime) + 0.5)
    OUS.LogDebug("Flight", string.format("Landed. Total duration: %d seconds.", duration))

    if duration > 10 and currentDestFull ~= "Unknown" then
        OdysseusDB.flightSettings.times = OdysseusDB.flightSettings.times or {}
        local oldTime = GetKnownTimeFromDB(currentStartFull, currentDestFull, currentStartShort, currentDestShort)

        -- If we already know the full route time and the measured duration is much
        -- shorter, assume the player used Request Stop / landed early and do not
        -- overwrite the known full-route duration.
        if oldTime and duration < (oldTime - 10) then
            OUS.LogDebug("Flight", string.format(
            "Skipped saving flight time because measured duration looked like an early stop. Route=[%s -> %s], Known=%ds, Measured=%ds",
            currentStartFull, currentDestFull, oldTime, duration
            ))
        else
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
    end

    activeKnownTime = nil
    currentDestFull = "Unknown"
    currentStartFull = "Unknown"
    currentDestShort = "Unknown"
    currentStartShort = "Unknown"
    startTime = 0

    cachedTotalDist = nil
    OUS.timerBottomText:SetText("")
    OUS.timerBottomText:Hide()
end

-- ==========================================
-- 6. LOAD SAVED DATA
-- ==========================================
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "UNIT_FLAGS" then
        if UnitOnTaxi("player") and not isFlying then
            HandleLiftoff()
        elseif not UnitOnTaxi("player") and isFlying then
            HandleLanding()
        end
        return
    end

    if event == "TAXIMAP_CLOSED" then
        taxiMapOpen = false
        mapTooltip:Hide()
        return
    end

    if event == "TAXIMAP_OPENED" then
        taxiMapOpen = true
        return
    end

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
        barFill:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)

        OUS.LogDebug("Flight", "Database loaded successfully.")
    end

    if event == "PLAYER_LOGIN" then
        OUS.ApplyFlightSettings()
    end
end)
