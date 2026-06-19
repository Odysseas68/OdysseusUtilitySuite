# OUS2 TODO

## Phase 1 — Foundation ✅ COMPLETE

### Frame System
* [x] Create OUS2ArtTest addon
* [x] Build NineSlice frame prototype (manual placement)
* [x] Create custom artwork pack (Midnight Arcane — AISure.uk)
* [x] Verify corners, borders, gems and background alignment
* [x] Add ESC key support via UISpecialFrames
* [x] Test custom scrollbar artwork
* [x] Verify thumb movement with scroll position
* [x] Add resizable frame (right edge, bottom edge, corner handles)
* [x] Add dynamic scroll layout (recalculates on OnSizeChanged)
* [x] Add debug flag system (DEBUG_GRID, DEBUG_UNDERLAY, DEBUG_SCROLLBOX)
* [x] Validate final frame constants (corner=80, topH=25, sideW=20, edgeInset=64, VedgeInset=5)

### Asset Organization
* [x] Design icon system
* [x] Create module icon pack (16 icons — 128x128)
* [x] Create navigation button artwork (Normal/Hover/Selected)
* [x] Create action button artwork (Normal/Hover/Pressed)
* [x] Create close button artwork (Normal/Hover/Pressed)
* [x] Create section marker artwork (Icon_SectionStar)
* [x] Create status indicator artwork (Checkbox_Checked/Unchecked)
* [x] Create OUS branding assets (Logo 512x512, Minimap button)
* [x] Create scrollbar artwork (ScrollTrack, ScrollThumb)
* [x] Create utility assets (Divider_Horizontal, TabIndicator)
* [x] Convert all PNG assets to 32-bit TGA with alpha (ImageMagick)
* [x] Store converted TGA files in Media/Textures/ (flat, no Assets/ subfolder)
* [x] Document ImageMagick conversion commands (ASSET_PROMPTS_v2.md)
* [x] Update TOC interface to 120007
* [ ] Recreate OUSBanner.tga (current proportions wrong)

---

## Phase 2 — OUS2 Window Layout ✅ COMPLETE

### File Setup
* [x] Create Config2\ subdirectory
* [x] OUS2Theme.lua — texture registry, colors, fonts, frame constants
* [x] OUS2Config.lua — three-panel production frame
* [x] Add Config2\OUS2Theme.lua and Config2\OUS2Config.lua to TOC (section 6)
* [x] Add /ous2 slash command to Core.lua

### Main Frame
* [x] Three-panel layout (Left Nav / Content / Help)
* [x] Header bar (Lock/Unlock button + Title + Close button)
* [x] Footer bar (Reset to Defaults + Close buttons)
* [x] Custom close button in header (CloseButton_Normal/Hover/Pressed TGA)
* [x] Lock/Unlock button (Checkbox_Checked/Unchecked TGA + label text — NOT emoji)
* [x] Resize handles (right edge, bottom edge, corner)
* [x] Resize bounds (min 1050x700, max 1600x1000)
* [x] ESC key support via UISpecialFrames

### Left Navigation Panel
* [x] Text-only navigation buttons (Button_Normal/Hover/Selected TGA)
* [x] TabIndicator on active button left edge
* [x] Separator line before Help/Changelog entries
* [x] Page switching system (SwitchPage — show/hide + Refresh call)
* [x] SetNavButtonActive — texture + label color + indicator state

### Content Panel
* [x] Scrollable content area (ScrollFrame + scroll child)
* [x] Custom scrollbar (ScrollTrack + ScrollThumb TGA)
* [x] Scrollbar parented to contentPanel — TOPRIGHT/BOTTOMRIGHT anchors
* [x] Dynamic scrollbar height (follows contentPanel height via anchors)
* [x] Thumb position synced to scroll position (UpdateCustomThumb)
* [x] Mouse wheel scrolling (scrollStep = 18px)
* [x] Page container (C.pageContainer = scrollChild)
* [ ] Remove debug border (cyan 1px BackdropTemplate outline — temporary)

