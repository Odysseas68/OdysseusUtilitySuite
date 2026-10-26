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
* [x] Shared Midnight Railway native Slider with fixed capsule thumb, smooth wheel scrolling, and footer clearance
  * User-reported acceptance covers dragging, FlightMaster bottom reachability and Railway appearance. Changelog and XP Bar Help retain their styled native inner scrollers; Help-to-settings restores the outer Slider.
  * [ ] Visually approve restored three grip marks and complete the remaining inner-clipping, transition, resize and combat/taint acceptance cases in [Finding 009](OUS_RETAIL_API_AUDIT_2026-10-25.md#housekeeping-runtime-009).

### Help Panel and Sidebar
* [x] Persistent Help text area
* [x] `C.SetHelpText(text)`
* [x] `C.ClearHelpText()`
* [x] Optional page-specific sidebar container
* [x] Hide/show sidebar frame with active page

### Public API
* [x] `OUS.Config2.RegisterPage(name, frame, refreshFn, sidebarFrame, refreshCurrentFn)` (optional retained-page callback; existing registrations remain supported)
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
* [x] Initial visual-only layout phase completed; card navigation and global controls are now wired

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
* [x] Click card -> `OUS.Config2.OpenPage(pageName)`
* [ ] Optional selected/current-page visual state

### Information Panel
* [x] Wide Information panel below module grid
* [x] Version display
* [x] Addon description
* [x] Build/date display from TOC metadata
* [ ] Final text/content pass

### General Sidebar
* [x] General page sidebar frame
* [x] Global Options card
* [x] Reset card
* [x] Sidebar blocks use `CardNormal`
* [x] Initial sidebar layout completed; minimap and session debug controls are now functional, while profile tools remain placeholders
* [ ] Micro-adjust Global Options spacing
* [ ] Micro-adjust Reset card spacing
* [ ] Add hover help later if needed

### Global Options
* [x] Show Minimap Button row (implemented and wired)
* [x] Enable Debug Logging row (implemented and wired for the current session)
* [x] Wire Show Minimap Button to real setting
* [x] Wire Enable Debug Logging through the existing session debug API (not a new persistent preference)
* [x] Migrate manual minimap button to LibDataBroker-1.1 + LibDBIcon-1.0 for broker-compatible launcher support
  * [x] Treat third-party minimap manager visibility as owned by the manager; avoid addon-specific workarounds

### Reset
* [x] Visual-only Reset sidebar explanation
* [x] Keep footer Reset to Defaults button
* [ ] Review global/reset-scope consistency and native acceptance; preserve implemented module resets and history-wipe separation
* [x] Utilities reset/toggle coverage implemented; Finding 004 has bounded runtime closure. This does not establish every global reset scenario

### Current Polish
* [ ] Review module card vertical alignment
* [ ] Review right sidebar card padding
* [ ] Review Information panel balance
* [ ] Review layout at minimum size
* [ ] Review layout after resizing wider/taller
* [ ] Screenshot/accept the final General page layout; functionality is already implemented
* [x] Implement OUS2 combat lifecycle: block new combat opens, conservatively close on combat entry, retain page, no automatic reopening, owned editor/preview cleanup
* [ ] Complete native combat/editor/preview acceptance from the audit lifecycle addendum; do not infer exhaustive safety from implementation or Finding 010 general acceptance

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
  * [x] Session Stats Stage 1 display and built-in Mistcrest settings
  * [x] Scrollable Help child
  * [x] Sliced template edit boxes

* [x] Delves page
  * [x] Configuration access consolidated under the XP Bar hub
  * [x] Standalone sidebar and General dashboard entries removed
  * [x] Companion and Journey template settings
  * [x] Delves dimension settings
  * [x] Back to XP Bar navigation

---

## Phase 5 — Polish & Advanced Controls

Phase 5.6 OUS2 legacy parity is in its final stage.

Completed Phase 5.6 parity areas:

* [x] Auto Remount
* [x] Stats Bar
* [x] Fishing Tracker
* [x] Openables
* [x] Utilities
* [x] Help
* [x] Changelog

XP Bar, Reputation and Delves migration is implemented. Remaining final parity/reset-scope decisions and review evidence are tracked in `Documentation\OUS2_XPBAR_PARITY.md`; do not reopen completed migration or duplicate that detailed checklist here.

### OUS2 Left-Navigation Pages

* [x] Help Page
  * [x] OUS2 Help page frame
  * [x] Overview section
  * [x] Module documentation
  * [x] Slash command reference
  * [x] Scrollable layout
  * [ ] OUSBanner at top after banner is recreated/reviewed

* [x] Changelog Page
  * [x] OUS2 Changelog page frame
  * [x] Scrollable version history
  * [x] Current version highlighted
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
* [x] Initial module master-toggle source review completed
* [ ] Review remaining module-toggle interactions and native acceptance individually; existing OUS2 controls are not generally missing, and a source review is not universal runtime parity
* [x] Verify Utilities master toggle coverage
* [x] Verify Utilities reset coverage
* [x] Resolve `/ous2` slash ownership
* [x] Current file and TOC both use `FlightData.lua`; no rename is required
* [x] Verify legacy flight data access: saved times, `SFT_FlightData`, then `OUS.FlightData` fallback remains supported; do not remove compatibility without separate authorization
* [x] Migrate legacy Config.lua functionality into OUS2 where appropriate
* [x] Migrate supported `xpbar_config.lua` functionality into the XP Bar and Delves OUS2 pages
* [x] Complete XP Bar / Reputation / Delves OUS2 parity per `Documentation\OUS2_XPBAR_PARITY.md`
* [x] Integrate Help.lua content into OUS2 Help page
* [x] Preserve `/ous` as the OUS2 entry point and retain `/ous2` as an alias
* [x] Retire legacy `Config.lua` and `xpbar_config.lua` after parity and migration validation
* [ ] Optional folder restructure only after OUS2 is stable

### Junk Seller Native 3D — Current Implementation and Acceptance

* [x] Optional native Goblin implemented alongside existing 2D Goblin/Coin FlipBooks: display 6882, Merchant Counter v2, actual 96/64/32 square viewports, independent camera-distance slider and isolated OUS2 Play Test Animation preview.
* [x] **Runtime-tested (bounded):** user approves textured rendering, Merchant Counter v2, preferred 64x64 merchant presentation at distance 1.2, Loot animation during selling and the independent configuration preview. Visual design is accepted; no further visual polishing is requested.
* [ ] Complete broader production regression acceptance: combat transitions, fallback, rapid mode/size switches, merchant close/reopen and relevant default/Krowi layouts. The approved appearance does not establish these cases.
* Defaults remain 3D OFF, size 96, camera distance 1.2; existing 2D selection remains default/fallback. Research probes and prior research history remain separate from production acceptance.

### Future Utilities Enhancements

* [x] **OUS-UTILITIES-VENDOR-001 — Junk Seller button positioning and conditional visibility.**
  * **COMPLETE — IMPLEMENTED — RUNTIME TESTED (bounded user acceptance, 2026-10-26).** `Utilities.lua` creates a 120×38 two-line Midnight button parented to `MerchantFrame`, with final user-selected TOPRIGHT anchor to its BOTTOMRIGHT at (-1, 1). This standard owner-frame relationship follows movement, column resizing, Buyback resizing and banner-height changes without a Krowi dependency or screen-coordinate calculations.
  * Final animated portrait: separate, mouse-transparent **36×38 MerchantFrame child**, six pixels left of the button, with dark Midnight backing, lighter inset and one-pixel purple border. Goblin artwork stays **28×28**; coin artwork **16×16**. Portrait visibility is independent of the button. Goblin Counting Gold is the default; both choices use native FlipBook. User acceptance covered approved visuals, idle/selling/completion, live counts, 12-entry continuation, Shift held on merchant opening, animation selection and /reload persistence, plus merchant Escape-close/reopen during selling. See [dedicated research and runtime closeout](OUS_JUNK_SELLER_COIN_ANIMATION_RESEARCH.md#14-runtime-verification-and-closure--2026-10-26) for evidence and limits.
  * Read-only reference: installed Krowi Extended Vendor UI **24.1**. `Gui/MerchantFrame.lua:70–82` resizes Blizzard's `MerchantFrame` for columns/rows; `addon.Gui.MerchantFrame` is a helper table, not a separate outer frame. Four columns add two item-column widths relative to two columns; Buyback restores captured baseline dimensions. `Gui/TokenBanner/TokenBanner.lua:51–55, 97–122, 233–251` places the Token Banner inside `MerchantMoneyInset`, updates its height and requests merchant resizing. Buyback does not hide that banner. Krowi's inspected persistent bottom controls/insets are inside the merchant; Blizzard's tabs extend below its lower-left edge. No permanent lower-right external control was found in these inspected paths; other addons and screen-edge fit still require native review. No bundled libraries needed inspection or modification.
  * With a nonempty queue and enabled module/seller, show the button when **Limit Sales to 12 OR Require Shift** is enabled; hide when both are off, queue empty, seller/master disabled or merchant session cancelled. Both-off selling remains automatic. Labels retain pending-entry counts and use `Selling...` during active work, otherwise `Sell Next 12` or `Sell All Junk`, on two lines. The button may remain visible during a configured batch, preserving existing manual entry behavior.
  * Original positioning-phase implementation: existing OUS2 seller-enable, Require Shift and batch-limit rows notify `OUS.ApplyJunkSellSettings()` so visibility updates immediately. One transient waiting-at-batch-limit flag permits resuming a paused queue when both controls are removed, without restarting an active sequence or resetting its partial accounting. Existing Shift checks, batch report logic, generation cancellation, blacklist, pricing/quantity/accounting, 0.3/0.2-second delays and combat guards remain intact. No SavedVariables/defaults changes, extra polling or third-party calls were added.
  * Original positioning-phase files: `Utilities.lua` for the button/visibility helper and paused-queue option transition; `Config2/OUS2Page_Utilities.lua` only for three existing setting callbacks; this TODO for the compatibility record. The audit document and OUS-AUDIT-009 remain unchanged and separate.
  * Historical positioning-phase offline validation: Lua 5.1 syntax passed for both Lua files; targeted LuaCheck remained **34 warnings / zero errors** (Utilities 34, page 0), matching baseline. **36/36 deterministic checks passed** using actual OUS modules with mocked frames/item/merchant APIs, including the 26 earlier Utilities checks, all four option combinations, empty/remainder queues, automatic continuation after removing controls, real OUS2 option callbacks, combat/cancellation and the installed Krowi resize-function formula in isolation. Mock anchors/formulas do not establish native geometry, font fit, taint or third-party event ordering. Final scoped diff and whitespace validation are checked before handoff.
  * Count-refresh follow-up: refresh the existing presentation helper after each sold or skipped queue entry; a transient active-work flag keeps the action label accurate and prevents option refreshes from restarting active work. Removing Require Shift starts an initially waiting queue through the existing guarded batch entry point; a paused 12-entry boundary still requires confirmation unless both controls are removed. The count remains queued entries, not physical stack quantity. Generation cancellation, transaction logic and continuation timing remain intact. Subsequent user-reported testing confirmed the live counter and batch continuation; the dedicated closeout records the tested scope and remaining limits.
  * **Animation integration history (2026-10-26; followed by the runtime closure below).** Standalone Coin Spin V3 and Goblin Counting V4 FlipBooks were observed playing in WoW; their unchanged assets are copied to `media/Textures/`. Goblin Counting Gold is the default account-wide `utilities.junkSell.animation = "goblin"` choice; `"coin"` selects Spinning Coin. Core backfills only missing/invalid selection. A themed OUS2 two-choice action selector beside Manage Blacklist updates presentation without touching transaction state. The final mouse-transparent 36×38 MerchantFrame child, anchored RIGHT to the button's LEFT at (-6, 0), shows Goblin at 28px or Coin at 16px independently of button visibility, for all four selling-option combinations and empty queues. Running work plays; scheduled start, Shift/batch waiting and completion show the idle cell. Hide/disable/cancellation stop/reset; mode changes reuse one group. The approved button remains 120×38 at (-1, 1), with unchanged styling, visibility and clicks. Offline: Lua 5.1 passed; LuaCheck 74 warnings / zero errors across Utilities/Core/page, matching baseline; 17/17 focused checks passed, including before/after sale/accounting/timer comparisons. These were offline integration results, not native runtime proof. Section 13 of `OUS_JUNK_SELLER_COIN_ANIMATION_RESEARCH.md` records implementation; Section 14 records subsequent user acceptance and untested edges.
  * Historical WoW acceptance plan: compare default merchant and Krowi 2/4 columns on Merchant/Buyback with Token Banner visible; move/resize the window and verify lower-right alignment and tab/banner clearance. Check both-off automatic selling with hidden button, each Shift/batch combination, empty queue, 12-item continuation, toggling options while open, reopening, master disable and combat. This was the pre-acceptance plan; completed observations and the remaining limits are recorded in the dedicated closeout. Krowi and its libraries are read-only references and must remain unchanged.
  * Closure limits: disabling Utilities mid-sale, exhaustive rapid-toggle/cancellation permutations, every Blizzard/Krowi layout combination and exhaustive taint/combat behavior were not directly runtime tested for this enhancement. These bounded remaining cases do not block closure and do not imply formal verification of the selling system.

* [ ] **OUS-UTILITIES-ZONEABILITY-001 — Duplicate Extra Abilities Button**
  * **Status: TODO — Research pending.** User-reported behavior: Blizzard Edit Mode labels the relevant element "Extra Abilities". Dragging a Zone Ability into an empty action-bar slot initially removes the floating ability button as expected, but it sometimes reappears later while the ability remains assigned to the action bar, creating an unwanted duplicate and occupying additional UI space.
  * Identify the exact Blizzard frame(s) responsible and distinguish `ZoneAbilityFrame` from `ExtraActionButton1`. Determine what triggers reappearance, compare with OUS enabled and disabled, and do not assume OUS is the cause.
  * Inspect current Retail Blizzard source and the visibility lifecycle; investigate action-slot ownership and updates. Evaluate an optional setting to suppress the duplicate floating button.
  * Respect combat lockdown, protected-frame restrictions, and taint safety. Preserve the existing Hide Extra Action / Zone Ability Artwork functionality.
  * Future research only: do not implement a workaround or behavior change until separately authorized.

### Future Openables Recognition Research

* [ ] **OUS-OPENABLES-DYNAMIC-001 — Research hybrid openable-item recognition.**
  * User-reported context: 93 additional items are currently in the OUS custom list. The user uses locally installed NOP (New Openables – Continued) to discover eligible items missing from OUS.
  * Read-only third-party reference: `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\NOP\`. Identify the exact installed version before drawing conclusions about its implementation.
  * Investigate the supplied NOP recognition approach: known item spells, explicit item-ID rules, known tooltip patterns, and dynamic item classifications. Compare it with OUS's existing dynamic categories.
  * Evaluate which of the 93 custom items can safely be recognized automatically; investigate shared item spells and narrowly defined tooltip patterns, measure false positives and possible database reduction, and preserve existing minimum quantity requirements.
  * Treat unknown or secret tooltip information conservatively. The generic `Use:` prefix is insufficient: food, flasks, potions, and other ordinary usable items also contain it.
  * Research only until separately authorized: do not implement dynamic recognition, remove or migrate custom/built-in entries, or modify NOP.

### Future Openables Quest Item Companion

* [ ] **OUS-OPENABLES-QUEST-001 — Quest Item Companion Button**
  * Future design/research only; implementation requires separate authorization. Keep this task separate from OUS-OPENABLES-DYNAMIC-001: quest-item interaction and dynamic loot-container recognition have different requirements and safety considerations.
  * Design a smaller companion button adjacent to the existing larger Openables button. Display eligible usable quest items separately from ordinary loot containers; never mix them into the normal Openables item rotation. Preserve the main button and its existing behavior.
  * Support objectives requiring direct item use or use on a specific NPC/target. Do not assume an item is usable merely because it appears in the quest log, and avoid automatic quest-item activation.
  * Hide the companion when no eligible quest item is available. Research multiple eligible items before choosing selection or cycling behavior; determine positioning, visibility, tooltip, and scale behavior during design.
  * Inspect current Retail quest-item and action-button APIs to establish reliable detection of quest items requiring player interaction. Investigate objective completion and item eligibility changes, including quests requiring an NPC, enemy, object, or other specific target.
  * Investigate secure actions, combat lockdown, protected frames, and taint risks while preserving compatibility with the existing Openables button. Avoid unnecessary polling and repeated full quest scans.
  * Read-only third-party reference: `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\NOP\`. The user has NOP (New Openables – Continued) installed and uses it as a discovery reference. Study its quest-item handling during future research; do not modify NOP or copy its implementation wholesale.

### Future Delves Display Enhancement

* [x] **OUS-DELVES-IDS-001 — Display Instance ID and Map ID beneath Delves bars.**
  * **IMPLEMENTED — RUNTIME TESTED.** User-reported WoW verification in **The Labyrinth of Kindo'jan** displayed **Instance ID: 3043 | Map ID: 2647** beneath the progress bars. Companion/Journey text remained readable, with no obvious positioning or overlap problem observed. Bars stayed visible after all nine chambers and disappeared after leaving.
  * This observed ID pair is location evidence, not a universal classification rule. No detection heuristics, ID/exclusion tables, or Alt+Left-click diagnostic behavior were changed for this runtime record.
  * One child FontString is centered 4 UI pixels below the Journey bar, constrained to its width, with muted gray text and the shared font family at a smaller readable size. It inherits parent movement, scale, alpha and visibility; existing progress-bar geometry is unchanged.
  * The existing renderer uses the eighth `GetInstanceInfo()` return and `C_Map.GetBestMapForUnit("player")`. Missing IDs show `-`; unlocked preview outside a real Delve shows `Instance ID: Preview | Map ID: Preview`. No new timer/polling, SavedVariables or defaults were introduced.
  * Historical Codex offline evidence remains separate: Lua 5.1 syntax passed for all three implementation files; LuaCheck 101 warnings / zero errors versus baseline 100 (one added undefined-global warning for the existing `GetInstanceInfo` API); 12/12 mocked deterministic checks passed. The earlier implementation task's final diff review and `git diff --check` passed. These checks were not rerun for this documentation-only runtime update.
  * Remaining limits: the reported run does not independently establish every preview, unavailable-ID, narrow-width, font/scale, screen-edge, fade or combat case. OUS-AUDIT-006 remains partially runtime verified: non-max exact-zero progress, confirmed maximum renown and unavailable progression data were not tested.

### Future Module Candidate: BuffBars
* [x] Create initial `Documentation/BUFFBARS_DESIGN.md`
* [x] Document `Reference\OdysseusBuffBarsTest\` as a validated 12.0.x proof-of-concept
* [x] Document WoW 12.1 aura API risk as a production integration blocker
* [ ] Keep `Reference\OdysseusBuffBarsTest\` frozen as the validated 12.0.x reference
* [ ] Research WoW 12.1 PTR `ManagedAuraContainer`, `AuraContainer`, and `AuraButton` patterns
* [ ] Build a separate 12.1 aura-container prototype before OUS integration
* [ ] Reassess direct `C_UnitAuras` index/instance-ID scanning after 12.1 PTR API details stabilize
* [ ] Decide whether BuffBars should enter Phase 6 as a gated or disabled-by-default module skeleton after 12.1 research
* [ ] Design `OdysseusDB.buffBars` defaults before adding code
* [ ] Port the aura engine only after the 12.1 research and design contract are approved
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
* [x] OUS2 becomes the primary configuration surface (`/ous`, with `/ous2` as an alias)

---

### Stats Bar Follow-Up Review

Future design review required:

- Audit legacy Stats Bar enable semantics.
- Existing OUS2 controls expose account-wide module enable (`OdysseusDB.modules.statsBar`) and per-character table enable (`OdysseusCharDB.statsBar.tableEnabled`).
- Review the separate per-character single-line enable (`OdysseusCharDB.statsBar.enabled`, currently managed through existing runtime commands) before adding another control.
- Document intended interaction between account-wide and character-specific visibility settings.
- Add any further control only after its interaction and persistence rules are defined and verified; do not treat existing module/table controls as absent.

---

### Fishing Tracker Follow-Up Review

- Completed in 1.0.7: The Coiled Huntress (item 244790) current Venom display beside fishing skill, using authoritative structured inventory-tooltip text and event-driven refresh without an internal counter. Equip/unequip/re-equip, applicable catch updates, and the tested spend/convert path passed WoW runtime testing.
- Completed display controls: frame scale and LibSharedMedia font selection.
- Completed classified Fish/Currency/Other summaries, Fish-only statistics rows, corrected Zone Fish totals, and the Zone Catch Details drill-down.
- Next: Fishing Tracker Session Statistics.
- Implemented: Wipe History with confirmation, settings-only Reset Defaults preserving history.
- Remaining: native reset/history-preservation and position-management acceptance; future Session Statistics remains a separate expansion.

---

### Flightmaster Follow-Up Review

- Completed in 1.0.6: optional destination-node Blizzard tooltip suppression, ownerless re-show preservation, destination name/zone, and bounded dynamic tooltip sizing. WoW testing passed with Zygor enabled/disabled, node movement/leave, map close/reopen, disabled module/tooltips, current-node presentation, and short/long destination layouts. Temporary runtime trace removed after validation; combat validation was not reported.
- Completed OUS2 advanced-control parity: media selectors, color rows, unlock/drag preview, export, wipe confirmation, reset position, and reset appearance.
- Existing OUS2 Enable Flight Master control calls `OUS.SetFlightMasterEnabled()`. Remaining: review/accept master-toggle behavior during active flight; the control is already exposed. Finding 011 has bounded normal-flight acceptance, not proof of nil-map behavior.

---

### Toolbox Follow-Up Review

Implemented: Toolbox scale control and Reset Position, with existing module enable/show-state separation.

Future Toolbox expansion ideas:

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

Future expansion requires suitable public APIs and OUS2 controls; existing scale/reset controls do not need reimplementation.

---

### XP Bar Follow-Up Review

- Migration and principal controls are implemented; remaining XP Bar, Reputation, Favorites, Delves, reset-scope and final review decisions are tracked in `Documentation\OUS2_XPBAR_PARITY.md`.
- Keep this section high-level and preserve the detailed checklist as implementation/review history.
- Session Stats Stage 1 is complete: the subsystem is separated from the XP Bar engine, its scrollable runtime view covers XP, reputation, gold, repairs, and five default-enabled Midnight Season 2 Mistcrests, and its persistent display controls live under XP Bar. Release 1.0.1 added guild-repair and physical junk quantity/value breakdowns, known merchant-wallet reconciliation, confirmed session resets, and Gold Diagnostics with help. Release 1.0.3 removed the Guild Repairs breakdown and introduced conservative guild-first funding attribution. Release 1.0.5 rebaselines session XP on initial login and reload so existing character progress is not counted as newly gained XP. The current single Repairs (Own + Guild) total records each full known OUS repair bill while Gold Spent continues to reflect observed personal-wallet spending without inferring a guild/personal split.
- Future Session Stats resource work may include custom Currency IDs, additional curated built-ins, `ITEM` resources kept architecturally distinct from `CURRENCY`, optional validated Blizzard Currency UI discovery, and search/filtering for larger lists.

---

## Current Focus

**Phase 4 — Completed**

- Module page migration completed.
- XP Bar migration completed.
- Delves configuration consolidated under XP Bar without removing its runtime functionality or settings.
- Openables page implemented and tested.
- Shared scale control implemented and adopted.
- Documentation synchronized.

**Phase 5 — Polish & Advanced Controls**

Current focus is Phase 5.6 — OUS2 legacy parity final stage.

1. General page polish
2. Enabled/disabled card states
3. Module count summary
4. Global Options visual/runtime acceptance (wiring implemented)
5. Global reset-scope review and native acceptance
6. Close remaining XP Bar / Reputation / Delves final review decisions per `Documentation\OUS2_XPBAR_PARITY.md`
7. Toolbox expansion
8. Faster Loot rules
9. Helper extraction

**Phase 5.5 — Framework Consolidation**

Purpose:
Consolidate the OUS2 framework and engineering infrastructure after Phase 5 feature completion before starting Phase 6.

Tasks:
- Review Codex skills for overlap and consistency.
- Extract stable shared helpers after patterns have stabilized.
- Remove obsolete compatibility code and stale comments.
- Verify all OUS2 pages follow the same architecture and coding patterns.
- Review active documentation for future drift (README_v2, ARCHITECTURE, TODO, CHANGELOG, AGENTS); preserve retired guidance only in historical evidence. Finding 012 reconciliation is completed below.
- Review file headers and version dates.
- Perform a lightweight Retail API audit against the current Interface version.
- Review event registrations, timers, and helper reuse for maintainability.

Exit Criteria:

- Documentation synchronized.
- Codex skills synchronized.
- No duplicate helper functions.
- Shared UI patterns stabilized.
- No known architectural debt blocking Phase 6.

## Release Prerequisites — Next Release Not Yet Prepared

These five activities are required before the next release; no new version or build date is selected by this checklist.

* [ ] Update the addon Version in `OdysseusUtilitySuite.toc`.
* [ ] Update/verify the OUS2 General version display against TOC metadata.
* [ ] Update/verify the OUS2 General build date; coordinate TOC `X-Build-Date` with that display.
* [ ] Update the in-game OUS2 Changelog.
* [ ] Update `CHANGELOG.md` with the same release substance.

General reads Version and X-Build-Date from the TOC; there are no separate current-version/build literals to invent. Lua source-header dates are separate. Release metadata and changelog edits are deferred to an authorized release task.

## Documentation Reconciliation — 2026-10-26

**OUS-AUDIT-012 — Documentation corrected.** Completed implementation is distinguished above from runtime-pending acceptance, polish, deferred architecture and future research. Preserve the bounded statuses and acceptance limits in the [audit finding index](OUS_RETAIL_API_AUDIT_2026-10-25.md#finding-status-index), including 006 edge cases, 007 ChallengeMode/combat overlap and 009 remaining scrollbar acceptance. Openables dynamic recognition/quest companion, duplicate Zone Ability research, BuffBars, helper extraction and optional expansion remain separate future/deferred tasks.
