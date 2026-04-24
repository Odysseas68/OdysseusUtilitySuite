# Changelog

All notable changes to **Odysseus Utility Suite** will be documented in this file.

## [2026-04-24] - AutoRemount Refinements

### Changed
- **Auto Remount**: Converted core known/excluded spell databases in `AutoRemountSpells.lua`
  to fast set-style lookup tables for more reliable spell filtering.
- **Auto Remount**: Added broad profession-crafting suppression so remount checks are
  skipped during profession crafting context instead of requiring per-recipe exclusions.

### Fixed
- **Auto Remount**: Excluded profession actions such as **Disenchant** are now ignored
  cleanly by spy mode and no longer produce false discovery/chat spam.
- **Auto Remount**: `LOOT_CLOSED` handling is now quieter and only logs/remounts when
  an actual gather/remount flow is pending, reducing debug noise during FasterLoot interactions.

### Fixed
- **Auto Remount**: Spy mode no longer auto-saves discovered spells — prints to chat only,
  user decides whether to `/ar add <id>`. Eliminates false positives from crafting,
  disenchanting, and other loot-window interactions.
- **Auto Remount**: Character mount (`/ar mount`) is now correctly per-character via
  `SavedVariablesPerCharacter` — previously shared across all characters.
- **Auto Remount**: Config tab now correctly displays current mount name on open for
  both character and account mount fields.

### Added
- **Auto Remount**: Permanent exclude list in `AutoRemountSpells.lua` for spells that
  open a loot window but should never trigger remount (Disenchant, Milling, Prospecting,
  Studying, Tailoring, and others).
- **Auto Remount**: Spy filter blacklist (`/ar spyfilter`) persisted in DB — spells added
  here are silently ignored by spy mode.
- **Auto Remount**: Spy frame renamed to "Custom Spell List" — shows manually added
  spells via `/ar add` only.
- **Auto Remount**: `/ous help` frame rewritten as scrollable `ScrollingMessageFrame`
  with all current commands including full Auto Remount section.
- **Auto Remount**: Config tab spy mode toggle label and help text updated to reflect
  print-only behavior.

---

## [2026-04-23] - Auto Remount

### Added
- **Auto Remount**: New module that automatically remounts after gathering herbs, mining ore, or logging lumber.
  - Spell ID database covering all gathering professions from Classic through Midnight (`AutoRemountSpells.lua`)
  - Configurable remount delay (0.1–5.0 seconds)
  - Per-character and account-wide mount override via `/ar mount` and `/ar account`
  - Fallback to favourite mount when no override is set (`SummonByID(0)`)
  - Druid Travel Form skip (toggleable)
  - Silent mode to suppress mount error messages
  - Safety checks: combat lockdown, flying, dead/ghost, dungeon/raid instance
  - No-loot fallback path for interactions that don't open a loot window (e.g. trap disarm)
  - **Spy mode** (`/ar spy`): tracks unknown spells that trigger loot windows and records them as potential gather spells
    - Loot-confirmed only — combat spells are discarded on `PLAYER_REGEN_ENABLED`
    - Persistent discovered spell list across sessions (`OdysseusDB.autoRemount.discoveredSpells`)
    - Spy frame with scrollable list, Copy All (DB-formatted output), and Clear with confirmation
  - Custom spell list (`/ar add` / `/ar remove` / `/ar export` / `/ar wipe`)
  - New **Auto Remount** tab in `/ous` config panel with toggles, delay slider, mount display, and reset
  - Full slash command set via `/ar` and `/autoremount`

---

## [2026-04-19] - Flightmaster & Delves bar

### Fixed
- **Flightmaster**: Fix tooltip persisting after mouse-off and spurious show after delve exit.
- **Delves bar**: Fix bar hiding after final boss, sticky companion detection,
    add Alt+Click debug info, correct Midnight Valeera delve IDs

## [2026-04-15] - Code Quality & XP Bar

### Fixed
- **XP Bar**: Replaced `GetXPExhaustion()` (Classic-only, nil in Retail 12.0+) with an
  event-driven cache updated by `UPDATE_EXHAUSTION`. Rest XP overlay on the bar now
  correctly reflects rested state instead of always reading as zero.

### Changed
- **Flight Master**: Replaced two always-running `OnUpdate` polling frames with
  event-driven handlers:
  - Liftoff / landing detection now uses `UNIT_FLAGS` (fires exactly on taxi state change)
    instead of calling `UnitOnTaxi()` every frame.
  - Map tooltip hide/show now uses `TAXIMAP_OPENED` / `TAXIMAP_CLOSED` events instead
    of a 20 fps polling loop. The `GameTooltip:Show` hook still handles hover updates.
  - The timer countdown `OnUpdate` frame is now only active during an active taxi ride.
- **XP Bar defaults**: Lightened default XP bar color (dark purple → violet `0.7/0.4/1.0`)
  and rest bar color (dark blue → sky blue `0.3/0.6/1.0`) for better visibility.

### Added
- **XP Bar config**: Background color picker added to the Experience tab, allowing the
  bar background color to be changed without editing saved variables.
- **XP Bar config**: "Show Zzzz Icon when Resting" checkbox moved below the three
  dimension sliders (Width / Height / Scale) for better layout flow.

---

## [2026-04-13] - XP / Reputation

### Fixed
- Replaced deprecated `GetText()` with `_G[]` for faction standing labels
- Removed `GetMaxPlayerLevel()` and `MAX_PLAYER_LEVEL` which are nil in Midnight 12.0
- Removed `UPDATE_EXHAUSTION` event which was removed in 12.0
- Fixed XP/Rep bar display logic for cross-expansion characters (level 87 showing
  rep bar instead of XP bar due to incorrect max level detection)
- Max level detection now uses `UnitXP()==0 and UnitXPMax()>1000000` to correctly
  handle Blizzard's 100,000,000 XP cap value at max level
- Fixed `mLVL` nil value crash in ParseXPText template parser
- Added `tostring()` safety wrap for reputation texture field
- Added `pcall` protection for StatusTrackingBarManager
- Suppressed false-positive LuaLS warnings for undocumented API fields

## [2026-04-11] - Flight Master

### Fixed
- Fixed custom flight-map tooltip errors by hardening taxi cost handling, switching the custom tooltip to a fixed safe width, and decoupling tooltip updates from Blizzard tooltip hide/show behavior.
- Added a fallback anchor so the Odysseus Flightmaster tooltip remains visible even if Blizzard's taxi tooltip is disrupted by third-party addon taint.
- Fixed route timing updates so unknown routes save correctly, while known full-route times are protected from Request Stop partial-flight overwrites.

---

## [2026-04-07] - Flight Master

### Fixed
- Fixed a custom Flightmaster tooltip error on flight-map hover caused by secret/tainted taxi tooltip values, by hardening taxi cost handling and replacing dynamic tooltip width sizing with a fixed safe width.

---

## [2026-04-07] - XP / Reputation / Delves

### Fixed
- Fixed a max-level reputation-bar regression where the custom rep bar could disappear if Blizzard's **Show as Experience Bar** option was unchecked, by persisting the currently displayed faction as fallback state.
- Fixed the Delve bar disappearing immediately after the final boss died while still inside the Delve chest room, by keeping Delve visibility active during the post-boss scenario state even after `IsDelveInProgress()` becomes false.
- Corrected Delve companion max-level handling order in the Delve update path.

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