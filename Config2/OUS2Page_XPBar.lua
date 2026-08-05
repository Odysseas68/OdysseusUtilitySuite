-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_XPBar.lua
-- Version : 2026.08.05
-- Desc    : OUS2 XP Bar navigation hub and placeholder child views
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local hub = CreateFrame("Frame", nil, page)
hub:SetAllPoints()

local childFrames = {}
local globalCheckboxes = {}
local globalScaleControls = {}
local globalMediaButtons = {}
local experienceColorSwatches = {}
local experienceScaleControls = {}
local experienceTemplateBox
local reputationCheckboxes = {}
local reputationColorSwatches = {}
local reputationModifierButtons = {}
local reputationTemplateBox
local borderColorSwatch
local Refresh
local RefreshGlobal
local RefreshExperience
local RefreshReputation
local defaultPageHeight = math.max(C.pageContainer:GetHeight() or 0, T.Frame.defaultH)
local globalPageHeight = defaultPageHeight

local REPUTATION_STANDING_COLOR_ROWS = {
    { key = "hated", label = "Hated" },
    { key = "hostile", label = "Hostile" },
    { key = "unfriendly", label = "Unfriendly" },
    { key = "neutral", label = "Neutral" },
    { key = "friendly", label = "Friendly" },
    { key = "honored", label = "Honored" },
    { key = "revered", label = "Revered" },
    { key = "exalted", label = "Exalted" },
    { key = "renown", label = "Renown" },
    { key = "paragon", label = "Paragon" },
}

local RELOAD_POPUP_KEY = "OUS2_XPBAR_HIDE_BLIZZARD_RELOAD"
if not StaticPopupDialogs[RELOAD_POPUP_KEY] then
    StaticPopupDialogs[RELOAD_POPUP_KEY] = {
        text = "Changing the Blizzard XP/Rep bar setting requires a UI reload to fully apply.",
        button1 = "Reload UI",
        button2 = "Later",
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

local function SetTextColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4])
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

local function CreateHeader(parent, titleText, subtitleText)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(T.Tex("IconXPBar"))
    icon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
    icon:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -14)

    local title = parent:CreateFontString(nil, "OVERLAY", T.Fonts.title)
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    title:SetText(titleText)
    SetTextColor(title, T.Colors.accent)

    local subtitle = parent:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetText(subtitleText)
    SetTextColor(subtitle, T.Colors.textDim)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(T.Tex("Divider"))
    divider:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -58)
    divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, -58)
    divider:SetHeight(6)
end

local function CreateSectionHeader(parent, text, yOffset)
    local star = parent:CreateTexture(nil, "ARTWORK")
    star:SetTexture(T.Tex("SectionStar"))
    star:SetSize(14, 14)
    star:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)

    local label = parent:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
    label:SetPoint("LEFT", star, "RIGHT", 6, 0)
    label:SetText(text)
    SetTextColor(label, T.Colors.header)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(T.Tex("Divider"))
    divider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    divider:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    divider:SetHeight(4)
end

-- Child-specific content height keeps longer settings views fully scrollable.
local function SetPageContentHeight(height)
    C.pageContainer:SetHeight(height or defaultPageHeight)
end

local function ShowHub()
    SetPageContentHeight(defaultPageHeight)
    for _, child in pairs(childFrames) do
        child:Hide()
    end
    hub:Show()
    C.ClearHelpText()
end

local function ShowChild(childKey)
    SetPageContentHeight(childKey == "Global" and globalPageHeight or defaultPageHeight)
    hub:Hide()
    for key, child in pairs(childFrames) do
        child:SetShown(key == childKey)
    end
    if childKey == "Global" and RefreshGlobal then
        RefreshGlobal()
    elseif childKey == "Experience" and RefreshExperience then
        RefreshExperience()
    elseif childKey == "Reputation" and RefreshReputation then
        RefreshReputation()
    end
    C.ClearHelpText()
end

page:HookScript("OnHide", function()
    SetPageContentHeight(defaultPageHeight)
end)

local function CreateInfoCard(parent, text, helpText, yOffset, height)
    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(height or 90)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset or -166)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset or -166)
    card:EnableMouse(true)

    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local body = card:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    body:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -T.Card.Padding)
    body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -T.Card.Padding, T.Card.Padding)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("MIDDLE")
    body:SetWordWrap(true)
    body:SetText(text)
    SetTextColor(body, T.Colors.textDim)

    card:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    card:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
end

local function CreateChildView(childKey, titleText, placeholderText)
    local child = CreateFrame("Frame", nil, page)
    child:SetAllPoints()
    child:Hide()
    childFrames[childKey] = child

    CreateHeader(child, titleText, "XP Bar settings section")

    local backButton = CreateFrame("Button", nil, child)
    backButton:SetHeight(36)
    backButton:SetPoint("TOPLEFT", child, "TOPLEFT", 18, -78)
    backButton:SetPoint("TOPRIGHT", child, "TOPRIGHT", -18, -78)
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
    backButton:SetScript("OnClick", ShowHub)

    if placeholderText then
        CreateSectionHeader(child, "Planned Settings", -140)
        CreateInfoCard(
            child,
            placeholderText,
            "This section is read-only until its existing settings are migrated to OUS2."
        )
    end

    return child
end

local function GetModulesDB()
    return OdysseusDB and OdysseusDB.modules
end

local function GetXPBarDB()
    return OdysseusDB and OdysseusDB.xpBar
end

local function WakeAndSleepBars()
    if OUS.WakeBars then
        OUS.WakeBars()
    end
    if OUS.SleepBars then
        OUS.SleepBars()
    end
end

local function AttachControlHelp(frame, background, helpText)
    frame:HookScript("OnEnter", function()
        if background then
            background:SetTexture(T.Tex("CardHover"))
        end
        C.SetHelpText(helpText)
    end)
    frame:HookScript("OnLeave", function()
        if background then
            background:SetTexture(T.Tex("CardNormal"))
        end
        C.ClearHelpText()
    end)
end

