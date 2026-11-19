"""Draws the far figures of the walk, over the flat shapes the background clips show and move: the standing stones of
the ritual and the stone with the mark, the kneeling figures, the one who stands, the watcher on the far cliff, the
figure in the canyon, and the distant shape that turns out to be the creature's shoulder.

They are small and far, so each is a few dozen pixels: a dark robe or stone, the moon along its upper right, as on
everything else. Each returns its image and its place in its parent's space.
"""

import math

from PIL import Image, ImageDraw

import gen_cave
import gen_reveal
from art_common import Noise, blank, put

def place(name, parent):
    points = gen_reveal.scene_polygon(name, parent)
    return points, math.floor(min(x for x, _ in points)), math.floor(min(y for _, y in points))


# ---------------------------------------------------------------- the ritual: four who kneel, one who stands

SUPER = 6


def silhouette(width, height, parts):
    """A mask drawn from round parts at six times the size and brought down, so a figure a dozen pixels high keeps
    its head, its back and its limbs apart. parts are ("disc", x, y, r) and ("limb", x0, y0, x1, y1, r) in pixels."""
    big = Image.new("L", (width * SUPER, height * SUPER), 0)
    draw = ImageDraw.Draw(big)
    for part in parts:
        if part[0] == "disc":
            _, x, y, r = part
            draw.ellipse([(x - r) * SUPER, (y - r) * SUPER, (x + r) * SUPER, (y + r) * SUPER], fill=255)
        elif part[0] == "limb":
            _, x0, y0, x1, y1, r = part
            draw.line([x0 * SUPER, y0 * SUPER, x1 * SUPER, y1 * SUPER], fill=255, width=round(2 * r * SUPER))
            for x, y in ((x0, y0), (x1, y1)):
                draw.ellipse([(x - r) * SUPER, (y - r) * SUPER, (x + r) * SUPER, (y + r) * SUPER], fill=255)
        else:
            draw.polygon([(x * SUPER, y * SUPER) for x, y in part[1]], fill=255)
    small = big.resize((width, height), Image.BOX)
    return [[small.getpixel((x, y)) >= 110 for x in range(width)] for y in range(height)]


def shade(mask, face_right):
    """Dark robes, the moon along their upper edges and down the outer right-hand side, as on everything else. Inner
    edges, under an arm or a chest, take less of it, so the figure is not drawn over with lines."""
    height, width = len(mask), len(mask[0])
    img = blank(width, height)
    for y in range(height):
        row = [x for x in range(width) if mask[y][x]]
        for x in row:
            open_above = y == 0 or not mask[y - 1][x]
            outer_top = not any(mask[k][x] for k in range(y))
            if open_above and y < height - 3:
                color = "C6" if outer_top else "C3"
            elif x == row[-1]:
                color = "C4"
            else:
                color = "C1" if y < height * 0.45 else "C0"
            put(img, x, y, color)
    return img


# One who kneels, designed at 64 x 60 and brought down to a third: kneeling up on the heels, the shins flat behind, the
# body bowed forward from the hips, the hooded head forward of the shoulders and lower, and the hands held out before
# the knees, with open ground under the chest. Facing right; those right of the stone are its mirror.
KNEELER_DESIGN = [
    ("limb", 4, 56, 28, 56, 3.5),
    ("disc", 10, 46, 8),
    ("limb", 11, 50, 32, 53, 5.5),
    ("limb", 14, 40, 23, 19, 7),
    ("limb", 26, 18, 29, 21, 2.3),
    ("disc", 32, 24, 6.0),
    ("limb", 24, 25, 29, 36, 2.6),
    ("limb", 29, 36, 37, 40, 2.4),
    ("disc", 38, 40, 2.6),
]
KNEELER_W, KNEELER_H = 14, 20
# Each one's left edge in the ritual layer, and whether it faces right: two either side of the stone with the mark,
# placed so that what is under each, where it kneels, is ground and not a standing stone.
KNEELERS = {1: (682, True), 2: (708, True), 3: (754, False), 4: (780, False)}
KNEE_COLUMN = 10


def kneeler_mask():
    big = Image.new("L", (64 * 4, 60 * 4), 0)
    draw = ImageDraw.Draw(big)
    for part in KNEELER_DESIGN:
        if part[0] == "disc":
            _, x, y, r = part
            draw.ellipse([(x - r) * 4, (y - r) * 4, (x + r) * 4, (y + r) * 4], fill=255)
        else:
            _, x0, y0, x1, y1, r = part
            draw.line([x0 * 4, y0 * 4, x1 * 4, y1 * 4], fill=255, width=round(8 * r))
            for x, y in ((x0, y0), (x1, y1)):
                draw.ellipse([(x - r) * 4, (y - r) * 4, (x + r) * 4, (y + r) * 4], fill=255)
    small = big.resize((21, 20), Image.BOX)
    return [[small.getpixel((x, y)) >= 115 for x in range(KNEELER_W)] for y in range(KNEELER_H)]


