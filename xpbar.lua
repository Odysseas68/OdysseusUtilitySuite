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
    delveBarPos = {p = "TOP", rP = "TOP", x = 0, y = -150},
    toastEnabled = true,
    toastSound = false,
    toastPos = {p = "TOP", rP = "TOP", x = 0, y = -120},
    xpFont = "Friz Quadrata TT",
    xpFontSize = 12,
    repMenuMod = "CTRL",
    favFactions = {}
}

local function DeepCopyTable(src)
    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then dest[k] = DeepCopyTable(v) else dest[k] = v end
    end
    return dest
end

local forceRepDisplay = false
local repTimer = nil
local lastXP, lastMaxXP, lastXPGain = 0, 0, 0
local isTestingDelve = false
local delveCheckTicker = nil
local isDebugOn = false 
local sleepTimer = nil
local fadeTicker = nil
local sessionXP = 0
local sessionRep = {}
local repCache = { renown = {}, paragon = {} }
local lastGainedFactionName = nil 

local function DebugPrint(msg)
    if isDebugOn then print("|cFF00FFFF[OUS Debug]:|r " .. tostring(msg)) end
end

local function FormatLargeNumber(n)
    if not n then return 0 end
    if n >= 1000000 then return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return tostring(n) end
end

-- ==========================================
-- 2. UNIVERSAL REPUTATION ENGINE (WITH ICONS)
-- ==========================================
local function GetFactionDetails(factionID)
    if not factionID then return nil end
    local data = C_Reputation.GetFactionDataByID(factionID)
    if not data then return nil end
    
    local name = data.name
    local reaction = data.reaction or 4
    local standingText = GetText("FACTION_STANDING_LABEL" .. reaction) or "Neutral"
    local curRep, maxRep = 0, 1
    local isMaxed, hasRewardPending = false, false
    local iconPath = "Interface\\Icons\\Achievement_Reputation_01" 
    local textureKit = nil
    
    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        local majorData = C_MajorFactions.GetMajorFactionData(factionID)
        if majorData then
            standingText = "Renown " .. majorData.renownLevel
            curRep = majorData.renownReputationEarned or 0
            maxRep = majorData.renownLevelThreshold or 1
            if majorData.textureKit then 
                textureKit = majorData.textureKit
                iconPath = "Interface\\Icons\\UI_MajorFaction_" .. textureKit 
            end
            if C_MajorFactions.HasMaximumRenown(factionID) then
                isMaxed = true; standingText = "Max Renown"; curRep = 1; maxRep = 1
            end
        end
    end
    
    if not isMaxed and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local repInfo = C_GossipInfo.GetFriendshipReputation(factionID)
        if repInfo and repInfo.friendshipFactionID > 0 then
            if repInfo.texture and repInfo.texture > 0 then iconPath = repInfo.texture end
            local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(factionID)
            if rankInfo and rankInfo.currentLevel then
                standingText = "Rank " .. rankInfo.currentLevel
                if rankInfo.currentLevel >= rankInfo.maxLevel then
                    isMaxed = true; standingText = "Max Rank"; curRep = 1; maxRep = 1
                else
                    curRep = repInfo.standing - repInfo.reactionThreshold
                    maxRep = repInfo.nextThreshold - repInfo.reactionThreshold
                end
            end
        end
    end
    
    if curRep == 0 and maxRep == 1 and data.currentStanding then
        if data.currentValue then 
            curRep, maxRep = data.currentValue, data.maxValue
        else
            curRep = data.currentStanding - data.currentReactionThreshold
            maxRep = data.nextReactionThreshold - data.currentReactionThreshold
        end
        if curRep >= maxRep and maxRep > 0 then isMaxed = true; curRep = 1; maxRep = 1 end
    end
    
    if isMaxed and C_Reputation.IsFactionParagon(factionID) then
        local currentValue, threshold, _, hasReward = C_Reputation.GetFactionParagonInfo(factionID)
        if currentValue and threshold and threshold > 0 then
            isMaxed = false; curRep = currentValue % threshold; maxRep = threshold
            hasRewardPending = hasReward
            if hasRewardPending then
                standingText = "Paragon (Reward Ready!)"
                if curRep == 0 then curRep = maxRep end
            else
                standingText = "Paragon"
            end
        end
    end
    
    if maxRep == 0 then maxRep = 1 end
    local repPC = math.floor((curRep / maxRep) * 100)
    
    return { name = name, standingText = standingText, curRep = curRep, maxRep = maxRep, repPC = repPC, isMaxed = isMaxed, hasRewardPending = hasRewardPending, description = data.description, reaction = reaction, icon = iconPath, textureKit = textureKit }
end

-- ==========================================
-- 3. CREATE THE MIDNIGHT VISUALS & TOAST
-- ==========================================
OUS.xpBarFrame = CreateFrame("Frame", "OdysseusXPBar", UIParent, "BackdropTemplate")
local xpBar = OUS.xpBarFrame
xpBar.bg = xpBar:CreateTexture(nil, "BACKGROUND"); xpBar.bg:SetAllPoints(true); xpBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)
xpBar.restedBar = CreateFrame("StatusBar", nil, xpBar); xpBar.restedBar:SetAllPoints(true); xpBar.restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar.progressBar = CreateFrame("StatusBar", nil, xpBar); xpBar.progressBar:SetAllPoints(true); xpBar.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); xpBar:SetBackdropBorderColor(0, 0, 0, 1)
xpBar.text = xpBar.progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); xpBar.text:SetPoint("CENTER", xpBar, "CENTER", 0, 0); 

xpBar:SetMovable(true); xpBar:EnableMouse(true); xpBar:RegisterForDrag("LeftButton")
xpBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
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
delveBar.compText = delveBar.compBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); delveBar.compText:SetPoint("CENTER"); 
delveBar.jourBar = CreateFrame("StatusBar", nil, delveBar); delveBar.jourBar:SetPoint("BOTTOM", 0, 1); delveBar.jourBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
delveBar.jourText = delveBar.jourBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); delveBar.jourText:SetPoint("CENTER"); 

delveBar:SetMovable(true); delveBar:EnableMouse(true); delveBar:RegisterForDrag("LeftButton")
delveBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
delveBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    OdysseusDB.xpBar.delveBarPos = {p = point, rP = relPoint, x = x, y = y}
end)
delveBar:Hide()

local toast = CreateFrame("Frame", "OdysseusToastFrame", UIParent, "BackdropTemplate")
toast:SetSize(300, 56); toast:SetFrameStrata("DIALOG")
toast:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
toast:SetBackdropColor(0.07, 0.05, 0.1, 0.95); toast:SetBackdropBorderColor(0.6, 0.2, 0.8, 1); toast:Hide(); toast:SetAlpha(0)
toast:SetMovable(true); toast:EnableMouse(true); toast:RegisterForDrag("LeftButton")
toast:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
toast:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local point, _, relPoint, x, y = self:GetPoint(); OdysseusDB.xpBar.toastPos = {p = point, rP = relPoint, x = x, y = y} end)

toast.icon = toast:CreateTexture(nil, "ARTWORK"); toast.icon:SetSize(36, 36); toast.icon:SetPoint("LEFT", 10, 0); toast.icon:SetTexture("Interface\\Icons\\Achievement_Reputation_01"); toast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 10, -2); toast.title:SetText("Renown Increased!")
toast.subText = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); toast.subText:SetPoint("BOTTOMLEFT", toast.icon, "BOTTOMRIGHT", 10, 2)

local toastAnim = toast:CreateAnimationGroup()
local fade1 = toastAnim:CreateAnimation("Alpha"); fade1:SetFromAlpha(0); fade1:SetToAlpha(1); fade1:SetDuration(0.4); fade1:SetOrder(1)
local wait = toastAnim:CreateAnimation("Alpha"); wait:SetFromAlpha(1); wait:SetToAlpha(1); wait:SetDuration(4.5); wait:SetOrder(2)
local fade2 = toastAnim:CreateAnimation("Alpha"); fade2:SetFromAlpha(1); fade2:SetToAlpha(0); fade2:SetDuration(0.6); fade2:SetOrder(3)
toastAnim:SetScript("OnFinished", function() toast:Hide() end)

function OUS.ShowToast(title, subText, iconPath)
    if not OdysseusDB or not OdysseusDB.xpBar.toastEnabled then return end
    toast.title:SetText(title); toast.subText:SetText(subText)
    if iconPath then toast.icon:SetTexture(iconPath) else toast.icon:SetTexture("Interface\\Icons\\Achievement_Reputation_01") end
    toast:Show(); toastAnim:Stop(); toastAnim:Play()
    if OdysseusDB.xpBar.toastSound then PlaySound(44269, "Master") end
end

-- ==========================================
-- 4. DIMENSIONS, FONTS & FADE ENGINE
-- ==========================================
local function ApplyFonts()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then fontPath = LSM:Fetch("font", db.xpFont) or fontPath end
    local size = db.xpFontSize or 12
    xpBar.text:SetFont(fontPath, size, "OUTLINE")
    delveBar.compText:SetFont(fontPath, math.max(8, size - 2), "OUTLINE")
    delveBar.jourText:SetFont(fontPath, math.max(8, size - 2), "OUTLINE")
end