local function CreateGlobalCheckbox(
    parent,
    labelText,
    helpText,
    yOffset,
    getDB,
    dbKey,
    onChanged,
    leftSide,
    noteText,
    checkboxList
)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(44)
    if leftSide == nil then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    elseif leftSide then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOP", -5, yOffset)
    else
        row:SetPoint("TOPLEFT", parent, "TOP", 5, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    end

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

    if noteText then
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 7, 2)
        label:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)

        local note = row:CreateFontString(nil, "OVERLAY", T.Fonts.small)
        note:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        note:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
        note:SetJustifyH("LEFT")
        note:SetText(noteText)
        SetTextColor(note, T.Colors.textDim)
    end

    row:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    row:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
    row:SetScript("OnClick", function()
        local db = getDB()
        if not db then return end

        local newValue = not db[dbKey]
        db[dbKey] = newValue
        if onChanged then
            onChanged(newValue)
        end
        Refresh()
    end)

    local entries = checkboxList or globalCheckboxes
    entries[#entries + 1] = {
        checkbox = checkbox,
        getDB = getDB,
        dbKey = dbKey,
    }
end

local function CreateGlobalScale(
    parent,
    labelText,
    helpText,
    yOffset,
    minValue,
    maxValue,
    step,
    initialValue,
    onChanged,
    rowHeight,
    inlineLabel
)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(rowHeight or 56)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
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
    if inlineLabel then
        label:SetPoint("LEFT", row, "LEFT", T.Card.Padding, 0)
        label:SetPoint("RIGHT", control, "LEFT", -10, 0)
        label:SetJustifyH("LEFT")
        label:SetJustifyV("MIDDLE")
        control:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    else
        label:SetPoint("TOPLEFT", row, "TOPLEFT", T.Card.Padding, -4)
        label:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
        label:SetJustifyH("LEFT")
        control:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -T.Card.Padding, 5)
    end

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(control, background, helpText)
    AttachControlHelp(control.leftButton, background, helpText)
    AttachControlHelp(control.rightButton, background, helpText)
    AttachControlHelp(control.slider, background, helpText)
    AttachControlHelp(control.editBox, background, helpText)

    return control
end

