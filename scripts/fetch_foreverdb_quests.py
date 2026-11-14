#!/usr/bin/env python3
"""Import ForeverDB's WoW Forever quest index and optional quest details.

No credentials or downloaded records are committed. A GitHub Actions artifact
contains the raw source snapshots and an audit manifest for offline guide work.
The free API tier has 5,000 requests/day across an account, so detail downloads
are bounded and support resuming from a prior artifact's extracted directory.
"""
import argparse
import json
import os
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://foreverdb.net/api/v1"
LIMIT = 100


def rows(payload):
    data = payload.get("data")
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("quests", "zones", "results", "items"):
            if isinstance(data.get(key), list):
                return data[key]
    raise ValueError("Unrecognized list response; do not assume an empty page")


def get_next(payload, offset, length):
    meta = payload.get("meta") or {}
    nxt = meta.get("next")
    if nxt is False or nxt == "":
        return None
    if isinstance(nxt, int):
        return nxt
    if isinstance(nxt, str):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(nxt).query)
        if "offset" in query:
            return int(query["offset"][0])
        raise ValueError("Unrecognized next-page URL")
    total = meta.get("total")
    if isinstance(total, int):
        return offset + length if offset + length < total else None
    return offset + length if length == LIMIT else None


class Client:
    def __init__(self, key, delay=2.1):
        if not key:
            raise ValueError("FOREVERDB_API_KEY is missing")
        self.key, self.delay, self.calls = key, delay, 0

    def fetch(self, path, params=None):
        url = BASE + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        request = urllib.request.Request(
            url, headers={"X-API-Key": self.key,
                          "User-Agent": "WayForth-quest-data-import/1.0",
                          "Accept": "application/json"})
        for attempt in range(5):
            if self.calls:
                time.sleep(self.delay)
            self.calls += 1
            try:
                with urllib.request.urlopen(request, timeout=45) as response:
                    return json.load(response)
            except urllib.error.HTTPError as exc:
                if exc.code not in (429, 500, 502, 503, 504) or attempt == 4:
                    raise RuntimeError("ForeverDB HTTP %d on %s" % (exc.code, path)) from None
                retry = exc.headers.get("Retry-After")
                time.sleep(min(120, int(retry)) if retry and retry.isdigit() else 2 ** attempt)
        raise RuntimeError("Retry limit exceeded")


def paginate(client, path, destination):
    destination.mkdir(parents=True, exist_ok=True)
    offset, seen, count = 0, set(), 0
    while True:
        if offset in seen:
            raise RuntimeError("Repeated pagination offset at " + path)
        seen.add(offset)
        file = destination / ("%08d.json" % offset)
        if file.exists():
            payload = json.loads(file.read_text(encoding="utf-8"))
        else:
            payload = client.fetch(path, {"limit": LIMIT, "offset": offset})
            file.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        batch = rows(payload)
        count += len(batch)
        following = get_next(payload, offset, len(batch))
        if following is None:
            return count
        if following <= offset:
            raise RuntimeError("Pagination did not advance at " + path)
        offset = following


def quest_ids(folder):
    ids = set()
    for file in sorted(folder.glob("*.json")):
        for quest in rows(json.loads(file.read_text(encoding="utf-8"))):
            value = quest.get("questId", quest.get("id"))
            if isinstance(value, int) and value > 0:
                ids.add(value)
            elif isinstance(value, str) and value.isdigit():
                ids.add(int(value))
            else:
                raise ValueError("Quest index row missing numeric ID: " + str(quest)[:120])
    return sorted(ids)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="build/foreverdb-quests")
    parser.add_argument("--details-limit", type=int, default=0,
                        help="Maximum detail requests this run (0 = index only)")
    args = parser.parse_args()
    if args.details_limit < 0 or args.details_limit > 4000:
        parser.error("--details-limit must be between 0 and 4000")
    out = Path(args.output)
    out.mkdir(parents=True, exist_ok=True)
    client = Client(os.environ.get("FOREVERDB_API_KEY"))
    meta_file = out / "meta.json"
    if not meta_file.exists():
        meta_file.write_text(json.dumps(client.fetch("/meta"), indent=2), encoding="utf-8")
    count = paginate(client, "/quests", out / "quest-pages")
    zones = paginate(client, "/zones", out / "zone-pages")
    ids = quest_ids(out / "quest-pages")
    details = out / "quest-details"
    details.mkdir(exist_ok=True)
    fetched = 0
    for quest_id in ids:
        file = details / ("%d.json" % quest_id)
        if file.exists():
            continue
        if fetched >= args.details_limit:
            break
        payload = client.fetch("/quests/%d" % quest_id)
        if not isinstance(payload.get("data"), dict):
            raise ValueError("Quest detail %d lacks object data" % quest_id)
        file.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        fetched += 1
        if fetched % 100 == 0:
            print("Fetched %d quest details" % fetched, flush=True)
    available = sum(1 for quest_id in ids if (details / ("%d.json" % quest_id)).exists())
    summary = {
        "source": BASE, "quest_index_rows": count, "unique_quest_ids": len(ids),
        "zones": zones, "detail_records": available, "details_fetched_this_run": fetched,
        "remaining_details": len(ids) - available, "requests_this_run": client.calls,
        "status": "details_complete" if available == len(ids) else "partial_details",
        "note": "Source data includes unconfirmed Classic locations. Audit provenance before navigation."
    }
    (out / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == "__main__":
    main()
