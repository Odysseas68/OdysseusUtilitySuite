-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_General.lua
-- Version : 2026.06.25
-- Desc    : OUS2 General dashboard layout and module navigation
-- =========================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local minimapOptionCheckbox
local debugOptionCheckbox
local Refresh

local MODULES = {
    { name = "XP Bar",          detail = "Experience and reputation",       icon = "IconXPBar", pageKey = "XPBar" },
    { name = "Delves",          detail = "Companion and journey tracking",  icon = "IconDelves" },
    { name = "Flight Master",   detail = "Flight timer and learned routes", icon = "IconFlightMaster", pageKey = "FlightMaster" },
    { name = "Flight Routing",  detail = "Taxi route visualization",        icon = "IconFlightRouting", pageKey = "FlightRouting" },
    { name = "Utilities",       detail = "Repair, junk, and rare tools",    icon = "IconUtilities", pageKey = "Utilities" },
    { name = "Openables",       detail = "Container item helper",           icon = "IconOpenables", pageKey = "Openables" },
    { name = "Stats Bar",       detail = "Character statistics display",    icon = "IconStatsBar", pageKey = "StatsBar" },
    { name = "Auto Remount",    detail = "Gathering remount helper",        icon = "IconAutoRemount", pageKey = "AutoRemount" },
    { name = "Faster Loot",     detail = "Streamlined loot handling",       icon = "IconFasterLoot", pageKey = "FasterLoot" },
    { name = "Fishing Tracker", detail = "Fishing session history",         icon = "IconFishingTracker", pageKey = "FishingTracker" },
    { name = "Toolbox",         detail = "Quick-access utility bar",        icon = "IconToolbox", pageKey = "Toolbox" },
    { name = "Future Reserved", detail = "Coming in a future update",       icon = "IconComingSoon"},
    { name = "Future Reserved", detail = "Coming in a future update",       icon = "IconComingSoon"},
    { name = "Future Reserved", detail = "Coming in a future update",       icon = "IconComingSoon"},
    { name = "Future Reserved", detail = "Coming in a future update",       icon = "IconComingSoon"},
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
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -14)

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
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

local totalModules = #MODULES
local configuredModules = 0

for _, moduleInfo in ipairs(MODULES) do
    if moduleInfo.pageKey then
        configuredModules = configuredModules + 1
    end
end

local reservedModules = totalModules - configuredModules

local statsFrame = CreateFrame("Frame", nil, page)
statsFrame:SetHeight(44)
statsFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -70)
statsFrame:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -70)

local function CreateStatCard(parent, labelText, valueText, index)
    local cardWidth = 120
    local gap = 10

    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(cardWidth, 44)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", (index - 1) * (cardWidth + gap), 0)
    AddPanelBackground(card, "CardNormal", 1)

    local value = card:CreateFontString(nil, "OVERLAY", T.Fonts.highlight)
    value:SetPoint("TOP", card, "TOP", 0, -5)
    value:SetText(valueText)
    SetTextColor(value, T.Colors.accent)

    local label = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    label:SetPoint("TOP", value, "BOTTOM", 0, -2)
    label:SetText(labelText)
    SetTextColor(label, T.Colors.textDim)

    return card
end

CreateStatCard(statsFrame, "Modules", tostring(totalModules), 1)
CreateStatCard(statsFrame, "Configured", tostring(configuredModules), 2)
CreateStatCard(statsFrame, "Reserved", tostring(reservedModules), 3)

CreateSectionHeader(page, "Modules", -124)

local cardStartY = -152
local cardHeight = T.Card.Height
local cardGap = 6
local columnGap = 10
local gridRows = math.ceil(#MODULES / 3)
local gridHeight = cardHeight * gridRows + cardGap * (gridRows - 1)

-- Wrapper frame for the module grid to ensure proper layout and spacing
local moduleGrid = CreateFrame("Frame", nil, page)
moduleGrid:SetPoint("TOPLEFT", page, "TOPLEFT", 6, cardStartY)
moduleGrid:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, cardStartY)
moduleGrid:SetHeight(gridHeight)

-- Columns for the module cards
local middleColumn = CreateFrame("Frame", nil, moduleGrid)
middleColumn:SetSize(180, gridHeight)
middleColumn:SetPoint("TOP", moduleGrid, "TOP", 0, 0)

local leftColumn = CreateFrame("Frame", nil, moduleGrid)
leftColumn:SetHeight(gridHeight)
leftColumn:SetPoint("TOPLEFT", moduleGrid, "TOPLEFT", 0, 0)
leftColumn:SetPoint("TOPRIGHT", middleColumn, "TOPLEFT", -columnGap / 2, 0)

