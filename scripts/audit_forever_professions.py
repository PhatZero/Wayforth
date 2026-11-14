"""Audit full Forever profession coverage without assuming unverified recipes.

Input JSON schema:
{"client":"forever","build":"1.60.1.x","professions":{
 "leatherworking":{"cap":300,"recipes":[
 {"spellId":1,"orangeFrom":1,"orangeUntil":20,"verified":true,
  "source":"https://www.wowhead.com/forever/...","reagents":[{"itemId":2,"count":1}]}
 ]}}}
This is a validation tool, not a recipe importer. Unverified records never cover a skill.
"""
import json
import sys

PROFESSIONS = (
    "alchemy", "blacksmithing", "cooking", "enchanting", "engineering",
    "first-aid", "fishing", "herbalism", "leatherworking", "mining",
    "skinning", "tailoring",
)
GATHERING = {"fishing", "herbalism", "mining", "skinning"}


def audit(data):
    if data.get("client") != "forever" or not data.get("build"):
        raise ValueError("A specific WoW Forever client build is required")
    result = {}
    for profession in PROFESSIONS:
        entry = data.get("professions", {}).get(profession, {})
        cap = entry.get("cap")
        if not isinstance(cap, int) or cap < 1:
            result[profession] = {"status": "missing cap", "gaps": []}
            continue
        if profession in GATHERING:
            result[profession] = {"status": "requires verified gathering route audit", "gaps": []}
            continue
        covered = [False] * cap
        approved = 0
        for recipe in entry.get("recipes", []):
            if not (
                recipe.get("verified") is True
                and recipe.get("source", "").startswith("https://www.wowhead.com/forever/")
                and isinstance(recipe.get("spellId"), int)
                and isinstance(recipe.get("orangeFrom"), int)
                and isinstance(recipe.get("orangeUntil"), int)
                and recipe.get("reagents")
                and all(isinstance(r.get("itemId"), int) and isinstance(r.get("count"), int)
                        and r["count"] > 0 for r in recipe["reagents"])
            ):
                continue
            start, stop = recipe["orangeFrom"], recipe["orangeUntil"]
            if not (1 <= start < stop):
                continue
            approved += 1
            for skill in range(max(1, start), min(cap + 1, stop)):
                covered[skill - 1] = True
        gaps = []
        start = None
        for skill in range(1, cap + 2):
            absent = skill <= cap and not covered[skill - 1]
            if absent and start is None:
                start = skill
            if not absent and start is not None:
                gaps.append([start, skill - 1])
                start = None
        result[profession] = {"status": "complete" if not gaps else "incomplete",
                              "approvedRecipes": approved, "gaps": gaps}
    return result


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as handle:
        print(json.dumps(audit(json.load(handle)), indent=2))
