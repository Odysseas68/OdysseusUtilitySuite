# OUS read-only technical audit

> Preserved audit dated October 25, 2026. The general audit below is the preceding Codex report, with presentation-only link conversion, Markdown spacing normalization, and stable finding anchors. Its severities, evidence qualifications, validation results, recommendations, and verdict are preserved. OUS references identify commit `6edb423d55a214bb6181c8e0af84ca65b245e114`; relative links resolve the checkout and `#L` numbers are historical source references. Blizzard links are pinned to LIVE source commit `15881d522c44cd106d3d8660106ec9f9d2f44167`. Later research is recorded separately at the end.

## Finding-status index

All findings initially had status **OPEN — Awaiting review/research.** Current dispositions are listed below. Earlier investigation headers and validation records retain their historical status and evidence limits. The [001 runtime addendum](#runtime-observations-001) and [002 runtime addendum](#runtime-observations-002) record bounded user observations and supersede the earlier implementation-decision recommendations: no production change is authorized for either finding. Preserve existing combat hiding for 001 and retain the source-supported concerns. The 001/002 observations do not establish safety for every item, modifier, environment, or client state. Finding 003 is resolved following its implementation and the [bounded user-reported runtime verification](#runtime-verification-003); the remaining timing and physical-item identity limits are retained in that addendum.

| ID | Severity | Module / subject | Status |
|---|---|---|---|
| [OUS-AUDIT-001](#ous-audit-001) | HIGH | Openables secure-frame operations during combat | RUNTIME TESTED — Monitoring. |
| [OUS-AUDIT-002](#ous-audit-002) | MEDIUM | Openables right-click action ownership | RUNTIME TESTED — Monitoring. |
| [OUS-AUDIT-003](#ous-audit-003) | MEDIUM | Openables delayed auto-open validity | IMPLEMENTED — RUNTIME TESTED — RESOLVED. |
| [OUS-AUDIT-004](#ous-audit-004) | MEDIUM | Utilities master enable switch | IMPLEMENTED — RUNTIME TESTED — RESOLVED. |
| [OUS-AUDIT-005](#ous-audit-005) | MEDIUM | XP/Delves disabled-module rendering | IMPLEMENTED — RUNTIME TESTED — RESOLVED. |
| [OUS-AUDIT-006](#ous-audit-006) | MEDIUM | Delves maximum-renown detection | IMPLEMENTED — PARTIALLY RUNTIME VERIFIED. |
| [OUS-AUDIT-007](#ous-audit-007) | MEDIUM | Stats Bar restriction handling | IMPLEMENTED — RUNTIME TESTED — Monitoring. |
| [OUS-AUDIT-008](#ous-audit-008) | MEDIUM | Fishing Tracker catch attribution | IMPLEMENTED — RUNTIME TESTED — RESOLVED. |
| [OUS-AUDIT-009](#ous-audit-009) | MEDIUM | Flight Master configuration scroll extent | IMPLEMENTED — RUNTIME TESTED (bounded); grip visual approval and remaining acceptance pending; height observation retained. |
| [OUS-AUDIT-010](#ous-audit-010) | LOW | OUS2 current-page refresh | IMPLEMENTED — RUNTIME TESTED — RESOLVED. |
| [OUS-AUDIT-011](#ous-audit-011) | LOW | Nullable map ID in flight-distance helpers | IMPLEMENTED — RUNTIME TESTED (bounded normal flight); nil-map branch native-unobserved. |
| [OUS-AUDIT-012](#ous-audit-012) | OPTIONAL | Documentation consistency | DOCUMENTATION CORRECTED — RESOLVED. |

[Focused Investigation 001 — Openables Combat Safety](#focused-investigation-001)

[Focused Investigation 002 — Openables Right-Click Action Ownership](#focused-investigation-002)

[Focused Investigation 003 — Openables Delayed Auto-Open](#focused-investigation-003)

## Preserved general audit

The statements about unchanged files, completed checks, and mock observations in this preserved section describe the original audit session. They are historical evidence, not checks rerun during the documentation follow-up. This follow-up creates only this Markdown document and performs the separately recorded source investigation.

<!-- BEGIN PRESERVED AUDIT -->

**OUS remains suitable for continued Retail use, with focused maintenance needed.** I found no missing API that requires a suite-wide migration, no Lua syntax failures, and no established CRITICAL issue. The highest-priority finding is an unsafe Openables protected-frame path on combat entry. Several additional defects affect enable switches, delayed actions, progression display, and fishing attribution.

**No files were modified.** No fixes, formatting, dependency updates, commits, pushes, or reference updates were performed.

## A. Executive summary

The audit supports isolated corrections rather than restructuring:

- **Prompt attention:** Openables combat visibility and configuration operations on its secure button.
- **Confirmed logic defects:** Openables delayed actions survive disablement; Utilities ignores its master switch; XP/Delves rendering can show disabled modules; Delves can label uncapped Journey progress as `MAX`; Stats Bar misinterprets restriction type `2`.
- **Source-supported functional concerns:** Openables right-click can execute the use macro under click-on-release settings, and Fishing Tracker’s UI timer can manufacture “recent fishing” evidence.
- **UI follow-up:** Check Flight Master’s scroll extent and refresh configuration controls when reopening the current page.

The recently fixed **FlightMaster/FlightRouting tooltip-suppression handoff remains supported by the inspected source and your reported in-game result**. I found no evidence warranting reopening it. Spell **6247 remains intentionally excluded**, and that decision is not a finding.

## B. Client, source, baseline, and scope

| Item | Examined baseline |
|---|---|
| OUS checkout | `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\OdysseusUtilitySuite` |
| OUS commit | `6edb423d55a214bb6181c8e0af84ca65b245e114` |
| Initial Git state | Clean `main`, tracking `origin/main`; one worktree |
| Installed Retail client | **12.1.5.70575**, product `wow`, from the installation’s `.build.info` |
| Primary Blizzard reference | `D:\WowDEV\Reference\Blizzard\wow-ui-source` |
| Source branch | **`live`** |
| Source commit | `15881d522c44cd106d3d8660106ec9f9d2f44167` |
| Source commit description/date | `12.1.5 (70575)`, October 23, 2026 |
| Reference tracked changes | None reported against source `HEAD` |
| OUS release metadata | Version **1.0.8**, build date **2026.10.09** |
| Declared interfaces | `120000, 120001, 120005, 120007, 120105` |

This establishes a matching installed-client/LIVE-source baseline. PTR and beta checkouts were not used to establish production API facts.

Coverage included the **40 production first-party Lua files**, bundled libraries and their XML load entries, relevant project guidance/documentation, and the separate `Documentation/OUS2ArtTest.lua` validation artifact. The actual load graph includes two files omitted from AGENTS.md’s enumerated order: **`xpbar_sessionstats.lua` and `JunkBroker.lua`**. Both are correctly present in the TOC.

Architecture remains consistent with OUS2 as the production configuration framework:

- Libraries → Core → data → module engines → Help → OUS2 theme/shell/control/pages.
- `/ous` routes to OUS2; `/ous2` remains its alias.
- SavedVariables include account-wide `OdysseusDB` **and `OdysseusFishingDB`**, plus per-character `OdysseusCharDB`.
- The minimap launcher uses the bundled LibDataBroker/LibDBIcon integration.
- No new dependency or database migration is justified by this audit.

The [TOC](../OdysseusUtilitySuite.toc) is the inspected authority for these declarations.

## C. Module-by-module health assessment

| Area | Assessment |
|---|---|
| **Core** | Initialization, launcher registration, slash ownership, and default seeding show no new blocking compatibility problem. Documentation understates the SavedVariables/load graph. |
| **OUS2 configuration** | Registration and shared-control patterns are sound. Current-page refresh and Flight Master content sizing need attention. Openables controls expose its existing combat-safety gap. |
| **FlightMaster** | Retained taxi APIs exist. Learning, early-stop protection, flight-only updates, and suppression ownership remain intact. One nullable-map boundary deserves a focused test. |
| **FlightRouting** | Hover handoff, route/anchor pools, native route queries, and cleanup were inspected. No evidence supports replacing the working handoff or route renderer. |
| **AutoRemount** | Exclusion precedence, built-in authority, structural filtering, interaction ownership, and Spy confirmation boundaries remain intact. Preserve `6247`. Special spell secrecy remains an unproven edge case. |
| **Openables** | Highest maintenance priority: combat operations, click ownership, and delayed-action validity. Current item/container APIs exist. |
| **FasterLoot** | Loot events and slot handling match inspected Retail usage. No new mandatory compatibility correction established. Hidden-parent/Edit Mode behavior remains a focused runtime acceptance area. |
| **Stats Bar** | String caching and the existing protected display-read fallback limit secret-value failures. Restriction-state interpretation is incorrect. |
| **FishingTracker** | Structured Venom reads explicitly reject secret values. Catch attribution can be contaminated by the UI inactivity timestamp. |
| **XP/Reputation** | Modern faction APIs are present. Watched-faction and remembered fallback paths remain. Module-disable rendering and max-level assumptions need focused validation. |
| **Delves** | Existing completion/sticky-companion behavior should be preserved. Journey maximum detection is incorrect for zero-progress uncapped levels. |
| **Session Stats** | Runtime counters, money reconciliation, guild-funding uncertainty, reset baselines, and callback ownership were inspected. No new accounting rewrite is justified. |
| **Utilities** | Merchant queue preserves bag/slot and item-identity checks. The master Utilities toggle is ineffective. |
| **JunkBroker** | Coalesced dirty-bag scans, delayed item information, tooltip ownership, and Session Stats subscription show no new blocking defect. |
| **Toolbox / Help** | Existing pools, popup positioning, shortcuts, and static ScrollBox patterns show no new mandatory API issue. |
| **Data files / libraries** | Structural checks passed. No dependency upgrade is justified solely by this review. Game-data completeness is not established by structural validation. |

## D. Confirmed problems and actionable source findings

“Confirmed” below means an inspected source defect or bounded standalone reproduction. **It does not mean reproduced in WoW.**

<a id="ous-audit-001"></a>

### OUS-AUDIT-001 — HIGH — Openables secure-frame operations during combat

**Location:** [Openables.lua:678](../Openables.lua#L678); related placement/locking code at lines 545–598.

**Description and evidence:** The `PLAYER_REGEN_DISABLED` handler calls `Hide()` on both the container and `opBtn`. The button is created with `SecureActionButtonTemplate` at line 362. Lock/unlock and position/scale paths also manipulate that button and its parent without a common combat guard.

Blizzard’s [SecureTemplates.xml:4](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml#L4) inherits [SecureFrameTemplate, explicitly protected](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplatesBase.xml#L4). The inspected [secure visibility driver](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua#L96) provides Blizzard’s managed show/hide path.

**Fact versus inference:** **A — confirmed unsafe source pattern.** An actual blocked-action report was not reproduced. The existing guard inside `OP.Refresh()` does not protect the separate combat-event or placement paths.

**Potential impact:** Blocked operations or Lua errors on combat entry and when changing Openables placement/locking during combat.

**Minimal correction:** Configure secure combat visibility outside combat, preserving candidate/module visibility rules; defer protected placement, scale, and locking changes until combat ends.

**Runtime verification required:** Yes. **Confidence:** High.

<a id="ous-audit-002"></a>

### OUS-AUDIT-002 — MEDIUM — Openables right-click can also use the item

**Location:** [Openables.lua:517](../Openables.lua#L517); click registration at line 369 and blacklist handling at line 474.

**Description and evidence:** The secure action uses generic attributes:

```lua
type = "macro"
macrotext = "/use item:ID"
```

Right-click is registered, and skipping/blacklisting happens in `PostClick`. There is no left-button-only action attribute or explicit right-button no-op.

Blizzard’s [modified-attribute rules](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L5) define generic attributes as applicable to any button. Its [click dispatcher](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L805) selects the action edge according to key-down settings.

**Fact versus inference:** Confirmed attribute configuration; source-supported execution concern **when click-on-release is selected**. The standalone inspection confirmed the generic action and absence of button-specific overrides.

**Potential impact:** A user trying to skip or blacklist an item can use it first.

**Minimal correction:** Bind item use to left-click only; keep right-click exclusively for skip/blacklist handling.

**Runtime verification required:** Yes, with both `ActionButtonUseKeyDown` settings. **Confidence:** High.

<a id="ous-audit-003"></a>

### OUS-AUDIT-003 — MEDIUM — Openables auto-open callbacks survive disablement

**Location:** [Openables.lua:619](../Openables.lua#L619).

**Description and evidence:** The delayed callback checks only `currentItem` and combat state. It does not recheck the module switch or `autoOpen`, and it reads the mutable current candidate rather than validating the originally scheduled item/slot. The disabled-module return leaves `currentItem` populated.

A standalone Lua check loaded the existing module, scheduled auto-open, disabled both switches, refreshed, and executed the queued callback. **`UseContainerItem` was still called.**

The call’s current signature is retained in [ContainerDocumentation.lua:584](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua#L584).

**Fact versus inference:** Confirmed control-flow defect, reproduced with mocked APIs. Native permission to use particular item types from a timer was not established.

**Potential impact:** Use attempts after disabling the feature, duplicate attempts, or acting on a changed candidate.

**Minimal correction:** Revalidate both switches, candidate identity, and current bag-slot contents when the callback executes; invalidate superseded pending work.

**Runtime verification required:** Yes. **Confidence:** High.

<a id="ous-audit-004"></a>

### OUS-AUDIT-004 — MEDIUM — Utilities ignores its master enable switch

**Location:** [Utilities.lua:228](../Utilities.lua#L228); also lines 120, 335, 428, and 441.

**Description and evidence:** The OUS2 “Enable Utilities” control writes `OdysseusDB.modules.utilities`. Repair, rare announcement, junk-selling entry/continuation, and artwork application do not consult that flag. They consult only their individual settings.

**Fact versus inference:** Confirmed OUS control-flow mismatch; no Blizzard API change is involved.

**Potential impact:** Repairing, selling, announcements, or artwork control can remain active after the user disables Utilities. A running sale continuation also lacks a fresh `junkSell.enabled` check.

**Minimal correction:** Apply the master flag at actionable entry points and delayed sale continuations, with appropriate cleanup/restoration when disabled. Preserve the existing merchant queue and accounting semantics.

**Runtime verification required:** Yes. **Confidence:** High.

<a id="ous-audit-005"></a>

### OUS-AUDIT-005 — MEDIUM — XP/Delves rendering can re-show disabled modules

**Location:** [xpbar_engine.lua:742](../xpbar_engine.lua#L742); public renderers at line 653 and [xpbar_delves.lua:249](../xpbar_delves.lua#L249).

**Description and evidence:** Initialization hides the bars when the module is disabled, then immediately calls `OUS.UpdateBar()`. The renderers do not enforce the module switch. Pending rep/Delves callbacks and configuration callbacks can also reach them.

A standalone check called the existing renderer with `modules.xpBar = false`; **both XP and Delves frames were shown** in the mocked scenario.

**Fact versus inference:** Confirmed source and standalone behavior. No incompatible Blizzard API is required to trigger it.

**Potential impact:** Disabled bars return after reload, a pending callback, or a configuration action.

**Minimal correction:** Enforce disabled-state hiding at the public rendering boundaries and stop relevant pending presentation work on disable.

**Runtime verification required:** Yes. **Confidence:** High.

<a id="ous-audit-006"></a>

### OUS-AUDIT-006 — MEDIUM — Delves confuses zero progress with maximum renown

**Location:** [xpbar_delves.lua:300](../xpbar_delves.lua#L300).

**Description and evidence:** Journey progress is treated as maximum when `level > 0`, `earned == 0`, and `threshold > 0`. That condition also describes zero progress at an uncapped level.

Blizzard instead uses [HasMaximumRenown](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua#L111), including in its [reputation renderer](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ReputationFrame.lua#L527). OUS already uses this API in its general faction helper.

A standalone check supplied uncapped level 4, `0/5000`; the existing Delves renderer displayed **`MAX`**.

**Fact versus inference:** Confirmed predicate defect; the frequency of that live data state remains unmeasured.

**Potential impact:** A full Journey bar and false `MAX` label immediately after a rank transition or at another zero-progress state.

**Minimal correction:** Use the established maximum-renown query for the resolved Journey faction.

**Runtime verification required:** Yes. **Confidence:** High.

<a id="ous-audit-007"></a>

### OUS-AUDIT-007 — MEDIUM — Stats Bar misinterprets restriction events

**Location:** [StatsBar.lua:525](../StatsBar.lua#L525).

**Description and evidence:** The handler treats restriction type `2` as general stat restrictions covering M+, encounters, and PvP. LIVE defines `2` as **ChallengeMode**, with separate Encounter, PvPMatch, and Map values. Combat end also unconditionally clears `isRestricted`, even if another restriction remains active.

See [RestrictedActionsConstantsDocumentation.lua:19](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsConstantsDocumentation.lua#L19) and the authoritative [ShouldUnitStatsBeSecret contract](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua#L388).

**Fact versus inference:** **A — confirmed incorrect restriction-state logic.** Existing guarded cache population catches inaccessible stat operations and substitutes dashes; this audit does not establish an uncaught crash.

**Potential impact:** Restricted reads after combat, incorrect suppression/recovery, or avoidable blank stat displays.

**Minimal correction:** Derive cache-read permission from the verified stat-secrecy query plus the intended combat policy, preserving the existing safe display fallback.

**Runtime verification required:** Yes, across encounters, M+, and PvP. **Confidence:** High.

<a id="ous-audit-008"></a>

### OUS-AUDIT-008 — MEDIUM — Fishing UI timing can create false catch attribution

**Location:** [Fishingtracker.lua:1828](../Fishingtracker.lua#L1828); loot attribution at lines 1754–1760.

**Description and evidence:** While the tracker is visible, `OnUpdate` continually refreshes `lastCastTime` whenever the close countdown is disabled—including while paused. `LOOT_READY` then accepts loot as fishing loot when that same timestamp is within three seconds, even when `IsFishingLoot()` is false.

**Fact versus inference:** Confirmed timestamp reuse; false attribution is a source-supported consequence of the shown/paused or countdown-disabled state. It was not reproduced in WoW.

**Potential impact:** Ordinary loot can enter fishing history and session totals.

**Minimal correction:** Keep actual fishing activity time separate from the UI auto-close clock, and base fallback catch attribution on actual fishing evidence.

**Runtime verification required:** Yes. **Confidence:** High.

<a id="ous-audit-010"></a>

### OUS-AUDIT-010 — LOW — Reopening the current OUS2 page can leave stale settings

**Location:** [OUS2Config.lua:517](../Config2/OUS2Config.lua#L517); opening/toggling at lines 898–907.

**Description and evidence:** `SwitchPage()` returns immediately for the current page, and `C.Toggle()` changes visibility without invoking its refresh callback. Most pages have no independent `OnShow` refresh.

**Fact versus inference:** Confirmed lifecycle gap. For example, a setting changed by slash command while the window is closed can remain stale when the same page reopens.

**Potential impact:** Controls show outdated settings until the user changes pages.

**Minimal correction:** Refresh the current page when opening the configuration window or explicitly opening that page.

**Runtime verification required:** Yes. **Confidence:** High.

## E. Conditional risks and unknowns

<a id="ous-audit-009"></a>

### OUS-AUDIT-009 — MEDIUM — Flight Master page content exceeds its declared scroll extent

**Location:** [OUS2Config.lua:697](../Config2/OUS2Config.lua#L697) and [OUS2Page_FlightMaster.lua:673](../Config2/OUS2Page_FlightMaster.lua#L673).

**Description and evidence:** The shared scroll child starts at height 700. Flight Master places its last 52-pixel action row at offset `-1336`, reaching approximately 1,388 pixels. Unlike AutoRemount and XPBar, this page does not increase the shared content height. The shell also assigns content width once rather than visibly resynchronizing it with resizing.

**Fact versus inference:** **B — confirmed layout mismatch; inaccessible/clipped controls require runtime confirmation.** Native ScrollFrame range calculation is not fully implemented in the Lua mirror.

**Potential impact:** Lower appearance/export/reset controls may be unreachable; horizontal resize may leave page width stale.

**Minimal correction:** If reproduced, use the existing page-height pattern and synchronize content width with the viewport.

**Blizzard reference:** [SimpleScrollFrame API](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScrollFrameAPIDocumentation.lua#L65).

**Runtime verification required:** Yes, at minimum/default/maximum window sizes. **Confidence:** High for the mismatch; medium-high for the visible consequence.

**2026-10-26 follow-up:** User-observed wheel scrolling reaches all FlightMaster bottom controls; clipping was not demonstrated. A separate, confirmed shared decorative-thumb defect and source-supported footer overlap are addressed by the [native scrollbar implementation addendum](#implementation-addendum-009). The initial-height discrepancy remains a bounded observation, not the established cause of failed dragging. Native dragging/footer acceptance is pending.

**Subsequent runtime and polish follow-up:** The user confirmed the native Slider repair: dragging, wheel scrolling and footer clearance work. The [fixed-thumb/smooth-wheel refinement](#refinement-addendum-009) is now implemented with offline validation; its appearance and scroll feel still require WoW acceptance. This does not establish exhaustive combat/taint safety or change the bounded height observation.

<a id="ous-audit-011"></a>

### OUS-AUDIT-011 — LOW — Flight distance helpers pass a nullable map result to a required argument

**Location:** [Flightmaster.lua:591](../Flightmaster.lua#L591) and [FlightRouting.lua:255](../FlightRouting.lua#L255).

**Description and evidence:** Both paths pass `C_Map.GetBestMapForUnit("player")` directly to `C_TaxiMap.GetAllTaxiNodes()`.

The first result is explicitly [nullable](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua#L49); the second API requires a [non-nil map ID](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/TaxiMapDocumentation.lua#L11).

**Fact versus inference:** **B — contract mismatch at the boundary.** I did not establish that this result becomes nil while these taxi-hover paths execute.

**Potential impact:** A distance-preview failure during an unusual map transition or unavailable-map state.

**Minimal correction:** If the boundary is encountered, return unavailable distance before the taxi query. Preserve tooltip ownership and route behavior.

**Runtime verification required:** Yes. **Confidence:** High for the contracts; medium for reachability.

Additional uncertainties do **not** justify automatic patches:

- **Special spell secrecy:** Player/pet casts are generally accessible, but the [spell-cast predicate](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua#L109) allows per-spell overrides. AutoRemount/Fishing table lookups would need accessible IDs. No actual secret player-cast ID was observed, so this remains **D — unknown**, not demonstrated breakage.
- **Map geometry secrecy:** FlightRouting performs arithmetic on map-canvas dimensions. Geometry can become secret through anchoring, but the audit did not establish that this particular canvas is secret. Its `GetSize()` call is not automatically a bug.
- **Maximum-level XP detection:** The `UnitXP == 0`/large-`UnitXPMax` heuristic at `xpbar_engine.lua:659` lacks a documented guarantee. Blizzard has an [effective-max-level helper](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_SharedXML/GameRulesUtil.lua#L134). Preserve working behavior pending a focused level-cap/XP-lock test.
- **Delve identity tables:** Numeric range fallbacks and companion/map tables cannot be exhaustively validated from FrameXML alone. Their post-boss behavior remains a runtime boundary.
- **Static IDs and completeness:** Currency seasons, item eligibility, spell classification, quartermaster coordinates, and topology completeness require live data or DB2 evidence. Positive structural validation does not establish content completeness.

Safe findings were also retained:

- Fishing Venom rejects secret tooltip values before parsing.
- FlightMaster measures destination text on an independent OUS-owned FontString.
- Stats Bar formats cached strings for presentation and contains its existing guarded read fallback.
- Secure Openables mouse handling uses `PostClick`; no prohibited secure-button `OnMouseDown`/`OnMouseUp` script was found.
- BackdropTemplate’s Lua does perform geometry arithmetic, but its presence on ordinary OUS frames is not evidence of taint or secrecy.
- The current FlightMap XML/Lua and MapCanvas hover wiring support the preserved suppression-handoff design.

## F. Optional improvements

<a id="ous-audit-012"></a>

### OUS-AUDIT-012 — OPTIONAL — Synchronize current engineering descriptions

**Location:** [README.md:97](../README.md#L97), [AGENTS.md:9](../AGENTS.md#L9), and `CLAUDE.md:273` (historical guidance; retired on 2026-10-26, with [AGENTS.md](../AGENTS.md) as the current authority).

**Description and evidence:** Current descriptions have drifted from source:

- The exclusion database contains **three** entries: `13262`, `6247`, and `1234969`; current prose still describes one.
- Guidance lists `120007`, while the TOC also supports `120105`.
- AGENTS.md’s load-order list omits Session Stats and JunkBroker.
- CLAUDE.md’s date-formatted release-version rule conflicts with the current semantic release metadata/conventions.

**Fact versus inference:** Confirmed documentation mismatches. The TOC, OUS2 metadata display, and two changelog surfaces agree on **1.0.8 / October 9**; recent source-header dates are separate.

**Potential impact:** Misleading maintenance decisions and future release mistakes.

**Minimal correction:** Update current-state descriptions during an authorized documentation/release task. Preserve historical test records and historical release entries.

**Blizzard reference:** Not applicable. **Runtime verification required:** No. **Confidence:** High.

No optimization patch is recommended from this audit. The flight updater is active only during flights; most other work is event-driven or bounded. Fishing’s per-frame text updates could be measured later, but there is no measured performance problem supporting a change now.

## G. Recommended patch order

1. **Openables safety and action ownership:** 001 → 002 → 003.
2. **Enable-state correctness:** Utilities 004, then XP/Delves 005.
3. **Data presentation:** Stats restrictions 007, Delves maximum detection 006, fishing attribution 008.
4. **Configuration polish:** Verify 009, then address 010.
5. **Documentation:** 012 during the next authorized maintenance/release pass.

Keep each correction isolated. Findings 009 and 011 should receive focused runtime evidence before changes to currently working behavior.

## H. Suggested focused in-game tests

| Test | Acceptance target |
|---|---|
| Openables shown → enter combat; try lock, scale, and position controls | No blocked operation or Lua error; correct restoration after combat |
| Right-click / Shift-right-click under both key-down settings | Skip/blacklist never uses the item |
| Schedule auto-open, then disable Auto Open/module immediately | No later use attempt |
| Change candidate/bag slot during pending auto-open | Callback cannot act on stale contents |
| Disable Utilities, visit a merchant, invoke rare command | No disabled utility action; pending sales stop |
| Disable XPBar with rep/Delves callbacks pending; reload | XP and Delves remain hidden |
| Journey at zero progress below cap; then actual cap | Zero progress remains zero; only the true cap shows `MAX` |
| Stats during encounter, between M+ pulls, PvP, and after exit | No restricted formatting errors; predictable cache recovery |
| Pause/show Fishing Tracker and loot a non-fishing source | Fishing history does not change |
| Resize OUS2 and scroll Flight Master fully | Every control is reachable and width follows the viewport |
| Change settings through slash commands, reopen same page | Controls reflect current values |
| Flight suppression ON/OFF and `6247` candy bucket regression | Preserve your established working results |

## I. Existing static-analysis and validation baseline

| Check | Result |
|---|---|
| Lua 5.1 syntax | **46/46 files passed**, using `C:\Tools\Lua51\luac5.1.exe -p` |
| Repository LuaCheck | **526 warnings, 0 errors**, 46 files; exit 1 due to warnings |
| Production first-party share | 499 warnings across 40 files |
| Bundled libraries share | 25 warnings across 5 files |
| Separate art-test artifact | 2 warnings |
| Direct namespaced call presence | All **63** found in LIVE generated docs or Blizzard Lua |
| All literal `C_` references, including indirect calls | All **82** found |
| Registered event presence | All **57** found |
| Literal frame-template scan | All **13** extracted templates found in Blizzard XML |
| Flight timing data | **15,605** entries; checked values positive |
| Route graph | **3,981** edges; no missing referenced nodes |
| Openables database | **1,779** entries; checked thresholds valid |
| Standalone logic checks | Reproduced findings 003, 005, and 006 with mocked APIs |
| Existing automated test suite | No runnable regression suite identified |
| `git diff --check` | Passed |
| Final tracked/index comparison | Both unchanged |

Most lint warnings concern WoW globals absent from the existing LuaCheck configuration, with additional unused-variable, shadowing, and vendor whitespace warnings. They are the **existing checkout baseline**, not newly introduced regressions. The findings above are separate source-review conclusions.

## J. Limitations and verdict

This audit used the latest locally available matching LIVE snapshot. It did not launch WoW, exercise native protected operations, inspect live SavedVariables, reproduce third-party interactions, or exhaustively validate game-data IDs. API presence checks establish existence, not complete semantic compatibility. Standalone mocks establish the tested Lua control flow, not native-client acceptance.

**1. Is OUS suitable for continued Retail use?**

**Yes, with the identified maintenance work prioritized.** No evidence supports retiring or rewriting the suite.

**2. Are immediate compatibility fixes necessary?**

**A narrow Openables combat-safety correction merits prompt attention and in-game verification.** No removed-API migration was identified. The remaining confirmed defects should be addressed before the next maintenance release.

**3. What are the three highest-value follow-up actions?**

1. Correct and validate Openables combat visibility, click ownership, and delayed-action validity.
2. Repair module-disable enforcement in Utilities and XP/Delves.
3. Correct Stats restriction handling and the progression/catch-attribution defects, then run the focused acceptance matrix.

**4. Which modules should remain untouched?**

Preserve the **FlightMaster/FlightRouting tooltip handoff**, **AutoRemount interaction/Spy architecture and intentional `6247` exclusion**, **FasterLoot engine**, **Session Stats accounting**, **JunkBroker**, **Toolbox**, **Help**, and bundled libraries unless a specific new reproduction justifies a local correction. Flight Master’s configuration-page sizing can be investigated independently of its working engine.

<!-- END PRESERVED AUDIT -->

---

<a id="focused-investigation-001"></a>

## Focused Investigation 001 — Openables Combat Safety

**Research date:** October 25, 2026.

**Finding:** OUS-AUDIT-001, HIGH. **Status: RESEARCHED — Decision pending.**

**Implementation:** None. **WoW runtime verification:** None performed.

### 1. Scope, provenance, and relationship to the general audit

The OUS checkout is still at `6edb423d55a214bb6181c8e0af84ca65b245e114`. The inspected Blizzard mirror is still on `live` at `15881d522c44cd106d3d8660106ec9f9d2f44167`, described as `12.1.5 (70575)`, committed October 23, 2026. The source snapshot therefore matches the original audit. The client build `12.1.5.70575` remains the originally audited installed-client observation; this follow-up does not claim a newly launched client or a runtime build query.

The primary OUS inspection was limited to `Openables.lua`, `Config2/OUS2Page_Openables.lua`, and the relevant initialization/slash-dispatch code in `Core.lua`. Relevant project skills and guidance were read. No item-selection, auto-open, blacklist, or click-attribute correction was investigated or implemented. Findings 002 and 003 retain their original status and remain separate work.

This section adds source detail and narrows the ownership analysis. It does not replace the original finding, change its severity, or promote an inferred blocked operation to a runtime-observed error. In particular, an ordinary constructor does not prove an ancestor is freely mutable once it hosts a secure child, and a protected-function annotation does not mean that method is forbidden on every ordinary UI frame.

Evidence labels used here:

- **Documented API contract:** Explicit generated signatures, return contracts, and protection annotations.
- **Verified OUS source fact:** What the existing code calls and which paths reach it.
- **Verified Blizzard source fact:** XML inheritance, secure dispatcher/driver code, and associated scripts.
- **Source-supported inference:** Expected client behavior inferred from those contracts and relationships.
- **Unresolved runtime question:** Requires a real client observation; no native protection behavior is simulated here.

### 2. Exact reference register

OUS line references below identify the unchanged OUS commit above. Relative links navigate the checkout; line numbers remain historical references if the checkout later advances. Blizzard links are immutable links to the inspected LIVE commit, whose local root is `D:\WowDEV\Reference\Blizzard\wow-ui-source`.

| Ref | Source and relevant lines | Evidence supplied |
|---|---|---|
| O1 | [Openables.lua](../Openables.lua#L352), lines 352–427 | Container, secure button, visuals, cooldown, and drag handle creation/parenting |
| O2 | [Openables.lua](../Openables.lua#L431), lines 431–455 | Drag start, per-frame movement, and drag stop |
| O3 | [Openables.lua](../Openables.lua#L474), lines 474–542 | Guarded PostClick; local display mutation and secure attributes |
| O4 | [Openables.lua](../Openables.lua#L545), lines 545–600 | Position/size application and lock/unlock |
| O5 | [Openables.lua](../Openables.lua#L607), lines 607–695 | Refresh guard, timers, events, combat entry/exit |
| O6 | [Openables.lua](../Openables.lua#L1016), lines 1016–1064 and 1569–1575 | Slash command and public API entry points |
| O7 | [OUS2Page_Openables.lua](../Config2/OUS2Page_Openables.lua#L84), lines 84–95, 184–199, 294–350, 418–433 | Module/settings callbacks, position reset, lock and scale controls, page refresh |
| O8 | [Core.lua](../Core.lua#L63), lines 63–74, 216–227, 598–604 | Default Openables settings, full reset, and slash dispatch |
| B1 | [SecureTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml#L4), lines 4–9; [SecureTemplatesBase.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplatesBase.xml#L4), line 4 | SecureActionButton inherits an explicitly protected frame and supplies its secure OnClick |
| B2 | [SimpleFrameAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L686), lines 686–692, 1053–1060, 1168–1177, 1206–1214, 1403–1410, 1470–1491, 1537–1574 | Frame-specific protected operations; other setters and their actual annotations |
| B3 | [SimpleScriptRegionAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua#L516), lines 10–20, 73–81, 516–528, 605–614 | Permission query, mouse enablement, explicit/implicit protection return values, parent changes |
| B4 | [SimpleScriptRegionResizingAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua#L22), lines 22–29, 135–148, 163–172 | Protected clear/anchor/size functions |
| B5 | [RestrictedActionsDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L11), lines 11–26 and 45–52 | Per-object, calling-context permission query and InCombatLockdown contract |
| B6 | [SecureStateDriver.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua#L7), lines 7–31, 96–108, 121–177, 183–195 | Registration bridge, visibility show/hide behavior, statehidden, immediate initial resolution, secure manager, combat rescan events |
| B7 | [SecureHandlers.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua#L427), lines 427–439, 496–498, 679–701; [SecureHandlerTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlerTemplates.xml#L5), lines 5–18 | Out-of-combat setup boundary; explicit protection requirement for handler headers; handler template inheritance |
| B8 | [RestrictedFrames.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua#L49), lines 49–98 and 237–245 | Secure handles distinguish protected frames and combat state; this is secure-environment code, not permission for an addon callback |
| B9 | [Backdrop.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_SharedXML/Backdrop.xml#L5), lines 5–9; [Backdrop.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua#L189), lines 189–193 and 221–229 | Backdrop template has no protected declaration; resizing invokes geometry-based texture work |
| B10 | [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L762), lines 762–769 and 805–831 | Secure action dispatch is separate from ordinary addon callbacks and PostClick |
| B11 | [Blizzard_RestrictedAddOnEnvironment.toc](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/Blizzard_RestrictedAddOnEnvironment.toc#L1), lines 1–15 | Secure environment and handler Lua/XML load graph |

The Lua/XML walk follows OUS creation through B1 inheritance and scripts, B9 backdrop scripts, and B11's secure driver/handler loading. B6 is loaded directly by the TOC; it creates its manager in Lua rather than through a separate manager XML. Native engine enforcement of ancestor protection and the exact outcome of a rejected call are outside this Lua/XML mirror. No nearby source TODO/FIXME was found that establishes an Openables-specific exception. B7's comment that its protected API frame prevents combat setup is developer commentary supporting that setup boundary, not a runtime observation of OUS.

### 3. Protected-frame ownership and lifecycle

```text
UIParent (Blizzard-owned)
  OdysseusOpenablesContainer (OUS; ordinary BackdropTemplate constructor)
    OdysseusOpenablesButton (OUS; SecureActionButtonTemplate + BackdropTemplate)
      icon/count/badge (texture/font regions)
      cooldown (ordinary CooldownFrameTemplate constructor)
    OdysseusOpenablesDragHandle (OUS; ordinary BackdropTemplate constructor)
```

| Object | Verified construction | Protection conclusion |
|---|---|---|
| `opBtn` | O1/B1: secure button explicitly inherits `protected="true"`; parent and CENTER anchor point to `opContainer` | **Directly/explicitly protected.** This conclusion does not depend on live flags. |
| `opContainer` | O1/B9: ordinary frame template, parent UIParent; hosts and anchors the secure button | **Not explicitly secure by its constructor.** Visibility/geometry affect the protected child, so treat it as a protected dependency/ancestor for this investigation. Expected indirect protection is a source-supported inference; the native `IsProtected()`/permission results must be observed in-client. It is not safe to assume that replacing `opBtn:Hide()` with only this parent's `Hide()` bypasses protection. |
| `dragHandle` | O1: ordinary sibling of `opBtn`, sharing its container; no secure template | No explicit secure action/protection declaration. Being a sibling is not proof that it independently inherits the button's explicit protection. Its effective visibility and movement depend on the shared container; inspect live flags before making broader claims. |
| `opCooldown` | O1: child of `opBtn`, no independent SecureActionButtonTemplate declaration | Part of the button's visual hierarchy. No independently configured secure action; exact effective/native protection flags remain unmeasured. |
| Icon/count/badge | O1: visual regions attached to the button | Visual updates are distinct from secure attributes and frame visibility/layout. Do not classify text/color updates as protected actions just because they are attached to this button. |
| OUS2 controls and management windows | O7: page controls under `C.pageContainer`; management windows are separate frames | The controls are not parents of the secure button. Changing their own labels/checks is distinct from callbacks that mutate Openables. No reason to freeze all OUS2 or management windows. |

B3 documents `IsProtected()` returning two booleans: `isProtected` and `isProtectedExplicitly`. That distinction supports precise live inspection; it does not expose the engine algorithm for propagating protection through this particular parent/anchor graph. UIParent ownership does not authorize modifying Blizzard UI or imply that every frame under UIParent is blocked.

**Lifecycle:** The frames and initial attributes are created while the addon file loads (O1). Saved position/size/lock are applied on this addon's `ADDON_LOADED` and on `PLAYER_ENTERING_WORLD` (O5). Those are real mutation entry points, not merely declarations. A reload while already in combat is a separate untested boundary: the initial creation path and initial application should be observed before deciding whether it needs explicit deferral. The current code contains no visibility driver or secure state snippet for combat.

### 4. Complete relevant operation and call-site inventory

| Existing path | Mutations or effects | Reachability and current guard |
|---|---|---|
| Initial creation, O1 | Container/button/drag sizes, points, visibility, mouse and drag setup; textures and cooldown parented at creation | Load-time setup. No explicit combat guard; no later reparenting of this hierarchy found. |
| `OnDragStart` / drag `OnUpdate`, O2 | Reads cursor/center; repeatedly calls container `ClearAllPoints()` and `SetPoint()` | No combat check on drag start or each update. No combat-entry cancellation of the updater. |
| `OnDragStop`, O2 | Clears the OUS-owned updater, reads the saved point, writes existing position keys | No combat check. This is custom point-based dragging; it does not use `StartMoving()`/`StopMovingOrSizing()`. |
| `UpdateButton()`, O3 | Container/button Show/Hide; button secure attributes; icon/count/color/badge/cooldown display | Only local call found is from `OP.Refresh()`. That caller returns before mutation in combat. The local function's own combat branch attempts Hide, but is currently unreachable through the guarded caller while lockdown is true. It should not be presented as an independently observed combat failure. |
| `OP.Refresh()`, O5 | May hide the container for disabled module; otherwise selects a candidate and invokes `UpdateButton()` | First statement returns during lockdown, before disabled-module hiding or display mutation. Item/auto-open behavior is outside this focused investigation. |
| `ApplyPosition()`, O4 | Clears/sets container points, resizes container and button/drag handle, applies lock-related mouse/drag/visibility state | No combat guard. Invoked by initialization/world events and public `OP.ApplyPosition()`. The UI's “scale” is implemented as `SetSize(64*s)` / `SetSize(40*s)`, not a runtime `SetScale()` call. |
| `SetLocked(state)`, O4 | Writes lock state; changes container mouse/movable/drag properties; shows/hides button, container, handle | No combat guard. Reached from `/op lock`, `/op unlock`, and OUS2's Lock Button callback. |
| `PLAYER_REGEN_DISABLED`, O5 | Calls `opContainer:Hide()` then `opBtn:Hide()` | Direct callback with no `OP.Refresh()` guard and no native permission check. Does not clear attributes, stop the drag updater, or record a deferred layout application. |
| `PLAYER_REGEN_ENABLED`, O5 | Schedules `OP.Refresh()` after 0.5 seconds | Fresh combat check when callback executes. Does not call `ApplyPosition()` or `SetLocked()`. |
| OUS2 Enable Openables checkbox, O7 | Writes existing module flag; calls `UpdateDisplay()` → `OP.Refresh()` | Guarded display path returns in combat. The setting can change while the last displayed native state remains. |
| OUS2 Lock Button, O7 | Calls `SlashHandler("lock"/"unlock")` → `SetLocked()` | Bypasses `OP.Refresh()`. No combat gate. |
| OUS2 Button Scale, O7 | Writes `db.scale`; calls public `ApplyPosition()` | Bypasses `OP.Refresh()`. Can partially change saved state before a restricted operation is refused. |
| OUS2 Reset Button Position, O7 | Writes default position keys; calls public `ApplyPosition()`; fallback also moves container directly | No combat gate in either branch. The normal public API is present in this baseline, so the fallback is not the expected route. |
| PostClick, O3 | Skip/blacklist processing and refresh | Explicit combat return before OUS post-action processing. The secure OnClick action precedes PostClick; the latter is not a combat guard for that secure action. Click ownership stays finding 002. |
| Core integration, O8 | Defaults and existing module flag; slash command forwards to `OP.SlashHandler`; full reset replaces settings and reloads UI | Core does not add a combat guard to Openables dispatch and does not directly manipulate these frames. No Core architecture change is justified by 001. |

Refresh callbacks from bag updates, item loading, item-lock changes, mount/pet changes, and the post-combat delay converge on `OP.Refresh()` and its fresh lockdown guard. The distinct position/lock/drag/event paths above do not. No runtime `SetParent()` or `SetScale()` call on `opContainer`/`opBtn` was found. Proposed fixes should not add combat reparenting as a workaround.

### 5. Which operations are protected, conditional, or safe?

**Documented API contracts:** B2 explicitly marks frame `Hide`, `Show`, `SetShown`, `SetScale`, and `SetClampedToScreen` as `IsProtectedFunction = true`. B3 does the same for `EnableMouse` and `SetParent`; B4 for `ClearAllPoints`, `SetPoint`, and `SetSize`. The frame-specific Hide/Show entries matter: the generic script-region entries alone omit those frame annotations. B5 describes `CheckAllowProtectedFunctions(object, silent)` as a test of the **calling context's permission on the supplied object**. This is why those annotations must be interpreted with object protection/context, rather than as a blanket ban on ordinary UI updates during combat.

**Strongly supported restricted boundary:** Ordinary OUS event/configuration/drag callbacks cannot acquire secure execution merely because they target a SecureActionButtonTemplate. Direct addon visibility/geometry changes to `opBtn` during lockdown are the unsafe pattern in 001. Changes to its container that affect the protected descendant must be treated conservatively; the mirror does not supply the full native ancestry algorithm. A `hooksecurefunc` or a PostClick guard would not turn an ordinary future setter callback into a secure visibility handler.

**Other setters:** `SetMovable` and `RegisterForDrag` lack `IsProtectedFunction` in the inspected generated entries. That absence does not prove every composite lock/unlock function safe: those functions also call annotated methods, including Show/Hide and EnableMouse. The entire helper should stop before beginning a restricted native-state transition. `SetAttribute` also lacks that general annotation in B2; do not infer that mutating action-defining attributes on a protected action button in combat is safe. The current ordinary attribute-update path is already behind `OP.Refresh()`; 001 does not propose changing attribute values or selection.

**Safe/non-equivalent activity:** Updating existing Lua settings or ordinary OUS2 checkbox text is not itself a secure-frame layout/action mutation. It can, however, create a saved/native mismatch if an immediate apply fails. Texture colors and text on OUS-owned visuals are not automatically taint defects. Showing a separate ordinary management window is not equivalent to showing the protected item button. BackdropTemplate does not itself declare protection (B9); its size-change geometry calculations are not proof that these OUS-owned dimensions are secret.

**Native outcome remains unresolved:** Source establishes unsafe call reachability and the protection boundary. It does not prove which error appears, whether an ineffective call is optimized away, which statement fails first, whether event execution stops at that statement, or whether the container's exact permission differs by shown/locked state. No crash, data loss, or observed protected-action error is claimed here.

### 6. Combat entry, in-combat settings, and restoration

**Combat entry while visible:** The exact OUS sequence is parent Hide followed by button Hide (O5). The button is directly protected; the parent controls its effective visibility. If the first operation is refused, the second may never execute. If operations are refused without completing the intended transition, the last shown button/container can remain visible. These are source-supported outcomes requiring client observation, not a completed combat test. The callback is also active when the Openables module is disabled; 001 does not depend on finding an openable at that instant to reach the calls.

**Combat entry during dragging:** The combat handler does not clear the custom `OnUpdate` mover. If hiding is blocked, it can continue requesting point changes each frame. If hiding succeeds, the updater is still assigned; do not assume hiding cleans it up or that OnDragStop will always run. The safe design requirement is to end the OUS-owned drag update before any later protected movement attempt. The exact release/visibility behavior needs a real drag-to-combat transition test.

**Settings during combat:** Module-checkbox refresh reaches the guard and avoids a new frame update, so disabling can leave pre-combat visibility until reconciliation. Lock/unlock and scale/reset call the unguarded helpers directly. Scale/reset write settings before applying native position/size, and SetLocked writes state before later visibility changes. A refused native operation can therefore leave settings and presentation inconsistent. Persisting a setting is not itself a blocked protected action; attempting to apply it immediately is the relevant boundary. Avoid broad disablement of unrelated management controls.

**Combat exit:** The existing 0.5-second callback invokes `OP.Refresh()`, which rechecks lockdown. If combat resumes before execution it returns safely. Otherwise it checks the module flag, rescans current candidates, and updates visibility and secure attributes through the existing logic. It does **not** replay position, size, or lock application, and no dedicated pending layout state exists. A correction that defers settings must explicitly reconcile those native settings after combat; merely relying on this rescan is insufficient. Pending auto-open validity is still finding 003 and is not redesigned here.

### 7. Is avoiding Hide sufficient? Correction options and trade-offs

No implementation is authorized by this document. The following are decision alternatives, not tested patches.

| Option | Smallest meaningful scope | What it preserves | Trade-offs / regression risks |
|---|---|---|---|
| **A. Freeze native Openables state during combat** | Remove/avoid both combat-entry visibility setters; guard lock, placement/size, and every drag mutation entry; stop the custom updater and reconcile after combat | Existing item selection, attributes, and out-of-combat layout can remain unchanged | Smallest approach without secure visibility infrastructure, but leaves the last button/drag presentation visible during combat. That changes the documented hide-on-combat behavior. Secure hardware clicks may still operate on the preconfigured action; no claim that PostClick blocks them. Requires an explicit behavior decision. |
| **B. Preserve combat hiding with a secure visibility gate** | Same mutation guards/reconciliation as A, plus an OUS-owned secure visibility boundary configured outside combat | Can preserve automatic combat hiding without altering item-use attributes, selection, or blacklist logic | More lifecycle work than A. Must compose combat eligibility with module/candidate/lock visibility, prevent a stale pre-refresh reveal after combat, and stop drag updates. A driver alone does not solve unguarded configuration setters. |

**Option A is not a complete behavior-preserving fix.** Removing only `opBtn:Hide()` is also insufficient: the parent Hide and unguarded lock/layout/drag paths remain. Removing both Hide calls plus comprehensive guards can eliminate those mutation attempts, but intentionally retains a visible pre-combat state. Setting alpha to zero would not be an equivalent solution because it does not establish non-interactivity or protected visibility state.

**Option B has two materially different placements:**

1. **Existing-frame driver:** A visibility driver on the button alone can leave the drag presentation/container active. A driver on the existing container must cooperate with its ordinary candidate/module Show/Hide owner. A blindly registered `[combat] hide; show` resolves immediately when registered and can force the container shown while empty or disabled; its later combat-exit show can precede the existing delayed rescan. Registering/unregistering only when eligible introduces further ownership/reconciliation requirements. This placement uses fewer frames but carries more risk of conflicting visibility ownership.
2. **Separate combat gate above the existing container:** A small OUS-owned, explicitly protected wrapper created outside combat can own combat visibility while the existing container continues to own candidate/module/lock presentation. Construction would parent the container to the gate from the outset; it would not reparent frames during combat. This separates the two visibility decisions and avoids an unconditional driver directly overriding the existing container. It adds one frame and requires verification of parent/anchor, layering, drag, and post-combat timing behavior. An explicit SecureFrameTemplate is sufficient for the built-in visibility driver's target role; SecureHandlerStateTemplate/snippets should be added only if a selected design actually requires custom state handling.

B6's visibility resolver calls Show/Hide and sets/clears `statehidden` for `show`/`hide` results; it does nothing when neither result is returned. Registration resolves the current state immediately. These facts explain both the utility of the mechanism and its potential ownership conflict. A two-way driver can reveal the old candidate before the 0.5-second refresh; a hide-only combat driver with deliberate out-of-combat gate release is a possible alternative, but would need to reconcile its `statehidden` metadata, recheck lockdown, and refresh before release. Neither restoration variant is treated as accepted without testing.

**Common minimum for either option:** Guard public and local native-state entry points, prevent drag updates from crossing the combat boundary, and choose a consistent settings policy. Deferring existing saved values needs a transient pending apply and guarded post-combat reconciliation; rejecting changes needs the controls/settings to remain consistent. No SavedVariables format change, polling loop, dependency, secure click-attribute rewrite, or replacement of the module is warranted. These are focused implementation requirements to review, not approval to create a new general framework.

**Smallest correction compatible with the currently documented behavior:** Retain the current secure button and item logic; guard/defer the uncovered layout/locking/drag paths and let an independently owned secure visibility boundary perform combat hiding. A wrapper gate is the clearest behavior-preserving candidate if existing-frame visibility cannot be composed without conflict. Source alone does not establish that a wrapper is necessary or that a direct driver is correct; select placement after the native protection/visibility observations below. If the user chooses persistent combat visibility instead, A is smaller and needs no visibility driver.

### 8. Focused in-game verification plan

No unsafe setters should be invoked merely to prove that they are blocked. Start with read-only observations and normal reproduction of the already existing UI, using current error reporting.

| Test | Evidence to collect / acceptance question |
|---|---|
| Native ownership snapshot outside and during combat | For the named button, container, and drag handle, collect accessible `IsProtected()` (both returns), `CanChangeProtectedState()`, and `C_RestrictedActions.CheckAllowProtectedFunctions(frame, true)` results. B3/B5 verify the query contracts. Treat inaccessible/secret output as unavailable; do not infer false. The silent permission query does not authorize or execute a setter. |
| Locked, eligible button visible → ordinary combat entry | Record existing error events, visibility of container/button, and `InCombatLockdown()` context. Determine whether the first parent Hide is rejected and whether the button remains visible. |
| No candidate; module disabled; parent hidden before combat | Determine whether no-op/hidden-state calls differ. Do not generalize one state to all others. |
| Unlocked/drag-handle state → combat | Confirm whether the handle remains visible and whether mouse interactions change. |
| Drag in progress → combat → mouse release → combat exit | Check for continuing layout attempts/errors, retained updater behavior, saved position, and ability to drag afterward. Do not intentionally exercise protected setters with mocks. |
| Existing scale/reset/lock controls during combat | Observe normal UI behavior without replacing handlers. Record saved-vs-native consistency and errors; module checkbox has a distinct guarded path. If a repeat is already known to fail, avoid unnecessary repeated actions. |
| Combat exit, quick re-entry before the 0.5-second callback | Verify fresh lockdown checks prevent delayed application in renewed combat. |
| Post-combat restore with candidate present, removed, and module disabled | Confirm the intended shown state and position/size/lock match the latest accepted settings. |
| Reload while in combat | Observe initialization and PLAYER_ENTERING_WORLD behavior separately from ordinary combat entry. No claim of support is made before this test. |
| Any future B prototype: empty/disabled/locked/unlocked plus rapid combat transitions | Driver registration must not expose an empty/disabled container; the gate must not reveal a stale candidate before reconciliation. No insecure driver setup during combat. |

Clicks, blacklist behavior, and auto-open must remain unchanged by any future 001 patch. Their dedicated defects remain 002/003. A normal out-of-combat smoke test can protect against regression without expanding this research into those implementations.

### 9. Final research verdict

**Confirmed:** The item button is explicitly protected. OUS directly attempts combat-entry hiding outside the refresh guard. Lock/placement/size and drag paths also bypass that guard. The existing post-combat refresh does not replay deferred layout. Frame-specific LIVE API annotations support the protected-operation concern. The plain container's constructor and the visual BackdropTemplate must not be equated with an explicitly secure button.

**Source-supported inference:** Native permission will constrain at least the secure-button changes and can constrain its parent/anchor dependencies. Blocked calls can leave visibility and saved/native state out of sync. Exact ancestor flags and the error/continuation behavior are not exposed fully by the mirror.

**Unresolved:** No native error, parent protection flags, drag-to-combat outcome, combat-load behavior, or correction option was tested in WoW. No finding is fixed, resolved, or runtime verified. The original HIGH severity is retained as an unsafe-source-pattern priority, not a runtime-confirmed serious-taint claim.

**Recommended next decision:** Review the native observations and retain or explicitly change the hide-during-combat requirement. If it is retained, authorize a narrowly scoped 001 patch combining mutation guards/reconciliation with a reviewed secure visibility composition; the independent gate is the preferred candidate to evaluate. If persistent combat visibility is acceptable, authorize the smaller freeze approach instead. Do not implement a driver by default or combine 002/003 fixes with this decision.

### 10. Documentation follow-up validation record

This task changes only `Documentation/OUS_RETAIL_API_AUDIT_2026-10-25.md`. The preserved section is checked against the preceding assistant audit after ignoring presentation-only links, added anchors, and Markdown spacing normalization. The index contains all 12 findings, with 001 RESEARCHED and 002–012 OPEN. Relative file links, pinned Blizzard source paths/line bounds, explicit internal anchors, Markdown fences, and the final document diff are checked. `git diff --check` is run for this documentation task. The original Lua/LuaCheck/data/mock results remain historical; production checks and mocks were not rerun to imply new runtime evidence. No production Lua/XML, configuration, TOC, SavedVariables, dependency, commit, or push is part of this task.

Validation result: **PASS** — all 12 historical findings and preserved audit prose match the preceding report after presentation normalization; 001 alone is RESEARCHED; 68 links/anchors and source line bounds pass; only the intended new Markdown file is present in Git status. Both the tracked diff check and the new-file diff whitespace check pass. No new Lua/mock/client validation was performed.

<a id="runtime-observations-001"></a>

### 11. User-reported runtime observations and monitoring decision

**Recorded:** October 25, 2026, following the source investigation above.

**Current status: RUNTIME TESTED — No failure observed; monitoring.**

**Evidence category: user-reported runtime observations.** The user reports completing the following tests in **a raid** and **an open-world raid event**:

| Test | Reported observation | Reported errors |
|---|---|---|
| Openables visible before entering combat | Entering combat correctly hides the button | None observed |
| Combat ends | The button reappears correctly | None observed |
| Openables configuration during combat | Lock/scale interactions behaved normally | None observed |

These are successful observations of the tested paths and environments. They were supplied by the user, not independently reproduced by Codex. Exact test timestamps, runtime build query, item IDs, addon composition, native protection/permission-query outputs, repeat counts, and error-reporting instrumentation were not supplied. The preserved client/source baseline remains identifiable; it must not be substituted for an independently recorded build for these tests.

**Decision supplied by the user:**

- No production change is authorized.
- Preserve the existing hide-during-combat behavior.
- Retain the conditional protected-frame concern.
- Revisit only if new runtime evidence establishes a failure.

The earlier source finding is **not disproven or permanently resolved**. The tested behavior narrows its practical significance: the predicted failure was not observed in these raid/open-world raid-event tests. No secure visibility driver, wrapper, mutation-guard patch, or other correction is selected or authorized. The original HIGH source-finding severity remains part of the preserved audit history; the current operational disposition is monitoring, not an immediate implementation recommendation.

This addendum supersedes the earlier request to choose between a freeze approach and a secure-visibility approach. The original investigation, its source facts, and its then-unresolved questions remain intact as history. No further 001 reproduction is requested merely to re-prove the same successful tests; new failure evidence is the trigger for reopening it. The right-click investigation below is independent and does not reopen the combat-safety decision.

---

<a id="focused-investigation-002"></a>

## Focused Investigation 002 — Openables Right-Click Action Ownership

**Research date:** October 25, 2026.

**Finding:** OUS-AUDIT-002, MEDIUM. **Status: RESEARCHED — Runtime verification pending.**

**Implementation:** None. **002 runtime observations:** None supplied or performed.

### 1. Baseline, scope, and exact references

The preserved OUS baseline is `6edb423d55a214bb6181c8e0af84ca65b245e114`; this task does not change production source. The local Blizzard reference was rechecked: branch `live`, commit `15881d522c44cd106d3d8660106ec9f9d2f44167`, description `12.1.5 (70575)`, committed October 23, 2026. It matches the original audit. The audited installed-client observation is Retail `12.1.5.70575`; no client was launched or runtime build queried during this follow-up.

Scope is the existing Openables secure button, its registered click edges/attributes, and right-click PostClick processing. Item selection, delayed auto-open validity (003), combat hiding (001), and blacklist storage formats are preserved. Local Blizzard Lua/XML is the primary evidence; no PTR/beta behavior is promoted to LIVE.

| Ref | Source and historical line references | What was inspected |
|---|---|---|
| R2-O1 | [Openables.lua](../Openables.lua#L362), lines 362–370 | SecureActionButtonTemplate creation and LeftButtonUp/LeftButtonDown/RightButtonUp registration |
| R2-O2 | [Openables.lua](../Openables.lua#L460), lines 460–492 | Tooltip promises, PostClick guards, session skip, Shift blacklist, candidate clearing, and refresh |
| R2-O3 | [Openables.lua](../Openables.lua#L496), lines 496–542 | Authoritative display refresh and generic `type`/`macrotext` assignment |
| R2-O4 | [Openables.lua](../Openables.lua#L262), lines 262–268 and 607–625 | Existing blacklist lookup and guarded refresh; the delayed auto-open path remains separate finding 003 |
| R2-B1 | [SecureTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml#L4), lines 4–9; [SecureTemplatesBase.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplatesBase.xml#L4), line 4 | Secure inheritance and the template-supplied `SecureActionButton_OnClick` binding |
| R2-B2 | [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L6), lines 6–29, 70–137 | Modified attributes, wildcard/no-op rules, modifier prefix, button suffix, and attribute resolver |
| R2-B3 | [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L694), lines 694–769; [macro handler](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L447), lines 447–461 | Edge/button conversion, action-type lookup, action dispatch, and `C_Macro.RunMacroText` call |
| R2-B4 | [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L795), lines 795–828 | Per-button useOnKeyDown override, CVar fallback, action-edge selection, and alternate hold-release action |
| R2-B5 | [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L831), lines 831–839 | Blizzard's own modifier-wildcard `*type1` / `*type2` action assignment pattern |
| R2-B6 | [SimpleButtonAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleButtonAPIDocumentation.lua#L271), lines 271–279 | RegisterForClicks signature and protected-function annotation |
| R2-B7 | [UI.xsd](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_SharedXML/UI.xsd#L416), lines 416–418 | Distinct PreClick, OnClick, and PostClick script slots; the native dispatcher itself is not supplied by the mirror |
| R2-B8 | [ActionButtonTemplate.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml#L172), lines 172–178; [ActionButton.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua#L1503), lines 1503–1509 | Blizzard's separate OnClick action handling and PostClick state update, as supporting lifecycle context |
| R2-B9 | [SlashCommands.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua#L377), lines 377–387; [ChatFrameUtil.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L1196), lines 1196–1219 | Native macro-option parsing followed by item-use dispatch; no additional left-button-only check in this visible Lua path |

The source walk follows the OUS template inheritance into XML's secure OnClick, then through the Lua edge selector, modified-attribute resolver, and macro dispatcher. It also checks the separate script slots and Blizzard's own OnClick/PostClick wiring. The relevant XML is therefore part of the evidence, not assumed absent. No nearby TODO/FIXME establishes a right-click safety exemption. R2-B3's comment about deferred down-button remapping is not evidence that OUS right-click is suppressed; OUS configures no such remapping.

### 2. Existing action ownership and attribute resolution

**Verified OUS source facts:**

- The button is created with `SecureActionButtonTemplate,BackdropTemplate` (R2-O1).
- Registered edges are exactly `LeftButtonUp`, `LeftButtonDown`, and `RightButtonUp`. RightButtonDown is not registered by OUS.
- The display update assigns generic `type = "macro"` and generic `macrotext = "/use item:ID"` (R2-O3).
- No OUS PreClick handler, replacement OnClick, button-specific type override, `useOnKeyDown`, `pressAndHoldAction`, `typerelease`, unit, or down/help/harm button remap is configured on this button in the inspected file. The template supplies OnClick; OUS supplies PostClick.
- The tooltip advertises left-click use, right-click session skip, and Shift-right-click permanent blacklist (R2-O2).

**Verified Blizzard source facts:** LeftButton maps to suffix `1` and RightButton to suffix `2`; Shift contributes the `shift-` prefix. Modified attributes are looked up for the effective prefix/name/suffix. Blizzard's nearby source comments explicitly describe a bare attribute as equivalent to the wildcard form for all modifiers/buttons. The resolver supports the documented empty-string `ATTRIBUTE_NOOP` and converts a resolved empty string to no action (R2-B2).

Therefore OUS's generic `type` is not left-click-only. In the absence of a more specific override it is available for both right-click and Shift-right-click, and the generic macrotext is available to the macro handler too. The fact that an action is handled securely grants execution through the secure path; it does not infer OUS's intended separation between use and skip.

The low-level multi-argument GetAttribute resolution is native. This report relies on Blizzard's inspected wrapper and explicit wildcard/no-op comments rather than inventing an exhaustive precedence algorithm. No external addon override or hardware-binding variant was measured; conclusions below describe the attributes and template binding established by this OUS baseline.

### 3. Secure click pipeline and the PostClick boundary

The expected button lifecycle is **PreClick → OnClick → PostClick** for a dispatched registered click. OUS has no PreClick work. Its XML-inherited OnClick enters `SecureActionButton_OnClick`; the selected normal action calls `OnActionButtonClick`, resolves `type`, and dispatches the macro handler. That handler resolves macrotext and calls `C_Macro.RunMacroText(text, button)` (R2-B1/B3/B4).

OUS's right-click skip/blacklist branch is only in PostClick. It first returns if there is no current candidate or if lockdown is active; otherwise it records either the session exclusion or the permanent existing DB exclusion, clears `currentItem`, and calls the existing refresh (R2-O2). It neither cancels an earlier macro request nor removes the secure action before OnClick. A PostClick combat return is likewise not a cancellation of template OnClick.

**Evidence qualification:** The Lua/XML proves that macro dispatch belongs to OnClick and exclusion processing belongs to PostClick. R2-B7/B8 support the distinct pre/action/post lifecycle; the native script-dispatch implementation and exact engine scheduling are outside the mirror. The ordering consequence is source-supported and awaits a real OUS click observation; no mock is presented as native dispatch proof.

**Use request is distinct from consumption:** A macro/use request can be dispatched during OnClick before PostClick exclusion handling. Server processing, a spell cast, cooldown, an opened loot window, and actual bag-count changes may complete later. A later blacklist cannot be assumed to undo an already dispatched use request. This report does not claim the bag count must change synchronously before PostClick.

The visible `/use` handler applies `SecureCmdOptionParse`, parses the item, and invokes `SecureCmdUseItem` when an item resolves. For OUS's `item:ID` form, the helper's name-based path reaches `C_Item.UseItemByName`; the Lua path adds no independent left-button test (R2-B9). OUS's macro contains no `[button:1]` condition. Macro-option parsing and final item-use permission/success still involve native behavior; the visible handler is not proof that every item request succeeds.

### 4. Key-down versus release behavior

R2-B4 first checks the button's `useOnKeyDown` attribute and otherwise reads `GetCVarBool("ActionButtonUseKeyDown")`. OUS sets no override. The ordinary template XML passes the native click arguments to this handler without supplying the extra action-bar `isKeyPress` / `isSecureAction` flags. Blizzard's comment specifically explains preserving addon-button key-down behavior in this case. This differs from assuming every secure action-bar mouse path has identical flag handling.

For the normal OUS template path, with no external attribute/remapping changes and a CVar held constant throughout the press/release:

| ActionButtonUseKeyDown | Registered left-button edges | Registered right-button release | Right-click exclusion path |
|---|---|---|---|
| Enabled | Down selects the normal macro; up does not select that normal action | Normal action selects down, but OUS does not register RightButtonDown; RightButtonUp does not select the normal macro | OUS PostClick is still the intended release-side skip/blacklist handler; exact client dispatch is to be verified |
| Disabled | Up selects the normal macro; down does not select that normal action | RightButtonUp selects the normal action; generic `type`/macrotext can dispatch `/use item:ID` | PostClick can then skip/blacklist after the use request has already been dispatched |

Shift-right-click has the same edge selection because Shift does not change the CVar. Its modifier prefix can still resolve the generic macro. OUS checks Shift only in PostClick to choose permanent blacklist instead of session skip. Holding Shift is therefore not an action-isolation guarantee.

The handler has a separate release/hold branch controlled by `pressAndHoldAction` or `ActionButtonUseKeyHeldSpell`. That branch resolves **`typerelease`**, not the normal `type` (R2-B3/B4). OUS sets neither a press-and-hold action nor a release action, so that branch does not by itself convert the generic macro into a configured release action. Do not equate a handler being called or returning true with this macro having been executed.

**Unknowns:** No current CVar value, per-button runtime attribute snapshot, native click trace, successful right-click item use, or Shift-right-click consumption was supplied for 002. The successful combat tests for 001 do not establish these values or outcomes.

### 5. Potential consequences and what must be preserved

**Confirmed configuration / conditional consequence:** Generic action ownership is broader than the advertised left-click use. With release-side action selection, right-button release can submit the same item-use macro before exclusion processing. Thus the inspected secure execution rules do **not** guarantee that right-click is skip-only.

**Runtime outcome remains conditional:** If the item is usable in the current context and the request succeeds, right-click can activate it, consume a charge/item, begin its cast, or open it. Item-specific requirements, cooldowns, combat limits, or other native behavior may prevent success. No specific consumed item or successful unintended activation is recorded. MEDIUM remains a credible conditional functional issue, not a runtime-confirmed loss.

A future isolated correction would need to preserve:

- Secure `/use item:ID` execution on left-click, including the existing down/up registration and user key-down preference.
- Modified left-click use where the generic action currently permits it; a plain unmodified-only assignment should not silently narrow modifier behavior.
- Right-click session skip and Shift-right-click permanent blacklist, their existing storage keys, and the single release-side PostClick processing.
- Existing candidate selection, quantity checks, collection filters, display/cooldown updates, and the post-exclusion refresh.
- Existing combat hiding and the user's no-change/monitoring decision for 001.
- Delayed auto-open behavior and finding 003 as separate work; neither is corrected under 002.

### 6. Minimal correction options, if later authorized

No correction is implemented or authorized here. All action-attribute changes would have to remain in the existing out-of-combat refresh/setup boundary; no combat PreClick attribute switching is proposed.

| Option | Intended change | Benefits / trade-offs |
|---|---|---|
| **A. Whitelist left-button action ownership** | Replace the authoritative generic `type = "macro"` assignment with modifier-wildcard left-only `*type1 = "macro"`, ensuring no generic type remains on the button. Existing generic macrotext can remain inert for buttons without an action type. | Preferred minimal ownership correction: left use works across modifiers, right has no secure action, and PostClick still receives RightButtonUp. The authoritative assignment at line 517 must be addressed so subsequent refreshes cannot restore the generic type. Blizzard uses `*type1` itself (R2-B5). Fresh/reloaded and repeated-refresh behavior need testing. |
| **B. Explicit right-button no-op** | Retain generic type, but assign modifier-wildcard `*type2` to the documented empty-string `ATTRIBUTE_NOOP` outside combat. | Smaller additive mask for currently registered right clicks; covers Shift too. It leaves broader generic ownership in place for any other button registered later, so it expresses a right-click exception rather than a left-only policy. Clearing type2 to nil/false is not the documented no-op and should not be assumed to stop fallback to generic type. |

Changing macrotext to left-only as well can make ownership more explicit but adds another attribute change; it is not necessary merely to prevent macro dispatch once no right-side action type resolves. A plain `type1` instead of the modifier-wildcard form needs special care because the preservation target includes modified left clicks.

Removing RightButtonUp registration would remove the skip/blacklist interaction and is unsuitable. Registering RightButtonDown would expand the unsafe action surface. Forcing one key-down CVar/value would mask the problem for a particular mode rather than separate action ownership. Mutating action attributes from an ordinary PreClick, replacing the secure OnClick, or adding secure-button OnMouseDown/OnMouseUp handlers would introduce unnecessary secure/combat concerns. None is recommended.

### 7. Controlled in-game tests

These are recommended user-controlled tests, not tests performed by Codex. Use a deliberately expendable, repeatable item whose activation and quantity/charge effects are easy to observe. Separate trials need an available candidate; an item already session-skipped or permanently blacklisted cannot provide an equivalent repeated test.

Record the client build, current `ActionButtonUseKeyDown`, relevant held-key preference, item ID/count, whether Auto Open is enabled, and any relevant addon/binding overrides. Isolate Auto Open through the existing UI if the user chooses to do so, so finding 003 cannot be mistaken for a right-click result. Codex has not changed any setting or CVar.

| Trial | What to record |
|---|---|
| Left-click with key-down enabled | Which edge starts the use; quantity/charge, cooldown, cast, or loot evidence; single expected action |
| Right-click with key-down enabled | Session skip result and any unexpected activation; the source predicts no normal macro on its registered release edge |
| Shift-right-click with key-down enabled | Permanent blacklist result and any activation; restore only the test blacklist entry through existing UI if another equivalent trial is wanted |
| Left-click with key-down disabled | Release-side expected use and no unintended double action |
| Right-click with key-down disabled | Whether activation/use evidence accompanies or precedes the session skip; this is the highest-value reproduction for 002 |
| Shift-right-click with key-down disabled | Whether activation/use evidence accompanies permanent blacklisting |
| Optional Ctrl/Alt-modified left/right trials | Check modifier preservation and conflicting native bindings; do not generalize a modified-input conflict to plain right-click |

Keep a CVar constant during each physical press/release. If the user changes it for the matrix, record and restore their original preference afterward. A blacklist/skip message alone does not prove that no use request ran; observe actual activation and the final bag state. Conversely a macro dispatch is not proof of successful consumption. If a low-impact right-click activation is reproduced, retain the item ID, settings, and sequence as the concrete trigger before deciding on correction A. No combat test is needed to establish this out-of-combat click-ownership question, and 001 should not be reopened without new failure evidence.

### 8. Final research verdict

**Verified source facts:** OUS assigns a generic macro action and registers RightButtonUp. Blizzard resolves generic action attributes across mouse buttons/modifiers and selects normal down/up actions from the button override/CVar. OUS's Shift/session distinction occurs only in PostClick. Its current code supplies no button-specific no-op or left-only action ownership.

**Source-supported inference:** With key-down use disabled on the normal addon-template path, right-button release can dispatch the use macro before OUS handles exclusion. Shift-right-click has the same conditional risk. Secure execution does not guarantee skip-only behavior; the relevant separation must come from action ownership.

**Unverified:** Native OUS click sequencing, the user's current click settings, and actual item activation/consumption. No 002 runtime failure or successful safety test is recorded. Original finding severity and conditional wording are retained.

**Recommended next step:** Perform the controlled release-mode right-click and Shift-right-click trials with an expendable item. If correction becomes necessary and is authorized, prefer left-only modifier-wildcard action ownership in the existing guarded assignment path, while keeping PostClick skip/blacklist behavior and the user's existing combat behavior intact. Status remains **RESEARCHED — Runtime verification pending.** Findings 003–012 remain OPEN.

### 9. Validation for this runtime-recording / 002 research update

Only this Markdown document is edited. Validation checks that the preserved general-audit block and all prior Investigation 001 prose remain unchanged, all 12 original findings remain present, only the intended statuses advance, and links/internal references and Markdown structure remain valid. The final documentation delta and whitespace are checked, including the existing untracked document's full-file diff. Historical static/mock results are not rerun or relabeled as current runtime evidence. No production implementation, staging, commit, or push is included.

<a id="runtime-observations-002"></a>

### 10. User-reported runtime results and monitoring decision

**Recorded:** October 25, 2026. **Evidence category:** user-reported controlled runtime observations.

**Test item:** Handful of Treats, item ID **37586**.

**Current status: RUNTIME TESTED — No unintended activation observed; monitoring.**

| Reported setting / verification | Input | User-reported result |
|---|---|---|
| `ActionButtonUseKeyDown = 1` | Right-click | Correctly skipped the item for the session |
| `ActionButtonUseKeyDown = 1` | Left-click | Correctly used the item |
| `ActionButtonUseKeyDown = 0`, changed through CVarBrowser and confirmed using GetCVar | Right-click | Again produced the intended session-skip behavior; no unintended item activation was reported |

The user explicitly verified the release-mode CVar value. Do not explain the result away by assuming that the setting was not changed. The reason actual unintended activation was not reproduced is not established by these observations. The earlier source-supported secure-action concern remains documented; its predicted successful unintended activation did not occur in this concrete reported trial.

No Shift-right-click, other modifier, left-click at value 0, other item, per-button runtime attribute trace, native use-request trace, or exact runtime build/environment was reported for these trials. Do not extend the results to those cases or import the separate raid environments from 001. The source/client baseline remains historical context, not a newly measured build for these tests. The record distinguishes no unintended activation reported from proof that no native use request was ever dispatched.

**Decision:** No production change is authorized. Preserve the existing source findings and research, record that actual unintended activation was not reproduced, and monitor without generalizing the result to every item, modifier, or client state. No left-only attribute patch or other 002 correction is selected. This addendum supersedes the earlier immediate test/implementation recommendation for the completed case while preserving that investigation as history. Finding 001 remains runtime tested and monitoring; finding 003 is investigated independently below.

---

<a id="focused-investigation-003"></a>

## Focused Investigation 003 — Openables Delayed Auto-Open

**Research date:** October 25, 2026. **Finding:** OUS-AUDIT-003, MEDIUM.

**Status: RESEARCHED — Decision pending.**

**Implementation:** None. **New standalone/native tests:** None performed.

### 1. Scope and source register

One focused inspection of `Openables.lua` covered the candidate builder/scanner, shared state assignments, delayed auto-open, refresh callers, invalidation behavior, and existing safeguards. The relevant OUS2 controls were inspected for their writes and refresh integration. This is source analysis against the existing OUS baseline `6edb423d55a214bb6181c8e0af84ca65b245e114`; line references identify that historical source. The previously recorded LIVE/client baseline remains preserved above. No new Blizzard API behavior, item-specific permission, or current native outcome is inferred from a new source snapshot in this investigation.

| Ref | OUS source and historical lines | Evidence |
|---|---|---|
| R3-1 | [Openables.lua](../Openables.lua#L19), lines 19–29 | Shared `currentItem`, bag-scan debounce flag, and pending item-data state |
| R3-2 | [Openables.lua](../Openables.lua#L59), lines 59–69, 99–105, 121–127, 245–251 | Item/tooltip loading callbacks converge on `OP.Refresh()` |
| R3-3 | [Openables.lua](../Openables.lua#L262), lines 262–341 | Existing blacklist/minimum-quantity checks; candidate construction, preferred-item scan, and returned candidate |
| R3-4 | [Openables.lua](../Openables.lua#L474), lines 474–492 | Right-click exclusions clear the shared candidate and immediately refresh |
| R3-5 | [Openables.lua](../Openables.lua#L496), lines 496–542 | Display update consumes the candidate; normal rendering retains it |
| R3-6 | [Openables.lua](../Openables.lua#L607), lines 607–625 | Module/combat entry guards, reassignment, schedule-time Auto Open test, and delayed callback |
| R3-7 | [Openables.lua](../Openables.lua#L629), lines 629–695 | Bag-only debounce, world/combat/item-lock/collection event refresh paths |
| R3-8 | [Openables.lua](../Openables.lua#L1016), lines 1016–1069 and 1574–1575 | Custom-item changes, `/op auto`, and public display-to-refresh bridge |
| R3-9 | [OUS2Page_Openables.lua](../Config2/OUS2Page_Openables.lua#L84), lines 84–95, 174–181, 224–240, 294–307, 420–433 | Module/Auto Open writes and live refresh; management changes versus UI-only page refresh |

All APIs discussed already occur in these paths. A proposed final bag-slot identity check can reuse the same `C_Container.GetContainerItemInfo` and `info.itemID` access already used by the scanner; no new item-instance/GUID API is proposed. The native permission and item-specific success of `UseContainerItem` from a timer are not established here.

### 2. Control flow and candidate lifecycle

1. `OP.Refresh()` returns immediately in combat. If the module is disabled, it hides the container and returns **without clearing `currentItem`** (R3-6).
2. An enabled, out-of-combat refresh assigns `currentItem = FindOpenableItem(currentItem and currentItem.itemID)`, then renders it. The scanner prefers the previous item ID when still eligible, otherwise returns a fallback candidate or nil (R3-3/R3-6).
3. Candidate construction creates a table containing `itemID`, `bag`, `slot`, icon, count, and category. A refresh can rebuild that table even when the logical item/slot is unchanged. Display counts can aggregate stacks, while the candidate still carries one selected bag/slot (R3-3).
4. Only at schedule time, the code checks `db.autoOpen` and non-nil `currentItem`, then schedules a 0.3-second callback (R3-6).
5. The callback refers to the shared Lua upvalue `currentItem`; it does **not** capture the scheduling candidate's ID, bag, slot, table, or a generation/token. At execution it checks only non-nil `currentItem` and fresh combat state, then calls `UseContainerItem(currentItem.bag, currentItem.slot)`.
6. No pending auto-open handle, ownership record, cancellation request, or generation invalidation exists in this path. Returning early, disabling a setting, or refreshing does not retract callbacks already scheduled. This is a fact about the existing implementation, not an assertion about undocumented timer APIs.

An exclusion sets the shared value to nil and immediately refreshes. If another eligible candidate exists, that refresh can install it and schedule its own callback. An older callback can then observe the replacement; temporarily clearing the variable is not durable invalidation. If the new scan returns nil, the callback's existing nil check safely prevents that attempt.

### 3. Answers to the eight research questions

| Question | Answer and evidence classification |
|---|---|
| 1. Can a pending callback execute after Auto Open is disabled? | **Yes, its source path permits the use call.** The callback does not recheck `db.autoOpen`. OUS2 changes the setting and refreshes, but an enabled-module refresh can retain/rebuild a candidate without scheduling a replacement; the old callback remains. `/op auto` disabling does not even call `OP.Refresh()` (R3-6/R3-8/R3-9). Actual native use success remains unverified. |
| 2. Can it execute after the module is disabled? | **Yes, its source path permits the use call.** The disabled refresh hides the container, returns, and retains the candidate. The old callback does not check the module flag (R3-6). Hiding the button/container is not a cancellation of this separate delayed Lua path. |
| 3. Can a changed currentItem redirect the callback? | **Yes by verified Lua control flow.** The closure reads the execution-time shared candidate. A refresh or exclusion can replace A with B; an old callback scheduled for A then uses B's coordinates if they are current when it runs. No native candidate-switch reproduction is claimed. |
| 4. Can bag contents change before execution? | **The code leaves that possibility unchecked.** It records a bag/slot at scan time and does not reread that slot at use time. Moving/removing/using items between those points is an inventory-state scenario requiring a client test; a particular event order or replacement-item use is not established. |
| 5. Can repeated refreshes overlap callbacks? | **Yes at the source scheduling level.** Every qualifying `OP.Refresh()` schedules another callback; no auto-open single-pending check exists. Only `DebouncedRefresh()` coalesces bag scans. Other callers bypass it. Multiple native successful uses are not proven. |
| 6. Which safeguards exist? | Fresh combat checks at refresh and execution; non-nil execution-time candidate; enabled module and Auto Open checks when scheduling; existing scan-time eligibility/filtering; bag-scan debounce and item-loading guards. Their boundaries are detailed below. |
| 7. Smallest correction? | Recheck both flags and combat at execution, bind requests to candidate/refresh ownership, reject stale bag-slot identity, and ensure superseded requests cannot act. Keep existing selection, secure click, and combat hiding behavior. No correction is implemented. |
| 8. Observable verification? | Exercise disablement during the delay, candidate/slot replacement, and overlapping refreshes with an expendable item; after any authorized correction verify no old request acts and a valid newest request still works. Native timing/result evidence is required. |

### 4. Existing safeguards and their limits

| Existing safeguard | What it protects | What it does not establish |
|---|---|---|
| Refresh-time `InCombatLockdown()` | Prevents that refresh from scanning/rendering/scheduling during current lockdown | Does not cancel a previously scheduled callback |
| Callback-time `InCombatLockdown()` | Prevents the use call if lockdown is active when the callback executes | Does not validate enable flags, item identity, or request ownership |
| Callback-time non-nil `currentItem` | Prevents indexing/using when no candidate is currently stored | A non-nil replacement or stale stored slot still passes |
| Module and Auto Open schedule-time checks | Avoids creating this request while those checked states are false | Does not guarantee either setting is still enabled 0.3 seconds later |
| Candidate builder | Applies existing blacklist, minimum-quantity/category, usability, and collection checks at scan time | Does not reserve a physical item or revalidate it at execution |
| Preferred candidate by item ID | Reduces unnecessary selection changes while an item remains eligible | Does not bind an old timer to that item/slot or prevent a fallback |
| `scanPending` / 1.5-second debounce | Coalesces `BAG_UPDATE_DELAYED` refresh work through that helper | Does not coalesce direct configuration, item-load, collection, or other refresh paths |
| Pending item-load/tooltip guards | Limit particular repeated loading requests | Do not own or invalidate auto-open callbacks |
| Existing 0.3-second delay | Gives a delayed use opportunity | Does not itself prove slot stability, cancelability, or native permission |

The OUS2 page's own `Refresh()` updates control textures/counts/scale display; it is not the same function as `OP.Refresh()`. Its checkbox handler reaches the engine through `OUS.Openables.UpdateDisplay()`. Management actions that alter custom/blacklist data can also refresh the engine; merely opening the page or redrawing a checkbox is not automatically another auto-open schedule (R3-9).

### 5. Risks, timing examples, and impact

**Disablement:** A callback scheduled while enabled can survive either setting change and later submit a use request. The combined disabled-flags case has an earlier standalone reproduction; native item activation after either toggle has not been reported.

**Candidate replacement:** Conceptually, refresh A at time `t` schedules a callback for `t + 0.3`. Refresh B at `t + 0.1` changes the shared candidate and schedules another for `t + 0.4`. At `t + 0.3`, the old callback reads B rather than A; B can receive a request only 0.2 seconds after its own selection. The later callback reads whatever candidate exists then. These times illustrate the literal scheduling logic; they are not a measured WoW timeline or a promise of exact timer timing.

**Slot replacement without a timely refresh:** If the selected slot changes before the callback and the shared candidate has not been updated, the code still passes its old bag/slot to the native use call. Depending on the actual contents and native restrictions, the call could fail, do nothing, or act on a replacement. The specific result is a runtime unknown. The bag debounce does not make inventory immutable during the wait.

**Overlapping requests:** Separate eligible refreshes can leave more than one callback logically pending. All inspect shared current state; stale requests can bunch up against the same or subsequent candidate. No duplicate consumption count is established. Successful use, failure feedback, and resulting bag/item-lock events may change the next outcome, so do not treat the example as deterministic native double-use.

Impact is potentially an action after opt-out, an early/unintended request against a replacement, or redundant requests. The source demonstrates missing validity boundaries; it does not demonstrate data loss, native protected-action errors, or a successful wrong-item activation. This remains a MEDIUM lifecycle/correctness concern.

### 6. Evidence ledger: source, historical standalone, native unknowns

- **Verified source behavior:** Both enable flags are checked only before scheduling; callback reads a shared upvalue; no callback-time item/slot identity check or auto-open ownership exists; every eligible refresh can schedule a request; the bag debounce is not global. These conclusions come from the single focused inspection above.
- **Previously reproduced standalone behavior:** The original audit loaded the existing module with mocked frame/item/container APIs, scheduled auto-open, set both `modules.openables` and `openables.autoOpen` false, called refresh, then invoked the queued callback. Its mocked `UseContainerItem` was still called. This is the historical combined-disable control-flow result; it did not independently reproduce each flag alone, candidate replacement, native timer dispatch, or native item consumption. It is not rerun here.
- **Unverified native WoW behavior:** Successful use after disablement, actual wrong-candidate/slot activation, duplicate use, precise event/timer ordering, and item-specific permission from the timer. Neither the successful 001 combat tests nor the 002 Handful of Treats click tests exercised this isolated auto-open lifecycle.

### 7. Minimal correction recommendation, subject to authorization

A small engine-local validity correction can use existing APIs and runtime-only local state:

1. **Recheck permission to proceed at callback execution:** the module remains enabled, the current Auto Open setting remains enabled, and combat is still clear. If any check fails, return without attempting use.
2. **Establish one logical owner:** capture the scheduled candidate's `itemID`, bag, and slot and associate the callback with a transient request generation/identity. Superseding refreshes and invalidation paths must make older requests inert, including early returns on module disable. Old `C_Timer.After` callbacks may still dispatch and simply return; this does not require inventing a cancellation API.
3. **Revalidate current candidate and slot:** the callback must still own the current request, the intended candidate fields must still match, and a fresh existing `GetContainerItemInfo` read must report the expected item ID in the intended slot. If identity or relevant eligibility has changed, abandon that old request and let the established refresh flow select later. An item-ID/slot check prevents a different item ID being used; it does not claim to distinguish every physical instance of identical items.
4. **Do not let stale completion clear a newer request:** any pending-owner bookkeeping must be consumed/cleared only by its owner. Keep post-action selection and normal bag refresh behavior in the existing system.

Flags alone would address opt-out but leave candidate/slot/overlap concerns. Capturing coordinates alone would leave stale-slot risk. A slot check alone would leave disabled-setting and overlapping-request risk. The recommendation therefore combines these small validity boundaries without replacing the scanner or changing secure-click behavior.

A generation check is sufficient to prevent old requests from acting even if their timers cannot be canceled through the current code. If every refresh replaces the request, the delay starts again after the latest refresh; sustained refreshes could postpone auto-open. Retaining one pending request for an unchanged logical candidate avoids that delay but requires more bookkeeping. This is a bounded implementation trade-off to review, not a reason to add polling or a general scheduler. Candidate tables are rebuilt during scanning, so table-reference equality alone is not a substitute for a deliberate ownership policy.

No SavedVariables structure, dependency, new native API, blacklist policy, item-selection precedence, click attribute, or combat-visibility change is needed for this recommendation. Existing 001/002 runtime-tested behavior remains untouched. No source correction is authorized by this research document.

### 8. Focused runtime requirements

The observations below would test native reachability now and, after any separately authorized patch, verify the correction. Use an expendable, repeatable item and record the Auto Open/module settings, item ID, bag/slot, quantity/charge or activation evidence, and whether the decisive change occurred before execution. Codex has not changed any settings, bag contents, or code.

| Scenario | Observable acceptance target after an authorized correction |
|---|---|
| Normal enabled auto-open with a stable candidate | One eligible current request can still use the intended item; no general behavior regression |
| Disable Auto Open within the pending interval, through OUS2 and separately `/op auto` | No old use attempt after the setting is off; the slash path must not rely on an off-transition refresh |
| Disable the Openables module during the interval | Container visibility follows existing behavior and no old auto-open request acts |
| Disable and quickly re-enable / refresh | Old requests stay inert; only a valid current request can act |
| Candidate A removed/excluded so refresh selects B | A's old callback cannot use B early; B's own valid request governs its use |
| Move/remove the intended item or replace its original slot | Old request cannot use a different item ID or stale coordinates |
| Two eligible direct refreshes before the first request executes | Only the selected current logical owner can attempt use; redundant old callbacks are harmless |
| No candidate remains | Pending callbacks return without attempting use |
| Combat active at callback execution | Existing combat guard continues preventing the timer-use call; combat hiding is unchanged |

The 0.3-second interval can make manual races hard to establish. A negative result without proof that a callback was pending before the toggle/change does not disprove the source path. Do not add debug timers, test files, or production instrumentation under this task; any later instrumentation or implementation requires its own authorization. A bag-count change alone also needs attribution: isolate ordinary clicks and other automation, and do not mistake the separate 002 right-click path for delayed auto-open.

### 9. Final research verdict

**Confirmed at source level:** Pending auto-open lacks fresh enable-state checks, candidate/slot binding, and a single logical request owner. Repeated engine refreshes can overlap scheduled callbacks. Existing combat, nil, scan-time eligibility, item-loading, and bag-debounce safeguards are real but do not close those boundaries.

**Historical standalone evidence:** The combined-disable case reached the mocked use call. This establishes the tested Lua control-flow defect, not a native WoW item-use outcome.

**Still unverified:** Successful unintended activation after disablement, candidate/slot replacement, or overlapping native callbacks. No such runtime result is claimed and no fix is implemented.

**Recommended next decision:** Review and, if desired, authorize an isolated 003 patch for callback-time flag checks, request ownership, and bag-slot identity validation, followed by the focused native tests above. Alternatively retain it as a researched source concern while collecting a controlled native reproduction. Status remains **RESEARCHED — Decision pending.** Findings 001/002 remain runtime tested and monitoring; 004–012 remain OPEN.

### 10. Validation for the 002 runtime record and 003 research

The intended delta is limited to the current status explanation/index, a navigation link, the appended 002 runtime addendum, and Investigation 003. The preserved general audit and all prior historical investigations remain unchanged. Validation checks all 12 findings and statuses, Markdown/internal references and historical source links, the final documentation delta, `git diff --check`, and full-file whitespace for this existing untracked document. No new standalone test or native WoW validation is performed; prior results remain qualified as historical or user-reported. No production implementation, staging, commit, or push is included.

<a id="implementation-003"></a>

### 11. Implementation addendum — delayed Auto Open validity

**Date:** October 25, 2026. **Status: IMPLEMENTED — Runtime verification pending.** The user authorized a minimal correction in `Openables.lua` plus the named TODO/audit documentation updates. The original finding, investigation, and historical validation records above remain unchanged. Their earlier no-implementation statements describe those earlier tasks; this addendum records the later authorized patch. No WoW runtime validation is claimed.

**Correction:** `OP.Refresh()` now retains one transient pending request keyed by item ID, bag, and slot. A repeated refresh of the same effective candidate retains the request and its original **0.3-second** deadline. A replacement candidate supersedes it; disabled module/Auto Open, no candidate, a combat-blocked refresh, combat entry, and `/op auto` disabling invalidate pending ownership. Older timer callbacks can still dispatch but cannot act after losing ownership. This uses the existing `C_Timer.After` path and one local request reference, without polling, new SavedVariables, or a new timer/cancellation API.

At execution, the callback checks ownership, both enable settings, current combat state, and the current candidate's ID/bag/slot. It rereads the original slot with the existing `C_Container.GetContainerItemInfo`, rejects a missing/different item ID, and reuses `BuildOpenableCandidate` for the existing blacklist, minimum quantity, usability, collection, and dynamic-category rules. It checks ownership again after that eligibility call because item loading can re-enter refresh. A stale callback cannot clear a replacement request. The owner is cleared before the native use attempt, and only the captured original coordinates are passed to `UseContainerItem`.

**Boundaries preserved:** Item-selection order and preferred-item logic, secure manual click attributes/handlers, default settings, item databases, SavedVariables schemas, existing combat hiding, and 001/002 monitoring decisions. The OUS2 combat-close/reopen requirement remains separate and is not implemented. `Openables.lua`'s source-header date is updated to `2026.10.25`; addon release metadata is unchanged.

**API evidence:** The previously inspected LIVE mirror still identifies `12.1.5 (70575)`, commit `15881d522c44cd106d3d8660106ec9f9d2f44167`. [ContainerDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua#L192), lines 192–209, permits no return from `GetContainerItemInfo`; lines 766–785 describe `ContainerItemInfo`, including item ID and stack count. The patch guards a missing result and uses fields already consumed by the existing scanner. The existing `UseContainerItem` signature remains at lines 584–595. This validates the API usage, not native item-use permission or success from a timer. No Blizzard frame/template behavior was changed by this callback patch.

**Offline validation evidence:**

- Lua 5.1 syntax: `C:\Tools\Lua51\luac5.1.exe -p Openables.lua` passed, exit 0.
- Targeted `luacheck Openables.lua`: **43 warnings / 0 errors**, unchanged from the immediately measured pre-patch baseline. Exit 1 denotes those warnings; no new warning count was introduced.
- **19/19 deterministic checks passed** under Lua 5.1 using the actual modified module with mocked UI/item/container/timer APIs. The lightweight harness ran through standard input; no test file was added to the repository.
- Requested cases passed: module disabled before callback, Auto Open disabled before callback, candidate replacement, changed bag-slot item, repeated refresh, combat before callback, and valid unchanged candidate with the 0.3-second deadline.
- Additional cases passed: disabling through a refresh, `/op auto` off/on without reviving old work, empty slot, no-candidate refresh, same item moved to a new slot, fresh blacklist, reduced stack below the existing threshold, an existing dynamic recipe category without a DB entry, and eligibility re-entry with either a newer candidate or the same candidate.

**Remaining native uncertainties / acceptance:** No client launch, native protected-action test, or live auto-open consumption result was obtained. Item ID plus slot does not uniquely identify identical physical item instances; the correction deliberately uses the module's existing identity contract. Native permission, item-lock/event timing, and interaction with manual clicks or other automation remain client tests. With an expendable repeatable item, verify normal Auto Open, disabling each flag before execution (including the slash path), replacing/moving the item, repeated refreshes, and combat entry. Confirm that stale work never uses another candidate and that a valid current request still works. With Auto Open off, smoke-test existing manual left-click and skip/blacklist behavior. Preserve the user's 001/002 successful observations without treating these offline checks as new runtime evidence.

**Related future work:** `Documentation/TODO_v2.md` now contains unchecked **OUS-OPENABLES-DYNAMIC-001** for read-only comparison with the exact installed NOP version and the user-reported 93 custom items. That research is not implemented here. Recognition based only on a generic `Use:` tooltip prefix is explicitly excluded. NOP and item databases are outside the implementation change.

<a id="runtime-verification-003"></a>

### 12. Runtime-verification addendum — OUS-AUDIT-003

**Recorded:** October 25, 2026. **Status: IMPLEMENTED — RUNTIME TESTED — RESOLVED.** This addendum records the user's completed WoW testing and supersedes the implementation addendum's runtime-pending disposition. The original finding, investigation, implementation addendum, and historical evidence remain preserved.

**User-reported WoW runtime results:** Testing passed for normal Auto Open operation; disabling Auto Open and module enablement; candidate/slot changes; repeated refresh behavior; combat restrictions; manual left-click item use; and right-click session skip and blacklist behavior. Auto Open remains disabled by default and was enabled temporarily for testing. These are user-reported client results, not runtime tests performed by Codex.

**Previously reported Codex offline validation:** Lua 5.1 syntax passed; targeted LuaCheck reported **43 warnings, zero errors, with no warning increase**; **19/19 deterministic checks passed**; and `git diff --check` passed. These historical offline results are separate from the user's WoW runtime observations and were not rerun for this documentation-only update.

**Remaining limits:** The tests do not exhaustively establish every timing or item-identity edge case. Item ID plus bag/slot does not uniquely identify identical physical item copies. Resolution records the implemented correction and the reported test coverage; it does not expand that coverage into a universal guarantee. Findings 001/002 remain runtime tested and monitoring, and 004–012 remain OPEN. The separate OUS2 combat-close/reopen requirement is outside this closeout.

<a id="focused-investigation-004"></a>

## Focused Investigation 004 — Utilities Master Toggle

**Research date:** October 25, 2026. **Status: RESEARCHED — Decision pending.** Read-only inspection of the current Utilities implementation, its callers, Core initialization/reset paths, and OUS2 controls. No production correction or WoW runtime test was performed. The original 004 finding is preserved; the rare-announcer qualification below corrects its overly broad implication that announcements ignore the master switch. Earlier status statements in historical investigations remain historical; the index records current dispositions.

### 1. Evidence and existing toggle semantics

OUS source references below identify the inspected working checkout, not new commit-pinned line numbers. Relevant evidence: [Utilities defaults/artwork](../Utilities.lua#L12), lines 12–91; [rare announcer](../Utilities.lua#L120), lines 120–193; [repair and slash entry](../Utilities.lua#L228), lines 228–298; [junk collection and execution](../Utilities.lua#L310), lines 310–466; [blacklist manager](../Utilities.lua#L476), lines 476–798; and [merchant cleanup](../Utilities.lua#L800), lines 800–819. Call-site search found no other caller of the local rare-announcer function.

[Core.lua](../Core.lua#L29), lines 29–40 and 85–103, initializes the master Boolean to true only when absent and preserves a saved false value; Utilities settings and the junk subtable are initialized separately. Reset at lines 150–179 restores module/default settings and explicitly reapplies artwork before the later reload. [OUS2Page_Utilities.lua](../Config2/OUS2Page_Utilities.lua#L72), lines 72–78, writes a checkbox's key and calls its optional callback, then refreshes presentation. The master row at lines 220–227 supplies **no callback**. Feature controls at lines 229–312 remain editable regardless of the master switch; only the artwork row supplies the artwork-application callback. Refresh at lines 314–320 displays stored checkbox values rather than an effective master-and-feature state.

**Verified source fact:** Utilities is loaded and registers events/hooks independently of its master flag. The master is currently an execution guard for `/ous_rare`, not a uniform module lifecycle switch. There is no master-disable handler here to unregister events, invalidate pending sales, hide the merchant sale button, or restore artwork. **Source-supported interpretation:** This conflicts with the UI help, “Enable or disable the Utilities module,” for automated repair/sales and ongoing artwork control. The presence of independent feature settings alone does not establish intentional independence from that master.

### 2. Feature-by-feature control flow

| Feature / path | Activation | Master check | Independent setting | Can run after master is disabled? / assessment |
|---|---|---|---|---|
| Rare announcement | `/ous_rare` → `AnnounceRare()` | **Yes**, slash wrapper at Utilities:296 | `rareEnabled`; target/open-world/map guards | New announcements are blocked through the sole found entry. The local helper omits the check, but this is not an observed bypass. Original finding needs this qualification. |
| Rare waypoint restoration | 0.1-second callback after a prior announcement, when a previous pin existed (Utilities:160–164) | No callback recheck | No separate restore switch | Previously scheduled restoration can run. This is cleanup of an already-started operation; suppressing it could leave the temporary pin. Apparently appropriate independence, not a new announcement. |
| Auto Repair, including reports/accounting | `MERCHANT_SHOW` → `DoRepair()` | No | `repairEnabled`; `guildRepair` chooses funding request; `announceRepair` controls output | Repair request and associated accounting/output remain reachable with master off. Clear source mismatch; actual repair/funding effects need runtime verification. |
| Junk entry / manual next batch | `MERCHANT_SHOW` → queue/button; 0.3-second callback or sale-button click → `SellNextBatch()` | No at either entry | `junkSell.enabled` at both entries; Shift condition at start; batch limit/report options | Can collect/show/start with master off when feature enabled. Inconsistent with master wording. A delayed batch start does recheck feature enablement. |
| Junk continuation | `SellNextItem()` immediately, then 0.2-second timer chain | No | **No fresh `junkSell.enabled` check**; existing merchant/combat/visibility guards | An active batch can continue despite either switch becoming false, subject to other guards. Queue item-ID/slot and positive-price checks remain. Native sale success is unverified. |
| Extra Action / Zone Ability artwork | Login/world/action-bar/zone/addon events, frame-level secure hooks, pending combat-exit application, setting callback and reset | No | `hideExtraActionArtwork` determines hide versus show | Continues applying its stored preference with master off. Source inconsistency; intentional persistent independence is not established. Immediate disable currently does not restore artwork. |
| Junk blacklist management | OUS2 action or `/js`; add/remove/wipe UI callbacks; OUS2 zero-delay presentation callback | No | Neither master nor seller-enabled gates editing | Remains available. Reasonable configuration independence: editing a blacklist does not itself sell an item. Product intent still requires a decision; do not blanket-disable configuration. |

### 3. Safeguards, compatibility, and combat boundaries

Junk sale execution already checks `isMerchantOpen`, `InCombatLockdown()`, and `MerchantFrame:IsShown()`; batch entry also checks feature enablement and Shift. Merchant closure clears the queue and hides its button; vendor-refusal/gold-cap errors clear the queue and merchant-open state. These cleanup branches must continue running while disabled. Blacklisting is applied during queue collection; this investigation does not recommend moving it or changing bag-slot identity, pricing, batching, transaction recording, or repair funding semantics.

Artwork application already defers during combat with `artworkApplyPending` and reapplies on `PLAYER_REGEN_ENABLED`. Its hooks remain installed; a master check cannot undo an earlier texture hide by merely returning. A future disable path must restore/relinquish decorative styling out of combat and preserve deferred handling, without forcing action frames visible or changing secure click ownership. No new combat/taint failure is established by this source inspection. Repair has no explicit combat guard in this path; that fact does not prove that native repair is permitted in every context. Additional Boolean guards can prevent calls; they do not demonstrate that the underlying merchant or artwork APIs are universally safe.

**Blizzard implementation context:** The local mirror was rechecked as branch `live`, commit `15881d522c44cd106d3d8660106ec9f9d2f44167` (the audit's recorded 12.1.5 / 70575 source baseline; no live client build was queried). The conditional Lua/XML walk confirms separate decorative textures: [ExtraActionBar.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ActionBar/Shared/ExtraActionBar.xml#L39), lines 39–44, defines `style`; lines 3 and 116 connect its inherited button template and instance. [ExtraActionBar.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ActionBar/Shared/ExtraActionBar.lua#L10), lines 10–60, updates texture/visibility and includes special empty/forced display paths. [ZoneAbility.xml](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ZoneAbility/ZoneAbility.xml#L3), lines 3–28, defines `Style` and frame handlers separately from spell buttons. [ZoneAbility.lua](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_ZoneAbility/ZoneAbility.lua#L158), lines 158–195, can return before display updates and otherwise updates the style texture. Its comment at line 158 says not to update unchanged data because it could affect OnClick; that is a developer note, not runtime proof of OUS taint. This supports keeping restoration confined to artwork and respecting Blizzard display ownership; it does not establish an exact universal restore policy or require button/template changes for this finding.

**SavedVariables compatibility:** A correction can read the existing master/feature keys without migration, new keys, or defaults changes. Disabling the master should preserve per-feature preferences and blacklist contents so re-enabling restores the user's selected policy. Do not rewrite those preferences to simulate module disablement.

### 4. Smallest correction recommendation and regression risks

**Recommended decision:** Confirm that the master suspends automated/action execution and artwork hiding while allowing configuration management and necessary cleanup. Then authorize a small separate patch, after the focused baseline runtime checks below. No correction is implemented here.

For repair/selling, add effective master guards to `DoRepair`, `OnMerchantShow`, `SellNextBatch`, and `SellNextItem`; at sale continuation also recheck `junkSell.enabled`. Keep merchant-close/error cleanup outside those guards. Define stop/restart semantics explicitly: disabling should clear pending sale work and hide the sale button without erasing already-earned accounting; re-enabling should require a fresh merchant session or explicit fresh collection rather than reviving an old queue. Checks alone cannot remember a brief off/on transition occurring entirely between callbacks; immediate cancellation needs a small disable callback in the existing master control, not polling or a new persistent state format.

For artwork, derive effective hiding from master **and** feature preference, preserve combat deferral, and invoke the existing application path when the master changes so already-hidden artwork can be restored. Review the Blizzard special-display cases above before choosing the exact restoration behavior; a blanket early return is insufficient. Leave the already-guarded rare entry, its pending waypoint restoration, and blacklist editing available under their existing roles. No event-registration overhaul, new timer, SavedVariables migration, or broad refactor is justified.

Regression risks are stopping a partially completed sale without reporting recorded proceeds correctly, reviving stale queues on re-enable, suppressing merchant cleanup, losing feature preferences, leaving artwork hidden, or showing artwork in a Blizzard empty/forced display state. Blanket checks at every callback can also break waypoint restoration and configuration access. Preserve normal master-on repair, guild-first request/accounting, Shift requirements, 12-item limits, blacklist collection, and merchant-close behavior.

### 5. Focused WoW runtime requirements and verdict

Use expendable unblacklisted grey items and a small repair bill; isolate other repair/vendor/artwork addons for attribution. Record master and feature values, actual item/wallet/durability changes, sale reports, button state, and errors rather than treating an OUS message as proof of a native transaction.

1. **Repair matrix:** With `repairEnabled=true`, compare master on/off on a fresh repair-merchant visit; then verify feature off blocks repair with master on. Check unchanged personal/guild-first reporting when enabled. Current source predicts the master-off case still attempts repair; native results remain unverified.
2. **Sale entry matrix:** With seller enabled, compare master on/off at a fresh merchant; exercise Require Shift and the manual next-batch button. Then turn the seller feature off before the initial 0.3-second callback; that callback should already refuse to start. Distinguish this existing guard from missing master enforcement.
3. **Active continuation:** During a multi-item batch, disable the master, then separately the seller feature, before a 0.2-second continuation. Test brief off/on as a distinct case. Check actual remaining items and accounting. Close/reopen the merchant and verify cleanup; after a future correction verify no old queue resumes and unchanged master-on batching still works.
4. **Rare/cleanup:** With a suitable open-world target and `rareEnabled=true`, verify `/ous_rare` is silent with master off. With master on, verify feature off is silent. For an announcement already started, confirm the prior waypoint is restored even if the module is disabled before its delayed restoration; use a controlled setting and avoid repeated public announcements.
5. **Artwork:** With a real Extra Action/Zone Ability present, compare master/feature combinations, toggle master after hiding, and repeat across combat entry/exit, zone refresh, and reload. Verify button use, icon/cooldown, Edit Mode/empty display, and absence of protected-action errors. Current source predicts the hiding preference remains effective with master off; an approved correction should restore safely and preserve the stored preference.
6. **Configuration/persistence:** Confirm blacklist management remains usable with master off, without a sale; confirm settings survive disable/re-enable and reload. Check that a saved false master is retained after login. Do not use reset or blacklist wipe as a testing shortcut.

**Final research verdict:** Source confirms inconsistent master enforcement for repair, junk entry/continuation, and artwork, plus a missing feature-level continuation check. Rare announcement is already master-gated; delayed waypoint restoration and blacklist configuration should not be treated as equivalent automation failures. Actual master-off transactions, exact callback timing, and combat/taint outcomes require WoW runtime verification. OUS-AUDIT-004 is **RESEARCHED — Decision pending**; 001/002 monitoring, 003 resolved, and 005–012 open remain unchanged.

<a id="implementation-004"></a>

### 6. Implementation addendum — Utilities master-toggle consistency

**Date:** October 25, 2026. **Status: IMPLEMENTED — Runtime verification pending.** The user authorized this focused correction after Investigation 004. The original finding and research above remain historical evidence. Changed production paths are limited to `Utilities.lua` and the existing master checkbox in `Config2/OUS2Page_Utilities.lua`; both source-header dates are updated to `2026.10.25`. No native WoW runtime verification is claimed.

**Exact correction:**

- A local `IsUtilitiesEnabled()` guard reads the existing master setting without changing any feature preferences. `DoRepair()` returns before repair/accounting actions when the module is disabled. Existing repair funding, cost reporting, and transaction logic remain unchanged.
- Junk merchant entry and batch start now enforce the master flag; each sale continuation enforces both master and seller enablement. One transient `junkSaleGeneration` counter owns delayed work. Cancellation advances it, clears the pending queue/merchant-active state, and hides only OUS's sale button. Both the existing 0.3-second start and 0.2-second continuation capture their generation; stale callbacks cannot act on a later queue. Starting a batch also advances the generation so an earlier delayed start cannot overlap it. Merchant reopening/closure and vendor-error cleanup invalidate old work through the same helper.
- `OUS.ApplyUtilitiesModuleSetting()` cancels sales immediately when disabled and invokes the existing artwork application function. The existing OUS2 master checkbox now calls it after writing the Boolean. Re-enabling does not restart an old sale or rescan bags: a fresh merchant visit collects the next queue. Shift checks, blacklist collection, 12-entry batching, price/slot checks, native sale calls, and accounting remain in their existing algorithm. Already-recorded transactions are retained; cancellation does not introduce a new partial-batch summary.
- Artwork hiding requires both master and the saved hide preference. A transient table records only textures OUS hid. Disable restores those textures to the existing normal alpha/show state once, then relinquishes them; later disabled-module events/hooks do not force unowned artwork visible. Re-enabling reapplies the saved preference. All artwork changes still pass through `InCombatLockdown()` / `artworkApplyPending` / `PLAYER_REGEN_ENABLED`; the latest settings are applied after combat. No action frame is forced visible and secure button actions are unchanged.
- The existing rare-announcement master guard and delayed waypoint restoration are unchanged. OUS2 settings, `/js`, and blacklist management remain accessible. No SavedVariables, defaults, item databases, dependencies, or OUS2 combat-close/reopen behavior changed.

**Source/API boundary:** This patch uses existing module API calls and the same LIVE Lua/XML artwork references cited in Investigation 004; no new Retail API signature or protected action is introduced. The earlier ownership discussion still applies: restoring the normal texture state once does not establish correctness for every Blizzard empty/forced display state or third-party styling interaction. The master checkbox is the verified notification path. Direct external writes that turn the master off and on entirely between callbacks without invoking the notification cannot be observed by a Boolean guard; no polling, SavedVariables interception, or broader toggle framework was added.

**Codex offline validation:** Both changed Lua files passed the Lua 5.1 parser (`C:\Tools\Lua51\luac5.1.exe -p`, exit 0). Targeted LuaCheck measured **34 warnings / zero errors** before and after the patch: Utilities 34, OUS2 page 0, with no warning increase. **26/26 deterministic checks passed** under Lua 5.1 using the actual modified Utilities module and, for the master-row integration check, the actual OUS2 page, with mocked native UI/merchant/map/timer APIs. The harness ran through standard input and added no repository test file.

The checks covered enabled/disabled master and feature combinations; normal sale delays/transactions; cancellation before start and during continuation; rapid master off/on; old callbacks against a replacement merchant queue; seller-feature disablement; direct master disablement observed at continuation; Shift/manual start behavior; merchant close/reopen and vendor errors; combat/merchant visibility guards; blacklist and 12-entry limits; rare gating and delayed waypoint restoration; artwork restoration, ownership release, reapplication and combat deferral; blacklist/manual-vendor independence; preference preservation; and actual master-row notification. These results establish mocked Lua control flow, not native transaction success or taint safety. Final validation includes `git diff --check`, full-file whitespace checking for the untracked audit, review of the final scoped diff, all 12 original findings/statuses, and preservation of unrelated uncommitted changes.

**Required WoW acceptance:** With expendable grey items and a small repair bill, compare master on/off while each feature remains enabled, then feature off with master on. Verify no repair or OUS sale with master off. Disable during a multi-item sale and before its delayed start; toggle off/on rapidly and reopen the merchant, confirming old work never sells another item and manual vendor use still works. Check retained transaction accounting and partial-batch reporting, normal Shift/blacklist/12-entry behavior, and configuration access/preferences after reload. Confirm rare announcements remain blocked while pending waypoint restoration completes. With actual Extra Action/Zone Ability buttons present, hide artwork, disable/re-enable Utilities, and repeat around combat and zone/ability updates; check safe restoration, saved-preference reapplication, button clicks/cooldowns/Edit Mode, special empty display states, and protected-action errors. No tests in this addendum are user-reported runtime passes. Findings 001/002 remain monitoring, 003 remains resolved, and 005–012 remain open.

<a id="runtime-verification-004"></a>

### 7. Runtime-verification addendum — OUS-AUDIT-004

**Recorded:** October 25, 2026. **Status: IMPLEMENTED — RUNTIME TESTED — RESOLVED.** The user's reported WoW tests support bounded closure; no contradictory evidence was identified in this review. This addendum supersedes the implementation's runtime-pending disposition while preserving the original finding, Investigation 004, implementation addendum, and historical evidence.

**User-reported WoW results:** With the Utilities master disabled, Auto Repair and Junk Seller performed no automatic transactions. Disabling each individual feature prevented its action; normal repair/selling worked with the relevant flags enabled. Pending/active sale cancellation and rapid master-toggle behavior passed the user's test sequence. In the **Draenor Garrison**, Zone Ability artwork was visible with Utilities disabled and hidden with Utilities plus Hide Artwork enabled; re-enabling Utilities reapplied the saved artwork preference. The user supplied screenshots demonstrating the visible/hidden artwork states. These are the user's observations and supplied evidence, not native tests performed by Codex during this documentation task.

**Previously reported Codex offline evidence:** Lua 5.1 syntax checks passed; targeted LuaCheck reported **34 warnings, zero errors**, unchanged from baseline; **26/26 deterministic checks passed**; and `git diff --check` passed. Those mocked/static results remain separate from the user-reported client results and were not rerun here.

**Bounded limits:** This does not establish exhaustive combat-state testing of artwork changes, every Blizzard Extra Action/Zone Ability lifecycle or third-party interaction, or every transaction/callback timing. Reload persistence was not explicitly confirmed by the supplied runtime record. The screenshots support the reported visual states, not all intervening lifecycle transitions. Finding 004 is resolved against the implemented behavior and reported coverage, with these limits retained; the separate duplicate Extra Abilities research TODO is unchanged.

<a id="focused-investigation-005"></a>

## Focused Investigation 005 — XP/Delves Disabled-Bar Visibility

**Research date:** October 25, 2026. **Status: RESEARCHED — Decision pending.** Focused read-only inspection of XP/rep/Delves renderers, frame creation, callbacks, relevant configuration/reset paths, and the favorite-selection renderer caller. No correction, new standalone execution test, or native WoW visibility test was performed. References identify the current inspected OUS checkout; earlier findings retain their historical source baseline and mock evidence.

### 1. Enable and visibility matrix

| Display | Actual enable / selection controls | Existing hide path | Path capable of showing it with master off |
|---|---|---|---|
| Experience | Shared `OdysseusDB.modules.xpBar`; `xpBar` settings contain appearance/behavior, not a separate Experience enable flag. `UpdateBar()` chooses XP below its max-level/XP-disabled conditions unless temporary reputation display takes precedence. | Master checkbox and disabled-module initialization hide `OUS.xpBarFrame`. | `RenderXPBar()` ends with `xpBar:Show()` (engine:592); its caller `UpdateBar()` has no master check. |
| Reputation | Same master and **same frame** as Experience; renderer selects max-level/XP-disabled mode or `Session.forceRepDisplay` with a resolved faction. No independent Reputation-bar enable flag found. | Same master hide; reputation renderer also hides when faction ID/details are unavailable (engine:598–606). | Valid reputation render ends with `xpBar:Show()` (engine:650), irrespective of master. |
| Delves companion | Same XP Bar master; `IsPlayerReallyInDelve()` or temporary unlocked positioning preview selects display. No separate Delves module or companion-enable flag found. | Core initially hides Delves; master checkbox/initialization hide it; `UpdateDelveBar()` hides outside a detected Delve/preview. | `UpdateDelveBar()` shows `OUS.delveBarFrame` at delves:338 without checking master. |
| Delves journey | Same master, conditions, and **same parent frame** as companion; no separate journey-enable flag found. | Same Delves parent hide. | Same parent show; both progress bars are updated in the display branch. |
| Related controls, not bar enable flags | `autoHide`, `activeAlpha`, `fadedAlpha`, `fadeDelay` control alpha; `hideBlizz` targets Blizzard's default XP/rep manager; `sessionStats.sections.experience/reputation` control Session Stats rows. | Alpha zero can make a shown bar visually absent. | None of these controls is an independent disable switch for the four displays above. Do not treat a faded bar as proof of correct master enforcement. |

**Source references:** [xpbar_core.lua](../xpbar_core.lua#L16), defaults/session state at lines 16–90 and frame creation at 123–183; [engine renderers](../xpbar_engine.lua#L549), lines 549–675; [Delves renderer](../xpbar_delves.lua#L249), lines 249–343; [XP Bar master control](../Config2/OUS2Page_XPBar.lua#L1338), lines 1338–1357. The four display names describe two OUS parent frames, not four independently enabled modules. `SetShown()` in the XP configuration hub controls configuration subpages (lines 143–158), not these gameplay bars.

### 2. Verified source paths and root cause

- **Initialization:** [engine:698–748](../xpbar_engine.lua#L698) fills settings and initializes presentation. With master false it hides XP/Delves at 742–745, then **unconditionally calls `OUS.UpdateBar()` at 747**. That public boundary checks only DB/settings existence, selects XP/rep, and calls `OUS.UpdateDelveBar()`. A later renderer can therefore undo the just-applied hide during initialization, including a reload with saved master false.
- **Event qualification:** [engine:870–907](../xpbar_engine.lua#L870) explicitly exempts `ADDON_LOADED` from its master guard; other registered engine events return while disabled. XP/exhaustion, faction/chat, world/zone, scenario/group, and combat events are not unrestricted bypasses. However, event work scheduled while enabled can outlive disablement.
- **Pending reputation callback:** [engine:799–809](../xpbar_engine.lua#L799) creates `Session.repTimer`; its callback clears temporary reputation display and calls `RefreshBars()` (162–168: wake → update → sleep), without rechecking master. The checkbox's disabled branch hides XP/Delves/favorites but does not cancel this timer.
- **Pending Delves checks:** [delves:345–357](../xpbar_delves.lua#L345) creates a one-second ticker which updates at detection or after ten checks; no master guard is present in its callback. It is started from enabled zone/world handling when the immediate Delves update did not show the frame ([engine:751–765](../xpbar_engine.lua#L751)). Disabled state does not cancel that pending ticker.
- **Configuration callers:** The master-off branch only hides frames. Settings remain accessible. XP colors/templates/dimensions/font/global-reset callbacks call `UpdateBar()` without a master check: [XP page:552–609](../Config2/OUS2Page_XPBar.lua#L552), 742–789, 834–835, 905–906, 1381, and 1431–1432. Delves template/dimension/color/reset/position actions call one or both renderers: [Delves page:155–244](../Config2/OUS2Page_Delves.lua#L155). These calls can re-show the relevant frame while master remains false; page refresh alone is not assumed to render a bar.
- **Preview/locking callers:** [delves:169–211](../xpbar_delves.lua#L169) refuses a new positioning unlock if master is off, and refuses the normal lock/unlock operation in combat. But the renderer trusts retained `Session.isDelveBarUnlocked`; master disable does not clear it. Locking calls the renderer too. Delves page hide locks preview ([page:552–558](../Config2/OUS2Page_Delves.lua#L552)); the independent combat listener locks via its existing bypass then renders. In a real Delve, that render can show the parent despite disabled master. Outside a Delve, locking clears preview and hides it.
- **Other caller:** A favorite-row watched-faction action calls `UpdateBar()` after clearing temporary rep mode ([xpbar_favorites.lua:496–505](../xpbar_favorites.lua#L496)); it is another reason to guard the renderer itself. The master-off UI already hides the hover panel. This is not a claim that an inaccessible hidden row can receive a normal click.

**Root cause:** Master enforcement is split between the ordinary event dispatcher and one-time hides rather than enforced at the shared rendering boundaries. This affects the entire XP Bar module's two gameplay frames, not just an independently disabled sub-bar. Data-dependent `Hide()` calls still work, so reappearance depends on which branch is rendered and, for Delves, location/preview state.

**Evidence categories:** The original 005 finding records a prior standalone/mock call with `modules.xpBar=false` showing both XP and Delves frames. That is historical control-flow evidence, not native WoW proof or an exhaustive XP/rep/location matrix. The paths above are verified current source behavior; actual visible reappearance after a particular live event, timer, settings action, or reload remains untested for this finding.

### 3. Intentional exceptions, reset, combat, and regression boundaries

Reputation display at max-level/XP-disabled conditions, temporary reputation auto-switching, hiding when faction data is unavailable, and Delves visibility while physically inside after completion are existing selection policies. Delves preview intentionally shows sample progress outside a real Delve while unlocked, and a new unlock already requires master enabled. None is an explicit master-disable exception. Preserve the Delve detection/fallback/exclusion logic ([delves:133–166](../xpbar_delves.lua#L133)), max-level/rep fallback selection, and separate finding 006's unresolved journey-max issue.

Fading ([engine:114–159](../xpbar_engine.lua#L114)) changes both frames' alpha and never calls `Show()`. A sleep/fade callback can alter alpha after disablement but cannot alone undo a `Hide()`; it can make a subsequently shown bar noticeable or invisible. Preserve current wake/combat/hover/auto-hide semantics when enabled. Favorites' popup/row visibility and reward toasts are distinct UI paths, not additional XP/Delves progress bars.

The frames inspected are OUS-created `Frame`/`StatusBar` objects under `UIParent` with `BackdropTemplate` on their parent frames, not secure action buttons. These renderers contain no combat-deferred visibility mechanism. Existing Delves positioning has explicit combat checks and combat-entry movement termination; do not replace them with blanket restrictions on normal enabled rendering. Source creation does not prove every native operation or third-party interaction is taint-free. This finding is established by OUS control flow and does not require a new Blizzard API or UI-template behavior assumption; no additional Blizzard Lua/XML walk was needed for the conclusion.

Local XP/rep/Delves settings resets preserve the master Boolean but call render/update paths, so can re-show disabled frames. The full [Core reset](../Core.lua#L150), lines 150–165, 193–198 and 258, deliberately sets module defaults (including XP Bar true), replaces XP settings and reloads; bars returning after that explicit full reset are not evidence of ignoring a still-false flag. `hideBlizz` and [ApplyBlizzardKiller](../xpbar_engine.lua#L268), lines 268–276, affect the default Blizzard manager separately, including its event registration; restoration of Blizzard default bars is not the minimal 005 correction and should not be silently added to it.

### 4. Minimal recommendation and risks

**Recommended next decision:** Authorize a separate minimal renderer/lifecycle patch after the focused baseline tests below, or retain 005 as researched while collecting that native reproduction. No correction is implemented here.

The smallest source correction is a master-disabled **hide-and-return** at both public boundaries: `OUS.UpdateBar()` must keep XP and Delves hidden and `OUS.UpdateDelveBar()` must keep Delves hidden even when called directly. Preserve existing enabled branches and settings; no new per-bar enable keys, defaults, migration, selection rules, or positioning changes are justified. A guard only in the event handler or only in `UpdateBar()` would leave documented direct paths open.

Use the existing master-disable callback to cancel/clear pending reputation and aggressive Delves presentation work and clear temporary forced-display/preview state coherently. Coordinate preview/movement cleanup with the existing combat-aware lock path; do not add unsafe movement calls merely to hide a frame. Sleep/fade cancellation may tidy pending presentation, but those timers are not the source of `Show()` and do not need a rewritten fade algorithm. Renderer guards remain essential even if timers are cancelled, because settings/direct callers can still render. Preserve persistent faction fallback, favorites, settings-edit access, auto-switch timing, anchors, dimensions, appearance, and enabled-state fade behavior.

Main regression risks are leaving forced reputation or unlocked-preview state stuck after cancelling its timer, breaking max-level reputation/faction fallback, suppressing Delves after completion or re-enable, moving/saving a frame during combat cleanup, or changing current alpha/wake behavior. Keep 006's journey calculation and OUS2 combat-close/reopen work separate.

### 5. Focused WoW test plan and verdict

1. **Baseline/reload:** With master enabled, record XP at a leveling character and Reputation with a valid faction in max-level/XP-disabled mode. Disable via OUS2; confirm both parent frames hide immediately. Reload with saved master false and check that it remains false; record visible frames and alpha separately. Do not use full Reset All as a substitute.
2. **Pending work:** Gain reputation to arm temporary display, disable before its return timer expires, and wait beyond the configured interval. Separately disable while a Delves entry/world check is pending and wait through its ten-check window. Record whether XP/rep or Delves returns. Compare ordinary events delivered only after disablement, which the dispatcher should already ignore.
3. **Settings while disabled:** Change an XP/rep color/template/dimension or the font/short-number setting. In a real Delve, change a Delves template/dimension/color. Test a local defaults/position reset only after recording values for restoration. Check both frames without attributing configuration-panel visibility to gameplay-bar visibility.
4. **Delves matrix:** With master on, confirm outside/inside, completion-before-exit, exit, and positioning preview/lock behavior. Disable while inside and while preview is unlocked; change pages and enter/leave combat, recording any reappearance. A new unlock with master off should already be refused. Companion and Journey should hide/show together as children of their shared parent.
5. **Enabled regression/acceptance:** Re-enable and confirm normal XP → temporary reputation → XP switching, max-level reputation and watched-faction fallback, Delves entry/completion/exit, saved anchors/scales/colors, hover/combat waking and auto-hide fading. Repeat disabled-state checks in combat for errors; do not infer taint safety from offline inspection. No independent per-bar disable test exists until such controls are explicitly designed.

**Research verdict:** Verified missing master checks at both public renderers, an initialization hide-then-render path, and pending/configuration bypasses support OUS-AUDIT-005. Ordinary engine events already have a guard; fading alone is not the re-show cause. Historical mock reproduction supports the source finding, while actual WoW reappearance and native combat/taint outcomes await focused tests. Status is **RESEARCHED — Decision pending.** Findings 001/002 remain runtime tested and monitoring; 003 and 004 are resolved with their bounded evidence; 006–012 remain OPEN.

<a id="implementation-005"></a>

### 6. Implementation addendum — XP/Delves renderer visibility guards

**Date:** October 25, 2026. **Status: IMPLEMENTED — Runtime verification pending.** This later authorized patch supersedes the research-only disposition without changing the original finding, historical mock result, or Investigation 005. Native WoW runtime verification remains pending.

**Exact correction:** `OUS.UpdateBar()` now checks DB/master availability before rendering; with the XP Bar master disabled or unavailable it hides the shared XP/Rep frame and Delves frame and returns. `OUS.UpdateDelveBar()` independently checks the same master, hides the Delves frame if present, and returns before detection or preview rendering. The existing settings-existence checks remain, and all enabled rendering branches are unchanged. Each boundary has a short purpose comment; both Lua source-header dates are updated to `2026.10.25`.

**Presentation lifecycle decision:** No additional cancellation infrastructure or state cleanup is necessary to prevent reappearance through these boundaries. Initialization's final update, pending reputation/Delves callbacks, direct settings refreshes, and retained unlocked preview state now encounter the guards. Pending timers may complete normally; the reputation callback can still clear its temporary display state. Retained preview state cannot produce a visible disabled bar, and a new unlock remains blocked by the existing master check. No new position save, movement operation, preview reset, forced-reputation reset, timer, or persistent state was added. Existing combat locking/page-hide behavior remains intact. This deliberately narrows the earlier broader cleanup recommendation to the demonstrated visibility defect.

**Boundaries preserved:** XP/reputation calculations and temporary reputation switching; companion selection; Delves instance/map detection, fallback/exclusion tables and journey calculation; dimensions, anchors, fonts, colors, templates, fade timing/alpha logic, and preferences. Existing OUS2 controls are unchanged. The new unchecked `OUS-DELVES-IDS-001` TODO describes only a future label below the bars; no label, ID display, API call, or detection change is implemented here. Existing Utilities/Openables TODO entries remain preserved.

**Codex offline validation:** Lua 5.1 syntax checks passed for both changed Lua files, exit 0. Targeted LuaCheck measured **88 warnings / zero errors** both before and after: engine 71, Delves 17, with no warning increase. **15/15 deterministic checks passed** under Lua 5.1 using the actual core, modified engine, and modified Delves modules with mocked native frames, data, events, and timers. The harness ran through standard input, without adding a repository test file.

The checks covered actual disabled `ADDON_LOADED` initialization; disabled direct calls to each boundary before data/detection reads; missing master metadata; pending reputation and Delves callbacks after disablement; retained preview invisibility without position changes and rejection of a new disabled unlock; settings-style direct refresh; re-enabled XP, max-level reputation, and Delves rendering; enabled reputation switching and its return timer; existing fade delay/tick/alpha targets; combat locking of an old preview while disabled; and normal enabled preview/lock/Delves exit behavior. These are mocked control-flow results, not native WoW verification. The final scoped diff, preserved enabled renderer bodies, four-file change boundary, all 12 original findings/statuses, and `git diff --check` are checked separately; full-file whitespace is also checked for this untracked audit.

**Remaining risks and WoW acceptance:** Verify disable/reload with master still false; disable before the temporary reputation return timer and during Delves entry checks, then wait through their intervals. While disabled, change relevant XP/rep settings and Delves settings inside a real Delve, and confirm neither parent frame returns. Test an unlocked preview, page changes, and combat entry/exit without position loss or protected-action errors. Re-enable on a leveling character, at max level with a valid faction, and inside a Delve; confirm normal reputation switching/fallback, completion-before-exit behavior, preview locking, hover/combat waking and auto-hide fading. Pending callbacks remain scheduled by design, so rapid off/on restores existing enabled-state behavior rather than defining a new cancellation policy. Native frame visibility, event order, protected-frame/taint interactions, and every location/preview timing remain client acceptance questions. No native runtime pass is claimed.

Findings 001/002 remain runtime tested and monitoring, 003/004 remain resolved, and 006–012 remain OPEN. No staging, commit, or push is part of this task.

<a id="runtime-verification-005"></a>

### 7. Runtime-verification addendum — OUS-AUDIT-005

**Recorded:** October 25, 2026. **Status: IMPLEMENTED — RUNTIME TESTED — RESOLVED.** The user reported testing the XP Bar correction in WoW and that everything worked correctly; no disabled-bar reappearance or regression was reported. This is a general runtime confirmation, not a separately documented pass for every scenario in the previous procedure. The applicable procedure covered disabled initialization/reload, pending reputation/Delves updates, settings refreshes, positioning preview/page/combat transitions, and re-enabled XP/rep/Delves switching and fading. Individual coverage of those scenarios is not independently established by the general confirmation.

**Previously reported Codex offline evidence:** Lua 5.1 syntax passed; targeted LuaCheck reported **88 warnings / zero errors**, unchanged from baseline; **15/15 deterministic checks passed**; and `git diff --check` passed. Those results remain separate from the user's WoW observation and were not rerun in this documentation task.

**Limits:** Resolution is bounded by the general reported success and prior source/offline evidence. It does not establish every event ordering, callback transition, combat-specific edge case, or third-party interaction. The original finding, investigation, implementation addendum, and historical results remain preserved; this later addendum supersedes only the runtime-pending disposition.

<a id="focused-investigation-006"></a>

## Focused Investigation 006 — Delves Journey Zero-Progress/MAX Handling

**Research date:** October 25, 2026. **Status: RESEARCHED — Decision pending.** This is a source-supported possible edge case, **not a confirmed live bug**: the user has not observed an incorrect MAX display during normal Delves gameplay. No production change or new native/standalone runtime test was performed. OUS references below describe the working checkout with the recent 005 guards; the original finding's older line references and mock evidence remain historical.

### 1. Progression and formatting flow

[xpbar_delves.lua:250–260](../xpbar_delves.lua#L250) now rejects disabled master state before detection/rendering. For an enabled module inside a detected Delve or unlocked preview, lines [290–318](../xpbar_delves.lua#L290) initialize Journey values to `jRep=0`, `jMax=1`, `jLvl="?"`, `jNextLvl="?"`; resolve the seasonal faction with `C_DelvesUI.GetDelvesFactionForSeason()`; then request `C_MajorFactions.GetMajorFactionRenownInfo(journeyFactionID)`.

When a renown record exists, level/progress/threshold come from `renownLevel`, `renownReputationEarned`, and `renownLevelThreshold`. The display level defaults to `"?"`; local predicate operands each default to zero. The **exact MAX predicate** at lines 300–305 is:

```lua
(level > 0) and (earned == 0) and (threshold > 0)
```

If true, the code fills the bar (`jRep=jMax=threshold`) and sets `jNextLvl="Max"`. Otherwise it uses earned progress, a positive threshold or denominator 1, and `level+1`. This next-level value is arithmetic, not a query of the highest available level. The Journey path does **not** call `HasMaximumRenown`, enumerate renown levels, or otherwise obtain an authoritative maximum state. Its nearby comment claiming a particular at-max tuple is an implementation assumption; the generated contract below does not establish that tuple as an exclusive maximum sentinel.

Preview at [lines 320–325](../xpbar_delves.lua#L320) overrides Journey with sample level 4 → 5 and 1200/5000, so the calculated MAX branch is not displayed in unlocked preview outside a real Delve. At [lines 334–340](../xpbar_delves.lua#L334), the `"Max"` marker produces hardcoded `Journey: (Lvl: <level>) :: MAX`, bypassing the saved Journey template. The normal branch calls `OUS.ParseRepText(..., false, jLvl, jNextLvl)`. [xpbar_engine.lua:242–265](../xpbar_engine.lua#L242) performs template substitutions; its own Max/Max Level substitutions require `isMaxed=true`, which this normal Journey call explicitly does not pass. A user could put literal MAX text in a custom template, but that is separate from this automatic branch.

### 2. Zero, unavailable, and actual maximum states

| Input / condition | Current source result | Evidence qualification |
|---|---|---|
| Record has positive level, exactly zero earned, positive threshold | Full bar and automatic MAX, regardless of actual cap | Verified branch ambiguity; no authoritative max query participates. |
| Record has positive earned progress | Normal template and `level+1` | Does not alone establish whether progression is capped. |
| Renown API returns no record, faction resolution fails, or required API is absent | Initial 0/1 and unknown level/next-level placeholders; no automatic MAX | Whole-result absence is guarded, but no explicit unavailable-data label/state exists. |
| Hypothetical partial record: earned missing while level/threshold are positive | `or 0` converts missing earned to zero, producing MAX | Defensive-code implication only: returned-record fields are documented non-nil; native partial records were not observed. |
| Missing/nonpositive level or missing/nonpositive threshold | Predicate false; fallback numeric/unknown output, not MAX | An entirely missing record is not the same as a missing single field. |
| Actual maximum state | MAX only if the same numeric predicate happens to match | Not verified from an authoritative maximum flag. Other tuples would miss MAX; native maximum tuple/timing is untested here. |

**Interpretation:** Zero progress can represent the start of a non-maxed level; Blizzard's rendering accepts zero as progress and uses a separate maximum predicate. The contracts do not reserve zero for maximum progression. The source-supported inference is that the OUS tuple cannot uniquely distinguish those states; this review does not assert that a particular zero-progress tuple has been observed for the user's seasonal Journey. Whole-result nil is kept out of MAX, while fallback zeros blur missing individual fields with real zero values. Actual maximum is not separately distinguished at all in this Journey branch.

### 3. Verified Retail source contracts and implementation context

The local Blizzard mirror was rechecked as branch `live`, commit `15881d522c44cd106d3d8660106ec9f9d2f44167`, description **12.1.5 (70575)**. This is a source baseline, not a newly queried installed-client build.

- [DelvesUIDocumentation.lua:165–172](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/DelvesUIDocumentation.lua#L165): `GetDelvesFactionForSeason()` takes no arguments and returns a non-nil numeric faction ID. The OUS truthiness guard is defensive; the contract does not document a nil return here or guarantee that every numeric ID immediately has usable renown data.
- [MajorFactionsDocumentation.lua:56–69](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua#L56): `GetMajorFactionRenownInfo(majorFactionID)` accepts a non-nil number and returns **nullable** `MajorFactionRenownInfo`. [Lines 255–262](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua#L255) define level, earned reputation, and threshold as non-nil numbers when the structure is returned; it has no maximum Boolean. No exclusive zero/MAX rule or readiness/event-order guarantee is documented.
- [MajorFactionsDocumentation.lua:111–124](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua#L111): `HasMaximumRenown(majorFactionID)` accepts that numeric faction ID and returns a non-nil Boolean. The generated metadata permits secret arguments only under its stated `AllowedWhenUntainted` condition; that is not permission to invent guarantees for restricted contexts.
- [ReputationFrame.lua:527–545](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ReputationFrame.lua#L527) uses `HasMaximumRenown` to choose a full bar; otherwise it uses the supplied earned/threshold values, with a separate absent-data fallback. The conditional Lua/XML walk connected the major-faction initializer through lines 550–563 to `ReputationEntryMixin` and its [XML entry/bar templates](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ReputationFrame.xml#L130) (bar template at line 77, child at 135). XML provides the display objects, not an alternative zero/MAX rule.
- [Blizzard_Journeys.lua:964–971](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_EncounterJournal/Mainline/Blizzard_Journeys.lua#L964) likewise fills the Journey progress bar only according to `HasMaximumRenown`, otherwise using earned progress, and skips absent/zero-denominator data. In Lua, numeric zero remains truthy, so zero earned is accepted rather than rejected by that check. Its associated [Blizzard_Journeys.xml:636](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_EncounterJournal/Mainline/Blizzard_Journeys.xml#L636) binds the overview progress control to `JourneysProgressBarMixin`. The local comment “Show a full bar if we have max renown” at Lua:965 describes intent, not an independent native-data guarantee.

OUS already uses the same maximum predicate in its general [faction helper](../xpbar_engine.lua#L281), at engine:293 and 333. That is a useful existing pattern; it does not mean the separate Delves Journey branch already benefits from it. Companion max handling uses friendship rank/current-versus-max data and remains a separate path; no companion change is proposed.

### 4. Historical mock evidence and minimal recommendation

The original finding records a standalone input described as uncapped level 4, 0/5000, for which the renderer displayed MAX. This demonstrates the genuine Lua control-flow ambiguity: the tuple is sufficient to trigger the branch without checking whether the faction is capped. It does not establish a native seasonal faction returning that tuple, API availability/event timing, the frequency of the edge case, or a user-observed incorrect display. No new mock run is needed to reinterpret that historical result, and no live reproduction is claimed.

**Recommended next decision:** Retain 006 as researched while collecting a focused native observation, or authorize a narrowly scoped correction based on the verified ambiguity. The user has no reported normal-play failure, so no urgent workaround or broad progression rewrite is justified.

If authorized later, replace the tuple-as-maximum heuristic with the existing verified `C_MajorFactions.HasMaximumRenown(journeyFactionID)` predicate, preserving the current full-bar/MAX presentation only for a positively established maximum. A valid non-max record with zero earned should remain zero progress through the existing template. Keep unavailable renown data on a conservative non-MAX placeholder path rather than assigning maximum or pretending a real threshold; do not infer readiness from missing values. Confirm native cap/threshold behavior before adjusting the denominator policy, and do not add polling or hardcoded level caps. Preserve normal Journey templates, companion progression/selection, detection and exclusion tables, appearance/positioning, and both 005 visibility guards. No fix is implemented here.

### 5. Focused WoW test plan and verdict

1. **Non-max zero:** At a naturally reached new non-max Journey level, compare the native Journey UI and OUS immediately after progression and once values settle. Record seasonal faction ID, level, earned, threshold, and `HasMaximumRenown` together using read-only inspection. Zero alone is not sufficient evidence of cap state; do not alter reputation/SavedVariables to manufacture it.
2. **Positive progress:** Observe a non-max level with positive earned progress; compare OUS template text and fill with native progression before/after a gain and level transition.
3. **Actual maximum:** On a character with confirmed seasonal maximum, compare the native cap state and predicate with OUS MAX/full-bar output; record the actual numeric tuple rather than assuming the comment's tuple is universal. If no such character is available, leave this case unverified.
4. **Unavailable/loading:** Observe real login/reload/zoning/season-data loading if renown info is naturally nil, and record the same snapshot after it becomes available. Distinguish unknown placeholders from actual 0/threshold; if unavailable data is never observed, retain it as an unverified case. Partial-field nil cases require separate offline simulation if a patch is later authorized, not claims of native behavior.
5. **Boundaries:** Unlocked preview should still show its sample data without MAX. Master-disabled bars must stay hidden. Compare real Delves entry/completion/exit, existing Journey template behavior, and companion display without changing detection IDs or layout.

**Research verdict:** The current MAX predicate is not an authoritative cap test and conflates valid zero progress with maximum when its tuple matches. Entirely missing API results do not currently produce MAX; missing individual earned data could do so only in a hypothetical partial record contrary to the documented non-nil field contract. Verified Blizzard/OUS comparison patterns support a small predicate correction, but no incorrect MAX has been reported in normal gameplay and native zero/cap/loading cases remain unverified. OUS-AUDIT-006 is **RESEARCHED — Decision pending**. Findings 001/002 remain monitoring, 003/004/005 resolved, and 007–012 OPEN.

<a id="implementation-006"></a>

### 6. Implementation addendum — authoritative Journey maximum state

**Date:** October 25, 2026. **Status: IMPLEMENTED — Runtime verification pending.** This authorized patch changes only the Journey maximum predicate and its explanatory comment in `xpbar_delves.lua`, plus this audit status/addendum. The source-header date was already `2026.10.25` from 005 and remains unchanged. The original finding, research, and historical mock evidence remain preserved.

**Exact correction / verified source fact:** After obtaining the seasonal faction ID and a non-nil renown-info record, Journey now establishes maximum with `C_MajorFactions.HasMaximumRenown and C_MajorFactions.HasMaximumRenown(journeyFactionID) == true`. It no longer derives maximum from positive level, zero earned, and positive threshold. Only a true API result establishes MAX; missing predicate or an unexpected nil result cannot do so. Missing faction/renown data still follows the existing unknown/0-of-1 fallback without calling the predicate. Non-max zero progress retains normal template formatting; confirmed maximum retains the existing MAX text and bar-value assignments. No denominator, template, companion, or selection logic was refactored.

**Verified API basis:** The same local LIVE source commit `15881d522c44cd106d3d8660106ec9f9d2f44167` identifies `12.1.5 (70575)`. The generated [HasMaximumRenown contract](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua#L111) takes a numeric faction ID and returns a non-nil Boolean. Nullable renown-info and returned-field contracts, and Blizzard's own maximum-predicate usage, remain documented in Investigation 006. Nil predicate results and missing fields in the deterministic cases are defensive simulations, not newly established native API behavior.

**Historical compatibility:** Reviewed `cdc6e832` (April 7, post-boss visibility), `0a464f20` (April 20, preserve watched/fallback faction when a temporary Journey lookup fails), and `bac7d263` (April 27, dynamic Journey cache and `C_MajorFactions` fallback). The current detection/post-boss fallback in Delves is unchanged; `xpbar_engine.lua` is untouched, preserving the latter two fixes and its current XP/rep switching/fading. Companion progression/selection, instance/map ID and exclusion tables, preview sample overrides, appearance/positioning, SavedVariables/defaults, and the recent 005 renderer guard are unchanged. Existing unrelated uncommitted edits and TODO entries remain intact.

**Codex offline validation:** Lua 5.1 parsing of `xpbar_delves.lua` passed, exit 0. Targeted LuaCheck reported **19 warnings / zero errors**, compared with **17 warnings / zero errors** immediately before the patch. The two added warnings are undefined-global reports for the two new references to the already-used, verified `C_MajorFactions` namespace; the lint configuration was not changed or suppressed. **15/15 deterministic checks passed** using the actual core/engine/modified Delves modules with mocked native APIs under Lua 5.1. The harness ran through standard input and added no repository test file.

Checks covered non-max zero and positive earned progress; confirmed maximum with zero and positive earned; nil renown info; unavailable seasonal faction; missing maximum API and nil maximum result; zero, negative, and missing thresholds below maximum; confirmed maximum with zero threshold; normal companion progress; disabled master returning before the predicate; preview sample override; and post-boss scenario fallback visibility. The MAX branch still assigns the raw threshold to both value and range: the zero-threshold test verifies that unchanged assignment (`0/0`) and MAX text in mocks, not native status-bar appearance. Non-max nonpositive thresholds retain the existing denominator-1 fallback. No broader threshold policy was introduced. Final validation reviews the exact task delta, all 12 findings/statuses, preservation of unrelated files, `git diff --check`, and full-file whitespace for the untracked audit.

**WoW runtime not yet verified / acceptance:** The user had not observed incorrect MAX in normal gameplay; this is an authoritative-predicate correction backed by source and deterministic checks, not a newly reproduced live failure. Compare OUS against native Journey progression at a non-max zero-progress boundary, with positive progress, and at confirmed maximum. Record seasonal faction ID, level, earned, threshold, and maximum Boolean together. Verify natural login/reload/zoning data unavailability remains non-MAX and recovers when data arrives; leave unavailable scenarios unverified if they do not occur. At confirmed maximum, check actual threshold and bar appearance, especially if the threshold is nonpositive; native unusual-threshold behavior remains unestablished. Confirm companion rendering, post-boss display until Delve exit, ordinary XP/rep/Journeys switching and fading, preview sample text, and master-disabled invisibility. Native event timing, combat/taint context, seasonal cap values, and all API-readiness transitions remain runtime limits.

Findings 001/002 remain monitoring, 003/004/005 remain resolved, and 007–012 remain OPEN. No staging, commit, or push is included.

<a id="runtime-verification-006"></a>

### 7. Runtime-verification addendum — OUS-AUDIT-006

**Recorded:** October 25, 2026. **Status: IMPLEMENTED — PARTIALLY RUNTIME VERIFIED.** The original finding, Investigation 006, implementation addendum, and offline test evidence remain preserved. The following user-reported WoW observations qualify the earlier runtime-pending status; they do not close all maximum-state edge cases.

**Initial native comparison:** For **Delves: Season 2**, OUS and Blizzard's Journeys interface matched at Journey level **6**, next level **7**, progress **446 / 4,200**. Valeera companion progression displayed normally.

**Subsequent run:** In **The Labyrinth of Kindo'jan**, the user completed all **nine chambers**. OUS displayed Valeera and Journey progression normally, the bars remained visible after completion, and they disappeared correctly after leaving. No display regression was reported. These are user-reported native observations, separate from the earlier Codex deterministic/static validation.

**Unverified cases:** Valid non-max progression with exactly zero earned, confirmed maximum-renown display, and unavailable API data were **not tested/reproduced**. The run establishes ordinary progression and the observed post-completion/exit lifecycle, not exhaustive combat, event-order, loading, or seasonal-cap behavior. Finding 006 remains partially runtime verified, not resolved.

<a id="focused-investigation-007"></a>

## Focused Investigation 007 — Stats Bar Restriction Handling

**Research date:** October 25, 2026. **Status: RESEARCHED — Decision pending.** Read-only inspection of `StatsBar.lua`, directly relevant OUS2 controls/Core settings, and generated Retail restriction/secrecy contracts. No production change, new standalone reproduction, or native Stats Bar restriction test was performed. OUS line references identify the current inspected checkout.

### 1. Current restriction-state lifecycle

[StatsBar.lua:16–27](../StatsBar.lua#L16) initializes one transient `isRestricted=false` Boolean and string cache. [RefreshCache():110–193](../StatsBar.lua#L110) returns immediately while that Boolean is true. Otherwise it reads item level, then attempts stat reads, arithmetic, formatting and spec-priority string construction inside an existing `pcall`; a failed protected block replaces its cached stat strings with dashes. It then updates both display modes. The item-level read/format precedes that `pcall`. The comment claiming all listed contexts are covered is not an authoritative API contract.

[Events:495–548](../StatsBar.lua#L495) register world entry, stat/rating/mastery/avoidance/leech/speed/item-level/equipment changes, combat entry/exit, restriction changes, and talent/trait updates. Their behavior is:

| Trigger | State / refresh action | Source-supported consequence |
|---|---|---|
| `PLAYER_ENTERING_WORLD` | Positions/locks frames, then calls `RefreshCache()` | No initial restriction-state query; reads depend on the existing Boolean/event history. |
| `PLAYER_REGEN_DISABLED` | Sets `isRestricted=true` | Stops subsequent cache refreshes; does not hide frames or clear their cached strings. |
| `PLAYER_REGEN_ENABLED` | Unconditionally sets `isRestricted=false`; schedules refresh after 0.1 seconds | Can clear the local gate while another restriction is still active. Callback only rechecks the same Boolean. |
| `ADDON_RESTRICTION_STATE_CHANGED` | Correctly receives type as first payload argument and state as second, but handles only numeric type 2; stores `state ~= 0` | Correct argument extraction, incorrect type generalization. Activating/Active both block for ChallengeMode; Inactive clears the shared Boolean regardless of combat/other restrictions. |
| Equipment / talent / trait updates | Deferred refresh after 0.2 / 0.1 seconds | Deferred work calls `RefreshCache()` and can read after an incorrect Boolean clear. |
| Other registered stat events | Immediate refresh when no unit argument or unit is `player` | Uses the same gate; does not independently query whether stats are secret. |

The event branch at lines 529–538 treats type 2 as general stat restrictions for M+, encounters and PvP. Actual Encounter/PvPMatch/Map/Chat notifications are ignored. The shared Boolean conflates combat with one restriction category; no `C_RestrictedActions` state snapshot or `C_Secrets.ShouldUnitStatsBeSecret()` query exists in the current file. A ChallengeMode Inactive notification can also clear the Boolean during combat, the reverse ordering of the combat-end concern. Either ordering is a verified possible assignment sequence, not proof that it occurred in the user's client.

### 2. Verified Retail API semantics

The local source HEAD was rechecked as LIVE commit `15881d522c44cd106d3d8660106ec9f9d2f44167`, description **12.1.5 (70575)**. This identifies inspected source, not a newly measured installed-client build. [RestrictedActionsConstantsDocumentation.lua:6–32](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsConstantsDocumentation.lua#L6) defines:

| `Enum.AddOnRestrictionType` | Meaning |
|---|---|
| Combat = 0 | Player actively affecting combat. |
| Encounter = 1 | Player actively participating in an instance encounter. |
| ChallengeMode = 2 | Active, incomplete challenge mode / mythic keystone dungeon. |
| PvPMatch = 3 | Active, incomplete PvP match. |
| Map = 4 | Map applies addon restrictions. |
| Chat = 5 | Addon chat communications are restricted. |

These describe restriction categories, not six equivalent stat-secrecy flags. In particular, Chat restriction alone does not establish that unit stats are secret. `Enum.AddOnRestrictionState` is **Inactive=0**, **Activating=1**, **Active=2**. Activating is the event-dispatch phase before enforcement begins; it is appropriate to stop new sensitive reads conservatively during that transition.

[RestrictedActionsDocumentation.lua:97–106](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L97) documents synchronous `ADDON_RESTRICTION_STATE_CHANGED(type, state)`, fired before activation or after deactivation. [Lines 29–43](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L29) define `C_RestrictedActions.GetAddOnRestrictionState(type)` returning the current enum state. [Lines 55–69](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L55) explicitly say `IsAddOnRestrictionActive(type)` always returns false during this event's dispatch. Therefore it is unsuitable as the sole inline activation guard. A fixed 0.1-second delay is a scheduling choice, not a guarantee that every restriction has ended.

[SecretPredicateAPIDocumentation.lua:388–395](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua#L388) defines **`C_Secrets.ShouldUnitStatsBeSecret()` with no arguments**, returning a non-nil Boolean indicating whether unit-stat queries produce secret values. It is the direct stat-read policy signal; restriction category 2 is not a substitute. [RestrictedActionsDocumentation.lua:44–53](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L44) also retains global `InCombatLockdown()` with no arguments and a Boolean result. The existing policy of not refreshing during combat can be preserved independently of stat secrecy. No Blizzard Lua/XML template behavior is needed to establish this local state-machine defect; the generated contracts establish the relevant semantics without a frame-template investigation.

### 3. Impact, display modes, and safety limits

**Verified source:** The local state can become unrestricted while a different restriction persists. Conversely, a remembered ChallengeMode-active state can suppress reads independently of whether the current stats are actually secret. During true restriction gating the last cached strings remain visible, rather than the frames automatically disappearing. If an allowed-by-local-Boolean refresh encounters an operation that raises inside the existing protected block, the cache becomes dashes; that fallback does not repair the gate or establish that every attempted read is permitted.

No incorrect stat formula was identified here. The concern is **when reads/calculations execute**, plus stale/dash display and recovery; not a demonstrated arithmetic regression or uncaught crash. Current native restriction overlaps, exact event order, secret-value behavior in the catch block, and recovery after context changes have not been tested. A missed/ignored deactivation can delay cache recovery until some other refresh event arrives.

Display gates remain separate: [UpdateDisplay():453–470](../StatsBar.lua#L453) requires account-wide `modules.statsBar`, per-character `statsBar.enabled`, and table mode off; [UpdateTable():306–315](../StatsBar.lua#L306) requires the same master and per-character `tableEnabled`. Table mode does not additionally require the single-line `enabled` flag. Restriction state does not override these visibility checks. Cache/event work itself is not master-gated, so it can still be attempted while presentation is disabled; do not silently change that separate behavior in a restriction fix. [OUS2 Stats Bar page](../Config2/OUS2Page_StatsBar.lua#L354), lines 354–365, refreshes both displays on master change; its reset at 93–132 and [Core settings initialization](../Core.lua#L37), lines 37–58, establish the existing account/character ownership. Configuration renderers use the string cache rather than directly invoking `RefreshCache()`.

### 4. Smallest correction recommendation and regression risks

**Recommended decision:** Authorize a focused cache-permission/lifecycle correction after gathering the baseline runtime observations below. Replace numeric-type-as-global-permission with a fresh check at the actual cache-read boundary: preserve the existing no-refresh-during-combat policy and independently consult the verified no-argument stat-secrecy predicate. Do not unconditionally equate combat end or one category's deactivation with global permission.

Treat restriction notifications as transition/invalidation signals and request a deferred permission recheck, retaining conservative Activating handling. Do not simply OR every category into one universal stat flag, and do not use `IsAddOnRestrictionActive` alone during event dispatch. Reuse the existing deferred refresh flow rather than polling, persistent restriction state, or a broad event-framework rewrite. Preserve the existing cache/dash fallback; do not add new broad `pcall` wrappers or claim that `pcall` sanitizes secret values. An unavailable required predicate must not become permission by assumption; select a conservative fallback explicitly if implementation is authorized.

Preserve mode gates, account/character settings, formulas/formatters, priority ordering, position/scale/locking, and SavedVariables schema. Regression risks include suppressing recovery after the last restriction ends, reading during Activating before permission is safely established, conflating Chat with stat secrecy, discarding the intended combat cache, changing table-versus-single-line semantics, and losing safe stale/dash behavior. This research does not authorize altering those display policies or protected Blizzard frames.

### 5. Focused WoW test procedure and verdict

1. Establish enabled single-line and table-mode baselines outside combat; record stats and cached display through combat entry/exit. Confirm master/per-character mode toggles still hide/show their intended frames without changing preferences.
2. In a Mythic Keystone run, inspect combat exit **between pulls while ChallengeMode remains active**. Record combat status, restriction type/state notifications, `GetAddOnRestrictionState` results after dispatch, and `ShouldUnitStatsBeSecret()` alongside visible cache/dashes and errors. Do not infer permission solely from combat ending.
3. Repeat overlapping Encounter, PvPMatch and applicable restricted-Map transitions where available, including context end while still in combat and reload/world entry into an already restricted context. Observe Chat separately; do not infer that Chat alone must blank the stats.
4. Trigger normal equipment/talent/stat updates where permitted and observe delayed refresh/recovery after the final restriction ends. Distinguish displayed cached strings from proof that a fresh read occurred. If event sequences or contexts cannot be observed, leave them unverified; do not manufacture a native result from source reasoning.
5. Before any future patch, use deterministic transition tests for activation, overlapping restrictions, both combat/deactivation orderings, pending callbacks and unavailable predicate behavior; after implementation, repeat native recovery and mode tests. No new instrumentation or production test change is implemented in this task.

**Research verdict:** Type 2 is ChallengeMode, not a generic stats restriction. Unconditional combat-end clearing and independent ChallengeMode state assignment cannot represent overlapping/current read permission reliably. The contract-backed stat-secrecy predicate plus an independent combat policy supports a minimal correction, but native impact and event sequences remain unverified. OUS-AUDIT-007 is **RESEARCHED — Decision pending**. Findings 001/002 remain monitoring; 003/004/005 resolved; 006 partially runtime verified; 008–012 OPEN.

<a id="implementation-007"></a>

### 6. Implementation addendum — Stats Bar read authorization

**Date:** October 25, 2026. **Status: IMPLEMENTED — Runtime verification pending.** The authorized correction is limited to `StatsBar.lua` and this audit addendum/status. Its source-header date is updated to `2026.10.25`. The original 007 finding and investigation remain historical evidence; no native Stats Bar failure or post-patch runtime pass is claimed.

**Exact correction:** Removed the shared combat/ChallengeMode `isRestricted` Boolean. At the start of `RefreshCache()`, before item-level or stat reads, the module now returns if `InCombatLockdown()` is true or a restriction-notification refresh is pending. It also returns if `C_Secrets.ShouldUnitStatsBeSecret` is unavailable or its no-argument result is anything other than explicit false. Only out-of-combat, settled-notification, explicitly non-secret state authorizes the existing read/format path. This preserves OUS's intentional combat cache even when Blizzard would permit stat reads, while making current Blizzard stat secrecy independent of combat end and individual category deactivation.

Combat entry performs no refresh; combat end retains its existing 0.1-second refresh request, whose callback must pass the same live gate. Every `ADDON_RESTRICTION_STATE_CHANGED` notification now requests a deferred recheck, without interpreting numeric type 2 as a universal stat restriction. One transient `restrictionRefreshPending` Boolean coalesces notifications into one existing-style 0.1-second callback and blocks intervening reads, including the pre-enforcement Activating dispatch window. The callback clears the scheduling hold and checks current combat/secrecy state; it does not assume the elapsed delay means restrictions ended. Chat therefore causes a brief deferred recheck, not a persistent stat-secret flag. No category registry, polling, new SavedVariables, or elaborate state machine was added. Equipment/talent/stat callbacks continue to use `RefreshCache()` and receive the same protection.

**Fallback and compatibility:** Blocked refreshes retain existing cached strings (initially dashes), rather than reading or doing arithmetic/formatting on secret stat values. The existing protected-call block and dash-on-read/format-failure behavior are preserved; `pcall` is not treated as a secret-value sanitizer. Existing nil-to-zero behavior inside permitted stat calculations remains unchanged. Renderers still use the string cache and preserve account-wide master, per-character single-line/table gates, table-mode independence from single-line enablement, formulas, colors, formatters, positioning/locking and settings compatibility. Cache work remains possible with presentation disabled if reads are otherwise authorized, matching prior semantics. No configuration/defaults or unrelated module changes were made.

**Verified API basis:** Local LIVE source was rechecked at commit `15881d522c44cd106d3d8660106ec9f9d2f44167`, description `12.1.5 (70575)`. [C_Secrets.ShouldUnitStatsBeSecret](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua#L388) has no arguments and a non-nil Boolean result. [InCombatLockdown](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L44) is also a no-argument Boolean query. The synchronous event's [activation/deactivation ordering](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua#L97) and [Activating state](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsConstantsDocumentation.lua#L14) support deferring reads beyond dispatch. The patch does not use `IsAddOnRestrictionActive`, which is documented to return false during event dispatch. Missing/nil secrecy-query tests are conservative defensive simulations, not claims that the normal documented Boolean return is nullable.

**Codex offline validation:** Lua 5.1 syntax passed, exit 0. Targeted LuaCheck reported **37 warnings / zero errors**, versus **34 warnings / zero errors** immediately before the patch. The three added warnings are undefined-global reports for references to the verified `C_Secrets` namespace; lint configuration was not modified or warnings suppressed. **19/19 deterministic checks passed**, executing the actual modified Stats Bar module under Lua 5.1 with mocked frames, events, timers and API results. The harness ran through standard input, adding no repository test file.

Checks covered ordinary updates; combat entry/cache retention; clean combat exit; combat exit with secrecy persisting; ChallengeMode deactivation during combat; interleaved activation notification/stat event before the predicate changes; coalesced overlapping categories; secrecy-cleared recovery; Chat without stat secrecy; missing namespace/predicate and nil predicate result; ordinary Lua read failure/dash recovery and existing nil-stat numeric fallback; pending equipment and combat-end callbacks; single-line/table semantics; disabled master presentation; reload/world entry into combat/secret contexts; and permission checks before mocked forbidden reads. These tests validate Lua authorization/control flow and fallback handling. Ordinary Lua exceptions/mocks do **not** reproduce native secret-value enforcement, restricted arithmetic semantics, or taint propagation. Final validation checks the exact scoped diff, preservation of unrelated uncommitted files and all audit findings/statuses, `git diff --check`, and full-file whitespace for the existing untracked audit.

**Remaining native limits / required WoW acceptance:** Check single-line and table modes outside combat, through combat entry/exit, and after equipment/talent changes. In a Mythic Keystone run, inspect combat exit between pulls while challenge context/secrecy persists, then actual context completion and recovery. Where available, repeat overlapping Encounter/PvPMatch/Map transitions, restriction deactivation while combat continues, and reload into an existing restricted context. Compare current secrecy/combat signals after dispatch with cached/dash display and errors, without treating a visible old string as proof of a fresh read. Check mode/master toggles and unchanged position/scale/formatting. Verify recovery after the last relevant restriction clears; the existing notification/stat refresh lifecycle remains responsible for recovery, without polling. No API missing/secret-data behavior, exact event sequence, or protected-action/taint outcome has been verified in native WoW. A false stat-secrecy predicate does not prove every unrelated API or third-party interaction is safe; the existing guarded read fallback remains necessary.

Findings 001/002 remain monitoring, 003/004/005 resolved, 006 partially runtime verified, and 008–012 OPEN. No staging, commit, or push is included.

<a id="runtime-observations-007"></a>

### 7. Runtime-observation addendum — OUS-AUDIT-007

**Recorded:** October 25, 2026. **Status: IMPLEMENTED — RUNTIME TESTED — Monitoring.** The user tested the updated Stats Bar during a **Tier 11 Bountiful Delve** and completed it successfully. Before testing, the displayed values were: **Item Level 309.69; Intellect 3056; Critical Strike 26.1%; Haste 20.9%; Mastery 40.9%; Versatility 3.5%**. The user deliberately exercised the addon trying to reproduce an error and reported no Lua errors or visible Stats Bar malfunction. The user also reported unlocking two Great Vault slots; that outcome is context, not evidence that a particular restriction transition or fresh stat read was tested. No more detailed procedure is inferred.

**Earlier Codex offline evidence, preserved separately:** Lua 5.1 syntax passed; **19/19 deterministic checks passed**; targeted LuaCheck reported **37 warnings / zero errors**, including three additional `C_Secrets` declaration warnings; `git diff --check` passed. These historical tests are not rerun or promoted to native secret-value proof by this documentation update.

**Limits:** No controlled Mythic Keystone ChallengeMode overlap reproduction or exhaustive restriction-category coverage was reported. Visible cached values do not prove that fresh restricted API reads succeeded. Native secret enforcement, event ordering and taint safety are not universally established by this run. The original finding, research and implementation evidence remain preserved; 007 is monitoring, **not fully resolved**.

<a id="focused-investigation-008"></a>

## Focused Investigation 008 — Fishing Tracker Timer and Loot Attribution

**Research date:** October 25, 2026. **Status: RESEARCHED — Decision pending.** Focused read-only review of Fishing Tracker ownership/timing, item-load continuations, history writes and FasterLoot's relevant handoff. No code or SavedVariables were changed, and no new mocked/native fishing-attribution reproduction was performed. Source references identify the current checkout; historical findings remain intact.

### 1. Ownership and event flow

[Fishingtracker.lua:21–31](../Fishingtracker.lua#L21) holds `isFishingActive`, `lastCastTime`, `lastLootTime`, plus separate session-duration fields. There is **no explicit pending-catch owner, cast generation, loot-session identity, or cancellable fishing attribution timeout**. Ownership is inferred each time `LOOT_READY` arrives.

| Path | Verified state / action | Attribution implication |
|---|---|---|
| Initialization | `ADDON_LOADED` sets `lastCastTime=GetTime()` (1660). | A brief recent-fishing window can exist without a cast, even with the tracker hidden. |
| Fishing start/channel start | Player plus one of four known spell IDs; sets active and refreshes `lastCastTime`; resumes the session timer and opens the tracker (1626–1628, 1704–1740). | Actual recognized cast evidence, not proof every subsequent loot window belongs to it. |
| Fishing stop/channel stop | Recognized player spell clears active and refreshes `lastCastTime` (1742–1747). | Keeps a three-second fallback after cast end, including an interrupted/abandoned cast unless native loot evidence distinguishes it. |
| `LOOT_READY` | Drops events within one second of last accepted loot. Otherwise accepts native `IsFishingLoot()` true, **or** active fishing, **or** timestamp age at most three seconds (1749–1765). | Native positive evidence is preferred, but false/unavailable native evidence does not veto the temporal fallback. |
| Accepted loot | Updates both loot and cast timestamps before checking/enumerating slots; records items/currencies, reopens UI if needed (1763–1785). | No cast claim is consumed. Accepted unrelated or empty loot can extend the fallback window. |
| UI/session controls | Pause/stop/reset alter session timing/totals, not attribution ownership (671–717); reopening writes `lastCastTime` (1861–1883). | Pausing the duration timer does not pause recording. Opening can manufacture recent-fishing evidence. |
| Visible UI `OnUpdate` | Writes `lastCastTime` whenever countdown is off or fishing is active (1793–1856). | A presentation clock continually refreshes evidence consumed by loot classification. |

Only `LOOT_READY` is registered for loot processing ([1630–1640](../Fishingtracker.lua#L1630)). Fishing Tracker has **no `LOOT_OPENED`, `LOOT_CLOSED`, loot-chat, loot-slot-cleared, loot-item-available, or bag-event confirmation/retry path** in the inspected registration. Equipment/profession/inventory/tooltip events here update the fishing Venom display, not catch ownership. There is no claim that a particular cast GUID is matched to a loot source.

The local LIVE mirror remains commit `15881d522c44cd106d3d8660106ec9f9d2f44167`, description `12.1.5 (70575)`. Generated [LootDocumentation.lua:187–237](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua#L187) defines synchronous LOOT_CLOSED, LOOT_OPENED (autoLoot/isFromItem payload), and LOOT_READY (autoloot Boolean). It does not provide a catch-unique ownership token or an exactly-once/delivery/slot-readiness guarantee in those entries. This review does not invent a READY/OPENED ordering, cross-addon handler order, or guarantee that `IsFishingLoot()` is available/true on every native fishing path. The control-flow finding does not depend on Blizzard Lua/XML presentation behavior.

### 2. UI clocks, expiry, and concrete risk sequences

The auto-close decision at [1817–1855](../Fishingtracker.lua#L1817) counts down only while not session-paused and either inactive-auto-close is enabled or mount-auto-close applies. Otherwise, or while active fishing, it writes `lastCastTime` every visible update. The `OnUpdate` loop returns when the module is disabled or main frame hidden. Manual close ([629](../Fishingtracker.lua#L629), 1864–1868) just hides the frame; it does not clear active/recent ownership or stop the session timer. Hiding stops future UI timestamp refresh but leaves the last three-second window; accepted loot can reopen the frame. The duration timer can continue accruing while hidden. UI refresh alone (`UpdateFishingUI`, 1390–1528) does not write that timestamp, although it updates zone presentation and can initialize an empty history row.

**Confirmed source-supported sequence A:** Open/reopen the tracker without fishing; its open path writes `lastCastTime`. A non-fishing loot event within three seconds and outside the one-second loot throttle passes the fallback. No native false attribution is claimed to have been observed.

**Sequence B:** Pause/stop with the tracker visible, or disable both applicable countdown conditions. `OnUpdate` continually refreshes the same timestamp. Ordinary item/currency loot can pass the fishing fallback indefinitely while that condition persists. A real recent cast can similarly admit an unrelated loot interaction; repeated accepted events more than one second apart can renew the window even after UI closure.

**No old expiry-timer claim:** This file creates no `C_Timer.After`, `NewTimer` or `NewTicker` for attribution/auto-close. Auto-close recomputes against current shared state each frame, and active fishing suppresses it; there is no captured old timeout here that independently expires during a newer cast. The three-minute new-session check (1707–1719) also uses `lastCastTime`, so UI refresh can mask actual fishing inactivity and prevent the intended session reset. These are shared-clock effects, not cancellation races in a timer object.

### 3. Delayed writes, duplicates, FasterLoot, and safeguards

[RecordCatch():1530–1582](../Fishingtracker.lua#L1530) captures item link/ID, quantity, quest signal, zone and subzone, then calls `Item:ContinueOnItemLoad`. Its continuation classifies and writes history/session totals without rechecking cast ownership, module enablement or a session/reset generation. An old item-load completion can therefore add an already accepted catch to the current session after a session reset/new-session transition. Captured zone/subzone preserve the original location for that item history write; the delayed callback does not blindly relabel it to the current zone. It cannot independently establish that acceptance was fishing-related. The separate row-image loader at [390–402](../Fishingtracker.lua#L390) checks `row.itemLink` before updating a reused row; that display safeguard is not a history-write guard.

Non-grey recorded items increment `OdysseusFishingDB.history[zone].total/catches`, preserve a display link/subzone, and increment session totals/catches. [RecordCurrencyCatch():1584–1620](../Fishingtracker.lua#L1584) writes currency totals/catches synchronously with a currency-link/name fallback. Fish/Other/Currency classification and grey exclusion happen **after ownership acceptance**; they do not prove fishing origin. A falsely accepted non-grey item can pollute history and Other/Fish/session counts, percentages and fish/hour inputs; falsely accepted currency can pollute currency totals. Global statistics and Zone Catch Details derive from that history.

**Conditional timing risks, not live reproductions:** The one-second throttle reduces closely spaced repeats but is not per-loot deduplication: a distinct catch inside that interval can be missed, while re-enumeration of the same still-present slots after it could count twice if such events occur. Slots lacking an item link are skipped without a registered later-availability retry. Recording at READY counts available slots rather than confirmed acquisition, so uncollected/failed loot can be recorded if exposed that way natively. Native occurrence and frequency of these sequences are unverified. No original 008 mocked/native reproduction is documented; its preserved finding is source-supported timestamp reuse, unlike other findings' explicit mock tests.

[Fasterloot.lua:75–126](../Fasterloot.lua#L75) handles LOOT_READY and yields/reveals loot when `IsFishingLoot()` is true. It has no shared ownership handshake with Tracker's active/recent fallback; when the native check is false, FasterLoot can select its normal fast path while Tracker accepts temporal fishing evidence. Its 0.033-second slot ticker, auto-loot policy, close/error cancellation and locked/group/full handling remain separate. This establishes a policy mismatch possibility, not a guaranteed ordering or proof that FasterLoot caused a missed/duplicate catch. Do not remove that integration based on inference.

**Existing safeguards:** module guards on normal event/OnUpdate entry; player/known-spell filtering; positive native fishing-loot preference; three-second fallback; one-second accepted-loot throttle; item-link/type checks; delayed item-info loading; grey exclusion; captured item zone; and FasterLoot's native-fishing yield. Skill/equipment/Venom display and UI controls are unrelated working paths to preserve.

### 4. Minimal correction recommendation

**Recommended next decision:** Obtain a controlled false-attribution observation for the open/paused/countdown-off cases, then authorize a small clock-ownership correction. The source defect itself is clear enough to justify that focused patch if desired; no implementation is included here.

Separate actual fishing activity evidence from the UI inactivity clock. Only genuine fishing cast/stop evidence should arm its bounded fallback; initialization, UI open/update, pause/resume and ordinary accepted loot must not manufacture or indefinitely renew that evidence. Preserve the native-positive fishing check and existing UI/session timing semantics by giving auto-close/session inactivity the appropriate separate clock. Revisit the three-minute session reset against actual fishing inactivity rather than a presentation heartbeat. Do not require a new persistent schema or broad loot-event rewrite.

Treat delayed catch/session ownership and exact deduplication as explicit follow-up decisions supported by controlled tests: a minimal transient session generation could reject stale item-load writes after reset if that is the chosen session policy, while preserving already accepted valid catches and their captured zone. Do not blindly cancel all pending loads on UI close; hiding the tracker is not proof a legitimate catch should be discarded. Preserve the one-second behavior and FasterLoot handoff until event traces justify changing them. Keep classification, skill/equipment/Venom, totals/history formats, Zone Catch Details and UI geometry/appearance unchanged; do not auto-delete or reclassify historical SavedVariables data from this source hypothesis.

### 5. Focused WoW test plan and verdict

1. Record current totals/history read-only. Open the tracker without fishing and loot a known ordinary non-grey item within/after three seconds; repeat paused/stopped and with countdown disabled. Compare a hidden, long-idle tracker control. Record whether ordinary loot enters catches, not merely whether the UI opens.
2. Perform normal fishing with auto-loot on/off and FasterLoot enabled/disabled. Observe actual inventory/currency gains versus recorded quantities for fish, legitimate Other, grey and currency catches. Do not infer ownership from item category alone.
3. Cancel a cast, then loot unrelated items; test within the real three-second fallback and after it. Close/reopen the tracker and repeat; verify intended session pause/resume, three-minute reset and auto-close behavior separately from catch attribution.
4. Observe rapid/repeated READY delivery and partial/manual/full-bag loot where feasible, comparing actual gains with history and distinguishing throttle suppression from duplicate recording. Record event timing if available; do not assume a particular READY/OPENED order.
5. If item info is naturally delayed, observe close/reset/zone-change/new-cast transitions before completion and compare captured-zone history/current session counts. Leave unobserved delayed-loading cases unverified; future offline tests may simulate them but cannot prove native event guarantees. Use expendable catches; do not wipe existing history as a shortcut.

**Research verdict:** A single timestamp is verifiably reused for UI inactivity and recent-fishing evidence; opening/paused/countdown-disabled presentation can manufacture fallback ownership, and accepted loot can extend it. No old attribution-expiry timer exists; delayed item-load writes instead have a separate session-ownership concern. False positives, misses, duplicates and history pollution are source-supported conditional risks, not reported WoW reproductions. OUS-AUDIT-008 is **RESEARCHED — Decision pending**. Findings 001/002 remain monitoring; 003/004/005 resolved; 006 partially runtime verified; 007 runtime tested and monitoring; 009–012 OPEN.

<a id="implementation-008"></a>

## OUS-AUDIT-008 — Runtime Reproduction and Implementation

**Recorded/implemented:** October 25, 2026. **Status: IMPLEMENTED — Runtime verification pending.** This later user-reported reproduction and authorized correction supersede Investigation 008's no-live-reproduction/research-only disposition. All original findings, historical research and earlier evidence remain preserved. No post-patch native pass is claimed.

**User-reported WoW reproduction:** The user cast Fishing, stopped without catching anything, let the tracker auto-close through inactivity, waited beyond the recent-fishing window, manually reopened Current Session, then looted an ordinary chest without another fishing cast. Chest contents were **Tarnished Dawnlit Commander's Cape x1**, **Potent Healing Potion x2**, and **Coffer Key Shards x12**. Current Session incorrectly showed **Total caught: 3; Currencies: 12; Others: 3**. The tracker showed its normal saved-catch message, **`[Tarnished Dawnlit Commander's Cape] (x1) [ID: 266210] saved.`**, and the user confirmed that the cape appeared in the main Fishing Tracker history. Together with the source recording path, this establishes at least one ordinary item entering normal persistent catch-history processing, not merely a session-counter display artifact. Exact native event ordering was not instrumented and is not inferred.

**Separate quantity-accounting observations:** In a controlled fishing session, **40/40 fish** matched chat quantities; in a post-quest same-location session, **20/20 fish** matched chat quantities. Gray-quality **Torn Caster's Net** was correctly excluded. The tracker normally displays its last saved catch. The earlier **22-versus-21** discrepancy was not reproduced, and the quest-related explanation remains unconfirmed. These user observations support those quantity/exclusion cases; they do not prove loot-origin attribution or validate this later patch.

**Root cause and exact correction:** `lastCastTime` had been shared by actual cast/stop events, initialization, UI reopening/heartbeat, accepted-loot refresh, three-second attribution and three-minute session reset. UI reopening could therefore create eligibility for the chest's `LOOT_READY`, and accepted loot could renew it. The patch adds only one transient clock, `lastUIActivityTime`, while leaving the existing actual-fishing Boolean and one-second throttle intact:

- `lastCastTime` starts unset and is assigned only on recognized player fishing start/channel-start and stop/channel-stop. Only actual fishing lifecycle evidence supplies the existing three-second fallback. Initialization and opening the UI no longer establish fishing evidence.
- Initialization, UI opening, countdown-suppressed/active-fishing `OnUpdate`, and accepted loot refresh **only `lastUIActivityTime`**. Genuine start/stop also update that UI clock so the inactivity/mount-close countdown keeps its existing behavior. Accepted native/fallback loot no longer extends `lastCastTime`.
- `LOOT_READY` still accepts native-positive `IsFishingLoot()`, active recognized fishing, or a genuine timestamp within three seconds. Without any of those, the handler never enters the slot-recording branch: it does not call `RecordCatch`/`RecordCurrencyCatch` or write catch counts/history through them. UI refresh can still initialize an empty zone-history row as before; that is distinct from recording an unrelated catch.
- The three-minute new-session check uses genuine fishing time and now guards the initially unset timestamp. UI-only activity cannot hide a genuine fishing gap. Pause/Resume, Reset/Stop button code is unchanged: **Reset clears current-session counters without resuming a paused timer**. UI duration, auto-opening, auto-close and manual visibility behavior remain separate from attribution.

No recording/classification algorithm, quantity handling, captured zone, history schema, grey/quest-item policy, skill/equipment/Venom display, UI geometry/font/scale, or FasterLoot source was changed. Existing delayed item-load ownership across resets, loot-slot deduplication, and the one-second throttle remain separate work. The Fishing Tracker source-header date is updated from `2026.10.09` to `2026.10.25` for this correction.

**Codex offline validation:** Lua 5.1 syntax passed, exit 0. Targeted LuaCheck remains **75 warnings / zero errors**, equal to the immediately measured baseline. **20/20 deterministic checks passed** under Lua 5.1 using source-extracted actual state declarations, classification/recording functions, button handlers, event handlers, auto-close loop and toggle path, with mocked UI/item/currency/loot/time APIs. Record-helper wrappers counted entry calls; the supported native-positive fishing test also loaded the actual unchanged FasterLoot module to exercise its yield. The harness ran through standard input, without repository test files. It models selected actual control flow rather than native events or the complete live UI.

Checks covered no-fishing manual opening; the reported cast/stop/auto-close/expired/reopen/chest sequence; Pause/Resume/Reset/Stop without new fishing; countdown-disabled and paused UI held open; real-cast fallback recording; x2/x5 quantities; genuine currency; grey exclusion; expiration; inactivity/mount close; paused Reset and explicit Resume; genuine three-minute reset despite UI heartbeat; short-gap continuity; FasterLoot fishing yield; rejected item/currency events never reaching record helpers or history writes; repeated unrelated loot; accepted fallback loot not extending the genuine deadline; native-positive fishing without recent cast metadata; and non-grey/quest recording with captured zone. Existing historical records were seeded in mocks and retained. Final validation includes the exact two-file delta, all 12 findings/statuses, preservation of unrelated files/TODOs, `git diff --check`, full audit whitespace, and one final diff review.

**Historical-data boundary:** No stored catches or historical totals were deleted, rewritten or retroactively classified. Item **266210** is not blacklisted or globally treated as invalid; other records for that ID are not assumed wrong. Any historical cleanup requires separate explicit authorization. Existing reset/wipe semantics and `OdysseusFishingDB` compatibility remain unchanged.

**Remaining limitations / WoW acceptance:** The preserved three-second fallback remains ambiguous if ordinary loot follows a genuine cast immediately. The deterministic check deliberately confirms that such an accepted event cannot extend the deadline; this is not complete native loot-origin proof. Native `IsFishingLoot()` timing, READY delivery/order, multi-slot availability and FasterLoot interleaving remain unverified after the patch. Delayed load callbacks can still cross a reset, and throttling/deduplication behavior is unchanged by design.

Repeat the exact reported chest reproduction after reload and confirm no saved-catch message, session increment or new catch-history entry. Repeat while paused and with auto-close disabled, then after Pause/Resume/Reset/Stop; check Reset still requires Resume when paused. Fish normally with auto-loot/FasterLoot enabled and disabled, including multiple physical fish, currency, grey junk and legitimate non-grey/quest rewards; compare actual quantities with recorded counts. Confirm inactivity/mount closing, manual reopen, and the three-minute fishing-gap reset. Do not wipe history as a test shortcut. Leave unobserved event/load cases unverified; no native post-patch success is asserted here.

Findings 001/002 remain monitoring; 003/004/005 resolved; 006 partially runtime verified; 007 runtime tested and monitoring; 009–012 OPEN. No staging, commit or push is included.

<a id="runtime-verification-008"></a>

### Runtime-verification addendum — OUS-AUDIT-008

**Recorded:** October 25, 2026. **Status: IMPLEMENTED — RUNTIME TESTED — RESOLVED.** The earlier controlled reproduction, investigation and implementation evidence remain preserved. The new user-reported WoW results support bounded closure of the UI-clock attribution defect; they supersede only the post-patch runtime-pending disposition.

**Pre-fix context:** After stopping fishing, auto-close, waiting beyond the recent-fishing window and manually reopening Current Session, ordinary chest loot was recorded: **Tarnished Dawnlit Commander's Cape x1 (266210), Potent Healing Potion x2, Coffer Key Shards x12**. Incorrect totals were **Total caught 3 / Currencies 12 / Others 3**. The saved-catch message for 266210 and its appearance in main catch history established normal catch-recording/persistent-history involvement, not merely counter display. No exact native event ordering is inferred.

**Post-fix user evidence, after correction and reload:** At **22:28:45**, an ordinary satchel was processed by FasterLoot; no Fishing Tracker saved-catch message appeared, and the user confirmed its contents were not recorded. At **22:29:07**, FasterLoot detected a fishing bobber and yielded; Fishing Tracker recorded **Toxic Tlhapi x2**, Current Session showed exactly **two fish**, and no duplicate was observed in the supplied debug excerpt. At **22:29:27**, the tracker reported automatic inactivity closure. These are user-reported native results, not tests performed by Codex.

**Inactivity settings:** The user confirmed **Auto Close Delay = 20 seconds**. The remaining-time countdown becomes visible during the final **10 seconds**. The screenshot's **Closing in: 3s** represented time remaining after countdown had started; neither 3 nor 10 seconds is the configured auto-close delay. No defaults/settings were changed in this documentation update.

**Separate prior accounting evidence:** The earlier controlled sessions matched **40/40** and **20/20** fish against chat quantities, including the post-quest same-location session. Gray Torn Caster's Net was excluded. The tracker normally displays its most recently recorded catch. The 22-versus-21 discrepancy was not reproduced and its cause remains unconfirmed. Those observations are not substituted for the post-fix ordinary-loot rejection test.

**Preserved Codex offline evidence:** Lua 5.1 syntax passed, **20/20 deterministic checks passed**, targeted LuaCheck remained **75 warnings / zero errors**, and `git diff --check` passed. Those historical mocked/static checks are distinct from the user's live observations and were not rerun here.

**Limits retained:** Unrelated loot immediately after a real cast can remain ambiguous within the genuine three-second fallback. Native event ordering and all loot sources/addon compositions are not exhaustively established. Delayed item-load ownership and loot-identity deduplication remain separate questions. Previously erroneous history was not automatically cleaned, and records for item 266210 are not universally invalidated. Resolution covers the reproduced UI-clock defect and supplied successful native sequence, not universal loot-origin proof.

<a id="focused-investigation-009"></a>

## Focused Investigation 009 — FlightMaster OUS2 Scroll Extent

**Research date:** October 25, 2026. **Status: RESEARCHED — Decision pending.** Read-only inspection of the FlightMaster page, OUS2 shell/theme, shared scale-control geometry, and directly relevant page-height patterns. No implementation, new mock scroll-range reproduction, or native UI reachability test was performed. References identify the current checkout; the original audit geometry/qualifications remain preserved.

### 1. Content-height contract and layout

[OUS2Config.lua:666–700](../Config2/OUS2Config.lua#L666) creates the content panel between navigation and help panels, anchors its ScrollFrame to the viewport, and creates one shared scroll child with **`SetSize(contentPanel:GetWidth(), 700)`** at line 697. This is a hardcoded initial height and one-time width assignment, not a measurement of page children. The shell exposes that child as `C.pageContainer` at line 864.

[OUS2Page_Flightmaster.lua:11–13](../Config2/OUS2Page_Flightmaster.lua#L11) parents its page to the shared child and uses `SetAllPoints()`. Its helpers position rows at fixed negative top offsets; row heights are **44** for checkboxes (72–96), **60** for scale controls (162–190), and **52** for action/media/color rows (99–137, 207–265, 267–305). `Refresh()` at [682–717](../Config2/OUS2Page_Flightmaster.lua#L682) updates checked values, sliders, selected names and colors. Neither creation nor refresh measures content bounds, sets the shared height, or registers a FlightMaster OnShow/OnHide height policy.

The existing lower rows extend beyond the declared initial 700-pixel height:

| Control | Top depth from page top | Row height | Bottom depth |
|---|---:|---:|---:|
| Bar Color | 956 | 52 | 1008 |
| Border Color | 1012 | 52 | 1064 |
| Export Flight Data | 1118 | 52 | 1170 |
| Wipe Saved Data | 1174 | 52 | 1226 |
| Reset Bar Position | 1280 | 52 | 1332 |
| Reset Appearance | 1336 | 52 | **1388** |

These values follow [page:604–680](../Config2/OUS2Page_Flightmaster.lua#L604). The final fixed row alone establishes a **688-pixel** discrepancy against the initial 700, before bottom padding. Control order is fixed; all these rows are created, not conditionally expanded/collapsed. Disabled FlightMaster or alternate settings change values, not row presence or the declared content height.

### 2. Shared scrolling, page switching, and resizing

[SwitchPage():516–538](../Config2/OUS2Config.lua#L516) hides the prior frame, shows the selected frame and calls its refresh. [RegisterPage():878–894](../Config2/OUS2Config.lua#L878) stores frame/refresh/sidebar ownership and may show/refresh the current page; neither API has a page-content-height argument or child-bound measurement. FlightMaster therefore cannot rely on registration to advertise its 1388-pixel layout.

Existing comparison patterns establish the intended shared-height boundary: [AutoRemount:381–392](../Config2/OUS2Page_AutoRemount.lua#L381) saves the previous height, extends it to at least 834 on show and restores it on hide. [XPBar:139–173](../Config2/OUS2Page_XPBar.lua#L139) sets a child-specific height and restores its captured default on hide. FlightMaster has no equivalent. Actual shared height can depend on preceding page history/default capture; it should not be described as invariably 700 at every moment. Those neighboring restore paths normally return their prior/default extent rather than fixing FlightMaster's missing declaration.

The shell wheel handler at [683–692](../Config2/OUS2Config.lua#L683) clamps vertical offsets to the native `GetVerticalScrollRange()`. Its custom thumb at [621–657](../Config2/OUS2Config.lua#L621) follows that same native range; on resizing, it recalculates track/thumb geometry. It does not calculate a range from FlightMaster descendants or enlarge the scroll child. Thus wheel/indicator plumbing consumes the native range but cannot be counted as a page-height repair. The thumb is drawn as a texture here; no drag-to-scroll behavior is assumed by this investigation.

[Theme frame bounds](../Config2/OUS2Theme.lua#L115) are default/minimum **1050×700**, maximum **1600×1000**, with header **60** and footer **40**. Navigation anchors at [shell:842–845](../Config2/OUS2Config.lua#L842) and the content anchors imply an approximately **600-pixel** vertical viewport at minimum/default height and **900 pixels** at maximum height, in the same layout units. If native range is based solely on the declared 700-pixel child, the ordinary child-minus-viewport model would allow about 100 pixels of scrolling at minimum and none at maximum; it would still not bring a row ending at 1388 into view. These are conditional geometry estimates, **not measured native ranges** or proof of exact clipping/hit testing.

Width is assigned once from the content panel, while viewport anchors respond to frame resizing. No shell size-change width resynchronization is present in these inspected paths. The child initially includes the 18-pixel scrollbar/gap allowance that the viewport excludes (theme track 10 + gap 8); row right padding also participates. A future width fix must respect those insets rather than blindly replacing one width with another. Current stale-width/horizontal-fit consequences remain runtime questions separate from vertical extent.

### 3. Fonts, controls, safeguards, and evidence limits

Page labels use theme fonts within fixed-height rows. FlightMaster's font-size setting changes the flight timer bar, not the configuration page's theme font. Long selected media names, narrow widths or font rendering can affect text fit/wrapping, but no wrapping-dependent height calculation exists; neither such text nor a dropdown automatically extends the page's declared height in OUS source. Media selection uses the shared popup path, not an expanded inline section. [OUS2ScaleControl.lua:18–37](../Config2/OUS2ScaleControl.lua#L18) derives its own control size from theme assets but does not update page content bounds. No new dynamic expansion or font/layout redesign is warranted by this finding.

Existing safeguards include a bounded resizable shell, anchored viewport/scrollbar, wheel clamping, thumb updates on vertical scroll and resize, fixed row heights, and explicit local height ownership in other long pages. They do not remove the FlightMaster extent mismatch. Popup/dialog strata and existing FlightMaster settings behavior are unrelated working paths to preserve.

The original finding's [SimpleScrollFrame contract](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScrollFrameAPIDocumentation.lua#L65) declares `GetVerticalScrollRange()` and its return; it does not expose the native algorithm for overflow descendants. This investigation's conclusion rests on OUS fixed geometry and missing height ownership, not an invented Blizzard XML behavior. **Source-confirmed:** the page places controls to depth 1388 without declaring a matching scroll extent. **Requires WoW verification:** which controls are actually clipped/unreachable, exact native range and overflow treatment, inherited-height effects, wrapping/hit areas, and horizontal resizing behavior.

### 4. Minimal recommendation and focused UI test

**Recommended next decision:** Verify bottom-row reachability in WoW, then authorize a local FlightMaster content-height correction if confirmed. The source mismatch already justifies preparing that small correction; no implementation is included here. Reuse the existing page OnShow save/extend and OnHide restore pattern, using the final row bottom plus modest padding (for example **1388 + 20 = 1408** for the current fixed layout). Preserve anchors, control order, window limits, navigation, shared scrollbar design, dialog layering and settings. No full child-measurement framework is needed for this static page. Evaluate shared width synchronization separately after a controlled horizontal-resize reproduction rather than bundling a shell rewrite into the height correction.

In WoW, open FlightMaster at the minimum/default window size after visiting General, AutoRemount and XPBar in separate sequences. Scroll with the mouse wheel to its limit and record whether Bar/Border Color, Export, Wipe Data, Reset Position and Reset Style are fully visible and hoverable. **Do not execute wipe/reset actions to test reachability.** Record content/viewport heights and native range if using read-only inspection. Enlarge vertically to maximum, then test right-edge, bottom-edge and corner resizing; return to minimum and compare wheel limits/thumb position and bottom padding. Inspect long media names and safe popup opening without changing settings. Repeat page switching/reopening to expose inherited-height effects and check that other pages retain their own scroll extents. Observe click/hover bounds, not merely artwork visibility.

**Research verdict:** There is a confirmed static layout/declared-height discrepancy, while inaccessible controls remain a source-supported risk pending native UI confirmation. Shared wheel/resize plumbing follows the native range and has no FlightMaster-specific extent update. OUS-AUDIT-009 is **RESEARCHED — Decision pending**. Findings 001/002 remain monitoring, 003/004/005/008 resolved, 006 partially runtime verified, 007 runtime tested and monitoring, and 010–012 OPEN.


<a id="implementation-addendum-009"></a>

## Implementation Addendum 009 — Shared OUS2 Native Scrollbar

**Date:** 2026-10-26. **Status: IMPLEMENTED — Runtime verification pending; height observation retained.** The original finding and Focused Investigation 009 remain historical evidence. This addendum records the later native observations, confirmed input defect and focused shared-shell correction; it does not resolve the finding before user acceptance.

### Evidence and revised scope

- **User-observed native WoW results:** FlightMaster mouse-wheel scrolling works, reaches the bottom and exposes all bottom controls. The thumb cannot be dragged; clicking near it can highlight the shared Reset to Defaults button; the thumb is difficult to distinguish. No actual clipping was demonstrated.
- **Verified pre-change source:** `BuildScrollbar()` constructed a plain Frame plus track/thumb Textures. It never created a Slider, associated an input thumb, enabled mouse input or implemented dragging. The wheel handler independently changed the ScrollFrame offset. This is a shared OUS2 input defect, not a demonstrated failure caused by the initial 700-unit child height.
- **Source-supported overlap:** the old track extended down to the content bottom at root-relative Y=40. The shared Reset button spans Y=28–56 and horizontally crosses the scrollbar strip, predicting a 16-unit vertical overlap. This fits the reported hover symptom, but the exact native mouse recipient was not inspected offline.
- **Height uncertainty retained:** FlightMaster rows still extend to roughly 1388 while the shared child starts at 700. The wheel uses the native range; the mirror does not expose its complete overflow algorithm. Page history and descendant overflow are possible explanations for the observed reachability, not verified causes. No page-height or shared-width correction is included.

### Exact implementation

`Config2/OUS2Config.lua` now builds one OUS-owned native vertical Slider in the existing content-panel gutter. It enables mouse input and associates a native thumb using `SetThumbTexture()` / `GetThumbTexture()`. Native Slider dragging owns movement; no cursor-motion loop, new timer, ScrollBox migration, page relocation or TGA asset was added.

- **Synchronization:** Slider `OnValueChanged` writes the existing ScrollFrame vertical offset, clamped to the current native range. ScrollFrame `OnVerticalScroll`, `OnScrollRangeChanged`, size/show changes and page selection refresh Slider limits/value, thumb size and appearance. An update guard and value/range comparisons prevent feedback and redundant scroll writes. The same objects are reused.
- **Wheel preservation:** the existing 18-unit ScrollFrame wheel handler is unchanged. Wheel input over the Slider delegates to that handler. The existing ScrollFrame, scroll child, initial 700 height, content viewport, page positions and footer button anchors are unchanged. Distinct Changelog/XPBar Help inner scrollers and AutoRemount/XPBar height ownership are untouched.
- **Footer clearance:** BuildFooter returns its actual Reset button and the existing `btnY + btnH` extent. Refresh measures the Reset button's top against the content-panel bottom in their shared inherited scale, adds the theme's four-unit gap, and anchors the Slider bottom accordingly. Before geometry is available, the fallback derives from that returned footer extent and the existing footer anchor. Current anchors yield a 20-unit inset and four-unit clear space; this is recomputed rather than assumed constant. The viewport is not shortened and Reset is not moved.
- **Hit bounds/layers:** the visible track is 10 units wide; two-unit horizontal hit expansion gives a 14-unit input strip within the existing 18-unit gutter. There is no vertical hit expansion into the footer. The Slider is one frame level above the ScrollFrame, without raising content strata. A decoration frame follows the native thumb and has mouse input disabled.
- **Midnight appearance:** dark charcoal-purple fill, subtle purple track outline, full-width lavender thumb, one-pixel outline and inner highlight. Hover and pressed states use restrained brighter theme colors; zero range is muted and disabled. Existing ScrollThumb media is used to establish native association, then color layers supply the wider painted body. No artwork files changed.
- **Thumb proportion:** `floor(trackHeight * viewportHeight / (viewportHeight + nativeRange))`, bounded by the existing 60-unit minimum and available track height; zero range fills the track. This consumes the actual native range, not an assumed 700-unit content extent. Theme additions are limited to hit padding, footer clearance and hover/drag colors.

Current implementation references: [BuildScrollbar](../Config2/OUS2Config.lua#L605), [value synchronization](../Config2/OUS2Config.lua#L661), [Slider callbacks](../Config2/OUS2Config.lua#L701), [content/wheel/initial child](../Config2/OUS2Config.lua#L736), [footer and construction wiring](../Config2/OUS2Config.lua#L458), [theme scrollbar values](../Config2/OUS2Theme.lua#L157). Earlier source line references remain tied to their recorded baseline.

### Verified Retail API evidence and combat boundary

Local Blizzard LIVE baseline: **12.1.5.70575**, commit **15881d522c44cd106d3d8660106ec9f9d2f44167**, under `D:\WowDEV\Reference\Blizzard\wow-ui-source`.

- `Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleSliderAPIDocumentation.lua:154–222` establishes min/max, orientation, thumb association, value and step setters. `GetThumbTexture` is also exposed by this contract.
- `Interface/AddOns/Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml:3–31` demonstrates an enabled native Slider with an associated thumb and no custom cursor-motion loop in that template. The standalone replacement uses the native Slider type, not this horizontal template or a ScrollBox.
- `Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:240–249` uses viewport height divided by native range plus height for visible-extent proportion, supporting the sizing boundary.
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScrollFrameAPIDocumentation.lua:103–111` marks `SetVerticalScroll(offset)` protected. Its full native restrictions and taint behavior are not established by mocks.

**Conservative new-input behavior:** Slider dragging and automatic out-of-range clamp writes are disabled/deferred during combat. The Slider continues to reflect scroll state, with muted appearance; combat-end refresh restores input and applies any pending clamp. The existing wheel handler remains unchanged, including its pre-existing call to SetVerticalScroll. This does not implement OUS2 combat close/reopen and does not certify native combat/taint safety. PLAYER_REGEN events refresh only this presentation/input state.

### Offline validation and pending acceptance

- Lua 5.1 syntax passed for both changed Lua files.
- Targeted LuaCheck: **8 warnings / zero errors**, compared with **9 warnings / zero errors** before the change. The replaced scrollbar no longer contains its unused `F` local; the theme has zero warnings.
- **15/15 focused deterministic source/control-flow checks passed:** native Slider/thumb configuration; gutter ownership; both synchronization directions without feedback; exact 18-unit wheel movement; zero range; range contraction/clamping; proportional/minimum thumb sizing; resizing; page switching and same-page refresh; actual-footer-bound clearance including a moved footer; normal/hover/pressed/hide states; mouse-transparent decoration; combat deferral/recovery; object reuse/no redundant scroll writes.
- Source review confirms the original BuildContentPanel/wheel/700-height block and footer control positions remain unchanged. Hash validation covers unrelated pages, independent scrollers and existing uncommitted work. Whitespace and final scoped diff are reviewed before handoff.

The mock ScrollFrame supplies explicit test ranges. It does not emulate native overflow calculation, native Slider cursor capture/direction, actual mouse-focus precedence, texture rendering or protected-call/taint behavior. It therefore does not newly prove FlightMaster reachability; that evidence is the user's earlier wheel test.

**Required native WoW acceptance:** drag the thumb top-to-bottom, release outside the control/window, and alternate wheel/drag scrolling. Confirm no Reset hover/click interception at the lower end; inspect frame-stack ownership if needed, without executing reset actions. Test zero-range/short pages, all FlightMaster bottom controls, min/max resizing, reopening/current-page selection, page-history sequences through AutoRemount/XPBar, and distinct Changelog/XPBar Help inner scrolling. Check hover/pressed contrast, clipping and UI scale. Verify new drag is muted during combat, existing wheel behavior remains as before, combat-end recovery works and no taint/protected-action errors occur. Do not mark OUS-AUDIT-009 resolved until dragging and footer behavior are accepted in WoW; the separate height discrepancy remains bounded.


<a id="refinement-addendum-009"></a>

## Refinement Addendum 009 — Fixed Midnight Thumb and Smooth Wheel

**Date:** 2026-10-26. **Status: IMPLEMENTED — Initial repair runtime tested; refinement runtime verification pending.** Earlier finding, investigation and implementation addenda are preserved as historical evidence.

### User-reported native baseline

The user reports that the initial native Slider repair works: **dragging, mouse-wheel scrolling and footer clearance are successful**. The prior wheel test already established that FlightMaster bottom controls are accessible. The current request concerns a steadier thumb, more deliberate Midnight styling and smoother wheel movement; it is not a reproduction of the original decorative-thumb failure. These are user-observed WoW results, separate from automated checks. Broader combat/taint behavior was not established.

### Focused refinement

Only the shared scrollbar code/theme and this audit document are changed. Existing page layouts, footer anchors, content viewport, initial 700-unit child height, native Slider/thumb association and input gutter are preserved. Changelog/XPBar Help inner scrollers and AutoRemount/XPBar height ownership are untouched.

- **Fixed grip:** `T.Scroll.thumbH = 64` replaces proportional sizing in the shared Slider. The rule is `min(trackHeight, 64)`; the track-height cap only prevents a thumb exceeding an unusually short track. Zero-range pages keep the same compact, muted/disabled grip. Legacy theme fields remain available, but do not control the shared thumb.
- **Midnight polish:** existing dark outlined track and lavender body remain. The thumb gains a narrow inner side highlight, lower inset shade and three small dark grip marks, preserving its one-pixel border and normal/hover/pressed/disabled colors. Decorations remain mouse-transparent; no new TGA asset or wider hit region is introduced.
- **Bounded smooth wheel:** wheel input updates a target by the existing conceptual **18 units per wheel event**, clamped to the actual native range. One reusable Slider `OnUpdate` handler eases the actual ScrollFrame offset toward that target over **0.12 seconds**, using cubic ease-out. Repeated wheel input accumulates the target and restarts the short transition from the current actual offset; it does not create timers or duplicate loops. Completion sets the exact target and removes OnUpdate, with no ongoing idle update or long inertia.
- **Direct dragging:** thumb/track mouse-down and user Slider value changes discard pending wheel motion. Slider dragging remains native and immediate. Programmatic Slider synchronization is guarded and does not cancel its own interpolated movement. Wheel input while the mouse is held uses the established immediate path rather than competing with the drag.
- **Reconciliation:** external scroll changes, native range changes, resizing, page selection (including current-page refresh), hide and reopen clear obsolete wheel intent and reconcile the actual position/Slider limits. Pending wheel targets never continue onto a different view. Internal interpolation writes are distinguished from external writes so ordinary per-frame synchronization does not cancel the transition.
- **Footer preservation:** the existing measured Reset-button clearance remains four units, with the same current 20-unit bottom inset and 14-unit hit strip in the 18-unit gutter. No footer button or page is repositioned.

### Retained safety boundary

The initial repair's conservative guard remains: new Slider drag and automatic clamp writes are disabled/deferred during combat. Entering combat also stops wheel interpolation; no autonomous smoothing writes continue in combat. For wheel events during combat, the original immediate wheel handler remains the fallback, with its pre-existing SetVerticalScroll call and 18-unit behavior. Combat exit reconciles state and restores new input. This preserves the prior wheel path; it does not certify that path as taint-safe or implement OUS2 combat close/reopen.

The relevant SetVerticalScroll contract and LIVE baseline remain those cited in the previous addendum: Retail **12.1.5.70575**, commit **15881d522c44cd106d3d8660106ec9f9d2f44167**. No new animation or scrolling API is assumed: the new OnUpdate is a bounded presentation loop, not a replacement native drag system.

### Offline validation and native acceptance still needed

Lua 5.1 syntax passed for both changed Lua files. Targeted LuaCheck remains **8 warnings / zero errors**, unchanged from this pass's baseline (shell 8, theme 0).

**21/21 focused deterministic checks passed.** They cover native Slider/thumb ownership and unchanged input bounds; direct dragging/value synchronization; fixed height across content ranges and a shorter-track cap; zero-range disabling; 18-unit wheel targets; monotonic interpolation, exact completion and update removal; rapid/reversed wheel input using one handler; drag cancellation of pending motion; page/range/resize/hide/reopen reconciliation; actual-footer-bound clearance; hover/pressed/disabled decoration; combat deferral/recovery and immediate wheel fallback; no duplicate objects or redundant idle scroll writes. Tests use extracted current shared functions and mocked geometry/ranges; they do not emulate native cursor capture, hidden native range calculation, rendering or taint.

Final scoped review and whitespace validation preserve the initial-height observation and unrelated findings. The user's successful initial-repair test is not presented as runtime proof of this refinement.

**Focused WoW acceptance:** compare slow and rapid wheel input, direction reversals and wheel limits; confirm the short motion feels smooth rather than floaty. Start wheel movement then immediately drag, release outside the control, and check synchronization/no residual movement. Verify the 64-unit grip and contrast on short/long/zero-range pages, page changes, reopening, min/max resizing and UI scale. Reconfirm footer clearance and FlightMaster bottom controls without activating Reset. Smoke-test the independent Changelog/XPBar Help scrollers and AutoRemount/XPBar page-history behavior. Check combat entry during interpolation, muted new dragging, existing wheel behavior, combat-end recovery and absence of protected-action/taint errors. Refinement visual/interaction acceptance and broader safety remain pending; do not claim comprehensive combat verification or resolution of the separate height discrepancy.


<a id="railway-addendum-009"></a>

## Final Design Addendum 009 — Midnight Railway and Native Inner Scrollers

**Date:** 2026-10-26. **Status: IMPLEMENTED — This pass requires native WoW verification; the separate height observation remains bounded.** Preserve the original finding, investigation and earlier addenda. The user has now visually accepted the shared fixed-thumb/smooth-wheel refinement and the Changelog Midnight MinimalScrollBar appearance. Those user-reported observations establish the preceding baseline, not acceptance of this pass or comprehensive combat/taint safety.

### Final architecture and focused correction

- **Shared Railway Slider:** regular OUS2 settings retain the existing native vertical Slider. A centered **6-unit outlined dark-purple rail** (4-unit inset fill) and **10-by-64-unit lavender capsule** (8-unit inset fill) replace square artwork and grip marks. A restrained 2-unit inner highlight is inset four units vertically. Top/bottom half-circle masks reuse Blizzard's `Interface\CharacterFrame\TempPortraitAlphaMask`; rectangular middles join the caps. No new artwork is added. The existing 10-unit Slider plus two-unit lateral hit insets remains a **14-unit input strip**. Native thumb association is retained with a transparent input thumb; mouse-transparent capsule artwork follows its bounds. The existing `min(trackHeight, 64)` short-track cap remains.
- **Shared behavior preserved:** native dragging, native range/value synchronization, 18-unit wheel targets, one bounded 0.12-second cubic ease-out handler, measured footer clearance and existing combat guards remain. Hiding the Slider removes its hit region and stops its animation. If wheel input reaches the underlying shared ScrollFrame while the Slider is suppressed, the existing immediate wheel path remains available; it cannot queue interpolation on a hidden Slider. The ScrollFrame itself is never hidden or disabled.
- **Changelog retained:** the native WowScrollBox/MinimalScrollBar, approved tints and corrected visible-viewport bottom anchor are retained. Its constant page-local `usesInnerScrollBar` flag suppresses the redundant outer Slider while Changelog is selected.
- **XP Bar Help clipping:** source inspection establishes that the Help child fills the XP Bar page, which fills the shared scroll child. Its old bottom anchor followed that child at `+10`, rather than the shorter visible viewport. At minimum shell height 700, the viewport is 600 high while the default child is 700 high; the old Help bottom lies at root-relative Y=-50. Even without that height mismatch, +10 above the viewport's Y=40 bottom reaches into the footer button's Y=28–56 band. The correction preserves the top inset **130** and right inset **34**, but anchors the bottom **18 above the actual shared viewport bottom**, matching the Changelog correction. The inner scrollbar still follows its ScrollBox, dynamically resizes, and ends at modeled root-relative Y=58, above the footer top Y=56. No fixed track height, footer move or shared child-height change is introduced.
- **Matching native tinting:** `T.StyleMinimalScrollBar()` extracts the already approved Changelog treatment for use by both instances. It tints native `Track.Begin/Middle/End`, `Track.Thumb.Begin/Middle/End`, and the two stepper `Texture` regions. Instance `HookScript` handlers reapply normal/hover/pressed/disabled theme colors after native atlas changes; native atlases, desaturation, hit regions, thumb sizing and callbacks remain intact. Global Blizzard mixins/templates are unchanged.
- **Actual subsection ownership:** XP Bar `ShowChild()` sets the transient page-local flag only for Help; `ShowHub()` clears it. Both request the existing shared reconciliation through `C.RefreshScrollbar()`. Shared page/range/resize/reopen reconciliation also consults the active page's flag. Leaving Help for Global, Experience, Reputation or another regular subsection restores the Slider; other XP Bar sections are not suppressed. Leaving either inner-scroller page restores ordinary-page behavior. This state is not persisted in SavedVariables.

Source references: `Config2/OUS2Config.lua` (`BuildScrollbar`, `SwitchPage`, `C.RefreshScrollbar`); `Config2/OUS2Theme.lua` (`T.Scroll`, `T.StyleMinimalScrollBar`); `Config2/OUS2Page_Changelog.lua` (page flag and inner-scroller setup); `Config2/OUS2Page_XPBar.lua` (`ShowHub`, `ShowChild`, `CreateHelpScrollContent`). Existing initial shared scroll-child height, window limits, page content, Reset/Close callbacks and addon modules remain unchanged.

### Verified API/source boundary

Local Blizzard **LIVE Retail 12.1.5.70575**, commit **15881d522c44cd106d3d8660106ec9f9d2f44167**, supplies the checked contracts and implementation: generated `SimpleFrameAPIDocumentation.lua` (`CreateMaskTexture`), `SimpleTextureAPIDocumentation.lua` (`AddMaskTexture`), `SimpleTextureBaseAPIDocumentation.lua` (`SetTexture`, `SetTexCoord`), `SimpleRegionAPIDocumentation.lua` (`SetVertexColor`) and `SimpleScriptRegionAPIDocumentation.lua` (`HookScript`). `Blizzard_SharedXML/Mainline/MajorFactionRenownSharedTemplates.xml` uses the portrait mask with `CLAMPTOBLACKADDITIVE`; `Blizzard_UnitFrame/Mainline/UnitPowerBarAlt.lua` also demonstrates mask texture-coordinate updates. `Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.xml/.lua` and `Blizzard_SharedXMLBase/ButtonStateBehavior.lua` establish the native regions, atlas changes and state handlers. The native handlers change atlases; the reviewed Lua does not reset vertex colors explicitly. This implementation reapplies tint after those handlers without assuming undocumented engine-side atlas/color retention. Source facts do not certify rendered mask seams, native input routing or taint safety.

### Offline validation and required native acceptance

- Lua 5.1 syntax checks passed for all four changed Lua files.
- Targeted LuaCheck: **11 warnings / zero errors**, unchanged from baseline (shell 8, theme 0, Changelog 0, XP Bar page 3).
- **76/76 focused deterministic checks passed**, using extracted current shell/view/scroller functions, the actual theme helper and Blizzard button-state methods with mocked frames. Coverage includes native Slider configuration and 14-unit input; fixed/capped thumb sizing; rounded-piece/mask setup and centering; measured footer clearance; both synchronization directions; exact 18-unit targets and cubic easing completion; repeated wheel input and drag cancellation; zero range; resize/hide/reopen reconciliation; combat drag suppression, immediate wheel fallback and recovery; Changelog-to-FlightMaster switching; XP Help/Global/Experience/hub transitions; hidden-Slider inactivity; both native inner templates/anchors and all tint states; minimum/maximum Help layout arithmetic and modeled end-of-content reachability.
- The mock supplies ranges and geometry. It does not reproduce native mouse capture, range calculation, text wrapping, shader-mask rendering, real footer/input stacking or protected-call/taint behavior. Final scoped diff/readback, file-hash preservation and `git diff --check` passed. Only the four named Lua files and this audit changed during this task; offline success is not native acceptance.

**WoW acceptance for this pass:** inspect rounded rail/capsule ends, joins, outline/highlight, centering and contrast at normal and alternate UI scales. Drag and release outside the control; test rapid/reversed wheel input and interruption by dragging on regular pages, including FlightMaster bottom controls. At minimum and maximum window sizes, confirm Changelog and XP Bar Help each show only the native inner scrollbar, its bottom arrow stays above the footer, dragging/wheel remain synchronized, and the final entry is reachable. Leave Help through Back and enter normal XP Bar sections; navigate Changelog to FlightMaster and reopen both inner and regular views, confirming the outer Slider restores only where appropriate and no invisible control intercepts input. Check zero-range pages, resizing while scrolled, combat entry/recovery and absence of taint/protected-action errors. Do not execute Reset to Defaults. The earlier bounded FlightMaster height observation remains separate; OUS-AUDIT-009 is not marked resolved by this pass.


<a id="housekeeping-runtime-009"></a>

## Runtime Evidence and Housekeeping 009 — 2026-10-26

**Status: IMPLEMENTED — RUNTIME TESTED (bounded); grip visual approval and remaining acceptance pending; height observation retained.** This updates the current disposition, not the original audit or earlier implementation chronology. Finding 009 is not fully resolved.

**User-reported WoW evidence:** shared native thumb dragging works; mouse-wheel scrolling reaches FlightMaster's bottom controls; the fixed-size thumb works and its Railway appearance is acceptable; Changelog's native Midnight appearance is approved; XP Bar Help has its native inner scrollbar; returning from Help to normal XP Bar settings restores the shared outer Slider. These are the supplied observations, not new Codex runtime tests. They do not independently establish every page, transition, window size or inner-scrollbar clipping case.

**Current working-tree source:** the shared OUS-owned native vertical Slider retains a centered **10×64 lavender capsule** over a **6-unit rounded dark-purple rail**, a **14-unit input region**, **18-unit wheel targets**, approximately **0.12-second cubic easing**, footer clearance and the existing conservative combat guards. Three **4×1** decorative grip marks have now been restored at midpoint offsets **-3, 0, +3**, using `T.Colors.border`; they follow the mouse-transparent thumb artwork and do not change interaction or visibility logic. Changelog and XP Bar Help keep native WowScrollBox/MinimalScrollBar instances, matching instance-local Midnight tinting and their visible-viewport bottom anchors. The outer Slider is suppressed on Changelog and only the Help subsection of XP Bar; ordinary XP Bar views restore it.

**Historical offline evidence:** the Railway pass reported Lua 5.1 syntax success, LuaCheck **11 warnings / zero errors** unchanged from baseline, and **76/76 deterministic checks**. The subsequent grip-only pass reported syntax success, shell LuaCheck **8 warnings / zero errors** unchanged from baseline, **20 focused grip checks**, and whitespace/diff review. Those results were not rerun during this documentation-only housekeeping and do not prove native visuals, cursor routing or taint safety. The restored grip marks still lack explicit native visual approval.

**Remaining acceptance:** approve grip contrast/spacing in WoW; check both inner scrollers' bottom arrows and final-entry reachability at minimum/maximum size and while resizing/scrolled; sample page/subsection transitions and reopen behavior; verify footer input clearance and combat/recovery without claiming exhaustive taint safety. The initial FlightMaster scroll-child-height discrepancy remains historical source evidence, not a confirmed accessibility defect: the reported wheel test reaches the bottom. OUS2 combat close/reopen design is a separate open TODO, not implemented by scrollbar guards.

**Metadata check:** the production TOC remains **Version 1.0.8 / X-Build-Date 2026.10.09**. OUS2 General reads those fields and formats the build date as **2026-10-09**; the separately displayed game version is not the addon version. No version/build-date change was made. All 12 findings and earlier addenda remain represented; other finding statuses are unchanged. Finding 012 remains open pending its remaining documentation review, including the README exclusion-count description; this housekeeping does not silently close it.

## OUS2 Combat Close/Reopen Lifecycle — Implementation — 2026-10-26

**Status: IMPLEMENTED — Native WoW runtime verification pending.** This is the separately authorized configuration lifecycle policy, not evidence of a reproduced combat crash or taint failure. It supersedes the earlier statement that the lifecycle was not implemented without altering those historical records. All twelve audit findings retain their existing statuses; **010 same-page refresh and 011 nullable flight-map handling remain unmodified and OPEN**.

**Policy and changes:** `Config2/OUS2Config.lua` rejects hidden-window combat opens centrally in `C.Toggle()` and `C.OpenPage()` before changing page state. Toggle still closes an already-shown window; OpenPage also closes a combat-visible window without navigating. Combat entry conservatively hides OUS2 through an added OnEvent hook after scrollbar setup, preserving the existing regen reconciliation script. OnHide ends owned movement/resizing and closes owned editors while normal page/sidebar cleanup runs. Combat exit never reopens the window, and blocked requests are not stored or replayed. `C.currentPage` is retained for manual reopening. There are no new SavedVariables, timers, polling, global window sweeps or production merchant calls.

**Editor ownership:** opening OUS2 media, copy and color editors is blocked during combat. Shell closure hides the media dropdown and copy dialog through their private OUS frame references. Each color-picker request carries a fresh `extraInfo` token; cleanup requires both matching `GetExtraInfo()` identity and the same swatch callback. Only then is the shared picker hidden. No Cancel/rollback or application callback is invoked by cleanup; already-applied colors remain. Color apply/cancel callbacks also reject combat execution. Another addon's picker, a stale token with a replaced callback, or a picker whose ownership API is unavailable is left untouched; ownership uncertainty is not permission for a global hide. Independent module-management/reset confirmation dialogs are not swept up by this shell cleanup.

**Verified source boundary:** local LIVE **12.1.5.70575**, commit `15881d522c44cd106d3d8660106ec9f9d2f44167`. `Blizzard_ColorPickerFrame/Mainline/ColorPickerFrame.lua:89–115` stores `info.extraInfo` and exposes `GetExtraInfo()`; its `OnHide` at 59–61 unregisters mouse handling, while rollback belongs to explicit Cancel/escape/outside-click paths. The associated XML routes OnHide to that mixin. `Blizzard_SharedXML/Backdrop.xml` declares an ordinary backdrop Frame template, not a requirement to close OUS2 in combat. `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:1076–1088` warns that CloseSpecialWindows handles possibly tainted values and belongs to secure code; this implementation does not call it. Combat-entry closure is a conservative product policy, not a proven universal API requirement.

**XP child restoration:** `Config2/OUS2Page_XPBar.lua` adds a narrow OnShow hook. A retained Global child regains `globalPageHeight`; other children/hub use the existing default height. It reconciles the scrollbar without calling `RefreshForOpen()` or `ShowHub()`, changing child selection, altering the Help inner-scroller flag, or changing settings/reset semantics. Existing OnHide default-height restoration and navigation callbacks remain. This does not implement generic same-page refreshing.

**Existing cleanup preserved:** the Utilities page's separate native Goblin preview still hides on page/sidebar closure and combat entry, clears readiness/playback intent, and ignores hidden/stale callbacks. It pauses/clears its native model outside combat; combat hide intentionally avoids those native writes, with later test playback reloading normally. No renderer change was needed. The independent merchant Goblin, 2D fallback, seller queue/generation, transaction timing and accounting are unchanged. Shared scrollbar drag guards, smooth-wheel cancellation, footer clearance and regen recovery remain; XP Bar Help and Changelog retain inner-scrollbar ownership.

**Offline validation:** Lua 5.1 syntax passes for both changed Lua files. Targeted LuaCheck remains **11 warnings / zero errors**, matching baseline (**8 shell / 3 XP page**). **148 focused mocked lifecycle assertions** pass using the actual shell, entry wrappers, Utilities preview/renderer and extracted actual XP height hooks. Coverage includes blocked/normal/visible-combat entry routes, no deferred opening or page mutation, movement interruption, preserved scrollbar handlers, editor ownership and color preservation, selected XP child/height restoration, preview cleanup/late callbacks, and separation from merchant state. Mocked visibility and native APIs do not establish native geometry, protection or taint safety. Final focused source/diff review and whitespace validation apply; unrelated work and historical findings are preserved.

**Required WoW acceptance:** exercise `/ous`, `/ous2`, `/ous2 Utilities`, minimap/broker/Compartment, Toolbox and public entry routes before/during/after combat. Confirm entry closes an open shell, new opens are blocked, close remains available, no automatic reopen occurs, and manual reopening retains the selected page. Interrupt dragging/resizing and wheel interpolation. Close/reopen XP Global, Help and other children; check bottom reachability, inner/outer scrollbar ownership, Changelog, footer input and resizing. Enter combat with a loading/playing Goblin preview; confirm it stays hidden until another manual test. Close configuration while a merchant is active and verify unchanged seller behavior. Test OUS media/copy/picker cleanup, already-applied color retention, normal Cancel out of combat and another addon's picker remaining untouched. Native event ordering, keyboard focus, screen geometry, dynamic frame protection and taint remain unverified until those tests. No release-readiness claim, staging, commit or push is made.

## Implementation Addendum 010 — Current-Page Refresh — 2026-10-26

**Status: IMPLEMENTED — Runtime verification pending.** The original source finding and earlier open-status records are preserved as history. The source-supported gap was that same-page SwitchPage returned before refreshing, while Toggle reopening did not request a page refresh. No native failure reproduction is claimed.

**Prior combat-lifecycle runtime update:** the user reports successful bounded WoW testing of the recently implemented combat lifecycle. This is user-reported acceptance, separate from Codex's earlier 148 mocked assertions. No complete per-entry-point/editor procedure was supplied; every editor-ownership, focus, native protection/taint and third-party edge condition is not established by that general confirmation. The combat policy remains intact in this patch.

### Refresh-contract review

All fourteen registered pages provide callbacks. Their inspected source contracts outside combat are:

| Page | Existing callback effects | Retained-page handling / show behavior |
| --- | --- | --- |
| General | Version, minimap and session-debug widget synchronization. | Existing callback; no data-refresh OnShow hook. |
| AutoRemount | Checkboxes, suppressed delay control, mount labels. | Existing callback; OnShow/OnHide own extended content height, not widget refresh. |
| Openables | Checkboxes, suppressed scale control and list counts. | Existing callback; no item-use/module-refresh action is invoked. |
| StatsBar | Checkboxes, suppressed controls and unfocused template text. | Existing callback; no stat-read/display action is invoked. |
| FishingTracker | Checkboxes, suppressed delay/opacity/scale controls and font label. | Existing callback; no fishing action is invoked. |
| FlightMaster | Checkboxes/status, suppressed dimensions/media/colors. | Existing callback; no module toggle, settings application, export or wipe action. |
| FasterLoot | Enabled checkbox/status text/colors. | Existing callback; no loot/runtime setter action. |
| Toolbox | Status, local disabled note, direction/lock widgets and suppressed scale. | Existing callback; no toolbox enable/layout action. |
| Delves | Suppressed controls, swatches, unfocused templates and edit-button/help text. | Existing callback; it does not unlock/show the positioning preview. Existing combat-event refresh and hide cleanup remain separate. |
| Utilities | Checkboxes/counts, animation/size labels, suppressed distance control; updates size/distance of an already-existing preview where safe. | Existing callback; never creates, shows, loads or plays a preview. Height and preview-hide hooks remain separate. |
| XPBar | Registered RefreshForOpen calls ShowHub, then synchronizes four settings groups. Existing Refresh synchronizes the same groups without ShowHub. | Only existing Refresh is used for same-page/reopen. Real page entry keeps RefreshForOpen. OnShow restores the retained child's height. |
| Changelog | Recalculates content dimensions from current text/width. | Existing layout-only callback and size handler; no explicit scroll-to-start operation. |
| Help | Empty callback for static content. | Harmless existing no-op. |
| FlightRouting | Empty callback for informational content. | Harmless existing no-op. |

Widget synchronization preserves existing focused-edit checks and suppressed control callbacks. These source facts are not universal native idempotence or scroll-position proof under changing geometry.

### Minimal correction and preserved boundaries

Only Config2/OUS2Config.lua and Config2/OUS2Page_XPBar.lua change in production. RegisterPage gains an optional fifth refreshCurrentFn argument; the retained-page callback defaults to the existing refresh function, preserving all four-argument registrations. XPBar alone supplies its existing non-navigation Refresh as that override. RefreshForOpen is deliberately excluded only from retained-page cases, not from normal entry/registration.

Same-page SwitchPage calls the retained callback once before scrollbar reconciliation. Toggle calls it once after a successful manual opening, never when closing or rejecting combat input. OpenPage continues using SwitchPage, so a different-page request invokes only the destination's normal callback, without a generic OnShow refresh of the previously retained page. The correction adds no page hide/show cycle, ShowHub call, scroll-offset reset, settings action, preview start, timer, polling or SavedVariables.

XP child selection and content-height restoration remain; Help/Changelog keep native inner-scroller ownership. Existing scrollbar range clamps still apply when actual geometry/range changes. Utilities' preview stays on-demand: first opening does not create it, retained requests do not resurrect a hidden preview, and an explicitly playing preview is not reloaded/restarted by refresh. Its existing calibration synchronization remains. Closing still cleans up preview/editor ownership, and production merchant presentation, selling queue, batching and accounting are untouched. All central combat guards, combat-entry hide/movement cleanup and no-auto-reopen policy remain. Finding 011 is not changed.

### Validation and native acceptance

Lua 5.1 syntax passes; targeted LuaCheck remains **11 warnings / zero errors** (**8 shell / 3 XP page**), unchanged baseline. **226 focused mocked lifecycle assertions** pass, retaining combat/editor/preview regressions and adding exact refresh-count checks, updated settings display, no refresh on close/blocked opens, no old-page cascade when opening another page, actual XP callback registration/bodies and child preservation, focused-template protection, valid shared scroll offsets, Changelog's layout-only callback and Utilities preview isolation. The XP UI dependencies and native visibility/scroll APIs are mocked; no native WoW acceptance for 010 is claimed. Final focused diff/readback and whitespace checks apply.

In WoW, change an existing setting through another supported route while OUS2 is closed, then reopen its retained page and confirm current widgets. Repeat explicit same-page requests. In XPBar, test Global, Experience, Reputation, Favorites, Session Stats and Help while scrolled; verify same-page/reopen retains the child and valid scroll position, while navigation from another page retains the normal hub-entry behavior. Confirm focused edits are not overwritten. Check Utilities first-open/reopen with no preview, same-page requests during an explicitly started test, and close cleanup. Check Changelog mid-scroll, inner/outer scrollers and footer clearance. Recheck combat rejection/no automatic reopening and owned-editor cleanup. Native scroll clamping during geometry changes, callback/event ordering, focus and taint remain bounded runtime uncertainties. No staging, commit or push.

## Finding 010 — Bounded Runtime Acceptance (2026-10-26)

**Status: IMPLEMENTED — RUNTIME TESTED — RESOLVED.** The user reports testing the current-page refresh correction in WoW with **no visible issues** in the exercised scenarios. This is general acceptance, not an independently documented pass for every scenario in the preceding procedure. The original finding, implementation and offline evidence remain above. Exhaustive taint, focus, scroll geometry and configuration lifecycle safety are not established by this report.

## Finding 011 — Nullable Flight-Map Boundary Implementation (2026-10-26)

**Status: IMPLEMENTED — Runtime verification pending.** No native failure, crash or taint defect has been reproduced.

### Verified contracts and caller behavior

The local LIVE reference remains **Retail 12.1.5.70575**, commit `15881d522c44cd106d3d8660106ec9f9d2f44167` (`version.txt` and Git snapshot checked). Generated [MapDocumentation.lua:49–65](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua#L49) declares `C_Map.GetBestMapForUnit(unitToken)` with a nullable numeric `uiMapID` result. [TaxiMapDocumentation.lua:11–25](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_APIDocumentationGenerated/TaxiMapDocumentation.lua#L11) requires a non-nullable numeric `uiMapID` for `C_TaxiMap.GetAllTaxiNodes(uiMapID)` and declares a non-nullable table result. This is a taxi-node retrieval API; OUS calculates distance from node/world positions itself.

Blizzard's [FM_FlightPathDataProvider.lua:19–46](https://github.com/Gethe/wow-ui-source/blob/15881d522c44cd106d3d8660106ec9f9d2f44167/Interface/AddOns/Blizzard_FlightMap/FM_FlightPathDataProvider.lua#L19) calls that API with `self:GetMap():GetMapID()`, the displayed map's ID. The provider is attached by `FlightMapMixin:OnLoad()` in `Blizzard_FlightMap.lua:53`, wired by `Blizzard_FlightMap.xml:39`. This usage does not establish that OUS's separate player-map query always returns a map during taxi hover. A possible nil-to-required-argument call is source-supported; its native reachability and precise client failure behavior remain unverified.

### Minimal correction and preserved contracts

- [Flightmaster.lua:521](../Flightmaster.lua#L521), `UpdateCustomFlightTooltip()`: retain the existing `cachedTotalDist = nil` reset, but query taxi nodes only when the player-map ID is present (boundary at lines 590–593). Missing map data leaves the distance cache unavailable and continues destination, known/unknown time, cost, tooltip sizing and ownership handling. The function still returns no distance value. Its tooltip uses the existing **Distance: Unknown** fallback; flight start hides the distance line when the cache is unavailable.
- [FlightRouting.lua:253](../FlightRouting.lua#L253), `CalcTotalRouteDist()`: return `nil` immediately when the map ID is nil, before taxi lookup (lines 255–257). The existing numeric-distance-or-nil contract remains. Its itinerary caller retains **Distance: Unknown** without changing route names, selection, hops, route lines or independently calculated time.
- A present map with missing nodes/positions/world coordinates follows existing unavailable-data branches. Missing distance is never fabricated as zero; actual computed zero remains a numeric available result under Lua truthiness. Valid-map calculations and formatting are unchanged.
- Saved timing lookup precedence (saved times, legacy `SFT_FlightData`, namespace `OUS.FlightData`), learned-flight persistence and migration are unchanged. No data file or TOC change, new timer, polling, event or protected-frame operation was introduced. Source headers carry the modification date.

### Offline validation and native acceptance

Lua 5.1 syntax checks passed for both changed Lua files. Targeted LuaCheck remains **87 warnings / zero errors**, unchanged from baseline (**32 Flightmaster / 55 FlightRouting**). **122 focused Lua 5.1 assertions passed** using the actual tooltip and routing function bodies with mocked APIs: valid/nil map IDs, available/unavailable nodes and positions, missing world coordinates, stale cache clearing, zero distance, short/nil and multi-leg routes, preserved tooltip/time/cost output and comparison against pre-change valid-map behavior. A numeric-zero map fixture checks forwarding rather than asserting that zero is a usable Retail map. Unavailable-node fixtures exercise existing defensive branches, not a claim that the declared non-nullable table result normally becomes nil. Mocks do not reproduce native map availability, taint or UI behavior. Focused source comparison confirms only the guards and header dates changed in these Lua files; final diff/readback and `git diff --check` passed.

**Required WoW acceptance:** hover known and unknown destinations on a normal taxi map; check destination, time, cost and distance, including Blizzard-tooltip suppression enabled/disabled. Test a multi-hop itinerary and confirm estimated time, distance, route selection and line drawing. Start and finish a flight and check timing/arrival and distance presentation. Close/reopen the taxi map and repeat after zoning or an available map-layer transition. If map data is naturally unavailable, verify graceful unavailable distance and continued tooltip/itinerary operation; ordinary successful testing cannot establish coverage of a nil-map event. No forced map-state manipulation is required. Native timing/event ordering and nil-map reachability remain pending user testing.

## Finding 011 — Bounded Normal-Flight Runtime Acceptance (2026-10-26)

**Status: IMPLEMENTED — RUNTIME TESTED (bounded normal flight); nil-map branch native-unobserved.** Following the implementation above, the user reported no problems during ordinary in-game flight testing. This supports normal behavior in the exercised scenarios; individual cases in the earlier acceptance procedure were not separately documented. The nullable map-ID branch remains verified by source contracts and offline mocks, **not directly observed in WoW**. No native nil-map failure or recovery, exhaustive transition ordering, combat or taint safety is claimed. The original finding and implementation/offline evidence remain intact.

## Finding 012 — Documentation Consistency Reconciliation (2026-10-26)

**Status: DOCUMENTATION CORRECTED — RESOLVED.** This closes the identified documentation discrepancies, not outstanding implementation or runtime acceptance work. Historical audit findings, addenda, research records and changelog entries remain preserved.

### Source-backed reconciliation

- **Root README:** `AutoRemountSpells.lua:89–132` contains exactly three exclusions: **13262 — Disenchant**, **6247 — Opening Halloween Event (Take Bucket)**, and **1234969 — Ethereal Augmentation**. `README.md` now lists all three. Its earlier Retail 12.1.0 test report with only Ethereal Augmentation excluded remains historical evidence, not a statement of the current database.
- **Guidance:** current `AGENTS.md` already matches the production TOC's five Interface values, account/per-character SavedVariables and complete 45-entry load order, including `xpbar_sessionstats.lua` and `JunkBroker.lua`. Those earlier audit discrepancies were already corrected. This pass updates its two remaining lowercase flight-data references to `FlightData.lua` and documents `RegisterPage`'s optional fifth retained-page refresh callback, as implemented in `Config2/OUS2Config.lua:1062–1068`. Four-argument registrations remain supported. Retired `CLAUDE.md` is not recreated.
- **General/TODO:** `OUS2Page_General.lua` already implements card navigation (line 193), minimap control and session-only debug wiring (lines 397–416), and reads addon Version/Build Date from TOC metadata (lines 264–272). Stale visual-only/missing-wiring items are corrected; enabled-card states, count summary, layout acceptance and global reset-scope review remain pending.
- **Module controls:** `OUS2Page_Toolbox.lua` has scale and Reset Position; `OUS2Page_FishingTracker.lua` has Wipe History with confirmation and settings-only reset preserving history. These are implementation facts, not new runtime passes. Future Fishing Session Statistics, Toolbox expansion and position-management review remain separate. Stats Bar already has module/table toggles; its separate character single-line policy remains a design review. Flight Master's master toggle is already exposed; active-flight interaction acceptance remains pending.
- **Migration/reset:** XP/Rep/Delves migration and primary controls are implemented. The existing parity document retains final decisions (including rest-icon placement, Reputation toast reset scope, preview consistency and popup layering); helper extraction is deferred engineering work. Utilities reset/toggle implementation and Finding 004's bounded closure are retained. Global reset consistency/runtime acceptance is not silently closed.
- **OUS2 lifecycle/scrollbar:** combat-entry closure, blocked combat opens, retained selection, no automatic reopening and owned cleanup are implemented. General native lifecycle acceptance remains distinct from Finding 010's bounded acceptance. The active theme README now distinguishes the production Railway Slider from historical art-test dimensions/formula and preserves native inner-scroller ownership and Finding 009's remaining acceptance.
- **Native Goblin:** active README/TODO distinguish implemented production display 6882, Merchant Counter v2, 96/64/32 native viewports, distance control and isolated preview from standalone research. User-reported acceptance covers approved textured rendering, preferred **64x64 at distance 1.2**, Loot playback during selling and independent preview. No further visual polishing is requested. Defaults remain **3D OFF / size 96 / distance 1.2**, with existing 2D Goblin/Coin FlipBooks as default/fallback. Combat, fallback, rapid-switch and merchant-layout regression cases remain bounded/pending.

### Remaining work and release boundary

Findings 001/002 remain monitoring; 003/004/005/008 retain bounded closure; 006 retains untested zero-progress/maximum/unavailable-data cases; 007 retains monitoring and unverified ChallengeMode/combat overlap; 009 retains its specific pending acceptance; 010 retains bounded runtime resolution; 011 has only ordinary-flight native acceptance. No other finding status is changed.

Openables dynamic recognition and quest companion, duplicate Zone Ability research, BuffBars, optional expansion and deferred architecture remain future tasks, not demonstrated current release-critical defects. `TODO_v2.md` records the five mandatory release activities: TOC Version, verify General Version, verify General Build Date coordinated with TOC X-Build-Date, in-game OUS2 Changelog and `CHANGELOG.md`. General derives metadata from the TOC. No next version/date was selected or release update performed.

### Documentation-only validation

Compared active claims with directly relevant source/data and later audit addenda. All 12 original findings and prior audit history are retained; only 011/012 index statuses and appended records change in this audit. Reviewed changed headings, relative file links and relevant anchors; reviewed the focused task diff and ran `git diff --check`. Production Lua, TOC, assets, SavedVariables, changelogs and historical research are unchanged. No Lua/runtime tests were rerun for documentation-only changes; earlier validation records remain historical. No staging, commit or push.
