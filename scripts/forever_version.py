"""Select a Forever release version or stamp it into the CI checkout."""
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "clients/forever/manifest/WayForth.toc"
NAMESPACE = ROOT / "shared/core/Namespace.lua"
PREFIX = "forever-"
VERSION = r"[0-9]+\.[0-9]+b[1-9][0-9]*"


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).splitlines()


def select():
    ref = os.environ.get("GITHUB_REF", "")
    if ref.startswith("refs/tags/"):
        tag = ref.removeprefix("refs/tags/")
        if not re.fullmatch(PREFIX + VERSION, tag):
            raise ValueError(f"Invalid Forever beta tag: {tag}")
        return tag.removeprefix(PREFIX)

    series = re.search(r"^## Version: ([0-9]+\.[0-9]+)b[1-9][0-9]*$", TOC.read_text(), re.M)[1]
    pattern = PREFIX + re.escape(series) + r"b([1-9][0-9]*)"
    tags = git("tag", "--list", PREFIX + series + "b*")
    same_commit = set(git("tag", "--points-at", "HEAD"))
    numbers = {tag: int(m[1]) for tag in tags if (m := re.fullmatch(pattern, tag))}
    existing = [number for tag, number in numbers.items() if tag in same_commit]
    number = max(existing) if existing else max(numbers.values(), default=0) + 1
    return f"{series}b{number}"


def stamp(version):
    if not re.fullmatch(VERSION, version):
        raise ValueError(f"Invalid Forever beta version: {version}")
    for path, pattern, replacement in [
        (TOC, r"^## Version: .+$", f"## Version: {version}"),
        (NAMESPACE, r'^ns.version = "[^"]+"$', f'ns.version = "{version}"'),
    ]:
        updated, count = re.subn(pattern, replacement, path.read_text(), flags=re.M)
        if count != 1:
            raise ValueError(f"Expected one version field in {path}")
        path.write_text(updated)


if __name__ == "__main__":
    if sys.argv[1:] == ["select"]:
        print(select())
    elif len(sys.argv) == 3 and sys.argv[1] == "stamp":
        stamp(sys.argv[2])
    else:
        sys.exit("Expected select or stamp VERSION")
