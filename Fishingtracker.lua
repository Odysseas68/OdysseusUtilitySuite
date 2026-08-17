-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Fishingtracker.lua
-- Version : 2026.05.29
-- Desc    : Fishing session tracker — catch counts, session timer, loot log
-- ============================================================

-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: FISHING TRACKER
-- ==========================================
local addonName, OUS = ...
local f = CreateFrame("Frame")

-- State Variables
local isFishingActive = false
local lastCastTime = 0
local lastLootTime = 0

-- Timer State Variables
local sessionAccumulatedTime = 0
local sessionStartTime = 0
local sessionTimerActive = false
local sessionPaused = false
local fphUpdateTimer = 15

local currentZone = ""
local currentSubZone = ""

OUS.fishingDefaults = {
    autoCloseInactive = true,
    autoCloseMounted = true,
    autoCloseDelay = 30,
    alpha = 0.95,
    pos = {"RIGHT", "RIGHT", -250, 0}
}

local sessionData = {
    total = 0,
    currencyTotal = 0,
    catches = {},
    catchLinks = {}
}

-- ==========================================
-- 2. ZONE ID MAPPING FOR FISHING NAMES
-- ==========================================
local ZONE_FISHING_NAMES = {
    -- ======================================
    -- MIDNIGHT (Your current list)
    -- ======================================
    [2395] = "Midnight Fishing", [2567] = "Midnight Fishing", [2393] = "Midnight Fishing",
    [2443] = "Midnight Fishing", [2480] = "Midnight Fishing", [2405] = "Midnight Fishing",
    [2479] = "Midnight Fishing", [2437] = "Midnight Fishing", [2568] = "Midnight Fishing",
    [2531] = "Midnight Fishing", [2532] = "Midnight Fishing", [2529] = "Midnight Fishing",
    [2530] = "Midnight Fishing", [2444] = "Midnight Fishing", [2512] = "Midnight Fishing",

    -- ======================================
    -- KHAZ ALGAR (The War Within)
    -- ======================================
    [2274] = "Khaz Algar Fishing", -- Continent
    [2248] = "Khaz Algar Fishing", -- Isle of Dorn
    [2339] = "Khaz Algar Fishing", -- Dornogal
    [2214] = "Khaz Algar Fishing", -- The Ringing Deeps
    [2215] = "Khaz Algar Fishing", -- Hallowfall
    [2255] = "Khaz Algar Fishing", -- Azj-Kahet
    [2213] = "Khaz Algar Fishing", -- City of Threads
    [2451] = "Khaz Algar Fishing", -- Siren Isle

    -- ======================================
    -- DRAGON ISLES (Dragonflight)
    -- ======================================
    [1978] = "Isles Fishing", -- Continent
    [2022] = "Isles Fishing", -- The Waking Shores
    [2023] = "Isles Fishing", -- Ohn'ahran Plains
    [2024] = "Isles Fishing", -- The Azure Span
    [2025] = "Isles Fishing", -- Thaldraszus
    [2112] = "Isles Fishing", -- Valdrakken
    [2151] = "Isles Fishing", -- The Forbidden Reach
    [2133] = "Isles Fishing", -- Zaralek Cavern
    [2200] = "Isles Fishing", -- Emerald Dream

    -- ======================================
    -- SHADOWLANDS
    -- ======================================
    [1550] = "Shadowlands Fishing", -- Continent
    [1525] = "Shadowlands Fishing", -- Revendreth
    [1533] = "Shadowlands Fishing", -- Bastion
    [1536] = "Shadowlands Fishing", -- Maldraxxus
    [1543] = "Shadowlands Fishing", -- The Maw
    [1565] = "Shadowlands Fishing", -- Ardenweald
    [1670] = "Shadowlands Fishing", -- Oribos
    [1961] = "Shadowlands Fishing", -- Korthia
    [1970] = "Shadowlands Fishing", -- Zereth Mortis

    -- ======================================
    -- KUL TIRAS & ZANDALAR (Battle for Azeroth)
    -- ======================================
    [875] = "BfA Fishing", -- Zandalar Continent
    [876] = "BfA Fishing", -- Kul Tiras Continent
    [862] = "BfA Fishing", -- Zuldazar
    [863] = "BfA Fishing", -- Nazmir
    [864] = "BfA Fishing", -- Vol'dun
    [895] = "BfA Fishing", -- Tiragarde Sound
    [896] = "BfA Fishing", -- Drustvar
    [942] = "BfA Fishing", -- Stormsong Valley
    [1161] = "BfA Fishing", -- Boralus
    [1165] = "BfA Fishing", -- Dazar'alor
    [1355] = "BfA Fishing", -- Nazjatar
    [1462] = "BfA Fishing", -- Mechagon

    -- ======================================
    -- BROKEN ISLES (Legion)
    -- ======================================
    [619] = "Legion Fishing", -- Continent
    [627] = "Legion Fishing", -- Dalaran
    [630] = "Legion Fishing", -- Azsuna
    [634] = "Legion Fishing", -- Stormheim
    [641] = "Legion Fishing", -- Val'sharah
    [646] = "Legion Fishing", -- Broken Shore
    [650] = "Legion Fishing", -- Highmountain
    [680] = "Legion Fishing", -- Suramar
    [830] = "Legion Fishing", -- Krokuun
    [882] = "Legion Fishing", -- Mac'Aree
    [885] = "Legion Fishing", -- Antoran Wastes

    -- ======================================
    -- DRAENOR (Warlords of Draenor)
    -- ======================================
    [572] = "Draenor Fishing", -- Continent
    [525] = "Draenor Fishing", -- Frostfire Ridge
    [534] = "Draenor Fishing", -- Tanaan Jungle
    [535] = "Draenor Fishing", -- Talador
    [542] = "Draenor Fishing", -- Spires of Arak
    [543] = "Draenor Fishing", -- Gorgrond
    [550] = "Draenor Fishing", -- Nagrand
    [558] = "Draenor Fishing", -- Shadowmoon Valley

    -- ======================================
    -- PANDARIA (Mists of Pandaria)
    -- ======================================
    [424] = "Pandaria Fishing", -- Continent
    [371] = "Pandaria Fishing", -- The Jade Forest
    [376] = "Pandaria Fishing", -- Valley of the Four Winds
    [378] = "Pandaria Fishing", -- Krasarang Wilds
    [379] = "Pandaria Fishing", -- Kun-Lai Summit
    [388] = "Pandaria Fishing", -- Townlong Steppes
    [390] = "Pandaria Fishing", -- Vale of Eternal Blossoms
    [418] = "Pandaria Fishing", -- Dread Wastes
    [422] = "Pandaria Fishing", -- Timeless Isle

    -- ======================================
    -- CATACLYSM
    -- ======================================
    [198] = "Cataclysm Fishing", -- Mount Hyjal
    [201] = "Cataclysm Fishing", -- Kelp'thar Forest
    [203] = "Cataclysm Fishing", -- Vashj'ir
    [204] = "Cataclysm Fishing", -- Abyssal Depths
    [205] = "Cataclysm Fishing", -- Shimmering Expanse
    [241] = "Cataclysm Fishing", -- Twilight Highlands
    [245] = "Cataclysm Fishing", -- Tol Barad
    [249] = "Cataclysm Fishing", -- Uldum
    [207] = "Cataclysm Fishing", -- Deepholm

    -- ======================================
    -- NORTHREND (Wrath of the Lich King)
    -- ======================================
    [113] = "Northrend Fishing", -- Continent
    [114] = "Northrend Fishing", -- Borean Tundra
    [115] = "Northrend Fishing", -- Dragonblight
    [116] = "Northrend Fishing", -- Grizzly Hills
    [117] = "Northrend Fishing", -- Howling Fjord
    [118] = "Northrend Fishing", -- Icecrown
    [119] = "Northrend Fishing", -- Sholazar Basin
    [120] = "Northrend Fishing", -- The Storm Peaks
    [121] = "Northrend Fishing", -- Zul'Drak
    [125] = "Northrend Fishing", -- Dalaran (Old)

    -- ======================================
    -- OUTLAND (The Burning Crusade)
    -- ======================================
    [101] = "Outland Fishing", -- Continent
    [100] = "Outland Fishing", -- Hellfire Peninsula
    [102] = "Outland Fishing", -- Zangarmarsh
    [103] = "Outland Fishing", -- Terokkar Forest
    [104] = "Outland Fishing", -- Nagrand (Old)
    [105] = "Outland Fishing", -- Blade's Edge Mountains
    [107] = "Outland Fishing", -- Netherstorm
    [108] = "Outland Fishing", -- Shadowmoon Valley (Old)
    [111] = "Outland Fishing", -- Shattrath City

    -- ======================================
    -- SPECIAL CASES
    -- ======================================
    [407] = "Midnight Fishing", -- Darkmoon Island
}

