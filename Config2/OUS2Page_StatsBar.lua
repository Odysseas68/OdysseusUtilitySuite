-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_StatsBar.lua
-- Version : 2026.07.03
-- Desc    : OUS2 Stats Bar module settings page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
local fontSizeControl
local tableWidthControl
local templateBox
local Refresh

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

local function GetStatsBarDB()
    return OdysseusDB and OdysseusDB.statsBar
end

local function GetStatsBarCharDB()
    return OdysseusCharDB and OdysseusCharDB.statsBar
end

local function UpdateDisplay()
    if OUS.StatsBar and OUS.StatsBar.UpdateDisplay then
        OUS.StatsBar.UpdateDisplay()
    end
end

local function UpdateTable()
    if OUS.StatsBar and OUS.StatsBar.UpdateTable then
        OUS.StatsBar.UpdateTable()
    end
end

local function ResetStatsBarDefaults()
    local charDB = GetStatsBarCharDB()
    local gdb = GetStatsBarDB()

    if charDB then
        charDB.enabled = true
        charDB.tableEnabled = false
        charDB.template = "{ilvl} | {spec}"
        charDB.x, charDB.y = 0, 0
        charDB.point, charDB.relPoint = "CENTER", "CENTER"
        charDB.tableX = 200
        charDB.tableY = 0
        charDB.tablePoint, charDB.tableRelPoint = "CENTER", "CENTER"
    end

    if gdb then
        gdb.fontSize = 12
        gdb.tableWidth = 150
        gdb.locked = false
        gdb.tableLocked = false
    end

    if OUS.StatsBar then
        if OUS.StatsBar.UpdateDisplay then
            OUS.StatsBar.UpdateDisplay()
        end
        if OUS.StatsBar.UpdateTable then
            OUS.StatsBar.UpdateTable()
        end
        if OUS.StatsBar.SetLocked then
            OUS.StatsBar.SetLocked(false)
        end
        if OUS.StatsBar.SetTableLocked then
            OUS.StatsBar.SetTableLocked(false)
        end
    end

    if Refresh then
        Refresh()
    end

    if OUS.LogDebug then
        OUS.LogDebug("StatsBar", "Settings restored to default.")
    end
end

StaticPopupDialogs["OUS2_CONFIRM_RESET_STATSBAR"] = {
    text = "Reset all Stats Bar settings to defaults? This cannot be undone.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = ResetStatsBarDefaults,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateCheckboxRow(labelText, helpText, yOffset, getDB, dbKey, onChanged)
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
        local db = getDB()
        if not db then return end

        local newValue = not db[dbKey]
        db[dbKey] = newValue
        if onChanged then
            onChanged(newValue)
        end
        Refresh()
    end)

    checkboxRows[#checkboxRows + 1] = {
        checkbox = checkbox,
        getDB = getDB,
        dbKey = dbKey,
    }
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

    return button
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

