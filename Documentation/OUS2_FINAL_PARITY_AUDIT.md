# OUS2 Final Legacy Parity Audit

Date: 2026-07-10

## Purpose

This release-readiness audit compares legacy `/ous` configuration surfaces, module-owned management frames, and related runtime configuration affordances against OUS2. It does not approve code changes. It records whether OUS2 exposes the same user-visible functionality as legacy `/ous` and the mature module command/config surfaces that legacy users rely on.

Classification key:

* PASS: OUS2 exposes equivalent functionality.
* WARNING: Functionality exists, but scope, wording, runtime coupling, testing, or documentation needs review.
* MISSING: Legacy-visible functionality is not yet available in OUS2.
* INTENTIONAL: OUS2 deliberately differs from legacy behavior.
* MODERNIZED: OUS2 provides equivalent behavior through a newer pattern.
* OBSOLETE: Legacy behavior should not be carried forward.

## Sources Audited

* `AGENTS.md`
* `Core.lua`
* `Config.lua`
* `xpbar_config.lua`
* `Help.lua`
* `Flightmaster.lua`
* `FlightRouting.lua`
* `Fasterloot.lua`
* `Fishingtracker.lua`
* `AutoRemount.lua`
* `StatsBar.lua`
* `Openables.lua`
* `Utilities.lua`
* `Toolbox.lua`
* `xpbar_core.lua`
* `xpbar_engine.lua`
* `xpbar_delves.lua`
* `xpbar_favorites.lua`
* `Config2\OUS2Config.lua`
* all current `Config2\OUS2Page_*.lua`
* `Documentation\OUS2_XPBAR_PARITY.md`
* `CHANGELOG.md`

## Executive Summary

OUS2 is functionally complete for the Phase 5.6 parity and modernization milestone. The remaining work is polish and minor parity review, not major runtime exposure.

The strongest parity areas are Auto Remount, Fishing Tracker, Openables, Toolbox, Utilities, Flight Master advanced controls, Stats Bar, Delves, Help, and the XP Bar Favorites selector bridge.

The remaining review items are concentrated in:

* General/global configuration: legacy central module-toggle placement still needs a final product decision.
* XP Bar: Reputation reset scope remains intentionally conservative and should stay documented.
* Final OUS2 polish: a UI consistency pass should still verify spacing, copy, and popup layering across pages.

## Module-by-Module Findings