### Help Panel
* [x] Static text panel (right side, helpWidth = 150px)
* [x] C.SetHelpText(text) / C.ClearHelpText() public API
* [x] Default message: "Hover a setting to see its description here."

### Public API
* [x] OUS.Config2.RegisterPage(name, frame, refreshFn)
* [x] OUS.Config2.OpenPage(pageName)
* [x] OUS.Config2.Toggle()
* [x] OUS.Config2.SetHelpText(text)
* [x] OUS.Config2.ClearHelpText()
* [x] C.pageContainer — scroll child, parent for all page frames

---

## Phase 3 — General Page (Dashboard)

### Addon Info
* [ ] General page frame + RegisterPage wiring
* [ ] Addon version + build date display
* [ ] Module count summary (loaded / enabled / disabled)

### Module Cards
* [ ] Module card grid layout (3 columns)
* [ ] Each card: Icon (40x40) + Module name + setting count
* [ ] Enabled/disabled visual state per card
* [ ] Click card → OUS.Config2.OpenPage(pageName)

### Future
* [ ] Search box (Phase 5+) — filter settings across all pages

---

## Phase 4 — Module Pages

Each module page follows the same pattern:
- Parent frame to `OUS.Config2.pageContainer`, `SetAllPoints()`
- Enable/disable checkbox at top of page
- Module icon (32x32) at top left
- Section headers (Icon_SectionStar)
- Divider_Horizontal between sections
- Hover any setting → `C.SetHelpText(text)` / leave → `C.ClearHelpText()`
- Call `OUS.Config2.RegisterPage(name, frame, Refresh)` at end of file

### Pages (in order)
* [ ] Utilities
* [ ] Openables
* [ ] Stats Bar
* [ ] Auto Remount
* [ ] Flight Master
* [ ] XP Bar
* [ ] Toolbox
* [ ] Faster Loot
* [ ] Fishing Tracker
* [ ] Delves
* [ ] Flight Routing

---

## Phase 5 — Help & Changelog Pages

### Help Page
* [ ] Overview section
* [ ] Module documentation
* [ ] Slash command reference
* [ ] OUSBanner at top (pending recreation)

### Changelog Page
* [ ] Scrollable version history
* [ ] Current version highlighted
* [ ] OUSBanner at top (pending recreation)

---

## Phase 6 — Polish & Migration

### OUS2Utils.lua (extract after patterns emerge)
* [ ] CreateStyledButton(parent, text, w, h)
* [ ] CreateSectionHeader(parent, text, yOffset)
* [ ] CreateDivider(parent, yOffset)
* [ ] AttachHelpText(frame, text) — wires OnEnter/OnLeave
* [ ] CreateCustomScrollbar(parent, ...)

### Migration
* [ ] Full folder restructure (Core/, UI/, Modules/, Data/)
* [ ] Migrate legacy Config.lua functionality
* [ ] Migrate xpbar_config.lua functionality
* [ ] Integrate Help.lua content into OUS2 Help page
* [ ] Deprecation review (/ous → /ous2 redirect or maintain both)
* [ ] Replace legacy configuration window

---

## Optional Features
* [ ] Search box in General tab
* [ ] Theme variants
* [ ] Minimap icon configuration in General tab
* [ ] Favorites/pinned settings page
* [ ] Profile system

---

## Long-Term Goals
* [ ] Shared module registration system — future modules auto-integrate
* [ ] Dynamic page generation
* [ ] Stable architecture through future Retail expansions

---

## Current Focus

**Phase 3 — General Page:**
1. Remove debug border from content panel
2. Create `Config2\OUS2Page_General.lua`
3. Build General dashboard (version info + module count + module cards)
4. Wire card clicks to `OUS.Config2.OpenPage(pageName)`
5. Add `Config2\OUS2Page_General.lua` to TOC after OUS2Config.lua
