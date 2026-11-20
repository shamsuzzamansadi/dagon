"""Draws the prologue's first three pictures, 480x270, in the Shore's palette. Original staging: silhouettes and light,
nothing taken from any adaptation of the story. The card with the line covers the bottom of the screen, about from
y = 190 down, so what matters in each picture stands above that.

    prologue_1_raider.png   captivity: the raider's side close, a porthole lit and barred, a guard above, our ship held
    prologue_2_escape.png   the same side from outside; the boat pulls away from it
    prologue_3_drift.png    the sea under a white sun; the boat drifts on it

The fourth, prologue_4_dry.png with its lying and sitting pieces, is not drawn here. It is the Shore itself as a new
game opens on it, photographed from the game by project/tests/capture_opening.gd, so that the last picture and the
game's first frame are one view (D97).

Each background leaves out what moves. The moving parts are saved beside it, as prologue_<n>_<part>.png, and the
prologue scene animates them a little: the lamp flickering and going out, the boat rowing away, drifting. The
positions are in PROLOGUE_LAYERS, and the scene uses the same ones.
"""

import math
import random

from PIL import ImageDraw

import gen_shore
from art_common import Noise, blank, hline, line, put, ramp
from palette import rgba

W, H = 480, 270
HORIZON = 150


def fill(img, points, color):
    ImageDraw.Draw(img).polygon(points, fill=rgba(color))


def night_sea(img, noise, top=HORIZON, calm=1.0):
    for y in range(top, H):
        d = (y - top) / (H - top)
        for x in range(W):
            value = 2.4 - d * 1.6 + (noise(x / (30.0 - 20 * d), y / 2.0) - 0.5) * 0.9 * calm
            put(img, x, y, ramp(["C0", "C1", "C2", "T0", "T1"], value, x, y, 0.35))
        if y % 3 == 0:
            for x in range(W):
                if noise(x / 7.0, y) > 0.82:
                    put(img, x, y, "C5")


def moon_path(img, noise):
    """The moon's light broken on the water beneath it, widening toward us. The boat rows into it, so the man at the
    oars stands dark against it rather than against dark water."""
    mx = gen_shore.MOON[0]
    for y in range(HORIZON + 1, 205):
        d = y - HORIZON
        half = 30 + d * 1.6
        for x in range(max(0, round(mx - half * 1.6)), min(W, round(mx + half * 1.6))):
            near = math.exp(-(((x - mx) / half) ** 2))
            n = noise(x / 5.0, y * 0.7)
            if y % 2 == 0 and n > 0.78 - 0.3 * near:
                put(img, x, y, "C7" if n > 0.9 and near > 0.6 else "C6" if near > 0.35 else "C5")
            elif near > 0.5 and n > 0.6:
                put(img, x, y, "C3")


def ship(img, x0, y_water, length, height, color, deck_color, funnels=2, guns=True, lights=()):
    hull = [(x0, y_water - height * 0.35), (x0 + length, y_water - height * 0.45), (x0 + length - 10, y_water + 2), (x0 + 12, y_water + 2)]
    fill(img, hull, color)
    sx = x0 + length * 0.35
    fill(img, [(sx, y_water - height * 0.35), (sx + length * 0.3, y_water - height * 0.38), (sx + length * 0.3, y_water - height * 0.7), (sx, y_water - height * 0.68)], deck_color)
    for i in range(funnels):
        fx = sx + 6 + i * 14
        fill(img, [(fx, y_water - height * 0.68), (fx + 7, y_water - height * 0.68), (fx + 6, y_water - height), (fx + 1, y_water - height)], color)
    ImageDraw.Draw(img).line([(x0 + 18, y_water - height * 0.4), (x0 + 22, y_water - height * 1.25)], fill=rgba(color))
    ImageDraw.Draw(img).line([(x0 + length - 20, y_water - height * 0.45), (x0 + length - 24, y_water - height * 1.15)], fill=rgba(color))
    if guns:
        ImageDraw.Draw(img).line([(x0 + length - 34, y_water - height * 0.5), (x0 + length - 8, y_water - height * 0.58)], fill=rgba(color), width=2)
    for lx, ly in lights:
        put(img, lx, ly, "A2")
        put(img, lx + 1, ly, "A1")


