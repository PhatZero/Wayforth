# Forever quest location coverage

Generated from the bundled manifest by `scripts/audit_quest_locations.lua`.

Sources are corrected Forever facts from QuestieDB, the compiled AllTheThings Forever catalog, Wowhead Forever and Classic quest maps, AHledger, WoWDB, and reviewed quest/item pages found through web searches. Exact revisions and the refresh command are in `docs/QUEST_LOCATION_SOURCES.md`.

Counts include the union of faction, race and class variants within each guide. Shared quests can appear in multiple guides.

| Phase | Quest IDs present | Static destinations | Missing static destinations |
| --- | ---: | ---: | ---: |
| accept | 2916 | 2905 | 11 |
| objective | 1880 | 1785 | 95 |
| turnin | 2926 | 2921 | 5 |

Static coverage describes source availability. It does not verify quest eligibility or live-client accuracy. Some requirements involve crafting, reputation or player-held items and have no single world destination. Unresolved phases use an active quest's live marker when available.

Of the 95 missing objective destinations, 95 have specific source-backed requirements in the tracker. They remain counted as missing static destinations.

| Guide | Quest steps | Static destinations | Missing |
| --- | ---: | ---: | ---: |
| zephras-alliance | 73 | 73 | 0 |
| zephras-horde | 67 | 67 | 0 |
| alliance-elwynn | 63 | 63 | 0 |
| alliance-dun-morogh | 53 | 53 | 0 |
| alliance-teldrassil | 59 | 59 | 0 |
| alliance-darkshore | 205 | 205 | 0 |
| alliance-stonetalon | 63 | 63 | 0 |
| alliance-ashenvale | 119 | 119 | 0 |
| alliance-thousand-needles | 81 | 80 | 1 |
| alliance-desolace | 147 | 142 | 5 |
| alliance-dustwallow | 100 | 99 | 1 |
| alliance-feralas | 125 | 123 | 2 |
| alliance-tanaris | 175 | 165 | 10 |
| alliance-azshara | 68 | 68 | 0 |
| alliance-ungoro | 131 | 131 | 0 |
| alliance-felwood | 197 | 195 | 2 |
| alliance-winterspring | 121 | 118 | 3 |
| alliance-silithus | 270 | 263 | 7 |
| alliance-hyjal | 3 | 1 | 2 |
| alliance-barrens | 141 | 140 | 1 |
| alliance-moonglade | 70 | 70 | 0 |
| horde-durotar | 187 | 187 | 0 |
| horde-mulgore | 194 | 193 | 1 |
| horde-the-barrens | 265 | 264 | 1 |
| horde-stonetalon-mountains | 89 | 89 | 0 |
| horde-ashenvale | 64 | 63 | 1 |
| horde-thousand-needles | 149 | 148 | 1 |
| horde-desolace | 159 | 153 | 6 |
| horde-dustwallow-marsh | 71 | 70 | 1 |
| horde-feralas | 94 | 94 | 0 |
| horde-tanaris | 148 | 137 | 11 |
| horde-azshara | 60 | 60 | 0 |
| horde-un-goro-crater | 99 | 99 | 0 |
| horde-felwood | 72 | 71 | 1 |
| horde-winterspring | 71 | 68 | 3 |
| horde-silithus | 112 | 110 | 2 |
| horde-mount-hyjal | 3 | 0 | 3 |
| horde-shen-dralas | 32 | 25 | 7 |
| horde-tirisfal-glades | 212 | 212 | 0 |
| horde-silverpine-forest | 120 | 120 | 0 |
| alliance-loch-modan | 123 | 122 | 1 |
| alliance-westfall | 117 | 117 | 0 |
| alliance-redridge-mountains | 111 | 110 | 1 |
| alliance-duskwood | 183 | 183 | 0 |
| alliance-wetlands | 180 | 180 | 0 |
| alliance-hillsbrad-foothills | 33 | 33 | 0 |
| horde-hillsbrad-foothills | 87 | 87 | 0 |
| alliance-alterac-mountains | 43 | 42 | 1 |
| horde-alterac-mountains | 34 | 34 | 0 |
| alliance-arathi-highlands | 99 | 99 | 0 |
| horde-arathi-highlands | 122 | 122 | 0 |
| alliance-stranglethorn-vale | 270 | 267 | 3 |
| horde-stranglethorn-vale | 262 | 259 | 3 |
| alliance-badlands | 99 | 98 | 1 |
| horde-badlands | 85 | 83 | 2 |
| alliance-swamp-of-sorrows | 48 | 48 | 0 |
| horde-swamp-of-sorrows | 75 | 74 | 1 |
| alliance-riverglades | 300 | 285 | 15 |
| horde-riverglades | 254 | 243 | 11 |
| alliance-the-hinterlands | 36 | 36 | 0 |
| horde-the-hinterlands | 83 | 83 | 0 |
| alliance-searing-gorge | 86 | 86 | 0 |
| horde-searing-gorge | 61 | 61 | 0 |
| alliance-blasted-lands | 33 | 33 | 0 |
| horde-blasted-lands | 26 | 26 | 0 |
| alliance-burning-steppes | 20 | 20 | 0 |
| horde-burning-steppes | 11 | 11 | 0 |
| alliance-western-plaguelands | 59 | 59 | 0 |
| horde-western-plaguelands | 54 | 54 | 0 |
| alliance-eastern-plaguelands | 87 | 87 | 0 |
| horde-eastern-plaguelands | 109 | 109 | 0 |

