# Odysseus Utility Suite — Claude Code Context

## Project Overview
A modular WoW Retail addon (Retail 12.0+) combining quality-of-life utility tools into a single suite. Modules are independently toggled from a shared Midnight-themed config UI opened with `/ous`. A next-generation config UI (OUS2) is under active development, opened with `/ous2`.

**SavedVariables:** `OdysseusDB` (account-wide), `OdysseusCharDB` (per-character)
**Namespace:** `local addonName, OUS = ...` — the `OUS` table is the global shared namespace.

---

## TOC Load Order (strict — do not reorder)
1. `Libs\LibStub\LibStub.lua`
2. `Libs\CallbackHandler-1.0\CallbackHandler-1.0.xml`
3. `Libs\LibDataBroker-1.1\LibDataBroker-1.1.lua`
4. `Libs\LibDBIcon-1.0\lib.xml`
5. `Libs\LibSharedMedia-3.0\LibSharedMedia-3.0.lua`
6. `Core.lua` — creates OUS namespace, DB init, debug engine, slash commands
7. `flightdata.lua` — flight timing database
8. `xpbar_data.lua` — XP/rep data tables
9. `Odysseus_RoutingDB.lua` — flight routing database
10. `AutoRemountSpells.lua` — AutoRemount spell ID database (gather + exclude lists)
11. `StatsBarSpecPriority.lua` — StatsBar spec priority database
12. `OpenablesDB.lua` — Openables item database (700+ itemIDs with min quantities)
13. `Flightmaster.lua` — flight timer/routing engine
14. `Fasterloot.lua` — auto-loot module
15. `Fishingtracker.lua` — fishing session tracker
16. `xpbar_core.lua` — XP/rep bar frame and layout
17. `xpbar_engine.lua` — XP/rep tracking logic
18. `xpbar_delves.lua` — Delves companion tracking
19. `xpbar_favorites.lua` — favorite rep pinning
20. `FlightRouting.lua` — taxi map route rendering
21. `AutoRemount.lua` — auto remount engine
22. `StatsBar.lua` — stats bar engine
23. `Openables.lua` — openables button engine
24. `Utilities.lua` — utility commands (rare announcer, auto repair, junk seller)
25. `Toolbox.lua` — floating icon toolbar engine
26. `Config.lua` — main config UI (loads last)
27. `xpbar_config.lua` — xpbar config panel (loads last)
28. `Help.lua` — tabbed help frame (loads last)
29. `Config2\OUS2Theme.lua` — OUS2 theme registry (textures, colors, fonts, constants)
30. `Config2\OUS2Config.lua` — OUS2 main config frame (loads last)

---

## Architecture Rules

**Namespace:** All module functions and state live on the `OUS` table. Never use bare globals.

**Module toggle pattern:** Each module checks `OdysseusDB.modules.<moduleName>` before initializing. New modules must register a key here in `Core.lua`'s `ADDON_LOADED` block.

**Event-driven:** Use `CreateFrame("Frame")` + `:RegisterEvent()` + `:SetScript("OnEvent", ...)`. No polling loops. No `OnUpdate` for state checks.

**Defaults pattern:** Each module exposes its defaults table as `OUS.<moduleDefaults>`. `OUS.ResetAllSettings()` in Core.lua iterates these — new modules must follow the same pattern.

**Debug logging:** Use `OUS.LogDebug("ModuleName", "message")` — never `print()` for debug output.

**Config wiring:** New module config panels attach to `OUS.ConfigFrame` (built in `Config.lua`). Config always loads last so it can reference any module's state.

**Per-character settings:** Use `OdysseusCharDB` (declared as `SavedVariablesPerCharacter` in the TOC). Account-wide settings go in `OdysseusDB`, character-specific settings go in `OdysseusCharDB` under a module key e.g. `OdysseusCharDB.autoRemountChar`, `OdysseusCharDB.statsBar`. Initialize in `Core.lua` ADDON_LOADED block.

**Documentation:** `CLAUDE.md` is long-term engineering documentation. Keep it synchronized with important architectural decisions, coding standards, reusable patterns, and project rules. Do not store temporary debugging sessions or transient implementation experiments here.

**Third-party compatibility:** Prefer addon ecosystem standards over addon-specific workarounds. OUS uses LibDataBroker-1.1 + LibDBIcon-1.0 for the minimap launcher; third-party minimap managers own launcher visibility and presentation. Do not add HidingBar-specific or similar addon-specific minimap workarounds.