def porthole(img, cx, cy, r=5):
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            d = math.hypot(x - cx, y - cy)
            if d <= r - 1:
                put(img, x, y, "C0")
            elif d <= r + 0.6:
                put(img, x, y, "C3" if y < cy else "C2")


def lamp():
    """A porthole lit from inside, barred, a man's head dark against the lamp. Laid over a porthole; it flickers, and
    in the escape it goes out."""
    img = blank(12, 12)
    for y in range(12):
        for x in range(12):
            d = math.hypot(x - 5.5, y - 5.5)
            if d <= 4.6:
                put(img, x, y, "A2" if d < 2.6 else "A1")
    for x in (4, 7):
        for y in range(1, 11):
            if math.hypot(x - 5.5, y - 5.5) <= 4.6:
                put(img, x, y, "C0")
    for y in range(6, 11):
        for x in range(2, 6):
            if math.hypot(x - 3.5, y - 8.0) <= 2.2 or (y >= 9 and 1 <= x <= 6):
                if math.hypot(x - 5.5, y - 5.5) <= 4.6:
                    put(img, x, y, "C0")
    return img


def sprite(img, rows, x0, y0, colors):
    """Pixels from rows of letters; a dot is left clear."""
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                put(img, x0 + x, y0 + y, colors[ch])


def stem_x(x0, top, bottom, y):
    """The raider's stem: raked, the deck well forward of the forefoot, curving in toward the waterline."""
    t = max(0.0, min(1.0, (y - (top + 3)) / (bottom + 4 - (top + 3))))
    return x0 - 6 + 8 * t + 18 * t**3


def boot_top(img, left, y0, y1, right=W - 1):
    """The band above the waterline, a shade lighter than the side, that marks a ship's hull from any rock."""
    for y in range(y0, y1 + 1):
        for x in range(math.ceil(left(y)), right + 1):
            put(img, x, y, "C2" if y > y0 else "C3")


def rail(img, x0, x1, deck, height=9, gaps=()):
    """A ship's rail: posts every six pixels on the deck's edge, and the rail along their tops, height pixels above
    the deck. gaps are openings in it, from one x to another."""
    def open_at(x):
        return any(a <= x <= b for a, b in gaps)

    for x in range(x0 + 2, x1, 6):
        if not open_at(x):
            for y in range(deck(x) - height + 1, deck(x) + 1):
                put(img, x, y, "C1")
    for x in range(x0, x1 + 1):
        if not open_at(x):
            put(img, x, deck(x) - height, "C2")


