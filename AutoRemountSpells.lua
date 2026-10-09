-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : AutoRemountSpells.lua
-- Version : 2026.10.09
-- Desc    : AutoRemount built-in spell and exclusion database
-- ============================================================

-- ==========================================
-- ODYSSEUS UTILITY SUITE: AUTO REMOUNT SPELL DATABASE
-- ==========================================
-- Gathering spell IDs by profession and expansion.
-- Add new IDs here when Blizzard adds new content.
-- Collect unknown spellIDs via /ar spy in-game.
local _, OUS = ...

OUS.AutoRemountSpells = {

    -- ==========================================
    -- MISCELLANEOUS
    -- ==========================================
    [1242005] = true,   -- Attempting to Disarm Trap
    [1259286] = true,   -- Attempting to Disarm Trap
    [1259477] = true,   -- Attempting to Disarm Trap
    [6247]    = true,   -- Coalesced Light: special interactable
    [3365]    = true,   -- Opening: generic chest/lock interaction
    [6478]    = true,   -- Tools: knowledge point nodes
    [134065]  = true,   -- Trap disarm (generic)
    [247077]  = true,   -- Trap disarm (generic)
    [98324]   = true,   -- Void-Tainted Remains: special lootable object

    -- ==========================================
    -- [General Interactions]
    -- [Quest / World Quest / Event]
    -- ==========================================
    [262151] = true,    -- Collecting
    [291920] = true,    -- Collecting
    [396468] = true,    -- Collecting
    [409086] = true,    -- Collecting
    [451190] = true,    -- Collecting
    [1283698] = true,   -- Collecting
    [6477] = true,      -- Opening

    -- ==========================================
    -- LUMBER / LOGGING (all expansions share one ID)
    -- ==========================================
    [1239682] = true,   -- Logging: all expansions

    -- ==========================================
    -- MINING
    -- ==========================================
    [265851]  = true,   -- Mining: Battle for Azeroth
    [265843]  = true,   -- Mining: Cataclysm
    [265837]  = true,   -- Mining: Classic
    [366260]  = true,   -- Mining: Dragonflight
    [2575]    = true,   -- Mining: generic fallback
    [265849]  = true,   -- Mining: Legion
    [471013]  = true,   -- Mining: Midnight
    [265845]  = true,   -- Mining: Mists of Pandaria
    [309835]  = true,   -- Mining: Shadowlands
    [265839]  = true,   -- Mining: The Burning Crusade
    [423341]  = true,   -- Mining: The War Within
    [265847]  = true,   -- Mining: Warlords of Draenor
    [265841]  = true,   -- Mining: Wrath of the Lich King

    -- ==========================================
    -- HERBALISM
    -- ==========================================
    [32605] = true,     -- Herb Gathering
    [265835]  = true,   -- Herbalism: Battle for Azeroth
    [265825]  = true,   -- Herbalism: Cataclysm
    [265819]  = true,   -- Herbalism: Classic
    [366252]  = true,   -- Herbalism: Dragonflight
    [2366]    = true,   -- Herbalism: generic fallback
    [265834]  = true,   -- Herbalism: Legion
    [471009]  = true,   -- Herbalism: Midnight
    [265827]  = true,   -- Herbalism: Mists of Pandaria
    [309780]  = true,   -- Herbalism: Shadowlands
    [265821]  = true,   -- Herbalism: The Burning Crusade
    [441327]  = true,   -- Herbalism: The War Within
    [265829]  = true,   -- Herbalism: Warlords of Draenor
    [265823]  = true,   -- Herbalism: Wrath of the Lich King
}

-- ==========================================
-- EXCLUDE LIST
-- ==========================================
-- Spells that open a loot window but should never trigger remount.
-- Add here when a spell is confirmed as a false positive.

OUS.AutoRemountExcludeSpells = {
    -- ==========================================
    -- [Class Spells]
    -- ==========================================

    -- ==========================================
    -- [Profession / Crafting]
    -- ==========================================

    -- ==========================================
    -- [Studying / Learning]
    -- ==========================================

    -- ==========================================
    -- [Fishing]
    -- ==========================================

    -- ==========================================
    -- [Travel / Transport / Movement]
    -- ==========================================

    -- ==========================================
    -- [General Interactions]
    -- ==========================================

    -- ==========================================
    -- [Quest / Scenario / Event]
    -- ==========================================

    -- ==========================================
    -- [DNT / Internal]
    -- ==========================================

    -- ==========================================
    -- [Special Cases]
    -- ==========================================

    -- ==========================================
    -- [Other / Unclassified]
    -- ==========================================
    [1234969] = true,   -- Ethereal Augmentation
}
