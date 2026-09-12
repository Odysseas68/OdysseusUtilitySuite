# OUS2 Final Legacy Configuration Parity Audit

Current re-audit date: 2026-09-11
Historical milestone retained: the 2026-07-10 Phase 5.6 audit described OUS2 as functionally complete subject to General-toggle review. This current setting-level audit supersedes that readiness conclusion because it checks every legacy control, its SavedVariable path, handler, and reset scope.

## Direct Answer

**Yes. The original audit found two functional legacy settings missing from OUS2. Both findings have now been implemented; no class-C legacy-only setting remains:**

1. `Enable Toolbox` — `OdysseusDB.modules.toolbox` — implemented on 2026-09-12 through a lifecycle-safe runtime setter and passed user in-game validation. Its immediate OUS2 lifecycle behavior is intentionally retained while legacy `/ous` remains unchanged as the historical compatibility/reference configuration.

`Enable Flight Master` — `OdysseusDB.modules.flightMaster` — was the other historical finding. It was implemented on 2026-09-12 through a lifecycle-safe runtime setter and passed user in-game validation.

One additional legacy capability is deliberately unavailable in OUS2:

3. `Enable Faster Loot` — `OdysseusDB.modules.fasterLoot`; the OUS2 Faster Loot page explicitly keeps this status read-only until a cleanup-aware public setter exists.

The audit also discovered that OUS2's global reset bypassed the legacy confirmation. That safety gap was corrected on 2026-09-11 by routing the OUS2 action through `ODYSSEUS_CONFIRM_WIPE_ALL`; the underlying reset function and scope were not changed. User runtime validation confirmed that OUS2 shows the dialog, Cancel leaves settings untouched, Confirm resets settings, and legacy `/ous` uses the same confirmation behavior.

These are real configuration gaps, not cosmetic differences. No legacy setting was found writing to an unidentified or divergent SavedVariable path, and there are no `UNKNOWN` mappings. Legacy `/ous` is not ready for retirement.

## Repository Baseline

The audit began against `3aa7c97d4b520fc8df85c184d1e3acf5885d9abf`, where an unrelated user edit in `xpbar_delves.lua` correctly blocked the documentation edit. The user committed and pushed that change separately. The resumed baseline is:

| Field | Current value |
|---|---|
| Repository root | `D:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\OdysseusUtilitySuite` |
| Branch | `main` |
| HEAD | `52a9c7aeb6424e1755d283058d75ecc8f36f32df` |
| `origin/main` | `52a9c7aeb6424e1755d283058d75ecc8f36f32df` |
| Ahead / behind | `0 / 0` |
| Worktree before this document edit | clean |
| TOC Version / OUS2 in-game Version | `2026.06.22` (OUS2 reads the TOC `Version` metadata) |
| OUS2 build date | `2026.06.25` (TOC `X-Build-Date`) |
| Interface metadata | `120000, 120001, 120005, 120007` |

Commit `52a9c7a` adds `[3081] = true -- Cursed Keepsake` to `NON_DELVE_INSTANCE_IDS` in `xpbar_delves.lua`. It changes Delves runtime identification data only and does not add, remove, or alter a legacy or OUS2 configuration control. Therefore the completed configuration inventory did not require reclassification.

## Authorities and Source Read

The following authorities and implementation files were read before the conclusions were made:

- `AGENTS.md`, `CLAUDE.md`, `README.md`, `CHANGELOG.md`
- `Documentation/README_v2.md`, `Documentation/ARCHITECTURE.md`, `Documentation/TODO_v2.md`
- the prior version of this document and `Documentation/OUS2_XPBAR_PARITY.md`
- `OdysseusUtilitySuite.toc`
- `Core.lua`, `Config.lua`, `xpbar_config.lua`, `Help.lua`
- `Flightmaster.lua`, `FlightRouting.lua`, `Fasterloot.lua`, `Fishingtracker.lua`
- `AutoRemount.lua`, `StatsBar.lua`, `Openables.lua`, `Utilities.lua`, `Toolbox.lua`
- `xpbar_core.lua`, `xpbar_engine.lua`, `xpbar_delves.lua`, `xpbar_favorites.lua`
- `Config2/OUS2Theme.lua`, `Config2/OUS2Config.lua`, `Config2/OUS2ScaleControl.lua`
- every current `Config2/OUS2Page_*.lua` file

No `Documentation/PROJECT_STATUS.md` or `Documentation/PHASE6_BASELINE.md` was present. Help and Changelog are read-only information surfaces; neither adds a persistent legacy setting.

## Configuration Implementation Map

### Legacy `/ous`

- Root window, General, Flight Master, Faster Loot, Fishing Tracker, Auto Remount, Utilities, Stats Bar, and Openables: `Config.lua`
- XP Bar child pages Global, Experience, Reputation, and Delves: `xpbar_config.lua`
- Root slash routing and global reset/default initialization: `Core.lua`
- Defaults and runtime consumers: the corresponding module engines listed above
- Standalone legacy help: `Help.lua`

