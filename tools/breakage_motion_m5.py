"""Deliberate breakages for the motion pass after the owner's playtest of ea86ae9 (D119 to D121), for tools/breakage.py.
Each puts back one of the faults the owner saw, or one like it, the way it could plausibly come back. How it looks is
checked by looking (project/tests/record_visual.gd), not here."""

W = "project/scenes/level/shore.tscn"

BREAKAGES = [
    # The emergence: the body out from the ridge, and the water before the whole creature (D119).
    ("The body fades in whole over the ridge again", W, 'material = SubResource("emerge_body")\n', ""),
    ("The water stops short of the walkway's end again", W, '[node name="Shallows" type="Sprite2D" parent="TrenchFront"]\nposition = Vector2(4290, -9)', '[node name="Shallows" type="Sprite2D" parent="TrenchFront"]\nposition = Vector2(4400, -9)'),
    # The arm: out from under the shoulder, and from the shoulder to the hand (D120).
    ("The shoulder never shows over the arm", W, 'NodePath("Dagon/Shoulder:visible")', 'NodePath("Dagon/Shoulder/Art:visible")'),
    ("The shoulder lies beside the arm's root, not over it", W, '[node name="Art" type="Sprite2D" parent="Dagon/Shoulder"]\nposition = Vector2(-326, -186)', '[node name="Art" type="Sprite2D" parent="Dagon/Shoulder"]\nposition = Vector2(-320, -186)'),
    ("The arm fades in whole in the air again", W, 'material = SubResource("emerge_arm")\n', ""),
    # Nothing first drawn in the middle of the reveal (D119).
    ("The shader is first drawn in the reveal again", W, '[node name="Emerge" type="Sprite2D" parent="CameraRig/Warm"]\nmodulate = Color(1, 1, 1, 0.3)\nmaterial = SubResource("emerge_crest")\n', '[node name="Emerge" type="Sprite2D" parent="CameraRig/Warm"]\nmodulate = Color(1, 1, 1, 0.3)\n'),
    ("The warm-up is too clear to be drawn", W, '[node name="Emerge" type="Sprite2D" parent="CameraRig/Warm"]\nmodulate = Color(1, 1, 1, 0.3)', '[node name="Emerge" type="Sprite2D" parent="CameraRig/Warm"]\nmodulate = Color(1, 1, 1, 0.005)'),
    # The sea: the one that followed him comes on over him (D121).
    ("The sea stops dead at the collapse again", W, '"values": [Vector2(0, 0), Vector2(-154, 0), Vector2(-480, -12), Vector2(-640, -130)]', '"values": [Vector2(0, 0), Vector2(0, 0), Vector2(-480, -12), Vector2(-640, -130)]'),
    ("The sea's rush falls short of a runner", W, '"values": [Vector2(0, 0), Vector2(-154, 0), Vector2(-480, -12), Vector2(-640, -130)]', '"values": [Vector2(0, 0), Vector2(-154, 0), Vector2(-200, -12), Vector2(-260, -130)]'),
]
