"""Draws the stranded ship's lifeboat, seen from a little above, canted toward the viewer so the
rim, interior and thwarts all read. Double-ended, lapstrake planks. A plank is stove in near the
stern, an oar leans against the hull, and a rope runs from the bow to a coil in the sand."""

import math
import random

from art_common import blank, hline, line, put

W, H = 112, 46
GROUND = H - 3  # Row of the sand surface under the keel.
X0, LENGTH = 11, 84


def rim_near(t):
    """Near gunwale: rows up from the ground, with sheer rising to both ends. The boat is canted bow-up."""
    sheer = 6.5 * (2 * t - 1) ** 4 + 1.5 * (2 * t - 1) ** 2
    return 15 + sheer + 2.0 * t


def rim_far(t):
    """Far gunwale, visible above the near one because the boat leans toward the viewer."""
    opening = 7.5 * math.sin(math.pi * t) ** 0.6
    return rim_near(t) + opening


def keel(t):
    """Bottom of the hull. It rises steeply to the stems, and the middle is sunk in the sand."""
    rocker = 11.0 * abs(2 * t - 1) ** 3.2
    return -1 + rocker + 1.2 * t


def draw():
    img = blank(W, H)
    rng = random.Random(41)

    def row(height):
        return GROUND - round(height)

    # Interior first: far inner planking, then the dark bottom.
    for x in range(X0, X0 + LENGTH + 1):
        t = (x - X0) / LENGTH
        top, bottom = row(rim_far(t)), row(rim_near(t))
        for y in range(top, bottom + 1):
            f = (y - top) / max(bottom - top, 1)
            color = "W2" if f < 0.3 else ("W1" if f < 0.62 else "W0")
            put(img, x, y, color)
        # A single line of inner plank, not one on every strake.
        if top + 2 < bottom and x % 19 > 1:
            put(img, x, top + 2, "W0")

    # Ribs on the far inner side.
    for x in range(X0 + 9, X0 + LENGTH - 8, 8):
        t = (x - X0) / LENGTH
        top, bottom = row(rim_far(t)), row(rim_near(t))
        for y in range(top + 1, min(top + 4, bottom)):
            put(img, x, y, "W1")

    # Thwarts: three benches across the boat.
    for t in (0.27, 0.5, 0.73):
        x = X0 + round(t * LENGTH)
        top, bottom = row(rim_far(t)), row(rim_near(t))
        for y in range(top + 1, bottom + 1):
            lean = round((bottom - y) * 0.55)
            hline(img, x - 3 + lean, x + 3 + lean, y, "W3")
            put(img, x - 4 + lean, y, "W0")
            put(img, x + 4 + lean, y, "W1")
        lean = round((bottom - (top + 1)) * 0.55)
        hline(img, x - 3 + lean, x + 3 + lean, top + 1, "W4")

    # Near hull: overlapping planks, darkening toward the sand.
    plank_edges = (0.2, 0.43, 0.68)
    for x in range(X0, X0 + LENGTH + 1):
        t = (x - X0) / LENGTH
        top, bottom = row(rim_near(t)), row(keel(t))
        span = max(bottom - top, 1)
        for y in range(top, bottom + 1):
            f = (y - top) / span
            if f < plank_edges[0]:
                color = "W3"
            elif f < plank_edges[1]:
                color = "W2"
            elif f < plank_edges[2]:
                color = "W1"
            else:
                color = "W1" if f < 0.85 else "W0"
            put(img, x, y, color)
        # Selective lap lines: broken on purpose, so the hull does not look ruled.
        for i, edge in enumerate(plank_edges):
            if (x + i * 13) % 23 > 3 and rng.random() > 0.08:
                put(img, x, top + round(edge * span), "W0" if i > 0 else "W1")

    # Rivets along one strake only.
    for x in range(X0 + 12, X0 + LENGTH - 10, 7):
        t = (x - X0) / LENGTH
        top, bottom = row(rim_near(t)), row(keel(t))
        put(img, x, top + round(0.3 * (bottom - top)), "W4")

    # Stove-in plank near the stern.
    for (dx, dy) in [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (-1, 1), (0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
                     (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (1, 3), (2, 3)]:
        put(img, X0 + 21 + dx, row(rim_near(0.3)) + 6 + dy, "W0")
    put(img, X0 + 20, row(rim_near(0.3)) + 6, "W4")
    put(img, X0 + 26, row(rim_near(0.3)) + 8, "W4")
    put(img, X0 + 25, row(rim_near(0.3)) + 6, "W3")

    # Gunwales: the brightest wood, with cool moonlight on the near rim where it faces the sky.
    for x in range(X0, X0 + LENGTH + 1):
        t = (x - X0) / LENGTH
        put(img, x, row(rim_far(t)), "W3")
        near = row(rim_near(t))
        put(img, x, near, "W4")
        put(img, x, near + 1, "W2")
        if 0.38 < t < 0.97 and (x % 11) > 2:
            put(img, x, near, "C7")

    # Stem posts rise past the rim at each end.
    for x_end, t_end in ((X0, 0.0), (X0 + LENGTH, 1.0)):
        base = row(rim_near(t_end))
        direction = -1 if t_end == 0.0 else 1
        for i in range(5):
            put(img, x_end + direction * (i // 2), base - i, "W3")
            put(img, x_end + direction * (i // 2) - direction, base - i, "W1")
        put(img, x_end + direction * 2, base - 5, "W4")

    # Oar: leans on the hull amidships with its blade down in the sand.
    top_x, top_y = X0 + 53, row(rim_far(0.63)) - 4
    foot_x, foot_y = X0 + 79, GROUND + 1
    line(img, top_x, top_y, foot_x - 3, foot_y - 11, "W4")
    line(img, top_x + 1, top_y + 1, foot_x - 2, foot_y - 10, "W2")
    for i, width in enumerate((1, 2, 2, 3, 3, 3, 3, 3, 2, 2)):
        y = foot_y - 10 + i
        x = foot_x - 3 + round(i * 0.45)
        hline(img, x - width // 2, x + width - width // 2 - 1, y, "W3")
        put(img, x + width - width // 2 - 1, y, "W4")
        put(img, x - width // 2, y, "W1")

    # Rope from the bow ring, sagging to a coil on the sand.
    bow_x, bow_y = X0 + LENGTH - 1, row(rim_near(1.0)) + 5
    put(img, bow_x, bow_y, "C6")
    for i in range(0, 14):
        s = i / 13
        x = bow_x + 1 + round(s * 12)
        y = bow_y + 1 + round((GROUND - 1 - bow_y) * s ** 1.7)
        put(img, x, y, "W4" if i % 2 else "W3")
    coil_x, coil_y = bow_x + 13, GROUND - 1
    hline(img, coil_x - 2, coil_x + 2, coil_y, "W3")
    hline(img, coil_x - 3, coil_x + 3, coil_y + 1, "W4")
    put(img, coil_x - 1, coil_y, "W1")
    put(img, coil_x + 1, coil_y + 1, "W2")

    # Contact: a dark line where the hull meets sand, then sand banked up over the keel.
    for x in range(X0 + 6, X0 + LENGTH - 5):
        t = (x - X0) / LENGTH
        y = row(keel(t))
        if y >= GROUND - 4:
            put(img, x, y + 1, "E0")
    heap = random.Random(7)
    for x in range(X0 - 4, X0 + LENGTH + 6):
        t = (x - (X0 - 4)) / (LENGTH + 10)
        height = 2.2 * math.sin(math.pi * t) ** 0.5 + heap.random() * 0.8
        for k in range(round(height) + 1):
            put(img, x, GROUND - k + 2, "E4" if k == round(height) else "E3")
    return img
