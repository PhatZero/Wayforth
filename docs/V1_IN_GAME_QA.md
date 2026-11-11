# WayForth v1.0-beta: Forever 1.60.1 In-Game QA

**Target:** Interface 16001. Install package under `World of Warcraft\_forever_\Interface\AddOns\WayForth\`.
**Safe source:** PR #28 integrates on top of Alliance Kalimdor PR #27; no separate addon or minimap icon.

## Visual identity
- [ ] Dashboard opens via one minimap icon, and its content switches internally between Dashboard, Guide Library, Favorites, Recently Used, Map, Character, Settings, Diagnostics.
- [ ] No traditional red Blizzard buttons remain. The selected dashboard concept's navy/charcoal background, gold borders, cyan accents, current guide card, four categories and separate lower lists are visibly recognizable.
- [ ] Tracker visually matches Dashboard; current objective is readable and the next two relevant steps appear by default.
- [ ] Tracker collapses to title/step bar with a plus icon and restores without changing quest position.
- [ ] Arrow is frameless, gold, independently draggable, with distance underneath if supported. It stays visible on tracker minimize when a waypoint is available.

## Official artwork and Forever full names
- [ ] Confirm approved compass remains unchanged in dashboard, tracker, minimap and minimized state.
- [ ] Confirm the Zephras Isle guide illustration renders and all four category tiles show distinct landscape/forge/treasure/map scenes, not spell/item icons.
- [ ] Confirm both settings buttons show gold gear icons and still open unified settings.
- [ ] Confirm the live Forever character panel displays `First Surname` while preserving `snapshot.name` as first-name-only.
- [ ] Toggle Blizzard's surname-on-nameplate setting; WayForth should still use the character's actual name, not visibility preferences.
- [ ] Confirm no duplicate surname, no appended ruleset/realm name, and no fabricated last name if the API returns nothing.
- [ ] Confirm 98% default opacity prevents quest-tracker bleed-through; slider can still lower it.
- [ ] Confirm compact tracker fits current objective, two upcoming steps and bottom controls without excessive empty space.

## Window layout and persistence
- [ ] Dashboard and tracker resize using lower-right grip; text wraps and controls do not overlap at minimum/maximum sizes.
- [ ] Move windows and arrow, adjust both opacity sliders, change arrow size and toggle window lock. Reload and log back in; all character preferences persist.
- [ ] Use a second character; settings, Favorites, recent history, and quest progress do not leak between characters.
- [ ] Closing the Dashboard leaves tracker open; tracker Settings opens unified Dashboard Settings instead of a third management window.
- [ ] Restore Defaults/Reset Navigation restores positions without deleting quest completion data.

## Guide selection and progression
- [ ] Near Level, Starters, Kalimdor, Eastern and All Zones filters show faction-appropriate guides. Search filters by known title, zone or continent.
- [ ] Guide selection offers Start at My Level, From Beginning and Resume Progress. Switch to another zone and back; earlier progress survives.
- [ ] Star two guides on one character. They appear under Favorites; recently opened guides appear in Recently Used. Second character has its own lists.
- [ ] Manual Next advances only the cursor; Skip records a skipped step without falsely completing any game quest; Undo Skip restores it.
- [ ] Pause Guide freezes automatic cursor movement and Smart Route recalculation; game-confirmed quest state remains recorded. Unpause resumes.
- [ ] Disable Automatic Recovery, complete quest out of guide, and confirm route does not jump. Sync Guide Now deliberately reconciles the route.
- [ ] Toggle Original/Smart Routing as available and verify the chosen route never bypasses unknown prerequisites.

## Quest and arrow validation
- [ ] Skyborne (Alliance/Horde): verify each starter checkpoint, including Missing Scholar quests 92727, 92849 and 92850, with live client quest records.
- [ ] Alliance starter zones Elwynn Forest, Dun Morogh and Teldrassil: inspect candidate IDs and progression.
- [ ] Kalimdor: select Darkshore, Ashenvale and other zones in the source catalog; source-indexed entries are not necessarily confirmed playable routes. Record unmatched, ineligible and unverified quests rather than certifying them.
- [ ] At a hub with quests spread across a long guide, accept one and confirm Hub Sweep lists other eligible pickups before routing to objective areas. Turn-ins that unlock follow-up quests should refresh the list.
- [ ] Ensure Hub Sweep excludes a blocked prerequisite, wrong zone/map and above-level quest. From Beginning deliberately keeps lower-level content; Smart Start avoids gray quests.
- [ ] Group suggestions must be labeled as candidates, not confirmed NPC availability, and must never mark quests completed.
- [ ] Click a nearby quest with no recorded coordinates; its full instructions appear without an invented waypoint. Click PIN on the side objective and confirm the arrow and displayed objective agree.
- [ ] Click Skip, Previous and Next while viewing a side objective. They must act on the visible selected step, not silently manipulate a different guide step.
- [ ] Accept a quest with an in-log special-use item. The small item action beside PIN uses the item on a real click; check charges, tooltip and ready-for-turn-in visibility.
- [ ] Change quests, reload, and close/minimize the tracker in and out of combat. Secure item changes must be deferred until combat ends, with no protected-action/taint errors.
- [ ] Cross-zone map positions do not generate an arrow on the wrong map; missing objective waypoints display a safe fallback.
- [ ] Check arrow facing/rotation and actual distance in the live client.

## Release gates
1. GitHub Actions validation green (Lua 5.1 syntax/tests, Python tests, package ZIP).
2. Manual in-game QA completed at 1080p and 1440p with screenshots matching the approved reference sufficiently closely.
3. Quest coordinate/title audits completed for any route advertised as verified.
4. Only then mark PR ready for merge and promote the build through the normal release process.

Guide imports/custom-guide creation are explicitly deferred; the v1 UI includes category entry points but does not pretend that missing profession/gold/exploration guide data has been authored.
