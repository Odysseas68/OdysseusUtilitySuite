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

local sessionData = {
    total = 0,
    catches = {}
}

-- ==========================================
-- ZONE ID MAPPING FOR FISHING NAMES
-- ==========================================
local ZONE_FISHING_NAMES = {
    -- Midnight
    [2395] = "Midnight Fishing", [2567] = "Midnight Fishing", [2393] = "Midnight Fishing",
    [2443] = "Midnight Fishing", [2480] = "Midnight Fishing", [2405] = "Midnight Fishing",
    [2479] = "Midnight Fishing", [2437] = "Midnight Fishing", [2568] = "Midnight Fishing",
    [2531] = "Midnight Fishing", [2532] = "Midnight Fishing", [2529] = "Midnight Fishing",
    [2530] = "Midnight Fishing", 
    -- Khaz Algar
    [2451] = "Khaz Algar Fishing",
    -- Cataclysm
    [198] = "Cataclysm Fishing", [201] = "Cataclysm Fishing", [203] = "Cataclysm Fishing",
    [204] = "Cataclysm Fishing", [205] = "Cataclysm Fishing", [241] = "Cataclysm Fishing",
    -- Legion
    [41] = "Legion Fishing", 
}

local function FormatTimer(diff)
    local h = math.floor(diff / 3600)
    local m = math.floor((diff % 3600) / 60)
    local s = math.floor(diff % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- ==========================================
-- 1. BUILD THE UI: MAIN FRAME
-- ==========================================
local mainFrame = CreateFrame("Frame", "OdysseusFishingMain", UIParent, "BackdropTemplate")
mainFrame:SetSize(340, 220) 
mainFrame:SetPoint("RIGHT", UIParent, "RIGHT", -250, 0)
mainFrame:Hide()
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    if OdysseusDB and OdysseusDB.fishingSettings then
        OdysseusDB.fishingSettings.pos = {point, relativePoint, xOfs, yOfs}
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

-- STATS BUTTON
local openStatsBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
openStatsBtn:SetSize(110, 22)
openStatsBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -12, -12)
openStatsBtn:SetText("Overall Stats")

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

local locStatsTitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
locStatsTitle:SetPoint("TOPLEFT", divider1, "BOTTOMLEFT", 0, -8)
locStatsTitle:SetText("Current Location Stats:")

local locTotalText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
locTotalText:SetPoint("TOPLEFT", locStatsTitle, "BOTTOMLEFT", 0, -4)
locTotalText:SetText("Fish caught in this location: |cFF87CEEB0|r")

local mfColName = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mfColName:SetPoint("TOPLEFT", locTotalText, "BOTTOMLEFT", 0, -20)
mfColName:SetText("Fish Name")

local mfColPct = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mfColPct:SetPoint("TOP", mfColName, "TOP", 0, 0)
mfColPct:SetPoint("RIGHT", mainFrame, "RIGHT", -15, 0)
mfColPct:SetWidth(45)
mfColPct:SetJustifyH("RIGHT")
mfColPct:SetText("Percent")

local mfColCount = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mfColCount:SetPoint("TOP", mfColName, "TOP", 0, 0)
mfColCount:SetPoint("RIGHT", mfColPct, "LEFT", -15, 0)
mfColCount:SetWidth(40)
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
-- 2. BUILD THE UI: SESSION FRAME
-- ==========================================
local sessFrame = CreateFrame("Frame", "OdysseusFishingSession", mainFrame, "BackdropTemplate")
sessFrame:SetSize(320, 150) 
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
closeSessBtn:SetScript("OnClick", function()
    mainFrame:Hide() 
end)

local sessTitle = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sessTitle:SetPoint("TOP", sessFrame, "TOP", 0, -12)
sessTitle:SetText("Current Session")

local timerText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
timerText:SetPoint("TOP", sessTitle, "BOTTOM", 0, -4)
timerText:SetText("00:00:00")
timerText:SetTextColor(0.2, 0.8, 0.4)

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

