"""Draws the finished reference section: the cave beyond the Shore, its mouth, and the exposed seabed outside it
as far as the first tablet. Same palette, row plan and methods as the accepted Shore (gen_shore.py).

World x 600 to 1440. Images are 270 rows tall, and row 220 is world y = 0, as on the Shore.

    cave_front.png   world space, x 600-1440: the floor, the roof, the mouth, the seabed, the fossil and the tablet
    cave_wall.png    parallax 0.9, local x 500-980: the cave's back wall and the carving, clipped behind the mouth
    abyss_far.png    parallax 0.35, local x 40-680: ridges and the plain beyond the mouth, clipped to the section
    ritual_far.png   parallax 0.5, local x 600-920: the rise and the haze where the ritual is seen
    foreground_cave.png  parallax 1.3, local x 880-1660: near-camera rock along the bottom edge
    shaft.png        a light mask for the moonlight through the mouth, not artwork
"""

import math
import random

from PIL import Image

from art_common import BAYER, Noise, blank, hline, line, put, ramp

HEIGHT = 270
GROUND_ROW = 220
FRONT_X0 = 600
FRONT_X1 = 1440
WALL_X0 = 500
WALL_W = 480
FAR_X0 = 40
FAR_W = 640
RITUAL_X0 = 600
RITUAL_W = 320
FG_X0 = 880
FG_W = 780
MOUTH_X = 1040
# The Shore's own art reaches x = 640, with its cliff, so nothing is drawn left of this: the cliff makes the edge.
DRAW_X0 = 640

MUD = ["E0", "E1", "E2", "E3", "E4", "E5"]
DEEP = ["C0", "E0", "E1", "E2", "E3"]
COLD = ["C0", "C1", "C2", "C3", "C4", "C5"]

# The collision's top surface in this stretch, as (x, y) with y down. check_art.py compares the two.
SURFACE = [(600, 0), (640, 0), (640, 14), (710, 14), (710, 0), (900, 0), (900, -12), (930, -12), (930, -22), (980, -22), (980, 0), (1420, 0), (1440, -3.33)]


def surface_y(x):
    """World y of the walkable top at x, matching the collision, including its vertical steps."""
    best = None
    for (x0, y0), (x1, y1) in zip(SURFACE, SURFACE[1:]):
        if x0 == x1:
            continue
        if x0 <= x < x1:
            best = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    if best is None:
        best = SURFACE[-1][1]
    return best


def roof_row(x):
    """The underside of the cave roof, in image rows. Low near the passage, higher inside, lifting into the mouth."""
    if x < 640:
        return 184
    if x < 690:
        return 184 - (x - 640) * 1.5
    if x < MOUTH_X - 70:
        n = Noise(5)
        return 104 + 10 * math.sin((x - 690) / 47.0) + 8 * (n(x / 23.0, 3) - 0.5)
    if x < MOUTH_X + 30:
        f = (x - (MOUTH_X - 70)) / 100.0
        return 104 + 6 - f * f * 110
    return -10


# ---------------------------------------------------------------- the front layer


def cave_front():
    width = FRONT_X1 - FRONT_X0
    img = blank(width, HEIGHT)
    noise = Noise(301)
    rng = random.Random(302)
    for col in range(width):
        x = FRONT_X0 + col
        if x < DRAW_X0:
            continue
        top = round(GROUND_ROW + surface_y(x + 0.5))
        inside = x < MOUTH_X
        # Moonlight reaches in from the mouth, and fades toward the passage.
        moon = max(0.0, 1.0 - (MOUTH_X + 20 - x) / 260.0) if inside else 1.0
        for y in range(top, HEIGHT):
            depth = y - top
            strata = noise(x / 31.0, y / 3.0)
            if inside:
                value = 2.5 + 1.0 * moon - depth * 0.06 + (strata - 0.5) * 1.0 + 0.4 * (noise.fractal(x / 7.0, y / 4.0, 2) - 0.5)
            else:
                # Cracked seabed mud, dried to a crust on top.
                crack = noise.fractal(x / 9.0, y / 9.0, 2)
                value = 3.9 - depth * 0.07 + (strata - 0.5) * 0.8 - (1.4 if 0.47 < crack < 0.5 else 0.0)
            put(img, col, y, ramp(MUD, value, x, y, 0.3))
        lit = noise(x / 8.0, 4.0)
        if inside:
            put(img, col, top, "E4" if lit > 0.4 + 0.3 * (1 - moon) else "E3")
            if moon > 0.5 and noise(x / 6.0, 9.0) > 0.7:
                put(img, col, top, "C5")
        else:
            put(img, col, top, "E5" if lit > 0.3 else "E4")
            put(img, col, top + 1, "E4" if lit > 0.55 else "E3")
            if noise(x / 5.0, 12.0) > 0.76:
                put(img, col, top, "C6")
    draw_steps(img, noise)
    draw_dip(img, noise)
    draw_roof(img, noise, rng)
    draw_jamb(img, noise, rng)
    draw_puddles(img, noise)
    draw_seabed_dressing(img, noise, rng)
    draw_fossil(img, noise, rng, 1130)
    draw_tablet(img, noise, 1320)
    return img


