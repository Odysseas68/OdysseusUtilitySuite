-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2Theme.lua
-- Version : 2026.06.16
-- Desc    : OUS2 theme registry — textures, colors, fonts, frame layout constants

local addonName, OUS = ...

OUS.Theme = {}
local T = OUS.Theme

-- ---------------------------------------------------------------------------
-- Texture root
-- ---------------------------------------------------------------------------

T.TEX = "Interface\\AddOns\\OdysseusUtilitySuite\\media\\Textures\\"

-- ---------------------------------------------------------------------------
-- Frame assets
-- ---------------------------------------------------------------------------

T.Assets = {
    -- Frame pieces
    Background      = "Background.tga",
    Top             = "Top.tga",
    Bottom          = "Bottom.tga",
    VerticalLeft    = "Vertical_Left.tga",
    VerticalRight   = "Vertical_Right.tga",
    TopLeft         = "TopLeft.tga",
    TopRight        = "TopRight.tga",
    BottomLeft      = "BottomLeft.tga",
    BottomRight     = "BottomRight.tga",
    HeaderGem       = "HeaderGem.tga",
    FooterGem       = "FooterGem.tga",

    -- Navigation buttons
    ButtonNormal    = "Button_Normal.tga",
    ButtonHover     = "Button_Hover.tga",
    ButtonSelected  = "Button_Selected.tga",

    -- Action buttons
    ActionNormal    = "ActionButton_Normal.tga",
    ActionHover     = "ActionButton_Hover.tga",
    ActionPressed   = "ActionButton_Pressed.tga",

    -- Close button
    CloseNormal     = "CloseButton_Normal.tga",
    CloseHover      = "CloseButton_Hover.tga",
    ClosePressed    = "CloseButton_Pressed.tga",

    -- Scrollbar
    ScrollTrack     = "ScrollTrack.tga",
    ScrollThumb     = "ScrollThumb.tga",

    -- Scale controls
    ScaleTrack         = "ScaleTrack.tga",
    ScaleFill          = "ScaleFill.tga",
    ScaleThumb         = "ScaleThumb.tga",

    ScaleArrowLeft     = "ScaleArrow_Left_Normal.tga",
    ScaleArrowLeftH    = "ScaleArrow_Left_Hover.tga",

    ScaleArrowRight    = "ScaleArrow_Right_Normal.tga",
    ScaleArrowRightH   = "ScaleArrow_Right_Hover.tga",

    ScaleEditBox       = "ScaleEditBox_Background.tga",

    -- Utility
    SectionStar     = "Icon_SectionStar.tga",
    CheckboxOn      = "Checkbox_Checked.tga",
    CheckboxOff     = "Checkbox_Unchecked.tga",
    Divider         = "Divider_Horizontal.tga",
    DividerOrnament = "Divider_Ornament.tga",
    TabIndicator    = "TabIndicator.tga",

    -- Branding
    Logo            = "OUS_Logo.tga",
    Banner          = "OUSBanner.tga",
    MinimapButton   = "Minimap_button.tga",
    IconOUS         = "Icon_OUS.tga",

    -- Module icons
    IconGeneral         = "Icon_General.tga",
    IconXPBar           = "Icon_XPBar.tga",
    IconDelves          = "Icon_Delves.tga",
    IconFlightMaster    = "Icon_FlightMaster.tga",
    IconFlightRouting   = "Icon_FlightRouting.tga",
    IconUtilities       = "Icon_Utilities.tga",
    IconOpenables       = "Icon_Openables.tga",
    IconStatsBar        = "Icon_StatsBar.tga",
    IconAutoRemount     = "Icon_AutoRemount.tga",
    IconFasterLoot      = "Icon_FasterLoot.tga",
    IconFishingTracker  = "Icon_FishingTracker.tga",
    IconToolbox         = "Icon_Toolbox.tga",
    IconHelp            = "Icon_Help.tga",
    IconChangelog       = "Icon_Changelog.tga",
    IconComingSoon      = "Icon_ComingSoon.tga",

    -- Module cards
    CardNormal          = "CardBG_Normal.tga",
    CardHover           = "CardBG_Hover.tga",
    CardSelected        = "CardBG_Selected.tga",
}

-- Returns the full texture path for a given asset key
function T.Tex(key)
    return T.TEX .. (T.Assets[key] or (key .. ".tga"))
end

-- ---------------------------------------------------------------------------
-- Frame layout constants (validated from OUS2ArtTest)
-- ---------------------------------------------------------------------------