| Module / Area | Legacy surface | OUS2 surface | Classification | Notes |
|---|---|---|---|---|
| General | `/ous` General tab central module toggles for Flight Master, Faster Loot, Fishing Tracker, XP Bar, Stats Bar, Openables, Utilities, Toolbox. | OUS2 General dashboard cards navigate to pages; some module pages have local enable toggles. | MISSING | OUS2 does not provide one central module-toggle matrix matching legacy. Flight Master and Faster Loot in particular appear status/config-only without a local module enable toggle. |
| General | `/ous` General `Reset All Settings` with confirmation and reload through `OUS.ResetAllSettings()`. | No OUS2 master reset action is provided. | INTENTIONAL | Master Reset is intentionally rejected for Phase 5.6. Scoped module resets are safer than carrying forward one broad reload-bound reset action. |
| General | Minimap launcher visibility migrated to broker/LibDBIcon. | OUS2 General has `Show Minimap Button` using public Core helpers. | MODERNIZED | OUS2 correctly follows broker-era architecture rather than legacy manual minimap ownership. |
| General | Debug toggle via slash/debug flow, not a classic `/ous` checkbox. | OUS2 General has `Enable Debug Logging`. | MODERNIZED | OUS2 adds a useful global control; verify persistence/session semantics match intended debug design. |
| Flight Master | Legacy `/ous` Flight Master controls: unlock/lock timer bar, map tooltips, width, height, scale, font size, border size, texture, font, border, bar color, border color, export, wipe data, reset defaults. | OUS2 Flight Master exposes tooltip toggle, unlock timer bar, width/height/scale/font/border controls, media/color rows, export, wipe, reset position, reset appearance. | PASS | OUS2 is more structured and uses public helpers such as `OUS.ResetFlightBarPosition()` and `OUS.ResetFlightBarAppearance()`. |
| Flight Master | Legacy reset defaults resets appearance settings together and preserves learned routes except wipe action. | OUS2 splits reset position and reset appearance. | MODERNIZED | Safer and more explicit than legacy; learned times preserved unless Wipe Data is used. |
| Flight Master | Legacy export frame opens above config. | OUS2 uses `C.ShowCopyTextDialog`. | PASS | Frame layering should be checked in-game after any OUS2 shell changes. |
| Flight Routing | No legacy `/ous` configuration tab; runtime taxi-map overlay uses bundled routes and learned flight times. | OUS2 Flight Routing is informational/status-oriented. | PASS | No missing legacy config was found. |
| Faster Loot | Legacy `/ous` Faster Loot tab is informational; behavior is runtime-only and module toggle is in General. | OUS2 Faster Loot page is informational/status-only. | PASS | Feature parity for the module page is present. Missing module toggle is tracked under General. |
| Fishing Tracker | Legacy `/ous` controls auto-close inactive, auto-close mounted, delay 10-60, alpha 0.1-1.0, wipe saved data, reset defaults. | OUS2 exposes enable module, auto-close inactive, auto-close mounted, delay, opacity, show/hide tracker, wipe saved data, reset defaults. | PASS | OUS2 adds local module enable and show/hide action. Wipe/reset scopes match the legacy intent. |
| Fishing Tracker | Legacy wipe confirmation uses `StaticPopup`. | OUS2 uses `OUS2_CONFIRM_WIPE_FISHING` and raises popups above OUS2. | PASS | Popup layering was addressed in the page implementation. |
| Auto Remount | Legacy `/ous` controls enabled, skip druid, silent, debug, spy mode, open spy frame, delay, clear character mount, clear account mount, reset defaults. | OUS2 exposes the same visible controls/actions and writes the same DB keys. | PASS | OUS2 uses existing helper paths where available and mirrors DB reset scope. |
| Auto Remount | Legacy slash commands manage custom spell list and spy filter. | OUS2 does not directly manage custom spell list or spy filter, but opens the existing Spy Frame. | WARNING | Not a `/ous` config gap, but release notes should keep this distinction clear. Full custom-spell management remains slash/spy-frame owned. |
| Stats Bar | Legacy module/slash config covers enabled, table mode, single/table locks, font size 8-24, table width, template, reset defaults. | OUS2 exposes module enable, lock single-line, font size 8-24, template, table view, table lock, table width, reset defaults. | PASS | Reset scope covers account and character settings, positions, locks, table mode, font size, width, and template. |
| Stats Bar | Legacy reset has no large OUS2-style confirmation. | OUS2 reset uses confirmation. | MODERNIZED | Safer behavior; not a parity blocker. |
| Openables | Legacy Openables module supports enable, auto-open, lock/unlock, scale, reset position, blacklist/custom/mass-add managers, counts/status, clear blacklist, wipe custom DB, export custom DB. | OUS2 exposes enable, auto-open, lock, scale, reset position, blacklist count/open/clear, custom count/open, mass add, export DB, wipe custom DB, status. | PASS | OUS2 is now stronger than legacy `/ous` and delegates management frames safely. |
| Openables | Runtime button now aggregates duplicate non-stackable itemIDs. | OUS2 does not need a separate config control. | PASS | Runtime behavior is outside config parity and is already represented by the button display. |
| Utilities | Legacy `/ous` controls Utilities module, Rare Announcer, Auto Repair, Guild Repair, Announce Repair, Junk Seller, Require Shift, Announce Junk Sale, Limit to 12, and Junk Seller blacklist management via `/js`. | OUS2 exposes the same DB-backed toggles and a `Manage Blacklist` action that opens the existing manager. | PASS | OUS2 includes blacklist count and frame-layering hooks. |
| Utilities | Rare Announcer action itself is slash-command driven (`/ous_rare`). | OUS2 provides enable toggle but no in-page announce button. | INTENTIONAL | The legacy config does not provide a target announce button either. |
| Toolbox | Legacy `/tb` controls show/hide, lock/unlock, scale 0.5-2.0, horizontal/vertical layout; Toolbox has Openables quick-action popup. | OUS2 exposes status, show/hide, lock, horizontal/vertical direction, scale, and reset position through public Toolbox helpers. | PASS | Lock/unlock uses `OUS.LockToolbox()`, direction uses `OUS.SetToolboxDirection()`, scale uses `OUS.SetToolboxScale()`, reset position uses `OUS.ResetToolboxPosition()`, and initialization status uses `OUS.IsToolboxInitialized()`. Toolbox modernization is complete for Phase 5.6. |
| Toolbox | Legacy Toolbox frame only initializes when enabled at addon load. | OUS2 page reports Initialized or Disabled until reload through `OUS.IsToolboxInitialized()`. | PASS | OUS2 accurately reflects the runtime creation model and does not manipulate Toolbox internals directly. |
| Toolbox | Per-button visibility beyond existing module-toggle-derived button filtering. | No OUS2 per-button visibility controls. | FUTURE ENHANCEMENT | Requires a separate settings model and user-facing design; not required for current runtime parity. |
| Toolbox | Openables quick-action popup styling/content customization. | OUS2 does not expose popup customization. | FUTURE ENHANCEMENT | Popup entries and behavior remain runtime-owned. |
| XP Bar - Global | Legacy global controls: font size 8-32, hide Blizzard UI with reload prompt, auto-hide, short numbers, rep display time 5-60, fade delay 0-60, active/faded alpha, font, border style/color/size, reset defaults. | OUS2 exposes these controls, uses reload popup, media/color helpers, and section reset. | PASS | Blizzard hide-in-instance disabled checkbox is intentionally not carried forward; runtime hiding remains `OUS.ApplyBlizzardKiller()`. |
| XP Bar - Experience | Legacy controls XP template, XP/rest/background/text colors, width 100-1000, height 10-100, scale 0.5-2.0, rested icon, reset defaults. | OUS2 exposes template, colors, dimensions, rested icon, reset defaults. | PASS | OUS2 dimension ranges now match legacy parity: width 100-1000, height 10-100, and scale 0.5-2.0. |
| XP Bar - Reputation | Legacy controls rep template, rep text color, standing colors, toast enabled, toast sound, modifier, reset defaults. | OUS2 exposes controls and reset defaults for template, text color, colors, and modifier. | INTENTIONAL | Reputation reset remains conservative. It does not clear Favorites because Favorites are user-curated data, not configuration. |
| XP Bar - Favorites | Legacy selector opens from configured modifier-right-click and writes `OdysseusDB.xpBar.favFactions`. | OUS2 Favorites page opens the existing selector via `OUS.OpenXPBarFavoritesSelector()` and does not write `favFactions` directly. | PASS | In-game verification was recorded after `/reload`: opens above OUS2, combat blocks opening, save works, hover dashboard updates, legacy modifier still works. |
| XP Bar - Help | Legacy XP help includes tokens and module commands. | OUS2 XPBar Help includes XP/Reputation/Delves tokens, stats/toast commands, movement notes, favorites notes. | WARNING | OUS2 help is mostly richer, but does not exactly mirror every legacy Help line such as `/ous` and `/ous help` inside the XPBar child help. Addon-wide OUS2 Help covers them. |
| Delves | Legacy XP config controls companion/journey templates, colors, width 100-1000, height 20-100 step 2, scale 0.5-2.0, reset defaults including position. | OUS2 Delves page exposes templates, colors, dimensions, scale, Reset Defaults, Reset Position. | PASS | OUS2 split reset defaults and reset position into scoped actions. This is safer and documented. |
| Delves | Legacy shift-drag movement has no explicit lock checkbox. | OUS2 provides a session-only Lock/Unlock Frame control, ordinary left-drag while unlocked, and Reset Position. | PASS | The edit state defaults locked after reload and does not add a SavedVariables key. |
| Help | Legacy `/ous help` standalone help remains. | OUS2 Help page exists and is read-only. | PASS | OUS2 does not change `/ous help`; parity is achieved for addon-wide help availability. |
| Changelog | No legacy `/ous` changelog page. | OUS2 Changelog read-only page exists. | OUS2-only / MODERNIZED | Useful addition, not a legacy parity requirement. |
| Changelog | Static in-game changelog text. | OUS2 now renders a compact newest-first scrolling release-notes viewer synchronized with `CHANGELOG.md`. | PASS | The old card layout was removed. The page strips simple Markdown bold markers while preserving a single-scroll release-notes layout. |

