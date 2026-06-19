-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_General.lua
-- Version : 2026.06.19
-- Desc    : OUS2 General dashboard visual layout
-- =========================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local MODULES = {
    { name = "XP Bar",          detail = "Experience and reputation",    icon = "IconXPBar" },
    { name = "Delves",          detail = "Companion and journey tracking", icon = "IconDelves" },
    { name = "Flight Master",   detail = "Flight timer and learned routes", icon = "IconFlightMaster" },
    { name = "Flight Routing",  detail = "Taxi route visualization",     icon = "IconFlightRouting" },
    { name = "Utilities",       detail = "Repair, junk, and rare tools", icon = "IconUtilities" },
    { name = "Openables",       detail = "Container item helper",        icon = "IconOpenables" },
    { name = "Stats Bar",       detail = "Character statistics display", icon = "IconStatsBar" },
    { name = "Auto Remount",    detail = "Gathering remount helper",     icon = "IconAutoRemount" },
    { name = "Faster Loot",     detail = "Streamlined loot handling",    icon = "IconFasterLoot" },
    { name = "Fishing Tracker", detail = "Fishing session history",     icon = "IconFishingTracker" },
    { name = "Toolbox",         detail = "Quick-access utility bar",     icon = "IconToolbox" },
}

local function SetTextColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4])
end

local function AddPanelBackground(parent, textureKey, alpha)
    local background = parent:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex(textureKey))
    background:SetAllPoints()
    background:SetAlpha(alpha)
    return background
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

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconGeneral"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("General")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Odysseus Utility Suite dashboard")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Modules", -76)

local cardStartY = -102
local cardHeight = 46
local cardGap = 6

for index, moduleInfo in ipairs(MODULES) do
    local row = math.floor((index - 1) / 2)
    local column = (index - 1) % 2
    local yOffset = cardStartY - row * (cardHeight + cardGap)

    local card = CreateFrame("Frame", nil, page)
    card:SetHeight(cardHeight)

    if column == 0 then
        card:SetPoint("TOPLEFT", page, "TOPLEFT", 18, yOffset)
        card:SetPoint("TOPRIGHT", page, "TOP", -4, yOffset)
    else
        card:SetPoint("TOPLEFT", page, "TOP", 4, yOffset)
        card:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, yOffset)
    end

    AddPanelBackground(card, "ButtonNormal", 0.58)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(T.Tex(moduleInfo.icon))
    icon:SetSize(T.Icons.card, T.Icons.card)
    icon:SetPoint("LEFT", card, "LEFT", 4, 0)

    local name = card:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -5)
    name:SetText(moduleInfo.name)
    SetTextColor(name, T.Colors.text)

    local detail = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
    detail:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    detail:SetJustifyH("LEFT")
    detail:SetText(moduleInfo.detail)
    SetTextColor(detail, T.Colors.textDim)
end

CreateSectionHeader("Global Options", -422)

local optionsPanel = CreateFrame("Frame", nil, page)
optionsPanel:SetHeight(48)
optionsPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -450)
optionsPanel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -450)
AddPanelBackground(optionsPanel, "ButtonNormal", 0.40)

local function CreateOptionPreview(text, xOffset)
    local checkbox = optionsPanel:CreateTexture(nil, "ARTWORK")
    checkbox:SetTexture(T.Tex("CheckboxOff"))
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", optionsPanel, "LEFT", xOffset, 0)

    local label = optionsPanel:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("LEFT", checkbox, "RIGHT", 7, 0)
    label:SetText(text)
    SetTextColor(label, T.Colors.text)
end

CreateOptionPreview("Show Minimap Button", 12)
CreateOptionPreview("Enable Debug Logging", 250)

CreateSectionHeader("Reset to Defaults", -516)

local resetPreview = CreateFrame("Frame", nil, page)
resetPreview:SetSize(180, 32)
resetPreview:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -544)
AddPanelBackground(resetPreview, "ActionNormal", 1)

local resetLabel = resetPreview:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
resetLabel:SetPoint("CENTER")
resetLabel:SetText("Reset to Defaults")
SetTextColor(resetLabel, T.Colors.text)

CreateSectionHeader("Information", -594)

local informationPanel = CreateFrame("Frame", nil, page)
informationPanel:SetHeight(62)
informationPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -622)
informationPanel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -622)
AddPanelBackground(informationPanel, "ButtonNormal", 0.40)

local logo = informationPanel:CreateTexture(nil, "ARTWORK")
logo:SetTexture(T.Tex("Logo"))
logo:SetSize(T.Icons.card, T.Icons.card)
logo:SetPoint("LEFT", informationPanel, "LEFT", 12, 0)

local addonTitle = informationPanel:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
addonTitle:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -7)
addonTitle:SetText("Odysseus Utility Suite")
SetTextColor(addonTitle, T.Colors.accent)

local version = informationPanel:CreateFontString(nil, "OVERLAY", T.Fonts.small)
version:SetPoint("TOPLEFT", addonTitle, "BOTTOMLEFT", 0, -5)
version:SetText("Version " .. tostring(OUS.Version or "unknown"))
SetTextColor(version, T.Colors.textDim)

local function Refresh()
    version:SetText("Version " .. tostring(OUS.Version or "unknown"))
end

C.RegisterPage("General", page, Refresh)