local function FormatTimer(diff)
    local h = math.floor(diff / 3600)
    local m = math.floor((diff % 3600) / 60)
    local s = math.floor(diff % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function FishingDebug(msg)
    if OUS.LogDebug then
        OUS.LogDebug("Fishing", msg)
    end
end

local function IsCurrencyLink(link)
    return type(link) == "string" and link:find("|Hcurrency:") ~= nil
end

local function GetCurrencyInfoFromLinkSafe(link)
    if not link or type(link) ~= "string" then
        return nil
    end

    if C_CurrencyInfo.GetCurrencyInfoFromLink then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfoFromLink, link)
        if ok and info then
            return info
        end
    end

    local currencyID = tonumber(link:match("|Hcurrency:(%d+)"))
    if currencyID and C_CurrencyInfo.GetCurrencyInfo then
        return C_CurrencyInfo.GetCurrencyInfo(currencyID)
    end

    return nil
end

local function SetRowDisplayFromLink(row, link)
    row.itemLink = link

    if IsCurrencyLink(link) then
        local info = GetCurrencyInfoFromLinkSafe(link)
        local name = (info and info.name) or (type(link) == "string" and (link:match("%[(.-)%]") or "Unknown Currency")) or "Unknown Currency"
        local icon = (info and info.iconFileID) or 134400

        row.icon:SetTexture(icon)
        row.name:SetText("|cFFFFFFFF" .. name .. "|r")
        return
    end

    row.name:SetText("Loading...")
    row.icon:SetTexture(134400)

    local itemLink = link
    local item = Item:CreateFromItemLink(itemLink)
    item:ContinueOnItemLoad(function()
        if row.itemLink ~= itemLink then
            return
        end

        local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(itemLink)
        local _, _, _, hex = C_Item.GetItemQualityColor(itemQuality or 1)
        local colorPrefix = hex and ("|c" .. hex) or "|cFFFFFFFF"

        row.icon:SetTexture(itemIcon or 134400)
        row.name:SetText(colorPrefix .. (itemName or "Unknown") .. "|r")
    end)
end

-- ==========================================
-- 3. BUILD THE UI: MAIN FRAME
-- ==========================================
local mainFrame = CreateFrame("Frame", "OdysseusFishingMain", UIParent, "BackdropTemplate")
-- WIDENED: Increased from 340 to 360 to prevent text clipping
mainFrame:SetSize(370, 220)
mainFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -200)
mainFrame:Hide()

mainFrame:SetMovable(true)
mainFrame:SetClampedToScreen(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Always save as TOPLEFT so frame grows downward only
    local x, y = self:GetLeft(), self:GetTop()
    local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
    x = x * scale
    y = -(UIParent:GetHeight() - y * scale)
    if OdysseusDB and OdysseusDB.fishingSettings then
        OdysseusDB.fishingSettings.pos = {"TOPLEFT", "TOPLEFT", x, y}
    end
end)

mainFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
mainFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
mainFrame:SetBackdropBorderColor(0.2, 0.5, 0.8, 1)

-- Stats Button
local openStatsBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
openStatsBtn:SetSize(110, 22)
openStatsBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -12, -12)
openStatsBtn:SetText("Overall Stats")

-- Fishing Pole Icon
local poleBtn = CreateFrame("Button", nil, mainFrame)
poleBtn:SetSize(36, 36)
poleBtn:SetPoint("TOPLEFT", 12, -12)
poleBtn.icon = poleBtn:CreateTexture(nil, "BACKGROUND")
poleBtn.icon:SetAllPoints()
poleBtn.icon:SetTexture(136245)
poleBtn.border = poleBtn:CreateTexture(nil, "OVERLAY")
poleBtn.border:SetAllPoints()
poleBtn.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

poleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local hasItem = GameTooltip:SetInventoryItem("player", 28)
    if not hasItem then GameTooltip:SetInventoryItem("player", 16) end
    GameTooltip:Show()
end)
poleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Headers & Text
local zoneText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
zoneText:SetPoint("TOPLEFT", poleBtn, "TOPRIGHT", 10, -2)
zoneText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

local subZoneText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
subZoneText:SetPoint("TOPLEFT", zoneText, "BOTTOMLEFT", 0, -2)

local profText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profText:SetPoint("TOPLEFT", poleBtn, "BOTTOMLEFT", 0, -10)
profText:SetText("Fishing Level")

local skillText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
skillText:SetPoint("TOPLEFT", profText, "BOTTOMLEFT", 0, -2)

local divider1 = mainFrame:CreateTexture(nil, "ARTWORK")
divider1:SetColorTexture(0.2, 0.5, 0.8, 0.5)
divider1:SetHeight(1)
divider1:SetPoint("TOP", skillText, "BOTTOM", 0, -8)
divider1:SetPoint("LEFT", mainFrame, "LEFT", 12, 0)
divider1:SetPoint("RIGHT", mainFrame, "RIGHT", -12, 0)

-- Column Labels
local locStatsTitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
locStatsTitle:SetPoint("TOPLEFT", divider1, "BOTTOMLEFT", 0, -8)
locStatsTitle:SetText("Current Location Stats:")

local locTotalText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
locTotalText:SetPoint("TOPLEFT", locStatsTitle, "BOTTOMLEFT", 0, -4)
locTotalText:SetText("Fish caught in this location: |cFF87CEEB0|r")

local locCurrencyText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
locCurrencyText:SetPoint("TOPLEFT", locTotalText, "BOTTOMLEFT", 0, -4)
locCurrencyText:SetText("Currencies in this location: |cFF87CEEB0|r")

local mfColName = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mfColName:SetPoint("TOPLEFT", locCurrencyText, "BOTTOMLEFT", 0, -15)
mfColName:SetText("Fish Name")

local mfColPct = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mfColPct:SetPoint("TOP", mfColName, "TOP", 0, 0)
mfColPct:SetPoint("RIGHT", mainFrame, "RIGHT", -15, 0)
-- WIDENED: Increased to 55 to comfortably fit "100.0%"
mfColPct:SetWidth(55)
mfColPct:SetJustifyH("RIGHT")
mfColPct:SetText("Percent")

local mfColCount = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mfColCount:SetPoint("TOP", mfColName, "TOP", 0, 0)
mfColCount:SetPoint("RIGHT", mfColPct, "LEFT", -10, 0)
-- WIDENED: Increased to 45
mfColCount:SetWidth(45)
mfColCount:SetJustifyH("CENTER")
mfColCount:SetText("Count")

local divider2 = mainFrame:CreateTexture(nil, "ARTWORK")
divider2:SetColorTexture(0.2, 0.5, 0.8, 0.5)
divider2:SetHeight(1)
divider2:SetPoint("TOP", mfColName, "BOTTOM", 0, -4)
divider2:SetPoint("LEFT", mainFrame, "LEFT", 12, 0)
divider2:SetPoint("RIGHT", mainFrame, "RIGHT", -12, 0)

local lastCatchText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lastCatchText:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 12, 10)
lastCatchText:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -12, 10)
lastCatchText:SetJustifyH("LEFT")
lastCatchText:SetText("")

-- ==========================================
-- 4. BUILD THE UI: SESSION FRAME
-- ==========================================
local sessFrame = CreateFrame("Frame", "OdysseusFishingSession", mainFrame, "BackdropTemplate")
-- WIDENED: Increased from 320 to 340 to prevent text clipping
sessFrame:SetSize(350, 150)
sessFrame:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 5, 0)

sessFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
sessFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
sessFrame:SetBackdropBorderColor(0.2, 0.8, 0.4, 1)

local closeSessBtn = CreateFrame("Button", nil, sessFrame, "UIPanelCloseButton")
closeSessBtn:SetPoint("TOPRIGHT", sessFrame, "TOPRIGHT", -2, -2)
closeSessBtn:SetScript("OnClick", function() mainFrame:Hide() end)

local sessTitle = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sessTitle:SetPoint("TOP", sessFrame, "TOP", 0, -12)
sessTitle:SetText("Current Session")

local timerText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
timerText:SetPoint("TOP", sessTitle, "BOTTOM", 0, -4)
timerText:SetText("00:00:00")
timerText:SetTextColor(0.2, 0.8, 0.4)

-- Session Control Buttons
local buttonContainer = CreateFrame("Frame", nil, sessFrame)
buttonContainer:SetSize(170, 20)
buttonContainer:SetPoint("TOP", timerText, "BOTTOM", 0, -6)

local resetBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
resetBtn:SetSize(50, 20)
resetBtn:SetPoint("LEFT", 0, 0)
resetBtn:SetText("Reset")

local pauseBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
pauseBtn:SetSize(60, 20)
pauseBtn:SetPoint("LEFT", resetBtn, "RIGHT", 5, 0)
pauseBtn:SetText("Pause")

local stopBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
stopBtn:SetSize(50, 20)
stopBtn:SetPoint("LEFT", pauseBtn, "RIGHT", 5, 0)
stopBtn:SetText("Stop")

local fphText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fphText:SetPoint("BOTTOMLEFT", sessFrame, "BOTTOMLEFT", 10, 8)
fphText:SetTextColor(0.8, 0.8, 0.8)
fphText:SetText("0 fish/hr")

local closeTimerText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
closeTimerText:SetPoint("BOTTOMRIGHT", sessFrame, "BOTTOMRIGHT", -10, 8)
closeTimerText:SetTextColor(1, 0.5, 0.5)
closeTimerText:SetText("")

