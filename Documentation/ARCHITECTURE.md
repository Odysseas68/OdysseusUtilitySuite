# OUS2 Architecture

## Purpose

This document defines the current OUS2 architecture, coding standards, UI layout, and migration plan for Odysseus Utility Suite.

OUS2 is the next-generation configuration and UI framework for OUS. It is being developed alongside the existing legacy `/ous` configuration window. Module-page migration is complete; the legacy UI remains available while Phase 5 polish and advanced-control parity continue.

---

## Current Status

Phase 4 module-page migration is complete. Current focus is **Phase 5 — Polish & Advanced Controls**.

Implemented:

* `Config2\OUS2Theme.lua`
* `Config2\OUS2Config.lua`
* `Config2\OUS2ScaleControl.lua`
* `Config2\OUS2Page_General.lua`
* `Config2\OUS2Page_Utilities.lua`
* `Config2\OUS2Page_Openables.lua`
* `Config2\OUS2Page_StatsBar.lua`
* `Config2\OUS2Page_AutoRemount.lua`
* `Config2\OUS2Page_FishingTracker.lua`
* `Config2\OUS2Page_FlightMaster.lua`
* `Config2\OUS2Page_FlightRouting.lua`
* `Config2\OUS2Page_FasterLoot.lua`
* `Config2\OUS2Page_Toolbox.lua`
* `Config2\OUS2Page_XPBar.lua`
* `Config2\OUS2Page_Delves.lua`
* Manual NineSlice shell
* Left navigation panel
* Scrollable content area
* Help panel with `C.SetHelpText()` / `C.ClearHelpText()`
* Optional page-specific sidebar area
* Resizable frame with stable resize-anchor handling
* General dashboard visual page
* Completed pages: General, Utilities, Openables, Stats Bar, Auto Remount, Fishing Tracker, Flightmaster, Flight Routing, Faster Loot, Toolbox, XP Bar, and Delves
* Shared module card assets
* Shared dashboard card constants in `T.Card`
* Shared scale-control assets and sizing constants in `T.Scale`
* Reusable `C.CreateScaleControl()` widget
* Shared OUS2 media dropdown, color picker, and copy-text dialog helpers
* Openables scale-control integration
* Flightmaster OUS2 advanced controls

Phase 5 follow-up work:

* General page polish
* Enabled/disabled card states
* Module count summary
* Global Options functionality
* Reset semantics review
* XP Bar color controls
* Favorites management API review
* Delves lock/unlock review
* Toolbox expansion
* Faster Loot rules
* Help page
* Changelog page
* Helper extraction

---

# Goals

## Primary Goals

- Modern Retail 12.0+ UI
- Consistent Midnight Arcane visual style
- Shared OUS2 UI framework
- Reduced duplicated UI code
- Easier module-page integration
- Safer future expansion
- Stable configuration architecture without rewriting working modules

## Secondary Goals

- Reusable page registration
- Sidebar help and page-specific sidebar content
- Reusable dashboard card visuals
- Searchable settings later
- Shared helper extraction after patterns stabilize
- Long-term migration from legacy `/ous` to OUS2 when ready

---

# Folder Structure

## Current Layout

