# WoW Forever profession catalog: verification ledger

**Scope:** Issue #28, phase 1. Forever client only. No Classic or Retail recipes may enter the published catalog.

## Verification gate

A recipe is **not approved for WayForth routing** merely because it appears on a Forever-themed website. Approval requires:

1. A source identifying the **WoW Forever** client and its build.
2. A confirmed recipe spell ID, output item ID, each reagent item ID and quantity.
3. Confirmed orange-to-yellow skill transition and skill needed to learn the recipe.
4. Acquisition method (trainer, pattern, vendor, quest, etc.) and any rank/station prerequisites.
5. In-game Forever corroboration, or a directly inspectable Forever client-data record matching the recorded build.
6. Source URL, client build, verification method, and verification date retained with the record.

A Classic or Retail page is never sufficient. Unconfirmed candidates remain outside `ns.professionRecipeCatalog`; missing skill ranges must produce a gap, not guessed quantities.

## Leatherworking 61–100: discovery sources (NOT YET APPROVED)

| Source | Client/build claimed | What it provides | Current status |
| --- | --- | --- | --- |
| https://wow-forever.gg/professions/leatherworking/ | Forever 1.60.1.70938 | 592-recipe catalog, color thresholds, reagents | Discovery only |
| https://www.zockify.com/forever/professions/leatherworking/recipes/ | Forever, updated 2026-11-13 | 512-recipe catalog, reagents, sources | Discovery only |
| https://www.warcraftforever.wiki/wiki/Leatherworking/Recipes | Forever beta 1.60.1.70124 | 514 patterns, yellow thresholds and reagents | Discovery only |
| https://everloot.app/tools/professions/leatherworking | Forever 1.60.1.70888 | 591 recipes, player observations | Discovery only |
| https://questing.wiki/wow-forever/professions/leatherworking/ | Forever and community reports | Recipes, colors, materials | Mixed provenance: manual scrutiny required |

These sources disagree on catalog counts and builds. **Do not automatically reconcile or treat their claims as game verification.** Confirm every candidate independently, especially when its orange threshold or ingredients differ.

## First acceptance fixture

- Character: Leatherworking **61/100**.
- Required: a contiguous verified **orange-only** route from 61 to 100, including trainer/rank checks.
- Expected UI: full recipe sequence and expanded ingredient totals **before** opening the profession window.
- Current status: **blocked on verified spell/item IDs, recipe orange breakpoints, and complete acquisition details**.
- Never substitute synthetic test recipes for production data.

## Source policy

Production recipe records must carry `provenance.client="forever"`, `provenance.verified=true`, a Forever source URL, and `provenance.checkedBuild`. Mark verified only after the verification gate above is met.
