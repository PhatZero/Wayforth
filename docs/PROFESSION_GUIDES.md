# WayForth Forever profession guides (offline planner)

Target client: **WoW Forever 1.60.1.70938**. WayForth supports all 12 professions, and never silently swaps in Classic or Retail recipe data.

## How to use

Select a profession guide. The tracker splits into two scrollable lists: **Step 1: Gather Materials** and **Step 2: Crafting Plan**. If the character's current skill and a complete source-verified orange route to skill 300 are available, WayForth displays **the entire remaining 1-to-300 recipe sequence** and a single net bill of materials before the profession crafting window is opened. All ingredients show **owned/required/missing**, including accessible bank inventory. The craft list uses **actual observed successful player spellcasts**, never changes in skill as a proxy. Profession progress persists per character across reloads and guide switching.

When a client-verified recipe range stops before 300, WayForth displays the **verified portion only**, including its exact ingredient totals and the precise next unverified skill gap. At the gap, opening the profession crafting window allows a **single live-orange-recipe** fallback. It does not label this fallback as a guaranteed full-range route. Yellow, green, and gray are never used for guaranteed skill planning.

Recipe acquisition instructions and the known cooking/first-aid/fishing Expert and Artisan rank quests/books are displayed. The character must train and learn required ranks/recipes. The planner doesn't fabricate trainer coordinates, quote auction prices, or promise a recipe drop. Gathering guides show a small shortlist of zone candidates, marking zones observed by Forever players separately from Classic-derived candidates, without inventing node waypoints.

## Actual source coverage

Client-verified orange recipe catalogs were imported from **ForeverDB.net**; data credit remains in the tracker. Source snapshot and compiler: `scripts/fetch_foreverdb_professions.py`, `scripts/build_foreverdb_profession_lua.py`; full gap and count ledger: `data/forever/profession_coverage.json`.

| Profession | Imported verified recipes | 1-300 orange coverage |
| --- | ---: | --- |
| Alchemy | 99 | No missing data bands |
| Blacksmithing | 231 | Gap: 20–29 |
| Cooking | 86 | No missing data bands |
| Enchanting | 125 | No missing data bands |
| Engineering | 80 | Gap: 30–74 |
| First Aid | 3 | Gaps: 30–139 and 175–300 |
| Leatherworking | 272 | No missing data bands |
| Tailoring | 242 | No missing data bands |
| Fishing | 18 Forever-observed zones | Zone observations, not full node routing |
| Herbalism | 7 Forever-observed zones | Zone observations, not full node routing |
| Mining | 6 Forever-observed zones | Zone observations, not full node routing |
| Skinning | 0 Forever-observed zones | Unverified candidate zones only |

**Important:** A gap means the source does not establish a verified orange path. Some real skills may have no guaranteed orange recipe at certain ranks at all. Never fill a gap from Classic's inferred color transitions or assume yellow succeeds. Source records, player-observed zones, source discrepancy reviews, and in-game QA remain separate evidence levels.

## Before a public CurseForge release

`scripts/check_forever_release_readiness.py` blocks publishing until every eight crafting-profession dataset has verified contiguous orange coverage to 300 **and** a matching-build in-game QA approval and screenshot evidence are recorded. The action build ZIP is suitable as a preview; it is **not** an automatically approved public release. See `docs/V1_IN_GAME_QA.md` and issue #28.

This implementation does not claim that the game has been played through or that every available craft event signature/waypoint is proven correct. Those are explicit in-game acceptance tasks.
