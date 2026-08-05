-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Help.lua
-- Version : 2026.08.05
-- Desc    : Tabbed help frame — slash commands and module documentation
-- ============================================================

local _, OUS = ...

-- =====================================
-- ODYSSEUS HELP FRAME (tabbed)
-- Loads after Config.lua — OUS.ConfigFrame already exists.
-- =====================================

local HELP_TABS = {
    {
        label = "General",
        lines = {
            {s = "— Main —"},
            {c = "/ous",              d = "Toggle Main Config"},
            {c = "/ous help",         d = "Show This Window"},
            {c = "/ous fish",         d = "Toggle Fishing Tracker"},
            {c = "/ousdebug",         d = "Toggle Debug Console"},
        },
    },
    {
        label = "Toolbox",
        lines = {
            {s = "— Toolbox —"},
            {c = "/tb",               d = "Show command list"},
            {c = "/tb toggle",        d = "Show/hide toolbox"},
            {c = "/tb lock",          d = "Lock position"},
            {c = "/tb unlock",        d = "Unlock — shows drag handle"},
            {c = "/tb scale [n]",     d = "Set icon scale (0.5–2.0)"},
            {c = "/tb ver",           d = "Switch to vertical layout"},
            {c = "/tb hor",           d = "Switch to horizontal layout"},
            {c = "/toolbox",          d = "Alias for /tb"},
        },
    },
    {
        label = "XP & Rep",
        lines = {
            {s = "— XP & Rep Bar —"},
            {c = "/xpstats",          d = "Show session XP & rep data"},
            {s = "— Debug —"},
            {c = "/toasttest",        d = "Test reward popup"},
            {c = "/delvedebug",       d = "Print delve instance IDs"},
        },
    },
    {
        label = "Auto Remount",
        lines = {
            {s = "— Auto Remount —"},
            {c = "/ar toggle",        d = "Toggle on/off"},
            {c = "/ar mount <n>",     d = "Set character mount"},
            {c = "/ar account <n>",   d = "Set account-wide mount"},
            {c = "/ar reset",         d = "Clear character mount override"},
            {c = "/ar reset account", d = "Clear account mount override"},
            {c = "/ar druid",         d = "Toggle druid form skip"},
            {c = "/ar delay <sec>",   d = "Set remount delay (0.1–5.0)"},
            {c = "/ar silent",        d = "Toggle error notifications"},
            {c = "/ar spy",           d = "Print loot-confirmed spells"},
            {c = "/ar spyfilter",     d = "Manage spy filter blacklist"},
            {c = "/ar add <id>",      d = "Add custom spell ID"},
            {c = "/ar remove <id>",   d = "Remove custom spell ID"},
            {c = "/ar export",        d = "Print custom spell IDs"},
            {c = "/ar wipe",          d = "Clear custom spell IDs"},
            {c = "/ar status",        d = "Show current settings"},
            {c = "/ar help",          d = "Show all AR commands"},
        },
    },
    {
        label = "Stats Bar",
        lines = {
            {s = "— Stats Bar —"},
            {c = "/sb toggle",        d = "Toggle on/off"},
            {c = "/sb table",         d = "Toggle table view"},
            {c = "/sb template <t>",  d = "Set single-line template"},
            {c = "/sb size <8-24>",   d = "Set font size"},
            {c = "/sb lock",          d = "Lock bar position"},
            {c = "/sb unlock",        d = "Unlock bar position"},
            {c = "/sb tlock",         d = "Lock table position"},
            {c = "/sb tunlock",       d = "Unlock table position"},
            {c = "/sb tokens",        d = "Show all template tokens"},
            {c = "/sb reset",         d = "Reset to defaults"},
            {c = "/sb status",        d = "Show current settings"},
        },
    },
    {
        label = "Openables",
        lines = {
            {s = "— Openables —"},
            {c = "/op add <id> [qty]",   d = "Add item to custom list"},
            {c = "/op remove <id>",      d = "Remove from custom list"},
            {c = "/op unblacklist <id>", d = "Remove from blacklist"},
            {c = "/op list",             d = "Open blacklist frame"},
            {c = "/op clist",            d = "Open custom items frame"},
            {c = "/op madd",             d = "Open drag-and-drop add frame"},
            {c = "/op auto",             d = "Toggle auto-open"},
            {c = "/op lock",             d = "Lock button position"},
            {c = "/op unlock",           d = "Unlock button position"},
            {c = "/op status",           d = "Show current settings"},
        },
    },
}

