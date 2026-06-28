-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Toolbox.lua
-- Version : 2026.06.22
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
        db.locked = newValue
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
        button:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -408)
        button:SetPoint("TOPRIGHT", page, "TOP", -5, -408)
    else
        button:SetPoint("TOPLEFT", page, "TOP", 5, -408)
        button:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -408)
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
        local db = GetToolboxDB()
        if not db then return end

        db.direction = direction
        if OUS.RefreshToolbox then
            OUS.RefreshToolbox()
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
    "Shows the Toolbox master-module state without changing it.",
    -104,
    48
)
statusText = statusBody

disabledNote = CreateInfoCard(
    "Toolbox was disabled at login. Re-enable from the legacy General module toggle and reload UI until OUS2 live initialization is added.",
    "Toolbox currently creates its frame only when enabled during addon initialization.",
    -156,
    70,
    T.Fonts.small,
    T.Colors.textDim
)

CreateSectionHeader("Visibility and Position", -250)
CreateActionButton(
    "Show / Hide Toolbox",
    "Show or hide the initialized Toolbox frame.",
    -276,
    function()
        if OUS.ToggleToolbox then
            OUS.ToggleToolbox()
        end
    end
)
lockCheckbox = CreateLockRow(-318)

CreateSectionHeader("Layout", -382)
horizontalButton = CreateDirectionButton("Horizontal", "horizontal", true)
verticalButton = CreateDirectionButton("Vertical", "vertical", false)

CreateSectionHeader("Future Settings", -472)
CreateInfoCard(
    "Scale, position reset, button visibility, and popup customization require dedicated OUS2 controls and safe public setters.",
    "Additional Toolbox controls remain deferred until their public update paths are established.",
    -498,
    70,
    T.Fonts.small,
    T.Colors.textDim
)

Refresh = function()
    local modules = GetModulesDB()
    local enabled = modules and modules.toolbox == true
    statusText:SetText("Toolbox Status: " .. (enabled and "Enabled" or "Disabled"))
    SetTextColor(statusText, enabled and T.Colors.enabled or T.Colors.disabled)

    if enabled then
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
end

C.RegisterPage("Toolbox", page, Refresh)
