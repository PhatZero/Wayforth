# WayForth — WoW Forever Companion

**Version:** 1.0b1 (premium interface integration / in-game QA required)  
**First target:** WoW: Forever 1.60.1, Interface `16001`  
**Account or subscription required:** No. There is no website integration or network client.

This is the standalone in-game companion for the WoW Forever platform, designed with an offline-first free core. It is deliberately stored in its own folder with no dependency on Base44 or the website runtime.

## Live quest objective tracking

The current quest's tracker card shows live kill and collection counters, completed objectives, event requirements and percentage progress where the client supplies it. It refreshes as quest-log, inventory and quest-data updates arrive, even when the guide stays on the same step.

Completed rows are highlighted and ready quests show **Ready to turn in**. Existing Pause Guide and Auto Advance settings still control progression. Objective counters alone never mark a quest turned in or skip its remaining requirements.

Long objective lists scroll inside the card. Resize the tracker for more room, or hover the card to read its full instructions and objectives. Switching guides or abandoning a quest clears its old counters. Hidden trackers read fresh progress when reopened.

If the current quest is absent from the log or live objective details are unavailable, the tracker explains the state and retains its guide instructions. Objective counts are read from the character's current quest log and are not stored between sessions. In-game appearance and client-specific behavior remain unverified.

## Quest hub routing

With Smart Routing and automatic advancement enabled, a pickup round collects the selected guide's eligible quests at the same hub before starting their objectives. The route then finishes that group's active objectives before making its turn-in round. Ready turn-ins in a return visit are handled before newly unlocked follow-ups send the player out again. The tracker and arrow follow the same selected task.

The shared planner scans the full guide, respects known prerequisites, level restrictions, faction/race/class filtering and skipped pickups, and excludes uncollected quest-starting drops from extra hub pickups. Candidate quests still depend on their actual availability in the Forever client; use Skip if a quest is not offered. The plan stores stable quest/step IDs and does not change completion flags. Pause Guide, manual advancement and Smart Routing controls remain available. Installing an update while still at a quest giver can finish the pickup round; an established field route is not pulled back solely to collect more quests.

## Quest-item buttons

When the current objective or turn-in quest has a usable item in your inventory, its icon appears beside the current objective. Click it to use the item, or hover for its tooltip. The button shows native charges and cooldowns, follows tracker movement and scale, and clears after consumption, abandonment, guide switching, minimization or closing the tracker. Items can remain available when the client explicitly allows their use on completed quests.

The current item remains usable during combat. If the guide, item or tracker position changes in combat, **WAIT** covers the frozen button and blocks clicks until combat ends. A tracker opened for the first time during combat also waits. Binding and positioning update automatically afterward. The button uses only the usable item identified by the current quest log; items missing from that client data cannot be inferred.

## Install

