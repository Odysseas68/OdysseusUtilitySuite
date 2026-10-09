# OUS2 Architecture

## Purpose

This document defines the current OUS2 architecture, coding standards, UI layout, and migration plan for Odysseus Utility Suite.

OUS2 is the primary configuration and UI framework for OUS. The legacy `/ous` configuration files were retired on 2026-09-12 after setting parity and migration-plumbing validation; `/ous` now opens OUS2 and `/ous2` remains an alias.

---

## Current Status

Phase 4 module-page migration and the legacy configuration retirement are complete. Final user runtime validation passed with the legacy files absent and OUS2 active.

Phase 5.6 parity is complete for Auto Remount, Stats Bar, Fishing Tracker, Openables, Utilities, Help, and Changelog. Remaining XP Bar, Reputation, and Delves parity work is tracked separately in `Documentation\OUS2_XPBAR_PARITY.md`; do not duplicate that checklist here.

Implemented:

* `Config2\OUS2Theme.lua`
* `Config2\OUS2Config.lua`
* `Config2\OUS2ScaleControl.lua`
* `Config2\OUS2Page_General.lua`
* `Config2\OUS2Page_Utilities.lua`
* `Config2\OUS2Page_Openables.lua`
* `Config2\OUS2Page_StatsBar.lua`
* `Config2\OUS2Page_AutoRemount.lua`
* `Config2\OUS2Page_FishingTracker.lua`
* `Config2\OUS2Page_FlightMaster.lua`
* `Config2\OUS2Page_FlightRouting.lua`
* `Config2\OUS2Page_FasterLoot.lua`
* `Config2\OUS2Page_Toolbox.lua`
* `Config2\OUS2Page_XPBar.lua`
* `Config2\OUS2Page_Delves.lua`
* `Config2\OUS2Page_Help.lua`
* `Config2\OUS2Page_Changelog.lua`
* Manual NineSlice shell
* Left navigation panel
* Scrollable content area
* Help panel with `C.SetHelpText()` / `C.ClearHelpText()`
* Optional page-specific sidebar area
* Resizable frame with stable resize-anchor handling
* General dashboard visual page
* Completed pages: General, Utilities, Openables, Stats Bar, Auto Remount, Fishing Tracker, Flightmaster, Flight Routing, Faster Loot, Toolbox, XP Bar, Delves, Help, and Changelog
* Shared module card assets
* Shared dashboard card constants in `T.Card`
* Shared scale-control assets and sizing constants in `T.Scale`
* Reusable `C.CreateScaleControl()` widget
* Shared OUS2 media dropdown, color picker, and copy-text dialog helpers
* Openables scale-control integration
* Flightmaster OUS2 advanced controls
* Dedicated XP Bar parity planning document: `Documentation\OUS2_XPBAR_PARITY.md`

Phase 5 follow-up work:

* General page polish
* Enabled/disabled card states
* Module count summary
* Global Options functionality
* Reset semantics review
* XP Bar, Reputation, and Delves parity items tracked in `Documentation\OUS2_XPBAR_PARITY.md`
* Toolbox expansion
* Faster Loot rules
* Helper extraction

---

# Goals

## Primary Goals

- Modern Retail 12.0+ UI
- Consistent Midnight Arcane visual style
- Shared OUS2 UI framework
- Reduced duplicated UI code
- Easier module-page integration
- Safer future expansion
- Stable configuration architecture without rewriting working modules

## Secondary Goals

- Reusable page registration
- Sidebar help and page-specific sidebar content
- Reusable dashboard card visuals
- Searchable settings later
- Shared helper extraction after patterns stabilize
- Continued OUS2 polish and reusable-helper extraction

---

# Folder Structure

## Current Layout

