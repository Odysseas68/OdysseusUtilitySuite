# Odysseus Utility Suite — Claude Code Context

## Project Overview
A modular WoW Retail addon (Retail 12.0+) combining quality-of-life utility tools into a single suite. Modules are independently toggled from a shared Midnight-themed config UI opened with `/ous`.

**SavedVariables:** `OdysseusDB` (account-wide), `OdysseusCharDB` (per-character)
**Namespace:** `local addonName, OUS = ...` — the `OUS` table is the global shared namespace.

---

## TOC Load Order (strict — do not reorder)
1. `Libs\LibStub\LibStub.lua`
2. `Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua`
3. `Libs\LibSharedMedia-3.0\LibSharedMedia-3.0.lua`
4. `Core.lua` — creates OUS namespace, DB init, debug engine, slash commands
5. `flightdata.lua` — flight timing database
6. `xpbar_data.lua` — XP/rep data tables
7. `Odysseus_RoutingDB.lua` — flight routing database
8. `AutoRemountSpells.lua` — AutoRemount spell ID database (gather + exclude lists)
9. `StatsBarSpecPriority.lua` — StatsBar spec priority database
10. `OpenablesDB.lua` — Openables item database (700+ itemIDs with min quantities)
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
22. `Utilities.lua` — utility commands (rare announcer, auto repair, junk seller)
23. `Toolbox.lua` — floating icon toolbar engine
24. `Config.lua` — main config UI (loads last)
25. `xpbar_config.lua` — xpbar config panel (loads last)
26. `Help.lua` — tabbed help frame (loads last)

---

## Architecture Rules

**Namespace:** All module functions and state live on the `OUS` table. Never use bare globals.

**Module toggle pattern:** Each module checks `OdysseusDB.modules.<moduleName>` before initializing. New modules must register a key here in `Core.lua`'s `ADDON_LOADED` block.

**Event-driven:** Use `CreateFrame("Frame")` + `:RegisterEvent()` + `:SetScript("OnEvent", ...)`. No polling loops. No `OnUpdate` for state checks.

**Defaults pattern:** Each module exposes its defaults table as `OUS.<moduleDefaults>`. `OUS.ResetAllSettings()` in Core.lua iterates these — new modules must follow the same pattern.

**Debug logging:** Use `OUS.LogDebug("ModuleName", "message")` — never `print()` for debug output.

**Config wiring:** New module config panels attach to `OUS.ConfigFrame` (built in `Config.lua`). Config always loads last so it can reference any module's state.

**Per-character settings:** Use `OdysseusCharDB` (declared as `SavedVariablesPerCharacter` in the TOC). Account-wide settings go in `OdysseusDB`, character-specific settings go in `OdysseusCharDB` under a module key e.g. `OdysseusCharDB.autoRemountChar`, `OdysseusCharDB.statsBar`. Initialize in `Core.lua` ADDON_LOADED block.

---

## Utilities Module Notes
- `OdysseusDB.utilities` — settings: `rareEnabled`, `repairEnabled`, `guildRepair`, `announceRepair`
- `OdysseusDB.utilities.junkSell` — settings: `enabled`, `requireShift`, `announceJunk`, `limitTo12`, `blacklist = {[itemID]=true}`
- **Rare Announcer**: uses `C_Map.SetUserWaypoint` + `GetUserWaypointHyperlink()` to get a native waypoint link — always restore the previous pin via `C_Map.GetUserWaypointFromHyperlink` after 0.1s. TomTom: `TomTom:AddWaypoint(mapID, x, y, { title, source="OUS", crazy=true })` — `source` and `crazy` are required fields. Color codes stripped from chat message (blocked in 12.0+). Open world only: `IsInInstance()` guard.
- **Auto Repair**: `MERCHANT_SHOW` event; guild repair check via `GetGuildBankWithdrawMoney()` (returns player withdrawal limit, not bank balance); `RepairAllItems(true)` for guild, `RepairAllItems()` for own gold. Coin icons: `Interface\\MoneyFrame\\UI-GoldIcon` etc. at 14×14 with `|T...:14:14:2:0|t` format.
- **Junk Seller**: `junkPending` built once via `CollectJunkItems()` at `MERCHANT_SHOW` — blacklist applied at collection time only, no rescanning. Sells via `table.remove(junkPending, 1)` + `C_Container.UseContainerItem(bag, slot)` — slots stable during vendor session. One item per 0.2s timer chain. `MerchantFrame:IsShown()` returns false at `MERCHANT_SHOW` event time — use 0.3s delay before starting. Button parented to `MerchantFrame` (not UIParent, not child frames that addons may hide like `MerchantMoneyFrame`). `limitTo12` batches 12 items at a time.
- **Localized General channel**: `GENERAL_CHANNEL` table with 10 locales (Leatrix Plus pattern); `GetChannelName(name)` to get index; send via `C_ChatInfo.SendChatMessage(msg, "CHANNEL", nil, index)`.

