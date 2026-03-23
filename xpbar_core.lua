local addonName, OUS = ...

-- ==========================================
-- 1. DEFAULTS & SESSION STATE
-- ==========================================
OUS.defaults = {
    xpTemplate = "Exp: [curXP]/[maxXP] ([restPC]) :: [curPC] through [pLVL] lvl :: [needXP] XP left :: [KTL] kills to lvl",
    repTemplate = "Rep: [faction] ([standing]) [curRep]/[maxRep] :: [repPC]%",
    delveCompTemplate = "[compName]: Level [pLVL] - [curXP]/[maxXP]",
    delveJourTemplate = "Journey: [curRep]/[maxRep]",
    xpColor = {r = 0.6, g = 0.2, b = 0.8}, restColor = {r = 0.0, g = 0.4, b = 0.9}, repColor = {r = 0.2, g = 0.8, b = 0.4},
    delveCompColor = {r = 0.8, g = 0.4, b = 0.0}, delveJourColor = {r = 0.0, g = 0.6, b = 0.8},
    hideBlizz = false, repDisplayTime = 15, journeyID = 2640, delveBrannID = 2640, delveValeeraID = 2744,
    autoHide = false, fadeDelay = 5, activeAlpha = 100, fadedAlpha = 0,
    xpBarWidth = 400, xpBarHeight = 24, xpBarScale = 1.0, xpBarPos = {p = "BOTTOM", rP = "BOTTOM", x = 0, y = 150},
    delveBarWidth = 300, delveBarHeight = 40, delveBarScale = 1.0, delveBarPos = {p = "TOP", rP = "TOP", x = 0, y = -150},
    toastEnabled = true, toastSound = false, toastPos = {p = "TOP", rP = "TOP", x = 0, y = -120},
    xpFont = "Friz Quadrata TT", xpFontSize = 12, repMenuMod = "CTRL", favFactions = {}
}

OUS.Session = {
    sessionXP = 0, sessionRep = {}, repCache = { renown = {}, paragon = {} }, lastGainedFactionName = nil,
    lastXP = 0, lastMaxXP = 0, lastXPGain = 0, forceRepDisplay = false, repTimer = nil,
    sleepTimer = nil, fadeTicker = nil, delveCheckTicker = nil, isTestingDelve = false, isDebugOn = false
}

function OUS.DeepCopyTable(src)
    local dest = {}
    for k, v in pairs(src) do if type(v) == "table" then dest[k] = OUS.DeepCopyTable(v) else dest[k] = v end end
    return dest
end

function OUS.FormatLargeNumber(n)
    if not n then return 0 end
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) elseif n >= 1000 then return string.format("%.1fK", n / 1000) else return tostring(n) end
end

-- ==========================================
-- 2. CREATE VISUAL FRAMES
-- ==========================================
OUS.xpBarFrame = CreateFrame("Frame", "OdysseusXPBar", UIParent, "BackdropTemplate")
local xpBar = OUS.xpBarFrame
xpBar.bg = xpBar:CreateTexture(nil, "BACKGROUND"); xpBar.bg:SetAllPoints(true); xpBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)
xpBar.restedBar = CreateFrame("StatusBar", nil, xpBar); xpBar.restedBar:SetAllPoints(true); xpBar.restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar.progressBar = CreateFrame("StatusBar", nil, xpBar); xpBar.progressBar:SetAllPoints(true); xpBar.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); xpBar:SetBackdropBorderColor(0, 0, 0, 1)
xpBar.text = xpBar.progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); xpBar.text:SetPoint("CENTER", xpBar, "CENTER", 0, 0)
xpBar:SetMovable(true); xpBar:EnableMouse(true); xpBar:RegisterForDrag("LeftButton")
xpBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
xpBar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local p, _, rP, x, y = self:GetPoint(); OdysseusDB.xpBar.xpBarPos = {p=p, rP=rP, x=x, y=y} end)

OUS.delveBarFrame = CreateFrame("Frame", "OdysseusDelveBar", UIParent, "BackdropTemplate")
local delveBar = OUS.delveBarFrame
delveBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); delveBar:SetBackdropBorderColor(0, 0, 0, 1)
delveBar.bg = delveBar:CreateTexture(nil, "BACKGROUND"); delveBar.bg:SetAllPoints(true); delveBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)
delveBar.compBar = CreateFrame("StatusBar", nil, delveBar); delveBar.compBar:SetPoint("TOP", 0, -1); delveBar.compBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
delveBar.compText = delveBar.compBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); delveBar.compText:SetPoint("CENTER")
delveBar.jourBar = CreateFrame("StatusBar", nil, delveBar); delveBar.jourBar:SetPoint("BOTTOM", 0, 1); delveBar.jourBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
delveBar.jourText = delveBar.jourBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); delveBar.jourText:SetPoint("CENTER")
delveBar:SetMovable(true); delveBar:EnableMouse(true); delveBar:RegisterForDrag("LeftButton")
delveBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
delveBar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local p, _, rP, x, y = self:GetPoint(); OdysseusDB.xpBar.delveBarPos = {p=p, rP=rP, x=x, y=y} end)
delveBar:Hide()