resetBtn:SetScript("OnClick", function()
    sessionData.total = 0
    sessionData.catches = {}
    sessionAccumulatedTime = 0
    fphUpdateTimer = 15 
    lastCatchText:SetText("")
    if sessionTimerActive then sessionStartTime = GetTime() end
    OUS.UpdateFishingUI()
end)

pauseBtn:SetScript("OnClick", function()
    if sessionTimerActive then
        sessionAccumulatedTime = sessionAccumulatedTime + (GetTime() - sessionStartTime)
        sessionTimerActive = false
        sessionPaused = true
        pauseBtn:SetText("Resume")
    else
        sessionStartTime = GetTime()
        sessionTimerActive = true
        sessionPaused = false
        pauseBtn:SetText("Pause")
    end
end)

stopBtn:SetScript("OnClick", function()
    if sessionTimerActive then
        sessionAccumulatedTime = sessionAccumulatedTime + (GetTime() - sessionStartTime)
        sessionTimerActive = false
    end
    sessionPaused = true
    pauseBtn:SetText("Resume")
end)

local sessDivider = sessFrame:CreateTexture(nil, "ARTWORK")
sessDivider:SetColorTexture(0.2, 0.8, 0.4, 0.5)
sessDivider:SetHeight(1)
sessDivider:SetPoint("TOP", buttonContainer, "BOTTOM", 0, -8)
sessDivider:SetPoint("LEFT", sessFrame, "LEFT", 12, 0)
sessDivider:SetPoint("RIGHT", sessFrame, "RIGHT", -12, 0)

local sessTotalText = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sessTotalText:SetPoint("TOPLEFT", sessDivider, "BOTTOMLEFT", 0, -8)
sessTotalText:SetText("Total caught this session: |cFF87CEEB0|r")

local sfColName = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfColName:SetPoint("TOPLEFT", sessTotalText, "BOTTOMLEFT", 0, -15)
sfColName:SetText("Fish Name")

local sfColPct = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfColPct:SetPoint("TOP", sfColName, "TOP", 0, 0)
sfColPct:SetPoint("RIGHT", sessFrame, "RIGHT", -15, 0)
sfColPct:SetWidth(45)
sfColPct:SetJustifyH("RIGHT")
sfColPct:SetText("Percent")

local sfColCount = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfColCount:SetPoint("TOP", sfColName, "TOP", 0, 0)
sfColCount:SetPoint("RIGHT", sfColPct, "LEFT", -15, 0)
sfColCount:SetWidth(40)
sfColCount:SetJustifyH("CENTER")
sfColCount:SetText("Count")

local sessDivider2 = sessFrame:CreateTexture(nil, "ARTWORK")
sessDivider2:SetColorTexture(0.2, 0.8, 0.4, 0.5)
sessDivider2:SetHeight(1)
sessDivider2:SetPoint("TOP", sfColName, "BOTTOM", 0, -4)
sessDivider2:SetPoint("LEFT", sessFrame, "LEFT", 12, 0)
sessDivider2:SetPoint("RIGHT", sessFrame, "RIGHT", -12, 0)


-- ==========================================
-- 3. BUILD THE UI: GLOBAL STATS FRAME
-- ==========================================
local statsFrame = CreateFrame("Frame", "OdysseusFishingStats", UIParent, "BackdropTemplate")
statsFrame:SetSize(400, 450)
statsFrame:SetPoint("CENTER")
statsFrame:Hide()
statsFrame:SetMovable(true)
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

