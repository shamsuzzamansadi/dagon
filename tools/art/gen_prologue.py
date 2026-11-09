"""Draws the prologue's four pictures, 480x270, in the Shore's palette. Original staging: silhouettes and light,
nothing taken from any adaptation of the story.

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
    bx, by = 300, 212
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
    bx, by = 200, 196
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
    bx, by = 150, 226
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
