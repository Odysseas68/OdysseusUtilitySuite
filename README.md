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

### Experience, Reputation & Delves Bar
A modular tracking bar system for modern Retail progression.

Highlights:
- experience tracking
- reputation tracking at max level
- Renown support
- Friendship faction support
- Paragon support
- Warband-aware reputation text parsing
- remembered reputation fallback behavior at max level
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
- update pipeline support through your local `Update_flights.py`

Notes:
- the timer prefers learned saved timings first, then bundled database values
- the addon keeps the standalone config frame; it does not replace Blizzard’s default taxi UI

---

### Flight Routing
The routing module enhances taxi destination previews.

Highlights:
- hovered destination itinerary sidebar
- route hop breakdown
- custom line drawing on the taxi / flight map
- generated route database support
- stable multi-hop map path rendering

---

### Faster Loot
A fast auto-loot module that tries to stay safe and predictable.

Highlights:
- respects manual loot choice
- respects group-loot situations that require player interaction
- avoids interfering with locked items
- yields correctly to the Fishing Tracker for bobber loot
- reveals the Blizzard loot frame when loot cannot be completed automatically

---

### Fishing Tracker
A location-aware fishing tracker with session and global statistics.

Highlights:
- tracks catches by zone and sub-zone
- session and overall statistics
- fish-per-hour tracking
- expansion-aware fishing profession naming by zone
- auto-close options for inactivity / mounting
- separate currency tracking
- item quality coloring in lists
- trash filtering
- support for double-loot cases such as fish + item or fish + currency

Current tracking behavior:
- fish count toward catch totals and fish-per-hour
- currencies are tracked separately
- both fish and currencies can still appear in the catch lists

---

## Commands

### Main
- `/ous` — open the main configuration window
- `/ous help` — open the on-screen help window

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

- Built for **WoW Retail**
- Midnight-themed standalone configuration UI
- Modular structure with minimal coupling between systems
- Local script pipeline used for generated databases and maintenance tasks
- Flight and faction helper scripts are local-development tools and are not required by end users

---

## Installation

1. Download or copy the `OdysseusUtilitySuite` folder.
2. Place it in:

   `World of Warcraft/_retail_/Interface/AddOns/`

3. Launch the game.
4. Enable the addon from the character AddOns list.
5. Type `/ous` to open the configuration window.

---

## Current Focus

The addon is currently in an active refinement phase, with recent work focused on:
- Flight Master timing and route presentation
- Fishing Tracker and Faster Loot cooperation
- config UI polish and Midnight-theme improvements
- XP / Reputation / Delves behavior refinement