"""Draws the sailor: a small pixel rig for the legs and arms, hand-placed pixels for head and coat.

World convention inside a frame: x=0 is the body's centre and y=0 the ground, with y negative upward.
Feet are placed by stride arithmetic: a planted foot moves back STEP pixels per frame, and the
controller advances one frame per STEP pixels travelled, so the foot stays still in the world.
"""

import math

from PIL import Image

from palette import rgba

FRAME_W = 32
FRAME_H = 32
STEP = 4  # Pixels travelled per walk frame. Keep in sync with walk_pixels_per_frame in the scene.

HEAD = [
    # y=-27 downward. T crown light, c cap, P peak, h hair, s skin, S skin shadow, e eye, b beard.
    "...cTTc...",
    "..cTTTTc..",
    "..ccccccPP",
    "..hSSSss..",
    "..hsseSss.",
    "..hhssss..",
    "...bbbss..",
]
HEAD_X = -5

COAT = [
    # y=-20 downward. r moonlit rim, h light, d coat, D shade, b button, n/N scarf.
    "..rrnNNr..",
    ".rhhnnNhd.",
    ".Dhdddddd.",
    ".Dddddddb.",
    ".Dddddddd.",
    ".Dddddddb.",
    ".DDdddddd.",
    ".DDddddddd",
    ".DDDdddddd",
]
COAT_X = -5

COLORS = {
    "T": "C5", "c": "C1", "P": "C0", "h": "E2", "s": "S1", "S": "S0", "e": "C0", "b": "W1",
    "r": "C7", "d": "C1", "D": "C0", "n": "T2", "N": "T3",
}
COAT_COLORS = dict(COLORS, h="C3", b="C6")

# One whole gait cycle. Each foot: (x, lift, tilt), tilt +1 heel down/toe up, -1 toe down/heel up.
WALK = [
    # near foot,       far foot,          bob, lantern sway, far-arm hand x
    ((8, 0, 1), (-8, 0, -1), 1, 0, 5),
    ((4, 0, 0), (-4, 2, -1), 1, 0, 3),
    ((0, 0, 0), (0, 3, -1), 0, 1, 0),
    ((-4, 0, 0), (4, 2, 0), 0, 1, -3),
    ((-8, 0, -1), (8, 0, 1), 1, 0, -5),
    ((-4, 2, -1), (4, 0, 0), 1, 0, -3),
    ((0, 3, -1), (0, 0, 0), 0, -1, 0),
    ((4, 2, 0), (-4, 0, 0), 0, -1, 3),
]


class Frame:
    def __init__(self):
        self.image = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

    def px(self, x, y, color):
        cx, cy = FRAME_W // 2 + x, FRAME_H + y
        if 0 <= cx < FRAME_W and 0 <= cy < FRAME_H:
            self.image.putpixel((cx, cy), rgba(color))

    def line(self, x0, y0, x1, y1, color, brush=((0, 0),)):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(steps + 1):
            x = round(x0 + (x1 - x0) * i / steps)
            y = round(y0 + (y1 - y0) * i / steps)
            for dx, dy in brush:
                self.px(x + dx, y + dy, color)

    def sprite(self, rows, left, top, colors):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != ".":
                    self.px(left + i, top + j, colors[ch])


def knee(hip, ankle, thigh, shin, forward=1):
    """Two-bone IK: the knee bends toward the facing direction."""
    dx, dy = ankle[0] - hip[0], ankle[1] - hip[1]
    d = max(math.hypot(dx, dy), 0.001)
    if d >= thigh + shin:
        return (hip[0] + dx * thigh / d, hip[1] + dy * thigh / d)
    a = (thigh * thigh - shin * shin + d * d) / (2 * d)
    # Limit the bend: at this size a fully folded swing leg reads as kneeling, not walking.
    h = min(math.sqrt(max(thigh * thigh - a * a, 0)), 2.2)
    mx, my = hip[0] + dx * a / d, hip[1] + dy * a / d
    # Perpendicular to the leg, on the forward side.
    px, py = -dy / d, dx / d
    if px * forward < 0:
        px, py = -px, -py
    return (mx + px * h, my + py * h)


def draw_boot(f, ax, ay, tilt, sole, upper, hi, lifted=False):
    """Ankle at (ax, ay). Toe points forward. The bottom row sits at y=-1 on flat ground."""
    if lifted:  # Compact, so a swinging foot stays one clean shape.
        f.line(ax - 1, ay, ax + 1, ay + 1 if tilt < 0 else ay, sole)
        f.line(ax - 1, ay - 1, ax + 1, ay - 1 if tilt >= 0 else ay, upper)
    elif tilt == 0:
        for x in range(ax - 1, ax + 4):
            f.px(x, ay + 1, sole)
        for x in range(ax - 1, ax + 3):
            f.px(x, ay, upper)
        f.px(ax + 2, ay, hi)
    elif tilt > 0:  # Heel down, toe lifted.
        f.line(ax - 1, ay + 1, ax + 3, ay, sole)
        f.line(ax - 1, ay, ax + 2, ay - 1, upper)
    else:  # Toe down, heel lifted.
        f.line(ax - 1, ay, ax + 3, ay + 1, sole)
        f.line(ax - 1, ay - 1, ax + 2, ay, upper)