OUS.toastFrame = CreateFrame("Frame", "OdysseusToastFrame", UIParent, "BackdropTemplate")
local toast = OUS.toastFrame
toast:SetSize(300, 56); toast:SetFrameStrata("DIALOG")
toast:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
toast:SetBackdropColor(0.07, 0.05, 0.1, 0.95); toast:SetBackdropBorderColor(0.6, 0.2, 0.8, 1); toast:Hide(); toast:SetAlpha(0)
toast:SetMovable(true); toast:EnableMouse(true); toast:RegisterForDrag("LeftButton")
toast:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
toast:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local p, _, rP, x, y = self:GetPoint(); OdysseusDB.xpBar.toastPos = {p=p, rP=rP, x=x, y=y} end)
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

OUS.statsFrame = CreateFrame("Frame", "OdysseusStatsFrame", UIParent, "BackdropTemplate")
local stats = OUS.statsFrame
stats:SetSize(350, 400); stats:SetPoint("CENTER"); stats:SetFrameStrata("DIALOG"); tinsert(UISpecialFrames, stats:GetName())
stats:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
stats:SetBackdropColor(0.07, 0.05, 0.1, 0.98); stats:SetBackdropBorderColor(0.5, 0.3, 0.7, 1); stats:Hide()
stats:SetMovable(true); stats:EnableMouse(true); stats:RegisterForDrag("LeftButton"); stats:SetScript("OnDragStart", stats.StartMoving); stats:SetScript("OnDragStop", stats.StopMovingOrSizing)
stats.headerBg = stats:CreateTexture(nil, "BACKGROUND", nil, 2); stats.headerBg:SetPoint("TOPLEFT", 4, -4); stats.headerBg:SetPoint("TOPRIGHT", -4, -4); stats.headerBg:SetHeight(30); stats.headerBg:SetColorTexture(1, 1, 1, 1); stats.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))
local statsClose = CreateFrame("Button", nil, stats, "UIPanelCloseButton"); statsClose:SetPoint("TOPRIGHT", stats, "TOPRIGHT", -2, -2)
local statsTitle = stats:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); statsTitle:SetPoint("TOP", 0, -10); statsTitle:SetText("Odysseus Session Stats"); statsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
stats.content = stats:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); stats.content:SetPoint("TOPLEFT", 20, -50); stats.content:SetPoint("BOTTOMRIGHT", -20, 20); stats.content:SetJustifyH("LEFT"); stats.content:SetJustifyV("TOP"); stats.content:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

function stats:UpdateData()
    local text = "|cFF00FFFFExperience Gained:|r\n" .. OUS.FormatLargeNumber(OUS.Session.sessionXP) .. " XP\n\n|cFF00FFFFReputation Breakdown:|r\n"
    local hasRep = false
    for faction, amount in pairs(OUS.Session.sessionRep) do hasRep = true; text = text .. "• " .. faction .. ": |cFF00FF00+" .. amount .. "|r\n" end
    if not hasRep then text = text .. "|cFF888888No reputation gained yet this session.|r" end
    self.content:SetText(text)
end

-- ==========================================
-- 3. DEBUG UI & SLASH COMMANDS
-- ==========================================
OUS.debugFrame = CreateFrame("Frame", "OdysseusDebugFrame", UIParent, "BackdropTemplate")
local dbg = OUS.debugFrame
dbg:SetSize(450, 400); dbg:SetPoint("CENTER"); dbg:SetFrameStrata("DIALOG"); dbg:Hide()
tinsert(UISpecialFrames, dbg:GetName())
dbg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
dbg:SetBackdropColor(0.07, 0.05, 0.1, 0.98); dbg:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)
dbg:SetMovable(true); dbg:EnableMouse(true); dbg:RegisterForDrag("LeftButton")
dbg:SetScript("OnDragStart", dbg.StartMoving); dbg:SetScript("OnDragStop", dbg.StopMovingOrSizing)

