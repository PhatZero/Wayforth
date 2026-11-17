# Forever dungeon quest coverage ledger

**Issue #65 · Partial implementation only · 17 November 2026**

The Forever group-finder and public dungeon overview enumerate 35 dungeon entries across about 28 base instances (some instances have separate wings). See [Icy Veins Forever dungeon list](https://www.icy-veins.com/wow-forever/dungeons-overview/). This is a **planning inventory**, not proof of quest lists or usable gameplay.

| # | Dungeon entry | WayForth quest coverage |
| ---: | --- | --- |
| 1 | Ragefire Chasm | Unverified: no in-addon quest manifest yet |
| 2 | Hall of Thanes | Partial: 4 observed Forever quests; eligible/pickup QA pending |
| 3 | Ruins of Lordaeron | Unverified: no in-addon quest manifest yet |
| 4 | Wailing Caverns | Unverified: no in-addon quest manifest yet |
| 5 | Deadmines | Unverified: no in-addon quest manifest yet |
| 6 | Shadowfang Keep | Unverified: no in-addon quest manifest yet |
| 7 | Blackfathom Deeps | Unverified: no in-addon quest manifest yet |
| 8 | Stormwind Stockades | Unverified: no in-addon quest manifest yet |
| 9 | Excavation Site: Wetlands | Unverified: no in-addon quest manifest yet |
| 10 | City of Dalaran | Unverified: no in-addon quest manifest yet |
| 11 | Gnomeregan | Unverified: no in-addon quest manifest yet |
| 12 | Razorfen Kraul | Unverified: no in-addon quest manifest yet |
| 13 | Scarlet Monastery - Graveyard | Unverified: no in-addon quest manifest yet |
| 14 | Scarlet Monastery - Library | Unverified: no in-addon quest manifest yet |
| 15 | The Drowned City | Unverified: no in-addon quest manifest yet |
| 16 | Scarlet Monastery - Armory | Unverified: no in-addon quest manifest yet |
| 17 | Razorfen Downs | Unverified: no in-addon quest manifest yet |
| 18 | Scarlet Monastery - Cathedral | Unverified: no in-addon quest manifest yet |
| 19 | Krol'dok Stronghold | Unverified: no in-addon quest manifest yet |
| 20 | Uldaman | Unverified: no in-addon quest manifest yet |
| 21 | Zul'Farrak | Unverified: no in-addon quest manifest yet |
| 22 | Maraudon | Unverified: no in-addon quest manifest yet |
| 23 | Alcaz Island Prison | Unverified: no in-addon quest manifest yet |
| 24 | Sunken Temple | Unverified: no in-addon quest manifest yet |
| 25 | Blackrock Depths | Unverified: no in-addon quest manifest yet |
| 26 | Dire Maul (East) | Unverified: no in-addon quest manifest yet |
| 27 | Blackmaw Hold | Unverified: no in-addon quest manifest yet |
| 28 | Lower Blackrock Spire | Unverified: no in-addon quest manifest yet |
| 29 | Dire Maul (North) | Unverified: no in-addon quest manifest yet |
| 30 | Dire Maul (West) | Unverified: no in-addon quest manifest yet |
| 31 | Scholomance | Unverified: no in-addon quest manifest yet |
| 32 | Shaper's Terrace | Unverified: no in-addon quest manifest yet |
| 33 | Stratholme (Main Gate) | Unverified: no in-addon quest manifest yet |
| 34 | Stratholme (Service Gate) | Unverified: no in-addon quest manifest yet |
| 35 | Upper Blackrock Spire | Unverified: no in-addon quest manifest yet |

## Implemented first slice: Hall of Thanes

Four dungeon-associated quests were **seen by Forever players** in the source database, with distinct pre-run and post-run phases: [#96393](https://foreverdb.net/quest/96393-old-ironforge-incursion), [#96394](https://foreverdb.net/quest/96394-the-restless-dead), [#96403](https://foreverdb.net/quest/96403-important-heirlooms), and [#96395](https://foreverdb.net/quest/96395-an-ancient-grudge). Source: [ForeverDB Hall of Thanes](https://foreverdb.net/dungeon/3065-the-hall-of-thanes), client 1.60.1.70938. Observed NPC pickup and turn-in coordinates are kept distinct.

- The first three quests have Forever-observed external pickups; An Ancient Grudge has **no recorded giver or pickup location**, so no arrow is invented.
- The tracker uses the existing active-quest, objective, turn-in, skip, tab and saved-progress mechanisms. Dungeon checklist counts use actual log/flag evidence only; an absent quest remains **Unknown**, not Available.
- Known faction-gated Alliance quests are excluded from a Horde character's actionable checklist.
- The entrance waypoint is source-observed, but in-instance coordinates and boss room directions are **not confirmed**. Do not use invented pins to replace room-level walkthrough QA.
- The Hall manifest is explicitly **Partial** and has **no completed in-game playthrough QA**. Four observed quests are not a certification that every optional, faction or chain variant has been found.

## Outstanding gates before #65 can close

1. Audit full quest associations for every dungeon, both factions, all external and in-instance pickups, chain prerequisites, exclusivity and turn-in locations. **Classic data is a discovery reference, not a Forever verification.**
2. Add source-provenanced quest manifests and actual entrance-to-exit walkthroughs, including quest-item objectives and pre-run pickup hubs, for all 35 entries.
3. Validate status counters and route transitions on a character with zero quests, a partially completed chain, a different faction and a returning character.
4. Perform two full Forever client playthrough QA runs per dungeon and collect screenshots; retain Partial/Unverified labels until proven.
5. Regression-test legacy leveling/profession data, guide tabs, manual switching, objective counters, protected actions and saved character progress.

This initial slice is not a full dungeon-guide release. It is intentionally source-conservative while the rest of the dungeon quests and inside-instance routes are audited.