def crest(x):
    """The lit crest of the rise at column x of the ritual layer: the ground they kneel on (gen_cave.ritual_far)."""
    noise = Noise(331)
    f = (x - 610) / 300.0
    return -220 + gen_cave.GROUND_ROW - round(20 + 14 * math.sin(f * math.pi) + 3 * (noise(x / 9.0, 5) - 0.5))


def kneeler(i):
    """One of the four who kneel. Where the clip has them up, the knees rest on the crest; bowing, the clip lowers them
    four pixels, and the strip of ground before them (ritual_ground) hides what goes below the crest."""
    left, face_right = KNEELERS[i]
    mask = kneeler_mask()
    if not face_right:
        mask = [row[::-1] for row in mask]
    img = shade(mask, face_right)
    knee = left + (KNEE_COLUMN if face_right else KNEELER_W - 1 - KNEE_COLUMN)
    return img, (left, crest(knee) - KNEELER_H)


def ground_strip():
    """The crest of the rise and the ground just under it, as the backdrop draws them, across the four who kneel, laid
    in front of them. When they bow it covers what sinks below the crest, and otherwise it cannot be told from the
    backdrop. Only where no standing stone comes down to the crest."""
    backdrop = gen_cave.ritual_far()
    lo = min(left for left, _ in KNEELERS.values())
    hi = max(left for left, _ in KNEELERS.values()) + KNEELER_W
    top = min(crest(x) for x in range(lo, hi))
    img = blank(hi - lo, max(crest(x) for x in range(lo, hi)) + 6 - top)
    stones = [gen_reveal.scene_polygon(n, "RitualLayer") for n in ("Stone1", "Stone2", "Stone3", "Stone4", "MarkStone")]
    for x in range(lo, hi):
        if any(min(px for px, _ in st) - 1 <= x <= max(px for px, _ in st) + 1 for st in stones):
            continue
        for y in range(crest(x), crest(x) + 6):
            pixel = backdrop.getpixel((x - gen_cave.RITUAL_X0, y + 220))
            if pixel[3]:
                img.putpixel((x - lo, y - top), pixel)
    return img, (lo, top)


WATCHER_W, WATCHER_H = 14, 30
# Standing, facing us, taller than any stone: a pointed hood, a pale face in it with two dark hollows, the shoulders,
# the robe to the ground, and a staff with a crook held at his side. The others kneel; he watches.
WATCHER_PARTS = [
    ("disc", 6.5, 4.4, 2.5),
    ("poly", [(5.5, 2.6), (6.4, 0.2), (7.5, 2.6)]),
    ("limb", 6.5, 6.4, 6.5, 7.6, 1.3),
    ("poly", [(3.0, 8.8), (5.0, 7.4), (8.0, 7.4), (10.0, 8.8), (10.2, 10.6), (2.8, 10.6)]),
    ("poly", [(2.8, 10.0), (10.2, 10.0), (9.6, 17.0), (11.2, 29.6), (1.6, 29.6), (3.4, 17.0)]),
    ("limb", 3.2, 9.6, 2.4, 17.6, 1.05),
    ("limb", 9.8, 9.6, 11.6, 15.2, 1.05),
]


def ritual_watcher():
    points, left, top = place("Watcher", "RitualLayer/Figures")
    mask = silhouette(WATCHER_W, WATCHER_H, WATCHER_PARTS)
    img = shade(mask, True)
    for x, y in ((6, 4), (7, 4), (6, 5), (7, 5), (6, 6)):
        put(img, x, y, "C5" if y < 6 else "C4")
    # The staff, dark against the haze with the moon down its right side, and its crook above his head.
    for y in range(2, 30):
        put(img, 12, y, "C0")
        put(img, 13, y, "C4" if y < 20 else "C2")
    for x, y in ((11, 1), (10, 1), (9, 2), (12, 1), (12, 0), (11, 0)):
        put(img, x, y, "C0")
    put(img, 11, 0, "C5")
    put(img, 12, 15, "S0")
    return img, (left - 1, top - 1)


def robed(width, height, seed):
    """A standing figure, hooded and robed to the ground, facing us or away: nobody can tell. A head, a neck's
    narrowing, shoulders, and the robe falling a little wider to its hem."""
    img = blank(width, height)
    noise = Noise(seed)
    head = max(5.0, height * 0.2)
    for y in range(height):
        if y < head:
            half = (width * 0.25) * math.sqrt(max(0.0, 1 - ((y - head / 2) / (head / 2 + 0.3)) ** 2)) + 0.7
        elif y < head + 1:
            half = width * 0.17
        else:
            t = (y - head - 1) / max(1.0, height - head - 2)
            half = width * (0.34 + 0.12 * t) - (0.8 if y < head + 2 else 0.0) + 0.5 * noise(y / 3.0, 1.0) * t
        x0, x1 = round(width / 2 - half), round(width / 2 + half) - 1
        for x in range(x0, x1 + 1):
            put(img, x, y, "C1" if x > width / 2 and noise(x / 2.0, y / 5.0) > 0.4 else "C0")
        put(img, x1, y, "C6" if y < head or y == round(head) + 1 else ("C5" if noise(y / 2.0, 3.0) > 0.35 else "C4"))
        if y == 0 or y == round(head) + 1:
            for x in range(x0 + 1, x1 + 1):
                put(img, x, y, "C5")
    return img


