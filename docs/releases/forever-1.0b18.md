# 🧭 WayForth Forever 1.0b18

**Beta update • World of Warcraft Forever 1.60.1 • Interface 16001**

This release adds the first dungeon quest-preparation guide and makes the guide tracker's tabs much more comfortable when resizing your window.

## 🏰 New: Dungeon Guides (first preview)

- **Dungeon Guides entry point:** Browse dungeon content through the existing WayForth dashboard and Guide Library, with no additional permanent window.
- **Hall of Thanes quest checklist:** A first **partial**, Forever-observed guide covering four associated quests: **Old Ironforge Incursion (#96393)**, **The Restless Dead (#96394)**, **Important Heirlooms (#96403)** and **An Ancient Grudge (#96395)**.
- **Prepare before you enter:** Quest pickup steps appear ahead of the entrance, followed by in-dungeon objectives and post-run turn-ins.
- **Live quest collection totals:** Track **Quests collected X/Y** and dungeon quests completed using your character's actual quest-log and completion information.
- **Faction-aware guidance:** Known Alliance-only quests are filtered for Horde characters; missing or unavailable quests are not assumed to be obtainable.
- **Honest waypoint handling:** Source-observed outside pickup/turn-in points are separate. Unverified quest givers and interior instance locations are clearly identified instead of supplying a made-up map pin.
- **Continue your adventure:** Dungeon steps use the existing tracker, guide tabs, Sync, skip/resume, and character-specific saved progress.

## 🛠️ Fixes: Smarter, resizable guide tabs

- **Responsive tab strip:** Show **two tabs around 500 px**, **three around 620 px**, and **up to five around 1000 px**, with paging for additional open guides.
- **Immediate reflow while dragging:** Tabs adjust when you shrink or enlarge the tracker, not only after a quest or UI refresh.
- **Clearer labels and close buttons:** Guide titles truncate to preserve the visible **X**, while the **+** guide-picker and page arrows retain dedicated space.
- **Keep your place:** Resizing preserves the active guide's visibility, your manual tab paging when appropriate, saved quest checkpoints, and profession crafting history.

## ✅ Automated validation

- **Regression tests** cover responsive tab counts at several window widths, resize reflow, active tab visibility, tab lifecycle, and progress persistence.
- **Dungeon checks** cover observed quest identifiers, source provenance, faction filtering, unknown pickup handling, collected/completed counters, and skip behavior.
- **Release packaging** is checked by the Forever Lua 5.1/Python CI suite before the installable ZIP is published.

## ⚠️ Known beta limitations

- **Dungeon Guides are an early preview, not complete coverage.** Only **Hall of Thanes** has an initial, **Partial** quest manifest. All other dungeon quest catalogs, full boss-to-boss walkthroughs, some prerequisites, and in-instance pathing still require Forever-specific research and verification. Tracking: [#65](https://github.com/PhatZero/Wayforth/issues/65).
- **Hall of Thanes still needs live verification.** Its four quest associations are observed in Forever source data, but **An Ancient Grudge (#96395)** has an unverified pickup, and not every faction/chain variant or interior location has been audited. Do not treat this checklist as a guarantee that all dungeon quests are obtainable.
- **Engineering 52–54:** No confirmed orange/yellow recipe progression path for this band. Tracking: [#55](https://github.com/PhatZero/Wayforth/issues/55).
- **First Aid 45–49 and 75–79:** Verified orange/yellow recipe progression remains incomplete. Tracking: [#56](https://github.com/PhatZero/Wayforth/issues/56).
- **in-game QA pending:** Automated checks passed, but this pre-QA beta still needs gameplay testing of dungeon pickup eligibility, quest counters, waypoints, and resizing the tracker at different UI scales. Existing UI acceptance checks remain open where player confirmation is needed.
- **Profession color reminder:** Verified yellow recipes may use a **10% extra-craft and material reserve**, but yellow crafts are **not guaranteed** to grant skill.

## 🧪 What to test

- **Resize the tracker:** Open four or more guides, drag between narrow and wide sizes, close some tabs with **X**, and confirm the active guide and **+** menu remain usable.
- **Try the new Dungeon Guides filter:** Select **Hall of Thanes**, inspect the pre-run quest list, and check whether known accepted quests increase the collected counter.
- **Complete a dungeon quest:** Confirm progress follows the in-game quest log and updates when the quest is turned in; verify missed quests remain unclaimed rather than automatically marked complete.
- **Check unknown pickups:** If a quest giver or location is unverified, WayForth should explain the gap rather than send you to an invented pin.
- **Report issues:** [WayForth on GitHub](https://github.com/PhatZero/Wayforth/issues). Please include screenshots, character faction/level, dungeon or quest ID, and steps to reproduce.

**Thank you for testing WayForth Forever!**
