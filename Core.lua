-- Addon   : OdysseusUtilitySuite
-- File    : Core.lua
-- Version : 2026.07.11
-- Desc    : Namespace, DB init, module defaults, slash commands
-- ============================================================

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
        OUS.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"

        OdysseusDB = OdysseusDB or {}
        OdysseusDB.modules = OdysseusDB.modules or {}

        if OdysseusDB.modules.flightMaster == nil then OdysseusDB.modules.flightMaster = true end
        if OdysseusDB.modules.fasterLoot == nil then OdysseusDB.modules.fasterLoot = true end
        if OdysseusDB.modules.fishingTracker == nil then OdysseusDB.modules.fishingTracker = true end
        if OdysseusDB.modules.xpBar == nil then OdysseusDB.modules.xpBar = true end
        if OdysseusDB.modules.autoRemount == nil then OdysseusDB.modules.autoRemount = true end
        if OdysseusDB.modules.statsBar == nil then OdysseusDB.modules.statsBar = true end
        if OdysseusDB.modules.openables == nil then OdysseusDB.modules.openables = true end
        if OdysseusDB.modules.toolbox    == nil then OdysseusDB.modules.toolbox    = true end
        if OdysseusDB.modules.utilities  == nil then OdysseusDB.modules.utilities  = true end

        OdysseusCharDB = OdysseusCharDB or {}
        OdysseusDB.statsBar = OdysseusDB.statsBar or {
            fontSize     = 12,
            tableWidth   = 150,
            locked       = false,
            tableLocked  = false,
        }
        OdysseusCharDB.statsBar = OdysseusCharDB.statsBar or {
            enabled      = true,
            template     = "{ilvl} | {spec}",
            x            = 0,
            y            = 0,
            point        = "CENTER",
            relPoint     = "CENTER",
            tableEnabled = false,
            tableX       = 200,
            tableY       = 0,
            tablePoint   = "CENTER",
            tableRelPoint = "CENTER",
        }

        OdysseusDB.openables = OdysseusDB.openables or {
            autoOpen   = false,
            blacklist  = {},
            customItems = {},
            x          = 300,
            y          = 0,
            point      = "CENTER",
            relPoint   = "CENTER",
            scale = 1.0,
        }

        OdysseusDB.toolbox = OdysseusDB.toolbox or {
            x         = 0,
            y         = 0,
            point     = "CENTER",
            relPoint  = "CENTER",
            locked    = true,
            shown     = true,
            scale     = 1.0,
            direction = "horizontal",
        }

        OdysseusDB.utilities = OdysseusDB.utilities or OUS.DeepCopyTable(OUS.utilitiesDefaults)
        if OdysseusDB.utilities.hideExtraActionArtwork == nil then
            OdysseusDB.utilities.hideExtraActionArtwork = false
        end
        OdysseusDB.utilities.junkSell = OdysseusDB.utilities.junkSell or {
            enabled      = true,
            requireShift = false,
            announceJunk = true,
            limitTo12    = true,
            blacklist    = {},
        }
        -- ensure limitTo12 exists on older saved data
        if OdysseusDB.utilities.junkSell.limitTo12 == nil then
            OdysseusDB.utilities.junkSell.limitTo12 = true
        end

        OdysseusDB.minimap = OdysseusDB.minimap or {}
        if OdysseusDB.minimap.hide == nil then
            OdysseusDB.minimap.hide = OdysseusDB.showMinimapButton == false
        end
        if OdysseusDB.minimap.minimapPos == nil then
            OdysseusDB.minimap.minimapPos = type(OdysseusDB.minimapAngle) == "number" and (OdysseusDB.minimapAngle % 360) or 225
        end
        OdysseusDB.showMinimapButton = nil
        OdysseusDB.minimapAngle = nil
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
        OdysseusDB.fishingSettings = OdysseusDB.fishingSettings or {}
        OdysseusFishingDB = OdysseusFishingDB or { history = {} }
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

        print(string.format("|cFF00CCFFOdysseus Utility Suite|r |cFF888888v%s|r loaded.", OUS.Version))
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
        flightMaster   = true,
        fasterLoot     = true,
        fishingTracker = true,
        xpBar          = true,
        autoRemount    = true,
        statsBar       = true,
        openables      = true,
        toolbox        = true,
        utilities      = true,
    }

    OdysseusDB.minimap = {
        hide = false,
        minimapPos = 225,
    }
    OdysseusDB.showMinimapButton = nil
    OdysseusDB.minimapAngle = nil

    -- Reset Utilities and immediately restore Blizzard artwork before reload.
    if OUS.utilitiesDefaults then
        OdysseusDB.utilities = OUS.DeepCopyTable(OUS.utilitiesDefaults)
        if OUS.ApplyExtraActionArtworkSetting then
            OUS.ApplyExtraActionArtworkSetting()
        end
    end

    -- Reset Flight Master
    if OUS.flightDefaults then
        OdysseusDB.flightSettings = OUS.DeepCopyTable(OUS.flightDefaults)
        OdysseusDB.flightSettings.times = {} -- Explicitly wipe flight times
    end

    -- Reset Fishing Tracker settings only (history preserved in OdysseusFishingDB)
    if OUS.fishingDefaults then
        OdysseusDB.fishingSettings = OUS.DeepCopyTable(OUS.fishingDefaults)
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

    OdysseusDB.openables = {
        autoOpen    = false,
        blacklist   = {},
        customItems = {},
        x           = 300,
        y           = 0,
        point       = "CENTER",
        relPoint    = "CENTER",
        scale = 1.0,
    }

    OdysseusDB.toolbox = {
        x         = 0,
        y         = 0,
        point     = "CENTER",
        relPoint  = "CENTER",
        locked    = true,
        shown     = true,
        scale     = 1.0,
        direction = "horizontal",
    }

    OdysseusCharDB = OdysseusCharDB or {}
    OdysseusDB.statsBar = {
        fontSize     = 12,
        tableWidth   = 150,
        locked       = false,
        tableLocked  = false,
    }
    OdysseusCharDB.statsBar = {
        enabled      = true,
        template     = "{ilvl} | {spec}",
        x            = 0,
        y            = 0,
        point        = "CENTER",
        relPoint     = "CENTER",
        tableEnabled = false,
        tableX       = 200,
        tableY       = 0,
        tablePoint   = "CENTER",
        tableRelPoint = "CENTER",
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
debugFrame:SetClampedToScreen(true)
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
function OUS.SetDebugMode(enabled, silent)
    OUS.Session.isDebugOn = enabled == true

    if OUS.Session.isDebugOn then
        debugFrame:Show()
        if not silent then
            print("|cFF00FFFF[Odysseus]|r Debug Mode |cFF00FF00ENABLED|r.")
        end
        OUS.LogDebug("Core", "Debug session started.")
    else
        debugFrame:Hide()
        if not silent then
            print("|cFF00FFFF[Odysseus]|r Debug Mode |cFFFF0000DISABLED|r.")
        end
    end
end

function OUS.IsDebugModeOn()
    return OUS.Session and OUS.Session.isDebugOn == true
end

SLASH_ODYSSEUSDEBUG1 = "/ousdebug"
SlashCmdList["ODYSSEUSDEBUG"] = function()
    OUS.SetDebugMode(not OUS.IsDebugModeOn())
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

SLASH_OPENABLES1 = "/op"
SLASH_OPENABLES2 = "/openables"
SlashCmdList["OPENABLES"] = function(msg)
    if OUS.Openables and OUS.Openables.SlashHandler then
        OUS.Openables.SlashHandler(msg)
    end
end

SLASH_STATSBAR1 = "/sb"
SLASH_STATSBAR2 = "/statsbar"
SlashCmdList["STATSBAR"] = function(msg)
    if OUS.StatsBar and OUS.StatsBar.SlashHandler then
        OUS.StatsBar.SlashHandler(msg)
    end
end

SLASH_TOOLBOX1 = "/tb"
SLASH_TOOLBOX2 = "/toolbox"
SlashCmdList["TOOLBOX"] = function(msg)
    if OUS.Toolbox and OUS.Toolbox.SlashHandler then
        OUS.Toolbox.SlashHandler(msg)
    end
end

-- ==========================================
-- 6. MINIMAP BUTTON
-- ==========================================
f:RegisterEvent("PLAYER_LOGIN")

local MINIMAP_LDB_NAME = "OdysseusUtilitySuite"
local MINIMAP_ICON = "Interface\\AddOns\\OdysseusUtilitySuite\\media\\icon\\OUS_icon_128.tga"
local minimapFallbackButton
local minimapRegistered = false

-- Shared launcher click behavior preserves the legacy minimap button actions.
local function HandleMinimapLauncherClick(button)
    if button == "LeftButton" then
        if OUS.ConfigFrame then
            if OUS.ConfigFrame:IsShown() then
                OUS.ConfigFrame:Hide()
            else
                OUS.ConfigFrame:Show()
            end
        end
    elseif button == "RightButton" then
        if OdysseusHelpFrame then
            if OdysseusHelpFrame:IsShown() then
                OdysseusHelpFrame:Hide()
            else
                OdysseusHelpFrame:Show()
            end
        end
    end
end

-- LibDataBroker launcher lets display addons own presentation without OUS-specific hooks.
local minimapLauncher = {
    type = "launcher",
    text = "Odysseus Utility Suite",
    label = "Odysseus Utility Suite",
    icon = MINIMAP_ICON,
    OnClick = function(_, button)
        HandleMinimapLauncherClick(button)
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cFF00FFFFOdysseus Utility Suite|r")
        tooltip:AddLine("Left click: Open Config", 0.8, 0.8, 0.8)
        tooltip:AddLine("Right click: Open Help", 0.8, 0.8, 0.8)
    end,
}

-- Minimap DB migration keeps old visibility and angle values on the new LibDBIcon schema.
local function EnsureMinimapDB()
    OdysseusDB = OdysseusDB or {}
    OdysseusDB.minimap = OdysseusDB.minimap or {}

    if OdysseusDB.minimap.hide == nil then
        OdysseusDB.minimap.hide = OdysseusDB.showMinimapButton == false
    end

    if OdysseusDB.minimap.minimapPos == nil then
        OdysseusDB.minimap.minimapPos = type(OdysseusDB.minimapAngle) == "number" and (OdysseusDB.minimapAngle % 360) or 225
    end

    OdysseusDB.showMinimapButton = nil
    OdysseusDB.minimapAngle = nil

    return OdysseusDB.minimap
end

-- Manual fallback only runs when LibDBIcon is unavailable.
local function CreateFallbackMinimapButton()
    if minimapFallbackButton then
        return minimapFallbackButton
    end

    local button = CreateFrame("Button", "OdysseusMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(MINIMAP_ICON)

    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(32, 32)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnClick", function(_, buttonName)
        HandleMinimapLauncherClick(buttonName)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        minimapLauncher.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(self)
            local db = EnsureMinimapDB()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            db.minimapPos = math.deg(math.atan2(cy - my, cx - mx)) % 360
            local angle = math.rad(db.minimapPos)
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angle), 80 * math.sin(angle))
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    minimapFallbackButton = button
    return button
