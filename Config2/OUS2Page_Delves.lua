-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Delves.lua
-- Version : 2026.06.22
-- Desc    : OUS2 Delves companion and journey settings page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local companionTemplateBox
local journeyTemplateBox
local widthControl
local heightControl
local scaleControl

local function SetTextColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4])
end

local function GetXPBarDB()
    return OdysseusDB and OdysseusDB.xpBar
end

local function AddSlicedEditBoxBackground(editBox)
    local capWidth = 10
    local leftCut = capWidth / T.Scale.editW
    local rightCut = 1 - leftCut

    local left = editBox:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(T.Tex("ScaleEditBox"))
    left:SetTexCoord(0, leftCut, 0, 1)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(capWidth)

    local right = editBox:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(T.Tex("ScaleEditBox"))
    right:SetTexCoord(rightCut, 1, 0, 1)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(capWidth)

    local middle = editBox:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture(T.Tex("ScaleEditBox"))
    middle:SetTexCoord(leftCut, rightCut, 0, 1)
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
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

local function CreateTemplateRow(labelText, helpText, yOffset, dbKey)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(82)
    row:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("TOPLEFT", row, "TOPLEFT", T.Card.Padding, -10)
    label:SetText(labelText)
    SetTextColor(label, T.Colors.text)

    local editBox = CreateFrame("EditBox", nil, row)
    editBox:SetHeight(T.Scale.editH)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -9)
    editBox:SetPoint("TOPRIGHT", row, "TOPRIGHT", -T.Card.Padding, -34)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(_G[T.Fonts.highlight])
    editBox:SetMaxLetters(300)
    editBox:SetTextInsets(12, 12, 0, 0)
    editBox:SetTextColor(
        T.Colors.text[1],
        T.Colors.text[2],
        T.Colors.text[3],
        T.Colors.text[4]
    )

    AddSlicedEditBoxBackground(editBox)

    local skipFocusCommit

    local function CommitTemplate()
        local db = GetXPBarDB()
        if not db then return end

        db[dbKey] = editBox:GetText()
        if OUS.UpdateDelveBar then
            OUS.UpdateDelveBar()
        end
    end

    editBox:SetScript("OnEnterPressed", function()
        CommitTemplate()
        skipFocusCommit = true
        editBox:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        if skipFocusCommit then
            skipFocusCommit = nil
        else
            CommitTemplate()
        end
    end)
    editBox:SetScript("OnEscapePressed", function()
        local db = GetXPBarDB()
        editBox:SetText(db and db[dbKey] or "")
        skipFocusCommit = true
        editBox:ClearFocus()
    end)

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(editBox, background, helpText)

    return editBox
end

local function ApplyDelveDimensions()
    if OUS.ApplyDimensions then OUS.ApplyDimensions() end
    if OUS.UpdateDelveBar then OUS.UpdateDelveBar() end
    if OUS.WakeBars then OUS.WakeBars() end
    if OUS.SleepBars then OUS.SleepBars() end
end

local function CreateScaleRow(labelText, helpText, yOffset, minValue, maxValue, step, initialValue, dbKey)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(56)
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
        function(value)
            local db = GetXPBarDB()
            if not db then return end

            db[dbKey] = value
            ApplyDelveDimensions()
        end
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
headerIcon:SetTexture(T.Tex("IconDelves"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Delves")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Companion and journey progress display")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

local backButton = CreateFrame("Button", nil, page)
backButton:SetHeight(36)
backButton:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -78)
backButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -78)
backButton:SetNormalTexture(T.Tex("ActionNormal"))
backButton:SetHighlightTexture(T.Tex("ActionHover"))
backButton:SetPushedTexture(T.Tex("ActionPressed"))

local backLabel = backButton:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
backLabel:SetPoint("CENTER")
backLabel:SetText("Back to XP Bar")
SetTextColor(backLabel, T.Colors.text)

backButton:SetScript("OnEnter", function()
    C.SetHelpText("Return to the XP Bar settings hub.")
end)
backButton:SetScript("OnLeave", function()
    C.ClearHelpText()
end)
backButton:SetScript("OnClick", function()
    C.OpenPage("XPBar")
end)

CreateSectionHeader("Text", -130)
companionTemplateBox = CreateTemplateRow(
    "Companion Template",
    "Set the token-based Delves companion progress text.",
    -156,
    "delveCompTemplate"
)
journeyTemplateBox = CreateTemplateRow(
    "Journey Template",
    "Set the token-based Delves journey progress text.",
    -246,
    "delveJourTemplate"
)

CreateSectionHeader("Dimensions", -352)
widthControl = CreateScaleRow(
    "Delve Bar Width",
    "Adjust the width of the Delves bar.",
    -378,
    100,
    1000,
    10,
    300,
    "delveBarWidth"
)
heightControl = CreateScaleRow(
    "Delve Bar Height",
    "Adjust the height of the Delves bar.",
    -438,
    20,
    100,
    2,
    40,
    "delveBarHeight"
)
scaleControl = CreateScaleRow(
    "Delve Bar Scale",
    "Adjust the overall scale of the Delves bar.",
    -498,
    0.5,
    2.0,
    0.05,
    1.0,
    "delveBarScale"
)

CreateSectionHeader("Future Settings", -578)
local note = CreateFrame("Frame", nil, page)
note:SetHeight(60)
note:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -604)
note:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -604)
note:EnableMouse(true)

local noteBackground = note:CreateTexture(nil, "BACKGROUND")
noteBackground:SetTexture(T.Tex("CardNormal"))
noteBackground:SetAllPoints()

local noteText = note:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
noteText:SetPoint("TOPLEFT", note, "TOPLEFT", T.Card.Padding, -T.Card.Padding)
noteText:SetPoint("BOTTOMRIGHT", note, "BOTTOMRIGHT", -T.Card.Padding, T.Card.Padding)
noteText:SetJustifyH("LEFT")
noteText:SetJustifyV("MIDDLE")
noteText:SetText("Delves colors and companion overrides will be added later.")
SetTextColor(noteText, T.Colors.textDim)

note:SetScript("OnEnter", function()
    noteBackground:SetTexture(T.Tex("CardHover"))
    C.SetHelpText("Color and companion override controls remain deferred.")
end)
note:SetScript("OnLeave", function()
    noteBackground:SetTexture(T.Tex("CardNormal"))
    C.ClearHelpText()
end)

local function Refresh()
    local db = GetXPBarDB()

    widthControl:SetValue(db and db.delveBarWidth or 300, true)
    heightControl:SetValue(db and db.delveBarHeight or 40, true)
    scaleControl:SetValue(db and db.delveBarScale or 1.0, true)

    if not companionTemplateBox:HasFocus() then
        local defaultTemplate = OUS.defaults and OUS.defaults.delveCompTemplate or ""
        companionTemplateBox:SetText(db and db.delveCompTemplate or defaultTemplate)
    end
    if not journeyTemplateBox:HasFocus() then
        local defaultTemplate = OUS.defaults and OUS.defaults.delveJourTemplate or ""
        journeyTemplateBox:SetText(db and db.delveJourTemplate or defaultTemplate)
    end
end

C.RegisterPage("Delves", page, Refresh)
