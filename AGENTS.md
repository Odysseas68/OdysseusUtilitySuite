# AGENTS.md

## Project Overview

Odysseus Utility Suite (OUS) is a modular World of Warcraft Retail addon for Retail Midnight 12.0+.

It combines quality-of-life utility tools into a single addon suite. Existing modules are independently toggled from the legacy Midnight-themed configuration UI opened with `/ous`. A next-generation configuration framework, OUS2, is under active development and opened with `/ous2`.

**Current WoW Interface target:** `120007`
**SavedVariables:** `OdysseusDB` account-wide, `OdysseusCharDB` per-character
**Namespace pattern:** `local addonName, OUS = ...`
**Shared namespace:** all exported functions, module state, defaults, and shared helpers live on the `OUS` table.

This project is in refinement and feature-expansion phase, not rewrite phase.

---

## Prime Directive

Prefer small, safe, reviewable changes.

Do not restructure working systems, rename stable functions, change SavedVariables formats, or reorder TOC entries unless explicitly instructed.

When uncertain, stop and report the uncertainty instead of inventing APIs, behavior, or architecture.

---

## Hard Constraints

Never violate these rules:

- Use WoW Retail 12.0+ APIs only.
- Current Interface target is `120007`.
- Do not use deprecated APIs.
- Do not infer WoW API signatures from Classic examples, old addon code, or model memory.
- Avoid taint and protected-call issues.
- Never hook, replace, or mutate protected Blizzard frames/functions directly.
- No `loadstring`.
- No `goto` or `::label::` syntax; WoW uses Lua 5.1.
- No broad `pcall` wrappers around core logic. Existing safe logging/display helper exceptions may remain.
- Work one file at a time unless the user explicitly asks for a multi-file change.
- Do not rename stable functions, tables, modules, SavedVariables keys, or slash commands without explicit approval.
- Do not change SavedVariables structures unless explicitly approved.
- Do not add dependencies unless explicitly requested.
- Keep enUS text unless localization work is explicitly requested.
- Keep comments minimal. Comment why, not what.
- Preserve important existing comments that explain non-obvious behavior.
- Never use emoji characters in WoW UI text; WoW fonts render them as blank boxes.
- For secure buttons, never set `OnMouseDown` or `OnMouseUp` on `SecureActionButtonTemplate` frames.
- Use `OUS.LogDebug("ModuleName", "message")` for debug output; do not use `print()` for normal debug logging.

---

## API Verification Order

Before implementing unfamiliar or uncertain Retail API usage, verify in this order:

1. Project-local skills and instructions:
   - `.github/skills/wow-api-combat/SKILL.md`
   - `.github/skills/wow-api-unit-player/SKILL.md`
   - `.github/skills/wow-api-spells-abilities/SKILL.md`
   - `.github/skills/wow-api-widget/SKILL.md`
   - `.github/skills/wow-api-framexml/SKILL.md`
   - `.github/skills/wow-api-events/SKILL.md`
   - `.github/skills/wow-addon-structure/SKILL.md`
   - `.github/instructions/`