-- Compact rows keep dense XP Bar child views inside the existing OUS2 scroll bounds.
local function AnchorGlobalColumnRow(row, parent, yOffset, leftSide, rowHeight, columnCount)
    row:SetHeight(rowHeight or 44)
    if leftSide == "full" then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    elseif type(leftSide) == "number" and columnCount then
        local width = columnCount == 4 and 138 or 186
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18 + ((leftSide - 1) * (width + 10)), yOffset)
        row:SetWidth(width)
    elseif leftSide then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOP", -5, yOffset)
    else
        row:SetPoint("TOPLEFT", parent, "TOP", 5, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    end
    row:EnableMouse(true)
end

local function ShortMediaLabel(name)
    return tostring(name or "None")
end

local function SetSwatchColor(swatch, color, fallback)
    if not swatch then return end

    color = color or fallback
    swatch:SetColorTexture(
        (color and color.r) or 1,
        (color and color.g) or 1,
        (color and color.b) or 1,
        1
    )
end

local function ApplyXPBarFontSettings()
    if OUS.ApplyFonts then
        OUS.ApplyFonts()
    end
end

local function ApplyXPBarBorderSettings()
    if OUS.ApplyXPBarBorders then
        OUS.ApplyXPBarBorders()
    end
end

local function CopyDefaultTable(key)
    local defaults = OUS.defaults
    if not defaults or type(defaults[key]) ~= "table" then
        return nil
    end

    if OUS.DeepCopyTable then
        return OUS.DeepCopyTable(defaults[key])
    end

    local function CopyTable(value)
        if type(value) ~= "table" then
            return value
        end

        local copy = {}
        for entryKey, entryValue in pairs(value) do
            copy[entryKey] = CopyTable(entryValue)
        end
        return copy
    end

    return CopyTable(defaults[key])
end

local function ResetGlobalDefaults()
    local db = GetXPBarDB()
    local defaults = OUS.defaults
    if not db or not defaults then return end

    db.hideBlizz = defaults.hideBlizz
    db.autoHide = defaults.autoHide
    db.repDisplayTime = defaults.repDisplayTime
    db.fadeDelay = defaults.fadeDelay
    db.activeAlpha = defaults.activeAlpha
    db.fadedAlpha = defaults.fadedAlpha
    db.xpFont = defaults.xpFont
    db.xpFontSize = defaults.xpFontSize

    if OUS.ApplyBlizzardKiller then OUS.ApplyBlizzardKiller() end
    ApplyXPBarFontSettings()
    if OUS.UpdateBar then OUS.UpdateBar() end
    WakeAndSleepBars()
    if OUS.LogDebug then
        OUS.LogDebug("XPBar", "Global defaults restored.")
    end

    RefreshGlobal()
end

-- Border reset remains isolated from the other Global settings groups.
local function ResetBorderDefaults()
    local db = GetXPBarDB()
    local defaults = OUS.defaults
    if not db or not defaults then return end

    db.barBorderName = defaults.barBorderName
    db.barBorderSize = defaults.barBorderSize
    db.barBorderColor = CopyDefaultTable("barBorderColor")

    ApplyXPBarBorderSettings()
    if OUS.LogDebug then
        OUS.LogDebug("XPBar", "Border defaults restored.")
    end

    RefreshGlobal()
end

local function ApplyExperienceBarColors()
    if OUS.UpdateBar then
        OUS.UpdateBar()
    end
end

local function ApplyExperienceBackground()
    if OUS.ApplyXPBarBg then
        OUS.ApplyXPBarBg()
    end
end

local function ApplyReputationColors()
    if OUS.UpdateBar then
        OUS.UpdateBar()
    end
end

local function CreateGlobalMediaRow(parent, labelText, helpText, yOffset, dbKey, mediaType, onChanged, leftSide)
    local row = CreateFrame("Frame", nil, parent)
    AnchorGlobalColumnRow(row, parent, yOffset, leftSide)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("LEFT", row, "LEFT", T.Card.Padding, 0)
    label:SetWidth(118)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    SetTextColor(label, T.Colors.text)

    local button = CreateFrame("Button", nil, row)
    button:SetPoint("LEFT", label, "RIGHT", 10, 0)
    button:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    button:SetHeight(24)
    button:SetNormalTexture(T.Tex("ActionNormal"))
    button:SetHighlightTexture(T.Tex("ActionHover"))
    button:SetPushedTexture(T.Tex("ActionPressed"))

    local buttonLabel = button:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    buttonLabel:SetPoint("LEFT", button, "LEFT", 8, 0)
    buttonLabel:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    buttonLabel:SetJustifyH("CENTER")
    buttonLabel:SetJustifyV("MIDDLE")
    buttonLabel:SetWordWrap(false)
    SetTextColor(buttonLabel, T.Colors.text)
    button.label = buttonLabel

    button:SetScript("OnClick", function()
        local db = GetXPBarDB()
        if not db then return end

        C.OpenMediaDropdown(button, mediaType, db[dbKey], function(name)
            db[dbKey] = name
            button.label:SetText(ShortMediaLabel(name))
            if onChanged then
                onChanged()
            end
            RefreshGlobal()
        end)
    end)

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(button, background, helpText)
    globalMediaButtons[dbKey] = button
    return button
end

local function CreateGlobalColorRow(parent, labelText, helpText, yOffset, dbKey, onChanged, leftSide, swatchStore, rootKey, rowHeight, columnCount)
    local row = CreateFrame("Frame", nil, parent)
    AnchorGlobalColumnRow(row, parent, yOffset, leftSide, rowHeight, columnCount)

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("LEFT", row, "LEFT", T.Card.Padding, 0)
    label:SetText(labelText)
    SetTextColor(label, T.Colors.text)

    local swatchButton = CreateFrame("Button", nil, row)
    swatchButton:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    local swatchSize = rowHeight and rowHeight < 36 and 24 or 28
    swatchButton:SetSize(swatchSize, swatchSize)
    label:SetPoint("RIGHT", swatchButton, "LEFT", -6, 0)
    label:SetJustifyH("LEFT")

    local swatch = swatchButton:CreateTexture(nil, "ARTWORK")
    local inset = rowHeight and rowHeight < 36 and 4 or 5
    swatch:SetPoint("TOPLEFT", swatchButton, "TOPLEFT", inset, -inset)
    swatch:SetPoint("BOTTOMRIGHT", swatchButton, "BOTTOMRIGHT", -inset, inset)
    swatch:SetColorTexture(0.6, 0.2, 0.8, 1)

    swatchButton:SetScript("OnClick", function()
        local db = GetXPBarDB()
        if not db then return end

        local colorTable = db[dbKey]
        if rootKey then
            local colorRoot = db[rootKey]
            colorTable = colorRoot and colorRoot[dbKey]
        end
        if type(colorTable) ~= "table" then return end

        C.OpenColorPicker(colorTable, swatch, function()
            if onChanged then
                onChanged()
            end
        end)

        local colorPickerFrame = _G.ColorPickerFrame
        if colorPickerFrame and colorPickerFrame.SetFrameStrata then
            colorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        end
    end)

    AttachControlHelp(row, nil, helpText)
    AttachControlHelp(swatchButton, nil, helpText)
    if swatchStore then
        swatchStore[dbKey] = swatch
    else
        borderColorSwatch = swatch
    end
    return swatch
end

local function CreateGlobalActionButton(parent, labelText, helpText, yOffset, onClick, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    button:SetSize(width or 132, 24)
    button:SetNormalTexture(T.Tex("ActionNormal"))
    button:SetHighlightTexture(T.Tex("ActionHover"))
    button:SetPushedTexture(T.Tex("ActionPressed"))

    local label = button:CreateFontString(nil, "OVERLAY", T.Fonts.small)
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

local function ApplyExperienceDimensions()
    if OUS.ApplyDimensions then OUS.ApplyDimensions() end
    if OUS.UpdateBar then OUS.UpdateBar() end
    if OUS.WakeBars then OUS.WakeBars() end
    if OUS.SleepBars then OUS.SleepBars() end
end

local function ResetExperienceDefaults()
    local db = GetXPBarDB()
    local defaults = OUS.defaults
    if not db or not defaults then return end

    db.xpTemplate = defaults.xpTemplate
    db.xpColor = CopyDefaultTable("xpColor")
    db.xpTextColor = CopyDefaultTable("xpTextColor")
    db.restColor = CopyDefaultTable("restColor")
    db.bgColor = CopyDefaultTable("bgColor")
    db.showRestIcon = defaults.showRestIcon
    db.xpBarWidth = defaults.xpBarWidth
    db.xpBarHeight = defaults.xpBarHeight
    db.xpBarScale = defaults.xpBarScale

    ApplyExperienceBackground()
    ApplyExperienceDimensions()
    if OUS.LogDebug then
        OUS.LogDebug("XPBar", "Experience tab defaults restored.")
    end

    RefreshExperience()
    RefreshGlobal()
end

local function ResetReputationDefaults()
    local db = GetXPBarDB()
    local defaults = OUS.defaults
    if not db or not defaults then return end

    db.repTemplate = defaults.repTemplate
    db.repTextColor = CopyDefaultTable("repTextColor")
    db.repColors = CopyDefaultTable("repColors")
    db.repMenuMod = defaults.repMenuMod

    ApplyReputationColors()
    if OUS.LogDebug then
        OUS.LogDebug("XPBar", "Reputation tab defaults restored.")
    end

    RefreshReputation()
end

local function CreateExperienceTemplateRow(parent, yOffset)
    local helpText = "Set the token-based text shown on the XP Bar."

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(82)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("TOPLEFT", row, "TOPLEFT", T.Card.Padding, -10)
    label:SetText("XP Text Template")
    SetTextColor(label, T.Colors.text)

    experienceTemplateBox = CreateFrame("EditBox", nil, row)
    experienceTemplateBox:SetHeight(T.Scale.editH)
    experienceTemplateBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -9)
    experienceTemplateBox:SetPoint("TOPRIGHT", row, "TOPRIGHT", -T.Card.Padding, -34)
    experienceTemplateBox:SetAutoFocus(false)
    experienceTemplateBox:SetFontObject(_G[T.Fonts.highlight])
    experienceTemplateBox:SetMaxLetters(300)
    experienceTemplateBox:SetTextInsets(12, 12, 0, 0)
    experienceTemplateBox:SetTextColor(
        T.Colors.text[1],
        T.Colors.text[2],
        T.Colors.text[3],
        T.Colors.text[4]
    )

    AddSlicedEditBoxBackground(experienceTemplateBox)

    local skipFocusCommit

    local function CommitTemplate()
        local db = GetXPBarDB()
        if not db then return end

        db.xpTemplate = experienceTemplateBox:GetText()
        if OUS.UpdateBar then
            OUS.UpdateBar()
        end
    end

    experienceTemplateBox:SetScript("OnEnterPressed", function()
        CommitTemplate()
        skipFocusCommit = true
        experienceTemplateBox:ClearFocus()
    end)
    experienceTemplateBox:SetScript("OnEditFocusLost", function()
        if skipFocusCommit then
            skipFocusCommit = nil
        else
            CommitTemplate()
        end
        Refresh()
    end)
    experienceTemplateBox:SetScript("OnEscapePressed", function()
        local db = GetXPBarDB()
        experienceTemplateBox:SetText(db and db.xpTemplate or "")
        skipFocusCommit = true
        experienceTemplateBox:ClearFocus()
    end)

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(experienceTemplateBox, background, helpText)
end

local function CreateReputationTemplateRow(parent, yOffset)
    local helpText = "Set the token-based text shown for reputation progress."

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(82)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("TOPLEFT", row, "TOPLEFT", T.Card.Padding, -10)
    label:SetText("Reputation Text Template")
    SetTextColor(label, T.Colors.text)

    reputationTemplateBox = CreateFrame("EditBox", nil, row)
    reputationTemplateBox:SetHeight(T.Scale.editH)
    reputationTemplateBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -9)
    reputationTemplateBox:SetPoint("TOPRIGHT", row, "TOPRIGHT", -T.Card.Padding, -34)
    reputationTemplateBox:SetAutoFocus(false)
    reputationTemplateBox:SetFontObject(_G[T.Fonts.highlight])
    reputationTemplateBox:SetMaxLetters(300)
    reputationTemplateBox:SetTextInsets(12, 12, 0, 0)
    reputationTemplateBox:SetTextColor(
        T.Colors.text[1],
        T.Colors.text[2],
        T.Colors.text[3],
        T.Colors.text[4]
    )

    AddSlicedEditBoxBackground(reputationTemplateBox)

    local skipFocusCommit

    local function CommitTemplate()
        local db = GetXPBarDB()
        if not db then return end

        db.repTemplate = reputationTemplateBox:GetText()
        if OUS.UpdateBar then
            OUS.UpdateBar()
        end
    end

    reputationTemplateBox:SetScript("OnEnterPressed", function()
        CommitTemplate()
        skipFocusCommit = true
        reputationTemplateBox:ClearFocus()
    end)
    reputationTemplateBox:SetScript("OnEditFocusLost", function()
        if skipFocusCommit then
            skipFocusCommit = nil
        else
            CommitTemplate()
        end
        Refresh()
    end)
    reputationTemplateBox:SetScript("OnEscapePressed", function()
        local db = GetXPBarDB()
        reputationTemplateBox:SetText(db and db.repTemplate or "")
        skipFocusCommit = true
        reputationTemplateBox:ClearFocus()
    end)

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(reputationTemplateBox, background, helpText)
end

