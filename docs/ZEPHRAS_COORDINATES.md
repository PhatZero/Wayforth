# Zephras Isle coordinate catalog (WayForth 0.3.3)

This is the source-of-truth audit for the **offline** WayForth Skyborne route, not a promise that every quest in the island's full public quest database has been authored as a guide step. All *authored* Alliance/Horde guide steps are validated by Lua regression tests for at least one map coordinate. The island uses **UI map ID 2521**; map coordinates are percentages (0–100). Stable pre-0.3.3 step IDs and SavedVariables are preserved.

## Sourcing, accuracy and limitations

- **Wowhead: Zephras Isle Zone Overview**, last updated Oct 22, 2026, directly provides all 18 class trainer coordinates and both Zephras outbound skyboat docks: https://www.wowhead.com/forever/guide/zephras-isle-zone-overview
- **Wowhead: The Missing Scholar 92850** confirms the final task, NPC and exact cave *entrance* from a comment (51.44, 68.99). Its start/finish pins are map widgets loaded dynamically rather than displayed as plain text: https://www.wowhead.com/forever/quest=92850/the-missing-scholar
- **Wowhead: The Missing Scholar 92849** contains the reported bedroll coordinate 52.05, 69.37 and confirms this is the second quest in the linked storyline: https://www.wowhead.com/forever/quest=92849/the-missing-scholar
- Companion independent quest data for quest givers, completion NPCs and coordinates, cross-checked against Wowhead quest IDs and texts: https://questing.wiki/wow-forever/quests/zones/zephras-isle/ ; https://senseos.gg/guides/wow-forever/zephras-isle/
- Where reliable documentation identifies only a zone or creature's approximate spawn region, we use a labeled **approximate objective-area center**, NOT a promised exact enemy position. Use the in-game quest POI first for active objective steps. Approximate centers in the catalog include #92463, #92470, #92473, #92517, #92597, #92598, #92849, #92947, #93746.
- The Missing Scholar (Alliance) is **three sequential quests with distinct IDs 92727, 92849, 92850**. 92849 includes rescue/carry-to-bedroll behavior; 92850 is the subsequent matriarch hunt. The 92850 pickup is near **52.1, 69.4**, the entrance is **51.44, 68.99**, the matriarch is near **51.9, 65.6**, and turn-in is near **66.2, 79.9**.
- **No HTTP calls or automated Wowhead scraping** occur in the addon. This source file contains curated published coordinates and is bundled with the ZIP. UI map ID must match the Forever client; test live player position/facing and arrow rotation before distribution.

## Quest waypoint catalog

Each role is independent. Pickup, objective and turn-in must not share a location merely because they share a quest ID.

