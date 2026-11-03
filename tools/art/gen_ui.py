"""Draws the UI's pixel font and theme, in the Shore's palette, so text stays crisp on the 480x270 canvas.

The font is an original 5x7 dot-matrix design with descenders, written as a BMFont that Godot imports.
"""

from PIL import Image

from art_common import blank, put
from palette import PALETTE

# Rows of 5 bits, top to bottom. The first 7 rows sit above the baseline; the rest descend below it.
GLYPHS = {
    "A": "0E 11 11 1F 11 11 11", "B": "1E 11 11 1E 11 11 1E", "C": "0E 11 10 10 10 11 0E",
    "D": "1E 11 11 11 11 11 1E", "E": "1F 10 10 1E 10 10 1F", "F": "1F 10 10 1E 10 10 10",
    "G": "0E 11 10 17 11 11 0F", "H": "11 11 11 1F 11 11 11", "I": "0E 04 04 04 04 04 0E",
    "J": "07 02 02 02 02 12 0C", "K": "11 12 14 18 14 12 11", "L": "10 10 10 10 10 10 1F",
    "M": "11 1B 15 15 11 11 11", "N": "11 19 15 13 11 11 11", "O": "0E 11 11 11 11 11 0E",
    "P": "1E 11 11 1E 10 10 10", "Q": "0E 11 11 11 15 12 0D", "R": "1E 11 11 1E 14 12 11",
    "S": "0F 10 10 0E 01 01 1E", "T": "1F 04 04 04 04 04 04", "U": "11 11 11 11 11 11 0E",
    "V": "11 11 11 11 11 0A 04", "W": "11 11 11 15 15 1B 11", "X": "11 11 0A 04 0A 11 11",
    "Y": "11 11 0A 04 04 04 04", "Z": "1F 01 02 04 08 10 1F",
    "a": "00 00 0E 01 0F 11 0F", "b": "10 10 1E 11 11 11 1E", "c": "00 00 0E 10 10 10 0E",
    "d": "01 01 0F 11 11 11 0F", "e": "00 00 0E 11 1F 10 0E", "f": "06 08 1C 08 08 08 08",
    "g": "00 00 0F 11 11 11 0F 01 0E", "h": "10 10 1E 11 11 11 11", "i": "04 00 04 04 04 04 04",
    "j": "02 00 02 02 02 02 02 12 0C", "k": "10 10 12 14 18 14 12", "l": "04 04 04 04 04 04 04",
    "m": "00 00 1A 15 15 15 15", "n": "00 00 1E 11 11 11 11", "o": "00 00 0E 11 11 11 0E",
    "p": "00 00 1E 11 11 11 1E 10 10", "q": "00 00 0F 11 11 11 0F 01 01", "r": "00 00 16 18 10 10 10",
    "s": "00 00 0F 10 0E 01 1E", "t": "08 08 1C 08 08 08 06", "u": "00 00 11 11 11 11 0F",
    "v": "00 00 11 11 11 0A 04", "w": "00 00 11 11 15 15 0A", "x": "00 00 11 0A 04 0A 11",
    "y": "00 00 11 11 11 11 0F 01 0E", "z": "00 00 1F 02 04 08 1F",
    "0": "0E 11 13 15 19 11 0E", "1": "04 0C 04 04 04 04 0E", "2": "0E 11 01 02 04 08 1F",
    "3": "1F 02 04 02 01 11 0E", "4": "02 06 0A 12 1F 02 02", "5": "1F 10 1E 01 01 11 0E",
    "6": "06 08 10 1E 11 11 0E", "7": "1F 01 02 04 08 08 08", "8": "0E 11 11 0E 11 11 0E",
    "9": "0E 11 11 0F 01 02 0C",
    "!": "04 04 04 04 04 00 04", '"': "0A 0A 00 00 00 00 00", "#": "0A 0A 1F 0A 1F 0A 0A",
    "$": "04 0F 14 0E 05 1E 04", "%": "18 19 02 04 08 13 03", "&": "0C 12 14 08 15 12 0D",
    "'": "04 04 00 00 00 00 00", "(": "02 04 08 08 08 04 02", ")": "08 04 02 02 02 04 08",
    "*": "00 04 15 0E 15 04 00", "+": "00 04 04 1F 04 04 00", ",": "00 00 00 00 00 04 04 08",
    "-": "00 00 00 1F 00 00 00", ".": "00 00 00 00 00 00 04", "/": "00 01 02 04 08 10 00",
    ":": "00 00 04 00 00 04 00", ";": "00 00 04 00 00 04 04 08", "<": "02 04 08 10 08 04 02",
    "=": "00 00 1F 00 1F 00 00", ">": "08 04 02 01 02 04 08", "?": "0E 11 01 02 04 00 04",
    "@": "0E 11 01 0D 15 15 0E", "[": "0E 08 08 08 08 08 0E", "\\": "00 10 08 04 02 01 00",
    "]": "0E 02 02 02 02 02 0E", "^": "04 0A 11 00 00 00 00", "_": "00 00 00 00 00 00 1F",
    "`": "08 04 00 00 00 00 00", "{": "02 04 04 08 04 04 02", "|": "04 04 04 04 04 04 04",
    "}": "08 04 04 02 04 04 08", "~": "00 00 08 15 02 00 00",
    # The letter keys of a German layout, so a key rebound there can be named.
    "\u00c4": "11 04 0A 11 1F 11 11", "\u00d6": "11 0E 11 11 11 11 0E", "\u00dc": "11 00 11 11 11 11 0E", "\u00df": "0E 11 11 1E 11 11 1E 10",
}