OUS2 files live in `Config2\`.

```text
OdysseusUtilitySuite
│
├─ Config2\
│   ├─ OUS2Theme.lua          ← theme registry, colors, fonts, frame/card/scale constants
│   ├─ OUS2Config.lua         ← main OUS2 shell, nav, content, help/sidebar, resize
│   ├─ OUS2ScaleControl.lua    ← reusable numeric scale control
│   ├─ OUS2Page_General.lua
│   ├─ OUS2Page_Utilities.lua
│   ├─ OUS2Page_Openables.lua
│   ├─ OUS2Page_StatsBar.lua
│   ├─ OUS2Page_AutoRemount.lua
│   ├─ OUS2Page_FishingTracker.lua
│   ├─ OUS2Page_FlightMaster.lua
│   ├─ OUS2Page_FlightRouting.lua
│   ├─ OUS2Page_FasterLoot.lua
│   ├─ OUS2Page_Toolbox.lua
│   ├─ OUS2Page_XPBar.lua
│   ├─ OUS2Page_Delves.lua
│   ├─ OUS2Page_Help.lua
│   └─ OUS2Page_Changelog.lua
│
├─ media\
│   └─ Textures\
│       ├─ CardBG_Normal.tga
│       ├─ CardBG_Hover.tga
│       ├─ CardBG_Selected.tga
│       ├─ ScaleTrack.tga
│       ├─ ScaleFill.tga
│       ├─ ScaleThumb.tga
│       └─ all other OUS2 TGA assets flat in this folder
│
├─ Documentation\
│   ├─ ARCHITECTURE.md
│   ├─ TODO_v2.md
│   ├─ README_v2.md
│   ├─ OUS2_XPBAR_PARITY.md
│   └─ ASSET_PROMPTS_v2.md
│
└─ existing OUS module files remain flat in the addon root
```

All existing OUS module files remain in the addon root until a future restructure is explicitly approved.

## External Engineering Workspace

The shared engineering workspace is intentionally outside the World of Warcraft installation:

```text
D:\WoWDev
|
+-- Reference
|   +-- Blizzard
|   +-- ThirdParty
|   +-- Odysseus
|   +-- Research
|   L-- Scripts
|
+-- Python
L-- Tools
```

Rules:

- The WoW installation contains only runtime and game files.
- The engineering workspace lives under `D:\WoWDev`.
- The shared Reference workspace lives at `D:\WoWDev\Reference`.
- `D:\WoWDev\Reference` is read-only research material during normal OUS development.
- Production addon code must never load, require, include, or depend on files under `D:\WoWDev\Reference`.
- Use `D:\WoWDev\Reference\Blizzard\wow-ui-source\` for Retail API and FrameXML verification.
- Treat `D:\WoWDev\Reference\Odysseus\OdysseusBuffBarsTest\` and `D:\WoWDev\Reference\ThirdParty\ElkBuffBars\` as reference-only sources.
- Do not create addon-local `Reference` directories inside the WoW installation.
- Do not create NTFS junctions from the WoW installation to `D:\WoWDev`.

### Lessons Learned

While troubleshooting Battle.net update error `BLZBNTAGT00000841`, we confirmed that Battle.net may recursively traverse NTFS junction targets under the World of Warcraft installation during Update and Scan & Repair operations. Keeping development assets outside the WoW installation avoids permission/update failures and keeps runtime files separate from engineering research material.

**Texture path:**

```text
Interface\AddOns\OdysseusUtilitySuite\media\Textures\
```

All OUS2 texture assets are flat in that directory. There is no `Assets\` subdirectory.

---

# TOC Order

OUS2 currently loads after the standalone Help UI:

```text
Config2\OUS2Theme.lua
Config2\OUS2Config.lua
Config2\OUS2ScaleControl.lua
Config2\OUS2Page_General.lua
Config2\OUS2Page_Utilities.lua
Config2\OUS2Page_Openables.lua
Config2\OUS2Page_StatsBar.lua
Config2\OUS2Page_AutoRemount.lua
Config2\OUS2Page_FishingTracker.lua
Config2\OUS2Page_FlightMaster.lua
Config2\OUS2Page_FlightRouting.lua
Config2\OUS2Page_FasterLoot.lua
Config2\OUS2Page_Toolbox.lua
Config2\OUS2Page_XPBar.lua
Config2\OUS2Page_Delves.lua
Config2\OUS2Page_Help.lua
Config2\OUS2Page_Changelog.lua
```

Rules:

- `OUS2Theme.lua` loads before all OUS2 UI files.
- `OUS2Config.lua` creates the shell and `C.pageContainer`.
- OUS2 page files load after `OUS2Config.lua`.
- Additional page files should be added after `Config2\OUS2Config.lua`.
- Do not reorder existing module engines unless explicitly instructed.

---

# OUS2 Theme System

## OUS2Theme.lua

Namespace:

```lua
OUS.Theme
local T = OUS.Theme
```

Responsibilities:

- Texture root: `T.TEX`
- Asset registry: `T.Assets`
- Texture resolver: `T.Tex(key)`
- Main frame constants: `T.Frame`
- Scrollbar constants: `T.Scroll`
- Scale control constants: `T.Scale`
- Dashboard card constants: `T.Card`
- Colors: `T.Colors`
- Fonts: `T.Fonts`
- Icon display sizes: `T.Icons`

## Theme Rules

Use these helpers and constants in OUS2 files:

```lua
T.Tex("AssetKey")
T.Colors.*
T.Fonts.*
T.Frame.*
T.Scroll.*
T.Scale.*
T.Icons.*
T.Card.*
```

Do not hardcode texture paths, RGB values, or duplicated card/frame constants in page files.

## Dashboard Card Assets

The General dashboard uses shared card textures:

```lua
CardNormal   = "CardBG_Normal.tga"
CardHover    = "CardBG_Hover.tga"
CardSelected = "CardBG_Selected.tga"
```

Rules:

- Resolve card textures through `T.Tex("CardNormal")`, `T.Tex("CardHover")`, and `T.Tex("CardSelected")`.
- Do not hardcode filenames or full paths in page files.
- Keep card geometry identical across normal, hover, and selected states.
- Swap the background texture for state changes.
- Keep module icon, title, description, chevron, and future status text as Lua UI layers above the card art.
- Do not bake module-specific text or icons into card textures.

## Card Constants

`T.Card` stores reusable dashboard card values, currently:

```lua
T.Card = {
    Height      = 72,
    IconSize    = 32,
    ChevronSize = 14,
    Padding     = 10,
}
```

Use these values for dashboard cards instead of duplicating local magic numbers.

---

# OUS2 Shell Layout

## Three-Panel Shell

```text
┌─────────────────────────────────────────────────────────────────┐
│  [Lock Window]    Odysseus Utility Suite          [Close]       │
│                                                                 │
│  ┌────────────┬──────────────────────┬──────────┬────────────┐  │
│  │ LEFT NAV   │ CONTENT / PAGE AREA  │ SCROLL   │ HELP/SIDE  │  │
│  │            │                      │ BAR      │ PANEL      │  │
│  └────────────┴──────────────────────┴──────────┴────────────┘  │
│                         [Reset to Defaults] [Close]             │
└─────────────────────────────────────────────────────────────────┘
```

## Left Navigation

- Text-only buttons
- Custom button textures:
  - `Button_Normal.tga`
  - `Button_Hover.tga`
  - `Button_Selected.tga`
- Active button shows `TabIndicator.tga`
- Separator before Help and Changelog
- No nav icons for now
- Navigation panel background is visually transparent so the main frame art shows through

## Content Panel

- Contains a scroll frame and scroll child
- `C.pageContainer` is the scroll child
- Page frames are parented to `C.pageContainer`
- Pages use `SetAllPoints()` and are shown/hidden by the nav system

## Help Panel and Page Sidebar

The right panel has two responsibilities:

1. Persistent Help text area
2. Optional page-specific sidebar content

The help text remains available for all pages through:

```lua
C.SetHelpText(text)
C.ClearHelpText()
```

An optional sidebar container exists below the help text area:

```lua
C.sidebarContainer
```

Page files may register optional sidebar content through the expanded page registration pattern.

Rules:

- Do not permanently replace the Help panel.
- General may use the page-specific sidebar area for Global Options and Reset visual cards.
- Future module pages should continue to use Help text for hover descriptions.
- Page-specific sidebar frames are hidden and shown with their owning page.

---

# OUS2 Public API

Core OUS2 API:

```lua
OUS.Config2.RegisterPage(pageName, pageFrame, refreshFn, sidebarFrame)
OUS.Config2.OpenPage(pageName)
OUS.Config2.Toggle()
OUS.Config2.SetHelpText(text)
OUS.Config2.ClearHelpText()
```

Shared containers:

```lua
OUS.Config2.pageContainer
OUS.Config2.sidebarContainer
```

## RegisterPage

`RegisterPage()` accepts a required page frame and optional sidebar frame:

```lua
OUS.Config2.RegisterPage("General", pageFrame, Refresh, sidebarFrame)
```

Rules:

- `pageFrame` belongs to `C.pageContainer`.
- `sidebarFrame`, when provided, belongs to `C.sidebarContainer`.
- Only the active page frame is shown.
- Only the active page sidebar frame is shown.
- Inactive page and sidebar frames are hidden, not destroyed.

---

# Page Pattern

Each OUS2 page file should:

1. Start with the standard OUS file header.
2. Use `local addonName, OUS = ...`.
3. Alias `local T = OUS.Theme`.
4. Alias `local C = OUS.Config2`.
5. Create the page frame parented to `C.pageContainer`.
6. Call `SetAllPoints()` and `Hide()`.
7. Optionally create a sidebar frame parented to `C.sidebarContainer`.
8. Build UI using `T.Tex`, `T.Colors`, `T.Fonts`, `T.Frame`, `T.Scroll`, `T.Scale`, `T.Icons`, and `T.Card`.
9. Implement `Refresh()` for DB-backed state when functionality is added.
10. Register with `C.RegisterPage("PageKey", page, Refresh, sidebarFrame)`.
11. Add the page file to the TOC after `Config2\OUS2Config.lua`.

---

# OUS2 Resizable Frame Rules

The OUS2 shell is manually resizable from:

- right edge
- bottom edge
- bottom-right corner

Important resize rule learned from testing:

- Do not rely on a persistent `CENTER` anchor during `StartSizing()`.
- Before `StartSizing()`, capture the frame's current screen position.
- Re-anchor to `UIParent` using `TOPLEFT`.
- Call `StopMovingOrSizing()` before starting the new resize.
- Guard resize handlers when the frame is locked or hidden.
- Keep resize handles above content, sidebar, and page frames with explicit frame levels.
- Avoid overlap between resize handles and interactive footer buttons.
- After adding sidebars, overlays, or page containers, test resize from all handles.

This prevents the frame from jumping to maximum size during resize.

---

# General Page Dashboard

The General page is a dashboard, not a deep settings page.

Current General dashboard structure:

```text
┌──────────────────────────────────────────────────────┬──────────────┐
│ Header: General / OUS dashboard                      │ Help text    │
│ Divider                                              │              │
│                                                      │ Sidebar:     │
│ Modules section                                      │ Global       │
│ 3-column module card grid                            │ Options      │
│                                                      │              │
│ Wide Information panel                               │ Sidebar:     │
│                                                      │ Reset        │
└──────────────────────────────────────────────────────┴──────────────┘
```

## Module Card Grid

Current visual goal:

- 3-column grid
- 11 current modules
- Room for future modules
- Card contains:
  - module icon
  - module name
  - short wrapped description
  - chevron
- Uses `CardNormal` and `CardHover`
- `CardSelected` exists for future enabled/current/selected state work

Current modules represented:

- XP Bar
- Delves
- Flight Master
- Flight Routing
- Utilities
- Openables
- Stats Bar
- Auto Remount
- Faster Loot
- Fishing Tracker
- Toolbox

## Information Panel

The Information panel belongs below the module grid in the main dashboard area.

It should summarize:

- addon name
- version
- short description
- development status

## General Sidebar

The General page uses optional sidebar content for:

- Global Options
- Reset

Current Global Options are visual-only:

- Show Minimap Button
- Enable Debug Logging

Launcher/minimap compatibility uses a broker-compatible architecture through LibDataBroker-1.1 + LibDBIcon-1.0. Third-party minimap managers own broker launcher visibility and presentation, and OUS intentionally follows the standard broker implementation instead of adding HidingBar-specific or similar addon-specific workarounds.

Minimap launcher state lives in:

```lua
OdysseusDB.minimap = {
    hide = false,
    minimapPos = 225,
}
```

Legacy values migrate from `OdysseusDB.showMinimapButton` and `OdysseusDB.minimapAngle` during Core initialization.

Current Reset sidebar block is visual-only and explains reset behavior.

The footer-level Reset to Defaults button remains the actual shell-level action surface.

---

# Module Page Design

Current and future module pages follow this pattern:

```text
┌─────────────────────────────────────────────────────┐
│ [Icon] Module Name                    [Enabled]     │
│ ─────────────────────────────────────────────────── │
│                                                     │
│ Section Header                                      │
│ Setting rows                                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Rules:

