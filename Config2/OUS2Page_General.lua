-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_General.lua
-- Version : 2026.06.21
-- Desc    : OUS2 General dashboard layout and module navigation
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
    { name = "Utilities",       detail = "Repair, junk, and rare tools", icon = "IconUtilities", pageKey = "Utilities" },
    { name = "Openables",       detail = "Container item helper",        icon = "IconOpenables", pageKey = "Openables" },
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

local function AddModuleCardStyle(parent)
    local background = parent:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()
    return background
end

local function CreateSectionHeader(parent, text, yOffset)
    local star = parent:CreateTexture(nil, "ARTWORK")
    star:SetTexture(T.Tex("SectionStar"))
    star:SetSize(14, 14)
    star:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

    local label = parent:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
    label:SetPoint("LEFT", star, "RIGHT", 6, 0)
    label:SetText(text)
    SetTextColor(label, T.Colors.header)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(T.Tex("Divider"))
    divider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    divider:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
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

CreateSectionHeader(page, "Modules", -78)

local cardStartY = -106
local cardHeight = T.Card.Height
local cardGap = 10
local columnGap = 10
local gridHeight = cardHeight * 4 + cardGap * 3

local middleColumn = CreateFrame("Frame", nil, page)
middleColumn:SetSize(180, gridHeight)
middleColumn:SetPoint("TOP", page, "TOP", 0, cardStartY)

local leftColumn = CreateFrame("Frame", nil, page)
leftColumn:SetHeight(gridHeight)
leftColumn:SetPoint("TOPLEFT", page, "TOPLEFT", 18, cardStartY)
leftColumn:SetPoint("TOPRIGHT", middleColumn, "TOPLEFT", -columnGap / 2, 0)

local rightModuleColumn = CreateFrame("Frame", nil, page)
rightModuleColumn:SetHeight(gridHeight)
rightModuleColumn:SetPoint("TOPLEFT", middleColumn, "TOPRIGHT", columnGap / 2, 0)
rightModuleColumn:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, cardStartY)

local moduleColumns = { leftColumn, middleColumn, rightModuleColumn }

for index, moduleInfo in ipairs(MODULES) do
    local row = math.floor((index - 1) / 3)
    local column = ((index - 1) % 3) + 1
    local yOffset = -row * (cardHeight + cardGap)
    local columnFrame = moduleColumns[column]

    local card = CreateFrame("Frame", nil, columnFrame)
    card:SetHeight(cardHeight)
    card:SetPoint("TOPLEFT", columnFrame, "TOPLEFT", 0, yOffset)
    card:SetPoint("TOPRIGHT", columnFrame, "TOPRIGHT", 0, yOffset)

    local cardBackground = AddModuleCardStyle(card)
    card:EnableMouse(true)
    card:SetScript("OnEnter", function()
        cardBackground:SetTexture(T.Tex("CardHover"))
    end)
    card:SetScript("OnLeave", function()
        cardBackground:SetTexture(T.Tex("CardNormal"))
    end)

    local pageKey = moduleInfo.pageKey
    if pageKey then
        card:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                OUS.Config2.OpenPage(pageKey)
            end
        end)
    end

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(T.Tex(moduleInfo.icon))
    icon:SetSize(T.Card.IconSize, T.Card.IconSize)
    icon:SetPoint("LEFT", card, "LEFT", T.Card.Padding, 0)

    local name = card:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -6)
    name:SetText(moduleInfo.name)
    SetTextColor(name, T.Colors.text)

    local detail = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    detail:SetPoint(
        "BOTTOMRIGHT",
        card,
        "BOTTOMRIGHT",
        -(T.Card.Padding + T.Card.ChevronSize),
        4
    )
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(true)
    detail:SetText(moduleInfo.detail)
    SetTextColor(detail, T.Colors.textDim)

    local chevron = card:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
    chevron:SetSize(T.Card.ChevronSize, T.Card.ChevronSize)
    chevron:SetPoint("RIGHT", card, "RIGHT", -T.Card.Padding, 0)
    chevron:SetJustifyH("CENTER")
    chevron:SetText(">")
    SetTextColor(chevron, T.Colors.accent)
end

CreateSectionHeader(page, "Information", -494)

local informationPanel = CreateFrame("Frame", nil, page)
informationPanel:SetHeight(140)
informationPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -522)
informationPanel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -522)
AddPanelBackground(informationPanel, "ButtonNormal", 0.40)

local logo = informationPanel:CreateTexture(nil, "ARTWORK")
logo:SetTexture(T.Tex("Logo"))
logo:SetSize(T.Icons.card * 2, T.Icons.card * 2)
logo:SetPoint("LEFT", informationPanel, "LEFT", 20, 0)

