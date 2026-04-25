# Changelog

All notable changes to **Odysseus Utility Suite** will be documented in this file.

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