**Minimap launcher SavedVariables:**
```lua
OdysseusDB.minimap = {
    hide = false,
    minimapPos = 225,
}
```
Legacy `OdysseusDB.showMinimapButton` and `OdysseusDB.minimapAngle` migrate to this structure in `Core.lua`.

**Retail-safe aura lessons:** Future BuffBars work should follow the validated `Reference\OdysseusBuffBarsTest\` proof-of-concept without copying it wholesale. The reference is validated for Retail 12.0.x, but WoW 12.1 aura restrictions may invalidate direct aura scanning by index, slot, aura instance ID, or aura tooltip data while auras are secret. Before integrating BuffBars into OUS, research 12.1 `ManagedAuraContainer`, `AuraContainer`, and `AuraButton` patterns and build a separate prototype. The 12.0.x reference rules remain useful design history: cache by `auraInstanceID`, preserve previous readable values when aura fields become secret, gate unsafe aura values with `issecretvalue` / `canaccessvalue`, use duration objects for timer text when available, avoid sorting secret fields in Lua, and avoid secure cancel overlay mutation or anchor rebuilds in combat.

---

## OUS2 Config UI Notes

OUS2 is the next-generation configuration window. Files live in `Config2\`.

**Namespaces:**
- `OUS.Theme` (alias `local T = OUS.Theme`) — texture registry, colors, fonts, constants
- `OUS.Config2` (alias `local C = OUS.Config2`) — frame state, page system, public API

**Texture path:** `Interface\\AddOns\\OdysseusUtilitySuite\\media\\Textures\\`
All TGA files sit flat in this directory — no `Assets/` subfolder.
Always access via `T.Tex(key)` helper — never hardcode paths in page files.

**Slash command:** `/ous2` — handler registered in `Core.lua` (not OUS2Config.lua), calls `OUS.Config2.Toggle()`.

**Current status:** Phase 4 module-page migration is complete. Current focus is Phase 5 — Polish & Advanced Controls.

**Completed OUS2 pages:** General, Utilities, Openables, Stats Bar, Auto Remount, Fishing Tracker, Flightmaster, Flight Routing, Faster Loot, Toolbox, XP Bar, and Delves.

**XP Bar migration:** Complete. The registered `XPBar` page is a hub with internal Global, Experience, Reputation, Favorites, and Help views. The separate registered `Delves` page is complete and provides Back to XP Bar navigation.

**Phase 5 follow-up:** General page polish, enabled/disabled card states, module count summary, Global Options functionality, reset semantics review, XP Bar color controls, Favorites management API review, Delves lock/unlock review, Toolbox expansion, Faster Loot rules, pending OUS2 left-navigation Help page and Changelog page, and helper extraction.

**Public API:**
```lua
OUS.Config2.RegisterPage(pageName, pageFrame, refreshFn)  -- wire a page into the nav
OUS.Config2.OpenPage(pageName)    -- show window and switch to named page
OUS.Config2.Toggle()              -- show/hide window
OUS.Config2.SetHelpText(text)     -- update help panel (call on setting hover)
OUS.Config2.ClearHelpText()       -- reset help panel (call on mouse leave)
C.pageContainer                   -- scroll child frame; parent all page content here
```

**Page file pattern:**
```lua
local addonName, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local pageFrame = CreateFrame("Frame", nil, C.pageContainer)
pageFrame:SetAllPoints()
pageFrame:Hide()

local function Refresh()
    -- read OdysseusDB and update widget states
end

-- Wire hover help text on any setting widget:
widget:SetScript("OnEnter", function() C.SetHelpText("Description.") end)
widget:SetScript("OnLeave", function() C.ClearHelpText() end)

