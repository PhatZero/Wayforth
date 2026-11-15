#!/usr/bin/env python3
"""Fail-closed public *beta* gate with explicit known issues and QA disclosure.

The full-production readiness gate is separate and still requires complete
profession coverage plus actual game screenshots. The repo owner explicitly
authorized a pre-QA beta; this gate must never claim manual verification.
"""
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
coverage = json.loads((ROOT / "data/forever/profession_coverage.json").read_text(encoding="utf-8"))
notes = os.environ.get("CHANGELOG", "")
if coverage.get("client") != "forever" or not str(coverage.get("build", "")).startswith("1.60.1."):
    raise SystemExit("Beta release blocked: invalid Forever client provenance")
expected = {
    "engineering": [[52, 54]],
    "first-aid": [[45, 49], [75, 79]],
}
slugs = ("alchemy", "blacksmithing", "cooking", "enchanting",
         "engineering", "first-aid", "leatherworking", "tailoring")
for slug in slugs:
    row = (coverage.get("professions") or {}).get(slug, {})
    gaps = row.get("missingOrangeOrYellowBands")
    if gaps is None or not row.get("verifiedOrangeRecipes"):
        raise SystemExit(f"Beta release blocked: incomplete coverage report for {slug}")
    if gaps != expected.get(slug, []):
        raise SystemExit(f"Beta release blocked: skill coverage changed for {slug}: {gaps}")
required_disclosures = (
    "Engineering", "52–54", "First Aid", "45–49", "75–79",
    "#55", "#56", "in-game QA pending",
)
missing = [phrase for phrase in required_disclosures if phrase not in notes]
if missing:
    raise SystemExit("Beta release blocked: changelog must disclose " + ", ".join(missing))
print("Forever pre-QA beta gate passed: source data and known gaps disclosed.")
print("This is NOT an in-game QA approval or a complete-profession certification.")
