"""Draws the epilogue's four pictures, 480 x 270, in the Shore's palette: one hand, one light and one level of detail.

    ending_1_found.png    the rescue: grey morning, the man in his boat, a steamer stopped and her boat pulling to him
    ending_2_listen.png   the lasting fear: night, years on; he stands at a window, a hand to the glass, listening
    ending_3_shop.png     the Innsmouth connection: a shop window, and in it a gold bracelet with the mark on it
    ending_4_rising.png   the continuing threat: the sea at night off the town, and the crest of the reveal breaking it

The card with the line lies low, from about y = 200 at its tallest, so what matters in each stands above y = 190.
The man is the Shore's sailor in all of them: the peaked cap, the beard, the teal scarf, the dark coat with the moon
along its edge. The last picture's crest is not drawn again: it is the reveal's own (gen_creature.py), so it cannot
come to look like something else.
"""

import math
import random

from PIL import Image, ImageDraw

import gen_creature
import gen_prologue
import gen_reveal
import gen_shore
from art_common import Noise, blank, hline, line, put, ramp
from gen_prologue import H, W, fill, night_sea
from palette import rgba

# The card's top at its tallest: nothing that has to be read lies below this row.
CLEAR_OF_THE_CARD = 190


def rows(img, x, y, pattern, colors):
    """Places hand-set pixels: one string a row, a letter a colour, a dot nothing."""
    for dy, row in enumerate(pattern):
        for dx, ch in enumerate(row):
            if ch != ".":
                put(img, x + dx, y + dy, colors[ch])


def ellipse(img, cx, cy, rx, ry, color):
    for y in range(math.floor(cy - ry), math.ceil(cy + ry) + 1):
        for x in range(math.floor(cx - rx), math.ceil(cx + rx) + 1):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                put(img, x, y, color)


def ripples(img, x0, x1, y, count=3, color="C4"):
    for i in range(count):
        hline(img, x0 + i * 5, x1 - i * 5, y + i * 2, color)


def moon_road(img, noise, mx, top, bottom, spread, x0=0, x1=W):
    """The moon on the water: short broken strokes under it, close and bright at the horizon, scattering toward us.
    No two rows alike, so it reads as light on moving water and not as a drawn shape."""
    for y in range(top, bottom):
        d = (y - top) / max(1, bottom - top)
        half = 3 + spread * d
        x = max(x0, round(mx - half * 2.2))
        while x < min(x1, round(mx + half * 2.2)):
            near = math.exp(-(((x - mx) / half) ** 2))
            n = noise(x / 4.0 + y * 3.7, y * 0.9)
            if n > 0.84 - 0.42 * near + 0.1 * d:
                run = 1 + round(3 * near * noise(x / 2.0, y * 1.3))
                for k in range(run):
                    if x0 <= x + k < x1:
                        put(img, x + k, y, "C8" if near > 0.7 and n > 0.7 else ("C6" if near > 0.3 else "C5"))
                x += run + 1
            x += 1


SAILOR = {"c": "C1", "T": "C5", "P": "C0", "h": "E2", "s": "S1", "S": "S0", "e": "C0", "b": "W1", "B": "W0", "d": "C1", "D": "C0", "r": "C7", "R": "C5", "n": "T2", "N": "T3", "a": "C2", "t": "E2", "k": "C3"}


# ---------------------------------------------------------------- 1. the rescue


