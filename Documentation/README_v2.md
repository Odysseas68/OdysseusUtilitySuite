# OUS2 UI Theme Reference

## Project

OUS2 is the next-generation configuration interface for Odysseus Utility Suite.

The goal is to replace the original Midnight-themed configuration window with a modern, modular, fantasy-themed UI inspired by World of Warcraft Midnight aesthetics.

## Related Documentation

* `Documentation\ARCHITECTURE.md` — OUS2 architecture, page system, and migration status.
* `Documentation\TODO_v2.md` — high-level phase tracking and remaining milestones.
* `Documentation\OUS2_XPBAR_PARITY.md` — authoritative engineering checklist for remaining XP Bar, Reputation, and Delves OUS2 parity work.
* `D:\WoWDev\Reference` — external engineering reference workspace for API, prototype, and third-party research.

## External Reference Workspace

The shared engineering workspace now lives outside the World of Warcraft installation:

```text
D:\WoWDev
|
+-- Reference
+-- Python
L-- Tools
```

Use `D:\WoWDev\Reference\Blizzard\wow-ui-source\` for Retail API, FrameXML, and Blizzard-generated documentation checks.

Do not create addon-local `Reference` folders or NTFS junctions from the WoW installation to `D:\WoWDev`. Battle.net may recursively traverse junction targets during Update and Scan & Repair. Production addon code must never reference files under `D:\WoWDev\Reference`.

---

# Theme Specification

## Theme Name

Midnight Arcane

## Visual Identity

### Frame

* Dark metallic charcoal
* Soft lavender highlights
* Arcane ornamental artwork
* Night Elf inspired filigree

### Background

* Deep midnight blue
* Subtle arcane mist
* Low contrast
* Non-distracting

### Accent Color

* Lavender crystal glow
* Arcane magical highlights
* Soft purple energy

### Text

* Pale silver
* High readability
* Consistent contrast

---

# Asset Reference

## Frame Assets

| File               | Canvas  | Purpose               |
| ------------------ | ------- | --------------------- |
| Background.tga     | 512x512 | Main frame background |
| Top.tga            | 512x68  | Top border            |
| Bottom.tga         | 512x68  | Bottom border         |
| Vertical_Left.tga  | 32x247  | Left border           |
| Vertical_Right.tga | 32x247  | Right border          |
| TopLeft.tga        | 128x128 | Top-left corner       |
| TopRight.tga       | 128x128 | Top-right corner      |
| BottomLeft.tga     | 128x128 | Bottom-left corner    |
| BottomRight.tga    | 128x128 | Bottom-right corner   |

---

## Decorative Assets

| File          | Canvas | Purpose         |
| ------------- | ------ | --------------- |
| HeaderGem.tga | 128x20 | Top ornament    |
| FooterGem.tga | 128x20 | Bottom ornament |

---

## Navigation Button Assets

| File                | Canvas | Purpose           |
| ------------------- | ------ | ----------------- |
| Button_Normal.tga   | 256x64 | Navigation button |
| Button_Hover.tga    | 256x64 | Hover state       |
| Button_Selected.tga | 256x64 | Selected state    |

Used for:

* Left navigation panel
* Page selection
* Module navigation

---

## Action Button Assets

| File                     | Canvas | Purpose                |
| ------------------------ | ------ | ---------------------- |
| ActionButton_Normal.tga  | 256x64 | Standard action button |
| ActionButton_Hover.tga   | 256x64 | Hover state            |
| ActionButton_Pressed.tga | 256x64 | Pressed state          |

Used for:

* Save
* Reset
* Apply
* Import
* Export
* Execute actions

---

## Close Button Assets

| File                    | Canvas  | Purpose       |
| ----------------------- | ------- | ------------- |
| CloseButton_Normal.tga  | 128x128 | Normal state  |
| CloseButton_Hover.tga   | 128x128 | Hover state   |
| CloseButton_Pressed.tga | 128x128 | Pressed state |

---

## Scrollbar Assets

| File            | Canvas | Purpose         |
| --------------- | ------ | --------------- |
| ScrollTrack.tga | 32x256 | Scrollbar track |
| ScrollThumb.tga | 32x64  | Scrollbar thumb |

Validated display sizes (from OUS2ArtTest):

Track:
* 15x320 (dynamic — height adjusts with frame resize)

Thumb:
* 15x60 minimum, 30% of track height

---

## Module Card Assets

| Asset | Size | Purpose |
|---------------------|---------|--------------------------------------|
| CardBG_Normal.tga   | 512x128 | Default dashboard module card        |
| CardBG_Hover.tga    | 512x128 | Mouse-over dashboard module card     |
| CardBG_Selected.tga | 512x128 | Active/current dashboard module card |

---

## Branding Assets

| File               | Canvas  | Purpose                                 |
| ------------------ | ------- | ----------------------------------------|
| Minimap_button.tga | 128x128 | Minimap icon                            |
| Icon_OUS.tga       | 128x128 | OUS branding icon                       |
| OUS_Logo.tga       | 512x512 | Full OUS logo                           |
| OUSBanner.tga      | 512x64  | Page header banner (pending recreation) |

Recommended display sizes:

Icons:
* 32x32
* 36x36
* 40x40

Logo:
* 512x512 centered — do not stretch

---

## Module Icons

All module icons:

* 128x128 source
* 24x24 navigation display
* 32x32 page header display

Files:

* Icon_General.tga
* Icon_XPBar.tga
* Icon_Delves.tga
* Icon_FlightMaster.tga
* Icon_FlightRouting.tga
* Icon_Utilities.tga
* Icon_Openables.tga
* Icon_StatsBar.tga
* Icon_AutoRemount.tga
* Icon_FasterLoot.tga
* Icon_FishingTracker.tga
* Icon_Toolbox.tga
* Icon_Help.tga
* Icon_Changelog.tga

---

## Utility Icons

| File                   | Canvas | Purpose         |
| ---------------------- | ------ | --------------- |
| Icon_SectionStar.tga   | 64x64  | Section headers |
| Checkbox_Checked.tga   | 128x128 | Enabled state  |
| Checkbox_Unchecked.tga | 128x128 | Disabled state |
| Divider_Horizontal.tga | 512x24 | Section divider |
| TabIndicator.tga       | 8x32   | Active nav item |

---

# OUS2 Module Navigation

Planned page order:

1. General
2. XP Bar
3. Delves
4. Flight Master
5. Flight Routing
6. Utilities
7. Openables
8. Stats Bar
9. Auto Remount
10. Faster Loot
11. Fishing Tracker
12. Toolbox
13. Help
14. Changelog

---

# Validated Frame Settings

Confirmed values from OUS2ArtTest — use these in OUS2Config.lua:

```lua
-- Frame
frame:SetSize(1050, 700)
frame:SetResizeBounds(1050, 700, 1600, 1000)