### OUS2

- Shell, page registration, footer reset, media/color dialogs, navigation, and sidebar: `Config2/OUS2Config.lua`
- Theme and numeric control infrastructure: `Config2/OUS2Theme.lua`, `Config2/OUS2ScaleControl.lua`
- Dashboard/global options: `Config2/OUS2Page_General.lua`
- Module pages: `Config2/OUS2Page_Utilities.lua`, `OUS2Page_Openables.lua`, `OUS2Page_StatsBar.lua`, `OUS2Page_AutoRemount.lua`, `OUS2Page_FishingTracker.lua`, `OUS2Page_FlightMaster.lua`, `OUS2Page_FlightRouting.lua`, `OUS2Page_FasterLoot.lua`, `OUS2Page_Toolbox.lua`, `OUS2Page_XPBar.lua`, and `OUS2Page_Delves.lua`
- Read-only pages: `Config2/OUS2Page_Help.lua`, `Config2/OUS2Page_Changelog.lua`

Both systems operate on the same module-owned defaults and runtime helpers. Similar labels were not treated as proof of parity; handlers and reset targets were compared.

## Classification and Count Summary

`Enable Openables` is rendered twice in legacy `/ous` against the same key and conceptual capability. There are 111 visible legacy control instances but 110 distinct settings/actions. The duplicate is counted once, as required.

| Classification | Count |
|---|---:|
| Total distinct legacy settings/actions audited | 110 |
| A. FULL PARITY | 87 |
| B. PRESENT — BEHAVIOR DIFFERS | 16 |
| C. LEGACY-ONLY — MISSING FROM OUS2 | 0 |
| D. INTENTIONALLY OMITTED | 1 |
| E. OBSOLETE / NO LONGER APPLICABLE | 0 |
| F. OUS2 EQUIVALENT VIA DIFFERENT UI | 6 |
| G. UNKNOWN | 0 |
| OUS2-only functional settings/actions | 16 |

## Master Legacy-First Parity Table

Abbreviations: `A` full parity; `B` present but behavior differs; `C` legacy-only missing; `D` intentionally omitted; `F` equivalent through different UI. `—` means that a default or reset comparison is not applicable to the action itself. Persistent defaults in the Notes column are the legacy/module defaults and are also what OUS2 displays or resets to unless a difference is stated.

### General and Module Toggles (9)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| General | Enable Flight Master | `OdysseusDB.modules.flightMaster` | Enable Flight Master on Flight Master page | Same path through `OUS.SetFlightMasterEnabled()` | B | Yes (`true`) | No | Yes | Implemented and user-validated 2026-09-12. Legacy writes only the key; OUS2 also immediately cleans up active UI/state when disabled and reapplies settings when enabled. |
| General | Enable Faster Loot | `OdysseusDB.modules.fasterLoot` | Read-only status on Faster Loot page | Same key, read only | D | — | No | No control | **HIGH.** Default `true`; page documents omission pending a cleanup-aware public setter. |
| General | Enable Fishing Tracker | `OdysseusDB.modules.fishingTracker` | Enable Module | Same path | B | Yes (`true`) | No | Yes | **HIGH.** Legacy central toggle only writes the DB; OUS2 also performs immediate tracker visibility/update work. |
| General | Enable Exp & Rep Bar | `OdysseusDB.modules.xpBar` | Enable Module | Same path | B | Yes (`true`) | No | Yes | **HIGH.** OUS2 immediately updates bar visibility; legacy central toggle is DB-only. |
| General | Enable Stats Bar | `OdysseusDB.modules.statsBar` | Enable Module | Same path | B | Yes (`true`) | No | Yes | **HIGH.** OUS2 immediately updates Stats Bar state; legacy central toggle is DB-only. |
| General | Enable Openables (shown in General and again on Openables page) | `OdysseusDB.modules.openables` | Enable Module on Openables page | Same path | F | Yes (`true`) | Yes | Yes | One conceptual setting; OUS2 consolidates the duplicate legacy placements. Both active page handlers update display. |
| General | Enable Utilities | `OdysseusDB.modules.utilities` | Enable Module | Same path | A | Yes (`true`) | Yes | Yes | Both are direct writes; module behavior is event gated. |
| General | Enable Toolbox | `OdysseusDB.modules.toolbox` | Enable Toolbox on Toolbox page | Same path through `OUS.SetToolboxEnabled()` | B | Yes (`true`) | No | Yes | Implemented and user-validated 2026-09-12. Legacy intentionally remains DB-only; OUS2 immediately hides/initializes runtime UI while preserving the separate saved `.shown` state. |
| General | Reset All Settings | Calls `OUS.ResetAllSettings()` after `ODYSSEUS_CONFIRM_WIPE_ALL` | Footer Reset to Defaults opens `ODYSSEUS_CONFIRM_WIPE_ALL` | Same confirmation and reset function | A | Yes | Yes | Yes | Corrected 2026-09-11; Cancel does nothing and Accept reaches the unchanged global reset callback. |

