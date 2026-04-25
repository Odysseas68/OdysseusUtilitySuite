-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: CORE NAMESPACE
-- ==========================================
local addonName, OUS = ...
_G[addonName] = OUS

OUS.Session = {
    isDebugOn = false,
    sessionStartTime = GetTime(),
    logHistory = {},
}

-- ==========================================
-- 2. DATABASE INITIALIZATION
-- ==========================================
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.modules = OdysseusDB.modules or {}

        if OdysseusDB.modules.flightMaster == nil then OdysseusDB.modules.flightMaster = true end
        if OdysseusDB.modules.fasterLoot == nil then OdysseusDB.modules.fasterLoot = true end
        if OdysseusDB.modules.fishingTracker == nil then OdysseusDB.modules.fishingTracker = true end
        if OdysseusDB.modules.xpBar == nil then OdysseusDB.modules.xpBar = true end
        if OdysseusDB.modules.autoRemount == nil then OdysseusDB.modules.autoRemount = true end
        if OdysseusDB.modules.statsBar == nil then OdysseusDB.modules.statsBar = true end

        OdysseusCharDB = OdysseusCharDB or {}
        OdysseusCharDB.statsBar = OdysseusCharDB.statsBar or {
            enabled      = true,
            template     = "{ilvl} | {spec}",
            fontSize     = 12,
            locked       = false,
            x            = 0,
            y            = 0,
            point        = "CENTER",
            relPoint     = "CENTER",
            tableEnabled = false,
            tableX       = 200,
            tableY       = 0,
            tablePoint   = "CENTER",
            tableRelPoint = "CENTER",
            tableLocked  = false,
            tableWidth   = 150,
        }

        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
        OdysseusDB.fishingSettings = OdysseusDB.fishingSettings or { history = {} }
        OdysseusDB.autoRemount = OdysseusDB.autoRemount or {
            enabled = true,
            delay = 0.5,
            silent = true,
            skipDruid = true,
            debug = false,
            spyMode = false,
            accountMountID = nil,
            customSpells = {},
            discoveredSpells = {},
            spyFilter = {},
        }
        OdysseusCharDB = OdysseusCharDB or {}
        OdysseusCharDB.autoRemountChar = OdysseusCharDB.autoRemountChar or {
            mountID = nil,
        }
    end
end)

function OUS.DeepCopyTable(src)
    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = OUS.DeepCopyTable(v)
        else
            dest[k] = v
        end
    end
    return dest
end

function OUS.ResetAllSettings()
    OdysseusDB = OdysseusDB or {}
    print("|cFF00CCFFOdysseus:|r All settings reset. Reloading UI.")

    -- Reset Modules
    OdysseusDB.modules = {
        flightMaster = true,
        fasterLoot = true,
        fishingTracker = true,
        xpBar = true,
        autoRemount = true,
        statsBar = true,
    }

    -- Reset Flight Master
    if OUS.flightDefaults then
        OdysseusDB.flightSettings = OUS.DeepCopyTable(OUS.flightDefaults)
        OdysseusDB.flightSettings.times = {} -- Explicitly wipe flight times
    end

    -- Reset Fishing Tracker
    if OUS.fishingDefaults then
        OdysseusDB.fishingSettings = OUS.DeepCopyTable(OUS.fishingDefaults)
        OdysseusDB.fishingSettings.history = {} -- Explicitly wipe fishing history
    end

    -- Reset XP Bar
    if OUS.defaults then
        OdysseusDB.xpBar = OUS.DeepCopyTable(OUS.defaults)
    else
        OdysseusDB.xpBar = OdysseusDB.xpBar or {}
    end

    -- Reset AutoRemount
    OdysseusDB.autoRemount = {
        enabled = true,
        delay = 0.5,
        silent = true,
        skipDruid = true,
        debug = false,
        spyMode = false,
        accountMountID = nil,
        customSpells = {},
        discoveredSpells = {},
        spyFilter = {},
    }
    OdysseusCharDB.autoRemountChar = { mountID = nil }

    OdysseusCharDB = OdysseusCharDB or {}
    OdysseusCharDB.statsBar = {
        enabled      = true,
        template     = "{ilvl} | {spec}",
        fontSize     = 12,
        locked       = false,
        x            = 0,
        y            = 0,
        point        = "CENTER",
        relPoint     = "CENTER",
        tableEnabled = false,
        tableX       = 200,
        tableY       = 0,
        tablePoint   = "CENTER",
        tableRelPoint = "CENTER",
        tableLocked  = false,
        tableWidth   = 150,
    }

    C_Timer.After(0.5, ReloadUI)