dbg.headerBg = dbg:CreateTexture(nil, "BACKGROUND", nil, 2)
dbg.headerBg:SetPoint("TOPLEFT", 4, -4); dbg.headerBg:SetPoint("TOPRIGHT", -4, -4); dbg.headerBg:SetHeight(26)
dbg.headerBg:SetColorTexture(1, 1, 1, 1); dbg.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

dbg.title = dbg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dbg.title:SetPoint("TOP", 0, -8); dbg.title:SetText("Odysseus Debug Log"); dbg.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

local dbgScroll = CreateFrame("ScrollFrame", "OdysseusDebugScroll", dbg, "UIPanelScrollFrameTemplate")
dbgScroll:SetPoint("TOPLEFT", 15, -40); dbgScroll:SetPoint("BOTTOMRIGHT", -35, 45)
local dbgEditBox = CreateFrame("EditBox", "OdysseusDebugEditBox", dbgScroll)
dbgEditBox:SetSize(dbgScroll:GetSize()); dbgEditBox:SetMultiLine(true); dbgEditBox:SetAutoFocus(false); dbgEditBox:SetFontObject("ChatFontNormal")
dbgScroll:SetScrollChild(dbgEditBox)

local selAllBtn = CreateFrame("Button", nil, dbg, "UIPanelButtonTemplate")
selAllBtn:SetSize(120, 25); selAllBtn:SetPoint("BOTTOMLEFT", 15, 10); selAllBtn:SetText("Select All")
selAllBtn:SetScript("OnClick", function() dbgEditBox:HighlightText(); dbgEditBox:SetFocus() end)

local clsBtn = CreateFrame("Button", nil, dbg, "UIPanelButtonTemplate")
clsBtn:SetSize(120, 25); clsBtn:SetPoint("BOTTOMRIGHT", -15, 10); clsBtn:SetText("Close")
clsBtn:SetScript("OnClick", function() dbg:Hide() end)

function OUS.LogDebug(msg)
    if not OUS.Session.isDebugOn then return end
    local currentText = dbgEditBox:GetText()
    local timeStamp = date("[%H:%M:%S] ")
    dbgEditBox:SetText(currentText .. timeStamp .. tostring(msg) .. "\n")
end

SLASH_XPSTATS1 = "/xpstats"; SLASH_XPSTATS2 = "/ousxp"
SlashCmdList["XPSTATS"] = function() if OUS.statsFrame:IsShown() then OUS.statsFrame:Hide() else OUS.statsFrame:UpdateData(); OUS.statsFrame:Show() end end

SLASH_DELVETEST1 = "/delvetest"
SlashCmdList["DELVETEST"] = function() OUS.Session.isTestingDelve = not OUS.Session.isTestingDelve; if OUS.UpdateBar then OUS.UpdateBar() end; if OUS.Session.isTestingDelve then print("|cFF00FF00Odysseus:|r Delves UI forced ON.") else print("|cFFFF0000Odysseus:|r Delves UI forced OFF.") end end

SLASH_TOASTTEST1 = "/toasttest"
SlashCmdList["TOASTTEST"] = function() OUS.ShowToast("Renown Increased!", "The Midnight Court - Rank 10") end

SLASH_DELVEDEBUG1 = "/delvedebug"
SlashCmdList["DELVEDEBUG"] = function() 
    local inInstance, instanceType = IsInInstance()
    local name, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    local scenarioType = "N/A"
    if C_Scenario and C_Scenario.GetInfo then local sInfo = C_Scenario.GetInfo(); if sInfo then scenarioType = tostring(sInfo.scenarioType) end end
    
    local log = string.format("--- Odysseus Delve Radar ---\nInInstance: %s | Type: %s\nInst Name: %s\nInst ID: %s | Diff ID: %s\nUI Map ID: %s\nScenario Type: %s", 
        tostring(inInstance), tostring(instanceType), tostring(name), tostring(instanceID), tostring(difficultyID), tostring(uiMapID), scenarioType)
    
    print("|cFF00FFFF--- Odysseus Delve Radar ---|r (Check /ousdebug for logs)")
    if OUS.LogDebug then OUS.LogDebug(log) end
end

SLASH_OUSDEBUG1 = "/ousdebug"
SlashCmdList["OUSDEBUG"] = function() 
    if dbg:IsShown() then 
        dbg:Hide() 
    else 
        dbg:Show() 
        OUS.Session.isDebugOn = true
        print("|cFF00FFFFOdysseus:|r Global Debug Mode |cFF00FF00ENABLED|r.")
    end 
end