### Flight Master (15)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Flight Master | Unlock / Lock Timer Bar | session `OUS.isFlightBarUnlocked` | Unlock / Lock Timer | Same session state through public helper | A | — | Yes | — | Session-only edit state. |
| Flight Master | Show Map Tooltips | `OdysseusDB.flightSettings.showTooltips` | Show Map Tooltips | Same path | A | Yes (`true`) | Yes | **No** | **MEDIUM reset risk:** legacy Reset Defaults resets this; OUS2 Reset Appearance preserves it. |
| Flight Master | Bar Texture | `.textureName` | Bar Texture | Same path | A | Yes (`Blizzard`) | Yes | Yes | Same media library and runtime apply path. |
| Flight Master | Bar Width | `.width` | Bar Width | Same path | B | Yes (`200`) | No | Yes | **MEDIUM.** Legacy calls raw `SetWidth`; OUS2 calls `ApplyFlightSettings()`, which folds scale into dimensions. |
| Flight Master | Bar Height | `.height` | Bar Height | Same path | B | Yes (`20`) | No | Yes | **MEDIUM.** Same engine-model difference as width. |
| Flight Master | Bar Scale | `.scale` | Bar Scale | Same path | B | Yes (`1.0`) | No | Yes | **MEDIUM.** Legacy calls `timerBar:SetScale`; current OUS2/runtime keeps parent scale `1` and scales layout dimensions. |
| Flight Master | Font Size | `.fontSize` | Font Size | Same path | A | Yes (`12`) | Yes | Yes | Public apply helper reaches current dimension/font model. |
| Flight Master | Export Flight Data | reads `.times` | Export Flight Data copy dialog | reads same data | F | — | Yes | — | Same export capability; OUS2 uses the shared copy-text dialog. |
| Flight Master | Wipe Saved Data | `.times = {}` after confirmation | Wipe Data | Same path | A | — | Yes | — | Learned flight times are the separate destructive target. |
| Flight Master | Bar Font | `.fontName` | Bar Font | Same path | A | Yes (`Friz Quadrata TT`) | Yes | Yes | Same LibSharedMedia value. |
| Flight Master | Bar Border | `.borderName` | Bar Border | Same path | A | Yes (`None`) | Yes | Yes | Same LibSharedMedia value. |
| Flight Master | Border Size | `.borderSize` | Border Size | Same path | A | Yes (`16`) | Yes | Yes | Same runtime apply helper. |
| Flight Master | Bar Color | `.color` | Bar Color | Same path | A | Yes (`1,0.7,0`) | Yes | Yes | Same table is edited in place. |
| Flight Master | Border Color | `.borderColor` | Border Color | Same path | A | Yes (white fallback) | Yes | **No** | **MEDIUM reset risk:** legacy `flightDefaults` does not include this key and preserves it; OUS2 Reset Appearance resets it to white. |
| Flight Master | Reset Defaults | copies `OUS.flightDefaults` | Reset Appearance (plus separate Reset Position) | same settings table | B | **No scope match** | No | No | **MEDIUM.** Legacy resets `showTooltips` and preserves `borderColor`; OUS2 does the reverse for those two fields. |

### Fishing Tracker (6)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Fishing Tracker | Auto-close when not fishing or AFK | `OdysseusDB.fishingSettings.autoCloseInactive` | Auto-close When Inactive | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Fishing Tracker | Auto-close when mounted/skyriding | `.autoCloseMounted` | Auto-close When Mounted | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Fishing Tracker | Auto-close Delay | `.autoCloseDelay` | Auto-close Delay | Same path | A | Yes (`30`) | Yes | Yes | Range `10–60`. |
| Fishing Tracker | Frame Transparency | `.alpha` | Frame Transparency | Same path | A | Yes (`0.95`) | Yes | Yes | Immediate alpha refresh. |
| Fishing Tracker | Wipe Saved Data | `OdysseusFishingDB` history | Wipe Saved Data | Same history DB | A | — | Yes | — | Confirmation retained; settings are not wiped. |
| Fishing Tracker | Reset Defaults | `OUS.fishingDefaults` | Reset Defaults | Same settings table/defaults | A | Yes | Yes | Yes | Position/history scope remains distinct. |

