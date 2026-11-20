"""The owner's pass on three things in motion, after their playtest of 2026-11-19 of ea86ae9, in the Abyss's scene.
Run once from the repository root, on the scene as stage_visual_m5.py left it; then run tools/art/generate.py, and
run this again with --positions to place the drawings it made.

  - The creature comes out of the fog from the ridge outward (D119): the body, the head and the crest take a shader
    that turns the clip's own fade into a front spreading from the ridge, so the ridge's edges never show inside a
    half-faded body. The water the ridge stands in now runs across the whole trench in front of the creature, so the
    body rises out of the same water at the same line; the trench's own water, behind it and no longer seen, is no
    longer raised.
  - The arm comes out from under the shoulder (D120): the body's own pixels where the arm crosses it are laid over the
    arm from the moment it shows, and lit as the body is; and through the same shader its fade-in brings it out from
    the shoulder to the hand, where it faded in whole in the air.
  - The sea that has him is the one that followed him (D121): at the collapse it keeps coming at the pace it had, then
    rushes on and rises until it fills the view, where a second sea in the screen's own space used to rise from the
    foot of the screen. That second sea is gone.

No line, sound or haptic cue, no key of the camera, no collision and no outcome changes; the reveal's and the
collapse's lengths are as they were.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "art"))
from scene_edit import Scene, v2

SCENE = "project/scenes/level/shore.tscn"
OLD_TIDE = "PackedVector2Array(0, -30, 8, -38, 18, -33, 30, -41, 44, -34, 60, -39, 80, -34, 120, -37, 900, -36, 900, 60, 0, 60)"
# Deep enough that, raised to fill the view at the end of the collapse, it still reaches below it.
NEW_TIDE = "PackedVector2Array(0, -30, 8, -38, 18, -33, 30, -41, 44, -34, 60, -39, 80, -34, 120, -37, 900, -36, 900, 300, 0, 300)"
ARM_AT = (-492, -274)
# The sea in the collapse, from where the flee left it. For its first 2.4 s it comes on at the flee's own 64 px/s, so
# that it does not stop; as the rush is heard it runs at about 400 px/s, which brings it to him from as far behind as
# a runner can be, 300 px; then it rises until it fills the view, as the screen fades.
SEA_TIMES = [0, 2.4, 3.3, 5.2]
SEA_AT = [(0, 0), (-154, 0), (-480, -12), (-640, -130)]


def stage(s):
    assert s.has_node("Shallows", "TrenchFront") and s.has_node("ReturningSea", ".") and not s.has_node("Shoulder", "Dagon")

    # The body, the head and the crest from the ridge outward; the arm from the shoulder to the hand.
    s.add_ext("s_emerge", "res://assets/reveal/emerge.gdshader", kind="Shader")
    for part, parent in (("body", "Dagon/Body"), ("head", "Dagon/Head"), ("crest", "Dagon/Head/Crest"), ("arm", "Dagon/Arm")):
        s.add_ext(f"r_dagon_{part}_reach", f"res://assets/reveal/dagon_{part}_reach.png")
        s.add_sub(f'''[sub_resource type="ShaderMaterial" id="emerge_{part}"]
shader = ExtResource("s_emerge")
shader_parameter/reach = ExtResource("r_dagon_{part}_reach")''')
        s.set_prop("Art", parent, "material", f'SubResource("emerge_{part}")')
    fade = s.clip("clip_dagon_reveal")
    arm_fade = fade.tracks[fade.find("Dagon/Arm:modulate")[0]]
    assert '"times": PackedFloat32Array(5.5, 5.95)' in arm_fade and '"values": [Color(1, 1, 1, 0), Color(1, 1, 1, 1)]' in arm_fade

    # The shoulder over the arm.
    s.add_ext("r_dagon_shoulder", "res://assets/reveal/dagon_shoulder.png")
    s.add_ext("r_dagon_shoulder_lit", "res://assets/reveal/dagon_shoulder_lit.png")
    s.insert_after("Drip", "Dagon/Arm", '''[node name="Shoulder" type="Node2D" parent="Dagon"]
visible = false
z_index = 1

[node name="Art" type="Sprite2D" parent="Dagon/Shoulder"]
position = Vector2(0, 0)
texture = ExtResource("r_dagon_shoulder")
centered = false

[node name="Lit" type="Sprite2D" parent="Dagon/Shoulder"]
modulate = Color(1, 1, 1, 0)
position = Vector2(0, 0)
texture = ExtResource("r_dagon_shoulder_lit")
centered = false''')

    reveal = s.clip("clip_dagon_reveal")
    arm = reveal.tracks[reveal.find("Dagon/Arm:visible")[0]]
    assert '"times": PackedFloat32Array(5.5)' in arm
    reveal.set_value("Dagon/Shoulder:visible", [5.5], ["true"], update=1)
    rims = reveal.tracks[reveal.find("Dagon/Rims:modulate")[0]]
    assert '"times": PackedFloat32Array(5, 9)' in rims and '"values": [Color(1, 1, 1, 0), Color(1, 1, 1, 1)]' in rims
    reveal.set_value("Dagon/Shoulder/Lit:modulate", [5, 9], ["Color(1, 1, 1, 0)", "Color(1, 1, 1, 1)"])
    # The trench's own water is behind the water the creature stands in, and is not seen.
    reveal.remove("Trench/WaterDrawn:position")
    reveal.save()

    # The sea.
    block = s.node("Water", "Tide")
    assert OLD_TIDE in block
    s.set_prop("Water", "Tide", "polygon", NEW_TIDE)
    collapse = s.clip("clip_collapse")
    collapse.remove("ReturningSea:visible")
    collapse.remove("ReturningSea/Water:position")
    collapse.set_value("Tide/Water:position", SEA_TIMES, [v2(x, y) for x, y in SEA_AT])
    collapse.save()
    for name, parent in (("Foam", "ReturningSea/Water"), ("Drawn", "ReturningSea/Water"), ("Water", "ReturningSea"), ("ReturningSea", ".")):
        s.remove_node(name, parent)
    line = '[ext_resource type="Texture2D" path="res://assets/abyss/abyss_returning_sea.png" id="r_abyss_returning_sea"]\n'
    assert s.text.count(line) == 1 and s.text.count('"r_abyss_returning_sea"') == 1
    s.text = s.text.replace(line, "")


def positions(s):
    import gen_reveal

    parts = gen_reveal.dagon_parts()
    assert parts["dagon_arm"][1] == ARM_AT, parts["dagon_arm"][1]
    for name, node in (("dagon_shoulder", "Art"), ("dagon_shoulder_lit", "Lit")):
        _image, (x, y) = parts[name]
        s.set_prop(node, "Dagon/Shoulder", "position", v2(x, y))
    _image, (x, y) = gen_reveal.ridge_water()
    assert "position = Vector2(%g, %g)" % (x, y) in s.node("Shallows", "TrenchFront")


s = Scene(SCENE)
if "--positions" in sys.argv:
    positions(s)
else:
    stage(s)
s.save()
print("staged" if "--positions" not in sys.argv else "placed")