local function ApplyDimensions()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    xpBar:SetSize(db.xpBarWidth or 400, db.xpBarHeight or 24); xpBar:SetScale(db.xpBarScale or 1.0)
    delveBar:SetSize(db.delveBarWidth or 300, db.delveBarHeight or 40); delveBar:SetScale(db.delveBarScale or 1.0)
    local innerHeight = ((db.delveBarHeight or 40) - 2) / 2
    delveBar.compBar:SetSize((db.delveBarWidth or 300) - 2, innerHeight); delveBar.jourBar:SetSize((db.delveBarWidth or 300) - 2, innerHeight)
end

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
    if not OdysseusDB or not OdysseusDB.xpBar.autoHide then FadeBarsTo((OdysseusDB and OdysseusDB.xpBar.activeAlpha or 100) / 100); return end
    if sleepTimer then sleepTimer:Cancel(); sleepTimer = nil end
    FadeBarsTo(OdysseusDB.xpBar.activeAlpha / 100)
end

local function SleepBars()
    if not OdysseusDB or not OdysseusDB.xpBar.autoHide then return end
    if UnitAffectingCombat("player") or xpBar:IsMouseOver() or delveBar:IsMouseOver() or forceRepDisplay or (OUS.favHoverFrame and OUS.favHoverFrame:IsMouseOver()) then return end
    if sleepTimer then sleepTimer:Cancel() end
    sleepTimer = C_Timer.NewTimer(OdysseusDB.xpBar.fadeDelay, function()
        if not UnitAffectingCombat("player") and not xpBar:IsMouseOver() and not delveBar:IsMouseOver() and not forceRepDisplay and not (OUS.favHoverFrame and OUS.favHoverFrame:IsMouseOver()) then
            FadeBarsTo(OdysseusDB.xpBar.fadedAlpha / 100)
        end
    end)
end

xpBar:HookScript("OnEnter", WakeBars); xpBar:HookScript("OnLeave", SleepBars)
delveBar:HookScript("OnEnter", WakeBars); delveBar:HookScript("OnLeave", SleepBars)

-- ==========================================
-- 5. PARSERS & HELPERS (THE FIX: RESTORED BLOCK)
-- ==========================================
local function ParseXPText(template, curXP, maxXP, restXP, level, mLVL, ktl, isMaxed, compName)
    local str = template or ""
    local needXP = maxXP - curXP
    local curPC = maxXP > 0 and math.floor((curXP / maxXP) * 100) or 0
    local needPC = maxXP > 0 and math.ceil((needXP / maxXP) * 100) or 0
    local restPC = (maxXP > 0 and restXP > 0) and math.floor((restXP / maxXP) * 100) or 0
    local restLVL = maxXP > 0 and string.format("%.2f", restXP / maxXP) or "0"
    local btl = maxXP > 0 and math.ceil(needXP / (maxXP / 20)) or 0

    if isMaxed then
        str = string.gsub(str, "%[curXP%]/%[maxXP%]", "Max Level"); str = string.gsub(str, "%[curXP%]", "Max"); str = string.gsub(str, "%[maxXP%]", "Max"); str = string.gsub(str, "%[needXP%]", "0")
    else
        str = string.gsub(str, "%[curXP%]", FormatLargeNumber(curXP)); str = string.gsub(str, "%[maxXP%]", FormatLargeNumber(maxXP)); str = string.gsub(str, "%[needXP%]", FormatLargeNumber(needXP))
    end
    str = string.gsub(str, "%[restXP%]", FormatLargeNumber(restXP)); str = string.gsub(str, "%[curPC%]", curPC); str = string.gsub(str, "%[needPC%]", needPC); str = string.gsub(str, "%[restPC%]", restPC); str = string.gsub(str, "%[pLVL%]", level); str = string.gsub(str, "%[nLVL%]", level + 1); str = string.gsub(str, "%[mLVL%]", mLVL); str = string.gsub(str, "%[restLVL%]", restLVL); str = string.gsub(str, "%[KTL%]", ktl or "?"); str = string.gsub(str, "%[BTL%]", btl)
    if compName then str = string.gsub(str, "%[compName%]", compName) end
    return str
end

local function ParseRepText(template, name, standingText, curRep, maxRep, isMaxed)
    local str = template or ""
    local needRep = maxRep - curRep
    local repPC = maxRep > 0 and math.floor((curRep / maxRep) * 100) or 100
    local needPC = maxRep > 0 and math.ceil((needRep / maxRep) * 100) or 0

    if isMaxed then
        str = string.gsub(str, "%[curRep%]/%[maxRep%]", "Max Level"); str = string.gsub(str, "%[curRep%]", "Max"); str = string.gsub(str, "%[maxRep%]", "Max"); str = string.gsub(str, "%[needRep%]", "0")
    else
        str = string.gsub(str, "%[curRep%]", FormatLargeNumber(curRep)); str = string.gsub(str, "%[maxRep%]", FormatLargeNumber(maxRep)); str = string.gsub(str, "%[needRep%]", FormatLargeNumber(needRep))
    end
    str = string.gsub(str, "%[faction%]", name or "Unknown"); str = string.gsub(str, "%[standing%]", standingText or "Neutral"); str = string.gsub(str, "%[repPC%]", repPC); str = string.gsub(str, "%[needPC%]", needPC)
    return str
end

local function ApplyBlizzardKiller()
    if OdysseusDB and OdysseusDB.xpBar.hideBlizz and StatusTrackingBarManager then StatusTrackingBarManager:UnregisterAllEvents(); StatusTrackingBarManager:Hide() end
end

local function GetActiveDelveCompanion()
    if not OdysseusDB then return "Companion", 2640 end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player") or 0
    if (instanceID and instanceID >= 2800) or (uiMapID >= 2350) then return "Valeera Sanguinar", OdysseusDB.xpBar.delveValeeraID or 2744 else return "Brann Bronzebeard", OdysseusDB.xpBar.delveBrannID or 2640 end
end

local function IsPlayerInDelve()
    if isTestingDelve then return true end
    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID and difficultyID >= 205 and difficultyID <= 220 then return true end
    return false
end

local function ScanFactionsForPopups(isInitialLogin)
    if not C_Reputation or not C_Reputation.GetNumFactions then return end
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.factionID then
            local fid = data.factionID
            local name = data.name
            if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                local majorData = C_MajorFactions.GetMajorFactionData(fid)
                if majorData then
                    local rLvl = majorData.renownLevel
                    if not isInitialLogin and repCache.renown[fid] and rLvl > repCache.renown[fid] then
                        local tex = majorData.textureKit and ("Interface\\Icons\\UI_MajorFaction_" .. majorData.textureKit) or nil
                        OUS.ShowToast("Renown Increased!", name .. " reached Rank " .. rLvl, tex)
                    end
                    repCache.renown[fid] = rLvl
                end
            end
            if C_Reputation.IsFactionParagon(fid) then
                local _, _, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(fid)
                if not isInitialLogin and hasRewardPending and not repCache.paragon[fid] then
                    OUS.ShowToast("Paragon Reward!", "A reward is ready for " .. name)
                end
                repCache.paragon[fid] = hasRewardPending
            end
        end
    end
end

-- ==========================================
-- 6. BAR UPDATERS
-- ==========================================
local function UpdateDelveBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    if IsPlayerInDelve() then
        local compName, compFactionID = GetActiveDelveCompanion()
        local cXP, cMax, cLvl, isMaxed = 0, 1, 1, false
        if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
            local repInfo = C_GossipInfo.GetFriendshipReputation(compFactionID)
            if repInfo and repInfo.friendshipFactionID > 0 then
                local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(compFactionID)
                if rankInfo and rankInfo.currentLevel then
                    cLvl = rankInfo.currentLevel
                    if rankInfo.currentLevel >= rankInfo.maxLevel then isMaxed = true; cMax = 1; cXP = 1 else cXP = repInfo.standing - repInfo.reactionThreshold; cMax = repInfo.nextThreshold - repInfo.reactionThreshold end
                end
            end
        end
        local jRep, jMax = 0, 1
        local journeyData = C_Reputation.GetFactionDataByID(db.journeyID)
        if journeyData then jRep = journeyData.currentStanding; jMax = journeyData.nextReactionThreshold; if jMax == 0 then jMax = 1 end end
        if isTestingDelve and cMax <= 1 and jMax <= 1 then cXP, cMax, cLvl = 25000, 83000, 15; jRep, jMax = 1200, 5000; isMaxed = false end

        delveBar.compBar:SetMinMaxValues(0, cMax); delveBar.compBar:SetValue(cXP); delveBar.compBar:SetStatusBarColor(db.delveCompColor.r, db.delveCompColor.g, db.delveCompColor.b, 1)
        delveBar.compText:SetText(ParseXPText(db.delveCompTemplate or defaults.delveCompTemplate, cXP, cMax, 0, cLvl, 60, "?", isMaxed, compName))
        delveBar.jourBar:SetMinMaxValues(0, jMax); delveBar.jourBar:SetValue(jRep); delveBar.jourBar:SetStatusBarColor(db.delveJourColor.r, db.delveJourColor.g, db.delveJourColor.b, 1)
        delveBar.jourText:SetText(ParseRepText(db.delveJourTemplate or defaults.delveJourTemplate, "Journey", "Active", jRep, jMax, false))
        delveBar:Show()
    else delveBar:Hide() end
end

