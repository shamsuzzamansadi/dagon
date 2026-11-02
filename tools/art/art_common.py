"""Small drawing helpers shared by the preview's art scripts. Everything is deterministic."""

import math
import random

from PIL import Image

from palette import rgba

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(image, x, y, color):
    if 0 <= x < image.width and 0 <= y < image.height:
        image.putpixel((x, y), rgba(color))


def hline(image, x0, x1, y, color):
    for x in range(int(x0), int(x1) + 1):
        put(image, x, y, color)


def line(image, x0, y0, x1, y1, color):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(int(steps) + 1):
        put(image, round(x0 + (x1 - x0) * i / steps), round(y0 + (y1 - y0) * i / steps), color)


def ramp(names, value, x, y, dither=0.45):
    """Picks from a colour ramp. Ordered dither only near a band edge, so bands stay deliberate."""
    value = max(0.0, min(value, len(names) - 1.0))
    base = int(value)
    if base >= len(names) - 1:
        return names[-1]
    frac = value - base
    threshold = (BAYER[y % 4][x % 4] + 0.5) / 16.0
    adjusted = 0.5 + (frac - 0.5) / max(dither, 0.01)
    return names[base + 1] if adjusted > threshold else names[base]


class Noise:
    """Tileable value noise on a lattice."""

    def __init__(self, seed, period=64):
        rng = random.Random(seed)
        self.period = period
        self.grid = [[rng.random() for _ in range(period)] for _ in range(period)]

    def _at(self, x, y):
        return self.grid[y % self.period][x % self.period]

    def __call__(self, x, y):
        ix, iy = math.floor(x), math.floor(y)
        fx, fy = x - ix, y - iy
        fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        top = self._at(ix, iy) * (1 - fx) + self._at(ix + 1, iy) * fx
        bottom = self._at(ix, iy + 1) * (1 - fx) + self._at(ix + 1, iy + 1) * fx
        return top * (1 - fy) + bottom * fy

    def fractal(self, x, y, octaves=3):
        total, amp, norm = 0.0, 1.0, 0.0
        for i in range(octaves):
            total += self(x * (2**i), y * (2**i)) * amp
            norm += amp
            amp *= 0.5
        return total / norm