| Quest ID | Map location by quest phase (x, y) |
|---|---|
| 92460 | pickup 42.8, 23.4 · turnin 42.1, 23.5 |
| 92461 | pickup 42.1, 23.5 · objective 44.9, 26.3 · turnin 42.1, 23.5 |
| 92462 | pickup 43.4, 24.8 · objective 45.8, 27.2 · turnin 43.4, 24.8 |
| 92463 | pickup 43.4, 24.8 · objective 48.0, 29.0 |
| 92470 | pickup 42.8, 23.7 · objective 36.0, 26.0 |
| 92473 | pickup 42.4, 25.2 · objective 40.0, 28.0 |
| 92474 | pickup 43.7, 24.1 · turnin 42.1, 23.5 |
| 94414 | pickup 43.8, 24.1 |
| 92597 | pickup 43.3, 24.9 · objective 46.0, 18.0 · turnin 43.3, 24.8 |
| 92598 | pickup 42.6, 24.4 · objective 48.0, 21.0 |
| 93461 | turnin 45.6, 45.4 |
| 92514 | turnin 45.6, 45.4 |
| 96101 | pickup 41.6, 44.8 |
| 92596 | pickup 45.0, 46.4 · turnin 45.0, 46.4 |
| 92595 | pickup 43.5, 44.8 · turnin 43.5, 44.8 |
| 92517 | pickup 45.7, 45.5 · objective 51.0, 34.0 |
| 93036 | pickup 45.7, 45.5 · turnin 44.9, 45.5 |
| 93926 | pickup 45.7, 45.5 · turnin 42.3, 62.0 |
| 92679 | pickup 62.1, 73.2 · turnin 46.7, 82.0 |
| 93948 | pickup 45.7, 45.5 · turnin 66.2, 76.5 |
| 92699 | pickup 66.1, 76.7 · turnin 66.6, 79.9 |
| 92700 | pickup 66.1, 76.7 · turnin 59.1, 79.8 |
| 92727 | pickup 66.3, 79.8 · turnin 53.3, 72.1 |
| 92849 | pickup 53.3, 72.1 · objective 50.0, 66.0 · turnin 52.1, 69.4 |
| 92850 | pickup 52.1, 69.4 · entrance 51.44, 68.99 · objective 51.9, 65.6 · turnin 66.2, 79.9 |
| 93735 | pickup 59.1, 79.8 · turnin 59.1, 73.0 |
| 93737 | pickup 59.1, 73.0 |
| 93738 | pickup 59.1, 73.0 · turnin 59.1, 79.8 |
| 93746 | pickup 59.1, 79.8 · objective 60.0, 57.0 |
| 93320 | pickup 66.1, 76.7 · turnin 69.7, 67.1 |
| 92643 | pickup 66.2, 76.5 · turnin 56.0, 58.8 |
| 92644 | pickup 56.0, 58.8 · turnin 66.2, 76.5 |
| 94568 | pickup 66.2, 76.5 · turnin 66.2, 76.5 |
| 92947 | pickup 61.1, 70.9 · objective 62.0, 50.0 · turnin 63.8, 50.5 |
| 93958 | pickup 63.8, 50.5 · turnin 65.2, 50.4 |
| 94369 | pickup 66.6, 79.9 · turnin 66.2, 76.5 |
| 93836 | pickup 59.1, 79.8 · turnin 66.2, 76.5 |
| 93089 | pickup 66.2, 76.5 · turnin 66.6, 79.9 |
| 93090 | pickup 66.2, 76.5 · turnin 59.1, 79.8 |
| 94946 | pickup 66.6, 79.9 · departure 65.9, 83.5 |
| 95349 | pickup 59.1, 79.8 · departure 57.9, 80.9 |

## Class trainers from Wowhead

These are additional manual checkpoints in the guide, not quest ID pins. Only the current character class sees each row. Each trainer uses UI map 2521.

| Class | Thendal (starter) | Shen'dar (intermediate) | Valanaar (advanced) |
|---|---|---|---|
| Druid | 41.6, 23.4 | 45.2, 44.2 | 64.0, 75.0 |
| Hunter | 42.4, 23.6 | 45.2, 44.2 | 59.6, 72.6 |
| Mage | 41.6, 23.6 | 45.0, 45.8 | 65.8, 80.4 |
| Rogue | 43.6, 24.2 | 43.2, 43.2 | 59.8, 72.6 |
| Shaman | 42.8, 23.6 | 43.6, 44.8 | 58.2, 78.6 |
| Warrior | 43.6, 24.2 | 44.8, 45.2 | 59.8, 72.8 |

**Skyboat dock waypoints:** Dalaran 65.9, 83.5; Thunder Bluff 57.9, 80.9. The routes may be used by either faction, but these are the intended guide defaults.

## How the code uses it

1. `Data/ZephrasLocations.lua` is loaded before `Data/ZephrasIsle.lua` and `Core/Guides.lua`.
2. `Guides:GetSteps()` maps a step's `questId` and phase (`accept→pickup`, `objective`, `turnin`), optionally `locationRole=entrance`, to a map point. It resolves faction-only IDs separately and does not edit stable step IDs or SavedVariables.
3. The Navigator prefers the curated NPC point on accept/turn-in/manual steps, and live objective POIs when available; static source coordinates are the fallback for objectives.
4. The new `test_zephras_location_catalog.lua` checks all class/faction route combinations for missing coordinates, plus explicit Missing Scholar start, cave, objective and end pins.
5. Any new quests should be added as original editorial route steps with distinct phase IDs and evidence in this file, never as a generic multi-quest manual step without a target.

## Scope

- **41 quest IDs** have one or more curated phase coordinates in the bundled catalog.
- **18 class trainer locations**, the two Skyborne skyboat docks, and other directly-authored one-off guide points are also included.
- Every currently authored guide checkpoint must resolve to a location in its own zone, but this is **not** full coverage of every optional quest, changing NPC, multi-spawn mob or future zone. Any unverified point should be omitted, marked approximate, or use an active quest POI rather than guessed precisely.
