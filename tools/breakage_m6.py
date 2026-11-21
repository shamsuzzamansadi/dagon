"""Deliberate breakages for what M6 added, for tools/breakage.py: the Display setting and the window that fits its
screen (D122), Settings' Examine (D124), the distant shape's place (D125) and the Awakened checkpoint (D127). Each
breaks one of them in the way it could plausibly go wrong.

Held elsewhere, so not here, as these suites cannot see them: the cave's boundaries (D126) by tools/art/check_art.py,
which reported 456 problems on the scene and art as they were; key names under a layout, the Display setting across a
relaunch and M2's examine by CI's desktop-checks job on the shipped builds; the frame log (D123) by its use. M3's two
survivors have their own tests, each shown failing under its breakage (docs/evidence/m6/verification-matrix.md)."""

D = "src/core/settings_data.cpp"
F = "src/core/window_fit.cpp"
M = "src/settings_menu.cpp"
S = "project/scenes/ui/settings_menu.tscn"
W = "project/scenes/level/shore.tscn"

BREAKAGES = [
    # The Display setting, saved like the others.
    ("Fullscreen is never saved", D, '\ttext.append(FULLSCREEN_FIELD).append(p_settings.fullscreen ? "=1\\n" : "=0\\n");\n', ""),
    ("A saved fullscreen is read as a window", D, "\t\t\t\tparsed.settings.fullscreen = *enabled;", "\t\t\t\tparsed.settings.fullscreen = false;"),
    ("The Display button does nothing", M, "\tsettings_.fullscreen = !settings_.fullscreen;\n\tcommit();", "\tcommit();"),
    ("Restore Defaults keeps fullscreen", M, "\tsettings_ = core::Settings{};\n\tstate_ = State::Idle;", "\tconst bool kept = settings_.fullscreen;\n\tsettings_ = core::Settings{};\n\tsettings_.fullscreen = kept;\n\tstate_ = State::Idle;"),
    # The window that fits its screen.
    ("A window too big for its screen keeps its size", F, "\t\tif (width * scale <= p_available_width && height * scale <= p_available_height) {", "\t\tif (p_available_width >= 0 && p_available_height >= 0) {"),
    ("The window is never larger than the picture", F, "\tfor (int scale = std::max(1, p_preferred_scale); scale >= 1; scale--) {", "\tfor (int scale = std::min(1, std::max(1, p_preferred_scale)); scale >= 1; scale--) {"),
    # Settings calls the key what every prompt calls it.
    ("The conflict message says Interact again", M, '\t\t\treturn "Examine";', '\t\t\treturn "Interact";'),
    ("Settings' row says Interact again", S, 'text = "Examine"', 'text = "Interact"'),
    # The GDD §8 review's fixes held by the integration tests.
    ("The distant shape's drawing is 1000 px off again", W, '[node name="Drawn" type="Sprite2D" parent="FarRidges/DistantShape"]\nposition = Vector2(0, -220)', '[node name="Drawn" type="Sprite2D" parent="FarRidges/DistantShape"]\nposition = Vector2(-1000, -220)'),
    ("Awakened stands in front of the statue again", W, '[node name="Awakened" type="Marker2D" parent="Checkpoints"]\nposition = Vector2(4262, -1)', '[node name="Awakened" type="Marker2D" parent="Checkpoints"]\nposition = Vector2(4250, -1)'),
]
