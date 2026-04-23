-- ==========================================
-- ODYSSEUS UTILITY SUITE: AUTO REMOUNT SPELL DATABASE
-- ==========================================
-- Gathering spell IDs by profession and expansion.
-- Add new IDs here when Blizzard adds new content.
-- Collect unknown spellIDs via /etrace in-game.
local addonName, OUS = ...

OUS.AutoRemountSpells = {

    -- ==========================================
    -- MISCELLANEOUS
    -- ==========================================
    3365,       -- Opening: generic chest/lock interaction
    98324,      -- Void-Tainted Remains: special lootable object
    6478,       -- Tools: knowledge point nodes
    6247,       -- Coalesced Light: special interactable

    -- ==========================================
    -- LUMBER / LOGGING (all expansions share one ID)
    -- ==========================================
    1239682,    -- Logging: all expansions

    -- ==========================================
    -- MINING
    -- ==========================================
    2575,       -- Mining: generic fallback

    265837,     -- Mining: Classic
    265839,     -- Mining: The Burning Crusade
    265841,     -- Mining: Wrath of the Lich King
    265843,     -- Mining: Cataclysm
    265845,     -- Mining: Mists of Pandaria
    265847,     -- Mining: Warlords of Draenor
    265849,     -- Mining: Legion
    265851,     -- Mining: Battle for Azeroth
    309835,     -- Mining: Shadowlands
    366260,     -- Mining: Dragonflight
    423341,     -- Mining: The War Within
    471013,     -- Mining: Midnight

    -- ==========================================
    -- HERBALISM
    -- ==========================================
    2366,       -- Herbalism: generic fallback

    265819,     -- Herbalism: Classic
    265821,     -- Herbalism: The Burning Crusade
    265823,     -- Herbalism: Wrath of the Lich King
    265825,     -- Herbalism: Cataclysm
    265827,     -- Herbalism: Mists of Pandaria
    265829,     -- Herbalism: Warlords of Draenor
    265834,     -- Herbalism: Legion
    265835,     -- Herbalism: Battle for Azeroth
    309780,     -- Herbalism: Shadowlands
    366252,     -- Herbalism: Dragonflight
    441327,     -- Herbalism: The War Within
    471009,     -- Herbalism: Midnight
}