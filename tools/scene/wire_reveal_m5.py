"""Wires the reveal's composition, the creature's art and its animation into shore.tscn, from the scene at BASE.
Run from the repository root: python tools/scene/wire_reveal_m5.py. Kept as the record of the edit: it rebuilds the
scene from BASE, so run it again only to reproduce that step, not on a scene that has moved on."""
import math, subprocess, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from scene_edit import Scene, v2, col

BASE = "09d854e"
SCENE = "project/scenes/level/shore.tscn"
Path(SCENE).write_text(subprocess.run(["git", "show", f"{BASE}:{SCENE}"], capture_output=True, text=True, check=True).stdout)
s = Scene(SCENE)

def swap(old, new):
    assert s.text.count(old) == 1, old[:60]
    s.text = s.text.replace(old, new)

# ---- 1. composition: the canyon's end falls away behind the Monolith; one night behind everything
swap("3820, -520, 4310, -520, 4400, -260, 4470, -170, 4544, -120, 4544, 0)",
     "3820, -520, 4196, -520, 4226, -404, 4258, -262, 4288, -172, 4330, -130, 4400, -106, 4470, -90, 4544, -66, 4544, 0)")
s.set_prop("Drawn", "Trench", "position", v2(4160, -700))

for rid, path in (("r_dagon_ridge", "reveal/dagon_ridge"), ("r_dagon_body_lit", "reveal/dagon_body_lit"), ("r_dagon_head_lit", "reveal/dagon_head_lit"),
                  ("r_dagon_crest_lit", "reveal/dagon_crest_lit"), ("r_dagon_arm_lit", "reveal/dagon_arm_lit"), ("r_water_drop", "reveal/water_drop"),
                  ("r_trench_surge", "abyss/abyss_trench_surge")):
    s.add_ext(rid, f"res://assets/{path}.png")

s.add_sub('''[sub_resource type="Gradient" id="water_fade"]
offsets = PackedFloat32Array(0, 0.65, 1)
colors = PackedColorArray(1, 1, 1, 1, 1, 1, 1, 0.85, 1, 1, 1, 0)''')

# ---- 2. the trench: mist behind the creature, and spray thrown wider
# Spray standing over the trench, behind the creature: a plain fall from thick at the water to nothing at its
# shoulders, across the whole view, so that it has no edge of its own. Four corners only: more, and the fall breaks
# along the triangles' diagonals.
s.insert_after("WaterDrawn", "Trench", '''[node name="Haze" type="Polygon2D" parent="Trench"]
modulate = Color(1, 1, 1, 0)
color = Color(0.4, 0.5, 0.58, 1)
polygon = PackedVector2Array(4160, -380, 5400, -380, 5400, 40, 4160, 40)
vertex_colors = PackedColorArray(0.4, 0.5, 0.58, 0, 0.4, 0.5, 0.58, 0, 0.4, 0.5, 0.58, 0.62, 0.4, 0.5, 0.58, 0.62)''')
s.replace_node("Splash", "Trench", '''[node name="Splash" type="CPUParticles2D" parent="Trench"]
z_index = 2
position = Vector2(4700, 2)
emitting = false
amount = 150
lifetime = 1.7
emission_shape = 3
emission_rect_extents = Vector2(170, 4)
direction = Vector2(0, -1)
spread = 34.0
gravity = Vector2(0, 230)
initial_velocity_min = 80.0
initial_velocity_max = 210.0
scale_amount_min = 2.0
scale_amount_max = 4.0
color = Color(0.7, 0.8, 0.82, 0.85)
color_ramp = SubResource("water_fade")''')

# ---- 3. the creature
def pts(points):
    return "PackedVector2Array(" + ", ".join("%g, %g" % p for p in points) + ")"

def along(points, step, shift=(0, 0)):
    out = []
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = max(1, round(math.hypot(x1 - x0, y1 - y0) / step))
        out += [(round(x0 + (x1 - x0) * i / n + shift[0]), round(y0 + (y1 - y0) * i / n + shift[1])) for i in range(n)]
    return out

for name in ("Brow", "Jaw", "Gills", "GillsBack", "Shoulder", "Knuckles"):
    s.remove_node(name, "Dagon/Rims")
