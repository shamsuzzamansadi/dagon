"""Deliberate breakages for what M5 added, for tools/breakage.py. M5 changed no C++: its logic is in the scene, in
what the reveal's clip moves and shows and in where the art stands. Each entry breaks one of those in the way it could
plausibly go wrong. How anything looks is checked by looking (project/tests/capture_m5.gd), not here."""

W = "project/scenes/level/shore.tscn"
E = "project/scenes/ui/ending.tscn"

BREAKAGES = [
    # The reveal's composition.
    ("The night begins at the last wall again", W, '[node name="Drawn" type="Sprite2D" parent="Trench"]\nposition = Vector2(4160, -700)', '[node name="Drawn" type="Sprite2D" parent="Trench"]\nposition = Vector2(4544, -700)'),
    ("The canyon's wall stands behind the arm again", W, "4196, -520, 4226, -404, 4258, -262, 4288, -172, 4330, -130, 4400, -106, 4470, -90, 4544, -66, 4544, 0)", "4310, -520, 4400, -260, 4470, -170, 4544, -120, 4544, 0)"),
    # The creature's motion: the drawn parts are what the clip moves.
    ("The head's turn moves nothing", W, 'NodePath("Dagon/Head:rotation")', 'NodePath("Dagon/Head/Lit:rotation")'),
    ("The arm slides and does not turn", W, 'NodePath("Dagon/Arm:rotation")', 'NodePath("Dagon/Arm/Lit:rotation")'),
    ("The moon never comes up on the head", W, 'NodePath("Dagon/Head/Lit:modulate")', 'NodePath("Dagon/Head/Lit:self_modulate")'),
    ("The drawn head is hidden", W, '[node name="Art" type="Sprite2D" parent="Dagon/Head"]\n', '[node name="Art" type="Sprite2D" parent="Dagon/Head"]\nvisible = false\n'),
    ("The ridge jumps as the reveal begins", W, '"values": [Vector2(4700, 0), Vector2(4700, 0), ', '"values": [Vector2(4700, -12), Vector2(4700, -12), '),
    ("Water still pours off it when it is over", W, '"times": PackedFloat32Array(0, 3.2, 10.5),\n"transitions": PackedFloat32Array(1, 1, 1),\n"update": 1,\n"values": [false, true, false]', '"times": PackedFloat32Array(0, 3.2, 10.5),\n"transitions": PackedFloat32Array(1, 1, 1),\n"update": 1,\n"values": [false, true, true]'),
    # The regression checks kept from M4, and tightened: hidden art, and shapes that draw nothing.
    ("The clip animates the water before it, under a hidden parent", W, '[node name="TrenchFront" type="Node2D" parent="."]\n', '[node name="TrenchFront" type="Node2D" parent="."]\nvisible = false\n'),
    ("The watcher on the cliff carries no shown drawing", W, '[node name="Drawn" type="Sprite2D" parent="FarRidges/WatcherFar"]\n', '[node name="Drawn" type="Sprite2D" parent="FarRidges/WatcherFar"]\nvisible = false\n'),
    ("The one who stands at the ritual carries no shown drawing", W, '[node name="Drawn" type="Sprite2D" parent="RitualLayer/Figures/Watcher"]\n', '[node name="Drawn" type="Sprite2D" parent="RitualLayer/Figures/Watcher"]\nvisible = false\n'),
    # The ending: the card may not come up over the pictures.
    ("The ending's card rises over its pictures", E, "offset_top = -50.0\noffset_right = -24.0", "offset_top = -120.0\noffset_right = -24.0"),
]