-- Button Scripts
resetBtn:SetScript("OnClick", function()
    sessionData.total = 0
    sessionData.currencyTotal = 0
    sessionData.catches = {}
    sessionAccumulatedTime = 0
    fphUpdateTimer = 15
    lastCatchText:SetText("")
    if sessionTimerActive then
        sessionStartTime = GetTime()
    end
    OUS.UpdateFishingUI()
    if OUS and OUS.LogDebug then
        OUS.LogDebug("Fishing", "Session timer reset.")
    end
end)

pauseBtn:SetScript("OnClick", function()
    if sessionTimerActive then
        sessionAccumulatedTime = sessionAccumulatedTime + (GetTime() - sessionStartTime)
        sessionTimerActive = false
        sessionPaused = true
        pauseBtn:SetText("Resume")
        if OUS and OUS.LogDebug then
            OUS.LogDebug("Fishing", "Session paused.")
        end
    else
        sessionStartTime = GetTime()
        sessionTimerActive = true
        sessionPaused = false
        pauseBtn:SetText("Pause")
        if OUS and OUS.LogDebug then
            OUS.LogDebug("Fishing", "Session resumed.")
        end
    end
end)

stopBtn:SetScript("OnClick", function()
    if sessionTimerActive then
        sessionAccumulatedTime = sessionAccumulatedTime + (GetTime() - sessionStartTime)
        sessionTimerActive = false
    end
    sessionPaused = true
    pauseBtn:SetText("Resume")
    if OUS and OUS.LogDebug then
        OUS.LogDebug("Fishing", "Session stopped.")
    end
end)

-- Session Columns
local sessDivider = sessFrame:CreateTexture(nil, "ARTWORK")
sessDivider:SetColorTexture(0.2, 0.8, 0.4, 0.5)
sessDivider:SetHeight(1)
sessDivider:SetPoint("TOP", buttonContainer, "BOTTOM", 0, -8)
sessDivider:SetPoint("LEFT", sessFrame, "LEFT", 12, 0)
sessDivider:SetPoint("RIGHT", sessFrame, "RIGHT", -12, 0)

local sessTotalText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sessTotalText:SetPoint("TOPLEFT", sessDivider, "BOTTOMLEFT", 0, -8)
sessTotalText:SetText("Total caught this session: |cFF87CEEB0|r")

local sessCurrencyText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sessCurrencyText:SetPoint("TOPLEFT", sessTotalText, "BOTTOMLEFT", 0, -4)
sessCurrencyText:SetText("Currencies this session: |cFF87CEEB0|r")

local sfColName = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfColName:SetPoint("TOPLEFT", sessCurrencyText, "BOTTOMLEFT", 0, -15)
sfColName:SetText("Fish Name")

local sfColPct = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfColPct:SetPoint("TOP", sfColName, "TOP", 0, 0)
sfColPct:SetPoint("RIGHT", sessFrame, "RIGHT", -15, 0)
-- WIDENED: Increased to 55 to comfortably fit "100.0%"
sfColPct:SetWidth(55)
sfColPct:SetJustifyH("RIGHT")
sfColPct:SetText("Percent")

local sfColCount = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfColCount:SetPoint("TOP", sfColName, "TOP", 0, 0)
sfColCount:SetPoint("RIGHT", sfColPct, "LEFT", -10, 0)
-- WIDENED: Increased to 45
sfColCount:SetWidth(45)
sfColCount:SetJustifyH("CENTER")
sfColCount:SetText("Count")

local sessDivider2 = sessFrame:CreateTexture(nil, "ARTWORK")
sessDivider2:SetColorTexture(0.2, 0.8, 0.4, 0.5)
sessDivider2:SetHeight(1)
sessDivider2:SetPoint("TOP", sfColName, "BOTTOM", 0, -4)
sessDivider2:SetPoint("LEFT", sessFrame, "LEFT", 12, 0)
sessDivider2:SetPoint("RIGHT", sessFrame, "RIGHT", -12, 0)


-- ==========================================
-- 5. BUILD THE UI: GLOBAL STATS FRAME
-- ==========================================
local statsFrame = CreateFrame("Frame", "OdysseusFishingStats", UIParent, "BackdropTemplate")
statsFrame:SetSize(400, 450)
statsFrame:SetPoint("CENTER")
statsFrame:Hide()

statsFrame:SetMovable(true)
statsFrame:SetClampedToScreen(true)
statsFrame:EnableMouse(true)
statsFrame:RegisterForDrag("LeftButton")
statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
statsFrame:SetScript("OnDragStop", statsFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, statsFrame:GetName())

statsFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
statsFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
statsFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

local closeStatsBtn = CreateFrame("Button", nil, statsFrame, "UIPanelCloseButton")
closeStatsBtn:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -2, -2)

local statsTabFish = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
statsTabFish:SetSize(100, 25)
statsTabFish:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -15)
statsTabFish:SetText("Fish")

local statsTabZone = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
statsTabZone:SetSize(100, 25)
statsTabZone:SetPoint("LEFT", statsTabFish, "RIGHT", 5, 0)
statsTabZone:SetText("Zone")

local statsTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
statsTitle:SetPoint("TOPLEFT", statsTabFish, "BOTTOMLEFT", 0, -15)
statsTitle:SetText("Overall Fishing Statistics Summary:")

local stat1 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
stat1:SetPoint("TOPLEFT", statsTitle, "BOTTOMLEFT", 0, -8)
local stat2 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
stat2:SetPoint("TOPLEFT", stat1, "BOTTOMLEFT", 0, -5)
local stat3 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
stat3:SetPoint("TOPLEFT", stat2, "BOTTOMLEFT", 0, -5)
local stat4 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
stat4:SetPoint("TOPLEFT", stat3, "BOTTOMLEFT", 0, -5)

local colHead1 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colHead1:SetPoint("TOPLEFT", stat4, "BOTTOMLEFT", 0, -30)
colHead1:SetText("Fish Name")

local colHead3 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colHead3:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -35, -135)
colHead3:SetWidth(60)
colHead3:SetJustifyH("RIGHT")
colHead3:SetText("Percent")

local colHead2 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colHead2:SetPoint("RIGHT", colHead3, "LEFT", -20, 0)
colHead2:SetWidth(60)
colHead2:SetJustifyH("CENTER")
colHead2:SetText("Count")