end

-- Fallback positioning mirrors the old minimap button when broker libraries are unavailable.
local function RefreshFallbackMinimapButton(db)
    local button = CreateFallbackMinimapButton()
    local angle = math.rad(db.minimapPos or 225)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angle), 80 * math.sin(angle))
    button:SetShown(db.hide ~= true)
    button:EnableMouse(db.hide ~= true)
end

-- Broker registration hands minimap ownership to LibDBIcon and display addons.
local function RefreshMinimapLauncher()
    local db = EnsureMinimapDB()
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    local dbIcon = LibStub and LibStub("LibDBIcon-1.0", true)

    if ldb and dbIcon then
        local dataObject = ldb:GetDataObjectByName(MINIMAP_LDB_NAME) or ldb:NewDataObject(MINIMAP_LDB_NAME, minimapLauncher)
        if dataObject then
            dataObject.icon = MINIMAP_ICON
        end

        if not minimapRegistered and dataObject then
            dbIcon:Register(MINIMAP_LDB_NAME, dataObject, db)
            minimapRegistered = true
        end

        dbIcon:Refresh(MINIMAP_LDB_NAME, db)
        if minimapFallbackButton then
            minimapFallbackButton:Hide()
            minimapFallbackButton:EnableMouse(false)
        end
        return
    end

    RefreshFallbackMinimapButton(db)
end

local function InitMinimapButton()
    RefreshMinimapLauncher()
end

-- Public OUS API used by OUS2 to persist and refresh launcher visibility.
function OUS.SetMinimapButtonShown(shown)
    local db = EnsureMinimapDB()
    db.hide = shown ~= true
    RefreshMinimapLauncher()
end

-- Public OUS API used by config surfaces to read launcher visibility.
function OUS.IsMinimapButtonShown()
    local db = EnsureMinimapDB()
    return db.hide ~= true
end

-- Event hook waits for saved variables before registering or refreshing the launcher.
f:HookScript("OnEvent", function(self, event, arg1)
    if (event == "ADDON_LOADED" and arg1 == addonName) or event == "PLAYER_LOGIN" then
        InitMinimapButton()
    end
end)

_G.Odysseus_ToggleConfig = function()
    if not OUS.ConfigFrame then return end
    if OUS.ConfigFrame:IsShown() then
        OUS.ConfigFrame:Hide()
    else
        OUS.ConfigFrame:Show()
    end
end
