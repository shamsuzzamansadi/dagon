"""Draws the monolith and the creature for the reveal, in the Shore's palette, over the shapes the scene already uses.

The shapes come from project/scenes/level/shore.tscn, so the art cannot drift from what the clips move and the
tests measure. Each part is drawn to a mask of its polygon, then shaded: rim light where the moon catches an edge,
wet streaks, texture, and on the monolith its carvings.

    monolith.png     the standing stone, world x 3830-4296, y -520-0, carved with the mark, worshippers, fish, and
                     high up the swimmer with its arm around a standing stone: what the reveal then shows, alive
    dagon_body.png, dagon_head.png, dagon_crest.png, dagon_arm.png    the creature, one per animated part
    crossing_carving.png    the panel by the ledges at the gap: a stone dropped on a beam's raised end, then the beam
                            level with the stone on it and a figure walking over. Bold, to be read at the game's scale
"""

import math
import random
import re
from pathlib import Path

from PIL import Image, ImageDraw

from art_common import Noise, blank, line, put, ramp
from palette import rgba

ROOT = Path(__file__).resolve().parents[2]
SCENE = ROOT / "project" / "scenes" / "level" / "shore.tscn"

STONE = ["E2", "E3", "E4", "E5", "C6", "C7"]
DARK = ["C0", "E0", "C1", "E1"]
MONOLITH_X, MONOLITH_Y = 3830, -520


def scene_polygon(name, parent):
    text = SCENE.read_text()
    match = re.search(r'\[node name="%s" type="Polygon2D" parent="%s"\]\n(.*?)\n\n' % (re.escape(name), re.escape(parent)), text, re.S)
    numbers = [float(n) for n in re.search(r"polygon = PackedVector2Array\(([^)]*)\)", match.group(1)).group(1).split(",")]
    return list(zip(numbers[0::2], numbers[1::2]))


def mask_of(points, origin, size):
    image = Image.new("L", size, 0)
    ImageDraw.Draw(image).polygon([(x - origin[0], y - origin[1]) for x, y in points], fill=255)
    return image


def inside(mask, x, y):
    return 0 <= x < mask.width and 0 <= y < mask.height and mask.getpixel((x, y)) > 0


# ---------------------------------------------------------------- the monolith


def engrave(img, mask, points, width=1):
    """A cut line: dark in the groove, lit along its upper lip, as the moon is high."""
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(int(steps) + 1):
            x = round(x0 + (x1 - x0) * i / steps)
            y = round(y0 + (y1 - y0) * i / steps)
            for w in range(width):
                if inside(mask, x, y + w):
                    put(img, x, y + w, "E1")
            if inside(mask, x, y - 1):
                put(img, x, y - 1, "C7")


def carve_mark(img, mask, cx, cy, s):
    """The mark: an eye above waves, as on the talisman."""
    eye = [(cx - 12 * s + i, cy - 6 * s - round(5 * s * math.sqrt(max(0.0, 1 - ((i - 12 * s) / (12 * s)) ** 2)))) for i in range(0, 24 * s + 1, 2)]
    engrave(img, mask, eye, 2)
    engrave(img, mask, [(x, 2 * cy - 12 * s - y) for x, y in eye], 2)
    for x in range(cx - 2 * s, cx + 2 * s):
        for y in range(cy - 8 * s, cy - 4 * s):
            if inside(mask, x, y):
                put(img, x, y, "E1")
    for row in (cy + 3 * s, cy + 7 * s):
        engrave(img, mask, [(cx - 13 * s + i, row - round(2 * s * abs(math.sin(i * math.pi / (4 * s))))) for i in range(0, 26 * s + 1)], 2)


def relief(img, mask, points):
    """A shape cut into the face: dark in the cut, its lower inner edge catching the moon, its outline sharp."""
    cut = Image.new("L", img.size, 0)
    ImageDraw.Draw(cut).polygon(points, fill=255)
    for y in range(img.height):
        for x in range(img.width):
            if cut.getpixel((x, y)) == 0 or not inside(mask, x, y):
                continue
            below = y + 1 < img.height and cut.getpixel((x, y + 1)) > 0
            above = y > 0 and cut.getpixel((x, y - 1)) > 0
            put(img, x, y, "C6" if not below else ("E0" if not above else "E1"))