### Auto Remount (10)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Auto Remount | Enable Auto Remount | `OdysseusDB.autoRemount.enabled` | Enable Auto Remount | Same path | A | Yes (`true`) | Yes | Yes | Feature setting, separate from module load toggle. |
| Auto Remount | Skip Druid Travel Form | `.skipDruid` | Skip Druid Travel Form | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Auto Remount | Silent mode | `.silent` | Silent Mode | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Auto Remount | Debug mode | `.debug` | Debug Mode | Same path | A | Yes (`false`) | Yes | Yes | Module-local diagnostics setting. |
| Auto Remount | Spy mode | `.spyMode` | Spy Mode | Same path | A | Yes (`false`) | Yes | Yes | Same chat-observation behavior. |
| Auto Remount | Open Spy Frame | action | Open Spy Frame | same runtime frame | A | — | Yes | — | OUS2 delegates to the existing frame. |
| Auto Remount | Remount Delay | `.delay` | Remount Delay | Same path | A | Yes (`0.5`) | Yes | Yes | Same numeric setting. |
| Auto Remount | Clear Character Mount | `OdysseusCharDB.autoRemountChar.mountID` | Clear Character Mount | Same path | A | — | Yes | Yes | Clears only per-character selection. |
| Auto Remount | Clear Account Mount | `OdysseusDB.autoRemount.accountMountID` | Clear Account Mount | Same path | A | — | Yes | Yes | Clears only account selection. |
| Auto Remount | Reset Defaults | account settings and character selection | Reset Defaults | same account/character paths | A | Yes | Yes | Yes | Same broad module scope. |

### Utilities (10)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Utilities | Enable Rare Announcer | `OdysseusDB.utilities.rareEnabled` | Enable Rare Announcer | Same path | A | Yes (`true`) | Yes | Yes | `/ous_rare` remains the announce action in both systems. |
| Utilities | Enable Auto Repair | `.repairEnabled` | Enable Auto Repair | Same path | A | Yes (`true`) | Yes | Yes | Event-driven merchant behavior unchanged. |
| Utilities | Use Guild Repair first | `.guildRepair` | Use Guild Repair First | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Utilities | Announce repair cost in chat | `.announceRepair` | Announce Repair Cost | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Utilities | Enable Junk Seller | `.junkSell.enabled` | Enable Junk Seller | Same path | A | Yes (`true`) | Yes | Yes | Existing merchant queue semantics retained. |
| Utilities | Require Shift to sell | `.junkSell.requireShift` | Require Shift to Sell | Same path | A | Yes (`false`) | Yes | Yes | Direct persistent setting. |
| Utilities | Announce junk sale in chat | `.junkSell.announceJunk` | Announce Junk Sale | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Utilities | Limit to 12 items per batch | `.junkSell.limitTo12` | Limit to 12 Items | Same path | A | Yes (`true`) | Yes | Yes | Direct persistent setting. |
| Utilities | Manage Blacklist | opens Junk Seller blacklist frame | Manage Blacklist | same runtime frame/data | A | — | Yes | — | OUS2 delegates rather than duplicating list storage. |
| Utilities | Hide Blizzard Artwork | `.hideExtraActionArtwork` | Hide Blizzard Artwork | Same path | A | Yes (`false`) | Yes | Yes | Both call the established safe apply helper; combat deferral remains runtime-owned. |

### Stats Bar (7)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Stats Bar | Table mode (vertical layout) | `OdysseusCharDB.statsBar.tableEnabled` | Table View | Same path | A | Yes (`false`) | Yes | Yes | Per-character setting. |
| Stats Bar | Lock single-line bar position | `OdysseusDB.statsBar.locked` | Lock Single-line Bar | Same path | A | Yes (`false`) | Yes | Yes | Same public lock helper. |
| Stats Bar | Lock table position | `.tableLocked` | Lock Table | Same path | A | Yes (`false`) | Yes | Yes | Same public lock helper. |
| Stats Bar | Font Size | `.fontSize` | Font Size | Same path | A | Yes (`12`) | Yes | Yes | Range `8–24`. |
| Stats Bar | Table Width | `.tableWidth` | Table Width | Same path | A | Yes (`150`) | Yes | Yes | Same layout update. |
| Stats Bar | Single-line Template | `OdysseusCharDB.statsBar.template` | Single-line Template | Same path | B | Yes (`{ilvl} | {spec}`) | No | Yes | **LOW.** Legacy commits on Enter; OUS2 also commits on focus loss. |
| Stats Bar | Reset Defaults | account and character Stats Bar settings/positions | Reset Defaults | same paths | A | Yes | Yes | Yes | OUS2 adds confirmation without reducing capability. |

