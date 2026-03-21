local addonName, OUS = ...
local f = CreateFrame("Frame")

-- ==========================================
-- 1. DATABASE, DEFAULTS & STATE VARIABLES
-- ==========================================
local defaults = {
    xpTemplate = "Exp: [curXP]/[maxXP] ([restPC]%) :: Level [pLVL] :: [KTL] Kills",
    repTemplate = "Rep: [faction] ([standing]) [curRep]/[maxRep] :: [repPC]%",
    delveCompTemplate = "[compName]: Level [pLVL] - [curXP]/[maxXP]",
    delveJourTemplate = "Journey: [curRep]/[maxRep]",
    xpColor = {r = 0.6, g = 0.2, b = 0.8},
    restColor = {r = 0.0, g = 0.4, b = 0.9},
    repColor = {r = 0.2, g = 0.8, b = 0.4},
    delveCompColor = {r = 0.8, g = 0.4, b = 0.0},
    delveJourColor = {r = 0.0, g = 0.6, b = 0.8},
    hideBlizz = false,
    repDisplayTime = 15,
    journeyID = 2640,
    delveBrannID = 2640,
    delveValeeraID = 2744,
    autoHide = false,
    fadeDelay = 5,
    activeAlpha = 100,
    fadedAlpha = 0,
    
    xpBarWidth = 400,
    xpBarHeight = 24,
    xpBarScale = 1.0,
    xpBarPos = {p = "BOTTOM", rP = "BOTTOM", x = 0, y = 150},
    
    delveBarWidth = 300,
    delveBarHeight = 40,
    delveBarScale = 1.0,
    delveBarPos = {p = "TOP", rP = "TOP", x = 0, y = -150}
}

local forceRepDisplay = false
local repTimer = nil
local lastXP, lastMaxXP, lastXPGain = 0, 0, 0
local isTestingDelve = false
local delveCheckTicker = nil
local isDebugOn = false 
local sleepTimer = nil
local fadeTicker = nil

local function DebugPrint(msg)
    if isDebugOn then print("|cFF00FFFF[OUS Debug]:|r " .. tostring(msg)) end
end

-- ==========================================
-- 2. CREATE THE MIDNIGHT VISUALS
-- ==========================================
OUS.xpBarFrame = CreateFrame("Frame", "OdysseusXPBar", UIParent, "BackdropTemplate")
local xpBar = OUS.xpBarFrame
xpBar.bg = xpBar:CreateTexture(nil, "BACKGROUND"); xpBar.bg:SetAllPoints(true); xpBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)
xpBar.restedBar = CreateFrame("StatusBar", nil, xpBar); xpBar.restedBar:SetAllPoints(true); xpBar.restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar.progressBar = CreateFrame("StatusBar", nil, xpBar); xpBar.progressBar:SetAllPoints(true); xpBar.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); xpBar:SetBackdropBorderColor(0, 0, 0, 1)
xpBar.text = xpBar.progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); xpBar.text:SetPoint("CENTER", xpBar, "CENTER", 0, 0); xpBar.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

xpBar:SetMovable(true); xpBar:EnableMouse(true); xpBar:RegisterForDrag("LeftButton")
xpBar:SetScript("OnDragStart", xpBar.StartMoving)
xpBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    OdysseusDB.xpBar.xpBarPos = {p = point, rP = relPoint, x = x, y = y}
end)

OUS.delveBarFrame = CreateFrame("Frame", "OdysseusDelveBar", UIParent, "BackdropTemplate")
local delveBar = OUS.delveBarFrame
delveBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); delveBar:SetBackdropBorderColor(0, 0, 0, 1)
delveBar.bg = delveBar:CreateTexture(nil, "BACKGROUND"); delveBar.bg:SetAllPoints(true); delveBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)
delveBar.compBar = CreateFrame("StatusBar", nil, delveBar); delveBar.compBar:SetPoint("TOP", 0, -1); delveBar.compBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
delveBar.compText = delveBar.compBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); delveBar.compText:SetPoint("CENTER"); delveBar.compText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
delveBar.jourBar = CreateFrame("StatusBar", nil, delveBar); delveBar.jourBar:SetPoint("BOTTOM", 0, 1); delveBar.jourBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
delveBar.jourText = delveBar.jourBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); delveBar.jourText:SetPoint("CENTER"); delveBar.jourText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

delveBar:SetMovable(true); delveBar:EnableMouse(true); delveBar:RegisterForDrag("LeftButton")
delveBar:SetScript("OnDragStart", delveBar.StartMoving)
delveBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    OdysseusDB.xpBar.delveBarPos = {p = point, rP = relPoint, x = x, y = y}
end)
delveBar:Hide()

-- ==========================================
-- 3. THE DIMENSIONS ENGINE
-- ==========================================
local function ApplyDimensions()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    
    xpBar:SetSize(db.xpBarWidth, db.xpBarHeight)
    xpBar:SetScale(db.xpBarScale)
    
    delveBar:SetSize(db.delveBarWidth, db.delveBarHeight)
    delveBar:SetScale(db.delveBarScale)
    
    local innerHeight = (db.delveBarHeight - 2) / 2
    delveBar.compBar:SetSize(db.delveBarWidth - 2, innerHeight)
    delveBar.jourBar:SetSize(db.delveBarWidth - 2, innerHeight)
end

