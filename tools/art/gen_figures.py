"""Draws the far figures of the walk, over the flat shapes the background clips show and move: the standing stones of
the ritual and the stone with the mark, the kneeling figures, the one who stands, the watcher on the far cliff, the
figure in the canyon, and the distant shape that turns out to be the creature's shoulder.

They are small and far, so each is a few dozen pixels: a dark robe or stone, the moon along its upper right, as on
everything else. Each returns its image and its place in its parent's space.
"""

import math

from PIL import Image, ImageDraw

import gen_reveal
from art_common import Noise, blank, put

KNEELER = [
    "..........rrr....",
    ".........rdddR...",
    "........rddddd...",
    ".......rdddddD...",
    "......rddddd.....",
    ".....rdddddd.....",
    "....rdddddddd....",
    "...rddddddddDs...",
    "..rdddddddddd.ss.",
    ".rdddddddddD.....",
    ".rddddddddDD.....",
    "rddddddddDD......",
    "rdddddDDDD.......",
    "dddddDDD.........",
    "DDDDDD...........",
]
COLORS = {"D": "C0", "d": "C1", "r": "C6", "R": "C4", "s": "C7"}


def place(name, parent):
    points = gen_reveal.scene_polygon(name, parent)
    return points, math.floor(min(x for x, _ in points)), math.floor(min(y for _, y in points))


def kneeler(name):
    """One of the four who kneel: bowed toward the stone with the mark, the arms out along the ground."""
    points, left, top = place(name, "RitualLayer/Figures/Kneeling")
    toward_right = points[0][0] < points[5][0]
    img = blank(17, 15)
    for y, row in enumerate(KNEELER):
        for x, ch in enumerate(row if toward_right else row[::-1]):
            if ch != ".":
                # The moon is to the right for all of them: one who faces left has it on his back.
                put(img, x, y, COLORS[ch] if toward_right or ch not in "rR" else "C1")
    if not toward_right:
        for y in range(15):
            xs = [x for x in range(17) if img.getpixel((x, y))[3]]
            if xs and y < 13:
                put(img, xs[-1], y, "C6")
    return img, (left, top - 1)


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
        out[f"ritual_kneeler_{i}"] = kneeler(f"Figure{i}")
    out["ritual_watcher"] = watcher("Watcher", "RitualLayer/Figures", 341)
    out["far_watcher"] = watcher("WatcherFar", "FarRidges", 343)
    out["canyon_figure"] = watcher("CanyonFigure", "ActArt", 345)
    return out
