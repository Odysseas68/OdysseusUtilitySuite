# OUS2 Architecture

## Purpose

This document defines the architecture, folder structure, coding standards, and migration plan for OUS2.

OUS2 is intended to become the long-term configuration and UI framework for Odysseus Utility Suite while preserving compatibility with existing modules.

---

# Goals

## Primary Goals

* Modern Retail 12.0+ UI
* Consistent visual style — Midnight Arcane theme
* Shared UI framework
* Reduced code duplication
* Easier module integration
* Easier maintenance
* Future expansion support

## Secondary Goals

* Resizable windows (implemented in OUS2ArtTest ✅)
* Theme support
* Searchable settings (Phase 3+)
* Dynamic page registration
* Reusable UI controls

---

# Folder Structure

## Current (Phase 2 — Config2 subfolder)

OUS2 files live in a dedicated `Config2/` subdirectory inside the addon root.
All existing OUS files remain flat in the root — untouched.

```text
OdysseusUtilitySuite
│
├─ Config2\
│   ├─ OUS2Theme.lua    ← texture registry, colors, fonts, frame constants
│   └─ OUS2Config.lua   ← main frame, nav panel, content panel, help panel
│
├─ media\
│   └─ Textures\
│       ├─ (all TGA files flat — no Assets/ subdirectory)
│       ├─ AiSure.uk\   ← source PNG files (backup)
│       └─ Original_PNG\ ← original generation backup
│
└─ (all existing OUS files remain flat in root)
```

**Texture path:** `Interface\AddOns\OdysseusUtilitySuite\media\Textures\`
All TGA files sit directly here — no `Assets/` subfolder.

**TOC entries (section 6):**
```
Config2\OUS2Theme.lua
Config2\OUS2Config.lua
```

## Future (Phase 6 — full restructure)

```text
OdysseusUtilitySuite
│
├─ Core\
│   ├─ Core.lua
│   ├─ Constants.lua
│   ├─ Events.lua
│   ├─ Logging.lua
│   └─ Utils.lua
│
├─ UI\
│   ├─ OUS2Config.lua
│   ├─ OUS2Theme.lua
│   ├─ OUS2Utils.lua        ← extracted common helpers (Phase 5+)
│   └─ Pages\
│       ├─ OUS2Page_General.lua
│       ├─ OUS2Page_Utilities.lua
│       └─ (one file per module page)
│
├─ Media\
│   └─ Textures\
│
├─ Modules\
│   ├─ XPBar\
│   ├─ FlightMaster\
│   ├─ FlightRouting\
│   ├─ Utilities\
│   ├─ Openables\
│   ├─ StatsBar\
│   ├─ AutoRemount\
│   ├─ Toolbox\
│   └─ FishingTracker\
│
└─ Data\
    ├─ XPBar\
    ├─ Flight\
    ├─ Openables\
    └─ Shared\
```

---

# UI Layout

## Three-Panel Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  [☐ Lock Window]    Odysseus Utility Suite         [X Close]    │
│  ───────────────────────────────────────────────────────────    │
│                                                                 │
│  ┌────────────┬──────────────────────┬──[▐]──┬───────────────┐  │
│  │  LEFT NAV  │    CONTENT PANEL     │SCROLL │  HELP PANEL   │  │
│  │            │                      │  BAR  │               │  │
│  │  General   │  Page content        │       │  Hover text   │  │
│  │  XP Bar    │                      │       │  description  │  │
│  │  Delves    │                      │       │  for current  │  │
│  │  Flight    │                      │       │  hovered      │  │
│  │  Utilities │                      │       │  setting      │  │
│  │  Openables │                      │       │               │  │
│  │  Stats Bar │                      │       │               │  │
│  │  Remount   │                      │       │               │  │
│  │  Loot      │                      │       │               │  │
│  │  Fishing   │                      │       │               │  │
│  │  Toolbox   │                      │       │               │  │
│  │  ────────  │                      │       │               │  │
│  │  Help      │                      │       │               │  │
│  │  Changelog │                      │       │               │  │
│  └────────────┴──────────────────────┴───────┴───────────────┘  │
│                          [Reset to Defaults]  [Close]           │
└─────────────────────────────────────────────────────────────────┘
```

## Panel Responsibilities

**Left Nav Panel:**
- Text-only navigation buttons (no icons in nav)
- Custom button textures: `Button_Normal/Hover/Selected.tga`
- `TabIndicator.tga` on active button left edge
- Separator line before Help/Changelog entries
- Width: `navWidth = 140px`
- Background: `col.navBg` dark tint