-- ==========================================
-- 4. AUTO-HIDE & FADE ENGINE
-- ==========================================
local function FadeBarsTo(targetAlpha)
    if fadeTicker then fadeTicker:Cancel() end
    local currentAlpha = xpBar:GetAlpha()
    local step = (targetAlpha - currentAlpha) / 10
    if step == 0 then return end
    
    local count = 0
    fadeTicker = C_Timer.NewTicker(0.02, function()
        count = count + 1
        local newAlpha = currentAlpha + (step * count)
        xpBar:SetAlpha(newAlpha); delveBar:SetAlpha(newAlpha)
        if count >= 10 then xpBar:SetAlpha(targetAlpha); delveBar:SetAlpha(targetAlpha) end
    end, 10)
end

local function WakeBars()
    if not OdysseusDB or not OdysseusDB.xpBar.autoHide then 
        FadeBarsTo((OdysseusDB and OdysseusDB.xpBar.activeAlpha or 100) / 100)
        return 
    end
    if sleepTimer then sleepTimer:Cancel(); sleepTimer = nil end
    FadeBarsTo(OdysseusDB.xpBar.activeAlpha / 100)
end

local function SleepBars()
    if not OdysseusDB or not OdysseusDB.xpBar.autoHide then return end
    if UnitAffectingCombat("player") or xpBar:IsMouseOver() or delveBar:IsMouseOver() or forceRepDisplay then return end
    
    if sleepTimer then sleepTimer:Cancel() end
    sleepTimer = C_Timer.NewTimer(OdysseusDB.xpBar.fadeDelay, function()
        if not UnitAffectingCombat("player") and not xpBar:IsMouseOver() and not delveBar:IsMouseOver() and not forceRepDisplay then
            FadeBarsTo(OdysseusDB.xpBar.fadedAlpha / 100)
        end
    end)
end

xpBar:HookScript("OnEnter", WakeBars); xpBar:HookScript("OnLeave", SleepBars)
delveBar:HookScript("OnEnter", WakeBars); delveBar:HookScript("OnLeave", SleepBars)

-- ==========================================
-- 5. PARSERS & LIVE UPDATE ENGINE
-- ==========================================
local function FormatLargeNumber(n)
    if not n then return 0 end
    if n >= 1000000 then return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return tostring(n) end
end

local function ParseXPText(template, curXP, maxXP, restXP, level, mLVL, ktl, isMaxed, compName)
    local str = template
    local needXP = maxXP - curXP
    local curPC = maxXP > 0 and math.floor((curXP / maxXP) * 100) or 0
    local needPC = maxXP > 0 and math.ceil((needXP / maxXP) * 100) or 0
    local restPC = (maxXP > 0 and restXP > 0) and math.floor((restXP / maxXP) * 100) or 0
    local restLVL = maxXP > 0 and string.format("%.2f", restXP / maxXP) or "0"
    local btl = maxXP > 0 and math.ceil(needXP / (maxXP / 20)) or 0

    if isMaxed then
        str = string.gsub(str, "%[curXP%]/%[maxXP%]", "Max Level")
        str = string.gsub(str, "%[curXP%]", "Max")
        str = string.gsub(str, "%[maxXP%]", "Max")
        str = string.gsub(str, "%[needXP%]", "0")
    else
        str = string.gsub(str, "%[curXP%]", FormatLargeNumber(curXP))
        str = string.gsub(str, "%[maxXP%]", FormatLargeNumber(maxXP))
        str = string.gsub(str, "%[needXP%]", FormatLargeNumber(needXP))
    end

    str = string.gsub(str, "%[restXP%]", FormatLargeNumber(restXP))
    str = string.gsub(str, "%[curPC%]", curPC)
    str = string.gsub(str, "%[needPC%]", needPC)
    str = string.gsub(str, "%[restPC%]", restPC)
    str = string.gsub(str, "%[pLVL%]", level)
    str = string.gsub(str, "%[nLVL%]", level + 1)
    str = string.gsub(str, "%[mLVL%]", mLVL)
    str = string.gsub(str, "%[restLVL%]", restLVL)
    str = string.gsub(str, "%[KTL%]", ktl or "?")
    str = string.gsub(str, "%[BTL%]", btl)
    if compName then str = string.gsub(str, "%[compName%]", compName) end
    return str
end

local function ParseRepText(template, name, standingText, curRep, maxRep)
    local str = template
    local needRep = maxRep - curRep
    local repPC = maxRep > 0 and math.floor((curRep / maxRep) * 100) or 100
    local needPC = maxRep > 0 and math.ceil((needRep / maxRep) * 100) or 0

    str = string.gsub(str, "%[faction%]", name or "Unknown")
    str = string.gsub(str, "%[standing%]", standingText or "Neutral")
    str = string.gsub(str, "%[curRep%]", FormatLargeNumber(curRep))
    str = string.gsub(str, "%[maxRep%]", FormatLargeNumber(maxRep))
    str = string.gsub(str, "%[needRep%]", FormatLargeNumber(needRep))
    str = string.gsub(str, "%[repPC%]", repPC)
    str = string.gsub(str, "%[needPC%]", needPC)
    return str
end

local function ApplyBlizzardKiller()
    if OdysseusDB and OdysseusDB.xpBar.hideBlizz and StatusTrackingBarManager then
        StatusTrackingBarManager:UnregisterAllEvents()
        StatusTrackingBarManager:Hide()
    end
end

local function GetActiveDelveCompanion()
    if not OdysseusDB then return "Companion", 2640 end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player") or 0
    if (instanceID and instanceID >= 2800) or (uiMapID >= 2350) then
        return "Valeera Sanguinar", OdysseusDB.xpBar.delveValeeraID or 2744
    else
        return "Brann Bronzebeard", OdysseusDB.xpBar.delveBrannID or 2640
    end
end

local function IsPlayerInDelve()
    if isTestingDelve then return true end
    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID and difficultyID >= 205 and difficultyID <= 220 then return true end
    return false
end