local colHead1 = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colHead1:SetPoint("TOPLEFT", stat3, "BOTTOMLEFT", 0, -30)
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
    
    local history = OdysseusDB.fishingSettings.history or {}
    local globalTotal = 0
    local globalFish = {}
    local uniqueZones = 0
    local uniqueSubZones = 0
    
    local zoneDataList = {}
    
    for zone, data in pairs(history) do
        uniqueZones = uniqueZones + 1
        local zoneTotal = data.total or 0
        globalTotal = globalTotal + zoneTotal
        table.insert(zoneDataList, { name = zone, count = zoneTotal })
        
        if data.catches then
            for link, count in pairs(data.catches) do
                globalFish[link] = (globalFish[link] or 0) + count
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
    for link, count in pairs(globalFish) do
        fishTypesCount = fishTypesCount + 1
        table.insert(fishDataList, { link = link, count = count })
    end
    
    stat1:SetText(string.format("Total Fish Caught: |cFF87CEEB%d|r", globalTotal))
    stat2:SetText(string.format("Total Fish Types: |cFF87CEEB%d|r", fishTypesCount))
    stat3:SetText(string.format("Total Zones / Sub-Zones: |cFF87CEEB%d|r / |cFF87CEEB%d|r", uniqueZones, uniqueSubZones))
    
    for _, row in ipairs(statsRows) do row:Hide() end
    
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
                
                row:SetScript("OnEnter", function(self)
                    if self.itemLink then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(self.itemLink)
                        GameTooltip:Show()
                    end
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
                statsRows[i] = row
            end
            
            local row = statsRows[i]
            local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(data.link)
            local hex = select(4, GetItemQualityColor(itemQuality or 1))
            local colorPrefix = hex and ("|c" .. hex) or "|cFFFFFFFF"
            
            row.icon:SetTexture(itemIcon)
            row.name:SetText(colorPrefix .. (itemName or "Unknown") .. "|r")
            row.count:SetText(data.count)
            
            local pct = (globalTotal > 0) and string.format("%.1f%%", (data.count / globalTotal) * 100) or "0%"
            row.pct:SetText(pct)
            row.itemLink = data.link
            
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
            
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row:Show()
            yOffset = yOffset + 20
        end
    end
    scrollChild:SetHeight(math.max(1, yOffset))
end

openStatsBtn:SetScript("OnClick", function()
    if statsFrame:IsShown() then statsFrame:Hide() else
        statsFrame:Show()
        UpdateGlobalStatsFrame()
    end
end)

statsTabFish:SetScript("OnClick", function() currentStatsTab = "Fish"; UpdateGlobalStatsFrame() end)
statsTabZone:SetScript("OnClick", function() currentStatsTab = "Zone"; UpdateGlobalStatsFrame() end)

-- ==========================================
-- 4. ROW CREATION (3-COLUMN LAYOUT)
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
    row.name:SetWidth(parent:GetWidth() - 110) 
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    
    row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.pct:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    row.pct:SetWidth(45)
    row.pct:SetJustifyH("RIGHT")
    
    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.count:SetPoint("RIGHT", row.pct, "LEFT", -10, 0)
    row.count:SetWidth(40)
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
-- 5. DATA LOGIC & ALPHA UPDATE
-- ==========================================

-- THE FIX: Applies Alpha ONLY to the Background Colors to prevent ghost text!
function OUS.UpdateFishingAlpha()
    if not OdysseusDB or not OdysseusDB.fishingSettings then return end
    local alpha = OdysseusDB.fishingSettings.alpha or 0.95
    
    -- Force master frames back to 100% solid opacity to cure any previous ghosting
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
    
    OdysseusDB.fishingSettings.history[currentZone] = OdysseusDB.fishingSettings.history[currentZone] or { total = 0, catches = {}, subZones = {} }
    local areaData = OdysseusDB.fishingSettings.history[currentZone]
    
    locTotalText:SetText(string.format("Fish caught in this location: |cFF87CEEB%d|r", areaData.total))
    sessTotalText:SetText(string.format("Total caught this session: |cFF87CEEB%d|r", sessionData.total))
    
    local mapID = C_Map.GetBestMapForUnit("player")
    local customProfName = mapID and ZONE_FISHING_NAMES[mapID]
    
    local prof1, prof2, _, fishProf = GetProfessions()
    if fishProf then
        local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(fishProf)
        profText:SetText(customProfName or name)
        local modStr = ""
        if skillModifier > 0 then modStr = "|cFF00FF00+" .. skillModifier .. "|r" end
        skillText:SetText(string.format("(Skill: |cFFFFFF00%d|r%s)/%d", skillLevel, modStr, maxSkillLevel))
    else
        profText:SetText("Fishing Not Found")
        skillText:SetText("")
    end
    
    local poleTex = GetInventoryItemTexture("player", 28) or GetInventoryItemTexture("player", 16) or 136245
    poleBtn.icon:SetTexture(poleTex)

    for _, row in ipairs(mainRows) do row:Hide() end
    local yOffset = -180 
    local rowIndex = 1
    
    if areaData.catches then
        local sortedAreaCatches = {}
        for itemLink, count in pairs(areaData.catches) do
            table.insert(sortedAreaCatches, {link = itemLink, count = count})
        end
        table.sort(sortedAreaCatches, function(a, b) return a.count > b.count end)
        
        for _, data in ipairs(sortedAreaCatches) do
            if not mainRows[rowIndex] then mainRows[rowIndex] = CreateFishRow(mainFrame) end
            local row = mainRows[rowIndex]
            local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(data.link)
            local hex = select(4, GetItemQualityColor(itemQuality or 1))
            local colorPrefix = hex and ("|c" .. hex) or "|cFFFFFFFF"
            
            row.icon:SetTexture(itemIcon)
            row.name:SetText(colorPrefix .. (itemName or "Unknown") .. "|r")
            
            local pct = (areaData.total > 0) and string.format("%.1f%%", (data.count / areaData.total) * 100) or "0%"
            row.count:SetText(data.count)
            row.pct:SetText(pct)
            
            row.itemLink = data.link
            row:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, yOffset)
            row:Show()
            
            yOffset = yOffset - 18
            rowIndex = rowIndex + 1
        end
    end
    mainFrame:SetHeight(math.max(220, math.abs(yOffset) + 35))

    for _, row in ipairs(sessRows) do row:Hide() end
    local sessY = -155 
    local sessIdx = 1
    
    local sortedSessionCatches = {}
    for itemLink, count in pairs(sessionData.catches) do
        table.insert(sortedSessionCatches, {link = itemLink, count = count})
    end
    table.sort(sortedSessionCatches, function(a, b) return a.count > b.count end)

    for _, data in ipairs(sortedSessionCatches) do
        if not sessRows[sessIdx] then sessRows[sessIdx] = CreateFishRow(sessFrame) end
        local row = sessRows[sessIdx]
        local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(data.link)
        local hex = select(4, GetItemQualityColor(itemQuality or 1))
        local colorPrefix = hex and ("|c" .. hex) or "|cFFFFFFFF"
        
        row.icon:SetTexture(itemIcon)
        row.name:SetText(colorPrefix .. (itemName or "Unknown") .. "|r")
        
        local pct = (sessionData.total > 0) and string.format("%.1f%%", (data.count / sessionData.total) * 100) or "0%"
        row.count:SetText(data.count)
        row.pct:SetText(pct)
        
        row.itemLink = data.link
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
    
    local itemName, _, itemQuality = GetItemInfo(itemLink)
    local exactName = string.match(itemLink, "%[(.-)%]") or itemName or "Unknown"
    local itemID = string.match(itemLink, "item:(%d+)")
    local hex = select(4, GetItemQualityColor(itemQuality or 1))
    local colorPrefix = hex and ("|c" .. hex) or "|cFFFFFFFF"
    
    local coloredName = colorPrefix .. "[" .. exactName .. "]|r"
    local statusText = ""
    
    if itemQuality and itemQuality == 0 then
        statusText = "|cFFFF0000not saved.|r"
        lastCatchText:SetText(coloredName .. " (|cFFFFFFFFx" .. quantity .. "|r) |cFF87CEEB[ID: " .. tostring(itemID) .. "]|r " .. statusText)
        return 
    else
        statusText = "|cFF87CEEBsaved.|r"
        lastCatchText:SetText(coloredName .. " (|cFFFFFFFFx" .. quantity .. "|r) |cFF87CEEB[ID: " .. tostring(itemID) .. "]|r " .. statusText)
    end
    
    currentZone = GetRealZoneText() or "Unknown Zone"
    currentSubZone = GetMinimapZoneText() or ""
    
    OdysseusDB.fishingSettings.history[currentZone] = OdysseusDB.fishingSettings.history[currentZone] or { total = 0, catches = {}, subZones = {} }
    OdysseusDB.fishingSettings.history[currentZone].subZones = OdysseusDB.fishingSettings.history[currentZone].subZones or {}
    
    OdysseusDB.fishingSettings.history[currentZone].total = OdysseusDB.fishingSettings.history[currentZone].total + quantity
    OdysseusDB.fishingSettings.history[currentZone].catches[itemLink] = (OdysseusDB.fishingSettings.history[currentZone].catches[itemLink] or 0) + quantity
    
    if currentSubZone ~= "" then
        OdysseusDB.fishingSettings.history[currentZone].subZones[currentSubZone] = true
    end
    
    sessionData.total = sessionData.total + quantity
    sessionData.catches[itemLink] = (sessionData.catches[itemLink] or 0) + quantity
    
    fphUpdateTimer = 15 
    OUS.UpdateFishingUI()