local function CreateReputationModifierButton(parent, labelText, value, yOffset, leftSide)
    local helpText
    if value == "NONE" then
        helpText = "Open the existing faction selector with right-click and no modifier."
    else
        helpText = "Use " .. labelText .. " with right-click to open the existing faction selector."
    end

    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(44)
    if leftSide then
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
        button:SetPoint("TOPRIGHT", parent, "TOP", -5, yOffset)
    else
        button:SetPoint("TOPLEFT", parent, "TOP", 5, yOffset)
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, yOffset)
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
        C.SetHelpText(helpText)
    end)
    button:SetScript("OnLeave", function(self)
        background:SetTexture(T.Tex(self.selected and "CardSelected" or "CardNormal"))
        C.ClearHelpText()
    end)
    button:SetScript("OnClick", function()
        local db = GetXPBarDB()
        if not db then return end

        db.repMenuMod = value
        Refresh()
    end)

    reputationModifierButtons[value] = button
end

local function UpdateReputationModifierButton(button, selected)
    button.selected = selected
    button.background:SetTexture(T.Tex(selected and "CardSelected" or "CardNormal"))
    SetTextColor(button.label, selected and T.Colors.accent or T.Colors.text)
end

local function CreateHelpRow(parent, text, helpText, yOffset, height)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(height or 38)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -yOffset)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, -yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local body = row:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    body:SetPoint("TOPLEFT", row, "TOPLEFT", T.Card.Padding, -T.Card.Padding)
    body:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -T.Card.Padding, T.Card.Padding)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("MIDDLE")
    body:SetWordWrap(true)
    body:SetText(text)
    SetTextColor(body, T.Colors.text)

    row:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    row:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)

    return yOffset + (height or 38) + 6
end

local function AddHelpSection(parent, text, yOffset)
    CreateSectionHeader(parent, text, -yOffset)
    return yOffset + 26
end

local function AddTokenRows(parent, entries, yOffset)
    for _, entry in ipairs(entries) do
        yOffset = CreateHelpRow(
            parent,
            entry[1] .. " - " .. entry[2],
            entry[2],
            yOffset
        )
    end
    return yOffset
end

