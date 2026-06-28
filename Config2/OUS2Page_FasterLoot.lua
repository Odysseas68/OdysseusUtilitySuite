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

local statusText

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
statusText = CreateInfoCard(
    "",
    "Shows the current Faster Loot module state without changing it.",
    -104,
    48
)
CreateInfoCard(
    "The module flag is read-only here until Faster Loot has a cleanup-aware public setter.",
    "Live enable and disable controls require the engine to safely stop active loot processing.",
    -156,
    62,
    T.Fonts.small,
    T.Colors.textDim
)

CreateSectionHeader("How It Works", -236)
CreateInfoCard(
    "- Faster Loot accelerates normal loot processing.\n"
        .. "- It respects manual-loot modifier and Auto Loot CVar behavior.\n"
        .. "- It yields when Fishing Tracker needs normal loot visibility.\n"
        .. "- It reveals the normal loot window for locked loot, group rolls, full bags, or max-count cases.",
    "Summarizes Faster Loot behavior and the conditions that restore the normal loot window.",
    -262,
    112,
    T.Fonts.small
)

CreateSectionHeader("Future Settings", -398)
CreateInfoCard(
    "- Loot rules are planned for a future version.\n"
        .. "- Enable or disable from OUS2 requires a safe public cleanup path first.",
    "Future controls depend on explicit engine APIs that preserve active loot cleanup.",
    -424,
    76,
    T.Fonts.small,
    T.Colors.textDim
)

local function Refresh()
    local enabled = OdysseusDB
        and OdysseusDB.modules
        and OdysseusDB.modules.fasterLoot == true

    statusText:SetText("Faster Loot Status: " .. (enabled and "Enabled" or "Disabled"))
    SetTextColor(statusText, enabled and T.Colors.enabled or T.Colors.disabled)
end

C.RegisterPage("FasterLoot", page, Refresh)
