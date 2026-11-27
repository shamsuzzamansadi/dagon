"""Renders text in the game's own BMFont (text .fnt + png), at an integer scale, nearest neighbour. Pillow only."""
import re
from pathlib import Path
from PIL import Image


def load(fnt_path):
    fnt_path = Path(fnt_path)
    chars, kern, line_height, base, page = {}, {}, 10, 7, None
    for line in fnt_path.read_text().splitlines():
        kv = dict(re.findall(r'(\w+)=("[^"]*"|\S+)', line))
        if line.startswith("common "):
            line_height, base = int(kv["lineHeight"]), int(kv["base"])
        elif line.startswith("page "):
            page = Image.open(fnt_path.parent / kv["file"].strip('"')).convert("RGBA")
        elif line.startswith("char "):
            chars[int(kv["id"])] = {k: int(kv[k]) for k in ("x", "y", "width", "height", "xoffset", "yoffset", "xadvance")}
        elif line.startswith("kerning "):
            kern[(int(kv["first"]), int(kv["second"]))] = int(kv["amount"])
    return {"chars": chars, "kern": kern, "line_height": line_height, "base": base, "page": page}


def measure(font, text):
    width, prev = 0, None
    for ch in text:
        c = font["chars"].get(ord(ch))
        if c is None:
            continue
        width += c["xadvance"] + (font["kern"].get((prev, ord(ch)), 0) if prev else 0)
        prev = ord(ch)
    return width, font["line_height"]


def render(font, text, colour):
    """The text at 1x, in one colour, on transparent, using the glyphs' alpha."""
    w, h = measure(font, text)
    out = Image.new("RGBA", (max(w, 1), h), (0, 0, 0, 0))
    x, prev = 0, None
    for ch in text:
        c = font["chars"].get(ord(ch))
        if c is None:
            continue
        if prev:
            x += font["kern"].get((prev, ord(ch)), 0)
        if c["width"] and c["height"]:
            glyph = font["page"].crop((c["x"], c["y"], c["x"] + c["width"], c["y"] + c["height"]))
            alpha = glyph.getchannel("A")
            solid = Image.new("RGBA", glyph.size, colour)
            solid.putalpha(alpha)
            out.alpha_composite(solid, (x + c["xoffset"], c["yoffset"]))
        x += c["xadvance"]
        prev = ord(ch)
    return out