OUS2 files live in `Config2\`.

```text
OdysseusUtilitySuite
│
├─ Config2\
│   ├─ OUS2Theme.lua          ← theme registry, colors, fonts, frame/card/scale constants
│   ├─ OUS2Config.lua         ← main OUS2 shell, nav, content, help/sidebar, resize
│   ├─ OUS2ScaleControl.lua    ← reusable numeric scale control
│   ├─ OUS2Page_General.lua
│   ├─ OUS2Page_Utilities.lua
│   ├─ OUS2Page_Openables.lua
│   ├─ OUS2Page_StatsBar.lua
│   ├─ OUS2Page_AutoRemount.lua
│   ├─ OUS2Page_FishingTracker.lua
│   ├─ OUS2Page_FlightMaster.lua
│   ├─ OUS2Page_FlightRouting.lua
│   ├─ OUS2Page_FasterLoot.lua
│   ├─ OUS2Page_Toolbox.lua
│   ├─ OUS2Page_XPBar.lua
│   └─ OUS2Page_Delves.lua
│
├─ media\
│   └─ Textures\
│       ├─ CardBG_Normal.tga
│       ├─ CardBG_Hover.tga
│       ├─ CardBG_Selected.tga
│       ├─ ScaleTrack.tga
│       ├─ ScaleFill.tga
│       ├─ ScaleThumb.tga
│       └─ all other OUS2 TGA assets flat in this folder
│
├─ Documentation\
│   ├─ ARCHITECTURE.md
│   ├─ TODO_v2.md
│   ├─ README_v2.md
│   └─ ASSET_PROMPTS_v2.md
│
└─ existing OUS module files remain flat in the addon root
```

All existing OUS module files remain in the addon root until a future restructure is explicitly approved.

**Texture path:**

```text
Interface\AddOns\OdysseusUtilitySuite\media\Textures\
```

All OUS2 texture assets are flat in that directory. There is no `Assets\` subdirectory.

---

# TOC Order

OUS2 currently loads after the legacy config/help files:

```text
Config2\OUS2Theme.lua
Config2\OUS2Config.lua
Config2\OUS2ScaleControl.lua
Config2\OUS2Page_General.lua
Config2\OUS2Page_Utilities.lua
Config2\OUS2Page_Openables.lua
Config2\OUS2Page_StatsBar.lua
Config2\OUS2Page_AutoRemount.lua
Config2\OUS2Page_FishingTracker.lua
Config2\OUS2Page_FlightMaster.lua
Config2\OUS2Page_FlightRouting.lua
Config2\OUS2Page_FasterLoot.lua
Config2\OUS2Page_Toolbox.lua
Config2\OUS2Page_XPBar.lua
Config2\OUS2Page_Delves.lua
```

Rules:

- `OUS2Theme.lua` loads before all OUS2 UI files.
- `OUS2Config.lua` creates the shell and `C.pageContainer`.
- OUS2 page files load after `OUS2Config.lua`.
- Additional page files should be added after `Config2\OUS2Config.lua`.
- Do not reorder existing module engines unless explicitly instructed.

---

# OUS2 Theme System

## OUS2Theme.lua

Namespace:

```lua
OUS.Theme
local T = OUS.Theme
```

Responsibilities:

- Texture root: `T.TEX`
- Asset registry: `T.Assets`
- Texture resolver: `T.Tex(key)`
- Main frame constants: `T.Frame`
- Scrollbar constants: `T.Scroll`
- Scale control constants: `T.Scale`
- Dashboard card constants: `T.Card`
- Colors: `T.Colors`
- Fonts: `T.Fonts`
- Icon display sizes: `T.Icons`

## Theme Rules

Use these helpers and constants in OUS2 files:

```lua
T.Tex("AssetKey")
T.Colors.*
T.Fonts.*
T.Frame.*
T.Scroll.*
T.Scale.*
T.Icons.*
T.Card.*
```

Do not hardcode texture paths, RGB values, or duplicated card/frame constants in page files.

## Dashboard Card Assets

The General dashboard uses shared card textures:

```lua
CardNormal   = "CardBG_Normal.tga"
CardHover    = "CardBG_Hover.tga"
CardSelected = "CardBG_Selected.tga"
```

Rules:

- Resolve card textures through `T.Tex("CardNormal")`, `T.Tex("CardHover")`, and `T.Tex("CardSelected")`.
- Do not hardcode filenames or full paths in page files.
- Keep card geometry identical across normal, hover, and selected states.
- Swap the background texture for state changes.
- Keep module icon, title, description, chevron, and future status text as Lua UI layers above the card art.
- Do not bake module-specific text or icons into card textures.

## Card Constants

`T.Card` stores reusable dashboard card values, currently:

```lua
T.Card = {
    Height      = 72,
    IconSize    = 32,
    ChevronSize = 14,
    Padding     = 10,
}
```

Use these values for dashboard cards instead of duplicating local magic numbers.

---

# OUS2 Shell Layout

## Three-Panel Shell

```text
┌─────────────────────────────────────────────────────────────────┐
│  [Lock Window]    Odysseus Utility Suite          [Close]       │
│                                                                 │
│  ┌────────────┬──────────────────────┬──────────┬────────────┐  │
│  │ LEFT NAV   │ CONTENT / PAGE AREA  │ SCROLL   │ HELP/SIDE  │  │
│  │            │                      │ BAR      │ PANEL      │  │
│  └────────────┴──────────────────────┴──────────┴────────────┘  │
│                         [Reset to Defaults] [Close]             │
└─────────────────────────────────────────────────────────────────┘
```

## Left Navigation

- Text-only buttons
- Custom button textures:
  - `Button_Normal.tga`
  - `Button_Hover.tga`
  - `Button_Selected.tga`
- Active button shows `TabIndicator.tga`
- Separator before Help and Changelog
- No nav icons for now
- Navigation panel background is visually transparent so the main frame art shows through

## Content Panel

- Contains a scroll frame and scroll child
- `C.pageContainer` is the scroll child
- Page frames are parented to `C.pageContainer`
- Pages use `SetAllPoints()` and are shown/hidden by the nav system

## Help Panel and Page Sidebar

The right panel has two responsibilities:

1. Persistent Help text area
2. Optional page-specific sidebar content

The help text remains available for all pages through:

```lua
C.SetHelpText(text)
C.ClearHelpText()
```

An optional sidebar container exists below the help text area:

```lua
C.sidebarContainer
```

Page files may register optional sidebar content through the expanded page registration pattern.

Rules:

- Do not permanently replace the Help panel.
- General may use the page-specific sidebar area for Global Options and Reset visual cards.
- Future module pages should continue to use Help text for hover descriptions.
- Page-specific sidebar frames are hidden and shown with their owning page.

---

# OUS2 Public API

Core OUS2 API:

```lua
OUS.Config2.RegisterPage(pageName, pageFrame, refreshFn, sidebarFrame)
OUS.Config2.OpenPage(pageName)
OUS.Config2.Toggle()
OUS.Config2.SetHelpText(text)
OUS.Config2.ClearHelpText()
```

Shared containers:

```lua
OUS.Config2.pageContainer
OUS.Config2.sidebarContainer
```

## RegisterPage

`RegisterPage()` accepts a required page frame and optional sidebar frame:

```lua
OUS.Config2.RegisterPage("General", pageFrame, Refresh, sidebarFrame)
```

Rules:

- `pageFrame` belongs to `C.pageContainer`.
- `sidebarFrame`, when provided, belongs to `C.sidebarContainer`.
- Only the active page frame is shown.
- Only the active page sidebar frame is shown.
- Inactive page and sidebar frames are hidden, not destroyed.

---

# Page Pattern

Each OUS2 page file should:

1. Start with the standard OUS file header.
2. Use `local addonName, OUS = ...`.
3. Alias `local T = OUS.Theme`.
4. Alias `local C = OUS.Config2`.
5. Create the page frame parented to `C.pageContainer`.
6. Call `SetAllPoints()` and `Hide()`.
7. Optionally create a sidebar frame parented to `C.sidebarContainer`.
8. Build UI using `T.Tex`, `T.Colors`, `T.Fonts`, `T.Frame`, `T.Scroll`, `T.Scale`, `T.Icons`, and `T.Card`.
9. Implement `Refresh()` for DB-backed state when functionality is added.
10. Register with `C.RegisterPage("PageKey", page, Refresh, sidebarFrame)`.
11. Add the page file to the TOC after `Config2\OUS2Config.lua`.

---

# OUS2 Resizable Frame Rules

The OUS2 shell is manually resizable from:

- right edge
- bottom edge
- bottom-right corner

Important resize rule learned from testing:

- Do not rely on a persistent `CENTER` anchor during `StartSizing()`.
- Before `StartSizing()`, capture the frame's current screen position.
- Re-anchor to `UIParent` using `TOPLEFT`.
- Call `StopMovingOrSizing()` before starting the new resize.
- Guard resize handlers when the frame is locked or hidden.
- Keep resize handles above content, sidebar, and page frames with explicit frame levels.
- Avoid overlap between resize handles and interactive footer buttons.
- After adding sidebars, overlays, or page containers, test resize from all handles.

This prevents the frame from jumping to maximum size during resize.

---

# General Page Dashboard

The General page is a dashboard, not a deep settings page.

Current General dashboard structure:

```text
┌──────────────────────────────────────────────────────┬──────────────┐
│ Header: General / OUS dashboard                      │ Help text    │
│ Divider                                              │              │
│                                                      │ Sidebar:     │
│ Modules section                                      │ Global       │
│ 3-column module card grid                            │ Options      │
│                                                      │              │
│ Wide Information panel                               │ Sidebar:     │
│                                                      │ Reset        │
└──────────────────────────────────────────────────────┴──────────────┘
```

## Module Card Grid

Current visual goal:

- 3-column grid
- 11 current modules
- Room for future modules
- Card contains:
  - module icon
  - module name
  - short wrapped description
  - chevron
- Uses `CardNormal` and `CardHover`
- `CardSelected` exists for future enabled/current/selected state work

Current modules represented:

- XP Bar
- Delves
- Flight Master
- Flight Routing
- Utilities
- Openables
- Stats Bar
- Auto Remount
- Faster Loot
- Fishing Tracker
- Toolbox

## Information Panel

The Information panel belongs below the module grid in the main dashboard area.

It should summarize:

- addon name
- version
- short description
- development status

## General Sidebar

The General page uses optional sidebar content for:

- Global Options
- Reset

Current Global Options are visual-only:

- Show Minimap Button
- Enable Debug Logging

Launcher/minimap compatibility uses a broker-compatible architecture through LibDataBroker-1.1 + LibDBIcon-1.0. Third-party minimap managers own broker launcher visibility and presentation, and OUS intentionally follows the standard broker implementation instead of adding HidingBar-specific or similar addon-specific workarounds.

Minimap launcher state lives in:

```lua
OdysseusDB.minimap = {
    hide = false,
    minimapPos = 225,
}
```

Legacy values migrate from `OdysseusDB.showMinimapButton` and `OdysseusDB.minimapAngle` during Core initialization.

Current Reset sidebar block is visual-only and explains reset behavior.

The footer-level Reset to Defaults button remains the actual shell-level action surface.

---

# Module Page Design

Current and future module pages follow this pattern:

```text
┌─────────────────────────────────────────────────────┐
│ [Icon] Module Name                    [Enabled]     │
│ ─────────────────────────────────────────────────── │
│                                                     │
│ Section Header                                      │
│ Setting rows                                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Rules:

