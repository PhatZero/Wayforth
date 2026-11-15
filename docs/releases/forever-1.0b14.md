# WayForth Forever 1.0b14

## Quest guide improvements

- **4,134 quests available offline:** Added the imported ForeverDB quest catalog to the Forever addon.
- **3,406 observed location phases:** Added Forever-observed quest pickup and turn-in location records to improve waypoint coverage.
- **Preserved existing guide routes:** Existing hand-authored waypoints remain the priority when present.
- **Quest metadata:** Bundled quest levels, faction information, zones and available chain relationships for future guide synchronization.
- **No live API needed:** Quest reference data is packaged with the addon.

## Profession planner foundation

- **Orange-only planning engine:** Added a foundation for calculating crafts and required materials using source-verified orange recipes.
- **Coverage checks:** The planner reports missing recipe coverage rather than inventing quantities or shopping lists.
- **Automated regression coverage:** Added synthetic route tests to verify calculations and incomplete-data handling.

## Known limitations

- **Quest database is not an optimized leveling route:** Imported quests do not automatically create complete, ordered, playable guides.
- **Navigation needs in-game validation:** Pickup and turn-in coordinates are source-observed but have not all been tested in-game; objective coordinates remain incomplete.
- **Professions are not finished:** Full verified 1-to-max recipe catalogs, complete shopping lists, live crafting integration and end-to-end testing remain tracked in issue #28.

**Data attribution:** Quest reference data from ForeverDB.net.
- **Offline packaging check:** Corrected generated data attribution formatting so the offline-only source validation passes.

- **Build regression fix:** Corrected the synthetic profession-planner test fixture so CI can validate the new route engine.

- **Release validation:** Offline tests now permit static recipe attribution links while checking that the addon does not call HTTP APIs.
