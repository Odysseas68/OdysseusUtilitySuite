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
* [x] Wire Show Minimap Button to real setting
* [ ] Wire Enable Debug Logging to real setting
* [x] Migrate manual minimap button to LibDataBroker-1.1 + LibDBIcon-1.0 for broker-compatible launcher support
  * [x] Treat third-party minimap manager visibility as owned by the manager; avoid addon-specific workarounds

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

## Phase 4 — Module Page Migration COMPLETE

Recommended order:

1. Utilities — COMPLETE
2. Openables — COMPLETE
3. Stats Bar — COMPLETE
4. Auto Remount — COMPLETE
5. Flightmaster — COMPLETE
6. XP Bar — COMPLETE
7. Toolbox — COMPLETE
8. Faster Loot — COMPLETE
9. Fishing Tracker — COMPLETE
10. Delves — COMPLETE
11. Flight Routing — COMPLETE

Completed module-page baseline, where applicable:

* [x] Page frame parented to `C.pageContainer`
* [x] Optional sidebar content considered only where useful
* [x] Module icon/header
* [x] Safe controls or intentionally read-only status
* [x] Section headers
* [x] Divider lines
* [x] Setting rows or informational cards
* [x] Hover help via `C.SetHelpText()` / `C.ClearHelpText()`
* [x] `Refresh()` function where settings are exposed
* [x] `C.RegisterPage(...)`
* [x] TOC entry after `Config2\OUS2Config.lua`

### Completed Module Pages

* [x] Utilities page
  * [x] DB-backed checkbox rows
  * [x] Hover help
  * [x] Refresh function
  * [x] TOC entry

* [x] Openables page
  * [x] DB-backed settings
  * [x] Existing Openables command integration
  * [x] Lock/unlock fixed through existing slash handler path
  * [x] Management buttons for blacklist, custom list, mass add, and status
  * [x] Replace temporary scale control with reusable custom OUS2 scale control

* [x] General page
* [x] Stats Bar page
* [x] Auto Remount page
* [x] Fishing Tracker page
* [x] Flightmaster page
  * [x] OUS2 font/texture/border selectors
  * [x] OUS2 bar and border color picker rows
  * [x] Safe unlock/drag preview behavior
  * [x] Export learned flight data UI
  * [x] Wipe learned flight data confirmation
  * [x] Reset position and visual appearance controls
* [x] Flight Routing page
* [x] Faster Loot page
* [x] Toolbox page

* [x] XP Bar page
  * [x] Registered XP Bar hub
  * [x] Global child settings
  * [x] Experience child settings
  * [x] Reputation child settings
  * [x] Read-only Favorites child
  * [x] Scrollable Help child
  * [x] Sliced template edit boxes

* [x] Delves page
  * [x] Separate registered `Delves` page
  * [x] Companion and Journey template settings
  * [x] Delves dimension settings
  * [x] Back to XP Bar navigation

---

## Phase 5 — Polish & Advanced Controls

### OUS2 Left-Navigation Pages

* [ ] Help Page
  * [ ] OUS2 Help page frame
  * [ ] Overview section
  * [ ] Module documentation
  * [ ] Slash command reference
  * [ ] Scrollable layout
  * [ ] OUSBanner at top after banner is recreated/reviewed

* [ ] Changelog Page
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
* [x] Migrate supported `xpbar_config.lua` functionality into the XP Bar and Delves OUS2 pages
* [ ] Integrate Help.lua content into OUS2 Help page
* [ ] Decide whether `/ous` remains separate or redirects to `/ous2`
* [ ] Optional folder restructure only after OUS2 is stable

### Future Module Candidate: BuffBars
* [x] Create initial `Documentation/BUFFBARS_DESIGN.md`
* [ ] Review validated `Reference\OdysseusBuffBarsTest\` proof-of-concept for production OUS boundaries
* [ ] Decide whether BuffBars should enter Phase 6 as a gated or disabled-by-default module skeleton
* [ ] Design `OdysseusDB.buffBars` defaults before adding code
* [ ] Port the Retail-safe aura engine only after the design contract is approved
* [ ] Add conservative OUS2 page only after stable public module APIs exist

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

### Stats Bar Follow-Up Review

Future design review required:

- Audit legacy Stats Bar enable semantics.
- Determine whether OUS2 should expose:
  - Account-wide module enable (`OdysseusDB.modules.statsBar`)
  - Per-character single-line bar enable (`OdysseusCharDB.statsBar.enabled`)
  - Per-character table enable (`OdysseusCharDB.statsBar.tableEnabled`)
- Document intended interaction between account-wide and character-specific visibility settings.
- Add OUS2 controls only after behavior and persistence rules are fully defined and verified.

---

### Fishing Tracker Follow-Up Review

- Wipe history UI
- Confirmation flow
- History statistics page
- Reset settings behavior
- Position management review

---

### Flightmaster Follow-Up Review

- Completed OUS2 advanced-control parity: media selectors, color rows, unlock/drag preview, export, wipe confirmation, reset position, and reset appearance.
- Remaining: audit master module toggle behavior during active flight before exposing it in OUS2.

---

### Toolbox Follow-Up Review

Future Toolbox expansion ideas:

- Toolbox scale control.
- Position reset.
- Button visibility management.
- Button ordering / drag-to-reorder.
- Horizontal / vertical layouts (expanded options).
- Button spacing control.
- Button size control.
- Icon-only / icon+text display modes.
- Popup positioning and behavior options.
- Auto-hide / always-show modes.
- Per-module button enable/disable.
- Profiles / layout presets (future consideration).

Expose only after safe public APIs exist and OUS2 controls are available.

---

### XP Bar Follow-Up Review

- [ ] Color controls
- [ ] Favorites management API
- [ ] Delves lock/unlock review
- [ ] Reset review

---

## Current Focus

**Phase 4 — Completed**

- Module page migration completed.
- XP Bar migration completed.
- Delves page completed.
- Openables page implemented and tested.
- Shared scale control implemented and adopted.
- Documentation synchronized.

**Phase 5 — Polish & Advanced Controls**

Current focus is Phase 5 — Polish & Advanced Controls.

1. General page polish
2. Enabled/disabled card states
3. Module count summary
4. Global Options functionality
5. Reset semantics review
6. XP Bar color controls
7. Favorites management API review
8. Delves lock/unlock review
9. Toolbox expansion
10. Faster Loot rules
11. Help page
12. Changelog page
13. Helper extraction

**Phase 5.5 — Framework Consolidation**

Purpose:
Consolidate the OUS2 framework and engineering infrastructure after Phase 5 feature completion before starting Phase 6.

Tasks:
- Review Codex skills for overlap and consistency.
- Extract stable shared helpers after patterns have stabilized.
- Remove obsolete compatibility code and stale comments.
- Verify all OUS2 pages follow the same architecture and coding patterns.
- Audit documentation for consistency (README_v2, ARCHITECTURE, TODO, CHANGELOG, CLAUDE, AGENTS).
- Review file headers and version dates.
- Perform a lightweight Retail API audit against the current Interface version.
- Review event registrations, timers, and helper reuse for maintainability.

Exit Criteria:

- Documentation synchronized.
- Codex skills synchronized.
- No duplicate helper functions.
- Shared UI patterns stabilized.
- No known architectural debt blocking Phase 6.
