# ⛵ Odysseus Utility Suite

A premium, highly-polished collection of Quality of Life (QoL) modules for World of Warcraft. Designed with a sleek "Midnight" aesthetic, this suite operates efficiently in the background to enhance your gameplay without cluttering your screen.

## 🌟 Core Modules

### ⚙️ Centralized Configuration
Manage your entire suite from a single, beautifully designed dashboard.
* **Dynamic Toggles:** Instantly enable or disable individual modules on the fly.
* **Data Management:** Safely wipe or export your saved database history (with built-in confirmation warnings).
* **SharedMedia Integration:** Fully supports LibSharedMedia for custom fonts, textures, and borders.

### 📊 Experience, Reputation & Delves Bar
A highly customizable, dual-purpose tracking bar that seamlessly adapts to what you are doing in the game.
* **Modern Tracking:** Fully supports Classic Reputations, Friendship Ranks, Renown, and Paragon overflow (including account-wide Warband gains).
* **Delves Auto-Detection:** Utilizes an invisible radar to detect when you enter a Delve, automatically swapping the main bar to a custom UI that tracks your active Companion (Brann Bronzebeard / Valeera Sanguinar) and Journey progress.
* **Smart Auto-Hide:** Configure your bars to smoothly fade out when idle, instantly waking up when you enter combat, gain XP/Reputation, or hover over them with your mouse.
* **Reward Toasts:** Get a stylish, animated popup notification whenever your Renown increases or a Paragon reward box is ready to be claimed! (Hold **Shift** and drag to reposition the popup).
* **Session Stats:** Type `/xpstats` to open a sleek window detailing exactly how much XP and Reputation you've farmed during your current session.

### 🦅 Flight Master
A smart, learning flight timer that tracks your travel network.
* **Dynamic Learning:** Automatically learns and permanently records flight durations the first time you take a path.
* **Smart Map Tooltips:** Hover over a flight node on the map to see the historical flight time and copper cost before you even speak to the Flight Master.
* **Fully Customizable:** Unlock the visual timer bar to drag it anywhere. Fine-tune the width, height, scale, colors, fonts, and borders to match your UI perfectly.

### ⚡ Faster Loot
An ultra-fast, intelligent auto-looter that safely bypasses Blizzard's UI rendering delays.
* **Group-Safe:** Strictly respects Master Loot, Group Loot, and Need Before Greed. It will safely leave the window open for any item that requires a party roll or manual distribution.
* **Smart Bag Protection:** Actively counts your *general* bag slots (ignoring specialized Reagent/Profession bags). If you have 1 or fewer free slots, it will still loot money and stackables, but leaves the window open so you don't miss unstackable gear.
* **Lock-Aware:** Safely ignores locked boxes requiring keys or a Rogue's lockpicking.
* **Module Synergy:** Automatically detects and yields to the Fishing Tracker when looting a bobber.

### 🎣 Fishing Tracker
A comprehensive, professional-grade fishing dashboard and database.
* **Dual Dashboards:** Tracks your "Current Session" and "Overall Global Statistics" with a unified, 3-column layout (Fish Name, Count, Percent).
* **Deep Database:** Records catches by Zone and specific Sub-Zone. Automatically sorts your most-caught fish to the top of the list.
* **Smart Auto-Close:** Configure the tracker to automatically hide itself if you go AFK or mount up, complete with a smooth 10-second warning countdown. Freezes the countdown while you are actively casting!
* **Rich Analytics:** Features real-time Fish-Per-Hour (`fish/hr`) tracking, dynamic item quality color-coding, and automatic trash (grey item) filtering so your database stays clean.
* **Expansion Aware:** Reads Zone IDs to display modern expansion fishing tiers (e.g., *Midnight Fishing*, *Khaz Algar Fishing*).
* **Custom Transparency:** Set the exact alpha level of the tracker's background frames without "ghosting" the text.

## ⚙️ Commands

* `/ous` - Open the Main Configuration Panel.
* `/ous help` - Opens a draggable on-screen mini-window listing all available commands.
* `/xpstats` (or `/ousxp`) - Open the Session XP & Reputation summary window.
* `/toasttest` - Fire a test Reward Popup (Hold **Shift** and drag to move it!).

**Developer Commands:**
* `/delvetest` - Toggles fake data to let you preview and move the Delves UI anywhere in the world.
* `/delvedebug` - Prints advanced instance/scenario IDs to the chat to help calibrate Delve detection.
* `/ousdebug` - Toggles the global developer mode for background process monitoring.

## 🛠️ Installation
1. Download the latest release.
2. Extract the `OdysseusUtilitySuite` folder.
3. Place the folder into your World of Warcraft `_retail_\Interface\AddOns\` directory.
4. Log in and type `/ous` to customize your experience!