**Content Panel:**
- Scrollable page content (via ScrollFrame + scroll child)
- Scroll child is `C.pageContainer` — pages are parented here
- Scrollbar sits to the RIGHT of the scroll frame, inside content panel bounds
- Dynamic height — adjusts with frame resize via `OnSizeChanged`

**Scrollbar:**
- Parented to `contentPanel` — NOT to `frame`
- `scrollTest` anchors `TOPRIGHT`/`BOTTOMRIGHT` to `contentPanel`
- Track height = `scrollTest:GetHeight()` (auto-follows panel height)
- Thumb height = `max(thumbMinH, trackH * thumbRatio)`
- Thumb position recalculated on `OnVerticalScroll`
- `trackW = 10`, `thumbMinH = 60`, `thumbRatio = 0.30`

**Help Panel:**
- Static text panel on the right side
- `C.SetHelpText(text)` — called by page files on setting hover
- `C.ClearHelpText()` — resets to default message on mouse leave
- Width: `helpWidth = 150px`
- Background: `col.helpBg` dark tint

**Header:**
- Lock/Unlock button (top left) — `Checkbox_Checked/Unchecked.tga` + label text
  - Unlocked: `"Lock Window"` + unchecked texture
  - Locked: `"Unlock Window"` + checked texture
  - Sets `frame:SetResizable(false/true)` on toggle
- Title: `"Odysseus Utility Suite"` centered
- Close button (top right) — `CloseButton_Normal/Hover/Pressed.tga`, 32x32

**Footer:**
- Reset to Defaults button — `ActionButton` artwork, 180px wide
- Close button — `ActionButton` artwork, 100px wide, to the right of Reset
- Both anchored from frame `BOTTOMRIGHT`, `btnY = 28` from bottom
- Gap between buttons: `gap = 50` (positive offset in anchor)

**IMPORTANT — WoW font system:**
- Emoji characters (🔒🔓 etc.) render as blank boxes in WoW's font system
- Never use emoji for UI state — use textures (`Checkbox_Checked/Unchecked.tga`)
- Never use emoji for buttons — use `SetNormalTexture` / `SetHighlightTexture`

---

# General Page — Dashboard Design

The General page is an addon dashboard, not a settings page.

```
┌─────────────────────────────────────────────────────┐
│  Odysseus Utility Suite                  v2026.06   │
│  ─────────────────────────────────────────────────  │
│  12 modules loaded · 10 enabled · 2 disabled        │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │ [Icon] XPBar│  │[Icon] Utils │  │[Icon] Fish  │ │
│  │ 6 settings  │  │ 8 settings  │  │ 4 settings  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │[Icon] Flight│  │[Icon] Opens │  │[Icon] Stats │ │
│  │ 5 settings  │  │ 7 settings  │  │ 3 settings  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ │
│                                                     │
│  [🔍 Search settings...]          (Phase 5+)        │
└─────────────────────────────────────────────────────┘
```

Contents:
- Addon version + build date
- Module count summary (loaded / enabled / disabled)
- Module cards: Icon + Name + setting count
- Enabled/disabled visual state per card
- Click card → navigates to that module page
- Search box (Phase 5+)

---

# Module Page Design

Each module page follows the same pattern:

```
┌─────────────────────────────────────────────────────┐
│  [Icon] Module Name                    [✓ Enabled]  │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  ★ Section Header                                   │
│  ─────────────────────────────────────────────────  │
│  Setting 1                            [ ] checkbox  │
│  Setting 2                            [ ] checkbox  │
│  Setting 3                            [value    ]   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

- Enable/disable checkbox at top right of each page
- Module icon (32x32) at top left of page header
- Section headers with `Icon_SectionStar.tga`
- `Divider_Horizontal.tga` between sections
- Hovering any setting → calls `C.SetHelpText(text)` to update Help panel
- Mouse leave → calls `C.ClearHelpText()`

---

# Shared UI Framework

## OUS2Theme.lua — `Config2\OUS2Theme.lua`

Namespace: `OUS.Theme` (alias `local T = OUS.Theme`)

Responsible for:
- Texture root path and asset filename registry (`T.TEX`, `T.Assets`, `T.Tex(key)`)
- Frame layout constants validated from OUS2ArtTest (`T.Frame`)
- Scrollbar constants (`T.Scroll`)
- Color definitions (`T.Colors`)
- Font definitions (`T.Fonts`)
- Icon display sizes (`T.Icons`)

```lua
-- Texture path
T.TEX = "Interface\\AddOns\\OdysseusUtilitySuite\\media\\Textures\\"

