-- ==========================================
-- ODYSSEUS UTILITY SUITE: OPENABLES DATABASE
-- ==========================================
-- Format: [itemID] = minQuantity
-- minQuantity = minimum stack count required before showing on button
-- Add items with: /op add <itemID> [minQuantity]

local addonName, OUS = ...

OUS.OpenablesDB = {

    -- ==========================================
    -- THE WAR WITHIN (11.2)
    -- ==========================================

    -- Tier Tokens
    [237584] = 1,   -- Voidglass Contaminant
    [237588] = 1,   -- Binding Agent
    [237592] = 1,   -- Foreboding Beaker
    [237596] = 1,   -- Silken Offering
    [237600] = 1,   -- Yearning Cursemark

    -- Sparks
    [231757] = 2,   -- Fractured Spark of Fortunes

    --Weekly cashes
    [263467] = 1,   -- Avid Learner's Supply Package

    -- ==========================================
    -- THE WAR WITHIN (11.1.7)
    -- ==========================================

    [244901] = 1,   -- D.I.S.C. Loading item

    -- ==========================================
    -- THE WAR WITHIN (11.1 - Undermine)
    -- ==========================================

    -- Tier Tokens
    [228802] = 1,   -- Greased Gallybux
    [228806] = 1,   -- Bloody Gallybux
    [228810] = 1,   -- Gilded Gallybux
    [228814] = 1,   -- Rusty Gallybux
    [228818] = 1,   -- Polished Gallybux

    -- Sparks
    [230905] = 2,   -- Fractured Spark of Fortunes

    -- Crest Pouches
    [231153] = 1,   -- Triumphant Satchel of Carved Undermine Crests
    [231154] = 1,   -- Celebratory Pack of Runed Undermine Crests
    [231264] = 1,   -- Glorious Cluster of Gilded Undermine Crests
    [231267] = 1,   -- Pouch of Weathered Undermine Crests
    [231269] = 1,   -- Satchel of Carved Undermine Crests
    [231270] = 1,   -- Pack of Runed Undermine Crests

    -- Delves
    [233555] = 1,   -- Restored Coffer Key
    [235531] = 1,   -- Restored Coffer Key
    [236096] = 100,   -- Coffer Key Shard

    -- Misc
    [232981] = 1,   -- G99 Installing item

    -- ==========================================
    -- THE WAR WITHIN (11.0)
    -- ==========================================

    -- Tier Tokens
    [225617] = 1,   -- Blasphemer's Effigy
    [225621] = 1,   -- Stalwart's Emblem
    [225625] = 1,   -- Conniver's Badge
    [225629] = 1,   -- Slayer's Icon
    [225633] = 1,   -- Obscenity's Idol

    -- Sparks
    [211297] = 2,   -- Fractured Spark of Omens

    -- Crest Pouches
    [220767] = 1,   -- Triumphant Satchel of Carved Harbinger Crests
    [220773] = 1,   -- Celebratory Pack of Runed Harbinger Crests
    [220776] = 1,   -- Glorious Cluster of Gilded Harbinger Crests
    [221268] = 1,   -- Pouch of Weathered Harbinger Crests
    [221373] = 1,   -- Satchel of Carved Harbinger Crests
    [221375] = 1,   -- Pack of Runed Harbinger Crests

    -- Contracts
    [222597] = 1,   -- Contract: Council of Dornogal
    [222598] = 1,   -- Contract: Council of Dornogal
    [222599] = 1,   -- Contract: Council of Dornogal
    [222600] = 1,   -- Contract: Assembly of the Deeps
    [222601] = 1,   -- Contract: Assembly of the Deeps
    [222602] = 1,   -- Contract: Assembly of the Deeps
    [222603] = 1,   -- Contract: Hallowfall Arathi
    [222604] = 1,   -- Contract: Hallowfall Arathi
    [222605] = 1,   -- Contract: Hallowfall Arathi
    [222606] = 1,   -- Contract: The Severed Threads
    [222607] = 1,   -- Contract: The Severed Threads
    [222608] = 1,   -- Contract: The Severed Threads

    -- Delves
    [218129] = 1,   -- Porcelain Arrowhead Idol
    [225249] = 1,   -- Rattling Bag o' Gold
    [225897] = 1,   -- Brute Force Idol
    [225898] = 1,   -- Idol of the Earthmother
    [225900] = 1,   -- Light-Touched Idol
    [225901] = 1,   -- Streamlined Relic
    [225902] = 1,   -- Idol of Final Will
    [225903] = 1,   -- Amorphous Relic
    [225904] = 1,   -- Time Lost Relic
    [225905] = 1,   -- Olden Seeker Relic
    [225906] = 1,   -- Lifeless Necrotic Relic
    [225907] = 1,   -- Relic of Sentience
    [225908] = 1,   -- Relicblood of Zekvir
    [228582] = 1,   -- Streamlined Relic
    [228984] = 1,   -- Unbreakable Iron Idol
    [229353] = 1,   -- Rage-Filled Idol
    [229899] = 100,   -- Coffer Key Shard
    [233071] = 1,   -- Delver's Bounty

    -- Knowledge / Profession
    [217707] = 5,   -- Imperfect Null Stone
    [224982] = 1,   -- Delver's Dirigible Schematic
    [226258] = 1,   -- Delver's Pouch of Reagents

    -- ==========================================
    -- DRAGONFLIGHT (10.2)
    -- ==========================================

    -- Dream Wardens
    [211374] = 1,   -- Tangled Yarn of Secrets -> "Untangling" -> Dream Wardens rep

    -- Azeronian Archives Tomes
    [213175] = 1,   -- Dusty Djaradin Tome
    [213176] = 1,   -- Preserved Isles Tome
    [213177] = 1,   -- Immaculate Tome
    [213185] = 1,   -- Dusty Centaur Tome
    [213186] = 1,   -- Dusty Niffen Tome
    [213187] = 1,   -- Dusty Drakonid Tome
    [213188] = 1,   -- Dusty Dracthyr Tome
    [213189] = 1,   -- Preserved Drakonid Tome
    [213190] = 1,   -- Preserved Djaradin Tome

    -- Chipped Prismatic Gems
    [210681] = 3,   -- Chipped Quick Topaz
    [210714] = 3,   -- Chipped Deadly Sapphire
    [210715] = 3,   -- Chipped Masterful Amethyst
    [210716] = 3,   -- Chipped Swift Opal
    [210717] = 3,   -- Chipped Hungering Ruby
    [211109] = 3,   -- Chipped Sustaining Emerald
    [220367] = 3,   -- Chipped Stalwart Pearl
    [220371] = 3,   -- Chipped Versatile Diamond

    -- Flawed Prismatic Gems
    [216639] = 3,   -- Flawed Swift Opal
    [216640] = 3,   -- Flawed Masterful Amethyst
    [216641] = 3,   -- Flawed Hungering Ruby
    [216642] = 3,   -- Flawed Sustaining Emerald
    [216643] = 3,   -- Flawed Quick Topaz
    [216644] = 3,   -- Flawed Deadly Sapphire
    [220368] = 3,   -- Flawed Stalwart Pearl
    [220372] = 3,   -- Flawed Versatile Diamond

    -- Prismatic Gems
    [210718] = 3,   -- Hungering Ruby
    [211106] = 3,   -- Masterful Amethyst
    [211107] = 3,   -- Quick Topaz
    [211123] = 3,   -- Deadly Sapphire
    [211124] = 3,   -- Swift Opal
    [211125] = 3,   -- Sustaining Emerald
    [220370] = 3,   -- Stalwart Pearl
    [220374] = 3,   -- Versatile Diamond

    -- Asynchronized Prismatic Gems
    [223904] = 1,   -- Asynchronized Cogwheel Gem
    [223905] = 1,   -- Asynchronized Meta Gem
    [223906] = 1,   -- Asynchronized Tinker Gem
    [223907] = 1,   -- Asynchronized Prismatic Gem

    -- Infinite Threads
    [219276] = 1,   -- Infinite Thread of Critical Strike
    [219277] = 1,   -- Infinite Thread of Haste
    [219278] = 1,   -- Infinite Thread of Speed
    [219279] = 1,   -- Infinite Thread of Leech
    [219281] = 1,   -- Infinite Thread of Versatility
    [219282] = 1,   -- Infinite Thread of Experience

    -- Spools of Eternal Thread
    [226142] = 1,   -- Greater Spool of Eternal Thread
    [226143] = 1,   -- Spool of Eternal Thread
    [226144] = 1,   -- Lesser Spool of Eternal Thread
    [226145] = 1,   -- Minor Spool of Eternal Thread

    -- ==========================================
    -- DRAGONFLIGHT (10.1)
    -- ==========================================

    -- Loamm Niffen
    [205250] = 1,   -- Loamm Niffen Valuable
    [205254] = 1,   -- Honorary Explorer's Compass
    [205342] = 1,   -- Loamm Niffen Insignia
    [205991] = 1,   -- Loamm Niffen - Symbol of Friendship

    -- ==========================================
    -- DRAGONFLIGHT (10.0)
    -- ==========================================

    -- Faction Insignia
    [202091] = 1,   -- Dragonscale Expedition Insignia
    [202092] = 1,   -- Iskaara Tuskarr Insignia
    [202093] = 1,   -- Valdrakken Accord Insignia
    [202094] = 1,   -- Maruuk Centaur Insignia

    -- Misc / Events
    [198614] = 1,   -- Soggy Clump of Darkmoon Cards
    [198790] = 1,   -- I.O.U.
    [201779] = 1,   -- Merithra's Blessing
    [201781] = 1,   -- Memory of Tyr
    [201782] = 1,   -- Tyr's Blessing
    [201783] = 1,   -- Tutaqan's Commendation
    [202670] = 1,   -- Treasure maps "Break Scroll Seal"

    -- Profession Knowledge / Enchanting Materials
    [198675] = 1,   -- lava-infused-seed -- needs to be disenchanted!
    [198689] = 1,   -- stormbound-horn -- needs to be disenchanted!
    [198694] = 1,   -- enriched-earthen-shard -- needs to be disenchanted!
    [198798] = 1,   -- flashfrozen-scroll -- needs to be disenchanted!
    [198799] = 1,   -- forgotten-arcane-tome -- needs to be disenchanted!
    [198800] = 1,   -- fractured-titanic-sphere -- needs to be disenchanted!
    [200939] = 1,   -- Chromatic Pocketwatch
    [200940] = 1,   -- Everflowing Inkwell
    [200941] = 1,   -- Seal of Order
    [200942] = 1,   -- Vibrant Emulsion
    [200943] = 1,   -- Whispering Band
    [200945] = 1,   -- Valiant Hammer
    [200946] = 1,   -- Thunderous Blade
    [200947] = 1,   -- Carving of Awakening
    [201356] = 1,   -- Glimmer of Fire
    [201357] = 1,   -- Glimmer of Frost
    [201358] = 1,   -- Glimmer of Air
    [201359] = 1,   -- Glimmer of Earth
    [210231] = 1,   -- Everburning Core -- needs to be disenchanted!
    [210234] = 1,   -- Essence of Dreams -- needs to be disenchanted!

    -- ==========================================
    -- SHADOWLANDS (9.x)
    -- ==========================================

    [189707] = 1,   -- Pocopoc's Bronze and Gold Body
    [189708] = 1,   -- Pocopoc's Beryllium and Silver Body
    [189709] = 1,   -- Pocopoc's Cobalt and Copper Body
    [189710] = 1,   -- Pocopoc's Ruby and Platinum Body
    [189711] = 1,   -- Pocopoc's Gold and Ruby Components
    [189712] = 1,   -- Pocopoc's Silver and Beryllium Components
    [189713] = 1,   -- Pocopoc's Copper and Cobalt Components
    [189714] = 1,   -- Pocopoc's Platinum and Emerald Components
    [189715] = 1,   -- Pocopoc's Diamond Vambraces
    [189716] = 1,   -- Pocopoc's Face Decoration
    [189717] = 1,   -- Pocopoc's Shielded Core
    [189718] = 1,   -- Pocopoc's Upgraded Core
    [190198] = 5,   -- Sandworn Chest Key Fragment
    [190339] = 1,   -- Enlightened Offering

    -- ==========================================
    -- GENERIC OPENABLES (multi-expansion)
    -- ==========================================

    -- Caches / Bags / Boxes / Pets
    [ 82800] = 1,   -- Pet Cage
    [221495] = 1,   -- Waddles
    [118697] = 1,   -- Pet Supplies
    [120321] = 1,   -- Mystery Bag
    [122514] = 1,   -- Mission Completion Orders
    [122535] = 1,   -- Traveler's Pet Supplies
    [139879] = 1,   -- Crate of Champion Equipment
    [142156] = 1,   -- Order Resources Cache
    [142447] = 1,   -- Torn Sack of Pet Supplies

    -- MoP Crafting Fragments (ore/herb nuggets)
    [100863] = 1,   -- Pattern: Celestial Cloth and Its Uses, some old recipes has no learning spell
    [100865] = 1,   -- Plans: Balanced Trillium Ingot and Its Uses, some old recipes has no learning spell
    [104165] = 1,   -- Kovok, 3rd line contains "Use: Teaches you how to summon and dismiss this companion."
    [108294] = 10,   -- Silver Ore Nugget
    [108295] = 10,   -- Tin Ore Nugget
    [108296] = 10,   -- Gold Ore Nugget
    [108297] = 10,   -- Iron Ore Nugget
    [108298] = 10,   -- Thorium Ore Nugget
    [108299] = 10,   -- Truesilver Ore Nugget
    [108300] = 10,   -- Mithril Ore Nugget
    [108301] = 10,   -- Fel Iron Ore Nugget
    [108302] = 10,   -- Adamantite Ore Nugget
    [108303] = 10,   -- Eternium Ore Nugget
    [108304] = 10,   -- Khorium Ore Nugget
    [108305] = 10,   -- Cobalt Ore Nugget
    [108306] = 10,   -- Saronite Ore Nugget
    [108307] = 10,   -- Obsidium Ore Nugget
    [108308] = 10,   -- Elementium Ore Nugget
    [108309] = 10,   -- Pyrite Ore Nugget
    [108318] = 10,   -- Mageroyal Petal
    [108319] = 10,   -- Earthroot Stem
    [108320] = 10,   -- Briarthorn Bramble
    [108321] = 10,   -- Swiftthistle Leaf
    [108322] = 10,   -- Bruiseweed Stem
    [108323] = 10,   -- Wild Steelbloom Petal
    [108324] = 10,   -- Kingsblood Petal
    [108325] = 10,   -- Liferoot Stem
    [108326] = 10,   -- Khadgar's Whisker Stem
    [108327] = 10,   -- Grave Moss Leaf
    [108328] = 10,   -- Fadeleaf Petal
    [108329] = 10,   -- Dragon's Teeth Stem
    [108330] = 10,   -- Stranglekelp Blade
    [108331] = 10,   -- Goldthorn Bramble
    [108332] = 10,   -- Firebloom Petal
    [108333] = 10,   -- Purple Lotus Petal
    [108334] = 10,   -- Arthas' Tears Petal
    [108335] = 10,   -- Sungrass Stalk
    [108336] = 10,   -- Blindweed Stem
    [108337] = 10,   -- Ghost Mushroom Cap
    [108338] = 10,   -- Gromsblood Leaf
    [108339] = 10,   -- Dreamfoil Blade
    [108340] = 10,   -- Golden Sansam Leaf
    [108341] = 10,   -- Mountain Silversage Stalk
    [108342] = 10,   -- Sorrowmoss Leaf
    [108343] = 10,   -- Icecap Petal
    [108344] = 10,   -- Felweed Stalk
    [108345] = 10,   -- Dreaming Glory Petal
    [108346] = 10,   -- Ragveil Cap
    [108347] = 10,   -- Terocone Leaf
    [108348] = 10,   -- Ancient Lichen Petal
    [108349] = 10,   -- Netherbloom Leaf
    [108350] = 10,   -- Nightmare Vine Stem
    [108351] = 10,   -- Mana Thistle Leaf
    [108352] = 10,   -- Goldclover Leaf
    [108353] = 10,   -- Adder's Tongue Stem
    [108354] = 10,   -- Tiger Lily Petal
    [108355] = 10,   -- Lichbloom Stalk
    [108356] = 10,   -- Icethorn Bramble
    [108357] = 10,   -- Talandra's Rose Petal
    [108358] = 10,   -- Deadnettle Bramble
    [108359] = 10,   -- Fire Leaf Bramble
    [108360] = 10,   -- Cinderbloom Petal
    [108361] = 10,   -- Stormvine Stalk
    [108362] = 10,   -- Azshara's Veil Stem
    [108363] = 10,   -- Heartblossom Petal
    [108364] = 10,   -- Twilight Jasmine Petal
    [108365] = 10,   -- Whiptail Stem
    [108391] = 10,   -- Titanium Ore Nugget

    -- Warlords of Draenor
    [109558] = 1,   -- Draenor 700 skills
    [109586] = 1,   -- Draenor 700 skills
    [109624] = 10,   -- Broken Frostweed Stem
    [109625] = 10,   -- Broken Fireweed Stem
    [109626] = 10,   -- Gorgrond Flytrap Ichor
    [109627] = 10,   -- Starflower Petal
    [109628] = 10,   -- Nagrand Arrowbloom Petal
    [109629] = 10,   -- Talador Orchid Petal
    [109991] = 10,   -- True Iron Nugget
    [109992] = 10,   -- Blackrock Fragment
    [110610] = 10,   -- Raw Beast Hide Scraps
    [111349] = 1,   -- A Treatise on Mining in Draenor
    [111350] = 1,   -- A Compendium of the Herbs of Draenor
    [111351] = 1,   -- A Guide to Skinning in Draenor
    [111356] = 1,   -- Fishing Guide to Draenor
    [111364] = 1,   -- First Aid in Draenor
    [111387] = 1,   -- The Joy of Draenor Cooking
    [111589] = 5,   -- Crescent Saberfish
    [111650] = 5,   -- Jawless Skulker
    [111651] = 5,   -- Fat Sleeper
    [111652] = 5,   -- Blind Lake Sturgeon
    [111656] = 5,   -- Fire Ammonite
    [111658] = 5,   -- Sea Scorpion
    [111659] = 5,   -- Abyssal Gulper Eel
    [111662] = 5,   -- Blackwater Whiptail
    [111921] = 1,   -- Draenor Engineering
    [111922] = 1,   -- Draenor Enchanting
    [111923] = 1,   -- Draenor Inscription
    [111972] = 1,   -- Enchanter's Study, Level 2, 2nd line contains "Garrison Blueprint"
    [112023] = 1,   -- Learning, Recipe: Draenic Philosopher's Stone, all learnable, it should replace most items in table T_RECIPES
    [112087] = 1,   -- Obsidian Frostwolf Petroglyph
    [112158] = 10,   -- Icy Dragonscale Fragment
    [112177] = 10,   -- Nerubian Chitin Fragment
    [112178] = 10,   -- Jormungar Scale Fragment
    [112179] = 10,   -- Patch of Thick Clefthoof Leather
    [112180] = 10,   -- Patch of Crystal Infused Leather
    [112181] = 10,   -- Fel Scale Fragment
    [112182] = 10,   -- Patch of Fel Hide
    [112183] = 10,   -- Nether Dragonscale Fragment
    [112184] = 10,   -- Cobra Scale Fragment
    [112185] = 10,   -- Wind Scale Fragment
    [113271] = 1,   -- Convert to garrison resources, Giant Kaliri Egg, Gain xxx Garrison Resources, common for all
    [113355] = 1,   -- Flip Card, Card of Omens
    [113992] = 1,   -- Scribe's Research Notes
    [114002] = 1,   -- Encoded Message
    [114171] = 1,   -- Crate Restored Artifact, common for all
    [115356] = 1,   -- Draenor Blacksmithing
    [115357] = 1,   -- Draenor Tailoring
    [115358] = 1,   -- Draenor Leatherworking
    [115359] = 1,   -- Draenor Jewelcrafting
    [115504] = 10,   -- Fractured Temporal Crystal
    [115510] = 300,   -- Elemental Rune
    [115981] = 1,   -- Abrogator Stone Cluster
    [118267] = 1,   -- Ravenmother Offering
    [118427] = 1,   -- Autographed Hearthstone Card, 3rd line contains "Use: Adds this toy to your toy box."
    [118592] = 2,   -- Partial Receipt: Gizmothingies
    [118727] = 1,   -- Frostfire Treasure Map
    [118728] = 1,   -- Shadowmoon Valey Treasure Map
    [118729] = 1,   -- Gorgrond Treasure Map
    [118730] = 1,   -- Talador Treasure Map
    [118731] = 1,   -- Spires of Arak Treasure Map
    [118732] = 1,   -- Nagrand Treasure Map
    [120301] = 1,   -- Create Armor Enhancement, Weapon Boost
    [122219] = 1,   -- Music Roll: Way of the Monk
    [122599] = 1,   -- Tome of Sorcerous Elements
    [122605] = 1,   -- Tome of the Stones
    [127413] = 1,   -- Jeweled Arakkoa Effigy, 3rd line contains "Use: Pry out the eyes of the statue."
    [127751] = 1,   -- Fel-Touched Pet Supplies, 3rd line Use: Open the bag. (1 Sec Cooldown)
    [128225] = 1,   -- Empowered Apexis Fragment
    [128294] = 1,   -- Trade Agreement: Arakkoa Outcasts
    [128314] = 1,   -- Frozen Arms of a Hero
    [128316] = 1,   -- Convert to Oil, Bulging Barrel of Oil,
    [128440] = 1,   -- Contract: Dowser Goodwell
    [128446] = 1,   -- Saberstalker Teachings: Trailblazer
    [128488] = 1,   -- Ship: The Awakener
    [128490] = 1,   -- Blueprint: Oil Rig
    [128980] = 1,   -- Scroll of Forgotten Knowledge
    [136269] = 1,   -- Kel'danath's Manaflask
    [136342] = 100,   -- Obliterum Ash

    -- Legion
    [136412] = 1,   -- Heavy Armor Set
    [136806] = 1,   -- Glass of Arcwine
    [137010] = 1,   -- 50 Ancient Mana
    [137207] = 1,   -- Fortified Armor Set
    [137208] = 1,   -- Indestructible Armor Set
    [137908] = 1,   -- Recipe: Battlebound Armbands, produce spell Learning
    [139010] = 1,   -- Petrified Silkweave
    [139011] = 1,   -- Berserking Helm of Ondry'el
    [139017] = 1,   -- Soothing Leystone Shard
    [139018] = 1,   -- Box of Calming Whispers
    [139019] = 1,   -- Spellmask of Alla'onus
    [139027] = 1,   -- Lenses of Spellseer Dellian
    [139786] = 1,   -- 25 mana
    [140236] = 1,   -- 100 Ancient Mana
    [140239] = 1,   -- 300 Ancient Mana
    [140240] = 1,   -- 150 Ancient Mana
    [140242] = 1,   -- 200 Ancient Mana
    [140260] = 1,   -- Arcane Remnant of Falanaar
    [140326] = 1,   -- Enchanted Burial Urn
    [140327] = 1,   -- Kyrtos's Research Notes
    [140328] = 1,   -- Volatile Leyline Crystal
    [140329] = 1,   -- Infinite Stone
    [140397] = 1,   -- G'Hanir's Blossom
    [140401] = 1,   -- 75 Ancient Mana
    [140439] = 1,   -- Sunblossom Pollen
    [140450] = 1,   -- Berserking Helm of Taenna
    [140451] = 1,   -- Spellmask of Azsylla
    [140526] = 1,   -- Eredar Signet, Use: Provides a significant increase to character experience.
    [141028] = 1,   -- Grimoire of Knowledge, Use: Open your Followers page and use this item to grant 4000 XP directly to a Champion.
    [141064] = 1,   -- Technique: Glyph of the Shivarra
    [141655] = 1,   -- Shimmering Ancient Mana Cluster
    [141870] = 1,   -- Arcane Tablet of Falanaar
    [143733] = 1,   -- Ancient Mana Shards
    [143734] = 1,   -- Ancient Mana Crystal Cluster
    [143748] = 1,   -- Ancient Mana Crystal
    [146328] = 1,   -- Petrified Wyrmtongue
    [146748] = 1,   -- Highmountain Tribute open containers
    [146757] = 10,   -- Prepared Ingredients
    [147416] = 1,   -- Arcane Tablet of Falanaar
    [147418] = 1,   -- Arcane Remnant of Falanaar
    [147729] = 1,   -- Netherchunk
    [150737] = 1,   -- Abundant Order Resources Cache
    [151638] = 1,   -- Leprous Sack of Pet Supplies, 3rd line in german translation is different from Fel-Touched Pet Supplies, so creative ...
    [151653] = 10,   -- Broken Isles Recipe Scrap
    [152998] = 1,   -- Carefully Hidden Muffin
    [154879] = 1,   -- Awoken Titan Essence
    [162536] = 1,   -- Scouting Report: Swiftwind Post

    -- Battle for Azeroth
    [163852] = 1,   -- Tortollan Pilgrimage Scroll
    [166999] = 1,   -- [Treasure Map]
    [168262] = 1,   -- Sentry Fish
    [169941] = 1,   -- Ceremonial Ankoan Scabbard; Grants reputation with the Ankoan
    [169942] = 1,   -- Vigrant Sea Blossom
    [170502] = 1,   -- Waterlogged Toolbox
    [170505] = 1,   -- Grimy Manaperal Bracelet
    [171335] = 1,   -- Corrupting Core
    [171354] = 1,   -- Horrific Core
    [177235] = 1,   -- Tubbins's Lucky Teapot
    [177239] = 1,   -- Racing Permit
    [178040] = 1,   -- Condensed Stygia
    [178512] = 1,   -- Celebration Package; 16th anniversary

    -- Other (DF+)
    [180842] = 1,   -- Stalwart Guardian
    [180844] = 1,   -- Brutal Vitality
    [180847] = 1,   -- Inspiring Presence
    [180896] = 1,   -- Safeguard
    [180932] = 1,   -- Fueled by Violence
    [180933] = 1,   -- Ashen Juggernaut
    [180935] = 1,   -- Crash the Ramparts
    [180943] = 1,   -- Cacophonous Roar
    [180944] = 1,   -- Merciless Bonegrinder
    [180949] = 1,   -- Animaflow Stabilizer, The Maw
    [180952] = 1,   -- Possibility Matrix, Torghast
    [181373] = 1,   -- Harm Denial
    [181376] = 1,   -- Inner Fury
    [181383] = 1,   -- Unrelenting Cold
    [181389] = 1,   -- Shivering Core
    [181435] = 1,   -- Calculated Strikes
    [181455] = 1,   -- Icy Propulsion
    [181461] = 1,   -- Ice Bite
    [181462] = 1,   -- Coordinated Offensive
    [181464] = 1,   -- Winter's Protection
    [181465] = 1,   -- Xuen's Bond
    [181466] = 1,   -- Grounding Breath
    [181467] = 1,   -- Flow of Time
    [181469] = 1,   -- Indelible Victory
    [181495] = 1,   -- Jade Bond
    [181498] = 1,   -- Grounding Surge
    [181504] = 1,   -- Infernal Cascade
    [181505] = 1,   -- Resplendent Mist
    [181506] = 1,   -- Master Flame
    [181508] = 1,   -- Fortifying Ingredients
    [181509] = 1,   -- Arcane Prodigy
    [181510] = 1,   -- Lingering Numbness
    [181511] = 1,   -- Nether Precision
    [181512] = 1,   -- Dizzying Tumble
    [181536] = 1,   -- Guest List Page
    [181539] = 1,   -- Discipline of the Grove
    [181553] = 1,   -- Gift of the Lich
    [181600] = 1,   -- Ire of the Ascended
    [181624] = 1,   -- Swift Transference
    [181639] = 1,   -- Siphoned Malice
    [181640] = 1,   -- Tumbling Technique
    [181641] = 1,   -- Rising Sun Revival
    [181698] = 1,   -- Cryo-Freeze
    [181700] = 1,   -- Scalding Brew
    [181705] = 1,   -- Celestial Effervescence
    [181707] = 1,   -- Diverted Energy
    [181709] = 1,   -- Unnerving Focus
    [181712] = 1,   -- Depths of Insanity
    [181734] = 1,   -- Magi's Brand
    [181735] = 1,   -- Hack and Slash
    [181736] = 1,   -- Flame Accretion
    [181737] = 1,   -- Nourishing Chi
    [181738] = 1,   -- Artifice of the Archmage
    [181740] = 1,   -- Evasive Stride
    [181742] = 1,   -- Walk with the Ox
    [181756] = 1,   -- Incantation of Swiftness
    [181759] = 1,   -- Strike with Clarity
    [181769] = 1,   -- Tempest Barrier
    [181770] = 1,   -- Bone Marrow Hops
    [181774] = 1,   -- Imbued Reflections
    [181775] = 1,   -- Way of the Fae
    [181776] = 1,   -- Vicious Contempt
    [181786] = 1,   -- Eternal Hunger
    [181826] = 1,   -- Translucent Image
    [181827] = 1,   -- Move with Grace
    [181834] = 1,   -- Chilled Resilience
    [181836] = 1,   -- Spirit Drain
    [181837] = 1,   -- Clear Mind
    [181838] = 1,   -- Charitable Soul
    [181840] = 1,   -- Light's Inspiration
    [181841] = 1,   -- Reinforced Shell
    [181842] = 1,   -- Power Unto Others
    [181843] = 1,   -- Shining Radiance
    [181844] = 1,   -- Pain Transformation
    [181845] = 1,   -- Exaltation
    [181847] = 1,   -- Lasting Spirit
    [181848] = 1,   -- Accelerated Cold
    [181866] = 1,   -- Withering Plague
    [181867] = 1,   -- Swift Penitence
    [181942] = 1,   -- Focused Mending
    [181943] = 1,   -- Eradicating Blow
    [181944] = 1,   -- Resonant Words
    [181962] = 1,   -- Mental Recovery
    [181963] = 1,   -- Blood Bond
    [181974] = 1,   -- Courageous Ascension
    [181975] = 1,   -- Hardened Bones
    [181980] = 1,   -- Embrace Death
    [181981] = 1,   -- Festering Transfusion
    [181982] = 1,   -- Everfrost
    [182105] = 1,   -- Astral Protection
    [182106] = 1,   -- Refreshing Waters
    [182107] = 1,   -- Vital Accretion
    [182108] = 1,   -- Thunderous Paws
    [182109] = 1,   -- Totemic Surge
    [182110] = 1,   -- Crippling Hex
    [182111] = 1,   -- Spiritual Resonance
    [182113] = 1,   -- Fleeting Wind
    [182125] = 1,   -- Pyroclastic Shock
    [182126] = 1,   -- High Voltage
    [182127] = 1,   -- Shake the Foundations
    [182128] = 1,   -- Call of Flame
    [182129] = 1,   -- Fae Fermata
    [182130] = 1,   -- Shattered Perceptions
    [182131] = 1,   -- Haunting Apparitions
    [182132] = 1,   -- Unending Grip
    [182133] = 1,   -- Insatiable Appetite
    [182134] = 1,   -- Unruly Winds
    [182135] = 1,   -- Focused Lightning
    [182136] = 1,   -- Chilled to the Core
    [182137] = 1,   -- Magma Fist
    [182138] = 1,   -- Mind Devourer
    [182139] = 1,   -- Rabid Shadows
    [182140] = 1,   -- Dissonant Echoes
    [182141] = 1,   -- Holy Oration
    [182142] = 1,   -- Embrace of Earth
    [182143] = 1,   -- Swirling Currents
    [182144] = 1,   -- Nature's Focus
    [182145] = 1,   -- Heavy Rainfall
    [182187] = 1,   -- Meat Shield
    [182201] = 1,   -- Unleashed Frenzy
    [182203] = 1,   -- Debilitating Malady
    [182206] = 1,   -- Convocation of the Dead
    [182208] = 1,   -- Lingering Plague
    [182288] = 1,   -- Impenetrable Gloom
    [182292] = 1,   -- Brutal Grasp
    [182295] = 1,   -- Proliferation
    [182304] = 1,   -- Divine Call
    [182307] = 1,   -- Shielding Words
    [182316] = 1,   -- Fel Defender
    [182317] = 1,   -- Shattered Restoration
    [182318] = 1,   -- Viscous Ink
    [182321] = 1,   -- Enfeebled Mark
    [182324] = 1,   -- Felfire Haste
    [182325] = 1,   -- Ravenous Consumption
    [182330] = 1,   -- Demonic Parole
    [182331] = 1,   -- Empowered Release
    [182335] = 1,   -- Spirit Attunement
    [182336] = 1,   -- Golden Path
    [182338] = 1,   -- Pure Concentration
    [182339] = 1,   -- Necrotic Barrage
    [182340] = 1,   -- Fel Celerity
    [182344] = 1,   -- Lost in Darkness
    [182345] = 1,   -- Elysian Dirge
    [182346] = 1,   -- Tumbling Waves
    [182347] = 1,   -- Essential Extraction
    [182348] = 1,   -- Lavish Harvest
    [182368] = 1,   -- Relentless Onslaught
    [182383] = 1,   -- Dancing with Fate
    [182384] = 1,   -- Serrated Glaive
    [182385] = 1,   -- Growing Inferno
    [182440] = 1,   -- Piercing Verdict
    [182441] = 1,   -- Marksman's Advantage
    [182442] = 1,   -- Veteran's Repute
    [182448] = 1,   -- Light's Barding
    [182449] = 1,   -- Resolute Barrier
    [182456] = 1,   -- Wrench Evil
    [182460] = 1,   -- Accrued Vitality
    [182461] = 1,   -- Echoing Blessings
    [182462] = 1,   -- Expurgation
    [182463] = 1,   -- Harrowing Punishment
    [182464] = 1,   -- Harmony of the Tortollan
    [182465] = 1,   -- Truth's Wake
    [182466] = 1,   -- Shade of Terror
    [182468] = 1,   -- Mortal Combo
    [182469] = 1,   -- Rejuvenating Wind
    [182470] = 1,   -- Demonic Momentum
    [182471] = 1,   -- Soul Furnace
    [182476] = 1,   -- Resilience of the Hunter
    [182478] = 1,   -- Corrupting Leer
    [182480] = 1,   -- Reversal of Fortune
    [182559] = 1,   -- Templar's Vindication
    [182582] = 1,   -- Enkindled Spirit
    [182584] = 1,   -- Cheetah's Vigor
    [182598] = 1,   -- Demon Muzzle
    [182604] = 1,   -- Roaring Fire
    [182605] = 1,   -- Tactical Retreat
    [182608] = 1,   -- Virtuous Command
    [182610] = 1,   -- Ferocious Appetite
    [184587] = 1,   -- Ambuscade
    [184588] = 1,   -- Soul-Stabilizing Talisman, The Maw
    [184605] = 1,   -- Sigil of the Unseen, The Maw
    [184613] = 1,   -- Encased Riftwalker Essence, The Maw
    [184615] = 1,   -- Extradimensional Pockets, Torghast
    [184617] = 1,   -- Bangle of Seniority, Torghast
    [184618] = 1,   -- Rank Insignia: Acquisitionist, Torghast
    [184619] = 1,   -- Loupe of Unusual Charm, Torghast
    [184620] = 1,   -- Vessel of Unfortunate Spirits, Torghast
    [184621] = 1,   -- Ritual Prism of Fortune, Torghast
    [184653] = 1,   -- Animated Levitating Chain, The Maw
    [184901] = 1,   -- Broker Traversal Enhancer, Torghast
    [186520] = 1,   -- Chest of Playtest Equipment - Create Essential Stuff
    [190315] = 10,   -- Rousing Earth
    [190320] = 10,   -- Rousing Fire
    [190322] = 10,   -- Rousing Order
    [190326] = 10,   -- Rousing Air
    [190328] = 10,   -- Rousing Frost
    [190330] = 10,   -- Rousing Decay
    [190451] = 10,   -- Rousing Ire
    [190640] = 1,   -- Font of Ephemeral Power
    [193205] = 1,   -- Ohuna Companion Color: Brown
    [194087] = 1,   -- Ohuna Companion Color: Red
    [194088] = 1,   -- Ohuna Companion Color: Dark
    [194089] = 1,   -- Bakar Companion Color: Orange
    [194090] = 1,   -- Bakar Companion Color: White
    [194091] = 1,   -- Bakar Companion Color: Golden Brown
    [194093] = 1,   -- Bakar Companion Color: Brown
    [194094] = 1,   -- Bakar Companion Color: Black
    [194095] = 1,   -- Ohuna Companion Color: Sepia
    [194540] = 1,   -- Nokhud Armorer's Notes
    [195453] = 1,   -- Ludo's Stash Map
    [198395] = 1,   -- Dull Spined Clam
    [198843] = 1,   -- Emerald Gardens Explorer's Notes
    [198852] = 1,   -- Bear Termination Orders
    [198854] = 1,   -- Archeologist Artifact Notes
    [199061] = 1,   -- A Guide to Rare Fish
    [199062] = 1,   -- Ruby Gem Cluster Map
    [199065] = 1,   -- Sorrowful Letter
    [199066] = 1,   -- Letter of Caution
    [199067] = 1,   -- Precious Plans
    [199068] = 1,   -- Time-Lost Memo
    [199752] = 1,   -- Ensemble: Crimson Valdrakken Clothing
    [199753] = 1,   -- Ensemble: Black Valdrakken Clothing
    [199754] = 1,   -- Ensemble: Azure Valdrakken Clothing
    [199755] = 1,   -- Ensemble: Green Valdrakken Clothing
    [199756] = 1,   -- Ensemble: Bronze Valdrakken Clothing
    [200738] = 1,   -- Onyx Gem Cluster Map
    [201437] = 5,   -- Slumbering Dream Fragment
    [201837] = 1,   -- Magmammoth Harness (requires aura -> aura missing check)
    [204075] = 15,   -- Whelpling's Shadowflame Crest Fragment
    [204076] = 15,   -- Drake's Shadowflame Crest Fragment
    [204077] = 15,   -- Wyrm's Shadowflame Crest Fragment
    [204078] = 15,   -- Aspect's Shadowflame Crest Fragment
    [204717] = 2,   -- Splintered Spark of Shadowflame
    [205363] = 1,   -- Ensemble: Ornate Black Dragon Labwear
    [205423] = 1,   -- Shadowflame Residue Sack
    [205962] = 1,   -- Echoing Storm Flightstone
    [207016] = 1,   -- Rift-Mender's Tabard
    [207017] = 1,   -- Rift-Mender's Cape
    [207018] = 1,   -- Rift-Mender's Spaulders
    [207020] = 1,   -- Ensemble: Rift-Mender's Vestments
    [208061] = 1,   -- Quantum Headpiece
    [208062] = 1,   -- Quantum Shoulders
    [208063] = 1,   -- Quantum Gloves
    [208064] = 1,   -- Quantum Chestpiece
    [208065] = 1,   -- Quantum Legs
    [208109] = 1,   -- Quantum Sword
    [208110] = 1,   -- Quantum Mace
    [208111] = 1,   -- Quantum Axe
    [208112] = 1,   -- Quantum Greatsword
    [208113] = 1,   -- Quantum Greataxe
    [208114] = 1,   -- Quantum Greathammer
    [208115] = 1,   -- Quantum Staff
    [208116] = 1,   -- Quantum Polearm
    [208117] = 1,   -- Quantum Bow
    [208118] = 1,   -- Quantum Crossbow
    [208119] = 1,   -- Quantum Firearm
    [208120] = 1,   -- Quantum Knife
    [208121] = 1,   -- Quantum Knuckles
    [208122] = 1,   -- Quantum Warglaives
    [208123] = 1,   -- Quantum Wand
    [208125] = 1,   -- Quantum Focus
    [208126] = 1,   -- Quantum Shield
    [208216] = 1,   -- Reins of the Quantum Courser
    [208396] = 2,   -- Dragon Shard of Knowledge
    [208831] = 1,   -- Tyr's Titan Key
    [209417] = 1,   -- Ensemble: Thundering Stormrider's Attire
    [209604] = 1,   -- Ensemble: Raiment of Amirdrassil
    [209837] = 1,   -- Faint Whispers of Dreaming
    [210468] = 1,   -- Emerald Blossom Dreamstone
    [210756] = 1,   -- Gleaming Satchel of Drake's Dreaming Crests
    [210762] = 1,   -- Shimmering Clutch of Wyrm's Dreaming Crests
    [210768] = 1,   -- Viridescent Bouquet of Aspect's Dreaming Crests
    [210770] = 1,   -- Satchel of Drake's Dreaming Crests
    [210790] = 1,   -- Ensemble: Elegant Green Dragon Outerwear
    [210917] = 1,   -- Pouch of Whelpling's Dreaming Crests
    [210923] = 1,   -- Clutch of Wyrm's Dreaming Crests
    [210982] = 1,   -- Thread of Power
    [210983] = 1,   -- Thread of Stamina
    [210984] = 1,   -- Thread of Critical Strike
    [210985] = 1,   -- Thread of Haste
    [210986] = 1,   -- Thread of Speed
    [210987] = 1,   -- Thread of Leech
    [210989] = 1,   -- Thread of Mastery
    [210996] = 1,   -- Moonberry's Many Mischief Makers
    [211515] = 2,   -- Splintered Spark of Awakening
    [211950] = 1,   -- Lively Clutch of Wyrm's Awakened Crests
    [211951] = 1,   -- Pouch of Whelpling's Awakened Crests
    [212383] = 1,   -- Yawning Basket of Aspect's Awakened Crests
    [212384] = 1,   -- Restless Satchel of Drake's Awakened Crests
    [212939] = 1,   -- Hearthstone event cards
    [213389] = 1,   -- Ancient Centaur Diary - "Breaking Down"
    [217242] = 1,   -- Awakening Stone Wing
    [217722] = 1,   -- Thread of Experience
    [219256] = 1,   -- Temporal Thread of Power
    [219257] = 1,   -- Temporal Thread of Stamina
    [219258] = 1,   -- Temporal Thread of Critical Strike
    [219259] = 1,   -- Temporal Thread of Haste
    [219260] = 1,   -- Temporal Thread of Speed
    [219261] = 1,   -- Temporal Thread of Leech
    [219262] = 1,   -- Temporal Thread of Mastery
    [219263] = 1,   -- Temporal Thread of Versatility
    [219264] = 1,   -- Temporal Thread of Experience
    [219265] = 1,   -- Perpetual Thread of Power
    [219266] = 1,   -- Perpetual Thread of Stamina
    [219267] = 1,   -- Perpetual Thread of Critical Strike
    [219268] = 1,   -- Perpetual Thread of Haste
    [219269] = 1,   -- Perpetual Thread of Speed
    [219270] = 1,   -- Perpetual Thread of Leech
    [219271] = 1,   -- Perpetual Thread of Mastery
    [219272] = 1,   -- Perpetual Thread of Versatility
    [219273] = 1,   -- Perpetual Thread of Experience
    [219274] = 1,   -- Infinite Thread of Power
    [219275] = 1,   -- Infinite Thread of Stamina
    [219280] = 1,   -- Infinite Thread of Mastery

    -- ==========================================
    -- CUSTOM (added via /op or SavedVars import)
    -- ==========================================

    [240926] = 1,   -- Pack of Runed Ethereal Crests
    [240927] = 1,   -- Satchel of Carved Ethereal Crests
    [240928] = 1,   -- Satchel of Carved Ethereal Crests
    [240929] = 1,   -- Glorious Cluster of Gilded Ethereal Crests
    [240930] = 1,   -- Celebratory Pack of Runed Ethereal Crests
    [240931] = 1,   -- Triumphant Satchel of Carved Ethereal Crests
    [135539] = 1,   -- Crate of Battlefield Goods
    [224752] = 1,   -- Soaked Journal Entry
    [225770] = 1,   -- Algari Anglerthread
    [225771] = 1,   -- Algari Seekerthread
    [226392] = 1,   -- Careless Dasher's Treasure
    [239101] = 1,   -- Voidcrawler
    [242516] = 1,   -- Memento of Epoch Legends
    [243248] = 10,   -- Anomaly Filament
    [243342] = 10,   -- Bloom Bauble
    [245653] = 100,   -- Coffer Key Shard
    [245925] = 1,   -- Artifactium Sand
    [246751] = 1,   -- Triumphant Satchel of Champion Dawncrests
    [246752] = 1,   -- Celebratory Pack of Hero Dawncrests
    [246815] = 1,   -- Lesser Bronze Cache
    [246936] = 1,   -- Resonant Epoch Memento
    [246937] = 1,   -- Perfected Epoch Memento
    [247719] = 5,   -- Multicraft Matrix
    [247725] = 5,   -- Resourceful Rebar
    [249145] = 1,   -- Manaforge Raider's Gamma Shockmace
    [249780] = 1,   -- Army of the Light Champion's Insignia
    [249781] = 1,   -- Wardens Champion's Insignia
    [249782] = 1,   -- Valarjar Champion's Insignia
    [249783] = 1,   -- Nightfallen Champion's Insignia
    [249784] = 1,   -- Legionfall Champion's Insignia
    [249785] = 1,   -- Highmountain Tribe Champion's Insignia
    [249786] = 1,   -- Dreamweaver Champion's Insignia
    [249787] = 1,   -- Court of Farondis Champion's Insignia
    [249788] = 1,   -- Argussian Reach Champion's Insignia
    [249891] = 1,   -- Mound of Artifactium Sand
    [253224] = 10,   -- Mote of a Broken Time
    [253227] = 10,   -- Flawless Thread of Time
    [253353] = 1,   -- Illusion: Felshatter
    [253756] = 1,   -- Insignia of the Broken Isles
    [254267] = 100,   -- Fragmented Memento of Epoch Challenges
    [254875] = 1,   -- Muck-Covered Writings
    [258035] = 1,   -- Pattern: Elegant Artisan's Alchemy Coveralls
    [258039] = 1,   -- Pattern: Elegant Artisan's Herbalism Hat
    [260630] = 5,   -- Ingenious Identifier
    [262792] = 100,   -- Shredded Bloomline
    [262793] = 20,   -- Stranded Bloomline
    [262798] = 20,   -- Stranded Glimmerline
    [262964] = 1,   -- Death's Hope
    [263287] = 1,   -- Reliquary-Keeper's Lost Shortbow
    [263977] = 1,   -- Venerable Satchel of Veteran Dawncrests
    [267061] = 1,   -- Pattern: Thalassian Herbalist's Cowl
    [268297] = 1,   -- Rattling Bag o' Gold
    [274069] = 1,   -- Warbound Pack of Hero Dawncrests
}