local statsDivider = statsFrame:CreateTexture(nil, "ARTWORK")
statsDivider:SetColorTexture(0.5, 0.3, 0.7, 0.5)
statsDivider:SetHeight(1)
statsDivider:SetPoint("TOPLEFT", colHead1, "BOTTOMLEFT", 0, -5)
statsDivider:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -15, -155)

local scrollFrame = CreateFrame("ScrollFrame", nil, statsFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", statsDivider, "BOTTOMLEFT", 0, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", statsFrame, "BOTTOMRIGHT", -30, 15)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(340, 1)

local statsRows = {}
local currentStatsTab = "Fish"

local function UpdateGlobalStatsFrame()
    if not statsFrame:IsShown() then return end
    if not OdysseusDB or not OdysseusDB.fishingSettings then return end

    local history = OdysseusFishingDB.history or {}
    local globalTotal = 0
    local globalCurrencyTotal = 0
    local globalFish = {}
    local uniqueZones = 0
    local uniqueSubZones = 0
    local zoneDataList = {}

    for zone, data in pairs(history) do
        uniqueZones = uniqueZones + 1
        local zoneTotal = data.total or 0
        globalTotal = globalTotal + zoneTotal
        globalCurrencyTotal = globalCurrencyTotal + (data.currencyTotal or 0)
        table.insert(zoneDataList, { name = zone, count = zoneTotal })

        if data.catches then
            for key, count in pairs(data.catches) do
                globalFish[key] = (globalFish[key] or 0) + count
                -- Store display link from any zone that has it
                if data.catchLinks and data.catchLinks[key] and not globalFishLinks then
                    globalFishLinks = {}
                end
                if data.catchLinks and data.catchLinks[key] then
                    globalFishLinks = globalFishLinks or {}
                    if not globalFishLinks[key] then
                        globalFishLinks[key] = data.catchLinks[key]
                    end
                end
            end
        end
        if data.subZones then
            for sz, _ in pairs(data.subZones) do
                uniqueSubZones = uniqueSubZones + 1
            end
        end
    end

    local fishTypesCount = 0
    local fishDataList = {}
    for key, count in pairs(globalFish) do
        fishTypesCount = fishTypesCount + 1
        local displayLink = (globalFishLinks and globalFishLinks[key]) or key
        table.insert(fishDataList, { link = displayLink, count = count })
    end

    stat1:SetText(string.format("Total Fish Caught: |cFF87CEEB%d|r", globalTotal))
    stat2:SetText(string.format("Total Currencies: |cFF87CEEB%d|r", globalCurrencyTotal))
    stat3:SetText(string.format("Total Fish Types: |cFF87CEEB%d|r", fishTypesCount))
    stat4:SetText(string.format("Total Zones / Sub-Zones: |cFF87CEEB%d|r / |cFF87CEEB%d|r", uniqueZones, uniqueSubZones))

    for _, row in ipairs(statsRows) do
        row:Hide()
    end

    local yOffset = 0
    if currentStatsTab == "Fish" then
        statsTitle:SetText("Overall Fishing Statistics Summary:")
        colHead1:SetText("Fish Name")
        table.sort(fishDataList, function(a, b) return a.count > b.count end)

        for i, data in ipairs(fishDataList) do
            if not statsRows[i] then
                local row = CreateFrame("Button", nil, scrollChild)
                row:SetSize(340, 20)

                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(16, 16)
                row.icon:SetPoint("LEFT", 0, 0)

                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
                row.name:SetWidth(180)
                row.name:SetJustifyH("LEFT")
                row.name:SetWordWrap(false)

                row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.pct:SetPoint("RIGHT", 0, 0)
                row.pct:SetWidth(60)
                row.pct:SetJustifyH("RIGHT")

                row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.count:SetPoint("RIGHT", row.pct, "LEFT", -20, 0)
                row.count:SetWidth(60)
                row.count:SetJustifyH("CENTER")

                statsRows[i] = row
            end

            local row = statsRows[i]
            row:SetScript("OnEnter", function(self)
                if self.itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(self.itemLink)
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)

            SetRowDisplayFromLink(row, data.link)
            row.count:SetText(data.count)

            local pct = (globalTotal > 0) and string.format("%.1f%%", (data.count / globalTotal) * 100) or "0%"
            row.pct:SetText(pct)

            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row:Show()
            yOffset = yOffset + 20
        end

    elseif currentStatsTab == "Zone" then
        statsTitle:SetText("Zone Statistics Summary:")
        colHead1:SetText("Zone Name")
        table.sort(zoneDataList, function(a, b) return a.count > b.count end)

        for i, data in ipairs(zoneDataList) do
            if not statsRows[i] then
                local row = CreateFrame("Button", nil, scrollChild)
                row:SetSize(340, 20)

                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.name:SetPoint("LEFT", 0, 0)
                row.name:SetWidth(180)
                row.name:SetJustifyH("LEFT")
                row.name:SetWordWrap(false)

                row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.pct:SetPoint("RIGHT", 0, 0)
                row.pct:SetWidth(60)
                row.pct:SetJustifyH("RIGHT")

                row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.count:SetPoint("RIGHT", row.pct, "LEFT", -20, 0)
                row.count:SetWidth(60)
                row.count:SetJustifyH("CENTER")
                statsRows[i] = row
            end

            local row = statsRows[i]
            if row.icon then row.icon:SetTexture(nil) end
            row.name:SetPoint("LEFT", 0, 0)
            row.name:SetText("|cFFFFFFFF" .. data.name .. "|r")
            row.count:SetText(data.count)

            local pct = (globalTotal > 0) and string.format("%.1f%%", (data.count / globalTotal) * 100) or "0%"
            row.pct:SetText(pct)
            row.itemLink = nil
            row:SetScript("OnEnter", nil)
            row:SetScript("OnLeave", nil)

            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row:Show()
            yOffset = yOffset + 20
        end
    end
    scrollChild:SetHeight(math.max(1, yOffset))
end

openStatsBtn:SetScript("OnClick", function()
    if statsFrame:IsShown() then
        statsFrame:Hide()
    else
        statsFrame:Show()
        UpdateGlobalStatsFrame()
        if OUS and OUS.LogDebug then
            OUS.LogDebug("Fishing", "Opened Global Stats panel.")
        end
    end
end)

