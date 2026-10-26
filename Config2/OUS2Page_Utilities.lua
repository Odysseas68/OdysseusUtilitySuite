-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Utilities.lua
-- Version : 2026.10.26
-- Desc    : OUS2 Utilities module settings page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local checkboxRows = {}
local junkBlacklistActionLabel
local junkAnimationLabel
local nativeGoblinControl
local nativeGoblinSizeLabel
local nativePreview
local junkBlacklistFrameHooked = false
local junkBlacklistPopupHooked = false
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
    row:SetHeight(36)
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
        if onClick then onClick() end
        Refresh()
    end)

    checkboxRows[#checkboxRows + 1] = {
        checkbox = checkbox,
        getDB = getDB,
        dbKey = dbKey,
    }
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
    button:SetScript("OnClick", function()
        if onClick then
            onClick()
        end
        Refresh()
    end)

    return label
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

local function CountEntries(tbl)
    local count = 0
    if tbl then
        for _ in pairs(tbl) do
            count = count + 1
        end
    end
    return count
end

local function RefreshJunkBlacklistCount()
    if junkBlacklistActionLabel then
        local db = GetJunkSellDB()
        junkBlacklistActionLabel:SetText("Manage Blacklist (" .. CountEntries(db and db.blacklist) .. ")")
    end
end

local function RaiseJunkBlacklistFrame()
    local container = _G["OUSJunkBLContainer"]
    if not container then return end

    container:SetFrameStrata("FULLSCREEN_DIALOG")
    container:SetFrameLevel(100)

    local addFrame = _G["OUSJunkBLAdd"]
    if addFrame then
        addFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        addFrame:SetFrameLevel(101)
    end

    local listFrame = _G["OUSJunkBLList"]
    if listFrame then
        listFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        listFrame:SetFrameLevel(101)
    end

    if not junkBlacklistFrameHooked then
        container:HookScript("OnHide", function()
            RefreshJunkBlacklistCount()
        end)
        junkBlacklistFrameHooked = true
    end
end

local function HookJunkBlacklistPopup()
    if junkBlacklistPopupHooked then return end

    for i = 1, 4 do
        local dialog = _G["StaticPopup" .. i]
        if dialog then
            dialog:HookScript("OnShow", function(self)
                if self.which == "OUS_JUNK_WIPE_BL" then
                    self:SetFrameStrata("FULLSCREEN_DIALOG")
                    self:SetFrameLevel(110)
                end
            end)
        end
    end
    junkBlacklistPopupHooked = true
end

local function OpenJunkBlacklistManager()
    if not OUS.ToggleJunkBlacklist then return end

    OUS.ToggleJunkBlacklist()
    HookJunkBlacklistPopup()
    C_Timer.After(0, RaiseJunkBlacklistFrame)
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
    "utilities",
    OUS.ApplyUtilitiesModuleSetting
)

CreateSectionHeader("Auto Repair", -150)
CreateCheckboxRow(
    "Enable Auto Repair",
    "Automatically repair damaged equipment when visiting a repair merchant.",
    -176,
    GetUtilitiesDB,
    "repairEnabled"
)
CreateCheckboxRow(
    "Use Guild Repair First",
    "Use available guild funds before personal funds when repairing.",
    -216,
    GetUtilitiesDB,
    "guildRepair"
)
CreateCheckboxRow(
    "Announce Repair Cost",
    "Report Own-funds repair cost or the quoted bill for a Guild-first repair request without guessing its funding.",
    -256,
    GetUtilitiesDB,
    "announceRepair"
)