local addonTitle = informationPanel:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
addonTitle:SetPoint("TOPLEFT", logo, "TOPRIGHT", 20, -6)
addonTitle:SetPoint("RIGHT", informationPanel, "RIGHT", -20, 0)
addonTitle:SetJustifyH("LEFT")
addonTitle:SetText("Odysseus Utility Suite")
SetTextColor(addonTitle, T.Colors.accent)

local aboutText = informationPanel:CreateFontString(nil, "OVERLAY", T.Fonts.small)
aboutText:SetPoint("TOPLEFT", addonTitle, "BOTTOMLEFT", 0, -12)
aboutText:SetPoint("RIGHT", informationPanel, "RIGHT", -20, 0)
aboutText:SetJustifyH("LEFT")
aboutText:SetText("A modular quality-of-life suite for WoW Retail.")
SetTextColor(aboutText, T.Colors.textDim)

local version = informationPanel:CreateFontString(nil, "OVERLAY", T.Fonts.small)
version:SetPoint("TOPLEFT", aboutText, "BOTTOMLEFT", 0, -12)
version:SetText("Version " .. tostring(OUS.Version or "unknown"))
SetTextColor(version, T.Colors.textDim)

local sidebar = CreateFrame("Frame", nil, C.sidebarContainer)
sidebar:SetAllPoints()
sidebar:Hide()

local optionsPanel = CreateFrame("Frame", nil, sidebar)
optionsPanel:SetHeight(158)
optionsPanel:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
optionsPanel:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
AddPanelBackground(optionsPanel, "CardNormal", 1)

local optionsTitle = optionsPanel:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
optionsTitle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", T.Card.Padding, -14)
optionsTitle:SetText("Global Options")
SetTextColor(optionsTitle, T.Colors.header)

local optionsDescription = optionsPanel:CreateFontString(nil, "OVERLAY", T.Fonts.small)
optionsDescription:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -T.Card.Padding)
optionsDescription:SetPoint("RIGHT", optionsPanel, "RIGHT", -T.Card.Padding, 0)
optionsDescription:SetJustifyH("LEFT")
optionsDescription:SetText("Configure general addon behavior.")
SetTextColor(optionsDescription, T.Colors.textDim)

local function CreateOptionPreview(text, yOffset)
    local checkbox = optionsPanel:CreateTexture(nil, "ARTWORK")
    checkbox:SetTexture(T.Tex("CheckboxOff"))
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 18, yOffset)

    local label = optionsPanel:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    label:SetPoint("LEFT", checkbox, "RIGHT", 7, 0)
    label:SetText(text)
    SetTextColor(label, T.Colors.text)
end

CreateOptionPreview("Show Minimap Button", -86)
CreateOptionPreview("Enable Debug Logging", -120)

local resetPanel = CreateFrame("Frame", nil, sidebar)
resetPanel:SetHeight(170)
resetPanel:SetPoint("TOPLEFT", optionsPanel, "BOTTOMLEFT", 0, -12)
resetPanel:SetPoint("TOPRIGHT", optionsPanel, "BOTTOMRIGHT", 0, -12)
AddPanelBackground(resetPanel, "CardNormal", 1)

local resetTitle = resetPanel:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
resetTitle:SetPoint("TOPLEFT", resetPanel, "TOPLEFT", T.Card.Padding, -16)
resetTitle:SetText("Reset")
SetTextColor(resetTitle, T.Colors.header)

local resetDescription = resetPanel:CreateFontString(nil, "OVERLAY", T.Fonts.small)
resetDescription:SetPoint("TOPLEFT", resetTitle, "BOTTOMLEFT", 0, -12)
resetDescription:SetPoint("RIGHT", resetPanel, "RIGHT", -T.Card.Padding, 0)
resetDescription:SetJustifyH("LEFT")
resetDescription:SetText("Restore all OUS settings to their default values.")
SetTextColor(resetDescription, T.Colors.textDim)

local resetPreview = CreateFrame("Frame", nil, resetPanel)
resetPreview:SetHeight(32)
resetPreview:SetPoint(
    "BOTTOMLEFT",
    resetPanel,
    "BOTTOMLEFT",
    T.Card.Padding,
    T.Card.Padding
)
resetPreview:SetPoint(
    "BOTTOMRIGHT",
    resetPanel,
    "BOTTOMRIGHT",
    -T.Card.Padding,
    T.Card.Padding
)
AddPanelBackground(resetPreview, "ActionNormal", 1)

local resetLabel = resetPreview:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
resetLabel:SetPoint("CENTER")
resetLabel:SetText("Reset to Defaults")
SetTextColor(resetLabel, T.Colors.text)

local function Refresh()
    version:SetText("Version " .. tostring(OUS.Version or "unknown"))
end

C.RegisterPage("General", page, Refresh, sidebar)