local function UpdateBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    local playerLevel = UnitLevel("player")
    local maxExpansionLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = (playerLevel >= maxExpansionLevel) or (IsXPUserDisabled and IsXPUserDisabled())
    
    local targetFactionID = nil
    if forceRepDisplay and lastGainedFactionName then
        if C_Reputation and C_Reputation.GetNumFactions then
            for i = 1, C_Reputation.GetNumFactions() do
                local data = C_Reputation.GetFactionDataByIndex(i)
                if data and data.name == lastGainedFactionName and not data.isHeader then targetFactionID = data.factionID; break end
            end
        end
    end
    if not targetFactionID then
        local w = C_Reputation.GetWatchedFactionData()
        if w then targetFactionID = w.factionID end
    end

    if not isMaxLevel and not (forceRepDisplay and targetFactionID) then
        local curXP, maxXP = UnitXP("player"), UnitXPMax("player")
        local restXP = GetXPExhaustion() or 0
        local ktl = "?"
        if lastXPGain > 0 then ktl = tostring(math.ceil((maxXP - curXP) / lastXPGain)) end

        xpBar.progressBar:SetMinMaxValues(0, maxXP); xpBar.progressBar:SetValue(curXP); xpBar.progressBar:SetStatusBarColor(db.xpColor.r, db.xpColor.g, db.xpColor.b, 0.9)
        if restXP > 0 then xpBar.restedBar:SetMinMaxValues(0, maxXP); xpBar.restedBar:SetValue(math.min(curXP + restXP, maxXP)); xpBar.restedBar:SetStatusBarColor(db.restColor.r, db.restColor.g, db.restColor.b, 0.6); xpBar.restedBar:Show() else xpBar.restedBar:Hide() end
        xpBar.text:SetText(ParseXPText(db.xpTemplate or defaults.xpTemplate, curXP, maxXP, restXP, playerLevel, maxExpansionLevel, ktl, false, nil)); xpBar:Show()
    else
        xpBar.restedBar:Hide()
        if targetFactionID then
            local info = GetFactionDetails(targetFactionID)
            if info then
                xpBar.progressBar:SetMinMaxValues(0, info.maxRep); xpBar.progressBar:SetValue(info.curRep); xpBar.progressBar:SetStatusBarColor(db.repColor.r, db.repColor.g, db.repColor.b, 0.9)
                xpBar.text:SetText(ParseRepText(db.repTemplate or defaults.repTemplate, info.name, info.standingText, info.curRep, info.maxRep, info.isMaxed)); xpBar:Show()
            else xpBar:Hide() end
        else xpBar:Hide() end
    end
    UpdateDelveBar()
end

local function TriggerAggressiveDelveCheck()
    if delveCheckTicker then delveCheckTicker:Cancel() end
    local checks = 0; delveCheckTicker = C_Timer.NewTicker(1, function() checks = checks + 1; if IsPlayerInDelve() or checks >= 10 then WakeBars(); UpdateBar(); SleepBars(); if delveCheckTicker then delveCheckTicker:Cancel() end end end)
end

-- ==========================================
-- 7. REPUTATION ADVANCED MENUS
-- ==========================================
local factionSelectFrame = CreateFrame("Frame", "OdysseusFactionSelectFrame", UIParent, "BackdropTemplate")
factionSelectFrame:SetSize(460, 500); factionSelectFrame:SetPoint("CENTER"); factionSelectFrame:SetFrameStrata("DIALOG")
factionSelectFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
factionSelectFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98); factionSelectFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1); factionSelectFrame:Hide()
factionSelectFrame:SetMovable(true); factionSelectFrame:EnableMouse(true); factionSelectFrame:RegisterForDrag("LeftButton")
factionSelectFrame:SetScript("OnDragStart", factionSelectFrame.StartMoving); factionSelectFrame:SetScript("OnDragStop", factionSelectFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, factionSelectFrame:GetName())
factionSelectFrame.headerBg = factionSelectFrame:CreateTexture(nil, "BACKGROUND", nil, 2); factionSelectFrame.headerBg:SetPoint("TOPLEFT", 4, -4); factionSelectFrame.headerBg:SetPoint("TOPRIGHT", -4, -4); factionSelectFrame.headerBg:SetHeight(30)
factionSelectFrame.headerBg:SetColorTexture(1, 1, 1, 1); factionSelectFrame.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))
factionSelectFrame.title = factionSelectFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); factionSelectFrame.title:SetPoint("TOP", 0, -8); factionSelectFrame.title:SetText("Select Favorites to Track"); factionSelectFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
local fsCloseBtn = CreateFrame("Button", nil, factionSelectFrame, "UIPanelCloseButton"); fsCloseBtn:SetPoint("TOPRIGHT", -2, -2)
local fsSaveBtn = CreateFrame("Button", nil, factionSelectFrame, "UIPanelButtonTemplate"); fsSaveBtn:SetSize(120, 26); fsSaveBtn:SetPoint("BOTTOMRIGHT", -15, 15); fsSaveBtn:SetText("Save Favorites")
local fsCancelBtn = CreateFrame("Button", nil, factionSelectFrame, "UIPanelButtonTemplate"); fsCancelBtn:SetSize(100, 26); fsCancelBtn:SetPoint("RIGHT", fsSaveBtn, "LEFT", -10, 0); fsCancelBtn:SetText("Cancel"); fsCancelBtn:SetScript("OnClick", function() factionSelectFrame:Hide() end)
local fsScroll = CreateFrame("ScrollFrame", "OdysseusFactionScroll", factionSelectFrame, "UIPanelScrollFrameTemplate"); fsScroll:SetPoint("TOPLEFT", 15, -45); fsScroll:SetPoint("BOTTOMRIGHT", -35, 50)
local fsScrollChild = CreateFrame("Frame"); fsScroll:SetScrollChild(fsScrollChild)

local fsButtons = {}
local tempFavorites = {}

local function RefreshFactionSelectTree()
    if not C_Reputation or not C_Reputation.GetNumFactions then return end
    for _, btn in pairs(fsButtons) do btn:Hide() end
    local yOffset = 0
    local numFactions = C_Reputation.GetNumFactions()
    
    for i = 1, numFactions do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and not data.isHidden then
            local btn = fsButtons[i]
            if not btn then
                btn = CreateFrame("Button", nil, fsScrollChild, "BackdropTemplate")
                btn:SetSize(380, 26)
                btn:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
                btn:SetBackdropColor(0, 0, 0, 0.4); btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                btn.expand = CreateFrame("Button", nil, btn); btn.expand:SetSize(16, 16); btn.expand:SetNormalFontObject("GameFontNormal")
                btn.check = CreateFrame("CheckButton", nil, btn, "ChatConfigCheckButtonTemplate"); btn.check:SetSize(24, 24); btn.check:SetHitRectInsets(0, 0, 0, 0)
                btn.wbIcon = btn:CreateTexture(nil, "OVERLAY"); btn.wbIcon:SetSize(14, 14)
                local success = pcall(function() btn.wbIcon:SetAtlas("warbands-icon") end); if not success then btn.wbIcon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend") end
                btn.facIcon = btn:CreateTexture(nil, "OVERLAY"); btn.facIcon:SetSize(16, 16)
                btn.bar = CreateFrame("StatusBar", nil, btn); btn.bar:SetSize(100, 14); btn.bar:SetPoint("RIGHT", -5, 0); btn.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                btn.bar.bg = btn.bar:CreateTexture(nil, "BACKGROUND"); btn.bar.bg:SetAllPoints(); btn.bar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                btn.bar.txt = btn.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); btn.bar.txt:SetPoint("CENTER"); btn.bar.txt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                btn.bar:EnableMouse(false)
                btn.txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); btn.txt:SetJustifyH("LEFT"); btn.txt:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE"); btn.txt:SetPoint("RIGHT", btn.bar, "LEFT", -5, 0); btn.txt:SetWordWrap(false)
                
                local function RowHoverOn()
                    btn:SetBackdropColor(0.2, 0.15, 0.3, 0.8); btn:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
                    local info = GetFactionDetails(btn.data.factionID)
                    if info then
                        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                        local iconStr = ""
                        if info.textureKit then iconStr = "|A:UI-MajorFaction-"..info.textureKit..":18:18|a " elseif info.icon then iconStr = "|T"..info.icon..":18:18:0:0|t " end
                        GameTooltip:SetText(iconStr .. info.name, 0.6, 0.2, 0.8)
                        GameTooltip:AddLine(info.standingText .. " - " .. FormatLargeNumber(info.curRep) .. " / " .. FormatLargeNumber(info.maxRep), 1, 1, 1)
                        if info.hasRewardPending then GameTooltip:AddLine("Paragon Reward Ready!", 0, 1, 0) end
                        if info.description and info.description ~= "" then GameTooltip:AddLine(" "); GameTooltip:AddLine(info.description, 0.8, 0.8, 0.8, true) end
                        GameTooltip:Show()
                    end
                end
                local function RowHoverOff() btn:SetBackdropColor(0, 0, 0, 0.4); btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1); GameTooltip:Hide() end
                btn:SetScript("OnEnter", RowHoverOn); btn:SetScript("OnLeave", RowHoverOff)
                btn.check:HookScript("OnEnter", RowHoverOn); btn.check:HookScript("OnLeave", RowHoverOff)
                fsButtons[i] = btn
            end
            
            btn.data = data
            btn.check:SetChecked(tempFavorites[data.factionID] == true)
            local indent = data.isHeader and 5 or 25
            if data.isHeader and data.isHeaderWithRep then indent = 15 end
            btn.expand:ClearAllPoints(); btn.expand:SetPoint("LEFT", indent, 0)
            btn.check:ClearAllPoints(); btn.check:SetPoint("LEFT", btn.expand, "RIGHT", 0, 0)
            
            if data.isAccountWide then btn.wbIcon:SetPoint("LEFT", btn.check, "RIGHT", 2, 0); btn.wbIcon:Show(); btn.facIcon:SetPoint("LEFT", btn.wbIcon, "RIGHT", 4, 0) else btn.wbIcon:Hide(); btn.facIcon:SetPoint("LEFT", btn.check, "RIGHT", 4, 0) end

            local info = GetFactionDetails(data.factionID)
            if info and info.textureKit then local s = pcall(function() btn.facIcon:SetAtlas("UI-MajorFaction-" .. info.textureKit) end); if not s then btn.facIcon:SetTexture(info.icon) end elseif info and info.icon then btn.facIcon:SetTexture(info.icon) end
            if data.isHeader and not data.isHeaderWithRep then btn.facIcon:Hide() else btn.facIcon:Show() end
            btn.txt:SetPoint("LEFT", btn.facIcon, "RIGHT", 4, 0)
            
            if data.isHeader and not data.isHeaderWithRep then
                btn.bar:Hide(); btn.expand:Show(); btn.expand:SetText(data.isCollapsed and "[+]" or "[-]")
                btn.expand:SetScript("OnClick", function() if data.isCollapsed then C_Reputation.ExpandFactionHeader(i) else C_Reputation.CollapseFactionHeader(i) end; RefreshFactionSelectTree() end)
                btn.txt:SetText("|cFFB088FF" .. data.name .. "|r")
            else
                if data.isHeader then btn.expand:Show(); btn.expand:SetText(data.isCollapsed and "[+]" or "[-]"); btn.expand:SetScript("OnClick", function() if data.isCollapsed then C_Reputation.ExpandFactionHeader(i) else C_Reputation.CollapseFactionHeader(i) end; RefreshFactionSelectTree() end) else btn.expand:Hide() end
                btn.txt:SetText(data.name)
                if info then
                    btn.bar:Show(); btn.bar:SetMinMaxValues(0, info.maxRep); btn.bar:SetValue(info.curRep)
                    if info.hasRewardPending then btn.bar:SetStatusBarColor(0.2, 0.8, 0.4, 1) elseif string.find(info.standingText, "Renown") then btn.bar:SetStatusBarColor(0.0, 0.6, 0.8, 1) elseif string.find(info.standingText, "Paragon") then btn.bar:SetStatusBarColor(0.5, 0.3, 0.8, 1) elseif info.reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[info.reaction] then local c = FACTION_BAR_COLORS[info.reaction]; btn.bar:SetStatusBarColor(c.r, c.g, c.b, 1) else btn.bar:SetStatusBarColor(0.5, 0.5, 0.5, 1) end
                    local displayCur = info.isMaxed and info.maxRep or info.curRep; btn.bar.txt:SetText(FormatLargeNumber(displayCur) .. " / " .. FormatLargeNumber(info.maxRep))
                else btn.bar:Hide() end
            end
            
            btn.check:SetScript("OnClick", function(self)
                local isChecked = self:GetChecked(); tempFavorites[data.factionID] = isChecked
                if data.isHeader then
                    for j = i + 1, C_Reputation.GetNumFactions() do
                        local childData = C_Reputation.GetFactionDataByIndex(j)
                        if not childData then break end; if childData.isHeader and (childData.isChild == data.isChild or (not childData.isChild and data.isChild)) then break end; tempFavorites[childData.factionID] = isChecked
                    end
                    RefreshFactionSelectTree()
                end
            end)
            btn:ClearAllPoints(); btn:SetPoint("TOPLEFT", 0, -yOffset); btn:Show()
            yOffset = yOffset + 28
        end
    end
    fsScrollChild:SetSize(380, yOffset)
