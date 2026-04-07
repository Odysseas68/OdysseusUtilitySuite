-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP & REP ENGINE
-- ==========================================
local addonName, OUS = ...

-- ==========================================
-- 2. DEFAULTS & SESSION STATE
-- ==========================================
OUS.defaults = {
    xpTemplate = "Exp: [curXP]/[maxXP] ([restPC]) :: [curPC]% through [pLVL] lvl :: [needXP] XP left :: [KTL] kills to lvl",
    repTemplate = "Rep: [faction] ([standing]) [curRep]/[maxRep] :: [repPC]%",
    delveCompTemplate = "[compName]: Level [pLVL] - [curXP]/[maxXP]",
    delveJourTemplate = "Journey: ([curLVL]->[nextLVL])::[curRep]/[maxRep]",

    -- Main Experience Colors
    xpColor = {r = 0.6, g = 0.2, b = 0.8},
    restColor = {r = 0.0, g = 0.4, b = 0.9},
    xpTextColor = {r = 1.0, g = 1.0, b = 1.0},
    showRestIcon = true,

    -- Dynamic Reputation Colors (Nested!)
    repTextColor = {r = 1.0, g = 1.0, b = 1.0},
    repColors = {
        hated = {r = 0.8, g = 0.13, b = 0.13},
        hostile = {r = 1.0, g = 0.0, b = 0.0},
        unfriendly = {r = 0.93, g = 0.4, b = 0.13},
        neutral = {r = 0.93, g = 0.8, b = 0.13},
        friendly = {r = 0.0, g = 1.0, b = 0.0},
        honored = {r = 0.0, g = 1.0, b = 0.53},
        revered = {r = 0.0, g = 1.0, b = 0.8},
        exalted = {r = 0.0, g = 1.0, b = 1.0},
        renown = {r = 0.0, g = 0.6, b = 1.0},
        paragon = {r = 0.4, g = 0.8, b = 0.6},
    },

    delveCompColor = {r = 0.8, g = 0.4, b = 0.0},
    delveJourColor = {r = 0.0, g = 0.6, b = 0.8},
    hideBlizz = true,
    shortNumbers = true,
    barBorderName = "Blizzard Tooltip",
    barBorderSize = 8,
    barBorderColor = {r = 0.6, g = 0.2, b = 0.8},
    repDisplayTime = 15,
    autoHide = false, fadeDelay = 5, activeAlpha = 100, fadedAlpha = 0,
    xpBarWidth = 650, xpBarHeight = 25, xpBarScale = 1.0,
    xpBarPos = {p = "TOP", rP = "TOP", x = -56, y = -99},
    delveBarWidth = 300, delveBarHeight = 40, delveBarScale = 1.0,
    delveBarPos = {p = "TOP", rP = "TOP", x = 0, y = -150},
    toastEnabled = true, toastSound = false,
    toastPos = {p = "TOP", rP = "TOP", x = -22, y = -130},
    xpFont = "Friz Quadrata TT", xpFontSize = 15,
    repMenuMod = "CTRL",
    favFactions = {},
    lastRepFactionName = nil
}

OUS.XPBarSession = OUS.XPBarSession or {
    sessionXP = 0,
    sessionRep = {},
    repCache = { renown = {}, paragon = {} },
    lastGainedFactionName = nil,
    lastXP = 0,
    lastMaxXP = 0,
    lastXPGain = 0,
    forceRepDisplay = false,
    repTimer = nil,
    sleepTimer = nil,
    fadeTicker = nil,
    delveCheckTicker = nil,
    isTestingDelve = false,
    lastKnownDelveState = false,
    lastDelveSeenTime = 0
}

function OUS.FormatLargeNumber(n)
    if not n then return "0" end

    -- If the user disabled abbreviated numbers, format with standard commas
    if OdysseusDB and OdysseusDB.xpBar and OdysseusDB.xpBar.shortNumbers == false then
        local formatted = tostring(math.floor(n))
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if (k==0) then break end
        end
        return formatted
    end

    -- Default behavior (Abbreviated: 1.5K, 2.3M)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(math.floor(n))
    end
end

-- ==========================================
-- 3. FRAME CREATION
-- ==========================================
-- Main XP Bar
OUS.xpBarFrame = CreateFrame("Frame", "OdysseusXPBar", UIParent, "BackdropTemplate")
local xpBar = OUS.xpBarFrame

xpBar.bg = xpBar:CreateTexture(nil, "BACKGROUND")
xpBar.bg:SetAllPoints(true)
xpBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)

xpBar.restedBar = CreateFrame("StatusBar", nil, xpBar)
xpBar.restedBar:SetAllPoints(true)
xpBar.restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

xpBar.progressBar = CreateFrame("StatusBar", nil, xpBar)
xpBar.progressBar:SetAllPoints(true)
xpBar.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

xpBar.borderFrame = CreateFrame("Frame", nil, xpBar, "BackdropTemplate")
xpBar.borderFrame:SetFrameLevel(xpBar:GetFrameLevel() + 2)

