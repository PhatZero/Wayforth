#!/usr/bin/env python3
"""Fetch every ForeverDB profession and gathering page into a build-stamped snapshot.

Run in GitHub Actions with FOREVERDB_API_KEY. Never publish the key or guess
missing recipe fields. Raw snapshots require schema review before Lua conversion.
"""
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://foreverdb.net/api/v1"
PROFESSIONS = ("alchemy", "blacksmithing", "cooking", "enchanting",
               "engineering", "leatherworking", "tailoring", "herbalism",
               "mining", "skinning", "first-aid", "fishing")
GATHERING = ("herbalism", "mining", "skinning", "fishing")
LIMIT = 100


def get(path, params=None):
    key = os.environ.get("FOREVERDB_API_KEY")
    if not key:
        raise RuntimeError("FOREVERDB_API_KEY is not configured")
    url = BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    for attempt in range(5):
        request = urllib.request.Request(
            url, headers={"X-API-Key": key, "User-Agent": "WayForth-profession-import/1.0",
                          "Accept": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=40) as response:
                return json.load(response)
        except urllib.error.HTTPError as exc:
            if exc.code not in (429, 500, 502, 503, 504) or attempt == 4:
                raise RuntimeError("ForeverDB API request failed: HTTP %d (%s)" %
                                   (exc.code, path)) from None
            delay = exc.headers.get("Retry-After")
            time.sleep(min(120, int(delay)) if delay and delay.isdigit() else 2 ** attempt)
    raise RuntimeError("Request retry limit reached")


def records(payload):
    data = payload.get("data")
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for name in ("recipes", "results", "items"):
            if isinstance(data.get(name), list):
                return data[name]
    raise ValueError("Unrecognized ForeverDB list response; inspect schema before importing")


def next_page(payload, offset, count):
    meta = payload.get("meta") or {}
    nxt = meta.get("next")
    if nxt is None:
        total = meta.get("total")
        if isinstance(total, int):
            return offset + count if offset + count < total else None
        return offset + count if count == LIMIT else None
    if nxt is False or nxt == "":
        return None
    if isinstance(nxt, int):
        return nxt
    if isinstance(nxt, str):
        parsed = urllib.parse.urlparse(nxt)
        query = urllib.parse.parse_qs(parsed.query)
        if "offset" in query:
            return int(query["offset"][0])
    raise ValueError("Unrecognized pagination marker; refusing incomplete import")


def main():
    output = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/foreverdb")
    output.mkdir(parents=True, exist_ok=True)
    meta = get("/meta")
    (output / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    summary = {"professions": {}, "gathering": {}, "source": BASE}
    for slug in PROFESSIONS:
        offset, pages, seen = 0, [], set()
        while True:
            if offset in seen:
                raise RuntimeError("Repeated pagination offset for " + slug)
            seen.add(offset)
            page = get("/professions/" + slug, {"limit": LIMIT, "offset": offset})
            pages.append(page)
            batch = records(page)
            following = next_page(page, offset, len(batch))
            if following is None:
                break
            if following <= offset:
                raise RuntimeError("Non-advancing pagination for " + slug)
            offset = following
            time.sleep(2.1)  # below 30 requests/minute free-tier rate
        (output / (slug + ".json")).write_text(
            json.dumps({"pages": pages}, indent=2), encoding="utf-8")
        summary["professions"][slug] = {"pages": len(pages),
                                         "recipes": sum(len(records(p)) for p in pages)}
        print(slug + ": " + str(summary["professions"][slug]["recipes"]) + " records", flush=True)
    for slug in GATHERING:
        payload = get("/gathering/" + slug)
        (output / ("gathering-" + slug + ".json")).write_text(
            json.dumps(payload, indent=2), encoding="utf-8")
        summary["gathering"][slug] = "fetched"
        time.sleep(2.1)
    (output / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
