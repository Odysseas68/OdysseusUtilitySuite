
### ⚡ Faster Loot Module (Safety & API Compatibility Update)
* **Cross-Version API Support:** Updated the loot-method detection to be fully compatible with both Classic WoW and modern Retail WoW (safely bypassing Blizzard's removal of the `GetLootMethod` command in Retail).
* **Advanced Bag Protection:** The auto-close feature now actively monitors your inventory. It specifically looks for standard bag slots (safely ignoring specialized Reagent or Profession bags). If you have 1 or fewer general slots available, it will still lightning-loot money and stackables, but will forcefully leave the window open so you never accidentally abandon unstackable gear on a corpse!

--------------------------------------------------------

Odysseus Utility Suite - Latest Update 18/3/2026
⚡ Faster Loot Module (Group & Raid Safety Update)

    Smart Group Looting: The module now fully respects group and raid loot rules (Master Loot, Group Loot, Need Before Greed). It actively checks the party's loot threshold and will safely ignore items that require a roll or manual distribution.

    Locked Item Detection: Added a strict safety check to prevent the addon from attempting to auto-loot locked boxes that require lockpicking or specific keys.

    Intelligent UI Yielding: The visual loot window will now aggressively auto-close only if every single item on the corpse was successfully looted. If an item is left behind for a group roll, the window safely stays open so you can see what dropped and interact with it normally.

-------------------------------------------------

Odysseus Utility Suite - Latest Update
🎣 Fishing Tracker Module (Major Overhaul)

    New Loot Detection Engine: Completely replaced the legacy chat-log parser with a native LOOT_READY event hook. It now reads item data directly from the game engine, guaranteeing 100% accuracy and bypassing chat-tab filter bugs.

    Expansion-Accurate Skill Names: Implemented a backend Zone ID mapping system. The UI now correctly displays modern profession tiers (e.g., Midnight Fishing, Khaz Algar Fishing) instead of the default generic "Fishing" tag.

    Global Statistics Dashboard: Added a brand new "Overall Stats" frame. Features a scrollable, full-database dashboard sortable by "Fish" (all-time catches) and "Zone" (locations fished), including total unique sub-zones discovered.

    Smart Auto-Close System: The tracker can now automatically hide itself to keep your screen clean.
        Automatically pauses the countdown while your bobber is actively in the water.
        Triggers countdown if you go AFK or mount/skyride away.
        Warns you with a discrete "Closing in: 10s" text only during the final 10 seconds.

    UI & Visual Upgrades:
        Widened the Main and Session frames to ensure text is never cut off.
        Implemented a clean, unified 3-column layout across all frames (Fish Name, Count, Percent) with perfectly centered metrics.
        Item names are now dynamically colored based on their in-game item quality hex codes.
        Added summary headers for "Current Location Stats" and "Total caught this session".

    Fish-Per-Hour Metric: Added a real-time fish/hr rolling average to the Session Frame. Throttled to update every 15 seconds to prevent visually distracting UI flickering.

    Database Upgrades: Upgraded the OdysseusDB backend to quietly track sub-zones. Included backward-compatibility logic to protect and seamlessly merge old save data without throwing Lua errors.

⚡ Faster Loot Module

    Module Synchronization: Faster Loot now perfectly communicates with the Fishing Tracker. Added an IsFishingLoot() gatekeeper so Faster Loot automatically yields to the fishing bobber, allowing the tracker to log the fish before Faster Loot cleans up the window.

⚙️ Configuration Menu (config.lua)

    New Fishing Tracker Tab: Built out a dedicated settings tab matching the clean Midnight Theme aesthetic.

    Auto-Close Controls: Added simple checkboxes to toggle Auto-Close on AFK or Mount, alongside an interactive slider to set the exact delay timer (10s to 60s).

    Database Management: Added a secure "Wipe Saved Data" button specifically for the Fishing Tracker. It includes a StaticPopupDialog confirmation warning to prevent accidental deletions.