def draw_steps(img, noise):
    """The two-step rock at 900-980, in the Shore boulder's manner: broad lit facets, a lit top."""
    for x0, x1, h in ((900, 979, 12), (930, 979, 22)):
        for x in range(x0, x1 + 1):
            col = x - FRONT_X0
            top = GROUND_ROW - h
            for y in range(top, GROUND_ROW + 1):
                f = (y - top) / max(h, 1)
                facet = noise(x / 10.0 + y / 15.0, y / 8.0 - x / 25.0)
                value = 3.4 - 1.9 * f + (facet - 0.5) * 2.0 + 0.5 * (x - x0) / (x1 - x0)
                put(img, col, y, ramp(MUD, value, x, y, 0.2))
            put(img, col, top, "C5" if noise(x / 5.0, 3.0) > 0.5 else "E5")
            put(img, col, top + 1, "E4")
    line(img, 952 - FRONT_X0, GROUND_ROW - 20, 956 - FRONT_X0, GROUND_ROW - 13, "E1")
    line(img, 956 - FRONT_X0, GROUND_ROW - 13, 953 - FRONT_X0, GROUND_ROW - 6, "E1")


def draw_dip(img, noise):
    """The low stretch just inside the passage: its two walls, drawn as ledges of the same rock."""
    for x in (640, 641, 709, 710):
        col = x - FRONT_X0
        for y in range(GROUND_ROW, GROUND_ROW + 15):
            put(img, col, y, "E2" if x in (641, 709) else "E1")
    for x in range(642, 709):
        put(img, x - FRONT_X0, GROUND_ROW + 14, "E3" if noise(x / 4.0, 1.0) > 0.45 else "E2")


def draw_roof(img, noise, rng):
    """The rock over the cave, with its strata, lit only near the mouth, and stalactites under it."""
    for x in range(DRAW_X0, MOUTH_X + 40):
        col = x - FRONT_X0
        under = round(roof_row(x))
        moon = max(0.0, 1.0 - (MOUTH_X - x) / 220.0)
        # Where the roof meets the Shore's cliff the joint is ragged, and as dark as the cliff, so it reads as one rock.
        seam = DRAW_X0 + 2 + round(5 * noise(0.0, x / 3.0))
        for y in range(0, max(0, under)):
            if x < DRAW_X0 + 8 and x < seam - round(4 * noise(y / 6.0, 77.0)):
                continue
            strata = noise(x / 40.0 + y / 70.0, y / 6.0)
            value = 0.9 + 0.8 * moon + (strata - 0.5) * 1.2 + 0.3 * (noise.fractal(x / 9.0, y / 7.0, 2) - 0.5)
            if under - y < 3:
                value += 0.8 * moon
            put(img, col, y, ramp(DEEP, value, x, y, 0.3))
        if 0 <= under < HEIGHT:
            put(img, col, under, "E3" if moon > 0.4 and noise(x / 4.0, 6.0) > 0.4 else "E1")
    # Stalactites: thin, irregular, more of them deep inside.
    x = 700
    while x < MOUTH_X - 40:
        length = rng.randrange(4, 16)
        width = rng.choice((1, 2, 2, 3))
        base = round(roof_row(x)) - 1
        for i in range(length):
            w = max(1, round(width * (1 - i / length)))
            for k in range(w):
                put(img, x - FRONT_X0 + k, base + i, "E1" if i < length - 2 else "E2")
        if rng.random() > 0.5:
            put(img, x - FRONT_X0, base + length, "T2")  # A bead of water.
        x += rng.randrange(9, 26)