def panel_found():
    img = blank(W, H)
    noise = Noise(411)
    horizon = 132
    # A grey morning, lightest low in the east, behind the steamer.
    for y in range(horizon + 1):
        for x in range(W):
            dawn = 2.1 * math.exp(-(((x - 380) / 210.0) ** 2)) * (y / horizon) ** 2
            value = 2.5 - (1 - y / horizon) * 1.3 + dawn + (noise(x / 40.0, y / 12.0) - 0.5) * 0.6
            put(img, x, y, ramp(["C2", "C3", "C4", "C5", "C6", "C7"], value, x, y, 0.4))
    night_sea(img, noise, top=horizon, calm=0.7)
    for y in range(horizon + 1, horizon + 16):
        for x in range(250, W):
            if noise(x / 9.0, y * 1.3) > 0.7 and y % 2:
                put(img, x, y, "C4")
    # The steamer, stopped, broadside: one funnel, its smoke lying down the wind, a lamp still lit at the bridge.
    water = horizon + 24
    gen_prologue.ship(img, 262, water, 214, 76, "C1", "C2", funnels=1, guns=False)
    for k in range(34):
        x = 342 - k * 3
        y = round(water - 80 - 9 * (1 - math.exp(-k / 9.0)) + 2 * math.sin(k / 3.0))
        for w in range(1 + k // 9):
            put(img, x - w, y - w % 2, "C3" if (k + w) % 3 else "C4")
    for x in range(274, 468, 9):
        put(img, x, water - 18, "C4")
    put(img, 350, water - 44, "A2")
    put(img, 351, water - 44, "A1")
    # Men at her rail, looking down at him, and the empty davits her boat was lowered from.
    for x in (296, 304, 322):
        rows(img, x, water - 39, [".cc.", ".cc.", "cccc", "cccc", "cccc"], {"c": "C0"})
    for x in (392, 418):
        line(img, x, water - 30, x, water - 46, "C1")
        line(img, x, water - 46, x + 6, water - 48, "C1")
        line(img, x + 6, water - 48, x + 6, water - 20, "C3")
    # Her dark side on the water under her.
    for y in range(water + 3, water + 12):
        for x in range(276, 466):
            if (x + y * 3) % 5 < 2 and noise(x / 6.0, y / 2.0) > 0.35:
                put(img, x, y, "C0")
    # Her boat, pulling toward him: two at the oars, a lantern in the bow, and a man standing there with a boat hook
    # out toward his gunwale.
    bx, by = 236, 163
    fill(img, [(bx, by), (bx + 56, by - 1), (bx + 50, by + 7), (bx + 6, by + 7)], "W1")
    hline(img, bx + 1, bx + 55, by - 1, "W3")
    hline(img, bx + 4, bx + 52, by + 3, "W2")
    for rx in (bx + 26, bx + 40):
        rows(img, rx, by - 10, [".PP.", ".cc.", ".ss.", "dddr", "dddr", "addd", "addd"], dict(SAILOR, c="C0", s="S0"))
        line(img, rx, by - 4, rx - 9, by + 9, "W3")
        put(img, rx - 10, by + 10, "C7")
        put(img, rx - 8, by + 10, "C6")
    rows(img, bx + 5, by - 15, ["..PP.", "..cc.", "..ss.", ".dddr", "ddddr", "addd.", "addd.", ".dd..", ".dd..", ".d.d."], dict(SAILOR, c="C0", s="S0"))
    line(img, bx + 5, by - 9, bx - 22, by + 4, "W3")
    put(img, bx - 23, by + 5, "C7")
    put(img, bx + 14, by - 4, "A3")
    put(img, bx + 14, by - 3, "A2")
    put(img, bx + 13, by - 3, "A1")
    put(img, bx + 15, by - 3, "A1")
    ripples(img, bx - 4, bx + 60, by + 9, 2)
    # His boat, nearer and larger. He lies back against the stern, his head on the gunwale, one arm over the side
    # with the hand trailing in the water: the whole of him above the boat's edge, against the lighter sea.
    sx, sy = 86, 177
    fill(img, [(sx, sy - 3), (sx + 124, sy - 4), (sx + 112, sy + 12), (sx + 10, sy + 12)], "W1")
    fill(img, [(sx + 4, sy + 6), (sx + 118, sy + 5), (sx + 112, sy + 12), (sx + 10, sy + 12)], "W0")
    hline(img, sx + 3, sx + 120, sy + 3, "W2")
    for x in range(sx, sx + 125):
        put(img, x, sy - 3 - (1 if x > sx + 60 else 0), "W4" if x % 7 else "W3")
    line(img, sx, sy - 3, sx - 2, sy - 9, "W2")
    line(img, sx + 124, sy - 4, sx + 128, sy - 10, "W2")
    # A thwart, and the oars shipped along it.
    line(img, sx + 70, sy - 6, sx + 116, sy - 8, "W3")
    line(img, sx + 70, sy - 5, sx + 116, sy - 7, "W2")
    # The man, sitting slumped in the stern with his back against it: his head fallen forward on his chest, his knees
    # up before him, an arm over the side with the hand hanging against the planks. Lit from the east, as she is.
    rows(img, sx + 9, sy - 30, [
        "......cTTTc...........",
        ".....cTTTTTc..........",
        ".....ccccccc..........",
        ".....hccccccPPP.......",
        ".....hhsssssr.........",
        ".....hhssesss.........",
        "......hsssssr.........",
        "......bbbbssr.........",
        ".....nnbbbbb..........",
        "...DdnNNnbb...........",
        "..DddnNNNndr..........",
        "..DdddnNNdddr.........",
        ".DDdddddddddr.........",
        ".DDddddddddddr....rrr.",
        ".DDdddddaadddr...rtttr",
        ".DDddddaaaaddr..rttttt",
        ".DDdddaaaaadddrrtttttt",
        ".DDddddaaadddtttttttt.",
        ".DDdddddaaddttttttttt.",
        ".DDddddddaadtttttttt..",
        ".DDdddddddaatttttttt..",
        ".DDddddddddaatttttt...",
        ".DDdddddddddaattttt...",
        ".DDdddddddddaaatttt...",
        "..DDddddddddaaattt....",
        "..DDdddddddddaaat.....",
        "...DDdddddddddaa......",
    ], SAILOR)
    # The forearm over the gunwale, and the hand against the hull.
    rows(img, sx + 22, sy - 4, ["aak.", ".aak", ".aak", "..ss", "..sS", "..sS", "...S"], SAILOR)
    ripples(img, sx - 10, sx + 134, sy + 14, 3, "C3")
    for x in range(sx + 6, sx + 118, 3):
        if noise(x / 3.0, 5.0) > 0.4:
            put(img, x, sy + 13, "C5")
    return img


# ---------------------------------------------------------------- 2. the window


def plank_wall(img, noise, colors=("C0", "W0", "E1"), board=22):
    for y in range(H):
        for x in range(W):
            seam = x % board == 0
            value = 0.85 + (noise(x / 3.0 + (x // board) * 7.0, y / 40.0) - 0.5) * 0.9 - (0.6 if seam else 0.0)
            put(img, x, y, ramp(list(colors), value, x, y, 0.3))


def panel_listen():
    img = blank(W, H)
    noise = Noise(412)
    plank_wall(img, noise)
    wx0, wy0, wx1, wy1 = 120, 14, 404, 170
    sea_top = 104
    sky = gen_shore.sky()
    moon_x = 190
    for y in range(wy0, wy1):
        for x in range(wx0, wx1):
            if y < sea_top:
                img.putpixel((x, y), sky.getpixel((max(0, min(479, x - moon_x + gen_shore.MOON[0])), max(0, y - 50 + gen_shore.MOON[1]))))
            else:
                d = (y - sea_top) / (wy1 - sea_top)
                value = 2.6 - d * 1.5 + (noise(x / (26.0 - 14 * d), y / 2.0) - 0.5) * 0.8
                put(img, x, y, ramp(["C0", "C1", "C2", "T0", "T1"], value, x, y, 0.35))
    hline(img, wx0, wx1, sea_top, "C4")
    moon_road(img, noise, moon_x, sea_top + 1, wy1, 16, wx0, wx1)
    # The frame: two lights wide and two high, heavy, the moon on the edges that face it.
    for x0, x1 in ((wx0 - 5, wx0), (wx1, wx1 + 5), (260, 264)):
        fill(img, [(x0, wy0 - 5), (x1, wy0 - 5), (x1, wy1), (x0, wy1)], "W0")
        for y in range(wy0, wy1):
            put(img, x0 if x0 > 200 else x1 - 1, y, "W2")
    for y0, y1 in ((wy0 - 5, wy0), (84, 88)):
        fill(img, [(wx0 - 5, y0), (wx1 + 5, y0), (wx1 + 5, y1), (wx0 - 5, y1)], "W0")
        hline(img, wx0, wx1, y1 - 1, "W1")
    # The sill, lit along its top.
    fill(img, [(wx0 - 14, wy1), (wx1 + 14, wy1), (wx1 + 14, wy1 + 8), (wx0 - 14, wy1 + 8)], "W1")
    hline(img, wx0 - 14, wx1 + 14, wy1, "W3")
    hline(img, wx0 - 14, wx1 + 14, wy1 + 8, "W0")
    # A candle burnt low at the frame's foot.
    fill(img, [(386, wy1 - 8), (391, wy1 - 8), (391, wy1), (386, wy1)], "C7")
    hline(img, 386, 390, wy1 - 8, "C9")
    rows(img, 386, wy1 - 16, ["..y..", ".yYy.", ".yYy.", ".yYy.", "..o.."], {"y": "A2", "Y": "A3", "o": "A0"})
    for dx, dy in ((-4, -12), (8, -13), (2, -19), (-3, -3), (9, -4)):
        put(img, 388 + dx, wy1 + dy, "A0")
    # The man, close to the glass, his back to us: against the sea and the sky in the right-hand light. His shoulders
    # are drawn up, uneven, and his head is bent forward and turned, an ear to the pane. One hand is flat on the
    # glass beside his head. The other grips the sill.
    cx = 322
    coat = [(cx - 62, H), (cx - 60, 196), (cx - 54, 170), (cx - 44, 152), (cx - 26, 142), (cx - 10, 138), (cx + 14, 140), (cx + 34, 146), (cx + 48, 158), (cx + 54, 176), (cx + 56, H)]
    fill(img, coat, "C0")
    # The fold of the back, and the collar turned up.
    fill(img, [(cx - 30, H), (cx - 26, 190), (cx - 18, 164), (cx - 8, 150), (cx + 20, 150), (cx + 32, 164), (cx + 38, 190), (cx + 40, H)], "C1")
    line(img, cx + 2, 150, cx + 4, H, "C0")
    fill(img, [(cx - 20, 142), (cx - 16, 130), (cx + 18, 130), (cx + 24, 143), (cx + 2, 150)], "C1")
    # The raised arm: upper arm out from the shoulder, the forearm up the glass to the cuff at the wrist. It stops
    # below the bar of the window, so the hand that comes out of it lies on one pane.
    cuff = 108
    arm = [(cx + 34, 146), (cx + 48, 158), (cx + 62, 150), (cx + 70, 128), (cx + 70, cuff + 1), (cx + 57, cuff), (cx + 56, 124), (cx + 48, 138)]
    fill(img, arm, "C0")
    fill(img, [(cx + 52, 146), (cx + 60, 142), (cx + 66, 126), (cx + 66, cuff + 4), (cx + 61, cuff + 4), (cx + 60, 126)], "C1")
    # The arm to the sill.
    fill(img, [(cx - 54, 170), (cx - 60, 196), (cx - 74, 180), (cx - 80, 170), (cx - 70, 164), (cx - 60, 164)], "C0")
    # The moon is beyond him and to his left: it runs along that side of everything, and over his shoulders.
    for (x0, y0), (x1, y1) in zip(coat[1:6], coat[2:7]):
        line(img, x0, y0, x1, y1, "C7")
        line(img, x0 + 1, y0 + 1, x1 + 1, y1 + 1, "C4")
    for (x0, y0), (x1, y1) in zip(coat[6:8], coat[7:9]):
        line(img, x0, y0, x1, y1, "C4")
    line(img, cx - 80, 170, cx - 70, 164, "C7")
    line(img, cx - 70, 164, cx - 60, 164, "C7")
    for (x0, y0), (x1, y1) in zip(arm[4:7], arm[5:8]):
        line(img, x0, y0, x1, y1, "C6")
    # The scarf, in the collar.
    fill(img, [(cx - 16, 132), (cx + 18, 132), (cx + 20, 138), (cx - 18, 138)], "T2")
    hline(img, cx - 15, cx + 17, 132, "T3")
    hline(img, cx - 12, cx + 4, 135, "T3")
    # The head: bent forward and to the right, the near ear, the cheek and beard beyond it, hair to the collar.
    hx, hy = cx + 4, 110
    for y in range(hy - 22, hy + 24):
        for x in range(hx - 20, hx + 22):
            ex, ey = (x - hx) / 17.0, (y - hy) / 21.0
            if ex * ex + ey * ey <= 1.0:
                put(img, x, y, "E1" if (x - hx) + (y - hy) * 0.3 < 9 else "E2")
    # The moon along the left of the skull.
    for y in range(hy - 20, hy + 18):
        x = round(hx - 17.0 * math.sqrt(max(0.0, 1 - ((y - hy) / 21.0) ** 2)))
        put(img, x, y, "C7")
        put(img, x + 1, y, "C4")
    # The cheek, turned to the glass: skin from the temple to the jaw, the beard under it, an ear.
    fill(img, [(hx + 9, hy - 8), (hx + 16, hy - 6), (hx + 18, hy + 4), (hx + 15, hy + 12), (hx + 8, hy + 10), (hx + 7, hy)], "S0")
    fill(img, [(hx + 12, hy - 6), (hx + 16, hy - 5), (hx + 17, hy + 3), (hx + 13, hy + 4)], "S1")
    fill(img, [(hx + 4, hy + 10), (hx + 15, hy + 12), (hx + 12, hy + 21), (hx + 2, hy + 22), (hx - 2, hy + 16)], "W1")
    fill(img, [(hx + 9, hy + 13), (hx + 14, hy + 13), (hx + 11, hy + 20)], "W0")
    rows(img, hx + 3, hy - 4, [".sS.", "sSSs", "sSSs", ".sS."], SAILOR)
    # The hand on the glass, beside his ear: the back of the right hand, pale against the night, the fingers spread
    # and the thumb out towards him. The wrist goes down into the cuff, and the cuff's edge crosses in front of it.
    rows(img, cx + 52, cuff - 17, [
        ".........s........",
        "......s..s..s.....",
        "......s..s..s.....",
        "......s..s..s..s..",
        "......s..s..s..s..",
        "......ss.s..s.ss..",
        ".......s.ss.s.s...",
        ".......sssssssS...",
        ".s.....ssssssSS...",
        ".ss....ssssssSS...",
        "..ss...ssssssSS...",
        "...ss.sssssssSS...",
        "....sssssssssS....",
        ".....ssssssssS....",
        "......sssssSS.....",
        ".......sssSSS.....",
        ".......sssSSS.....",
        ".......sssSSS.....",
        ".......sssSSS.....",
    ], SAILOR)
    line(img, cx + 57, cuff, cx + 70, cuff + 1, "C6")
    line(img, cx + 58, cuff + 1, cx + 69, cuff + 2, "C0")
    # The hand on the sill: the knuckles over its edge.
    rows(img, cx - 84, wy1 - 6, ["...ssss..", "..sssssss", ".ssSsSsSs", ".sSsSsSsS", "..S.S.S.S"], SAILOR)
    return img


# ---------------------------------------------------------------- 3. the bracelet


def mark(img, cx, cy, color, s=1.0):
    """The mark, as on the talisman and the Monolith: an eye above two lines of waves."""
    for x in range(round(cx - 13 * s), round(cx + 13 * s) + 1):
        h = 5.5 * s * math.sqrt(max(0.0, 1 - ((x - cx) / (13.0 * s)) ** 2))
        put(img, x, round(cy - h), color)
        put(img, x, round(cy + h), color)
    for y in range(round(cy - 3 * s), round(cy + 3 * s) + 1):
        for x in range(round(cx - 2 * s), round(cx + 2 * s) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= (2.6 * s) ** 2:
                put(img, x, y, color)
    for k, row in enumerate((cy + 10 * s, cy + 15 * s)):
        for i in range(round(-15 * s), round(15 * s) + 1):
            put(img, cx + i, round(row - 2 * abs(math.sin((i + k * 2) * math.pi / 6.0))), color)


def bracelet(img, cx, cy):
    """A gold cuff standing on its edge, seen from above and before: a band bent nearly to a ring, its ends apart at
    the front with a ball on each, broad where it carries the mark and narrowing toward its ends. One looks through
    it: its far side shows its inner face, in shadow, and the stand shows inside its ring. A band with an opening
    and a thickness, which no plate has."""
    rx, ry = 52, 19
    opening = (22.0, 62.0)
    def broad(angle):
        """Half the band's height: broadest at the mark, least at the ends."""
        return 5.0 + 9.0 * max(0.0, math.cos(math.radians(angle - 112.0) / 1.6)) ** 2
    def at(angle):
        return cx + rx * math.cos(math.radians(angle)), cy + ry * math.sin(math.radians(angle))
    # The far side, behind: its inner face, dark, with the light catching only its upper edge.
    for step in range(1800, 3601):
        angle = step / 10.0
        x, y = at(angle)
        half = broad(angle)
        for yy in range(round(y - half), round(y + half) + 1):
            put(img, round(x), yy, "A0" if (yy - (y - half)) < 3 else "W1")
        put(img, round(x), round(y - half), "A2")
        put(img, round(x), round(y - half) + 1, "A1")
        put(img, round(x), round(y + half), "W0")
    # The near side, before: its outer face, lit from the upper right.
    for step in range(0, 1801):
        angle = step / 10.0
        if opening[0] < angle < opening[1]:
            continue
        x, y = at(angle)
        half = broad(angle)
        facing = math.cos(math.radians(angle - 58.0))
        for yy in range(round(y - half), round(y + half) + 1):
            t = (yy - (y - half)) / (2 * half)
            value = 1.3 + 1.2 * facing - 1.1 * t + 0.9 * math.exp(-((t - 0.22) / 0.12) ** 2)
            put(img, round(x), yy, ramp(["A0", "A1", "A2", "A3"], value, round(x), yy, 0.3))
        # The thickness of the metal, along the top.
        put(img, round(x), round(y - half) - 1, "A3")
        put(img, round(x), round(y - half) - 2, "A2" if facing > 0 else "A1")
        put(img, round(x), round(y + half), "A0")
        put(img, round(x), round(y + half) + 1, "W0")
    # The ends, cut square across the band, each with its ball.
    for angle in opening:
        x, y = at(angle)
        half = broad(angle)
        for yy in range(round(y - half) - 2, round(y + half) + 1):
            put(img, round(x), yy, "A0")
            put(img, round(x) + (1 if angle == opening[0] else -1), yy, "A1")
        ellipse(img, x, y, 5.0, 5.0, "A1")
        ellipse(img, x + 0.8, y - 1.0, 3.2, 3.2, "A2")
        put(img, round(x + 2), round(y - 3), "A3")
        put(img, round(x + 1), round(y - 3), "A3")
        for dx in range(-3, 4):
            put(img, round(x) + dx, round(y) + 5, "A0")
    # The mark, cut into the broadest of the near side and following its curve: the eye, and two lines of waves.
    engraved = blank(31, 21)
    for x in range(4, 27):
        h = 4.6 * math.sqrt(max(0.0, 1 - ((x - 15) / 11.5) ** 2))
        put(engraved, x, round(5 - h), "W0")
        put(engraved, x, round(5 + h), "W0")
    for x in range(14, 17):
        for y in range(4, 7):
            put(engraved, x, y, "W0")
    for row in (14, 19):
        for x in range(2, 29):
            put(engraved, x, row - (1 if (x + (row // 5)) % 6 < 3 else 0) - (1 if (x + (row // 5)) % 6 == 1 else 0), "W0")
    for ex in range(31):
        angle = 112.0 + math.degrees((15 - ex) / rx)
        x, y = at(angle)
        for ey in range(21):
            if engraved.getpixel((ex, ey))[3]:
                put(img, round(x), round(y) - 10 + ey, "W0")


def panel_shop():
    img = blank(W, H)
    noise = Noise(413)
    # The street front: old brick, damp.
    for y in range(H):
        course = y // 9
        for x in range(W):
            joint = y % 9 == 0 or (x + course % 2 * 11) % 22 == 0
            value = 1.5 + (noise(x / 5.0 + course * 3.0, course * 7.0 + (x + course % 2 * 11) // 22) - 0.5) * 1.6 - (1.0 if joint else 0.0)
            put(img, x, y, ramp(["E0", "E1", "E2", "E3"], value, x, y, 0.3))
    wx0, wy0, wx1, wy1 = 62, 30, 418, 196
    # The sign over it: a board, and a fish cut in it.
    fill(img, [(wx0 + 60, 4), (wx1 - 60, 4), (wx1 - 60, 22), (wx0 + 60, 22)], "W0")
    hline(img, wx0 + 60, wx1 - 60, 4, "W2")
    fx, fy = 240, 13
    for x in range(-22, 19):
        h = 5 * math.sqrt(max(0.0, 1 - (x / 20.0) ** 2))
        put(img, fx + x, round(fy - h), "W3")
        put(img, fx + x, round(fy + h), "W3")
    line(img, fx + 19, fy, fx + 28, fy - 5, "W3")
    line(img, fx + 19, fy, fx + 28, fy + 5, "W3")
    line(img, fx + 28, fy - 5, fx + 28, fy + 5, "W3")
    put(img, fx - 14, fy - 1, "W3")
    # The window: a painted frame, and dark glass with the street's light lying in it in two soft bands.
    fill(img, [(wx0 - 6, wy0 - 6), (wx1 + 6, wy0 - 6), (wx1 + 6, wy1 + 6), (wx0 - 6, wy1 + 6)], "W1")
    hline(img, wx0 - 6, wx1 + 6, wy0 - 6, "W3")
    for y in range(wy0 - 5, wy1 + 6):
        put(img, wx1 + 6, y, "W3")
        put(img, wx0 - 6, y, "W0")
    for y in range(wy0, wy1):
        for x in range(wx0, wx1):
            band = math.exp(-(((x - y * 0.35 - 96) / 16.0) ** 2)) + 0.6 * math.exp(-(((x - y * 0.35 - 300) / 9.0) ** 2))
            value = 0.7 + 0.9 * band + (noise(x / 50.0, y / 50.0) - 0.5) * 0.5
            put(img, x, y, ramp(["C0", "C1", "C2"], value, x, y, 0.25))
    for x in (wx0 + 118, wx1 - 118):
        fill(img, [(x - 2, wy0), (x + 2, wy0), (x + 2, wy1), (x - 2, wy1)], "W1")
        for y in range(wy0, wy1):
            put(img, x + 2, y, "W2")
    # He is in the glass, faintly: the cap, the shoulders. Looking in.
    reflection = [(322, 150), (326, 122), (338, 112), (346, 110), (346, 100), (343, 90), (346, 80), (356, 76), (366, 78), (374, 82), (376, 84), (368, 86), (370, 98), (366, 110), (376, 112), (390, 120), (396, 150)]
    ghost = Image.new("L", (W, H), 0)
    ImageDraw.Draw(ghost).polygon(reflection, fill=255)
    for y in range(70, 152):
        for x in range(318, 400):
            if ghost.getpixel((x, y)):
                put(img, x, y, "C2" if img.getpixel((x, y)) == rgba("C1") or img.getpixel((x, y)) == rgba("C0") else "C3")
    hline(img, 349, 364, 111, "T0")
    # The shelf, a cloth over it, and what a harbour shop sells: a compass, a clay pipe, a few coins, each ticketed.
    shelf = 152
    fill(img, [(wx0, shelf), (wx1, shelf), (wx1, wy1), (wx0, wy1)], "W0")
    for y in range(shelf, wy1):
        for x in range(wx0, wx1):
            fold = math.sin(x / 13.0 + 2.0 * math.sin(y / 9.0))
            value = 1.3 + 0.8 * fold - (y - shelf) * 0.02
            put(img, x, y, ramp(["W0", "W1", "W2"], value, x, y, 0.3))
    hline(img, wx0, wx1, shelf, "W3")
    ellipse(img, 118, 170, 12, 6, "C4")
    ellipse(img, 118, 170, 10, 4.4, "C8")
    line(img, 111, 172, 125, 168, "C0")
    put(img, 125, 168, "A1")
    line(img, 336, 176, 362, 170, "C8")
    fill(img, [(362, 166), (369, 165), (370, 172), (363, 173)], "C7")
    for x, y in ((384, 178), (392, 174), (398, 180)):
        ellipse(img, x, y, 3.4, 1.8, "A1")
        hline(img, x - 2, x + 1, y - 1, "A2")
    for x, y in ((100, 184), (350, 184), (236, 186)):
        fill(img, [(x, y), (x + 9, y), (x + 9, y + 5), (x, y + 5)], "C8")
        hline(img, x + 2, x + 6, y + 2, "C4")
    # The bracelet, in the middle of the window, on a dark stand that lifts it clear: gold, the only gold here.
    fill(img, [(176, 102), (308, 102), (322, 172), (162, 172)], "T0")
    hline(img, 176, 308, 102, "T1")
    for x in range(190, 300, 27):
        line(img, x, 104, x - 8 + (x - 242) // 6, 171, "C0")
    # Its shadow on the stand, under and to the left of it.
    for y in range(140, 168):
        for x in range(176, 300):
            if ((x - 234) / 60.0) ** 2 + ((y - 156) / 11.0) ** 2 <= 1.0 and (x + y) % 2:
                put(img, x, y, "C0")
    bracelet(img, 242, 130)
    return img


# ---------------------------------------------------------------- 4. the last sea


def crest_of_the_reveal():
    """The reveal's own crest, with the moon on it, at the size it has there on the screen."""
    base, lit, _at = gen_creature.crest(gen_reveal.scene_polygon("Crest", "Dagon/Head"))
    whole = base.copy()
    whole.alpha_composite(lit)
    return whole.resize((whole.width // 2, whole.height // 2), Image.NEAREST)


def panel_rising():
    img = gen_shore.sky()
    noise = Noise(414)
    rng = random.Random(415)
    horizon = 128
    night_sea(img, noise, top=horizon, calm=0.6)
    hline(img, 0, W - 1, horizon, "C3")
    moon_road(img, noise, gen_shore.MOON[0] + 70, horizon + 1, CLEAR_OF_THE_CARD + 30, 34)
    # What breaks the water: the crest, and under it the top of the head it stands on, a long low back.
    cx, sea = 222, 166
    crest = crest_of_the_reveal()
    img.alpha_composite(crest, (cx - 42, sea - 18 - crest.height + 16))
    back = {}
    for x in range(cx - 74, cx + 70):
        t = (x - cx + 4) / 74.0
        rise = 15 * math.sqrt(max(0.0, 1 - t * t)) * (1.0 - 0.25 * t)
        if rise < 1:
            continue
        top = round(sea - rise)
        back[x] = top
        for y in range(top, sea + 2):
            lit = y - top < 2 and x > cx - 30
            put(img, x, y, ("T3" if (x + y) % 3 else "T2") if lit else ("C1" if y - top < 5 and noise(x / 5.0, y / 3.0) > 0.5 else "C0"))
    # The sea it has lifted: a dark swell standing round it, the moon's road bent on its near slope, and the rings
    # running out from it across the calm.
    for y in range(sea - 4, sea + 16):
        for x in range(cx - 130, cx + 126):
            t = (x - cx) / 128.0
            swell = (sea + 15) - 19 * max(0.0, 1 - t * t) ** 1.5
            if y >= swell and (x not in back or y > sea + 1) and 0 <= x < W:
                depth = (y - swell) / 16.0
                value = 0.2 + 1.9 * depth + (noise(x / 16.0, y / 2.0) - 0.5) * 0.8
                put(img, x, y, ramp(["C0", "C1", "T0", "C2"], value, x, y, 0.3))
    for ring, (rx, ry) in enumerate(((104, 12), (134, 19), (168, 27), (206, 36))):
        for step in range(0, 1800, 2):
            angle = math.radians(step / 10.0)
            x, y = round(cx + rx * math.cos(angle)), round(sea + 4 + ry * math.sin(angle))
            if 0 <= x < W and y < CLEAR_OF_THE_CARD + 34 and noise(x / 7.0, ring * 3.0 + 1.0) > 0.42:
                put(img, x, y, "C5" if ring < 2 else "C4")
                if ring == 0 and noise(x / 3.0, 2.0) > 0.55:
                    put(img, x, y - 1, "C7")
    # White water where its back leaves the sea, and the sea pouring off the crest and the back.
    for x in sorted(back):
        if noise(x / 2.5, 7.0) > 0.25:
            y = sea + 1 + round(2 * noise(x / 6.0, 8.0))
            put(img, x, y, "C8" if noise(x / 2.0, 9.0) > 0.45 else "C7")
            put(img, x, y + 1, "C6" if noise(x / 3.0, 10.0) > 0.5 else "C4")
            if noise(x / 3.0, 11.0) > 0.6:
                put(img, x, y - 1, "C9")
    for end in (cx - 78, cx + 72):
        for k in range(14):
            put(img, end + (k if end > cx else -k), sea + 2 + (k % 3 == 0), "C7" if k % 2 else "C5")
    for x in sorted(back)[6:-6:5]:
        length = rng.randrange(4, 11)
        for k in range(length):
            if (k + x) % 3:
                put(img, x, back[x] + 2 + k, "C6" if k < 3 else "C4")
    for tip_x, tip_y in ((cx - 36, sea - 62), (cx - 16, sea - 70), (cx + 2, sea - 68), (cx + 24, sea - 56), (cx + 42, sea - 40)):
        length = rng.randrange(10, 22)
        for k in range(length):
            if (k + tip_x) % 4:
                put(img, tip_x + 4 + k // 7, tip_y + 14 + k, "C6" if k < length // 2 else "C5")
    for _ in range(40):
        x, y = cx + rng.randrange(-84, 84), sea - rng.randrange(2, 22)
        if img.getpixel((x, y)) not in (rgba("C0"), rgba("T3"), rgba("T2"), rgba("T1")):
            put(img, x, y, rng.choice(("C7", "C8", "C6")))
    # The town, for the size of it: a spit of land with its roofs and a steeple, two windows lit, a boat at anchor.
    spit = []
    for x in range(0, 132):
        land = 180 - 9 * math.exp(-((x - 30) / 60.0) ** 2) + 3 * noise(x / 9.0, 20.0) + max(0, x - 96) * 0.5
        spit.append(round(land))
        for y in range(round(land), H):
            put(img, x, y, "C0" if noise(x / 7.0, y / 5.0) > 0.3 else "E0")
    for x0, wide, tall in ((6, 11, 8), (19, 9, 6), (30, 13, 9), (46, 8, 6), (56, 12, 8), (71, 9, 6), (84, 10, 5)):
        ground = spit[x0 + wide // 2]
        fill(img, [(x0, ground), (x0, ground - tall), (x0 + wide // 2, ground - tall - 4), (x0 + wide, ground - tall), (x0 + wide, ground)], "C0")
        put(img, x0 + wide // 2, ground - tall - 4, "C3")
        put(img, x0 + wide - 1, ground - tall, "C2")
    fill(img, [(37, spit[38] - 9), (39, spit[38] - 26), (41, spit[38] - 9)], "C0")
    put(img, 39, spit[38] - 26, "C3")
    for x, y in ((10, spit[11] - 4), (61, spit[62] - 4)):
        put(img, x, y, "A2")
        put(img, x + 1, y, "A1")
    bx, by = 112, 187
    fill(img, [(bx, by), (bx + 14, by), (bx + 12, by + 3), (bx + 2, by + 3)], "C0")
    line(img, bx + 7, by, bx + 7, by - 12, "C0")
    hline(img, bx - 2, bx + 16, by + 4, "C4")
    return img