def carve_swimmer(img, mask, cx, cy):
    """High on the stone: the swimmer rising from the water, crested, its long jaw open, one arm across a standing
    stone and its hand closed round the far side. The reveal shows the same profile and the same arm, alive."""
    # The standing stone it holds: raised, outlined, lighter than the face around it.
    pillar = [(cx - 82, cy + 60), (cx - 84, cy - 22), (cx - 76, cy - 36), (cx - 62, cy - 36), (cx - 56, cy - 22), (cx - 58, cy + 60)]
    for y in range(cy - 36, cy + 60):
        for x in range(cx - 84, cx - 55):
            if inside(mask, x, y) and _in_polygon(pillar, x, y):
                put(img, x, y, "C7" if (x + y) % 7 else "C6")
    engrave(img, mask, pillar + [pillar[0]], 1)
    # The body, the head in profile facing the stone, and the crest along the skull.
    relief(img, mask, [(cx - 8, cy + 60), (cx - 4, cy + 12), (cx + 6, cy - 12), (cx + 30, cy - 22), (cx + 54, cy - 8), (cx + 64, cy + 22), (cx + 68, cy + 60)])
    relief(img, mask, [(cx + 30, cy - 20), (cx + 4, cy - 16), (cx - 16, cy - 20), (cx - 38, cy - 24), (cx - 48, cy - 32), (cx - 34, cy - 42), (cx - 8, cy - 50), (cx + 18, cy - 50), (cx + 36, cy - 38)])
    for k, (sx, tall) in enumerate(((-4, 10), (6, 14), (16, 16), (26, 12), (34, 8))):
        relief(img, mask, [(cx + sx - 3, cy - 46 + k), (cx + sx + 1, cy - 48 - tall + k), (cx + sx + 5, cy - 44 + k)])
    # The open jaw: a pale line of stone left standing between the jaws.
    engrave(img, mask, [(cx - 42, cy - 30), (cx - 14, cy - 28), (cx + 10, cy - 26)], 1)
    for x, y in ((cx - 22, cy - 38), (cx - 21, cy - 38)):
        put(img, x, y, "T3")
    # The arm: from the shoulder, across the stone, and the hand round its far edge.
    relief(img, mask, [(cx + 8, cy - 2), (cx - 20, cy + 4), (cx - 50, cy - 2), (cx - 74, cy - 6), (cx - 88, cy - 6), (cx - 92, cy + 2), (cx - 86, cy + 10), (cx - 74, cy + 8), (cx - 50, cy + 12), (cx - 20, cy + 18), (cx + 10, cy + 12)])
    for f in range(3):
        relief(img, mask, [(cx - 90, cy + 2 + f * 3), (cx - 96, cy + 4 + f * 4), (cx - 94, cy + 6 + f * 4), (cx - 88, cy + 5 + f * 3)])
    # Water below it, rising.
    for row in (cy + 62, cy + 70):
        engrave(img, mask, [(cx - 100 + i, row - round(2 * abs(math.sin(i * math.pi / 8)))) for i in range(0, 190)], 1)


def _in_polygon(points, x, y):
    inside_ = False
    for (x0, y0), (x1, y1) in zip(points, points[1:] + points[:1]):
        if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
            inside_ = not inside_
    return inside_


def carve_worshippers(img, mask, x0, y, count, centre):
    """Kneeling figures, bowed low, their arms out along the ground toward the middle of the stone."""
    for i in range(count):
        x = x0 + i * 24
        d = 1 if x < centre else -1
        def at(dx, dy):
            return (x + d * dx, y + dy)
        relief(img, mask, [at(0, 16), at(0, 8), at(4, 3), at(9, 3), at(12, 7), at(13, 12), at(10, 16)])
        relief(img, mask, [at(14, 9), at(17, 9), at(18, 13), at(15, 14)])
        relief(img, mask, [at(11, 14), at(23, 15), at(23, 17), at(10, 17)])


