"""Measures how far the character moves on screen between rendered frames of a Movie Maker capture.

Usage: python measure_jitter.py <frame-dir> <fps> <start-seconds> <end-seconds>

It tracks a point fixed to the character: the top of the sailor's face, or of the greybox
silhouette. While the camera follows, that point should not move. A flicker is the point
stepping one way and then back.
"""

import glob
import sys

from PIL import Image

SKIN = (0xB5, 0x8A, 0x6D)
SILHOUETTE = (183, 193, 204)


def tracked_x(path):
    """The leftmost pixel of the top row of the face or silhouette, which is fixed to the head."""
    image = Image.open(path).convert("RGB")
    pixels = image.load()
    for color in (SKIN, SILHOUETTE):
        for y in range(image.height):
            for x in range(image.width):
                if pixels[x, y] == color:
                    return x
    return None


def main():
    frames = sorted(glob.glob(sys.argv[1] + "/frame*.png"))
    fps, start, end = float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
    section = frames[int(start * fps) : int(end * fps)]
    xs = [tracked_x(path) for path in section]
    xs = [x for x in xs if x is not None]
    steps = [b - a for a, b in zip(xs, xs[1:]) if b != a]
    reversals = sum(1 for a, b in zip(steps, steps[1:]) if a * b < 0)
    print(f"{len(xs)} frames, t={start:g}-{end:g} s: {len(steps)} changes, {reversals} flickers back, x from {min(xs)} to {max(xs)}")


if __name__ == "__main__":
    main()