- Module icon at top left
- Module enable toggle near top right
- Section headers use `Icon_SectionStar.tga`
- Dividers use `Divider_Horizontal.tga`
- Settings use hover help:
  - `C.SetHelpText(text)`
  - `C.ClearHelpText()`
- Wire settings only after their module toggle, live-update, and reset semantics are confirmed
- Completed module pages follow the shared registration, refresh, theme, and hover-help patterns

---

# Current Technical Debt

Known issues to resolve in focused patches:

1. Some modules do not consistently enforce the master `OdysseusDB.modules.*` toggle.
2. Utilities reset/master-toggle coverage still needs audit before relying on OUS2 reset semantics.
3. `/ous2` command ownership should be confirmed and kept unambiguous.
4. Flight data naming/casing should be reviewed:
   - tree shows `FlightData.lua`
   - old docs mention `flightdata.lua`
5. Flight timing data still uses legacy global access patterns.
6. Completed OUS2 module pages still require focused visual polish and in-game testing.
7. General page is still mostly visual-only.
8. `OUS2Utils.lua` is intentionally deferred until multiple pages reveal stable helper patterns.
9. `OUSBanner.tga` remains pending recreation.
10. Documentation should remain synchronized as Phase 5 polish and advanced controls evolve.

---

# Migration Plan

