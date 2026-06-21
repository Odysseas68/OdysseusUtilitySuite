-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Openables.lua
-- Version : 2026.06.21
-- Desc    : OUS2 Openables module settings page
-- ================================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
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

local function CreateCheckboxRow(labelText, helpText, yOffset, getDB, dbKey, onClick)
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
        if onClick then
            onClick()
        else
            local db = getDB()
            if not db then return end
            db[dbKey] = not db[dbKey]
            if OUS.Openables and OUS.Openables.UpdateDisplay then
                OUS.Openables.UpdateDisplay()
            end
        end
        Refresh()
    end)

    checkboxRows[#checkboxRows + 1] = {
        checkbox = checkbox,
        getDB = getDB,
        dbKey = dbKey,
    }
end

local function CreateActionButton(labelText, command, helpText, yOffset)
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
    button:SetScript("OnClick", function()
        if OUS.Openables and OUS.Openables.SlashHandler then
            OUS.Openables.SlashHandler(command)
        end
    end)
end

local function GetModulesDB()
    return OdysseusDB and OdysseusDB.modules
end

local function GetOpenablesDB()
    return OdysseusDB and OdysseusDB.openables
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconOpenables"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Openables")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Container, cache, recipe, pet, mount, and token helper")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Settings", -78)
CreateCheckboxRow(
    "Enable Openables",
    "Enable or disable the Openables module.",
    -104,
    GetModulesDB,
    "openables"
)
CreateCheckboxRow(
    "Auto Open",
    "Automatically use the currently detected openable item when it is safe to do so.",
    -152,
    GetOpenablesDB,
    "autoOpen"
)
CreateCheckboxRow(
    "Lock Button",
    "Lock the Openables button in place and hide its drag handle.",
    -200,
    GetOpenablesDB,
    "locked",
    function()
        local db = GetOpenablesDB()
        if not db or not (OUS.Openables and OUS.Openables.SlashHandler) then return end
        OUS.Openables.SlashHandler(db.locked and "unlock" or "lock")
    end
)

CreateSectionHeader("Button Position", -266)

local scaleRow = CreateFrame("Frame", nil, page)
scaleRow:SetHeight(60)
scaleRow:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -292)
scaleRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -292)
scaleRow:EnableMouse(true)

local scaleBackground = scaleRow:CreateTexture(nil, "BACKGROUND")
scaleBackground:SetTexture(T.Tex("CardNormal"))
scaleBackground:SetAllPoints()

local scaleLabel = scaleRow:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
scaleLabel:SetPoint("LEFT", scaleRow, "LEFT", T.Card.Padding, 0)
scaleLabel:SetText("Button Scale")
SetTextColor(scaleLabel, T.Colors.text)

scaleControl = C.CreateScaleControl(
    scaleRow,
    T.Scale.minValue,
    T.Scale.maxValue,
    T.Scale.step,
    1.0,
    function(newValue)
        local db = GetOpenablesDB()
        if not db then return end

        db.scale = newValue
        if OUS.Openables and OUS.Openables.ApplyPosition then
            OUS.Openables.ApplyPosition()
        end
    end
)
scaleControl:SetPoint("RIGHT", scaleRow, "RIGHT", -T.Card.Padding, 0)

scaleRow:SetScript("OnEnter", function()
    scaleBackground:SetTexture(T.Tex("CardHover"))
    C.SetHelpText("Adjust the displayed size of the Openables button.")
end)
scaleRow:SetScript("OnLeave", function()
    scaleBackground:SetTexture(T.Tex("CardNormal"))
    C.ClearHelpText()
end)

-- TODO: Open management frames above OUS2 or anchor them beside it while OUS2 is shown.
CreateSectionHeader("Management", -374)
CreateActionButton(
    "Open Blacklist",
    "list",
    "Open the list of items excluded from Openables.",
    -400
)
CreateActionButton(
    "Open Custom List",
    "clist",
    "Open the custom Openables item list.",
    -442
)
CreateActionButton(
    "Mass Add Items",
    "madd",
    "Open the mass-add tool for custom Openables items.",
    -484
)
CreateActionButton(
    "Show Status",
    "status",
    "Print the current Openables status and item counts in chat.",
    -526
)

Refresh = function()
    for _, entry in ipairs(checkboxRows) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    local db = GetOpenablesDB()
    local scale = db and tonumber(db.scale) or 1.0
    scaleControl:SetValue(scale, true)
end

C.RegisterPage("Openables", page, Refresh)