local function UpdateDelveBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    
    if IsPlayerInDelve() then
        local compName, compFactionID = GetActiveDelveCompanion()
        local cXP, cMax, cLvl = 0, 1, 1
        local isMaxed = false
        
        if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
            local repInfo = C_GossipInfo.GetFriendshipReputation(compFactionID)
            if repInfo and repInfo.friendshipFactionID > 0 then
                local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(compFactionID)
                if rankInfo and rankInfo.currentLevel then
                    cLvl = rankInfo.currentLevel
                    if rankInfo.currentLevel >= rankInfo.maxLevel then
                        isMaxed = true; cMax = 1; cXP = 1
                    else
                        cXP = repInfo.standing - repInfo.reactionThreshold
                        cMax = repInfo.nextThreshold - repInfo.reactionThreshold
                    end
                end
            end
        end
        
        local jRep, jMax = 0, 1
        local journeyData = C_Reputation.GetFactionDataByID(db.journeyID)
        if journeyData then
            jRep = journeyData.currentStanding
            jMax = journeyData.nextReactionThreshold
            if jMax == 0 then jMax = 1 end
        end
        
        if isTestingDelve and cMax <= 1 and jMax <= 1 then
            cXP, cMax, cLvl = 25000, 83000, 15; jRep, jMax = 1200, 5000; isMaxed = false
        end

        delveBar.compBar:SetMinMaxValues(0, cMax); delveBar.compBar:SetValue(cXP)
        delveBar.compBar:SetStatusBarColor(db.delveCompColor.r, db.delveCompColor.g, db.delveCompColor.b, 1)
        delveBar.compText:SetText(ParseXPText(db.delveCompTemplate, cXP, cMax, 0, cLvl, 60, "?", isMaxed, compName))
        
        delveBar.jourBar:SetMinMaxValues(0, jMax); delveBar.jourBar:SetValue(jRep)
        delveBar.jourBar:SetStatusBarColor(db.delveJourColor.r, db.delveJourColor.g, db.delveJourColor.b, 1)
        delveBar.jourText:SetText(ParseRepText(db.delveJourTemplate, "Journey", "Active", jRep, jMax))
        delveBar:Show()
    else
        delveBar:Hide()
    end
end

local function UpdateBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    local playerLevel = UnitLevel("player")
    local maxExpansionLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = (playerLevel >= maxExpansionLevel) or (IsXPUserDisabled and IsXPUserDisabled())
    local watchedData = C_Reputation.GetWatchedFactionData()
    local showRep = isMaxLevel or (forceRepDisplay and watchedData)

    if not showRep then
        local curXP, maxXP = UnitXP("player"), UnitXPMax("player")
        local restXP = GetXPExhaustion() or 0
        local ktl = "?"
        if lastXPGain > 0 then ktl = tostring(math.ceil((maxXP - curXP) / lastXPGain)) end

        xpBar.progressBar:SetMinMaxValues(0, maxXP); xpBar.progressBar:SetValue(curXP)
        xpBar.progressBar:SetStatusBarColor(db.xpColor.r, db.xpColor.g, db.xpColor.b, 0.9)

        if restXP > 0 then
            xpBar.restedBar:SetMinMaxValues(0, maxXP); xpBar.restedBar:SetValue(math.min(curXP + restXP, maxXP))
            xpBar.restedBar:SetStatusBarColor(db.restColor.r, db.restColor.g, db.restColor.b, 0.6)
            xpBar.restedBar:Show()
        else
            xpBar.restedBar:Hide()
        end

        xpBar.text:SetText(ParseXPText(db.xpTemplate, curXP, maxXP, restXP, playerLevel, maxExpansionLevel, ktl, false, nil))
        xpBar:Show()
    else
        xpBar.restedBar:Hide()
        if watchedData then
            local name = watchedData.name
            local standingText = GetText("FACTION_STANDING_LABEL" .. (watchedData.reaction or 4)) or "Neutral"
            local curRep, maxRep = 0, 1
            if watchedData.currentValue then 
                curRep, maxRep = watchedData.currentValue, watchedData.maxValue
            elseif watchedData.currentStanding then
                curRep = watchedData.currentStanding - watchedData.currentReactionThreshold
                maxRep = watchedData.nextReactionThreshold - watchedData.currentReactionThreshold
                if maxRep == 0 then maxRep = 1 end
            end

            xpBar.progressBar:SetMinMaxValues(0, maxRep > 0 and maxRep or 1); xpBar.progressBar:SetValue(curRep)
            xpBar.progressBar:SetStatusBarColor(db.repColor.r, db.repColor.g, db.repColor.b, 0.9)
            xpBar.text:SetText(ParseRepText(db.repTemplate, name, standingText, curRep, maxRep))
            xpBar:Show()
        else
            xpBar:Hide() 
        end
    end
    UpdateDelveBar()
end

local function TriggerAggressiveDelveCheck()
    if delveCheckTicker then delveCheckTicker:Cancel() end
    local checks = 0
    delveCheckTicker = C_Timer.NewTicker(1, function()
        checks = checks + 1
        if IsPlayerInDelve() or checks >= 10 then
            WakeBars(); UpdateBar(); SleepBars()
            if delveCheckTicker then delveCheckTicker:Cancel() end
        end
    end)
end