## Phase 1 — Foundation COMPLETE

Completed:

- OUS2ArtTest prototype
- Manual NineSlice validation
- Midnight Arcane asset pack
- TGA conversion workflow
- Resizable frame prototype
- Scrollbar prototype
- Debug-grid workflow

## Phase 2 — OUS2 Window Layout COMPLETE

Completed:

- `OUS2Theme.lua`
- `OUS2Config.lua`
- Three-panel shell
- Header/footer
- Left navigation
- Help panel
- Scroll content area
- Custom scrollbar
- Stable resize handling
- ESC close support
- `/ous2` toggle
- `RegisterPage`, `OpenPage`, `Toggle`
- Cold-start page lifecycle
- `C.pageContainer`
- `C.sidebarContainer`

## Phase 3 — General Dashboard COMPLETED

Completed:

- `OUS2Page_General.lua`
- TOC wiring
- General page registration
- 3-column module card layout
- Shared card assets
- `T.Card` constants
- Card hover visuals
- Wrapped module descriptions
- Wide Information area
- General sidebar content
- Global Options visual block
- Reset visual block

Phase 5 follow-up carried forward:

- Module count summary
- Enabled/disabled card state
- Card navigation to module pages
- Global Options functionality
- Reset functionality after reset semantics audit
- Final micro-adjustments
- Documentation sync after visual layout is stable