def draw_jamb(img, noise, rng):
    """The right edge of the cave: a ragged rock rib from roof to floor, lit on the side the moon is on."""
    for y in range(0, GROUND_ROW + 2):
        edge = MOUTH_X - 14 + round(10 * (noise(y / 19.0, 41.0) - 0.5)) + max(0, 40 - y) // 3
        for x in range(edge - 18, edge + 1):
            col = x - FRONT_X0
            d = edge - x
            facet = noise(x / 9.0 + y / 21.0, y / 11.0)
            value = 1.3 + (facet - 0.5) * 1.6 - d * 0.02
            put(img, col, y, ramp(DEEP, value, x, y, 0.25))
        lit = noise(y / 5.0, 42.0)
        put(img, edge - FRONT_X0, y, "E4" if lit > 0.3 else "E3")
        put(img, edge - 1 - FRONT_X0, y, "E3" if lit > 0.55 else "E2")
        if lit > 0.82 and y > 60:
            put(img, edge - FRONT_X0, y, "C4")
        if rng.random() > 0.93:
            put(img, edge - rng.randrange(3, 12) - FRONT_X0, y, "T1")


def draw_puddles(img, noise):
    """Standing water on the cave floor, catching the light from the mouth."""
    for x0, x1 in ((770, 812), (860, 893), (996, 1030)):
        for x in range(x0, x1):
            row = GROUND_ROW + 1
            edge = min(x - x0, x1 - 1 - x)
            if edge < 1:
                continue
            put(img, x - FRONT_X0, row, "T1")
            if edge > 2:
                put(img, x - FRONT_X0, row + 1, "T0")
            if noise(x / 3.0, 22.0) > 0.62:
                put(img, x - FRONT_X0, row, "C6")


def draw_seabed_dressing(img, noise, rng):
    """Shells, a few bones and dead weed on the mud outside, in loose drifts."""
    for cx, spread, n in ((1080, 30, 9), (1200, 50, 14), (1380, 40, 10)):
        for _ in range(n):
            x = cx + rng.randrange(-spread, spread)
            y = GROUND_ROW + rng.randrange(2, 30)
            size = rng.choice((1, 1, 2, 3))
            hline(img, x - FRONT_X0, x - FRONT_X0 + size, y, rng.choice(("E4", "E5", "C6")))
            hline(img, x - FRONT_X0, x - FRONT_X0 + size, y + 1, "E1")
    for x0, length in ((1060, 18), (1240, 22), (1350, 14)):
        for i in range(length):
            x = x0 + i
            if rng.random() > 0.25:
                put(img, x - FRONT_X0, GROUND_ROW - 1, "T1" if rng.random() > 0.4 else "T0")
            if rng.random() > 0.6:
                put(img, x - FRONT_X0, GROUND_ROW - 2, "T2")


def draw_fossil(img, noise, rng, cx):
    """A spine as long as the boat, half in the mud, with too many ribs curling up out of it."""
    x0, x1 = cx - 30, cx + 32
    for x in range(x0, x1):
        f = (x - x0) / (x1 - x0)
        h = round(4 + 2 * math.sin(f * math.pi))
        for k in range(h):
            put(img, x - FRONT_X0, GROUND_ROW - k, "E5" if k == h - 1 else ("E4" if k > 1 else "E3"))
        if (x - x0) % 4 == 0:
            put(img, x - FRONT_X0, GROUND_ROW - h, "C7")
    # Ribs: thin arcs, more than any animal should have.
    for i, x in enumerate(range(x0 + 3, x1 - 3, 5)):
        height = 6 + round(5 * math.sin((x - x0) / (x1 - x0) * math.pi)) + (i % 2)
        for k in range(height):
            dx = round((k / height) ** 2 * 3)
            put(img, x + dx - FRONT_X0, GROUND_ROW - 4 - k, "E5" if k % 3 else "E4")
        put(img, x + 3 - FRONT_X0, GROUND_ROW - 4 - height, "C7")
    # The skull end, flat and wrong.
    for x in range(x1 - 2, x1 + 5):
        for k in range(0, 6 - abs(x - x1 - 1)):
            put(img, x - FRONT_X0, GROUND_ROW - k, "E4" if k else "E3")
    put(img, x1 + 1 - FRONT_X0, GROUND_ROW - 3, "E0")