end

-- ==========================================
-- 3. GLOBAL DEBUG ENGINE
-- ==========================================
local debugFrame = CreateFrame("Frame", "OdysseusDebugFrame", UIParent, "BackdropTemplate")
debugFrame:SetSize(450, 250)
debugFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
debugFrame:SetFrameStrata("DIALOG")
debugFrame:Hide()

debugFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
debugFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
debugFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)

debugFrame:SetMovable(true)
debugFrame:EnableMouse(true)
debugFrame:RegisterForDrag("LeftButton")
debugFrame:SetScript("OnDragStart", debugFrame.StartMoving)
debugFrame:SetScript("OnDragStop", debugFrame.StopMovingOrSizing)

local debugHeader = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
debugHeader:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 10, -10)
debugHeader:SetText("|cFF00FFFF[Odysseus Debug Console]|r")

-- Safest font object to prevent C-Side crashes
local msgFrame = CreateFrame("ScrollingMessageFrame", nil, debugFrame)
msgFrame:SetPoint("TOPLEFT", 10, -30)
msgFrame:SetPoint("BOTTOMRIGHT", -10, 40)
msgFrame:SetFontObject(GameFontNormal)
msgFrame:SetJustifyH("LEFT")
msgFrame:SetFading(false)
msgFrame:SetMaxLines(500)

local closeXBtn = CreateFrame("Button", nil, debugFrame, "UIPanelCloseButton")
closeXBtn:SetPoint("TOPRIGHT", debugFrame, "TOPRIGHT", -2, -2)
closeXBtn:SetScript("OnClick", function()
    debugFrame:Hide()
    OUS.Session.isDebugOn = false
end)

local closeBtn = CreateFrame("Button", nil, debugFrame, "UIPanelButtonTemplate")
closeBtn:SetSize(80, 22)
closeBtn:SetPoint("BOTTOMRIGHT", debugFrame, "BOTTOMRIGHT", -10, 10)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function()
    debugFrame:Hide()
    OUS.Session.isDebugOn = false
end)

local clearBtn = CreateFrame("Button", nil, debugFrame, "UIPanelButtonTemplate")
clearBtn:SetSize(80, 22)
clearBtn:SetPoint("BOTTOMLEFT", debugFrame, "BOTTOMLEFT", 10, 10)
clearBtn:SetText("Clear")
clearBtn:SetScript("OnClick", function()
    msgFrame:Clear()
    wipe(OUS.Session.logHistory)
end)

local copyBtn = CreateFrame("Button", nil, debugFrame, "UIPanelButtonTemplate")
copyBtn:SetSize(100, 22)
copyBtn:SetPoint("LEFT", clearBtn, "RIGHT", 10, 0)
copyBtn:SetText("Select All")

local copyOverlay = CreateFrame("ScrollFrame", nil, debugFrame, "UIPanelScrollFrameTemplate")
copyOverlay:SetPoint("TOPLEFT", 10, -30)
copyOverlay:SetPoint("BOTTOMRIGHT", -30, 40)
copyOverlay:Hide()

local copyEditBox = CreateFrame("EditBox", nil, copyOverlay)
copyEditBox:SetMultiLine(true)
copyEditBox:SetFontObject(GameFontNormal)
copyEditBox:SetWidth(390)
copyEditBox:SetAutoFocus(false)
copyOverlay:SetScrollChild(copyEditBox)