### Openables (6 distinct settings/actions beyond the duplicated module toggle)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Openables | Auto-open on bag update | `OdysseusDB.openables.autoOpen` | Auto-open on Bag Update | Same path | A | Yes (`false`) | Yes | Yes | Both refresh display immediately. |
| Openables | Button Scale | `.scale` | Button Scale | Same path | A | Yes (`1.0`) | Yes | Yes | Same saved value and live layout result. |
| Openables | Reset Button Position | `.point/.relPoint/.x/.y` | Reset Position | Same paths | A | Yes | Yes | Yes | Same container position target. |
| Openables | Clear All Blacklist | `.blacklist = {}` | Clear Blacklist | Same path | A | — | Yes | — | Confirmation and display refresh retained. |
| Openables | Export DB | reads `.customItems` | Export Custom DB | same data | A | — | Yes | — | Copy presentation differs cosmetically only. |
| Openables | Wipe Custom DB | `.customItems = {}` | Wipe Custom DB | Same path | A | — | Yes | — | Confirmation and display refresh retained. |

### XP Bar — Global (13)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| XP Global | Global Font Size | `OdysseusDB.xpBar.xpFontSize` | Global Font Size | Same path | A | Yes (`15`) | Yes | Yes | Range `8–32`. |
| XP Global | Hide Default Blizzard UI | `.hideBlizz` | Hide Default Blizzard UI | Same path | B | Yes (`true`) | No | Yes | **MEDIUM.** Legacy disables the checkbox in instances; OUS2 intentionally leaves it usable. Both use the reload/apply flow. |
| XP Global | Enable Auto-Hide / Mouseover Engine | `.autoHide` | Enable Auto-Hide | Same path | A | Yes (`false`) | Yes | Yes | Same wake/sleep engine. |
| XP Global | Abbreviate Numbers | `.shortNumbers` | Abbreviate Numbers | Same path | A | Yes (`true`) | Yes | Yes | Same formatting consumer. |
| XP Global | Auto-Switch Display Time | `.repDisplayTime` | Reputation Display Time | Same path | A | Yes (`15`) | Yes | Yes | Range `5–60`. |
| XP Global | Auto-Hide Fade Delay | `.fadeDelay` | Fade Delay | Same path | A | Yes (`5`) | Yes | Yes | Range `0–60`. |
| XP Global | Global Font | `.xpFont` | Global Font | Same path | A | Yes (`Friz Quadrata TT`) | Yes | Yes | Same LibSharedMedia value. |
| XP Global | Active Opacity (%) | `.activeAlpha` | Active Opacity (fractional UI) | Same percent path through conversion | B | Yes (`100`) | Yes after conversion | Yes | **LOW.** OUS2 presents `0.10–1.00` but persists legacy percentage units. |
| XP Global | Faded Opacity (%) | `.fadedAlpha` | Faded Opacity (fractional UI) | Same percent path through conversion | B | Yes (`0`) | Yes after conversion | Yes | **LOW.** OUS2 presents fractional alpha but persists legacy percentage units. |
| XP Global | Bar Border Style | `.barBorderName` | Bar Border Style | Same path | A | Yes (`Blizzard Tooltip`) | Yes | Yes | Same media value. |
| XP Global | Border Color | `.barBorderColor` | Border Color | Same path | A | Yes (`0.6,0.2,0.8`) | Yes | Yes | Same table and apply helper. |
| XP Global | Bar Border Size | `.barBorderSize` | Border Size | Same path | A | Yes (`8`) | Yes | Yes | Same range and apply helper. |
| XP Global | Reset Defaults | resets all Global display and border fields | Reset Display + Reset Border | same keys split by section | F | Yes | Yes | Via two actions | Same resulting values require two explicit OUS2 actions. |

### XP Bar — Experience (10)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| XP Experience | Text Format | `OdysseusDB.xpBar.xpTemplate` | Experience Text Format | Same path | B | Yes | No | Yes | **LOW.** Legacy commits on Enter; OUS2 also commits on focus loss. |
| XP Experience | Main EXP Bar color | `.xpColor` | Experience Bar Color | Same path | A | Yes (`0.7,0.4,1.0`) | Yes | Yes | Same live bar update. |
| XP Experience | Text Color | `.xpTextColor` | Experience Text Color | Same path | A | Yes (white) | Yes | Yes | Same table. |
| XP Experience | Rested Bar color | `.restColor` | Rested Bar Color | Same path | A | Yes (`0.3,0.6,1.0`) | Yes | Yes | Same table. |
| XP Experience | Background color | `.bgColor` | Background Color | Same path | A | Yes (`0.07,0.05,0.1`) | Yes | Yes | Same background apply helper. |
| XP Experience | Main Bar Width | `.xpBarWidth` | Experience Bar Width | Same path | A | Yes (`650`) | Yes | Yes | Range `100–1000`. |
| XP Experience | Main Bar Height | `.xpBarHeight` | Experience Bar Height | Same path | A | Yes (`25`) | Yes | Yes | Range `10–100`. |
| XP Experience | Main Bar Scale | `.xpBarScale` | Experience Bar Scale | Same path | A | Yes (`1.0`) | Yes | Yes | Range `0.5–2.0`. |
| XP Experience | Show `Zzzz` Icon when Resting | `.showRestIcon` | Show Rested Icon under Global | Same path | F | Yes (`true`) | Yes | Yes | Capability moved to a different OUS2 section. |
| XP Experience | Reset Defaults | Experience display keys only | Reset Experience | same keys | A | Yes | Yes | Yes | Position remains preserved in both scoped resets. |

