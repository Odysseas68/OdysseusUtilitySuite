-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Config.lua
-- Version : 2026.10.26
-- Desc    : OUS2 main configuration frame — three-panel layout, nav system, page switching

local _, OUS = ...
local T = OUS.Theme
local LSM = LibStub("LibSharedMedia-3.0")

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

OUS.Config2 = {}
local C = OUS.Config2

C.frame            = nil
C.currentPage      = nil
C.pages            = {}        -- [pageName] = { frame, sidebarFrame, navBtn }
C.navButtons       = {}        -- ordered list of nav button frames
C.sidebarContainer = nil
C.locked           = false     -- frame resize lock state
local RefreshSharedScrollbar

-- ---------------------------------------------------------------------------
-- Page order (drives nav button creation order)
-- ---------------------------------------------------------------------------

local PAGE_ORDER = {
    "General",
    "XPBar",
    "FlightMaster",
    "FlightRouting",
    "Utilities",
    "Openables",
    "StatsBar",
    "AutoRemount",
    "FasterLoot",
    "FishingTracker",
    "Toolbox",
    -- separator before these two
    "Help",
    "Changelog",
}

-- Pages that appear after the separator in the nav
local SEPARATOR_BEFORE = { Help = true, Changelog = true }

-- Display labels for nav buttons
local PAGE_LABELS = {
    General         = "General",
    XPBar           = "XP Bar",
    FlightMaster    = "Flight Master",
    FlightRouting   = "Flight Routing",
    Utilities       = "Utilities",
    Openables       = "Openables",
    StatsBar        = "Stats Bar",
    AutoRemount     = "Auto Remount",
    FasterLoot      = "Faster Loot",
    FishingTracker  = "Fishing Tracker",
    Toolbox         = "Toolbox",
    Help            = "Help",
    Changelog       = "Changelog",
}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- Adds a texture to a parent frame; returns the texture object
local function AddTexture(parent, file, layer, width, height)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK")
    tex:SetTexture(T.TEX .. file)
    tex:SetSize(width, height)
    return tex
end

local mediaDropdown
local mediaDropdownButtons = {}
local ownedColorPickerInfo

local function EnsureMediaDropdown()
    if mediaDropdown then
        return mediaDropdown
    end

    mediaDropdown = CreateFrame("Frame", "OUS2MediaDropdown", UIParent, "BackdropTemplate")
    mediaDropdown:SetSize(220, 300)
    mediaDropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    mediaDropdown:Hide()

    mediaDropdown:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    mediaDropdown:SetBackdropColor(0.05, 0.04, 0.08, 0.98)
    mediaDropdown:SetBackdropBorderColor(T.Colors.accent[1], T.Colors.accent[2], T.Colors.accent[3], 0.9)

    mediaDropdown.title = mediaDropdown:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
    mediaDropdown.title:SetPoint("TOP", mediaDropdown, "TOP", 0, -10)
    mediaDropdown.title:SetTextColor(T.Colors.header[1], T.Colors.header[2], T.Colors.header[3], T.Colors.header[4])

    local scrollFrame = CreateFrame("ScrollFrame", nil, mediaDropdown, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mediaDropdown, "TOPLEFT", 12, -34)
    scrollFrame:SetPoint("BOTTOMRIGHT", mediaDropdown, "BOTTOMRIGHT", -28, 10)

    mediaDropdown.scrollChild = CreateFrame("Frame", nil, scrollFrame)
    mediaDropdown.scrollChild:SetSize(190, 1)
    scrollFrame:SetScrollChild(mediaDropdown.scrollChild)

    return mediaDropdown
end

function C.OpenMediaDropdown(owner, mediaType, currentName, onSelect)
    if InCombatLockdown() then return false end
    local dropdown = EnsureMediaDropdown()
    local titleText = "Select " .. (mediaType == "font" and "Font" or (mediaType == "statusbar" and "Texture" or "Border"))

    if dropdown:IsShown() and dropdown.owner == owner and dropdown.mediaType == mediaType then
        dropdown:Hide()
        return
    end

    dropdown.owner = owner
    dropdown.mediaType = mediaType
    dropdown.title:SetText(titleText)
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -4)

    for _, btn in ipairs(mediaDropdownButtons) do
        btn:Hide()
    end

    local list = LSM:List(mediaType)
    local yOffset = 0

    for i, name in ipairs(list) do
        local btn = mediaDropdownButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, dropdown.scrollChild)
            btn:SetSize(190, 24)

            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()

            btn.label = btn:CreateFontString(nil, "OVERLAY", T.Fonts.small)
            btn.label:SetPoint("LEFT", btn, "LEFT", 6, 0)
            btn.label:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            btn.label:SetJustifyH("LEFT")
            btn.label:SetWordWrap(false)

            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetColorTexture(1, 1, 1, 0.10)

            table.insert(mediaDropdownButtons, btn)
        end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", dropdown.scrollChild, "TOPLEFT", 0, -yOffset)
        btn.bg:SetTexture(nil)
        btn.bg:SetColorTexture(0.08, 0.07, 0.11, 0.92)
        btn.label:SetFontObject(_G[T.Fonts.small] or GameFontNormalSmall)

        local path = LSM:Fetch(mediaType, name)
        if mediaType == "statusbar" and path then
            btn.bg:SetColorTexture(1, 1, 1, 1)
            btn.bg:SetTexture(path)
            btn.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        elseif mediaType == "font" and path then
            local ok = pcall(function()
                btn.label:SetFont(path, 11, "OUTLINE")
            end)
            if not ok then
                btn.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            end
        elseif mediaType == "border" then
            btn.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        end

        btn.label:SetText(name)
        if name == currentName then
            btn.label:SetTextColor(T.Colors.accent[1], T.Colors.accent[2], T.Colors.accent[3], 1)
        else
            btn.label:SetTextColor(T.Colors.text[1], T.Colors.text[2], T.Colors.text[3], 1)
        end

        btn:SetScript("OnClick", function()
            if onSelect then
                onSelect(name)
            end
            dropdown:Hide()
        end)

        btn:Show()
        yOffset = yOffset + 26
    end

    dropdown.scrollChild:SetHeight(math.max(1, yOffset))
    dropdown:Show()