-- Helper — returns full path for a given asset key
function T.Tex(key)
    return T.TEX .. (T.Assets[key] or (key .. ".tga"))
end

-- Frame constants (validated)
T.Frame = {
    defaultW = 1050,  defaultH = 700,
    minW = 1050,      minH = 700,
    maxW = 1600,      maxH = 1000,
    cornerSize  = 80,
    topHeight   = 25,
    sideWidth   = 20,
    edgeInset   = 64,
    VedgeInset  = 5,
    bgInsetX    = 12,
    bgInsetY    = 20,
    gemOffsetTop    = 15,
    gemOffsetBottom = 15,
    navWidth    = 140,
    helpWidth   = 150,
    panelGap    = 8,
    headerHeight = 60,
    footerHeight = 40,
}

-- Scrollbar constants
T.Scroll = {
    trackW          = 10,
    thumbMinH       = 60,
    thumbRatio      = 0.30,
    contentGap      = 8,
    scrollStep      = 18,
}

-- Colors { r, g, b, a }
T.Colors = {
    accent       = { 0.67, 0.56, 1.00, 1.0 },
    text         = { 0.85, 0.85, 0.95, 1.0 },
    textDim      = { 0.55, 0.55, 0.65, 1.0 },
    textDisabled = { 0.40, 0.40, 0.45, 1.0 },
    header       = { 1.00, 0.82, 0.00, 1.0 },
    border       = { 0.40, 0.30, 0.60, 1.0 },
    bgDark       = { 0.08, 0.06, 0.14, 0.97 },
    navBg        = { 0.06, 0.04, 0.10, 0.90 },
    helpBg       = { 0.06, 0.04, 0.10, 0.85 },
    separator    = { 0.35, 0.28, 0.50, 0.80 },
    highlight    = { 0.80, 0.70, 1.00, 0.15 },
    enabled      = { 0.40, 1.00, 0.40, 1.0 },
    disabled     = { 1.00, 0.35, 0.35, 1.0 },
}

-- Fonts
T.Fonts = {
    title         = "GameFontNormalLarge",
    normal        = "GameFontNormal",
    small         = "GameFontNormalSmall",
    dimmed        = "GameFontHighlightSmall",
    highlight     = "GameFontHighlight",
    navButton     = "GameFontNormal",
    sectionHeader = "GameFontNormalLarge",
}

-- Icon display sizes
T.Icons = {
    nav        = 24,
    pageHeader = 32,
    card       = 40,
    minimap    = 32,
}
```

## OUS2Config.lua — `Config2\OUS2Config.lua`

Namespace: `OUS.Config2` (alias `local C = OUS.Config2`)

Main frame + three-panel layout + nav system + page switching.
Keep all code in one file until pages are extracted in Phase 6.

**Public API exposed by OUS2Config.lua:**

```lua
-- Register a page (called by page files after building their UI)
OUS.Config2.RegisterPage(pageName, pageFrame, refreshFn)

-- Open config to a specific page (deep-link from Toolbox/slash)
OUS.Config2.OpenPage(pageName)

-- Toggle config window open/closed
OUS.Config2.Toggle()

-- Set help panel text (called on setting hover by page files)
OUS.Config2.SetHelpText(text)

-- Reset help panel text (called on mouse leave by page files)
OUS.Config2.ClearHelpText()
```

**Page container:** `C.pageContainer` — the scroll child frame; pages are parented here.

## OUS2Utils.lua (Phase 5+)

Extracted common helpers after patterns emerge:
- `CreateStyledButton(parent, text, w, h)`
- `CreateSectionHeader(parent, text, yOffset)`
- `CreateDivider(parent, yOffset)`
- `AttachHelpText(frame, text)` — wires OnEnter/OnLeave to SetHelpText/ClearHelpText
- `CreateCustomScrollbar(parent, ...)`

---

# Page System

Each page file builds its UI parented to `C.pageContainer` and registers itself:

```lua
-- In each page file:
local pageFrame = CreateFrame("Frame", nil, OUS.Config2.pageContainer)
pageFrame:SetAllPoints()
pageFrame:Hide()

local function Refresh()
    -- read from OdysseusDB and update widget states
end