-- ==========================================
-- 6. CONFIGURATION UI FRAMEWORK
-- ==========================================
StaticPopupDialogs["ODYSSEUS_RELOAD_PROMPT"] = {
    text = "Changing this setting requires a UI reload to avoid errors. Reload now?",
    button1 = "Yes", button2 = "No", OnAccept = function() ReloadUI() end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

OUS.xpConfigFrame = CreateFrame("Frame", "OdysseusXPConfig", UIParent, "BackdropTemplate")
local config = OUS.xpConfigFrame
config:SetSize(600, 500); config:SetPoint("CENTER"); config:SetFrameStrata("DIALOG")
config:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 }})
config:Hide(); config:SetMovable(true); config:EnableMouse(true); config:RegisterForDrag("LeftButton")
config:SetScript("OnDragStart", config.StartMoving); config:SetScript("OnDragStop", config.StopMovingOrSizing)

local closeButton = CreateFrame("Button", nil, config, "UIPanelCloseButton"); closeButton:SetPoint("TOPRIGHT", config, "TOPRIGHT", -4, -4)
local title = config:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -16); title:SetText("Experience & Reputation Bar Module")

local pageContainer = CreateFrame("Frame", nil, config, "BackdropTemplate"); pageContainer:SetPoint("TOPLEFT", 16, -70); pageContainer:SetPoint("BOTTOMRIGHT", -16, 16)
pageContainer:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
pageContainer:SetBackdropColor(0.07, 0.05, 0.1, 0.5)

local tabs, pages = {}, {}
local function SelectTab(id)
    for i = 1, #tabs do
        if i == id then
            tabs[i]:SetBackdropColor(0.6, 0.2, 0.8, 0.5); tabs[i]:SetBackdropBorderColor(0.6, 0.2, 0.8, 1); tabs[i].text:SetTextColor(1, 1, 1, 1); pages[i]:Show()
        else
            tabs[i]:SetBackdropColor(0.05, 0.03, 0.05, 0.8); tabs[i]:SetBackdropBorderColor(0.3, 0.3, 0.3, 1); tabs[i].text:SetTextColor(0.5, 0.5, 0.5, 1); pages[i]:Hide()
        end
    end
end

local function CreateTab(id, label)
    local tab = CreateFrame("Button", nil, config, "BackdropTemplate"); tab:SetID(id); tab:SetSize(90, 26)
    tab:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }})
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal"); tab.text:SetPoint("CENTER"); tab.text:SetText(label)
    if id == 1 then tab:SetPoint("BOTTOMLEFT", pageContainer, "TOPLEFT", 10, -3) else tab:SetPoint("LEFT", tabs[id-1], "RIGHT", 4, 0) end
    tab:SetScript("OnClick", function(self) SelectTab(self:GetID()); PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end)
    local page = CreateFrame("Frame", nil, pageContainer); page:SetPoint("TOPLEFT", 8, -8); page:SetPoint("BOTTOMRIGHT", -8, 8); page:Hide()
    tabs[id], pages[id] = tab, page
end

CreateTab(1, "Global") CreateTab(2, "Experience") CreateTab(3, "Reputation") CreateTab(4, "Delves") CreateTab(5, "Help")
SelectTab(1)

-- ==========================================
-- 7. POPULATING UI COMPONENTS
-- ==========================================
local function CreateTemplateBox(parent, titleText, yOffset, dbKey)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal"); title:SetPoint("TOPLEFT", 16, yOffset); title:SetText(titleText)
    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetSize(536, 30); bg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    bg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }}); bg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)
    local editBox = CreateFrame("EditBox", nil, bg)
    editBox:SetFontObject("GameFontHighlight"); editBox:SetPoint("TOPLEFT", 8, -6); editBox:SetPoint("BOTTOMRIGHT", -8, 6); editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); OdysseusDB.xpBar[dbKey] = self:GetText(); WakeBars(); UpdateBar(); SleepBars() end)
    return editBox
end

local function OpenColorPicker(dbColor, colorBoxFrame)
    local info = {
        r = dbColor.r, g = dbColor.g, b = dbColor.b, hasOpacity = false,
        swatchFunc = function() local r, g, b = ColorPickerFrame:GetColorRGB(); dbColor.r, dbColor.g, dbColor.b = r, g, b; colorBoxFrame:SetBackdropColor(r, g, b, 1); UpdateBar() end,
        cancelFunc = function(previousValues) dbColor.r, dbColor.g, dbColor.b = previousValues.r, previousValues.g, previousValues.b; colorBoxFrame:SetBackdropColor(previousValues.r, previousValues.g, previousValues.b, 1); UpdateBar() end,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
end

-- THE FIX: Added xOffset parameter so we can put boxes side-by-side!
local function CreateColorBox(parent, labelText, xOffset, yOffset, dbKey)
    local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
    box:SetSize(24, 24); box:SetPoint("TOPLEFT", xOffset, yOffset)
    box:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); box:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); text:SetPoint("LEFT", box, "RIGHT", 10, 0); text:SetText(labelText)
    box:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 1, 1, 1) end)
    box:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) end)
    box:SetScript("OnClick", function(self) OpenColorPicker(OdysseusDB.xpBar[dbKey], self) end)
    return box
end