copyBtn:SetScript("OnClick", function()
    if copyOverlay:IsShown() then
        copyOverlay:Hide()
        msgFrame:Show()
        copyBtn:SetText("Select All")
    else
        msgFrame:Hide()
        local fullLog = table.concat(OUS.Session.logHistory, "\n")
        copyEditBox:SetText(fullLog)
        copyOverlay:Show()
        copyEditBox:HighlightText()
        copyEditBox:SetFocus()
        copyBtn:SetText("Back to Log")
    end
end)

-- ==========================================
-- 4. GLOBAL LOGGING FUNCTION (ARMORED & CLEAN)
-- ==========================================
function OUS.LogDebug(module, message)
    if not OUS.Session.isDebugOn then return end

    local success, err = pcall(function()
        local timeStamp = date("%H:%M:%S") or "00:00:00"
        local safeMod = tostring(module or "Core")
        local safeMsg = tostring(message or "nil")

        local plainText = string.format("[%s] [%s] %s", timeStamp, safeMod, safeMsg)
        local formattedMsg = string.format("|cFF888888[%s]|r |cFFFFD100[%s]|r %s", timeStamp, safeMod, safeMsg)

        if not OUS.Session.logHistory then OUS.Session.logHistory = {} end
        table.insert(OUS.Session.logHistory, plainText)
        if #OUS.Session.logHistory > 500 then
            table.remove(OUS.Session.logHistory, 1)
        end

        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(formattedMsg)
        end

        if msgFrame then
            msgFrame:AddMessage(formattedMsg)
        end
    end)

    if not success then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Odysseus CRITICAL]|r LogDebug crashed: " .. tostring(err))
        end
    end
end

-- ==========================================
-- 5. MAIN COMMANDS & GLOBALS
-- ==========================================
SLASH_ODYSSEUSDEBUG1 = "/ousdebug"
SlashCmdList["ODYSSEUSDEBUG"] = function()
    OUS.Session.isDebugOn = not OUS.Session.isDebugOn
    if OUS.Session.isDebugOn then
        debugFrame:Show()
        print("|cFF00FFFF[Odysseus]|r Debug Mode |cFF00FF00ENABLED|r.")
        OUS.LogDebug("Core", "Debug session started.")
    else
        debugFrame:Hide()
        print("|cFF00FFFF[Odysseus]|r Debug Mode |cFFFF0000DISABLED|r.")
    end
end

SLASH_ODYSSEUS1 = "/ous"
SlashCmdList["ODYSSEUS"] = function(msg)
    local cmd = string.lower(strtrim(msg))

    if cmd == "fish" then
        if OUS.ToggleFishingTracker then OUS.ToggleFishingTracker() end
    elseif cmd == "debug" then
        SlashCmdList["ODYSSEUSDEBUG"]()
    elseif cmd == "help" then
        if OdysseusHelpFrame then
            if OdysseusHelpFrame:IsShown() then OdysseusHelpFrame:Hide() else OdysseusHelpFrame:Show() end
        end
    else
        if OUS.ConfigFrame then
            if OUS.ConfigFrame:IsShown() then OUS.ConfigFrame:Hide() else OUS.ConfigFrame:Show() end
        end
    end
end

SLASH_AUTOREMOUNT1 = "/ar"
SLASH_AUTOREMOUNT2 = "/autoremount"
SlashCmdList["AUTOREMOUNT"] = function(msg)
    if OUS.AutoRemount and OUS.AutoRemount.SlashHandler then
        OUS.AutoRemount.SlashHandler(msg)
    end
end

SLASH_STATSBAR1 = "/sb"
SLASH_STATSBAR2 = "/statsbar"
SlashCmdList["STATSBAR"] = function(msg)
    if OUS.StatsBar and OUS.StatsBar.SlashHandler then
        OUS.StatsBar.SlashHandler(msg)
    end
end

_G.Odysseus_ToggleConfig = function()
    if not OUS.ConfigFrame then return end
    if OUS.ConfigFrame:IsShown() then
        OUS.ConfigFrame:Hide()
    else
        OUS.ConfigFrame:Show()
    end
end