1. Quit WoW completely.
2. Extract the release ZIP. It contains one top-level `WayForth` folder.
3. Copy that folder to:

   `World of Warcraft\_forever_\Interface\AddOns\WayForth\`

4. Start WoW: Forever. On the character selection screen, enable **WayForth** under AddOns.
5. Enter the world. A **map icon** should appear by the minimap. Left-click to open/close, right-click for settings; drag to reposition. If available, the Addon Compartment also opens the window.

You should see `WayForth.toc` directly under `AddOns\WayForth\`. Do not copy the outer `WayForthAddon_v0.1.0` source folder into AddOns.

## v1.0-beta visual pass and Forever names (November 2026)

- The original approved **gold-and-cyan compass is unchanged**.
- The dashboard and Guide Tracker use **bundled, illustrated TGA artwork**, not Blizzard inventory/spell icons, for Zephras Isle and guide categories: Leveling, Professions, Gold Making, and Exploration. These are original visual assets and do not imply unimplemented guides are complete.
- A single illustrated-art texture atlas also contains the gold gear icon for both Settings buttons and sidebar.
- Tracker defaults to 98% opacity and a shorter height so the Blizzard quest tracker does not bleed through; existing characters with the previous untouched 85%/480px defaults are migrated, but personalized values remain.
- Forever character identity displays first **and** last name where the game exposes it. This reads the two results of `UnitFullName("player")` and `UnitName("player")`, supports early builds returning `"First Last"` in one result, filters legacy realm placeholders, and safely falls back to a first name. The legacy `snapshot.name` remains first-name-only for SavedVariables compatibility, with new `firstName`, `lastName` and `displayName` fields. Character progress is still saved per character.
- Automated Lua surname tests cover modern/early Forever, legacy realms, absent surnames, and fallback behavior. Validate on the exact Forever client before claiming a specific surname is detected.

## Main leveling guide tester library (November 10, 2026)

WayForth includes faction-filtered **Alliance and Horde zone guide catalogs covering the main 1-60 leveling path**, suitable for volunteer quest-data verification. In addition to the curated Alliance starters and Skyborne story guide, the current main library includes sourced Horde Kalimdor, Eastern Kingdoms early/mid/high zones for both factions and the existing Alliance Kalimdor zone catalog. See [Main Guide Testers](docs/MAIN_GUIDE_TESTERS.md) for who should test which route and how to report mismatches.

**Do not advertise these as finished speed-leveling routes.** The generated entries are source-backed quest candidates sorted primarily by quest minimum level, with candidate pickup positions only where public records contained quest-giver coordinates. They are not verified objective/turn-in coordinates, optimized paths, or guaranteed quests for every race/class. Sparse late-zone records are visibly labeled Limited Data. The live client decides quest availability, progress and waypoints.

Data source: [ATTWoWAddon/AllTheThings, Forever zones](https://github.com/ATTWoWAddon/AllTheThings/tree/b2d15612a1319d450ffe844ee6b9ef708aa9d2c9/.contrib/.db/forever/zones), snapshot `b2d15612a1319d450ffe844ee6b9ef708aa9d2c9` (2026-11-10); factual IDs, titles, minimum levels, and optional candidate NPC positions adapted for original WayForth step wording. Quest sync and SavedVariables remain local to the addon.

## v1.0-beta premium in-game interface

This build updates the **existing WayForth addon**, not a second addon or a separate Base44 app.

- **One unified dashboard/settings window**, with left-side navigation, character summary, current guide card, guide category tiles, searchable leveling library, Favorites and Recently Used. Leveling guides are filtered by character faction and can be viewed near level, in starter zones, in Kalimdor, in Eastern Kingdoms, or across all zones.
- **One separate guide tracker**, movable and resizable, with current objective, upcoming objectives, clickable manual waypoint selection, persistent pin, normal Next vs. recorded Skip, Undo Skip, and a collapsible summary bar. Minimized tracker retains a visible floating arrow when a waypoint is available.
- **Original gold/cyan navigation needle**, bundled as a transparent 128px TGA generated by WayForth's own build script (no reused minimap arrow or decorative box). World-position bearings correctly scale across rectangular maps and, where supported, between zones on the same continent. Different-continent and unlocated targets never get a fake direction.
- **Real world MAP PIN**, not merely a locked arrow. The tracker button sets the selected step's Blizzard user waypoint, supports remote-zone pins when the map API allows them, converts unsupported child maps to valid parents where possible, and enables super tracking. Shift-click MAP PIN to open that map.
- **Concurrent quest tracker** shows active objectives and ready turn-ins from the selected guide alongside the hub sweep. A compact next-page control exposes additional quests without expanding into another window.
- **Character-specific preferences**, including window positions/sizes, opacity, Guide Recovery, Pause Guide, Auto Advance, Smart Routing and guide history; existing SavedVariables are migrated conservatively.
- **12 profession guides** cover all primary and secondary skills, show tailored material and pairing notes, and advance through skill, campsite and rank checkpoints from live client skill data.
- **Legacy Professions planner** carries over the WoWForever Fortune seven-perk planner, 16-point character plans, prerequisites, gathering and all-rounder presets, and per-character saves. It plans only; it does not change Legacy points in game.
- **Guide-switching choices** remain Start at My Level, From Beginning, and Resume Progress; previous quest completions are preserved per guide.
- **Premium Hub Sweep** checks the whole selected guide for nearby quest pickups, active objectives, and ready turn-ins. After a real pickup event, Smart Routing prefers remaining eligible quests at that hub before departing. Candidate pickups are clearly unconfirmed, with known prerequisites, level mode, and map boundaries enforced.
- **Accurate selected-step navigation** keeps the tracker and frameless arrow on the same objective. Clicking a side step with no verified destination still shows instructions; it never invents an arrow. MAP PIN and Skip act on the visible side objective.
- **Quest-item action** appears beside PIN when Forever's quest log exposes a usable special item. It uses a real secure button and defers attribute/visibility updates during combat; no item action is guessed from guide text.
- **Native custom addon controls**, rather than Blizzard's red button template. Guide imports and custom guide creation remain future backlog items.

**Validation status:** Automated Lua 5.1 syntax, route/quest synchronization tests and installable ZIP packaging run in GitHub Actions. In-game appearance, quest objective availability, and waypoint accuracy still require testing in WoW: Forever.

**Guide data limitation:** The 0.3.4 Kalimdor quest catalog is a source-indexed candidate library, not an audited collection of fully playable/verified routes. The profession section now includes 12 skill-aware guides with live rank checkpoints. It does not claim a fixed cheapest recipe list: learned recipes, trainer access and material prices must be checked in game.

For an in-game release checklist, see [V1_IN_GAME_QA.md](docs/V1_IN_GAME_QA.md).

## Historical v0.3.3 functionality

- Forever 1.60.1 first: interface `16001` and **modern API** detection (never treats the interface number as Classic by itself).
- A dark, gold-accented, draggable WayForth window and minimap launcher.
- Character snapshot: name, race, class, level, zone, XP and money (when the game exposes them).
- Original onboarding guide plus curated **Skyborne / Zephras Isle** routes for Alliance and Horde, with class-specific steps and saved per-character progress.
- Quest ID based advancement when quests are accepted or turned in (when the Forever client exposes those APIs); manual controls for objectives that cannot be safely detected.
- Compact always-visible tracker and independent draggable navigation pointer, using the client's live quest waypoints where available, and verified authored coordinates as fallback.
- Verified early-zone coordinates with optional in-game user map pins when standing on Zephras Isle and the client supports it. Steps with no quest waypoint or authored coordinates never invent a route.
- Dashboard, Guide Library, Map, Character, Professions, Legacy planner, Progress, Settings and Diagnostics sections.
- Account-wide preferences and character-specific progress with defensive defaults and schema versioning.
- Error capture and basic client diagnostic status.
- No slash command required, no sign-in, no payment and no network communication.

**Historical v0.3.3 limitations:** complete coverage of every quest, zone routes beyond Zephras Isle, cross-zone pathfinding, recipe shopping-list optimization, website sync, SimC-style copy/paste export, subscription systems, polished custom art assets. Later sections describe the subsequent guide and interface work. Direction/distance are shown only when the client exposes map coordinates and facing; this must be verified in the live Forever client.

## v0.3.1 usability and quest sync fixes

- The navigation pointer is **only a frameless arrow**, with a small distance label underneath; the old dark navigation box, banner, and destination copy are gone. Drag it as before to reposition it.
- **Sync** in the compact tracker now searches all quest-linked steps of the selected guide instead of stopping at the first manual checkpoint. It checks completed quest flags, accepted/active quests, and objectives ready to turn in, with optional compatibility API fallbacks.
- Explicit **Sync** can catch up to a later confirmed quest, even when unverified manual steps came first. Such manual steps remain available via **Prev** and are **not** silently marked complete.
- Current-session quest acceptance and turn-in events are captured; turned-in quests are also stored per character to handle delayed client completion flags.
- The tracker displays a short sync result: no matching quest data, unavailable quest APIs, no new updates, or how many steps were recognized and where the guide moved.
- Quest content still requires known quest IDs. Manual tasks without matching quest IDs cannot be auto-completed, and additional zone coverage remains future work.

## v0.3.2 quest ID and arrow repair

- Fixed shared Skyborne guide steps with separate Alliance/Horde quest IDs for Welcome to Shen'dar Village, The Fate of Zephras, and What Comes Next. Saved step keys remain unchanged.
- Added cross-checked Zephras Isle map coordinates for early class trainers, late Hunter/Druid/Shaman trainers, the Shen'dar quest contact, and both faction skyboat departure points. Authored original guide wording is preserved; locations still unverified are left without invented pins.
- Waypoint resolver tries the live quest waypoint, map-specific quest waypoint, and matching on-map quest POI before returning to verified authored coordinates.
- Pickup, turn-in, and class trainer steps favor their verified authored NPC coordinates; objective steps favor their live client destination. The frameless floating arrow remains separate from the tracker.
- Optional world-distance calculation failures no longer hide an otherwise valid directional arrow. Map Pin now uses the same target resolver and can pin active quest POIs even when no authored coordinate exists.
- Still requires live in-game validation on Forever 1.60.1, including arrow rotation and true client quest status. The addon never fetches Wowhead at runtime.

**Coordinate references:** https://www.wowhead.com/forever/guide/zephras-isle-zone-overview ; https://questing.wiki/wow-forever/quests/zones/zephras-isle/ ; https://zephras.com/forever/enUS/zone/16593/

## v0.3.3 all authored Zephras route waypoints

- An offline, curated **41-quest location catalog** now distinguishes pickup NPCs, objective areas, cave entrances, turn-in NPCs and skyboat departures instead of reusing one quest waypoint for all phases.
- Missing Scholar now has distinct Alliance guide checkpoints for quests `92727`, `92849`, and `92850`, with an explicit cave entrance (51.44, 68.99), 92850 pickup (52.1, 69.4), matriarch area (51.9, 65.6), and Valanaar turn-in (66.2, 79.9). Auto-sync can now recognize the real quest ID at the exact stage.
- New class-aware trainer stops provide **all 18 class trainers** listed in the Wowhead Zephras Isle map guide, at Thendal, Shen'dar, and Valanaar.
- Formerly generic manual region checkpoints now use individual verified quests where reliable metadata is available, with exact NPC endpoints vs approximate spawn areas clearly separated.
- All authored Alliance/Horde steps across the six playable Skyborne classes are required to resolve a valid zone map waypoint by an executable Lua regression test.
- **No runtime Wowhead access** and no extra addon dependency. Coordinates are static game-map data; some quest objectives are area centers and should use current in-game quest POIs when available.
- See [the source and accuracy audit](docs/ZEPHRAS_COORDINATES.md). Full coverage of every *optional* Zephras quest and actual runtime arrow display are not claimed without in-game QA.

## Alliance Smart Routes — integrated feature branch

- Keeps the original **single WayForth** addon, manifest, dashboard, minimap map button, frameless arrow, tracker and per-character `WoWForeverCharDB`.
- Adds **67 curated source-matched quest IDs** for Human/Elwynn Forest, Dwarf/Gnome/Dun Morogh, and Night Elf/Teldrassil. The existing Zephras guide is preserved. These are **starter route seeds**, not yet complete walkthroughs or confirmed live-client quest lists.
- Opens Guides with three explicit choices: **Start Guide** (recommended XP-aware), **From Beginning** (story), or **Resume Saved**. More Guides/Previous Guides page through available racial zones. The player may choose another Alliance region independently of race.
- Recommended mode checks level hints and known prerequisites, prioritizes accepted quests, and avoids sending a high-level character through low-XP starter quests. The five-level low-XP threshold is an **estimate**, not the exact Forever XP formula. When a region is below the player's level, WayForth suggests the next region but does not claim to have an authored onward guide.
- A new **439-entry zone source ID catalog** (Elwynn 99, Dun Morogh 107, Teldrassil 89, Zephras 144) is available through **Diagnostics > Validate Quest IDs**. **Copy ID Report** exposes each ID's client title or unresolved status for live QA. Source presence or a loaded title does not prove in-game eligibility, NPC, location, quest chain, or XP.
- Route switches preserve independent saved progress and never mark skipped quests complete. Recommended steps recalculate after quest turn-in and level-up; unknown/out-of-zone waypoints do not become fake arrows.
- The existing navigation pointer uses live client quest POIs when available. Cross-continent transport, class-specific content, complete optional quest coverage, and missing pickup/turn-in coordinates still need verification and authoring.

**Status:** GitHub feature branch; not deployed or certified in the live Forever client.

## v0.3.4 Alliance Kalimdor expansion

- Adds 16 zone guides with **798 source-listed Alliance/neutral quest ID candidates**, including Darkshore, Ashenvale, Stonetalon, Thousand Needles, Desolace, Dustwallow, Feralas, Tanaris, Azshara, Un\'Goro, Felwood, Winterspring, Silithus, plus optional Barrens/Moonglade and high-level Hyjal.
- The original single WayForth addon now provides six guide cards per page, with **Near My Level**, **Kalimdor** and **All Zones** filtering. Every guide supports **Recommended**, **From Beginning**, and **Resume Saved**, retaining independent character progress.
- The **Diagnostics quest audit** now covers 1,237 source-listed records across starter zones and Kalimdor. An ID match is not live validation of a quest\'s location, faction eligibility, prerequisites, or XP.
- NPC pickup coordinates are only shown when the character is inside that region. Missing objective/turn-in positions are never fabricated. The guide tracker displays travel hints when outside the zone.
- The routes are catalog-backed early drafts, **not yet complete optimized walkthroughs**. See [Kalimdor scope and QA](docs/KALIMDOR_ALLIANCE.md) before claiming all quests/coordinates verified.

## Dashboard, guide tracker, and navigation pointer

The **minimap icon opens the full dashboard**, even when a guide is running. From **Guides**, select the desired guide card, then click **Start Guide**.

A small quest tracker opens on the side of the game screen while the full dashboard closes. The tracker displays the current step, progress, instruction, and location, with **Prev**, **Done**, **Next**, **Pin**, and **Sync** buttons. The tracker and navigation pointer can each be dragged to a convenient place on your screen. The **Guides** button in the tracker returns to the dashboard's guide selection page. Closing the tracker also hides its pointer; select **Show Tracker** in Dashboard to resume.

The independent pointer uses `C_QuestLog.GetNextWaypoint(questId)` when a quest is active and the API provides usable map coordinates. Otherwise it uses a verified coordinate saved in the guide. It updates direction with `GetPlayerFacing()` and player map position at a throttled interval, and shows world-space distance if the client can calculate it. If your position, facing, or an objective position is unavailable, it **does not draw a misleading arrow**. No built-in navigation arrow is available for unverified manually authored checkpoints. Other addons are not required.

On **Settings → Tracker Settings**, show/hide the tracker, lock the frames, adjust its scale, and reset their positions. The account shares UI layout settings; each character remembers whether its tracker was open. Both the original WayForth tutorial and existing guide progress are preserved.

## Playing the Zephras Isle guide

1. Click the WayForth **minimap icon** to open the dashboard and select **Guides**.
2. Click one of the three guide cards: **Addon Tutorial**, **Skyborne: Alliance**, or **Skyborne: Horde**. On a new Skyborne character, the matching faction route is suggested automatically when detected.
3. Click **Start Guide**. The full dashboard closes; the tracker and independent waypoint pointer appear.
4. Follow the active step, using **Done/Next/Prev** when necessary. Quest acceptance and turn-in events can advance steps automatically when the client supports those APIs.
5. Click **Pin** to place an optional in-game map waypoint. For steps without a usable coordinate, the pointer explains the limitation rather than inventing a bearing.
6. Click the minimap icon any time to adjust settings or select a different guide. Closing or switching a guide does not erase per-character progress.

The authored route uses 44 raw shared/class/faction-filtered checkpoints rather than attempting to reproduce another guide's full 100+ quest list. It covers Thendal Grove, Shen'dar Village, Falaath, the pylons, Valanaar, faction branches, Shrine of Akir, and departing the island. The published Blizzard range is levels 1-12; exit quests can bring a player to roughly level 13.

Sources for zone names and quest metadata (guide instructions themselves are original):
- https://worldofwarcraft.blizzard.com/en-gb/news/24302071
- https://senseos.gg/guides/wow-forever/zephras-isle/
- https://senseos.gg/wiki/wow-forever/quests/92460/coming-of-age/
- https://bindonforever.com/zones/zephras-isle
- https://forevermastery.com/en/guides/wow-forever-zephras-isle

## Data model

- Account-wide: `WoWForeverDB` (settings and schema version).
- Character-specific: `WoWForeverCharDB` (guide progress, snapshot and schema version).
- Backup before installing a major update: `_forever_\WTF\Account\<account>\SavedVariables\WayForth.lua` (or `WoWForever.lua` if upgrading from the previous name), plus relevant per-character SavedVariables files. Paths depend on the client's WTF layout.

SavedVariables are written by the game during logout or UI reload, not immediately on each edit.

## Upgrade from the pre-rename WoWForever test addon

WoW stores SavedVariables in files named after the **addon folder**, not after the variable names. Renaming the folder from `WoWForever` to `WayForth` does **not** automatically load the old `WoWForever.lua` files.

For a clean install, quit the game and remove/disable the old `Interface/AddOns/WoWForever` folder, then install `WayForth`. Avoid running both versions together.

For an existing test installation with settings/progress you wish to keep:

1. Exit WoW completely. Back up the entire `_forever_/WTF` directory first.
2. Install the new `Interface/AddOns/WayForth` folder and remove/disable the old `WoWForever` addon folder.
3. Within `_forever_/WTF/Account/<account>/SavedVariables/`, **copy** `WoWForever.lua` to `WayForth.lua` if the old file exists and `WayForth.lua` does not yet hold data you want to keep.
4. Where your WoW build stores per-character addon SavedVariables (often `_forever_/WTF/Account/<account>/<realm>/<character>/SavedVariables/`), copy `WoWForever.lua` to `WayForth.lua` for each character whose progression you want to retain. Some client builds store these values differently; inspect your own WTF tree before copying.
5. Do not rename the variable identifiers **inside** the Lua files. WayForth deliberately retains `WoWForeverDB` and `WoWForeverCharDB` for backward compatibility.
6. Start the game, confirm Settings and guide progress, then keep your backups until verified.

If the old addon has never been installed, no migration is needed.



## Development

Shared modules and artwork live in `shared/`. Forever guides, compatibility code, and the manifest live in `clients/forever/`. Build the installable ZIP using Python 3:

```sh
python3 scripts/build.py
```

Run static/manifest tests with:

```sh
python3 -m unittest discover -s tests -v
```

Tests do **not** simulate a WoW client. See [`docs/QA.md`](docs/QA.md) for the in-game verification checklist. The code uses only bundled WoW APIs and no external Lua libraries.

## Compatibility

Forever is built on the modern retail addon API even though its interface number is `16001`. A TOC number alone cannot prove full compatibility. For other WoW clients, this release displays an untested compatibility warning rather than claiming support. Confirm the active interface with `/dump select(4, GetBuildInfo())` if needed for debugging; the addon itself does not require slash commands.

## Release discipline

Develop WayForth on feature branches and target `main` in this repository. The Forever build installs as `WayForth/`.

## Build and submit the Forever beta

Open **Actions → Build WayForth Forever → Run workflow** and select `main`.
Leave the upload checkbox clear to build and download the preview artifact.
Extract the installable WayForth ZIP from the GitHub artifact before manual installation or upload.

Once the WayForth project is set up on CurseForge, open GitHub **Settings → Secrets and variables → Actions**.
Add the numeric CurseForge project ID as a repository variable named `CURSEFORGE_PROJECT_ID`.
Add a [CurseForge author API token](https://authors.curseforge.com/account/api-tokens) as a repository secret named `CURSEFORGE_TOKEN`.

To submit a beta, run the same workflow, check **Upload the tested Forever beta to CurseForge**, and enter player-facing release notes.
The workflow submits the validated installable ZIP for Forever 1.60.1 and logs the returned CurseForge file ID.
Check the project's Files page for its review status. If an upload loses its response, check Files before submitting the same build again.

## GitHub releases

Open [Release WayForth Forever](https://github.com/PhatZero/Wayforth/actions/workflows/release.yml), choose **Run workflow** on `main`, and enter release notes. The workflow runs the addon tests and attaches the installable ZIP to a tagged GitHub prerelease. Select **Also submit the beta to CurseForge** to upload it there in the same run.

### Forever beta versioning

Push a tag on the commit to release, for example:

```sh
git tag forever-1.0b1
git push origin forever-1.0b1
```

The tag sets the version in the installable ZIP, manifest, addon UI, and GitHub prerelease. To also send tag-triggered releases to CurseForge, set the GitHub Actions repository variable `CURSEFORGE_PUBLISH_TAGS` to `true` and configure the project ID and token above. Tag pushes default to GitHub only.

Running the release workflow on `main` chooses the next numbered beta in the manifest's series. A rerun on the same tagged commit reuses its numbered version. Ordinary builds do not allocate release numbers.

### Tracker enhancements

- Hub rounds collect eligible nearby quests, finish their field objectives, then group ready turn-ins and unlocked follow-ups. Known prerequisite/level gates and manual checkpoints remain respected.
- Live objective counters refresh without changing steps. Long lists scroll; the remaining quests page within the available tracker space.
- Known blocked quests show their level or prerequisite requirement and the next action. Sync Guide Now retries recovery after you resolve it.
- Navigation explains remote zones, client-reported dungeon destinations and missing waypoints. MAP PIN still opens the destination world map.
- Choose **Report a Bug** from the tracker **...** menu or dashboard **Diagnostics**. Copy the selected report with Ctrl+C and paste into GitHub or ChatGPT. It includes addon/client version, guide, selected step, quest, map, coordinates and live objective status; nothing is sent automatically.

The UI and routing changes require in-game verification on Forever, including combat, hub follow-ups, world-map pins and dungeon transitions.

### Quest assistance and travel

- **Quest not offered** (tracker **...** menu) explains known requirements and offers a prerequisite or another active quest. Choosing a suggestion changes focus without marking the unavailable quest complete. Unknown availability remains explicit; Sync retries recovery.
- **Travel directions** (tracker **...** menu) follows authored legs. The initial routes cover both Zephras skycutter departures and the Missing Scholar cave entrance. The tracker **Next Travel** button advances a travel leg without completing a quest. Unlocated transport legs show instructions with no invented arrow. Other guides retain existing travel hints; boats, zeppelins, portals, flight paths and entrances can be represented by authored legs, but unverified connections are not generated.
- **Next-zone suggestions** appear in the tracker after all steps are complete or all remaining quests are at least five levels below you with no active quests/manual checkpoints pending. Click a suggested zone to switch; saved progress stays intact. Suggestions respect faction, visible steps, optional guides and the Smart Zone Recommendations setting. Manual checkpoints now have an explicit **Done / Next** button.
- **Settings > Quest Actions** contains separate **Accept Active Guide Quests** and **Turn In Active Guide Quests** toggles. Both default OFF per character. Holding Shift, pausing the guide or entering combat suppresses automation. Only matching, unskipped guide quest IDs are handled; multiple reward choices remain manual. Clients without ID-bearing gossip APIs still allow manual NPC quest selection followed by supported quest-dialog actions.

In-game Forever verification remains necessary, especially transport availability, NPC dialogs, reward choices, and guide transitions.

### Quest-log space and guide search

- WayForth reads the client-reported standard quest-log limit and quest count. At three or fewer free slots it shows a tracker warning and a chat notice when entering the near-full/full state. Unknown limits do not generate guessed warnings.
- Ready turn-ins from the active guide take priority before another pickup round when space is low. Existing field objectives and manual routing settings remain respected. The upcoming list offers ready turn-ins as **FREE A SLOT** entries. Automatic quest acceptance waits when the log is full or a known ready turn-in can free space. WayForth never abandons quests.
- Open **Search this guide** from the tracker **...** menu. Search the active guide by quest name or ID, NPC, hub, step number, or instruction text. Results include completed and skipped steps and are paginated.
- Click a result to open its full instructions in a scrollable, read-only view. **Back to Results** retains the search. Browsing does not change the guide cursor, waypoint, skipped flags or completion history. Results are revalidated if the active guide or visible steps change.