- Module icon at top left
- Module enable toggle near top right
- Section headers use `Icon_SectionStar.tga`
- Dividers use `Divider_Horizontal.tga`
- Settings use hover help:
  - `C.SetHelpText(text)`
  - `C.ClearHelpText()`
- Wire settings only after their module toggle, live-update, and reset semantics are confirmed
- Completed module pages follow the shared registration, refresh, theme, and hover-help patterns

---

# AutoRemount Engine and Research Surfaces

This describes the implemented module in `AutoRemount.lua`, its keyed spell tables in `AutoRemountSpells.lua`, and the OUS2 actions in `Config2/OUS2Page_AutoRemount.lua`, included in release 1.0.8 (build 2026.10.09). The historical OUS2 migration/parity results remain intact.

## Production authority and interaction ownership

Spell precedence is deliberate: permanent explicit exclusion, built-in positive gathering database, mount filtering, harmful filtering, legacy custom spells, then unknown Spy processing. Built-in positive entries retain authority; an excluded, mount, or safely harmful spell cannot gain production authority merely by appearing in the custom list.

`C_Spell.IsSpellHarmful(spellIdentifier)` is a structural guard, not a complete semantic classifier. Only a successful, accessible boolean `true` is harmful. False, nil, inaccessible values, unavailable APIs, and API errors do not become positive harmful classifications.

