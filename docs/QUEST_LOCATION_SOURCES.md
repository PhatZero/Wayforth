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
- [Quest Checker](https://questchecker.com/) documents Retail support for its character lookup and supplies an in-game macro for Classic. It provides completion-state lookup. Guide Sync reads the current character's completed/active quest flags in the game client.

Quest eligibility uses the recorded quest race mask to determine faction restrictions. The correction filters opposite-faction quests from candidate zone guides. Entries explicitly listed in AllTheThings' `HiddenQuestTriggers` category are excluded from actionable guide steps. Numeric cursors and bookmarks on an excluded quest resume at the next surviving legacy step. The first import incorrectly applied NPC allegiance to some kill and loot targets. The corrected import filters quest-giver and vendor interactions by NPC allegiance. Kill and loot targets are eligible through their quest's faction.

An authored Zephras waypoint takes priority over supplemental records. Existing guide step IDs and per-character completion keys remain stable. Catalog quests with work to do receive an objective phase before the existing turn-in. The legacy cursor migration maps numeric saved positions to their original step IDs before the new phases are used.

A bundled objective location identifies a recorded target, loot source, vendor, reward source or event. It can be one of several destinations needed for the quest. Navigation prefers the live quest waypoint for an accepted objective. Some crafting, reputation and item requirements have no single fixed world location.

The WoWDB review also prompted use of the explicit entity markers in Forever's scripted-objective records. These resolve centaur enemies for the Desolace reputation quests and Silva Fil'naveth for the Druid flight back to Darnassus. The latter retains Forever's flight interaction before the separately recorded Darnassus finisher. Instance bosses with unresolved dungeon-floor coordinates retain named instructions without an invented outdoor point. The coverage audit keeps every phase without a valid static destination in its missing count, including phases with documented requirements.

## Refresh

Check out the source repositories at the revisions above. The QuestieDB checkout contains the Lua 5.1 interpreter used by its exporter.

```bash
python3 scripts/import_forever_locations.py /path/to/QuestieDB \
  --att /path/to/AllTheThings --cache /path/to/wowhead-fact-cache \
  --reports scripts/data/forever_quest_reports.json
lua5.1 scripts/audit_quest_locations.lua docs/QUEST_LOCATION_COVERAGE.md
```

Use `--cached-only` to regenerate from the available supplemental snapshots. The importer writes the output after source loading finishes. The audit lists every unresolved static destination by guide, quest ID and phase. Source coverage requires live-client verification of accuracy and availability.