end

function C.OpenColorPicker(colorTable, swatchFrame, onUpdate)
    if InCombatLockdown() then return false end
    if type(colorTable) ~= "table" or not swatchFrame then
        return
    end

    colorTable.r = colorTable.r or 1
    colorTable.g = colorTable.g or 1
    colorTable.b = colorTable.b or 1

    local previous = {
        r = colorTable.r,
        g = colorTable.g,
        b = colorTable.b,
    }

    local function ApplyColor()
        if InCombatLockdown() then return end
        local r, g, b = ColorPickerFrame:GetColorRGB()
        colorTable.r, colorTable.g, colorTable.b = r, g, b
        swatchFrame:SetColorTexture(r, g, b, 1)
        if onUpdate then
            onUpdate(r, g, b)
        end
    end

    local info = {
        extraInfo = {},
        r = colorTable.r,
        g = colorTable.g,
        b = colorTable.b,
        hasOpacity = false,
        colorPickerFunc = ApplyColor,
        swatchFunc = ApplyColor,
        cancelFunc = function()
            if InCombatLockdown() then return end
            colorTable.r, colorTable.g, colorTable.b = previous.r, previous.g, previous.b
            swatchFrame:SetColorTexture(previous.r, previous.g, previous.b, 1)
            if onUpdate then
                onUpdate(previous.r, previous.g, previous.b)
            end
        end,
    }
    ownedColorPickerInfo = info
    ColorPickerFrame:SetupColorPickerAndShow(info)
end

local copyDialog
local copyDialogEditBox

function C.ShowCopyTextDialog(titleText, bodyText)
    if InCombatLockdown() then return false end
    if not copyDialog then
        copyDialog = CreateFrame("Frame", "OUS2CopyTextDialog", UIParent, "BackdropTemplate")
        copyDialog:SetSize(520, 420)
        copyDialog:SetPoint("CENTER")
        copyDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        copyDialog:Hide()
        tinsert(UISpecialFrames, "OUS2CopyTextDialog")

        copyDialog:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        copyDialog:SetBackdropColor(0.05, 0.04, 0.08, 0.98)
        copyDialog:SetBackdropBorderColor(T.Colors.accent[1], T.Colors.accent[2], T.Colors.accent[3], 0.9)

        local title = copyDialog:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
        title:SetPoint("TOP", copyDialog, "TOP", 0, -14)
        title:SetTextColor(T.Colors.header[1], T.Colors.header[2], T.Colors.header[3], T.Colors.header[4])
        copyDialog.title = title

        local closeBtn = CreateFrame("Button", nil, copyDialog)
        closeBtn:SetSize(28, 28)
        closeBtn:SetPoint("TOPRIGHT", copyDialog, "TOPRIGHT", -8, -8)
        closeBtn:SetNormalTexture(T.Tex("CloseNormal"))
        closeBtn:SetHighlightTexture(T.Tex("CloseHover"))
        closeBtn:SetPushedTexture(T.Tex("ClosePressed"))
        closeBtn:SetScript("OnClick", function()
            copyDialog:Hide()
        end)

        local scrollFrame = CreateFrame("ScrollFrame", nil, copyDialog, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", copyDialog, "TOPLEFT", 18, -46)
        scrollFrame:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -34, 54)

        copyDialogEditBox = CreateFrame("EditBox", nil, scrollFrame)
        copyDialogEditBox:SetMultiLine(true)
        copyDialogEditBox:SetAutoFocus(false)
        copyDialogEditBox:SetFontObject(ChatFontNormal)
        copyDialogEditBox:SetWidth(450)
        copyDialogEditBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            copyDialog:Hide()
        end)
        scrollFrame:SetScrollChild(copyDialogEditBox)

        local selectAllBtn = CreateFrame("Button", nil, copyDialog)
        selectAllBtn:SetSize(120, 28)
        selectAllBtn:SetPoint("BOTTOMLEFT", copyDialog, "BOTTOMLEFT", 18, 16)
        selectAllBtn:SetNormalTexture(T.Tex("ActionNormal"))
        selectAllBtn:SetHighlightTexture(T.Tex("ActionHover"))
        selectAllBtn:SetPushedTexture(T.Tex("ActionPressed"))

        local selectAllText = selectAllBtn:CreateFontString(nil, "OVERLAY", T.Fonts.small)
        selectAllText:SetAllPoints()
        selectAllText:SetText("Select All")
        selectAllText:SetTextColor(T.Colors.text[1], T.Colors.text[2], T.Colors.text[3], T.Colors.text[4])

        selectAllBtn:SetScript("OnClick", function()
            copyDialogEditBox:HighlightText()
            copyDialogEditBox:SetFocus()
        end)

        local closeActionBtn = CreateFrame("Button", nil, copyDialog)
        closeActionBtn:SetSize(120, 28)
        closeActionBtn:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -18, 16)
        closeActionBtn:SetNormalTexture(T.Tex("ActionNormal"))
        closeActionBtn:SetHighlightTexture(T.Tex("ActionHover"))
        closeActionBtn:SetPushedTexture(T.Tex("ActionPressed"))

        local closeActionText = closeActionBtn:CreateFontString(nil, "OVERLAY", T.Fonts.small)
        closeActionText:SetAllPoints()
        closeActionText:SetText("Close")
        closeActionText:SetTextColor(T.Colors.text[1], T.Colors.text[2], T.Colors.text[3], T.Colors.text[4])

        closeActionBtn:SetScript("OnClick", function()
            copyDialog:Hide()
        end)
    end

    copyDialog.title:SetText(titleText or "Copy Text")
    copyDialogEditBox:SetText(bodyText or "")
    copyDialogEditBox:SetCursorPosition(0)
    copyDialog:Show()
