#!/usr/bin/env python3
"""Compile downloaded ForeverDB build-stamped recipe records into offline Lua.

Only client-verified orange, and client-reported yellow-to-green thresholds,
are eligible. Classic-derived orange values are never treated as guaranteed.
unlearnable/unknown recipes, and speculative records are never promoted.
No API key or player data is packaged in the addon.
"""
import json
import pathlib
import sys

CRAFTING = ("alchemy", "blacksmithing", "cooking", "enchanting", "engineering",
            "first-aid", "leatherworking", "tailoring")
GATHERING = ("fishing", "herbalism", "mining", "skinning")
SOURCE_WAYS = ("auto", "trainer", "vendor", "quest", "drop")
WAY_NAMES = {"auto": "Automatically learned", "trainer": "Trainer",
             "vendor": "Vendor recipe", "quest": "Quest recipe", "drop": "Drop recipe"}


def lua_str(value):
    value = str(value)
    value = value.replace("\\", "\\\\").replace('"', '\\"')
    value = value.replace("\r", "\\r").replace("\n", "\\n").replace("\t", "\\t")
    return '"' + value + '"'


def rows(snapshot, slug, build):
    pages = json.loads((snapshot / (slug + ".json")).read_text(encoding="utf-8"))["pages"]
    collected = []
    for page in pages:
        if page.get("meta", {}).get("build") != build:
            raise ValueError("Mixed client builds in " + slug)
        data = page.get("data") or {}
        if data.get("slug") != slug or not isinstance(data.get("recipes"), list):
            raise ValueError("Unexpected ForeverDB recipe schema for " + slug)
        collected.extend(data["recipes"])
    if not pages or len(collected) != pages[0].get("meta", {}).get("total"):
        raise ValueError("Incomplete source pagination for " + slug)
    return collected


def recipe_line(r, build):
    skill = r.get("skill") or {}
    origin, stop, green = skill.get("orange"), skill.get("yellow"), skill.get("green")
    learned = r.get("learnedFrom") or {}
    acquisition = learned.get("sources") or {}
    learn_at = acquisition.get("learnAtSkill")
    ways = acquisition.get("ways") or []
    reagents = r.get("reagents") or []
    client_orange = (
        skill.get("orangeSource") == "client"
        and isinstance(origin, int) and isinstance(stop, int)
        and 1 <= origin < stop
    )
    # ForeverDB explicitly marks orangeSource="classic" for orange breakpoints
    # inferred from Classic trainer data. Yellow and green thresholds are from
    # the Forever client. Import those as YELLOW-ONLY: never claim the
    # uncorroborated Classic orange range is guaranteed.
    client_yellow = (
        skill.get("orangeSource") in ("client", "classic")
        and isinstance(stop, int) and isinstance(green, int)
        and 1 <= stop < green <= 450
    )
    if (r.get("speculation") or not (client_orange or client_yellow)
        or not isinstance(learn_at, int) or learn_at < 1
        or learn_at > (origin if client_orange else stop)
        or not isinstance(r.get("spellId"), int)
        or not isinstance(r.get("name"), str)
        or not isinstance(r.get("url"), str)
        or not r["url"].startswith("https://foreverdb.net/spell/")
        or not any(w in SOURCE_WAYS for w in ways) or not reagents):
        return None
    if any(not isinstance(x, dict) or not isinstance(x.get("itemId"), int)
           or not isinstance(x.get("name"), str)
           or not isinstance(x.get("count"), int) or x["count"] < 1
           for x in reagents):
        return None
    orange_start = origin if client_orange else stop
    orange_stop = stop
    parts = ["name=" + lua_str(r["name"]), "spellId=" + str(r["spellId"]),
             "orangeFrom=" + str(orange_start), "orangeUntil=" + str(orange_stop),
             "learnAt=" + str(learn_at)]
    if not client_orange:
        parts.append("yellowOnly=true")
    if client_yellow:
        parts.append("yellowUntil=" + str(green))
    output = r.get("makes") or {}
    if isinstance(output.get("itemId"), int) and isinstance(output.get("count"), int) and output["count"] > 0:
        parts.extend(["outputItemId=" + str(output["itemId"]), "yield=" + str(output["count"])])
    method = next(w for w in SOURCE_WAYS if w in ways)
    acquisition_description = WAY_NAMES[method]
    if skill.get("orangeSource") == "classic" and method == "trainer":
        acquisition_description += " (Forever availability must be checked)"
    parts.extend(["source=" + lua_str(r["url"]),
                  "acquisition=" + lua_str(acquisition_description),
                  "sourcePriority=" + str(SOURCE_WAYS.index(method)),
                  "provenance={client=\"forever\",verified=true,url=" + lua_str(r["url"])
                  + ",checkedBuild=" + lua_str(build)
                  + ",orangeSource=" + lua_str(skill.get("orangeSource", "unknown"))
                  + ",yellowSource=" + lua_str("forever-client" if client_yellow else "none")
                  + "}"])
    reags = ["{itemId=%d,name=%s,count=%d}" % (x["itemId"], lua_str(x["name"]), x["count"])
             for x in reagents]
    parts.append("reagents={" + ",".join(reags) + "}")
    return "    {" + ",".join(parts) + "},"


