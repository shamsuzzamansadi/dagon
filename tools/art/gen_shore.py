"""Draws the environment layers for the Shore. All images are 270 rows tall, matching the camera's
fixed vertical range, so a row in an image is also a row on screen.

Screen plan: sky above row 150, then far sea, wet flats, a low bank, and the walkable ground at row 220.
"""

import math
import random

from art_common import Noise, blank, hline, line, put, ramp

HEIGHT = 270
WORLD_WIDTH = 640
GROUND_ROW = 220
HORIZON = 150
TIDE_LINE = 176
MOON = (318, 54)
MOON_R = 9
# The cleft in the right cliff, where the ground carries on into the greybox part of the level.
PASSAGE_X = 622
PASSAGE_HEIGHT = 36

SKY = ["C0", "C1", "C2", "C3", "C4", "C5", "C6"]
FLAT = ["E1", "C2", "C3", "C4", "C5"]
MUD = ["E0", "E1", "E2", "E3", "E4", "E5"]


def ground_height(x):
    """The walkable profile, above row 220. Same points as the greybox level; rock drawn separately."""
    points = [(0, 0), (360, 0), (420, 10), (480, 10), (540, 0), (WORLD_WIDTH, 0)]
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x0 <= x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return 0.0


def moon_distance(x, y):
    return math.hypot(x - MOON[0], (y - MOON[1]) * 1.25)


def sky():
    img = blank(480, HEIGHT)
    rng = random.Random(11)
    for y in range(HORIZON + 2):
        for x in range(480):
            base = 0.15 + 3.1 * (y / HORIZON) ** 1.6
            glow = 2.6 * math.exp(-((moon_distance(x, y) / 62.0) ** 2)) + 0.7 * math.exp(-((moon_distance(x, y) / 150.0) ** 2))
            put(img, x, y, ramp(SKY, base + glow, x, y, 0.35))
    # Sparse stars, only in the dark upper sky, away from the moon.
    placed = 0
    while placed < 46:
        x, y = rng.randrange(480), rng.randrange(0, 88)
        if moon_distance(x, y) < 95:
            continue
        bright = rng.random()
        put(img, x, y, "C8" if bright > 0.8 else ("C6" if bright > 0.35 else "C5"))
        if bright > 0.93:
            put(img, x, y, "C9")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                put(img, x + dx, y + dy, "C5")
        placed += 1
    # Moon: a full disc with faint maria, softened by a stepped halo.
    for y in range(MOON[1] - MOON_R - 3, MOON[1] + MOON_R + 4):
        for x in range(MOON[0] - MOON_R - 3, MOON[0] + MOON_R + 4):
            d = math.hypot(x - MOON[0], y - MOON[1])
            if d <= MOON_R:
                put(img, x, y, "C9")
            elif d <= MOON_R + 1.2:
                put(img, x, y, "C8")
            elif d <= MOON_R + 2.6 and (x + y) % 2 == 0:
                put(img, x, y, "C7")
    for x, y in ((-3, -2), (-2, -3), (-4, -1), (2, 2), (3, 1), (3, 3), (-1, 4), (0, 4), (4, -4)):
        put(img, MOON[0] + x, MOON[1] + y, "C8")
    return img


def clouds(width=WORLD_WIDTH):
    """Heavy banks with billowing tops over flat, dark bellies, lit only near the moon. Tiles horizontally."""
    img = blank(width, HEIGHT)
    noise = Noise(23)
    rng = random.Random(77)
    banks = [
        # (centre x, belly row, half width, billow height, belly value)
        (92, 48, 116, 17, 1.0), (262, 42, 60, 9, 1.1), (424, 36, 90, 13, 1.0), (592, 60, 82, 16, 1.1),
        (150, 94, 124, 16, 1.5), (360, 86, 96, 13, 1.6), (526, 113, 128, 14, 1.9),
        (42, 126, 110, 10, 2.2), (282, 132, 136, 8, 2.5), (604, 140, 90, 6, 2.8),
    ]
    for cx, cy, rx, rise, belly in banks:
        # A row of overlapping circles makes the rounded top edge.
        bumps = []
        x = cx - rx + 4
        while x < cx + rx - 4:
            span = math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2))
            radius = 3.0 + rise * span * (0.4 + 0.6 * rng.random())
            bumps.append((x, radius))
            x += max(3.0, radius * rng.uniform(0.45, 0.85))
        for x in range(cx - rx, cx + rx + 1):
            span = math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2))
            lift = 1.5 * span
            for bx, radius in bumps:
                if abs(x - bx) < radius:
                    lift = max(lift, math.sqrt(radius * radius - (x - bx) ** 2) * 0.82)
            top = cy - lift
            under = cy + 3.0 * span * (0.5 + noise(x / 20.0, cy / 3.0 + 5))
            if under - top < 1.5:
                continue
            for y in range(round(top), round(under) + 1):
                depth = y - top
                near = math.exp(-((moon_distance(x, y) / 90.0) ** 2))
                value = belly + 0.8 * max(0.0, 1.0 - depth / 5.0) + 2.9 * near * max(0.0, 1.0 - depth / 8.0)
                put(img, x % width, y, ramp(SKY, value, x, y, 0.3))
            rim = math.exp(-((moon_distance(x, top) / 70.0) ** 2))
            if rim > 0.28:
                put(img, x % width, round(top), "C7" if rim > 0.62 else "C6")
    return img