## SavedVariables and Defaults Review

| Area | Classification | Notes |
|---|---|---|
| Account module toggles | MISSING | Legacy central toggles live under `OdysseusDB.modules.*`. OUS2 spreads some module toggles into pages and omits central parity. |
| Master reset | INTENTIONAL | A full OUS2 master reset is intentionally rejected for this phase because the legacy action is broad, destructive, reload-bound, and cuts across mature module ownership boundaries. Scoped module resets remain preferred. |
| Minimap DB | MODERNIZED | OUS2 uses broker-safe `OdysseusDB.minimap.hide` via Core helpers. |
| Flight Master defaults | PASS | OUS2 covers appearance and position reset through public helpers. |
| Fishing defaults/history | PASS | OUS2 separates settings reset from history wipe. |
| Auto Remount account/character DB | PASS | OUS2 uses `OdysseusDB.autoRemount` and `OdysseusCharDB.autoRemountChar` with scoped clear actions. |
| Stats Bar account/character DB | PASS | OUS2 reset matches broad legacy scope. |
| Openables DB | PASS | OUS2 preserves `blacklist`, `customItems`, position, lock, scale, and auto-open structure. |
| Toolbox DB | PASS | OUS2 uses public Toolbox helpers for lock, direction, scale, reset position, initialization status, and show/hide; no direct runtime-state manipulation is required. |
| XP Bar DB | PASS | Exposed XP Bar settings now match the Phase 5.6 parity scope. Favorites remain user-curated data and are not cleared by Reputation reset. |
| Delves DB | PASS | OUS2 uses existing XP Bar Delves keys and scoped reset actions. |

