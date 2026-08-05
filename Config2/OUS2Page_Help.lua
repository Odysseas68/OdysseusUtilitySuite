-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Page_Help.lua
-- Version : 2026.08.05
-- Desc    : OUS2 addon-wide Help page
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
local CARD_HEIGHT = 82
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
local function AddHelpCard(titleText, bodyText, helpText)
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
    background:SetTexture(T.Tex("CardNormal"))
    background:SetAllPoints()

    local title = card:CreateFontString(nil, "OVERLAY", T.Fonts.normal)
    title:SetPoint("TOPLEFT", card, "TOPLEFT", T.Card.Padding, -8)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -T.Card.Padding, -8)
    title:SetJustifyH("LEFT")
    title:SetText(titleText)
    SetTextColor(title, T.Colors.accent)

    local body = card:CreateFontString(nil, "OVERLAY", T.Fonts.small)
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
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
        background:SetTexture(T.Tex("CardNormal"))
        C.ClearHelpText()
    end)
end

local headerIcon = page:CreateTexture(nil, "ARTWORK")
headerIcon:SetTexture(T.Tex("IconHelp"))
headerIcon:SetSize(T.Icons.pageHeader, T.Icons.pageHeader)
headerIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -14)

local title = page:CreateFontString(nil, "OVERLAY", T.Fonts.title)
title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 10, 0)
title:SetText("Help")
SetTextColor(title, T.Colors.accent)

local subtitle = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetText("Addon-wide module guide and command reference")
SetTextColor(subtitle, T.Colors.textDim)

local headerDivider = page:CreateTexture(nil, "ARTWORK")
headerDivider:SetTexture(T.Tex("Divider"))
headerDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -58)
headerDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -58)
headerDivider:SetHeight(6)

CreateSectionHeader("Command Reference", -78)

local overview = page:CreateFontString(nil, "OVERLAY", T.Fonts.small)
overview:SetPoint("TOPLEFT", page, "TOPLEFT", 18, -104)
overview:SetPoint("TOPRIGHT", page, "TOPRIGHT", -18, -104)
overview:SetJustifyH("LEFT")
overview:SetWordWrap(true)
overview:SetText("This page mirrors the addon help content inside OUS2. The legacy /ous help window remains unchanged.")
SetTextColor(overview, T.Colors.textDim)

AddHelpCard(
    "General",
    "/ous - Toggle legacy config\n/ous2 - Toggle OUS2 config\n/ous help - Open legacy help\n/ousdebug - Toggle debug console",
    "Core addon commands. This OUS2 page is read-only and does not replace /ous help."
)
AddHelpCard(
    "Toolbox",
    "/tb toggle - Show or hide\n/tb lock, /tb unlock\n/tb scale [n]\n/tb ver, /tb hor",
    "Toolbox commands control the floating icon bar, position lock state, scale, and layout direction."
)
AddHelpCard(
    "XP & Rep",
    "/xpstats - Session XP and rep\n/toasttest - Test reward popup\n/delvedebug - Instance IDs",
    "XP Bar tracks experience, reputation, session gains, favorites, and related debug helpers."
)
AddHelpCard(
    "Utilities",
    "/ous_rare - Announce target rare\n/js - Open junk blacklist\nUtilities also covers auto repair and junk selling.",
    "Utilities contains Rare Announcer, Auto Repair, and Junk Seller helpers."
)
AddHelpCard(
    "Auto Remount",
    "/ar toggle\n/ar mount <n>, /ar account <n>\n/ar delay <sec>\n/ar reset, /ar status, /ar help",
    "Auto Remount handles gathering remount behavior, mount preferences, delay, druid skip, and spy tools."
)
AddHelpCard(
    "Fishing Tracker",
    "/ous fish - Toggle tracker\nOUS2 controls auto-close, delay, frame opacity, wipe data, and reset defaults.",
    "Fishing Tracker records session catches and can pause Faster Loot when normal loot visibility is needed."
)
AddHelpCard(
    "Openables",
    "/op list, /op clist, /op madd\n/op add <id> [qty]\n/op remove <id>\n/op lock, /op unlock, /op status",
    "Openables manages the secure openable-item button, blacklist, custom items, and auto-open option."
)
AddHelpCard(
    "Faster Loot",
    "Faster Loot accelerates normal loot handling and reveals the loot window when player action is required.",
    "Faster Loot is intentionally informational in OUS2 until safe runtime setters exist."
)
AddHelpCard(
    "Flight Master",
    "Flight timing, learned-route data, timer bar appearance, and route overlays are configured from OUS2.",
    "Flight Master and Flight Routing expose their current settings on separate OUS2 pages."
)
AddHelpCard(
    "Stats Bar",
    "/sb toggle, /sb table\n/sb template <t>\n/sb size <8-24>\n/sb lock, /sb unlock, /sb reset",
    "Stats Bar displays character stat summaries in single-line or table layouts."
)
AddHelpCard(
    "Delves",
    "Use OUS2 XP Bar and Delves pages for companion, journey, size, and template settings.",
    "Delves has its own OUS2 page linked from the XP Bar hub and the left navigation."
)

local function Refresh()
end

C.RegisterPage("Help", page, Refresh)