end

-- Hide only owned editors; shared-picker closure must not apply or roll back settings.
local function CloseOwnedEditors()
    if mediaDropdown then mediaDropdown:Hide() end
    if copyDialog then copyDialog:Hide() end
    local picker = _G.ColorPickerFrame
    local info = ownedColorPickerInfo
    if info and picker and type(picker.GetExtraInfo) == "function"
        and picker:GetExtraInfo() == info.extraInfo and picker.swatchFunc == info.swatchFunc then
        picker:Hide()
    end
    ownedColorPickerInfo = nil
end

-- ---------------------------------------------------------------------------
-- NineSlice frame border
-- ---------------------------------------------------------------------------

local function BuildFrameBorder(frame)
    local F = T.Frame

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(T.Tex("Background"))
    bg:SetPoint("TOPLEFT",     frame, "TOPLEFT",     F.bgInsetX,  -F.bgInsetY)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -F.bgInsetX,  F.bgInsetY)

    -- Top / bottom edges (stretch horizontally, inset from corners)
    local top = AddTexture(frame, T.Assets.Top, "BORDER", 512, F.topHeight)
    top:SetPoint("TOPLEFT",     frame, "TOPLEFT",     F.edgeInset,  0)
    top:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -F.edgeInset, 0)

    local bottom = AddTexture(frame, T.Assets.Bottom, "BORDER", 512, F.topHeight)
    bottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  F.edgeInset,  0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -F.edgeInset, 0)

    -- Vertical edges (stretch full height)
    local left = AddTexture(frame, T.Assets.VerticalLeft, "BORDER", F.sideWidth, 172)
    left:SetPoint("TOPLEFT",    frame, "TOPLEFT",    F.VedgeInset,  0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", F.VedgeInset,  0)
    left:SetWidth(F.sideWidth)

    local right = AddTexture(frame, T.Assets.VerticalRight, "BORDER", F.sideWidth, 172)
    right:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -F.VedgeInset, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -F.VedgeInset, 0)
    right:SetWidth(F.sideWidth)

    -- Corners
    local tl = AddTexture(frame, T.Assets.TopLeft,     "OVERLAY", F.cornerSize, F.cornerSize)
    tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    local tr = AddTexture(frame, T.Assets.TopRight,    "OVERLAY", F.cornerSize, F.cornerSize)
    tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    local bl = AddTexture(frame, T.Assets.BottomLeft,  "OVERLAY", F.cornerSize, F.cornerSize)
    bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    local br = AddTexture(frame, T.Assets.BottomRight, "OVERLAY", F.cornerSize, F.cornerSize)
    br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    -- Gems
    local headerGem = AddTexture(frame, T.Assets.HeaderGem, "OVERLAY", 128, 20)
    headerGem:SetPoint("TOP", frame, "TOP", 0, -F.gemOffsetTop)

    local footerGem = AddTexture(frame, T.Assets.FooterGem, "OVERLAY", 128, 20)
    footerGem:SetPoint("BOTTOM", frame, "BOTTOM", 0, F.gemOffsetBottom)
end

-- ---------------------------------------------------------------------------
-- Header bar
-- ---------------------------------------------------------------------------

