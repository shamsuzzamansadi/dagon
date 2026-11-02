"""Checks the generated preview art: one palette, and feet that do not slide.

Usage: python tools/art/check_art.py
Exits non-zero on any failure.
"""

import pathlib
import sys

from PIL import Image

from gen_sailor import FRAME_H, FRAME_W, STEP
from palette import ALLOWED, rgba

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "project" / "assets" / "preview"
# light.png is a light mask, not artwork: its values multiply the lantern colour.
ARTWORK = ["sky", "clouds", "far", "glints", "flats", "bank", "terrain", "foreground", "fish", "boat", "sailor"]
IDLE_FRAMES = 8
WALK_FRAMES = 8


def bottom_row_columns(sheet, frame, color):
    left = frame * FRAME_W
    return [x for x in range(FRAME_W) if sheet.getpixel((left + x, FRAME_H - 1)) == color]


def main():
    problems = []
    for name in ARTWORK:
        image = Image.open(OUT / f"{name}.png").convert("RGBA")
        off_palette = {c for _, c in image.getcolors(1 << 24) if c[3] != 0 and c not in ALLOWED}
        if off_palette:
            problems.append(f"{name}.png has {len(off_palette)} colours outside the palette")
    print(f"palette: checked {len(ARTWORK)} images against {len(ALLOWED)} colours")

    # Each foot's sole has its own colour, so its position can be read from the shipped pixels.
    sheet = Image.open(OUT / "sailor.png").convert("RGBA")
    for label, color, frames in (("near", rgba("E0"), (1, 2, 3)), ("far", rgba("C0"), (5, 6, 7))):
        positions = []
        for f in frames:
            columns = bottom_row_columns(sheet, IDLE_FRAMES + f, color)
            if not columns:
                problems.append(f"{label} foot is not on the ground in walk frame {f}")
                continue
            positions.append(columns[0])
        steps = [a - b for a, b in zip(positions, positions[1:])]
        print(f"{label} foot heel columns in frames {frames}: {positions}, back by {steps} px per frame")
        if any(step != STEP for step in steps):
            problems.append(f"{label} planted foot moves {steps}, expected {STEP} per frame")
    for f in range(WALK_FRAMES):
        left = (IDLE_FRAMES + f) * FRAME_W
        if not any(sheet.getpixel((left + x, FRAME_H - 1))[3] for x in range(FRAME_W)):
            problems.append(f"walk frame {f} has no foot on the ground")

    for problem in problems:
        print(f"PROBLEM {problem}")
    print(f"CHECK_ART problems={len(problems)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
