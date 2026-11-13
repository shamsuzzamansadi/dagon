"""Draws the Exposed Abyss and the canyon to the Monolith, past the finished reference section: world x 1440 to 4544.
Same palette, row plan and methods as the Shore (gen_shore.py) and the reference section (gen_cave.py), which it
continues without a seam: the ground uses that section's own noise and formula where the two meet.

Images are 270 rows tall, and row 220 is world y = 0. Nothing here changes where anything can be walked: every
surface is read from the collision in scenes/level/shore.tscn, and check_art.py compares the two.

    abyss_ground_<n>.png   world space, x 1440-4544 in four tiles: the seabed, the hollow under the slab, the rocks
"""

import math
import random
import re
from pathlib import Path

import gen_cave
import gen_reveal
from art_common import BAYER, Noise, blank, hline, line, put, ramp

ROOT = Path(__file__).resolve().parents[2]
SCENE = ROOT / "project" / "scenes" / "level" / "shore.tscn"

HEIGHT = 270
GROUND_ROW = 220
X0 = 1440
X1 = 4544
TILES = 4
TILE_W = (X1 - X0) // TILES
# The level's last wall, at the trench. It keeps its collision and is not drawn, as it would cut through the creature.
END_WALL_X = 4520

MUD = ["E0", "E1", "E2", "E3", "E4", "E5"]
DEEP = ["C0", "E0", "E1", "E2", "E3"]
COLD = ["C0", "C1", "C2", "C3", "C4", "C5"]
# Where the collision has a block to climb: drawn as rock, not as mud.
ROCKS = [(2780, 2812), (3004, 3036), (3584, 3612)]
HOLLOW = (2150, 2290)


def scene_text():
    return SCENE.read_text()


def collision_surface():
    """The walkable top of the terrain from the reference section's end to the trench, as (x, y) with y down."""
    match = re.search(r'\[node name="Ground" type="CollisionPolygon2D" parent="Terrain"\]\npolygon = PackedVector2Array\(([^)]*)\)', scene_text())
    numbers = [float(n) for n in match.group(1).split(",")]
    points = list(zip(numbers[0::2], numbers[1::2]))
    first = next(i for i, p in enumerate(points) if p == (1420.0, 0.0))
    last = next(i for i, p in enumerate(points) if p == (4520.0, 0.0))
    return points[first : last + 1] + [(X1, 0.0)]


SURFACE = collision_surface()


def surface_y(x):
    """World y of the walkable top at x, matching the collision, including its vertical steps."""
    best = SURFACE[-1][1]
    for (x0, y0), (x1, y1) in zip(SURFACE, SURFACE[1:]):
        if x0 != x1 and x0 <= x < x1:
            best = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return best


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return a + (b - a) * t


def smooth(x, a, b):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def in_rock(x):
    return any(a <= x < b for a, b in ROCKS)


def rock_side(x):
    """-1 at a rock's left edge to 1 at its right, the side the moon is on."""
    for a, b in ROCKS:
        if a <= x < b:
            return 2.0 * (x - a) / (b - a - 1) - 1.0
    return 0.0


# ---------------------------------------------------------------- the ground


def ground():
    """One strip, x 1440 to 4544. Dried crust as outside the cave, going black and wet as the Abyss deepens, and
    worn stone underfoot where the canyon closes round the Monolith."""
    width = X1 - X0
    img = blank(width, HEIGHT)
    # Behind the mud, which then lies against their feet.
    paste(img, rib_arch(), None)
    paste(img, crossing_ledges(), None)
    paste(img, crossing_pillar(), None)
    noise = Noise(301)  # The reference section's own, so the mud carries on across x = 1440.
    stone = Noise(331)
    draw_props_behind(img, noise)
    for col in range(width):
        x = X0 + col
        top = round(GROUND_ROW + surface_y(x + 0.5))
        wet = smooth(x, 1650, 2350) * (1 - smooth(x, 3380, 3600))
        paved = smooth(x, 3420, 3620)
        rock = in_rock(x)
        for y in range(top, HEIGHT):
            # Under a rock the mud is as deep as beside it.
            depth = y - (GROUND_ROW if rock else top)
            strata = noise(x / 31.0, y / 3.0)
            crack = noise.fractal(x / 9.0, y / 9.0, 2)
            crust = 3.9 - depth * 0.07 + (strata - 0.5) * 0.8 - (1.4 if 0.47 < crack < 0.5 else 0.0)
            black = 2.7 - depth * 0.05 + (strata - 0.5) * 0.6 - (1.0 if 0.47 < crack < 0.49 else 0.0) + 0.5 * (noise(x / 60.0, 5.0) - 0.5)
            value = mix(crust, black, wet)
            if paved > 0:
                # Flags: long worn stones, their joints dark, a little colder than the mud.
                course = (y - GROUND_ROW) // 9
                joint = (x + course * 17 + round(6 * stone(course * 3.1, 2.0))) % 46
                flag = 3.3 - depth * 0.05 + (stone(x / 23.0 + course, y / 5.0) - 0.5) * 1.0
                if joint < 1 or (y - GROUND_ROW) % 9 == 8:
                    flag -= 1.3
                value = mix(value, flag, paved)
            if rock and y <= GROUND_ROW:
                f = (y - top) / 14.0
                facet = stone(x / 10.0 + y / 15.0, y / 8.0 - x / 25.0)
                value = 3.5 - 1.9 * f + (facet - 0.5) * 2.2 + 0.6 * rock_side(x)
            put(img, col, y, ramp(MUD, value, x, y, 0.3))
        lit = noise(x / 8.0, 4.0)
        if rock:
            put(img, col, top, "C5" if stone(x / 5.0, 3.0) > 0.5 else "E5")
            put(img, col, top + 1, "E4")
            continue
        dry_top = "E5" if lit > 0.3 else "E4"
        wet_top = "E4" if lit > 0.45 else "E3"
        put(img, col, top, wet_top if wet > 0.5 else dry_top)
        put(img, col, top + 1, ("E3" if lit > 0.55 else "E2") if wet > 0.5 else ("E4" if lit > 0.55 else "E3"))
        glint = noise(x / 5.0, 12.0)
        if glint > 0.76:
            put(img, col, top, "C6")
        elif wet > 0.5 and glint < 0.2:
            put(img, col, top, "T2")
    draw_faces(img, noise)
    draw_rock_feet(img, stone)
    draw_hollow(img, noise)
    draw_dressing(img, noise)
    draw_props(img, noise)
    draw_footprint(img, noise)
    draw_prints(img)
    # The ground runs on under the last wall, which is not drawn, and past it breaks off into the trench, where nobody
    # can stand: the crust falls away to the water, its broken edge lit.
    for x in range(TRENCH_LIP, X1):
        col = x - X0
        drop = round((TRENCH_WATER + 2) * smooth(x, TRENCH_LIP, X1) + 3 * noise(x / 3.0, 61.0))
        for row in range(GROUND_ROW - 40, GROUND_ROW + drop):
            img.putpixel((col, row), (0, 0, 0, 0))
        put(img, col, GROUND_ROW + drop, "E4" if noise(x / 2.0, 62.0) > 0.4 else "E3")
        put(img, col, GROUND_ROW + drop + 1, "E2")
    return img