Accepted built-in or eligible custom interactions advance `interactionSequence` and own `currentInteractionID`. The delayed no-loot fallback and LOOT_CLOSED remount callback capture that ID and return without state mutation or remount when a newer interaction supersedes it. This ownership is scoped to AutoRemount, not a general asynchronous framework. Existing combat, form, mounted/flying, dead/ghost, instance, and profession-UI safety checks remain in force.

## Spy lifecycle and review

Unknown candidates remain transient and never set production gathering/remount authority. The five-second timeout bounds the wait for **initial loot evidence**, not the entire loot session:

1. A qualifying unknown spell starts a pending candidate and timer.
2. The first LOOT_READY or LOOT_OPENED marks loot evidence and cancels that timer.
3. Only LOOT_CLOSED confirms the candidate. Closure without evidence clears it; no evidence within five seconds expires it.
4. Replacement, excluded/harmful/mount spells, disabling Spy, and combat end clear pending state. Timer identity checks prevent stale callbacks from mutating newer candidates.
5. Candidate admission respects the Spy filter; confirmation rechecks permanent exclusions and existing custom membership. A SpellID already in discoveredSpells is not inserted or announced again.

LOOT_READY allows confirmation through FasterLoot's fast path even when AutoRemount does not observe a visible LOOT_OPENED path. This is bounded association with loot, not a semantic proof that an unknown spell is gathering. The production no-loot fallback does not confirm Spy candidates.

Readable lifecycle debug output includes candidate started, replacement clearing, expired, confirmed, loot evidence, and relevant clearing reasons. Discovery chat announces only a newly stored SpellID: `Odysseus AutoRemount Spy: New spell discovered: <name> (<id>)`. The persistent Spy review/export frame has Refresh, Copy All, and confirmed Clear. Refresh rebuilds the display without changing discoveredSpells.

## Custom Spells management

Spy contains discovered unknown candidates; Custom Spells contains user-approved production triggers. Discovery never automatically promotes a spell to Custom Spells.

`/ar custom` opens the separate standalone Custom Spells window. It offers SpellID input, Add Spell (also Enter), icon/name/SpellID rows with Remove, and Clear All with confirmation. Names/icons have safe fallback handling. Existing `/ar add`, `/ar remove`, and `/ar wipe` remain supported and refresh the frame. Storage remains the numeric array `OdysseusDB.autoRemount.customSpells`; structural guards still apply to its entries. OUS2 Actions includes **Open/Add Custom Spells**.

## Audit window and snapshot boundaries

`/ar audit` opens **Odysseus AutoRemount — Audit**, one 800 × 560 movable/clamped DIALOG window with ESC close and a shared scroll/list area. The former `/ar harmfulaudit` is a hidden compatibility alias, absent from normal command help.

The top control row is **DB Audit | Spellbook | Talents | Refresh | Copy All | Close**. Compact standalone Midnight buttons use deep-purple backgrounds, purple/cyan borders, hover/pressed states, and a persistent selected-mode highlight; no large OUS2 Action artwork is used.

Switching mode refreshes that mode, updates context/summary/limitations/columns/rows/export, and resets scrolling. Refresh only re-queries the selected mode. Copy All exports the current snapshot as plain text through a native multiline EditBox, selects all for Ctrl+C, and returns to the same mode without another audit query. Snapshots live only in transient UI state; no SavedVariables, polling, or production authority are introduced.

Public helpers are `AR.ShowAuditFrame(mode)` and `AR.RefreshAuditFrame()`. The older exclusion-specific show/refresh helpers remain compatibility entry points. Names sort case-insensitively with SpellID as a secondary key; unresolved rows and distinct talent node/entry mappings remain identifiable.

| Mode | Fields | Meaning and limits |
|---|---|---|
| DB Audit | SpellID, Name, Harmful, Helpful, Mount, Self Buff, Active Aura Now | Scans the current explicit exclusion table; preserves classification/name failures as unresolved rather than negative results. Summary includes classifications, overlaps, unresolved names/fields, and diagnostic harmful/mount candidates. |
| Spellbook | SpellID, Name, Type, Passive, Harmful, Helpful, Self Buff | Known current-character player skill-line spells, deduplicated by SpellID. Summary/export includes character/class, classification totals, skipped slots, and query issues. |
| Talents | SpellID, Name, Node, Rank, Passive, Harmful, Helpful, Self Buff | Selected active entries and primary definition SpellIDs. Export also preserves Entry ID and active config ID/name; summary includes unmapped entries and query issues. |

DB classifications have explicit boundaries: no verified general static Buff/Aura classifier exists in the inspected Retail API surface. **Self Buff = No** does not mean “not a buff/aura.” **Active Aura Now = No** means no player aura was returned at refresh; it does not establish that the spell can never be an aura.

