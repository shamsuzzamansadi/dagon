"""Puts the far figures' drawings on the shapes the background clips show and move (tools/art/gen_figures.py). Each
shape stays, draws nothing itself, and carries its drawing as a child, so whatever moves or fades the shape moves or
fades the drawing. Run once from the repository root, on the scene as it was after wire_reveal_m5.py."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "art"))
from scene_edit import Scene, v2
import gen_figures

s = Scene("project/scenes/level/shore.tscn")
figures = gen_figures.all_figures()

def clear(name, parent):
    block = s.node(name, parent)
    line = next(l for l in block.split("\n") if l.startswith("color = Color("))
    r, g, b, _a = [x.strip() for x in line[len("color = Color("):-1].split(",")]
    s.set_prop(name, parent, "color", f"Color({r}, {g}, {b}, 0)")
    return next((l for l in block.split("\n") if l.startswith("position = Vector2(")), None)

def drawn(name, parent, texture, light_mask=None):
    """Adds the drawing as a child of the shape, placed in the shape's own space."""
    assert not s.has_node("Drawn", f"{parent}/{name}"), name
    position = clear(name, parent)
    image, at = figures[texture]
    ox, oy = (0.0, 0.0)
    if position and parent != "ActArt":
        ox, oy = [float(v) for v in position[len("position = Vector2("):-1].split(",")]
    s.add_ext(f"r_{texture}", f"res://assets/cave/{texture}.png")
    extra = f"light_mask = {light_mask}\n" if light_mask else ""
    s.insert_after(name, parent, f'''[node name="Drawn" type="Sprite2D" parent="{parent}/{name}"]
{extra}position = {v2(at[0] - ox, at[1] - oy)}
texture = ExtResource("r_{texture}")
centered = false''')

for name in ("Stone1", "Stone2", "Stone3", "Stone4", "MarkEye", "MarkWave"):
    clear(name, "RitualLayer")
drawn("MarkStone", "RitualLayer", "ritual_stones")
for i in range(1, 5):
    drawn(f"Figure{i}", "RitualLayer/Figures/Kneeling", f"ritual_kneeler_{i}")
drawn("Watcher", "RitualLayer/Figures", "ritual_watcher")
drawn("WatcherFar", "FarRidges", "far_watcher")
drawn("DistantShape", "FarRidges", "distant_shape")
drawn("CanyonFigure", "ActArt", "canyon_figure")
s.save()
print("wired")
