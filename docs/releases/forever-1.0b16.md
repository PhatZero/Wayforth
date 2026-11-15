# 🧭 WayForth Forever 1.0b16

**Beta release • World of Warcraft: Forever 1.60.1 • Interface 16001**

## ✨ What's new

- **Closable guide tabs are back.** Keep multiple leveling and profession guides open, switch between them, close individual tabs with **X**, use **+** to choose another guide, and page across extra tabs.
- **Materials you can actually track.** Profession preparation now shows item-icon cards with live **Have / Required / Missing** quantities, per-item progress bars, and a **Collected X / Y** summary.
- **Prepare ingredients before crafting.** When supported by source-verified Forever recipes, WayForth expands crafted intermediates into underlying raw ingredients and lists the intermediate crafts separately. The original recipe bill of materials remains intact.
- **Crafting plan with real counters.** See ordered skill bands, recipe names and acquisition guidance, **Crafted X / Y** totals and progress bars based on observed successful crafting events, not guesses from skill gains.
- **Full-width profession views.** Switch between **Materials** and **Crafting Plan** using dedicated tabs or the bottom navigation. Both pages scroll independently, without the cramped side-by-side text columns.

## 🛠 Fixes and improvements

- **Restore working guide management:** Closing a guide tab no longer removes its saved checkpoints or profession craft history.
- **Cleaner shopping lists:** Counts reflect bag inventory and accessible bank contents; supported intermediate conversions show raw material needs separately.
- **More readable tracker:** Larger default workspace, card-based ingredient display, clearer recipe stages, and better wrapping.
- **Relevant steps first:** Crafting view focuses on actionable skill ranges rather than showing past skill bands as incomplete.
- **Smoother updates:** Only the visible profession page is repainted during automatic inventory and crafting refreshes.
- **Regression coverage:** Added Lua tests for tab switching/closing, saved progress, inventory updates, intermediate conversion calculations and material totals. Automated Lua checks and ZIP packaging passed.

## ⚠️ Known beta limitations

- **Engineering 52–54:** No confirmed orange/yellow progression path for this skill range. Tracked in [#55](https://github.com/PhatZero/Wayforth/issues/55).
- **First Aid 45–49 and 75–79:** Verified orange/yellow progression data remains incomplete. Tracked in [#56](https://github.com/PhatZero/Wayforth/issues/56).
- **in-game QA pending:** This is a pre-QA beta. Automated checks and build validation are not a substitute for testing the visual layout, profession event signatures, reagent quantities, trainer requirements, and guides inside the actual WoW Forever client.
- **Yellow recipe reserve:** A **10% extra-craft and material buffer** is planned where verified yellow recipes are needed, but a yellow craft does **not** guarantee a skill point.
- **Recipe access:** Crafted-intermediate suggestions use source-verified data, but you must learn the indicated recipe or obtain the finished component directly. Unverified routes are never claimed as complete.
- **Other guide content:** Quest locations, pickups, and map navigation still need player verification. Where source data is missing, WayForth should display an honest limitation rather than invent a destination.

## 🧪 Help test this beta

- **Profession check:** Try Tailoring, Leatherworking, or another profession. Confirm material bars update when adding/removing reagents and that a successful craft increments only the correct recipe counter.
- **Tab check:** Open more than one guide, close one tab, switch back, and verify progress survives **/reload**.
- **Long-list check:** Scroll the full materials list and crafting plan at different tracker widths; report any clipped text or overlapping buttons.
- **Report issues:** Use [WayForth GitHub Issues](https://github.com/PhatZero/Wayforth/issues). Include your profession/skill, the affected recipe or quest ID, your inventory counts, and a screenshot where possible.

**Thanks for helping improve WayForth Forever!**