-- Wire hover text for a setting:
settingRow:SetScript("OnEnter", function()
    OUS.Config2.SetHelpText("Description of this setting.")
end)
settingRow:SetScript("OnLeave", function()
    OUS.Config2.ClearHelpText()
end)

OUS.Config2.RegisterPage("Utilities", pageFrame, Refresh)
```

Pages are hidden/shown by the nav system. Only one visible at a time — others hidden, not destroyed.

---

# Navigation System

Left panel text-only buttons — no icons in nav.
Active button: `Button_Selected.tga` texture + accent color label + `TabIndicator.tga` shown on left edge.
Inactive button: `Button_Normal.tga` texture + normal color label + indicator hidden.
Separator line (`col.separator` color texture) injected before Help and Changelog entries.

Pages (in order):
```
General
XP Bar
Delves
Flight Master
Flight Routing
Utilities
Openables
Stats Bar
Auto Remount
Faster Loot
Fishing Tracker
Toolbox
──────────────  ← separator
Help
Changelog
```

Internal page keys (used in `PAGE_ORDER`, `RegisterPage`, `OpenPage`):
```
General, XPBar, Delves, FlightMaster, FlightRouting,
Utilities, Openables, StatsBar, AutoRemount, FasterLoot,
FishingTracker, Toolbox, Help, Changelog
```

---

# Configuration Strategy

## Slash Commands
```
/ous   → legacy Config.lua (unchanged, loads /ous handler in Core.lua)
/ous2  → OUS2Config.lua toggle (handler registered in Core.lua)
```

Both coexist during development. `/ous` untouched until Phase 6 deprecation review.

**Note:** The `/ous2` slash command handler lives in `Core.lua` (not OUS2Config.lua)
to stay consistent with OUS architecture where Core owns all slash commands.

```lua
-- In Core.lua:
SLASH_OUS2CONFIG1 = "/ous2"
SlashCmdList["OUS2CONFIG"] = function()
    if OUS.Config2 and OUS.Config2.Toggle then
        OUS.Config2.Toggle()
    end
