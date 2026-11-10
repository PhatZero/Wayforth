# WayForth v0.3.3 - in-game QA

Test on **WoW: Forever 1.60.1 / Interface 16001** before marking ProjectForge foundation stories complete. The tests below are not equivalent to the static checks.

## Install / lifecycle
- [ ] `WayForth` appears in AddOns with version `0.3.3`, loads without enabling out-of-date addons.
- [ ] After character login, the minimap map button appears. Click toggles the addon; right-click opens Settings.
- [ ] Drag the minimap button. Relog, verify its position persists.
- [ ] Window opens, all eight sections switch correctly, buttons behave as labeled.
- [ ] Drag the main window. Relog, verify its position persists.
- [ ] Login and `/reload` show no Lua errors (temporarily use `/console scriptErrors 1` for QA only).
- [ ] UI opens with no website login, network login or subscription.

## Data / character
- [ ] Dashboard and Character show current character name, level, zone and XP where available.
- [ ] Complete two steps of the onboarding guide. Reload UI, verify steps and selected step persist.
- [ ] Log into another character and verify the guide begins independently.
- [ ] Set UI scale; toggle window lock and minimap visibility; relog and verify saved preferences.
- [ ] Inspect the SavedVariables files after exit; account and per-character DBs have `schemaVersion = 1`.
- [ ] Temporarily rename/remove the DB values in a backup test environment; addon reconstructs defaults.

## Compatibility / errors
- [ ] Diagnostics displays client version, interface, module count and SavedVariables health.
- [ ] Check actual build/version against `GetBuildInfo()`; client label is correct.
- [ ] Deliberately disable the minimap icon and confirm Addon Compartment access (if supported).
- [ ] If another client is tested, verify it is labeled **untested**, not automatically supported.

## Release quality
- [ ] No protected combat API operations, secure-frame taint warnings or frame leaks in normal play.
- [ ] Validate correct `/Interface/AddOns/WayForth/WayForth.toc` placement.
- [ ] Validate no included development scripts, docs, credentials, or website code in ZIP.
- [ ] Record results and any game-version-specific failures in the feature PR.

**Scope reminder:** Zephras Isle routes, quest-flag advancement, and the separate tracker/navigation arrow require live-client QA. Full objective counters, cross-zone route planning, profession collection, online sync and premium controls remain future milestones.

## Zephras Isle guide acceptance
- [ ] On a new Skyborne of each faction, the correct guide is selected automatically, if the client provides the Skyborne race token.
- [ ] Switch Guide cycles onboarding, Alliance and Horde; switching does not overwrite other guides' progress.
- [ ] Horde does not show High Order only steps; Alliance does not show Windshaper only steps.
- [ ] Only the current class's training steps show, e.g. Hunter gets pet training, Druid the spirit chain.
- [ ] Accept Coming of Age (92460); the quest acceptance step advances. Hand it in; the completion step advances.
- [ ] Quest updates do not cause UI reload loops or repeated Lua errors; no auto-skip of manual checkpoints.
- [ ] Complete several steps, `/reload` and relog. Progress and current step persist per character.
- [ ] Open Map / Set Map Pin on Zephras Isle for a verified early coordinate; if client does not support pins, show a safe error message instead of crashing.
- [ ] Outside Zephras Isle, Set Map Pin fails gracefully; unverified coordinates never generate invented pins.
- [ ] Confirm quest names/IDs, hub order and final departures against live 1.60.1.
- [ ] Verify no regression to minimap, dashboard, settings, diagnostics or the onboarding guide.

## Dashboard, tracker and compass (v0.3.1)
- [ ] Left-click minimap icon opens the **dashboard**, not the full guide instructions; clicking again closes it.
- [ ] Choose Guides and click each of the three guide cards. Selection preview changes without overwriting the current guide.
- [ ] Start Guide activates the selected route, closes the dashboard, and opens the compact floating tracker and pointer.
- [ ] The tracker has Prev, Done, Next, Pin, Sync controls; the Guides button reopens selection while the tracker remains visible.
- [ ] The minimap dashboard remains usable while tracker and pointer are open.
- [ ] Drag the tracker and pointer independently, reload/relog and confirm both positions persist.
- [ ] Settings → Tracker Settings locks dragging, adjusts tracker scale, resets locations, and can toggle visibility.
- [ ] Close the tracker, confirm the arrow hides; use Dashboard → Show Tracker to resume.
- [ ] On an active quest where the client provides a next waypoint, pointer updates when facing/moving and shows a distance if supported. Test cardinal directions against world map and correct any arrow orientation offsets.
- [ ] If no usable quest waypoint is available, only verified authored step coordinates may guide the arrow.
- [ ] If current map, player position, facing or arrow texture rotation is unsupported/restricted, show an unavailable message rather than fake direction/distance or a Lua error.
- [ ] Verify no compass updates continue after hiding, no combat taint errors, and no user-visible frame flashing on quest updates.
- [ ] Confirm previous version's tutorial guide, minimap position and character-specific saved quest progress survive upgrade.

