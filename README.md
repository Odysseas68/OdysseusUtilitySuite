# Odysseus Utility Suite

**Odysseus Utility Suite** is a modular Quality-of-Life addon for **World of Warcraft Retail** focused on utility, visibility, and clean customization.

It combines several standalone tools into one suite while keeping each module independently toggleable from a single Midnight-themed configuration window.

---

## Modules

### Central Configuration
The suite includes a standalone configuration frame opened with `/ous`.

Features include:
- per-module enable/disable toggles
- Midnight-themed standalone config UI
- settings grouped by module
- safe reset / wipe actions where appropriate
- Flight Master export support for learned flight-time data

---

### Openables
Scans your bags after every bag update and surfaces a single-click button for the first actionable item found. No more hunting through bags for tier tokens, crest pouches, mounts, pets, or unlearned recipes.

Highlights:
- built-in database of 700+ items spanning Classic through TWW 11.2: tier tokens, crest pouches, sparks, delve keys, coffer key shards, contracts, profession knowledge, gems, enchanting materials, rep insignia, and legacy crafting fragments
- smart collection filtering — already-learned mounts, collected pets, and known toys are automatically skipped via Blizzard collection APIs (`C_MountJournal`, `C_PetJournal`, `C_ToyBox`)
- recipe scanning — unlearned recipes detected dynamically via item class API, no static recipe DB required; already-known recipes filtered via `C_TradeSkillUI` and tooltip data
- dynamic category classification at scan time — no static mapping required
- category-colored border: purple (mount), blue (pet), green (toy), pink (recipe), orange (knowledge), grey (currency), gold (cache)
- category badge overlay: M / P / T / R / K / G — hidden for generic caches
- custom item list — add by ID, drag-and-drop, or remove individually
- per-item minimum quantity threshold so small stacks don't trigger the button
- session blacklist (right-click) and permanent blacklist (Shift+right-click)
- auto-open mode: uses the item automatically 0.3s after a bag update
- scalable button (0.5×–2.0×) with lock/unlock positioning — drag handle shown when unlocked
- cooldown sweep overlay
- blacklist management frame and custom list management frame
- mass add frame: queue multiple items via drag-and-drop, set quantities, commit all at once
- export frame: outputs custom list as ready-to-paste `OpenablesDB.lua` lines
- combat-safe: hides on combat entry, rescans on exit; taint-free secure button implementation

Commands:
- `/op add <itemID> [qty]` — add item to custom list
- `/op remove <itemID>` — remove from custom list
- `/op list` — open blacklist management frame
- `/op clist` — open custom items management frame
- `/op madd` — open drag-and-drop mass add frame
- `/op unblacklist <itemID>` — remove from permanent blacklist
- `/op auto` — toggle auto-open
- `/op lock` / `/op unlock` — lock/unlock button position
- `/op status` — show current settings

---

### Stats Bar
A movable character statistics overlay with two display modes.

Highlights:
- **Single-line mode**: customizable template with stat tokens
- **Table mode**: vertical two-column layout with iLvl, primary stat, and secondaries in spec priority order
- Spec priority database covering all specs from murloc.io (Mythic+)
- Combat-safe: all stats cached on events, never read live in restricted contexts
- Per-character settings — template, font size, table width, position
- Both frames independently movable and lockable
- Font size and table width adjustable live from config or slash commands

Commands:
- `/sb toggle` — toggle on/off
- `/sb table` — toggle table view
- `/sb template <text>` — set single-line template
- `/sb size <8-24>` — set font size
- `/sb lock` / `/sb unlock` — lock/unlock bar position
- `/sb tlock` / `/sb tunlock` — lock/unlock table position
- `/sb tokens` — show all template tokens
- `/sb reset` — reset to defaults
- `/sb status` — show current settings

---

### Auto Remount
Automatically remounts after gathering herbs, mining ore, logging lumber, or any other loot-based interaction. Install and forget.