def gaps(recipes, cap=300, include_yellow=False):
    covered = [False] * (cap + 1)
    for r in recipes:
        skill = r["skill"]
        learn = r["learnedFrom"]["sources"]["learnAtSkill"]
        orange, yellow, green = skill.get("orange"), skill.get("yellow"), skill.get("green")
        if (skill.get("orangeSource") == "client"
                and isinstance(orange, int) and isinstance(yellow, int)
                and orange < yellow):
            for n in range(max(1, orange, learn), min(cap + 1, yellow)):
                covered[n] = True
        if (include_yellow and isinstance(yellow, int)
                and isinstance(green, int) and green > yellow):
            for n in range(max(1, yellow, learn), min(cap + 1, green)):
                covered[n] = True
    ranges, opened = [], None
    for n in range(1, cap + 2):
        missing = n <= cap and not covered[n]
        if missing and opened is None:
            opened = n
        if not missing and opened is not None:
            ranges.append([opened, n - 1])
            opened = None
    return ranges


def gathering_lines(snapshot, slug):
    data = json.loads((snapshot / ("gathering-" + slug + ".json")).read_text(encoding="utf-8"))["data"]
    if data.get("profession") != slug:
        raise ValueError("Unexpected gathering source for " + slug)
    zones = {z["mapId"]: z for z in data.get("zones", []) if isinstance(z.get("mapId"), int)}
    entries = []
    for band in data.get("bestZones", []):
        first, last = band.get("fromSkill"), band.get("toSkill")
        if not isinstance(first, int) or not isinstance(last, int) or last < first:
            continue
        for choice in band.get("zones", []):
            zone = zones.get(choice.get("mapId"))
            if not zone:
                continue
            # Spawn distribution is partially Classic. An observed Forever
            # visit is evidence for the zone, not proof of each node location.
            verified = slug in ("mining", "herbalism") and (zone.get("spotsSeenInForever") or 0) > 0
            entries.append({"skillFrom": max(1, first), "skillUntil": last + 1,
                            "zone": zone["name"], "mapId": zone["mapId"],
                            "verified": verified,
                            "text": ("Forever-observed gathering zone candidate." if verified else
                                     "Candidate zone from Classic distribution; check in Forever.")})
    if slug == "fishing":
        for zone in data.get("zones", []):
            if not isinstance(zone.get("mapId"), int):
                continue
            start = zone.get("skill")
            if not isinstance(start, int):
                continue
            observed = (zone.get("castsInForever") or 0) > 0
            entries.append({"skillFrom": max(1, start), "skillUntil": 301,
                            "zone": zone["name"], "mapId": zone["mapId"],
                            "verified": observed,
                            "text": ("Players caught fish here in Forever." if observed else
                                     "Fishing-zone data is from Classic; verify before traveling.")})
    entries.sort(key=lambda e: (e["skillFrom"], not e["verified"], e["zone"]))
    lines = []
    for entry in entries:
        lines.append("    {client=\"forever\",skillFrom=%d,skillUntil=%d,mapId=%d,zone=%s,verified=%s,instructions=%s}," %
                     (entry["skillFrom"], entry["skillUntil"], entry["mapId"],
                      lua_str(entry["zone"]), "true" if entry["verified"] else "false",
                      lua_str(entry["text"])))
    return lines, entries


def main():
    snapshot = pathlib.Path(sys.argv[1])
    destination = pathlib.Path(sys.argv[2])
    coverage = pathlib.Path(sys.argv[3])
    meta = json.loads((snapshot / "meta.json").read_text(encoding="utf-8"))
    build = (meta.get("data") or {}).get("build")
    if not isinstance(build, str) or not build.startswith("1.60.1."):
        raise ValueError("A supported Forever client build is required")
    result = {"client": "forever", "build": build, "professions": {}}
    out = ["-- Generated from ForeverDB.net build " + build,
           "-- Data from ForeverDB.net (https://foreverdb.net).",
           "-- Client-verified orange; client-reported yellow including Classic-orange rows.",
           "-- No API key, assumed recipe or guessed waypoint is included.",
           "local _,ns=...", "ns.professionRecipeCatalog=ns.professionRecipeCatalog or {}"]
    for slug in CRAFTING:
        records = rows(snapshot, slug, build)
        admitted = []
        rendered = []
        for record in records:
            line = recipe_line(record, build)
            if line:
                admitted.append(record)
                rendered.append(line)
        out.append("ns.professionRecipeCatalog[" + lua_str(slug) + "]={")
        out.extend(rendered)
        out.append("}")
        result["professions"][slug] = {
            "sourceRecipes": len(records), "verifiedOrangeRecipes": sum(r["skill"].get("orangeSource")=="client"\n                and isinstance(r["skill"].get("orange"), int)\n                and r["skill"]["orange"]<r["skill"]["yellow"] for r in admitted),\n            "clientYellowRecovered": sum(r["skill"].get("orangeSource")=="classic"\n                and isinstance(r["skill"].get("green"), int)\n                and r["skill"]["green"]>r["skill"]["yellow"] for r in admitted),
            "verifiedYellowRecipes": sum(isinstance(r["skill"].get("green"),int)
                and r["skill"]["green"]>r["skill"]["yellow"] for r in admitted),
            "missingOrangeBands": gaps(admitted),
            "missingOrangeOrYellowBands": gaps(admitted,include_yellow=True)}
    out.append("ns.professionGatheringCatalog=ns.professionGatheringCatalog or {}")
    for slug in GATHERING:
        rendered, entries = gathering_lines(snapshot, slug)
        out.append("ns.professionGatheringCatalog[" + lua_str(slug) + "]={")
        out.extend(rendered)
        out.append("}")
        result["professions"][slug] = {
            "candidateZones": len(entries), "foreverObservedZones":
                sum(bool(e["verified"]) for e in entries)}
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(out) + "\n", encoding="utf-8")
    coverage.parent.mkdir(parents=True, exist_ok=True)
    coverage.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2), flush=True)


if __name__ == "__main__":
    main()
