"""Draws the prologue's four pictures, 480x270, in the Shore's palette. Original staging: silhouettes and light,
nothing taken from any adaptation of the story. The card with the line covers the bottom of the screen, about from
y = 190 down, so what matters in each picture stands above that.

    prologue_1_raider.png   a grey raider at night, our ship held beside it
    prologue_2_escape.png   a small boat pulling away from a dark hull
    prologue_3_drift.png    the boat alone, under a white sun
    prologue_4_dry.png      the boat on bare seabed, the sea a thin line far off
"""

import math
import random

from PIL import ImageDraw

import gen_shore
from art_common import Noise, blank, hline, put, ramp
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


def panel_raider():
    img = gen_shore.sky()
    noise = Noise(401)
    night_sea(img, noise)
    # Our ship, held: smaller, further off, no lights but one.
    ship(img, 300, HORIZON + 6, 110, 34, "C2", "C3", funnels=1, guns=False, lights=((352, HORIZON - 12),))
    # The raider, nearer, longer and lower, its guns trained along the deck.
    ship(img, 90, HORIZON + 22, 210, 52, "C1", "C2", funnels=2, guns=True, lights=((150, HORIZON + 4), (188, HORIZON + 3), (230, HORIZON + 2)))
    return img


def panel_escape():
    img = gen_shore.sky()
    noise = Noise(402)
    night_sea(img, noise, top=HORIZON + 10)
    # The hull wall, close on the left, riveted and black.
    fill(img, [(0, 40), (150, 70), (170, H), (0, H)], "C0")
    for y in range(80, 230, 18):
        for x in range(10, 150, 12):
            put(img, x + (y // 18) % 2 * 6, y, "C2")
    put(img, 120, 96, "A2")
    put(img, 121, 96, "A1")
    # The boat, pulling away, with a man at the oars.
    bx, by = 300, 176
    fill(img, [(bx, by), (bx + 46, by - 2), (bx + 40, by + 7), (bx + 6, by + 7)], "W1")
    hline(img, bx + 2, bx + 44, by, "W3")
    fill(img, [(bx + 20, by - 1), (bx + 26, by - 1), (bx + 25, by - 12), (bx + 21, by - 12)], "C2")
    for k in range(4):
        put(img, bx + 22 + k // 2, by - 14 + k % 2, "S0")
    ImageDraw.Draw(img).line([(bx + 4, by + 9), (bx + 34, by - 6)], fill=rgba("W2"))
    ImageDraw.Draw(img).line([(bx + 10, by - 6), (bx + 44, by + 10)], fill=rgba("W2"))
    # The wake, back toward the ship.
    for i in range(30):
        x = bx - 6 - i * 5
        y = by + 5 + i // 6
        if x > 160:
            put(img, x, y, "C6" if i % 3 else "C5")
            put(img, x - 2, y + 1, "C4")
    return img


def panel_drift():
    img = blank(W, H)
    noise = Noise(403)
    # A white sky, hot and empty, and a sun too bright to look at.
    for y in range(HORIZON + 1):
        for x in range(W):
            value = 4.6 - (y / HORIZON) * 0.8 + 1.4 * math.exp(-((math.hypot(x - 340, y - 40) / 50.0) ** 2))
            put(img, x, y, ramp(["C5", "C6", "C7", "C8", "C9", "A3"], value, x, y, 0.4))
    for y in range(28, 53):
        for x in range(328, 353):
            if math.hypot(x - 340, y - 40) <= 9:
                put(img, x, y, "A3")
    # The sea like oil, flat to every edge.
    for y in range(HORIZON, H):
        d = (y - HORIZON) / (H - HORIZON)
        for x in range(W):
            value = 3.2 - d * 1.8 + (noise(x / 60.0, y / 1.5) - 0.5) * 0.4
            put(img, x, y, ramp(["C2", "C3", "C4", "C5", "C6"], value, x, y, 0.4))
    hline(img, 0, W - 1, HORIZON, "C7")
    # The boat, small, and no one rowing.
    bx, by = 200, 172
    fill(img, [(bx, by), (bx + 40, by - 2), (bx + 35, by + 6), (bx + 5, by + 6)], "W1")
    hline(img, bx + 2, bx + 38, by, "W3")
    fill(img, [(bx + 16, by - 2), (bx + 24, by - 2), (bx + 24, by - 6), (bx + 16, by - 5)], "C2")
    for i in range(3):
        hline(img, bx - 10 + i * 4, bx + 50 - i * 4, by + 8 + i * 2, "C3")
    return img


def panel_dry():
    img = gen_shore.sky()
    noise = Noise(404)
    # The sea, gone to a thin pale line at the very edge of sight.
    for x in range(W):
        put(img, x, HORIZON + 4, "T2" if noise(x / 9.0, 1) > 0.4 else "C4")
        put(img, x, HORIZON + 5, "C3")
    # Everything else is seabed: black, wet, and shining where the moon is.
    for y in range(HORIZON + 6, H):
        d = (y - HORIZON) / (H - HORIZON)
        for x in range(W):
            value = 2.6 - d * 1.9 + (noise(x / 20.0, y / 3.0) - 0.5) * 0.8
            sheen = 1.0 * math.exp(-(((x - 318) / 40.0) ** 2)) * (1 - d)
            put(img, x, y, ramp(["E0", "E1", "E2", "E3", "C5"], value + sheen, x, y, 0.35))
    rng = random.Random(405)
    for _ in range(40):
        x, y = rng.randrange(W), rng.randrange(HORIZON + 12, H)
        put(img, x, y, rng.choice(("E4", "T1", "C6")))
    # The boat, on its side, stranded: the same boat the Shore begins with.
    bx, by = 150, 180
    fill(img, [(bx, by - 2), (bx + 70, by - 10), (bx + 74, by + 2), (bx + 4, by + 6)], "W1")
    hline(img, bx + 4, bx + 70, by - 9, "W3")
    fill(img, [(bx + 6, by - 3), (bx + 68, by - 9), (bx + 66, by - 4), (bx + 8, by + 1)], "W0")
    return img


PANELS = {
    "prologue_1_raider.png": panel_raider,
    "prologue_2_escape.png": panel_escape,
    "prologue_3_drift.png": panel_drift,
    "prologue_4_dry.png": panel_dry,
}


# ---------------------------------------------------------------- the epilogue's pictures, after the escape


def panel_found():
    """Grey morning. A steamer, stopped, its boat lowered, and beside it the small boat with a man lying in it."""
    img = blank(W, H)
    noise = Noise(411)
    horizon = 132
    for y in range(horizon + 1):
        for x in range(W):
            put(img, x, y, ramp(["C3", "C4", "C5", "C6"], 2.4 - y / horizon * 1.2 + (noise(x / 40.0, y / 12.0) - 0.5) * 0.5, x, y, 0.4))
    night_sea(img, noise, top=horizon, calm=0.7)
    # The steamer, broadside, one funnel smoking into the grey.
    ship(img, 210, horizon + 24, 230, 64, "C1", "C2", funnels=1, guns=False, lights=())
    for k in range(18):
        put(img, 300 + k * 2 + (k % 3), horizon - 40 - k * 2 - (k % 2), "C3")
        put(img, 301 + k * 2, horizon - 41 - k * 2, "C4")
    for x in range(222, 430, 9):
        put(img, x, horizon + 6, "C4")
    # A ladder down its side, and its own boat in the water below.
    for y in range(horizon + 2, horizon + 26, 3):
        hline(img, 262, 268, y, "W2")
    fill(img, [(244, horizon + 28), (290, horizon + 26), (286, horizon + 33), (248, horizon + 33)], "C2")
    for k, fx in enumerate((256, 266, 276)):
        fill(img, [(fx, horizon + 27), (fx + 4, horizon + 27), (fx + 4, horizon + 19), (fx, horizon + 19)], "C1")
        put(img, fx + 1 + k % 2, horizon + 17, "C1")
    # Ours, nearer: the man in the bottom of it, not moving.
    bx, by = 132, 168
    fill(img, [(bx, by), (bx + 58, by - 3), (bx + 52, by + 8), (bx + 6, by + 8)], "W1")
    hline(img, bx + 2, bx + 56, by - 1, "W3")
    fill(img, [(bx + 12, by - 4), (bx + 38, by - 6), (bx + 38, by - 2), (bx + 12, by)], "C2")
    for k in range(4):
        put(img, bx + 40 + k, by - 6, "S0")
    for i in range(3):
        hline(img, bx - 8 + i * 4, bx + 64 - i * 4, by + 10 + i * 2, "C3")
    return img


def panel_listen():
    """Night, years on. A small room, a man at the window, the sea and the moon beyond it. He is awake."""
    img = blank(W, H)
    noise = Noise(412)
    for y in range(H):
        for x in range(W):
            put(img, x, y, ramp(["C0", "W0", "E1"], 0.9 + (noise(x / 30.0, y / 30.0) - 0.5) * 0.6, x, y, 0.4))
    wx0, wy0, wx1, wy1 = 250, 24, 400, 150
    sky = gen_shore.sky()
    for y in range(wy0, wy1):
        for x in range(wx0, wx1):
            if y < 112:
                img.putpixel((x, y), sky.getpixel((x - wx0 + 240, y - wy0 + 16)))
            else:
                put(img, x, y, "T0" if (x + y) % 3 else "C2")
    # The moon's path on the water, through the glass.
    for y in range(113, wy1):
        for x in range(316, 340):
            if (x * 7 + y * 3) % 5 == 0 and abs(x - 328) < 4 + (y - 112) // 3:
                put(img, x, y, "C6")
    for x in range(wx0, wx1):
        put(img, x, wy0, "W2")
        put(img, x, wy1, "W2")
        put(img, x, 88, "W1")
    for y in range(wy0, wy1 + 1):
        put(img, wx0, y, "W2")
        put(img, wx1, y, "W2")
        put(img, (wx0 + wx1) // 2, y, "W1")
    # The sill, and the man at it, seated, his back to us, his head turned a little toward the sea.
    fill(img, [(240, 150), (410, 150), (410, 156), (240, 156)], "W1")
    fill(img, [(298, 270), (294, 168), (304, 150), (326, 148), (334, 166), (330, 270)], "C1")
    fill(img, [(306, 150), (305, 132), (312, 126), (322, 128), (324, 140), (322, 150)], "C1")
    put(img, 324, 134, "W1")
    fill(img, [(276, 270), (280, 210), (350, 210), (354, 270)], "W0")
    # A candle on the sill, burnt low.
    fill(img, [(262, 150), (266, 150), (266, 142), (262, 142)], "C6")
    put(img, 264, 140, "A2")
    put(img, 264, 139, "A3")
    return img


def panel_shop():
    """A shop window on a grey street. On a cloth, a gold band: an eye, above a line of waves."""
    img = blank(W, H)
    noise = Noise(413)
    for y in range(H):
        for x in range(W):
            put(img, x, y, ramp(["E1", "E2", "E3", "C3"], 1.6 + (noise(x / 25.0, y / 25.0) - 0.5) * 0.6, x, y, 0.4))
    wx0, wy0, wx1, wy1 = 100, 18, 380, 182
    fill(img, [(wx0, wy0), (wx1, wy0), (wx1, wy1), (wx0, wy1)], "C1")
    for x in range(wx0, wx1 + 1):
        put(img, x, wy0, "W3")
        put(img, x, wy1, "W3")
    for y in range(wy0, wy1 + 1):
        put(img, wx0, y, "W3")
        put(img, wx1, y, "W3")
    # The cloth, and odds and ends on it: a compass, a pipe, a coin or two.
    fill(img, [(140, 128), (340, 128), (360, 176), (120, 176)], "W1")
    hline(img, 141, 339, 128, "W2")
    for a in range(0, 360, 10):
        put(img, 170 + round(9 * math.cos(math.radians(a))), 150 + round(4 * math.sin(math.radians(a))), "C5")
    hline(img, 300, 318, 156, "W3")
    put(img, 318, 155, "W3")
    for cx_, cy_ in ((286, 166), (294, 168)):
        put(img, cx_, cy_, "A1")
        put(img, cx_ + 1, cy_, "A2")
    # The band, standing on its edge, its face toward the street: gold, and on it the mark.
    bx0, by0, bx1, by1 = 196, 112, 284, 146
    fill(img, [(bx0 + 4, by0), (bx1 - 4, by0), (bx1, by0 + 4), (bx1, by1 - 4), (bx1 - 4, by1), (bx0 + 4, by1), (bx0, by1 - 4), (bx0, by0 + 4)], "A1")
    hline(img, bx0 + 4, bx1 - 4, by0, "A3")
    hline(img, bx0 + 2, bx1 - 2, by0 + 1, "A2")
    hline(img, bx0 + 4, bx1 - 4, by1, "W2")
    for y in range(by0 + 2, by1 - 1):
        put(img, bx0 + 1, y, "A2")
        put(img, bx1 - 1, y, "W2")
    cx, cy = (bx0 + bx1) // 2, by0 + 13
    for x in range(cx - 14, cx + 15):
        h = round(6 * math.sqrt(max(0, 1 - ((x - cx) / 14.5) ** 2)))
        put(img, x, cy - h, "W1")
        put(img, x, cy + h, "W1")
    for x in range(cx - 3, cx + 4):
        for y in range(cy - 3, cy + 4):
            if (x - cx) ** 2 + (y - cy) ** 2 <= 10:
                put(img, x, y, "W1")
    for row in (cy + 11, cy + 16):
        for i in range(36):
            put(img, cx - 18 + i, row - round(2 * abs(math.sin(i * math.pi / 6))), "W1")
    # The faint reflection of a man, looking in.
    for y in range(40, 120):
        for x in range(300, 344):
            if (x - 322) ** 2 / 360 + (y - 80) ** 2 / 1300 < 1 and (x + y) % 3 == 0:
                put(img, x, y, "C3")
    return img


def panel_rising():
    """The sea at night from the shore. Calm, and under the moon's path a slow swell that should not be there, and
    breaking it, for a moment, a row of dark points."""
    img = gen_shore.sky()
    noise = Noise(414)
    horizon = 128
    night_sea(img, noise, top=horizon, calm=0.6)
    for y in range(horizon + 6, horizon + 40):
        for x in range(250, 390):
            d = ((x - 320) / 66.0) ** 2 + ((y - horizon - 22) / 14.0) ** 2
            if d < 1 and (x + y) % 2 == 0:
                put(img, x, y, "T1" if d > 0.5 else "T2")
    # The crest: spines, uneven, the tallest in the middle, water running off them.
    for k, (sx, tall) in enumerate(((300, 6), (309, 9), (318, 12), (327, 10), (336, 7), (344, 4))):
        base = horizon + 20
        for t in range(tall):
            half = max(0, (tall - t) // 4)
            for x in range(sx - half, sx + half + 1):
                put(img, x, base - t, "C0")
        put(img, sx, base - tall + 1, "C5")
        put(img, sx + 1, base + 1, "T2")
    for x in range(W):
        for y in range(H - 18, H):
            put(img, x, y, "E0" if noise(x / 9.0, y) > 0.4 else "E1")
    return img


ENDING_PANELS = {
    "ending_1_found.png": panel_found,
    "ending_2_listen.png": panel_listen,
    "ending_3_shop.png": panel_shop,
    "ending_4_rising.png": panel_rising,
}