local function CreateHelpScrollContent(parent)
    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBox")
    scrollBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -130)
    scrollBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -34, 10)

    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetWidth(12)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local content = CreateFrame("Frame", nil, scrollBox)
    content:SetWidth(math.max(1, scrollBox:GetWidth() - 4))
    content.scrollable = true

    scrollBox:HookScript("OnSizeChanged", function(_, width)
        content:SetWidth(math.max(1, width - 4))
    end)

    local yOffset = 6

    yOffset = AddHelpSection(content, "XP Template Tokens", yOffset)
    yOffset = AddTokenRows(content, {
        { "[curXP]", "Current XP" },
        { "[maxXP]", "Maximum XP" },
        { "[needXP]", "Remaining XP" },
        { "[curPC]", "Current percentage" },
        { "[needPC]", "Remaining percentage" },
        { "[restPC]", "Rested percentage" },
        { "[pLVL]", "Current level" },
        { "[nLVL]", "Next level" },
        { "[mLVL]", "Maximum level" },
        { "[restXP]", "Rested XP" },
        { "[restLVL]", "Rested XP measured in levels" },
        { "[KTL]", "Kills to level" },
    }, yOffset)

    yOffset = yOffset + 8
    yOffset = AddHelpSection(content, "Reputation Template Tokens", yOffset)
    yOffset = AddTokenRows(content, {
        { "[faction]", "Faction name" },
        { "[standing]", "Current standing" },
        { "[curRep]", "Current reputation" },
        { "[maxRep]", "Maximum reputation for the current level" },
        { "[needRep]", "Remaining reputation" },
        { "[repPC]", "Current reputation percentage" },
        { "[needPC]", "Remaining reputation percentage" },
        { "[curLVL]", "Current reputation or journey level" },
        { "[nextLVL]", "Next reputation or journey level" },
    }, yOffset)

    yOffset = yOffset + 8
    yOffset = AddHelpSection(content, "Delves Template Tokens", yOffset)
    yOffset = AddTokenRows(content, {
        { "[compName]", "Companion name" },
        { "[pLVL]", "Companion level" },
        { "[curXP]", "Current companion XP" },
        { "[maxXP]", "Maximum companion XP" },
        { "[needXP]", "Remaining companion XP" },
        { "[curPC]", "Current companion XP percentage" },
        { "[needPC]", "Remaining companion XP percentage" },
        { "[curLVL]", "Current journey level" },
        { "[nextLVL]", "Next journey level" },
        { "[curRep]", "Current journey reputation" },
        { "[maxRep]", "Maximum journey reputation for the current level" },
        { "[needRep]", "Remaining journey reputation" },
        { "[repPC]", "Current journey percentage" },
        { "[needPC]", "Remaining journey percentage" },
        { "[faction]", "Journey name" },
        { "[standing]", "Journey state" },
    }, yOffset)

    yOffset = yOffset + 8
    yOffset = AddHelpSection(content, "Favorites", yOffset)
    yOffset = CreateHelpRow(
        content,
        "Modifier-right-click the XP Bar to open the existing Reputation Favorites selector.",
        "The modifier is configured on the Reputation child page.",
        yOffset,
        52
    )
    yOffset = CreateHelpRow(
        content,
        "Clicking a saved Favorite can set it as watched; normal max-level display prefers the currently watched faction.",
        "Watched-faction behavior remains owned by the XP Bar engine.",
        yOffset,
        58
    )
    yOffset = CreateHelpRow(
        content,
        "Save Favorites commits the temporary selection. Cancel closes the selector without saving changes.",
        "The existing selector keeps edits temporary until Save Favorites is clicked.",
        yOffset,
        58
    )
    yOffset = CreateHelpRow(
        content,
        "OUS2 Favorites management is planned for a future version when a public selector API exists.",
        "OUS2 does not manipulate Favorites data directly.",
        yOffset,
        52
    )

    yOffset = yOffset + 8
    yOffset = AddHelpSection(content, "Commands", yOffset)
    yOffset = CreateHelpRow(
        content,
        "/xpstats - Show session XP and reputation statistics.",
        "Open the XP Bar session statistics frame.",
        yOffset
    )
    yOffset = CreateHelpRow(
        content,
        "/toasttest - Test the reputation reward popup.",
        "Show the XP Bar reward toast test.",
        yOffset
    )

    yOffset = yOffset + 8
    yOffset = AddHelpSection(content, "Movement", yOffset)
    yOffset = CreateHelpRow(
        content,
        "Hold Shift and drag the XP Bar frame to reposition it.",
        "The XP Bar saves its position when its drag operation stops.",
        yOffset,
        46
    )
    yOffset = CreateHelpRow(
        content,
        "Use Unlock Frame on the Delves page, then left-drag the Delves frame.",
        "Lock Frame saves the position and restores normal Delves visibility.",
        yOffset,
        46
    )

    yOffset = yOffset + 8
    yOffset = AddHelpSection(content, "Notes", yOffset)
    yOffset = CreateHelpRow(
        content,
        "Reputation display may temporarily switch after reputation gains.",
        "Recent reputation gains can temporarily force reputation display.",
        yOffset,
        46
    )
    yOffset = CreateHelpRow(
        content,
        "At max level, the last reputation faction is used as a fallback only when no faction is watched.",
        "A currently watched faction takes priority over the remembered fallback.",
        yOffset,
        58
    )
    yOffset = CreateHelpRow(
        content,
        "Delves visibility depends on the existing Delves detection logic.",
        "OUS2 does not change or preview Delves detection state.",
        yOffset,
        46
    )

    content:SetHeight(yOffset + 14)

    local view = CreateScrollBoxLinearView()
    view:SetPanExtent(T.Scroll.scrollStep)
    ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)
end

CreateHeader(
    hub,
    "XP Bar",
    "Experience, reputation, Delves, and progress display"
)
CreateSectionHeader(hub, "Settings", -78)

local cardData = {
    {
        name = "Global",
        detail = "Shared appearance and behavior",
        help = "Open the planned global XP Bar settings section.",
        childKey = "Global",
    },
    {
        name = "Experience",
        detail = "Experience display settings",
        help = "Open the planned experience settings section.",
        childKey = "Experience",
    },
    {
        name = "Reputation",
        detail = "Reputation display settings",
        help = "Open the planned reputation settings section.",
        childKey = "Reputation",
    },
    {
        name = "Favorites",
        detail = "Pinned faction management",
        help = "Open the planned Favorites settings section.",
        childKey = "Favorites",
    },
    {
        name = "Delves",
        detail = "Companion and journey settings",
        help = "Delves settings will be implemented as a separate OUS2 page.",
        isDelves = true,
    },
    {
        name = "Help",
        detail = "Tokens, commands, and guidance",
        help = "Open the planned XP Bar help section.",
        childKey = "Help",
    },
}

