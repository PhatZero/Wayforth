# WayForth 1.0 Beta — Main Leveling Guides: Tester Brief

**Audience:** Volunteer playtesters on WoW Forever 1.60.1 (Interface 16001).  
**Status:** Source-indexed quest data, *not* a fully validated or optimized leveling route.

## What is available

- **Alliance:** Elwynn Forest, Dun Morogh, Teldrassil, Zephras Isle; the existing Alliance Kalimdor catalog; Eastern Kingdoms guides from Loch Modan and Westfall through Eastern Plaguelands, including Riverglades.
- **Horde:** Durotar, Mulgore, Tirisfal Glades, Zephras Isle; The Barrens, Silverpine Forest and other Kalimdor/Eastern Kingdoms zone guides through the level-60 areas.
- **Both factions:** Contested-zone entries are separated by faction where the source provides faction restrictions. Some neutral quest eligibility is still uncertain.
- **Known limitations:** A guide can have few source records, and some class/race quests and daily/repeatable quests are intentionally omitted. Quest order is primarily by source-listed minimum level. Gold-making, profession and exploration guide content is not included in this test pass.

The data was adapted from factual quest entries in the [AllTheThings Forever zone source](https://github.com/ATTWoWAddon/AllTheThings/tree/master/.contrib/.db/forever/zones) at commit `b2d15612a1319d450ffe844ee6b9ef708aa9d2c9` (November 10, 2026). Quest IDs and some possible quest-giver locations are source records. Only the game can establish that a quest is eligible or completed for a particular character. Coordinates are **candidate pickup points**, not verified turn-ins.

## Installing

1. Close WoW and back up `WTF/Account/<account>/SavedVariables/WoWForeverDB.lua` and the character's `WoWForeverCharDB.lua` if present.
2. Extract the ZIP so `Interface/AddOns/WayForth/WayForth.toc` exists. Do not keep multiple `WayForth` directories inside each other.
3. Start WoW Forever and use the compass minimap icon to open the Dashboard.
4. Go to **Guide Library** and use Starter Zones, Near My Level, or All Zones. Source-backed additions are marked **SOURCE TEST**.
5. Open Guide Details. **Smart Start** is an estimated suggestion; **From Beginning** and **Resume Saved** give alternative starting points. Inspect the preview before launching.

## Suggested volunteer coverage

| Tester group | Starting region | Follow-on test |
| --- | --- | --- |
| Human Alliance | Elwynn Forest | Westfall, Redridge, Duskwood |
| Dwarf / Gnome Alliance | Dun Morogh | Loch Modan, Wetlands |
| Night Elf Alliance | Teldrassil | Darkshore, Ashenvale |
| Skyborne Alliance | Zephras Isle | Westfall or Loch Modan |
| Orc / Troll Horde | Durotar | The Barrens, Stonetalon |
| Tauren Horde | Mulgore | The Barrens, Thousand Needles |
| Undead Horde | Tirisfal Glades | Silverpine, Hillsbrad |
| Skyborne Horde | Zephras Isle | Silverpine or The Barrens |
| Mid-level Alliance / Horde | Any relevant contested zone | Arathi, Stranglethorn, Desolace, Feralas, Tanaris |
| High-level Alliance / Horde | Level 40+ character | Felwood, Un'Goro, Plaguelands, Silithus, Winterspring |

Testers do **not** need to complete every zone. A few repeatable observations per guide are more valuable than claiming full verification.

## For each guide, test

- Does the guide appear **only on the correct faction**?
- Are the title and character level range plausible?
- Can you preview Smart Start, From Beginning, and Resume without erasing progress?
- Are the first five quest IDs and titles valid in the game? Record any missing, renamed, faction-gated, class-gated or obsolete quest.
- Can you obtain the quest at the suggested NPC? Does the pickup arrow point to the correct location?
- When the quest enters your log, does the arrow prefer the **live map POI**? Does it handle missing POIs gracefully?
- Does turn-in advance only after the game confirms completion? Does Skip keep the quest uncompleted?
- Do Favorites, Recently Used, minimized tracker, and /reload persistence still work?
- When traveling to another zone, does WayForth avoid a wrong-map arrow?

**Never assume a step is wrong just because your character is ineligible.** Record the race, faction, class, level and prior completion status so we can distinguish the two.

## Report format

Copy and fill this out for each mismatch:

```text
WayForth build:
Character faction / race / class / level:
Zone and Guide:
Guide step number / quest ID / expected title:
What the addon showed:
What WoW Forever actually showed:
Expected pickup/turn-in location (if known):
Actual coordinates (if checked):
Quest was accepted / active / ready / turned in:
Arrow behavior:
Screenshots / Lua error text:
Can reproduce after /reload?:
```

**Important release rule:** These are usable **candidate quest checklists**, *not* RestedXP/Zygor-style finished routes yet. Precise routing, all in-game prerequisites, and verified optimized turn-in grouping require tester reports and further curation.