def draw_leg(f, hip, foot, base, shade, sole, upper, hi):
    fx, lift, tilt = foot
    ankle = (fx, -2 - lift)
    k = knee(hip, ankle, 6, 6)
    kx, ky = round(k[0]), round(k[1])
    # Thick on both axes, so a leg at full stride keeps its width.
    thigh_brush = ((0, 0), (1, 0), (-1, 0), (0, -1), (1, -1))
    shin_brush = ((0, 0), (1, 0), (0, -1))
    f.line(hip[0], hip[1], kx, ky, base, thigh_brush)
    f.line(kx, ky, ankle[0], ankle[1], base, shin_brush)
    # Shadow on the underside and back of the leg gives it volume.
    f.line(hip[0] - 1, hip[1] + 1, kx - 1, ky + 1, shade)
    f.line(kx - 1, ky, ankle[0], ankle[1], shade)
    # Wide trouser cuff at the boot: a period sailor's leg.
    f.px(ankle[0] + 2, ankle[1], base)
    f.px(ankle[0] - 1, ankle[1], shade)
    draw_boot(f, ankle[0], ankle[1], tilt, sole, upper, hi, lifted=lift > 0)


def draw_lantern(f, hx, hy):
    """Hangs from a hand at (hx, hy)."""
    f.px(hx, hy + 1, "C6")  # Bail.
    f.line(hx - 1, hy + 2, hx + 1, hy + 2, "E1")
    f.line(hx - 1, hy + 3, hx - 1, hy + 5, "E1")
    f.line(hx + 1, hy + 3, hx + 1, hy + 5, "E1")
    f.line(hx, hy + 3, hx, hy + 5, "A2")
    f.px(hx, hy + 4, "A3")
    f.px(hx - 1, hy + 4, "A1")
    f.line(hx - 1, hy + 6, hx + 1, hy + 6, "E1")


def draw_body(f, bob, lift_chest=0, far_hand=None, sway=0, near_hand=(7, -13), head_nod=0, blink=False):
    top = -20 + bob
    if far_hand is not None:
        # Far arm, behind the coat.
        f.line(0, top + 2, far_hand[0], far_hand[1], "C1", ((0, 0), (0, 1)))
        f.px(far_hand[0], far_hand[1] + 2, "S0")
    head_rows = HEAD if not blink else [r.replace("e", "s") for r in HEAD]
    coat_rows = COAT
    f.sprite(coat_rows, COAT_X, top - lift_chest, COAT_COLORS)
    f.sprite(head_rows, HEAD_X, top - 7 - lift_chest + head_nod, COLORS)
    # Near arm carries the lantern, drawn over the coat so the arm reads against the body.
    hand = (near_hand[0], near_hand[1] + bob)
    elbow = (2, top + 7)
    f.line(-1, top + 2, elbow[0], elbow[1], "C2", ((0, 0), (0, 1), (1, 0)))
    f.line(elbow[0], elbow[1], hand[0], hand[1], "C2", ((0, 0), (0, 1)))
    f.line(-1, top + 2, elbow[0], elbow[1], "C4")
    f.line(elbow[0], elbow[1], hand[0], hand[1], "C4")
    f.line(-2, top + 3, elbow[0] - 1, elbow[1] + 1, "C0")
    f.px(-1, top + 1, "C5")
    f.px(0, top + 1, "C5")
    f.px(hand[0], hand[1], "S1")
    f.px(hand[0] + 1, hand[1], "S0")
    draw_lantern(f, hand[0] + 1 + sway, hand[1])


def walk_frame(entry):
    near, far, bob, sway, far_arm = entry
    f = Frame()
    hip_y = -12 + bob
    # Far side is darker, so the two legs stay separate when they cross.
    draw_leg(f, (1, hip_y), far, "C2", "C1", "C0", "C0", "C1")
    draw_leg(f, (0, hip_y), near, "C7", "C6", "E0", "E1", "E3")
    draw_body(f, bob, far_hand=(far_arm, -13 + bob), sway=sway)
    return f.image


def idle_frame(breath, sway, blink=False):
    f = Frame()
    hip_y = -12
    draw_leg(f, (1, hip_y), (3, 0, 0), "C2", "C1", "C0", "C0", "C1")
    draw_leg(f, (0, hip_y), (-3, 0, 0), "C7", "C6", "E0", "E1", "E3")
    draw_body(f, 0, lift_chest=breath, far_hand=None, sway=sway, near_hand=(7, -13), blink=blink)
    return f.image


def air_frame(near, far, sway):
    f = Frame()
    hip_y = -13
    draw_leg(f, (1, hip_y), far, "C2", "C1", "C0", "C0", "C1")
    draw_leg(f, (0, hip_y), near, "C7", "C6", "E0", "E1", "E3")
    draw_body(f, -1, far_hand=(-4, -14), sway=sway, near_hand=(7, -15))
    return f.image


def all_frames():
    """Returns {animation: [frames]} in the order the sheet is laid out."""
    return {
        "idle": [
            idle_frame(0, 0), idle_frame(0, 0), idle_frame(1, 0), idle_frame(1, 1),
            idle_frame(1, 0), idle_frame(0, 0), idle_frame(0, -1), idle_frame(0, 0, blink=True),
        ],
        "walk": [walk_frame(e) for e in WALK],
        "jump": [air_frame((3, 5, 0), (-4, 3, -1), 1)],
        "fall": [air_frame((-2, 3, -1), (4, 5, 0), -1)],
    }
