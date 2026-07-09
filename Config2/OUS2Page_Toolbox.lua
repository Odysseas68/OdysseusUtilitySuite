-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Toolbox.lua
-- Version : 2026.07.09
-- Desc    : OUS2 Toolbox module settings page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local statusText
local disabledNote
local lockCheckbox
local horizontalButton
local verticalButton
local scaleControl
local Refresh

local function SetTextColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4])
end

local function CreateSectionHeader(text, yOffset)
    local star = page:CreateTexture(nil, "ARTWORK")
    star:SetTexture(T.Tex("SectionStar"))
    star:SetSize(14, 14)
    star:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)

    local label = page:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
    label:SetPoint("LEFT", star, "RIGHT", 6, 0)
    label:SetText(text)
    SetTextColor(label, T.Colors.header)

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(T.Tex("Divider"))
    divider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    divider:SetPoint("RIGHT", page, "RIGHT", -18, 0)
    divider:SetHeight(4)
end

local function GetModulesDB()
    return OdysseusDB and OdysseusDB.modules
end

local function GetToolboxDB()
    return OdysseusDB and OdysseusDB.toolbox
end

local function CreateInfoCard(text, helpText, yOffset, height, fontObject, color)
    local card = CreateFrame("Frame", nil, page)
    card:SetHeight(height)
    card:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    card:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    card:EnableMouse(true)

    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local body = card:CreateFontString(nil, "OVERLAY", fontObject or T.Fonts.normal)
    body:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -T.Card.Padding)
    body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -T.Card.Padding, T.Card.Padding)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("MIDDLE")
    body:SetWordWrap(true)
    body:SetText(text)
    SetTextColor(body, color or T.Colors.text)

    card:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    card:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)

    return card, body
end

local function CreateActionButton(labelText, helpText, yOffset, onClick)
    local button = CreateFrame("Button", nil, page)
    button:SetHeight(36)
    button:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    button:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    button:SetNormalTexture(T.Tex("ActionNormal"))
    button:SetHighlightTexture(T.Tex("ActionHover"))
    button:SetPushedTexture(T.Tex("ActionPressed"))

    local label = button:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("CENTER")
    label:SetText(labelText)
    SetTextColor(label, T.Colors.text)

    button:SetScript("OnEnter", function()
        C.SetHelpText(helpText)
    end)
    button:SetScript("OnLeave", function()
        C.ClearHelpText()
    end)
    button:SetScript("OnClick", onClick)
end

local function CreateLockRow(yOffset)
    local helpText = "Lock the Toolbox in place or unlock its existing drag handle."

    local row = CreateFrame("Button", nil, page)
    row:SetHeight(44)
    row:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local checkbox = row:CreateTexture(nil, "ARTWORK")
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", row, "LEFT", T.Card.Padding, 0)

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("LEFT", checkbox, "RIGHT", 7, 0)
    label:SetText("Lock Toolbox Position")
    SetTextColor(label, T.Colors.text)

    row:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    row:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
    row:SetScript("OnClick", function()
        local db = GetToolboxDB()
        if not db then return end

        local newValue = not db.locked
        if OUS.LockToolbox then
            OUS.LockToolbox(newValue)
        end
        Refresh()
    end)

    return checkbox
end

local function CreateDirectionButton(labelText, direction, leftSide)
    local button = CreateFrame("Button", nil, page)
    button:SetHeight(44)

    if leftSide then
        button:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -428)
        button:SetPoint("TOPRIGHT", page, "TOP", -5, -428)
    else
        button:SetPoint("TOPLEFT", page, "TOP", 5, -428)
        button:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -428)
    end

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = button:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("CENTER")
    label:SetText(labelText)
    SetTextColor(label, T.Colors.text)

    button.background = background
    button.label = label
    button.selected = false

    button:SetScript("OnEnter", function(self)
        if not self.selected then
            background:SetTexture(T.Tex("CardHover"))
        end
        C.SetHelpText("Set the Toolbox button layout to " .. string.lower(labelText) .. ".")
    end)
    button:SetScript("OnLeave", function(self)
        background:SetTexture(T.Tex(self.selected and "CardSelected" or "CardNormal"))
        C.ClearHelpText()
    end)
    button:SetScript("OnClick", function()
        if OUS.SetToolboxDirection then
            OUS.SetToolboxDirection(direction)
        end
        Refresh()
    end)

    return button
