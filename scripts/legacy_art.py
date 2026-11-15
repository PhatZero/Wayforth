"""Draw the bundled Legacy treasure-chest icon with only the Python standard library.

The artwork is shared by the dashboard tile and the sidebar; no Blizzard
inventory icon or external image download is required.
"""
import math

SIZE = 128


def _polygon(x, y, points):
    inside = False
    a = points[-1]
    for b in points:
        if (a[1] > y) != (b[1] > y) and x < ((b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]):
            inside = not inside
        a = b
    return inside


LID_OUTER = ((27, 50), (33, 35), (45, 28), (83, 28), (95, 35), (101, 50), (101, 59), (27, 59))
LID_INNER = ((32, 50), (37, 39), (47, 33), (81, 33), (91, 39), (96, 50), (96, 54), (32, 54))
BODY_OUTER = ((27, 57), (101, 57), (98, 94), (92, 101), (36, 101), (30, 94))
BODY_INNER = ((32, 61), (96, 61), (93, 92), (89, 96), (39, 96), (35, 92))


def _pixel(x, y):
    # Soft navy vignette with a teal/gold glow behind the chest.
    d = math.hypot((x - 64) * 1.1, (y - 57) * 1.1)
    glow = max(0.0, 1.0 - d / 80)
    r = 8 + int(11 * glow)
    g = 19 + int(35 * glow)
    b = 34 + int(47 * glow)

    # Compass-inspired halo and tiny stars echo the WayForth dashboard art.
    h = math.hypot(x - 64, y - 58)
    if 48 < h < 49.5:
        r, g, b = 35, 103, 117
    if 53 < h < 54 and x % 7 < 3:
        r, g, b = 95, 78, 45
    if (x, y) in ((16, 19), (110, 25), (21, 90), (108, 99), (14, 62), (112, 66)):
        r, g, b = 225, 187, 111

    # Ground shadow and metallic base.
    if ((x - 64) / 46) ** 2 + ((y - 101) / 10) ** 2 < 1:
        r, g, b = 6, 17, 29
    if _polygon(x, y, BODY_OUTER):
        r, g, b = 208, 158, 76
    if _polygon(x, y, BODY_INNER):
        r, g, b = (79 + int(y / 8), 48 + int(y / 17), 31)
        if (y - 64) % 12 <= 1:
            r, g, b = 116, 75, 38

    # Bright gold bands framing the wood.
    if 34 <= x <= 39 and 60 <= y <= 96 or 89 <= x <= 94 and 60 <= y <= 96:
        r, g, b = (219, 171, 79) if x % 3 else (245, 204, 116)
    if 61 <= y <= 65 and 29 <= x <= 99:
        r, g, b = 221, 174, 81
    if 93 <= y <= 97 and 36 <= x <= 92:
        r, g, b = 187, 128, 52

    # Domed lid, gilded border, and center strap.
    if _polygon(x, y, LID_OUTER):
        r, g, b = 233, 178, 73
    if _polygon(x, y, LID_INNER):
        r, g, b = (119 + max(0, 45 - y), 73, 34)
        if y < 37:
            r, g, b = 178, 118, 49
    if 59 <= x <= 69 and 30 <= y <= 86 and _polygon(x, y, LID_OUTER):
        r, g, b = 228, 182, 85
    if 59 <= x <= 69 and 58 <= y <= 97:
        r, g, b = 207, 159, 70

    # Distinct teal gemstone lock at the center.
    if 54 <= x <= 74 and 62 <= y <= 82:
        r, g, b = 232, 185, 88
    if 58 <= x <= 70 and 65 <= y <= 78:
        r, g, b = 17, 76, 97
    if abs(x - 64) + abs(y - 71) < 7:
        r, g, b = 44, 212, 218
    if abs(x - 63) + abs(y - 69) < 3:
        r, g, b = 196, 249, 241

    # Four visible brass rivets.
    if any((x - px) ** 2 + (y - py) ** 2 <= 5 for px, py in ((34, 56), (94, 56), (38, 91), (90, 91))):
        r, g, b = 251, 220, 137
    return b, g, r, 255


def legacy_art_texture():
    """Return a deterministic 128x128 top-left-origin BGRA TGA."""
    header = bytearray(18)
    header[2] = 2
    header[12:14] = SIZE.to_bytes(2, "little")
    header[14:16] = SIZE.to_bytes(2, "little")
    header[16] = 32
    header[17] = 0x28
    output = bytearray(header)
    for y in range(SIZE):
        for x in range(SIZE):
            output.extend(_pixel(x, y))
    return bytes(output)
