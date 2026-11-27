#!/usr/bin/env python3
"""The itch page's cover and screenshots, from frames of the exported game. Pillow only.

  make_images.py <frames dir from itch_shots.py> <route_check shots dir> <pixel_font.fnt> <out dir>

Each frame is a capture of the game at 1440 x 810, which is its 480 x 270 picture at 3 x 3 pixels a block. It is reduced
to that picture exactly, and refused if any block holds more than one colour; then enlarged by whole numbers only.
"""
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fnt_text  # noqa: E402

NATIVE = (480, 270)
SCREENSHOTS = [
    ("screenshot-1.png", "frames", "0093.png"),
    ("screenshot-2.png", "shots", "03-prologue.png"),
    ("screenshot-3.png", "frames", "0108.png"),
    ("screenshot-4.png", "frames", "0130.png"),
    ("screenshot-5.png", "frames", "0150.png"),
]
COVER_FRAME = ("frames", "0093.png")
COVER_CROP = (40, 12)  # left, top of a 315 x 250 window on the 480 x 270 picture
TITLE, SUBTITLE = "DAGON", "Beneath the Black Tide"
PALE, SHADOW, SUB = (223, 230, 230, 255), (10, 14, 24, 255), (174, 188, 196, 255)  # palette C9, C0, C8


def native(path):
    im = Image.open(path).convert("RGB")
    assert im.size == (NATIVE[0] * 3, NATIVE[1] * 3), (path, im.size)
    small = im.resize(NATIVE, Image.NEAREST)
    if small.resize(im.size, Image.NEAREST).tobytes() != im.tobytes():
        raise SystemExit(f"{path}: not whole 3 x 3 blocks")
    return small


def shadowed(font, text, colour):
    w, h = fnt_text.measure(font, text)
    out = Image.new("RGBA", (w + 1, h + 1), (0, 0, 0, 0))
    out.alpha_composite(fnt_text.render(font, text, SHADOW), (1, 1))
    out.alpha_composite(fnt_text.render(font, text, colour), (0, 0))
    return out


def main():
    frames, shots, fnt, out = (Path(a) for a in sys.argv[1:5])
    out.mkdir(parents=True, exist_ok=True)
    source = {"frames": frames, "shots": shots}
    for name, where, frame in SCREENSHOTS:
        native(source[where] / frame).resize((1920, 1080), Image.NEAREST).save(out / name, optimize=True)
        print(name, "from", where, frame)
    font = fnt_text.load(fnt)
    x0, y0 = COVER_CROP
    cover = native(source[COVER_FRAME[0]] / COVER_FRAME[1]).crop((x0, y0, x0 + 315, y0 + 250)).convert("RGBA")
    title = shadowed(font, TITLE, PALE)
    title = title.resize((title.width * 4, title.height * 4), Image.NEAREST)
    sub = shadowed(font, SUBTITLE, SUB)
    tx = 30
    cover.alpha_composite(title, (tx, 22))
    cover.alpha_composite(sub, (tx + (title.width - 4 - sub.width + 1) // 2, 22 + title.height + 4))
    cover.convert("RGB").resize((630, 500), Image.NEAREST).save(out / "cover.png", optimize=True)
    print("cover.png from", *COVER_FRAME, "crop", COVER_CROP)


if __name__ == "__main__":
    main()