xpBar.text = xpBar.progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
xpBar.text:SetPoint("CENTER", xpBar, "CENTER", 0, 0)

xpBar:SetMovable(true)
xpBar:EnableMouse(true)
xpBar:RegisterForDrag("LeftButton")
xpBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
xpBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rP, x, y = self:GetPoint()
    OdysseusDB.xpBar.xpBarPos = {p=p, rP=rP, x=x, y=y}
end)

-- Delve Bar
OUS.delveBarFrame = CreateFrame("Frame", "OdysseusDelveBar", UIParent, "BackdropTemplate")
local delveBar = OUS.delveBarFrame

delveBar.borderFrame = CreateFrame("Frame", nil, delveBar, "BackdropTemplate")
delveBar.borderFrame:SetFrameLevel(delveBar:GetFrameLevel() + 2)

delveBar.bg = delveBar:CreateTexture(nil, "BACKGROUND")
delveBar.bg:SetAllPoints(true)
delveBar.bg:SetColorTexture(0.07, 0.05, 0.1, 0.8)

delveBar.compBar = CreateFrame("StatusBar", nil, delveBar)
delveBar.compBar:SetPoint("TOP", 0, -1)
delveBar.compBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

delveBar.compText = delveBar.compBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
delveBar.compText:SetPoint("CENTER")

delveBar.jourBar = CreateFrame("StatusBar", nil, delveBar)
delveBar.jourBar:SetPoint("BOTTOM", 0, 1)
delveBar.jourBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

delveBar.jourText = delveBar.jourBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
delveBar.jourText:SetPoint("CENTER")

delveBar:SetMovable(true)
delveBar:EnableMouse(true)
delveBar:RegisterForDrag("LeftButton")
delveBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
delveBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rP, x, y = self:GetPoint()
    OdysseusDB.xpBar.delveBarPos = {p=p, rP=rP, x=x, y=y}
end)
delveBar:Hide()

-- Toast Notification Frame
OUS.toastFrame = CreateFrame("Frame", "OdysseusToastFrame", UIParent, "BackdropTemplate")
local toast = OUS.toastFrame
toast:SetSize(300, 56)
toast:SetFrameStrata("DIALOG")
toast:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
toast:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
toast:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
toast:Hide()
toast:SetAlpha(0)

toast:SetMovable(true)
toast:EnableMouse(true)
toast:RegisterForDrag("LeftButton")
toast:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
toast:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rP, x, y = self:GetPoint()
    OdysseusDB.xpBar.toastPos = {p=p, rP=rP, x=x, y=y}
end)

toast.icon = toast:CreateTexture(nil, "ARTWORK")
toast.icon:SetSize(36, 36)
toast.icon:SetPoint("LEFT", 10, 0)
toast.icon:SetTexture("Interface\\Icons\\Achievement_Reputation_01")
toast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 10, -2)
toast.title:SetText("Renown Increased!")

toast.subText = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toast.subText:SetPoint("BOTTOMLEFT", toast.icon, "BOTTOMRIGHT", 10, 2)

toast.isHovered = false
toast.remainingTime = 0
-- Toast timing (seconds)
toast.fadeDuration = 0.4
toast.displayDuration = 5.0
toast.isFading = false

toast:SetScript("OnEnter", function(self)
    self.isHovered = true
end)

toast:SetScript("OnLeave", function(self)
    self.isHovered = false
end)

local function StopToastUpdates()
    toast:SetScript("OnUpdate", nil)
    toast.isFading = false
end

local function StartToastFadeOut()
    if toast.isFading then return end
    toast.isFading = true

    local startAlpha = toast:GetAlpha()
    local elapsedTotal = 0
    local fadeDuration = toast.fadeDuration or 1.2

    toast:SetScript("OnUpdate", function(self, elapsed)
        if self.isHovered then return end

        elapsedTotal = elapsedTotal + elapsed
        local progress = math.min(elapsedTotal / fadeDuration, 1)
        self:SetAlpha(startAlpha * (1 - progress))

        if progress >= 1 then
            self:SetScript("OnUpdate", nil)
            self.isFading = false
            self:Hide()
        end
    end)
end

local function StartToastTimer()
    StopToastUpdates()
    toast:SetAlpha(1)
    toast.remainingTime = toast.displayDuration or 8.0

    toast:SetScript("OnUpdate", function(self, elapsed)
        if self.isHovered then return end

        self.remainingTime = self.remainingTime - elapsed
        if self.remainingTime <= 0 then
            StartToastFadeOut()
        end
    end)
end