Spellbook uses `C_SpellBook.GetNumSpellBookSkillLines`, `GetSpellBookSkillLineInfo` (offset/item count), `GetSpellBookItemInfo` (type, exposed SpellID, passive/off-spec fields), and `IsSpellKnown`. Actual known spells are retained; future/off-spec/non-spell items are skipped. The scope is player skill-line entries only: the pet bank is separate, profession-specific offsets are not expanded, and flyout contents are not expanded. It is not exhaustive character ability enumeration; absence must not mean “not a class spell.”

Talents follows `C_ClassTalents.GetActiveConfigID` and `C_Traits.GetConfigInfo/GetTreeNodes/GetNodeInfo/GetEntryInfo/GetDefinitionInfo`. **Node ID, Entry ID, and SpellID are distinct identifiers.** Nodes can expose multiple entries; choice alternatives are not all selected. The collector retains committed selections and active ranked entries, skips inactive subtrees, and withholds snapshots with staged/unapplied edits using `ConfigHasStagedChanges`. For tier nodes with multiple committed entries, per-entry rank is shown only where the matching active entry exposes it; otherwise it remains unresolved.

A selected entry may lack a definition/primary SpellID and remains an unmapped research row. Passive status uses `C_Spell.IsSpellPassive`. Talent entries can be visible independently of ordinary Spellbook membership. Active non-passive abilities commonly appeared on both surfaces in the supplied runtime observations, but this is not a universal Blizzard guarantee. The exposed primary SpellID does not enumerate every secondary/internal effect or aura; PvP talents are outside this mode.