end

fsSaveBtn:SetScript("OnClick", function() if not OdysseusDB.xpBar.favFactions then OdysseusDB.xpBar.favFactions = {} end; OdysseusDB.xpBar.favFactions = DeepCopyTable(tempFavorites); factionSelectFrame:Hide() end)

OUS.favHoverFrame = CreateFrame("Frame", "OdysseusFavRepFrame", UIParent, "BackdropTemplate")
local favFrame = OUS.favHoverFrame
favFrame:SetSize(400, 200); favFrame:SetFrameStrata("TOOLTIP")
favFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 }})
favFrame:SetBackdropColor(0.05, 0.03, 0.08, 0.95); favFrame:SetBackdropBorderColor(0.6, 0.2, 0.8, 1); favFrame:Hide()
local favTitle = favFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); favTitle:SetPoint("TOP", 0, -8); favTitle:SetText("|cFFB088FFOdysseus Favorites Dashboard|r")
local favScroll = CreateFrame("ScrollFrame", "OdysseusFavScroll", favFrame, "UIPanelScrollFrameTemplate"); favScroll:SetPoint("TOPLEFT", 10, -25); favScroll:SetPoint("BOTTOMRIGHT", -30, 10)
local favScrollChild = CreateFrame("Frame"); favScroll:SetScrollChild(favScrollChild)
local favRows = {}

local function RefreshHoverFavorites()
    if not OdysseusDB or not OdysseusDB.xpBar.favFactions then return end
    for _, row in pairs(favRows) do row:Hide() end
    local favList = {}
    for fid, isFav in pairs(OdysseusDB.xpBar.favFactions) do if isFav then table.insert(favList, fid) end end
    if #favList == 0 then return end
    
    table.sort(favList, function(a, b) local da = C_Reputation.GetFactionDataByID(a); local db = C_Reputation.GetFactionDataByID(b); return (da and da.name or "") < (db and db.name or "") end)
    
    local yOffset = 0; local index = 1
    if C_Reputation and C_Reputation.GetNumFactions then
        for i = 1, C_Reputation.GetNumFactions() do
            local data = C_Reputation.GetFactionDataByIndex(i)
            if data and OdysseusDB.xpBar.favFactions[data.factionID] then
                if not (data.isHeader and not data.isHeaderWithRep) then
                    local info = GetFactionDetails(data.factionID)
                    if info then
                        local row = favRows[index]
                        if not row then
                            row = CreateFrame("Button", nil, favScrollChild, "BackdropTemplate"); row:SetSize(340, 26)
                            row:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
                            row:SetBackdropColor(0, 0, 0, 0.4); row:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                            row.wbIcon = row:CreateTexture(nil, "OVERLAY"); row.wbIcon:SetSize(14, 14); pcall(function() row.wbIcon:SetAtlas("warbands-icon") end)
                            row.facIcon = row:CreateTexture(nil, "OVERLAY"); row.facIcon:SetSize(16, 16)
                            row.bar = CreateFrame("StatusBar", nil, row); row.bar:SetSize(100, 14); row.bar:SetPoint("RIGHT", -5, 0); row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                            row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND"); row.bar.bg:SetAllPoints(); row.bar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                            row.bar.txt = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.bar.txt:SetPoint("CENTER"); row.bar.txt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                            row.bar:EnableMouse(false)
                            row.txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.txt:SetJustifyH("LEFT"); row.txt:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE"); row.txt:SetPoint("RIGHT", row.bar, "LEFT", -5, 0); row.txt:SetWordWrap(false)
                            
                            row:SetScript("OnEnter", function(self)
                                self:SetBackdropColor(0.2, 0.15, 0.3, 0.8); self:SetBackdropBorderColor(0.6, 0.2, 0.8, 1); WakeBars()
                                local rInfo = GetFactionDetails(self.factionID)
                                if rInfo then
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    local iconStr = ""
                                    if rInfo.textureKit then iconStr = "|A:UI-MajorFaction-"..rInfo.textureKit..":18:18|a " elseif rInfo.icon then iconStr = "|T"..rInfo.icon..":18:18:0:0|t " end
                                    GameTooltip:SetText(iconStr .. rInfo.name, 0.6, 0.2, 0.8)
                                    GameTooltip:AddLine(rInfo.standingText .. " - " .. FormatLargeNumber(rInfo.curRep) .. " / " .. FormatLargeNumber(rInfo.maxRep), 1, 1, 1)
                                    if rInfo.hasRewardPending then GameTooltip:AddLine("Paragon Reward Ready!", 0, 1, 0) end
                                    if rInfo.description and rInfo.description ~= "" then GameTooltip:AddLine(" "); GameTooltip:AddLine(rInfo.description, 0.8, 0.8, 0.8, true) end
                                    GameTooltip:Show()
                                end
                            end)
                            row:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0.4); self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1); GameTooltip:Hide(); C_Timer.After(0.1, CheckHideFavFrame) end)
                            favRows[index] = row
                        end
                        
                        row.factionID = data.factionID
                        if data.isAccountWide then row.wbIcon:SetPoint("LEFT", 5, 0); row.wbIcon:Show(); row.facIcon:SetPoint("LEFT", row.wbIcon, "RIGHT", 4, 0) else row.wbIcon:Hide(); row.facIcon:SetPoint("LEFT", 5, 0) end
                        if info.textureKit then local s = pcall(function() row.facIcon:SetAtlas("UI-MajorFaction-" .. info.textureKit) end); if not s then row.facIcon:SetTexture(info.icon) end else row.facIcon:SetTexture(info.icon) end
                        row.txt:SetPoint("LEFT", row.facIcon, "RIGHT", 4, 0); row.txt:SetText(info.name)
                        row.bar:SetMinMaxValues(0, info.maxRep); row.bar:SetValue(info.curRep)
                        
                        if info.hasRewardPending then row.bar:SetStatusBarColor(0.2, 0.8, 0.4, 1) elseif string.find(info.standingText, "Renown") then row.bar:SetStatusBarColor(0.0, 0.6, 0.8, 1) elseif string.find(info.standingText, "Paragon") then row.bar:SetStatusBarColor(0.5, 0.3, 0.8, 1) elseif info.reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[info.reaction] then local c = FACTION_BAR_COLORS[info.reaction]; row.bar:SetStatusBarColor(c.r, c.g, c.b, 1) else row.bar:SetStatusBarColor(0.5, 0.5, 0.5, 1) end
                        local displayCur = info.isMaxed and info.maxRep or info.curRep; row.bar.txt:SetText(FormatLargeNumber(displayCur) .. " / " .. FormatLargeNumber(info.maxRep))
                        
                        row:SetScript("OnClick", function()
                            local cIndex = nil
                            for j = 1, C_Reputation.GetNumFactions() do local d = C_Reputation.GetFactionDataByIndex(j); if d and d.factionID == data.factionID then cIndex = j; break end end
                            if cIndex then C_Reputation.SetWatchedFactionByIndex(cIndex); lastGainedFactionName = nil; forceRepDisplay = false; if UpdateBar then UpdateBar() end; favFrame:Hide() end
                        end)
                        
                        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -yOffset); row:Show()
                        yOffset = yOffset + 28
                        index = index + 1
                    end
                end
            end
        end
    end
    favScrollChild:SetSize(340, yOffset); favFrame:SetHeight(math.min(400, math.max(80, yOffset + 40)))
