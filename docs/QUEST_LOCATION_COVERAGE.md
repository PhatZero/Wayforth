# Forever quest location coverage

Generated from the bundled manifest by `scripts/audit_quest_locations.lua`.

Sources are the corrected Forever facts from QuestieDB, the compiled AllTheThings Forever catalog, Wowhead Forever and Classic quest maps, and recorded quest giver/finisher names from AHledger and matching WoWDB references. Exact revisions and the refresh command are in `docs/QUEST_LOCATION_SOURCES.md`.

Counts include the union of faction, race and class variants within each guide. Shared quests can appear in multiple guides.

| Phase | Quest IDs present | Static destinations | Missing static destinations |
| --- | ---: | ---: | ---: |
| accept | 2916 | 2899 | 17 |
| objective | 1876 | 1761 | 115 |
| turnin | 2926 | 2912 | 14 |

Static coverage describes source availability. It does not verify quest eligibility or live-client accuracy. Some requirements involve crafting, reputation or player-held items and have no single world destination. Unresolved phases use an active quest's live marker when available.

Of the 115 missing objective destinations, 33 have specific WoWDB-backed requirements in the tracker. They remain counted as missing static destinations.

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
| alliance-desolace | 146 | 140 | 6 |
| alliance-dustwallow | 100 | 99 | 1 |
| alliance-feralas | 125 | 123 | 2 |
| alliance-tanaris | 175 | 165 | 10 |
| alliance-azshara | 68 | 68 | 0 |
| alliance-ungoro | 131 | 131 | 0 |
| alliance-felwood | 197 | 195 | 2 |
| alliance-winterspring | 121 | 118 | 3 |
| alliance-silithus | 270 | 263 | 7 |
| alliance-hyjal | 2 | 1 | 1 |
| alliance-barrens | 141 | 140 | 1 |
| alliance-moonglade | 70 | 70 | 0 |
| horde-durotar | 187 | 186 | 1 |
| horde-mulgore | 194 | 193 | 1 |
| horde-the-barrens | 265 | 264 | 1 |
| horde-stonetalon-mountains | 89 | 89 | 0 |
| horde-ashenvale | 64 | 63 | 1 |
| horde-thousand-needles | 149 | 148 | 1 |
| horde-desolace | 158 | 151 | 7 |
| horde-dustwallow-marsh | 71 | 70 | 1 |
| horde-feralas | 94 | 94 | 0 |
| horde-tanaris | 148 | 137 | 11 |
| horde-azshara | 60 | 60 | 0 |
| horde-un-goro-crater | 99 | 99 | 0 |
| horde-felwood | 72 | 71 | 1 |
| horde-winterspring | 71 | 68 | 3 |
| horde-silithus | 112 | 110 | 2 |
| horde-mount-hyjal | 2 | 0 | 2 |
| horde-shen-dralas | 32 | 20 | 12 |
| horde-tirisfal-glades | 212 | 212 | 0 |
| horde-silverpine-forest | 120 | 120 | 0 |
| alliance-loch-modan | 123 | 122 | 1 |
| alliance-westfall | 117 | 117 | 0 |
| alliance-redridge-mountains | 111 | 110 | 1 |
| alliance-duskwood | 183 | 182 | 1 |
| alliance-wetlands | 180 | 180 | 0 |
| alliance-hillsbrad-foothills | 33 | 33 | 0 |
| horde-hillsbrad-foothills | 87 | 87 | 0 |
| alliance-alterac-mountains | 43 | 42 | 1 |
| horde-alterac-mountains | 34 | 34 | 0 |
| alliance-arathi-highlands | 99 | 99 | 0 |
| horde-arathi-highlands | 122 | 119 | 3 |
| alliance-stranglethorn-vale | 270 | 265 | 5 |
| horde-stranglethorn-vale | 262 | 257 | 5 |
| alliance-badlands | 99 | 98 | 1 |
| horde-badlands | 85 | 83 | 2 |
| alliance-swamp-of-sorrows | 48 | 47 | 1 |
| horde-swamp-of-sorrows | 75 | 73 | 2 |
| alliance-riverglades | 300 | 276 | 24 |
| horde-riverglades | 254 | 235 | 19 |
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
| alliance-eastern-plaguelands | 87 | 86 | 1 |
| horde-eastern-plaguelands | 109 | 108 | 1 |

## Unresolved static destinations