-- =====================================
-- Frame
-- =====================================
local helpFrame = CreateFrame("Frame", "OdysseusHelpFrame", UIParent, "BackdropTemplate")
helpFrame:SetSize(480, 480)
helpFrame:SetPoint("CENTER")
helpFrame:SetFrameStrata("DIALOG")
helpFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
helpFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
helpFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)
helpFrame:Hide()
helpFrame:SetMovable(true)
helpFrame:SetClampedToScreen(true)
helpFrame:EnableMouse(true)
helpFrame:RegisterForDrag("LeftButton")
helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, helpFrame:GetName())

-- Header bar
helpFrame.headerBg = helpFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
helpFrame.headerBg:SetPoint("TOPLEFT", 4, -4)
helpFrame.headerBg:SetPoint("TOPRIGHT", -4, -4)
helpFrame.headerBg:SetHeight(26)
helpFrame.headerBg:SetColorTexture(1, 1, 1, 1)
helpFrame.headerBg:SetGradient("HORIZONTAL",
    CreateColor(0.3, 0.1, 0.5, 0.8),
    CreateColor(0.07, 0.05, 0.1, 0.8))

helpFrame.title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
helpFrame.title:SetPoint("TOP", helpFrame, "TOP", 0, -8)
helpFrame.title:SetText("Odysseus Commands")
helpFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

local helpCloseBtn = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
helpCloseBtn:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -2, -2)

-- =====================================
-- Nav panel (left)
-- =====================================
local helpNav = CreateFrame("Frame", nil, helpFrame, "BackdropTemplate")
helpNav:SetSize(110, 434)
helpNav:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 4, -34)
helpNav:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
helpNav:SetBackdropColor(0.05, 0.05, 0.07, 0.78)
helpNav:SetBackdropBorderColor(0.24, 0.22, 0.30, 0.95)

-- =====================================
-- Content panel (right)
-- =====================================
local helpContent = CreateFrame("Frame", nil, helpFrame, "BackdropTemplate")
helpContent:SetPoint("TOPLEFT", helpNav, "TOPRIGHT", 0, 0)
helpContent:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -4, 4)
helpContent:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
helpContent:SetBackdropColor(0.07, 0.05, 0.10, 0.18)
helpContent:SetBackdropBorderColor(0.20, 0.14, 0.28, 0.35)

-- =====================================
-- Compact banner (shared, sits above all tab content)
-- =====================================
local helpBannerLogo = helpContent:CreateTexture(nil, "ARTWORK")
helpBannerLogo:SetSize(200, 100)
helpBannerLogo:SetPoint("TOP", helpContent, "TOP", 0, -6)
helpBannerLogo:SetTexture("Interface\\AddOns\\OdysseusUtilitySuite\\Media\\icon\\OUS_banner")

local helpBannerTitle = helpContent:CreateFontString(nil, "OVERLAY")
helpBannerTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
helpBannerTitle:SetPoint("TOP", helpBannerLogo, "BOTTOM", 0, -3)
helpBannerTitle:SetText("|cFF00FFFFOdysseus|r |cFFAA88FFUtility Suite|r")

local helpBannerSep = helpContent:CreateTexture(nil, "ARTWORK")
helpBannerSep:SetHeight(1)
helpBannerSep:SetPoint("TOPLEFT",  helpContent, "TOPLEFT",  8, -116)
helpBannerSep:SetPoint("TOPRIGHT", helpContent, "TOPRIGHT", -8, -116)
helpBannerSep:SetColorTexture(0.4, 0.2, 0.6, 0.7)