def watcher(name, parent, seed):
    points, left, top = place(name, parent)
    width = math.ceil(max(x for x, _ in points)) - left + 1
    height = math.ceil(max(y for _, y in points)) - top
    return robed(width, height, seed), (left, top)


def stones():
    """The four standing stones and the one that carries the mark, as one image in the ritual layer's space."""
    names = ["Stone1", "Stone2", "Stone3", "Stone4", "MarkStone"]
    shapes = {name: gen_reveal.scene_polygon(name, "RitualLayer") for name in names}
    left = math.floor(min(x for shape in shapes.values() for x, _ in shape))
    top = math.floor(min(y for shape in shapes.values() for _, y in shape))
    right = math.ceil(max(x for shape in shapes.values() for x, _ in shape))
    bottom = math.ceil(max(y for shape in shapes.values() for _, y in shape))
    img = blank(right - left + 1, bottom - top)
    noise = Noise(337)
    for name, shape in shapes.items():
        mask = Image.new("L", img.size, 0)
        ImageDraw.Draw(mask).polygon([(x - left, y - top) for x, y in shape], fill=255)
        for y in range(img.height):
            row = [x for x in range(img.width) if mask.getpixel((x, y))]
            for x in row:
                edge = x == row[-1]
                first = y == 0 or not mask.getpixel((x, y - 1))
                put(img, x, y, "C4" if edge and noise(y / 2.0, x) > 0.3 else ("C3" if first else ("C1" if noise(x / 2.0, y / 4.0) > 0.45 else "C0")))
    # The mark on the middle stone: the eye, and the waves under it, as the greybox had them, in the same teal.
    eye = gen_reveal.scene_polygon("MarkEye", "RitualLayer")
    wave = gen_reveal.scene_polygon("MarkWave", "RitualLayer")
    for shape, color in ((eye, "T3"), (wave, "T3")):
        mask = Image.new("L", img.size, 0)
        ImageDraw.Draw(mask).polygon([(x - left, y - top) for x, y in shape], fill=255)
        for y in range(img.height):
            for x in range(img.width):
                if mask.getpixel((x, y)):
                    put(img, x, y, color)
    cx = round((min(x for x, _ in eye) + max(x for x, _ in eye)) / 2) - left
    cy = round((min(y for _, y in eye) + max(y for _, y in eye)) / 2) - top
    put(img, cx, cy, "C0")
    put(img, cx, cy - 1, "T4")
    return img, (left, top)


def distant_shape():
    """Far off over the cliff, before anyone knows what it is: a dark back, with what might be rocks along its top.
    They are the spines of the reveal. Nothing else of it is given away."""
    points = gen_reveal.scene_polygon("DistantShape", "FarRidges")
    left, top = math.floor(min(x for x, _ in points)), math.floor(min(y for _, y in points)) - 6
    width = math.ceil(max(x for x, _ in points)) - left + 1
    height = math.ceil(max(y for _, y in points)) - top
    mask = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon([(x - left, y - top) for x, y in points], fill=255)
    for x, tall in ((38, 5), (48, 6), (58, 6), (68, 5), (78, 4)):
        base = min(y for y in range(height) if mask.getpixel((x, y)))
        draw.polygon([(x - 3, base + 2), (x + 1, base - tall), (x + 4, base + 3)], fill=255)
    img = blank(width, height)
    noise = Noise(339)
    for x in range(width):
        column = [y for y in range(height) if mask.getpixel((x, y))]
        for y in column:
            depth = y - column[0]
            lit = depth < 2 and x > width * 0.4 and noise(x / 3.0, 2.0) > 0.35
            put(img, x, y, "C2" if lit else ("C1" if depth < 9 and noise(x / 4.0, y / 3.0) > 0.6 else "C0"))
    return img, (left, top)


def all_figures():
    out = {"ritual_stones": stones(), "distant_shape": distant_shape()}
    for i in range(1, 5):
        out[f"ritual_kneeler_{i}"] = kneeler(i)
    out["ritual_ground"] = ground_strip()
    out["ritual_watcher"] = ritual_watcher()
    out["far_watcher"] = watcher("WatcherFar", "FarRidges", 343)
    out["canyon_figure"] = watcher("CanyonFigure", "ActArt", 345)
    return out