local function BuildHeader(frame, navPanel)
    local F = T.Frame
    local col = T.Colors

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", T.Fonts.title)
    title:SetPoint("TOP", frame, "TOP", 0, -36)
    title:SetText("Odysseus Utility Suite")
    title:SetTextColor(col.text[1], col.text[2], col.text[3], col.text[4])

    -- Close button top-right (custom artwork)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -28)
    closeBtn:SetNormalTexture(T.Tex("CloseNormal"))
    closeBtn:SetHighlightTexture(T.Tex("CloseHover"))
    closeBtn:SetPushedTexture(T.Tex("ClosePressed"))
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Lock / Unlock button top-left — checkbox texture + text label + Logo
    local lockBtn = CreateFrame("Button", nil, frame)
    lockBtn:SetSize(120, 24)
    lockBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -32)

    local lockCheck = lockBtn:CreateTexture(nil, "ARTWORK")
    lockCheck:SetSize(16, 16)
    lockCheck:SetPoint("LEFT", lockBtn, "LEFT", 0, 0)

    local lockLabel = lockBtn:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    lockLabel:SetPoint("LEFT", lockCheck, "RIGHT", 6, 0)
    lockLabel:SetTextColor(col.text[1], col.text[2], col.text[3], 1)

    local sidebarLogo = navPanel:CreateTexture(nil, "ARTWORK")
    sidebarLogo:SetTexture(T.Tex("Logo"))
    sidebarLogo:SetSize(80, 80)
    sidebarLogo:SetPoint("TOP", navPanel, "TOP", 0, 0)

    local function UpdateLockState()
        if C.locked then
            lockCheck:SetTexture(T.Tex("CheckboxOn"))
            lockLabel:SetText("Unlock Window")
            frame:SetResizable(false)
        else
            lockCheck:SetTexture(T.Tex("CheckboxOff"))
            lockLabel:SetText("Lock Window")
            frame:SetResizable(true)
        end
    end

    lockBtn:SetScript("OnClick", function()
        C.locked = not C.locked
        UpdateLockState()
    end)

    UpdateLockState()
end

-- ---------------------------------------------------------------------------
-- Footer bar
-- ---------------------------------------------------------------------------

local function BuildFooter(frame)
    local col = T.Colors
    local btnH = 28
    local btnY  = 28      -- distance from bottom edge
    local gap   = 50       -- gap between buttons

    -- Close button (rightmost)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(100, btnH)
    closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, btnY)
    closeBtn:SetNormalTexture(T.Tex("ActionNormal"))
    closeBtn:SetHighlightTexture(T.Tex("ActionHover"))
    closeBtn:SetPushedTexture(T.Tex("ActionPressed"))

    local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    closeLabel:SetAllPoints()
    closeLabel:SetText("Close")
    closeLabel:SetTextColor(col.text[1], col.text[2], col.text[3], col.text[4])

    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Reset to Defaults button (left of Close)
    local resetBtn = CreateFrame("Button", nil, frame)
    resetBtn:SetSize(180, btnH)
    resetBtn:SetPoint("BOTTOMRIGHT", closeBtn, "BOTTOMLEFT", gap, 0)
    resetBtn:SetNormalTexture(T.Tex("ActionNormal"))
    resetBtn:SetHighlightTexture(T.Tex("ActionHover"))
    resetBtn:SetPushedTexture(T.Tex("ActionPressed"))

    local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    resetLabel:SetAllPoints()
    resetLabel:SetText("Reset to Defaults")
    resetLabel:SetTextColor(col.text[1], col.text[2], col.text[3], col.text[4])

    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_ALL")
    end)
    return resetBtn, btnY + btnH
end

-- ---------------------------------------------------------------------------
-- Left navigation panel
-- ---------------------------------------------------------------------------

local function SetNavButtonActive(pageName)
    local col = T.Colors
    for _, entry in ipairs(C.navButtons) do
        local isActive = (entry.pageName == pageName)
        if isActive then
            entry.btn:SetNormalTexture(T.Tex("ButtonSelected"))
            entry.label:SetTextColor(col.accent[1], col.accent[2], col.accent[3], 1)
        else
            entry.btn:SetNormalTexture(T.Tex("ButtonNormal"))
            entry.label:SetTextColor(col.text[1], col.text[2], col.text[3], 1)
        end
    end
end

-- Retained pages synchronize settings without replaying navigation-only initialization.
local function RefreshCurrentPage()
    local entry = C.pages[C.currentPage]
    if entry and entry.RefreshCurrent then entry.RefreshCurrent() end
end

local function SwitchPage(pageName)
    if C.currentPage == pageName then
        RefreshCurrentPage()
        if RefreshSharedScrollbar then RefreshSharedScrollbar() end
        return
    end

    -- Hide current page
    if C.currentPage and C.pages[C.currentPage] then
        local prev = C.pages[C.currentPage]
        if prev.frame then prev.frame:Hide() end
        if prev.sidebarFrame then prev.sidebarFrame:Hide() end
    end

    C.currentPage = pageName

    -- Show or create new page
    local entry = C.pages[pageName]
    if entry then
        if entry.frame then entry.frame:Show() end
        if entry.sidebarFrame then entry.sidebarFrame:Show() end
        if entry.Refresh then
            entry.Refresh()
        end
    end

    SetNavButtonActive(pageName)
    if RefreshSharedScrollbar then RefreshSharedScrollbar() end
end