local sliderCounter = 1
local function CreatePremiumSlider(parent, titleText, yOffset, dbKey, minVal, maxVal, step, onUpdate)
    local sliderName = "OdysseusXPSlider" .. sliderCounter; sliderCounter = sliderCounter + 1
    local container = CreateFrame("Frame", nil, parent); container:SetSize(400, 40); container:SetPoint("TOPLEFT", 16, yOffset)
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormal"); title:SetPoint("TOPLEFT", 0, 0); title:SetText(titleText)
    local btnMinus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate"); btnMinus:SetSize(22, 22); btnMinus:SetPoint("BOTTOMLEFT", 0, 0); btnMinus:SetText("<")
    local slider = CreateFrame("Slider", sliderName, container, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", btnMinus, "RIGHT", 10, 0); slider:SetWidth(200); slider:SetMinMaxValues(minVal, maxVal); slider:SetValueStep(step); slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Text"]:SetText(""); _G[slider:GetName() .. "Low"]:SetText(minVal); _G[slider:GetName() .. "High"]:SetText(maxVal)
    local btnPlus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate"); btnPlus:SetSize(22, 22); btnPlus:SetPoint("LEFT", slider, "RIGHT", 10, 0); btnPlus:SetText(">")
    local editBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
    editBg:SetSize(40, 24); editBg:SetPoint("LEFT", btnPlus, "RIGHT", 15, 0)
    editBg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }}); editBg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)
    local editBox = CreateFrame("EditBox", nil, editBg)
    editBox:SetFontObject("GameFontHighlight"); editBox:SetPoint("TOPLEFT", 5, -2); editBox:SetPoint("BOTTOMRIGHT", -5, 2); editBox:SetAutoFocus(false); editBox:SetJustifyH("CENTER")

    btnMinus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() - step) end)
    btnPlus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() + step) end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(slider:GetValue()) end)
    editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); local val = tonumber(self:GetText()); if val then val = math.max(minVal, math.min(maxVal, val)); slider:SetValue(val) else self:SetText(slider:GetValue()) end end)
    
    slider:SetScript("OnValueChanged", function(self, value) 
        local snappedValue
        if step < 1 then snappedValue = math.floor(value * 100 + 0.5) / 100 else snappedValue = math.floor(value + 0.5) end
        OdysseusDB.xpBar[dbKey] = snappedValue
        editBox:SetText(snappedValue)
        if onUpdate then onUpdate() end
    end)
    return slider
end

local xpEditBox, xpColorBox, restColorBox
local repEditBox, repColorBox, repTimeSlider
local delveCompEditBox, delveJourEditBox, delveCompColorBox, delveJourColorBox
local hideBlizzCheck, autoHideCheck, fadeDelaySlider, activeAlphaSlider, fadedAlphaSlider

-- PAGE 1: GLOBAL
pages[1]:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"):SetPoint("TOPLEFT", 16, -16); pages[1]:GetRegions():SetText("Global Settings")
hideBlizzCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate")
hideBlizzCheck:SetPoint("TOPLEFT", 16, -50); hideBlizzCheck.text = hideBlizzCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hideBlizzCheck.text:SetPoint("LEFT", hideBlizzCheck, "RIGHT", 4, 0); hideBlizzCheck.text:SetText("Hide Default Blizzard UI (Requires Reload / Disabled in Instances)")
hideBlizzCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.hideBlizz = self:GetChecked(); StaticPopup_Show("ODYSSEUS_RELOAD_PROMPT") end)
pages[1]:SetScript("OnShow", function() if IsInInstance() then hideBlizzCheck:Disable(); hideBlizzCheck.text:SetTextColor(0.5, 0.5, 0.5) else hideBlizzCheck:Enable(); hideBlizzCheck.text:SetTextColor(1, 1, 1) end end)

autoHideCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate")
autoHideCheck:SetPoint("TOPLEFT", 16, -90); autoHideCheck.text = autoHideCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); autoHideCheck.text:SetPoint("LEFT", autoHideCheck, "RIGHT", 4, 0); autoHideCheck.text:SetText("Enable Auto-Hide / Mouseover Engine")
autoHideCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.autoHide = self:GetChecked(); WakeBars(); SleepBars() end)

repTimeSlider = CreatePremiumSlider(pages[1], "Auto-Switch Display Time (Seconds)", -140, "repDisplayTime", 5, 60, 1, function() WakeBars(); SleepBars() end)
fadeDelaySlider = CreatePremiumSlider(pages[1], "Auto-Hide Fade Delay (Seconds)", -200, "fadeDelay", 0, 60, 1, function() WakeBars(); SleepBars() end)
activeAlphaSlider = CreatePremiumSlider(pages[1], "Active Opacity (%)", -260, "activeAlpha", 10, 100, 5, function() WakeBars(); SleepBars() end)
fadedAlphaSlider = CreatePremiumSlider(pages[1], "Faded Opacity (%)", -320, "fadedAlpha", 0, 100, 5, function() WakeBars(); SleepBars() end)

local resetGlobalBtn = CreateFrame("Button", nil, pages[1], "UIPanelButtonTemplate"); resetGlobalBtn:SetSize(140, 26); resetGlobalBtn:SetPoint("BOTTOMRIGHT", -16, 16); resetGlobalBtn:SetText("Reset Defaults")
resetGlobalBtn:SetScript("OnClick", function() 
    OdysseusDB.xpBar.hideBlizz = defaults.hideBlizz; OdysseusDB.xpBar.autoHide = defaults.autoHide
    OdysseusDB.xpBar.repDisplayTime = defaults.repDisplayTime; OdysseusDB.xpBar.fadeDelay = defaults.fadeDelay
    OdysseusDB.xpBar.activeAlpha = defaults.activeAlpha; OdysseusDB.xpBar.fadedAlpha = defaults.fadedAlpha
    hideBlizzCheck:SetChecked(defaults.hideBlizz); autoHideCheck:SetChecked(defaults.autoHide)
    repTimeSlider:SetValue(defaults.repDisplayTime); fadeDelaySlider:SetValue(defaults.fadeDelay)
    activeAlphaSlider:SetValue(defaults.activeAlpha); fadedAlphaSlider:SetValue(defaults.fadedAlpha)
    ApplyBlizzardKiller(); WakeBars(); SleepBars()
end)

