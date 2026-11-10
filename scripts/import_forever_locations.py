#!/usr/bin/env python3
"""Refresh bundled quest endpoints from corrected Forever data and Wowhead maps.

Pass a QuestieDB checkout at QUESTIEDB_REF. Only factual IDs, names and points
are retained. The game client reads the generated Lua and performs no downloads.
"""
import argparse
import concurrent.futures
import json
import html
from pathlib import Path
import re
import subprocess
import tempfile
import time
import urllib.request
import urllib.error
from decimal import Decimal, ROUND_HALF_UP

ROOT = Path(__file__).resolve().parents[1]
QUESTIEDB_REF = "aca0da1c4a5ed0bc12997b9aaeef7b35af9ee26e"
ATT_REF = "d30715fb2657743d1b8801e5e3f26b96b7047160"
OUTPUT = ROOT / "clients/forever/guides/ForeverQuestLocations.lua"


def values(table):
    return [value for key, value in sorted((table or {}).items(), key=lambda item: int(item[0]))]


def field(table, key, default=None):
    return (table or {}).get(str(key), default)


def lua(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "{" + ", ".join(lua(item) for item in value) + "}"
    if isinstance(value, dict):
        return "{" + ", ".join(f"{key} = {lua(item)}" for key, item in value.items()) + "}"
    raise TypeError(value)


class Catalog:
    def __init__(self, data, source, att, reports):
        self.reports = reports
        self.npc_names = {}
        for npc_id, row in data["Npc"].items():
            self.npc_names.setdefault(field(row, 1), []).append(int(npc_id))
        self.att = att
        self.extra_entities = {}
        self.data = data
        text = (source / "support/Forever/Zones/areaIdToUiMapId.lua").read_text()
        text = text.split("ZoneDB.private.areaIdToUiMapId = [[return {")[1]
        self.maps = {int(area): int(map_id) for area, map_id in re.findall(r"\[(\d+)\] = (\d+)", text)}
        geometry = json.loads((source / "data/Forever/conversion.json").read_text())["geometry"]
        self.transforms = {row["area_id"]: row["coefficients"] for row in geometry["transforms"]
                           if row["area_transform_supported"]}
        classic_source = (source / "data/Classic/classicQuestDB.lua").read_text()
        self.classic_ids = {int(quest_id) for quest_id in re.findall(r"^\[(\d+)\] =", classic_source, re.M)}
        self.names = {int(map_id): name.strip().split(" -> ")[-1]
                      for area, map_id, name in re.findall(r"\[(\d+)\] = (\d+), -- ([^\n]+)", text)}

    def points(self, spawns, kind, entity_id=None, name=None, source="QuestieDB"):
        result = []
        for area, positions in sorted((spawns or {}).items(), key=lambda item: int(item[0])):
            map_id = self.maps.get(int(area))
            if not map_id:
                continue
            for xy in values(positions):
                x, y = field(xy, 1), field(xy, 2)
                if isinstance(x, (int, float)) and isinstance(y, (int, float)) and 0 < x < 100 and 0 < y < 100:
                    point = dict(mapId=map_id, x=x, y=y, kind=kind)
                    if entity_id:
                        point["id"] = entity_id
                    if name:
                        point["name"] = name
                    if source != "QuestieDB":
                        point["source"] = source
                    result.append(point)
                    break  # An actual recorded spawn, never an average of distant locations.
        return result

    def att_points(self, coordinates, kind, entity_id=None):
        result = []
        for map_id, positions in (coordinates or {}).items():
            if int(map_id) not in self.names:
                continue
            for xy in values(positions):
                x, y = field(xy, 1), field(xy, 2)
                if isinstance(x, (int, float)) and isinstance(y, (int, float)) and 0 < x < 100 and 0 < y < 100:
                    point = dict(mapId=int(map_id), x=x, y=y, kind=kind, source="ATT")
                    if entity_id:
                        point["id"] = entity_id
                    result.append(point)
                    break
        return result

    def index_att(self):
        for npc_id, npc in sorted(self.att.get("npcs", {}).items(), key=lambda item: int(item[0])):
            self.extra_entities[("Npc", int(npc_id))] = self.att_points(npc.get("coords"), "npc", int(npc_id))
        for _, quest in sorted(self.att.get("quests", {}).items(), key=lambda item: int(item[0])):
            for npc_id in values(quest.get("qgs")):
                self.extra_entities.setdefault(("Npc", npc_id), []).extend(self.att_points(quest.get("coords"), "npc", npc_id))

    def entity(self, kind, entity_id):
        row = self.data[kind].get(str(entity_id), {})
        points = self.points(field(row, 7 if kind == "Npc" else 4), kind.lower(), entity_id, field(row, 1))
        if not points:
            points = [dict(point) for point in self.extra_entities.get((kind, entity_id), [])]
            for point in points:
                if field(row, 1):
                    point["name"] = field(row, 1)
        faction_code = field(row, 13) if kind == "Npc" else None
        faction = {"A": "Alliance", "H": "Horde"}.get(faction_code) if isinstance(faction_code, str) else None
        if faction:
            for point in points:
                point["faction"] = faction
        return points

    def item(self, item_id, seen=None):
        seen = set() if seen is None else seen
        if item_id in seen:
            return []
        seen.add(item_id)
        row = self.data["Item"].get(str(item_id), {})
        result = []
        for key, kind in ((2, "Npc"), (3, "Object")):
            for entity_id in values(field(row, key)):
                for point in self.entity(kind, entity_id):
                    point["kind"] = "loot"
                    point.pop("faction", None)
                    point["itemId"] = item_id
                    result.append(point)
        for container in values(field(row, 4)):
            result.extend(self.item(container, seen))
        if not result:
            for vendor in values(field(row, 14)):
                for point in self.entity("Npc", vendor):
                    point["kind"] = "vendor"
                    point["itemId"] = item_id
                    result.append(point)
        if not result:
            for quest_id in values(field(row, 6)):
                quest = self.data["Quest"].get(str(quest_id), {})
                for point in self.endpoint(quest, 3):
                    point["kind"] = "reward"
                    point["requiredQuest"] = quest_id
                    result.append(point)
        return result

    def endpoint(self, quest, key):
        result = []
        for index, kind in ((1, "Npc"), (2, "Object")):
            for entity_id in values(field(field(quest, key), index)):
                result.extend(self.entity(kind, entity_id))
        if key == 2:
            for item_id in values(field(field(quest, key), 3)):
                result.extend(self.item(item_id))
        return result

    def objectives(self, quest):
        result = []
        objectives = field(quest, 10, {})
        for key, kind in ((1, "Npc"), (2, "Object")):
            for row in values(field(objectives, key)):
                result.extend(self.entity(kind, field(row, 1)))
        for row in values(field(objectives, 3)):
            result.extend(self.item(field(row, 1)))
        for row in values(field(objectives, 5)):
            for entity_id in values(field(row, 1)):
                result.extend(self.entity("Npc", entity_id))
        for point in result:
            if point["kind"] == "npc":
                point["kind"] = "target"
                point.pop("faction", None)
        result.extend(self.points(field(field(quest, 9), 2), "event"))
        for row in values(field(quest, 29)):
            result.extend(self.points(field(row, 1), "event"))
        return result

    def record(self, quest_id):
        quest = self.data["Quest"].get(str(quest_id), {})
        record = {}
        if str(quest_id) in self.att.get("hiddenQuests", {}):
            record["hidden"] = True
        mask = field(quest, 6, 0)
        if isinstance(mask, int) and mask:
            alliance, horde = bool(mask & 4294967373), bool(mask & 8589934770)
            if alliance != horde:
                record["faction"] = "Alliance" if alliance else "Horde"
        for name, points in (("pickup", self.endpoint(quest, 2)),
                             ("objective", self.objectives(quest)),
                             ("turnin", self.endpoint(quest, 3))):
            if points:
                record[name] = self.unique(points)
        if field(quest, 10) or field(quest, 9) or field(quest, 29):
            record["hasObjective"] = True
        att_quest = self.att.get("quests", {}).get(str(quest_id), {})
        if not record.get("pickup"):
            points = self.att_points(att_quest.get("coords"), "pickup")
            if points:
                record["pickup"] = points
        for objective in values(att_quest.get("objectives")):
            record["hasObjective"] = True
            points = self.att_points(objective.get("coords"), "area")
            if not points:
                for npc_id in values(objective.get("crs")):
                    points.extend(self.entity("Npc", npc_id))
                for provider in values(objective.get("providers")):
                    kind, entity_id = field(provider, 1), field(provider, 2)
                    if kind in ("n", "o"):
                        points.extend(self.entity("Npc" if kind == "n" else "Object", entity_id))
                    elif kind == "i":
                        points.extend(self.item(entity_id))
            if points and not record.get("objective"):
                for point in points:
                    if point["kind"] == "npc":
                        point["kind"] = "target"
                        point.pop("faction", None)
                record["objective"] = self.unique(points)
        report = self.reports.get(str(quest_id), {}).get("facts", {})
        for role, label in (("pickup", "Giver"), ("turnin", "Turned in to")):
            if record.get(role) or not report.get(label):
                continue
            name = report[label]
            record[role + "Name"] = name
            candidates = self.npc_names.get(name, [])
            if len(candidates) == 1:
                points = self.entity("Npc", candidates[0])
                for point in points:
                    point["source"] = "AHledger / " + point.get("source", "QuestieDB")
                if points:
                    record[role] = points
        starter_items = values(field(field(quest, 2), 3))
        if starter_items:
            record["startItem"] = starter_items[0]
        return record

    @staticmethod
    def unique(points):
        result, seen = [], set()
        for point in points:
            key = (point["mapId"], point["kind"], point.get("id"), point["x"], point["y"])
            if key not in seen:
                seen.add(key)
                result.append(point)
        return result

    def index_maps(self, facts):
        # An explicit entity ID can locate the same NPC/object for another quest.
        for fact in facts:
            phases = {}
            self.supplement(phases, fact)
            for role in ("pickup", "objective", "turnin"):
                for point in phases.get(role, []):
                    entity_type = point.get("entityType", point["kind"])
                    kind = {"npc": "Npc", "object": "Object"}.get(entity_type)
                    if kind:
                        copy = dict(point, kind=entity_type)
                        self.extra_entities.setdefault((kind, point["id"]), []).append(copy)
        for key, points in self.extra_entities.items():
            self.extra_entities[key] = self.unique(points)

    def classic_point(self, area_id, xy):
        transform = self.transforms.get(area_id)
        if not transform:
            return None
        x = xy[0] * transform["scale_x"] + transform["offset_x"]
        y = xy[1] * transform["scale_y"] + transform["offset_y"]
        return [float(Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
                for value in (x, y)]

    def matches_classic(self, fact):
        quest_id = str(fact["questId"])
        expected = field(self.data["Quest"].get(quest_id), 1) or self.data.get("guideNames", {}).get(quest_id)
        def normalize(name):
            name = re.sub(r"\s*\(\d+/\d+\)\s*", " ", name or "")
            return re.sub(r"[^a-z0-9]", "", name.lower())
        return bool(expected and fact.get("questName") and normalize(expected) == normalize(fact["questName"]))

    def supplement(self, record, fact):
        classic = fact.get("flavor") == "classic"
        if classic and not self.matches_classic(fact):
            return
        quest = self.data["Quest"].get(str(fact["questId"]), {})
        roles = {"start": "pickup", "end": "turnin", "requirement": "objective", "sourcerequirement": "objective"}
        additions = {}
        for area, zone in fact.get("mapper", {}).get("objectives", {}).items():
            map_id = self.maps.get(int(area))
            if not map_id:
                continue
            self.names[map_id] = zone["zone"]
            # Dungeon floor coordinates use a different frame from outdoor maps.
            levels = zone.get("levels", [])
            if len(levels) > 1:
                continue
            for level in levels:
                for entry in level:
                    role = roles.get(entry.get("point"))
                    xy = entry.get("coord")
                    if not role or not xy or not (0 < xy[0] < 100 and 0 < xy[1] < 100):
                        continue
                    if classic:
                        # Known endpoints must retain the Forever NPC/object ID.
                        endpoint_key = {"pickup": 2, "turnin": 3}.get(role)
                        if endpoint_key:
                            entities = field(field(quest, endpoint_key), 1 if entry.get("type") == 1 else 2)
                            if entities and entry["id"] not in values(entities):
                                continue
                        xy = self.classic_point(int(area), xy)
                        if not xy or not (0 < xy[0] < 100 and 0 < xy[1] < 100):
                            continue
                    point = dict(mapId=map_id, x=xy[0], y=xy[1],
                                 kind="npc" if entry.get("type") == 1 else "object",
                                 id=entry["id"], name=entry["name"], source="Wowhead Classic" if classic else "Wowhead Forever")
                    if entry.get("item"):
                        point["entityType"] = point["kind"]
                        point["kind"] = "loot"
                    alliance = entry.get("reactalliance", 0) > 0
                    horde = entry.get("reacthorde", 0) > 0
                    if alliance != horde and role != "objective" and point["kind"] != "loot":
                        point["faction"] = "Alliance" if alliance else "Horde"
                    additions.setdefault(role, []).append(point)
        for role, points in additions.items():
            if not record.get(role):
                record[role] = self.unique(points)
        if additions.get("objective"):
            record["hasObjective"] = True


def fetch_map(quest_id, cache, flavor="forever"):
    directory = cache / flavor
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{quest_id}.json"
    if path.exists():
        return json.loads(path.read_text())
    legacy = cache / f"{quest_id}.json"
    if flavor == "forever" and legacy.exists():
        return json.loads(legacy.read_text())
    url = f"https://www.wowhead.com/{flavor}/quest={quest_id}"
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "WayForth-data-audit/1.0"})
            with urllib.request.urlopen(request, timeout=25) as response:
                page = response.read().decode("utf-8")
            match = re.search(r"new Mapper\((\{[^\n]+\})\)", page)
            title = re.search(r"<title>(.*?) - Quest -", page)
            fact = dict(questId=quest_id, flavor=flavor, questName=html.unescape(title.group(1)) if title else None,
                        source=url, mapper=json.loads(match.group(1)) if match else {})
            path.write_text(json.dumps(fact, ensure_ascii=False))
            return fact
        except urllib.error.HTTPError as error:
            if error.code == 404:
                fact = dict(questId=quest_id, flavor=flavor, source=url, mapper={}, status=404)
                path.write_text(json.dumps(fact))
                return fact
            if error.code in (401, 403, 429) or attempt == 2:
                raise
            time.sleep(attempt + 1)
        except (OSError, ValueError):
            if attempt == 2:
                raise
            time.sleep(attempt + 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("questiedb", type=Path)
    parser.add_argument("--reports", type=Path, default=ROOT / "scripts/data/forever_quest_reports.json", help="JSON file or directory of player-recorded giver/finisher facts")
    parser.add_argument("--att", type=Path, required=True)
    parser.add_argument("--cache", type=Path, required=True)
    parser.add_argument("--cached-only", action="store_true", help="Use cached supplemental facts without downloading")
    args = parser.parse_args()
    source = args.questiedb.resolve()
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    if revision != QUESTIEDB_REF:
        raise SystemExit(f"Expected QuestieDB {QUESTIEDB_REF}, got {revision}")
    args.cache.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        exported = Path(temporary) / "facts.json"
        subprocess.run([str(source / "tools/lua-binary/linux-x64/lua"),
                        str(ROOT / "scripts/export_forever_locations.lua"), str(ROOT), str(exported)],
                       cwd=source, check=True)
        data = json.loads(exported.read_text())
        att_source = args.att.resolve()
        att_revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=att_source, text=True).strip()
        if att_revision != ATT_REF:
            raise SystemExit(f"Expected AllTheThings {ATT_REF}, got {att_revision}")
        subprocess.run([str(source / "tools/lua-binary/linux-x64/lua"),
                        str(ROOT / "scripts/export_att_locations.lua"), str(att_source), str(exported)],
                       cwd=source, check=True)
        att = json.loads(exported.read_text())
    reports = {}
    if args.reports:
        if args.reports.is_dir():
            facts = [json.loads(path.read_text()) for path in sorted(args.reports.glob("*.json"))]
        else:
            facts = json.loads(args.reports.read_text())
        for fact in facts:
            reports[str(fact["questId"])] = fact
    catalog = Catalog(data, source, att, reports)
    catalog.index_att()
    facts = []
    for filename in ("forever_quest_maps.json", "classic_quest_maps.json"):
        facts.extend(json.loads((ROOT / "scripts/data" / filename).read_text()))
    catalog.index_maps(facts)
    records = {int(quest_id): catalog.record(quest_id) for quest_id in data["wanted"]}
    for fact in facts:
        catalog.supplement(records[fact["questId"]], fact)
    needed = [quest_id for quest_id, record in records.items()
              if not record.get("pickup") or not record.get("turnin")
              or record.get("hasObjective") and not record.get("objective")]
    for flavor in ("forever", "classic"):
        requested = needed if flavor == "forever" else [q for q in needed if q in catalog.classic_ids]
        if args.cached_only:
            requested = [q for q in requested if (args.cache / flavor / f"{q}.json").exists()
                         or flavor == "forever" and (args.cache / f"{q}.json").exists()]
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            facts = pool.map(lambda q: fetch_map(q, args.cache, flavor), sorted(requested))
            for fact in facts:
                catalog.supplement(records[fact["questId"]], fact)
    lines = ["-- Generated by scripts/import_forever_locations.py. Coordinates are map percentages.",
             f"-- Questie/QuestieDB {QUESTIEDB_REF}, corrected Forever facts; supplemental Wowhead Forever and Classic maps.",
             f"-- AllTheThings {ATT_REF}, compiled Forever quest/NPC facts.",
             "-- AHledger player-recorded quest giver/finisher names supplement missing relationships.",
             "-- Source records require live-client verification. Authored route locations take priority.",
             "local _, ns = ...", "ns.foreverLocationMaps = {"]
    used_maps = {point["mapId"] for record in records.values()
                 for role in ("pickup", "objective", "turnin") for point in record.get(role, [])}
    for map_id in sorted(used_maps):
        lines.append(f"    [{map_id}] = {lua(catalog.names[map_id])},")
    lines.extend(["}", "ns.foreverQuestLocations = {"])
    for quest_id, record in sorted(records.items()):
        lines.append(f"    [{quest_id}] = {{")
        for key, value in record.items():
            if isinstance(value, list):
                lines.append(f"        {key} = {{")
                lines.extend(f"            {lua(point)}," for point in value)
                lines.append("        },")
            else:
                lines.append(f"        {key} = {lua(value)},")
        lines.append("    },")
    lines.append("}\n")
    OUTPUT.write_text("\n".join(lines))
    print(f"Wrote {len(records)} quest records to {OUTPUT}")
    for role in ("pickup", "objective", "turnin"):
        missing = [str(q) for q, row in records.items() if not row.get(role)
                   and (role != "objective" or row.get("hasObjective"))]
        print(f"{role}: {len(missing)} unresolved IDs: {', '.join(sorted(missing, key=int))}")


if __name__ == "__main__":
    main()
