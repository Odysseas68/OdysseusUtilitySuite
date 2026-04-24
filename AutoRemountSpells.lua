-- ==========================================
-- ODYSSEUS UTILITY SUITE: AUTO REMOUNT SPELL DATABASE
-- ==========================================
-- Gathering spell IDs by profession and expansion.
-- Add new IDs here when Blizzard adds new content.
-- Collect unknown spellIDs via /ar spy in-game.
local addonName, OUS = ...

OUS.AutoRemountSpells = {

    -- ==========================================
    -- MISCELLANEOUS
    -- ==========================================
    [3365]    = true,   -- Opening: generic chest/lock interaction
    [98324]   = true,   -- Void-Tainted Remains: special lootable object
    [6478]    = true,   -- Tools: knowledge point nodes
    [6247]    = true,   -- Coalesced Light: special interactable

    -- ==========================================
    -- LUMBER / LOGGING (all expansions share one ID)
    -- ==========================================
    [1239682] = true,   -- Logging: all expansions

    -- ==========================================
    -- MINING
    -- ==========================================
    [2575]    = true,   -- Mining: generic fallback

    [265837]  = true,   -- Mining: Classic
    [265839]  = true,   -- Mining: The Burning Crusade
    [265841]  = true,   -- Mining: Wrath of the Lich King
    [265843]  = true,   -- Mining: Cataclysm
    [265845]  = true,   -- Mining: Mists of Pandaria
    [265847]  = true,   -- Mining: Warlords of Draenor
    [265849]  = true,   -- Mining: Legion
    [265851]  = true,   -- Mining: Battle for Azeroth
    [309835]  = true,   -- Mining: Shadowlands
    [366260]  = true,   -- Mining: Dragonflight
    [423341]  = true,   -- Mining: The War Within
    [471013]  = true,   -- Mining: Midnight

    -- ==========================================
    -- HERBALISM
    -- ==========================================
    [2366]    = true,   -- Herbalism: generic fallback

    [265819]  = true,   -- Herbalism: Classic
    [265821]  = true,   -- Herbalism: The Burning Crusade
    [265823]  = true,   -- Herbalism: Wrath of the Lich King
    [265825]  = true,   -- Herbalism: Cataclysm
    [265827]  = true,   -- Herbalism: Mists of Pandaria
    [265829]  = true,   -- Herbalism: Warlords of Draenor
    [265834]  = true,   -- Herbalism: Legion
    [265835]  = true,   -- Herbalism: Battle for Azeroth
    [309780]  = true,   -- Herbalism: Shadowlands
    [366252]  = true,   -- Herbalism: Dragonflight
    [441327]  = true,   -- Herbalism: The War Within
    [471009]  = true,   -- Herbalism: Midnight
}

-- ==========================================
-- EXCLUDE LIST
-- ==========================================
-- Spells that open a loot window but should never trigger remount.
-- Add here when a spell is confirmed as a false positive.
OUS.AutoRemountExcludeSpells = {
    [13262]   = true,   -- Disenchant
    [31252]   = true,   -- Milling
    [72575]   = true,   -- Prospecting
    [1280988] = true,   -- Studying: Midnight crafting/research
    [1280992] = true,   -- Studying: Midnight crafting/research (variant)
    [421177]  = true,   -- Disable ALL Mounts
    [195126]  = true,   -- Tailoring
}