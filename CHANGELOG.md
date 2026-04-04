# Changelog

All notable changes to **Odysseus Utility Suite** will be documented in this file.

---

## [Unreleased / Current] - 2026-04-04

### Changed
- Refined the standalone **Midnight-themed configuration UI**.
- Restyled the left navigation buttons with a darker metallic / Midnight look.
- Added matching dark-purple content headers across config sections.
- Improved the Flight Master export workflow with safer Lua string escaping and sorted output for cleaner update files.
- Improved slider edit-box formatting for decimal-based settings.
- Hardened multiple config actions against missing database tables.

### Flight Master
- Improved flight timing stability and state cleanup during landing.
- Added safer database lookups for mixed legacy and learned flight timing entries.
- Rounded learned flight durations before saving for cleaner exported data.
- Increased the update threshold so tiny route-time differences no longer spam database updates.
- Preserved the standalone timer bar workflow and `/ous` configuration flow.

### Flight Routing
- Removed the old `/route` debug command from the live module.
- Improved tooltip/sidebar route handling and map line drawing safety.
- Added estimated total route time to the itinerary sidebar when route timing data is known.
- Fixed hover/selection visual issues in the config navigation while polishing the UI.

### Faster Loot
- Kept full cooperation with the Fishing Tracker so fishing loot can be processed safely.
- Improved handling for bag-full / max-count situations by cancelling the active loot ticker before yielding the Blizzard loot window.
- Added safer debug logging guards.

### Fishing Tracker
- Fixed helper-scope and display issues introduced during the tracker update pass.
- Improved fishing loot detection by recognizing loot that happens shortly after a fishing cast, even if the cast/channel stop event has already fired.
- Added support for fishing-related currency rewards.
- Separated **fish catches** from **currency totals**:
  - fish count toward catch totals and fish-per-hour
  - currencies are tracked separately
  - both still appear in the lists
- Added separate currency summary lines in:
  - current location
  - current session
  - overall statistics
- Hardened item/currency row rendering against async stale-row callbacks.

### Core
- Hardened `ResetAllSettings()` against missing saved-variable tables.
- Added a session log history cap to prevent unbounded debug log growth.
- Made global config toggling safer if the config frame is not yet created.

---

## [2026-03-24] - Flight Routing & Map Update

### Added
- Added a route itinerary sidebar for Flight Map / Taxi destinations.
- Added custom route-line drawing on the map using anchored line segments.
- Added generated route database support for the Flight Routing module.
- Added learned-flight export workflow for updating the bundled flight timing database.

### Changed
- Expanded the Flight Master module from a simple timer into a broader flight utility system with:
  - learned route timing
  - map-side route previews
  - itinerary details for hovered destinations

---

## [2026-03-21] - Midnight, XP/Rep & Delves Update

### Added
- Added the unified `/ous` configuration panel.
- Added the modular **Experience / Reputation Bar** system.
- Added support for:
  - standard experience tracking
  - watched reputation
  - Renown
  - Friendship factions
  - Paragon progress
  - Warband-aware reputation text parsing
- Added Delves support with companion + journey tracking.
- Added reward toast notifications for major reputation milestones.
- Added `/xpstats` session statistics.

### Changed
- Split the XP/Rep system into dedicated module files for core logic, engine logic, Delves, favorites, and config.
- Improved max-level reputation fallback behavior and remembered-faction logic.
- Refined fade, wake, and visibility handling for the custom bars.

---

## [2026-03-18] - Faster Loot & Fishing Tracker Update

### Faster Loot
- Added safer handling for group and raid loot rules.
- Added locked-item checks.
- Improved behavior when items must be left behind for manual handling.

### Fishing Tracker
- Replaced older catch detection with `LOOT_READY`-based tracking.
- Added expansion-aware fishing profession naming by zone.
- Added the overall statistics frame.
- Added auto-close logic and fish-per-hour tracking.
- Added database upgrades for location and sub-zone tracking.