## Runtime Behavior and Helper Review

| Runtime area | Classification | Notes |
|---|---|---|
| Reload prompts | PASS | XP Bar hide Blizzard behavior has OUS2 reload popup. Legacy exact wording differs but behavior is equivalent. |
| Popup confirmations | PASS | Wipe/reset confirmations exist where risk is high. Some OUS2 confirmations are safer than legacy. |
| Frame layering | WARNING | OUS2 pages generally use `FULLSCREEN_DIALOG`, `C.ShowCopyTextDialog`, `C.OpenColorPicker`, and popup raising helpers. Full in-game layering regression pass is still recommended. |
| Public helper use | PASS | OUS2 uses public helpers for Flight Master, Favorites, Openables, Utilities blacklist, StatsBar locks, and XP Bar apply flows where available. |
| Combat guards | PASS | Runtime combat-sensitive areas remain in engines; XP Favorites selector and hover popup are guarded. Openables secure button architecture is preserved. |
| Dynamic UI counts | PASS | Openables blacklist/custom counts and Utilities junk blacklist count refresh in OUS2. |
| Toolbox scaling model | PASS | Toolbox follows the Flight Master scaling philosophy: the movable parent frame remains at `SetScale(1)`, while saved scale is folded into dimensions, spacing, and child button sizes. This fixes the scale-position drift observed when changing scale from OUS2 or `/tb scale`. |
| Static pages | PASS | OUS2 Help remains static by design. OUS2 Changelog has been redesigned and synchronized as a compact newest-first release-notes viewer. |

## Engineering Implementation Notes

### Toolbox Scaling

Toolbox no longer relies on frame-level `SetScale()` for the movable parent frame.

The runtime now follows the Flight Master scaling model:

* the parent frame remains at `SetScale(1)`;
* `OdysseusDB.toolbox.scale` remains the saved user setting;
* scale is folded into button dimensions, frame padding, button spacing, and child control sizes during layout.

This is an implementation decision, not a new user-visible feature. It prevents frame position drift during live scaling because the movable frame's anchor coordinate system no longer changes when the user adjusts scale from OUS2 or `/tb scale`.

## Legacy-Only Functionality

* REVIEW: Central legacy General tab module-toggle matrix placement.
* INTENTIONAL: Legacy General `Reset All Settings` master reset is not carried forward into OUS2.
* INTENTIONAL: Reputation reset does not clear Favorites because Favorites are user-curated data, not configuration.
* REVIEW: Some module enable/disable behavior remains page-local or status-only rather than matching legacy General's central toggle workflow.

## OUS2-Only Functionality

* MODERNIZED: OUS2 dashboard cards and left navigation.
* MODERNIZED: OUS2 Help page.
* MODERNIZED: OUS2 Changelog page is now a compact newest-first scrolling release-notes viewer rather than a card layout.
* MODERNIZED: OUS2 XP Bar Favorites action opens the existing selector without direct DB writes.
* MODERNIZED: OUS2 Toolbox controls use public Toolbox helpers for runtime operations and avoid direct internal state manipulation.
* MODERNIZED: OUS2 Delves page as separate left-navigation page.
* MODERNIZED: Safer split reset actions for Flight Master and Delves.
* MODERNIZED: Minimap launcher visibility follows broker/LibDBIcon ownership.

## Documentation Mismatches

* PASS: `Documentation\OUS2_XPBAR_PARITY.md` has been synchronized with the completed XP Bar range updates and current reset-scope decisions.
* PASS: `CHANGELOG.md` has been synchronized with the completed Toolbox modernization, XP Bar parity, and Changelog redesign work.

## Recommended Release-Readiness Patch Order

1. General parity review:
   * Decide whether OUS2 should add a central module toggle matrix or keep module toggles on individual module pages.
   * Keep the legacy full-addon master reset out of OUS2 unless a future milestone deliberately reopens the decision.
2. Final OUS2 polish pass:
   * Review spacing, copy, disabled states, status language, and visual consistency across completed pages.
3. Final in-game regression pass:
   * `/reload`
   * `/ous` vs `/ous2` value comparison for every module.
   * Popup layering over OUS2.
   * Reset scopes.
   * Combat-safe blocked actions.
   * SavedVariables persistence after reload.

## Validation Commands

For this audit report:

```bat
git diff --check
git status --short
```

For future code patches:

```bat
luacheck Config2\OUS2Page_<changed>.lua
git diff --check
```

## Final Result

OUS2 is functionally complete for the Phase 5.6 parity and modernization milestone.

## Final Polish

* Finish General module-toggle parity review.
* Keep Reputation reset scope documented as intentionally conservative.
* Complete a final OUS2 polish and UI consistency pass.