CreateSectionHeader("Junk Seller", -306)
CreateCheckboxRow(
    "Enable Junk Seller",
    "Enable automatic selling of eligible junk items at merchants.",
    -332,
    GetJunkSellDB,
    "enabled",
    OUS.ApplyJunkSellSettings
)
CreateCheckboxRow(
    "Require Shift to Sell",
    "Require the Shift key to be held before junk selling begins.",
    -372,
    GetJunkSellDB,
    "requireShift",
    OUS.ApplyJunkSellSettings
)
CreateCheckboxRow(
    "Announce Junk Sales",
    "Report completed junk sales and their value in chat.",
    -412,
    GetJunkSellDB,
    "announceJunk"
)
CreateCheckboxRow(
    "Detailed Sale Report",
    "Report each sold junk stack in chat with its clickable item link, quantity, and total value.",
    -452,
    GetJunkSellDB,
    "detailedSaleReport"
)
CreateCheckboxRow(
    "Limit Sales to 12 Items",
    "Sell junk in batches of 12 items and require confirmation for the next batch.",
    -492,
    GetJunkSellDB,
    "limitTo12",
    OUS.ApplyJunkSellSettings
)
junkAnimationLabel = CreateActionButton(
    "Junk Seller Animation",
    "Choose the 2D Goblin Counting Gold (default) or Spinning Coin, used when 3D is off or unavailable. Changes artwork only; does not start or stop junk selling.",
    -532,
    function()
        local db = GetJunkSellDB()
        if not db then return end
        db.animation = db.animation == "coin" and "goblin" or "coin"
        OUS.UpdateJunkSellAnimation()
    end
)
junkBlacklistActionLabel = CreateActionButton(
    "Manage Blacklist",
    "Open the existing Junk Seller blacklist manager to add, remove, or wipe blacklisted items.",
    -532,
    OpenJunkBlacklistManager
)
junkAnimationLabel:GetParent():SetPoint("TOPRIGHT", page, "TOP", -4, -532)
junkBlacklistActionLabel:GetParent():SetPoint("TOPLEFT", page, "TOP", 4, -532)

CreateCheckboxRow(
    "Enable 3D Goblin",
    "Use the native Goblin and Merchant Counter artwork at the selected size. Off preserves your selected 2D animation. Cosmetic only.",
    -572,
    GetJunkSellDB,
    "nativeGoblin",
    OUS.ApplyJunkSellVisualSettings
)

local distanceRow = CreateFrame("Frame", nil, page)
distanceRow:SetHeight(56)
distanceRow:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -612)
distanceRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -612)
distanceRow:EnableMouse(true)
local distanceBackground = distanceRow:CreateTexture(nil, "BACKGROUND")
distanceBackground:SetTexture(T.Tex("CardNormal"))
distanceBackground:SetAllPoints()
local distanceLabel = distanceRow:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
distanceLabel:SetPoint("LEFT", distanceRow, "LEFT", T.Card.Padding, 0)
distanceLabel:SetText("3D Goblin Zoom")
SetTextColor(distanceLabel, T.Colors.text)
nativeGoblinControl = C.CreateScaleControl(distanceRow, 1, 2, 0.1, 1.2, function(value)
    local db = GetJunkSellDB()
    if not db then return end
    db.nativeGoblinDistance = value
    OUS.ApplyJunkSellVisualSettings()
    if nativePreview then nativePreview:SetDistance(value) end
end)
nativeGoblinControl:SetPoint("RIGHT", distanceRow, "RIGHT", -T.Card.Padding, 0)
distanceRow:SetScript("OnEnter", function()
    C.SetHelpText("Camera distance 1.0-2.0, default 1.2. Increasing the value moves the Goblin farther away. Updates safely outside combat.")
end)
distanceRow:SetScript("OnLeave", C.ClearHelpText)

local sidebar = CreateFrame("Frame", nil, C.sidebarContainer)
sidebar:SetAllPoints()
sidebar:Hide()
local previewTitle = sidebar:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
previewTitle:SetPoint("TOP", sidebar, "TOP", 0, -T.Card.Padding)
previewTitle:SetText("3D Goblin Preview")
SetTextColor(previewTitle, T.Colors.header)
local previewAnchor = CreateFrame("Frame", nil, sidebar)
previewAnchor:SetSize(96, 96)
previewAnchor:SetPoint("TOP", previewTitle, "BOTTOM", 0, -T.Card.Padding)
previewAnchor:EnableMouse(false)
local previewStatus = sidebar:CreateFontString(nil, "OVERLAY", T.Fonts.small)
previewStatus:SetPoint("TOPLEFT", previewAnchor, "BOTTOMLEFT", -T.Card.Padding, -T.Card.Padding)
previewStatus:SetPoint("RIGHT", sidebar, "RIGHT", -T.Card.Padding, 0)
previewStatus:SetJustifyH("LEFT")
previewStatus:SetText("Play Test Animation loads a cosmetic preview. No merchant or items required.")
SetTextColor(previewStatus, T.Colors.textDim)