-- Background insets
local bgInsetX = 12
local bgInsetY = 20

-- Frame piece sizes
local corner     = 80      -- corner texture display size
local topH       = 25      -- top/bottom edge height
local sideW      = 20      -- side edge width
local edgeInset  = 64      -- horizontal inset for top/bottom edges
local VedgeInset = 5       -- horizontal inset for vertical edges

-- Top/Bottom edge anchors
top:SetPoint("TOPLEFT",     frame, "TOPLEFT",     edgeInset,  0)
top:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -edgeInset, 0)
bottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  edgeInset,  0)
bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -edgeInset, 0)

-- Vertical edge anchors (stretch full height minus corners)
left:SetPoint("TOPLEFT",    frame, "TOPLEFT",    VedgeInset, 0)
left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", VedgeInset, 0)
right:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -VedgeInset, 0)
right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -VedgeInset, 0)

-- Gem positions
headerGem:SetPoint("TOP",    frame, "TOP",    0, -15)
footerGem:SetPoint("BOTTOM", frame, "BOTTOM", 0,  15)

-- Scrollbar (dynamic — recalculates on OnSizeChanged)
local trackHeight = frameH - 260       -- adjusts with frame height
local thumbHeight = math.max(60, math.floor(trackHeight * 0.30))
track:SetSize(15, trackHeight)
thumb:SetSize(15, thumbHeight)
```

---

## Debug Flags

Toggle at top of file for development:

```lua
local DEBUG_GRID      = false   -- yellow 25px coordinate grid
local DEBUG_UNDERLAY  = false   -- magenta background to see frame bounds
local DEBUG_SCROLLBOX = false   -- cyan border around scroll content area
```

---

## Current Status

### Completed

* OUS2Theme.lua
* OUS2Config.lua
* OUS2ScaleControl.lua
* General page
* Utilities page
* Openables page
* Stats Bar page
* Auto Remount page
* Fishing Tracker page
* Flightmaster page
* Flight Master OUS2 advanced controls and legacy parity
* Flight Routing page
* Faster Loot page
* Toolbox page
* XP Bar hub page
* Delves page
* Help page
* Changelog page
* Shared OUS2 page framework
* Shared card system
* Shared scale-control system
* Shared help-panel system
* Broker-compatible launcher/minimap guidance for third-party addon compatibility
* Minimap launcher migration to LibDataBroker-1.1 + LibDBIcon-1.0
* Midnight Arcane theme implementation
* Documentation synchronization

### Current Phase

Phase 5.6 — OUS2 legacy parity final stage

### Remaining Work

* General page polish
* Enabled/disabled module card states
* Module count summary
* Global Options functionality
* Reset semantics review
* XP Bar / Reputation / Delves parity tracked in `Documentation\OUS2_XPBAR_PARITY.md`
* Toolbox expansion features
* Faster Loot rules system
* OUSBanner recreation/review
* Shared helper extraction after patterns stabilize