end

xpBar:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        local mod = OdysseusDB.xpBar.repMenuMod or "CTRL"
        local open = false
        if mod == "CTRL" and IsControlKeyDown() then open = true elseif mod == "SHIFT" and IsShiftKeyDown() then open = true elseif mod == "ALT" and IsAltKeyDown() then open = true elseif mod == "NONE" then open = true end
        if open then if factionSelectFrame:IsShown() then factionSelectFrame:Hide() else tempFavorites = DeepCopyTable(OdysseusDB.xpBar.favFactions or {}); RefreshFactionSelectTree(); factionSelectFrame:Show() end end
    end
end)

function CheckHideFavFrame() if not favFrame:IsMouseOver() and not xpBar:IsMouseOver() then favFrame:Hide(); SleepBars() end end

xpBar:HookScript("OnEnter", function()
    WakeBars(); RefreshHoverFavorites()
    local hasFavs = false
    if OdysseusDB and OdysseusDB.xpBar.favFactions then for k, v in pairs(OdysseusDB.xpBar.favFactions) do if v then hasFavs = true; break end end end
    if hasFavs then favFrame:ClearAllPoints(); local point = OdysseusDB.xpBar.xpBarPos.p or "BOTTOM"; if string.find(point, "BOTTOM") then favFrame:SetPoint("BOTTOM", xpBar, "TOP", 0, 5) else favFrame:SetPoint("TOP", xpBar, "BOTTOM", 0, -5) end; favFrame:Show() end
end)

xpBar:HookScript("OnLeave", function() C_Timer.After(0.1, CheckHideFavFrame) end)
favFrame:SetScript("OnLeave", function() C_Timer.After(0.1, CheckHideFavFrame) end)
favFrame:SetScript("OnEnter", function() WakeBars() end)

-- ==========================================
-- 8. SESSION STATS UI FRAME
-- ==========================================
OUS.statsFrame = CreateFrame("Frame", "OdysseusStatsFrame", UIParent, "BackdropTemplate")
local stats = OUS.statsFrame
stats:SetSize(350, 400); stats:SetPoint("CENTER"); stats:SetFrameStrata("DIALOG")
tinsert(UISpecialFrames, stats:GetName())
stats:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
stats:SetBackdropColor(0.07, 0.05, 0.1, 0.98); stats:SetBackdropBorderColor(0.5, 0.3, 0.7, 1); stats:Hide()
stats:SetMovable(true); stats:EnableMouse(true); stats:RegisterForDrag("LeftButton"); stats:SetScript("OnDragStart", stats.StartMoving); stats:SetScript("OnDragStop", stats.StopMovingOrSizing)
stats.headerBg = stats:CreateTexture(nil, "BACKGROUND", nil, 2); stats.headerBg:SetPoint("TOPLEFT", 4, -4); stats.headerBg:SetPoint("TOPRIGHT", -4, -4); stats.headerBg:SetHeight(30); stats.headerBg:SetColorTexture(1, 1, 1, 1); stats.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))
local statsClose = CreateFrame("Button", nil, stats, "UIPanelCloseButton"); statsClose:SetPoint("TOPRIGHT", stats, "TOPRIGHT", -2, -2)
local statsTitle = stats:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); statsTitle:SetPoint("TOP", 0, -10); statsTitle:SetText("Odysseus Session Stats"); statsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
stats.content = stats:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); stats.content:SetPoint("TOPLEFT", 20, -50); stats.content:SetPoint("BOTTOMRIGHT", -20, 20); stats.content:SetJustifyH("LEFT"); stats.content:SetJustifyV("TOP"); stats.content:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

function stats:UpdateData()
    local text = "|cFF00FFFFExperience Gained:|r\n" .. FormatLargeNumber(sessionXP) .. " XP\n\n|cFF00FFFFReputation Breakdown:|r\n"
    local hasRep = false
    for faction, amount in pairs(sessionRep) do hasRep = true; text = text .. "• " .. faction .. ": |cFF00FF00+" .. amount .. "|r\n" end
    if not hasRep then text = text .. "|cFF888888No reputation gained yet this session.|r" end
    self.content:SetText(text)
end

-- ==========================================
-- 9. UNIFIED CONFIGURATION INTEGRATION
-- ==========================================
StaticPopupDialogs["ODYSSEUS_RELOAD_PROMPT"] = { text = "Changing this setting requires a UI reload to avoid errors. Reload now?", button1 = "Yes", button2 = "No", OnAccept = function() ReloadUI() end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }

local function BuildXPConfigUI()
    if not OUS.XPBarTab then return end
    local pageContainer = CreateFrame("Frame", nil, OUS.XPBarTab, "BackdropTemplate"); pageContainer:SetPoint("TOPLEFT", 5, -35); pageContainer:SetPoint("BOTTOMRIGHT", -5, 5); pageContainer:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }}); pageContainer:SetBackdropColor(0.07, 0.05, 0.1, 0.5)

    local tabs, pages = {}, {}
    local function SelectTab(id)
        for i = 1, #tabs do if i == id then tabs[i]:SetBackdropColor(0.6, 0.2, 0.8, 0.5); tabs[i]:SetBackdropBorderColor(0.6, 0.2, 0.8, 1); tabs[i].text:SetTextColor(1, 1, 1, 1); pages[i]:Show() else tabs[i]:SetBackdropColor(0.05, 0.03, 0.05, 0.8); tabs[i]:SetBackdropBorderColor(0.3, 0.3, 0.3, 1); tabs[i].text:SetTextColor(0.5, 0.5, 0.5, 1); pages[i]:Hide() end end
    end

    local function CreateTab(id, label)
        local tab = CreateFrame("Button", nil, OUS.XPBarTab, "BackdropTemplate"); tab:SetID(id); tab:SetSize(85, 22); tab:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }}); tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); tab.text:SetPoint("CENTER"); tab.text:SetText(label)
        if id == 1 then tab:SetPoint("BOTTOMLEFT", pageContainer, "TOPLEFT", 10, -1) else tab:SetPoint("LEFT", tabs[id-1], "RIGHT", 4, 0) end
        tab:SetScript("OnClick", function(self) SelectTab(self:GetID()); PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end); local page = CreateFrame("Frame", nil, pageContainer); page:SetPoint("TOPLEFT", 4, -4); page:SetPoint("BOTTOMRIGHT", -4, 4); page:Hide(); tabs[id], pages[id] = tab, page
    end

    CreateTab(1, "Global"); CreateTab(2, "Experience"); CreateTab(3, "Reputation"); CreateTab(4, "Delves"); CreateTab(5, "Help"); SelectTab(1)

    local function CreateTemplateBox(parent, titleText, yOffset, dbKey)
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal"); title:SetPoint("TOPLEFT", 12, yOffset); title:SetText(titleText)
        local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate"); bg:SetSize(450, 26); bg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4); bg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }}); bg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)
        local editBox = CreateFrame("EditBox", nil, bg); editBox:SetFontObject("GameFontHighlightSmall"); editBox:SetPoint("TOPLEFT", 6, -4); editBox:SetPoint("BOTTOMRIGHT", -6, 4); editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); OdysseusDB.xpBar[dbKey] = self:GetText(); WakeBars(); UpdateBar(); SleepBars() end)
        return editBox
    end

    local function OpenColorPicker(dbColor, colorBoxFrame)
        ColorPickerFrame:SetupColorPickerAndShow({ r = dbColor.r, g = dbColor.g, b = dbColor.b, hasOpacity = false, swatchFunc = function() local r, g, b = ColorPickerFrame:GetColorRGB(); dbColor.r, dbColor.g, dbColor.b = r, g, b; colorBoxFrame:SetBackdropColor(r, g, b, 1); UpdateBar() end, cancelFunc = function(previousValues) dbColor.r, dbColor.g, dbColor.b = previousValues.r, previousValues.g, previousValues.b; colorBoxFrame:SetBackdropColor(previousValues.r, previousValues.g, previousValues.b, 1); UpdateBar() end })
    end

    local function CreateColorBox(parent, labelText, xOffset, yOffset, dbKey)
        local box = CreateFrame("Button", nil, parent, "BackdropTemplate"); box:SetSize(22, 22); box:SetPoint("TOPLEFT", xOffset, yOffset); box:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); box:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); text:SetPoint("LEFT", box, "RIGHT", 6, 0); text:SetText(labelText)
        box:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 1, 1, 1) end); box:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) end); box:SetScript("OnClick", function(self) OpenColorPicker(OdysseusDB.xpBar[dbKey], self) end)
        return box
    end

    local sliderCounter = 1
    local function CreatePremiumSlider(parent, titleText, yOffset, dbKey, minVal, maxVal, step, onUpdate)
        local sliderName = "OdysseusXPSlider" .. sliderCounter; sliderCounter = sliderCounter + 1
        local container = CreateFrame("Frame", nil, parent); container:SetSize(450, 40); container:SetPoint("TOPLEFT", 12, yOffset)
        local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); title:SetPoint("TOPLEFT", 0, 0); title:SetText(titleText)
        local btnMinus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate"); btnMinus:SetSize(20, 20); btnMinus:SetPoint("BOTTOMLEFT", 0, 0); btnMinus:SetText("<")
        local slider = CreateFrame("Slider", sliderName, container, "OptionsSliderTemplate"); slider:SetPoint("LEFT", btnMinus, "RIGHT", 6, 0); slider:SetWidth(250); slider:SetMinMaxValues(minVal, maxVal); slider:SetValueStep(step); slider:SetObeyStepOnDrag(true)
        _G[slider:GetName() .. "Text"]:SetText(""); _G[slider:GetName() .. "Low"]:SetText(""); _G[slider:GetName() .. "High"]:SetText("")
        local btnPlus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate"); btnPlus:SetSize(20, 20); btnPlus:SetPoint("LEFT", slider, "RIGHT", 6, 0); btnPlus:SetText(">")
        local editBg = CreateFrame("Frame", nil, container, "BackdropTemplate"); editBg:SetSize(40, 22); editBg:SetPoint("LEFT", btnPlus, "RIGHT", 10, 0); editBg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }}); editBg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)
        local editBox = CreateFrame("EditBox", nil, editBg); editBox:SetFontObject("GameFontHighlightSmall"); editBox:SetPoint("TOPLEFT", 4, -2); editBox:SetPoint("BOTTOMRIGHT", -4, 2); editBox:SetAutoFocus(false); editBox:SetJustifyH("CENTER")

        local initVal = OdysseusDB.xpBar[dbKey] or minVal
        slider:SetValue(initVal); editBox:SetText(initVal)

        btnMinus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() - step) end); btnPlus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() + step) end)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(slider:GetValue()) end); editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); local val = tonumber(self:GetText()); if val then val = math.max(minVal, math.min(maxVal, val)); slider:SetValue(val) else self:SetText(slider:GetValue()) end end)
        slider:SetScript("OnValueChanged", function(self, value) local snappedValue if step < 1 then snappedValue = math.floor(value * 100 + 0.5) / 100 else snappedValue = math.floor(value + 0.5) end; OdysseusDB.xpBar[dbKey] = snappedValue; editBox:SetText(snappedValue); if onUpdate then onUpdate() end end)
        return slider, editBox
    end

    local fontSizeSlider, fontSizeBox = CreatePremiumSlider(pages[1], "Global Font Size", -10, "xpFontSize", 8, 32, 1, ApplyFonts)
    local fontLbl = pages[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); fontLbl:SetPoint("TOPLEFT", 12, -60); fontLbl:SetText("Global Font (Requires LibSharedMedia):")
    local fontBtn = CreateFrame("Button", nil, pages[1], "UIPanelButtonTemplate"); fontBtn:SetSize(200, 24); fontBtn:SetPoint("TOPLEFT", 12, -75); fontBtn:SetText(string.sub(tostring(OdysseusDB.xpBar.xpFont or "Friz Quadrata TT"), 1, 25))
    fontBtn:SetScript("OnClick", function(self) if OUS.OpenDropDown then OUS.OpenDropDown("font", OdysseusDB.xpBar.xpFont, function(name) OdysseusDB.xpBar.xpFont = name; self:SetText(string.sub(tostring(name), 1, 25)); ApplyFonts() end) end end)
    local hideBlizzCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate"); hideBlizzCheck:SetPoint("TOPLEFT", 12, -110); hideBlizzCheck.text = hideBlizzCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); hideBlizzCheck.text:SetPoint("LEFT", hideBlizzCheck, "RIGHT", 4, 0); hideBlizzCheck.text:SetText("Hide Default Blizzard UI (Requires Reload)"); hideBlizzCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.hideBlizz = self:GetChecked(); StaticPopup_Show("ODYSSEUS_RELOAD_PROMPT") end)
    pages[1]:SetScript("OnShow", function() if IsInInstance() then hideBlizzCheck:Disable(); hideBlizzCheck.text:SetTextColor(0.5, 0.5, 0.5) else hideBlizzCheck:Enable(); hideBlizzCheck.text:SetTextColor(1, 1, 1) end if fontBtn then fontBtn:SetText(string.sub(tostring(OdysseusDB.xpBar.xpFont or "Friz Quadrata TT"), 1, 25)) end end)
    local autoHideCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate"); autoHideCheck:SetPoint("TOPLEFT", 12, -140); autoHideCheck.text = autoHideCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); autoHideCheck.text:SetPoint("LEFT", autoHideCheck, "RIGHT", 4, 0); autoHideCheck.text:SetText("Enable Auto-Hide / Mouseover Engine"); autoHideCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.autoHide = self:GetChecked(); WakeBars(); SleepBars() end)

    local repTimeSlider, repTimeBox = CreatePremiumSlider(pages[1], "Auto-Switch Display Time (Seconds)", -180, "repDisplayTime", 5, 60, 1, function() WakeBars(); SleepBars() end)
    local fadeDelaySlider, fadeDelayBox = CreatePremiumSlider(pages[1], "Auto-Hide Fade Delay (Seconds)", -230, "fadeDelay", 0, 60, 1, function() WakeBars(); SleepBars() end)
    local activeAlphaSlider, activeAlphaBox = CreatePremiumSlider(pages[1], "Active Opacity (%)", -280, "activeAlpha", 10, 100, 5, function() WakeBars(); SleepBars() end)
    local fadedAlphaSlider, fadedAlphaBox = CreatePremiumSlider(pages[1], "Faded Opacity (%)", -330, "fadedAlpha", 0, 100, 5, function() WakeBars(); SleepBars() end)
    local resetGlobalBtn = CreateFrame("Button", nil, pages[1], "UIPanelButtonTemplate"); resetGlobalBtn:SetSize(120, 24); resetGlobalBtn:SetPoint("BOTTOMRIGHT", -12, 12); resetGlobalBtn:SetText("Reset Defaults")
    resetGlobalBtn:SetScript("OnClick", function() OdysseusDB.xpBar.hideBlizz = defaults.hideBlizz; OdysseusDB.xpBar.autoHide = defaults.autoHide; OdysseusDB.xpBar.repDisplayTime = defaults.repDisplayTime; OdysseusDB.xpBar.fadeDelay = defaults.fadeDelay; OdysseusDB.xpBar.activeAlpha = defaults.activeAlpha; OdysseusDB.xpBar.fadedAlpha = defaults.fadedAlpha; OdysseusDB.xpBar.xpFont = defaults.xpFont; OdysseusDB.xpBar.xpFontSize = defaults.xpFontSize; hideBlizzCheck:SetChecked(defaults.hideBlizz); autoHideCheck:SetChecked(defaults.autoHide); repTimeSlider:SetValue(defaults.repDisplayTime); repTimeBox:SetText(defaults.repDisplayTime); fadeDelaySlider:SetValue(defaults.fadeDelay); fadeDelayBox:SetText(defaults.fadeDelay); activeAlphaSlider:SetValue(defaults.activeAlpha); activeAlphaBox:SetText(defaults.activeAlpha); fadedAlphaSlider:SetValue(defaults.fadedAlpha); fadedAlphaBox:SetText(defaults.fadedAlpha); fontSizeSlider:SetValue(defaults.xpFontSize); fontSizeBox:SetText(defaults.xpFontSize); fontBtn:SetText(defaults.xpFont); ApplyBlizzardKiller(); ApplyFonts(); WakeBars(); SleepBars() end)

    local xpEditBox = CreateTemplateBox(pages[2], "Text Format", -10, "xpTemplate"); local xpColorBox = CreateColorBox(pages[2], "Main Experience Color", 12, -70, "xpColor"); local restColorBox = CreateColorBox(pages[2], "Rested Experience Color", 220, -70, "restColor")
    local xpWidthSlider, xpWidthBox = CreatePremiumSlider(pages[2], "Main Bar Width", -110, "xpBarWidth", 100, 1000, 10, function() ApplyDimensions(); WakeBars(); SleepBars() end)
    local xpHeightSlider, xpHeightBox = CreatePremiumSlider(pages[2], "Main Bar Height", -160, "xpBarHeight", 10, 100, 1, function() ApplyDimensions(); WakeBars(); SleepBars() end)
    local xpScaleSlider, xpScaleBox = CreatePremiumSlider(pages[2], "Main Bar Scale", -210, "xpBarScale", 0.5, 2.0, 0.05, function() ApplyDimensions(); WakeBars(); SleepBars() end)
    local resetXPBtn = CreateFrame("Button", nil, pages[2], "UIPanelButtonTemplate"); resetXPBtn:SetSize(120, 24); resetXPBtn:SetPoint("BOTTOMRIGHT", -12, 12); resetXPBtn:SetText("Reset Defaults")
    resetXPBtn:SetScript("OnClick", function() OdysseusDB.xpBar.xpTemplate = defaults.xpTemplate; OdysseusDB.xpBar.xpColor = DeepCopyTable(defaults.xpColor); OdysseusDB.xpBar.restColor = DeepCopyTable(defaults.restColor); OdysseusDB.xpBar.xpBarWidth = defaults.xpBarWidth; OdysseusDB.xpBar.xpBarHeight = defaults.xpBarHeight; OdysseusDB.xpBar.xpBarScale = defaults.xpBarScale; OdysseusDB.xpBar.xpBarPos = DeepCopyTable(defaults.xpBarPos); xpEditBox:SetText(defaults.xpTemplate); xpEditBox:SetCursorPosition(0); xpColorBox:SetBackdropColor(defaults.xpColor.r, defaults.xpColor.g, defaults.xpColor.b, 1); restColorBox:SetBackdropColor(defaults.restColor.r, defaults.restColor.g, defaults.restColor.b, 1); xpWidthSlider:SetValue(defaults.xpBarWidth); xpWidthBox:SetText(defaults.xpBarWidth); xpHeightSlider:SetValue(defaults.xpBarHeight); xpHeightBox:SetText(defaults.xpBarHeight); xpScaleSlider:SetValue(defaults.xpBarScale); xpScaleBox:SetText(defaults.xpBarScale); xpBar:ClearAllPoints(); xpBar:SetPoint(defaults.xpBarPos.p, UIParent, defaults.xpBarPos.rP, defaults.xpBarPos.x, defaults.xpBarPos.y); ApplyDimensions(); WakeBars(); UpdateBar(); SleepBars() end)

    local repEditBox = CreateTemplateBox(pages[3], "Text Format", -10, "repTemplate"); local repColorBox = CreateColorBox(pages[3], "Main Reputation Color", 12, -70, "repColor")
    local toastEnableCheck = CreateFrame("CheckButton", nil, pages[3], "UICheckButtonTemplate"); toastEnableCheck:SetPoint("TOPLEFT", 12, -110); toastEnableCheck.text = toastEnableCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); toastEnableCheck.text:SetPoint("LEFT", toastEnableCheck, "RIGHT", 4, 0); toastEnableCheck.text:SetText("Enable Renown & Paragon Reward Popups"); toastEnableCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.toastEnabled = self:GetChecked() end)
    local toastSoundCheck = CreateFrame("CheckButton", nil, pages[3], "UICheckButtonTemplate"); toastSoundCheck:SetPoint("TOPLEFT", 32, -140); toastSoundCheck.text = toastSoundCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); toastSoundCheck.text:SetPoint("LEFT", toastSoundCheck, "RIGHT", 4, 0); toastSoundCheck.text:SetText("Play Sound on Reward Popup"); toastSoundCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.toastSound = self:GetChecked() end)

    local modLbl = pages[3]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); modLbl:SetPoint("TOPLEFT", 12, -180); modLbl:SetText("Right-Click Modifier for Faction Menu:")
    local modBtn = CreateFrame("Button", nil, pages[3], "UIPanelButtonTemplate"); modBtn:SetSize(120, 24); modBtn:SetPoint("TOPLEFT", 12, -195); modBtn:SetText(OdysseusDB.xpBar.repMenuMod or "CTRL")
    modBtn:SetScript("OnClick", function(self) local current = OdysseusDB.xpBar.repMenuMod or "CTRL"; local nextMod = "CTRL"; if current == "CTRL" then nextMod = "SHIFT" elseif current == "SHIFT" then nextMod = "ALT" elseif current == "ALT" then nextMod = "NONE" else nextMod = "CTRL" end; OdysseusDB.xpBar.repMenuMod = nextMod; self:SetText(nextMod) end)

    local resetRepBtn = CreateFrame("Button", nil, pages[3], "UIPanelButtonTemplate"); resetRepBtn:SetSize(120, 24); resetRepBtn:SetPoint("BOTTOMRIGHT", -12, 12); resetRepBtn:SetText("Reset Defaults")
    resetRepBtn:SetScript("OnClick", function() OdysseusDB.xpBar.repTemplate = defaults.repTemplate; OdysseusDB.xpBar.repColor = DeepCopyTable(defaults.repColor); OdysseusDB.xpBar.toastEnabled = defaults.toastEnabled; OdysseusDB.xpBar.toastSound = defaults.toastSound; OdysseusDB.xpBar.repMenuMod = defaults.repMenuMod; repEditBox:SetText(defaults.repTemplate); repEditBox:SetCursorPosition(0); repColorBox:SetBackdropColor(defaults.repColor.r, defaults.repColor.g, defaults.repColor.b, 1); toastEnableCheck:SetChecked(defaults.toastEnabled); toastSoundCheck:SetChecked(defaults.toastSound); modBtn:SetText(defaults.repMenuMod); WakeBars(); UpdateBar(); SleepBars() end)

    local delveCompEditBox = CreateTemplateBox(pages[4], "Companion Text Format", -10, "delveCompTemplate"); local delveJourEditBox = CreateTemplateBox(pages[4], "Journey Text Format", -65, "delveJourTemplate")
    local delveCompColorBox = CreateColorBox(pages[4], "Companion Color", 12, -120, "delveCompColor"); local delveJourColorBox = CreateColorBox(pages[4], "Journey Color", 220, -120, "delveJourColor")
    local delveWidthSlider, delveWidthBox = CreatePremiumSlider(pages[4], "Delve Bar Width", -160, "delveBarWidth", 100, 1000, 10, function() ApplyDimensions(); WakeBars(); SleepBars() end)
    local delveHeightSlider, delveHeightBox = CreatePremiumSlider(pages[4], "Delve Bar Height", -210, "delveBarHeight", 20, 100, 2, function() ApplyDimensions(); WakeBars(); SleepBars() end)
    local delveScaleSlider, delveScaleBox = CreatePremiumSlider(pages[4], "Delve Bar Scale", -260, "delveBarScale", 0.5, 2.0, 0.05, function() ApplyDimensions(); WakeBars(); SleepBars() end)
    local resetDelveBtn = CreateFrame("Button", nil, pages[4], "UIPanelButtonTemplate"); resetDelveBtn:SetSize(120, 24); resetDelveBtn:SetPoint("BOTTOMRIGHT", -12, 12); resetDelveBtn:SetText("Reset Defaults")
    resetDelveBtn:SetScript("OnClick", function() OdysseusDB.xpBar.delveCompTemplate = defaults.delveCompTemplate; OdysseusDB.xpBar.delveJourTemplate = defaults.delveJourTemplate; OdysseusDB.xpBar.delveCompColor = DeepCopyTable(defaults.delveCompColor); OdysseusDB.xpBar.delveJourColor = DeepCopyTable(defaults.delveJourColor); OdysseusDB.xpBar.delveBarWidth = defaults.delveBarWidth; OdysseusDB.xpBar.delveBarHeight = defaults.delveBarHeight; OdysseusDB.xpBar.delveBarScale = defaults.delveBarScale; OdysseusDB.xpBar.delveBarPos = DeepCopyTable(defaults.delveBarPos); delveCompEditBox:SetText(defaults.delveCompTemplate); delveCompEditBox:SetCursorPosition(0); delveJourEditBox:SetText(defaults.delveJourTemplate); delveJourEditBox:SetCursorPosition(0); delveCompColorBox:SetBackdropColor(defaults.delveCompColor.r, defaults.delveCompColor.g, defaults.delveCompColor.b, 1); delveJourColorBox:SetBackdropColor(defaults.delveJourColor.r, defaults.delveJourColor.g, defaults.delveJourColor.b, 1); delveWidthSlider:SetValue(defaults.delveBarWidth); delveWidthBox:SetText(defaults.delveBarWidth); delveHeightSlider:SetValue(defaults.delveBarHeight); delveHeightBox:SetText(defaults.delveBarHeight); delveScaleSlider:SetValue(defaults.delveBarScale); delveScaleBox:SetText(defaults.delveBarScale); delveBar:ClearAllPoints(); delveBar:SetPoint(defaults.delveBarPos.p, UIParent, defaults.delveBarPos.rP, defaults.delveBarPos.x, defaults.delveBarPos.y); ApplyDimensions(); WakeBars(); UpdateBar(); SleepBars() end)

    local helpText = pages[5]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", 12, -12); helpText:SetJustifyH("LEFT")
    helpText:SetText("|cFFFFD100EXPERIENCE TAGS:|r\n|cFFFFFF00[curXP]|r - Current XP  |  |cFFFFFF00[maxXP]|r - Max XP\n|cFFFFFF00[needXP]|r - Remaining XP  |  |cFFFFFF00[curPC]|r - Current %\n|cFFFFFF00[needPC]|r - Remaining %  |  |cFFFFFF00[restPC]|r - Rested %\n|cFFFFFF00[pLVL]|r - Current Lvl  |  |cFFFFFF00[nLVL]|r - Next Lvl\n|cFFFFFF00[mLVL]|r - Max Lvl  |  |cFFFFFF00[restXP]|r - Rested XP\n|cFFFFFF00[restLVL]|r - Rested XP (Lvl)  |  |cFFFFFF00[KTL]|r - Kills to Level\n\n|cFFFFD100REPUTATION & DELVES TAGS:|r\n|cFF00FF00[faction]|r - Name  |  |cFF00FF00[standing]|r - Standing\n|cFF00FF00[curRep]|r - Cur Rep  |  |cFF00FF00[maxRep]|r - Max Rep\n|cFF00FFFF[compName]|r - Companion Name  |  |cFF00FFFF[pLVL]|r - Comp Lvl\n\n|cFFFFD100MASTER CHAT COMMANDS:|r\n|cFF00FF00/ous|r - Open Main Config\n|cFF00FF00/ous help|r - Show All Commands\n|cFF00FF00/xpstats|r - Show Session XP/Rep\n|cFF00FF00/toasttest|r - Test Popup (Hold Shift to Move!)\n|cFF888888(Tip: Shift+Drag to move the bars!)|r\n|cFF888888(Tip: Mod+Right-Click the XP Bar for the Faction Menu!)|r")
    
    hideBlizzCheck:SetChecked(OdysseusDB.xpBar.hideBlizz); autoHideCheck:SetChecked(OdysseusDB.xpBar.autoHide); toastEnableCheck:SetChecked(OdysseusDB.xpBar.toastEnabled); toastSoundCheck:SetChecked(OdysseusDB.xpBar.toastSound)
    xpEditBox:SetText(OdysseusDB.xpBar.xpTemplate or ""); repEditBox:SetText(OdysseusDB.xpBar.repTemplate or ""); delveCompEditBox:SetText(OdysseusDB.xpBar.delveCompTemplate or ""); delveJourEditBox:SetText(OdysseusDB.xpBar.delveJourTemplate or "")
    local cXP, cRest, cRep = OdysseusDB.xpBar.xpColor, OdysseusDB.xpBar.restColor, OdysseusDB.xpBar.repColor
    local cDC, cDJ = OdysseusDB.xpBar.delveCompColor, OdysseusDB.xpBar.delveJourColor
    if cXP then xpColorBox:SetBackdropColor(cXP.r, cXP.g, cXP.b, 1) end; if cRest then restColorBox:SetBackdropColor(cRest.r, cRest.g, cRest.b, 1) end; if cRep then repColorBox:SetBackdropColor(cRep.r, cRep.g, cRep.b, 1) end; if cDC then delveCompColorBox:SetBackdropColor(cDC.r, cDC.g, cDC.b, 1) end; if cDJ then delveJourColorBox:SetBackdropColor(cDJ.r, cDJ.g, cDJ.b, 1) end
