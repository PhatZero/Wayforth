# WayForth Alliance Kalimdor — v0.3.4 quest data and QA

## Scope
The original WayForth addon includes 16 Kalimdor guides loaded by `Data/KalimdorAlliance.lua` after `Data/ForeverQuestCatalog.lua`, before `Core/Guides.lua`. This expands the existing Alliance Teldrassil starting route, does not add a second addon, and retains the existing minimap, tracker, arrow, and SavedVariables.

The guide data is extracted and adapted from **public, source-listed quest metadata** in ATTWoWAddon/AllTheThings, snapshot `68c9764b54bc6619bfdd924e7bd9846ed583eef1`, under `.contrib/.db/forever/zones/kalimdor/`.

**Audit honesty:** 798 entries are quest-ID candidates (all faction-unrestricted/neutral or explicitly Alliance-tagged, excluding explicitly Horde-tagged). This is not proof that every record is available to every Alliance race/class or even present in a particular Forever build. We have not verified all quest IDs, object locations, turn-in NPCs, prerequisites, item objectives, or XP in-game.

## Zone catalog
| Zone | Source quest candidates |
|---|---:|
| Darkshore | 78 |
| Stonetalon Mountains | 27 |
| Ashenvale | 48 |
| Thousand Needles | 36 |
| Desolace | 55 |
| Dustwallow Marsh | 42 |
| Feralas | 50 |
| Tanaris | 64 |
| Azshara | 26 |
| Un'Goro Crater | 48 |
| Felwood | 68 |
| Winterspring | 47 |
| Silithus | 98 |
| Mount Hyjal | 1 |
| The Barrens | 70 |
| Moonglade | 40 |
| **Total** | **798** |

Each candidate has a distinct accept checkpoint (quest ID and possible source pickup coordinate) and a completion checkpoint (same ID; do not reuse pickup as turn-in). This yields 1,596 Kalimdor guide checkpoints before filtering class-specific entries. The source dataset has class flags and one known source prerequisite where specified.

Kalimdor quests combine with **439 existing starter-zone source-ID records** in the Diagnostics audit, for **1,237 source records**. A source record may exist in more than one zone and is not equivalent to a unique active quest or validated quest.

## UX behavior
- In **Guides**, the launcher offers six cards per page and cycles **Near My Level → Kalimdor → All Zones**. The player may select any Alliance zone independent of starting race.
- **Start Guide** estimates XP suitability from minimum quest-level metadata. This is NOT the server's precise XP calculation. It avoids obviously low-level quests at high levels and respects known prerequisites. **From Beginning** offers story-mode; **Resume Saved** returns to each region's separate saved position.
- Optional The Barrens (neutral/Alliance content) and Moonglade (largely class-specific) do not clutter near-level suggestions but remain accessible in Kalimdor / All views.
- While the player is outside a selected Kalimdor zone, the tracker provides a travel hint. Navigation does not interpret one region's coordinates in another region's map space.
- The source pickup coordinates are used **only** for accept steps while inside the correct zone. Turn-in and objective markers come from the live quest POI if available, otherwise the arrow stays hidden. Transport hints are not a tested cross-continent navigation algorithm.

## Remaining authoring and validation work
- [ ] Visit all 16 regions on a Forever Alliance character where eligible.
- [ ] In **Diagnostics → Validate Quest IDs → Copy ID Report**, export the live-client candidate title results and compare mismatches/unresolved IDs.
- [ ] Verify class restrictions, historical/optional quests, quest-giver NPCs and chain prerequisites, and remove wrong-faction or unobtainable records.
- [ ] Verify pickup coordinates, actual objective coordinates, cave entrances, distinct turn-in NPCs and map UI IDs. Do not confuse source metadata with validated world waypoints.
- [ ] Test smart switches (e.g. Skyborne → Darkshore → Ashenvale → Feralas → Tanaris) at levels 12, 25, 42 and 55; restore saved progress per region.
- [ ] For near-level mode, compare suggested quests with actual experience-color and quest level in the Forever client. Tune filtering based on real XP results.
- [ ] Validate travel legs to each region, especially shared-faction boats, contested neutral hubs, Moonglade class travel and endgame Mount Hyjal access.
- [ ] Convert the catalog-backed routes into **fully curated speed-friendly zone walkthroughs** after client validation. At present there is no claim of tested optimal quest order, all objective waypoints, or complete optional content (Shen'dralas in particular is not in this source catalog).