for name, parent in (("Rims", "Dagon"), ("Art", "Dagon/Crest"), ("Crest", "Dagon"), ("Eye", "Dagon"), ("Pupil", "Dagon"), ("Art", "Dagon/Head"), ("Art", "Dagon/Arm"), ("Runoff", "Dagon")):
    s.remove_node(name, parent)

s.set_prop("Ridge", "Dagon", "color", "Color(0.012, 0.018, 0.035, 0)")
s.insert_after("Ridge", "Dagon", '''[node name="Art" type="Sprite2D" parent="Dagon/Ridge"]
position = Vector2(-330, -186)
texture = ExtResource("r_dagon_ridge")
centered = false''')
s.insert_after("Art", "Dagon/Body", '''[node name="Rims" type="Node2D" parent="Dagon"]
visible = false

[node name="Body" type="Sprite2D" parent="Dagon/Rims"]
position = Vector2(-360, -258)
texture = ExtResource("r_dagon_body_lit")
centered = false''')
CREST = [(-60, -382), (-54, -428), (-34, -408), (-14, -442), (6, -412), (24, -440), (42, -402), (66, -416), (74, -372), (106, -384), (96, -285), (70, -300)]
jaw = along([(-176, -272), (-110, -254), (-40, -248), (30, -251)], 9)
s.insert_after("Head", "Dagon", f'''[node name="Crest" type="Polygon2D" parent="Dagon/Head"]
color = Color(0.012, 0.018, 0.035, 0)
polygon = {pts(CREST)}

[node name="Art" type="Sprite2D" parent="Dagon/Head/Crest"]
position = Vector2(-60, -442)
texture = ExtResource("r_dagon_crest")
centered = false

[node name="Lit" type="Sprite2D" parent="Dagon/Head/Crest"]
modulate = Color(1, 1, 1, 0)
position = Vector2(-60, -442)
texture = ExtResource("r_dagon_crest_lit")
centered = false

[node name="Art" type="Sprite2D" parent="Dagon/Head"]
position = Vector2(-192, -386)
texture = ExtResource("r_dagon_head")
centered = false

[node name="Lit" type="Sprite2D" parent="Dagon/Head"]
modulate = Color(1, 1, 1, 0)
position = Vector2(-192, -386)
texture = ExtResource("r_dagon_head_lit")
centered = false

[node name="Eye" type="Polygon2D" parent="Dagon/Head"]
visible = false
position = Vector2(-90, -347)
color = Color(0.5, 0.92, 0.78, 1)
polygon = PackedVector2Array(-22, 0, -6, -10, 12, -7, 22, 3, 8, 10, -10, 9)

[node name="Pupil" type="Polygon2D" parent="Dagon/Head"]
visible = false
color = Color(0.012, 0.018, 0.035, 1)
polygon = PackedVector2Array(-94, -355, -88, -355, -88, -338, -94, -338)

[node name="Pour" type="CPUParticles2D" parent="Dagon/Head"]
emitting = false
amount = 22
lifetime = 0.8
texture = ExtResource("r_water_drop")
emission_shape = 4
emission_points = {pts(jaw)}
direction = Vector2(0, 1)
spread = 6.0
gravity = Vector2(0, 300)
initial_velocity_min = 10.0
initial_velocity_max = 40.0
color = Color(0.5, 0.66, 0.7, 0.45)
color_ramp = SubResource("water_fade")''')
underside = along([(-486, -268), (-436, -252), (-490, -246), (-438, -238), (-488, -222), (-436, -224), (-476, -200), (-430, -210), (-395, -203), (-350, -168), (-312, -142)], 12)
s.insert_after("Arm", "Dagon", f'''[node name="Art" type="Sprite2D" parent="Dagon/Arm"]
position = Vector2(-492, -274)
texture = ExtResource("r_dagon_arm")
centered = false

[node name="Lit" type="Sprite2D" parent="Dagon/Arm"]
modulate = Color(1, 1, 1, 0)
position = Vector2(-492, -274)
texture = ExtResource("r_dagon_arm_lit")
centered = false

[node name="Drip" type="CPUParticles2D" parent="Dagon/Arm"]
emitting = false
amount = 12
lifetime = 0.7
texture = ExtResource("r_water_drop")
emission_shape = 4
emission_points = {pts(underside)}
direction = Vector2(0, 1)
spread = 4.0
gravity = Vector2(0, 320)
initial_velocity_min = 4.0
initial_velocity_max = 24.0
color = Color(0.5, 0.66, 0.7, 0.45)
color_ramp = SubResource("water_fade")''')
BODY = [(-360, 260), (-345, -110), (-300, -175), (-235, -205), (-150, -215), (-100, -235), (-80, -258), (60, -258), (80, -235), (140, -205), (230, -175), (290, -100), (330, 260)]
shoulders = along(BODY[1:4], 9, (2, 8)) + along(BODY[9:12], 9, (-2, 8))
s.insert_after("Lit", "Dagon/Arm", "PLACEHOLDER")
s.text = s.text.replace("PLACEHOLDER\n\n", "")
a, b = s.node_span("Drip", "Dagon/Arm")
s.text = s.text[:b] + f'''[node name="Runoff" type="CPUParticles2D" parent="Dagon"]
emitting = false
amount = 34
lifetime = 0.8
texture = ExtResource("r_water_drop")
emission_shape = 4
emission_points = {pts(shoulders)}
direction = Vector2(0, 1)
spread = 6.0
gravity = Vector2(0, 280)
initial_velocity_min = 6.0
initial_velocity_max = 36.0
color = Color(0.5, 0.66, 0.7, 0.4)
color_ramp = SubResource("water_fade")

[node name="TrenchFront" type="Node2D" parent="."]

[node name="Surge" type="Sprite2D" parent="TrenchFront"]
modulate = Color(1, 1, 1, 0)
position = Vector2(4530, 60)
texture = ExtResource("r_trench_surge")
centered = false

[node name="Mist" type="Polygon2D" parent="TrenchFront"]
modulate = Color(1, 1, 1, 0)
color = Color(0.4, 0.5, 0.58, 1)
polygon = PackedVector2Array(4160, -170, 5400, -170, 5400, 50, 4160, 50)
vertex_colors = PackedColorArray(0.4, 0.5, 0.58, 0, 0.4, 0.5, 0.58, 0, 0.4, 0.5, 0.58, 0.7, 0.4, 0.5, 0.58, 0.7)

''' + s.text[b:]

