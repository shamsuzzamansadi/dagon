"""Checks the generated Shore art: one palette, feet that do not slide, and a drawn ground that is
where the collision is.

Usage: python tools/art/check_art.py
Exits non-zero on any failure.
"""

import pathlib
import re
import sys

from PIL import Image

from gen_sailor import FRAME_H, FRAME_W, STEP
from gen_shore import GROUND_ROW
from palette import ALLOWED, rgba

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "project" / "assets" / "shore"
SCENE = ROOT / "project" / "scenes" / "level" / "shore.tscn"
UI_OUT = ROOT / "project" / "assets" / "ui"
# light.png is a light mask, not artwork: its values multiply the lantern colour.
ARTWORK = ["sky", "clouds", "far", "glints", "flats", "bank", "terrain", "foreground", "fish", "boat", "sailor", "talisman"]
IDLE_FRAMES = 8
WALK_FRAMES = 8
# Walkable columns between the feet of the side cliffs, and the space a figure stands in above them.
OPEN_GROUND = range(30, 615)
HEADROOM_ROWS = 30
# Weed and small stones may lie on the ground. A standing surface, such as the rock's top, may not.
DRESSING_ROWS = 3
ROCK_TOP = -14
ROCK_FLARE_COLUMNS = 3


def bottom_row_columns(sheet, frame, color):
    left = frame * FRAME_W
    return [x for x in range(FRAME_W) if sheet.getpixel((left + x, FRAME_H - 1)) == color]


def collision_polygon():
    text = SCENE.read_text()
    match = re.search(r'\[node name="Ground" type="CollisionPolygon2D".*?polygon = PackedVector2Array\(([^)]*)\)', text, re.S)
    numbers = [float(n) for n in match.group(1).split(",")]
    return list(zip(numbers[0::2], numbers[1::2]))


def collision_top(polygon, x):
    """The highest point of the collision at world x."""
    tops = []
    for (x0, y0), (x1, y1) in zip(polygon, polygon[1:] + polygon[:1]):
        if min(x0, x1) <= x < max(x0, x1):
            tops.append(y0 + (y1 - y0) * (x - x0) / (x1 - x0))
    return min(tops)


def check_surface(problems):
    """Compares the drawn ground with the scene's collision, column by column."""
    terrain = Image.open(OUT / "terrain.png").convert("RGBA")
    polygon = collision_polygon()
    near_rock = 0
    for x in OPEN_GROUND:
        top = collision_top(polygon, x + 0.5)
        surface = round(top) + GROUND_ROW
        solid = [y for y in range(surface - HEADROOM_ROWS, terrain.height) if terrain.getpixel((x, y))[3] != 0]
        first = solid[0]
        if solid != list(range(first, terrain.height)):
            problems.append(f"terrain column {x} has a gap below row {first}")
        if top <= ROCK_TOP:
            if first != surface:
                problems.append(f"rock column {x} is drawn from row {first}, but its collision top is row {surface}")
            continue
        if any(collision_top(polygon, x + 0.5 + d) <= ROCK_TOP for d in range(-ROCK_FLARE_COLUMNS, ROCK_FLARE_COLUMNS + 1)):
            near_rock += 1
            continue
        if not surface - DRESSING_ROWS <= first <= surface + 1:
            problems.append(f"ground column {x} is drawn from row {first}, but its collision top is row {surface}")
    print(f"surface: compared {len(OPEN_GROUND)} columns with the collision in {SCENE.name}, {near_rock} of them beside the rock")


def main():
    problems = []
    for name in ARTWORK:
        image = Image.open(OUT / f"{name}.png").convert("RGBA")
        off_palette = {c for _, c in image.getcolors(1 << 24) if c[3] != 0 and c not in ALLOWED}
        if off_palette:
            problems.append(f"{name}.png has {len(off_palette)} colours outside the palette")
    # The font atlas is white by design: the theme colours it from the palette.
    for name in ["slider_grabber", "slider_grabber_focus"]:
        image = Image.open(UI_OUT / f"{name}.png").convert("RGBA")
        if {c for _, c in image.getcolors(1 << 24) if c[3] != 0} - ALLOWED:
            problems.append(f"{name}.png has colours outside the palette")
    print(f"palette: checked {len(ARTWORK) + 2} images against {len(ALLOWED)} colours")

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

    check_surface(problems)

    for problem in problems:
        print(f"PROBLEM {problem}")
    print(f"CHECK_ART problems={len(problems)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
