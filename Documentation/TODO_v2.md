# OUS2 TODO

## Phase 1 — Foundation COMPLETE

### Frame System
* [x] Create OUS2ArtTest addon
* [x] Build NineSlice frame prototype with manual placement
* [x] Create Midnight Arcane artwork pack
* [x] Verify frame corners, borders, gems, and background alignment
* [x] Add ESC key support via UISpecialFrames
* [x] Test custom scrollbar artwork
* [x] Verify scrollbar thumb movement
* [x] Add resizable frame prototype
* [x] Add dynamic scroll layout
* [x] Add debug flag workflow
* [x] Validate base frame constants

### Asset Organization
* [x] Design icon system
* [x] Create module icon pack
* [x] Create navigation button artwork
* [x] Create action button artwork
* [x] Create close button artwork
* [x] Create section marker artwork
* [x] Create checkbox/status artwork
* [x] Create OUS branding assets
* [x] Create scrollbar artwork
* [x] Create utility assets
* [x] Convert PNG assets to TGA
* [x] Store TGA files in `media\Textures\`
* [x] Document asset workflow
* [x] Update TOC interface target to 120007
* [x] Create dashboard card assets:
  * [x] `CardBG_Normal.tga`
  * [x] `CardBG_Hover.tga`
  * [x] `CardBG_Selected.tga`
* [ ] Recreate or review `OUSBanner.tga`

---

## Phase 2 — OUS2 Window Layout COMPLETE

### File Setup
* [x] Create `Config2\` subdirectory
* [x] Create `Config2\OUS2Theme.lua`
* [x] Create `Config2\OUS2Config.lua`
* [x] Add OUS2 files to TOC
* [x] Add `/ous2` command path

### Main Frame
* [x] Three-panel layout
* [x] Header bar
* [x] Footer bar
* [x] Custom close button
* [x] Lock/Unlock button
* [x] Resize handles
* [x] Resize bounds
* [x] ESC close support
* [x] Cold-start-safe OUS2 lifecycle
* [x] Eager `C.pageContainer` creation
* [x] Stable resize-anchor handling before `StartSizing()`
* [x] Resize handle guards for locked/hidden frame
* [x] Explicit resize handle frame levels
* [x] Remove temporary cyan debug border

### Left Navigation Panel
* [x] Text-only navigation buttons
* [x] Wider navigation geometry
* [x] Transparent nav background
* [x] Active `TabIndicator`
* [x] Separator before Help/Changelog
* [x] Page switching
* [x] Active nav visual state

### Content Panel
* [x] Scrollable content area
* [x] Custom scrollbar
* [x] Dynamic scrollbar height
* [x] Thumb position sync
* [x] Mouse wheel scrolling
* [x] `C.pageContainer` as page parent

### Help Panel and Sidebar
* [x] Persistent Help text area
* [x] `C.SetHelpText(text)`
* [x] `C.ClearHelpText()`
* [x] Optional page-specific sidebar container
* [x] Hide/show sidebar frame with active page

### Public API
* [x] `OUS.Config2.RegisterPage(name, frame, refreshFn, sidebarFrame)`
* [x] `OUS.Config2.OpenPage(pageName)`
* [x] `OUS.Config2.Toggle()`
* [x] `OUS.Config2.SetHelpText(text)`
* [x] `OUS.Config2.ClearHelpText()`
* [x] `C.pageContainer`
* [x] `C.sidebarContainer`

---

## Phase 3 — General Page Dashboard IN PROGRESS

### Page Setup
* [x] Create `Config2\OUS2Page_General.lua`
* [x] Add standard OUS file header
* [x] Add page file to TOC after `Config2\OUS2Config.lua`
* [x] Register page with OUS2
* [x] Keep page visual-only during layout phase

### Dashboard Header
* [x] General page icon
* [x] General title
* [x] Dashboard subtitle
* [x] Divider
* [ ] Final header micro-adjustments

### Module Cards
* [x] 3-column dashboard card grid
* [x] Current 11 module cards
* [x] Support room for future modules
* [x] Use existing module icons
* [x] Use module names
* [x] Use wrapped module descriptions
* [x] Use shared card textures:
  * [x] `CardNormal`
  * [x] `CardHover`
* [x] Add `T.Card` constants
* [x] Use `T.Card.Height`
* [x] Use `T.Card.IconSize`
* [x] Use `T.Card.ChevronSize`
* [x] Use `T.Card.Padding`
* [x] Keep `CardSelected` available for future state
* [ ] Enabled/disabled visual state per card
* [ ] Module count summary
* [ ] Click card -> `OUS.Config2.OpenPage(pageName)`
* [ ] Optional selected/current-page visual state

### Information Panel
* [x] Wide Information panel below module grid
* [x] Version display
* [x] Addon description
* [ ] Build/date display if available
* [ ] Final text/content pass

### General Sidebar
* [x] General page sidebar frame
* [x] Global Options card
* [x] Reset card
* [x] Sidebar blocks use `CardNormal`
* [x] Keep sidebar visual-only
* [ ] Micro-adjust Global Options spacing
* [ ] Micro-adjust Reset card spacing
* [ ] Add hover help later if needed

### Global Options
* [x] Visual-only Show Minimap Button row
* [x] Visual-only Enable Debug Logging row
* [ ] Wire Show Minimap Button to real setting
* [ ] Wire Enable Debug Logging to real setting

### Reset
* [x] Visual-only Reset sidebar explanation
* [x] Keep footer Reset to Defaults button
* [ ] Audit reset semantics before exposing more functionality
* [ ] Ensure Utilities reset/toggle coverage is fixed before relying on OUS2 reset controls

### Current Polish
* [ ] Review module card vertical alignment
* [ ] Review right sidebar card padding
* [ ] Review Information panel balance
* [ ] Review layout at minimum size
* [ ] Review layout after resizing wider/taller
* [ ] Screenshot final General page before functionality phase

---

## Phase 4 — Module Pages

Recommended order:

1. Utilities
2. Openables
3. Stats Bar
4. Auto Remount
5. Flight Master
6. XP Bar
7. Toolbox
8. Faster Loot
9. Fishing Tracker
10. Delves
11. Flight Routing

Each module page should include:

* [ ] Page frame parented to `C.pageContainer`
* [ ] Optional sidebar content only if useful
* [ ] Module icon/header
* [ ] Module enable/disable control
* [ ] Section headers
* [ ] Divider lines
* [ ] Setting rows
* [ ] Hover help via `C.SetHelpText()` / `C.ClearHelpText()`
* [ ] `Refresh()` function
* [ ] `C.RegisterPage(...)`
* [ ] TOC entry after `Config2\OUS2Config.lua`

---

## Phase 5 — Help and Changelog Pages

### Help Page
* [ ] OUS2 Help page frame
* [ ] Overview section
* [ ] Module documentation
* [ ] Slash command reference
* [ ] Scrollable layout
* [ ] OUSBanner at top after banner is recreated/reviewed

### Changelog Page
* [ ] OUS2 Changelog page frame
* [ ] Scrollable version history
* [ ] Current version highlighted
* [ ] OUSBanner at top after banner is recreated/reviewed

---

## Phase 6 — Polish and Migration

### OUS2Utils.lua

Extract only after patterns stabilize across multiple pages:

* [ ] Create styled card helper
* [ ] Create styled button helper
* [ ] Create section header helper
* [ ] Create divider helper
* [ ] Create hover help attach helper
* [ ] Create reusable scrollbar helper if needed

### Migration
* [ ] Audit module master-toggle behavior
* [ ] Fix Utilities master toggle coverage
* [ ] Fix Utilities reset coverage
* [ ] Resolve `/ous2` slash ownership if still duplicated
* [ ] Review `FlightData.lua` / `flightdata.lua` casing and TOC consistency
* [ ] Review legacy flight data global access
* [ ] Migrate legacy Config.lua functionality where appropriate
* [ ] Migrate `xpbar_config.lua` functionality where appropriate
* [ ] Integrate Help.lua content into OUS2 Help page
* [ ] Decide whether `/ous` remains separate or redirects to `/ous2`
* [ ] Optional folder restructure only after OUS2 is stable

---

## Optional Features

* [ ] Search box in General tab
* [ ] Theme variants
* [ ] Favorites/pinned settings page
* [ ] Profile system, only if truly needed later
* [ ] Import/export, only if truly needed later

---

## Long-Term Goals

* [ ] Shared module registration system
* [ ] Dynamic page generation where safe
* [ ] Stable UI architecture through future Retail expansions
* [ ] OUS2 becomes the primary configuration surface

---

## Current Focus

**Phase 3 — General Dashboard polish**

Immediate next work:

1. Micro-adjust the General sidebar cards.
2. Micro-adjust the Information panel.
3. Test General layout at default, min, and resized sizes.
4. Keep General page visual-only until toggle/reset semantics are audited.
5. Then wire safe dashboard functionality:
   - module count summary
   - enabled/disabled card states
   - card navigation
   - Global Options
   - Reset behavior after audit
