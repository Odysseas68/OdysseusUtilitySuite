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
        
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
        OdysseusDB.fishingSettings = OdysseusDB.fishingSettings or { history = {} }
    end
end)

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
        
        DEFAULT_CHAT_FRAME:AddMessage(formattedMsg)

        if msgFrame then
            msgFrame:AddMessage(formattedMsg)
        end
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Odysseus CRITICAL]|r LogDebug crashed: " .. tostring(err))
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

_G.Odysseus_ToggleConfig = function()
    if OUS.ConfigFrame:IsShown() then OUS.ConfigFrame:Hide() else OUS.ConfigFrame:Show() end
end