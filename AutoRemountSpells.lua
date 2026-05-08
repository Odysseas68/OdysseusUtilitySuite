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
    [134065]  = true,   -- Trap disarm (generic)
    [247077]  = true,   -- Trap disarm (generic)
    [1259286] = true,   -- Attempting to Disarm Trap
    [1242005] = true,   -- Attempting to Disarm Trap
    [1259477] = true,   -- Attempting to Disarm Trap
    [179665] = true,    -- Disable ALL Mounts

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
    [451190] = true,    -- Collecting
    [6477] = true,      -- Opening
    [409086] = true,    -- Collecting
    [396468] = true,    -- Collecting
    [291920] = true,    -- Collecting
    [32605] = true,     -- Herb Gathering
    [262151] = true,    -- Collecting
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
    [105174]  = true,   -- Hand of Gul'dan
    [264178]  = true,   -- Demonbolt
    [686]     = true,   -- Shadow Bolt
    [1224771] = true,   -- Void Hole Fishing
    [1265750] = true,   -- [DNT] Sniping
    [1236931] = true,   -- [DNT] Battle Ring Attacker Ping
    [1225385] = true,   -- Grasping Shadows
    [179665]  = true,   -- Disable ALL Mounts
    [1254138] = true,   -- Arcane Charge
    [430229]  = true,   -- Unlocking
    [1251677] = true,   -- [DNT] Bonus Event - Active Aura
    [198137]  = true,   -- Divine Hammer
    [431398]  = true,   -- Empyrean Hammer
    [1234109] = true,   -- Rummaging
    [184575]  = true,   -- Blade of Justice
    [32606]   = true,   -- Mining
    [1236467] = true,   -- Gleeful Glamour - Gnome
    [1241675] = true,   -- 12.0 Delves - DevouringHost01 - V01 - Injured Solider: Interact (Hufton)
    [1243709] = true,   -- Punt!
    [434635] = true,    -- Ruination
    [104316] = true,    -- Call Dreadstalkers
    [1239318] = true,   -- Heavy Mists
    [1239227] = true,   -- Fishing
    [1263680] = true,   -- Light Spores
    [20271] = true,     -- Judgment
    [24275] = true,     -- Hammer of Wrath
    [383328] = true,    -- Final Verdict
    [408385] = true,    -- Crusading Strikes
    [255937] = true,    -- Wake of Ashes
    [454351] = true,    -- Avenging Wrath
    [434506] = true,    -- Infernal Bolt
    [1288478] = true,   -- Activate
    [30146] = true,     -- Summon Felguard
    [119914] = true,    -- Axe Toss
    [1231411] = true,   -- Recuperate
    [1288474] = true,   -- Analyzing
    [8386] = true,      -- Attacking
    [1247818] = true,   -- [DNT] Altar - Auto-Collect
    [1236942] = true,   -- Divine Hammer
    [1270789] = true,   -- Kill Credit [DNT]
    [115750] = true,    -- Blinding Light
    [1236535] = true,   -- [DNT] Add to Scenario Defense
    [295727] = true,    -- Compressed Ocean Fishing
    [1270530] = true,   -- Studying
    [131474] = true,    -- Fishing
    [101847] = true,    -- Shoe Baby
    [467455] = true,    -- NoCho
    [783] = true,       -- Travel Form
    [149653] = true,    -- Jump Forward - Land
    [1227965] = true,   -- Alndust Toss
    [361652] = true,    -- Demonic Gateway
    [132411] = true,    -- Singe Magic
    [259072] = true,    -- Bonus Roll 3.0
    [1248091] = true,   -- Unlocking
    [432573] = true,    -- Cozy Fire
    [1270531] = true,   -- Studying
    [1286595] = true,   -- Investigating
    [1270421] = true,   -- Destroy
    [258303] = true,    -- Burning
    [461749] = true,    -- Opening
    [234153] = true,    -- Drain Life
    [250491] = true,    -- Destroying
    [6201] = true,      -- Create Healthstone
    [1244973] = true,   -- Anomaly Collector
    [1265824] = true,   -- [DNT] Void Power Credit - T1
    [1225292] = true,   -- Fishing Journal - Looted - Learn - Entry
}