GLYPH_WIDTH = 5
BASELINE = 7
LINE_HEIGHT = 10
FONT_SIZE = 10
SPACE_ADVANCE = 3
CELL_W = 6
CELL_H = 10
COLUMNS = 16


def _rows(char):
    return [int(value, 16) for value in GLYPHS[char].split()]


def _columns_used(rows):
    """The first and last columns that have ink, so narrow letters get a narrow advance."""
    used = [x for x in range(GLYPH_WIDTH) if any(row & (1 << (GLYPH_WIDTH - 1 - x)) for row in rows)]
    return used[0], used[-1]


def font():
    """Returns the glyph atlas and the BMFont text that describes it."""
    chars = sorted(GLYPHS, key=ord)
    rows_needed = len(chars) // COLUMNS + 1
    atlas = Image.new("RGBA", (COLUMNS * CELL_W, rows_needed * CELL_H), (255, 255, 255, 0))
    entries = [f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={SPACE_ADVANCE} page=0 chnl=15"]
    for index, char in enumerate(chars):
        rows = _rows(char)
        left, right = _columns_used(rows)
        cell_x, cell_y = (index % COLUMNS) * CELL_W, (index // COLUMNS) * CELL_H
        for y, row in enumerate(rows):
            for x in range(left, right + 1):
                if row & (1 << (GLYPH_WIDTH - 1 - x)):
                    atlas.putpixel((cell_x + x - left, cell_y + y), (255, 255, 255, 255))
        width = right - left + 1
        entries.append(f"char id={ord(char)} x={cell_x} y={cell_y} width={width} height={len(rows)} xoffset=0 yoffset=0 xadvance={width + 1} page=0 chnl=15")
    lines = [
        f'info face="DagonPixel" size={FONT_SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0 outline=0',
        f"common lineHeight={LINE_HEIGHT} base={BASELINE} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4",
        'page id=0 file="pixel_font.png"',
        f"chars count={len(entries)}",
        *entries,
        "",
    ]
    return atlas, "\n".join(lines)


def slider_grabber(color):
    img = blank(5, 9)
    for y in range(9):
        for x in range(5):
            put(img, x, y, color)
    return img


def _color(name, alpha=1.0):
    h = PALETTE[name]
    r, g, b = (int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.4f}, {g:.4f}, {b:.4f}, {alpha})"


def _box(box_id, bg, border=None, margin=(4, 1), alpha=1.0):
    lines = [
        f'[sub_resource type="StyleBoxFlat" id="{box_id}"]',
        f"content_margin_left = {float(margin[0])}",
        f"content_margin_top = {float(margin[1])}",
        f"content_margin_right = {float(margin[0])}",
        f"content_margin_bottom = {float(margin[1])}",
    ]
    if bg is None:
        lines.append("draw_center = false")
    else:
        lines.append(f"bg_color = {_color(bg, alpha)}")
    if border is not None:
        lines += [f"border_width_{side} = 1" for side in ("left", "top", "right", "bottom")]
        lines.append(f"border_color = {_color(border)}")
    return lines + [""]


def theme():
    """The project's theme: restrained, cold, and with a focus marker that shows on any display."""
    boxes = [
        _box("panel", "C1", "C4", margin=(10, 7), alpha=0.97),
        _box("caption", "C0", margin=(6, 3), alpha=0.8),
        _box("button", "C2", margin=(5, 2)),
        _box("button_hover", "C3", margin=(5, 2)),
        _box("button_pressed", "C4", margin=(5, 2)),
        _box("button_focus", None, "C9", margin=(5, 2)),
        _box("slider", "C3", margin=(0, 1)),
        _box("slider_area", "C5", margin=(0, 1)),
        _box("slider_area_focus", "C7", margin=(0, 1)),
    ]
    lines = [
        f'[gd_resource type="Theme" load_steps={len(boxes) + 4} format=3]',
        "",
        '[ext_resource type="FontFile" path="res://assets/ui/pixel_font.fnt" id="1_font"]',
        '[ext_resource type="Texture2D" path="res://assets/ui/slider_grabber.png" id="2_grabber"]',
        '[ext_resource type="Texture2D" path="res://assets/ui/slider_grabber_focus.png" id="3_grabber_focus"]',
        "",
    ]
    for box in boxes:
        lines += box
    lines += [
        "[resource]",
        'default_font = ExtResource("1_font")',
        f"default_font_size = {FONT_SIZE}",
        f"Label/colors/font_color = {_color('C8')}",
        "Label/constants/line_spacing = 1",
        'CaptionLabel/base_type = &"Label"',
        'CaptionLabel/styles/normal = SubResource("caption")',
        f"Button/colors/font_color = {_color('C8')}",
        f"Button/colors/font_hover_color = {_color('C9')}",
        f"Button/colors/font_focus_color = {_color('C9')}",
        f"Button/colors/font_pressed_color = {_color('C9')}",
        f"Button/colors/font_hover_pressed_color = {_color('C9')}",
        'Button/styles/normal = SubResource("button")',
        'Button/styles/hover = SubResource("button_hover")',
        'Button/styles/pressed = SubResource("button_pressed")',
        'Button/styles/focus = SubResource("button_focus")',
        'PanelContainer/styles/panel = SubResource("panel")',
        'HSlider/icons/grabber = ExtResource("2_grabber")',
        'HSlider/icons/grabber_highlight = ExtResource("3_grabber_focus")',
        'HSlider/styles/slider = SubResource("slider")',
        'HSlider/styles/grabber_area = SubResource("slider_area")',
        'HSlider/styles/grabber_area_highlight = SubResource("slider_area_focus")',
        "VBoxContainer/constants/separation = 3",
        "HBoxContainer/constants/separation = 6",
        "",
    ]
    return "\n".join(lines)


def write_all(out):
    out.mkdir(parents=True, exist_ok=True)
    atlas, description = font()
    atlas.save(out / "pixel_font.png")
    (out / "pixel_font.fnt").write_text(description)
    slider_grabber("C7").save(out / "slider_grabber.png")
    slider_grabber("C9").save(out / "slider_grabber_focus.png")
    (out / "theme.tres").write_text(theme())