def draw_faces(img, noise):
    """Every step in the ground has a face. One that looks toward the moon is lit down its edge, the other is in shadow."""
    for (x0, y0), (x1, y1) in zip(SURFACE, SURFACE[1:]):
        if x0 != x1 or x0 >= END_WALL_X or x0 < X0:
            continue
        upper, lower = round(GROUND_ROW + min(y0, y1)), round(GROUND_ROW + max(y0, y1))
        faces_right = y1 > y0  # The ground drops to the right of this x.
        col = int(x0) - X0 - (1 if faces_right else 0)
        for y in range(upper, min(lower, HEIGHT)):
            lit = noise(y / 4.0, x0 / 7.0)
            if faces_right:
                put(img, col, y, "E5" if lit > 0.6 else "E4")
                put(img, col - 1, y, "E4" if lit > 0.5 else "E3")
            else:
                put(img, col, y, "E1" if lit > 0.4 else "E0")
                put(img, col + 1, y, "E2" if lit > 0.5 else "E1")
        put(img, col, upper, "C6" if faces_right else "E3")


def draw_rock_feet(img, stone):
    """Each rock sits in the mud: broken stone banked against its foot, and a crack or two down its face. Its top and
    sides stay exactly where the collision has them."""
    rng = random.Random(333)
    for a, b in ROCKS:
        for side, x_edge, step in ((-1, a, -1), (1, b - 1, 1)):
            # Rubble, falling away from the rock.
            for i in range(1, 9):
                h = max(0, round(5 - i * 0.6 + 2 * (stone((x_edge + i * step) / 2.0, 9.0) - 0.5)))
                for k in range(h):
                    put(img, x_edge + i * step - X0, GROUND_ROW - 1 - k, ("E4" if side > 0 else "E3") if k == h - 1 else "E2")
        for _ in range(2):
            x = rng.randrange(a + 5, b - 5)
            y = GROUND_ROW - rng.randrange(8, 13)
            for k in range(rng.randrange(4, 9)):
                put(img, x - X0 + (k // 3) * rng.choice((-1, 1)), y + k, "E1")


def draw_hollow(img, noise):
    """The hollow under the slab: black standing water along its floor, and its floor darker than the seabed above."""
    left, right = HOLLOW
    floor = GROUND_ROW + 48
    for x in range(left + 24, right - 2):
        if noise(x / 14.0, 71.0) > 0.35:
            put(img, x - X0, floor, "T1" if noise(x / 3.0, 72.0) > 0.4 else "T0")
            if noise(x / 3.0, 73.0) > 0.78:
                put(img, x - X0, floor, "C6")


def draw_dressing(img, noise):
    """What the sea left, thinning as the Abyss deepens: shells and bone in loose drifts, dead weed, standing water,
    and nearer the Monolith small stones fallen from the canyon's walls."""
    rng = random.Random(332)
    # Drifts of shell and bone, as on the seabed outside the cave.
    for cx, spread, n in ((1520, 40, 10), (1700, 60, 16), (1930, 40, 9), (2420, 70, 14), (2660, 50, 10), (3120, 80, 16), (3320, 50, 9)):
        for _ in range(n):
            x = cx + rng.randrange(-spread, spread)
            y = GROUND_ROW + round(surface_y(x)) + rng.randrange(2, 30)
            size = rng.choice((1, 1, 2, 3))
            hline(img, x - X0, x - X0 + size, y, rng.choice(("E4", "E5", "C6")))
            hline(img, x - X0, x - X0 + size, y + 1, "E1")
    # Dead weed lying on the mud.
    for x0, length in ((1470, 16), (1650, 24), (1790, 12), (2330, 20), (2520, 14), (2700, 18), (3080, 22), (3260, 12)):
        for i in range(length):
            x = x0 + i
            row = GROUND_ROW + round(surface_y(x))
            if rng.random() > 0.25:
                put(img, x - X0, row - 1, "T1" if rng.random() > 0.4 else "T0")
            if rng.random() > 0.6:
                put(img, x - X0, row - 2, "T2")
    # Standing water, in the wet stretch.
    for x0, x1 in ((2360, 2400), (2470, 2496), (2620, 2670), (2880, 2930), (3140, 3190), (3290, 3318)):
        for x in range(x0, x1):
            edge = min(x - x0, x1 - 1 - x)
            if edge < 1:
                continue
            row = GROUND_ROW + round(surface_y(x)) + 1
            put(img, x - X0, row, "T1")
            if edge > 2:
                put(img, x - X0, row + 1, "T0")
            if noise(x / 3.0, 22.0) > 0.62:
                put(img, x - X0, row, "C6")
    # Stones fallen from the walls, where the canyon closes in.
    for _ in range(46):
        x = rng.randrange(3460, END_WALL_X - 4)
        if in_rock(x) or 3836 < x < 4300:
            continue
        w = rng.choice((2, 3, 3, 4, 5))
        row = GROUND_ROW + round(surface_y(x))
        for i in range(w):
            h = 1 + (1 if 0 < i < w - 1 and w > 3 else 0)
            for k in range(h):
                put(img, x + i - X0, row - 1 - k, "E4" if k == h - 1 else "E2")
        put(img, x - X0, row - 1, "E3")


# ---------------------------------------------------------------- the far view

# The far layer's own space: it moves at 0.35 of the camera, so 1 px of it passes for about 3 px of the route.
FAR_X0 = 680  # Where the reference section's far view (gen_cave.abyss_far) ends.
FAR_X1 = 2140
ESCARPMENT_X0 = 700
# The far cliff's top, as (x in the layer, world y). It is as high as it is for two things that are not this
# milestone's to draw: the distant shape rises from behind it between 960 and 1118, and must have its foot hidden
# before and after it moves; the watcher stands on the level stretch at 1262 to 1298, at y = -140 exactly.
ESCARPMENT_TOP = [(700, -80), (740, -90), (790, -101), (860, -126), (930, -151), (960, -158), (1130, -157), (1180, -149), (1250, -141),
    (1262, -140), (1298, -140), (1310, -138), (1380, -125), (1470, -106), (1560, -97), (1700, -102), (1850, -117),
    (2000, -127), (2140, -131)]
WATCHER_LEDGE = (1262, 1298)
ESCARPMENT = ["C0", "C1", "C2", "C3"]


def far_plain():
    """The plain and its far ridges, carried on from the reference section's far view to the canyon."""
    return gen_cave.abyss_far(FAR_X0, FAR_X1 - FAR_X0, spires=(95, 388, 810, 1240))


def escarpment_top(x, noise):
    """World y of the far cliff's top at x in the layer."""
    for (x0, y0), (x1, y1) in zip(ESCARPMENT_TOP, ESCARPMENT_TOP[1:]):
        if x0 <= x <= x1:
            y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
            break
    else:
        return 0.0
    if WATCHER_LEDGE[0] <= x <= WATCHER_LEDGE[1]:
        return y
    # Broken, but only upward where the shape hides, so its foot never shows.
    rough = 3.0 * noise(x / 6.0, 71.0) + 4.0 * noise(x / 19.0, 72.0)
    edge = min(1.0, (x - ESCARPMENT_X0) / 40.0)
    return y - rough * edge * (0.6 if 930 <= x <= 1250 else 1.0)


def escarpment():
    """A far cliff across the seabed, darker than the sky behind it, its top edge caught by the moon. Its foot is lost
    in the mist on the plain."""
    width = FAR_X1 - ESCARPMENT_X0
    img = blank(width, HEIGHT)
    noise = Noise(341)
    foot = 138
    for col in range(width):
        x = ESCARPMENT_X0 + col
        top = round(GROUND_ROW + escarpment_top(x, noise))
        if top >= foot:
            continue
        crack = noise(x / 2.5, 77.0)
        for y in range(top, foot + 6):
            depth = y - top
            if y >= foot - 6:
                # Mist takes the foot: fewer and fewer of its pixels.
                keep = (foot + 6 - y) / 12.0 * (0.6 + 0.8 * noise(x / 30.0, 79.0))
                if (BAYER[y % 4][x % 4] + 0.5) / 16.0 > keep:
                    continue
            # Broad faces of rock leaning one way, and beds lying across them: no two columns alike.
            face = noise.fractal((x + depth * 0.5) / 34.0, y / 30.0, 3)
            beds = noise(x / 60.0, (y + 5.0 * noise(x / 40.0, 83.0)) / 5.0)
            value = 0.35 + 1.6 * math.exp(-depth / 2.0) + (face - 0.5) * 2.2 + (beds - 0.5) * 0.5
            if crack > 0.86 and 2 < depth < 8 + 40 * noise(x / 7.0, 85.0):
                value -= 0.8
            put(img, col, y, ramp(ESCARPMENT, value, x, y, 0.45))
        put(img, col, top, "C4" if noise(x / 4.0, 81.0) > 0.45 else "C3")
    return img


# ---------------------------------------------------------------- stone standing on the seabed

STONE = ["E2", "E3", "E4", "E5", "C6", "C7"]
ROCK = ["C0", "E0", "E1", "E2", "E3", "E4"]


def scene_shape(name, parent, offset=(0.0, 0.0)):
    return [(x + offset[0], y + offset[1]) for x, y in gen_reveal.scene_polygon(name, parent)]


def _covers(points, x, y):
    """Whether a polygon covers the centre of a pixel: the same pixels the engine fills, and no more."""
    return gen_reveal._in_polygon(points, x + 0.5, y + 0.5)


def stone_from(shapes, seed, colors=STONE, level=2.3, grain=1.5):
    """Stone that fills the given shapes pixel for pixel: lit along the top and on the side the moon is on, dark
    beneath and on the other side, faceted and cracked between. Returns the image and its origin."""
    left = math.floor(min(x for shape in shapes for x, _ in shape))
    top = math.floor(min(y for shape in shapes for _, y in shape))
    width = math.ceil(max(x for shape in shapes for x, _ in shape)) - left
    height = math.ceil(max(y for shape in shapes for _, y in shape)) - top
    filled = [[any(_covers(shape, left + c, top + r) for shape in shapes) for c in range(width)] for r in range(height)]

    def at(c, r):
        return 0 <= c < width and 0 <= r < height and filled[r][c]

    img = blank(width, height)
    noise = Noise(seed)
    for r in range(height):
        for c in range(width):
            if not filled[r][c]:
                continue
            x, y = left + c, top + r
            above = 0
            while above < 12 and at(c, r - 1 - above):
                above += 1
            facet = noise(x / 7.0 + y / 11.0, y / 6.0 - x / 17.0)
            value = level + (1.7 if above == 0 else 0.7 if above == 1 else 0.0) - above * 0.07 + (facet - 0.5) * grain
            value += (0.8 if not at(c + 1, r) else 0.0) - (0.9 if not at(c - 1, r) else 0.0) - (0.8 if not at(c, r + 1) else 0.0)
            crack = noise.fractal(x / 5.0, y / 5.0, 2)
            if 0.48 < crack < 0.5 and above > 1:
                value -= 1.3
            put(img, c, r, ramp(colors, value, x, y, 0.3))
    return img, (left, top)


def paste(img, part, at):
    """Lays a part into the strip by its world origin."""
    part_img, (x, y) = part if at is None else (part, at)
    img.alpha_composite(part_img, (round(x) - X0, GROUND_ROW + round(y)))


# ---------------------------------------------------------------- the crossing

def crossing_ledges():
    """The three ledges up to the stone, each a slab of paler rock on a stack of dark, and the post the great slab
    turns on, down in the hollow."""
    img = blank(160, 120)
    origin = (2030, -70)
    for index, name in enumerate(("SupportHigh", "SupportMid", "SupportLow")):
        part, at = stone_from([scene_shape(name, "CrossingLedges")], 361 + index, ROCK, 2.0 + 0.2 * index, 1.8)
        img.alpha_composite(part, (at[0] - origin[0], at[1] - origin[1]))
    for index, name in enumerate(("Shelf", "Mid", "Low")):
        part, at = stone_from([scene_shape(name, "CrossingLedges")], 365 + index, STONE, 2.5, 1.0)
        img.alpha_composite(part, (at[0] - origin[0], at[1] - origin[1]))
    return img, origin


def crossing_pillar():
    return stone_from([gen_reveal.scene_polygon("Pillar", ".")], 369, ROCK, 2.4, 1.6)


def crossing_slab():
    """The great slab, in its own space as the scene turns it: one long stone, cracked through near one end, with the
    wave cut small into the end the stone must fall on."""
    slab, origin = stone_from([gen_reveal.scene_polygon("Slab", "Crossing")], 371, STONE, 2.6, 1.0)
    for x, y in ((-24, -3), (-23, -2), (-23, -1), (-24, 0), (-23, 1), (-23, 2), (-24, 3)):
        put(slab, x - origin[0], y - origin[1], "E1")
        put(slab, x + 1 - origin[0], y - origin[1], "E3")
    mark = gen_reveal.scene_polygon("Mark", "Crossing")
    for y in range(-4, 4):
        for x in range(30, 56):
            if _covers(mark, x, y):
                put(slab, x - origin[0], y - origin[1], "T4")
    return slab, origin


def crossing_stone():
    """The stone to be pushed: a boulder the size of a man's chest, rounded by the sea."""
    stone, origin = stone_from([gen_reveal.scene_polygon("Art", "CrossingStone")], 373, STONE, 2.9, 1.2)
    return stone, origin


# ---------------------------------------------------------------- what stands along the way

BONE_OLD = ["E2", "E3", "E4", "E5", "C6", "C7"]
PROPS = {name: None for name in ("FossilB", "TabletKneel", "Footprint", "TabletEye", "Relief", "Cairn", "Statue")}


def prop_position(name):
    match = re.search(r'\[node name="%s" type="Interactable" parent="Props"\]\nposition = Vector2\(([-0-9.]+), ([-0-9.]+)\)' % name, scene_text())
    return float(match.group(1)), float(match.group(2))


def prop_shape(prop, part):
    """A part of a prop, in world space: the prop's place, the part's own offset and scale, and its shape."""
    text = scene_text()
    block = re.search(r'\[node name="%s" type="Polygon2D" parent="Props/%s"\]\n(.*?)\n\n' % (part, prop), text, re.S).group(1)
    offset = re.search(r"position = Vector2\(([-0-9.]+), ([-0-9.]+)\)", block)
    ox, oy = (float(offset.group(1)), float(offset.group(2))) if offset else (0.0, 0.0)
    scale = re.search(r"scale = Vector2\(([-0-9.]+), ([-0-9.]+)\)", block)
    sx, sy = (float(scale.group(1)), float(scale.group(2))) if scale else (1.0, 1.0)
    px, py = prop_position(prop)
    numbers = [float(n) for n in re.search(r"polygon = PackedVector2Array\(([^)]*)\)", block).group(1).split(",")]
    return [(x * sx + px + ox, y * sy + py + oy) for x, y in zip(numbers[0::2], numbers[1::2])]


def carve(img, shapes, cut="E0", fill="T3", lip="T4"):
    """A sign cut into stone, in the strip: dark under its upper edge, where the moon cannot reach in, and bright
    along its lower lip, as on the first tablet. The same on every stone, so one can be known from another."""
    def covered(x, y):
        return any(_covers(shape, x, y) for shape in shapes)
    left = math.floor(min(x for shape in shapes for x, _ in shape))
    right = math.ceil(max(x for shape in shapes for x, _ in shape))
    top = math.floor(min(y for shape in shapes for _, y in shape))
    bottom = math.ceil(max(y for shape in shapes for _, y in shape))
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            if not covered(x, y):
                continue
            color = fill
            if not covered(x, y + 1):
                color = lip
            elif not covered(x, y - 1):
                color = cut
            put(img, x - X0, GROUND_ROW + y, color)


def draw_tablet(img, noise, shape):
    """A standing slab like the first, outside the cave (gen_cave.draw_tablet), lit and edged as it is, filling its
    own shape in the scene: the one in the recess is smaller, to stand under the shelf."""
    left, right = math.floor(min(x for x, _ in shape)), math.ceil(max(x for x, _ in shape))
    top, bottom = math.floor(min(y for _, y in shape)), math.ceil(max(y for _, y in shape))
    cx = (left + right) / 2
    for y in range(top, bottom):
        for x in range(left, right + 1):
            if not _covers(shape, x, y):
                continue
            facet = noise(x / 6.0, y / 7.0)
            value = 3.0 + (facet - 0.5) * 1.0 + (0.6 if x < cx else 0.0) - (y - top) * 0.02
            color = ramp(MUD, value, x, y, 0.2)
            if not _covers(shape, x, y - 1):
                color = "C6"
            elif not _covers(shape, x - 1, y):
                color = "C5"
            elif not _covers(shape, x + 1, y):
                color = "E1"
            put(img, x - X0, GROUND_ROW + y, color)


def draw_props_behind(img, noise):
    """What the way passes in front of, or under: put down before the ground, so the mud lies against its foot."""
    # Under the first shelf: a hollowed face of the rock, and the procession cut into it.
    paste(img, stone_from([scene_shape("Alcove", "ActArt")], 381, ROCK, 0.9, 1.2), None)
    paste(img, stone_from([prop_shape("Relief", "Panel")], 382, ROCK, 2.1, 0.9), None)
    draw_walkers(img)
    carve(img, [prop_shape("Relief", "Sea"), prop_shape("Relief", "Arm")])
    # What holds the second shelf up: two leaning props of rock, behind the way under it.
    for x, lean in ((3440, 5), (3548, -4)):
        post = [(x, 0), (x + lean, -28), (x + lean + 9, -28), (x + 10, 0)]
        paste(img, stone_from([post], 383 + x, ROCK, 1.5, 1.4), None)
    for name, seed in (("ShelfA", 385), ("ShelfB", 386)):
        paste(img, stone_from([scene_shape(name, "Ledges")], seed, STONE, 2.5, 1.0), None)


# A robed figure walking toward the sea, its head bowed: too small for the scene's shapes to say, so drawn by hand.
WALKER = ["..##.", "..##.", "...#.", ".###.", ".####", ".###.", ".###.", ".###.", ".####", ".####", "#####"]
STRIDES = [".#.#.", "#...#"]


def draw_walkers(img):
    """The procession, one figure on each walker's shape and standing on its foot, cut as the rest of the relief."""
    for i in range(1, 6):
        shape = prop_shape("Relief", f"Walker{i}")
        left = round((min(x for x, _ in shape) + max(x for x, _ in shape)) / 2) - 2
        rows = WALKER + [STRIDES[i % 2]]
        top = round(max(y for _, y in shape)) - len(rows)
        lit = {(left + c, top + r) for r, line_ in enumerate(rows) for c, mark in enumerate(line_) if mark == "#"}
        for x, y in lit:
            color = "E3" if (x, y + 1) not in lit else "E5" if (x, y - 1) not in lit else "E4"
            put(img, x - X0, GROUND_ROW + y, color)


def draw_props(img, noise):
    """What he can stop and look at."""
    # The second fossil: a skull as long as a man, one socket, lying where the ribs stand.
    paste(img, stone_from([prop_shape("FossilB", "Art")], 391, BONE_OLD, 3.0, 1.2), None)
    carve(img, [prop_shape("FossilB", "Socket")], cut="E0", fill="E0", lip="E1")
    for prop in ("TabletKneel", "TabletEye"):
        draw_tablet(img, noise, prop_shape(prop, "Art"))
    carve(img, [prop_shape("TabletKneel", "Mark")])
    carve(img, [prop_shape("TabletEye", "Mark")])
    carve(img, [prop_shape("TabletEye", "Pupil")], cut="E0", fill="E0", lip="E0")
    paste(img, stone_from([prop_shape("Cairn", "Stack")], 392, STONE, 2.4, 1.6), None)
    carve(img, [prop_shape("Cairn", "Mark")])
    paste(img, stone_from([prop_shape("Statue", "Figure")], 393, STONE, 2.3, 1.2), None)
    carve(img, [prop_shape("Statue", "Mark")])


def draw_footprint(img, noise):
    """The print: pressed into the mud and seen from a little above, so it lies down the face of the ground with its
    toes toward us. Water stands in it."""
    shape = prop_shape("Footprint", "Art")
    flipped = [(x, 2 - y * 0.8) for x, y in shape]
    carve(img, [flipped], cut="E0", fill="E0", lip="E4")
    for x in range(round(min(x for x, _ in shape)) + 6, round(max(x for x, _ in shape)) - 6):
        if _covers(flipped, x, 4) and noise(x / 2.0, 91.0) > 0.45:
            put(img, x - X0, GROUND_ROW + 4, "T2" if noise(x / 3.0, 92.0) > 0.5 else "T1")
    # What shows over the prompt when he stands at it: the dent along the edge of the ground, and the mud its three
    # toes pushed up, lit on top.
    left, right = round(min(x for x, _ in shape)), round(max(x for x, _ in shape))
    for x in range(left + 3, right - 2):
        put(img, x - X0, GROUND_ROW + round(surface_y(x)), "E1")
    for (tx, ty), height in zip(sorted((p for p in shape if p[1] < -9), key=lambda p: p[0]), (2, 3, 2)):
        row = GROUND_ROW + round(surface_y(tx))
        for dx in range(-2, 3):
            h = height - (1 if abs(dx) == 2 else 0)
            for k in range(1, h + 1):
                put(img, round(tx) + dx - X0, row - k, "E4" if k == h else "E2" if dx < 0 else "E3")


def draw_prints(img):
    """Three small prints, a man's, pressed into the crust on the way to the ledges: dark in the dent, its far rim lit."""
    for i in range(3):
        shape = scene_shape(f"PrintDown{i}", "ActArt")
        left, right = round(min(x for x, _ in shape)), round(max(x for x, _ in shape))
        row = GROUND_ROW + round(surface_y(left))
        hline(img, left - X0, right - X0, row, "E1")
        put(img, left + 1 - X0, row + 1, "E0")
        put(img, right - 1 - X0, row + 1, "E0")
        put(img, right - X0, row - 1, "E4")


# ---------------------------------------------------------------- the canyon

def canyon_wall():
    """The canyon's far wall, which closes behind the Monolith and stands over it: dark, bedded rock, far darker than
    the Monolith's worked stone, so that stone is what the eye goes to. Its outline is the scene's, broken a little
    at the rim. Returns the image and its world origin."""
    shape = scene_shape("CanyonBack", "ActArt")
    x0, y0 = math.floor(min(x for x, _ in shape)), math.floor(min(y for _, y in shape))
    width, height = math.ceil(max(x for x, _ in shape)) - x0, -y0
    mask = gen_reveal.mask_of(shape, (x0, y0), (width, height))
    img = blank(width, height)
    noise = Noise(401)
    for col in range(width):
        x = x0 + col
        column = [row for row in range(height) if mask.getpixel((col, row))]
        if not column:
            continue
        # The rim is broken: it never rises above the scene's outline, only falls short of it.
        rim = column[0] + round(5 * noise(x / 9.0, 41.0) + 3 * noise(x / 3.0, 42.0))
        seep = noise(x / 7.0, 51.0) > 0.87 and x % 3 == 0
        for row in range(rim, height):
            y = y0 + row
            depth = row - rim
            beds = noise(x / 70.0 + y / 160.0, (y + 14.0 * noise(x / 90.0, 43.0)) / 6.0)
            mass = noise.fractal(x / 40.0, y / 55.0, 3)
            value = 1.25 + 1.3 * math.exp(-depth / 3.0) + (beds - 0.5) * 1.1 + (mass - 0.5) * 1.3 - 0.5 * max(0.0, (row - height + 60) / 60.0)
            # Joints: where a bed is split from top to bottom.
            if noise(x / 2.5, round(y / 46.0) * 7.0) > 0.9:
                value -= 0.8
            color = ramp(DEEP, value, x, y, 0.35)
            if seep and 30 < depth < 30 + 90 * noise(x / 5.0, 52.0) and (row + col) % 3:
                color = "T0"
            put(img, col, row, color)
        put(img, col, rim, "C3" if noise(x / 4.0, 44.0) > 0.5 else "C2")
    return img, (x0, y0)


# ---------------------------------------------------------------- the stones and the gate

GLYPH_STONES = {"GlyphKneel": ["Mark"], "GlyphEye": ["Mark"], "GlyphWave": ["MarkA", "MarkB"]}


def node_shape(name, parent):
    """A shape in its parent's own space, with its own offset: for art that goes where the shape is, as a child."""
    block = re.search(r'\[node name="%s" type="Polygon2D" parent="%s"\]\n(.*?)\n\n' % (name, re.escape(parent)), scene_text(), re.S).group(1)
    offset = re.search(r"position = Vector2\(([-0-9.]+), ([-0-9.]+)\)", block)
    ox, oy = (float(offset.group(1)), float(offset.group(2))) if offset else (0.0, 0.0)
    numbers = [float(n) for n in re.search(r"polygon = PackedVector2Array\(([^)]*)\)", block).group(1).split(",")]
    return [(x + ox, y + oy) for x, y in zip(numbers[0::2], numbers[1::2])]


def carve_into(img, origin, shapes, cut, fill, lip):
    """As carve(), into an image of its own."""
    def covered(x, y):
        return any(_covers(shape, x, y) for shape in shapes)
    for row in range(img.height):
        for col in range(img.width):
            x, y = col + origin[0], row + origin[1]
            if covered(x, y):
                put(img, col, row, lip if not covered(x, y + 1) else cut if not covered(x, y - 1) else fill)


def glyph_stone(name, lit=False):
    """One of the three stones at the Monolith's foot, with its sign: worn and dim until it is pressed, and then the
    same sign, bright. Unlit, the whole stone; lit, the sign alone, to lie over it."""
    parent = "Monolith/" + name
    body = node_shape("Art", parent)
    stone, origin = stone_from([body], 411 + len(name), STONE, 2.6, 1.0)
    marks = [node_shape(mark, parent) for mark in GLYPH_STONES[name]]
    if lit:
        stone = blank(*stone.size)
        carve_into(stone, origin, marks, cut="T3", fill="T4", lip="C9")
    else:
        carve_into(stone, origin, marks, cut="E0", fill="E2", lip="C6")
    return stone, origin


def gate():
    """The gate: one slab of the Monolith's own stone, as tall as the canyon lets be seen, banded where it was dressed.
    In the gate's own space."""
    slab, origin = stone_from([gen_reveal.scene_polygon("Visual", "Monolith/Gate")], 421, STONE, 2.3, 0.9)
    for row in range(slab.height):
        if row % 37 in (0, 1):
            for col in range(1, slab.width - 1):
                put(slab, col, row, "E1" if row % 37 == 0 else "E5")
    return slab, origin


# ---------------------------------------------------------------- the rib arch

RIBS = ["Rib1", "Rib2", "Rib3", "Rib4", "Rib5"]
BONE = ["E1", "E2", "E3", "E4", "E5", "C6", "C7", "C8"]


def _distance(points, x, y):
    """Distance from a point to a line drawn through points."""
    best = 1e9
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        dx, dy = x1 - x0, y1 - y0
        t = max(0.0, min(1.0, ((x - x0) * dx + (y - y0) * dy) / (dx * dx + dy * dy)))
        best = min(best, math.hypot(x - x0 - t * dx, y - y0 - t * dy))
    return best


def _along(points, x, y):
    """How far along a line drawn through points its nearest point to (x, y) lies, in pixels."""
    best, at, run = 1e9, 0.0, 0.0
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        dx, dy = x1 - x0, y1 - y0
        t = max(0.0, min(1.0, ((x - x0) * dx + (y - y0) * dy) / (dx * dx + dy * dy)))
        distance = math.hypot(x - x0 - t * dx, y - y0 - t * dy)
        if distance < best:
            best, at = distance, run + t * math.hypot(dx, dy)
        run += math.hypot(dx, dy)
    return at


def rib_arch():
    """Five ribs of something far larger than a whale, standing out of the mud and leaning over the way on. Each fills
    its own shape in the scene, short of the tip, where it snapped from the spine. Bleached along the back where the
    moon reaches, dark beneath, stained green where it stands in the mud, split across in places by its own weight.
    Returns the image and its world origin."""
    shapes = [gen_reveal.scene_polygon(name, "ActArt") for name in RIBS]
    x0 = math.floor(min(x for shape in shapes for x, _ in shape)) - 1
    y0 = math.floor(min(y for shape in shapes for _, y in shape)) - 1
    x1 = math.ceil(max(x for shape in shapes for x, _ in shape)) + 1
    img = blank(x1 - x0, -y0)
    noise = Noise(351)
    rng = random.Random(352)
    for index, shape in enumerate(shapes):
        mask = gen_reveal.mask_of(shape, (x0, y0), img.size)
        half = len(shape) // 2
        back, belly = shape[:half], shape[half:]
        length = sum(math.hypot(bx - ax, by - ay) for (ax, ay), (bx, by) in zip(back, back[1:]))
        # Cracks run in from the belly, where the weight pulls, each stopping part of the way across.
        cracks = sorted((rng.uniform(0.18, 0.85) * length, rng.uniform(0.15, 0.55)) for _ in range(3))
        left = math.floor(min(x for x, _ in shape)) - x0
        right = math.ceil(max(x for x, _ in shape)) - x0
        for col in range(left, right + 1):
            for row in range(img.height):
                if not gen_reveal.inside(mask, col, row):
                    continue
                x, y = col + x0 + 0.5, row + y0 + 0.5
                to_back, to_belly = _distance(back, x, y), _distance(belly, x, y)
                across = to_back / max(0.01, to_back + to_belly)
                along = _along(back, x, y)
                # Snapped off where it once met the spine: a splintered end, not a cut one.
                end = length - along
                splinter = 1.5 + 10.0 * noise(across * 9.0, index * 5.0 + 0.5)
                if end < splinter or abs(across - 0.45) > 0.2 + 0.35 * end / 14.0:
                    continue
                pit = noise(x / 3.0, y / 3.0 + index * 9.0)
                grain = noise((x + y) / 14.0, (x - y) / 3.0 + index)
                value = 6.0 - 4.4 * across + (grain - 0.5) * 1.2 - (1.0 if pit > 0.84 else 0.0) - 1.6 * max(0.0, 1.0 - along / length * 5.0)
                if end < splinter + 1.5:
                    value -= 1.2
                for at, reach in cracks:
                    if across > reach and abs(along - at) < 0.6:
                        value -= 2.4
                    elif across > reach + 0.1 and 0.6 <= along - at < 1.8:
                        value += 0.7
                color = ramp(BONE, value, col + x0, row, 0.3)
                # Weed and stain where it stands in the mud, and a little in the cracks' lee.
                if -y < 26 * noise(x / 6.0, 7.0 + index) and noise(x / 2.0, y / 4.0) > 0.52:
                    color = "T1" if across < 0.5 else "T0"
                put(img, col, row, color)
    return img, (x0, y0)


# ---------------------------------------------------------------- the mural

MURAL = ["WaveTop", "WaveLow", "Kneel", "Eye", "Symbol", "Swimmer", "ArmLeft", "ArmRight"] + [f"Bowing{i}" for i in range(1, 6)]
STATUE_EYES = ["EyesA", "EyesB"]
FRAGMENTS = ["FragmentWave", "FragmentKneel", "FragmentEye"]


def _canvas(shapes, pad=1):
    left = math.floor(min(x for shape in shapes for x, _ in shape)) - pad
    top = math.floor(min(y for shape in shapes for _, y in shape)) - pad
    right = math.ceil(max(x for shape in shapes for x, _ in shape)) + pad
    bottom = math.ceil(max(y for shape in shapes for _, y in shape)) + pad
    return blank(right - left, bottom - top), (left, top)


def mural_lit():
    """The mural as the stones light it: every cut in the panel filled with the same light as their signs, bright
    along its lower lip, and a groove's shadow round each figure where the light does not reach; the statues' eyes lit
    with it. One image in world space, for the node the awakening shows and fades."""
    panel = [scene_shape(name, "Monolith/MuralLit") for name in MURAL]
    eyes = [scene_shape(name, "Monolith/MuralLit") for name in STATUE_EYES]
    img, origin = _canvas(panel + eyes)

    def covered(x, y):
        return any(_covers(shape, x, y) for shape in panel)
    for row in range(img.height):
        for col in range(img.width):
            x, y = col + origin[0], row + origin[1]
            if not covered(x, y) and any(covered(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                put(img, col, row, "T1")
    carve_into(img, origin, panel, cut="T3", fill="T4", lip="C9")
    carve_into(img, origin, eyes, cut="C9", fill="C9", lip="T4")
    return img, origin


def mural_fragments():
    """What can be made out on the panel before it is lit: three signs, worn faint, cut as the rest of the stone."""
    shapes = [scene_shape(name, "Monolith") for name in FRAGMENTS]
    img, origin = _canvas(shapes)
    carve_into(img, origin, shapes, cut="E3", fill="E4", lip="C7")
    return img, origin


# ---------------------------------------------------------------- the statues and the trench


def statues():
    """The two figures either side of the stones, worn to the shape of the one on the second shelf: dark against the
    Monolith's face, as the greybox had them, lit only along their tops. One image, in world space."""
    return stone_from([scene_shape(name, "Monolith") for name in ("StatueA", "StatueB")], 395, ROCK, 1.6, 1.2)


# Past the last wall, x 4544 to 5400: never on screen in play, only when the camera draws back for what rises.
TRENCH_X1 = 5400
TRENCH_TOP = -700
TRENCH_BOTTOM = 60
TRENCH_WATER = 20
TRENCH_LIP = 4526
SKY = ["C0", "C1", "C2", "C3", "C4", "C5"]
FAR_SIDE = ["C0", "C1", "C2", "C3"]
WATER = ["C0", "T0", "T1", "T2"]


def trench():
    """What stands behind the creature: the night as the Shore's sky has it, going down to a haze the moon lights over
    the trench, kept lighter than the creature so its shape reads against it; the far side, a low black bank and its
    wall down to the water; and the water, black, the moon on it in a broken line. Origin (X1, TRENCH_TOP)."""
    width, height = TRENCH_X1 - X1, TRENCH_BOTTOM - TRENCH_TOP
    img = blank(width, height)
    noise = Noise(431)
    rng = random.Random(432)
    for col in range(width):
        x = X1 + col
        bank = -10 - round(7 * noise(x / 40.0, 3.0) + 3 * noise(x / 9.0, 4.0))
        for row in range(height):
            y = TRENCH_TOP + row
            if y >= TRENCH_WATER:
                depth = y - TRENCH_WATER
                value = 1.5 - depth * 0.04 + (noise(x / 13.0, y / 2.0) - 0.5) * 0.6
                color = ramp(WATER, value, x, y, 0.3)
                if depth == 0:
                    color = "T2" if noise(x / 6.0, 9.0) > 0.45 else "T1"
                elif depth < 4 and noise(x / 3.0, 11.0 + depth) > 0.78:
                    color = "C6"
            elif y >= bank:
                value = 1.3 + (noise(x / 25.0, y / 4.0) - 0.5) * 0.8 - (y - bank) * 0.02 + (1.0 if y == bank else 0.0)
                color = ramp(FAR_SIDE, value, x, y, 0.3)
            else:
                # Lit by the moon behind the camera: C3 where the head rises, as light as the greybox had it, C4 at
                # the horizon, darker only far above, where the stars are.
                value = 1.6 + 2.4 * max(0.0, min(1.0, (y + 520) / 400.0)) - 0.4 * smooth(y, -520, -700)
                value += 0.9 * smooth(y, -90, bank) * (0.6 + 0.4 * noise(x / 30.0, y / 10.0))
                # No ordered dither: the camera draws back to half size and through every size between, and a fine
                # pattern folds into shapes that are not there. The bands' edges drift with the haze instead.
                value += 0.7 * (noise(x / 47.0, y / 13.0) - 0.5)
                color = ramp(SKY, value, x, y, 0.0)
                if value < 2.4 and rng.random() > 0.9985:
                    color = rng.choice(("C6", "C7", "C8"))
            put(img, col, row, color)
    return img


def ground_tiles():
    strip = ground()
    return [strip.crop((i * TILE_W, 0, (i + 1) * TILE_W, HEIGHT)) for i in range(TILES)]