-- PAGE 2: EXPERIENCE
pages[2]:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"):SetPoint("TOPLEFT", 16, -16); pages[2]:GetRegions():SetText("Experience Bar Options")
xpEditBox = CreateTemplateBox(pages[2], "Text Format", -50, "xpTemplate")
xpColorBox = CreateColorBox(pages[2], "Main Experience Color", 16, -130, "xpColor")
restColorBox = CreateColorBox(pages[2], "Rested Experience Color", 16, -170, "restColor")

local xpWidthSlider = CreatePremiumSlider(pages[2], "Main Bar Width", -210, "xpBarWidth", 100, 1000, 10, function() ApplyDimensions(); WakeBars(); SleepBars() end)
local xpHeightSlider = CreatePremiumSlider(pages[2], "Main Bar Height", -270, "xpBarHeight", 10, 100, 1, function() ApplyDimensions(); WakeBars(); SleepBars() end)
local xpScaleSlider = CreatePremiumSlider(pages[2], "Main Bar Scale", -330, "xpBarScale", 0.5, 2.0, 0.05, function() ApplyDimensions(); WakeBars(); SleepBars() end)

local resetXPBtn = CreateFrame("Button", nil, pages[2], "UIPanelButtonTemplate"); resetXPBtn:SetSize(140, 26); resetXPBtn:SetPoint("BOTTOMRIGHT", -16, 16); resetXPBtn:SetText("Reset Defaults")
resetXPBtn:SetScript("OnClick", function() 
    OdysseusDB.xpBar.xpTemplate = defaults.xpTemplate; OdysseusDB.xpBar.xpColor = {r = defaults.xpColor.r, g = defaults.xpColor.g, b = defaults.xpColor.b}; OdysseusDB.xpBar.restColor = {r = defaults.restColor.r, g = defaults.restColor.g, b = defaults.restColor.b}; 
    OdysseusDB.xpBar.xpBarWidth = defaults.xpBarWidth; OdysseusDB.xpBar.xpBarHeight = defaults.xpBarHeight; OdysseusDB.xpBar.xpBarScale = defaults.xpBarScale;
    OdysseusDB.xpBar.xpBarPos = {p = defaults.xpBarPos.p, rP = defaults.xpBarPos.rP, x = defaults.xpBarPos.x, y = defaults.xpBarPos.y};
    xpEditBox:SetText(defaults.xpTemplate); xpColorBox:SetBackdropColor(defaults.xpColor.r, defaults.xpColor.g, defaults.xpColor.b, 1); restColorBox:SetBackdropColor(defaults.restColor.r, defaults.restColor.g, defaults.restColor.b, 1); 
    xpWidthSlider:SetValue(defaults.xpBarWidth); xpHeightSlider:SetValue(defaults.xpBarHeight); xpScaleSlider:SetValue(defaults.xpBarScale);
    xpBar:ClearAllPoints(); xpBar:SetPoint(defaults.xpBarPos.p, UIParent, defaults.xpBarPos.rP, defaults.xpBarPos.x, defaults.xpBarPos.y)
    ApplyDimensions(); WakeBars(); UpdateBar(); SleepBars() 
end)

-- PAGE 3: REPUTATION
pages[3]:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"):SetPoint("TOPLEFT", 16, -16); pages[3]:GetRegions():SetText("Reputation Bar Options")
repEditBox = CreateTemplateBox(pages[3], "Text Format", -50, "repTemplate")
repColorBox = CreateColorBox(pages[3], "Main Reputation Color", 16, -130, "repColor")

local resetRepBtn = CreateFrame("Button", nil, pages[3], "UIPanelButtonTemplate"); resetRepBtn:SetSize(140, 26); resetRepBtn:SetPoint("BOTTOMRIGHT", -16, 16); resetRepBtn:SetText("Reset Defaults")
resetRepBtn:SetScript("OnClick", function() OdysseusDB.xpBar.repTemplate = defaults.repTemplate; OdysseusDB.xpBar.repColor = {r = defaults.repColor.r, g = defaults.repColor.g, b = defaults.repColor.b}; repEditBox:SetText(defaults.repTemplate); repColorBox:SetBackdropColor(defaults.repColor.r, defaults.repColor.g, defaults.repColor.b, 1); WakeBars(); UpdateBar(); SleepBars() end)

-- PAGE 4: DELVES
pages[4]:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"):SetPoint("TOPLEFT", 16, -16); pages[4]:GetRegions():SetText("Delves Mini-Bar Options")
delveCompEditBox = CreateTemplateBox(pages[4], "Companion Text Format (Top Bar)", -50, "delveCompTemplate")
delveJourEditBox = CreateTemplateBox(pages[4], "Journey Text Format (Bottom Bar)", -120, "delveJourTemplate")

-- THE FIX: Placed side-by-side horizontally to save space!
delveCompColorBox = CreateColorBox(pages[4], "Companion Bar Color", 16, -190, "delveCompColor")
delveJourColorBox = CreateColorBox(pages[4], "Journey Bar Color", 280, -190, "delveJourColor")

local delveWidthSlider = CreatePremiumSlider(pages[4], "Delve Bar Width", -230, "delveBarWidth", 100, 1000, 10, function() ApplyDimensions(); WakeBars(); SleepBars() end)
local delveHeightSlider = CreatePremiumSlider(pages[4], "Delve Bar Height", -290, "delveBarHeight", 20, 100, 2, function() ApplyDimensions(); WakeBars(); SleepBars() end)
local delveScaleSlider = CreatePremiumSlider(pages[4], "Delve Bar Scale", -350, "delveBarScale", 0.5, 2.0, 0.05, function() ApplyDimensions(); WakeBars(); SleepBars() end)