statsTabFish:SetScript("OnClick", function() currentStatsTab = "Fish"; UpdateGlobalStatsFrame() end)
statsTabZone:SetScript("OnClick", function() currentStatsTab = "Zone"; UpdateGlobalStatsFrame() end)

-- ==========================================
-- 6. ROW CREATION (3-COLUMN LAYOUT)
-- ==========================================
local mainRows = {}
local sessRows = {}

local function CreateFishRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(parent:GetWidth() - 24, 16)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 0, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    -- WIDENED: Adjusted to make sure the item name doesn't bleed into the newly widened percent/count columns
    row.name:SetWidth(parent:GetWidth() - 130)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.pct:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    -- WIDENED: 55px width
    row.pct:SetWidth(55)
    row.pct:SetJustifyH("RIGHT")

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.count:SetPoint("RIGHT", row.pct, "LEFT", -10, 0)
    -- WIDENED: 45px width
    row.count:SetWidth(45)
    row.count:SetJustifyH("CENTER")

    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

-- ==========================================
-- 7. DATA LOGIC & UI UPDATE
-- ==========================================
function OUS.UpdateFishingAlpha()
    if not OdysseusDB or not OdysseusDB.fishingSettings then return end
    local alpha = OdysseusDB.fishingSettings.alpha or 0.95

    -- Force master frames to solid opacity to cure any previous ghosting
    if mainFrame then mainFrame:SetAlpha(1.0) end
    if statsFrame then statsFrame:SetAlpha(1.0) end

    -- Apply transparency purely to the backdrop colors
    if mainFrame then mainFrame:SetBackdropColor(0.07, 0.05, 0.1, alpha) end
    if sessFrame then sessFrame:SetBackdropColor(0.07, 0.05, 0.1, alpha) end
    if statsFrame then statsFrame:SetBackdropColor(0.07, 0.05, 0.1, alpha) end
end

function OUS.UpdateFishingUI()
    if not mainFrame:IsShown() then return end
    if not OdysseusDB or not OdysseusDB.fishingSettings then return end

    currentZone = GetRealZoneText() or "Unknown Zone"
    currentSubZone = GetMinimapZoneText() or ""

    zoneText:SetText(currentZone)
    subZoneText:SetText(currentSubZone)

    OdysseusFishingDB.history[currentZone] = OdysseusFishingDB.history[currentZone] or { total = 0, currencyTotal = 0, catches = {}, subZones = {} }
    local areaData = OdysseusFishingDB.history[currentZone]

    locTotalText:SetText(string.format("Fish caught in this location: |cFF87CEEB%d|r", areaData.total or 0))
    locCurrencyText:SetText(string.format("Currencies in this location: |cFF87CEEB%d|r", areaData.currencyTotal or 0))

    sessTotalText:SetText(string.format("Total caught this session: |cFF87CEEB%d|r", sessionData.total or 0))
    sessCurrencyText:SetText(string.format("Currencies this session: |cFF87CEEB%d|r", sessionData.currencyTotal or 0))

    local mapID = C_Map.GetBestMapForUnit("player")
    local customProfName = mapID and ZONE_FISHING_NAMES[mapID]

    local prof1, prof2, _, fishProf = GetProfessions()
    if fishProf then
        local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(fishProf)
        if not customProfName and name == "Fishing" then
            profText:SetText("Classic Fishing")
        else
            profText:SetText(customProfName or name)
        end
        local modStr = ""
        if skillModifier > 0 then modStr = "|cFF00FF00+" .. skillModifier .. "|r" end
        skillText:SetText(string.format("(Skill: |cFFFFFF00%d|r%s)/%d", skillLevel, modStr, maxSkillLevel))
    else
        profText:SetText("Fishing Not Found")
        skillText:SetText("")
    end

    local poleTex = GetInventoryItemTexture("player", 28) or GetInventoryItemTexture("player", 16) or 136245
    poleBtn.icon:SetTexture(poleTex)

    -- Update Main Rows
    for _, row in ipairs(mainRows) do
        row:Hide()
    end

    local yOffset = -180
    local rowIndex = 1

    if areaData.catches then
        local sortedAreaCatches = {}
        for key, count in pairs(areaData.catches) do
            local displayLink = (areaData.catchLinks and areaData.catchLinks[key]) or key
            table.insert(sortedAreaCatches, { link = displayLink, count = count })
        end
        table.sort(sortedAreaCatches, function(a, b) return a.count > b.count end)

        for _, data in ipairs(sortedAreaCatches) do
            if not mainRows[rowIndex] then
                mainRows[rowIndex] = CreateFishRow(mainFrame)
            end
            local row = mainRows[rowIndex]

            SetRowDisplayFromLink(row, data.link)

            local pct = (areaData.total > 0) and string.format("%.1f%%", (data.count / areaData.total) * 100) or "0%"
            row.count:SetText(data.count)
            row.pct:SetText(pct)

            row:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, yOffset)
            row:Show()

            yOffset = yOffset - 18
            rowIndex = rowIndex + 1
        end
    end
    local newHeight = math.max(220, math.abs(yOffset) + 35)
    if mainFrame:GetHeight() ~= newHeight then
        mainFrame:SetHeight(newHeight)
        -- Re-anchor after resize to prevent bidirectional growth
        local p = OdysseusDB and OdysseusDB.fishingSettings and OdysseusDB.fishingSettings.pos
        mainFrame:ClearAllPoints()
        if p then
            mainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", p[3], p[4])
        else
            mainFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -200)
        end
    end

    -- Update Session Rows
    for _, row in ipairs(sessRows) do
        row:Hide()
    end

    local sessY = -155
    local sessIdx = 1

    local sortedSessionCatches = {}
    for key, count in pairs(sessionData.catches) do
        local displayLink = sessionData.catchLinks[key] or key
        table.insert(sortedSessionCatches, { link = displayLink, count = count })
    end
    table.sort(sortedSessionCatches, function(a, b) return a.count > b.count end)

    for _, data in ipairs(sortedSessionCatches) do
        if not sessRows[sessIdx] then
            sessRows[sessIdx] = CreateFishRow(sessFrame)
        end
        local row = sessRows[sessIdx]

        SetRowDisplayFromLink(row, data.link)

        local pct = (sessionData.total > 0) and string.format("%.1f%%", (data.count / sessionData.total) * 100) or "0%"
        row.count:SetText(data.count)
        row.pct:SetText(pct)

        row:SetPoint("TOPLEFT", sessFrame, "TOPLEFT", 12, sessY)
        row:Show()

        sessY = sessY - 18
        sessIdx = sessIdx + 1
    end
    sessFrame:SetHeight(math.max(150, math.abs(sessY) + 30))

    if statsFrame:IsShown() then UpdateGlobalStatsFrame() end