local function CreateHubCard(info, index)
    local row = math.floor((index - 1) / 2)
    local yOffset = -106 - row * (T.Card.Height + 10)
    local leftSide = index % 2 == 1

    local card = CreateFrame("Button", nil, hub)
    card:SetHeight(T.Card.Height)
    if leftSide then
        card:SetPoint("TOPLEFT", hub, "TOPLEFT", 18, yOffset)
        card:SetPoint("TOPRIGHT", hub, "TOP", -5, yOffset)
    else
        card:SetPoint("TOPLEFT", hub, "TOP", 5, yOffset)
        card:SetPoint("TOPRIGHT", hub, "TOPRIGHT", -18, yOffset)
    end

    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local name = card:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    name:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -12)
    name:SetText(info.name)
    SetTextColor(name, T.Colors.text)

    local detail = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
    detail:SetPoint("RIGHT", card, "RIGHT", -(T.Card.Padding + T.Card.ChevronSize), 0)
    detail:SetJustifyH("LEFT")
    detail:SetText(info.detail)
    SetTextColor(detail, T.Colors.textDim)

    local chevron = card:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
    chevron:SetSize(T.Card.ChevronSize, T.Card.ChevronSize)
    chevron:SetPoint("RIGHT", card, "RIGHT", -T.Card.Padding, 0)
    chevron:SetJustifyH("CENTER")
    chevron:SetText(">")
    SetTextColor(chevron, T.Colors.accent)

    card:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(info.help)
    end)
    card:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
    card:SetScript("OnClick", function()
        if info.isDelves then
            if C.pages and C.pages.Delves and C.pages.Delves.frame then
                C.OpenPage("Delves")
            else
                C.SetHelpText("Delves settings will be implemented as a separate OUS2 page.")
            end
            return
        end

        ShowChild(info.childKey)
    end)
end

for index, info in ipairs(cardData) do
    CreateHubCard(info, index)
end

local globalChild = CreateChildView(
    "Global",
    "XP Bar - Global",
    nil
)

local DISPLAY_HEADER_Y = -350
local DISPLAY_FIRST_ROW_Y = -368
local DISPLAY_ROW_STEP = 46
local DISPLAY_FONT_Y = DISPLAY_FIRST_ROW_Y - (DISPLAY_ROW_STEP * 5) - 2
local BORDER_HEADER_Y = DISPLAY_FONT_Y - 66
local BORDER_STYLE_Y = BORDER_HEADER_Y - 18
local BORDER_SIZE_Y = BORDER_STYLE_Y - 48
local BORDER_COLOR_Y = BORDER_SIZE_Y - 48
globalPageHeight = math.max(defaultPageHeight, -BORDER_COLOR_Y + 68)

CreateSectionHeader(globalChild, "Module", -130)
CreateGlobalCheckbox(
    globalChild,
    "Enable XP Bar Module",
    "Enable or disable the XP Bar module.",
    -156,
    GetModulesDB,
    "xpBar",
    function(enabled)
        if enabled then
            if OUS.UpdateBar then OUS.UpdateBar() end
            if OUS.UpdateDelveBar then OUS.UpdateDelveBar() end
            if OUS.WakeBars then OUS.WakeBars() end
        else
            if OUS.xpBarFrame then OUS.xpBarFrame:Hide() end
            if OUS.delveBarFrame then OUS.delveBarFrame:Hide() end
            if OUS.favHoverFrame then OUS.favHoverFrame:Hide() end
        end
    end
)

CreateSectionHeader(globalChild, "Behavior", -214)
CreateGlobalCheckbox(
    globalChild,
    "Hide Blizzard XP/Rep Bars",
    "Hide the Blizzard XP and reputation bars. A UI reload may be required for this change to apply fully.",
    -240,
    GetXPBarDB,
    "hideBlizz",
    function()
        StaticPopup_Show(RELOAD_POPUP_KEY)
    end,
    true,
    "Requires /reload to fully apply."
)
CreateGlobalCheckbox(
    globalChild,
    "Abbreviate Large Numbers",
    "Use abbreviated values for large XP and reputation numbers.",
    -240,
    GetXPBarDB,
    "shortNumbers",
    function()
        if OUS.UpdateBar then OUS.UpdateBar() end
    end,
    false
)
CreateGlobalCheckbox(
    globalChild,
    "Auto-hide Bars",
    "Fade the XP Bar displays after the configured delay.",
    -288,
    GetXPBarDB,
    "autoHide",
    WakeAndSleepBars,
    true
)
CreateGlobalCheckbox(
    globalChild,
    "Show Rested Icon",
    "Show the rested-state icon on the XP Bar when applicable.",
    -288,
    GetXPBarDB,
    "showRestIcon",
    function()
        if OUS.UpdateBar then OUS.UpdateBar() end
    end,
    false
)

CreateSectionHeader(globalChild, "Display", DISPLAY_HEADER_Y)
CreateGlobalActionButton(
    globalChild,
    "Reset Defaults",
    "Reset the Global behavior and Display settings, excluding the separate Border section.",
    DISPLAY_HEADER_Y + 4,
    ResetGlobalDefaults
)

globalScaleControls.xpFontSize = CreateGlobalScale(
    globalChild,
    "Font Size",
    "Adjust the XP Bar font size.",
    DISPLAY_FIRST_ROW_Y,
    8,
    32,
    1,
    15,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.xpFontSize = value
        ApplyXPBarFontSettings()
        if OUS.UpdateBar then OUS.UpdateBar() end
        if OUS.UpdateDelveBar then OUS.UpdateDelveBar() end
    end,
    44
)

globalScaleControls.repDisplayTime = CreateGlobalScale(
    globalChild,
    "Auto-Switch Display Time",
    "Set how long reputation progress remains active after a reputation gain.",
    DISPLAY_FIRST_ROW_Y - DISPLAY_ROW_STEP,
    5,
    60,
    1,
    15,
    function(value)
        local db = GetXPBarDB()
        if db then
            db.repDisplayTime = value
        end
        WakeAndSleepBars()
    end,
    44
)

globalScaleControls.fadeDelay = CreateGlobalScale(
    globalChild,
    "Auto-Hide Fade Delay",
    "Set the delay before auto-hide fades the bars.",
    DISPLAY_FIRST_ROW_Y - (DISPLAY_ROW_STEP * 2),
    0,
    60,
    1,
    5,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.fadeDelay = value
        WakeAndSleepBars()
    end,
    44
)

globalScaleControls.activeAlpha = CreateGlobalScale(
    globalChild,
    "Active Alpha",
    "Set bar opacity while the XP Bar is active.",
    DISPLAY_FIRST_ROW_Y - (DISPLAY_ROW_STEP * 3),
    0.1,
    1.0,
    0.05,
    1.0,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.activeAlpha = math.floor((value * 100) + 0.5)
        WakeAndSleepBars()
    end,
    44
)

