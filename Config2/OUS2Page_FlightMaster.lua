-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_FlightMaster.lua
-- Version : 2026.06.25
-- Desc    : OUS2 Flight Master display settings page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local tooltipCheckbox
local unlockCheckbox
local widthControl
local heightControl
local scaleControl
local fontSizeControl
local borderSizeControl
local textureButton
local fontButton
local borderButton
local barColorButton
local borderColorButton
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

local function AttachRowHelp(row, background, helpText)
    row:HookScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    row:HookScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
end

local function CreateCheckboxRow(labelText, helpText, yOffset, onClick)
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

    AttachRowHelp(row, background, helpText)
    row:SetScript("OnClick", onClick)

    return checkbox
end

local function CreateActionRow(labelText, buttonText, helpText, yOffset, onClick)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(52)
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

    local button = CreateFrame("Button", nil, row)
    button:SetSize(150, 28)
    button:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)

    button.normal = button:CreateTexture(nil, "BACKGROUND")
    button.normal:SetTexture(T.Tex("ActionButtonNormal"))
    button.normal:SetAllPoints()

    button.label = button:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    button.label:SetPoint("CENTER")
    button.label:SetText(buttonText)
    SetTextColor(button.label, T.Colors.text)

    button:SetScript("OnEnter", function()
        button.normal:SetTexture(T.Tex("ActionButtonHover"))
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    button:SetScript("OnLeave", function()
        button.normal:SetTexture(T.Tex("ActionButtonNormal"))
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
    button:SetScript("OnMouseDown", function()
        button.normal:SetTexture(T.Tex("ActionButtonPressed"))
    end)
    button:SetScript("OnMouseUp", function()
        button.normal:SetTexture(T.Tex("ActionButtonHover"))
    end)
    button:SetScript("OnClick", onClick)

    AttachRowHelp(row, background, helpText)

    return button
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


local function ShortenName(name)
    name = tostring(name or "")
    if #name > 24 then
        return string.sub(name, 1, 21) .. "..."
    end
    return name
end

local function CreateMediaRow(labelText, helpText, yOffset, mediaType, dbKey, applyFunc)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(52)
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

    local button = CreateFrame("Button", nil, row)
    button:SetSize(190, 28)
    button:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    button:SetNormalTexture(T.Tex("ActionButtonNormal"))
    button:SetHighlightTexture(T.Tex("ActionButtonHover"))
    button:SetPushedTexture(T.Tex("ActionButtonPressed"))

    button.label = button:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    button.label:SetAllPoints()
    button.label:SetText("")
    SetTextColor(button.label, T.Colors.text)

    button:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    button:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
    button:SetScript("OnClick", function()
        local db = GetFlightSettings()
        if not db or not C.OpenMediaDropdown then return end

        C.OpenMediaDropdown(button, mediaType, db[dbKey], function(name)
            db[dbKey] = name
            button.label:SetText(ShortenName(name))
            if applyFunc then
                applyFunc()
            elseif OUS.ApplyFlightSettings then
                OUS.ApplyFlightSettings()
            end
        end)
    end)

    AttachRowHelp(row, background, helpText)

    function button:SetSelectedName(name)
        button.label:SetText(ShortenName(name))
    end

    return button
end

local function CreateColorRow(labelText, helpText, yOffset, dbKey, defaultColor, onChanged)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(52)
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

    local button = CreateFrame("Button", nil, row)
    button:SetSize(82, 28)
    button:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetTexture(T.Tex("ActionButtonNormal"))
    button.bg:SetAllPoints()

    button.swatch = button:CreateTexture(nil, "ARTWORK")
    button.swatch:SetSize(42, 16)
    button.swatch:SetPoint("CENTER")

    button:SetScript("OnEnter", function()
        button.bg:SetTexture(T.Tex("ActionButtonHover"))
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    button:SetScript("OnLeave", function()
        button.bg:SetTexture(T.Tex("ActionButtonNormal"))
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
    button:SetScript("OnMouseDown", function()
        button.bg:SetTexture(T.Tex("ActionButtonPressed"))
    end)
    button:SetScript("OnMouseUp", function()
        button.bg:SetTexture(T.Tex("ActionButtonHover"))
    end)
    button:SetScript("OnClick", function()
        local db = GetFlightSettings()
        if not db or not C.OpenColorPicker then return end

        db[dbKey] = db[dbKey] or {
            r = defaultColor.r,
            g = defaultColor.g,
            b = defaultColor.b,
        }

        C.OpenColorPicker(db[dbKey], button.swatch, function(r, g, b)
            if onChanged then
                onChanged(r, g, b)
            elseif OUS.ApplyFlightSettings then
                OUS.ApplyFlightSettings()
            end
        end)
    end)

    AttachRowHelp(row, background, helpText)

    function button:SetColor(color)
        color = color or defaultColor
        button.swatch:SetColorTexture(color.r or defaultColor.r, color.g or defaultColor.g, color.b or defaultColor.b, 1)
    end

    return button
end

local function EscapeLuaString(text)
    return tostring(text):gsub("\\", "\\\\"):gsub("\"", "\\\"")
end

local function BuildFlightExportText()
    local flightSettings = OdysseusDB and OdysseusDB.flightSettings
    local times = flightSettings and flightSettings.times
    local output = "-- Exported on " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    local hasData = false

    if type(times) == "table" then
        local startNodes = {}
        for startNode, dests in pairs(times) do
            if type(dests) == "table" then
                table.insert(startNodes, startNode)
            end
        end
        table.sort(startNodes)

        for _, startNode in ipairs(startNodes) do
            local dests = times[startNode]
            local destNodes = {}

            for destNode, duration in pairs(dests) do
                if type(duration) == "number" then
                    table.insert(destNodes, destNode)
                end
            end

            if #destNodes > 0 then
                table.sort(destNodes)
                output = output .. "    [\"" .. EscapeLuaString(startNode) .. "\"] = {\n"

                for _, destNode in ipairs(destNodes) do
                    output = output .. "        [\"" .. EscapeLuaString(destNode) .. "\"] = " .. dests[destNode] .. ",\n"
                    hasData = true
                end

                output = output .. "    },\n"
            end
        end
    end

    if not hasData then
        return "-- No new flights to export yet.\n-- Your flight database is empty."
    end

    return output
end

StaticPopupDialogs["OUS2_CONFIRM_WIPE_FLIGHT_TIMES"] = StaticPopupDialogs["OUS2_CONFIRM_WIPE_FLIGHT_TIMES"] or {
    text = "Are you sure you want to wipe ALL recorded Flight Master times? This cannot be undone.",
    button1 = "Yes, Wipe",
    button2 = "Cancel",
    OnAccept = function()
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
        OdysseusDB.flightSettings.times = {}
        print("|cFF00CCFFOdysseus:|r All recorded flight times |cFFFF0000wiped|r!")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


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
    function()
        local db = GetFlightSettings()
        if not db then return end

        db.showTooltips = not db.showTooltips
        Refresh()
    end
)

unlockCheckbox = CreateCheckboxRow(
    "Unlock Timer Bar",
    "Show the timer bar preview and allow it to be dragged. Lock it again when finished.",
    -152,
    function()
        if OUS.SetFlightBarUnlocked then
            OUS.SetFlightBarUnlocked(not OUS.isFlightBarUnlocked)
        end
        Refresh()
    end
)

CreateSectionHeader("Timer Bar", -212)
widthControl = CreateScaleRow(
    "Bar Width",
    "Adjust the width of the Flight Master timer bar.",
    -238,
    50,
    600,
    10,
    200,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.width = newValue
        if OUS.ApplyFlightSettings then
            OUS.ApplyFlightSettings()
        elseif OUS.timerBar then
            OUS.timerBar:SetWidth(newValue)
        end
    end
)

heightControl = CreateScaleRow(
    "Bar Height",
    "Adjust the height of the Flight Master timer bar.",
    -302,
    5,
    100,
    1,
    20,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.height = newValue
        if OUS.ApplyFlightSettings then
            OUS.ApplyFlightSettings()
        elseif OUS.timerBar then
            OUS.timerBar:SetHeight(newValue)
        end
    end
)

scaleControl = CreateScaleRow(
    "Bar Scale",
    "Adjust the overall scale of the Flight Master timer bar.",
    -366,
    0.5,
    3.0,
    0.05,
    1.0,
    function(newValue)
        local db = GetFlightSettings()
        if not db then return end

        db.scale = newValue
        if OUS.ApplyFlightSettings then
            OUS.ApplyFlightSettings()
        end
    end
)

CreateSectionHeader("Text and Border", -446)
fontSizeControl = CreateScaleRow(
    "Font Size",
    "Adjust the text size used by the Flight Master timer bar.",
    -472,
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
    -536,
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

CreateSectionHeader("Appearance", -616)
textureButton = CreateMediaRow(
    "Bar Texture",
    "Choose the LibSharedMedia statusbar texture used by the timer bar fill.",
    -642,
    "statusbar",
    "textureName",
    function()
        if OUS.ApplyFlightTexture then
            OUS.ApplyFlightTexture()
        end
    end
)

fontButton = CreateMediaRow(
    "Bar Font",
    "Choose the LibSharedMedia font used by the Flight Master timer text.",
    -698,
    "font",
    "fontName",
    function()
        if OUS.ApplyFlightFonts then
            OUS.ApplyFlightFonts()
        end
    end
)

borderButton = CreateMediaRow(
    "Bar Border",
    "Choose the LibSharedMedia border artwork used around the timer bar.",
    -754,
    "border",
    "borderName",
    function()
        if OUS.ApplyFlightBorder then
            OUS.ApplyFlightBorder()
        end
    end
)

CreateSectionHeader("Colors", -834)
barColorButton = CreateColorRow(
    "Bar Color",
    "Choose the fill color used by the Flight Master timer bar.",
    -860,
    "color",
    OUS.flightDefaults and OUS.flightDefaults.color or { r = 1, g = 0.7, b = 0 },
    function(r, g, b)
        if OUS.SetFlightBarColor then
            OUS.SetFlightBarColor(r, g, b)
        end
    end
)

borderColorButton = CreateColorRow(
    "Border Color",
    "Choose the border color used by the selected Flight Master border.",
    -916,
    "borderColor",
    { r = 1, g = 1, b = 1 },
    function(r, g, b)
        if OUS.SetFlightBorderColor then
            OUS.SetFlightBorderColor(r, g, b)
        elseif OUS.ApplyFlightBorder then
            OUS.ApplyFlightBorder()
        end
    end
)

CreateSectionHeader("Data", -996)
CreateActionRow(
    "Export Flight Data",
    "Export",
    "Open a copy window with recorded flight times for manual export.",
    -1022,
    function()
        if C.ShowCopyTextDialog then
            C.ShowCopyTextDialog("Export Flight Data", BuildFlightExportText())
        end
    end
)

CreateActionRow(
    "Wipe Saved Data",
    "Wipe Data",
    "Delete all recorded Flight Master learned times. Appearance settings are preserved.",
    -1078,
    function()
        StaticPopup_Show("OUS2_CONFIRM_WIPE_FLIGHT_TIMES")
    end
)

CreateSectionHeader("Advanced", -1158)
CreateActionRow(
    "Reset Bar Position",
    "Reset Position",
    "Move the timer bar back to its default top-center position.",
    -1184,
    function()
        if OUS.ResetFlightBarPosition then
            OUS.ResetFlightBarPosition()
        end
        Refresh()
    end
)

CreateActionRow(
    "Reset Appearance",
    "Reset Style",
    "Reset Flight Master bar size, scale, font, texture, color, and border settings. Learned flight times are preserved.",
    -1240,
    function()
        if OUS.ResetFlightBarAppearance then
            OUS.ResetFlightBarAppearance()
        end
        Refresh()
    end
)

Refresh = function()
    local db = GetFlightSettings()
    local tooltipsChecked = db and db.showTooltips == true
    local unlockedChecked = OUS.isFlightBarUnlocked == true

    tooltipCheckbox:SetTexture(T.Tex(tooltipsChecked and "CheckboxOn" or "CheckboxOff"))
    unlockCheckbox:SetTexture(T.Tex(unlockedChecked and "CheckboxOn" or "CheckboxOff"))

    widthControl:SetValue(db and db.width or 200, true)
    heightControl:SetValue(db and db.height or 20, true)
    scaleControl:SetValue(db and db.scale or 1.0, true)
    fontSizeControl:SetValue(db and db.fontSize or 12, true)
    borderSizeControl:SetValue(db and db.borderSize or 16, true)

    if textureButton then
        textureButton:SetSelectedName(db and db.textureName or "Blizzard")
    end
    if fontButton then
        fontButton:SetSelectedName(db and db.fontName or "Friz Quadrata TT")
    end
    if borderButton then
        borderButton:SetSelectedName(db and db.borderName or "None")
    end
    if barColorButton then
        barColorButton:SetColor(db and db.color or (OUS.flightDefaults and OUS.flightDefaults.color))
    end
    if borderColorButton then
        borderColorButton:SetColor(db and db.borderColor or { r = 1, g = 1, b = 1 })
    end
end

C.RegisterPage("FlightMaster", page, Refresh)
