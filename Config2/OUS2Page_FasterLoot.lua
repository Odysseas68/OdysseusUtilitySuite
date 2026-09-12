-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_FasterLoot.lua
-- Version : 2026.06.22
-- Desc    : OUS2 Faster Loot informational page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local enableCheckbox
local statusText
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

local function CreateInfoCard(text, helpText, yOffset, height, fontObject, color)
    local card = CreateFrame("Frame", nil, page)
    card:SetHeight(height)
    card:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
    card:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    card:EnableMouse(true)

    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local body = card:CreateFontString(nil, "OVERLAY", fontObject or T.Fonts.normal)
    body:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -T.Card.Padding)
    body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -T.Card.Padding, T.Card.Padding)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("MIDDLE")
    body:SetWordWrap(true)
    body:SetText(text)
    SetTextColor(body, color or T.Colors.text)

    card:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    card:SetScript("OnLeave", function()
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)

    return body
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
    row:SetScript("OnClick", onClick)

    return checkbox
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconFasterLoot"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Faster Loot")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Automatic loot-window optimization")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Status", -78)
enableCheckbox = CreateCheckboxRow(
    "Enable Faster Loot",
    "Enable or disable Faster Loot immediately through its cleanup-aware runtime setter.",
    -104,
    function()
        local enabled = OdysseusDB and OdysseusDB.modules and OdysseusDB.modules.fasterLoot == true
        if OUS.SetFasterLootEnabled then
            OUS.SetFasterLootEnabled(not enabled)
        end
        Refresh()
    end
)

statusText = CreateInfoCard(
    "",
    "Shows the current Faster Loot module state.",
    -156,
    48
)
CreateInfoCard(
    "Disabling cancels active fast-loot processing and restores Blizzard's normal loot window behavior.",
    "The event and hook infrastructure remains installed and safely gated by the module setting.",
    -208,
    62,
    T.Fonts.small,
    T.Colors.textDim
)

CreateSectionHeader("How It Works", -288)
CreateInfoCard(
    "- Faster Loot accelerates normal loot processing.\n"
        .. "- It respects manual-loot modifier and Auto Loot CVar behavior.\n"
        .. "- It yields when Fishing Tracker needs normal loot visibility.\n"
        .. "- It reveals the normal loot window for locked loot, group rolls, full bags, or max-count cases.",
    "Summarizes Faster Loot behavior and the conditions that restore the normal loot window.",
    -314,
    112,
    T.Fonts.small
)

CreateSectionHeader("Future Settings", -450)
CreateInfoCard(
    "- Loot rules are planned for a future version.",
    "Future controls should continue using explicit engine APIs that preserve active loot cleanup.",
    -476,
    76,
    T.Fonts.small,
    T.Colors.textDim
)

Refresh = function()
    local enabled = OdysseusDB
        and OdysseusDB.modules
        and OdysseusDB.modules.fasterLoot == true

    enableCheckbox:SetTexture(T.Tex(enabled and "CheckboxOn" or "CheckboxOff"))
    statusText:SetText("Faster Loot Status: " .. (enabled and "Enabled" or "Disabled"))
    SetTextColor(statusText, enabled and T.Colors.enabled or T.Colors.disabled)
end

C.RegisterPage("FasterLoot", page, Refresh)