def draw_tablet(img, noise, cx):
    """The first slab, standing, cut with rising lines: the waters rose first."""
    for y in range(GROUND_ROW - 33, GROUND_ROW + 1):
        row = y - (GROUND_ROW - 33)
        half = 11 if row > 6 else 7 + round(row * 0.7)
        for x in range(cx - half, cx + half + 1):
            facet = noise(x / 6.0, y / 7.0)
            value = 3.0 + (facet - 0.5) * 1.0 + (0.6 if x < cx else 0.0) - row * 0.02
            put(img, x - FRONT_X0, y, ramp(MUD, value, x, y, 0.2))
        put(img, cx - half - FRONT_X0, y, "C5")
        put(img, cx + half - FRONT_X0, y, "E1")
    hline(img, cx - 7 - FRONT_X0, cx + 7 - FRONT_X0, GROUND_ROW - 33, "C6")
    # The glyph: two rows of rising waves, cut in, with a lit lower lip.
    for band, base in ((0, GROUND_ROW - 24), (1, GROUND_ROW - 17)):
        for i in range(17):
            x = cx - 8 + i
            y = base - round(2 * abs(math.sin(i * math.pi / 4)))
            put(img, x - FRONT_X0, y, "E0")
            put(img, x - FRONT_X0, y + 1, "T3")


# ---------------------------------------------------------------- the back wall


def cave_wall():
    img = blank(WALL_W, HEIGHT)
    noise = Noise(311)
    rng = random.Random(312)
    for col in range(WALL_W):
        x = WALL_X0 + col
        for y in range(0, GROUND_ROW + 15):
            strata = noise(x / 45.0 + y / 90.0, y / 5.0)
            moon = max(0.0, 1.0 - (980 - x) / 300.0)
            value = 1.2 + 0.9 * moon + (strata - 0.5) * 1.3 + 0.35 * (noise.fractal(x / 8.0, y / 6.0, 2) - 0.5)
            put(img, col, y, ramp(DEEP, value, x, y, 0.3))
        # A few short seeps of water down the wall, dark teal where they gather.
        if noise(x / 7.0, 51.0) > 0.86 and x % 3 == 0:
            start = 150 + round(40 * noise(x / 5.0, 52.0))
            for y in range(start, min(GROUND_ROW, start + 14 + round(16 * noise(x / 4.0, 53.0)))):
                put(img, col, y, "T0")
    draw_carving(img, noise, 830)
    return img


def draw_carving(img, noise, cx):
    """The mark, cut deep and kept clean: an eye above waves, held in a curling arm ringed with suckers.
    The wall here is smoother and lighter, because someone has cleaned it."""
    cy = GROUND_ROW - 30
    col = lambda x: x - WALL_X0
    for y in range(cy - 22, cy + 20):
        for x in range(cx - 26, cx + 27):
            d = math.hypot((x - cx) / 26.0, (y - cy) / 21.0)
            if d < 1.0:
                value = 2.6 + (noise(x / 9.0, y / 9.0) - 0.5) * 0.5 - d * 0.6
                put(img, col(x), y, ramp(DEEP, value, x, y, 0.2))
    # The arm: a spiral from lower left, curling over the top, its suckers along the inside.
    points = []
    for i in range(120):
        a = math.pi * 0.85 + i / 119 * math.pi * 1.55
        r = 20 - i * 0.09
        points.append((cx + r * math.cos(a), cy + 2 + r * math.sin(a) * 0.8))
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        line(img, col(round(x0)), round(y0), col(round(x1)), round(y1), "E0")
        line(img, col(round(x0)), round(y0) - 1, col(round(x1)), round(y1) - 1, "E4")
    for i in range(6, 110, 11):
        x, y = points[i]
        inward_x = cx + (x - cx) * 0.86
        inward_y = cy + 2 + (y - cy - 2) * 0.86
        put(img, col(round(inward_x)), round(inward_y), "E0")
        put(img, col(round(inward_x)) + 1, round(inward_y), "E0")
        put(img, col(round(inward_x)), round(inward_y) - 1, "C6")
    # The eye.
    for x in range(cx - 9, cx + 10):
        h = round(5 * math.sqrt(max(0.0, 1 - ((x - cx) / 9.5) ** 2)))
        put(img, col(x), cy - 6 - h, "E0")
        put(img, col(x), cy - 6 + h, "E0")
        put(img, col(x), cy - 6 - h - 1, "C6")
    for x in range(cx - 2, cx + 3):
        for y in range(cy - 8, cy - 3):
            put(img, col(x), y, "T3" if (x + y) % 3 else "T4")
    # The waves below it.
    for base in (cy + 3, cy + 8):
        for i in range(19):
            x = cx - 9 + i
            y = base - round(2 * abs(math.sin(i * math.pi / 4.5)))
            put(img, col(x), y, "E0")
            put(img, col(x), y - 1, "E4")