end
```

---

# Migration Plan

## Phase 1 — Foundation ✅ COMPLETE
- [x] Full artwork pack (Midnight Arcane theme)
- [x] All assets converted to TGA (ImageMagick pipeline)
- [x] OUS2ArtTest addon — frame prototype validated
- [x] Validated frame constants (corner=80, topH=25, sideW=20, edgeInset=64, VedgeInset=5)
- [x] Debug flag system (DEBUG_GRID, DEBUG_UNDERLAY, DEBUG_SCROLLBOX)
- [x] Resizable frame with resize handles (right, bottom, corner)
- [x] Custom scrollbar — track + thumb, synced to scroll position

## Phase 2 — OUS2 Window Layout ✅ COMPLETE
- [x] OUS2Theme.lua — texture registry, colors, fonts, frame constants
- [x] OUS2Config.lua — three-panel frame (Left Nav / Content / Help)
- [x] Header bar — Lock/Unlock button + title + Close button
- [x] Footer bar — Reset to Defaults + Close buttons
- [x] Lock/Unlock button (checkbox texture + label, freezes resize)
- [x] Custom close button (CloseButton TGA artwork)
- [x] Resize handles (right edge, bottom edge, corner)
- [x] Resize bounds (min 1050x700, max 1600x1000)
- [x] Left nav panel — text-only buttons with Button TGA artwork
- [x] TabIndicator on active nav button left edge
- [x] Separator before Help/Changelog nav entries
- [x] Page switching system (show/hide, Refresh() call)
- [x] Custom scrollbar — parented to contentPanel, dynamic height
- [x] Help panel — SetHelpText/ClearHelpText public API
- [x] ESC key support via UISpecialFrames
- [x] `/ous2` slash command in Core.lua
- [x] `RegisterPage` / `OpenPage` / `Toggle` public API
- [ ] Remove debug border from content panel (cyan 1px — temporary)

## Phase 3 — General Page (Dashboard)
- [ ] General page frame + RegisterPage wiring
- [ ] Addon version + build date display
- [ ] Module count summary (loaded / enabled / disabled)
- [ ] Module card grid layout (Icon + Name + setting count)
- [ ] Enabled/disabled visual state per card
- [ ] Click card → SwitchPage(pageName)

## Phase 4 — Module Pages
Order:
```
Utilities → Openables → Stats Bar → Auto Remount
→ Flight Master → XP Bar → Toolbox → Faster Loot
→ Fishing Tracker → Delves → Flight Routing
```
Each page: enable toggle + settings + section headers + dividers + hover help text

## Phase 5 — Help & Changelog Pages
- [ ] Help page (scrollable, OUSBanner at top)
- [ ] Changelog page (scrollable version history, current version highlighted)
- [ ] OUSBanner.tga recreation (current proportions wrong)

## Phase 6 — Polish & Migration
- [ ] OUS2Utils.lua — extract common helpers
- [ ] Search box in General tab
- [ ] Full folder restructure (Core/, UI/, Modules/, Data/)
- [ ] Migrate legacy Config.lua functionality
- [ ] Migrate xpbar_config.lua functionality
- [ ] Integrate Help.lua content into Help page
- [ ] Deprecation review (/ous → /ous2 redirect or maintain both)
- [ ] Replace legacy configuration window

---

# Asset Library (complete)

## Texture Path
`Interface\AddOns\OdysseusUtilitySuite\media\Textures\`
All files flat in this directory — no subdirectory.

## Frame
```
Background.tga      TopLeft.tga         TopRight.tga
BottomLeft.tga      BottomRight.tga     Top.tga
Bottom.tga          Vertical_Left.tga   Vertical_Right.tga
HeaderGem.tga       FooterGem.tga
```

## Buttons
```
Button_Normal.tga       Button_Hover.tga        Button_Selected.tga
ActionButton_Normal.tga ActionButton_Hover.tga  ActionButton_Pressed.tga
CloseButton_Normal.tga  CloseButton_Hover.tga   CloseButton_Pressed.tga
```

## Scrollbar
```
ScrollTrack.tga     ScrollThumb.tga
```

## Icons (all 128x128 source, displayed 24x24 nav / 32x32 page / 40x40 card)
```
Icon_OUS.tga            Icon_General.tga        Icon_XPBar.tga
Icon_Delves.tga         Icon_FlightMaster.tga   Icon_FlightRouting.tga
Icon_Utilities.tga      Icon_Openables.tga      Icon_StatsBar.tga
Icon_AutoRemount.tga    Icon_FasterLoot.tga     Icon_FishingTracker.tga
Icon_Toolbox.tga        Icon_Help.tga           Icon_Changelog.tga
Minimap_button.tga
```

## Utility
```
Icon_SectionStar.tga    Checkbox_Checked.tga    Checkbox_Unchecked.tga
Divider_Horizontal.tga  TabIndicator.tga
```

## Branding
```
OUS_Logo.tga        (512x512 — do not stretch, center only)
OUSBanner.tga       (pending recreation — wrong proportions)
```

---

# Coding Standards

## Retail 12.0+
- Retail-safe APIs only — current interface: `120007`
- Event-driven architecture — no polling loops, no `OnUpdate` for state checks
- No deprecated APIs (verify in `wow-ui-source` before using unfamiliar API)
- No taint — never hook or replace protected Blizzard frames/functions directly
- No `goto` or `::label::` (Lua 5.1 — forbidden)
- Secure frame compliance — `SecureActionButtonTemplate` buttons: never set `OnMouseDown`/`OnMouseUp`

## UI Rules
- No `OnUpdate` unless absolutely necessary — prefer Events, Timers, Callbacks
- Manual NineSlice placement — `NineSliceUtil.ApplyLayout` is atlas-only, does NOT work with custom TGA files
- Frame constants defined in `OUS2Theme.lua` — never hardcoded in page files
- Never use emoji characters in WoW UI — they render as blank boxes in WoW's font system; use textures instead

## OUS2 Specific
- All texture paths via `T.Tex(key)` helper — never hardcode paths in page files
- All colors via `T.Colors.*` — never hardcode RGB values in page files
- Help panel text via `C.SetHelpText(text)` / `C.ClearHelpText()` — not GameTooltip
- Page files must call `OUS.Config2.RegisterPage(name, frame, refreshFn)` to wire into nav
- Page files parent their content to `OUS.Config2.pageContainer`
- Debug borders (cyan `BackdropTemplate` outlines) are temporary — remove before commit

---

# Long-Term Vision

OUS2 becomes:
- Configuration framework for all OUS modules
- Shared UI framework (buttons, scrollbars, headers, dividers)
- Help system with per-setting descriptions
- Changelog viewer
- Module dashboard (General page)
- Future: theme variants, search, profile system

All future OUS modules integrate into OUS2 automatically via `RegisterPage` — no manual modification of the main config file required.

Architecture remains stable through future Retail expansions.