end

local function UpdateDirectionButton(button, selected)
    button.selected = selected
    button.background:SetTexture(T.Tex(selected and "CardSelected" or "CardNormal"))
    SetTextColor(button.label, selected and T.Colors.accent or T.Colors.text)
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconToolbox"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Toolbox")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Floating quick-access task bar")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Status", -78)
local _, statusBody = CreateInfoCard(
    "",
    "Shows the Toolbox module and runtime initialization state without changing it.",
    -104,
    64
)
statusText = statusBody

disabledNote = CreateInfoCard(
    "Toolbox was disabled during login. Enable the module and reload UI before the Toolbox frame can be created.",
    "Toolbox currently creates its runtime frame only during addon initialization.",
    -176,
    70,
    T.Fonts.small,
    T.Colors.textDim
)

CreateSectionHeader("Visibility and Position", -270)
CreateActionButton(
    "Show / Hide Toolbox",
    "Show or hide the initialized Toolbox frame.",
    -296,
    function()
        if OUS.ToggleToolbox then
            OUS.ToggleToolbox()
        end
    end
)
lockCheckbox = CreateLockRow(-338)

CreateSectionHeader("Layout", -402)
horizontalButton = CreateDirectionButton("Horizontal", "horizontal", true)
verticalButton = CreateDirectionButton("Vertical", "vertical", false)

CreateSectionHeader("Scale", -492)
local scaleRow = CreateFrame("Frame", nil, page)
scaleRow:SetHeight(60)
scaleRow:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -518)
scaleRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -518)
scaleRow:EnableMouse(true)

local scaleBackground = scaleRow:CreateTexture(nil, "BACKGROUND")
scaleBackground:SetTexture(T.Tex("CardNormal"))
scaleBackground:SetAllPoints()

local scaleLabel = scaleRow:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
scaleLabel:SetPoint("LEFT", scaleRow, "LEFT", T.Card.Padding, 0)
scaleLabel:SetText("Toolbox Scale")
SetTextColor(scaleLabel, T.Colors.text)

scaleControl = C.CreateScaleControl(
    scaleRow,
    0.5,
    2.0,
    0.1,
    1.0,
    function(newValue)
        if OUS.SetToolboxScale then
            OUS.SetToolboxScale(newValue)
        end
    end
)
scaleControl:SetPoint("RIGHT", scaleRow, "RIGHT", -T.Card.Padding, 0)

scaleRow:SetScript("OnEnter", function()
    scaleBackground:SetTexture(T.Tex("CardHover"))
    C.SetHelpText("Adjust the displayed size of the Toolbox buttons.")
end)
scaleRow:SetScript("OnLeave", function()
    scaleBackground:SetTexture(T.Tex("CardNormal"))
    C.ClearHelpText()
end)

CreateActionButton(
    "Reset Position",
    "Reset the Toolbox to its default saved screen position.",
    -592,
    function()
        if OUS.ResetToolboxPosition then
            OUS.ResetToolboxPosition()
        end
        Refresh()
    end
)

Refresh = function()
    local modules = GetModulesDB()
    local enabled = modules and modules.toolbox == true
    local initialized = OUS.IsToolboxInitialized and OUS.IsToolboxInitialized()
    statusText:SetText("Module: " .. (enabled and "Enabled" or "Disabled") .. "\nRuntime: " .. (initialized and "Initialized" or "Disabled until reload"))
    SetTextColor(statusText, initialized and T.Colors.enabled or T.Colors.disabled)

    if initialized then
        disabledNote:Hide()
    else
        disabledNote:Show()
    end

    local db = GetToolboxDB()
    local locked = db and db.locked == true
    lockCheckbox:SetTexture(T.Tex(locked and "CheckboxOn" or "CheckboxOff"))

    local direction = db and db.direction or "horizontal"
    UpdateDirectionButton(horizontalButton, direction == "horizontal")
    UpdateDirectionButton(verticalButton, direction == "vertical")

    local scale = db and tonumber(db.scale) or 1.0
    scaleControl:SetValue(scale, true)
end

C.RegisterPage("Toolbox", page, Refresh)
