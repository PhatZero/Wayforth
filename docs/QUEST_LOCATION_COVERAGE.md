# Forever quest location coverage

Generated from the bundled manifest by `scripts/audit_quest_locations.lua`.

Sources are the corrected Forever facts from QuestieDB, the compiled AllTheThings Forever catalog, Wowhead Forever quest maps, and recorded quest giver/finisher names from AHledger. Exact revisions and the refresh command are in `docs/QUEST_LOCATION_SOURCES.md`.

Counts include the union of faction, race and class variants within each guide. Shared quests can appear in multiple guides.

| Phase | Quest IDs present | Static destinations | Missing static destinations |
| --- | ---: | ---: | ---: |
| accept | 2954 | 2837 | 117 |
| objective | 1888 | 1701 | 187 |
| turnin | 2964 | 2772 | 192 |

Static coverage describes source availability. It does not verify quest eligibility or live-client accuracy. Some requirements involve crafting, reputation or player-held items and have no single world destination. Unresolved phases use an active quest's live marker when available.

| Guide | Quest steps | Static destinations | Missing |
| --- | ---: | ---: | ---: |
| zephras-alliance | 73 | 73 | 0 |
| zephras-horde | 67 | 67 | 0 |
| alliance-elwynn | 63 | 63 | 0 |
| alliance-dun-morogh | 53 | 53 | 0 |
| alliance-teldrassil | 59 | 59 | 0 |
| alliance-darkshore | 205 | 205 | 0 |
| alliance-stonetalon | 65 | 64 | 1 |
| alliance-ashenvale | 128 | 120 | 8 |
| alliance-thousand-needles | 83 | 80 | 3 |
| alliance-desolace | 149 | 128 | 21 |
| alliance-dustwallow | 100 | 98 | 2 |
| alliance-feralas | 125 | 123 | 2 |
| alliance-tanaris | 175 | 164 | 11 |
| alliance-azshara | 68 | 67 | 1 |
| alliance-ungoro | 131 | 131 | 0 |
| alliance-felwood | 197 | 193 | 4 |
| alliance-winterspring | 121 | 118 | 3 |
| alliance-silithus | 272 | 264 | 8 |
| alliance-hyjal | 2 | 1 | 1 |
| alliance-barrens | 173 | 152 | 21 |
| alliance-moonglade | 89 | 79 | 10 |
| horde-durotar | 187 | 185 | 2 |
| horde-mulgore | 194 | 192 | 2 |
| horde-the-barrens | 267 | 260 | 7 |
| horde-stonetalon-mountains | 89 | 87 | 2 |
| horde-ashenvale | 64 | 59 | 5 |
| horde-thousand-needles | 149 | 147 | 2 |
| horde-desolace | 158 | 140 | 18 |
| horde-dustwallow-marsh | 71 | 69 | 2 |
| horde-feralas | 94 | 93 | 1 |
| horde-tanaris | 148 | 136 | 12 |
| horde-azshara | 60 | 59 | 1 |
| horde-un-goro-crater | 99 | 99 | 0 |
| horde-felwood | 72 | 70 | 2 |
| horde-winterspring | 71 | 68 | 3 |
| horde-silithus | 112 | 110 | 2 |
| horde-mount-hyjal | 2 | 0 | 2 |
| horde-shen-dralas | 32 | 19 | 13 |
| horde-tirisfal-glades | 212 | 212 | 0 |
| horde-silverpine-forest | 120 | 118 | 2 |
| alliance-loch-modan | 123 | 122 | 1 |
| alliance-westfall | 117 | 117 | 0 |
| alliance-redridge-mountains | 111 | 110 | 1 |
| alliance-duskwood | 189 | 188 | 1 |
| alliance-wetlands | 182 | 180 | 2 |
| alliance-hillsbrad-foothills | 33 | 33 | 0 |
| horde-hillsbrad-foothills | 87 | 81 | 6 |
| alliance-alterac-mountains | 43 | 42 | 1 |
| horde-alterac-mountains | 34 | 34 | 0 |
| alliance-arathi-highlands | 99 | 99 | 0 |
| horde-arathi-highlands | 122 | 116 | 6 |
| alliance-stranglethorn-vale | 270 | 259 | 11 |
| horde-stranglethorn-vale | 265 | 257 | 8 |
| alliance-badlands | 102 | 100 | 2 |
| horde-badlands | 88 | 85 | 3 |
| alliance-swamp-of-sorrows | 48 | 43 | 5 |
| horde-swamp-of-sorrows | 75 | 71 | 4 |
| alliance-riverglades | 300 | 140 | 160 |
| horde-riverglades | 254 | 150 | 104 |
| alliance-the-hinterlands | 36 | 36 | 0 |
| horde-the-hinterlands | 83 | 81 | 2 |
| alliance-searing-gorge | 86 | 86 | 0 |
| horde-searing-gorge | 61 | 61 | 0 |
| alliance-blasted-lands | 33 | 33 | 0 |
| horde-blasted-lands | 26 | 26 | 0 |
| alliance-burning-steppes | 20 | 20 | 0 |
| horde-burning-steppes | 11 | 11 | 0 |
| alliance-western-plaguelands | 59 | 59 | 0 |
| horde-western-plaguelands | 54 | 54 | 0 |
| alliance-eastern-plaguelands | 87 | 85 | 2 |
| horde-eastern-plaguelands | 109 | 106 | 3 |

## Unresolved static destinations

