# Changelog

All notable changes to **Odysseus Utility Suite** will be documented in this file.

## [2026-05-29] - Flightmaster Distance & Bar Overhaul

### Added
- **Flightmaster**: Live distance countdown below the timer bar — straight-line world coordinate distance using `C_Map.GetWorldPosFromMapPos()`, auto-switches between meters (`743m`) and kilometers (`1km 345m`), light blue color matching the map tooltip
- **Flightmaster**: Distance interpolates live during flight (known time) or estimates using avg taxi speed ~28 yards/sec (unknown time)
- **Flightmaster**: Border color picker added next to the border selector — live drag preview, persists across reloads
- **Flightmaster**: `OUS.SetFlightBarColor`, `OUS.SetFlightBorderColor`, `OUS.PreviewFlightBar`, `OUS.ShowFlightTextFrames`, `OUS.HideFlightTextFrames` — Config.lua now calls all bar operations through the OUS table (no direct StatusBar method calls from Config)
- **FlightRouting**: Total route distance in the itinerary panel — sum of all hop segments using world coordinates. Summary lines recolored: Total Hops (gold), Estimated Time (green), Distance (light blue)
- **FlightData**: Updated to FlyTravelTimes v1.1.6 + 37 personal Midnight routes — 13,062 total routes, 538 nodes (1,421 routes recovered from pre-1.1.2 parser bug)

### Changed
- **Flightmaster**: Replaced `StatusBar` with plain `Frame` + `Texture` fill — `SetWidth()` each frame eliminates StatusBar texture redraw hiccup
- **Flightmaster**: Decoupled `borderFrame`, `timerTextFrame`, `timerTopFrame`, `timerBottomFrame` from `timerBar` — all parented to `UIParent`, anchored to bar, independent redraws
- **Flightmaster**: Timer text throttled to 1s updates, distance text to 0.1s — bar fill still updates every frame
- **Config**: `OpenColorPicker` now includes `colorPickerFunc` for live drag preview on all color pickers (bar color and border color)

### Fixed
- **Flightmaster**: Distance display static during unknown-time flights — now counts down using estimated average taxi speed
- **Flightmaster**: Border color not updating live — `SetFlightBorderColor` now calls `SetBackdropBorderColor` directly without resetting the backdrop
- **Flightmaster**: Border color not persisting on reload — color table updated in-place to preserve `colorTableRef` reference held by the color box
- **Flightmaster**: Decoupled frames not showing on unlock — explicit show/hide added for all decoupled frames in lock/unlock toggle

### Infrastructure
- Standard file headers added to 13 engine/config files: `Fasterloot.lua`, `Fishingtracker.lua`, `xpbar_core.lua`, `xpbar_engine.lua`, `xpbar_delves.lua`, `xpbar_favorites.lua`, `AutoRemount.lua`, `StatsBar.lua`, `Openables.lua`, `Toolbox.lua`, `Config.lua`, `xpbar_config.lua`, `Help.lua`
- `FlightRouting.lua` standard header added

---

## [2026-05-15] - Toolbox & Help Frame

### Added
- **Toolbox**: New module — floating icon bar giving one-click access to all OUS module panels
  - One icon per active module: OUS Config, XP Bar Stats, Flight Master, Fishing Tracker, Auto Remount, Stats Bar, Openables
  - Horizontal and vertical layout modes (`/tb ver` / `/tb hor`)
  - Drag handle overlay when unlocked — all icon buttons disabled during repositioning to prevent accidental clicks
  - Smart screen-aware positioning: layout direction determines popup axis, available space determines side
  - Openables quick-action popup: Mass Add, Custom List, Blacklist — Midnight-themed buttons, auto-positions to stay on screen
  - Stats Bar toggle respects current display mode (table vs single-line) — pure show/hide, mode preserved
  - Flight Master and Auto Remount buttons open Config on their respective tab; click again to close
  - Persists position, scale, direction, lock state, and visibility across sessions via `OdysseusDB.toolbox`
  - Module enable/disable checkbox in Config General tab
  - Full slash command set via `/tb` and `/toolbox`
