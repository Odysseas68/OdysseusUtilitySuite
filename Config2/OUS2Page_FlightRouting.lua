-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_FlightRouting.lua
-- Version : 2026.06.22
-- Desc    : OUS2 Flight Routing informational page
-- ================================================

local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

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

    return card
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconFlightRouting"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Flight Routing")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Taxi map route visualization and estimated travel paths")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Status", -78)
CreateInfoCard(
    "Flight Routing is active automatically on taxi-map hover.",
    "Flight Routing activates automatically while hovering taxi destinations.",
    -104,
    48
)
CreateInfoCard(
    "Routes are calculated from bundled taxi topology and learned Flight Master timing data.",
    "Route topology comes from the bundled database, while estimates use available Flight Master timings.",
    -156,
    62
)

CreateSectionHeader("How It Works", -236)
CreateInfoCard(
    "- Hover taxi nodes on the flight map to preview routes.\n"
        .. "- The route line and itinerary appear only while the taxi map and tooltip context are active.\n"
        .. "- Estimated durations improve as Flight Master learns more route timings.\n"
        .. "- Some estimates may be unknown when timing data is missing.",
    "Explains when route lines, itineraries, and estimated durations are available.",
    -262,
    108,
    T.Fonts.small
)

CreateSectionHeader("Data Sources", -390)
CreateInfoCard(
    "Bundled route topology: Odysseus_RoutingDB.lua",
    "The generated routing database supplies taxi nodes and connections.",
    -416,
    42,
    T.Fonts.small
)
CreateInfoCard(
    "Learned timing data: OdysseusDB.flightSettings.times",
    "Flight Master stores learned route durations in the existing flight settings database.",
    -462,
    42,
    T.Fonts.small
)
CreateInfoCard(
    "Route finder: OUS.FindShortestRoute()",
    "The public route finder calculates a path between known taxi node IDs.",
    -508,
    42,
    T.Fonts.small
)

CreateSectionHeader("Future Settings", -570)
CreateInfoCard(
    "Route display options require a dedicated settings structure and public cleanup API before they can be safely exposed.",
    "Routing controls remain unavailable until the engine has safe enable and cleanup behavior.",
    -596,
    58,
    T.Fonts.small,
    T.Colors.textDim
)

local function Refresh()
end

C.RegisterPage("FlightRouting", page, Refresh)
