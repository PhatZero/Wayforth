# WayForth Forever profession guides (offline planner)

Target client: **WoW Forever 1.60.1.70938**. WayForth supports all 12 professions, and never silently swaps in Classic or Retail recipe data.

## How to use

Choose a profession in WayForth and open the **Guide Tracker**. Multiple open guide tabs can be switched using their titles, and each guide tab has an **X** to close it. Closing a tab does **not** delete quest checkpoints, profession skill progress, or observed successful crafting counts. The **+** button returns to guide selection. The tracker uses a larger default size and supports resizing.

The profession workspace has two full-width scrollable pages:

- **MATERIALS (preparation):** An item-icon checklist shows the **owned / required / missing** quantity of each material, a live progress bar, and a **collected / required** total. Inventory is read from bags plus accessible bank storage and repainted on inventory changes. Under the list, the tracker previews the **next three actionable crafting stages** with their observed craft totals.
- **CRAFTING PLAN:** A card for each remaining source-backed recipe shows the planned skill range, color, how many actual successful spellcasts were recorded, its acquisition method and, where applicable, the yellow reserve. A manual **REFRESH** control is available, and counts also update automatically. Past skill bands are omitted from the active work list rather than mislabeled as uncompleted crafts.

When source-verified Forever recipes can make a needed intermediate (for example, a cloth bolt) at the player's current skill, the preparation checklist expands that requirement into underlying raw reagents and displays a separate **PREPARE CRAFTED INTERMEDIATES** section. This is an **optional conversion path**. The player must know and have access to the indicated recipe; otherwise the intermediate itself must be obtained directly. The authoritative bill of materials is retained unchanged in the route engine. Converted totals use known recipe yields, consume available intermediate inventory first, and are recalculated as stock changes.

If a complete source-verified orange/yellow route to skill 300 is available, WayForth can show the entire remaining 1-to-300 crafting sequence and its corresponding shopping requirements before the crafting window is opened. When coverage stops, the UI clearly shows the verified segment and the next missing skill range; it does not imply coverage past that point. The live fallback only proposes the next currently orange/yellow recipe and requires the profession window to be open. Orange is preferred. Yellow uses **10% extra crafts, rounded up** in both the route and ingredient totals, but yellow skill-ups are not guaranteed. Green and gray recipes are never used to **claim skill gains**.

**Tracking contract:** The material checklist is automatic from inventory quantities, not hand-ticked. Craft counts come from successful player spellcast events for known recipe spell IDs, not inferred skill gains. Every recipe needs to be learned before crafting; vendor/drop/trainer availability remains subject to the live game client. Per-character progress is preserved across tab changes and reloads. On a client build where crafting spellcast events are unavailable, the tracker explicitly labels craft counts as unavailable instead of fabricating completion. A successful automated test is **not** the same as an in-game visual and event-flow QA pass.

Recipe acquisition instructions and known cooking/first-aid/fishing Expert and Artisan rank quests/books remain available. The planner does not invent trainer coordinates, auction prices or recipe drops. Gathering guides show candidate or player-observed zones with explicit source labels rather than invented node waypoints.

## Actual source coverage

Client-sourced color-band recipe catalogs were imported from **ForeverDB.net**; data credit remains in the tracker. Source snapshot and compiler: `scripts/fetch_foreverdb_professions.py`, `scripts/build_foreverdb_profession_lua.py`; full gap and count ledger: `data/forever/profession_coverage.json`.

| Profession | Imported verified recipes | 1-300 orange coverage | With yellow fallback |
| --- | ---: | --- |
| Alchemy | 99 | No missing data bands | Full color coverage |
| Blacksmithing | 231 | Gap: 20–29 | Full color coverage |
| Cooking | 86 | No missing data bands | Full color coverage |
| Enchanting | 125 | No missing data bands | Full color coverage |
| Engineering | 80 client-verified orange, 69 recovered yellow-only | Gap: 30–74 | Gap: 52–54 |
| First Aid | 3 client-verified orange, 8 recovered yellow-only | Gaps: 30–139 and 175–300 | Gaps: 45–49 and 75–79 |
| Leatherworking | 272 | No missing data bands | Full color coverage |
| Tailoring | 242 | No missing data bands | Full color coverage |
| Fishing | 18 Forever-observed zones | Zone observations, not full node routing | N/A |
| Herbalism | 7 Forever-observed zones | Zone observations, not full node routing | N/A |
| Mining | 6 Forever-observed zones | Zone observations, not full node routing | N/A |
| Skinning | 0 Forever-observed zones | Unverified candidate zones only | N/A |

**Important:** A gap means the source does not establish a verified orange path. Some real skills may have no confirmed orange or yellow recipe at certain ranks. Client-yellow-only records derived from Classic orange rows are imported strictly as yellow, never as guaranteed orange. Never fill a gap from Classic's inferred color transitions, use green/gray recipes, or assume that the 10% yellow buffer guarantees a skill point. Source records, player-observed zones, source discrepancy reviews, and in-game QA remain separate evidence levels.

## Before a public CurseForge release

`scripts/check_forever_release_readiness.py` blocks publishing until all eight crafting-profession datasets have verified orange/yellow coverage through 300 **and** a matching-build in-game QA approval and screenshot evidence are recorded. The action build ZIP is suitable as a preview; it is **not** an automatically approved public release. See `docs/V1_IN_GAME_QA.md` and issue #28.

This implementation does not claim that the game has been played through or that every available craft event signature/waypoint is proven correct. Those are explicit in-game acceptance tasks.