## Frameless navigation arrow and quest sync (v0.3.1)
- [ ] Open an active guide: the pointer shows **only the arrow** with a small distance label. There must be no dark navigation box, header, or destination block.
- [ ] Drag the arrow to a new position; its position persists after UI reload.
- [ ] Show the tracker and press **Sync** with no matching quests: the tracker explains no progress was found instead of pretending success.
- [ ] Accept a quest in the selected guide: the acceptance step is marked complete automatically or after Sync.
- [ ] Complete objectives and turn in the quest: objective and turn-in steps are recognized even if a turn-in event occurs before completed flags update.
- [ ] Play several quests ahead of the current guide, passing a manual checkpoint. Press **Sync**; it catches up to a later confirmed quest and leaves unverified manual objectives available with Prev.
- [ ] Complete a few steps, logout and reload; quest events and user-entered manual completions survive and are not reset.
- [ ] Test non-Skyborne or wrong-faction character: Sync warns when no quest IDs match the selected guide.
- [ ] Check an inactive or unavailable quest log API: no Lua exception; message says quest syncing is unavailable.
- [ ] Test an unsupported map location: the frameless arrow is hidden rather than presenting an incorrect direction.

## Quest IDs, verified coordinates and arrow fallbacks (v0.3.2)
- [ ] Alliance Welcome to Shen'dar Village uses 93461; Horde uses 92514. Confirm both accept/turn-in progress tracks correctly.
- [ ] Alliance Fate of Zephras uses 94369; Horde uses 93836. Alliance What Comes Next is 93089; Horde is 93090.
- [ ] On a Hunter, early trainer points to Tai'ree Farsight (42.4, 23.6) and late trainer to Quel'ana Quickgale (59.6, 72.6).
- [ ] Alliance final skyboat guide step points to 65.9, 83.5; Horde final skyboat guide step to 57.9, 80.9.
- [ ] A step with verified coordinates shows the independent frameless arrow even if no quest waypoint is provided.
- [ ] When live GetNextWaypoint is unavailable, the arrow can use GetNextWaypointForMap or matching GetQuestsOnMap quest POIs, if returned by the client.
- [ ] A distance API failure does not hide the arrow, and no false yard count is shown.
- [ ] Pin on an active quest objective with a map POI but no authored coordinates succeeds or shows a safe client compatibility message.
- [ ] Unverified locations still show No waypoint, never an invented direction.
- [ ] On moving/facing North, East, South, West verify actual arrow direction in the game; compare minimap rotation and correct if necessary.
- [ ] On an off-zone map or instanced content, do not display a misleading arrow or allow an invalid user pin.
- [ ] Prior 0.3.1 quest sync status, SavedVariables, tracker positions and settings are preserved.

## Zephras 0.3.3 full waypoint verification
- [ ] Step to each of the 3 Missing Scholar quests, 92727/92849/92850, confirms quest IDs and correct pickup/turn-in stages.
- [ ] At #92850, test pickup near 52.1, 69.4, cave entrance 51.44, 68.99, matriarch 51.9, 65.6, and final turn-in in Valanaar 66.2, 79.9.
- [ ] The cave entrance arrow should not point above a cliff; objective arrow should switch correctly after entering and pressing Done.
- [ ] Test each class at the three Wowhead trainer locations; other class trainers must not appear.
- [ ] Alliance/Horde quest IDs and directions are distinct; re-entering a saved guide does not change existing step IDs or lose progress.
- [ ] Test a step with no live quest POI but a catalog coordinate: a frameless arrow should appear if the player position/facing APIs work.
- [ ] Test arrow when in a cave/interior map; if UI map coords cannot be resolved the message should say why rather than showing false direction.
- [ ] Test pins at distinct pickup/turnin NPCs for a single quest ID; do not navigate to the pickup location for an already turned-in objective.
- [ ] Record both game build and arrow rotation/distance behavior before treating this release as compatible.

## Alliance Smart Routes and source ID audit (feature branch)

- [ ] A level 18 Alliance Skyborne character can select Human, Night Elf, or Dwarf/Gnome regions from the **same** minimap dashboard.
- [ ] Recommended mode rejects gray/very-low-XP starter steps and suggests another area; **From Beginning** can still choose the old storyline, and **Resume Saved** keeps the previously selected position.
- [ ] Switching to Teldrassil, then Elwynn, then back to Teldrassil preserves independent saved steps and completed records.
- [ ] Skipped quests are not falsely marked completed; active quests take priority when appropriate; required lead-in quests are not silently treated as complete.
- [ ] At a level-up or turn-in, Recommended mode refreshes the suggested next step without changing the character's selected region.
- [ ] On an Alliance character, Horde-only guides are not offered; Horde cannot activate Alliance-only starter routes.
- [ ] Check 783, 282, 420, 456, 457, 458, 459 and the separate 92727/92849/92850 Missing Scholar stages against the live client and their on-map objectives.
- [ ] In Diagnostics select **Validate Quest IDs** and **Copy ID Report**. Record 439 source candidate entries; classify client title matches, title-only IDs, mismatches and unresolved/uncached IDs separately.
- [ ] Review unresolved and mismatched IDs manually against the game. Do not promote them to verified solely because a web catalog lists them.
- [ ] Test cross-zone travel instructions and live quest arrows; missing waypoints must not display fabricated coordinates.
- [ ] Verify full optional quests, class quests, profession introductions, actual quest level and prerequisites before declaring any racial starter guide complete.