T.Frame = {
    -- Default size
    defaultW        = 1050,
    defaultH        = 700,

    -- Resize bounds
    minW            = 1050,
    minH            = 700,
    maxW            = 1600,
    maxH            = 1000,

    -- NineSlice placement
    cornerSize      = 80,       -- corner texture display size
    topHeight       = 25,       -- top/bottom edge height
    sideWidth       = 20,       -- side edge width
    edgeInset       = 64,       -- horizontal inset for top/bottom edges
    VedgeInset      = 5,        -- horizontal inset for vertical edges

    -- Background insets
    bgInsetX        = 12,
    bgInsetY        = 20,

    -- Gem offsets from frame edge
    gemOffsetTop    = 15,
    gemOffsetBottom = 15,

    -- Panel widths
    navWidth        = 180,      -- left navigation panel
    helpWidth       = 165,      -- right help panel
    panelGap        = 8,        -- gap between panels

    -- Header / footer reserved height
    headerHeight    = 60,
    footerHeight    = 40,
}

-- ---------------------------------------------------------------------------
-- Track height is dynamic and follows contentPanel height.
-- ---------------------------------------------------------------------------

T.Scroll = {
    trackW          = 10,
    thumbMinH       = 60,
    thumbRatio      = 0.30,     -- thumb height = 30% of track height
    rightMargin     = 70,       -- distance from frame right edge to scrollbar center
    contentGap      = 8,       -- gap between scrollbar and content panel
    -- Track height is dynamic and follows contentPanel height.
    trackHeightBase = 260,      -- subtracted from frame height to get track height
    scrollStep      = 18,       -- pixels per mouse wheel tick
}

-- ---------------------------------------------------------------------------
-- Scale control widget (custom OUS2 slider)
-- Used by Openables and future OUS2 pages for numeric settings.
-- ---------------------------------------------------------------------------

T.Scale = {
    minValue       = 0.5,   -- minimum allowed value
    maxValue       = 2.0,   -- maximum allowed value
    step           = 0.1,   -- increment/decrement amount

    trackW         = 160,   -- track texture width
    trackH         = 12,    -- track texture height

    thumbW         = 12,    -- thumb texture width
    thumbH         = 18,    -- thumb texture height

    arrowW         = 20,    -- left/right button width
    arrowH         = 20,    -- left/right button height

    editW          = 60,    -- value edit box width
    editH          = 20,    -- value edit box height
}

-- ---------------------------------------------------------------------------
-- Module card layout
-- ---------------------------------------------------------------------------

T.Card = {
    Height      = 66,   -- default dashboard card height
    IconSize    = 32,   -- module icon size inside card
    ChevronSize = 14,   -- right-side navigation chevron size
    Padding     = 10,   -- inner spacing from card edges
}

-- ---------------------------------------------------------------------------
-- Colors  { r, g, b, a }
-- ---------------------------------------------------------------------------

T.Colors = {
    accent          = { 0.67, 0.56, 1.00, 1.0 },   -- lavender crystal
    text            = { 0.85, 0.85, 0.95, 1.0 },   -- pale silver
    textDim         = { 0.55, 0.55, 0.65, 1.0 },   -- dimmed silver
    textDisabled    = { 0.40, 0.40, 0.45, 1.0 },   -- disabled / greyed out
    header          = { 1.00, 0.82, 0.00, 1.0 },   -- gold section headers
    border          = { 0.40, 0.30, 0.60, 1.0 },   -- dark purple border
    bgDark          = { 0.08, 0.06, 0.14, 0.97 },  -- main frame background
    navBg           = { 0.06, 0.04, 0.10, 0.10 },  -- left nav panel background
    helpBg          = { 0.06, 0.04, 0.10, 0.10 },  -- help panel background
    separator       = { 0.35, 0.28, 0.50, 0.80 },  -- nav separator line
    highlight       = { 0.80, 0.70, 1.00, 0.15 },  -- hover highlight overlay
    enabled         = { 0.40, 1.00, 0.40, 1.0 },   -- module enabled indicator
    disabled        = { 1.00, 0.35, 0.35, 1.0 },   -- module disabled indicator
}

-- ---------------------------------------------------------------------------
-- Fonts  (WoW shared font strings — no external font files needed)
-- ---------------------------------------------------------------------------

T.Fonts = {
    title           = "GameFontNormalLarge",
    normal          = "GameFontNormal",
    small           = "GameFontNormalSmall",
    dimmed          = "GameFontHighlightSmall",
    highlight       = "GameFontHighlight",
    navButton       = "GameFontNormal",
    sectionHeader   = "GameFontNormalLarge",
}

-- ---------------------------------------------------------------------------
-- Icon display sizes
-- ---------------------------------------------------------------------------

T.Icons = {
    nav             = 24,   -- left nav panel icon size
    pageHeader      = 32,   -- page header icon size
    card            = 40,   -- General page module card icon size
    minimap         = 32,   -- minimap button display size
}