# ---------------------------------------------------------------- beyond the mouth


def abyss_far():
    """The seabed going on for ever: a pale band where it meets the sky, black ridges, a sheen on the mud."""
    img = blank(FAR_W, HEIGHT)
    noise = Noise(321)
    rng = random.Random(322)
    horizon = 132
    ridge_far = [horizon - 10 - 16 * noise((FAR_X0 + c) / 70.0, 1) - 10 * noise((FAR_X0 + c) / 23.0, 2) for c in range(FAR_W)]
    ridge_near = [horizon + 4 - 22 * noise((FAR_X0 + c) / 55.0, 7) ** 1.6 - 6 * noise((FAR_X0 + c) / 15.0, 8) for c in range(FAR_W)]
    for c in range(FAR_W):
        x = FAR_X0 + c
        for y in range(round(ridge_far[c]), HEIGHT):
            if y < ridge_near[c]:
                # Far ridges, almost the sky's own colour, lightest at their tops.
                value = 2.6 - (y - ridge_far[c]) * 0.05 + (noise(x / 13.0, y / 9.0) - 0.5) * 0.5
                put(img, c, y, ramp(COLD, value, x, y, 0.35))
            elif y < horizon + 8:
                value = 1.4 + (noise(x / 11.0, y / 6.0) - 0.5) * 0.8 - (y - ridge_near[c]) * 0.04
                put(img, c, y, ramp(DEEP, value, x, y, 0.3))
            else:
                # The plain: wet black mud, with moonlight lying along it in bands.
                d = (y - horizon) / (HEIGHT - horizon)
                sheen = 1.2 * math.exp(-((y - horizon - 14) / 7.0) ** 2) * (0.5 + noise(x / 25.0, 3))
                value = 1.6 - d * 1.3 + sheen + (noise(x / 17.0, y / 3.0) - 0.5) * 0.6
                put(img, c, y, ramp(DEEP + ["C4"], value, x, y, 0.35))
        put(img, c, round(ridge_far[c]), "C4" if noise(x / 5.0, 31) > 0.4 else "C3")
    # Mist low on the plain, dithered, thinning upward.
    for c in range(FAR_W):
        x = FAR_X0 + c
        for y in range(horizon - 4, horizon + 10):
            density = math.exp(-((y - horizon - 2) / 5.0) ** 2) * noise(x / 40.0, 61)
            if density > 0.45 and (x + y) % 2 == 0:
                put(img, c, y, "C4" if density > 0.6 else "C3")
    # A few far spires of rock, as thin as needles.
    for sx in (120, 260, 470, 560):
        h = rng.randrange(14, 30)
        base = horizon + 2
        for k in range(h):
            w = max(1, round(2 * (1 - k / h)))
            for i in range(w):
                put(img, sx + i, base - k, "C1" if k < h - 2 else "C2")
    return img