function OUS.ShowToast(title, subText, iconPath)
    if not OdysseusDB or not OdysseusDB.xpBar.toastEnabled then return end

    StopToastUpdates()

    toast.title:SetText(title)
    toast.subText:SetText(subText)

    if iconPath then
        toast.icon:SetTexture(iconPath)
    else
        toast.icon:SetTexture("Interface\\Icons\\Achievement_Reputation_01")
    end

    toast:Show()
    toast:SetAlpha(0)

    local fadeInElapsed = 0
    local fadeInDuration = 0.15

    toast:SetScript("OnUpdate", function(self, elapsed)
        if self.isHovered then return end

        fadeInElapsed = fadeInElapsed + elapsed
        local progress = math.min(fadeInElapsed / fadeInDuration, 1)
        self:SetAlpha(progress)

        if progress >= 1 then
            StartToastTimer()
        end
    end)

    if OdysseusDB.xpBar.toastSound then
        local TOAST_SOUND_ID = 44269
            PlaySound(TOAST_SOUND_ID, "Master")
    end

    OUS.LogDebug("XPBar", "Triggered Toast Notification: " .. title)
end

-- Session Stats Frame
OUS.statsFrame = CreateFrame("Frame", "OdysseusStatsFrame", UIParent, "BackdropTemplate")
local stats = OUS.statsFrame
stats:SetSize(350, 400)
stats:SetPoint("CENTER")
stats:SetFrameStrata("DIALOG")
tinsert(UISpecialFrames, stats:GetName())

stats:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
stats:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
stats:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)
stats:Hide()

stats:SetMovable(true)
stats:EnableMouse(true)

stats:RegisterForDrag("LeftButton")
stats:SetScript("OnDragStart", stats.StartMoving)
stats:SetScript("OnDragStop", stats.StopMovingOrSizing)

stats.headerBg = stats:CreateTexture(nil, "BACKGROUND", nil, 2)
stats.headerBg:SetPoint("TOPLEFT", 4, -4)
stats.headerBg:SetPoint("TOPRIGHT", -4, -4)
stats.headerBg:SetHeight(30)
stats.headerBg:SetColorTexture(1, 1, 1, 1)
stats.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

local statsClose = CreateFrame("Button", nil, stats, "UIPanelCloseButton")
statsClose:SetPoint("TOPRIGHT", stats, "TOPRIGHT", -2, -2)

local statsTitle = stats:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statsTitle:SetPoint("TOP", 0, -10)
statsTitle:SetText("Odysseus Session Stats")
statsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

stats.content = stats:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
stats.content:SetPoint("TOPLEFT", 20, -50)
stats.content:SetPoint("BOTTOMRIGHT", -20, 20)
stats.content:SetJustifyH("LEFT")
stats.content:SetJustifyV("TOP")
stats.content:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

function stats:UpdateData()
    local text = "|cFF00FFFFExperience Gained:|r\n" .. OUS.FormatLargeNumber(OUS.XPBarSession.sessionXP) .. " XP\n\n|cFF00FFFFReputation Breakdown:|r\n"
    local hasRep = false

    for faction, amount in pairs(OUS.XPBarSession.sessionRep) do
        hasRep = true
        text = text .. "• " .. faction .. ": |cFF00FF00+" .. amount .. "|r\n"
    end

    if not hasRep then
        text = text .. "|cFF888888No reputation gained yet this session.|r"
    end

    self.content:SetText(text)
end

-- ==========================================
-- 4. MODULE SLASH COMMANDS
-- ==========================================
SLASH_XPSTATS1 = "/xpstats"
SLASH_XPSTATS2 = "/ousxp"
SlashCmdList["XPSTATS"] = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    if OUS.statsFrame:IsShown() then
        OUS.statsFrame:Hide()
    else
        OUS.statsFrame:UpdateData()
        OUS.statsFrame:Show()
    end
end

SLASH_DELVETEST1 = "/delvetest"
SlashCmdList["DELVETEST"] = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    OUS.XPBarSession.isTestingDelve = not OUS.XPBarSession.isTestingDelve
    if OUS.UpdateBar then OUS.UpdateBar() end
    if OUS.XPBarSession.isTestingDelve then
        print("|cFF00FF00Odysseus:|r Delves UI forced ON.")
        OUS.LogDebug("XPBar", "Test Delve Mode Enabled")
    else
        print("|cFFFF0000Odysseus:|r Delves UI forced OFF.")
        OUS.LogDebug("XPBar", "Test Delve Mode Disabled")
    end
end

SLASH_TOASTTEST1 = "/toasttest"
SlashCmdList["TOASTTEST"] = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    OUS.ShowToast("Renown Increased!", "The Midnight Court - Rank 10")
end

SLASH_DELVEDEBUG1 = "/delvedebug"
SlashCmdList["DELVEDEBUG"] = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    local inInstance, instanceType = IsInInstance()
    local name, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    local scenarioType = "N/A"
    if C_Scenario and C_Scenario.GetInfo then
        local sInfo = C_Scenario.GetInfo()
        if sInfo then scenarioType = tostring(sInfo.scenarioType) end
    end

    local log = string.format("InInstance: %s | Type: %s | Name: %s | ID: %s | Diff: %s | Map: %s",
        tostring(inInstance), tostring(instanceType), tostring(name), tostring(instanceID), tostring(difficultyID), tostring(uiMapID))

    print("|cFF00FFFF--- Odysseus Delve Radar ---|r (Check /ousdebug for logs)")
    OUS.LogDebug("DelveRadar", log)
end