# ---- 4. the clip: the same length, lines, sounds and camera; the creature moves as a body
def smooth(u):
    u = max(0.0, min(1.0, u)); return u * u * (3 - 2 * u)
def ease_in(u):
    u = max(0.0, min(1.0, u)); return u * u
def ease_out(u):
    u = max(0.0, min(1.0, u)); return 1 - (1 - u) ** 2
def span(t, t0, t1):
    return (t - t0) / (t1 - t0)
def rot(a, p):
    return (p[0] * math.cos(a) - p[1] * math.sin(a), p[0] * math.sin(a) + p[1] * math.cos(a))
def times(t0, t1, step=0.1):
    n = round((t1 - t0) / step)
    return [round(t0 + i * step, 3) for i in range(n + 1)]
BREATH = 3.335
def breath(t, start):
    return 0.0 if t < start else 0.5 - 0.5 * math.cos(2 * math.pi * (t - start) / BREATH)

def rise(t):
    if t <= 1.5: y = 0.0
    elif t <= 3.0: y = -12 * ease_in(span(t, 1.5, 3.0))
    elif t <= 5.0: y = -12 - 34 * ease_out(span(t, 3.0, 5.0))
    elif t <= 7.0: y = -46 - 12 * ease_out(span(t, 5.0, 7.0))
    elif t <= 7.3: y = -58 + 4 * ease_out(span(t, 7.0, 7.3))
    else: y = -54 - 6 * smooth(span(t, 7.3, 9.0))
    return y - 4 * breath(t, 7.33)

NECK = (30, -256)
def head_angle(t):
    back = 0.05 * (smooth(span(t, 3.2, 3.8)) - smooth(span(t, 4.4, 5.4)))
    return back - 0.055 * smooth(span(t, 11.4, 12.2))
def head_at(t):
    a = head_angle(t); r = rot(a, NECK); turn = smooth(span(t, 11.4, 12.2))
    return (NECK[0] - r[0] - 4 * turn, NECK[1] - r[1] + 2 * turn - 2 * breath(t, 7.83))