## Unresolved static destinations

Quest names below omit WayForth's Work on, Pick up and Complete labels, chain numbering and faction annotations. Use the clean name and quest ID when searching. The complete 101-quest web search receipt is in `scripts/data/quest_web_search_review.json`.

| Guide | Quest ID | Quest name | Phase | Known requirements |
| --- | ---: | --- | --- | --- |
| alliance-alterac-mountains | 96800 | Past Due | objective | Wowhead Forever (instance): Find The Lost Magic of the Runemasters in Scarlet Monastery's Library. A player report places the book on a table on the right side of the final boss room. Check your quest log for current requirements and quantities. |
| alliance-badlands | 716 | Stone Is Better than Cloth | objective | Wowhead Classic (craft): Have a blacksmith craft Patterned Bronze Bracers, or buy them for Lucien Tosselwrench. Check your quest log for current requirements and quantities. |
| alliance-barrens | 1796 | Components for the Enchanted Gold Bloodrobe | objective | WoWDB (craft): Craft or buy Robes of Arcana for Menara Voidrender. Check your quest log for current requirements and quantities. |
| alliance-desolace | 1371 | Gizmo for Warug | objective | WoWDB (craft): Obtain an Advanced Target Dummy and keep your Magram reputation high enough to speak with Warug. Check your quest log for current requirements and quantities. |
| alliance-desolace | 92754 | A New Need for Shadow Protection | objective | Wowhead Forever (craft): Prepare Greater Shadow Protection Potions for Mirda in Magram Village and maintain your Magram reputation. Check your quest log for current requirements and quantities. |
| alliance-desolace | 93196 | Khan Jehn | accept |  |
| alliance-desolace | 93196 | Khan Jehn | objective | Wowhead Forever (event): Maintain Honored Magram reputation and use the Ultimate Necromancy Staff at the ritual tent beside Magram Village's central lake. Check your quest log for current requirements and quantities. |
| alliance-desolace | 93196 | Khan Jehn | turnin |  |
| alliance-dustwallow | 1203 | Jarl Needs a Blade | objective | Wowhead Classic (craft): Craft or buy a Moonsteel Broadsword for Jarl in Dustwallow Marsh. Check your quest log for current requirements and quantities. |
| alliance-felwood | 4107 | Salve via Disenchanting | objective | Wowhead Classic (craft): Disenchant suitable magic items, or buy Lesser Nether Essence, for the Cenarion plant salve exchange. Check your quest log for current requirements and quantities. |
| alliance-felwood | 5886 | Salve via Disenchanting | objective | Wowhead Classic (craft): Obtain Lesser Nether Essence by disenchanting magic items or buying it for the Cenarion plant salve exchange. Check your quest log for current requirements and quantities. |
| alliance-feralas | 3791 | The Mystery of Morrowgrain | objective | WoWDB (supplies): Collect 10 Morrowgrain for Quintis Jonespyre. The quest supplies an Evergreen Pouch. Check your quest log for current requirements and quantities. |
| alliance-feralas | 3792 | Morrowgrain to Feathermoon Stronghold | objective | Wowhead Classic (supplies): Grow or obtain Morrowgrain for Quintis Jonespyre. Use the Evergreen Pouch with the required soil and seeds. Check your quest log for current requirements and quantities. |
| alliance-hyjal | 92521 | The Demon Tower | objective | Wowhead Forever (event): Watch Hnaz's imp at the tower containing the captive satyr. Its exact pickup and return locations remain unresolved. Check your quest log for current requirements and quantities. |
| alliance-hyjal | 92521 | The Demon Tower | turnin |  |
| alliance-loch-modan | 86776 | Ingredients for the Forge | objective | Wowhead Forever (supplies): Smelt or buy Bronze Bars for Morhan Coppertongue in Thelsamar. Check your quest log for current requirements and quantities. |
| alliance-redridge-mountains | 95816 | Sign Me Up! | objective | Wowhead Forever (use-item): Complete the provided Massive Pile of Forms, then bring the finished forms to Elaine Compton in Redridge Mountains. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 94615 | Foal Play | objective | Wowhead Forever (loot): Search beside the stables at Wheeler's Grange and make a tracing of the pawprints left by the missing horses. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 94879 | Scraps of Knowledge | objective | Wowhead Forever (loot): Collect Twilight Pages from the ruined houses in Sunnyglade for Ashe Amberhall. Look for pale pages resting on crates. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 94923 | Hats Off | objective | Wowhead Forever (loot): Look for Robbie's Hat in the large clam on the river island west of Wheeler's Grange. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 94931 | Stolen Saws | objective | Wowhead Forever (loot): Recover the stashed Saw Blades from gnoll camps in Bristle Hills for Halligan Turner. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95123 | A Blast Ye Scurvy Dogs! | objective | Wowhead Forever (loot): Steal Eastsea Powder Kegs near the demolished settlement of Winstead for Wharfmaster Whizzbuzz. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95156 | Stuff 'Em and Stick 'Em | objective | Wowhead Forever (loot): Collect Bundles of Hay at Wheeler's farm outside Farholde Keep for Ember Bladewhisper. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95184 | The Sharpest of Blades | objective | Wowhead Forever (craft): Craft or buy Solid Sharpening Stones for Ember Bladewhisper at Farholde's training grounds. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95426 | Rog'mar Supplies | objective | Wowhead Forever (loot): Steal Rog'mar Supply Crates from the Horde training camps north of Rog'mar. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95561 | Apple of My Eye | objective | Wowhead Forever (loot): Gather Fresh Apples beneath the apple trees inside Farholde Keep. Rotten apples cannot be collected. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95934 | Proof of Profit | objective | Wowhead Forever (loot): Search the dragon caves for a Cubic Draconia crystal for Gelinda Coppergleam. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95975 | Her World | objective | Wowhead Forever (loot): Gather Wildflowers for Tessa Dawnbright in Farholde Keep. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 95982 | Not My Circus | objective | Wowhead Forever (craft): Cook or buy Briny Seafood Stew for Jasper Geartoggle in Powderfuse Port. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 96009 | High Stakes | objective | Wowhead Forever (loot): Collect Wood Bundles at Turner's Logging Camp for Bertrand Ironbrow. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 96063 | Gaseous Gold | objective | Wowhead Forever (loot): Collect Marsh Gas Vials at the vents around the marshy ponds southwest of Sleebo Fizzlespout. Use the quantity in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-riverglades | 96084 | Something's in the Water | objective | Wowhead Forever (use-item): Fill the Empty Phial at the pools in the plains north of Farholde Keep, then take the sample to Sister Rowland. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8317 | Kitchen Assistance | objective | WoWDB (craft): Prepare 10 Smoked Desert Dumplings for Calandrath. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8496 | Bandages for the Field | objective | WoWDB (craft): Prepare 30 each of Heavy Runecloth Bandage, Heavy Mageweave Bandage and Heavy Silk Bandage. Keep Logistics Task Briefing X for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8540 | Boots for the Guard | objective | WoWDB (craft): Prepare 3 Ornate Mithril Boots. Keep Logistics Task Briefing II for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8541 | Grinding Stones for the Guard | objective | WoWDB (craft): Prepare 10 each of Dense Grinding Stone, Solid Grinding Stone and Heavy Grinding Stone. Keep Logistics Task Briefing III for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8781 | Arms for the Field | objective | WoWDB (craft): Prepare 2 Moonsteel Broadswords for Janela Stouthammer. Keep Logistics Task Briefing VI for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8856 | Desert Survival Kits | accept |  |
| alliance-silithus | 9023 | The Perfect Poison | objective | WoWDB (instance): Loot the venom sacs from High Priest Venoxis in Zul'Gurub and Kurinnaxx in the Ruins of Ahn'Qiraj. Check your quest log for current requirements and quantities. |
| alliance-stranglethorn-vale | 1036 | Avast Ye, Scallywag | objective | WoWDB (reputation): Meet the reputation requirement in your quest log, then speak with Fleet Master Firallon aboard the Crimson Veil off Stranglethorn. Check your quest log for current requirements and quantities. |
| alliance-stranglethorn-vale | 97328 | Anything of Value | objective | Wowhead Forever (loot): Recover Stolen Shipments from the crates around the Ruins of Zul'Kunda and deliver them to Booty Bay. Check your quest log for current requirements and quantities. |
| alliance-stranglethorn-vale | 97420 | Reduce, Reuse, Reconcile | accept |  |
| alliance-tanaris | 2771 | A Good Head On Your Shoulders | objective | WoWDB (craft): Prepare 2 Mithril Coifs and 1 Ornate Mithril Shoulder for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 2772 | The World At Your Feet | objective | WoWDB (craft): Prepare 2 Heavy Mithril Boots and 1 Ornate Mithril Pants for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 2773 | The Mithril Kid | objective | WoWDB (craft): Prepare 2 Heavy Mithril Breastplates and 1 Ornate Mithril Gloves for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7653 | Imperial Plate Belt | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Belt plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7654 | Imperial Plate Boots | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Boots plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7655 | Imperial Plate Bracer | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Bracer plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7656 | Imperial Plate Chest | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Chest plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7657 | Imperial Plate Helm | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Helm plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7658 | Imperial Plate Leggings | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Leggings plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7659 | Imperial Plate Shoulders | objective | Classic reference (supplies): Collect Thorium Bars for the Imperial Plate Shoulders plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| alliance-thousand-needles | 1192 | Indurium Ore | objective | WoWDB (loot): Collect 4 Indurium Ore. Check the quest log for the current source and remaining quantity. Check your quest log for current requirements and quantities. |
| alliance-winterspring | 5305 | Sweet Serenity | objective | Wowhead Classic (instance): In Stratholme's Scarlet Bastion, interact with the Blacksmithing Plans to summon the Crimson Hammersmith, then recover the Crimson Hammersmith's Apron. Check your quest log for current requirements and quantities. |
| alliance-winterspring | 5306 | Snakestone of the Shadow Huntress | objective | WoWDB (instance): Defeat Shadow Hunter Vosh'gajin in Blackrock Spire and loot Vosh'gajin's Snakestone. Check your quest log for current requirements and quantities. |
| alliance-winterspring | 5307 | Corruption | objective | Classic reference (instance): Defeat the Black Guard Swordsmith in Stratholme and recover the Insignia of the Black Guard. Check your quest log for current requirements and quantities. |
| horde-ashenvale | 6504 | The Lost Pages | objective | WoWDB (combine): Collect the 12 Shredder Operating Manual pages and combine them into Chapters 1, 2 and 3. Check your quest log for current requirements and quantities. |
| horde-badlands | 716 | Stone Is Better than Cloth | objective | Wowhead Classic (craft): Have a blacksmith craft Patterned Bronze Bracers, or buy them for Lucien Tosselwrench. Check your quest log for current requirements and quantities. |
| horde-badlands | 9439 | Unclaimed Baggage | turnin |  |
| horde-desolace | 1371 | Gizmo for Warug | objective | WoWDB (craft): Obtain an Advanced Target Dummy and keep your Magram reputation high enough to speak with Warug. Check your quest log for current requirements and quantities. |
| horde-desolace | 92754 | A New Need for Shadow Protection | objective | Wowhead Forever (craft): Prepare Greater Shadow Protection Potions for Mirda in Magram Village and maintain your Magram reputation. Check your quest log for current requirements and quantities. |
| horde-desolace | 93045 | Test Your Theory | objective | Wowhead Forever (use-item): Dispel the curse on the Accursed Skull using the quest's staff and crystal. Maintain Gelkis reputation, then report to Nerlokh. Check your quest log for current requirements and quantities. |
| horde-desolace | 93196 | Khan Jehn | accept |  |
| horde-desolace | 93196 | Khan Jehn | objective | Wowhead Forever (event): Maintain Honored Magram reputation and use the Ultimate Necromancy Staff at the ritual tent beside Magram Village's central lake. Check your quest log for current requirements and quantities. |
| horde-desolace | 93196 | Khan Jehn | turnin |  |
| horde-dustwallow-marsh | 1203 | Jarl Needs a Blade | objective | Wowhead Classic (craft): Craft or buy a Moonsteel Broadsword for Jarl in Dustwallow Marsh. Check your quest log for current requirements and quantities. |
| horde-felwood | 5891 | Salve via Disenchanting | objective | Classic reference (craft): Obtain Lesser Nether Essence by disenchanting magic items or buying it for the Cenarion plant salve exchange. Check your quest log for current requirements and quantities. |
| horde-mount-hyjal | 92521 | The Demon Tower | accept |  |
| horde-mount-hyjal | 92521 | The Demon Tower | objective | Wowhead Forever (event): Watch Hnaz's imp at the tower containing the captive satyr. Its exact pickup and return locations remain unresolved. Check your quest log for current requirements and quantities. |
| horde-mount-hyjal | 92521 | The Demon Tower | turnin |  |
| horde-mulgore | 96294 | A Darker Truth | objective | Wowhead Forever (delivery): Take the Bloody Parchment recovered from Broodmother Valraxx to Muln Earthfury at Skywatcher Plateau. Check your quest log for current requirements and quantities. |
| horde-riverglades | 93787 | Food for the Taking | objective | Wowhead Forever (loot): Take Feed Satchels from the Alliance farm in Meadowsbrook for Krom'rosh. Check your quest log for current requirements and quantities. |
| horde-riverglades | 93971 | Farholde Scouting Report | accept |  |
| horde-riverglades | 94734 | A Boar's Delight | objective | Wowhead Forever (loot): Find Sweetberries at the human farm near the ocean and Riverweed along the river for Gobam. Check your quest log for current requirements and quantities. |
| horde-riverglades | 95123 | A Blast Ye Scurvy Dogs! | objective | Wowhead Forever (loot): Steal Eastsea Powder Kegs near the demolished settlement of Winstead for Wharfmaster Whizzbuzz. Check your quest log for current requirements and quantities. |
| horde-riverglades | 95602 | Sickening Lights | objective | Wowhead Forever (event): Destroy the Twilight Ritual Circles in the caves beneath Sunnyglade. Check your quest log for current requirements and quantities. |
| horde-riverglades | 95934 | Proof of Profit | objective | Wowhead Forever (loot): Search the dragon caves for a Cubic Draconia crystal for Gelinda Coppergleam. Check your quest log for current requirements and quantities. |
| horde-riverglades | 95951 | Fetch 'n' Fletch | objective | Wowhead Forever (combine): Loot Wood Bundles from Peasant Woodpiles at Turner's Logging Camp, then use them to fletch Makeshift Stickin' Spears. Check your quest log for current requirements and quantities. |
| horde-riverglades | 95982 | Not My Circus | objective | Wowhead Forever (craft): Cook or buy Briny Seafood Stew for Jasper Geartoggle in Powderfuse Port. Check your quest log for current requirements and quantities. |
| horde-riverglades | 96026 | Step Two: More Rock | objective | Wowhead Forever (craft): Craft or buy Heavy Weightstones for Hamur in Bolder'ok. Check your quest log for current requirements and quantities. |
| horde-riverglades | 96063 | Gaseous Gold | objective | Wowhead Forever (loot): Collect Marsh Gas Vials at the vents around the marshy ponds southwest of Sleebo Fizzlespout. Use the quantity in your current quest log. Check your quest log for current requirements and quantities. |
| horde-riverglades | 97884 | Armory of Sunnyglade | objective | Wowhead Forever (loot): Search the basement of the old Sunnyglade armory for the Tremayne Family Blacksmithing Techniques tome. Check your quest log for current requirements and quantities. |
| horde-shen-dralas | 93041 | Facing the Truth | objective | Wowhead Forever (loot): Recover the Accursed Skull and Gelkis Necromantic Garb for Uthek the Wise. Maintain the required Gelkis reputation. Check your quest log for current requirements and quantities. |
| horde-shen-dralas | 93062 | Bone Burying | accept |  |
| horde-shen-dralas | 93072 | Long-Term Solutions | accept |  |
| horde-shen-dralas | 93125 | Going Home | accept |  |
| horde-shen-dralas | 93129 | Threat of Starvation | accept |  |
| horde-shen-dralas | 93129 | Threat of Starvation | objective | Wowhead Forever (loot): Recover Stolen Supplies from the Outcast Hideaway for Hagiak at the Magram Front. Maintain the required Magram reputation. Check your quest log for current requirements and quantities. |
| horde-shen-dralas | 93188 | Return to Orgrul | accept |  |
| horde-silithus | 8317 | Kitchen Assistance | objective | WoWDB (craft): Prepare 10 Smoked Desert Dumplings for Calandrath. Check your quest log for current requirements and quantities. |
| horde-silithus | 9023 | The Perfect Poison | objective | WoWDB (instance): Loot the venom sacs from High Priest Venoxis in Zul'Gurub and Kurinnaxx in the Ruins of Ahn'Qiraj. Check your quest log for current requirements and quantities. |
| horde-stranglethorn-vale | 1036 | Avast Ye, Scallywag | objective | WoWDB (reputation): Meet the reputation requirement in your quest log, then speak with Fleet Master Firallon aboard the Crimson Veil off Stranglethorn. Check your quest log for current requirements and quantities. |
| horde-stranglethorn-vale | 3643 | Show Your Work | objective | Wowhead Classic (craft): Prepare Mithril Tubes, an Accurate Scope and Advanced Target Dummies for Oglethorpe Obnoticus. Check your quest log for current requirements and quantities. |
| horde-stranglethorn-vale | 97328 | Anything of Value | objective | Wowhead Forever (loot): Recover Stolen Shipments from the crates around the Ruins of Zul'Kunda and deliver them to Booty Bay. Check your quest log for current requirements and quantities. |
| horde-swamp-of-sorrows | 93663 | Lost in Transit | objective | Wowhead Forever (loot): Search the waters along the road for the missing courier's shipment, then deliver it to the Harborage. Check your quest log for current requirements and quantities. |
| horde-tanaris | 2771 | A Good Head On Your Shoulders | objective | WoWDB (craft): Prepare 2 Mithril Coifs and 1 Ornate Mithril Shoulder for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| horde-tanaris | 2772 | The World At Your Feet | objective | WoWDB (craft): Prepare 2 Heavy Mithril Boots and 1 Ornate Mithril Pants for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| horde-tanaris | 2773 | The Mithril Kid | objective | WoWDB (craft): Prepare 2 Heavy Mithril Breastplates and 1 Ornate Mithril Gloves for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| horde-tanaris | 3639 | Show Your Work | objective | WoWDB (craft): Prepare 20 Big Iron Bombs, 20 Solid Dynamite and 5 Explosive Sheep for Nixx Sprocketspring. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7653 | Imperial Plate Belt | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Belt plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7654 | Imperial Plate Boots | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Boots plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7655 | Imperial Plate Bracer | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Bracer plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7656 | Imperial Plate Chest | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Chest plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7657 | Imperial Plate Helm | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Helm plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7658 | Imperial Plate Leggings | objective | Wowhead Classic (supplies): Collect Thorium Bars for the Imperial Plate Leggings plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7659 | Imperial Plate Shoulders | objective | Classic reference (supplies): Collect Thorium Bars for the Imperial Plate Shoulders plans. Use the quantity shown in your current quest log. Check your quest log for current requirements and quantities. |
| horde-the-barrens | 95819 | Sign Me Up! | objective | Wowhead Forever (use-item): Complete the provided Massive Pile of Forms, then bring the finished forms to Jornah in the Barrens. Check your quest log for current requirements and quantities. |
| horde-thousand-needles | 98069 | Stolen Freewind Supplies | objective | Wowhead Forever (loot): Recover Stolen Freewind Supplies from the harpy lair west of Freewind Post. Search the cliff base and the cave above. Check your quest log for current requirements and quantities. |
| horde-winterspring | 5305 | Sweet Serenity | objective | Wowhead Classic (instance): In Stratholme's Scarlet Bastion, interact with the Blacksmithing Plans to summon the Crimson Hammersmith, then recover the Crimson Hammersmith's Apron. Check your quest log for current requirements and quantities. |
| horde-winterspring | 5306 | Snakestone of the Shadow Huntress | objective | WoWDB (instance): Defeat Shadow Hunter Vosh'gajin in Blackrock Spire and loot Vosh'gajin's Snakestone. Check your quest log for current requirements and quantities. |
| horde-winterspring | 5307 | Corruption | objective | Classic reference (instance): Defeat the Black Guard Swordsmith in Stratholme and recover the Insignia of the Black Guard. Check your quest log for current requirements and quantities. |