- **Help Frame**: Reworked from single scrolling list to tabbed frame matching Config nav aesthetic
  - 6 tabs: General, Toolbox, XP & Rep, Auto Remount, Stats Bar, Openables
  - Midnight-themed nav buttons (accent strip, sheen, hover/active states)
  - `ScrollFrame` + `FontString` per tab — top-down rendering, lazy-created on first visit
  - Compact banner (200×100) + title + separator shared across all tabs
  - Extracted to standalone `Help.lua` — no Config.lua dependency
- **Config**: `OUS.ConfigFrame.ShowTab` and `OUS.ConfigFrame.currentNavTab` exposed for external callers

### Changed
- **Config**: General tab module toggle checkboxes spacing tightened from 35px to 28px to accommodate Toolbox toggle
- **Help**: Moved from `Config.lua` into standalone `Help.lua` (section 5, loads after `xpbar_config.lua`)

---

## [2026-05-15] - Stats Bar: Secret Value Fix

### Fixed
- **Stats Bar**: `Fmt1` and `FmtNum` display helpers now use `pcall` around `string.format`/`math.floor` — `tonumber()` does not neutralize secret number values in Retail 12.0+ and passes them through unchanged, causing taint errors in instanced content (Timewalking, M+, encounters). Stats display `"—"` when values are restricted.

---

## [2026-05-15] - Openables: Cosmetic Item Detection