| Guide | Quest ID | Phase | Step |
| --- | ---: | --- | --- |
| alliance-alterac-mountains | 96800 | objective | Work on: Past Due |
| alliance-ashenvale | 1017 | objective | Work on: Mage Summoner |
| alliance-ashenvale | 6545 | objective | Work on: Warsong Runner Update |
| alliance-ashenvale | 6545 | turnin | Warsong Runner Update |
| alliance-ashenvale | 6546 | objective | Work on: Warsong Outrider Update |
| alliance-ashenvale | 6546 | turnin | Warsong Outrider Update |
| alliance-ashenvale | 6547 | objective | Work on: Warsong Scout Update |
| alliance-ashenvale | 6547 | turnin | Warsong Scout Update |
| alliance-ashenvale | 86757 | objective | Work on: Slowing the Orc Advance |
| alliance-azshara | 3381 | turnin | A Meeting with the Master |
| alliance-badlands | 716 | objective | Work on: Stone Is Better than Cloth |
| alliance-badlands | 736 | turnin | Complete: The Star, the Hand and the Heart [H] |
| alliance-barrens | 1510 | turnin | News of Dogran (2/2) |
| alliance-barrens | 1512 | turnin | Love's Gift |
| alliance-barrens | 1515 | turnin | Dogran's Captivity |
| alliance-barrens | 1796 | objective | Work on: Components for the Enchanted Gold Bloodrobe (1/5) |
| alliance-barrens | 1946 | turnin | Nether-lace Garment |
| alliance-barrens | 2996 | accept | Seeking Strahad (Orgrimmar) |
| alliance-barrens | 3001 | accept | Seeking Strahad (Undercity) |
| alliance-barrens | 55296 | accept | Completed when turning in Chen's Empty Keg (2/3) (821) |
| alliance-barrens | 55296 | turnin | Completed when turning in Chen's Empty Keg (2/3) (821) |
| alliance-barrens | 6365 | turnin | Meats to Orgrimmar |
| alliance-barrens | 6384 | turnin | Ride to Orgrimmar |
| alliance-barrens | 6385 | accept | Doras the Wind Rider Master |
| alliance-barrens | 6385 | turnin | Doras the Wind Rider Master |
| alliance-barrens | 6386 | accept | Return to the Crossroads. |
| alliance-barrens | 6386 | turnin | Return to the Crossroads. |
| alliance-barrens | 854 | turnin | Journey to the Crossroads |
| alliance-barrens | 95819 | accept | Sign Me Up! |
| alliance-barrens | 95819 | objective | Work on: Sign Me Up! |
| alliance-barrens | 95819 | turnin | Sign Me Up! |
| alliance-barrens | 98024 | accept | Journey to the Crossroads |
| alliance-barrens | 98024 | turnin | Journey to the Crossroads |
| alliance-desolace | 1371 | objective | Work on: Gizmo for Warug |
| alliance-desolace | 1382 | objective | Work on: Strange Alliance |
| alliance-desolace | 1385 | objective | Work on: Brutal Politics |
| alliance-desolace | 92754 | accept | A New Need for Shadow Protection |
| alliance-desolace | 92754 | turnin | A New Need for Shadow Protection |
| alliance-desolace | 92755 | accept | Mysterious Mysticism |
| alliance-desolace | 92755 | turnin | Mysterious Mysticism |
| alliance-desolace | 92811 | turnin | Economic Warfare (Magram) |
| alliance-desolace | 92814 | accept | I Need a Tailor |
| alliance-desolace | 92814 | turnin | I Need a Tailor |
| alliance-desolace | 92817 | accept | Leather Technique |
| alliance-desolace | 92817 | turnin | Leather Technique |
| alliance-desolace | 92818 | turnin | Big, No, MASSIVE Iron Axes |
| alliance-desolace | 93196 | accept | Khan Jehn (Magram) |
| alliance-desolace | 93196 | objective | Work on: Khan Jehn (Magram) |
| alliance-desolace | 93196 | turnin | Khan Jehn (Magram) |
| alliance-desolace | 93226 | turnin | Buying Friendship: Magram [A] |
| alliance-desolace | 93678 | accept | Abridged Notes on Draenethyst |
| alliance-desolace | 93678 | objective | Work on: Abridged Notes on Draenethyst |
| alliance-desolace | 93678 | turnin | Abridged Notes on Draenethyst |
| alliance-desolace | 97284 | turnin | Vahlarriel's Vengeance |
| alliance-duskwood | 98447 | turnin | Complete: The Valor Family (2/2) |
| alliance-dustwallow | 1203 | objective | Work on: Jarl Needs a Blade |
| alliance-dustwallow | 98233 | turnin | Sword in the Slime |
| alliance-eastern-plaguelands | 5149 | objective | Work on: Pamela's Doll |
| alliance-eastern-plaguelands | 6026 | objective | Work on: That's Asking A Lot |
| alliance-felwood | 4106 | objective | Work on: Salve via Skinning (2/2) |
| alliance-felwood | 4107 | objective | Work on: Salve via Disenchanting (2/2) |
| alliance-felwood | 5885 | objective | Work on: Salve via Skinning (1/2) |
| alliance-felwood | 5886 | objective | Work on: Salve via Disenchanting (1/2) |
| alliance-feralas | 3791 | objective | Work on: The Mystery of Morrowgrain |
| alliance-feralas | 3792 | objective | Work on: Morrowgrain to Feathermoon Stronghold |
| alliance-hyjal | 92521 | turnin | The Demon Tower |
| alliance-loch-modan | 86776 | objective | Work on: Ingredients for the Forge |
| alliance-moonglade | 5926 | accept | Heeding the Call [Thunder Bluff] |
| alliance-moonglade | 5926 | turnin | Heeding the Call [Thunder Bluff] |
| alliance-moonglade | 5927 | accept | Heeding the Call [Orgrimmar] |
| alliance-moonglade | 5927 | turnin | Heeding the Call [Orgrimmar] |
| alliance-moonglade | 5928 | accept | Heeding the Call [Mulgore] |
| alliance-moonglade | 5928 | turnin | Heeding the Call [Mulgore] |
| alliance-moonglade | 5931 | objective | Work on: Back to Darnassus |
| alliance-moonglade | 94913 | accept | Moonglade |
| alliance-moonglade | 98340 | accept | The Great Cat Spirit |
| alliance-moonglade | 98362 | turnin | To Thunder Bluff |
| alliance-redridge-mountains | 95816 | objective | Work on: Sign Me Up! |
| alliance-riverglades | 93443 | turnin | Complete: Lost Shipping Crate [A] [Stranglethorn Vale] |
| alliance-riverglades | 94613 | accept | Pick up: My Kingdom for a Horse |
| alliance-riverglades | 94615 | objective | Work on: Foal Play |
| alliance-riverglades | 94678 | accept | Pick up: Gnoll Infestation [A] |
| alliance-riverglades | 94678 | turnin | Complete: Gnoll Infestation [A] |
| alliance-riverglades | 94679 | accept | Pick up: Snargl's Snout [A] |
| alliance-riverglades | 94679 | objective | Work on: Snargl's Snout [A] |
| alliance-riverglades | 94679 | turnin | Complete: Snargl's Snout [A] |
| alliance-riverglades | 94841 | turnin | Complete: Lost Shipping Crate [A] [Desolace] |
| alliance-riverglades | 94857 | accept | Pick up: If a Tree Falls, and No One Hears... |
| alliance-riverglades | 94857 | turnin | Complete: If a Tree Falls, and No One Hears... |
| alliance-riverglades | 94858 | objective | Work on: All That's Left |
| alliance-riverglades | 94858 | turnin | Complete: All That's Left |
| alliance-riverglades | 94861 | accept | Pick up: Helping Hands |
| alliance-riverglades | 94861 | turnin | Complete: Helping Hands |
| alliance-riverglades | 94877 | accept | Pick up: Saving Sunnyglade |
| alliance-riverglades | 94877 | turnin | Complete: Saving Sunnyglade |
| alliance-riverglades | 94879 | objective | Work on: Scraps of Knowledge |
| alliance-riverglades | 94879 | turnin | Complete: Scraps of Knowledge |
| alliance-riverglades | 94881 | turnin | Complete: Curious Trinkets |
| alliance-riverglades | 94885 | turnin | Complete: Field Marshal's Log |
| alliance-riverglades | 94886 | accept | Pick up: The Western Front |
| alliance-riverglades | 94886 | turnin | Complete: The Western Front |
| alliance-riverglades | 94887 | accept | Pick up: Saving Marshal Ryan |
| alliance-riverglades | 94887 | objective | Work on: Saving Marshal Ryan |
| alliance-riverglades | 94887 | turnin | Complete: Saving Marshal Ryan |
| alliance-riverglades | 94888 | accept | Pick up: No Soldier Left Behind |
| alliance-riverglades | 94888 | turnin | Complete: No Soldier Left Behind |
| alliance-riverglades | 94889 | accept | Pick up: Carving a Path [A] |
| alliance-riverglades | 94889 | turnin | Complete: Carving a Path [A] |
| alliance-riverglades | 94890 | objective | Work on: Bring Me His Head [A] |
| alliance-riverglades | 94890 | turnin | Complete: Bring Me His Head [A] |
| alliance-riverglades | 94891 | turnin | Complete: News to Farholde |
| alliance-riverglades | 94892 | accept | Pick up: Dying Wish |
| alliance-riverglades | 94892 | turnin | Complete: Dying Wish |
| alliance-riverglades | 94893 | accept | Pick up: Delivering Closure |
| alliance-riverglades | 94893 | turnin | Complete: Delivering Closure |
| alliance-riverglades | 94894 | turnin | Complete: The Twilight Threat |
| alliance-riverglades | 94907 | accept | Pick up: A Small Favor |
| alliance-riverglades | 94907 | objective | Work on: A Small Favor |
| alliance-riverglades | 94907 | turnin | Complete: A Small Favor |
| alliance-riverglades | 94923 | accept | Pick up: Hats Off |
| alliance-riverglades | 94923 | objective | Work on: Hats Off |
| alliance-riverglades | 94923 | turnin | Complete: Hats Off |
| alliance-riverglades | 94924 | accept | Pick up: Hunting the Hunters |
| alliance-riverglades | 94924 | objective | Work on: Hunting the Hunters |
| alliance-riverglades | 94924 | turnin | Complete: Hunting the Hunters |
| alliance-riverglades | 94925 | accept | Pick up: A Fur Trade |
| alliance-riverglades | 94925 | turnin | Complete: A Fur Trade |
| alliance-riverglades | 94926 | accept | Pick up: Drop the Hammer |
| alliance-riverglades | 94926 | objective | Work on: Drop the Hammer |
| alliance-riverglades | 94926 | turnin | Complete: Drop the Hammer |
| alliance-riverglades | 94927 | accept | Pick up: Dunston Checks Out |
| alliance-riverglades | 94927 | turnin | Complete: Dunston Checks Out |
| alliance-riverglades | 94928 | accept | Pick up: A Few Furs for Friz |
| alliance-riverglades | 94928 | turnin | Complete: A Few Furs for Friz |
| alliance-riverglades | 94931 | objective | Work on: Stolen Saws |
| alliance-riverglades | 94961 | turnin | Complete: Biting the Hand (1/2) |
| alliance-riverglades | 94963 | turnin | Complete: Biting the Hand (2/2) |
| alliance-riverglades | 94992 | turnin | Complete: Rescue Roundup |
| alliance-riverglades | 94999 | accept | Pick up: Eyes for the Watchman |
| alliance-riverglades | 94999 | turnin | Complete: Eyes for the Watchman |
| alliance-riverglades | 95059 | objective | Work on: Frazzlespark's Crate [A] |
| alliance-riverglades | 95064 | accept | Pick up: Preventative Measures |
| alliance-riverglades | 95064 | turnin | Complete: Preventative Measures |
| alliance-riverglades | 95066 | accept | Pick up: The Rog'mar Situation |
| alliance-riverglades | 95066 | objective | Work on: The Rog'mar Situation |
| alliance-riverglades | 95066 | turnin | Complete: The Rog'mar Situation |
| alliance-riverglades | 95118 | turnin | Complete: Saltwater Savages |
| alliance-riverglades | 95120 | accept | Pick up: WANTED: Old Rot-Chum |
| alliance-riverglades | 95122 | turnin | Complete: Unchecked Expansion |
| alliance-riverglades | 95123 | objective | Work on: A Blast Ye Scurvy Dogs! |
| alliance-riverglades | 95123 | turnin | Complete: A Blast Ye Scurvy Dogs! |
| alliance-riverglades | 95124 | turnin | Complete: Admiral Lamora |
| alliance-riverglades | 95147 | accept | Pick up: The Lost Scout |
| alliance-riverglades | 95147 | objective | Work on: The Lost Scout |
| alliance-riverglades | 95147 | turnin | Complete: The Lost Scout |
| alliance-riverglades | 95148 | accept | Pick up: Southern Watch Gnoll Report |
| alliance-riverglades | 95148 | objective | Work on: Southern Watch Gnoll Report |
| alliance-riverglades | 95148 | turnin | Complete: Southern Watch Gnoll Report |
| alliance-riverglades | 95156 | objective | Work on: Stuff 'Em and Stick 'Em |
| alliance-riverglades | 95165 | objective | Work on: See Ya, Scallywags! |
| alliance-riverglades | 95184 | objective | Work on: The Sharpest of Blades |
| alliance-riverglades | 95184 | turnin | Complete: The Sharpest of Blades |
| alliance-riverglades | 95219 | objective | Work on: From Port to Port |
| alliance-riverglades | 95219 | turnin | Complete: From Port to Port |
| alliance-riverglades | 95260 | accept | Pick up: Terrors From the Deep |
| alliance-riverglades | 95261 | turnin | Complete: It Takes Guts |
| alliance-riverglades | 95267 | objective | Work on: The Monster Surfaces |
| alliance-riverglades | 95288 | turnin | Complete: Smuggler's Paradise |
| alliance-riverglades | 95293 | turnin | Complete: Smuggler's Special |
| alliance-riverglades | 95294 | accept | Pick up: Smuggler's Bargain |
| alliance-riverglades | 95312 | turnin | Complete: Coming to Collect |
| alliance-riverglades | 95315 | turnin | Complete: The Riverglades Report |
| alliance-riverglades | 95321 | accept | Pick up: Tazzik's Dues |
| alliance-riverglades | 95321 | turnin | Complete: Tazzik's Dues |
| alliance-riverglades | 95322 | objective | Work on: Get the Goods |
| alliance-riverglades | 95322 | turnin | Complete: Get the Goods |
| alliance-riverglades | 95325 | turnin | Complete: We've Been Robbed! |
| alliance-riverglades | 95326 | accept | Pick up: The Big Payback |
| alliance-riverglades | 95329 | accept | Pick up: Out in the Field |
| alliance-riverglades | 95329 | turnin | Complete: Out in the Field |
| alliance-riverglades | 95330 | accept | Pick up: Love Thy Neighbor |
| alliance-riverglades | 95426 | accept | Pick up: Rog'mar Supplies |
| alliance-riverglades | 95426 | objective | Work on: Rog'mar Supplies |
| alliance-riverglades | 95426 | turnin | Complete: Rog'mar Supplies |
| alliance-riverglades | 95472 | accept | Pick up: Consolation Prize |
| alliance-riverglades | 95472 | turnin | Complete: Consolation Prize |
| alliance-riverglades | 95561 | objective | Work on: Apple of My Eye |
| alliance-riverglades | 95561 | turnin | Complete: Apple of My Eye |
| alliance-riverglades | 95562 | objective | Work on: Cut Off the Heads |
| alliance-riverglades | 95615 | turnin | Complete: In Memoriam |
| alliance-riverglades | 95642 | objective | Work on: Abominable Magics |
| alliance-riverglades | 95643 | objective | Work on: Indiscriminate Purge |
| alliance-riverglades | 95792 | accept | Pick up: Clear 'em Out |
| alliance-riverglades | 95792 | objective | Work on: Clear 'em Out |
| alliance-riverglades | 95792 | turnin | Complete: Clear 'em Out |
| alliance-riverglades | 95912 | accept | Pick up: WANTED: Blademaster Kaijo |
| alliance-riverglades | 95912 | turnin | Complete: WANTED: Blademaster Kaijo |
| alliance-riverglades | 95913 | turnin | Complete: Fit for a Princess |
| alliance-riverglades | 95934 | accept | Pick up: Proof of Profit |
| alliance-riverglades | 95934 | objective | Work on: Proof of Profit |
| alliance-riverglades | 95934 | turnin | Complete: Proof of Profit |
| alliance-riverglades | 95935 | accept | Pick up: Hail the Dragonslayer [A] |
| alliance-riverglades | 95935 | objective | Work on: Hail the Dragonslayer [A] |
| alliance-riverglades | 95935 | turnin | Complete: Hail the Dragonslayer [A] |
| alliance-riverglades | 95943 | objective | Work on: Foreman's Plight |
| alliance-riverglades | 95957 | accept | Pick up: Drink Up! |
| alliance-riverglades | 95957 | turnin | Complete: Drink Up! |
| alliance-riverglades | 95961 | turnin | Complete: Stepped Out |
| alliance-riverglades | 95975 | accept | Pick up: Her World |
| alliance-riverglades | 95975 | objective | Work on: Her World |
| alliance-riverglades | 95975 | turnin | Complete: Her World |
| alliance-riverglades | 95982 | objective | Work on: Not My Circus |
| alliance-riverglades | 95982 | turnin | Complete: Not My Circus |
| alliance-riverglades | 95983 | accept | Pick up: A Feast for Buzzards [A] |
| alliance-riverglades | 95983 | turnin | Complete: A Feast for Buzzards [A] |
| alliance-riverglades | 95984 | accept | Pick up: Song of the Strider [A] |
| alliance-riverglades | 95984 | turnin | Complete: Song of the Strider [A] |
| alliance-riverglades | 95986 | accept | Pick up: King of the Wild Plains [A] |
| alliance-riverglades | 95986 | turnin | Complete: King of the Wild Plains [A] |
| alliance-riverglades | 95988 | accept | Pick up: Goes Down Smooth |
| alliance-riverglades | 95988 | turnin | Complete: Goes Down Smooth |
| alliance-riverglades | 95991 | accept | Pick up: WANTED: Ghostmaw [A] |
| alliance-riverglades | 96009 | objective | Work on: High Stakes |
| alliance-riverglades | 96015 | accept | Pick up: A Miner Problem |
| alliance-riverglades | 96015 | turnin | Complete: A Miner Problem |
| alliance-riverglades | 96063 | objective | Work on: Gaseous Gold |
| alliance-riverglades | 96063 | turnin | Complete: Gaseous Gold |
| alliance-riverglades | 96067 | turnin | Complete: Rock 'em and Sock 'em |
| alliance-riverglades | 96082 | accept | Pick up: Doctor's Orderly |
| alliance-riverglades | 96082 | turnin | Complete: Doctor's Orderly |
| alliance-riverglades | 96083 | accept | Pick up: Clerical Quarantine |
| alliance-riverglades | 96083 | turnin | Complete: Clerical Quarantine |
| alliance-riverglades | 96084 | objective | Work on: Something's in the Water |
| alliance-riverglades | 96084 | turnin | Complete: Something's in the Water |
| alliance-riverglades | 96085 | objective | Work on: Upstream Contamination |
| alliance-riverglades | 96085 | turnin | Complete: Upstream Contamination |
| alliance-riverglades | 96126 | accept | Pick up: An Ogre's Captive |
| alliance-riverglades | 96126 | turnin | Complete: An Ogre's Captive |
| alliance-silithus | 8317 | objective | Work on: Kitchen Assistance |
| alliance-silithus | 8496 | objective | Work on: Bandages for the Field (A) |
| alliance-silithus | 8540 | objective | Work on: Boots for the Guard (A) |
| alliance-silithus | 8541 | objective | Work on: Grinding Stones for the Guard (A) |
| alliance-silithus | 8781 | objective | Work on: Arms for the Field (A) |
| alliance-silithus | 8856 | accept | Desert Survival Kits (A) |
| alliance-silithus | 8856 | turnin | Desert Survival Kits (A) |
| alliance-silithus | 9023 | objective | Work on: The Perfect Poison |
| alliance-stonetalon | 1511 | turnin | Ken'zigla's Draught |
| alliance-stranglethorn-vale | 1036 | objective | Work on: Avast Ye, Scallywag |
| alliance-stranglethorn-vale | 2761 | objective | Work on: Smelt On, Smelt Off |
| alliance-stranglethorn-vale | 95384 | accept | Pick up: Partial Mystical Notes |
| alliance-stranglethorn-vale | 95384 | turnin | Complete: Partial Mystical Notes |
| alliance-stranglethorn-vale | 95786 | accept | Pick up: An Acquaintance in Southshore |
| alliance-stranglethorn-vale | 95786 | objective | Work on: An Acquaintance in Southshore |
| alliance-stranglethorn-vale | 95786 | turnin | Complete: An Acquaintance in Southshore |
| alliance-stranglethorn-vale | 97048 | accept | Pick up: Returning to Port |
| alliance-stranglethorn-vale | 97328 | objective | Work on: Anything of Value |
| alliance-stranglethorn-vale | 97420 | accept | Pick up: Reduce, Reuse, Reconcile |
| alliance-stranglethorn-vale | 97420 | turnin | Complete: Reduce, Reuse, Reconcile |
| alliance-swamp-of-sorrows | 93176 | objective | Work on: My Little Friends |
| alliance-swamp-of-sorrows | 93429 | turnin | Complete: Blood of My Blood |
| alliance-swamp-of-sorrows | 93430 | accept | Pick up: Taking the Bait Back |
| alliance-swamp-of-sorrows | 93430 | turnin | Complete: Taking the Bait Back |
| alliance-swamp-of-sorrows | 93585 | turnin | Complete: This Light of Mine |
| alliance-tanaris | 2771 | objective | Work on: A Good Head On Your Shoulders |
| alliance-tanaris | 2772 | objective | Work on: The World At Your Feet |
| alliance-tanaris | 2773 | objective | Work on: The Mithril Kid |
| alliance-tanaris | 3638 | objective | Work on: The Pledge of Secrecy |
| alliance-tanaris | 7653 | objective | Work on: Imperial Plate Belt |
| alliance-tanaris | 7654 | objective | Work on: Imperial Plate Boots |
| alliance-tanaris | 7655 | objective | Work on: Imperial Plate Bracer |
| alliance-tanaris | 7656 | objective | Work on: Imperial Plate Chest |
| alliance-tanaris | 7657 | objective | Work on: Imperial Plate Helm |
| alliance-tanaris | 7658 | objective | Work on: Imperial Plate Leggings |
| alliance-tanaris | 7659 | objective | Work on: Imperial Plate Shoulders |
| alliance-thousand-needles | 1192 | objective | Work on: Indurium Ore |
| alliance-thousand-needles | 96136 | accept | Call of Air |
| alliance-thousand-needles | 96136 | turnin | Call of Air |
| alliance-wetlands | 98294 | accept | Pick up: Forced Disarmament? (Triggered shortly after I picked up the Dragonmaw Armaments) |
| alliance-wetlands | 98294 | turnin | Complete: Forced Disarmament? (Triggered shortly after I picked up the Dragonmaw Armaments) |
| alliance-winterspring | 5305 | objective | Work on: Sweet Serenity |
| alliance-winterspring | 5306 | objective | Work on: Snakestone of the Shadow Huntress |
| alliance-winterspring | 5307 | objective | Work on: Corruption |
| horde-arathi-highlands | 640 | objective | Work on: The Broken Sigil |
| horde-arathi-highlands | 643 | objective | Work on: Sigil of Arathor |
| horde-arathi-highlands | 644 | objective | Work on: Sigil of Trollbane |
| horde-arathi-highlands | 92519 | objective | Work on: Ward Restocking |
| horde-arathi-highlands | 92707 | accept | Pick up: The Giant in the Den |
| horde-arathi-highlands | 92707 | turnin | Complete: The Giant in the Den |
| horde-ashenvale | 2 | accept | Pick up: Sharptalon's Claw |
| horde-ashenvale | 23 | accept | Pick up: Ursangous's Paw |
| horde-ashenvale | 24 | accept | Pick up: Shadumbra's Head |
| horde-ashenvale | 6503 | objective | Work on: Ashenvale Outrunners |
| horde-ashenvale | 6504 | objective | Work on: The Lost Pages |
| horde-azshara | 3381 | turnin | Complete: A Meeting with the Master |
| horde-badlands | 716 | objective | Work on: Stone Is Better than Cloth |
| horde-badlands | 735 | turnin | Complete: The Star, the Hand and the Heart [A] |
| horde-badlands | 9439 | turnin | Complete: Unclaimed Baggage |
| horde-desolace | 1367 | objective | Work on: Magram Alliance |
| horde-desolace | 1368 | objective | Work on: Gelkis Alliance |
| horde-desolace | 1371 | objective | Work on: Gizmo for Warug |
| horde-desolace | 92754 | accept | Pick up: A New Need for Shadow Protection |
| horde-desolace | 92754 | turnin | Complete: A New Need for Shadow Protection |
| horde-desolace | 92814 | accept | Pick up: I Need a Tailor |
| horde-desolace | 92814 | turnin | Complete: I Need a Tailor |
| horde-desolace | 92817 | accept | Pick up: Leather Technique |
| horde-desolace | 92817 | turnin | Complete: Leather Technique |
| horde-desolace | 93045 | accept | Pick up: Test Your Theory |
| horde-desolace | 93045 | objective | Work on: Test Your Theory |
| horde-desolace | 93196 | accept | Pick up: Khan Jehn (Magram) |
| horde-desolace | 93196 | objective | Work on: Khan Jehn (Magram) |
| horde-desolace | 93196 | turnin | Complete: Khan Jehn (Magram) |
| horde-desolace | 93678 | accept | Pick up: Abridged Notes on Draenethyst |
| horde-desolace | 93678 | objective | Work on: Abridged Notes on Draenethyst |
| horde-desolace | 93678 | turnin | Complete: Abridged Notes on Draenethyst |
| horde-desolace | 97265 | turnin | Complete: Hate the Hatefury |
| horde-durotar | 784 | objective | Work on: Vanquish the Betrayers |
| horde-durotar | 96873 | objective | Work on: A Pain in the Neck |
| horde-dustwallow-marsh | 1201 | objective | Work on: Theramore Spies |
| horde-dustwallow-marsh | 1203 | objective | Work on: Jarl Needs a Blade |
| horde-eastern-plaguelands | 5149 | objective | Work on: Pamela's Doll |
| horde-eastern-plaguelands | 6026 | objective | Work on: That's Asking A Lot |
| horde-eastern-plaguelands | 6146 | objective | Work on: Nathanos' Ruse |
| horde-felwood | 5890 | objective | Work on: Salve via Skinning (1/2) |
| horde-felwood | 5891 | objective | Work on: Salve via Disenchanting (1/2) |
| horde-feralas | 2973 | objective | Work on: A New Cloak's Sheen |
| horde-hillsbrad-foothills | 527 | objective | Work on: Battle of Hillsbrad (1/7) |
| horde-hillsbrad-foothills | 528 | objective | Work on: Battle of Hillsbrad (2/7) |
| horde-hillsbrad-foothills | 539 | objective | Work on: Battle of Hillsbrad (5/7) |
| horde-hillsbrad-foothills | 541 | objective | Work on: Battle of Hillsbrad (6/7) |
| horde-hillsbrad-foothills | 547 | objective | Work on: Humbert's Sword |
| horde-hillsbrad-foothills | 567 | objective | Work on: Dangerous! |
| horde-mount-hyjal | 92521 | accept | Pick up: The Demon Tower |
| horde-mount-hyjal | 92521 | turnin | Complete: The Demon Tower |
| horde-mulgore | 96294 | objective | Work on: A Darker Truth |
| horde-mulgore | 99197 | turnin | Complete: A Donation of Silk |
| horde-riverglades | 93786 | turnin | Complete: A Message in Blood |
| horde-riverglades | 93787 | objective | Work on: Food for the Taking |
| horde-riverglades | 93971 | accept | Pick up: Farholde Scouting Report |
| horde-riverglades | 93971 | objective | Work on: Farholde Scouting Report |
| horde-riverglades | 93971 | turnin | Complete: Farholde Scouting Report |
| horde-riverglades | 94480 | objective | Work on: A Gift From Our Enemies |
| horde-riverglades | 94481 | turnin | Complete: A Serving of Strength |
| horde-riverglades | 94532 | turnin | Complete: Gnoll Infestation [H] |
| horde-riverglades | 94533 | objective | Work on: Snargl's Snout [H] |
| horde-riverglades | 94533 | turnin | Complete: Snargl's Snout [H] |
| horde-riverglades | 94669 | turnin | Complete: Pay to Play |
| horde-riverglades | 94670 | turnin | Complete: Bloodmaster's Ring (2/7) |
| horde-riverglades | 94672 | turnin | Complete: Encroaching Twilight |
| horde-riverglades | 94680 | turnin | Complete: Twilight Missives |
| horde-riverglades | 94727 | objective | Work on: Digging for Answers |
| horde-riverglades | 94727 | turnin | Complete: Digging for Answers |
| horde-riverglades | 94734 | objective | Work on: A Boar's Delight |
| horde-riverglades | 94734 | turnin | Complete: A Boar's Delight |
| horde-riverglades | 94737 | objective | Work on: A Treat for a Friend |
| horde-riverglades | 94739 | turnin | Complete: Bloodmaster's Ring (3/7) |
| horde-riverglades | 94744 | turnin | Complete: The Wayward Warrior |
| horde-riverglades | 94745 | accept | Pick up: Carving a Path [H] |
| horde-riverglades | 94745 | turnin | Complete: Carving a Path [H] |
| horde-riverglades | 94748 | accept | Pick up: Break Their Chains |
| horde-riverglades | 94748 | turnin | Complete: Break Their Chains |
| horde-riverglades | 94768 | accept | Pick up: Bring Me His Head [H] |
| horde-riverglades | 94768 | objective | Work on: Bring Me His Head [H] |
| horde-riverglades | 94768 | turnin | Complete: Bring Me His Head [H] |
| horde-riverglades | 94961 | turnin | Complete: Biting the Hand (1/2) |
| horde-riverglades | 94962 | turnin | Complete: Bloodmaster's Ring (4/7) |
| horde-riverglades | 94963 | turnin | Complete: Biting the Hand (2/2) |
| horde-riverglades | 94964 | turnin | Complete: Bloodmaster's Ring (5/7) |
| horde-riverglades | 94965 | turnin | Complete: Bloodmaster's Ring (6/7) |
| horde-riverglades | 95062 | objective | Work on: Frazzlespark's Crate [H] |
| horde-riverglades | 95118 | turnin | Complete: Saltwater Savages |
| horde-riverglades | 95120 | accept | Pick up: WANTED: Old Rot-Chum |
| horde-riverglades | 95122 | turnin | Complete: Unchecked Expansion |
| horde-riverglades | 95123 | objective | Work on: A Blast Ye Scurvy Dogs! |
| horde-riverglades | 95123 | turnin | Complete: A Blast Ye Scurvy Dogs! |
| horde-riverglades | 95124 | turnin | Complete: Admiral Lamora |
| horde-riverglades | 95162 | turnin | Complete: Paletusk Harvesting |
| horde-riverglades | 95163 | turnin | Complete: Drive Them Back |
| horde-riverglades | 95165 | objective | Work on: See Ya, Scallywags! |
| horde-riverglades | 95183 | objective | Work on: Step One: Rock |
| horde-riverglades | 95183 | turnin | Complete: Step One: Rock |
| horde-riverglades | 95260 | accept | Pick up: Terrors From the Deep |
| horde-riverglades | 95261 | turnin | Complete: It Takes Guts |
| horde-riverglades | 95267 | objective | Work on: The Monster Surfaces |
| horde-riverglades | 95278 | accept | Pick up: It Is Time, Brother... |
| horde-riverglades | 95278 | objective | Work on: It Is Time, Brother... |
| horde-riverglades | 95288 | turnin | Complete: Smuggler's Paradise |
| horde-riverglades | 95293 | turnin | Complete: Smuggler's Special |
| horde-riverglades | 95294 | accept | Pick up: Smuggler's Bargain |
| horde-riverglades | 95312 | turnin | Complete: Coming to Collect |
| horde-riverglades | 95321 | accept | Pick up: Tazzik's Dues |
| horde-riverglades | 95321 | turnin | Complete: Tazzik's Dues |
| horde-riverglades | 95322 | objective | Work on: Get the Goods |
| horde-riverglades | 95322 | turnin | Complete: Get the Goods |
| horde-riverglades | 95325 | turnin | Complete: We've Been Robbed! |
| horde-riverglades | 95326 | accept | Pick up: The Big Payback |
| horde-riverglades | 95417 | accept | Pick up: The Purple Ones |
| horde-riverglades | 95417 | turnin | Complete: The Purple Ones |
| horde-riverglades | 95418 | accept | Pick up: Spread the Word |
| horde-riverglades | 95424 | turnin | Complete: Might Makes Right |
| horde-riverglades | 95425 | objective | Work on: Unworthy Champion |
| horde-riverglades | 95425 | turnin | Complete: Unworthy Champion |
| horde-riverglades | 95427 | accept | Pick up: Twilight No More! |
| horde-riverglades | 95427 | objective | Work on: Twilight No More! |
| horde-riverglades | 95427 | turnin | Complete: Twilight No More! |
| horde-riverglades | 95431 | accept | Pick up: Rumblings of Discontent |
| horde-riverglades | 95432 | turnin | Complete: Rise Up! |
| horde-riverglades | 95433 | objective | Work on: Death to the Executioner |
| horde-riverglades | 95472 | accept | Pick up: Consolation Prize |
| horde-riverglades | 95472 | turnin | Complete: Consolation Prize |
| horde-riverglades | 95601 | accept | Pick up: The Purple Ones |
| horde-riverglades | 95601 | objective | Work on: The Purple Ones |
| horde-riverglades | 95601 | turnin | Complete: The Purple Ones |
| horde-riverglades | 95602 | accept | Pick up: Sickening Lights |
| horde-riverglades | 95602 | objective | Work on: Sickening Lights |
| horde-riverglades | 95602 | turnin | Complete: Sickening Lights |
| horde-riverglades | 95792 | accept | Pick up: Clear 'em Out |
| horde-riverglades | 95792 | objective | Work on: Clear 'em Out |
| horde-riverglades | 95792 | turnin | Complete: Clear 'em Out |
| horde-riverglades | 95934 | accept | Pick up: Proof of Profit |
| horde-riverglades | 95934 | objective | Work on: Proof of Profit |
| horde-riverglades | 95934 | turnin | Complete: Proof of Profit |
| horde-riverglades | 95936 | accept | Pick up: Hail the Dragonslayer [H] |
| horde-riverglades | 95936 | objective | Work on: Hail the Dragonslayer [H] |
| horde-riverglades | 95936 | turnin | Complete: Hail the Dragonslayer [H] |
| horde-riverglades | 95951 | objective | Work on: Fetch 'n' Fletch |
| horde-riverglades | 95951 | turnin | Complete: Fetch 'n' Fletch |
| horde-riverglades | 95982 | objective | Work on: Not My Circus |
| horde-riverglades | 95982 | turnin | Complete: Not My Circus |
| horde-riverglades | 96026 | objective | Work on: Step Two: More Rock |
| horde-riverglades | 96026 | turnin | Complete: Step Two: More Rock |
| horde-riverglades | 96063 | objective | Work on: Gaseous Gold |
| horde-riverglades | 96063 | turnin | Complete: Gaseous Gold |
| horde-riverglades | 96067 | turnin | Complete: Rock 'em and Sock 'em |
| horde-riverglades | 96103 | accept | Pick up: A Feast for Buzzards [H] |
| horde-riverglades | 96104 | objective | Work on: Song of the Strider [H] |
| horde-riverglades | 96104 | turnin | Complete: Song of the Strider [H] |
| horde-riverglades | 96105 | turnin | Complete: King of the Wild Plains [H] |
| horde-riverglades | 96109 | turnin | Complete: A Hunter's Quiver |
| horde-riverglades | 97884 | objective | Work on: Armory of Sunnyglade |
| horde-shen-dralas | 93041 | objective | Work on: Facing the Truth |
| horde-shen-dralas | 93058 | accept | Pick up: Saving Our Own |
| horde-shen-dralas | 93058 | objective | Work on: Saving Our Own |
| horde-shen-dralas | 93062 | accept | Pick up: Bone Burying |
| horde-shen-dralas | 93072 | accept | Pick up: Long-Term Solutions |
| horde-shen-dralas | 93072 | turnin | Complete: Long-Term Solutions |
| horde-shen-dralas | 93125 | accept | Pick up: Going Home |
| horde-shen-dralas | 93125 | turnin | Complete: Going Home |
| horde-shen-dralas | 93129 | accept | Pick up: Threat of Starvation |
| horde-shen-dralas | 93129 | objective | Work on: Threat of Starvation |
| horde-shen-dralas | 93129 | turnin | Complete: Threat of Starvation |
| horde-shen-dralas | 93188 | accept | Pick up: Return to Orgrul |
| horde-shen-dralas | 93188 | turnin | Complete: Return to Orgrul |
| horde-silithus | 8317 | objective | Work on: Kitchen Assistance |
| horde-silithus | 9023 | objective | Work on: The Perfect Poison |
| horde-silverpine-forest | 530 | objective | Work on: A Husband's Revenge |
| horde-silverpine-forest | 98299 | objective | Work on: Stop the Spread |
| horde-stonetalon-mountains | 1087 | objective | Work on: Cenarius' Legacy |
| horde-stonetalon-mountains | 1088 | objective | Work on: Ordanus |
| horde-stranglethorn-vale | 1036 | objective | Work on: Avast Ye, Scallywag |
| horde-stranglethorn-vale | 2761 | objective | Work on: Smelt On, Smelt Off |
| horde-stranglethorn-vale | 3642 | objective | Work on: The Pledge of Secrecy |
| horde-stranglethorn-vale | 3643 | objective | Work on: Show Your Work |
| horde-stranglethorn-vale | 95384 | accept | Pick up: Partial Mystical Notes |
| horde-stranglethorn-vale | 95384 | turnin | Complete: Partial Mystical Notes |
| horde-stranglethorn-vale | 97048 | accept | Pick up: Returning to Port |
| horde-stranglethorn-vale | 97328 | objective | Work on: Anything of Value |
| horde-swamp-of-sorrows | 93176 | objective | Work on: My Little Friends |
| horde-swamp-of-sorrows | 93430 | accept | Pick up: Taking the Bait Back |
| horde-swamp-of-sorrows | 93430 | turnin | Complete: Taking the Bait Back |
| horde-swamp-of-sorrows | 93663 | objective | Work on: Lost in Transit |
| horde-tanaris | 2771 | objective | Work on: A Good Head On Your Shoulders |
| horde-tanaris | 2772 | objective | Work on: The World At Your Feet |
| horde-tanaris | 2773 | objective | Work on: The Mithril Kid |
| horde-tanaris | 3638 | objective | Work on: The Pledge of Secrecy |
| horde-tanaris | 3639 | objective | Work on: Show Your Work |
| horde-tanaris | 7653 | objective | Work on: Imperial Plate Belt |
| horde-tanaris | 7654 | objective | Work on: Imperial Plate Boots |
| horde-tanaris | 7655 | objective | Work on: Imperial Plate Bracer |
| horde-tanaris | 7656 | objective | Work on: Imperial Plate Chest |
| horde-tanaris | 7657 | objective | Work on: Imperial Plate Helm |
| horde-tanaris | 7658 | objective | Work on: Imperial Plate Leggings |
| horde-tanaris | 7659 | objective | Work on: Imperial Plate Shoulders |
| horde-the-barrens | 3513 | accept | Pick up: The Runed Scroll |
| horde-the-barrens | 3514 | objective | Work on: Horde Presence |
| horde-the-barrens | 55296 | accept | Pick up: Completed when turning in Chen's Empty Keg (2/3) (821) |
| horde-the-barrens | 55296 | turnin | Complete: Completed when turning in Chen's Empty Keg (2/3) (821) |
| horde-the-barrens | 843 | objective | Work on: Gann's Reclamation |
| horde-the-barrens | 846 | objective | Work on: Revenge of Gann (1/2) |
| horde-the-barrens | 95819 | objective | Work on: Sign Me Up! |
| horde-the-hinterlands | 7830 | objective | Work on: Avenging the Fallen |
| horde-the-hinterlands | 7841 | objective | Work on: Message to the Wildhammer |
| horde-thousand-needles | 1150 | objective | Work on: Test of Endurance |
| horde-thousand-needles | 98069 | objective | Work on: Stolen Freewind Supplies |
| horde-winterspring | 5305 | objective | Work on: Sweet Serenity |
| horde-winterspring | 5306 | objective | Work on: Snakestone of the Shadow Huntress |
| horde-winterspring | 5307 | objective | Work on: Corruption |