local function BuildNavPanel(navPanel)
    local F = T.Frame
    local col = T.Colors
    local btnW = F.navButtonWidth
    local btnInset = F.navButtonInset
    local btnH = 28
    local btnSpacing = 4
    local yOffset = -F.headerHeight - 35

    for _, pageName in ipairs(PAGE_ORDER) do

        -- Separator line before Help / Changelog
        if SEPARATOR_BEFORE[pageName] then
            local sep = navPanel:CreateTexture(nil, "ARTWORK")
            sep:SetColorTexture(col.separator[1], col.separator[2], col.separator[3], col.separator[4])
            sep:SetSize(btnW - 16, 1)
            sep:SetPoint("TOPLEFT", navPanel, "TOPLEFT", btnInset, yOffset - 6)
            yOffset = yOffset - 14
        end

        -- Nav button
        local btn = CreateFrame("Button", nil, navPanel)
        btn:SetSize(btnW, btnH)
        btn:SetPoint("TOPLEFT", navPanel, "TOPLEFT", btnInset, yOffset)
        btn:SetNormalTexture(T.Tex("ButtonNormal"))
        btn:SetHighlightTexture(T.Tex("ButtonHover"))

        -- Button label
        local label = btn:CreateFontString(nil, "OVERLAY", T.Fonts.navButton)
        label:SetPoint("LEFT", btn, "LEFT", 28, 1)
        label:SetText(PAGE_LABELS[pageName] or pageName)
        label:SetTextColor(col.text[1], col.text[2], col.text[3], 1)

        btn:SetScript("OnClick", function()
            SwitchPage(pageName)
        end)

        -- Register page entry (frame created later by page files)
        if not C.pages[pageName] then
            C.pages[pageName] = {}
        end
        C.pages[pageName].navBtn    = btn

        table.insert(C.navButtons, {
            pageName  = pageName,
            btn       = btn,
            label     = label,
        })

        yOffset = yOffset - (btnH + btnSpacing)
    end
end

-- ---------------------------------------------------------------------------
-- Shared native scrollbar
-- ---------------------------------------------------------------------------