local resetDelveBtn = CreateFrame("Button", nil, pages[4], "UIPanelButtonTemplate"); resetDelveBtn:SetSize(140, 26); resetDelveBtn:SetPoint("BOTTOMRIGHT", -16, 16); resetDelveBtn:SetText("Reset Defaults")
resetDelveBtn:SetScript("OnClick", function() 
    OdysseusDB.xpBar.delveCompTemplate = defaults.delveCompTemplate; OdysseusDB.xpBar.delveJourTemplate = defaults.delveJourTemplate; OdysseusDB.xpBar.delveCompColor = {r = defaults.delveCompColor.r, g = defaults.delveCompColor.g, b = defaults.delveCompColor.b}; OdysseusDB.xpBar.delveJourColor = {r = defaults.delveJourColor.r, g = defaults.delveJourColor.g, b = defaults.delveJourColor.b}; 
    OdysseusDB.xpBar.delveBarWidth = defaults.delveBarWidth; OdysseusDB.xpBar.delveBarHeight = defaults.delveBarHeight; OdysseusDB.xpBar.delveBarScale = defaults.delveBarScale;
    OdysseusDB.xpBar.delveBarPos = {p = defaults.delveBarPos.p, rP = defaults.delveBarPos.rP, x = defaults.delveBarPos.x, y = defaults.delveBarPos.y};
    delveCompEditBox:SetText(defaults.delveCompTemplate); delveJourEditBox:SetText(defaults.delveJourTemplate); delveCompColorBox:SetBackdropColor(defaults.delveCompColor.r, defaults.delveCompColor.g, defaults.delveCompColor.b, 1); delveJourColorBox:SetBackdropColor(defaults.delveJourColor.r, defaults.delveJourColor.g, defaults.delveJourColor.b, 1); 
    delveWidthSlider:SetValue(defaults.delveBarWidth); delveHeightSlider:SetValue(defaults.delveBarHeight); delveScaleSlider:SetValue(defaults.delveBarScale);
    delveBar:ClearAllPoints(); delveBar:SetPoint(defaults.delveBarPos.p, UIParent, defaults.delveBarPos.rP, defaults.delveBarPos.x, defaults.delveBarPos.y)
    ApplyDimensions(); WakeBars(); UpdateBar(); SleepBars() 
end)

-- PAGE 5: HELP
local helpText = pages[5]:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
helpText:SetPoint("TOPLEFT", 16, -16); helpText:SetJustifyH("LEFT")
helpText:SetText(
    "|cFFFFD100EXPERIENCE TAGS:|r\n" ..
    "|cFFFFFF00[curXP]|r - Current XP  |  |cFFFFFF00[maxXP]|r - Max XP  |  |cFFFFFF00[needXP]|r - Remaining XP\n" ..
    "|cFFFFFF00[curPC]|r - Current %  |  |cFFFFFF00[needPC]|r - Remaining %  |  |cFFFFFF00[restPC]|r - Rested %\n" ..
    "|cFFFFFF00[pLVL]|r - Current Lvl  |  |cFFFFFF00[nLVL]|r - Next Lvl  |  |cFFFFFF00[mLVL]|r - Max Lvl\n" ..
    "|cFFFFFF00[restXP]|r - Rested XP Value  |  |cFFFFFF00[restLVL]|r - Rested XP (In Levels)\n" ..
    "|cFFFFFF00[KTL]|r - Kills to Level  |  |cFFFFFF00[BTL]|r - Bubbles to Level\n\n" ..
    "|cFFFFD100REPUTATION TAGS:|r\n" ..
    "|cFF00FF00[faction]|r - Faction Name  |  |cFF00FF00[standing]|r - Standing (Revered, etc.)\n" ..
    "|cFF00FF00[curRep]|r - Current Rep  |  |cFF00FF00[maxRep]|r - Max Rep  |  |cFF00FF00[needRep]|r - Remaining Rep\n" ..
    "|cFF00FF00[repPC]|r - Current %  |  |cFF00FF00[needPC]|r - Remaining %\n\n" ..
    "|cFFFFD100DELVES TAGS (Companion uses XP tags, Journey uses Rep tags):|r\n" ..
    "|cFF00FFFF[compName]|r - Auto Name  |  |cFF00FFFF[curXP]|r - Comp XP  |  |cFF00FFFF[maxXP]|r - Max Comp XP\n" ..
    "|cFF00FFFF[pLVL]|r - Comp Level  |  |cFF00FFFF[curRep]|r - Journey Rep  |  |cFF00FFFF[maxRep]|r - Journey Max\n" ..
    "|cFF00FFFF[repPC]|r - Journey %"
)