globalScaleControls.fadedAlpha = CreateGlobalScale(
    globalChild,
    "Faded Alpha",
    "Set bar opacity after auto-hide fades the bars.",
    DISPLAY_FIRST_ROW_Y - (DISPLAY_ROW_STEP * 4),
    0.0,
    1.0,
    0.05,
    0.0,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.fadedAlpha = math.floor((value * 100) + 0.5)
        WakeAndSleepBars()
    end,
    44
)

CreateGlobalMediaRow(
    globalChild,
    "Global Font",
    "Select the shared XP Bar font.",
    DISPLAY_FONT_Y,
    "xpFont",
    "font",
    ApplyXPBarFontSettings,
    "full"
)

CreateSectionHeader(globalChild, "Border", BORDER_HEADER_Y)
CreateGlobalActionButton(
    globalChild,
    "Reset Defaults",
    "Reset only the XP Bar border style, color, and size.",
    BORDER_HEADER_Y + 4,
    ResetBorderDefaults
)

CreateGlobalMediaRow(
    globalChild,
    "Bar Border Style",
    "Select the XP Bar border texture.",
    BORDER_STYLE_Y,
    "barBorderName",
    "border",
    ApplyXPBarBorderSettings,
    "full"
)

globalScaleControls.barBorderSize = CreateGlobalScale(
    globalChild,
    "Border Size",
    "Adjust the XP Bar border thickness.",
    BORDER_SIZE_Y,
    0,
    50,
    1,
    8,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.barBorderSize = value
        ApplyXPBarBorderSettings()
    end,
    44,
    true
)

CreateGlobalColorRow(
    globalChild,
    "Border Color",
    "Choose the XP Bar border color.",
    BORDER_COLOR_Y,
    "barBorderColor",
    ApplyXPBarBorderSettings,
    "full"
)

local experienceChild = CreateChildView(
    "Experience",
    "XP Bar - Experience",
    nil
)

CreateSectionHeader(experienceChild, "Text", -130)
CreateExperienceTemplateRow(experienceChild, -156)

CreateSectionHeader(experienceChild, "Dimensions", -262)

experienceScaleControls.xpBarWidth = CreateGlobalScale(
    experienceChild,
    "XP Bar Width",
    "Adjust the width of the XP Bar.",
    -288,
    100,
    1000,
    10,
    650,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.xpBarWidth = value
        ApplyExperienceDimensions()
    end
)

experienceScaleControls.xpBarHeight = CreateGlobalScale(
    experienceChild,
    "XP Bar Height",
    "Adjust the height of the XP Bar.",
    -348,
    10,
    100,
    1,
    25,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.xpBarHeight = value
        ApplyExperienceDimensions()
    end
)

experienceScaleControls.xpBarScale = CreateGlobalScale(
    experienceChild,
    "XP Bar Scale",
    "Adjust the overall scale of the XP Bar.",
    -408,
    0.5,
    2.0,
    0.05,
    1.0,
    function(value)
        local db = GetXPBarDB()
        if not db then return end
        db.xpBarScale = value
        ApplyExperienceDimensions()
    end
)

CreateSectionHeader(experienceChild, "Colors", -488)
CreateGlobalActionButton(
    experienceChild,
    "Reset Defaults",
    "Reset only legacy XP Bar Experience settings: template, colors, rested icon, width, height, and scale.",
    -484,
    ResetExperienceDefaults
)
CreateGlobalColorRow(
    experienceChild,
    "Main EXP Bar",
    "Choose the main experience progress color.",
    -514,
    "xpColor",
    ApplyExperienceBarColors,
    true,
    experienceColorSwatches
)
CreateGlobalColorRow(
    experienceChild,
    "XP Text Color",
    "Choose the XP Bar text color.",
    -514,
    "xpTextColor",
    ApplyExperienceBarColors,
    false,
    experienceColorSwatches
)
CreateGlobalColorRow(
    experienceChild,
    "Rested Bar",
    "Choose the rested experience overlay color.",
    -562,
    "restColor",
    ApplyExperienceBarColors,
    true,
    experienceColorSwatches
)
CreateGlobalColorRow(
    experienceChild,
    "Background",
    "Choose the XP Bar background color.",
    -562,
    "bgColor",
    ApplyExperienceBackground,
    false,
    experienceColorSwatches
)
local reputationChild = CreateChildView(
    "Reputation",
    "XP Bar - Reputation",
    nil
)

CreateSectionHeader(reputationChild, "Text", -130)
CreateReputationTemplateRow(reputationChild, -156)

CreateSectionHeader(reputationChild, "Toast", -262)
CreateGlobalCheckbox(
    reputationChild,
    "Toast Enabled",
    "Show the existing reputation reward toast when applicable.",
    -288,
    GetXPBarDB,
    "toastEnabled",
    nil,
    true,
    nil,
    reputationCheckboxes
)
CreateGlobalCheckbox(
    reputationChild,
    "Toast Sound",
    "Play the configured sound with reputation reward toasts.",
    -288,
    GetXPBarDB,
    "toastSound",
    nil,
    false,
    nil,
    reputationCheckboxes
)

CreateSectionHeader(reputationChild, "Faction Menu Modifier", -350)
CreateReputationModifierButton(reputationChild, "CTRL", "CTRL", -376, true)
CreateReputationModifierButton(reputationChild, "SHIFT", "SHIFT", -376, false)
CreateReputationModifierButton(reputationChild, "ALT", "ALT", -426, true)
CreateReputationModifierButton(reputationChild, "NONE", "NONE", -426, false)

CreateSectionHeader(reputationChild, "Reputation", -492)
CreateGlobalActionButton(
    reputationChild,
    "Reset Defaults",
    "Reset only Reputation template, colors, and faction menu modifier settings.",
    -488,
    ResetReputationDefaults
)
CreateGlobalColorRow(
    reputationChild,
    "Reputation Text Color",
    "Choose the text color used for reputation display.",
    -518,
    "repTextColor",
    ApplyReputationColors,
    true,
    reputationColorSwatches
)

CreateSectionHeader(reputationChild, "Standing Colors", -562)
for index, entry in ipairs(REPUTATION_STANDING_COLOR_ROWS) do
    local row = math.floor((index - 1) / 4)
    local column = ((index - 1) % 4) + 1
    CreateGlobalColorRow(
        reputationChild,
        entry.label,
        "Choose the " .. entry.label .. " reputation standing color.",
        -586 - (row * 34),
        entry.key,
        ApplyReputationColors,
        column,
        reputationColorSwatches,
        "repColors",
        30,
        4
    )