-- Native dragging owns only the existing scrollbar gutter, not page or footer input.
local function BuildScrollbar(frame, contentPanel, scrollFrame, footerButton, footerExtent)
    local S = T.Scroll
    local col = T.Colors
    local slider = CreateFrame("Slider", nil, contentPanel)
    slider:SetWidth(S.trackW)
    slider:SetPoint("TOPRIGHT", contentPanel, "TOPRIGHT", 0, 0)
    slider:SetOrientation("VERTICAL")
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    slider:SetHitRectInsets(-S.hitInset, -S.hitInset, 0, 0)
    slider:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(false)
    slider:SetMinMaxValues(0, 0)

    -- Cropped portrait masks form rounded caps without changing the input geometry.
    local function CreateCapsule(parent, width, inset, layer, color)
        local caps = {}
        for index, point in ipairs({ "TOP", "BOTTOM" }) do
            local cap = parent:CreateTexture(nil, layer)
            cap:SetSize(width, width / 2)
            cap:SetPoint(point, parent, point, 0, index == 1 and -inset or inset)
            local mask = parent:CreateMaskTexture()
            mask:SetTexture(S.capMask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(cap)
            mask:SetTexCoord(0, 1, (index - 1) / 2, index / 2)
            cap:AddMaskTexture(mask)
            cap:SetColorTexture(unpack(color))
            caps[index] = cap
        end
        local middle = parent:CreateTexture(nil, layer)
        middle:SetPoint("TOPLEFT", caps[1], "BOTTOMLEFT")
        middle:SetPoint("BOTTOMRIGHT", caps[2], "TOPRIGHT")
        middle:SetColorTexture(unpack(color))
        return { caps[1], middle, caps[2] }
    end

    CreateCapsule(slider, S.railW, 0, "BACKGROUND", col.border)
    CreateCapsule(slider, S.railW - 2, 1, "BORDER", col.bgDark)

    slider:SetThumbTexture(T.Tex("ScrollThumb"))
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(S.trackW, S.thumbH)
    thumb:SetColorTexture(1, 1, 1, 0)
    local thumbArt = CreateFrame("Frame", nil, slider)
    thumbArt:SetAllPoints(thumb)
    thumbArt:EnableMouse(false)
    CreateCapsule(thumbArt, S.trackW, 0, "BACKGROUND", col.border)
    local thumbFill = CreateCapsule(thumbArt, S.trackW - 2, 1, "ARTWORK", col.accent)
    CreateCapsule(thumbArt, S.shineW, S.shineInset, "OVERLAY", col.highlight)
    for _, offset in ipairs({ -3, 0, 3 }) do
        local grip = thumbArt:CreateTexture(nil, "OVERLAY", nil, 1)
        grip:SetSize(S.trackW - 6, 1)
        grip:SetPoint("CENTER", thumbArt, "CENTER", 0, offset)
        grip:SetColorTexture(unpack(col.border))
    end

    local updating, hovered, pressed, enabled = false, false, false, false
    local bottomInset
    local targetOffset, startOffset, wheelElapsed
    local smoothWrite = false

    -- Discard wheel intent whenever another interaction owns the scroll position.
    local function StopWheelMotion()
        targetOffset, startOffset, wheelElapsed = nil, nil, nil
        slider:SetScript("OnUpdate", nil)
    end

    -- The capsule follows the transparent native thumb without receiving input.
    local function UpdateAppearance()
        local color = col.textDisabled
        if enabled then
            color = pressed and col.scrollThumbDragging or (hovered and col.scrollThumbHover or col.accent)
        end
        for _, region in ipairs(thumbFill) do region:SetColorTexture(unpack(color)) end
    end

    -- Consume the native range; do not infer it from the declared child height.
    local function RefreshScrollbar()
        if updating then return end
        updating = true

        local inset = math.max(0, footerExtent - T.Frame.footerHeight + S.footerGap)
        local footerTop, panelBottom = footerButton:GetTop(), contentPanel:GetBottom()
        if footerTop and panelBottom then
            inset = math.max(0, footerTop - panelBottom + S.footerGap)
        end
        if bottomInset ~= inset then
            bottomInset = inset
            slider:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", 0, inset)
        end

        local range = math.max(0, scrollFrame:GetVerticalScrollRange())
        local offset = scrollFrame:GetVerticalScroll()
        local clamped = math.max(0, math.min(offset, range))
        local trackHeight = math.max(1, slider:GetHeight())
        local thumbHeight = math.min(trackHeight, S.thumbH)
        if thumb:GetHeight() ~= thumbHeight then thumb:SetHeight(thumbHeight) end

        local minValue, maxValue = slider:GetMinMaxValues()
        if minValue ~= 0 or maxValue ~= range then slider:SetMinMaxValues(0, range) end
        if slider:GetValue() ~= clamped then slider:SetValue(clamped) end
        -- New scroll writes wait out combat; the established wheel path is untouched.
        if offset ~= clamped and not InCombatLockdown() then scrollFrame:SetVerticalScroll(clamped) end
        local entry = C.pages[C.currentPage]
        local innerScroller = entry and entry.frame and entry.frame.usesInnerScrollBar
        enabled = range > 0 and not innerScroller and not InCombatLockdown()
        slider:SetEnabled(enabled)
        slider:SetShown(not innerScroller)
        if not enabled then pressed = false end
        UpdateAppearance()
        updating = false
    end

    -- Geometry/page changes keep the actual offset but drop obsolete wheel targets.
    local function ReconcileScrollbar()
        StopWheelMotion()
        RefreshScrollbar()
    end

    -- One bounded update handler interpolates wheel intent, never native dragging.
    local function AdvanceWheelMotion(_, elapsed)
        if not targetOffset or InCombatLockdown() then ReconcileScrollbar(); return end
        local range = math.max(0, scrollFrame:GetVerticalScrollRange())
        targetOffset = math.max(0, math.min(targetOffset, range))
        wheelElapsed = math.min(S.wheelDuration, wheelElapsed + elapsed)
        local progress = wheelElapsed / S.wheelDuration
        local eased = 1 - (1 - progress) ^ 3
        local offset = math.max(0, math.min(startOffset + (targetOffset - startOffset) * eased, range))
        if scrollFrame:GetVerticalScroll() ~= offset then
            smoothWrite = true
            scrollFrame:SetVerticalScroll(offset)
            smoothWrite = false
        end
        if progress >= 1 then StopWheelMotion() end
    end

    local immediateWheel = scrollFrame:GetScript("OnMouseWheel")
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        if InCombatLockdown() or pressed or not slider:IsShown() then
            StopWheelMotion()
            if immediateWheel then immediateWheel(self, delta) end
            return
        end
        local range = math.max(0, self:GetVerticalScrollRange())
        local current = self:GetVerticalScroll()
        local step = delta < 0 and S.scrollStep or -S.scrollStep
        local target = math.max(0, math.min((targetOffset or current) + step, range))
        if target == current then StopWheelMotion(); return end
        targetOffset, startOffset, wheelElapsed = target, current, 0
        if not slider:GetScript("OnUpdate") then slider:SetScript("OnUpdate", AdvanceWheelMotion) end
    end)

    slider:SetScript("OnValueChanged", function(_, value)
        if updating or not enabled then return end
        if InCombatLockdown() then RefreshScrollbar(); return end
        StopWheelMotion()
        local range = math.max(0, scrollFrame:GetVerticalScrollRange())
        local offset = math.max(0, math.min(value, range))
        if scrollFrame:GetVerticalScroll() ~= offset then scrollFrame:SetVerticalScroll(offset) end
    end)
    slider:SetScript("OnMouseWheel", function(_, delta)
        local handler = scrollFrame:GetScript("OnMouseWheel")
        if handler then handler(scrollFrame, delta) end
    end)
    slider:SetScript("OnEnter", function() hovered = true; UpdateAppearance() end)
    slider:SetScript("OnLeave", function() hovered = false; UpdateAppearance() end)
    slider:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and enabled then
            StopWheelMotion()
            pressed = true
            UpdateAppearance()
        end
    end)
    slider:SetScript("OnMouseUp", function() pressed = false; UpdateAppearance() end)
    slider:SetScript("OnHide", function()
        StopWheelMotion()
        hovered = false
        pressed = false
        UpdateAppearance()
    end)
    slider:SetScript("OnSizeChanged", ReconcileScrollbar)
    scrollFrame:HookScript("OnVerticalScroll", function()
        if not smoothWrite then StopWheelMotion() end
        RefreshScrollbar()
    end)
    scrollFrame:HookScript("OnScrollRangeChanged", ReconcileScrollbar)
    scrollFrame:HookScript("OnSizeChanged", ReconcileScrollbar)
    frame:HookScript("OnSizeChanged", ReconcileScrollbar)
    frame:HookScript("OnShow", ReconcileScrollbar)
    frame:HookScript("OnHide", StopWheelMotion)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", ReconcileScrollbar)
    RefreshScrollbar()
    return ReconcileScrollbar
