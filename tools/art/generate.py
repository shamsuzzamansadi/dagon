"""Writes every Shore asset into project/assets/shore/.

Run from anywhere (needs Pillow): python tools/art/generate.py
Output is deterministic, so running it again changes nothing unless the scripts changed.
"""

import math
import pathlib

from PIL import Image

import gen_boat
import gen_sailor
import gen_shore

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "project" / "assets" / "shore"
RES = "res://assets/shore"

GLINT_TOP = gen_shore.HORIZON
GLINT_HEIGHT = gen_shore.TIDE_LINE - gen_shore.HORIZON + 2
GLINT_FRAMES = 4


def sprite_frames(texture, animations):
    """Writes a SpriteFrames resource: animations = [(name, fps, loop, [regions])]."""
    regions = [r for _, _, _, rs in animations for r in rs]
    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={len(regions) + 2} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{RES}/{texture}" id="1"]',
        "",
    ]
    index = 0
    frame_ids = []
    for _, _, _, rs in animations:
        ids = []
        for x, y, w, h in rs:
            lines += [f'[sub_resource type="AtlasTexture" id="a{index}"]', 'atlas = ExtResource("1")', f"region = Rect2({x}, {y}, {w}, {h})", ""]
            ids.append(f"a{index}")
            index += 1
        frame_ids.append(ids)
    lines += ["[resource]", "animations = ["]
    entries = []
    for (name, fps, loop, _), ids in zip(animations, frame_ids):
        frames = ", ".join(f'{{\n"duration": 1.0,\n"texture": SubResource("{i}")\n}}' for i in ids)
        entries.append(f'{{\n"frames": [{frames}],\n"loop": {"true" if loop else "false"},\n"name": &"{name}",\n"speed": {fps}\n}}')
    lines += [", ".join(entries), "]", ""]
    return "\n".join(lines)


def write_sailor():
    frames = gen_sailor.all_frames()
    order = [("idle", 4.0, True), ("walk", 10.0, True), ("jump", 1.0, False), ("fall", 1.0, False)]
    count = sum(len(frames[name]) for name, _, _ in order)
    sheet = Image.new("RGBA", (count * gen_sailor.FRAME_W, gen_sailor.FRAME_H), (0, 0, 0, 0))
    animations = []
    i = 0
    for name, fps, loop in order:
        regions = []
        for frame in frames[name]:
            sheet.paste(frame, (i * gen_sailor.FRAME_W, 0))
            regions.append((i * gen_sailor.FRAME_W, 0, gen_sailor.FRAME_W, gen_sailor.FRAME_H))
            i += 1
        animations.append((name, fps, loop, regions))
    sheet.save(OUT / "sailor.png")
    (OUT / "sailor_frames.tres").write_text(sprite_frames("sailor.png", animations))


def write_glints():
    sheet = Image.new("RGBA", (480, GLINT_HEIGHT * GLINT_FRAMES), (0, 0, 0, 0))
    for i in range(GLINT_FRAMES):
        band = gen_shore.glints(i).crop((0, GLINT_TOP, 480, GLINT_TOP + GLINT_HEIGHT))
        sheet.paste(band, (0, i * GLINT_HEIGHT))
    sheet.save(OUT / "glints.png")
    regions = [(0, i * GLINT_HEIGHT, 480, GLINT_HEIGHT) for i in range(GLINT_FRAMES)]
    (OUT / "glints_frames.tres").write_text(sprite_frames("glints.png", [("default", 3.0, True, regions)]))


def write_light():
    """A stepped radial light, so the lantern's pool keeps the pixel look instead of a smooth gradient."""
    size = 128
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / c
            level = 0.0
            for edge, value in ((0.22, 1.0), (0.42, 0.62), (0.68, 0.34), (1.0, 0.14)):
                if d <= edge:
                    level = value
                    break
            v = round(255 * level)
            image.putpixel((x, y), (v, v, v, 255))
    image.save(OUT / "light.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    gen_shore.sky().save(OUT / "sky.png")
    gen_shore.clouds().save(OUT / "clouds.png")
    gen_shore.far().save(OUT / "far.png")
    gen_shore.flats().save(OUT / "flats.png")
    gen_shore.bank().save(OUT / "bank.png")
    gen_shore.terrain().save(OUT / "terrain.png")
    gen_shore.foreground().save(OUT / "foreground.png")
    gen_shore.fish_prop().save(OUT / "fish.png")
    gen_boat.draw().save(OUT / "boat.png")
    write_sailor()
    write_glints()
    write_light()
    print(f"Wrote assets to {OUT}")


if __name__ == "__main__":
    main()