---

## Toolbox Module Notes
- `OdysseusDB.toolbox` — settings: `x`, `y`, `point`, `relPoint`, `locked`, `shown`, `scale`, `direction`
- Frame: `OUSToolboxFrame` (plain Frame, global name) — drag handle overlay shown when unlocked
- Button pool: pre-created per visible module, re-used across `LayoutButtons()` calls
- Direction: `"horizontal"` (default) or `"vertical"` — controls frame sizing and button anchor axis
- Openables popup: `OUSToolboxOpPopup` — invisible anchor container, Midnight-themed child buttons, smart screen-aware positioning based on bar orientation and available space
- `OUS.ConfigFrame.ShowTab` and `OUS.ConfigFrame.currentNavTab` exposed by Config.lua for Toolbox to open specific config tabs
- Lock/unlock: drag handle covers full frame when unlocked; all icon buttons get `EnableMouse(false)` during unlock to prevent accidental clicks

---

## Help Frame Notes
- `Help.lua` is standalone — no dependency on Config.lua internals
- `OdysseusHelpFrame` global name preserved for Core.lua `/ous help` handler
- Tabbed layout: 6 tabs (General, Toolbox, XP & Rep, Auto Remount, Stats Bar, Openables)
- `ScrollingMessageFrame` replaced with `ScrollFrame` + `FontString` for top-down rendering
- Content frames lazy-created per tab on first visit
- Compact banner (200×100) + title + separator on `helpContent` panel, shared across all tabs

---

## Openables Module Notes
- `OUS.OpenablesDB` — static item database loaded from `OpenablesDB.lua`; format `[itemID] = minQuantity`
- `OdysseusDB.openables` — runtime settings: `autoOpen`, `blacklist`, `customItems`, `x`, `y`, `point`, `relPoint`, `locked`, `scale`
- Button architecture: `opContainer` (plain Frame, draggable, `EnableMouse(false)` when locked) → `opBtn` (SecureActionButtonTemplate child, handles clicks)
- Secure click: `type=macro`, `macrotext="/use item:ID"` — never use `C_Container.UseContainerItem` directly (taint in 12.0+)
- Never set `OnMouseDown` or `OnMouseUp` on `opBtn` — breaks secure execution
- Drag: `opContainer:RegisterForDrag("LeftButton")` only when unlocked; when unlocked `opBtn` is hidden and `dragHandle` is shown
- Collection filtering: `C_MountJournal.GetMountFromItem`, `C_PetJournal.GetPetInfoByItemID`, `C_ToyBox.GetToyInfo`, tooltip `ITEM_SPELL_KNOWN` for recipes, tooltip `ITEM_COSMETIC` + `"Already Known"` string for appearance items
- Cosmetic detection: `GetItemCategory(itemID, bag, slot)` scans `C_TooltipInfo.GetBagItem` for `ITEM_COSMETIC` — no database needed. Collection check uses hardcoded `"Already Known"` string (capital K, no period) — `ITEM_ALREADY_KNOWN` is `nil` in Retail 12.0+ and must not be used
- Category classID: use return position 12 of `C_Item.GetItemInfo` for numeric classID — position 6 returns the localized string

---

## API Reference (local — read before implementing uncertain APIs)
- Combat, lockdown, secrets: `.github/skills/wow-api-combat/SKILL.md`
- Unit/player/auras: `.github/skills/wow-api-unit-player/SKILL.md`
- Spells and abilities: `.github/skills/wow-api-spells-abilities/SKILL.md`
- Widget/frame creation: `.github/skills/wow-api-widget/SKILL.md`
- FrameXML templates: `.github/skills/wow-api-framexml/SKILL.md`
- Events reference: `.github/skills/wow-api-events/SKILL.md`
- Global 12.0+ rules: `.github/instructions/`
- Addon structure: `.github/skills/wow-addon-structure/SKILL.md`

---

## Local Reference Repos
- `../../WoWAddonDevGuide/` — Midnight 12.0+ API reference, patterns, secret values documentation
- `../../wow-ui-source/` — Gethe mirror of live Blizzard UI source; use `Interface/AddOns/Blizzard_APIDocumentationGenerated/` for secret predicate and API signature verification

---

