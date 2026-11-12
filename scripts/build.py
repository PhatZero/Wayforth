#!/usr/bin/env python3
"""Validate the addon manifest and package an installable WayForth ZIP."""
from pathlib import Path
import re
import zipfile
import base64
import zlib
from navigation_art import navigation_arrow_texture

ROOT = Path(__file__).resolve().parents[1]
FOREVER = ROOT / "clients" / "forever"
SHARED = ROOT / "shared"
DIST = ROOT / "dist"
TOC = FOREVER / "manifest" / "WayForth.toc"
VALID_MODULES = {"Core", "Data", "UI"}
BRAND_SOURCE = SHARED / "artwork" / "WayForthCompass.tga.b85"
BRAND_PATH = "WayForth/Textures/WayForthCompass.tga"
ART_SOURCE = SHARED / "artwork" / "WayForthArtAtlas.tga.b85"
ART_PATH = "WayForth/Textures/WayForthArtAtlas.tga"
ARROW_PATH = "WayForth/Textures/WayForthArrow.tga"


def brand_texture():
    """Unpack the approved original compass into a client-safe 32-bit RGBA TGA.

    Source is stored as zlib+base85 text because GitHub's text-only contents
    upload keeps this asset reviewable and reproducible without binary tools.
    """
    compressed = base64.b85decode(BRAND_SOURCE.read_text(encoding="ascii").strip())
    data = zlib.decompress(compressed)
    assert len(data) > 18, "Empty compass texture"
    assert data[2] == 10, "Compass must use RLE truecolor TGA"
    assert int.from_bytes(data[12:14], "little") == 64
    assert int.from_bytes(data[14:16], "little") == 64
    assert data[16] == 32, "Compass needs an alpha channel"
    return data



def illustrated_art():
    """Bundled 512x128 original illustrated guide artwork, with alpha, RLE TGA."""
    blob = zlib.decompress(base64.b85decode(ART_SOURCE.read_text(encoding="ascii").strip()))
    assert len(blob) > 18 and blob[2] == 10, "Art atlas must be RLE truecolor TGA"
    assert int.from_bytes(blob[12:14], "little") == 512
    assert int.from_bytes(blob[14:16], "little") == 128
    assert blob[16] == 32, "Art atlas needs alpha channel"
    return blob


def source_path(item):
    module, name = Path(item).parts
    overrides = {
        "Core/Compatibility.lua": FOREVER / "api",
        "UI/Tracker.lua": SHARED / "tracker",
        "UI/QuestItemButton.lua": SHARED / "tracker",
        "UI/Navigator.lua": SHARED / "navigation",
    }
    directories = {"Data": FOREVER / "guides", "UI": SHARED / "ui", "Core": SHARED / "core"}
    return overrides.get(item, directories[module]) / name


def manifest():
    text = TOC.read_text(encoding="utf-8-sig")
    assert re.search(r"^## Interface: 16001\s*$", text, re.M), "Forever interface must be 16001"
    assert re.search(r"^## Version: [0-9]+\.[0-9]+b[1-9][0-9]*\s*$", text, re.M), "Version must match package"
    assert "## SavedVariables: WoWForeverDB" in text
    assert "## SavedVariablesPerCharacter: WoWForeverCharDB" in text
    scripts = [line.strip().replace("\\", "/") for line in text.splitlines()
               if line.strip() and not line.startswith("#")]
    assert scripts, "No Lua scripts registered"
    assert len(set(scripts)) == len(scripts), "TOC has duplicate paths"
    for item in scripts:
        path = Path(item)
        assert path.parts[0] in VALID_MODULES and path.suffix == ".lua", f"Invalid entry {item}"
        assert ".." not in path.parts and source_path(item).is_file(), f"Missing module {item}"
    return scripts


def build():
    scripts = manifest()
    DIST.mkdir(parents=True, exist_ok=True)
    version = re.search(r"^## Version: (.+)$", TOC.read_text(), re.M)[1].strip()
    target = DIST / f"WayForth-Forever-{version}.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as package:
        package.write(TOC, "WayForth/WayForth.toc")
        for script in scripts:
            package.write(source_path(script), f"WayForth/{script}")
        package.writestr(BRAND_PATH, brand_texture())
        package.writestr(ART_PATH, illustrated_art())
        package.writestr(ARROW_PATH, navigation_arrow_texture())
    with zipfile.ZipFile(target) as package:
        broken = package.testzip()
        assert broken is None, f"Broken ZIP member: {broken}"
        assert package.namelist()[0] == "WayForth/WayForth.toc"
    return target


if __name__ == "__main__":
    print("Built:", build())