local function CreateTemplateRow(yOffset)
    local helpText = "Set the token-based text shown by the single-line Stats Bar."

    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(86)
    row:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("TOPLEFT", row, "TOPLEFT", T.Card.Padding, -9)
    label:SetText("Template")
    SetTextColor(label, T.Colors.text)

    templateBox = CreateFrame("EditBox", nil, row)
    templateBox:SetHeight(T.Scale.editH)
    templateBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -7)
    templateBox:SetPoint("TOPRIGHT", row, "TOPRIGHT", -T.Card.Padding, -30)
    templateBox:SetAutoFocus(false)
    templateBox:SetFontObject(_G[T.Fonts.highlight])
    templateBox:SetMaxLetters(200)
    templateBox:SetTextInsets(12, 12, 0, 0)
    templateBox:SetTextColor(
        T.Colors.text[1],
        T.Colors.text[2],
        T.Colors.text[3],
        T.Colors.text[4]
    )

    AddSlicedEditBoxBackground(templateBox)

    local tokenHint = row:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    tokenHint:SetPoint("TOPLEFT", templateBox, "BOTTOMLEFT", 0, -6)
    tokenHint:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    tokenHint:SetJustifyH("LEFT")
    tokenHint:SetText("{ilvl} {spec} {crit} {haste} {mast} {vers} {int} {agi} {str}")
    SetTextColor(tokenHint, T.Colors.textDim)

    local function CommitTemplate()
        local db = GetStatsBarCharDB()
        if db then
            db.template = templateBox:GetText()
            UpdateDisplay()
        end
        templateBox:ClearFocus()
    end

    templateBox:SetScript("OnEnterPressed", CommitTemplate)
    templateBox:SetScript("OnEditFocusLost", CommitTemplate)
    templateBox:SetScript("OnEscapePressed", function()
        local db = GetStatsBarCharDB()
        templateBox:SetText(db and db.template or "{ilvl} | {spec}")
        templateBox:ClearFocus()
    end)

    AttachControlHelp(row, background, helpText)
    AttachControlHelp(templateBox, background, helpText)
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconStatsBar"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Stats Bar")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Character stat display and table view")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Module", -78)
CreateCheckboxRow(
    "Enable Stats Bar Module",
    "Enable or disable the Stats Bar module.",
    -104,
    GetModulesDB,
    "statsBar",
    function()
        UpdateDisplay()
        UpdateTable()
    end
)

CreateSectionHeader("Single-Line Bar", -164)
CreateCheckboxRow(
    "Lock Single-Line Position",
    "Lock the single-line Stats Bar in its current position.",
    -190,
    GetStatsBarDB,
    "locked",
    function(newValue)
        if OUS.StatsBar and OUS.StatsBar.SetLocked then
            OUS.StatsBar.SetLocked(newValue)
        end
    end
)

fontSizeControl = CreateScaleRow(
    "Font Size",
    "Adjust the font size used by both Stats Bar display modes.",
    -238,
    8,
    24,
    1,
    12,
    function(newValue)
        local db = GetStatsBarDB()
        if not db then return end

        db.fontSize = newValue
        UpdateDisplay()
        UpdateTable()
    end
)

CreateTemplateRow(-306)

CreateSectionHeader("Table View", -412)
CreateCheckboxRow(
    "Enable Table View",
    "Show the vertical table instead of the single-line Stats Bar.",
    -438,
    GetStatsBarCharDB,
    "tableEnabled",
    function()
        UpdateDisplay()
        UpdateTable()
    end
)
CreateCheckboxRow(
    "Lock Table Position",
    "Lock the Stats Bar table in its current position.",
    -486,
    GetStatsBarDB,
    "tableLocked",
    function(newValue)
        if OUS.StatsBar and OUS.StatsBar.SetTableLocked then
            OUS.StatsBar.SetTableLocked(newValue)
        end
    end
)

tableWidthControl = CreateScaleRow(
    "Table Width",
    "Adjust the width of the Stats Bar table.",
    -534,
    100,
    300,
    5,
    150,
    function(newValue)
        local db = GetStatsBarDB()
        if not db then return end

        db.tableWidth = newValue
        UpdateTable()
    end
)

CreateSectionHeader("Actions", -612)
CreateActionButton(
    "Reset Defaults",
    "Reset only Stats Bar settings, positions, locks, table mode, font size, width, and template text.",
    -638,
    function()
        StaticPopup_Show("OUS2_CONFIRM_RESET_STATSBAR")
    end
)

Refresh = function()
    for _, entry in ipairs(checkboxRows) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    local db = GetStatsBarDB()
    fontSizeControl:SetValue(db and db.fontSize or 12, true)
    tableWidthControl:SetValue(db and db.tableWidth or 150, true)

    if not templateBox:HasFocus() then
        local charDB = GetStatsBarCharDB()
        templateBox:SetText(charDB and charDB.template or "{ilvl} | {spec}")
    end
end

C.RegisterPage("StatsBar", page, Refresh)