def far():
    """Horizon, a dark headland that makes this a coast, and the sea, far out past the flats."""
    img = blank(WORLD_WIDTH, HEIGHT)
    noise = Noise(31)
    for x in range(WORLD_WIDTH):
        # Stepped sea cliffs at the right, a low point at the left.
        mass = 38 * (0.5 + 0.5 * math.tanh((x - 388) / 20.0)) * (1 - 0.16 * math.sin(x / 33.0))
        mass *= 1 - 0.7 * max(0.0, (x - 530) / 110.0)
        mass += 7 * math.exp(-(((x - 345) / 26.0) ** 2))
        mass += 8 * math.exp(-(((x - 62) / 70.0) ** 2))
        h = mass * (0.82 + 0.36 * noise.fractal(x / 19.0, 3.0, 3))
        if h < 1:
            continue
        top = HORIZON - round(h)
        for y in range(top, HORIZON + 1):
            f = (y - top) / max(HORIZON - top, 1)
            lit = 0.5 * (noise(x / 7.0, y / 4.0) - 0.5)
            put(img, x, y, ramp(["C1", "C2", "C3"], 1.25 - f * 1.1 + lit, x, y, 0.4))
        put(img, x, top, "C4")
    # Sea: hazy at the horizon, darkening toward the viewer. Teal is only a hint.
    for y in range(HORIZON, TIDE_LINE + 6):
        f = min(1.0, (y - HORIZON) / (TIDE_LINE - HORIZON))
        for x in range(WORLD_WIDTH):
            value = 3.1 - 2.3 * f + 0.5 * (noise(x / (5.0 + 18 * f), y * 0.9) - 0.5)
            put(img, x, y, ramp(["C1", "T0", "T1", "C3", "C4"], value, x, y, 0.25))
    for x in range(WORLD_WIDTH):
        if noise(x / 17.0, 21.0) > 0.36:
            put(img, x, HORIZON, "C5")
    # Long, slow swell lines, widening toward the viewer.
    rng = random.Random(5)
    for y in range(HORIZON + 3, TIDE_LINE + 2, 3):
        x = rng.randrange(40)
        while x < WORLD_WIDTH:
            length = rng.randrange(8, 24 + (y - HORIZON))
            hline(img, x, x + length, y, "T1" if rng.random() > 0.4 else "C3")
            x += length + rng.randrange(18, 70)
    return img


def tide_edge(x, noise):
    return TIDE_LINE + 2.2 * math.sin(x / 37.0) + 3.0 * (noise(x / 16.0, 9.0) - 0.5)