end

-- ==========================================
-- 10. EVENT LISTENERS & DB MERGER
-- ==========================================
f:RegisterEvent("ADDON_LOADED"); f:RegisterEvent("PLAYER_ENTERING_WORLD"); f:RegisterEvent("ZONE_CHANGED_NEW_AREA"); f:RegisterEvent("SCENARIO_UPDATE"); f:RegisterEvent("UPDATE_INSTANCE_INFO"); f:RegisterEvent("PLAYER_XP_UPDATE"); f:RegisterEvent("UPDATE_EXHAUSTION"); f:RegisterEvent("UPDATE_FACTION"); f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:RegisterEvent("PLAYER_REGEN_ENABLED"); f:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE"); f:RegisterEvent("CHAT_MSG_SYSTEM") 

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        OdysseusDB = OdysseusDB or {}; OdysseusDB.xpBar = OdysseusDB.xpBar or {}
        for k, v in pairs(defaults) do if OdysseusDB.xpBar[k] == nil or (type(v) == "string" and OdysseusDB.xpBar[k] == "") then if type(v) == "table" then OdysseusDB.xpBar[k] = DeepCopyTable(v) else OdysseusDB.xpBar[k] = v end end end
        BuildXPConfigUI(); ApplyFonts()
        local xpP = OdysseusDB.xpBar.xpBarPos; xpBar:ClearAllPoints(); xpBar:SetPoint(xpP.p, UIParent, xpP.rP, xpP.x, xpP.y)
        local dbP = OdysseusDB.xpBar.delveBarPos; delveBar:ClearAllPoints(); delveBar:SetPoint(dbP.p, UIParent, dbP.rP, dbP.x, dbP.y)
        local tP = OdysseusDB.xpBar.toastPos; toast:ClearAllPoints(); toast:SetPoint(tP.p, UIParent, tP.rP, tP.x, tP.y)
        ApplyDimensions(); lastXP, lastMaxXP = UnitXP("player"), UnitXPMax("player"); WakeBars(); SleepBars()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        ApplyBlizzardKiller(); TriggerAggressiveDelveCheck(); ScanFactionsForPopups(true); WakeBars(); SleepBars()
    elseif event == "SCENARIO_UPDATE" or event == "UPDATE_INSTANCE_INFO" then
        UpdateBar()
    elseif event == "PLAYER_XP_UPDATE" then
        local currentXP, maxXP = UnitXP("player"), UnitXPMax("player")
        if currentXP > lastXP and maxXP == lastMaxXP then lastXPGain = currentXP - lastXP; sessionXP = sessionXP + lastXPGain elseif currentXP < lastXP or maxXP > lastMaxXP then lastXPGain = (lastMaxXP - lastXP) + currentXP; sessionXP = sessionXP + lastXPGain end
        lastXP, lastMaxXP = currentXP, maxXP; if forceRepDisplay then forceRepDisplay = false; if repTimer then repTimer:Cancel() end end; WakeBars(); UpdateBar(); SleepBars()
    elseif event == "UPDATE_FACTION" then
        ScanFactionsForPopups(false)
        local isMaxLevel = (UnitLevel("player") >= (GetMaxPlayerLevel and GetMaxPlayerLevel() or 80)) or (IsXPUserDisabled and IsXPUserDisabled())
        if not isMaxLevel then forceRepDisplay = true; if repTimer then repTimer:Cancel() end; repTimer = C_Timer.NewTimer(OdysseusDB.xpBar.repDisplayTime or 15, function() forceRepDisplay = false; WakeBars(); UpdateBar(); SleepBars() end) end
        WakeBars(); UpdateBar(); SleepBars()
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" or event == "CHAT_MSG_SYSTEM" then
        if not arg1 then return end
        local success, msg = pcall(function() return tostring(arg1) end); if not success or type(msg) ~= "string" then return end
        msg = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", ""); msg = string.gsub(msg, "|r", ""); msg = string.gsub(msg, "|H.-|h(.-)|h", "%1")
        local faction, amount = string.match(msg, "[Rr]eputation with (.-) increased by (%d+)")
        if not faction then faction, amount = string.match(msg, "Warband's reputation with (.-) increased by (%d+)") end
        if faction and amount then faction = string.gsub(faction, "[%[%]%.]", ""); faction = string.gsub(faction, "^%s+", ""); faction = string.gsub(faction, "%s+$", ""); sessionRep[faction] = (sessionRep[faction] or 0) + tonumber(amount); lastGainedFactionName = faction end
    elseif event == "PLAYER_REGEN_DISABLED" then WakeBars() elseif event == "PLAYER_REGEN_ENABLED" then SleepBars() end
