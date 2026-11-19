"""The owner's visual pass after their playtest of 2026-11-19 (59562c6), in the Abyss's scene. Run once from the
repository root, on the scene as stage_turn_m5.py left it; then run tools/art/generate.py, and run this again with
--positions to place the drawings it made.

  - The ridge beside the walkway is the creature's near shoulder (D105). Its shape now follows the body's own outline
    over its left side and its top, so the edge followed along it before the reveal is the shoulder's as it rises, and
    it goes on below the water at its foot. A strip of water past the walkway, in front of the creature and behind
    the walkway, stands at its foot: the ridge stands in it before the reveal, and rises out of it.
  - The ritual's four who kneel and the one who stands are drawn again (tools/art/gen_figures.py): their drawings are
    placed where the drawings now sit, and a strip of the ground the backdrop draws is laid in front of the four, so
    that when the clip bows them it hides what goes below the crest.

Nothing that moves, nothing's timing, no line or sound, no collision changes.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "art"))
from PIL import Image
from scene_edit import Scene, v2

SCENE = "project/scenes/level/shore.tscn"
OLD_RIDGE = "PackedVector2Array(-330, 0, -326, -120, -296, -170, -250, -186, -214, -160, -190, -96, -150, 0)"
BODY_AT = (-360, -258)
# The ridge's right side, as it was a steep fall from its top to the walkway, from the new top.
RIGHT_FLANK = [(-204, -180), (-194, -140), (-182, -96), (-168, -50), (-150, 0), (-146, 70)]


def ridge_polygon():
    """Along the body's own outline: up its left side from below the water, and over the top to the ridge's crest."""
    body = Image.open("project/assets/reveal/dagon_body.png")
    alpha = body.getchannel("A")

    def left_at(y):
        row = y - BODY_AT[1]
        return next(c for c in range(body.width) if alpha.getpixel((c, row))) + BODY_AT[0]

    def top_at(x):
        col = x - BODY_AT[0]
        return next(r for r in range(body.height) if alpha.getpixel((col, r))) + BODY_AT[1]

    points = [(left_at(y), y) for y in (70, 40, 0, -40, -80, -110)]
    points += [(x, top_at(x)) for x in range(-340, -211, 10)]
    points += [(-212, top_at(-212))]
    return points + RIGHT_FLANK


def stage(s):
    block = s.node("Ridge", "Dagon")
    assert OLD_RIDGE in block, "the ridge is not as wire_reveal_m5.py left it"
    points = ridge_polygon()
    s.set_prop("Ridge", "Dagon", "polygon", "PackedVector2Array(%s)" % ", ".join(f"{x:g}, {y:g}" for x, y in points))
    assert not s.has_node("Shallows", "TrenchFront")
    s.add_ext("r_ridge_water", "res://assets/reveal/ridge_water.png")
    s.insert_before("Surge", "TrenchFront", '''[node name="Shallows" type="Sprite2D" parent="TrenchFront"]
position = Vector2(0, 0)
texture = ExtResource("r_ridge_water")
centered = false''')
    assert not s.has_node("Ground", "RitualLayer")
    s.add_ext("r_ritual_ground", "res://assets/cave/ritual_ground.png")
    s.insert_after("Drawn", "RitualLayer/Figures/Watcher", '''[node name="Ground" type="Sprite2D" parent="RitualLayer"]
light_mask = 2
position = Vector2(0, 0)
texture = ExtResource("r_ritual_ground")
centered = false''')


def positions(s):
    import gen_figures
    import gen_reveal

    _image, (x, y) = gen_reveal.dagon_parts()["dagon_ridge"]
    s.set_prop("Art", "Dagon/Ridge", "position", v2(x, y))
    _image, (x, y) = gen_reveal.ridge_water()
    s.set_prop("Shallows", "TrenchFront", "position", v2(x, y))
    figures = gen_figures.all_figures()
    for i in range(1, 5):
        _image, (x, y) = figures[f"ritual_kneeler_{i}"]
        s.set_prop("Drawn", f"RitualLayer/Figures/Kneeling/Figure{i}", "position", v2(x, y))
    _image, (x, y) = figures["ritual_watcher"]
    s.set_prop("Drawn", "RitualLayer/Figures/Watcher", "position", v2(x, y))
    _image, (x, y) = figures["ritual_ground"]
    s.set_prop("Ground", "RitualLayer", "position", v2(x, y))


s = Scene(SCENE)
if "--positions" in sys.argv:
    positions(s)
else:
    stage(s)
s.save()
print("staged" if "--positions" not in sys.argv else "placed")