### Added
- **Openables**: Cosmetic/appearance item detection — scans tooltip for `ITEM_COSMETIC` global string (Blizzard's "Cosmetic" label) to automatically identify appearance items without any database; no manual item IDs needed
  - Collection filtering via `ITEM_ALREADY_KNOWN` tooltip scan — button disappears after the appearance is learned
  - Soft lavender border color and `"A"` badge for cosmetic items
  - `GetItemCategory` extended to accept `bag`/`slot` for tooltip-driven detection at scan time
  - Approach mirrors NOP addon — zero database maintenance, works for any current and future cosmetic items

---

## [2026-05-12] - Openables: Recipe Filtering & Secure Button

### Added
- **Openables**: Recipe scanning — unlearned recipes detected dynamically via `Enum.ItemClass.Recipe` (classID 9), no static DB required
  - `C_TradeSkillUI.GetRecipeInfo(spellID)` checked first for professions the character has initialized
  - Tooltip fallback via `C_TooltipInfo.GetBagItem` + `ITEM_SPELL_KNOWN` string match for classic-era recipes using generic "Learning" spell
  - Recipe category badge `R` with pink-red border color
  - Async item cache retry via `Item:ContinueOnItemLoad` when `C_Item.GetItemInfo` returns nil at scan time
- **Openables**: Drag handle frame — when unlocked, button is replaced by a distinct blue drag-handle frame (move icon + "drag" label) to prevent accidental item use while repositioning
- **Openables**: Combat safety hardened — `UpdateButton` now hides container and button on `InCombatLockdown()` rather than returning early with button still visible; `PostClick` also guards against combat

### Fixed
- **Openables**: Secure button click now works correctly in Retail 12.0+ — uses `SecureActionButtonTemplate` with `type=macro` and `/use item:ID`; all `OnMouseDown` scripts removed from `opBtn` to prevent taint interference
- **Openables**: Button position drag restored — `opContainer` handles all dragging; `opBtn` has zero drag scripts
- **Openables**: `GetItemCategory` now correctly reads classID from return position 12 of `C_Item.GetItemInfo` (was incorrectly reading position 6 which returns the localized string, not the numeric enum)
- **Openables**: `/op clist` and `/op list` frames now pre-load uncached item names before building rows — no more empty list on first open
- **Openables**: Scale correctly applied to drag handle frame on login and via Config slider

---

## [2026-05-11] - Openables: Collection Filtering & Polish

### Added
- **Openables**: Smart collection filtering — known mounts, collected pets, and learned toys are automatically skipped
  - Mount filtering via `C_MountJournal.GetMountFromItem` + `GetMountInfoByID` — async-safe with item load retry
  - Pet filtering via `C_PetJournal.GetPetInfoByItemID` + `GetNumCollectedInfo` — handles direct-learn pet items
  - Toy filtering via `C_ToyBox.GetToyInfo` + `PlayerHasToy` — inline, no cache needed
  - Refreshes on `NEW_MOUNT_ADDED`, `MOUNT_JOURNAL_USABILITY_CHANGED`, `PET_JOURNAL_LIST_UPDATE`
- **Openables**: Dynamic category classification — every item (built-in DB or custom) is automatically classified at scan time via Blizzard collection APIs, no static mapping required
- **Openables**: Category-colored border — border color changes per item type: purple (mount), blue (pet), green (toy), orange (knowledge), grey (currency), gold (cache/generic)
- **Openables**: Category badge — small letter overlay bottom-left of icon: M (mount), P (pet), T (toy), K (knowledge), G (currency); hidden for generic caches
- **Openables**: Button scale now correctly restored on login/reload — position no longer shifts when scaling

### Fixed
- **Openables**: Button scale not persisted across sessions
- **Openables**: Icon corners no longer visible outside the border
- **Openables**: Removed unused `PrintBlacklist` chat function — blacklist management is frame-only via `/op list`

---

## [2026-05-10] - Openables Module

### Added
- **Openables**: New module — scans bags and surfaces a single-click button for any openable item found.
  - Built-in database (`OpenablesDB.lua`) with 700+ items spanning Classic through TWW 11.2: tier tokens, crest pouches, sparks, delve keys, coffer key shards, contracts, profession knowledge, gems, enchanting materials, rep insignia, and legacy crafting fragments
  - Custom item list — add items via `/op add <itemID> [minQty]`, drag-and-drop via `/op madd`, or remove via `/op remove <itemID>`
  - Per-item minimum quantity threshold — button only appears when stack meets the minimum
  - Session blacklist (right-click to skip for session) and permanent blacklist (Shift+right-click)
  - Auto-open mode: automatically uses the item 0.3s after a bag update
  - Draggable button with lock/unlock via `/op lock` / `/op unlock`
  - Scalable button via Config slider (0.5×–2.0×) with live preview
  - Category-colored tooltip-style border with hover and push feedback
  - Cooldown sweep overlay on the button
  - Blacklist management frame (`/op list`) — scrollable list with per-item Remove button and Clear All
  - Custom list management frame (`/op clist`) — scrollable list showing item name, min quantity, and per-item Remove button
  - Mass add frame (`/op madd`) — drag-and-drop queue: drop multiple items, set per-item quantity, commit all at once
  - Full slash command set via `/op` and `/openables`
  - **Openables** tab in `/ous` config: enable toggle, auto-open toggle, button scale slider, reset position button, blacklist count and clear, custom DB count, export and wipe
  - Export frame: outputs custom list as ready-to-paste `OpenablesDB.lua` lines with item names, pre-selected for Ctrl+C
  - Combat-safe: hides on `PLAYER_REGEN_DISABLED`, rescans on `PLAYER_REGEN_ENABLED`

---

## [2026-04-25] - Stats Bar

### Added
- **Stats Bar**: New module displaying character statistics as a movable overlay.
  - Two display modes: single-line template and vertical table view
  - **Single-line mode**: fully customizable template with tokens (`{ilvl}`, `{spec}`, `{crit}`, `{haste}`, `{mast}`, `{vers}`, `{int}`, `{agi}`, `{str}`, and more)
  - **Table mode**: vertical two-column layout showing iLvl, primary stat, and secondaries in spec priority order with real texture separators
  - Spec priority database (`StatsBarSpecPriority.lua`) covering all specs and hero talent trees from murloc.io (Mythic+)
  - Combat-safe: all stats cached on stat events, never read live during combat/M+/encounter/PvP (`ADDON_RESTRICTION_STATE_CHANGED` handled)
  - Per-character settings via `OdysseusCharDB.statsBar` — template, font size, table width, position
  - Both frames independently movable, lockable, and position-persistent across sessions
  - Font size and table width adjustable live via config or `/sb size` command
  - Full slash command set via `/sb` and `/statsbar`
  - **Stats Bar** tab added to `/ous` config panel with all toggles, sliders, template editor, and reset

---

## [2026-04-24] - AutoRemount Refinements

### Changed
- **Auto Remount**: Converted spell databases to fast set-style lookup tables.
- **Auto Remount**: Added broad profession-crafting suppression via `ProfessionsFrame` check.

### Fixed
- **Auto Remount**: Spy mode no longer auto-saves discovered spells — prints to chat only.
- **Auto Remount**: Character mount now correctly per-character via `SavedVariablesPerCharacter`.
- **Auto Remount**: Config tab correctly displays current mount name on open.

### Added
- **Auto Remount**: Permanent exclude list for false-positive loot-window spells.
- **Auto Remount**: Spy filter blacklist (`/ar spyfilter`) persisted in DB.
- **Auto Remount**: `/ous help` frame rewritten as scrollable `ScrollingMessageFrame`.

---

## [2026-04-23] - Auto Remount

### Added
- **Auto Remount**: New module — automatically remounts after gathering herbs, mining ore, or logging lumber.
  - Spell ID database covering all gathering professions from Classic through Midnight
  - Configurable remount delay, per-character and account-wide mount override
  - Druid Travel Form skip, silent mode, full safety checks
  - Spy mode: prints loot-confirmed unknown spells to chat for manual review
  - Custom spell list via `/ar add` / `/ar remove` / `/ar export` / `/ar wipe`
  - Full slash command set via `/ar` and `/autoremount`

---

## [2026-04-19] - Flightmaster & Delves bar

### Fixed
- **Flightmaster**: Fix tooltip persisting after mouse-off and spurious show after delve exit.
- **Delves bar**: Fix bar hiding after final boss, sticky companion detection, correct Midnight Valeera delve IDs.

## [2026-04-15] - Code Quality & XP Bar

### Fixed
- **XP Bar**: Replaced `GetXPExhaustion()` (Classic-only, nil in Retail 12.0+).

### Changed
- **Flight Master**: Replaced polling frames with event-driven handlers.
- **XP Bar defaults**: Lightened default colors for better visibility.

### Added
- **XP Bar config**: Background color picker and layout improvements.

---

## [2026-04-13] - XP / Reputation

### Fixed
- Replaced deprecated `GetText()`, removed nil APIs, fixed max level detection, fixed crashes.

## [2026-04-11] - Flight Master

### Fixed
- Fixed custom flight-map tooltip errors, fallback anchor, route timing updates.

---

## [2026-04-07] - Flight Master / XP / Reputation / Delves

### Fixed
- Fixed Flightmaster tooltip, max-level rep bar regression, Delve bar post-boss disappear.

## [Unreleased / Current] - 2026-04-04

### Changed
- Refined Midnight-themed configuration UI, nav buttons, content headers.
- Improved Flight Master export workflow and slider formatting.

### Core
- Hardened `ResetAllSettings()`, added session log history cap.

---

## [2026-03-24] - Flight Routing & Map Update

### Added
- Route itinerary sidebar, custom route-line drawing, generated route database, learned-flight export.

---

## [2026-03-21] - Midnight, XP/Rep & Delves Update

### Added
- Unified `/ous` configuration panel, modular Experience/Reputation Bar, Delves support, reward toasts, `/xpstats`.

---

## [2026-03-18] - Faster Loot & Fishing Tracker Update

### Faster Loot
- Safer group loot handling, locked-item checks, improved bag-full behavior.

### Fishing Tracker
- `LOOT_READY`-based tracking, expansion-aware naming, statistics frame, fish-per-hour, currency tracking.