def raider_hull(img, x0, top, bottom):
    """The raider's side, close: black plates, rivets, a row of portholes, and its rail against the sky. Its bow is
    raked and its hull carries a band above the water, so that it reads as a ship's and not as a wall."""
    edge = [(stem_x(x0, top, bottom, y), y) for y in range(top + 3, bottom + 5)]
    fill(img, edge + [(W, bottom), (W, top + 3)], "C0")
    for y in range(top + 14, bottom - 4, 16):
        for x in range(x0 + 10, W, 12):
            put(img, x + (y // 16) % 2 * 6, y, "C2")
    boot_top(img, lambda y: stem_x(x0, top, bottom, y) + 1, bottom - 10, bottom - 7)
    left = round(stem_x(x0, top, bottom, top + 3))
    hline(img, left + 1, W - 1, top + 3, "C3")
    hline(img, left + 1, W - 1, top + 4, "C2")
    # The stem, lit along its forward edge where the moon comes past it.
    for x, y in edge[2:-6]:
        put(img, math.ceil(x), y, "C2")
    # The hawse pipe and the anchor stowed under it, a ship's mark at any size.
    ax, ay = left + 14, top + 16
    for x, y in ((ax - 1, ay - 1), (ax, ay - 1), (ax + 1, ay - 1), (ax - 2, ay), (ax + 2, ay), (ax - 1, ay + 1), (ax + 1, ay + 1)):
        put(img, x, y, "C3")
    put(img, ax, ay + 1, "C1")
    for y in range(ay + 2, ay + 9):
        put(img, ax, y, "C3")
    hline(img, ax - 2, ax + 2, ay + 3, "C3")
    for x, y in ((ax - 3, ay + 7), (ax - 2, ay + 8), (ax - 1, ay + 9), (ax + 1, ay + 9), (ax + 2, ay + 8), (ax + 3, ay + 7)):
        put(img, x, y, "C3")


def funnel(img, x, deck, top, width, rake, rim, band):
    """A steamer's funnel, raked aft, with a cap and a pale band near its top. rim is the side the moon lights."""
    for y in range(top, deck + 1):
        shift = round(rake * (deck - y) / (deck - top))
        for dx in range(width):
            put(img, x + shift + dx, y, "C0")
        put(img, x + shift + (0 if rim < 0 else width - 1), y, "C3")
        if band <= y - top < band + 3:
            for dx in range(1, width - 1):
                put(img, x + shift + dx, y, "C3" if y - top == band else "C2")
    shift = rake
    hline(img, x + shift - 1, x + shift + width, top, "C0")
    hline(img, x + shift - 1, x + shift + width, top + 1, "C0")
    hline(img, x + shift, x + shift + width - 1, top - 1, "C4")


GUARD = [
    "....ddd....",
    "...ddddd...",
    ".rdddddd...",
    "...rddd....",
    "...rddd....",
    "....ddd....",
    "..rddddddd.",
    ".rdddddddd.",
    ".rdddddddd.",
    ".rd.ddddd.d",
    ".rd.ddddd.d",
    ".dd.ddddd.d",
    "...dddddd..",
    "...rdddddd.",
    "..rdddddd..",
    "..rdddddd..",
    "..rdd..dd..",
    "..rd...dd..",
    "..dd....dd.",
    "..dd....dd.",
    ".rdd....dd.",
    ".ddd....ddd",
]


def guard(img, x, deck):
    """The guard at the head of the gangway: cap, head, shoulders, a greatcoat to the knee, and his boots apart on the
    deck. His rifle on his shoulder. The moon is behind him to the left, and lights his left edges."""
    top = deck - len(GUARD) + 1
    sprite(img, GUARD, x, top, {"d": "C0", "r": "C4"})
    line(img, x + 9, top + 7, x + 12, top - 3, "C0")
    put(img, x + 12, top - 4, "C0")
    put(img, x + 11, top - 3, "C3")


def panel_raider_layers():
    """Captivity. The raider's side, close, in the dark; one porthole lit and barred, a man's head against it. A
    guard on the deck above. Our own ship small beyond, held alongside by a line."""
    img = gen_shore.sky()
    noise = Noise(401)
    night_sea(img, noise)
    ship(img, 24, HORIZON + 4, 118, 32, "C2", "C3", funnels=1, guns=False, lights=())
    ImageDraw.Draw(img).line([(140, HORIZON - 12), (196, 92)], fill=rgba("C3"))
    raider_hull(img, 190, 64, 188)
    # The water along her: broken light at the waterline, and a wave folded back from the stem.
    for y in range(186, 194):
        for x in range(184, W):
            if x >= stem_x(190, 64, 188, y) - 2 and noise(x / 6.0, y) > 0.55:
                put(img, x, y, "C5")
    for y in range(181, 190):
        x = math.floor(stem_x(190, 64, 188, y))
        for k in range(1 + (y - 181) // 3):
            put(img, x - 1 - k, y, "C7" if (k + y) % 3 else "C6")
    for x, y in ((198, 189), (196, 190), (194, 190), (192, 191), (201, 190)):
        put(img, x, y, "C6")

    def deck(x):
        return 66

    # The funnel aft, raked, with its band: the mark carried into the escape.
    funnel(img, 432, deck(440), 14, 22, 5, -1, 6)
    # The deck: a gun trained over the bow on our ship, out over the open water to the left and a little down, its
    # barrel against the sky above the rail and well clear of the moon; its breech behind the shield. It stands on a
    # pedestal, which comes down through the rail to a base on the deck.
    floor = deck(258)
    fill(img, [(252, 58), (264, 58), (265, floor - 2), (251, floor - 2)], "C0")
    fill(img, [(247, floor - 2), (269, floor - 2), (270, floor), (246, floor)], "C0")
    fill(img, [(244, 58), (270, 58), (268, 50), (248, 50)], "C0")
    fill(img, [(268, 51), (275, 52), (275, 56), (268, 56)], "C0")
    ImageDraw.Draw(img).line([(248, 53), (203, 55)], fill=rgba("C0"), width=3)
    fill(img, [(200, 53), (204, 53), (204, 57), (200, 57)], "C0")
    # The moon behind it catches the top of the shield, the barrel and the muzzle, and the pedestal's near edge.
    hline(img, 249, 267, 49, "C4")
    line(img, 247, 51, 205, 53, "C4")
    hline(img, 200, 204, 52, "C4")
    for y in range(59, floor - 2):
        put(img, 251, y, "C3")
    hline(img, 246, 250, floor - 3, "C3")
    # The rail, open where the guard stands at the head of the gangway.
    rail(img, round(stem_x(190, 64, 188, 67)) + 1, W - 1, deck, gaps=((364, 384),))
    guard(img, 368, deck(374))
    for cx in (240, 290, 340, 390, 440):
        porthole(img, cx, 120 - (cx - 240) // 50)
    return img, {"lamp": (lamp(), (334, 110))}


# The escape's boat, in its 110 x 26 layer: bow to the right, the waterline at BY. Larger than it was, so that the man
# in it can be told from it at the game's size; the layer and its place in the scene are unchanged.
BX, BY, BOAT_LEN = 34, 16, 60
SEAT = BX + 30


def hull(img, bx, by, length, depth):
    """A small boat's hull from the side: dark planking, a lighter strake, and the gunwale caught by the light."""
    fill(img, [(bx, by), (bx + length, by - 2), (bx + length - 8, by + depth), (bx + 8, by + depth)], "W1")
    hline(img, bx + 4, bx + length - 6, by + depth // 2, "W2")
    hline(img, bx + 2, bx + length - 2, by, "W3")


def boat_with_rower(wake=True):
    """The small boat from the side, and its wake behind it. 110 x 26. The man at the oars is drawn with the oars,
    in the two layers the scene swaps for each stroke, so that he rows with them."""
    img = blank(110, 26)
    hull(img, BX, BY, BOAT_LEN, 9)
    if wake:
        for i in range(8):
            x = BX - 3 - i * 4
            y = BY + 5 + i // 4
            if x >= 0:
                put(img, x, y, "C6" if i % 3 else "C5")
                put(img, x - 2, y + 1, "C4")
    return img


def figure(img, hip, shoulder, hands, lit="C6", coat="C1", rim="C5", head_drop=0, head_forward=0, face_left=True):
    """A seated man in a dark coat and cap, from the side: a thick back from hip to shoulder, an arm to his hands, a
    head with a lighter face. The light comes from the upper right, so his top and right edges catch it."""
    draw = ImageDraw.Draw(img)
    hx, hy = hip
    sx, sy = shoulder
    draw.line([(hx, hy), (sx, sy)], fill=rgba(coat), width=4)
    draw.line([(hx + 1, hy), (sx + 1, sy)], fill=rgba(coat), width=3)
    # The back, catching the light along its right edge.
    for t in range(0, 11):
        x = round(hx + (sx - hx) * t / 10) + 2
        y = round(hy + (sy - hy) * t / 10)
        put(img, x, y, rim)
    # The arm, a little lighter than the coat, so it reads in front of the body; the hands bare.
    ax, ay = hands
    draw.line([(sx - 1, sy + 1), (ax, ay)], fill=rgba("C2"), width=2)
    put(img, ax, ay, "S1")
    put(img, ax, ay + 1, "S0")
    # The head: a cap on top, its crown lit; the face toward the way he faces, lighter than anything dark round it.
    face = -1 if face_left else 1
    cx, cy = sx + face * (1 + head_forward), sy - 3 + head_drop
    for dx in (-1, 0, 1):
        put(img, cx + dx, cy - 2, "C0")
        put(img, cx + dx, cy - 1, "C0")
    put(img, cx + 1, cy - 2, lit)
    put(img, cx + 2, cy - 1, lit)
    put(img, cx + face, cy, "S1")
    put(img, cx, cy, "S0")
    put(img, cx + face, cy + 1, "S0")
    put(img, cx - face, cy, "C0")
    put(img, cx - face, cy + 1, coat)
    put(img, cx + face * 2, cy - 1, "C0")


def oars(frame):
    """The man at the oars and the oar, at the end of the stroke (0), leaning back with his hands drawn in and the
    blade trailing astern, or at the catch (1), leaning forward with his arms out and the blade dipping ahead."""
    img = blank(110, 26)
    hip = (SEAT, BY - 1)
    lock = (SEAT - 3, BY - 1)
    if frame == 0:
        shoulder, hands = (SEAT + 2, BY - 11), (SEAT - 1, BY - 6)
    else:
        shoulder, hands = (SEAT - 4, BY - 9), (SEAT - 10, BY - 5)
    # The oar: through the rowlock from his hands, and on into the water.
    dx, dy = lock[0] - hands[0], lock[1] - hands[1]
    scale = (BY + 7 - lock[1]) / max(1, dy) if dy > 0 else 4.0
    blade = (round(lock[0] + dx * scale), BY + 7)
    draw = ImageDraw.Draw(img)
    draw.line([hands, lock], fill=rgba("W3"))
    draw.line([lock, blade], fill=rgba("W2"))
    draw.line([(blade[0], blade[1] - 1), (blade[0] + (2 if dx > 0 else -2), blade[1])], fill=rgba("W1"), width=2)
    if frame == 1:
        for k in range(3):
            put(img, blade[0] + k - 1, blade[1] + 1 + k % 2, "C6")
    figure(img, hip, shoulder, hands)
    return img


# The raider in the escape, from astern: its waterline, and its counter stern overhanging the water.
ESCAPE_WATERLINE = 184
ESCAPE_STERN = [(160, 74), (162, 80), (162, 88), (159, 96), (153, 103), (146, 108), (128, ESCAPE_WATERLINE)]


def escape_deck(x):
    """The raider's deck in the escape: its sheer rising toward the stern."""
    return round(80 - 6 * x / 160)


def escape_hull_right(y):
    """How far right the raider's hull reaches on row y of the escape."""
    for (x0, y0), (x1, y1) in zip(ESCAPE_STERN, ESCAPE_STERN[1:]):
        if y0 <= y <= y1:
            return x0 + (x1 - x0) * (y - y0) / max(1, y1 - y0)
    return ESCAPE_STERN[-1][0] if y > ESCAPE_STERN[-1][1] else ESCAPE_STERN[0][0]


def panel_escape_layers():
    """The same raider from astern and a little off, at night: its counter stern over the water, the rail, the
    funnel with its band, the mast; empty davits, their falls hanging, where the boat was. Its hull stands in the
    water, which breaks white along it and gives back its dark. The lit porthole low on it. The boat pulls away from
    it to the right, the oars dipping, and the lamp behind goes out."""
    img = gen_shore.sky()
    noise = Noise(402)
    night_sea(img, noise, top=HORIZON)
    moon_path(img, noise)
    wl = ESCAPE_WATERLINE
    # Its reflection first, under where the hull will stand: the sea darkened, broken by the swell's lit lines.
    for y in range(wl + 1, 214):
        d = y - wl
        right = escape_hull_right(wl - d * 1.6) + 2 * math.sin(y * 1.3)
        for x in range(0, round(right)):
            n = noise(x / 9.0, y * 0.9)
            if n > 0.22 + d * 0.016:
                put(img, x, y, "C0" if n > 0.5 else "C1")
            elif y % 3 == 0 and n < 0.12:
                put(img, x, y, "C4")
    hull_edge = [(escape_hull_right(y), y) for y in range(ESCAPE_STERN[0][1], wl + 1)]
    # The rudder under the counter: it is her stern.
    fill(img, [(136, 142), (143, 144), (144, wl), (131, wl)], "C0")
    line(img, 143, 145, 144, wl - 1, "C2")
    top_edge = [(x, escape_deck(x) + 1) for x in range(0, 161)]
    fill(img, [(0, wl)] + top_edge + hull_edge, "C0")
    for y in range(92, wl - 12, 16):
        for x in range(8, round(escape_hull_right(y)) - 4, 12):
            put(img, x + (y // 16) % 2 * 6, y, "C2")
    boot_top(img, lambda y: 0, wl - 10, wl - 7, right=0)
    for y in range(wl - 10, wl - 6):
        for x in range(0, round(escape_hull_right(y))):
            put(img, x, y, "C2" if y > wl - 10 else "C3")
    for x in range(0, 161):
        put(img, x, escape_deck(x) + 1, "C3")
        put(img, x, escape_deck(x) + 2, "C2")
    # The stern's edge lit by the moon on the right.
    for x, y in hull_edge[1:-4]:
        put(img, math.floor(x) - 1, y, "C2")
    # Funnel and band, as in the captivity, the moon on its right side; the mast and its stay to the stern.
    funnel(img, 34, escape_deck(44), 30, 18, 5, 1, 6)
    for y in range(6, escape_deck(98) + 1):
        put(img, 98, y, "C0")
        put(img, 99, y, "C2" if y < 60 else "C0")
    hline(img, 89, 109, 22, "C0")
    hline(img, 90, 108, 21, "C2")
    line(img, 99, 8, 158, escape_deck(158) - 8, "C1")
    line(img, 157, escape_deck(157), 160, escape_deck(157) - 14, "C1")
    # Empty davits, and their falls hanging down the side to where the boat was lowered.
    for dx in (108, 136):
        deck = escape_deck(dx)
        for y in range(deck - 14, deck + 1):
            put(img, dx, y, "C0")
        for x, y in ((dx + 1, deck - 15), (dx + 2, deck - 16), (dx + 3, deck - 16), (dx + 4, deck - 15), (dx + 4, deck - 14)):
            put(img, x, y, "C0")
        put(img, dx + 2, deck - 17, "C3")
        for y in range(deck - 13, ESCAPE_WATERLINE - 3):
            put(img, dx + 4 + round(1.5 * math.sin((y - deck) / 30.0)), y, "C2")
    rail(img, 0, 160, escape_deck, height=8)
    for cx in (6, 44, 84):
        porthole(img, cx, 108)
    porthole(img, 124, 108)
    # Where the hull goes into the water: the swell breaking white along it, most at the stern.
    for x in range(0, round(escape_hull_right(wl)) + 3):
        for y in (wl - 1, wl, wl + 1):
            n = noise(x / 3.0, y * 1.7)
            if n > 0.5:
                put(img, x, y, "C7" if n > 0.8 else ("C6" if n > 0.65 else "C5"))
    for x, y in ((126, wl - 2), (128, wl - 1), (130, wl), (131, wl - 1), (133, wl + 1), (124, wl + 1), (135, wl)):
        put(img, x, y, "C7")
    return img, {
        "lamp": (lamp(), (118, 102)),
        "boat": (boat_with_rower(), (190, 158)),
        "oars_0": (oars(0), (0, 0)),
        "oars_1": (oars(1), (0, 0)),
    }


# The drift's boat layer: six rows taller than it was, upward, so the slumped man fits above the gunwale. Its waterline
# is on the same row of the screen as before, y = 172; the scene's place for it, and its bob, move up by those rows.
DRIFT_W, DRIFT_H, DRIFT_BY = 76, 22, 14
DRIFT_AT = (185, 158)


def panel_drift_layers():
    img = blank(W, H)
    noise = Noise(403)
    # A white sky, hot and empty, and a sun too bright to look at.
    for y in range(HORIZON + 1):
        for x in range(W):
            value = 3.4 - (y / HORIZON) * 0.7 + 1.9 * math.exp(-((math.hypot(x - 340, y - 40) / 24.0) ** 2))
            put(img, x, y, ramp(["C5", "C6", "C7", "C8", "C9", "A3"], value, x, y, 0.4))
    for y in range(30, 51):
        for x in range(330, 351):
            if math.hypot(x - 340, y - 40) <= 7:
                put(img, x, y, "A3")
    # The sea like oil, flat to every edge.
    for y in range(HORIZON, H):
        d = (y - HORIZON) / (H - HORIZON)
        for x in range(W):
            value = 3.2 - d * 1.8 + (noise(x / 60.0, y / 1.5) - 0.5) * 0.4
            put(img, x, y, ramp(["C2", "C3", "C4", "C5", "C6"], value, x, y, 0.4))
    hline(img, 0, W - 1, HORIZON, "C7")
    # The boat, and no one rowing: the oars shipped along it, the man slumped forward over his knees, his head hanging,
    # one arm over the side to the water. Dark against the bright sea, his back caught by the sun.
    boat = blank(DRIFT_W, DRIFT_H)
    bx, by = 10, DRIFT_BY
    hull(boat, bx, by, 50, 7)
    hline(boat, bx + 8, bx + 46, by - 1, "W2")
    seat = bx + 28
    figure(boat, (seat, by - 1), (seat - 5, by - 7), (seat - 9, by + 3), lit="C7", rim="C6", head_drop=5, head_forward=1)
    for i in range(3):
        hline(boat, bx - 8 + i * 4, bx + 60 - i * 4, by + 9 + min(i, 1) * 2 - (i == 2), "C3")
    return img, {"boat": (boat, DRIFT_AT)}


def panel_raider():
    return flatten(panel_raider_layers())


def panel_escape():
    return flatten(panel_escape_layers(), skip=("oars_1",))


def panel_drift():
    return flatten(panel_drift_layers())


def flatten(layers, skip=()):
    """The picture as one image, for anything that shows it still."""
    img, parts = layers
    img = img.copy()
    boat_at = parts.get("boat", (None, (0, 0)))[1]
    for name, (part, (x, y)) in parts.items():
        if name in skip:
            continue
        if name.startswith("oars"):
            x, y = boat_at
        img.alpha_composite(part, (x, y))
    return img


PROLOGUE_LAYERS = {
    "prologue_1": panel_raider_layers,
    "prologue_2": panel_escape_layers,
    "prologue_3": panel_drift_layers,
}


PANELS = {
    "prologue_1_raider.png": lambda: panel_raider_layers()[0],
    "prologue_2_escape.png": lambda: panel_escape_layers()[0],
    "prologue_3_drift.png": lambda: panel_drift_layers()[0],
}


def prologue_parts():
    """Every moving part, by file name, with where it goes in its picture."""
    parts = {}
    for key, layers in PROLOGUE_LAYERS.items():
        for name, (image, at) in layers()[1].items():
            parts[f"{key}_{name}.png"] = (image, at)
    return parts


# ---------------------------------------------------------------- the epilogue's pictures, after the escape


def _ending(name):
    """The epilogue's pictures are drawn in gen_ending.py, which uses this file's sea and ship."""
    import gen_ending

    return getattr(gen_ending, name)


ENDING_PANELS = {
    "ending_1_found.png": lambda: _ending("panel_found")(),
    "ending_2_listen.png": lambda: _ending("panel_listen")(),
    "ending_3_shop.png": lambda: _ending("panel_shop")(),
    "ending_4_rising.png": lambda: _ending("panel_rising")(),
}