-- The sidebar preview has its own model and can never enter merchant-selling state.
local function PlayNativePreview()
    if InCombatLockdown() then previewStatus:SetText("Preview unavailable during combat. Try again afterwards."); return end
    if not nativePreview then
        local reason
        nativePreview, reason = OUS.CreateJunkGoblinRenderer(previewAnchor, false, function(message)
            previewStatus:SetText(message)
        end)
        if not nativePreview then previewStatus:SetText(reason); return end
        nativePreview:SetPoint("CENTER", previewAnchor, "CENTER")
    end
    nativePreview.failed = false
    nativePreview:Show()
    local db = GetJunkSellDB()
    nativePreview:SetViewportSize(db and db.nativeGoblinSize)
    nativePreview:SetDistance(db and db.nativeGoblinDistance)
    nativePreview:SetActive(true)
end
nativeGoblinSizeLabel = CreateActionButton(
    "3D Goblin Size",
    "Click to cycle 96x96 (Large), 64x64 (Medium), and 32x32 (Small). Resizes the native viewport and counter without changing camera distance or selling state. Combat changes apply at the next safe refresh.",
    -678,
    function()
        local db = GetJunkSellDB()
        if not db then return end
        db.nativeGoblinSize = db.nativeGoblinSize == 96 and 64 or (db.nativeGoblinSize == 64 and 32 or 96)
        OUS.ApplyJunkSellVisualSettings()
        if nativePreview then nativePreview:SetViewportSize(db.nativeGoblinSize) end
    end
)
local nativeTestLabel = CreateActionButton(
    "Play Test Animation",
    "Play Loot animation 50 once in the sidebar preview, then restore natural idle. Works with 3D mode off; never sells items.",
    -678,
    PlayNativePreview
)
nativeGoblinSizeLabel:GetParent():SetPoint("TOPRIGHT", page, "TOP", -4, -678)
nativeTestLabel:GetParent():SetPoint("TOPLEFT", page, "TOP", 4, -678)

CreateSectionHeader("Rare Announcer", -728)
CreateCheckboxRow(
    "Enable Rare Announcer",
    "Enable rare target announcements and waypoint links.",
    -754,
    GetUtilitiesDB,
    "rareEnabled"
)

CreateSectionHeader("Extra Action Button", -804)
CreateCheckboxRow(
    "Hide Blizzard Artwork",
    "Hides the decorative Blizzard artwork around Extra Action and Zone Ability buttons while preserving the buttons, icons, cooldowns, clicks, positioning, and Edit Mode behavior.",
    -830,
    GetUtilitiesDB,
    "hideExtraActionArtwork",
    OUS.ApplyExtraActionArtworkSetting
)

Refresh = function()
    for _, entry in ipairs(checkboxRows) do
        local db = entry.getDB()
        local checked = db and db[entry.dbKey] == true
        entry.checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end
    RefreshJunkBlacklistCount()
    local db = GetJunkSellDB()
    junkAnimationLabel:SetText("Junk Seller Animation\n" .. (db and db.animation == "coin" and "Spinning Coin" or "Goblin Counting Gold"))
    nativeGoblinControl:SetValue(db and db.nativeGoblinDistance or 1.2, true)
    local size = db and db.nativeGoblinSize
    size = (size == 32 or size == 64) and size or 96
    local sizeName = size == 32 and "Small" or (size == 64 and "Medium" or "Large")
    nativeGoblinSizeLabel:SetText("3D Goblin Size\n" .. size .. "x" .. size .. " (" .. sizeName .. ")")
    if nativePreview then
        nativePreview:SetViewportSize(size)
        nativePreview:SetDistance(db and db.nativeGoblinDistance)
    end
end

-- Match the existing page-owned content-height lifecycle as these controls extend the page.
local previousContentHeight
page:HookScript("OnShow", function()
    previousContentHeight = C.pageContainer:GetHeight()
    C.pageContainer:SetHeight(math.max(previousContentHeight, 890))
end)
page:HookScript("OnHide", function()
    if nativePreview then nativePreview:Hide() end
    if previousContentHeight then C.pageContainer:SetHeight(previousContentHeight) end
end)
sidebar:HookScript("OnHide", function()
    if nativePreview then nativePreview:Hide() end
end)

C.RegisterPage("Utilities", page, Refresh, sidebar)