end

local function RecordCatch(itemLink, quantity)
    if not OdysseusDB or not OdysseusDB.fishingSettings then return end
    quantity = quantity or 1

    local exactName = string.match(itemLink, "%[(.-)%]") or "Unknown"
    local itemID = string.match(itemLink, "item:(%d+)")
    local catchKey = itemID or itemLink
    local zone = GetRealZoneText() or "Unknown Zone"
    local subZone = GetMinimapZoneText() or ""

    local item = Item:CreateFromItemLink(itemLink)
    item:ContinueOnItemLoad(function()
        local itemName, _, itemQuality = C_Item.GetItemInfo(itemLink)
        local _, _, _, hex = C_Item.GetItemQualityColor(itemQuality or 1)
        local colorPrefix = hex and ("|c" .. hex) or "|cFFFFFFFF"
        local coloredName = colorPrefix .. "[" .. exactName .. "]|r"

        -- Filter out trash (Grey items)
        if itemQuality and itemQuality == 0 then
            lastCatchText:SetText(coloredName .. " (|cFFFFFFFFx" .. quantity .. "|r) |cFF87CEEB[ID: " .. tostring(itemID) .. "]|r |cFFFF0000not saved.|r")
            OUS.LogDebug("Fishing", "Ignored trash catch: " .. exactName)
            OUS.UpdateFishingUI()
            return
        end

        lastCatchText:SetText(coloredName .. " (|cFFFFFFFFx" .. quantity .. "|r) |cFF87CEEB[ID: " .. tostring(itemID) .. "]|r |cFF87CEEBsaved.|r")
        OUS.LogDebug("Fishing", "Saved catch: " .. exactName .. " x" .. quantity)

        OdysseusFishingDB.history[zone] = OdysseusFishingDB.history[zone] or { total = 0, currencyTotal = 0, catches = {}, catchLinks = {}, subZones = {} }
        OdysseusFishingDB.history[zone].subZones = OdysseusFishingDB.history[zone].subZones or {}
        OdysseusFishingDB.history[zone].total = (OdysseusFishingDB.history[zone].total or 0) + quantity
        OdysseusFishingDB.history[zone].catches[catchKey] = (OdysseusFishingDB.history[zone].catches[catchKey] or 0) + quantity
        if not OdysseusFishingDB.history[zone].catchLinks then
            OdysseusFishingDB.history[zone].catchLinks = {}
        end
        if not OdysseusFishingDB.history[zone].catchLinks[catchKey] then
            OdysseusFishingDB.history[zone].catchLinks[catchKey] = itemLink
        end
        if subZone ~= "" then
            OdysseusFishingDB.history[zone].subZones[subZone] = true
        end

        sessionData.total = (sessionData.total or 0) + quantity
        sessionData.catches[catchKey] = (sessionData.catches[catchKey] or 0) + quantity
        if not sessionData.catchLinks[catchKey] then
            sessionData.catchLinks[catchKey] = itemLink
        end

        fphUpdateTimer = 15
        OUS.UpdateFishingUI()
    end)
end

local function RecordCurrencyCatch(currencyID, quantity)
    if not OdysseusDB or not OdysseusDB.fishingSettings then return end
    if not currencyID then return end

    quantity = quantity or 1

    local currencyLink = nil
    if C_CurrencyInfo.GetCurrencyLink then
        currencyLink = C_CurrencyInfo.GetCurrencyLink(currencyID)
    elseif GetCurrencyLink then
        currencyLink = GetCurrencyLink(currencyID)
    end

    local info = C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID) or nil
    local currencyName = (info and info.name) or ("Currency " .. tostring(currencyID))
    local displayLink = currencyLink or ("currency:" .. tostring(currencyID))

    lastCatchText:SetText("|cFFFFFFFF[" .. currencyName .. "]|r (|cFFFFFFFFx" .. quantity .. "|r) |cFF87CEEB[Currency ID: " .. tostring(currencyID) .. "]|r |cFF87CEEBsaved.|r")
    OUS.LogDebug("Fishing", "Saved currency catch: " .. currencyName .. " x" .. quantity)

    local zone = GetRealZoneText() or "Unknown Zone"
    local subZone = GetMinimapZoneText() or ""

    OdysseusFishingDB.history[zone] = OdysseusFishingDB.history[zone] or { total = 0, currencyTotal = 0, catches = {}, catchLinks = {}, subZones = {} }
    OdysseusFishingDB.history[zone].subZones = OdysseusFishingDB.history[zone].subZones or {}
    OdysseusFishingDB.history[zone].currencyTotal = (OdysseusFishingDB.history[zone].currencyTotal or 0) + quantity
    OdysseusFishingDB.history[zone].catches[displayLink] = (OdysseusFishingDB.history[zone].catches[displayLink] or 0) + quantity

    if subZone ~= "" then
        OdysseusFishingDB.history[zone].subZones[subZone] = true
    end

    sessionData.currencyTotal = (sessionData.currencyTotal or 0) + quantity
    sessionData.catches[displayLink] = (sessionData.catches[displayLink] or 0) + quantity

    fphUpdateTimer = 15
    OUS.UpdateFishingUI()
end

