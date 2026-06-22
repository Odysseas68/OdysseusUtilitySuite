-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_FishingTracker.lua
-- Version : 2026.06.22
-- Desc    : OUS2 Fishing Tracker module settings page
-- ================================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
local delayControl
local opacityControl
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

local function GetFishingSettings()
    return OdysseusDB and OdysseusDB.fishingSettings
end

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

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconFishingTracker"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Fishing Tracker")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Track fishing activity and catches")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Module", -78)
CreateCheckboxRow(
    "Enable Fishing Tracker",
    "Enable or disable fishing activity tracking.",
    -104,
    GetModulesDB,
    "fishingTracker",
    function(newValue)
        if not newValue and OdysseusFishingMain then
            OdysseusFishingMain:Hide()
        end
    end
)

CreateSectionHeader("Behavior", -164)
CreateCheckboxRow(
    "Auto-close While Inactive",
    "Automatically close the tracker after the configured period without fishing.",
    -190,
    GetFishingSettings,
    "autoCloseInactive"
)
CreateCheckboxRow(
    "Auto-close While Mounted",
    "Automatically close the tracker while mounted or skyriding.",
    -238,
    GetFishingSettings,
    "autoCloseMounted"
)

CreateSectionHeader("Display", -300)
delayControl = CreateScaleRow(
    "Auto-close Delay",
    "Set the inactivity period before the Fishing Tracker closes.",
    -326,
    10,
    60,
    1,
    30,
    function(newValue)
        local db = GetFishingSettings()
        if db then
            db.autoCloseDelay = newValue
        end
    end
)

opacityControl = CreateScaleRow(
    "Frame Opacity",
    "Adjust the opacity of the Fishing Tracker windows.",
    -390,
    0.1,
    1.0,
    0.05,
    0.95,
    function(newValue)
        local db = GetFishingSettings()
        if not db then return end

        db.alpha = newValue
        if OUS.UpdateFishingAlpha then
            OUS.UpdateFishingAlpha()
        end
    end
)

CreateSectionHeader("Actions", -470)
CreateActionButton(
    "Show / Hide Tracker",
    "Show or hide the Fishing Tracker window.",
    -496,
    function()
        if OUS.ToggleFishingTracker then
            OUS.ToggleFishingTracker()
        end
    end
)

Refresh = function()
    for _, entry in ipairs(checkboxRows) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    local db = GetFishingSettings()
    delayControl:SetValue(db and db.autoCloseDelay or 30, true)
    opacityControl:SetValue(db and db.alpha or 0.95, true)
end

C.RegisterPage("FishingTracker", page, Refresh)
