#!/usr/bin/env python3
"""Convert downloaded ForeverDB quest details into an offline Lua supplement.

Only WoW Forever-observed NPC/object coordinates are eligible for navigation.
This deliberately does not fabricate objective locations or quest order.
"""
import argparse
import json
from pathlib import Path


def lua_string(value):
    return json.dumps(str(value), ensure_ascii=True)


def point(actor):
    if not isinstance(actor, dict):
        return None
    location = actor.get("location")
    if not isinstance(location, dict) or location.get("source") != "seen in WoW Forever":
        return None
    try:
        map_id = int(location["uiMapId"])
        x, y = float(location["x"]), float(location["y"])
    except (KeyError, ValueError, TypeError):
        return None
    if map_id <= 0 or not 0 <= x <= 100 or not 0 <= y <= 100:
        return None
    parts = ["mapId=%d" % map_id, "x=%.3f" % x, "y=%.3f" % y,
             "source=" + lua_string("ForeverDB: seen in WoW Forever")]
    if actor.get("name"):
        parts.append("name=" + lua_string(actor["name"]))
    if actor.get("type"):
        parts.append("kind=" + lua_string(actor["type"]))
    if isinstance(actor.get("id"), int):
        parts.append("id=%d" % actor["id"])
    return "{" + ",".join(parts) + "}"


def build(input_dir, output):
    records = []
    for path in sorted((input_dir / "quest-details").glob("*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        record = payload.get("data")
        if not isinstance(record, dict) or not isinstance(record.get("id"), int):
            raise ValueError("Invalid quest detail: " + str(path))
        records.append(record)
    if not records:
        raise ValueError("No detailed quest records")
    if len({r["id"] for r in records}) != len(records):
        raise ValueError("Duplicate quest IDs")
    output.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "-- Generated from ForeverDB.net quest API. Attribution: https://foreverdb.net",
        "-- Only Forever-observed coordinates may be used for navigation.",
        "-- Not a verified optimized route. No objective waypoints are inferred.",
        "local _,ns=...",
        "ns.foreverDBQuests={",
    ]
    verified = 0
    for r in sorted(records, key=lambda r: r["id"]):
        fields = ["name=" + lua_string(r.get("name") or "Unknown"),
                  "source=" + lua_string(r.get("source") or "unknown")]
        for field, target in (("level", "level"), ("requiredLevel", "minLevel")):
            if isinstance(r.get(field), int):
                fields.append(target + "=" + str(r[field]))
        if r.get("side") in ("a", "h", "both"):
            fields.append("side=" + lua_string(r["side"]))
        zone = r.get("zone") or {}
        if isinstance(zone, dict) and zone.get("n"):
            fields.append("zone=" + lua_string(zone["n"]))
        for source, target in (("starts", "pickup"), ("ends", "turnin")):
            p = point(r.get(source))
            if p:
                fields.append(target + "={" + p + "}")
                verified += 1
        chain = r.get("chain") or {}
        previous = sorted({entry["questId"] for entry in (chain.get("previous") or [])
            if isinstance(entry, dict) and isinstance(entry.get("questId"), int)
            and entry.get("relation") == "Next quest"
            and entry.get("source") == "seen in WoW Forever"})
        if previous:
            fields.append("previous={" + ",".join(map(str, previous)) + "}")
        lines.append("  [%d]={%s}," % (r["id"], ",".join(fields)))
    lines += ["}", "-- Fill missing pickup/turn-in locations only; preserve authored guide locations.",
              "ns.foreverQuestLocations=ns.foreverQuestLocations or {}",
              "for id,q in pairs(ns.foreverDBQuests) do",
              "  local r=ns.foreverQuestLocations[id]",
              "  if not r then r={name=q.name};ns.foreverQuestLocations[id]=r end",
              "  if not r.name then r.name=q.name end",
              "  if not r.pickup and q.pickup then r.pickup=q.pickup end",
              "  if not r.turnin and q.turnin then r.turnin=q.turnin end",
              "end"]
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"quest_details": len(records), "forever_verified_location_phases": verified,
                      "output": str(output)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="build/foreverdb-quests")
    parser.add_argument("--output", default="clients/forever/guides/ForeverDBQuestData.lua")
    args = parser.parse_args()
    build(Path(args.input), Path(args.output))
