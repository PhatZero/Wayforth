#!/usr/bin/env python3
"""Block public Forever releases until source coverage and in-game QA are proven."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
coverage=json.loads((ROOT/"data/forever/profession_coverage.json").read_text())
expected={"alchemy","blacksmithing","cooking","enchanting","engineering","first-aid",
          "leatherworking","tailoring"}
if coverage.get("client")!="forever" or not str(coverage.get("build","")).startswith("1.60.1."):
    raise SystemExit("Release blocked: missing Forever build provenance.")
professions=coverage.get("professions") or {}
for slug in sorted(expected):
    row=professions.get(slug) or {}
    if not row.get("verifiedOrangeRecipes") or row.get("missingOrangeOrYellowBands") is None:
        raise SystemExit("Release blocked: unverified recipe inventory for "+slug)
    if row["missingOrangeOrYellowBands"]:
        raise SystemExit("Release blocked: verified orange/yellow coverage missing for "+slug+
                         " "+str(row["missingOrangeOrYellowBands"]))
approval=ROOT/"data/forever/release_qa_approval.json"
if not approval.is_file():
    raise SystemExit("Release blocked: actual Forever in-game QA approval is absent.")
result=json.loads(approval.read_text())
if result.get("approved") is not True or result.get("clientBuild")!=coverage["build"]:
    raise SystemExit("Release blocked: game-build-matched in-game QA has not been approved.")
if not result.get("reviewedBy") or not result.get("reviewedAt") or not result.get("evidence"):
    raise SystemExit("Release blocked: in-game screenshots and reviewer evidence are required.")
print("Forever release gate passed: verified source coverage and in-game QA.")