### XP Bar — Reputation (16)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| XP Reputation | Text Format | `OdysseusDB.xpBar.repTemplate` | Reputation Text Format | Same path | B | Yes | No | Yes | **LOW.** Legacy commits on Enter; OUS2 also commits on focus loss. |
| XP Reputation | Rep Text Color | `.repTextColor` | Reputation Text Color | Same path | A | Yes (white) | Yes | Yes | Same table. |
| XP Reputation | Hated color | `.repColors.hated` | Hated | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Hostile color | `.repColors.hostile` | Hostile | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Unfriendly color | `.repColors.unfriendly` | Unfriendly | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Neutral color | `.repColors.neutral` | Neutral | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Friendly color | `.repColors.friendly` | Friendly | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Honored color | `.repColors.honored` | Honored | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Revered color | `.repColors.revered` | Revered | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Exalted color | `.repColors.exalted` | Exalted | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Renown color | `.repColors.renown` | Renown | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Paragon color | `.repColors.paragon` | Paragon | Same path | A | Yes | Yes | Yes | Same color table. |
| XP Reputation | Enable Renown & Paragon Reward Popups | `.toastEnabled` | Reward Popups | Same path | A | Yes (`true`) | Yes | **No** | **MEDIUM reset risk:** legacy Reputation reset resets it; OUS2 Reputation reset preserves it. |
| XP Reputation | Play Sound on Reward Popup | `.toastSound` | Reward Popup Sound | Same path | A | Yes (`false`) | Yes | **No** | **MEDIUM reset risk:** legacy reset resets it; OUS2 preserves it. |
| XP Reputation | Right-Click Modifier for Faction Menu | `.repMenuMod` | four explicit modifier buttons | Same path | F | Yes (`CTRL`) | Yes | Yes | Legacy cycles one button; OUS2 directly selects CTRL/SHIFT/ALT/NONE. |
| XP Reputation | Reset Defaults | resets template, text/standing colors, toast flags, modifier | Reset Reputation | same table, narrower key set | B | No scope match | No | No | **MEDIUM.** OUS2 omits `toastEnabled` and `toastSound`; Favorites are correctly preserved by both interpretations. |

### Delves (8)

| Module | Legacy Setting / Action | Legacy Key / Path | OUS2 Equivalent | OUS2 Key / Path | Class | Default Match? | Behavior Match? | Reset Match? | Notes / Risk |
|---|---|---|---|---|---|---|---|---|---|
| Delves | Companion Text Format | `OdysseusDB.xpBar.delveCompTemplate` | Companion Text Format | Same path | A | Yes | Yes | Yes | Same token engine. |
| Delves | Journey Text Format | `.delveJourTemplate` | Journey Text Format | Same path | A | Yes | Yes | Yes | Same token engine. |
| Delves | Companion Color | `.delveCompColor` | Companion Color | Same path | A | Yes (`0.8,0.4,0`) | Yes | Yes | Same table. |
| Delves | Journey Color | `.delveJourColor` | Journey Color | Same path | A | Yes (`0,0.6,0.8`) | Yes | Yes | Same table. |
| Delves | Delve Bar Width | `.delveBarWidth` | Delve Bar Width | Same path | A | Yes (`300`) | Yes | Yes | Range `100–1000`. |
| Delves | Delve Bar Height | `.delveBarHeight` | Delve Bar Height | Same path | A | Yes (`40`) | Yes | Yes | Range `20–100`, step `2`. |
| Delves | Delve Bar Scale | `.delveBarScale` | Delve Bar Scale | Same path | A | Yes (`1.0`) | Yes | Yes | Range `0.5–2.0`. |
| Delves | Reset Defaults (includes position) | display keys plus `.delveBarPos` | Reset Defaults + Reset Position | same keys split across actions | F | Yes | Yes | Via two actions | Same total capability through two scoped OUS2 actions. The Cursed Keepsake runtime ID is unrelated. |

## Risk-Prioritized Non-Parity Findings

### HIGH

1. Deliberately omitted Faster Loot module toggle. The missing lifecycle-safe setter is explicitly acknowledged in OUS2.
2. Flight Master, Toolbox, Fishing Tracker, XP Bar, and Stats Bar module-toggle handlers are not equivalent: OUS2 applies immediate runtime cleanup, initialization, visibility, or update side effects while the legacy General controls only write their module keys. This needs a deliberate lifecycle decision, not an assumption of parity.

### MEDIUM