end

-- ---------------------------------------------------------------------------
-- Content panel + scroll frame
-- ---------------------------------------------------------------------------

local function BuildContentPanel(frame, navPanel, helpPanel)
    local F = T.Frame
    local S = T.Scroll
    local col = T.Colors

    -- Content panel sits between nav and help panels
    local contentPanel = CreateFrame("Frame", nil, frame)
    contentPanel:SetPoint("TOPLEFT",     navPanel,  "TOPRIGHT",    F.panelGap,  0)
    contentPanel:SetPoint("TOPRIGHT",    helpPanel, "TOPLEFT",    -F.panelGap,  0)
    contentPanel:SetPoint("BOTTOMLEFT",  navPanel,  "BOTTOMRIGHT", F.panelGap,  0)
    contentPanel:SetPoint("BOTTOMRIGHT", helpPanel, "BOTTOMLEFT", -F.panelGap,  0)

    -- Scroll frame fills content panel minus space for scrollbar on the right
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentPanel)
    scrollFrame:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -(S.trackW + S.contentGap), 0)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current   = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step      = S.scrollStep
        if delta < 0 then
            self:SetVerticalScroll(math.min(current + step, maxScroll))
        else
            self:SetVerticalScroll(math.max(current - step, 0))
        end
    end)

    -- Scroll child — pages are parented here
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(contentPanel:GetWidth(), 700)
    scrollFrame:SetScrollChild(scrollChild)

    return contentPanel, scrollFrame, scrollChild
end

-- ---------------------------------------------------------------------------
-- Help panel
-- ---------------------------------------------------------------------------

local function BuildHelpPanel(frame)
    local F = T.Frame
    local col = T.Colors

    local helpPanel = CreateFrame("Frame", nil, frame)
    helpPanel:SetWidth(F.helpWidth)
    helpPanel:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -F.cornerSize + F.sideWidth + 28, -F.headerHeight)
    helpPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -F.cornerSize + F.sideWidth + 28,  F.footerHeight)

    -- Background tint
    local helpBg = helpPanel:CreateTexture(nil, "BACKGROUND")
    helpBg:SetColorTexture(col.helpBg[1], col.helpBg[2], col.helpBg[3], col.helpBg[4])
    helpBg:SetAllPoints()

    -- Optional page-specific content lives below the persistent Help area.
    local sidebarContainer = CreateFrame("Frame", nil, helpPanel)
    sidebarContainer:SetPoint("TOPLEFT", helpPanel, "TOPLEFT", 0, -84)
    sidebarContainer:SetPoint("BOTTOMRIGHT", helpPanel, "BOTTOMRIGHT", 0, 0)

    C.sidebarContainer = sidebarContainer

    -- Help panel title
    local helpTitle = helpPanel:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    helpTitle:SetPoint("TOPLEFT", helpPanel, "TOPLEFT", 8, -8)
    helpTitle:SetText("Help")
    helpTitle:SetTextColor(col.accent[1], col.accent[2], col.accent[3], 1)

    -- Help text body — updated on setting hover
    local helpText = helpPanel:CreateFontString(nil, "OVERLAY", T.Fonts.dimmed)
    helpText:SetPoint("TOPLEFT",  helpPanel, "TOPLEFT",  8, -24)
    helpText:SetPoint("TOPRIGHT", helpPanel, "TOPRIGHT", -8, -24)
    helpText:SetPoint("BOTTOMRIGHT", sidebarContainer, "TOPRIGHT", -8, 8)
    helpText:SetJustifyH("LEFT")
    helpText:SetJustifyV("TOP")
    helpText:SetWordWrap(true)
    helpText:SetText("Hover a setting to see its description here.")
    helpText:SetTextColor(col.textDim[1], col.textDim[2], col.textDim[3], 1)

    -- Expose setter for page files to push description text
    function C.SetHelpText(text)
        helpText:SetText(text or "")
    end

    function C.ClearHelpText()
        helpText:SetText("Hover a setting to see its description here.")
    end

    return helpPanel
end

-- ---------------------------------------------------------------------------
-- Resize handles (right edge, bottom edge, corner)
-- ---------------------------------------------------------------------------

local function BuildResizeHandles(frame)
    local resizeFrameLevel = frame:GetFrameLevel() + 10

    local function StartResize(direction)
        if C.locked or not frame:IsShown() then return end

        local left = frame:GetLeft()
        local top = frame:GetTop()
        if left and top then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end

        frame:StopMovingOrSizing()
        frame:StartSizing(direction)
    end

    -- Right edge
    local resizeRight = CreateFrame("Button", nil, frame)
    resizeRight:SetFrameLevel(resizeFrameLevel)
    resizeRight:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    0, -90)
    resizeRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0,  90)
    resizeRight:SetWidth(12)
    resizeRight:SetScript("OnMouseDown", function() StartResize("RIGHT") end)
    resizeRight:SetScript("OnMouseUp",   function() frame:StopMovingOrSizing() end)

    -- Bottom edge
    local resizeBottom = CreateFrame("Button", nil, frame)
    resizeBottom:SetFrameLevel(resizeFrameLevel)
    resizeBottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  90, 0)
    resizeBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -90, 0)
    resizeBottom:SetHeight(12)
    resizeBottom:SetScript("OnMouseDown", function() StartResize("BOTTOM") end)
    resizeBottom:SetScript("OnMouseUp",   function() frame:StopMovingOrSizing() end)

    -- Bottom-right corner
    local resizeCorner = CreateFrame("Button", nil, frame)
    resizeCorner:SetFrameLevel(resizeFrameLevel)
    resizeCorner:SetSize(20, 20)
    resizeCorner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    resizeCorner:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeCorner:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeCorner:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeCorner:SetScript("OnMouseDown", function() StartResize("BOTTOMRIGHT") end)
    resizeCorner:SetScript("OnMouseUp",   function() frame:StopMovingOrSizing() end)