| Guide | Quest ID | Phase | Step | Known requirements |
| --- | ---: | --- | --- | --- |
| alliance-alterac-mountains | 96800 | objective | Work on: Past Due |  |
| alliance-badlands | 716 | objective | Work on: Stone Is Better than Cloth |  |
| alliance-barrens | 1796 | objective | Work on: Components for the Enchanted Gold Bloodrobe (1/5) | WoWDB (craft): Craft or buy Robes of Arcana for Menara Voidrender. Check your quest log for current requirements and quantities. |
| alliance-desolace | 1371 | objective | Work on: Gizmo for Warug | WoWDB (craft): Obtain an Advanced Target Dummy and keep your Magram reputation high enough to speak with Warug. Check your quest log for current requirements and quantities. |
| alliance-desolace | 92754 | turnin | A New Need for Shadow Protection |  |
| alliance-desolace | 93196 | accept | Khan Jehn (Magram) |  |
| alliance-desolace | 93196 | objective | Work on: Khan Jehn (Magram) |  |
| alliance-desolace | 93196 | turnin | Khan Jehn (Magram) |  |
| alliance-desolace | 93678 | objective | Work on: Abridged Notes on Draenethyst |  |
| alliance-duskwood | 98447 | turnin | Complete: The Valor Family (2/2) |  |
| alliance-dustwallow | 1203 | objective | Work on: Jarl Needs a Blade |  |
| alliance-eastern-plaguelands | 5149 | objective | Work on: Pamela's Doll |  |
| alliance-felwood | 4107 | objective | Work on: Salve via Disenchanting (2/2) |  |
| alliance-felwood | 5886 | objective | Work on: Salve via Disenchanting (1/2) |  |
| alliance-feralas | 3791 | objective | Work on: The Mystery of Morrowgrain | WoWDB (supplies): Collect 10 Morrowgrain for Quintis Jonespyre. The quest supplies an Evergreen Pouch. Check your quest log for current requirements and quantities. |
| alliance-feralas | 3792 | objective | Work on: Morrowgrain to Feathermoon Stronghold |  |
| alliance-hyjal | 92521 | turnin | The Demon Tower |  |
| alliance-loch-modan | 86776 | objective | Work on: Ingredients for the Forge |  |
| alliance-redridge-mountains | 95816 | objective | Work on: Sign Me Up! |  |
| alliance-riverglades | 94615 | objective | Work on: Foal Play |  |
| alliance-riverglades | 94879 | objective | Work on: Scraps of Knowledge |  |
| alliance-riverglades | 94923 | objective | Work on: Hats Off |  |
| alliance-riverglades | 94926 | accept | Pick up: Drop the Hammer |  |
| alliance-riverglades | 94926 | objective | Work on: Drop the Hammer |  |
| alliance-riverglades | 94931 | objective | Work on: Stolen Saws |  |
| alliance-riverglades | 95059 | objective | Work on: Frazzlespark's Crate [A] |  |
| alliance-riverglades | 95066 | objective | Work on: The Rog'mar Situation |  |
| alliance-riverglades | 95123 | objective | Work on: A Blast Ye Scurvy Dogs! |  |
| alliance-riverglades | 95147 | objective | Work on: The Lost Scout |  |
| alliance-riverglades | 95148 | objective | Work on: Southern Watch Gnoll Report |  |
| alliance-riverglades | 95156 | objective | Work on: Stuff 'Em and Stick 'Em |  |
| alliance-riverglades | 95184 | objective | Work on: The Sharpest of Blades |  |
| alliance-riverglades | 95219 | objective | Work on: From Port to Port |  |
| alliance-riverglades | 95426 | objective | Work on: Rog'mar Supplies |  |
| alliance-riverglades | 95561 | objective | Work on: Apple of My Eye |  |
| alliance-riverglades | 95934 | objective | Work on: Proof of Profit |  |
| alliance-riverglades | 95935 | accept | Pick up: Hail the Dragonslayer [A] |  |
| alliance-riverglades | 95943 | objective | Work on: Foreman's Plight |  |
| alliance-riverglades | 95975 | objective | Work on: Her World |  |
| alliance-riverglades | 95982 | objective | Work on: Not My Circus |  |
| alliance-riverglades | 96009 | objective | Work on: High Stakes |  |
| alliance-riverglades | 96063 | objective | Work on: Gaseous Gold |  |
| alliance-riverglades | 96084 | objective | Work on: Something's in the Water |  |
| alliance-silithus | 8317 | objective | Work on: Kitchen Assistance | WoWDB (craft): Prepare 10 Smoked Desert Dumplings for Calandrath. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8496 | objective | Work on: Bandages for the Field (A) | WoWDB (craft): Prepare 30 each of Heavy Runecloth Bandage, Heavy Mageweave Bandage and Heavy Silk Bandage. Keep Logistics Task Briefing X for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8540 | objective | Work on: Boots for the Guard (A) | WoWDB (craft): Prepare 3 Ornate Mithril Boots. Keep Logistics Task Briefing II for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8541 | objective | Work on: Grinding Stones for the Guard (A) | WoWDB (craft): Prepare 10 each of Dense Grinding Stone, Solid Grinding Stone and Heavy Grinding Stone. Keep Logistics Task Briefing III for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8781 | objective | Work on: Arms for the Field (A) | WoWDB (craft): Prepare 2 Moonsteel Broadswords for Janela Stouthammer. Keep Logistics Task Briefing VI for the delivery. Check your quest log for current requirements and quantities. |
| alliance-silithus | 8856 | accept | Desert Survival Kits (A) |  |
| alliance-silithus | 9023 | objective | Work on: The Perfect Poison | WoWDB (instance): Loot the venom sacs from High Priest Venoxis in Zul'Gurub and Kurinnaxx in the Ruins of Ahn'Qiraj. Check your quest log for current requirements and quantities. |
| alliance-stranglethorn-vale | 1036 | objective | Work on: Avast Ye, Scallywag | WoWDB (reputation): Meet the reputation requirement in your quest log, then speak with Fleet Master Firallon aboard the Crimson Veil off Stranglethorn. Check your quest log for current requirements and quantities. |
| alliance-stranglethorn-vale | 95384 | accept | Pick up: Partial Mystical Notes |  |
| alliance-stranglethorn-vale | 95786 | objective | Work on: An Acquaintance in Southshore |  |
| alliance-stranglethorn-vale | 97328 | objective | Work on: Anything of Value |  |
| alliance-stranglethorn-vale | 97420 | accept | Pick up: Reduce, Reuse, Reconcile |  |
| alliance-swamp-of-sorrows | 93176 | objective | Work on: My Little Friends |  |
| alliance-tanaris | 2771 | objective | Work on: A Good Head On Your Shoulders | WoWDB (craft): Prepare 2 Mithril Coifs and 1 Ornate Mithril Shoulder for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 2772 | objective | Work on: The World At Your Feet | WoWDB (craft): Prepare 2 Heavy Mithril Boots and 1 Ornate Mithril Pants for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 2773 | objective | Work on: The Mithril Kid | WoWDB (craft): Prepare 2 Heavy Mithril Breastplates and 1 Ornate Mithril Gloves for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7653 | objective | Work on: Imperial Plate Belt |  |
| alliance-tanaris | 7654 | objective | Work on: Imperial Plate Boots | WoWDB (supplies): Collect 20 Thorium Bars for the Imperial Plate Boots plans. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7655 | objective | Work on: Imperial Plate Bracer |  |
| alliance-tanaris | 7656 | objective | Work on: Imperial Plate Chest | WoWDB (supplies): Collect 30 Thorium Bars for the Imperial Plate Chest plans. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7657 | objective | Work on: Imperial Plate Helm | WoWDB (supplies): Collect 25 Thorium Bars for the Imperial Plate Helm plans. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7658 | objective | Work on: Imperial Plate Leggings | WoWDB (supplies): Collect 30 Thorium Bars for the Imperial Plate Leggings plans. Check your quest log for current requirements and quantities. |
| alliance-tanaris | 7659 | objective | Work on: Imperial Plate Shoulders |  |
| alliance-thousand-needles | 1192 | objective | Work on: Indurium Ore | WoWDB (loot): Collect 4 Indurium Ore. Check the quest log for the current source and remaining quantity. Check your quest log for current requirements and quantities. |
| alliance-winterspring | 5305 | objective | Work on: Sweet Serenity |  |
| alliance-winterspring | 5306 | objective | Work on: Snakestone of the Shadow Huntress | WoWDB (instance): Defeat Shadow Hunter Vosh'gajin in Blackrock Spire and loot Vosh'gajin's Snakestone. Check your quest log for current requirements and quantities. |
| alliance-winterspring | 5307 | objective | Work on: Corruption |  |
| horde-arathi-highlands | 92519 | objective | Work on: Ward Restocking |  |
| horde-arathi-highlands | 92707 | accept | Pick up: The Giant in the Den |  |
| horde-arathi-highlands | 92707 | turnin | Complete: The Giant in the Den |  |
| horde-ashenvale | 6504 | objective | Work on: The Lost Pages | WoWDB (combine): Collect the 12 Shredder Operating Manual pages and combine them into Chapters 1, 2 and 3. Check your quest log for current requirements and quantities. |
| horde-badlands | 716 | objective | Work on: Stone Is Better than Cloth |  |
| horde-badlands | 9439 | turnin | Complete: Unclaimed Baggage |  |
| horde-desolace | 1371 | objective | Work on: Gizmo for Warug | WoWDB (craft): Obtain an Advanced Target Dummy and keep your Magram reputation high enough to speak with Warug. Check your quest log for current requirements and quantities. |
| horde-desolace | 92754 | turnin | Complete: A New Need for Shadow Protection |  |
| horde-desolace | 93045 | objective | Work on: Test Your Theory |  |
| horde-desolace | 93196 | accept | Pick up: Khan Jehn (Magram) |  |
| horde-desolace | 93196 | objective | Work on: Khan Jehn (Magram) |  |
| horde-desolace | 93196 | turnin | Complete: Khan Jehn (Magram) |  |
| horde-desolace | 93678 | objective | Work on: Abridged Notes on Draenethyst |  |
| horde-durotar | 96873 | objective | Work on: A Pain in the Neck |  |
| horde-dustwallow-marsh | 1203 | objective | Work on: Jarl Needs a Blade |  |
| horde-eastern-plaguelands | 5149 | objective | Work on: Pamela's Doll |  |
| horde-felwood | 5891 | objective | Work on: Salve via Disenchanting (1/2) |  |
| horde-mount-hyjal | 92521 | accept | Pick up: The Demon Tower |  |
| horde-mount-hyjal | 92521 | turnin | Complete: The Demon Tower |  |
| horde-mulgore | 96294 | objective | Work on: A Darker Truth |  |
| horde-riverglades | 93787 | objective | Work on: Food for the Taking |  |
| horde-riverglades | 93971 | accept | Pick up: Farholde Scouting Report |  |
| horde-riverglades | 93971 | objective | Work on: Farholde Scouting Report |  |
| horde-riverglades | 93971 | turnin | Complete: Farholde Scouting Report |  |
| horde-riverglades | 94480 | objective | Work on: A Gift From Our Enemies |  |
| horde-riverglades | 94734 | objective | Work on: A Boar's Delight |  |
| horde-riverglades | 94737 | objective | Work on: A Treat for a Friend |  |
| horde-riverglades | 95062 | objective | Work on: Frazzlespark's Crate [H] |  |
| horde-riverglades | 95123 | objective | Work on: A Blast Ye Scurvy Dogs! |  |
| horde-riverglades | 95183 | objective | Work on: Step One: Rock |  |
| horde-riverglades | 95278 | objective | Work on: It Is Time, Brother... |  |
| horde-riverglades | 95602 | objective | Work on: Sickening Lights |  |
| horde-riverglades | 95934 | objective | Work on: Proof of Profit |  |
| horde-riverglades | 95936 | accept | Pick up: Hail the Dragonslayer [H] |  |
| horde-riverglades | 95951 | objective | Work on: Fetch 'n' Fletch |  |
| horde-riverglades | 95982 | objective | Work on: Not My Circus |  |
| horde-riverglades | 96026 | objective | Work on: Step Two: More Rock |  |
| horde-riverglades | 96063 | objective | Work on: Gaseous Gold |  |
| horde-riverglades | 97884 | objective | Work on: Armory of Sunnyglade |  |
| horde-shen-dralas | 93041 | objective | Work on: Facing the Truth |  |
| horde-shen-dralas | 93058 | objective | Work on: Saving Our Own |  |
| horde-shen-dralas | 93062 | accept | Pick up: Bone Burying |  |
| horde-shen-dralas | 93072 | accept | Pick up: Long-Term Solutions |  |
| horde-shen-dralas | 93072 | turnin | Complete: Long-Term Solutions |  |
| horde-shen-dralas | 93125 | accept | Pick up: Going Home |  |
| horde-shen-dralas | 93125 | turnin | Complete: Going Home |  |
| horde-shen-dralas | 93129 | accept | Pick up: Threat of Starvation |  |
| horde-shen-dralas | 93129 | objective | Work on: Threat of Starvation |  |
| horde-shen-dralas | 93129 | turnin | Complete: Threat of Starvation |  |
| horde-shen-dralas | 93188 | accept | Pick up: Return to Orgrul |  |
| horde-shen-dralas | 93188 | turnin | Complete: Return to Orgrul |  |
| horde-silithus | 8317 | objective | Work on: Kitchen Assistance | WoWDB (craft): Prepare 10 Smoked Desert Dumplings for Calandrath. Check your quest log for current requirements and quantities. |
| horde-silithus | 9023 | objective | Work on: The Perfect Poison | WoWDB (instance): Loot the venom sacs from High Priest Venoxis in Zul'Gurub and Kurinnaxx in the Ruins of Ahn'Qiraj. Check your quest log for current requirements and quantities. |
| horde-stranglethorn-vale | 1036 | objective | Work on: Avast Ye, Scallywag | WoWDB (reputation): Meet the reputation requirement in your quest log, then speak with Fleet Master Firallon aboard the Crimson Veil off Stranglethorn. Check your quest log for current requirements and quantities. |
| horde-stranglethorn-vale | 3642 | objective | Work on: The Pledge of Secrecy |  |
| horde-stranglethorn-vale | 3643 | objective | Work on: Show Your Work |  |
| horde-stranglethorn-vale | 95384 | accept | Pick up: Partial Mystical Notes |  |
| horde-stranglethorn-vale | 97328 | objective | Work on: Anything of Value |  |
| horde-swamp-of-sorrows | 93176 | objective | Work on: My Little Friends |  |
| horde-swamp-of-sorrows | 93663 | objective | Work on: Lost in Transit |  |
| horde-tanaris | 2771 | objective | Work on: A Good Head On Your Shoulders | WoWDB (craft): Prepare 2 Mithril Coifs and 1 Ornate Mithril Shoulder for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| horde-tanaris | 2772 | objective | Work on: The World At Your Feet | WoWDB (craft): Prepare 2 Heavy Mithril Boots and 1 Ornate Mithril Pants for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| horde-tanaris | 2773 | objective | Work on: The Mithril Kid | WoWDB (craft): Prepare 2 Heavy Mithril Breastplates and 1 Ornate Mithril Gloves for Trenton Lighthammer. Check your quest log for current requirements and quantities. |
| horde-tanaris | 3639 | objective | Work on: Show Your Work | WoWDB (craft): Prepare 20 Big Iron Bombs, 20 Solid Dynamite and 5 Explosive Sheep for Nixx Sprocketspring. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7653 | objective | Work on: Imperial Plate Belt |  |
| horde-tanaris | 7654 | objective | Work on: Imperial Plate Boots | WoWDB (supplies): Collect 20 Thorium Bars for the Imperial Plate Boots plans. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7655 | objective | Work on: Imperial Plate Bracer |  |
| horde-tanaris | 7656 | objective | Work on: Imperial Plate Chest | WoWDB (supplies): Collect 30 Thorium Bars for the Imperial Plate Chest plans. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7657 | objective | Work on: Imperial Plate Helm | WoWDB (supplies): Collect 25 Thorium Bars for the Imperial Plate Helm plans. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7658 | objective | Work on: Imperial Plate Leggings | WoWDB (supplies): Collect 30 Thorium Bars for the Imperial Plate Leggings plans. Check your quest log for current requirements and quantities. |
| horde-tanaris | 7659 | objective | Work on: Imperial Plate Shoulders |  |
| horde-the-barrens | 95819 | objective | Work on: Sign Me Up! |  |
| horde-thousand-needles | 98069 | objective | Work on: Stolen Freewind Supplies |  |
| horde-winterspring | 5305 | objective | Work on: Sweet Serenity |  |
| horde-winterspring | 5306 | objective | Work on: Snakestone of the Shadow Huntress | WoWDB (instance): Defeat Shadow Hunter Vosh'gajin in Blackrock Spire and loot Vosh'gajin's Snakestone. Check your quest log for current requirements and quantities. |
| horde-winterspring | 5307 | objective | Work on: Corruption |  |
