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


def panel_escape_layers():
    """The same raider's side from outside, at night, the lit porthole low on it. The boat pulls away from it to the
    right, the oars dipping, and the lamp behind goes out."""
    img = gen_shore.sky()
    noise = Noise(402)
    night_sea(img, noise, top=HORIZON)
    moon_path(img, noise)
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

