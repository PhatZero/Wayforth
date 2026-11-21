# WayForth Forever: Simple Step Reader

## Player-facing behavior

WayForth now defaults to a single owner for guide progression: the authored step reader.

1. The selected guide stays selected across log updates, level-ups, and zone changes.
2. Quest events update completion evidence. Auto Advance moves forward **only across consecutive, verified current steps**.
3. Manual checkpoints, including travel/training steps, require **Done / Next**. Checking a later quest does not silently jump across one.
4. **Sync Guide Now** is an explicit catch-up action. It can move to a later step backed by live quest evidence; when the selected quest is missing, it can point back to an authored pickup or prerequisite without inventing completion.
5. **From Beginning**, **Resume**, and **Recommended** remain explicit guide-selection choices. Recommended favors an active quest and its current phase. It no longer guesses based on the character's level in step-reader mode.
6. Navigator, tracker tabs, dashboard, profession materials, dungeon checklists and guide data are not removed or redesigned as part of this change.

## Data versus behavior

Guide content remains in `clients/forever/guides/`. Each authored step can describe a quest pickup, objective, turn-in, or manual action. The reader uses the existing quest APIs and stable step IDs in `shared/core/Guides.lua`; the visual tracker and navigator display the selected step rather than deciding the route.

## Compatibility

`simpleStepReader` defaults to `true` in per-character settings, including existing characters at their next database initialization. Existing `guideProgress` SavedVariables, `currentStepId`, completed markers, guide tabs and favorites are preserved. Legacy hub/quest-log/smart-route heuristics remain in the codebase for compatibility during this transition, but they cannot move the cursor while the step reader is enabled. They should be retired after in-game QA and migration coverage.

The reader does **not** turn an unknown quest status into completion. If the API is unavailable, the user can continue manually. Previously completed accept/objective markers are not deleted when a quest is abandoned, but such stale markers are not sufficient for automatic advancement unless the live quest status also satisfies the step.

## QA checklist in Forever

- Start a guide from its beginning, accept a quest and verify pickup → objective.
- Finish objectives and verify objective → turn-in → next step after handing in.
- Start halfway through a guide and use **Sync Guide Now** with a quest already in the log.
- Abandon a tracked quest. Use Sync to return to its pickup, and confirm the cursor does not immediately skip ahead.
- Confirm an uncompleted trainer/travel/manual step blocks automatic progression, even if later quests are accepted.
- Confirm no automatic step jump when changing zones, leveling, or entering/exiting flight.
- Confirm dashboard, tab close buttons, minimap/map pins, quest-item controls, and profession/dungeon views still work.