## Hard Constraints (never violate)
- WoW Retail 12.0+ API only — interfaces: `120000, 120001, 120005`
- No deprecated functions (no `UnitXP` alternatives that are Classic-only, etc.)
- No taint — never hook or replace protected Blizzard frames/functions directly
- No `loadstring`, no `pcall` wrappers around core logic (only around logging, as in Core.lua)
- No multi-file changes in a single task — work one file at a time
- Preserve modular architecture — modules must not directly call functions from sibling modules (go through OUS table)
- For any uncertain or unfamiliar Retail API usage, reference `.github/skills/` local files first, then `../../WoWAddonDevGuide/` (Midnight 12.0+ API reference, secret values documentation), then `../../wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/` (live Blizzard generated API docs, secret predicate verification), then https://github.com/JBurlison/WoWAddonAPIAgents
- Before using any uncertain WoW API, verify the correct Retail 12.0+ signature and secret predicate status in `../../wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/` — do not infer API signatures from Classic patterns or training data
- Cross-reference patterns from EnhanceQoL addon (`../EnhanceQoL/`) for modern event-driven approaches; see `../../WoWAddonDevGuide/05_Patterns_And_Best_Practices.md` for Midnight-era patterns
- Minimal comments only — never narrate what code is doing; only comment *why* when genuinely non-obvious; section headers allowed; short one-line descriptions on functions/helpers/tables
- **No `goto` or `::label::` syntax** — WoW uses Lua 5.1 which does not support these; use nested `if` guards instead
- Character stats (`UnitStat`, `GetCombatRating`, etc.) are gated behind `SecretWhenUnitStatsRestricted` — always cache on stat events, never read live in combat, never compare secret values directly. Known restricted contexts: Mythic+, raid encounters, rated PvP, Timewalking. Known safe: Delves, Ritual Sites, normal/heroic dungeons, open world.
- `GetXPExhaustion()` is valid in Retail 12.0+ — returns rested XP amount or `nil` when not rested. `C_XP` namespace does not exist — do not use it. Safe pattern: `(GetXPExhaustion and GetXPExhaustion()) or 0`
- `tonumber()` does NOT neutralize secret number values in Retail 12.0+ — it passes them through unchanged; use `pcall` around stat reads and format/math operations on stat values (permitted exception: display helpers and stat cache population only, not core logic)
- Secure buttons: never set `OnMouseDown`/`OnMouseUp` on `SecureActionButtonTemplate` frames — use `PostClick` for post-action logic only; use `type=macro` with `/use item:ID` for item use
- All files must have a standard header comment block at the top: `-- Addon : OdysseusUtilitySuite / -- File : FileName.lua / -- Version : YYYY.MM.DD / -- Desc : brief description`
- Before every commit, update the TOC `## Version:` field to the current date in `YYYY.MM.DD` format — no commit without a version bump

---

## Adding a New Module (checklist)
1. Create `NewModule.lua` in the addon root
2. Add the module toggle default in `Core.lua` ADDON_LOADED block: `if OdysseusDB.modules.newModule == nil then OdysseusDB.modules.newModule = true end`
3. Add the file to `OdysseusUtilitySuite.toc` in section 4 (before Config.lua)
4. If the module has settings, expose defaults as `OUS.newModuleDefaults` and wire reset into `OUS.ResetAllSettings()`
5. If the module has per-character settings, initialize under `OdysseusCharDB.<moduleKey>` in `Core.lua` ADDON_LOADED block
6. Add config panel wiring in `Config.lua` or a dedicated `newmodule_config.lua` loaded after the engine
7. Add a Toolbox button entry to `BUTTONS` table in `Toolbox.lua` if the module has a toggleable frame or opens a config tab
8. Add slash commands to the relevant tab in `Help.lua`

---

## Slash Commands (existing — don't duplicate)
- `/ous` — toggle config window
- `/ous help` — help frame
- `/ous debug` — alias for ousdebug
- `/ous fish` — toggle fishing tracker
- `/ousdebug` — toggle debug console
- `/xpstats`, `/ousxp` — xpbar commands
- `/toasttest`, `/delvetest`, `/delvedebug` — xpbar debug
- `/ar`, `/autoremount` — AutoRemount module commands
- `/sb`, `/statsbar` — StatsBar module commands
- `/op`, `/openables` — Openables module commands
- `/tb`, `/toolbox` — Toolbox module commands (`toggle`, `lock`, `unlock`, `scale [n]`, `ver`, `hor`)
- `/ous_rare` — Utilities rare announcer (target a mob first)

---

## What "refinement phase" means
The addon is feature-complete and stable. Tasks should be minimal and surgical:
- Prefer fixing or improving existing code over restructuring
- Do not rename functions, tables, or SavedVariables keys (breaks live saved data)
- Do not change TOC load order without explicit instruction