SHOULDER = (-305, -166)
def arm_angle(t):
    if t <= 6.55: return -0.5 + 0.72 * ease_out(span(t, 5.5, 6.55))
    if t <= 7.0: return 0.22 - 0.22 * ease_in(span(t, 6.55, 7.0))
    if t <= 7.1: return -0.02 * span(t, 7.0, 7.1)
    return -0.02 * (1 - smooth(span(t, 7.1, 7.5)))
def arm_at(t):
    r = rot(arm_angle(t), SHOULDER)
    return (SHOULDER[0] - r[0], SHOULDER[1] - r[1])

c = s.clip("clip_dagon_reveal")
c.remove("Dagon/Crest:visible")
for old in ("Eye:visible", "Pupil:visible", "Pupil:position"):
    c.rename(f"Dagon/{old}", f"Dagon/Head/{old}")
ts = [0.0] + times(1.5, 14.0)
c.set_value("Dagon:position", ts, [v2(4700, round(rise(t), 2)) for t in ts])
ts = times(3.0, 14.0)
c.set_value("Dagon/Head:position", ts, [v2(round(head_at(t)[0], 2), round(head_at(t)[1], 2)) for t in ts])
c.set_value("Dagon/Head:rotation", ts, ["%.4f" % head_angle(t) for t in ts])
c.set_value("Dagon/Head/Crest:position", [11.4, 11.9], [v2(0, 0), v2(0, -4)], [-2, 1])
ts = times(5.5, 7.5, 0.05)
c.set_value("Dagon/Arm:position", ts, [v2(round(arm_at(t)[0], 2), round(arm_at(t)[1], 2)) for t in ts])
c.set_value("Dagon/Arm:rotation", ts, ["%.4f" % arm_angle(t) for t in ts])
c.set_value("Dagon/Arm:modulate", [5.5, 5.95], [col(1, 1, 1, 0), col(1, 1, 1, 1)])
c.set_value("Dagon/Body:modulate", [3.0, 4.3], [col(1, 1, 1, 0), col(1, 1, 1, 1)])
c.set_value("Dagon/Head:modulate", [3.0, 4.3], [col(1, 1, 1, 0), col(1, 1, 1, 1)])
for path, t0, t1 in (("Dagon/Head/Lit", 5.0, 9.0), ("Dagon/Head/Crest/Lit", 5.0, 9.0), ("Dagon/Arm/Lit", 6.0, 8.6)):
    c.set_value(f"{path}:modulate", [t0, t1], [col(1, 1, 1, 0), col(1, 1, 1, 1)])
c.set_value("Dagon/Head/Eye:scale", [9.5, 9.78], [v2(1, 0.14), v2(1, 1)], [0.5, 1])
c.set_value("Dagon/Head/Pupil:visible", [9.74], ["true"], update=1)
c.set_value("Dagon/Head/Pour:emitting", [0, 3.4, 8.6], ["false", "true", "false"], update=1)
c.set_value("Dagon/Arm/Drip:emitting", [0, 6.0, 11.6], ["false", "true", "false"], update=1)
c.set_value("Trench/Splash:emitting", [0, 2.6, 6.2], ["false", "true", "false"], update=1)
c.set_value("Trench/Haze:modulate", [2.4, 4.6], [col(1, 1, 1, 0), col(1, 1, 1, 1)])
c.set_value("TrenchFront/Mist:modulate", [2.7, 4.4, 9.0], [col(1, 1, 1, 0), col(1, 1, 1, 1), col(1, 1, 1, 0.8)])
c.set_value("TrenchFront/Surge:modulate", [2.5, 2.8], [col(1, 1, 1, 0), col(1, 1, 1, 0.94)])
c.set_value("TrenchFront/Surge:position", [2.5, 3.4, 4.4, 6.2, 9.0], [v2(4530, 60), v2(4530, -84), v2(4530, -58), v2(4530, -36), v2(4530, -30)], [0.45, -2, -2, -2, 1])
c.save()
s.set_prop("Arm", "Dagon", "position", v2(round(arm_at(5.5)[0], 2), round(arm_at(5.5)[1], 2)))
s.set_prop("Arm", "Dagon", "rotation", "%.4f" % arm_angle(5.5))
s.save()
print("wired", len(c.tracks), "tracks")
