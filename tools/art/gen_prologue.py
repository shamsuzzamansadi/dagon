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


def raider_hull(img, x0, top, bottom):
    """The raider's side, close: black plates, rivets, a row of portholes, and its rail against the sky."""
    fill(img, [(x0, top + 6), (W, top), (W, bottom), (x0 + 6, bottom + 4)], "C0")
    for y in range(top + 14, bottom - 4, 16):
        for x in range(x0 + 10, W, 12):
            put(img, x + (y // 16) % 2 * 6, y, "C2")
    hline(img, x0 + 2, W - 1, top + 3, "C3")
    hline(img, x0 + 2, W - 1, top + 4, "C2")
    for x in range(x0 + 4, W, 6):
        for y in range(top - 6, top + 3):
            put(img, x, y, "C1")
    hline(img, x0 + 2, W - 1, top - 7, "C2")


def panel_raider_layers():
    """Captivity. The raider's side, close, in the dark; one porthole lit and barred, a man's head against it. A
    guard on the deck above. Our own ship small beyond, held alongside by a line."""
    img = gen_shore.sky()
    noise = Noise(401)
    night_sea(img, noise)
    ship(img, 24, HORIZON + 4, 118, 32, "C2", "C3", funnels=1, guns=False, lights=())
    ImageDraw.Draw(img).line([(140, HORIZON - 12), (196, 92)], fill=rgba("C3"))
    raider_hull(img, 190, 64, 188)
    for y in range(186, 194):
        for x in range(190, W):
            if noise(x / 6.0, y) > 0.55:
                put(img, x, y, "C5")
    # The deck: a gun along it, and a guard with a rifle on his shoulder.
    ImageDraw.Draw(img).line([(260, 56), (318, 44)], fill=rgba("C1"), width=3)
    fill(img, [(244, 58), (270, 58), (268, 50), (248, 50)], "C1")
    fill(img, [(372, 58), (372, 46), (370, 42), (372, 38), (376, 38), (378, 42), (376, 46), (376, 58)], "C1")
    ImageDraw.Draw(img).line([(377, 40), (382, 30)], fill=rgba("C1"))
    for cx in (240, 290, 340, 390, 440):
        porthole(img, cx, 120 - (cx - 240) // 50)
    return img, {"lamp": (lamp(), (334, 110))}


def boat_with_rower(wake=True):
    """The small boat from the side, a man at the oars, and its wake behind it. 110 x 26; the boat's bow at the right."""
    img = blank(110, 26)
    bx, by = 60, 16
    fill(img, [(bx, by), (bx + 46, by - 2), (bx + 40, by + 7), (bx + 6, by + 7)], "W1")
    hline(img, bx + 2, bx + 44, by, "W3")
    fill(img, [(bx + 20, by - 1), (bx + 26, by - 1), (bx + 25, by - 12), (bx + 21, by - 12)], "C2")
    for k in range(4):
        put(img, bx + 22 + k // 2, by - 14 + k % 2, "S0")
    if wake:
        for i in range(12):
            x = bx - 4 - i * 5
            y = by + 5 + i // 5
            if x >= 0:
                put(img, x, y, "C6" if i % 3 else "C5")
                put(img, x - 2, y + 1, "C4")
    return img


def oars(frame):
    """The oars over the boat above, at the catch (0) or at the end of the stroke (1)."""
    img = blank(110, 26)
    bx, by = 60, 16
    if frame == 0:
        ImageDraw.Draw(img).line([(bx + 23, by - 6), (bx + 6, by + 9)], fill=rgba("W2"))
        ImageDraw.Draw(img).line([(bx + 23, by - 6), (bx + 2, by + 6)], fill=rgba("W1"))
    else:
        ImageDraw.Draw(img).line([(bx + 23, by - 6), (bx + 42, by + 9)], fill=rgba("W2"))
        ImageDraw.Draw(img).line([(bx + 23, by - 6), (bx + 46, by + 6)], fill=rgba("W1"))
        for k in range(3):
            put(img, bx + 44 + k, by + 9 + k % 2, "C6")
    return img


def panel_escape_layers():
    """The same raider's side from outside, at night, the lit porthole low on it. The boat pulls away from it to the
    right, the oars dipping, and the lamp behind goes out."""
    img = gen_shore.sky()
    noise = Noise(402)
    night_sea(img, noise, top=HORIZON)
    fill(img, [(0, 40), (150, 70), (170, H), (0, H)], "C0")
    for y in range(80, 230, 18):
        for x in range(10, 150, 12):
            put(img, x + (y // 18) % 2 * 6, y, "C2")
    for cx, cy in ((44, 100), (84, 104)):
        porthole(img, cx, cy)
    porthole(img, 124, 108)
    return img, {
        "lamp": (lamp(), (118, 102)),
        "boat": (boat_with_rower(), (190, 158)),
        "oars_0": (oars(0), (0, 0)),
        "oars_1": (oars(1), (0, 0)),
    }


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
    # The boat, small, and no one rowing: the oars shipped, the man slumped low in it.
    boat = blank(70, 16)
    bx, by = 15, 8
    fill(boat, [(bx, by), (bx + 40, by - 2), (bx + 35, by + 6), (bx + 5, by + 6)], "W1")
    hline(boat, bx + 2, bx + 38, by, "W3")
    fill(boat, [(bx + 16, by - 2), (bx + 24, by - 2), (bx + 24, by - 6), (bx + 16, by - 5)], "C2")
    hline(boat, bx + 6, bx + 34, by - 3, "W2")
    for i in range(3):
        hline(boat, bx - 10 + i * 4, bx + 50 - i * 4, by + 8 + min(i, 1) * 2 - (i == 2), "C3")
    return img, {"boat": (boat, (185, 164))}


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