-- ==========================================
-- 8. CORE EVENT LISTENERS
-- ==========================================
local FISHING_SPELL_IDS = {
    [131476] = true, [131474] = true, [7620] = true, [1224771] = true,
}

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("UNIT_SPELLCAST_START")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
f:RegisterEvent("UNIT_SPELLCAST_STOP")
f:RegisterEvent("LOOT_READY")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local arg1 = ...
        if arg1 == addonName then
            OdysseusDB = OdysseusDB or {}
            OdysseusDB.modules = OdysseusDB.modules or {}
            OdysseusDB.fishingSettings = OdysseusDB.fishingSettings or {}

            for k, v in pairs(OUS.fishingDefaults) do
                if OdysseusDB.fishingSettings[k] == nil then
                    if type(v) == "table" then
                        OdysseusDB.fishingSettings[k] = OUS.DeepCopyTable(v)
                    else
                        OdysseusDB.fishingSettings[k] = v
                    end
                end
            end

            lastCastTime = GetTime()

            if OdysseusDB.fishingSettings.pos then
                local p = OdysseusDB.fishingSettings.pos
                mainFrame:ClearAllPoints()
                mainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", p[3], p[4])
            end

            if OUS.UpdateFishingAlpha then
                OUS.UpdateFishingAlpha()
            end
        end
        return
    end

    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fishingTracker then
        return
    end

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit, _, spellID = ...
        if unit == "player" and FISHING_SPELL_IDS[spellID] then
            -- The 3-minute grace period check
            if (GetTime() - lastCastTime) > 180 then
                sessionData.total = 0
                sessionData.currencyTotal = 0
                sessionData.catches = {}
                sessionAccumulatedTime = 0
                fphUpdateTimer = 15
                lastCatchText:SetText("")
                sessionPaused = false
                pauseBtn:SetText("Pause")
                if OUS and OUS.LogDebug then
                    OUS.LogDebug("Fishing", "Session auto-reset after 3+ minutes of inactivity.")
                end
            end

            isFishingActive = true
            lastCastTime = GetTime()

            -- Auto-resume the timer
            if not sessionTimerActive then
                sessionStartTime = GetTime()
                sessionTimerActive = true
                sessionPaused = false
                pauseBtn:SetText("Pause")
            end

            if not mainFrame:IsShown() then
                mainFrame:Show()
                OUS.UpdateFishingUI()
                if OUS and OUS.LogDebug then
                    OUS.LogDebug("Fishing", "Cast detected. Tracker opened/woken up.")
                end
            end
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_STOP" then
        local unit, _, spellID = ...
        if unit == "player" and FISHING_SPELL_IDS[spellID] then
            isFishingActive = false
            lastCastTime = GetTime()
        end

    elseif event == "LOOT_READY" then
        if GetTime() - lastLootTime < 1.0 then
            return
        end

        local fishingRecently = (GetTime() - lastCastTime) <= 3.0
        local isFishingLootEvent = false

        if IsFishingLoot and IsFishingLoot() then
            isFishingLootEvent = true
        elseif isFishingActive or fishingRecently then
            isFishingLootEvent = true
        end

        if isFishingLootEvent then
            lastLootTime = GetTime()
            lastCastTime = GetTime()

            local numItems = GetNumLootItems()
            for i = 1, numItems do
                local slotType = GetLootSlotType(i)
                local itemLink = GetLootSlotLink(i)
                local _, _, quantity, currencyID = GetLootSlotInfo(i)

                if slotType == 1 and itemLink then
                    RecordCatch(itemLink, quantity or 1)
                elseif currencyID then
                    RecordCurrencyCatch(currencyID, quantity or 1)
                end
            end

            if not mainFrame:IsShown() then
                mainFrame:Show()
                OUS.UpdateFishingUI()
            end
        end
    end
end)

-- ==========================================
-- 9. TIMER & AUTO-CLOSE LOOP
-- ==========================================
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fishingTracker then return end
    if not mainFrame:IsShown() then return end

    local diff = 0
    if sessionTimerActive then
        diff = sessionAccumulatedTime + (GetTime() - sessionStartTime)
        timerText:SetText(FormatTimer(diff))
    else
        diff = sessionAccumulatedTime
        timerText:SetText(FormatTimer(diff))
    end

    fphUpdateTimer = fphUpdateTimer + elapsed
    if fphUpdateTimer >= 15 then
        if diff > 0 then
            local fph = math.floor((sessionData.total / diff) * 3600)
            fphText:SetText(string.format("%d fish/hr", fph))
        else
            fphText:SetText("0 fish/hr")
        end
        fphUpdateTimer = 0
    end

    local delay = OdysseusDB.fishingSettings.autoCloseDelay or 30
    local shouldCountdown = false

    if not sessionPaused then
        if OdysseusDB.fishingSettings.autoCloseInactive then
            shouldCountdown = true
        elseif OdysseusDB.fishingSettings.autoCloseMounted and IsMounted() then
            shouldCountdown = true
        end
    end

    if not shouldCountdown or isFishingActive then
        lastCastTime = GetTime()
        closeTimerText:SetText("")
    else
        local inactiveTime = GetTime() - lastCastTime
        local remaining = delay - inactiveTime

        if remaining <= 0 then
            isFishingActive = false
            if sessionTimerActive then
                sessionAccumulatedTime = sessionAccumulatedTime + (GetTime() - sessionStartTime)
                sessionTimerActive = false
            end
            sessionPaused = true
            pauseBtn:SetText("Resume")
            mainFrame:Hide()
            closeTimerText:SetText("")
            if OUS and OUS.LogDebug then
                OUS.LogDebug("Fishing", "Tracker auto-closed due to inactivity/mounting.")
            end
        else
            if remaining <= 10 and (sessionData.total > 0 or sessionTimerActive) then
                closeTimerText:SetText(string.format("Closing in: %ds", math.ceil(remaining)))
            else
                closeTimerText:SetText("")
            end
        end
    end
end)

-- ==========================================
-- 10. TOGGLE API
-- ==========================================
function OUS.ToggleFishingTracker()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fishingTracker then return end

    if mainFrame:IsShown() then
        mainFrame:Hide()
        if OUS and OUS.LogDebug then
            OUS.LogDebug("Fishing", "Tracker manually hidden.")
        end
    else
        mainFrame:Show()
        lastCastTime = GetTime()
        fphUpdateTimer = 15
        if sessionData.total == 0 and not sessionTimerActive and not sessionPaused then
            sessionStartTime = GetTime()
            sessionTimerActive = true
            pauseBtn:SetText("Pause")
        end
        OUS.UpdateFishingUI()
        if OUS and OUS.LogDebug then
            OUS.LogDebug("Fishing", "Tracker manually opened.")
        end
    end
end