local rightModuleColumn = CreateFrame("Frame", nil, moduleGrid)
rightModuleColumn:SetHeight(gridHeight)
rightModuleColumn:SetPoint("TOPLEFT", middleColumn, "TOPRIGHT", columnGap / 2, 0)
rightModuleColumn:SetPoint("TOPRIGHT", moduleGrid, "TOPRIGHT", 0, 0)

local moduleColumns = { leftColumn, middleColumn, rightModuleColumn }

-- Module loop to create cards for each modules
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

local informationGap = T.Card.Padding
local informationTopGap = 14
local informationCardHeight = 135

local informationCard = CreateFrame("Frame", nil, page)
informationCard:SetHeight(informationCardHeight)
informationCard:SetPoint("TOPLEFT", moduleGrid, "BOTTOMLEFT", 0, -informationTopGap)
informationCard:SetPoint("TOPRIGHT", moduleGrid, "BOTTOM", -(informationGap / 2), -informationTopGap)
AddPanelBackground(informationCard, "CardNormal", 1)

local welcomeCard = CreateFrame("Frame", nil, page)
welcomeCard:SetHeight(informationCardHeight)
welcomeCard:SetPoint("TOPLEFT", moduleGrid, "BOTTOM", informationGap / 2, -informationTopGap)
welcomeCard:SetPoint("TOPRIGHT", moduleGrid, "BOTTOMRIGHT", 0, -informationTopGap)
AddPanelBackground(welcomeCard, "CardNormal", 1)

local function AddCardTitle(parent, text)
    local title = parent:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
    title:SetPoint("TOP", parent, "TOP", 0, -14)
    title:SetText(text)
    SetTextColor(title, T.Colors.header)

    local ornament = parent:CreateTexture(nil, "ARTWORK")
    ornament:SetTexture(T.Tex("DividerOrnament"))
    ornament:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -36)
    ornament:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -36)
    ornament:SetHeight(16)

    return ornament
end

local informationOrnament = AddCardTitle(informationCard, "Information")

local addonVersion =
    C_AddOns.GetAddOnMetadata(addonName, "Version")
    or "unknown"
local buildDateText = C_AddOns.GetAddOnMetadata(addonName, "X-Build-Date")
if not buildDateText and addonVersion:match("^%d%d%d%d%.%d%d%.%d%d$") then
    buildDateText = addonVersion
end
buildDateText = buildDateText or "unknown"

local gameVersionText = select(1, GetBuildInfo()) or "unknown"

local version = informationCard:CreateFontString(nil, "OVERLAY", T.Fonts.small)
version:SetPoint("TOPLEFT", informationOrnament, "BOTTOMLEFT", 0, -12)
version:SetText("Version: " .. addonVersion)
SetTextColor(version, T.Colors.text)

local buildDate = informationCard:CreateFontString(nil, "OVERLAY", T.Fonts.small)
buildDate:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -10)
buildDate:SetText("Build Date: " .. tostring(buildDateText))
SetTextColor(buildDate, T.Colors.textDim)

local gameVersion = informationCard:CreateFontString(nil, "OVERLAY", T.Fonts.small)
gameVersion:SetPoint("TOPLEFT", buildDate, "BOTTOMLEFT", 0, -10)
gameVersion:SetText("Game Version: " .. tostring(gameVersionText))
SetTextColor(gameVersion, T.Colors.textDim)

local welcomeOrnament = AddCardTitle(welcomeCard, "Welcome")

local welcomeText = welcomeCard:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
welcomeText:SetPoint("TOPLEFT", welcomeOrnament, "BOTTOMLEFT", 0, -12)
welcomeText:SetPoint("BOTTOMRIGHT", welcomeCard, "BOTTOMRIGHT", -T.Card.Padding, T.Card.Padding)
welcomeText:SetJustifyH("LEFT")
welcomeText:SetJustifyV("TOP")
welcomeText:SetWordWrap(true)
welcomeText:SetText(
    "Thank you for using Odysseus Utility Suite.\n" ..
    "Built for adventurers, by adventurers."
)
SetTextColor(welcomeText, T.Colors.textDim)

local sidebar = CreateFrame("Frame", nil, C.sidebarContainer)
sidebar:SetPoint("TOPLEFT", C.sidebarContainer, "TOPLEFT", 0, 0)
sidebar:SetPoint("TOPRIGHT", C.sidebarContainer, "TOPRIGHT", 0, 0)
sidebar:SetHeight(360)
sidebar:Hide()

local sidebarCardWidth = 165

local optionsPanel = CreateFrame("Frame", nil, sidebar)
optionsPanel:SetSize(sidebarCardWidth, 158)
optionsPanel:SetPoint("TOP", sidebar, "TOP", 0, 0)
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

