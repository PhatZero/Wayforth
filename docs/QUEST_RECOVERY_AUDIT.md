# WayForth Forever: all-guide quest recovery audit

**Audit date:** November 10, 2026  
**Scope:** Every Forever leveling guide loaded by the addon from the shared guide engine.  
**Purpose:** Confirm the *behavior of quest-history synchronization, prerequisite backtracking, and safe waypoint fallbacks* across guide collections. This is **not** a claim that every quest, prerequisite, NPC, or coordinate has been verified in a live game session.

## Recovery behavior now shared by all quest guides

1. **From Beginning**: use the authored guide's first unfinished step, even if it is below the player's level. Manual checkpoints are not silently completed.
2. **Resume Saved**: use that character's saved guide cursor. Legacy stable step IDs remain compatible.
3. **Smart Start**: prioritize an active quest from the *selected guide* and use an appropriate objective/turn-in phase. For a new catalog-backed route, suggest a level-suitable **candidate pickup**, not an unaccepted quest's turn-in.
4. **Missing quest**: follow recorded prerequisites backward. If a required quest is already in the log, finish it first. Otherwise direct toward its authored pickup.
5. **Unknown pickup coordinate**: show the pickup instruction and zone/hub label without synthesizing an arrow. An existing source coordinate is still *candidate data* pending in-game verification.
6. **Unknown prerequisite**: explain which quest cannot be resolved from the selected guide, and suppress the unverified destination.
7. **Sync Guide Now**: scan every authored quest in the selected guide; infer completion **only** from actual quest-completion flags, accepted/turn-in events, or legitimate step-level manual actions. Recalculate the selected route using the same shared recovery rules, including when explicitly invoked from Story mode.
8. **No forged completion**: route selection, preview, and recovery never set quest-completed flags or mark a quest as turned in.

## Source catalog inventory

These are **source row counts**, not validated live quest pickups. Existing authored Zephras quests are intentionally excluded from the catalog inventory to avoid mixing curated steps with auto-generated rows.

| Source collection | Quest records | Candidate coordinate present | Missing pickup coordinate | Recorded prerequisite references | References outside source file |
|---|---:|---:|---:|---:|---:|
| Alliance starter zones | 68 | 0 | 68 | 19 | 0 |
| Eastern Kingdoms early/mid | 556 | 467 | 89 | 335 | 13 |
| Eastern Kingdoms higher-level | 766 | 545 | 221 | 337 | 18 |
| Horde Kalimdor | 692 | 585 | 107 | 363 | 19 |
| Horde race-specific starter additions | 21 | 21 | 0 | 13 | 3 |
| Alliance Kalimdor | 798 | 641 | 157 | 424 | 28 |
| **Total** | **2,901** | **2,259** | **642** | **1,491** | **81** |

A prerequisite mentioned in another file **may still be valid** (cross-zone, adjacent source collection or race-specific extension). Some current source generators intentionally discard prerequisites not present in the same zone. We must not assume that all 81 are errors, or claim that the prerequisites form complete trees.

**Important:** Newly added Alliance starter pickup steps retain the old `quest-<id>` key for their existing turn-in step and create `quest-<id>-accept` as the pickup key. Existing per-character turn-in history is preserved.

## Functional test coverage

The offline Lua 5.1 suite validates:

- Every loaded guide has non-empty, unique step IDs after faction, race and class filtering.
- Quest-based guides share prerequisite-aware recovery rather than using the Zephras-only engine.
- Beginning and Resume remain selectable without mutating other guides' progress.
- Accepted quests take precedence over arbitrary same-level source rows.
- Unresolved prerequisites do not advance into a locked downstream quest.
- Source-catalog quests lacking coordinates remain visible with a no-waypoint explanation.
- Automatic or explicit route selection does not invent quest completions.
- Existing Zephras chain tests still cover level-10 mid-guide recovery, known prerequisite pickups, active objectives and ready-for-turn-in phases.

These tests **cannot** determine whether an NPC actually offers the quest on Forever, the character's phase, unknown quest flags, a chain requiring an external zone, or whether the saved location is correct.

## Outstanding verification work

- Validate quest-availability flags and prerequisite dependencies in the live Forever client, zone by zone.
- Add pickup and objective/turn-in coordinates where evidence supports them; review all 642 catalog entries with no source coordinates.
- Reconcile cross-zone and suppressed dependencies, and add clear travel-to-prerequisite guidance where needed.
- Split optional/class/race/branch quests from a coherent mandatory route. Source records sorted by minimum level are not an optimized leveling guide.
- Confirm known coordinates are the correct NPC and quest phase (candidate pickup coordinates should not be treated as turn-in locations).
- Perform live playthrough QA for Horde, Alliance, each race-specific starter, phasing, and quests with no map POI.

**Status interpretation:** shared recovery *engine* can be tested across all guides; individual quests remain catalog candidates until validated. Do not advertise all 1-60 routes as complete Zygor/RestedXP-equivalent optimized guides.