end)

-- ==========================================
-- 11. STANDALONE SLASH COMMANDS
-- ==========================================
SLASH_XPSTATS1 = "/xpstats"; SLASH_XPSTATS2 = "/ousxp"; SlashCmdList["XPSTATS"] = function() if OUS.statsFrame:IsShown() then OUS.statsFrame:Hide() else OUS.statsFrame:UpdateData(); OUS.statsFrame:Show() end end
SLASH_DELVETEST1 = "/delvetest"; SlashCmdList["DELVETEST"] = function() isTestingDelve = not isTestingDelve; UpdateBar(); if isTestingDelve then print("|cFF00FF00Odysseus:|r Delves UI forced ON.") else print("|cFFFF0000Odysseus:|r Delves UI forced OFF.") end end
SLASH_TOASTTEST1 = "/toasttest"; SlashCmdList["TOASTTEST"] = function() OUS.ShowToast("Renown Increased!", "The Midnight Court - Rank 10") end
SLASH_DELVEDEBUG1 = "/delvedebug"; SlashCmdList["DELVEDEBUG"] = function() local inInstance, instanceType = IsInInstance(); local name, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo(); local uiMapID = C_Map.GetBestMapForUnit("player"); local scenarioType = "N/A"; if C_Scenario and C_Scenario.GetInfo then local sInfo = C_Scenario.GetInfo(); if sInfo then scenarioType = tostring(sInfo.scenarioType) end end; print("|cFF00FFFF--- Odysseus Delve Radar ---|r"); print("InInstance: ", tostring(inInstance), " | Type:", tostring(instanceType)); print("Inst Name:", tostring(name)); print("Inst ID:", tostring(instanceID), " | Diff ID:", tostring(difficultyID)); print("UI Map ID:", tostring(uiMapID)); print("Scenario Type:", scenarioType) end
SLASH_OUSDEBUG1 = "/ousdebug"; SlashCmdList["OUSDEBUG"] = function() isDebugOn = not isDebugOn; if isDebugOn then print("|cFF00FFFFOdysseus:|r Global Debug Mode |cFF00FF00ENABLED|r.") else print("|cFF00FFFFOdysseus:|r Global Debug Mode |cFFFF0000DISABLED|r.") end end