# Forever quest locations

The bundled catalog holds factual quest IDs, phase endpoints, entity names and map-specific coordinates. It is loaded after the guide definitions and before the guide engine. The game client makes no source downloads.

## Sources

- [QuestieDB](https://github.com/Questie/QuestieDB/tree/aca0da1c4a5ed0bc12997b9aaeef7b35af9ee26e) provides corrected Forever quest starter/finisher relationships, NPC/object spawns, item loot sources, vendors and quest rewards. The importer uses its Static Correction loader with authored corrections and traces enabled. Its Forever coordinate conversion and native AreaID-to-UiMapID table are applied as supplied. Dungeon compatibility floors and unresolved sentinel coordinates are excluded.
- [AllTheThings](https://github.com/ATTWoWAddon/AllTheThings/tree/d30715fb2657743d1b8801e5e3f26b96b7047160) provides additional quest pickup locations, objective points and NPC positions from its compiled `db/Camelot/Categories/Zones.lua`. Quest-giver positions can locate a known finisher NPC referenced by QuestieDB. The importer retains the finisher relationship from its own source.
- [Wowhead Forever](https://www.wowhead.com/forever) quest maps supply separate `start`, `end`, `requirement` and `sourcerequirement` points for records missing from the catalogs. Supplemental map facts were retrieved on November 10, 2026 and retained in `scripts/data/forever_quest_maps.json`. The stored set contains 323 reviewed quest records, including an additional 181 pages checked during the expanded source pass.
- [AHledger](https://ahledger.com/wow-forever/quests) contributes player-recorded giver and finisher names. Only explicit `Giver` and `Turned in to` fields are used. A name resolves to a static destination only when it identifies one NPC ID in the source database and that NPC has a recorded map location. The factual snapshots used by the import are retained in `scripts/data/forever_quest_reports.json`.

- [Wowhead Classic](https://www.wowhead.com/classic/quests) supplies fallback points for matching quest IDs and names. Where a Forever starter or finisher ID is recorded, the Classic endpoint must identify the same entity. Classic percentages are converted into the Forever map frame using the pinned conversion manifest. Mulgore, Eastern Plaguelands, Redridge Mountains and Stormwind have non-identity transforms. Classic fallback points are labeled `Wowhead Classic` and fill missing phase data. Explicit NPC/object IDs in the source maps can also locate that same entity for another quest with a known starter or finisher relationship. Snapshots are retained in `scripts/data/classic_quest_maps.json`. The pass checked 80 Classic quest pages, of which 74 exposed map data.
- [WoWDB](https://www.wowdb.com/) supplies named finishers and objective requirements for matching quest IDs and normalized titles. The comprehensive pass attempted every one of the 108 quest IDs that still had a missing static destination. The page reader retrieved 31 matching Live/PTR records. No matching record was retrieved for the other 77 IDs. This is a retrieval result, not a claim that those quests do not exist. The per-quest receipt, including attempted URLs and phases, is retained in `scripts/data/wowdb_remaining_review.json`. Direct downloads returned HTTP 403.

  Factual references are retained in `scripts/data/wowdb_quest_reports.json`. For example, [A Meeting with the Master (3381)](https://ptr.wowdb.com/quests/3381-a-meeting-with-the-master) identifies Sanath Lim-yo as its finisher. A name produces coordinates only when it identifies one NPC ID with a position in the Forever data. [The Pledge of Secrecy (3638)](https://www.wowdb.com/quests/3638-the-pledge-of-secrecy) explicitly documents an item-use interaction with Nixx Sprocketspring, allowing an objective destination at that NPC. Crafting and reputation requirements do not inherit a finisher waypoint. Reviewed item requirements must match the complete required-item ID set recorded for the Forever quest. WoWDB's Retail availability flag is retained as source metadata.

  [Desert Survival Kits (8856)](https://www.wowdb.com/quests/8856-desert-survival-kits) has conflicting food names in its summary and objective list. Only its consistent Calandrath finisher reference is imported. [Salve via Disenchanting (5891)](https://ptr.wowdb.com/quests/5891-salve-via-disenchanting) exposed no useful objective details and contributes a review receipt only.
- The expanded web search checked all 101 quest IDs still missing a static destination after the WoWDB pass. Every ID had an indexed source match. Search queries use clean quest names, with WayForth's `Work on:`, `Pick up:` and `Complete:` prefixes, chain numbering and faction annotations removed. Real punctuation in names such as `Step Two: More Rock` is preserved. The complete query/source receipt is in `scripts/data/quest_web_search_review.json`. Search matches establish that a record can be found; they do not by themselves establish a waypoint or live availability.

  The 82 reviewed factual additions in `scripts/data/web_quest_references.json` retain the source URL and provider. They include named finishers, explicit item-start links, objective requirements, component relationships and target names. For example, [Partial Mystical Notes](https://www.wowhead.com/forever/item=213127/partial-mystical-notes) explicitly starts its quest and drops from Skullsplitter Mystics. The matching NPC's recorded Forever position supplies the pickup waypoint. Scaldaron's head, Komuk's Warmaul and Goliath's Wristguards receive the same item-start treatment. Distinct quest IDs are retained for the two faction versions of Hail the Dragonslayer and the two different quests named The Valor Family.

  Explicit delivery objectives can point to their named recipient. Item-use, doll-component, capture and disenchanting requirements resolve through their documented source entities. Crafted goods retain instructions without a fabricated crafting destination. The Imperial Plate pages disagree across versions about Thorium Bar quantities, so their tracker instructions defer to the current quest log. The same caution applies to the conflicting vial counts on Gaseous Gold. Its short coordinate comment does not identify a target, so that coordinate is not imported.

  Two clear community-reported points are included with the separate `Wowhead Forever comment` source label: the [Foreman's Crate in its broken cart](https://www.wowhead.com/forever/quest=95943/foremans-plight) at Riverglades 51.9, 57.3, and the [Packaged Tonics toolbox](https://www.wowhead.com/forever/quest=92519/ward-restocking) at Arathi Highlands 60.3, 58.9. The latter page also has a less precise 62, 59 report. These points need live-client verification. Dungeon locations and encounters can have useful textual instructions while their floor coordinates remain unresolved.
- [Quest Checker](https://questchecker.com/) documents Retail support for its character lookup and supplies an in-game macro for Classic. It provides completion-state lookup. Guide Sync reads the current character's completed/active quest flags in the game client.

Quest eligibility uses the recorded quest race mask to determine faction restrictions. The correction filters opposite-faction quests from candidate zone guides. Entries explicitly listed in AllTheThings' `HiddenQuestTriggers` category are excluded from actionable guide steps. Numeric cursors and bookmarks on an excluded quest resume at the next surviving legacy step. The first import incorrectly applied NPC allegiance to some kill and loot targets. The corrected import filters quest-giver and vendor interactions by NPC allegiance. Kill and loot targets are eligible through their quest's faction.

An authored Zephras waypoint takes priority over supplemental records. Existing guide step IDs and per-character completion keys remain stable. Catalog quests with work to do receive an objective phase before the existing turn-in. The legacy cursor migration maps numeric saved positions to their original step IDs before the new phases are used.

A bundled objective location identifies a recorded target, loot source, vendor, reward source or event. It can be one of several destinations needed for the quest. Navigation prefers the live quest waypoint for an accepted objective. Some crafting, reputation and item requirements have no single fixed world location.

The WoWDB review also prompted use of the explicit entity markers in Forever's scripted-objective records. These resolve centaur enemies for the Desolace reputation quests and Silva Fil'naveth for the Druid flight back to Darnassus. The latter retains Forever's flight interaction before the separately recorded Darnassus finisher. Instance bosses with unresolved dungeon-floor coordinates retain named instructions without an invented outdoor point. The coverage audit keeps every phase without a valid static destination in its missing count, including phases with documented requirements. Its quest-name column uses the clean catalog name, with the phase in a separate column.

## Refresh

Check out the source repositories at the revisions above. The QuestieDB checkout contains the Lua 5.1 interpreter used by its exporter.

```bash
python3 scripts/import_forever_locations.py /path/to/QuestieDB \
  --att /path/to/AllTheThings --cache /path/to/wowhead-fact-cache \
  --reports scripts/data/forever_quest_reports.json
lua5.1 scripts/audit_quest_locations.lua docs/QUEST_LOCATION_COVERAGE.md
```

Use `--cached-only` to regenerate from the available supplemental snapshots. The importer writes the output after source loading finishes. The audit lists every unresolved static destination by guide, quest ID and phase. Source coverage requires live-client verification of accuracy and availability.

## Shared level and prerequisite enrichment

`ForeverQuestRequirements.lua` imports factual minimum levels and positive prerequisite IDs for 2,421 bundled quest IDs from [QuestieDB c6745129](https://github.com/Questie/QuestieDB/tree/c6745129ef9ea5e6dd1cdcd77224090f71bda880). This is separate from the location catalog's pinned revision. The source project's corrected Forever loader includes authored corrections. Field 4 is the minimum level, field 12 is an AND group, and field 13 contains alternative prerequisites (OR). Existing authored chain rules take priority. Zero/negative-ID rules and combined group/single definitions are not imported because their special semantics need separate review. Missing data is not proof of availability.

From the pinned QuestieDB checkout:

```sh
./tools/lua-binary/linux-x64/lua /path/to/Wayforth/scripts/export_forever_requirements.lua /path/to/Wayforth /path/to/Wayforth/clients/forever/guides/ForeverQuestRequirements.lua
```

The runtime accepts completion of any OR alternative. Recovery prefers an already-active alternative, then a pickup present in the guide. Quests already in the player's log remain authoritative. Source-backed requirements still need in-game confirmation, especially Forever custom quests.

Run the full inventory from Wayforth:

```sh
lua5.1 scripts/audit_all_guides.lua docs/ALL_GUIDE_AUDIT.md
lua5.1 scripts/audit_quest_locations.lua docs/QUEST_LOCATION_COVERAGE.md
```

Travel Directions uses authored legs first, then a known phase-specific destination. Mainland guides with existing travel hints show those instructions before the destination. A destination is not a walkable route or a claim that a flight/boat is available. No missing coordinate is invented; Horde Mount Hyjal currently has no bundled destination and retains instruction-only guidance.

### Incremental missing-destination refresh

`ForeverQuestLocationUpdates.lua` fills 12 empty phase records across 10 IDs from the same newer QuestieDB revision, preserving existing coordinates. Ten of these additions resolve visible guide-step gaps: pickup gaps fall from 11 to 3 and turn-in gaps from 5 to 3. The other source records are retained for applicable variants. Objective coverage remains unchanged; an Alliance-only vendor does not establish a Horde destination.

```sh
python3 scripts/import_forever_location_updates.py /path/to/pinned/QuestieDB
```

The importer requires the pinned commit, checks quest names before accepting new points, retains map/faction/entity metadata, and never replaces a nonempty phase. Its export excludes the incremental overlay so regeneration remains reproducible.