end
local favoritesChild = CreateChildView(
    "Favorites",
    "XP Bar - Favorites",
    nil
)

CreateSectionHeader(favoritesChild, "Favorites", -130)
CreateGlobalActionButton(
    favoritesChild,
    "Open Favorites Selector",
    "Open the existing XP Bar Favorites selector. OUS2 delegates saving to the legacy selector.",
    -126,
    function()
        if OUS.OpenXPBarFavoritesSelector and OUS.OpenXPBarFavoritesSelector() then
            C.SetHelpText("Favorites selector opened.")
        else
            C.SetHelpText("Favorites selector cannot be opened during combat.")
            if OUS.LogDebug then
                OUS.LogDebug("XPBar", "OUS2 Favorites selector open request failed.")
            end
        end
    end,
    180
)
CreateInfoCard(
    favoritesChild,
    "Favorites are managed through the existing Reputation Favorites selector.\n\n" ..
    "How to use:\n\n" ..
    "1. Open the Reputation bar menu.\n" ..
    "2. Use the configured modifier key.\n" ..
    "3. Select favorite factions.\n" ..
    "4. Save changes.",
    "Favorites continue to use the existing Reputation Favorites selector.",
    -156,
    210
)

CreateSectionHeader(favoritesChild, "Notes", -390)
CreateInfoCard(
    favoritesChild,
    "- Favorites are stored in OdysseusDB.xpBar.favFactions.\n" ..
    "- Watched factions remain managed by the XP Bar engine.\n" ..
    "- OUS2 opens the existing selector and does not write Favorites directly.",
    "Favorites and watched-faction state remain owned by the XP Bar runtime.",
    -416,
    130
)
local helpChild = CreateChildView(
    "Help",
    "XP Bar - Help",
    nil
)
CreateHelpScrollContent(helpChild)

RefreshGlobal = function()
    for _, entry in ipairs(globalCheckboxes) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    local db = GetXPBarDB()
    globalScaleControls.xpFontSize:SetValue(db and db.xpFontSize or 15, true)
    globalScaleControls.repDisplayTime:SetValue(db and db.repDisplayTime or 15, true)
    globalScaleControls.fadeDelay:SetValue(db and db.fadeDelay or 5, true)
    globalScaleControls.activeAlpha:SetValue((db and db.activeAlpha or 100) / 100, true)
    globalScaleControls.fadedAlpha:SetValue((db and db.fadedAlpha or 0) / 100, true)
    globalScaleControls.barBorderSize:SetValue(db and db.barBorderSize or 8, true)

    if globalMediaButtons.xpFont then
        globalMediaButtons.xpFont.label:SetText(ShortMediaLabel(db and db.xpFont or "Friz Quadrata TT"))
    end
    if globalMediaButtons.barBorderName then
        globalMediaButtons.barBorderName.label:SetText(ShortMediaLabel(db and db.barBorderName or "Blizzard Tooltip"))
    end
    if borderColorSwatch then
        local color = db and db.barBorderColor
        borderColorSwatch:SetColorTexture(
            (color and color.r) or 0.6,
            (color and color.g) or 0.2,
            (color and color.b) or 0.8,
            1
        )
    end
end

RefreshExperience = function()
    local db = GetXPBarDB()
    experienceScaleControls.xpBarWidth:SetValue(db and db.xpBarWidth or 650, true)
    experienceScaleControls.xpBarHeight:SetValue(db and db.xpBarHeight or 25, true)
    experienceScaleControls.xpBarScale:SetValue(db and db.xpBarScale or 1.0, true)
    SetSwatchColor(
        experienceColorSwatches.xpColor,
        db and db.xpColor,
        OUS.defaults and OUS.defaults.xpColor or { r = 0.7, g = 0.4, b = 1.0 }
    )
    SetSwatchColor(
        experienceColorSwatches.xpTextColor,
        db and db.xpTextColor,
        OUS.defaults and OUS.defaults.xpTextColor or { r = 1.0, g = 1.0, b = 1.0 }
    )
    SetSwatchColor(
        experienceColorSwatches.restColor,
        db and db.restColor,
        OUS.defaults and OUS.defaults.restColor or { r = 0.3, g = 0.6, b = 1.0 }
    )
    SetSwatchColor(
        experienceColorSwatches.bgColor,
        db and db.bgColor,
        OUS.defaults and OUS.defaults.bgColor or { r = 0.07, g = 0.05, b = 0.1 }
    )

    if not experienceTemplateBox:HasFocus() then
        local defaultTemplate = OUS.defaults and OUS.defaults.xpTemplate or ""
        experienceTemplateBox:SetText(db and db.xpTemplate or defaultTemplate)
    end
end

RefreshReputation = function()
    for _, entry in ipairs(reputationCheckboxes) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    local db = GetXPBarDB()
    SetSwatchColor(
        reputationColorSwatches.repTextColor,
        db and db.repTextColor,
        OUS.defaults and OUS.defaults.repTextColor or { r = 1.0, g = 1.0, b = 1.0 }
    )
    for _, entry in ipairs(REPUTATION_STANDING_COLOR_ROWS) do
        SetSwatchColor(
            reputationColorSwatches[entry.key],
            db and db.repColors and db.repColors[entry.key],
            OUS.defaults and OUS.defaults.repColors and OUS.defaults.repColors[entry.key]
        )
    end

    if not reputationTemplateBox:HasFocus() then
        local defaultTemplate = OUS.defaults and OUS.defaults.repTemplate or ""
        reputationTemplateBox:SetText(db and db.repTemplate or defaultTemplate)
    end

    local currentModifier = db and db.repMenuMod or "CTRL"
    for value, button in pairs(reputationModifierButtons) do
        UpdateReputationModifierButton(button, value == currentModifier)
    end
end

Refresh = function()
    RefreshGlobal()
    RefreshExperience()
    RefreshReputation()
end

local function RefreshForOpen()
    ShowHub()
    RefreshGlobal()
    RefreshExperience()
    RefreshReputation()
end

C.RegisterPage("XPBar", page, RefreshForOpen)