## Phase 4 — Module Page Migration COMPLETED

Completed:

1. General
2. Utilities
3. Openables — reusable scale control integrated; visual polish/testing pending
4. Stats Bar
5. Auto Remount
6. Fishing Tracker
7. Flightmaster
8. Flight Routing
9. Faster Loot
10. Toolbox
11. XP Bar
12. Delves

XP Bar OUS2 architecture:

- `XPBar` is the registered hub page.
- Global, Experience, Reputation, Favorites, and Help are internal child views of the XP Bar page.
- Switching to the top-level XP Bar page returns navigation to the hub.
- `Delves` is a separate registered OUS2 page reached from the XP Bar hub and provides a Back to XP Bar action.

Flightmaster OUS2 architecture:

- `Config2\OUS2Page_FlightMaster.lua` provides legacy-parity settings for tooltips, timer bar unlock, dimensions, scale, font size, border size, media selectors, color rows, export, wipe, position reset, and appearance reset.
- Flight Master controls update `OdysseusDB.flightSettings` and call public engine APIs in `Flightmaster.lua`: `ApplyFlightSettings`, `ApplyFlightFonts`, `ApplyFlightTexture`, `ApplyFlightBorder`, `SetFlightBarUnlocked`, `ResetFlightBarPosition`, `ResetFlightBarAppearance`, `SetFlightBarColor`, and `SetFlightBorderColor`.
- User scale is applied by resizing the timer bar dimensions; the timer frame itself remains at scale `1` to avoid redraw and anchoring issues.
- `ResetFlightBarAppearance()` restores visual settings only. Learned flight times remain in `OdysseusDB.flightSettings.times` unless the user explicitly wipes them or uses the global reset flow.
- OUS2 uses shared helpers from `OUS2Config.lua`: `C.OpenMediaDropdown()`, `C.OpenColorPicker()`, and `C.ShowCopyTextDialog()`. These helpers are independent of legacy `Config.lua` dropdowns.

Phase 5 follow-up work:

- General page polish
- Enabled/disabled card states
- Module count summary
- Global Options functionality
- Reset semantics review
- XP Bar color controls
- Favorites management API review
- Delves lock/unlock review
- Toolbox expansion
- Faster Loot rules
- Help page
- Changelog page
- Helper extraction

## Phase 5 — Polish & Advanced Controls

Current:

- General, card-state, module-summary, Global Options, and reset-semantics polish
- XP Bar color controls and Favorites API review
- Delves lock/unlock review
- Toolbox and Faster Loot advanced controls
- Shared helper extraction

Pending OUS2 left-navigation pages:

- Help page
- Changelog page

## Phase 6 — Polish and Migration

Planned later:

- `OUS2Utils.lua` helper extraction
- Search
- Legacy config migration review
- Optional folder restructure
- `/ous` deprecation or coexistence decision

---

# Asset Reference

## Texture Path

```text
Interface\AddOns\OdysseusUtilitySuite\media\Textures\
```

## Frame Assets

```text
Background.tga
TopLeft.tga
TopRight.tga
BottomLeft.tga
BottomRight.tga
Top.tga
Bottom.tga
Vertical_Left.tga
Vertical_Right.tga
HeaderGem.tga
FooterGem.tga
```

## Button Assets

```text
Button_Normal.tga
Button_Hover.tga
Button_Selected.tga
ActionButton_Normal.tga
ActionButton_Hover.tga
ActionButton_Pressed.tga
CloseButton_Normal.tga
CloseButton_Hover.tga
CloseButton_Pressed.tga
```

## Module Card Assets

```text
CardBG_Normal.tga
CardBG_Hover.tga
CardBG_Selected.tga
```

Purpose:

- Normal dashboard card background
- Hover dashboard card background
- Future selected/current/active dashboard card background

## Scrollbar Assets

```text
ScrollTrack.tga
ScrollThumb.tga
```

## Scale Control Assets

```text
ScaleTrack.tga
ScaleFill.tga
ScaleThumb.tga
ScaleArrow_Left_Normal.tga
ScaleArrow_Left_Hover.tga
ScaleArrow_Right_Normal.tga
ScaleArrow_Right_Hover.tga
ScaleEditBox_Background.tga
```

Purpose:

* Reusable OUS2 numeric scale/slider control
* First integrated into the Openables button-scale setting
* Planned reuse for future module controls such as XP Bar size, Stats Bar sizing, opacity, delay, and similar numeric settings

## Icons

```text
Icon_OUS.tga
Icon_General.tga
Icon_XPBar.tga
Icon_Delves.tga
Icon_FlightMaster.tga
Icon_FlightRouting.tga
Icon_Utilities.tga
Icon_Openables.tga
Icon_StatsBar.tga
Icon_AutoRemount.tga
Icon_FasterLoot.tga
Icon_FishingTracker.tga
Icon_Toolbox.tga
Icon_Help.tga
Icon_Changelog.tga
Minimap_button.tga
```

## Utility Assets

```text
Icon_SectionStar.tga
Checkbox_Checked.tga
Checkbox_Unchecked.tga
Divider_Horizontal.tga
TabIndicator.tga
```

## Branding

```text
OUS_Logo.tga
OUSBanner.tga
```

`OUSBanner.tga` still needs review/recreation.

---

# Coding Standards

- Retail 12.0+ APIs only
- No deprecated APIs
- No protected-frame mutation
- No emoji in WoW UI text
- No `goto` / labels
- No `loadstring`
- No broad `pcall` wrappers around core logic
- Event-driven design
- Keep OUS2 changes focused and reviewable
- Keep page files visual-first until module behavior is ready
- Use `OUS.LogDebug()` for normal debug output
- Add one-line comments before major helpers, public OUS APIs, and non-obvious integration boundaries
- Prefer standard third-party integration APIs over addon internals; keep optional compatibility isolated and nil-guarded
- Use LibDataBroker-1.1 + LibDBIcon-1.0 for launcher/minimap integration instead of raw manual minimap button ownership
- Let third-party minimap managers own broker launcher visibility and avoid addon-specific minimap workarounds

---

# Long-Term Vision

OUS2 becomes:

- the main configuration framework for OUS
- a shared UI toolkit for module pages
- the dashboard and help hub for the addon
- a stable, expandable UI foundation for future Retail versions

The legacy `/ous` config remains available until OUS2 reaches functional parity and a deprecation/coexistence decision is made.
