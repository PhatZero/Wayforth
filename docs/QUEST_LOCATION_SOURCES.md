# Forever quest locations

The bundled catalog holds factual quest IDs, phase endpoints, entity names and map-specific coordinates. It is loaded after the guide definitions and before the guide engine. The game client makes no source downloads.

## Sources

- [QuestieDB](https://github.com/Questie/QuestieDB/tree/aca0da1c4a5ed0bc12997b9aaeef7b35af9ee26e) provides corrected Forever quest starter/finisher relationships, NPC/object spawns, item loot sources, vendors and quest rewards. The importer uses its Static Correction loader with authored corrections and traces enabled. Its Forever coordinate conversion and native AreaID-to-UiMapID table are applied as supplied. Dungeon compatibility floors and unresolved sentinel coordinates are excluded.
- [AllTheThings](https://github.com/ATTWoWAddon/AllTheThings/tree/d30715fb2657743d1b8801e5e3f26b96b7047160) provides additional quest pickup locations, objective points and NPC positions from its compiled `db/Camelot/Categories/Zones.lua`. Quest-giver positions can locate a known finisher NPC referenced by QuestieDB. The importer retains the finisher relationship from its own source.
- [Wowhead Forever](https://www.wowhead.com/forever) quest maps supply separate `start`, `end`, `requirement` and `sourcerequirement` points for records missing from the catalogs. Supplemental map facts were retrieved on November 10, 2026 and retained in `scripts/data/forever_quest_maps.json`. Subsequent requests returned HTTP 403, so the remaining source gaps are retained in the audit.
- [AHledger](https://ahledger.com/wow-forever/quests) contributes player-recorded giver and finisher names. Only explicit `Giver` and `Turned in to` fields are used. A name resolves to a static destination only when it identifies one NPC ID in the source database and that NPC has a recorded map location. The factual snapshots used by the import are retained in `scripts/data/forever_quest_reports.json`.

An authored Zephras waypoint takes priority over supplemental records. Existing guide step IDs and per-character completion keys remain stable. Catalog quests with work to do receive an objective phase before the existing turn-in. The legacy cursor migration maps numeric saved positions to their original step IDs before the new phases are used.

A bundled objective location identifies a recorded target, loot source, vendor, reward source or event. It can be one of several destinations needed for the quest. Navigation prefers the live quest waypoint for an accepted objective. Some crafting, reputation and item requirements have no single fixed world location.

## Refresh

Check out the source repositories at the revisions above. The QuestieDB checkout contains the Lua 5.1 interpreter used by its exporter.

```bash
python3 scripts/import_forever_locations.py /path/to/QuestieDB \
  --att /path/to/AllTheThings --cache /path/to/wowhead-fact-cache \
  --reports scripts/data/forever_quest_reports.json
lua5.1 scripts/audit_quest_locations.lua docs/QUEST_LOCATION_COVERAGE.md
```

Use `--cached-only` to regenerate from the available supplemental snapshots. The importer writes the output after source loading finishes. The audit lists every unresolved static destination by guide, quest ID and phase. Source coverage requires live-client verification of accuracy and availability.
