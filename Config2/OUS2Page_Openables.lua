-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Openables.lua
-- Version : 2026.07.03
-- Desc    : OUS2 Openables module settings page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2
local C_Item = _G.C_Item

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
local scaleControl
local blacklistActionLabel
local customActionLabel
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

local function RaiseFrame(frameName)
    local frame = _G[frameName]
    if frame then
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetFrameLevel(90)
        if frame.Raise then
            frame:Raise()
        end
    end
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
        if type(command) == "function" then
            command()
        elseif OUS.Openables and OUS.Openables.SlashHandler then
            OUS.Openables.SlashHandler(command)
            if command == "list" then
                C_Timer.After(0, function() RaiseFrame("OdysseusOpenablesListFrame") end)
            elseif command == "clist" then
                C_Timer.After(0, function() RaiseFrame("OdysseusOpenablesCustomListFrame") end)
            elseif command == "madd" then
                C_Timer.After(0, function() RaiseFrame("OdysseusOpenablesMaddFrame") end)
            end
        end
    end)

    return label
end

local function GetModulesDB()
    return OdysseusDB and OdysseusDB.modules
end

local function GetOpenablesDB()
    return OdysseusDB and OdysseusDB.openables
end

local function CountEntries(tbl)
    local count = 0
    if tbl then
        for _ in pairs(tbl) do
            count = count + 1
        end
    end
    return count
end

local function RefreshCounts()
    local db = GetOpenablesDB()
    local blacklistCount = CountEntries(db and db.blacklist)
    local customCount = CountEntries(db and db.customItems)

    if blacklistActionLabel then
        blacklistActionLabel:SetText("Open Blacklist (" .. blacklistCount .. ")")
    end
    if customActionLabel then
        customActionLabel:SetText("Open Custom List (" .. customCount .. ")")
    end
end

local function RefreshOpenables()
    if OUS.Openables and OUS.Openables.UpdateDisplay then
        OUS.Openables.UpdateDisplay()
    end
    RefreshCounts()
    if Refresh then
        Refresh()
    end
end

local function ResetOpenablesPosition()
    local db = GetOpenablesDB()
    if not db then return end

    db.x, db.y = 300, 0
    db.point, db.relPoint = "CENTER", "CENTER"

    if OUS.Openables and OUS.Openables.ApplyPosition then
        OUS.Openables.ApplyPosition()
    else
        local container = _G["OdysseusOpenablesContainer"]
        if container then
            container:ClearAllPoints()
            container:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
        end
    end
end

local function BuildCustomItemsExport()
    local db = GetOpenablesDB()
    if not db or not db.customItems or not next(db.customItems) then
        return "-- Custom list is empty."
    end

    local lines = {}
    for itemID, qty in pairs(db.customItems) do
        local name = C_Item.GetItemNameByID(itemID) or "Unknown"
        table.insert(lines, string.format("    [%d] = %d,   -- %s", itemID, qty, name))
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

local function OpenCustomItemsExport()
    if C.ShowCopyTextDialog then
        C.ShowCopyTextDialog("Openables - Custom Items Export", BuildCustomItemsExport())
        RaiseFrame("OUS2CopyTextDialog")
    end
end

local function WipeCustomItems()
    local db = GetOpenablesDB()
    if not db then return end

    db.customItems = {}
    print("|cFF00CCFFOdysseus Openables:|r Custom items wiped.")
    RefreshOpenables()
end

local function ClearAllBlacklist()
    local db = GetOpenablesDB()
    if not db then return end

    db.blacklist = {}
    print("|cFF00CCFFOdysseus Openables:|r Permanent blacklist cleared.")
    RefreshOpenables()
end

local function ShowPopupOnTop(popupKey)
    local dialog = StaticPopup_Show(popupKey)
    if dialog then
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetFrameLevel(100)
    end
end

StaticPopupDialogs["OUS2_CONFIRM_WIPE_OP_CUSTOM"] = {
    text = "Wipe ALL custom Openables items? This cannot be undone.",
    button1 = "Yes, Wipe",
    button2 = "Cancel",
    OnAccept = WipeCustomItems,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["OUS2_CONFIRM_CLEAR_OP_BLACKLIST"] = {
    text = "Clear the entire Openables permanent blacklist? This cannot be undone.",
    button1 = "Yes, Clear",
    button2 = "Cancel",
    OnAccept = ClearAllBlacklist,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

CreateActionButton(
    "Reset Button Position",
    ResetOpenablesPosition,
    "Reset the Openables button to its default saved position.",
    -374
)

CreateSectionHeader("Management", -424)
blacklistActionLabel = CreateActionButton(
    "Open Blacklist",
    "list",
    "Open the list of items excluded from Openables.",
    -450
)
CreateActionButton(
    "Clear All Blacklist",
    function()
        ShowPopupOnTop("OUS2_CONFIRM_CLEAR_OP_BLACKLIST")
    end,
    "Clear only the permanent Openables blacklist. Custom items and built-in items are preserved.",
    -492
)
customActionLabel = CreateActionButton(
    "Open Custom List",
    "clist",
    "Open the custom Openables item list.",
    -534
)
CreateActionButton(
    "Mass Add Items",
    "madd",
    "Open the mass-add tool for custom Openables items.",
    -576
)
CreateActionButton(
    "Export DB",
    OpenCustomItemsExport,
    "Open a copyable export of the custom Openables item database.",
    -618
)
CreateActionButton(
    "Wipe Custom DB",
    function()
        ShowPopupOnTop("OUS2_CONFIRM_WIPE_OP_CUSTOM")
    end,
    "Wipe only custom Openables items. Built-in items and blacklist entries are preserved.",
    -660
)
CreateActionButton(
    "Show Status",
    "status",
    "Print the current Openables status and item counts in chat.",
    -702
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
    RefreshCounts()
end

C.RegisterPage("Openables", page, Refresh)