def ritual_far():
    """The rise where the ritual happens, and the pale haze behind it, in place of the greybox's flat shapes."""
    img = blank(RITUAL_W, HEIGHT)
    noise = Noise(331)
    for c in range(RITUAL_W):
        x = RITUAL_X0 + c
        # The haze: a pale glow standing behind the rise, brightest at its centre, thinning out by dither, not an edge.
        cx, cy = 756, GROUND_ROW - 60
        for y in range(GROUND_ROW - 110, GROUND_ROW - 20):
            d = math.hypot((x - cx) / 115.0, (y - cy) / 42.0) + (noise(x / 14.0, y / 9.0) - 0.5) * 0.25
            if d < 1.0:
                threshold = (BAYER[y % 4][x % 4] + 0.5) / 16.0
                if (1.0 - d) * 2.2 < threshold:
                    continue
                value = 3.2 - d * 2.4 + (noise(x / 12.0, y / 8.0) - 0.5) * 0.6
                put(img, c, y, ramp(COLD, max(value, 0.8), x, y, 0.4))
        # The rise: a low dark mound, lit only along its crest.
        if 610 <= x <= 910:
            f = (x - 610) / 300.0
            crest = GROUND_ROW - round(20 + 14 * math.sin(f * math.pi) + 3 * (noise(x / 9.0, 5) - 0.5))
            for y in range(crest, GROUND_ROW + 60):
                value = 1.2 - (y - crest) * 0.03 + (noise(x / 10.0, y / 6.0) - 0.5) * 0.5
                put(img, c, y, ramp(DEEP, value, x, y, 0.3))
            put(img, c, crest, "C4" if noise(x / 4.0, 9) > 0.45 else "C3")
    return img


def foreground_cave():
    """Near-camera rock at the bottom edge, and the tips of fallen stones, all in near-black."""
    img = blank(FG_W, HEIGHT)
    noise = Noise(341)
    stones = [(0, 40, 12), (60, 26, 6), (140, 70, 18), (250, 34, 7), (330, 48, 10), (430, 30, 5), (520, 62, 14), (640, 36, 8), (720, 60, 16)]
    for sx, sw, sh in stones:
        for x in range(sx, sx + sw):
            if not 0 <= x < FG_W:
                continue
            arc = math.sin(math.pi * (x - sx + 0.5) / sw) ** 0.6
            h = round(sh * arc * (0.88 + 0.24 * noise(x / 6.0, sx)))
            for y in range(HEIGHT - h, HEIGHT):
                put(img, x, y, "C0")
            if h > 1:
                put(img, x, HEIGHT - h, "E1")
    for x in range(FG_W):
        put(img, x, HEIGHT - 1, "C0")
        put(img, x, HEIGHT - 2, "C0")
    return img


def shaft():
    """A light mask: moonlight slanting in through the mouth onto the floor, in a few stepped bands."""
    w, h = 220, 240
    image = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    for y in range(h):
        # The beam leans left as it comes down, widening a little.
        centre = w * 0.7 - y * 0.42
        half = 26 + y * 0.12
        for x in range(w):
            d = abs(x - centre) / half
            fall = 1.0 - (y / h) * 0.45
            level = 0.0
            for edge, value in ((0.35, 0.75), (0.7, 0.45), (1.0, 0.2)):
                if d <= edge:
                    level = value * fall
                    break
            v = round(255 * level)
            image.putpixel((x, y), (v, v, v, 255))
    return image


# ---------------------------------------------------------------- the Shore's new prop


def tentacle():
    """Something the sea left on the Shore: part of an arm, thick as a leg, its suckers ringed. Not a squid's."""
    w, h = 40, 12
    img = blank(w, h)
    rng = random.Random(351)
    path = []
    for i in range(36):
        f = i / 35
        path.append((2 + i, 8 - 3 * math.sin(f * math.pi * 1.2) + (2 if f > 0.85 else 0) * (f - 0.85) * 20))
    for i, (x, y) in enumerate(path):
        thick = 4.6 - i * 0.11
        for k in range(-round(thick / 2), round(thick / 2) + 1):
            yy = round(y + k)
            put(img, round(x), yy, "S0" if k < 0 else ("E3" if k > thick / 2 - 1 else "S0"))
        put(img, round(x), round(y - thick / 2) - 1 + 1, "S1" if i % 7 else "E5")
        # Suckers along the underside, each a pale ring.
        if i % 4 == 1 and i < 33:
            yy = round(y + thick / 2) - 1
            put(img, round(x), yy, "E5")
            put(img, round(x) + 1, yy, "C6")
            put(img, round(x), yy + 1, "E1")
    # The cut end: clean, and dark inside.
    x, y = path[0]
    for k in range(-2, 3):
        put(img, round(x) - 1, round(y) + k, "W0")
    for _ in range(4):
        put(img, rng.randrange(6, 34), h - 1, "T1")
    return img