def carve_fish(img, mask, x, y, size):
    body = [(x, y), (x + size, y - size // 3), (x + 2 * size, y), (x + size, y + size // 3), (x, y)]
    engrave(img, mask, body, 1)
    engrave(img, mask, [(x, y), (x - size // 2, y - size // 3), (x - size // 2, y + size // 3), (x, y)], 1)


def monolith():
    points = scene_polygon("Back", "Monolith")
    width, height = 466, 520
    mask = mask_of(points, (MONOLITH_X, MONOLITH_Y), (width, height))
    img = blank(width, height)
    noise = Noise(501)
    rng = random.Random(502)
    for y in range(height):
        for x in range(width):
            if mask.getpixel((x, y)) == 0:
                continue
            # Moonlight from above and to the right, falling off toward the foot, where it is wet and dark.
            light = 2.0 + 1.4 * (x / width) + 0.8 * (1 - y / height) - 1.2 * max(0.0, (y - 440) / 80)
            strata = noise(x / 60.0, y / 7.0)
            weather = noise.fractal(x / 14.0, y / 14.0, 3)
            value = light + (strata - 0.5) * 0.8 + (weather - 0.5) * 1.1
            put(img, x, y, ramp(STONE, value, x, y, 0.35))
    # The silhouette's edges: lit on the right, shadowed on the left.
    for y in range(height):
        row = [x for x in range(width) if mask.getpixel((x, y))]
        if row:
            put(img, row[0], y, "E1")
            put(img, row[0] + 1, y, "E2")
            put(img, row[-1], y, "C7" if noise(y / 4.0, 9) > 0.4 else "C6")
    # Cracks, wandering down the face.
    for _ in range(9):
        x, y = rng.randrange(40, width - 40), rng.randrange(20, 300)
        for _ in range(rng.randrange(30, 110)):
            if inside(mask, x, y):
                put(img, x, y, "E1")
            x += rng.choice((-1, 0, 0, 1))
            y += 1
    carve_mark(img, mask, width // 2, 70, 3)
    carve_swimmer(img, mask, width // 2 + 20, 200)
    carve_worshippers(img, mask, 60, 300, 14, width // 2 + 10)
    for fx, fy in ((60, 380), (150, 392), (250, 376), (340, 388)):
        carve_fish(img, mask, fx, fy, 14)
    for row in (412, 420):
        engrave(img, mask, [(30 + i, row - round(2 * abs(math.sin(i * math.pi / 10)))) for i in range(0, width - 60)], 1)
    # The mural panel, low down where a man can reach: smoother, recessed, its fragments faint.
    for y in range(428, 515):
        for x in range(22, 115):
            if inside(mask, x, y):
                value = 3.1 + (noise(x / 9.0, y / 9.0) - 0.5) * 0.4
                put(img, x, y, ramp(STONE, value, x, y, 0.2))
    for x in range(22, 115):
        put(img, x, 428, "E1")
    # Its foot: weed, barnacles, standing water.
    for x in range(width):
        for y in range(486, height):
            if inside(mask, x, y) and rng.random() > 0.88:
                put(img, x, y, rng.choice(("T1", "T2", "E2", "C6")))
    return img


# ---------------------------------------------------------------- the creature


def shade_part(name, rim_side=-1, sheen=True):
    """A dark, wet body part, rimmed by the moon on its upper edges, with a faint texture of scale."""
    points = scene_polygon(name, "Dagon")
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    left, top = math.floor(min(xs)), math.floor(min(ys))
    size = (math.ceil(max(xs)) - left + 1, math.ceil(max(ys)) - top + 1)
    mask = mask_of(points, (left, top), size)
    img = blank(*size)
    noise = Noise(600 + len(name))
    rng = random.Random(610 + len(name))
    for y in range(size[1]):
        for x in range(size[0]):
            if mask.getpixel((x, y)) == 0:
                continue
            scale = noise((x + (y % 6 > 2) * 3) / 3.0, y / 3.0)
            value = 0.9 + (scale - 0.5) * 1.0 + 0.6 * noise.fractal(x / 30.0, y / 30.0, 2)
            put(img, x, y, ramp(DARK, value, x, y, 0.4))
    # The rim: an edge pixel whose neighbour above, or on the lit side, is outside.
    for y in range(size[1]):
        for x in range(size[0]):
            if mask.getpixel((x, y)) == 0:
                continue
            up = not inside(mask, x, y - 1)
            side = not inside(mask, x + rim_side, y)
            if up or side:
                put(img, x, y, "T3" if noise(x / 5.0, y / 5.0) > 0.45 else "C6")
                if inside(mask, x, y + 1):
                    put(img, x, y + 1, "T2")
                if inside(mask, x, y + 2) and rng.random() > 0.5:
                    put(img, x, y + 2, "T1")
    # Water running off: thin, broken streaks downward from the lit edges.
    if sheen:
        for _ in range(size[0] // 3):
            x = rng.randrange(size[0])
            y = next((yy for yy in range(size[1]) if mask.getpixel((x, yy))), None)
            if y is None:
                continue
            for k in range(rng.randrange(8, 40)):
                if inside(mask, x, y + 3 + k) and (k + x) % 5:
                    put(img, x, y + 3 + k, "T1" if k < 10 else "C1")
    return img, (left, top)


def body_form(img):
    """The body's form, so it reads as a body and not a wall. Moonlight from above and to the left rounds it: light
    falls off inward from the edges that face the moon. Three broad plates curve across the chest, each a groove lit
    along its lower lip. A fold of gill below the head."""
    import numpy as np
    from scipy import ndimage

    w, h = img.size
    alpha = np.array(img.split()[3]) > 0
    depth = ndimage.distance_transform_edt(alpha)
    gy, gx = np.gradient(ndimage.gaussian_filter(depth, 3))
    norm = np.hypot(gx, gy) + 1e-6
    # The surface faces away from the inside: its normal is the downhill direction of depth.
    facing = np.clip((gx / norm) * 0.6 + (gy / norm) * 0.8, 0, 1)
    light = facing * np.exp(-depth / 70.0)
    noise = Noise(640)
    for y in range(h):
        for x in range(w):
            if not alpha[y, x]:
                continue
            v = light[y, x] + (noise(x / 5.0, y / 5.0) - 0.5) * 0.14
            if v > 0.8:
                put(img, x, y, "T2")
            elif v > 0.55:
                put(img, x, y, "T1")
            elif v > 0.32:
                put(img, x, y, "E1")
            elif v > 0.14:
                put(img, x, y, "C1")
    cx = w * 0.45
    for k, (row, bend) in enumerate(((h * 0.42, 34), (h * 0.58, 30), (h * 0.74, 26))):
        for x in range(int(w * 0.12), int(w * 0.84)):
            y = int(row + bend * math.cos((x - cx) / (w * 0.42) * math.pi / 2) - bend)
            if 2 <= y < h - 4 and alpha[y, x] and alpha[y + 3, x]:
                for d in (-2, -1, 0):
                    put(img, x, y + d, "C0")
                put(img, x, y + 1, "T1" if x < cx else "E1")
                if noise(x / 4.0, k) > 0.3:
                    put(img, x, y + 2, "E1" if x < cx else "C1")
    gx0, gy0 = int(w * 0.64), int(h * 0.06)
    for k in range(3):
        for t in range(48):
            x = gx0 + k * 9 + round(5 * math.sin(t / 8.0))
            y = gy0 + t
            if 0 <= x < w - 1 and 0 <= y < h and alpha[y, x]:
                put(img, x, y, "C0")
                if alpha[y, x + 1]:
                    put(img, x + 1, y, "T1")


def dagon_parts():
    parts = {}
    body, offset = shade_part("Body")
    body_form(body)
    parts["body"] = (body, offset)
    parts["head"] = shade_part("Head")
    parts["crest"] = shade_part("Crest", rim_side=1)
    arm, offset = shade_part("Arm", rim_side=1)
    # The webbed hand: membranes between the fingers, and pale claws at their tips.
    parts["arm"] = (arm, offset)
    return parts


# ---------------------------------------------------------------- the clue at the gap


def crossing_carving():
    """A panel of pale stone set in the rock, 80 x 48, with two scenes cut deep. Lines two pixels wide, figures ten
    pixels tall: at 480 x 270 it reads from where the sailor stands below it."""
    width, height = 80, 48
    rng = random.Random(701)
    noise = Noise(702)
    points = [(2, 4), (10, 1), (40, 3), (70, 0), (78, 5), (79, 30), (77, 46), (50, 47), (20, 46), (1, 44), (0, 20)]
    mask = mask_of(points, (0, 0), (width, height))
    img = blank(width, height)
    for y in range(height):
        for x in range(width):
            if mask.getpixel((x, y)):
                value = 3.0 + 0.6 * (1 - y / height) + (noise.fractal(x / 9.0, y / 9.0, 2) - 0.5) * 0.9
                put(img, x, y, ramp(STONE, value, x, y, 0.3))
    for y in range(height):
        row = [x for x in range(width) if mask.getpixel((x, y))]
        if row:
            put(img, row[0], y, "E1")
            put(img, row[-1], y, "C7")

    def cut(path, width_=2):
        engrave(img, mask, path, width_)

    def disc(cx, cy, r):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and inside(mask, x, y):
                    put(img, x, y, "E1")
        put(img, cx - 1, cy - r - 1, "C7")
        put(img, cx, cy - r - 1, "C7")

    # The divider: a deep groove down the middle.
    cut([(40, 6), (40, 42)], 2)
    # Left: the beam on its stone, the near end raised high, and a round stone falling onto that end.
    cut([(8, 40), (36, 40)], 1)
    cut([(18, 39), (22, 33), (26, 39)], 1)
    cut([(6, 22), (36, 38)], 2)
    disc(9, 11, 3)
    for y in (16, 18):
        put(img, 9, y, "E1")
    # Right: the same beam lying level, the stone resting on its near end, a figure walking over it.
    cut([(44, 40), (76, 40)], 1)
    cut([(56, 39), (60, 33), (64, 39)], 1)
    cut([(44, 31), (76, 31)], 2)
    disc(48, 27, 3)
    disc(66, 15, 2)
    cut([(66, 18), (66, 24)], 2)
    cut([(66, 24), (63, 30)], 1)
    cut([(66, 24), (69, 30)], 1)
    cut([(66, 19), (63, 23)], 1)
    cut([(66, 19), (70, 21)], 1)
    # Weathering: a few chips and a crack, none across the figures.
    for _ in range(14):
        x, y = rng.randrange(3, 77), rng.randrange(3, 45)
        if inside(mask, x, y) and not (5 < x < 37 and 8 < y < 41) and not (43 < x < 77 and 10 < y < 41):
            put(img, x, y, "E2")
    return img