end

-- ---------------------------------------------------------------------------
-- Main frame constructor
-- ---------------------------------------------------------------------------

local function CreateConfig2Frame()
    if C.frame then return C.frame end

    local F = T.Frame
    local col = T.Colors

    -- Main frame
    local frame = CreateFrame("Frame", "OUS2ConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(F.defaultW, F.defaultH)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetResizable(true)
    frame:SetResizeBounds(F.minW, F.minH, F.maxW, F.maxH)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    tinsert(UISpecialFrames, "OUS2ConfigFrame")

    C.frame = frame

    -- Build frame border (NineSlice)
    BuildFrameBorder(frame)

    -- Build help panel first — nav and content anchor to it
    local helpPanel = BuildHelpPanel(frame)

    -- Left nav panel
    local navPanel = CreateFrame("Frame", nil, frame)
    navPanel:SetWidth(F.navWidth)
    navPanel:SetPoint("TOPLEFT",    frame, "TOPLEFT",    F.cornerSize - F.sideWidth - 26, -F.headerHeight)
    navPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", F.cornerSize - F.sideWidth - 26,  F.footerHeight)

    -- Content + scroll
    local contentPanel, scrollFrame, scrollChild = BuildContentPanel(frame, navPanel, helpPanel)

    -- Nav buttons
    BuildNavPanel(navPanel)

    -- Header and footer
    BuildHeader(frame, navPanel)
    local footerButton, footerExtent = BuildFooter(frame)
    RefreshSharedScrollbar = BuildScrollbar(frame, contentPanel, scrollFrame, footerButton, footerExtent)

    -- Compose with scrollbar events and ordinary page cleanup; never queue a combat reopen.
    frame:HookScript("OnHide", function(self)
        self:StopMovingOrSizing()
        CloseOwnedEditors()
    end)
    frame:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if self:IsShown() then self:Hide() else CloseOwnedEditors() end
        end
    end)

    -- Resize handles
    BuildResizeHandles(frame)

    -- Expose scroll child as the page container
    C.pageContainer = scrollChild

    -- Open to General page by default
    SwitchPage("General")

    return frame
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Reconcile the outer Slider when a page switches between settings and native inner scrolling.
function C.RefreshScrollbar()
    if RefreshSharedScrollbar then RefreshSharedScrollbar() end
end

-- Register optional retained-page refresh separately when normal entry also changes navigation.
-- usage: OUS.Config2.RegisterPage(name, frame, refreshFn, sidebarFrame, refreshCurrentFn)
function C.RegisterPage(pageName, pageFrame, refreshFn, sidebarFrame, refreshCurrentFn)
    if not C.pages[pageName] then
        C.pages[pageName] = {}
    end
    C.pages[pageName].frame        = pageFrame
    C.pages[pageName].Refresh      = refreshFn
    C.pages[pageName].RefreshCurrent = refreshCurrentFn or refreshFn
    C.pages[pageName].sidebarFrame = sidebarFrame

    -- If this is the current page, show it immediately
    if C.currentPage == pageName then
        if pageFrame then pageFrame:Show() end
        if sidebarFrame then sidebarFrame:Show() end
        if refreshFn then refreshFn() end
    else
        if pageFrame then pageFrame:Hide() end
        if sidebarFrame then sidebarFrame:Hide() end
    end
end

-- Open config to a specific page (called from Toolbox or slash commands)
function C.OpenPage(pageName)
    if InCombatLockdown() then
        if C.frame and C.frame:IsShown() then C.frame:Hide() end
        return false
    end
    local frame = CreateConfig2Frame()
    frame:Show()
    SwitchPage(pageName)
end

-- Toggle the config window
function C.Toggle()
    if C.frame and C.frame:IsShown() then
        C.frame:Hide()
        return
    end
    if InCombatLockdown() then return false end
    local frame = CreateConfig2Frame()
    frame:Show()
    RefreshCurrentPage()
end

-- Page files load after this file and require a valid parent immediately.
CreateConfig2Frame()

-- ---------------------------------------------------------------------------
-- Slash command
-- ---------------------------------------------------------------------------

SLASH_OUS2CONFIG1 = "/ous2"
SlashCmdList["OUS2CONFIG"] = function(msg)
    local arg = strtrim(msg or "")
    if arg ~= "" and C.pages[arg] then
        C.OpenPage(arg)
    else
        C.Toggle()
    end
end