Highlights:
- spell ID database covering all gathering professions from Classic through Midnight
- per-character and account-wide mount override
- fallback to favourite mount when no override is set
- druid Travel Form skip (toggleable)
- silent mode to suppress mount error messages
- safety checks: combat lockdown, flying, dead/ghost, dungeon/raid instance, profession crafting UI
- no-loot fallback path for interactions without a loot window (e.g. trap disarm)
- spy mode: prints loot-confirmed unknown spells to chat for manual review
- custom spell list and permanent exclude list for false positives
- full slash command set via `/ar` and `/autoremount`

Commands:
- `/ar mount <name>` — set character mount
- `/ar account <name>` — set account-wide mount
- `/ar reset` — clear character mount override
- `/ar reset account` — clear account mount override
- `/ar toggle` — toggle on/off
- `/ar druid` — toggle druid form skip
- `/ar delay <sec>` — set remount delay (0.1–5.0s)
- `/ar silent` — toggle error notifications
- `/ar spy` — toggle spy mode
- `/ar spyfilter` — manage spy filter blacklist
- `/ar add <id>` / `/ar remove <id>` — manage custom spell IDs
- `/ar export` / `/ar wipe` — export or clear custom spell IDs
- `/ar status` — show current settings
- `/ar help` — show all commands

---

### Experience, Reputation & Delves Bar
A modular tracking bar system for modern Retail progression.

Highlights:
- experience tracking
- reputation tracking at max level
- Renown, Friendship faction, Paragon support
- Warband-aware reputation text parsing
- session statistics window
- reward toast notifications
- Delves companion + journey tracking
- configurable fade / wake / auto-hide behavior

Commands:
- `/xpstats`
- `/ousxp`

---

### Flight Master
A flight timer and routing helper for Flight Map / Taxi use.

Highlights:
- learned flight durations saved locally
- bundled + learned route timing lookups
- configurable timer bar
- itinerary sidebar for hovered destinations
- estimated total route time when route data is known
- export workflow for newly learned routes

---

### Flight Routing
Enhances taxi destination previews with itinerary sidebar, route hop breakdown, and custom line drawing on the flight map.

---

### Faster Loot
A fast auto-loot module that respects group loot, locked items, and bag-full situations.

---

### Fishing Tracker
A location-aware fishing tracker with session and global statistics, fish-per-hour tracking, currency tracking, and trash filtering.

---

## Commands

### Main
- `/ous` — open the main configuration window
- `/ous help` — open the on-screen help window

### Openables
- `/op` / `/openables` — full command set (see Openables section above)

### Stats Bar
- `/sb` / `/statsbar` — full command set (see Stats Bar section above)

### Auto Remount
- `/ar` / `/autoremount` — full command set (see Auto Remount section above)

### XP / Reputation
- `/xpstats`
- `/ousxp`

### Utility / Debug
- `/toasttest`
- `/delvetest`
- `/delvedebug`
- `/ousdebug`

---

## Design Notes

- Built for **WoW Retail 12.0+** (Midnight expansion)
- Midnight-themed standalone configuration UI
- Modular structure with minimal coupling between systems
- Event-driven design — no polling loops or `OnUpdate` for state checks
- No taint — secure button implementation via `SecureActionButtonTemplate` with macro attributes; zero `OnMouseDown` scripts on secure frames
- Character stats cached safely — never read live in combat or restricted contexts
- Collection filtering via Blizzard APIs only — no static itemID→collectibleID mapping databases

---

## Installation

1. Download or copy the `OdysseusUtilitySuite` folder.
2. Place it in: `World of Warcraft/_retail_/Interface/AddOns/`
3. Launch the game and enable the addon from the AddOns list.
4. Type `/ous` to open the configuration window.

---

## Current Focus

The addon is in active refinement, with recent work on:
- Openables module: recipe filtering, secure button taint resolution, drag handle UX
- Openables module: smart collection filtering for mounts, pets, toys, and recipes
- Openables module: category-colored borders and badge overlay
- Stats Bar and Auto Remount modules in maintenance/stable phase