2. Local API/reference repos:
   - `d:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\WoWAddonDevGuide\`
   - `d:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\wow-ui-source\`

3. Blizzard generated API docs inside the local Gethe mirror:
   - `d:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\`

4. Local modern addon comparison:
   - `d:\Program Files\Blizzard\World of Warcraft\_retail_\Interface\AddOns\EnhanceQoL\`

5. External reference only when needed:
   - JBurlison/WoWAddonAPIAgents patterns

When using `wow-ui-source`, prefer the `live` mirror and Blizzard-generated API documentation for function signatures, event payloads, and secret predicate status.

---

## TOC Load Order

The TOC order is strict. Do not reorder unless explicitly instructed.

1. `Libs\LibStub\LibStub.lua`
2. `Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua`
3. `Libs\LibSharedMedia-3.0\LibSharedMedia-3.0.lua`
4. `Core.lua` — creates OUS namespace, DB init, debug engine, slash commands
5. `flightdata.lua` — flight timing database
6. `xpbar_data.lua` — XP/rep data tables
7. `Odysseus_RoutingDB.lua` — flight routing database
8. `AutoRemountSpells.lua` — AutoRemount spell ID database
9. `StatsBarSpecPriority.lua` — StatsBar spec priority database
10. `OpenablesDB.lua` — Openables item database
11. `Flightmaster.lua` — flight timer/routing engine
12. `Fasterloot.lua` — auto-loot module
13. `Fishingtracker.lua` — fishing session tracker
14. `xpbar_core.lua` — XP/rep bar frame and layout
15. `xpbar_engine.lua` — XP/rep tracking logic
16. `xpbar_delves.lua` — Delves companion tracking
17. `xpbar_favorites.lua` — favorite rep pinning
18. `FlightRouting.lua` — taxi map route rendering
19. `AutoRemount.lua` — auto remount engine
20. `StatsBar.lua` — stats bar engine
21. `Openables.lua` — openables button engine
22. `Utilities.lua` — utility commands
23. `Toolbox.lua` — floating icon toolbar engine
24. `Config.lua` — legacy main config UI
25. `xpbar_config.lua` — XPBar config panel
26. `Help.lua` — tabbed help frame
27. `Config2\OUS2Theme.lua` — OUS2 theme registry
28. `Config2\OUS2Config.lua` — OUS2 main config frame

Additional OUS2 page files should load after `Config2\OUS2Config.lua`.

---

## Core Architecture Rules

### Namespace

Use:

```lua
local addonName, OUS = ...
```

All shared state and exported functions belong on `OUS`. Avoid bare globals unless a global frame name is intentionally required by WoW or existing architecture.

### Module Toggle Pattern

Each module checks `OdysseusDB.modules.<moduleName>` before initializing.

New modules must register a toggle default in `Core.lua` inside the `ADDON_LOADED` defaults block.

### SavedVariables

Use `OdysseusDB` for account-wide settings.

Use `OdysseusCharDB` for per-character settings, initialized under a module-specific key, for example:

```lua
OdysseusCharDB.autoRemountChar
OdysseusCharDB.statsBar
```

Do not change existing SavedVariables structures without explicit approval.

### Event-Driven Design

Use:

```lua
CreateFrame("Frame")
:RegisterEvent()
:SetScript("OnEvent", ...)
```

Avoid polling loops. Avoid `OnUpdate` for state checks unless there is no safe event/timer alternative.

### Defaults Pattern

Each module with settings exposes defaults as `OUS.<moduleDefaults>`.

`OUS.ResetAllSettings()` in `Core.lua` iterates module defaults. New modules with settings must follow this pattern.

### Debug Logging

Use:

```lua
OUS.LogDebug("ModuleName", "message")
```

Do not use `print()` for routine debug output.

### Config Wiring

Legacy config panels attach to `OUS.ConfigFrame` from `Config.lua`.

Config files load last and may assume module state already exists.

---

## Slash Commands

Do not duplicate or replace existing slash commands without explicit approval.

Known commands:

- `/ous`
- `/ous2`
- `/ous help`
- `/ous debug`
- `/ous fish`
- `/ousdebug`
- `/xpstats`
- `/ousxp`
- `/toasttest`
- `/delvetest`
- `/delvedebug`
- `/ar`
- `/autoremount`
- `/sb`
- `/statsbar`
- `/op`
- `/openables`
- `/tb`
- `/toolbox`
- `/ous_rare`

Slash command registration stays in `Core.lua` unless a module already owns an established command pattern.

---

## OUS2 Configuration Framework

OUS2 is the next-generation configuration UI and long-term UI framework.

Current OUS2 files live in:

```text
Config2\OUS2Theme.lua
Config2\OUS2Config.lua
```

Existing OUS files remain flat in the addon root. Do not move them until Phase 6 is explicitly approved.

### OUS2 Namespaces

- `OUS.Theme` / `local T = OUS.Theme`
- `OUS.Config2` / `local C = OUS.Config2`

### Texture Rules

Texture root:

```text
Interface\AddOns\OdysseusUtilitySuite\media\Textures\
```

All TGA files sit flat in this directory. There is no `Assets/` subdirectory.

Always use:

```lua
T.Tex("AssetKey")
```

Do not hardcode texture paths in page files.

### OUS2 Styling Rules

- Use `T.Colors.*`; do not hardcode RGB values in page files.
- Use `T.Fonts.*`; do not hardcode font objects unless required.
- Use `T.Frame.*`, `T.Scroll.*`, and `T.Icons.*`; do not duplicate constants.
- OUS2 visual identity is Midnight Arcane: dark metallic charcoal, deep midnight blue, pale readable text, soft lavender crystal accents.
- Do not stretch logos. Center large branding assets.

### OUS2 Public API

```lua
OUS.Config2.RegisterPage(pageName, pageFrame, refreshFn)
OUS.Config2.OpenPage(pageName)
OUS.Config2.Toggle()
OUS.Config2.SetHelpText(text)
OUS.Config2.ClearHelpText()
C.pageContainer
```

### OUS2 Page Keys

Use exactly these internal page keys:

```text
General
XPBar
Delves
FlightMaster
FlightRouting
Utilities
Openables
StatsBar
AutoRemount
FasterLoot
FishingTracker
Toolbox
Help
Changelog
```

### OUS2 Page Pattern

Each page file should:

1. Use `local addonName, OUS = ...`.
2. Alias `local T = OUS.Theme` and `local C = OUS.Config2`.
3. Create a page frame parented to `C.pageContainer`.
4. Call `SetAllPoints()` and `Hide()`.
5. Build UI using `T.Tex`, `T.Colors`, `T.Fonts`, and frame constants.
6. Wire setting hover text with `C.SetHelpText(text)` and `C.ClearHelpText()`.
7. Implement `Refresh()` to read from `OdysseusDB` / `OdysseusCharDB`.
8. Register with `OUS.Config2.RegisterPage("PageKey", pageFrame, Refresh)`.
9. Add the file to the TOC after `Config2\OUS2Config.lua`.

### OUS2 Current Focus

Current focus is Phase 3: General page dashboard.

Tasks:

1. Remove temporary debug border from content panel.
2. Create `Config2\OUS2Page_General.lua`.
3. Build General dashboard with version info, module count, and module cards.
4. Wire module cards to `OUS.Config2.OpenPage(pageName)`.
5. Add the new file to the TOC after `Config2\OUS2Config.lua`.

### OUS2 Manual NineSlice

Manual placement only.

Never use:

```lua
NineSliceUtil.ApplyLayout
```

It is atlas-only and does not work with custom TGA files.

### OUS2 Scrollbar

Scrollbar rules:

- Parent custom scrollbar to `contentPanel`, not to the main frame.
- `scrollTest` anchors `TOPRIGHT` and `BOTTOMRIGHT` to `contentPanel`.
- Track height follows `scrollTest:GetHeight()`.
- Thumb position recalculates on `OnVerticalScroll`.
- Current constants: `trackW = 10`, `thumbMinH = 60`, `thumbRatio = 0.30`, `scrollStep = 18`.

### OUS2 Debug Artifacts

Temporary debug grid, underlay, and cyan `BackdropTemplate` debug borders must be removed or disabled before committing production UI pages.

---

### OUS2 Resizable Frame Rules

For manually resizable OUS2 frames:

* Do not rely on a persistent CENTER anchor during `StartSizing()`.
* Before calling `StartSizing()`, normalize the frame to a stable screen anchor.
* Capture the current frame position with `GetLeft()` and `GetTop()`.
* Re-anchor the frame to `UIParent` using `TOPLEFT` before resizing.
* Call `StopMovingOrSizing()` before starting a new resize operation.
* Guard resize handlers when the frame is locked or hidden.
* Give resize handles an explicit frame level above content, sidebar, and page frames.
* Resize handles must not overlap interactive buttons or controls.
* After adding sidebars, overlays, page containers, or footer controls, test resize from right, bottom, and bottom-right handles.

---

## Modern ScrollBox Rules

For static scrollable content in Retail 12.0.5+:

- Use `WowScrollBox` with `MinimalScrollBar`.
- Do not use nonexistent `WowScrollBar`.
- Do not use data-provider list APIs for static content.
- Use `CreateScrollBoxLinearView()`.
- Use `ScrollUtil.InitScrollBoxWithScrollBar`.
- Set `child.scrollable = true`.
- In tabbed UIs, store and hide/show `{ box, bar, child }` together because ScrollBox may reparent the child.

Known templates:

- `MinimalScrollBar`
- `WowTrimScrollBar`
- `WowTrimHorizontalScrollBar`

Nonexistent in current Retail:

- `WowScrollBar`

---

## Module Notes

### XPBar / Reputation / Delves

Files:

- `xpbar_core.lua`
- `xpbar_engine.lua`
- `xpbar_delves.lua`
- `xpbar_favorites.lua`
- `xpbar_config.lua`

Rules:

- Preserve the current modular structure.
- Prefer existing update flow over introducing a new system.
- Keep fixes local and minimal.
- Pay attention to login, reload, zoning, max-level mode, favorite faction persistence, watched faction clearing, and delve completion transitions.
- At max level, the bar should remain useful for reputation even when XP no longer matters.
- Delve completion may change map, instance, or scenario state after final boss; avoid fragile visibility logic.

### Flightmaster / FlightRouting

Files:

- `Flightmaster.lua`
- `FlightRouting.lua`
- `flightdata.lua`
- `Odysseus_RoutingDB.lua`

Rules:

- Preserve route timing and learned-route behavior.
- Treat generated route/data files as data, not normal logic.
- Do not broadly change flight timing data formats unless explicitly required.
- Preserve the separate tooltip approach because third-party addons may taint or alter Blizzard tooltips.
- If changing route matching, consider both bundled routes and newly learned routes.
- If a fix only affects display, avoid changing learning/storage logic.

### Utilities

Covers rare announcer, auto repair, and junk seller.

Rules:

- `OdysseusDB.utilities` stores core utility settings.
- `OdysseusDB.utilities.junkSell` stores junk seller settings.
- Rare announcer should use safe waypoint handling and restore previous pins.
- Auto repair runs from `MERCHANT_SHOW`.
- Junk seller uses a pending queue collected once per merchant session.
- `MerchantFrame:IsShown()` may be false at `MERCHANT_SHOW`; use a short delay where existing code expects it.
- Junk selling should use stable bag/slot queue logic and respect blacklist behavior.

### Openables

Files:

- `Openables.lua`
- `OpenablesDB.lua`

Rules:

- Static DB format: `OUS.OpenablesDB[itemID] = minQuantity`.
- Runtime settings live in `OdysseusDB.openables`.
- Use a plain draggable container with a `SecureActionButtonTemplate` child.
- Secure click should use `type=macro` and `/use item:ID`.
- Never use `C_Container.UseContainerItem` directly for the openables secure button path.
- Never set `OnMouseDown` or `OnMouseUp` on the secure button.
- Use `PostClick` only for post-action logic.
- Do not assume every item API is immediately available; use item loading guards where needed.

### AutoRemount

Rules:

- Spell DB lives in `AutoRemountSpells.lua`.
- Preserve gather/exclude list behavior.
- Avoid chat spam from spy/debug mode.
- Be careful around combat, form, mounting, and profession/crafting exclusions.
- Do not introduce protected mount calls in unsafe contexts.

### StatsBar

Rules:

- Character stat reads may be restricted by Retail secret-value rules.
- Cache stats on safe events.
- Do not compare or format restricted secret values directly in combat/restricted contexts.
- `tonumber()` does not neutralize secret number values.
- Use project-established stat cache/display helper patterns.

### Fasterloot / Fishingtracker

Rules:

- Fasterloot must reveal loot when roll/locked/full states require player action.
- Fishingtracker can pause fasterloot behavior where existing code requires it.
- Currency and item link handling may be delayed or nil; guard item/currency loading.

### Toolbox

Rules:

- Toolbox frame and button pool are reusable.
- Preserve lock/unlock behavior where drag handle controls movement.
- Do not break smart popup positioning.
- Toolbox may deep-link into config pages via existing `OUS.ConfigFrame` or OUS2 APIs.

### Help

Rules:

- `Help.lua` is standalone.
- Preserve global `OdysseusHelpFrame` for `/ous help`.
- Modern Help content uses `WowScrollBox` + `MinimalScrollBar` patterns.

---

## Adding a New Module

Use this checklist:

1. Create the new module file in the addon root unless a restructure is explicitly approved.
2. Use `local addonName, OUS = ...`.
3. Add the module toggle default in `Core.lua` inside the `ADDON_LOADED` defaults block.
4. If the module has account-wide settings, initialize under `OdysseusDB.<moduleKey>`.
5. If the module has per-character settings, initialize under `OdysseusCharDB.<moduleKey>`.
6. Expose defaults as `OUS.<moduleDefaults>` if it has settings.
7. Ensure reset flow can include the module defaults.
8. Add the file to `OdysseusUtilitySuite.toc` before config files.
9. Add config wiring in `Config.lua` or a dedicated config file loaded after the module engine.
10. Add a Toolbox button entry if the module has a toggleable frame or useful config shortcut.
11. Add slash command docs to `Help.lua` when applicable.
12. Create `Config2\OUS2Page_<Module>.lua` if the module needs an OUS2 page.
13. Add the OUS2 page file to the TOC after `Config2\OUS2Config.lua`.

---

## Documentation Rules

Documentation is part of the project, not an afterthought.

Maintain and update when behavior changes:

- README.md
- Documentation/README_v2.md
- Documentation/ARCHITECTURE.md
- Documentation/TODO_v2.md
- CHANGELOG.md (if present)

CLAUDE.md is reference material only.
Do not modify CLAUDE.md unless explicitly instructed.

AGENTS.md should only be modified when development rules,
architecture conventions, workflows, or project standards change.

When documentation and code disagree, inspect the code and report the mismatch.

For documentation-only tasks:

- Do not modify code.
- Do not invent completed features.
- Mark uncertain or inferred items clearly.
- Keep current phase/status accurate.

When a new file is created, determine whether documentation updates
are actually required before modifying documentation.
Avoid documentation-only churn for cosmetic or internal changes.

---

## Working Style

When debugging:

1. Identify the likely root cause.
2. Check relevant APIs before proposing code.
3. Prefer the smallest safe fix.
4. Preserve style and formatting.
5. Show exact replacement blocks when possible.
6. Mention important edge cases.
7. Avoid unrelated cleanup.

When editing:

- Prefer one focused patch.
- Avoid broad refactors.
- Avoid opportunistic rewrites.
- Do not change unrelated modules.
- Report any risks, assumptions, or unverified API behavior.

When producing code for the user to paste manually:

- Provide exact replacement blocks.
- Keep indentation intact.
- Give clear insertion/replacement location.
- Avoid tiny ambiguous snippets when a full replacement block is safer.

## File Header Rule

Every new Lua file must start with this header format:

```
-- Addon   : OdysseusUtilitySuite
-- File    : Relative\Path\Filename.lua
-- Version : YYYY.MM.DD
-- Desc    : Short description of the file purpose
-- =========================================
```
---

## Skill Trigger Patterns

Codex may convert these patterns into skills. Keep each pattern focused.

### Pattern: WoW Retail API Check

Use before implementing uncertain WoW API usage.

Apply when:

- changing event handlers
- changing aura, spell, unit, stats, map, scenario, delve, XP, reputation, flight, item, mount, pet, toy, or frame APIs
- touching anything that may interact with protected Blizzard UI
- API signatures, payloads, return values, nil cases, or secret predicates are uncertain

Rules:

- Verify exact function name.
- Verify arguments.
- Verify return values.
- Verify event payloads.
- Verify nil/delayed/loading cases.
- Verify combat lockdown or taint risk.
- Verify secret predicate status in local `wow-ui-source`.
- Do not infer signatures from memory.
- Prefer modern `C_` namespace APIs when they are the Retail-safe path.
- Call out uncertainty explicitly.

### Pattern: Minimal Addon Patch

Use for normal OUS edits.

Rules:

- Work one file at a time unless explicitly asked otherwise.
- Preserve names, structure, formatting, and architecture.
- Do not rename functions, tables, frames, SavedVariables, or slash commands.
- Do not refactor working systems unless explicitly asked.
- Prefer targeted helpers over large rewrites.
- Avoid unrelated side effects.
- Keep enUS text.
- Do not add dependencies.
- Do not invent helper systems.

Patch style:

- Show exact replacement blocks.
- Specify exact insertion spot.
- Keep comments minimal.
- Preserve non-obvious existing comments.
- Mention edge cases briefly.

### Pattern: XPBar Debug

Use when editing:

- `xpbar_core.lua`
- `xpbar_engine.lua`
- `xpbar_delves.lua`
- `xpbar_favorites.lua`
- `xpbar_config.lua`

Rules:

- Preserve module boundaries and load order.
- Prefer sticky session-safe fixes over broad heuristics.
- Handle max-level reputation behavior carefully.
- Handle favorite faction persistence carefully.
- Handle login/reload/zoning timing carefully.
- Handle delve completion and scenario/map transitions carefully.

### Pattern: Flightmaster Safe Edit

Use when editing:

- `Flightmaster.lua`
- `FlightRouting.lua`
- `flightdata.lua`
- `Odysseus_RoutingDB.lua`

Rules:

- Preserve learned-route behavior.
- Preserve arrival threshold behavior.
- Preserve independent tooltip behavior.
- Treat third-party tooltip taint as possible.
- Avoid changing data formats unless required.
- Avoid changing storage/learning logic for display-only fixes.

### Pattern: OUS2 Config UI Edit

Use when editing:

- `Config2\OUS2Theme.lua`
- `Config2\OUS2Config.lua`
- `Config2\OUS2Page_*.lua`
- OUS2 assets/docs

Rules:

- Use `T.Tex`, `T.Colors`, `T.Fonts`, `T.Frame`, `T.Scroll`, and `T.Icons`.
- Do not hardcode texture paths, RGB colors, or frame constants in page files.
- Parent pages to `C.pageContainer`.
- Register pages with `OUS.Config2.RegisterPage`.
- Use `C.SetHelpText` / `C.ClearHelpText` for hover help.
- Use manual NineSlice only.
- Do not use emoji.
- Remove debug borders before production commit.
- Keep `/ous` legacy config untouched unless explicitly asked.

### Pattern: Openables Safe Edit

Use when editing `Openables.lua` or `OpenablesDB.lua`.

Rules:

- Preserve secure button architecture.
- Use macro `/use item:ID` for secure item use.
- Never set `OnMouseDown` or `OnMouseUp` on secure button.
- Avoid direct `C_Container.UseContainerItem` for the secure openables button path.
- Guard delayed item info.
- Do not change DB format unless explicitly approved.

### Pattern: AutoRemount Safe Edit

Use when editing `AutoRemount.lua` or `AutoRemountSpells.lua`.

Rules:

- Preserve spell DB keyed-table style.
- Preserve gather/exclude separation.
- Avoid protected mount/form calls in unsafe contexts.
- Avoid debug/chat spam.
- Be careful with combat, profession crafting, shapeshift, mounts, and spy mode.

### Pattern: Utilities Safe Edit

Use when editing `Utilities.lua`.

Rules:

- Preserve rare announcer waypoint restoration.
- Preserve auto repair merchant timing.
- Preserve junk seller pending queue behavior.
- Respect junk blacklist collection-time behavior.
- Use existing batch/timer logic unless explicitly changing it.

### Pattern: Documentation Maintainer

Use for documentation updates.

Rules:

- Read code before changing docs when possible.
- Do not modify code.
- Do not invent features.
- Keep current phase/status accurate.
- Update related documentation consistently when needed.
- Treat `CLAUDE.md` as reference-only; do not modify it unless explicitly instructed.
- Report code/doc mismatches.

### Pattern: New Module Blueprint

Use when adding a new OUS module.

Goals:

- Keep the module independent.
- Preserve TOC discipline.
- Preserve toggle/default/reset/config patterns.
- Avoid cross-module coupling.
- Add OUS2 integration when appropriate.

Checklist:

1. Module file.
2. `OdysseusDB.modules.<moduleName>` default.
3. Account/per-character DB defaults.
4. `OUS.<moduleDefaults>` if settings exist.
5. Reset integration.
6. TOC entry before config files.
7. Legacy config integration if needed.
8. OUS2 page integration if needed.
9. Help/slash command documentation.
10. Toolbox integration if useful.

---

## Do Not Do

Do not:

- Rewrite the addon.
- Flatten or restructure modules.
- Convert the project to a different framework.
- Introduce Ace3 or other dependencies unless explicitly requested.
- Change database formats casually.
- Use Classic-only APIs.
- Use deprecated APIs.
- Create polling loops for state.
- Hook protected Blizzard frames/functions directly.
- Replace working systems because a generic Lua pattern looks cleaner.
- Treat generated data files as ordinary logic files.
- Assume AI-generated docs are correct without checking code.

---

## Preferred Response Format for Codex

For analysis/report tasks:

1. Summary
2. Files inspected
3. Findings
4. Risks/uncertainties
5. Suggested next step

For code-change tasks:

1. Summary of change
2. Files changed
3. Why the change is safe
4. Edge cases considered
5. Testing steps in WoW

For API-check tasks:

1. API verified
2. Source checked
3. Signature/return values
4. Nil/combat/taint/secret-value risks
5. Recommended usage
