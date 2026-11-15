# WoW Forever profession catalog: verification ledger

**Scope:** Issue #28, phase 1. Forever client only. No Classic or Retail recipes may enter the published catalog.

## Imported client data (November 15, 2026)

An authenticated ForeverDB snapshot for client **1.60.1.70938** was acquired from GitHub Actions and compiled into `clients/forever/guides/ForeverProfessionData.lua` with `scripts/build_foreverdb_profession_lua.py`. The compiler admits only recipes whose `skill.orangeSource` is **client**, with valid IDs, ingredients, known learning skill and acquisition source; inferred Classic breakpoints are rejected. Full counts and gaps: `data/forever/profession_coverage.json`. This verified-import stage does **not** replace in-game screenshots or user acceptance.

**Skill bands needing fresh Forever corroboration before public release:** Blacksmithing 20–29, Engineering 30–74, First Aid 30–139 and 175–300. Some First Aid skills may intrinsically lack orange recipes, in which case an orange-only full route is not possible without a game rule change. The tracker safely displays a shorter verified route or a live, single-craft orange fallback, never an invented full list.

## Verification gate

A recipe is **not approved for WayForth routing** merely because it appears on a Forever-themed website. Approval requires:

1. A source identifying the **WoW Forever** client and its build.
2. A confirmed recipe spell ID, output item ID, each reagent item ID and quantity.
3. Confirmed orange-to-yellow skill transition and skill needed to learn the recipe.
4. Acquisition method (trainer, pattern, vendor, quest, etc.) and any rank/station prerequisites.
5. In-game Forever corroboration, or a directly inspectable Forever client-data record matching the recorded build.
6. Source URL, client build, verification method, and verification date retained with the record.

A Classic or Retail page is never sufficient. Unconfirmed candidates remain outside `ns.professionRecipeCatalog`; missing skill ranges must produce a gap, not guessed quantities.

## Full catalog coverage (all professions, 1–Forever cap)

All twelve professions are in scope simultaneously. This table was originally written before the first client-verified import; refer to the source coverage JSON and update above for current measured coverage. A single Leatherworking skill range is **not** the deliverable or a release gate by itself. Crafting professions require complete recipe and ingredient coverage; gathering professions require Forever-verified nodes, skill thresholds, trainer/rank gates, and region-specific routes.

| Profession | Required data | Verification status |
| --- | --- | --- |
| Alchemy | Recipes, reagents, orange thresholds, trainers | Pending |
| Blacksmithing | Plans, bars/intermediates, orange thresholds, trainers | Pending |
| Cooking | Recipes, ingredients, orange thresholds, sources | Pending |
| Enchanting | Enchants, materials, orange thresholds, trainers | Pending |
| Engineering | Schematics, components, orange thresholds, trainers | Pending |
| First Aid | Bandages and Forever-specific recipes, materials, orange thresholds | Pending |
| Fishing | Skill thresholds, trainers, Forever waters/routes | Pending |
| Herbalism | Nodes, skill thresholds, trainers, zones | Pending |
| Leatherworking | Patterns, hides/leather/intermediates, orange thresholds | Pending |
| Mining | Ore nodes, smelting recipes, skill thresholds, zones | Pending |
| Skinning | Creature skill thresholds, zones, trainers | Pending |
| Tailoring | Patterns, cloth/intermediates, orange thresholds, trainers | Pending |

## Leatherworking discovery sources (NOT YET APPROVED)

| Source | Client/build claimed | What it provides | Current status |
| --- | --- | --- | --- |
| https://wow-forever.gg/professions/leatherworking/ | Forever 1.60.1.70938 | 592-recipe catalog, color thresholds, reagents | Discovery only |
| https://www.zockify.com/forever/professions/leatherworking/recipes/ | Forever, updated 2026-11-13 | 512-recipe catalog, reagents, sources | Discovery only |
| https://www.warcraftforever.wiki/wiki/Leatherworking/Recipes | Forever beta 1.60.1.70124 | 514 patterns, yellow thresholds and reagents | Discovery only |
| https://everloot.app/tools/professions/leatherworking | Forever 1.60.1.70888 | 591 recipes, player observations | Discovery only |
| https://questing.wiki/wow-forever/professions/leatherworking/ | Forever and community reports | Recipes, colors, materials | Mixed provenance: manual scrutiny required |

These sources disagree on catalog counts and builds. **Do not automatically reconcile or treat their claims as game verification.** Confirm every candidate independently, especially when its orange threshold or ingredients differ.

## Regression example, not a delivery milestone

- Character: Leatherworking **61/100**.
- Required: a contiguous verified **orange-only** route from 61 to 100, including trainer/rank checks.
- Expected UI: full recipe sequence and expanded ingredient totals **before** opening the profession window.
- Current status: **blocked on verified spell/item IDs, recipe orange breakpoints, and complete acquisition details**. The same verification gate applies to **every** profession and skill range.
- Never substitute synthetic test recipes for production data.

## Source policy

Production recipe records must carry `provenance.client="forever"`, `provenance.verified=true`, a Forever source URL, and `provenance.checkedBuild`. Mark verified only after the verification gate above is met.
