-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Changelog.lua
-- Version : 2026.07.04
-- Desc    : OUS2 read-only project changelog page
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local page = CreateFrame("Frame", nil, C.pageContainer)
page:SetAllPoints()
page:Hide()

local function SetTextColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4])
end

local CARD_LEFT = 18
local CARD_TOP = -146
local CARD_WIDTH = 284
local CARD_HEIGHT = 112
local CARD_COLUMN_GAP = 12
local CARD_ROW_GAP = 12
local nextCardIndex = 0

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

-- Adds cards row-by-row so odd counts stay anchored in the left column.
local function AddChangeCard(dateText, titleText, bodyText, helpText, current)
    local index = nextCardIndex
    nextCardIndex = nextCardIndex + 1

    local column = index % 2
    local row = (index - column) / 2
    local xOffset = CARD_LEFT + column * (CARD_WIDTH + CARD_COLUMN_GAP)
    local yOffset = CARD_TOP - row * (CARD_HEIGHT + CARD_ROW_GAP)

    local card = CreateFrame("Frame", nil, page)
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card:EnableMouse(true)
    card:SetPoint("TOPLEFT", page, "TOPLEFT", xOffset, yOffset)

    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(T.Tex(current and "CardSelected" or "CardNormal"))
    background:SetAllPoints()

    local date = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    date:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -8)
    date:SetPoint("TOPRIGHT", card, "TOPRIGHT", -T.Card.Padding, -8)
    date:SetJustifyH("LEFT")
    date:SetText(dateText)
    SetTextColor(date, T.Colors.textDim)

    local title = card:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    title:SetPoint("TOPLEFT", date, "BOTTOMLEFT", 0, -3)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -T.Card.Padding, -24)
    title:SetJustifyH("LEFT")
    title:SetText(titleText)
    SetTextColor(title, T.Colors.accent)

    local body = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -T.Card.Padding, 8)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    body:SetText(bodyText)
    SetTextColor(body, T.Colors.text)

    card:SetScript("OnEnter", function()
        background:SetTexture(T.Tex("CardHover"))
        C.SetHelpText(helpText)
    end)
    card:SetScript("OnLeave", function()
        background:SetTexture(T.Tex(current and "CardSelected" or "CardNormal"))
        C.ClearHelpText()
    end)
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconChangelog"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Changelog")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Recent project updates summarized for in-game reference")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Recent Changes", -78)

local overview = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
overview:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -104)
overview:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -104)
overview:SetJustifyH("LEFT")
overview:SetWordWrap(true)
overview:SetText("This read-only page summarizes CHANGELOG.md. The full project changelog remains in the addon folder.")
SetTextColor(overview, T.Colors.textDim)

AddChangeCard(
    "2026-07-03",
    "BuffBars 12.1 Aura API Planning",
    "Documented the frozen Retail 12.0.x reference and blocked production integration pending 12.1 aura-container research.",
    "BuffBars remains planning-only. No production files or TOC entries are added here.",
    true
)
AddChangeCard(
    "2026-06-28",
    "BuffBars Design Documentation",
    "Added the initial BuffBars design document and tracked the feature as a future Phase 6 candidate.",
    "Captures the validated reference audit while keeping production OUS code untouched."
)
AddChangeCard(
    "2026-06-25",
    "Broker Minimap Launcher Migration",
    "Moved the launcher to LibDataBroker and LibDBIcon with migrated minimap SavedVariables and manager-friendly visibility.",
    "OUS now follows the broker ecosystem instead of owning minimap presentation directly."
)
AddChangeCard(
    "2026-06-25",
    "Project Guidance Updates",
    "Added guidance for comments, public helpers, and third-party compatibility boundaries.",
    "Records the project rules used to keep future addon changes small and reviewable."
)
AddChangeCard(
    "2026-06-25",
    "OUS2 Flight Master Phase 5 Advanced Controls",
    "Added OUS2 Flight Master controls for tooltips, timer bar appearance, export, wipe, reset position, and reset appearance.",
    "Summarizes the Flight Master advanced-control parity work and shared OUS2 helper additions."
)
AddChangeCard(
    "2026-06-03",
    "Utilities Module + Config Polish",
    "Added Utilities with Rare Announcer, Auto Repair, Junk Seller, legacy config controls, defaults, and Toolbox access.",
    "Summarizes the Utilities module introduction and related configuration polish."
)

local function Refresh()
end

C.RegisterPage("Changelog", page, Refresh)