end

-- ==========================================
-- 6. CORE EVENT LISTENERS
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
            OdysseusDB.fishingSettings.history = OdysseusDB.fishingSettings.history or {}
            
            if OdysseusDB.fishingSettings.autoCloseInactive == nil then OdysseusDB.fishingSettings.autoCloseInactive = true end
            if OdysseusDB.fishingSettings.autoCloseMounted == nil then OdysseusDB.fishingSettings.autoCloseMounted = true end
            if OdysseusDB.fishingSettings.autoCloseDelay == nil then OdysseusDB.fishingSettings.autoCloseDelay = 30 end
            if OdysseusDB.fishingSettings.alpha == nil then OdysseusDB.fishingSettings.alpha = 0.95 end

            lastCastTime = GetTime() 
            
            if OdysseusDB.fishingSettings.pos then
                local p = OdysseusDB.fishingSettings.pos
                mainFrame:ClearAllPoints()
                mainFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
            end
            
            if OUS.UpdateFishingAlpha then OUS.UpdateFishingAlpha() end
        end
        return 
    end

    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fishingTracker then return end

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit, _, spellID = ...
        if unit == "player" and FISHING_SPELL_IDS[spellID] then
            isFishingActive = true
            lastCastTime = GetTime()
            
            if not sessionTimerActive and not sessionPaused then
                sessionStartTime = GetTime()
                sessionTimerActive = true
                pauseBtn:SetText("Pause")
            end
            
            if not mainFrame:IsShown() then
                mainFrame:Show()
                OUS.UpdateFishingUI()
            end
        end
        
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_STOP" then
        local unit, _, spellID = ...
        if unit == "player" and FISHING_SPELL_IDS[spellID] then
            isFishingActive = false 
            lastCastTime = GetTime() 
        end

    elseif event == "LOOT_READY" then
        if GetTime() - lastLootTime < 1.0 then return end
        
        local isFishingLoot = false
        if IsFishingLoot and IsFishingLoot() then
            isFishingLoot = true
        elseif isFishingActive then
            isFishingLoot = true
        end

        if isFishingLoot then
            lastLootTime = GetTime()
            lastCastTime = GetTime() 
            
            local numItems = GetNumLootItems()
            for i = 1, numItems do
                if GetLootSlotType(i) == 1 then
                    local itemLink = GetLootSlotLink(i)
                    local _, _, quantity = GetLootSlotInfo(i)
                    if itemLink then
                        RecordCatch(itemLink, quantity or 1)
                    end
                end
            end
            
            if not mainFrame:IsShown() then mainFrame:Show() end
        end
    end
end)

-- TIMER, FPH & AUTO-CLOSE LOOP
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
        else
            if remaining <= 10 and (sessionData.total > 0 or sessionTimerActive) then
                closeTimerText:SetText(string.format("Closing in: %ds", math.ceil(remaining)))
            else
                closeTimerText:SetText("")
            end
        end
    end
end)

function OUS.ToggleFishingTracker()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fishingTracker then return end

    if mainFrame:IsShown() then
        mainFrame:Hide()
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
    end
end