local function CreateOptionToggle(text, helpText, yOffset, isChecked, onClick)
    local row = CreateFrame("Button", nil, optionsPanel)
    row:SetHeight(22)
    row:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 12, yOffset)
    row:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -12, yOffset)

    local checkbox = row:CreateTexture(nil, "ARTWORK")
    checkbox:SetTexture(T.Tex("CheckboxOff"))
    checkbox:SetSize(16, 16)
    checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)

    local label = row:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    label:SetPoint("LEFT", checkbox, "RIGHT", 7, 0)
    label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(text)
    SetTextColor(label, T.Colors.text)

    row:SetScript("OnEnter", function()
        C.SetHelpText(helpText)
    end)
    row:SetScript("OnLeave", function()
        C.ClearHelpText()
    end)
    row:SetScript("OnClick", function()
        if onClick then
            onClick()
        end
        Refresh()
    end)

    function row:SetChecked(checked)
        checkbox:SetTexture(T.Tex(checked and "CheckboxOn" or "CheckboxOff"))
    end

    row:SetChecked(isChecked and isChecked() or false)
    return row
end

minimapOptionCheckbox = CreateOptionToggle(
    "Show Minimap Button",
    "Show or hide the Odysseus minimap launcher. If a minimap manager controls it, manage visibility there.",
    -86,
    function()
        if OUS.IsMinimapButtonShown then
            return OUS.IsMinimapButtonShown()
        end
        return not OdysseusDB or not OdysseusDB.minimap or OdysseusDB.minimap.hide ~= true
    end,
    function()
        local shown = true
        if OUS.IsMinimapButtonShown then
            shown = OUS.IsMinimapButtonShown()
        elseif OdysseusDB then
            shown = not OdysseusDB.minimap or OdysseusDB.minimap.hide ~= true
        end

        if OUS.SetMinimapButtonShown then
            OUS.SetMinimapButtonShown(not shown)
        else
            OdysseusDB = OdysseusDB or {}
            OdysseusDB.minimap = OdysseusDB.minimap or { minimapPos = 225 }
            OdysseusDB.minimap.hide = shown == true
        end
    end
)

debugOptionCheckbox = CreateOptionToggle(
    "Enable Debug Logging",
    "Enable the Odysseus debug console and diagnostic log output for the current session.",
    -120,
    function()
        if OUS.IsDebugModeOn then
            return OUS.IsDebugModeOn()
        end
        return OUS.Session and OUS.Session.isDebugOn == true
    end,
    function()
        local enabled = OUS.Session and OUS.Session.isDebugOn == true
        if OUS.SetDebugMode then
            OUS.SetDebugMode(not enabled)
        elseif OUS.Session then
            OUS.Session.isDebugOn = not enabled
        end
    end
)

local function CreateSidebarPlaceholder(parent, titleText, detailText, anchorTo)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(sidebarCardWidth, 86)

    if anchorTo then
        card:SetPoint("TOP", anchorTo, "BOTTOM", 0, -12)
    else
        card:SetPoint("TOP", parent, "TOP", 0, 0)
    end

    AddPanelBackground(card, "CardNormal", 1)

    local title = card:CreateFontString(nil, "OVERLAY", T.Fonts.sectionHeader)
    title:SetPoint("TOP", card, "TOP", 0, -12)
    title:SetText(titleText)
    SetTextColor(title, T.Colors.header)

    local detail = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    detail:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -38)
    detail:SetPoint("RIGHT", card, "RIGHT", -T.Card.Padding, 0)
    detail:SetJustifyH("CENTER")
    detail:SetWordWrap(true)
    detail:SetText(detailText)
    SetTextColor(detail, T.Colors.textDim)

    return card
end

local profileToolsPanel = CreateSidebarPlaceholder(
    sidebar,
    "Profile Tools",
    "Import / Export profiles\nComing soon",
    optionsPanel
)

CreateSidebarPlaceholder(
    sidebar,
    "Search Index",
    "Find modules and settings\nComing soon",
    profileToolsPanel
)

Refresh = function()
    local addonVersion =
        C_AddOns.GetAddOnMetadata(addonName, "Version")
        or "unknown"

    version:SetText("Version: " .. addonVersion)

    if minimapOptionCheckbox then
        local shown
        if OUS.IsMinimapButtonShown then
            shown = OUS.IsMinimapButtonShown()
        else
            shown = not OdysseusDB or not OdysseusDB.minimap or OdysseusDB.minimap.hide ~= true
        end
        minimapOptionCheckbox:SetChecked(shown)
    end

    if debugOptionCheckbox then
        local enabled
        if OUS.IsDebugModeOn then
            enabled = OUS.IsDebugModeOn()
        else
            enabled = OUS.Session and OUS.Session.isDebugOn == true
        end
        debugOptionCheckbox:SetChecked(enabled)
    end
end

C.RegisterPage("General", page, Refresh, sidebar)