OUS.Config2.RegisterPage("PageName", pageFrame, Refresh)
```

**Internal page name keys** (use exactly these strings):
`General, XPBar, Delves, FlightMaster, FlightRouting, Utilities, Openables, StatsBar, AutoRemount, FasterLoot, FishingTracker, Toolbox, Help, Changelog`

**NineSlice:** Manual placement only. `NineSliceUtil.ApplyLayout` is atlas-only and does NOT work with custom TGA files — never use it.

**Emoji in WoW:** Emoji characters (🔒🔓 etc.) render as blank boxes in WoW's font system. Never use emoji for UI state or button labels — use textures (`Checkbox_Checked/Unchecked.tga`) and font strings with plain ASCII text instead.

**Scrollbar architecture (OUS2):**
- `scrollTest` container is parented to `contentPanel`, anchored `TOPRIGHT`/`BOTTOMRIGHT` — NOT to `frame`
- Track height = `scrollTest:GetHeight()` (auto-follows panel height via anchors)
- Thumb position recalculated in `UpdateCustomThumb()` on `OnVerticalScroll`
- `trackW = 10`, `thumbMinH = 60`, `thumbRatio = 0.30`, `scrollStep = 18`

**Debug border:** A temporary cyan 1px `BackdropTemplate` border exists on `contentPanel` for layout verification — remove before committing the General page.

**Frame constants (from OUS2Theme.lua — do not hardcode in page files):**
```lua
T.Frame.navWidth     = 140    -- left nav panel width
T.Frame.helpWidth    = 150    -- right help panel width
T.Frame.panelGap     = 8      -- gap between panels
T.Frame.headerHeight = 60     -- reserved top area
T.Frame.footerHeight = 40     -- reserved bottom area
T.Frame.cornerSize   = 80     -- NineSlice corner display size
```

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
- Legacy `UIPanelScrollFrameTemplate` replaced with `WowScrollBox` + `MinimalScrollBar` (modern 12.0.5 pattern)
- Content frames lazy-created per tab on first visit; `helpScrollFrames[index]` stores `{ box, bar, child }` — all three must be shown/hidden together on tab switch because `WowScrollBox` reparents `child` internally via `ReparentScrollChildren`, so hiding `box` alone does not hide `child`
- Compact banner (200×100) + title + separator on `helpContent` panel, shared across all tabs

---

## Scrollbar API (Retail 12.0.5 — verified from wow-ui-source)
**Confirmed vertical templates:** `MinimalScrollBar`, `WowTrimScrollBar`
**Confirmed horizontal template:** `WowTrimHorizontalScrollBar`
**Does NOT exist in 12.0.5:** `WowScrollBar` — do not use

**Standard wiring pattern for static content:**
```lua
local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBox")
local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)
local child = CreateFrame("Frame", nil, scrollBox)
child.scrollable = true  -- required: ReparentScrollChildren only picks up frames with this flag
-- populate child with content here
local view = CreateScrollBoxLinearView()
view:SetPanExtent(20)
ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)
```
- `child.scrollable = true` is mandatory — without it `ReparentScrollChildren` ignores the frame and nothing scrolls
- Do NOT use `CreateScrollBoxListLinearView` for static content — that requires a `DataProvider` and is for data-driven lists only
- Do NOT call `ScrollUtil.InitScrollBoxListWithScrollBar` for static content — use `InitScrollBoxWithScrollBar`
- When using in a tabbed UI, store `{ box, bar, child }` and hide/show all three on tab switch

**MinimalScrollBar texture key paths** (verified via in-game dump):
- `scrollBar.Track.Begin/Middle/End` — direct textures (track rail background); call `:SetVertexColor(r, g, b)`
- `scrollBar.Track.Thumb.Begin/Middle/End` — sub-textures one level deeper (draggable thumb); call `:SetVertexColor(r, g, b)`
- `scrollBar.Back.Texture` — up arrow texture
- `scrollBar.Forward.Texture` — down arrow texture
- Always guard each access with `if` checks against nil before calling `:SetVertexColor`

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
- `D:/WoWDev/Reference/Blizzard/wow-ui-source/` — Gethe mirror of live Blizzard UI source; use `Interface/AddOns/Blizzard_APIDocumentationGenerated/` for secret predicate and API signature verification
- `D:/WoWDev/Reference/Odysseus/OdysseusBuffBarsTest/` — frozen Odysseus reference addon used for BuffBars research
- `D:/WoWDev/Reference/ThirdParty/ElkBuffBars/` — third-party reference addon for historical BuffBars behavior
- `D:/WoWDev/Reference/ThirdParty/LibEQOL/` and `D:/WoWDev/Reference/ThirdParty/LibSettingsDesigner/` — third-party library references
- Keep the engineering workspace outside the World of Warcraft installation. Do not recreate addon-local `Reference` directories or NTFS junctions into `D:/WoWDev`.

---

## Hard Constraints (never violate)
- WoW Retail 12.0+ API only — current interface: `120007`
- No deprecated functions (verify in wow-ui-source before using any unfamiliar API)
- No taint — never hook or replace protected Blizzard frames/functions directly
- No `loadstring`, no `pcall` wrappers around core logic (only around logging, as in Core.lua)
- No multi-file changes in a single task — work one file at a time
- Preserve modular architecture — modules must not directly call functions from sibling modules (go through OUS table)
- For any uncertain or unfamiliar Retail API usage, reference `.github/skills/` local files first, then `D:/WoWDev/Reference/Blizzard/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/` (live Blizzard generated API docs, secret predicate verification), then https://github.com/JBurlison/WoWAddonAPIAgents
- Before using any uncertain WoW API, verify the correct Retail 12.0+ signature and secret predicate status in `D:/WoWDev/Reference/Blizzard/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/` — do not infer API signatures from Classic patterns or training data
- Cross-reference patterns from EnhanceQoL addon (`../EnhanceQoL/`) for modern event-driven approaches.
- Minimal comments only — never narrate what code is doing; only comment *why* when genuinely non-obvious; section headers allowed; short one-line descriptions on functions/helpers/tables
- **No `goto` or `::label::` syntax** — WoW uses Lua 5.1 which does not support these; use nested `if` guards instead
- Character stats (`UnitStat`, `GetCombatRating`, etc.) are gated behind `SecretWhenUnitStatsRestricted` — always cache on stat events, never read live in combat, never compare secret values directly. Known restricted contexts: Mythic+, raid encounters, rated PvP, Timewalking. Known safe: Delves, Ritual Sites, normal/heroic dungeons, open world.
- `GetXPExhaustion()` is valid in Retail 12.0+ — returns rested XP amount or `nil` when not rested. `C_XP` namespace does not exist — do not use it. Safe pattern: `(GetXPExhaustion and GetXPExhaustion()) or 0`
- `tonumber()` does NOT neutralize secret number values in Retail 12.0+ — it passes them through unchanged; use `pcall` around stat reads and format/math operations on stat values (permitted exception: display helpers and stat cache population only, not core logic)
- Secure buttons: never set `OnMouseDown`/`OnMouseUp` on `SecureActionButtonTemplate` frames — use `PostClick` for post-action logic only; use `type=macro` with `/use item:ID` for item use
- **Emoji characters render as blank boxes in WoW's font system** — never use emoji for UI state, button labels, or any in-game text; use textures or plain ASCII text instead
- **NineSlice:** `NineSliceUtil.ApplyLayout` is atlas-only — does NOT work with custom TGA files; always use manual SetPoint placement for custom frame borders
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
9. Create `Config2\OUS2Page_NewModule.lua` and call `OUS.Config2.RegisterPage("NewModule", frame, Refresh)`
10. Add `Config2\OUS2Page_NewModule.lua` to TOC after `Config2\OUS2Config.lua`

---

## Adding a New OUS2 Page (checklist)
1. Create `Config2\OUS2Page_<Name>.lua`
2. Add standard file header comment
3. Parent page frame to `OUS.Config2.pageContainer`, call `SetAllPoints()`, `Hide()`
4. Add module icon (32x32 from `T.Tex("Icon<Name)")`) at top left
5. Add enable/disable checkbox at top right
6. Build settings using `T.Colors`, `T.Fonts`, `T.Tex()` — never hardcode values
7. Wire `OnEnter`/`OnLeave` on every setting row to `C.SetHelpText` / `C.ClearHelpText`
8. Implement `Refresh()` function — reads from `OdysseusDB` and updates widget states
9. Call `OUS.Config2.RegisterPage("Name", pageFrame, Refresh)` at end of file
10. Add `Config2\OUS2Page_<Name>.lua` to TOC in section 6

---

## Slash Commands (existing — don't duplicate)
- `/ous` — toggle legacy config window
- `/ous2` — toggle OUS2 config window (new)
- `/ous help` — help frame
- `/ous debug` — alias for ousdebug
- `/ous fish` — toggle fishing tracker
- `/ousdebug` — toggle debug console
- `/xpstats` — XP Bar session statistics command
- Legacy `/ousxp` alias removed; do not register it again
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