-- =====================================
-- Tab logic
-- =====================================
local helpNavBtns   = {}
local helpCurrentTab = nil
local helpScrollFrames = {}  -- lazy-created per tab, stores {box, bar}

local function SetHelpNavBtnState(btn, active)
    if active then
        btn:SetBackdropColor(0.12, 0.12, 0.15, 0.97)
        btn:SetBackdropBorderColor(0.62, 0.60, 0.68, 1)
        btn.base:SetColorTexture(0.18, 0.18, 0.22, 0.96)
        btn.accent:SetColorTexture(0.84, 0.80, 0.92, 1)
        btn.accent:Show()
        btn.text:SetTextColor(1.0, 0.97, 0.92)
        btn.topSheen:SetAlpha(0.22)
        btn.bottomShade:SetAlpha(0.28)
        btn.innerGlow:Show()
    else
        btn:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
        btn:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)
        btn.base:SetColorTexture(0.13, 0.13, 0.16, 0.94)
        btn.accent:SetColorTexture(0.58, 0.58, 0.66, 0.90)
        btn.accent:Hide()
        btn.text:SetTextColor(0.82, 0.82, 0.88)
        btn.topSheen:SetAlpha(0.12)
        btn.bottomShade:SetAlpha(0.20)
        btn.innerGlow:Hide()
    end
end

