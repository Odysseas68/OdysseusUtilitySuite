-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_FlightMaster.lua
-- Version : 2026.06.22
-- Desc    : OUS2 Flight Master display settings page
-- ================================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local tooltipCheckbox
local widthControl
local heightControl
local scaleControl
local fontSizeControl
local borderSizeControl
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

local function GetFlightSettings()
    return OdysseusDB and OdysseusDB.flightSettings
end

local function CreateCheckboxRow(labelText, helpText, yOffset, dbKey)
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
    label:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
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
        local db = GetFlightSettings()
        if not db then return end

        db[dbKey] = not db[dbKey]
        Refresh()
    end)

    return checkbox
end

local function AttachControlHelp(frame, background, helpText)
    frame:HookScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    frame:HookScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
end

local function CreateScaleRow(labelText, helpText, yOffset, minValue, maxValue, step, initialValue, onChanged)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(60)
    row:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("LEFT", row, "LEFT", T.Card.Padding, 0)
    label:SetText(labelText)
    SetTextColor(label, T.Colors.text)

    local control = C.CreateScaleControl(
        row,
        minValue,
        maxValue,
        step,
        initialValue,
        onChanged
    )
    control:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(control, background, helpText)
    AttachControlHelp(control.leftButton, background, helpText)
    AttachControlHelp(control.rightButton, background, helpText)
    AttachControlHelp(control.slider, background, helpText)
    AttachControlHelp(control.editBox, background, helpText)

    return control
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconFlightMaster"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Flight Master")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Flight timer bar display settings")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Display", -78)
tooltipCheckbox = CreateCheckboxRow(
    "Show Map Tooltips",
    "Show flight time, cost, and distance details while viewing taxi destinations.",
    -104,
    "showTooltips"
)

CreateSectionHeader("Timer Bar", -164)
widthControl = CreateScaleRow(
    "Bar Width",
    "Adjust the width of the Flight Master timer bar.",
    -190,
    50,
    600,
    10,
    200,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.width = newValue
        if OUS.timerBar then
            OUS.timerBar:SetWidth(newValue)
        end
    end
)

heightControl = CreateScaleRow(
    "Bar Height",
    "Adjust the height of the Flight Master timer bar.",
    -254,
    5,
    100,
    1,
    20,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.height = newValue
        if OUS.timerBar then
            OUS.timerBar:SetHeight(newValue)
        end
    end
)

scaleControl = CreateScaleRow(
    "Bar Scale",
    "Adjust the overall scale of the Flight Master timer bar.",
    -318,
    0.5,
    3.0,
    0.05,
    1.0,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.scale = newValue
        if OUS.timerBar then
            OUS.timerBar:SetScale(newValue)
        end
    end
)

CreateSectionHeader("Text and Border", -398)
fontSizeControl = CreateScaleRow(
    "Font Size",
    "Adjust the text size used by the Flight Master timer bar.",
    -424,
    6,
    40,
    1,
    12,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.fontSize = newValue
        if OUS.ApplyFlightFonts then
            OUS.ApplyFlightFonts()
        end
    end
)

borderSizeControl = CreateScaleRow(
    "Border Size",
    "Adjust the thickness of the selected Flight Master border.",
    -488,
    0,
    50,
    1,
    16,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.borderSize = newValue
        if OUS.ApplyFlightBorder then
            OUS.ApplyFlightBorder()
        end
    end
)

Refresh = function()
    local db = GetFlightSettings()
    local checked = db and db.showTooltips == true
    tooltipCheckbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))

    widthControl:SetValue(db and db.width or 200, true)
    heightControl:SetValue(db and db.height or 20, true)
    scaleControl:SetValue(db and db.scale or 1.0, true)
    fontSizeControl:SetValue(db and db.fontSize or 12, true)
    borderSizeControl:SetValue(db and db.borderSize or 16, true)
end

C.RegisterPage("FlightMaster", page, Refresh)