-- ==========================================
-- 8. EVENT LISTENERS & DB MERGER
-- ==========================================
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("SCENARIO_UPDATE")
f:RegisterEvent("UPDATE_INSTANCE_INFO") 
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("UPDATE_EXHAUSTION")
f:RegisterEvent("UPDATE_FACTION")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.xpBar = OdysseusDB.xpBar or {}
        
        for k, v in pairs(defaults) do
            if OdysseusDB.xpBar[k] == nil then
                if type(v) == "table" then OdysseusDB.xpBar[k] = {p = v.p, rP = v.rP, x = v.x, y = v.y, r = v.r, g = v.g, b = v.b} else OdysseusDB.xpBar[k] = v end
            end
        end

        xpEditBox:SetText(OdysseusDB.xpBar.xpTemplate); repEditBox:SetText(OdysseusDB.xpBar.repTemplate)
        delveCompEditBox:SetText(OdysseusDB.xpBar.delveCompTemplate); delveJourEditBox:SetText(OdysseusDB.xpBar.delveJourTemplate)
        
        hideBlizzCheck:SetChecked(OdysseusDB.xpBar.hideBlizz)
        autoHideCheck:SetChecked(OdysseusDB.xpBar.autoHide)
        
        repTimeSlider:SetValue(OdysseusDB.xpBar.repDisplayTime)
        fadeDelaySlider:SetValue(OdysseusDB.xpBar.fadeDelay)
        activeAlphaSlider:SetValue(OdysseusDB.xpBar.activeAlpha)
        fadedAlphaSlider:SetValue(OdysseusDB.xpBar.fadedAlpha)
        
        xpWidthSlider:SetValue(OdysseusDB.xpBar.xpBarWidth); xpHeightSlider:SetValue(OdysseusDB.xpBar.xpBarHeight); xpScaleSlider:SetValue(OdysseusDB.xpBar.xpBarScale)
        delveWidthSlider:SetValue(OdysseusDB.xpBar.delveBarWidth); delveHeightSlider:SetValue(OdysseusDB.xpBar.delveBarHeight); delveScaleSlider:SetValue(OdysseusDB.xpBar.delveBarScale)
        
        local cXP, cRest, cRep = OdysseusDB.xpBar.xpColor, OdysseusDB.xpBar.restColor, OdysseusDB.xpBar.repColor
        local cDC, cDJ = OdysseusDB.xpBar.delveCompColor, OdysseusDB.xpBar.delveJourColor
        xpColorBox:SetBackdropColor(cXP.r, cXP.g, cXP.b, 1); restColorBox:SetBackdropColor(cRest.r, cRest.g, cRest.b, 1); repColorBox:SetBackdropColor(cRep.r, cRep.g, cRep.b, 1)
        delveCompColorBox:SetBackdropColor(cDC.r, cDC.g, cDC.b, 1); delveJourColorBox:SetBackdropColor(cDJ.r, cDJ.g, cDJ.b, 1)
        
        local xpP = OdysseusDB.xpBar.xpBarPos
        xpBar:ClearAllPoints(); xpBar:SetPoint(xpP.p, UIParent, xpP.rP, xpP.x, xpP.y)
        
        local dbP = OdysseusDB.xpBar.delveBarPos
        delveBar:ClearAllPoints(); delveBar:SetPoint(dbP.p, UIParent, dbP.rP, dbP.x, dbP.y)
        
        ApplyDimensions()
        lastXP, lastMaxXP = UnitXP("player"), UnitXPMax("player")
        WakeBars(); SleepBars()

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        ApplyBlizzardKiller()
        TriggerAggressiveDelveCheck()
        WakeBars(); SleepBars()

    elseif event == "SCENARIO_UPDATE" or event == "UPDATE_INSTANCE_INFO" then
        UpdateBar()

    elseif event == "PLAYER_XP_UPDATE" then
        local currentXP, maxXP = UnitXP("player"), UnitXPMax("player")
        if currentXP > lastXP and maxXP == lastMaxXP then lastXPGain = currentXP - lastXP
        elseif currentXP < lastXP or maxXP > lastMaxXP then lastXPGain = (lastMaxXP - lastXP) + currentXP end
        
        lastXP, lastMaxXP = currentXP, maxXP
        if forceRepDisplay then forceRepDisplay = false; if repTimer then repTimer:Cancel() end end
        WakeBars(); UpdateBar(); SleepBars()

    elseif event == "UPDATE_FACTION" then
        local isMaxLevel = (UnitLevel("player") >= (GetMaxPlayerLevel and GetMaxPlayerLevel() or 80)) or (IsXPUserDisabled and IsXPUserDisabled())
        if not isMaxLevel then
            forceRepDisplay = true
            if repTimer then repTimer:Cancel() end
            repTimer = C_Timer.NewTimer(OdysseusDB.xpBar.repDisplayTime or 15, function() 
                forceRepDisplay = false; 
                WakeBars(); UpdateBar(); SleepBars() 
            end)
        end
        WakeBars(); UpdateBar(); SleepBars()

    elseif event == "PLAYER_REGEN_DISABLED" then
        WakeBars()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        SleepBars()
    end
end)

SLASH_XPCONFIG1 = "/xpconfig"
SlashCmdList["XPCONFIG"] = function() config:SetShown(not config:IsShown()) end

SLASH_DELVETEST1 = "/delvetest"
SlashCmdList["DELVETEST"] = function()
    isTestingDelve = not isTestingDelve; UpdateBar()
    if isTestingDelve then print("|cFF00FF00Odysseus:|r Delves UI forced ON.") else print("|cFFFF0000Odysseus:|r Delves UI forced OFF.") end
end

SLASH_DELVEDEBUG1 = "/delvedebug"
SlashCmdList["DELVEDEBUG"] = function()
    local inInstance, instanceType = IsInInstance()
    local name, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    local scenarioType = "N/A"
    if C_Scenario and C_Scenario.GetInfo then
        local sInfo = C_Scenario.GetInfo()
        if sInfo then scenarioType = tostring(sInfo.scenarioType) end
    end
    print("|cFF00FFFF--- Odysseus Delve Radar ---|r")
    print("InInstance: ", tostring(inInstance), " | Type:", tostring(instanceType))
    print("Inst Name:", tostring(name))
    print("Inst ID:", tostring(instanceID), " | Diff ID:", tostring(difficultyID))
    print("UI Map ID:", tostring(uiMapID))
    print("Scenario Type:", scenarioType)
end

SLASH_OUSDEBUG1 = "/ousdebug"
SlashCmdList["OUSDEBUG"] = function()
    isDebugOn = not isDebugOn
    if isDebugOn then print("|cFF00FFFFOdysseus:|r Global Debug Mode |cFF00FF00ENABLED|r.") else print("|cFF00FFFFOdysseus:|r Global Debug Mode |cFFFF0000DISABLED|r.") end
end