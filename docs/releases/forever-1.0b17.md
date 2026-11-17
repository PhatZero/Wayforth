# 🧭 WayForth Forever 1.0b17

**Beta release • WoW Forever 1.60.1 • Interface 16001**

This update focuses on **startup compatibility, navigation polish, and cleaner guide switching**. It includes improvements merged after 1.0b16.

## 🛠️ Important fixes

- **Fix a startup-blocking profession event error.** WayForth now safely handles WoW Forever clients that do not recognize `TRADE_SKILL_UPDATE`, `TRADE_SKILL_LIST_UPDATE`, or `SKILL_LINES_CHANGED`, rather than aborting addon loading.
- **Keep profession tracking available.** The addon listens for the supported `TRADE_SKILL_SHOW` event when available, so opening a crafting window can refresh profession progress and capture known recipes. Inventory and successful-craft tracking remain in place.
- **Restore the Legacy category artwork.** The dashboard tile and sidebar use a bundled, matching Legacy texture instead of relying on an unreliable atlas slot or client icon.
- **Add a visible close button to the navigation menu.** The tracker’s three-dot **Options** menu now has its own **X**; closing the menu does not close the tracker, active guide, or navigation arrow.
- **Stop distracting guide suggestions during flights.** Automatic next-zone recommendations are suppressed during detected taxi/flight travel. Each zone change resets the **30-second settling period**, and eligible suggestions are evaluated after arrival.
- **Preserve manual guide changes.** The Guide Library remains accessible while traveling, and existing guide checkpoints, saved progress, and map navigation are retained.

## ✅ Automated checks

- **Forever compatibility regression:** A synthetic client rejects unsupported trade-skill events while WayForth still initializes and handles a profession window opening.
- **UI regressions:** Tests cover bundled Legacy art, navigation menu dismissal, and preservation of tracker state.
- **Travel regressions:** Tests cover multi-zone flights, the 30-second grace period, and suggestion suppression.
- **Build verification:** CI checks Lua 5.1 syntax, regression tests, Python validation, and installable ZIP integrity before publication.

## ⚠️ Known beta limitations

- **Engineering 52–54:** A source-verified orange/yellow recipe path is still missing. Tracking: [#55](https://github.com/PhatZero/Wayforth/issues/55).
- **First Aid 45–49 and 75–79:** Confirmed orange/yellow progression data remains incomplete. Tracking: [#56](https://github.com/PhatZero/Wayforth/issues/56).
- **in-game QA pending:** Automated checks do **not** replace verification in the actual Forever client. Please check that the startup error is gone, Legacy art displays at different UI scales, the **Options X** works, and taxi flights do not prompt unwanted guide switches. Related QA: [#60](https://github.com/PhatZero/Wayforth/issues/60), [#61](https://github.com/PhatZero/Wayforth/issues/61), [#62](https://github.com/PhatZero/Wayforth/issues/62).
- **Dungeon guides:** Complete dungeon quest manifests, prerequisite chains, and pre-run pickup checklists are still planned, **not included in this beta**. Tracking: [#65](https://github.com/PhatZero/Wayforth/issues/65).
- **Profession planning:** Yellow recipes use a **10% extra-craft/material reserve** where supported; yellow crafts are **not guaranteed** skill-ups. Unverified recipes and quest destinations are not presented as confirmed.

## 🧪 Help test this beta

- **Startup:** Launch Forever with WayForth enabled; confirm there is no unknown trade-skill event popup.
- **Professions:** Open a profession, collect ingredients, make a recipe, and check **Have / Required / Missing** and **Crafted X / Y** counters.
- **Navigation UI:** Open the three-dot Options menu and dismiss it with **X**, then confirm the guide and arrow stay visible.
- **Flight path:** Fly through multiple zones, land, and confirm no automatic guide prompt during flight or the following 30 seconds.
- **Artwork:** Inspect the Legacy tile and sidebar icon at both small and large UI scales.

Report anything unexpected at [WayForth Issues](https://github.com/PhatZero/Wayforth/issues), ideally with a screenshot, character details, and the affected quest or recipe ID.

**Thanks for testing WayForth Forever!**