def flats():
    """The wet seabed the sea has left. It stays a mid value so a dark figure reads in front of it."""
    img = blank(WORLD_WIDTH, HEIGHT)
    noise = Noise(47)
    rng = random.Random(9)
    for x in range(WORLD_WIDTH):
        edge = round(tide_edge(x, noise))
        for y in range(edge, GROUND_ROW + 3):
            f = (y - TIDE_LINE) / (GROUND_ROW - TIDE_LINE)
            sheen = 0.9 * math.exp(-(((x - 330) / (56.0 + 90 * f)) ** 2))
            value = 2.75 - 0.25 * f + sheen * (1 - 0.3 * f) + 0.55 * (noise(x / (11 + 30 * f), y / 2.0) - 0.5)
            put(img, x, y, ramp(FLAT, value, x, y, 0.3))
        # The tide line: broken foam where the sea has drawn back, far from the shore.
        if noise(x / 6.0, 3.0) > 0.38:
            put(img, x, edge, "C6" if noise(x / 3.0, 7.0) > 0.5 else "T3")
        elif noise(x / 4.0, 13.0) > 0.5:
            put(img, x, edge, "T2")
    # Ripple marks: fine near the tide line, longer nearer the viewer.
    for y in range(TIDE_LINE + 6, GROUND_ROW, 2):
        f = (y - TIDE_LINE) / (GROUND_ROW - TIDE_LINE)
        x = rng.randrange(30)
        while x < WORLD_WIDTH:
            length = rng.randrange(3 + round(6 * f), 8 + round(22 * f))
            if rng.random() > 0.4:
                hline(img, x, x + length, y, "C3" if f > 0.3 else "C4")
                if rng.random() > 0.7:
                    hline(img, x + 1, x + length - 1, y - 1, "C5")
            x += length + rng.randrange(10, 52)
    # Tide pools reflect the sky, brightest under the moon, and never as bright as the moon's path.
    pools = [(330, 186, 19, 1), (300, 193, 22, 2), (364, 198, 26, 2), (440, 188, 18, 1), (530, 200, 32, 2), (112, 193, 18, 1), (262, 209, 28, 1)]
    for px, py, rx, ry in pools:
        for y in range(py - ry, py + ry + 1):
            half = rx * math.sqrt(max(0.0, 1 - ((y - py) / (ry + 0.5)) ** 2))
            for x in range(round(px - half), round(px + half) + 1):
                if noise(x / 5.0, y * 1.0) < 0.22:
                    continue
                strength = math.exp(-(((x - 330) / 80.0) ** 2))
                value = 1.0 + 2.5 * strength + (0.5 - abs(y - py) / (ry + 1))
                put(img, x, y, ramp(["C4", "C5", "C6", "C7"], value, x, y, 0.3))
        hline(img, px - rx // 2, px + rx // 3, py + ry + 1, "C3")
    # A wreck far out on the flats: ribs and a canted mast. Small, and low in contrast.
    wx, wy = 424, 183
    for i, h in enumerate((5, 7, 8, 8, 7, 6, 4)):
        x = wx + i * 4
        line(img, x, wy, x + 1, wy - h, "C1")
        put(img, x + 2, wy - h, "C1")
    hline(img, wx - 2, wx + 26, wy + 1, "C2")
    line(img, wx + 13, wy, wx + 19, wy - 24, "C1")
    line(img, wx + 14, wy - 15, wx + 21, wy - 13, "C1")
    # Old stakes march off toward the tide, leading the eye to the moon's reflection.
    for x, y, h in [(262, 212, 11), (280, 202, 8), (296, 195, 6), (308, 190, 4), (318, 186, 3), (326, 183, 2)]:
        width = 3 if h > 9 else (2 if h > 4 else 1)
        for k in range(width):
            line(img, x + k, y, x + k, y - h, "E1" if k < width - 1 or width == 1 else "E0")
        put(img, x + width - 1, y - h, "C6")
        if h > 4:
            hline(img, x - 1, x + width, y + 1, "C2")
            line(img, x, y + 2, x, y + 2 + h // 3, "C3")
    return img


def bank():
    """A low dark bank behind the walkable ground. It has a gap in the middle so the flats show behind the sailor."""
    img = blank(WORLD_WIDTH, HEIGHT)
    noise = Noise(61)
    rng = random.Random(3)
    def height(x):
        left = 15 * math.exp(-(((x - 26) / 62.0) ** 2))
        right = 13 * math.exp(-(((x - 560) / 72.0) ** 2)) + 7 * math.exp(-(((x - 628) / 30.0) ** 2))
        small = 3.0 * math.exp(-(((x - 300) / 42.0) ** 2))
        return (left + right + small) * (0.8 + 0.4 * noise.fractal(x / 18.0, 4.0, 3))
    for x in range(WORLD_WIDTH):
        h = height(x)
        if h < 1:
            continue
        top = GROUND_ROW + 1 - round(h)
        for y in range(top, GROUND_ROW + 2):
            f = (y - top) / max(h, 1)
            put(img, x, y, ramp(["E2", "E1", "E0"], f * 1.6, x, y, 0.4))
        put(img, x, top, "C4" if h > 3 else "E3")
    # Marram grass in sparse clumps, not an even row.
    for cx, spread, n in ((34, 18, 9), (70, 12, 6), (548, 20, 10), (604, 12, 6)):
        for _ in range(n):
            x = cx + rng.randrange(-spread, spread)
            base = GROUND_ROW + 1 - round(height(x))
            h = rng.randrange(4, 9)
            lean = rng.choice((1, 1, 2, -1))
            line(img, x, base, x + lean, base - h, "T1" if rng.random() > 0.35 else "E1")
            put(img, x + lean, base - h, "C4")
    return img


def terrain(width=WORLD_WIDTH):
    """The walkable ground and the rock at x=200-240, on the greybox collision. Side cliffs frame the view."""
    img = blank(width, HEIGHT)
    noise = Noise(71)
    rng = random.Random(13)
    for x in range(width):
        top = GROUND_ROW - round(ground_height(x))
        for y in range(top, HEIGHT):
            depth = y - top
            strata = noise(x / 34.0, (y - ground_height(x) * 0.6) / 2.2)
            value = 3.7 - depth * 0.075 + (strata - 0.5) * 0.9
            value += 0.5 * (noise.fractal(x / 8.0, y / 5.0, 2) - 0.5)
            put(img, x, y, ramp(MUD, value, x, y, 0.3))
        # The surface: a lit top edge, so the path reads even against the dark bank.
        lit = noise(x / 9.0, 2.0)
        put(img, x, top, "E5" if lit > 0.34 else "E4")
        put(img, x, top + 1, "E4" if lit > 0.5 else "E3")
        if noise(x / 5.0, 11.0) > 0.72:
            put(img, x, top, "C6")  # Wet gleam from the moon.
    # Stones and shells, in loose clusters.
    for cx, spread, n in ((100, 60, 14), (300, 50, 16), (470, 44, 12), (590, 30, 8)):
        for _ in range(n):
            x = cx + rng.randrange(-spread, spread)
            y = GROUND_ROW - round(ground_height(x)) + rng.randrange(3, 30)
            size = rng.choice((1, 1, 2, 2, 3))
            shade = rng.choice(("E4", "E3", "E5"))
            hline(img, x, x + size, y, shade)
            hline(img, x, x + size, y + 1, "E1")
            if size > 1:
                put(img, x, y, "E5")
    # Sea wrack on the surface: dark ragged weed strung along the tideline.
    for x0, length in ((150, 22), (272, 16), (326, 26), (496, 18), (570, 24)):
        for i in range(length):
            x = x0 + i
            top = GROUND_ROW - round(ground_height(x))
            if rng.random() > 0.2:
                put(img, x, top, "T1" if rng.random() > 0.3 else "T0")
            if rng.random() > 0.55:
                put(img, x, top - 1, "T2" if rng.random() > 0.55 else "T1")
            if rng.random() > 0.75:
                put(img, x, top + 1, "T0")
    draw_rock(img, noise, rng)
    ground = img.copy()
    draw_side_cliff(img, noise, 0, 25, 62, +1, 37)
    draw_side_cliff(img, noise, width - 1, width - 21, width - 58, -1, 53)
    draw_passage(img, ground, width - 21, width)
    return img


def draw_rock(img, noise, rng):
    """The boulder. Its whole top is the collision top at 14 px, so feet rest on what is drawn. Below the
    top it flares out and low stones sit at its foot, so the silhouette stops reading as a rectangle."""
    x0, x1, top = 200, 239, GROUND_ROW - 14
    for x in range(x0 - 3, x1 + 4):
        outside = max(x0 - x, x - x1, 0)
        y_top = top if outside == 0 else top + 3 + 3 * outside + (1 if noise(x / 3.0, 8.0) > 0.5 else 0)
        for y in range(y_top, GROUND_ROW + 2):
            f = (y - top) / 15.0
            # Broad facets, not fine noise: planes turned to the moon are lighter.
            facet = noise(x / 11.0 + y / 16.0, y / 9.0 - x / 28.0)
            value = 3.6 - 2.3 * f + (facet - 0.5) * 2.1 + 0.6 * (x - x0) / (x1 - x0)
            put(img, x, y, ramp(MUD, value, x, y, 0.2))
        put(img, x, y_top, "C6" if noise(x / 5.0, 3.0) > 0.45 else "E5")
        if y_top + 1 < GROUND_ROW:
            put(img, x, y_top + 1, "E4")
    # One crack, some barnacles in a cluster, and weed where the tide last touched it.
    line(img, x0 + 13, top + 3, x0 + 16, top + 8, "E1")
    line(img, x0 + 16, top + 8, x0 + 14, top + 12, "E1")
    for _ in range(10):
        x, y = rng.randrange(x0 + 22, x1 - 3), rng.randrange(top + 7, GROUND_ROW - 1)
        put(img, x, y, "C6" if rng.random() > 0.5 else "C5")
    for x in range(x0 + 2, x1 - 1):
        hang = noise(x / 3.0, 17.0)
        if hang > 0.58:
            length = 1 + round((hang - 0.58) * 13)
            line(img, x, GROUND_ROW - 6, x, GROUND_ROW - 6 + length, "T1" if x % 3 else "T2")
    # Low stones at the foot, inside the walkable area but too small to matter.
    for sx, sw, sh in ((x0 - 8, 7, 3), (x0 - 3, 4, 2), (x1 + 3, 6, 3), (x1 + 8, 3, 1)):
        for x in range(sx, sx + sw):
            rise = round(sh * math.sin(math.pi * (x - sx + 0.5) / sw))
            for k in range(rise + 1):
                put(img, x, GROUND_ROW - k, "E3" if k < rise else "E5")
    hline(img, x0 - 8, x1 + 11, GROUND_ROW + 1, "E0")


def draw_side_cliff(img, noise, edge_x, foot_x, top_x, direction, seed):
    """A rock mass in dipping strata of uneven thickness, widening toward the top so it frames the view.
    On the left its foot is the collision wall; on the right draw_passage opens a way through."""
    rng = random.Random(seed)
    bands = []
    u = -80
    while u < GROUND_ROW + 160:
        thick = rng.choice((5, 7, 8, 10, 12, 15, 19, 26))
        bands.append((u, u + thick, rng.randrange(-8, 9), len(bands)))
        u += thick

    def band_at(value):
        for band in bands:
            if band[0] <= value < band[1]:
                return band
        return bands[-1]

    for row in range(0, GROUND_ROW + 3):
        f = max(0.0, (GROUND_ROW - row) / GROUND_ROW)
        reach = foot_x + (top_x - foot_x) * f ** 1.35
        band = band_at(row)
        r = (row - band[0]) / (band[1] - band[0])
        near_player = row > GROUND_ROW - 34
        if near_player:
            offset = (noise(row / 3.5, seed + 2) - 0.5) * 2.0
        else:
            # Large weathered bulges, then each stratum sticking out or set back.
            bulge = (noise(row / 34.0, seed) - 0.5) * 34 * min(1.0, f * 2.0)
            offset = bulge + band[2] * (0.15 + 0.55 * f) + (1 - r) * 1.5 + (noise(row / 3.5, seed + 2) - 0.5) * 2.5
        edge = round(reach + direction * offset)
        xs = range(edge_x, edge + 1) if direction > 0 else range(edge, edge_x + 1)
        for x in xs:
            dist = abs(edge - x)
            # The strata dip into the cliff and wander a little.
            v = row + dist * 0.24 + 3.0 * (noise(dist / 10.0, row / 18.0 + seed) - 0.5)
            inner = band_at(v)
            local = v - inner[0]
            thick = inner[1] - inner[0]
            facet = noise(x / 19.0 + row / 37.0, row / 13.0 + seed)
            value = 1.85 - dist * 0.03 + (facet - 0.5) * 1.8 + 0.4 * f
            if local < 1.3:
                value += 1.0  # A lit top on each stratum.
            elif thick - local < 1.8:
                value -= 0.9  # A shadow under it.
            if thick > 8 and (dist + inner[3] * 7) % 29 == 0 and local > 1.5:
                value = 0.2  # An occasional vertical crack.
            put(img, x, row, ramp(MUD, value, x, row, 0.2))
        put(img, edge, row, "C6" if r < 0.3 else ("C5" if noise(row / 3.0, seed + 1) > 0.4 else "E4"))
        put(img, edge - direction, row, "E4")
        if row > GROUND_ROW - 64 and rng.random() > 0.8:
            put(img, edge - direction * rng.randrange(2, 14), row, "T1")


def draw_passage(img, ground, foot_x, width):
    """A dark cleft through the foot of the right cliff, on the walkable ground. It rises from the left
    jamb to clear the sailor's head, and meets the unlit greybox backdrop at the world's edge."""
    for x in range(foot_x - 1, width):
        for y in range(GROUND_ROW, GROUND_ROW + 3):
            img.putpixel((x, y), ground.getpixel((x, y)))
    x1 = width - 1
    for x in range(PASSAGE_X, width):
        clear = round(PASSAGE_HEIGHT * math.sqrt(1 - ((x1 - x) / (x1 - PASSAGE_X)) ** 2))
        for y in range(GROUND_ROW - clear, GROUND_ROW):
            put(img, x, y, "C0")
        put(img, x, GROUND_ROW - clear - 1, "E0")


def foreground(width=720):
    """Near-camera stones along the bottom edge, in near-black. Never above row 250, so feet stay clear."""
    img = blank(width, HEIGHT)
    noise = Noise(83)
    stones = [(-6, 34, 15), (40, 24, 8), (118, 40, 7), (214, 30, 5), (312, 54, 10), (398, 26, 6), (498, 44, 8), (592, 30, 6), (664, 62, 17)]
    for sx, sw, sh in stones:
        for x in range(sx, sx + sw):
            if not 0 <= x < width:
                continue
            arc = math.sin(math.pi * (x - sx + 0.5) / sw) ** 0.6
            h = round(sh * arc * (0.88 + 0.24 * noise(x / 6.0, sx)))
            top = HEIGHT - h
            for y in range(top, HEIGHT):
                put(img, x, y, "C0")
            if h > 1:
                put(img, x, top, "E1")
    for x in range(width):
        put(img, x, HEIGHT - 1, "C0")
        put(img, x, HEIGHT - 2, "C0")
    return img


def glints(frame, frames=4):
    """Sea highlights under the moon, on their own layer. The moon's path follows the viewer, as it really does."""
    img = blank(480, HEIGHT)
    rng = random.Random(100 + frame)
    center = MOON[0]
    for y in range(HORIZON + 1, TIDE_LINE - 1):
        f = (y - HORIZON) / (TIDE_LINE - HORIZON)
        half = 7 + 26 * f
        count = 2 + round(5 * f)
        for _ in range(count):
            x = round(center + rng.gauss(0, half * 0.55))
            length = rng.randrange(1, 3 + round(5 * f))
            color = "C9" if rng.random() > 0.72 else ("C8" if rng.random() > 0.4 else "C7")
            hline(img, x, x + length, y, color)
    # A few restrained highlights away from the path.
    for _ in range(9):
        x, y = rng.randrange(480), rng.randrange(HORIZON + 3, TIDE_LINE - 1)
        hline(img, x, x + rng.randrange(1, 4), y, "T3" if rng.random() > 0.3 else "T4")
    return img


def talisman():
    """A carved disc on a rotted cord, half in the mud: an eye above a line of waves. The mark recurs on the way to the monolith."""
    img = blank(16, 11)
    # The cord, trailing off to the left.
    for x, y in ((0, 9), (1, 8), (2, 8), (3, 7), (4, 7)):
        put(img, x, y, "E2")
    # The disc.
    for y, (x0, x1) in enumerate(((7, 11), (6, 12), (5, 13), (5, 13), (5, 13), (5, 13), (5, 13), (6, 12), (7, 11))):
        for x in range(x0, x1 + 1):
            put(img, x, y + 1, "C4" if y < 4 else "C3")
    for x in range(7, 12):
        put(img, x, 1, "C6")
    # The eye, then the waves.
    for x in range(7, 12):
        put(img, x, 3, "T4")
    put(img, 6, 4, "T4")
    put(img, 12, 4, "T4")
    put(img, 9, 4, "C0")
    for x in range(7, 12):
        put(img, x, 5, "T3")
    for x, y in ((6, 8), (7, 7), (8, 8), (9, 7), (10, 8), (11, 7), (12, 8)):
        put(img, x, y, "T3")
    # Mud over its lower edge, so it sits in the ground rather than on it.
    for x in range(4, 15):
        put(img, x, 10, "E2")
    for x in (5, 6, 12, 13):
        put(img, x, 9, "E2")
    return img


def fish_prop():
    """A dead fish on the sand, for the sense that the sea left suddenly. Used sparingly."""
    img = blank(14, 6)
    rows = ["......EEE.....", "..EFFFFFFFFE..", ".EFFDFFFFFFFEE", "..EFFFFFFFFE.E", "....GGGGGG....", ".............."]
    colors = {"E": "C5", "F": "C7", "D": "C0", "G": "E1"}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                put(img, x, y, colors[ch])
    return img
