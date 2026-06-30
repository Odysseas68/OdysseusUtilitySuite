# Changelog

All notable changes to **Odysseus Utility Suite** will be documented in this file.

## [2026-06-28] - BuffBars Design Documentation

### Documentation
- Added initial `Documentation\BUFFBARS_DESIGN.md` for the validated BuffBars reference audit.
- Tracked BuffBars as a future Phase 6 candidate without adding production module files or TOC entries.
- Added long-term Retail-safe aura lessons to `CLAUDE.md`.

---

## [2026-06-25] - Broker Minimap Launcher Migration

### Changed
- Migrated the OUS minimap launcher from a manually owned minimap button to LibDataBroker-1.1 + LibDBIcon-1.0.
- Migrated minimap SavedVariables from `showMinimapButton` / `minimapAngle` to `OdysseusDB.minimap.hide` / `OdysseusDB.minimap.minimapPos`.
- Preserved OUS2 Show Minimap Button behavior through the existing public Core APIs.
- Documented that third-party minimap managers own broker launcher visibility and OUS will not add HidingBar-specific minimap workarounds.

---

## [2026-06-25] - Project Guidance Updates

### Documentation
- Added coding-comment guidance for major helpers, public OUS APIs, and non-obvious integration boundaries.
- Added third-party addon compatibility guidance, including broker-compatible launcher/minimap preference via LibDataBroker-1.1 + LibDBIcon-1.0.

---

## [2026-06-25] - OUS2 Flight Master Phase 5 Advanced Controls

### Added
- **OUS2 Flight Master**: advanced-control parity for map tooltips, timer bar unlock/drag preview, width, height, scale, font size, border size, texture/font/border selectors, bar color, border color, export, wipe confirmation, reset position, and reset appearance.
- **OUS2 shared helpers**: reusable media dropdown, color picker, and copy-text dialog helpers in `Config2\OUS2Config.lua`.

### Changed
- **Flightmaster**: OUS2 scale changes call `OUS.ApplyFlightSettings()` and use the engine's dimension-based scaling path instead of applying user scale with `timerBar:SetScale()`.
- **Flightmaster reset**: OUS2 Reset Appearance restores visual settings while preserving learned flight times.

---

## [2026-06-03] - Utilities Module + Config Polish

### Added
- **Utilities**: New module — `Utilities.lua` — rare announcer, auto repair, junk seller
- **Utilities → Rare Announcer** (`/ous_rare`): target any mob and announce to General chat with classification tag (`[Rare]`, `[Rare Elite]`, `[Elite]`, `[World Boss]`, `[Normal]`), native Blizzard waypoint hyperlink via `C_Map.SetUserWaypoint` + `GetUserWaypointHyperlink()` (restores previous pin after 0.1s), TomTom support (`AddWaypoint` with `source="OUS"`, `crazy=true`), open world only guard, localized General channel table (Leatrix Plus pattern, 10 locales)
- **Utilities → Auto Repair**: auto-repairs on `MERCHANT_SHOW`; guild repair first (`GetGuildBankWithdrawMoney` permission check), own gold fallback; announces cost in chat with coin icons (`UI-GoldIcon`, `UI-SilverIcon`, `UI-CopperIcon` at 14×14); colored fund source (green = guild, amber = own)
- **Utilities → Junk Seller**: scans bags on `MERCHANT_SHOW`, collects grey quality non-blacklisted items into `junkPending`; sells one item per 0.2s timer chain via `C_Container.UseContainerItem`; `limitTo12` option batches 12 at a time with `Sell Next 12 (X left)` button; button always visible when junk present, anchored to `MerchantFrame BOTTOMRIGHT`; `requireShift` shows button and waits for click; `UI_ERROR_MESSAGE` stops selling on `ERR_VENDOR_DOESNT_BUY`; combat guard on both `OnMerchantShow` and `SellNextItem`
- **Config → Utilities tab**: new tab with Rare Announcer, Auto Repair, and Junk Seller sections; per-section checkboxes for all settings
- **Core**: `utilities` module default; `OdysseusDB.utilities` settings (`rareEnabled`, `repairEnabled`, `guildRepair`, `announceRepair`); `OdysseusDB.utilities.junkSell` sub-table (`enabled`, `requireShift`, `announceJunk`, `limitTo12`, `blacklist`); migration guard for `limitTo12` on older saved data
- **Toolbox**: Utilities button added before Openables (`ability_repair` icon)

### Changed
- **Config → General**: module toggles reformatted to 2-column layout (4 rows instead of 8, saves ~140px vertical space); uses `ChatConfigCheckButtonTemplate` with named frame pattern matching existing toggles

### Infrastructure
- `Utilities.lua` added to TOC before `Toolbox.lua`
- TOC version bumped to `2026.06.03`

---

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