1. Flight Master width, height, and scale reach the current dimension-scaling engine through OUS2, while legacy calls raw frame setters.
2. Flight Reset Defaults and OUS2 Reset Appearance have different key scopes: `showTooltips` versus `borderColor`.
3. Reputation Reset Defaults in OUS2 omits the legacy reset of `toastEnabled` and `toastSound`.
4. XP Bar's Hide Blizzard UI checkbox has different availability semantics inside instances.

### LOW

1. XP active/faded opacity is displayed fractionally in OUS2 but converted to the same legacy percentage paths.
2. XP and Reputation templates, and the Stats Bar template, also commit on focus loss in OUS2 instead of Enter only.
3. Six capabilities use different UI placement/presentation: duplicate Openables toggle consolidation, Flight export dialog, split XP Global reset, moved Rested Icon setting, explicit Reputation modifier buttons, and split Delves reset.

## Special-Area Findings

### General / Module Toggles

All eight legacy module keys were traced. Openables and Utilities have material parity. The previously missing Flight Master and Toolbox toggles are now present through lifecycle-safe setters and passed user runtime validation. Faster Loot is deliberately read-only. Flight Master, Toolbox, Fishing Tracker, XP Bar, and Stats Bar write the same paths/defaults but have different live side effects. Toolbox's improved OUS2 lifecycle is intentional; legacy remains unchanged. No dependency or alternate SavedVariable path was found.

### Reset Defaults

- The global reset target and confirmation boundary are now shared. The audit-discovered OUS2 bypass was corrected on 2026-09-11 without changing `OUS.ResetAllSettings()`.
- User runtime validation found a pre-existing shared Retail reload issue after confirmation: both OUS2 and legacy reset the settings, but `C_Timer.After(0.5, ReloadUI)` produced `ADDON_ACTION_BLOCKED` and did not reload the UI.
- `Core.lua` now calls `C_UI.Reload()` synchronously at the end of the confirmed user-action path. The user retested both OUS2 and legacy reset flows successfully; both now complete the existing reset and reload without the observed blocked-action error. The historical reason for introducing the old timer is unknown.
- Flight reset scopes differ for `showTooltips` and `borderColor`.
- Reputation reset scopes differ for the two toast fields.
- XP Global and Delves provide the same aggregate capability through split OUS2 actions.
- Fishing history, Flight learned data, Openables lists, and Auto Remount selections were checked separately from ordinary defaults.

### Position / Lock / Visibility

- No legacy `/ous` Reset Position or Lock action is missing.
- Openables Reset Button Position has direct parity.
- Flight timer unlock has direct parity; OUS2 additionally offers Reset Position.
- Delves legacy position reset is available through OUS2's separate Reset Position action, and OUS2 adds a session-only Lock/Unlock Frame control.
- XP/Rep frame movement remains shift-drag runtime behavior; legacy `/ous` does not expose separate position buttons for those frames.
- Stats Bar lock controls have parity. Fishing Tracker legacy `/ous` has no lock/reset-position control; OUS2 adds Show/Hide only.

### Color / Media / Border

Every legacy color, font, texture, border style, border size, alpha, dimension, scale, and text-template value maps to the same underlying path. No persistent default-value mismatch was found. Differences are handler/reset scope or UI-unit differences documented in the table, not missing capability.

### Favorites / List Management

- Legacy `/ous` does not contain a Favorites-management control; the selector is opened from the XP Bar runtime modifier gesture. OUS2 adds a safe selector-opening action and writes no separate list format.
- Openables blacklist/custom-list management continues to use `OdysseusDB.openables.blacklist` and `.customItems`; OUS2 adds direct manager-opening and mass-add actions.
- Utilities uses the existing Junk Seller blacklist manager and storage.
- No legacy list reorder control or additional conditional list setting was found.

### Hidden / Conditional Controls

No class-, spec-, or profession-only legacy `/ous` control exists. The only functional availability condition found is the legacy XP `hideBlizz` checkbox being disabled in instances. Lazy-created export/manager frames and action buttons were included. Faster Loot and Flight Routing informational text was not counted as a setting.

### SavedVariable Paths and Defaults

All mapped persistent/action capabilities use the same underlying SavedVariable or runtime data target; none uses a migrated shadow path or compatibility alias. No class-C missing item remains, and the intentionally omitted Faster Loot control is read-only. No individual persistent default mismatch was found. The material differences are reset key scope and handler side effects.

## OUS2-Only Functional Settings and Actions (16)

Navigation, Back, Close, shell-window Lock/Unlock, read-only Help/Changelog, counts, and informational status text are excluded unless they invoke module functionality.