local function ShowHelpTab(index)
    helpCurrentTab = index

    for i, btn in ipairs(helpNavBtns) do
        SetHelpNavBtnState(btn, i == index)
    end

    for i, t in pairs(helpScrollFrames) do
        if i == index then
            t.box:Show()
            t.bar:Show()
            t.child:Show()
        else
            t.box:Hide()
            t.bar:Hide()
            t.child:Hide()
        end
    end

    if helpScrollFrames[index] then return end

    -- Lazy-create ScrollBox + MinimalScrollBar for this tab, below banner
    local scrollBox = CreateFrame("Frame", nil, helpContent, "WowScrollBox")
    scrollBox:SetPoint("TOPLEFT", 10, -122)
    scrollBox:SetPoint("BOTTOMRIGHT", -14, 10)

    local scrollBar = CreateFrame("EventFrame", nil, helpContent, "MinimalScrollBar")
    scrollBar:SetWidth(12)
    scrollBar:SetPoint("TOPLEFT",    scrollBox, "TOPRIGHT",    2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local child = CreateFrame("Frame", nil, scrollBox)
    child:SetWidth(scrollBox:GetWidth() - 4)
    child.scrollable = true

    local fs = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 0, 0)
    fs:SetWidth(child:GetWidth())
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(3)

    local lines = {}
    for _, entry in ipairs(HELP_TABS[index].lines) do
        if entry.s then
            lines[#lines + 1] = "|cFFAA88FF" .. entry.s .. "|r"
        elseif entry.c then
            lines[#lines + 1] = "|cFF00FF00" .. entry.c .. "|r  |cFFCCCCCC" .. entry.d .. "|r"
        end
    end
    fs:SetText(table.concat(lines, "\n"))
    child:SetHeight(fs:GetStringHeight() + 20)

    local view = CreateScrollBoxLinearView()
    view:SetPanExtent(20)
    ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)

    -- Tint MinimalScrollBar to OUS purple theme
    local tr = scrollBar.Track
    if tr then
        -- Track background textures (direct textures)
        if tr.Begin  then tr.Begin:SetVertexColor(0.4, 0.2, 0.6) end
        if tr.Middle then tr.Middle:SetVertexColor(0.4, 0.2, 0.6) end
        if tr.End    then tr.End:SetVertexColor(0.4, 0.2, 0.6) end
        -- Thumb sub-textures (one level deeper)
        local th = tr.Thumb
        if th then
            if th.Begin  then th.Begin:SetVertexColor(0.7, 0.4, 1.0) end
            if th.Middle then th.Middle:SetVertexColor(0.7, 0.4, 1.0) end
            if th.End    then th.End:SetVertexColor(0.7, 0.4, 1.0) end
        end
    end
    if scrollBar.Back   and scrollBar.Back.Texture   then
        scrollBar.Back.Texture:SetVertexColor(0.7, 0.4, 1.0)
    end
    if scrollBar.Forward and scrollBar.Forward.Texture then
        scrollBar.Forward.Texture:SetVertexColor(0.7, 0.4, 1.0)
    end

    helpScrollFrames[index] = { box = scrollBox, bar = scrollBar, child = child }
    scrollBox:Show()
    scrollBar:Show()
end

local function CreateHelpNavBtn(tabIndex, yOffset)
    local btn = CreateFrame("Button", nil, helpNav, "BackdropTemplate")
    btn:SetSize(98, 28)
    btn:SetPoint("TOP", helpNav, "TOP", 0, yOffset)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    btn.base = btn:CreateTexture(nil, "BACKGROUND")
    btn.base:SetPoint("TOPLEFT", 1, -1)
    btn.base:SetPoint("BOTTOMRIGHT", -1, 1)

    btn.topSheen = btn:CreateTexture(nil, "ARTWORK")
    btn.topSheen:SetPoint("TOPLEFT", 1, -1)
    btn.topSheen:SetPoint("TOPRIGHT", -1, -1)
    btn.topSheen:SetHeight(9)
    btn.topSheen:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.topSheen:SetGradient("VERTICAL",
        CreateColor(0.90, 0.90, 0.96, 0.14),
        CreateColor(0.55, 0.55, 0.62, 0.02))

    btn.bottomShade = btn:CreateTexture(nil, "ARTWORK")
    btn.bottomShade:SetPoint("BOTTOMLEFT", 1, 1)
    btn.bottomShade:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bottomShade:SetHeight(8)
    btn.bottomShade:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.bottomShade:SetGradient("VERTICAL",
        CreateColor(0.00, 0.00, 0.00, 0.02),
        CreateColor(0.00, 0.00, 0.00, 0.22))

    btn.innerGlow = btn:CreateTexture(nil, "OVERLAY")
    btn.innerGlow:SetPoint("TOPLEFT", 2, -2)
    btn.innerGlow:SetPoint("BOTTOMRIGHT", -2, 2)
    btn.innerGlow:SetColorTexture(0.84, 0.80, 0.92, 0.05)
    btn.innerGlow:Hide()

    btn.accent = btn:CreateTexture(nil, "ARTWORK")
    btn.accent:SetPoint("TOPLEFT", 1, -1)
    btn.accent:SetPoint("BOTTOMLEFT", 1, 1)
    btn.accent:SetWidth(3)
    btn.accent:Hide()

    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(HELP_TABS[tabIndex].label)

    btn:SetScript("OnEnter", function(self)
        if helpCurrentTab == tabIndex then return end
        self:SetBackdropColor(0.11, 0.11, 0.14, 0.98)
        self:SetBackdropBorderColor(0.48, 0.48, 0.56, 1)
        self.base:SetColorTexture(0.16, 0.16, 0.20, 0.96)
        self.text:SetTextColor(0.96, 0.94, 0.98)
        self.accent:SetColorTexture(0.72, 0.72, 0.80, 0.95)
        self.accent:Show()
        self.innerGlow:Show()
    end)
    btn:SetScript("OnLeave", function()
        SetHelpNavBtnState(btn, helpCurrentTab == tabIndex)
    end)
    btn:SetScript("OnClick", function()
        ShowHelpTab(tabIndex)
    end)

    SetHelpNavBtnState(btn, false)
    helpNavBtns[tabIndex] = btn
end

for i = 1, #HELP_TABS do
    CreateHelpNavBtn(i, -8 - (i - 1) * 32)
end

-- Open on General tab by default each time it's shown
helpFrame:SetScript("OnShow", function()
    ShowHelpTab(helpCurrentTab or 1)
end)
