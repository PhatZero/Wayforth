"""Generate WayForth's original frameless 128px navigation-needle texture.

No external assets or dependencies: deterministic RGBA TGA, top-left origin.
"""
import math

SIZE = 128


def _inside(x, y, polygon):
    hit = False
    previous = polygon[-1]
    for current in polygon:
        x1, y1 = previous
        x2, y2 = current
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            hit = not hit
        previous = current
    return hit


OUTER = ((64, 8), (89, 59), (76, 61), (76, 99), (64, 111),
         (52, 99), (52, 61), (39, 59))
INNER = ((64, 23), (79, 56), (69, 55), (69, 96), (64, 101),
         (59, 96), (59, 55), (49, 56))
CYAN = ((64, 27), (68, 56), (66, 94), (64, 98), (62, 94), (60, 56))
SHADOW = tuple((x + 2, y + 3) for x, y in OUTER)


def _composite(color, layer):
    r, g, b, a = color
    lr, lg, lb, la = layer
    coverage = la / 255.0
    remainder = a * (1.0 - coverage) / 255.0
    total = coverage + remainder
    if total == 0:
        return (0, 0, 0, 0)
    return (round((lr * coverage + r * remainder) / total),
            round((lg * coverage + g * remainder) / total),
            round((lb * coverage + b * remainder) / total),
            round(total * 255))


def _color(x, y):
    c = (0, 0, 0, 0)
    radius = math.hypot(x - 64, y - 67)
    if 38 < radius < 43:
        c = _composite(c, (27, 202, 226, 30))
    if 41 < radius < 42.2 and 22 < y < 115:
        c = _composite(c, (235, 183, 82, 87))
    if _inside(x, y, SHADOW):
        c = _composite(c, (2, 10, 24, 170))
    if _inside(x, y, OUTER):
        c = _composite(c, (232, 183, 79, 255))
    if _inside(x, y, INNER):
        c = _composite(c, (13, 31, 51, 255))
    if _inside(x, y, CYAN):
        c = _composite(c, (37, 213, 233, 255))
    if math.hypot(x - 64, y - 12) < 4.0:
        c = _composite(c, (255, 239, 175, 220))
    if 61 < y < 68 and 58 < x < 70:
        c = _composite(c, (255, 216, 125, 150))
    return c


def navigation_arrow_texture():
    """Return a 128x128 RGBA TGA that WoW: Forever can load directly."""
    header = bytearray(18)
    header[2] = 2  # Uncompressed true-color
    header[12:14] = SIZE.to_bytes(2, "little")
    header[14:16] = SIZE.to_bytes(2, "little")
    header[16] = 32
    header[17] = 0x28  # Top-left origin, eight alpha bits
    output = bytearray(header)
    for y in range(SIZE):
        for x in range(SIZE):
            samples = [_color(x + ox, y + oy)
                       for oy in (0.25, 0.75) for ox in (0.25, 0.75)]
            a = round(sum(p[3] for p in samples) / 4)
            if a:
                r = round(sum(p[0] * p[3] for p in samples) / sum(p[3] for p in samples))
                g = round(sum(p[1] * p[3] for p in samples) / sum(p[3] for p in samples))
                b = round(sum(p[2] * p[3] for p in samples) / sum(p[3] for p in samples))
            else:
                r = g = b = 0
            output.extend((b, g, r, a))
    return bytes(output)


if __name__ == "__main__":
    from pathlib import Path
    target = Path("WayForthArrow.tga")
    target.write_bytes(navigation_arrow_texture())
    print(target)
