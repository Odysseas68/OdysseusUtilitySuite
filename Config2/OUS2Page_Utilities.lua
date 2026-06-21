-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Utilities.lua
-- Version : 2026.06.21
-- Desc    : OUS2 Utilities module settings page
-- ================================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
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

local function CreateCheckboxRow(labelText, helpText, yOffset, getDB, dbKey)
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
        db[dbKey] = not db[dbKey]
        Refresh()
    end)

    checkboxRows[#checkboxRows + 1] = {
        checkbox = checkbox,
        getDB = getDB,
        dbKey = dbKey,
    }
end

local function GetModulesDB()
    return OdysseusDB and OdysseusDB.modules
end

local function GetUtilitiesDB()
    return OdysseusDB and OdysseusDB.utilities
end

local function GetJunkSellDB()
    local utilities = GetUtilitiesDB()
    return utilities and utilities.junkSell
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconUtilities"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Utilities")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Repair, junk selling, and rare announcement tools")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Module", -78)
CreateCheckboxRow(
    "Enable Utilities",
    "Enable or disable the Utilities module.",
    -104,
    GetModulesDB,
    "utilities"
)

CreateSectionHeader("Auto Repair", -164)
CreateCheckboxRow(
    "Enable Auto Repair",
    "Automatically repair damaged equipment when visiting a repair merchant.",
    -190,
    GetUtilitiesDB,
    "repairEnabled"
)
CreateCheckboxRow(
    "Use Guild Repair First",
    "Use available guild funds before personal funds when repairing.",
    -238,
    GetUtilitiesDB,
    "guildRepair"
)
CreateCheckboxRow(
    "Announce Repair Cost",
    "Report the repair cost and funding source in chat.",
    -286,
    GetUtilitiesDB,
    "announceRepair"
)

CreateSectionHeader("Junk Seller", -348)
CreateCheckboxRow(
    "Enable Junk Seller",
    "Enable automatic selling of eligible junk items at merchants.",
    -374,
    GetJunkSellDB,
    "enabled"
)
CreateCheckboxRow(
    "Require Shift to Sell",
    "Require the Shift key to be held before junk selling begins.",
    -422,
    GetJunkSellDB,
    "requireShift"
)
CreateCheckboxRow(
    "Announce Junk Sales",
    "Report completed junk sales and their value in chat.",
    -470,
    GetJunkSellDB,
    "announceJunk"
)
CreateCheckboxRow(
    "Limit Sales to 12 Items",
    "Sell junk in batches of 12 items and require confirmation for the next batch.",
    -518,
    GetJunkSellDB,
    "limitTo12"
)

CreateSectionHeader("Rare Announcer", -580)
CreateCheckboxRow(
    "Enable Rare Announcer",
    "Enable rare target announcements and waypoint links.",
    -606,
    GetUtilitiesDB,
    "rareEnabled"
)

Refresh = function()
    for _, entry in ipairs(checkboxRows) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end
end

C.RegisterPage("Utilities", page, Refresh)