| # | OUS2-only control | Classification | Notes |
|---:|---|---|---|
| 1 | Show Minimap Button | Intentional enhancement | Broker/LibDBIcon visibility through Core helper. |
| 2 | Enable Debug Logging | Intentional enhancement | Global persistent debug toggle. |
| 3 | Fishing Tracker Show/Hide | New module capability | Explicit runtime visibility action. |
| 4 | Openables Lock/Unlock | New module capability | Persists `.locked`; legacy config has no control. |
| 5 | Openables Open Blacklist | Intentional enhancement | Opens existing manager. |
| 6 | Openables Open Custom List | Intentional enhancement | Opens existing manager. |
| 7 | Openables Mass Add | Intentional enhancement | Opens existing batch-entry frame. |
| 8 | Openables Show Status | Intentional enhancement | Invokes existing status action. |
| 9 | Toolbox Show/Hide | New module capability | Runtime frame visibility, not module enable. |
| 10 | Toolbox Lock/Unlock | New module capability | Public Toolbox helper. |
| 11 | Toolbox Direction | New module capability | Horizontal/vertical layout. |
| 12 | Toolbox Scale | New module capability | Public dimension-scaling helper. |
| 13 | Toolbox Reset Position | New module capability | Public position helper. |
| 14 | XP Favorites selector action | Intentional enhancement | Opens existing selector; `favFactions` remains user-curated data. |
| 15 | Delves Lock/Unlock Frame | New module capability | Session-only edit state. |
| 16 | Flight Master Reset Position | Intentional enhancement | Split from appearance reset. |

The standalone Delves Reset Position button is not counted again as OUS2-only because it is one half of the legacy combined reset capability.

## Retirement Readiness

**C. NO — material parity blockers remain.**

Exact blockers:

1. Faster Loot enable/disable is intentionally unavailable pending a safe public setter.
2. Flight Master and Reputation reset-scope differences require implementation or an explicit product decision.
3. Four module-toggle live-side-effect differences still require a documented lifecycle decision. Toolbox's behavior difference is intentionally accepted and user-validated: OUS2 applies immediate lifecycle handling while legacy remains DB-only.

## Minimum Future Patch Set

1. **Implemented and user-validated 2026-09-12:** add a lifecycle-safe Flight Master module setter and route an OUS2 toggle through it. The loaded event-driven module does not require reload; disabling during an active taxi abandons that measurement, and subsequent new taxis operate normally after re-enabling.
2. Add a cleanup-aware Faster Loot public setter, then expose the currently withheld OUS2 toggle.
3. **Implemented and user-validated 2026-09-12:** add a lifecycle-safe Toolbox module setter and OUS2 toggle. Module disable preserves the separate saved shown/hidden state, and re-enable creates or restores the runtime without requiring reload. The user intentionally accepted this OUS2 improvement without changing legacy's DB-only handler.
4. Decide and document whether Flight Reset Appearance should reset `showTooltips`, whether it should preserve `borderColor`, and whether Reputation reset should include both toast flags.
5. Normalize or explicitly document the intended live behavior for Fishing Tracker, XP Bar, and Stats Bar module toggles.
6. Re-run the setting-level audit after those decisions. Do not retire `/ous` before that re-audit passes.

No other parity finding is implemented by the 2026-09-11 reset-gate correction.

## Documentation Mismatches Corrected by This Re-audit

The 2026-07-10 version of this document said the OUS2 master reset was absent and intentionally rejected. The setting-level audit found that current source instead contained an immediate footer action and recorded its missing confirmation. That confirmation gap was corrected on 2026-09-11 while preserving the historical finding. The older document also described OUS2 as functionally complete despite the module-toggle gaps and did not record the Flight/Reputation reset scopes. Those claims are superseded above. `Documentation/TODO_v2.md` also contains stale follow-up wording for some already-present General/dashboard features; this audit does not edit that separate historical planning file.

## Validation Record

- Original setting-level audit: full document readback and overbroad-wording review passed at the documentation checkpoint.
- Master-table recount after the 2026-09-12 Toolbox toggle implementation: 110 rows; `A=87`, `B=16`, `C=0`, `D=1`, `F=6`; 16 OUS2-only rows. User runtime validation passed for saved module state, immediate disable cleanup, saved shown/hidden restoration, separate Show/Hide behavior, reload-free re-enable, retained lock/direction/scale/position behavior, and legacy/OUS2 SavedVariable synchronization. No Lua errors occurred. Legacy's DB-only runtime behavior is intentionally unchanged.
- Reset confirmation and shared Retail reload correction: user runtime validation passed for both OUS2 and legacy `/ous`; static and Git validation is recorded in the implementation report.

## Integrity Statement

This audit began as a documentation-only checkpoint. The 2026-09-11 correction changed only the OUS2 global-reset click gate, the shared reset path's reload invocation, and synchronized audit text. The 2026-09-12 Flight Master and Toolbox parity patches add only their OUS2 controls and module-local runtime setter/cleanup boundaries. These changes do not alter reset scope, SavedVariables schemas/defaults, TOC metadata, load order, tags, or releases.
