-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_AutoRemount.lua
-- Version : 2026.06.22
-- Desc    : OUS2 Auto Remount module settings page
-- ================================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
local delayControl
local characterMountText
local accountMountText
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

local function GetAutoRemountDB()
    return OdysseusDB and OdysseusDB.autoRemount
end

local function GetAutoRemountCharDB()
    return OdysseusCharDB and OdysseusCharDB.autoRemountChar
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
        local db = GetAutoRemountDB()
        if not db then return end

        db[dbKey] = not db[dbKey]
        Refresh()
    end)

    checkboxRows[#checkboxRows + 1] = {
        checkbox = checkbox,
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

local function CreateDelayRow(yOffset)
    local helpText = "Set how long Auto Remount waits after gathering before attempting to remount."

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
    label:SetText("Remount Delay")
    SetTextColor(label, T.Colors.text)

    local control = C.CreateScaleControl(
        row,
        0.1,
        5.0,
        0.1,
        0.5,
        function(newValue)
            local db = GetAutoRemountDB()
            if db then
                db.delay = newValue
            end
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

local function CreateStatusRow(labelText, helpText, yOffset)
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

    local value = row:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
    value:SetPoint("LEFT", label, "RIGHT", 12, 0)
    value:SetPoint("RIGHT", row, "RIGHT", -T.Card.Padding, 0)
    value:SetJustifyH("RIGHT")
    SetTextColor(value, T.Colors.textDim)

    AttachControlHelp(row, background, helpText)
    return value
end

local function GetMountDisplayText(mountID)
    if not mountID then
        return "Not selected"
    end

    if C_MountJournal and C_MountJournal.GetMountInfoByID then
        local name = C_MountJournal.GetMountInfoByID(mountID)
        if name then
            return name
        end
    end

    return "Unknown mount (" .. tostring(mountID) .. ")"
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconAutoRemount"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Auto Remount")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Gathering remount helper")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Behavior", -78)
CreateCheckboxRow(
    "Enable Auto Remount",
    "Automatically remount after supported gathering actions.",
    -104,
    "enabled"
)
CreateCheckboxRow(
    "Skip Druid Travel Form",
    "Do not remount Druids while any shapeshift form is active.",
    -152,
    "skipDruid"
)
CreateCheckboxRow(
    "Silent Mount Errors",
    "Suppress mount error messages reported by Auto Remount.",
    -200,
    "silent"
)

delayControl = CreateDelayRow(-248)

CreateSectionHeader("Mount Status", -328)
characterMountText = CreateStatusRow(
    "Character Mount",
    "Shows the mount selected specifically for this character.",
    -354
)
accountMountText = CreateStatusRow(
    "Account Mount",
    "Shows the account-wide mount used when no character mount is selected.",
    -410
)

Refresh = function()
    local db = GetAutoRemountDB()
    for _, entry in ipairs(checkboxRows) do
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    delayControl:SetValue(db and db.delay or 0.5, true)

    local charDB = GetAutoRemountCharDB()
    characterMountText:SetText(GetMountDisplayText(charDB and charDB.mountID))
    accountMountText:SetText(GetMountDisplayText(db and db.accountMountID))
end

C.RegisterPage("AutoRemount", page, Refresh)
