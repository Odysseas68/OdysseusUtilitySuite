# Odysseus Utility Suite

**Odysseus Utility Suite** is a modular Quality-of-Life addon for **World of Warcraft Retail** focused on utility, visibility, and clean customization.

It combines several standalone tools into one suite while keeping each module independently toggleable from a single Midnight-themed configuration window.

---

## Modules

### Central Configuration
The suite uses the OUS2 Midnight-themed configuration frame, opened with `/ous` or `/ous2`.

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
- scrollable session statistics for experience, reputation, gross personal gold gained/spent, attributable Own-funds repairs, junk quantity/value, and Midnight Season 2 Mistcrests
- confirmed Reset Counters clears current-session gains without clearing saved history; Gold Debug provides copyable diagnostics and a highlighted field reference
- Session Stats display and Mistcrest controls within the XP Bar configuration page
- reward toast notifications
- Delves companion + journey tracking
- configurable fade / wake / auto-hide behavior

Commands:
- `/xpstats`

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

### Utilities
A collection of small but powerful QoL tools bundled into one module.

**Extra Action Button artwork**:
- Optional `OdysseusDB.utilities.hideExtraActionArtwork` setting (default: `false`)
- Hides only Blizzard's decorative artwork around the Extra Action Button and Zone Ability frame; buttons, icons, cooldowns, clicks, positioning, and Edit Mode remain Blizzard-owned
- Creates no replacement border or backdrop
- Disable Enhance QoL's equivalent hide-artwork option when using the OUS setting so both addons do not control the same Blizzard artwork

**Rare Announcer** (`/ous_rare`):
- Target any mob and announce its name, classification, and location to General chat
- Classification tags: `[Rare]`, `[Rare Elite]`, `[Elite]`, `[World Boss]`, `[Normal]`
- Native Blizzard waypoint hyperlink — click in chat to open world map at the location
- TomTom support — activates the navigation arrow automatically if TomTom is installed
- Open world only guard

**Auto Repair**:
- Automatically repairs all items when a merchant is opened
- Guild First uses one native repair request when guild repair is permitted, without relying on cached Guild Bank coverage; Blizzard uses available guild repair resources and charges personal funds for any remainder
- Otherwise uses own gold with the existing affordability check
- Optional chat reports personal repair cost using Own funds, or the quoted bill as a Guild-first repair request without guessing funding
- Guild-first personal spending still counts toward Session Stats Gold Spent, but its unproven split is omitted from Repairs; no Guild Repairs row is shown

**Junk Seller**:
- Automatically sells grey quality items when a merchant is opened
- Sells one bag entry per 0.2s to avoid "Item is busy" errors; reported item totals count physical stack quantities
- Limit to 12 bag entries per batch (configurable) — `Sell Next 12 (X left)` button for remainder
- Button remains available while the merchant is open and Junk Seller is enabled, inside the bottom-left footer
- Optional Shift protection applies to automatic/delayed batch starts and button clicks
- Sale values use the actual bag-item hyperlink's per-unit vendor price multiplied by stack quantity
- Optional Detailed Sale Report (default OFF) prints one clickable item link, quantity, and whole-stack value per accepted sale; Announce Junk Sales controls the final summary separately
- Per-item blacklist to exclude specific items from selling
- Combat safe — stops immediately on combat lockdown

**OUS Junk broker**:
- LibDataBroker display for current carried grey-junk vendor value, including blacklisted grey items and physical stack quantities
- Uses current bag-item hyperlink pricing consistent with Junk Seller, with colored Blizzard coin amounts; `*` indicates values still loading
- Tooltip shows current bag quantity/value and Session Stats junk totals; Reset Counters clears only session totals, not bag values
- Left-click shows Session Stats; right-click shows Gold Diagnostics without toggling either closed
- Works with Titan Panel and other LDB hosts; Titan is not required

Commands:
- `/ous_rare` — announce targeted mob to General chat with waypoint

---

### Toolbox
A floating icon bar giving one-click access to all active OUS module panels.

Highlights:
- one icon per active module — OUS Config, XP Bar Stats, Flight Master, Fishing Tracker, Auto Remount, Stats Bar, Openables
- horizontal and vertical layout modes, toggleable live
- drag handle overlay when unlocked — icon buttons disabled during repositioning
- smart screen-aware popup positioning — layout orientation drives the direction, available screen space drives the side
- Openables quick-action popup: Mass Add, Custom List, Blacklist — Midnight-themed, anchors intelligently relative to bar position
- Stats Bar toggle is mode-aware — hides whichever frame is currently active without changing mode
- Flight Master and Auto Remount buttons open Config on their respective tab; click again to close
- scale, position, direction, and lock state persisted across sessions
- enable/disable toggle in Config General tab

Commands:
- `/tb toggle` — show/hide toolbox
- `/tb lock` / `/tb unlock` — lock or unlock position
- `/tb scale [0.5-2.0]` — set icon scale
- `/tb ver` / `/tb hor` — switch layout direction
- `/toolbox` — alias for `/tb`

---

### Faster Loot
A fast auto-loot module that respects group loot, locked items, and bag-full situations.

---

### Fishing Tracker
A location-aware fishing tracker with session and global statistics, fish-per-hour tracking, currency tracking, and trash filtering.

---

## Commands

### Toolbox
- `/tb` / `/toolbox` — full command set (see Toolbox section above)

### Main
- `/ous` — open the OUS2 configuration window
- `/ous2` — alias for the OUS2 configuration window
- `/ous help` — open the on-screen help window

### Openables
- `/op` / `/openables` — full command set (see Openables section above)

### Stats Bar
- `/sb` / `/statsbar` — full command set (see Stats Bar section above)

### Auto Remount
- `/ar` / `/autoremount` — full command set (see Auto Remount section above)

### XP / Reputation
- `/xpstats`

### Utility / Debug
- `/toasttest`
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
4. Type `/ous` to open the OUS2 configuration window.

---

## Current Focus

OUS2 is the primary configuration framework. Current focus is post-migration polish and feature expansion.

Completed OUS2 pages:
- General
- Utilities
- Openables
- Stats Bar
- Auto Remount
- Fishing Tracker
- Flightmaster
- Flight Routing
- Faster Loot
- Toolbox
- XP Bar

XP Bar migration is complete: its OUS2 page is a hub for Global, Experience, Reputation, Favorites, Session Stats, and Help child views. Delves configuration remains available through XP Bar, including Back to XP Bar navigation, but no longer has a standalone sidebar or General dashboard entry.

Phase 5 follow-up work:
- General page polish
- Enabled/disabled card states
- Module count summary
- Global Options functionality
- Reset semantics review
- XP Bar color controls
- Favorites management API review
- Delves lock/unlock review
- Flightmaster advanced controls
- Toolbox expansion
- Faster Loot rules
- Pending OUS2 left-navigation Help page
- Pending OUS2 left-navigation Changelog page
- Helper extraction