The implementation source audit inspected local LIVE build **12.1.0.69933**, commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`, including generated SpellBook, ClassTalents, and SharedTraits contracts and relevant Blizzard Lua/XML callers. Inaccessible or failed research queries remain explicitly unresolved.

## Minimal explicit exclusions

The legacy 153-entry exclusion database was progressively reduced after structural filtering and the bounded Spy lifecycle were validated. That table is historical/research context, not the current required exclusion set.

The current research configuration intentionally retains only **1234969 — Ethereal Augmentation**. The supplied runtime evidence attributes this aura to item **243191 — Ethereal Augment Rune**, which repeatedly caused persistent/noisy Spy behavior in gameplay. Keep exclusions minimal; add explicit entries only when actual runtime behavior demonstrates a need. Future Opening, Collecting, or other spells require investigation if they survive into persistent discoveries. This does not establish that no future exclusions will be needed.

## Retail 12.1.0 runtime evidence

The following records **user-reported in-game observations supplied for this synchronization**, separate from source review and mocks. The near-zero-exclusion experiment retained only Ethereal Augmentation.

| Tested scenario | Observed outcome |
|---|---|
| World/class gameplay | Harmful combat spells were structurally ignored. Utility/passive/non-gather candidates expired, were replaced, or cleared; no false persistent discovery resulted. |
| Opening with FasterLoot | Built-in 3365 Opening followed the production gather/loot/remount path; FasterLoot interoperability remained functional. |
| Fishing | Transient fishing-related SpellIDs became candidates, then were replaced/expired/cleared without false persistence. Fishing Tracker/FasterLoot interoperability remained functional. |
| Herbalism | 471009 Herb Gathering was detected; loot completed and the remount callback reached its safety check. Remount was correctly skipped when the character remained in a valid mounted/gather state. |
| Mining | 471013 Midnight Mining was detected; loot completed and the remount callback reached its safety check. Remount could correctly be skipped when already effectively mounted. |
| Raid/boss environment | Warlock harmful spells were ignored; utility/buff candidates expired or cleared. Environmental DNT effects and Demonic Gateway-related IDs did not persist. Boss loot through FasterLoot did not falsely confirm a stale unrelated candidate; the Spy frame remained clean after the raid test. |

With the exclusion table reduced from 153 entries to the one retained Ethereal Augmentation entry, these tested world, fishing, gathering, combat, raid, and loot scenarios produced **zero new persistent Spy discoveries**. The Spy frame remained clean apart from the already-known Ethereal Augmentation case. This result is bounded to the tested scenarios.

Runtime/user verification identified **111771 — Demonic Gateway** as the actual cast spell; observed **361652** and **113895** were associated with activation/use of the placed gateway. These are observed distinctions, not general Blizzard API rules.

Death occurred during the raid test, but there was no dedicated logged death-state assertion. **No specific death-handler validation PASS is claimed.** No stale candidate was observed later being falsely confirmed after the encounter transitions.

Spellbook and Talents modes were subsequently exercised in-game and returned real current-character data. A useful bounded example was **Hellbent Commander**: SpellID **1250897**, Node ID **110198**, Entry ID **136727**, rank **1**, Passive **Yes**. It appeared as a current player buff/aura and in Talents while absent from the ordinary Spellbook audit. This example does not establish a universal membership or aura-mapping rule.

## Separate static/mock validation record

At the audit-frame implementation stage, the standalone Lua 5.1 mocked harness passed **671 assertions**, Lua 5.1 syntax parsing exited **0**, targeted LuaCheck reported **0 warnings / 0 errors**, and `git diff --check` passed. That harness included the then-current 153-entry DB audit and existing production/Spy/Custom regressions.

Those results are static/mock evidence, not in-game validation, and were not rerun during this documentation-only synchronization. The later one-entry exclusion experiment and real Spellbook/Talent observations above are separate runtime evidence.

---

# Current Technical Debt

Known issues to resolve in focused patches:

1. Some modules do not consistently enforce the master `OdysseusDB.modules.*` toggle.
2. Utilities reset/master-toggle coverage still needs audit before relying on OUS2 reset semantics.
3. `/ous2` command ownership should be confirmed and kept unambiguous.
4. Flight data naming/casing should be reviewed:
   - tree shows `FlightData.lua`
   - old docs mention `flightdata.lua`
5. Flight timing data still uses legacy global access patterns.
6. Completed OUS2 module pages still require focused visual polish and in-game testing.
7. General page is still mostly visual-only.
8. `OUS2Utils.lua` is intentionally deferred until multiple pages reveal stable helper patterns.
9. `OUSBanner.tga` remains pending recreation.
10. Documentation should remain synchronized as Phase 5 polish and advanced controls evolve.

---

# Migration Plan

## Phase 1 — Foundation COMPLETE

Completed:

- OUS2ArtTest prototype
- Manual NineSlice validation
- Midnight Arcane asset pack
- TGA conversion workflow
- Resizable frame prototype
- Scrollbar prototype
- Debug-grid workflow

## Phase 2 — OUS2 Window Layout COMPLETE

Completed:

- `OUS2Theme.lua`
- `OUS2Config.lua`
- Three-panel shell
- Header/footer
- Left navigation
- Help panel
- Scroll content area
- Custom scrollbar
- Stable resize handling
- ESC close support
- `/ous2` toggle
- `RegisterPage`, `OpenPage`, `Toggle`
- Cold-start page lifecycle
- `C.pageContainer`
- `C.sidebarContainer`

## Phase 3 — General Dashboard COMPLETED

Completed:

- `OUS2Page_General.lua`
- TOC wiring
- General page registration
- 3-column module card layout
- Shared card assets
- `T.Card` constants
- Card hover visuals
- Wrapped module descriptions
- Wide Information area
- General sidebar content
- Global Options visual block
- Reset visual block

Phase 5 follow-up carried forward:

- Module count summary
- Enabled/disabled card state
- Card navigation to module pages
- Global Options functionality
- Reset functionality after reset semantics audit
- Final micro-adjustments
- Documentation sync after visual layout is stable

## Phase 4 — Module Page Migration COMPLETED

Completed:

1. General
2. Utilities
3. Openables — reusable scale control integrated; visual polish/testing pending
4. Stats Bar
5. Auto Remount
6. Fishing Tracker
7. Flightmaster
8. Flight Routing
9. Faster Loot
10. Toolbox
11. XP Bar
12. Delves

Fishing Tracker equipment display:

- `Fishingtracker.lua` gates The Coiled Huntress Venom display on item 244790 in profession-tool inventory slot 28. `C_TooltipInfo.GetInventoryItem("player", 28)` is authoritative; the reader scans native line left/right text for `+<digits> Venom`, supports multiline strings and color codes, skips secret values, and clears unavailable results. It neither reads nor alters the visible GameTooltip and maintains no inferred count or Venom SavedVariables.
- The green `Venom: +<value>` FontString shares the fishing skill row, is right-aligned beneath Overall Stats, and participates in `OUS.UpdateFishingFont()` through the existing static FontString list. Catch classification, skill formatting, frame width, and pole-hover tooltip behavior are unchanged.
- Refresh uses normal tracker UI refresh/open, fishing `LOOT_READY` processing, slot-28 `PLAYER_EQUIPMENT_CHANGED`, `PROFESSION_EQUIPMENT_CHANGED`, player `UNIT_INVENTORY_CHANGED`, and `TOOLTIP_DATA_UPDATE` matching the last relevant data-instance ID. No polling or repeating timer is added.
- WoW tests passed equip/unequip/re-equip, applicable catch updates, and the tested spend/convert path. These observations do not establish coverage for every external state-change mechanism or other rods; a later normal refresh remains the fallback for unsignaled changes.

XP Bar OUS2 architecture:

- `XPBar` is the registered hub page.
- Global, Experience, Reputation, Favorites, Session Stats, and Help are internal child views of the XP Bar page.
- Switching to the top-level XP Bar page returns navigation to the hub.
- The existing `Delves` settings frame remains registered for implementation compatibility, but is reached through the XP Bar hub rather than a standalone sidebar or General dashboard entry and retains its Back to XP Bar action.

Session Stats runtime architecture:

- `JunkBroker.lua` loads after Utilities and publishes `OUSJunkBroker`, a host-independent LibDataBroker data source with no Titan API calls or dependency. Its runtime-only carried-bag cache includes blacklisted grey items, prices fresh hyperlinks per physical stack, and coalesces startup/item-info updates. It reads authoritative Session Stats junk counters and subscribes to `JunkChanged` for tooltip refreshes; resetting session counters never clears inventory values. Clicks reuse `OUS.SessionStats.Show()` and `OUS.SessionStats.ShowGoldDiagnostics()` without duplicating window construction or accounting.
- Runtime load order is `xpbar_core.lua` → `xpbar_sessionstats.lua` → `xpbar_engine.lua`.
- `xpbar_core.lua` owns shared `OUS.XPBarSession` XP/reputation state and `OUS.FormatLargeNumber`; `xpbar_sessionstats.lua` owns the scrollable Session Stats frame, money/repair/Mistcrest tracking, initialization, related events, `/xpstats`, and `OUS.SessionStats.Refresh()`; `xpbar_engine.lua` continues to track XP/reputation and requests Session Stats refreshes after those values change.
- The frame displays Experience Gained, Reputation Breakdown, Gold Gained, Gold Spent, Repairs (Own + Guild), Junk quantity/value, and Midnight Season 2 Mistcrests, and dynamically reflows when configured sections or currencies are hidden. XP Bar configuration exposes Show Experience, Show Reputation, Show Gold, Show Repairs, Show Currencies, and one tracking control for each built-in Mistcrest. Junk follows gold visibility; the Guild Repairs row and runtime counter were removed in 1.0.3.
- Persistent visibility preferences and sparse built-in currency overrides live at `OdysseusDB.xpBar.sessionStats`; runtime counters are not persisted and reset on login or reload. Initial-login and reload `PLAYER_ENTERING_WORLD` events clear session XP and rebaseline it from current player XP; ordinary world transitions do not reset accumulated session XP. A missing override follows the catalog default, while `false` explicitly disables that currency's display. Disabled currencies continue to be tracked so re-enabling them preserves the current runtime baseline and session total.
- Gold Gained and Gold Spent are gross personal-wallet income and spending. Utilities reports known OUS merchant transactions through `OUS.SessionStats.RecordKnownMerchantTransaction()`: junk income and personal repair wallet effects count immediately and enqueue signed wallet effects. Repairs (Own + Guild) separately records the full bill known before every OUS-initiated repair exactly once, including personal, fully guild-funded, and mixed guild/personal transactions. Junk Gold is a subset of Gold Gained, and Junk Items counts physical stack quantities. The fallback repair observer uses a `RepairAllItems` post-hook without replacing Blizzard's function. Guild First issues one `RepairAllItems(true)` when permitted, without cached bank/withdrawal coverage or full personal affordability prerequisites. Blizzard supplies any native guild/personal split; OUS does not infer it.
- Before an OUS guild-first call, `OUS.SessionStats.MarkRepairFundingIndeterminate()` sets a runtime-only merchant-interaction guard. It bypasses post-hook funding prediction and both pending-cost/bill-reduction repair inference, but leaves ordinary Gold Spent reconciliation, the explicit full-bill Repairs total, and known junk movements active. The guard survives Reset Counters and merchant-show handler ordering, and clears at merchant close even if XPBar tracking was disabled. Chat reports the quoted bill as a request and includes the immediately observed guild repair/withdrawal allowance for context; that reading does not establish guild-bank funds, actual guild funding, or the final funding split. No polling or settlement timer is used.
- `PLAYER_MONEY` reconciles the observed wallet delta against the known movement queue: exact ordered cumulative prefixes first, otherwise same-sign entries in queue order with opposite signs skipped and partial consumption supported. Only unexplained remainder adds ordinary Gold Gained/Spent. `lastMoney` stores an actual observed `GetMoney()` value, never a predicted balance; cold-login initialization leaves it nil until world entry (or the nil-baseline money fallback).
- Junk Seller obtains a fresh bag-slot hyperlink and uses `C_Item.GetItemInfo(info.hyperlink)` sellPrice multiplied by stackCount for production proceeds. ItemID and bag-tooltip price probes are optional debug comparisons, may be nil, and do not drive accounting. The queue remains collected once per merchant session; physical quantity totals are separate from the 12 bag-entry batching limit. The merchant-footer button stays available when enabled, and batch starts recheck Shift protection. `OdysseusDB.utilities.junkSell.detailedSaleReport` defaults OFF and emits per-stack chat independently of summary announcements.
- Confirmed `OUS.SessionStats.ResetCounters()` clears runtime XP/reputation gains, gold/repair/junk counters, and Mistcrest Session gains. It reads fresh XP/wallet baselines, rebaselines crest quantities, clears known movement and pending repair state, and rereads an open merchant's repair bill. Reputation gains are message-based and restart from an empty session table. Current/Season crest information is refreshed rather than zeroed; lifetime/Overall Stats and SavedVariables are untouched. Runtime-only Gold Diagnostics history remains, with an enabled reset timeline record; its separate help reference explains wallet observations, known transactions, and reconciliation results.
- The current typed built-in catalog contains only `CURRENCY` resources: Adventurer (3442), Veteran (3443), Champion (3444), Hero (3445), and Myth (3446) Mistcrests. Blizzard currency data remains authoritative for current quantity, name/icon, and seasonal earned/cap values.
- Mistcrest Session counts only positive quantity deltas; Current uses the owned quantity; Season uses earned versus maximum. Spending lowers Current without subtracting from Session.
- Cold-login baselines are intentionally deferred: `ADDON_LOADED` can expose a provisional zero currency quantity, so the first valid `CURRENCY_DISPLAY_UPDATE` establishes `lastQuantity` and only later positive deltas count toward Session. Reloads did not reproduce the original false gain because currency data was already cached.
- Custom Currency IDs, additional curated currencies, `ITEM` resources, optional Blizzard Currency UI discovery, and larger-list search/filtering remain future work. Currency UI enumeration is not treated as a complete stable currency database.

Flightmaster OUS2 architecture:

- `hideBlizzardTooltip` defaults to `false` in `OUS.flightDefaults` and uses the existing missing-default merge into `OdysseusDB.flightSettings`. The OUS2 Display checkbox is effective only with Flight Master and Show Map Tooltips active. Destination nodes can suppress the entire GameTooltip; the current node retains Blizzard's native "You are here" presentation.
- Hidden mode tracks the suppressed FlightMap pin. Ownerless/non-pin GameTooltip Show activity preserves it; a successfully processed valid new pin replaces it. A secure post-hook of `FlightMap_FlightPointPinMixin:OnMouseLeave()` dismisses OUS only for the tracked pin. Map close and module/tooltips-disabled cleanup clear tracking; OFF mode retains GameTooltip-driven dismissal and positioning beneath Blizzard's tooltip.
- The custom tooltip displays cleaned destination name/zone text, when available, centered in gold RGB `(1, 0.82, 0)` at 14 px. An independent hidden OUS FontString anchored only to `UIParent` measures the same ordinary text for bounded 220–360 px width, 20 px horizontal padding, and wrapped-text height. Measurement does not read GameTooltip or pin geometry; the manual texture background/borders remain in use.
- Runtime tests passed ordinary Blizzard behavior and the documented Zygor enabled/disabled cases without a third-party dependency or addon-specific handling. See the 1.0.6 changelog for coverage; this does not establish universal tooltip-addon compatibility or a combat pass.
- `Config2\OUS2Page_FlightMaster.lua` provides legacy-parity settings for tooltips, timer bar unlock, dimensions, scale, font size, border size, media selectors, color rows, export, wipe, position reset, and appearance reset.
- Flight Master controls update `OdysseusDB.flightSettings` and call public engine APIs in `Flightmaster.lua`: `ApplyFlightSettings`, `ApplyFlightFonts`, `ApplyFlightTexture`, `ApplyFlightBorder`, `SetFlightBarUnlocked`, `ResetFlightBarPosition`, `ResetFlightBarAppearance`, `SetFlightBarColor`, and `SetFlightBorderColor`.
- User scale is applied by resizing the timer bar dimensions; the timer frame itself remains at scale `1` to avoid redraw and anchoring issues.
- `ResetFlightBarAppearance()` restores visual settings only. Learned flight times remain in `OdysseusDB.flightSettings.times` unless the user explicitly wipes them or uses the global reset flow.
- OUS2 uses shared helpers from `OUS2Config.lua`: `C.OpenMediaDropdown()`, `C.OpenColorPicker()`, and `C.ShowCopyTextDialog()`. These helpers are independent of legacy `Config.lua` dropdowns.

Phase 5.6 follow-up work:

- General page polish
- Enabled/disabled card states
- Module count summary
- Global Options functionality
- Reset semantics review
- XP Bar, Reputation, and Delves parity tracked in `Documentation\OUS2_XPBAR_PARITY.md`
- Toolbox expansion
- Faster Loot rules
- Helper extraction

## Phase 5 — Polish & Advanced Controls

Current:

- General, card-state, module-summary, Global Options, and reset-semantics polish
- Phase 5.6 OUS2 legacy parity is in its final stage
- XP Bar, Reputation, and Delves parity planning is centralized in `Documentation\OUS2_XPBAR_PARITY.md`
- Toolbox and Faster Loot advanced controls
- Shared helper extraction

Pending OUS2 left-navigation pages:

- None

## Phase 6 — Polish and Migration

Planned later:

- `OUS2Utils.lua` helper extraction
- Search
- Optional folder restructure

---

# Asset Reference

## Texture Path

```text
Interface\AddOns\OdysseusUtilitySuite\media\Textures\
```

## Frame Assets

```text
Background.tga
TopLeft.tga
TopRight.tga
BottomLeft.tga
BottomRight.tga
Top.tga
Bottom.tga
Vertical_Left.tga
Vertical_Right.tga
HeaderGem.tga
FooterGem.tga
```

## Button Assets

```text
Button_Normal.tga
Button_Hover.tga
Button_Selected.tga
ActionButton_Normal.tga
ActionButton_Hover.tga
ActionButton_Pressed.tga
CloseButton_Normal.tga
CloseButton_Hover.tga
CloseButton_Pressed.tga
```

## Module Card Assets

```text
CardBG_Normal.tga
CardBG_Hover.tga
CardBG_Selected.tga
```

Purpose:

- Normal dashboard card background
- Hover dashboard card background
- Future selected/current/active dashboard card background

## Scrollbar Assets

```text
ScrollTrack.tga
ScrollThumb.tga
```

## Scale Control Assets

```text
ScaleTrack.tga
ScaleFill.tga
ScaleThumb.tga
ScaleArrow_Left_Normal.tga
ScaleArrow_Left_Hover.tga
ScaleArrow_Right_Normal.tga
ScaleArrow_Right_Hover.tga
ScaleEditBox_Background.tga
```

Purpose:

* Reusable OUS2 numeric scale/slider control
* First integrated into the Openables button-scale setting
* Planned reuse for future module controls such as XP Bar size, Stats Bar sizing, opacity, delay, and similar numeric settings

## Icons

```text
Icon_OUS.tga
Icon_General.tga
Icon_XPBar.tga
Icon_Delves.tga
Icon_FlightMaster.tga
Icon_FlightRouting.tga
Icon_Utilities.tga
Icon_Openables.tga
Icon_StatsBar.tga
Icon_AutoRemount.tga
Icon_FasterLoot.tga
Icon_FishingTracker.tga
Icon_Toolbox.tga
Icon_Help.tga
Icon_Changelog.tga
Minimap_button.tga
```

## Utility Assets

```text
Icon_SectionStar.tga
Checkbox_Checked.tga
Checkbox_Unchecked.tga
Divider_Horizontal.tga
TabIndicator.tga
```

## Branding

```text
OUS_Logo.tga
OUSBanner.tga
```

`OUSBanner.tga` still needs review/recreation.

---

# Coding Standards

- Retail 12.0+ APIs only
- No deprecated APIs
- No protected-frame mutation
- No emoji in WoW UI text
- No `goto` / labels
- No `loadstring`
- No broad `pcall` wrappers around core logic
- Event-driven design
- Keep OUS2 changes focused and reviewable
- Keep page files visual-first until module behavior is ready
- Use `OUS.LogDebug()` for normal debug output
- Add one-line comments before major helpers, public OUS APIs, and non-obvious integration boundaries
- Prefer standard third-party integration APIs over addon internals; keep optional compatibility isolated and nil-guarded
- Use LibDataBroker-1.1 + LibDBIcon-1.0 for launcher/minimap integration instead of raw manual minimap button ownership
- Let third-party minimap managers own broker launcher visibility and avoid addon-specific minimap workarounds

---

# Long-Term Vision

OUS2 becomes:

- the main configuration framework for OUS
- a shared UI toolkit for module pages
- the dashboard and help hub for the addon
- a stable, expandable UI foundation for future Retail versions

OUS2 is the only loaded configuration UI. `/ous` is preserved as the primary entry point and `/ous2` remains an alias.
