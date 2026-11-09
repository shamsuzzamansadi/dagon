"""Deliberate breakages for the owner's revision of 2026-11-09, for tools/breakage.py. Each breaks one thing the
revision added, in the way it could plausibly go wrong. The earlier passes' entries are in docs/evidence/m3/."""

D = "src/game_director.cpp"
F = "src/core/flee.cpp"
P = "src/player_controller.cpp"
M = "src/menu_controller.cpp"
W = "project/scenes/level/shore.tscn"
PR = "project/scenes/ui/prologue.tscn"

BREAKAGES = [
    # The returning sea.
    ("The sea never comes on", F, "const double travelled = std::max(0.0, static_cast<double>(p_tide.speed)) * moving;", "const double travelled = 0.0 * moving;"),
    ("The sea goes the wrong way", F, "return static_cast<float>(static_cast<double>(p_tide.start_x) - travelled);", "return static_cast<float>(static_cast<double>(p_tide.start_x) + travelled);"),
    # Each keeps its parameters in use: the native tests are built with warnings as errors.
    ("Being reached never ends the flee", F, "	if (p_sailor_x >= tide_front(p_tide, p_elapsed) - p_tide.reach) {", "	if (p_sailor_x != p_sailor_x && tide_front(p_tide, p_elapsed) < 0.0f) {"),
    ("The fallback never ends a flee", F, "	if (p_elapsed >= p_fallback_seconds) {", "	if (p_elapsed < 0.0 && p_fallback_seconds < 0.0) {"),
    ("The sea's picture does not follow its rule", D, "		tide->set_global_position(Vector2(front, tide->get_global_position().y));\n", ""),
    ("The sea is never shown", D, "				tide->set_visible(true);\n", ""),
    # The crossing.
    ("A weight never brings the slab down", D, "	(void)p_trigger_id;\n	lower_crossing(false);\n", "	(void)p_trigger_id;\n"),
    ("The slab comes down again for each weight", D, "	if (crossing_lowered_) {\n		return;\n	}\n	crossing_lowered_ = true;\n	print_verbose(\"dagon: crossing lowered\");", "	crossing_lowered_ = true;\n	print_verbose(\"dagon: crossing lowered\");"),
    ("A restored world keeps the slab up", D, "		case core::Beat::Monolith:\n			lower_crossing(true);\n			break;\n", ""),
    ("The slab never settles level", D, "		crossing->set_rotation(static_cast<float>(static_cast<double>(crossing_raised_rotation_) * (1.0 - eased)));", "		crossing->set_rotation(crossing_raised_rotation_ * 0.5f);"),
    ("The crossing's line is not in the script", W, 'crossing_line = &"abyss.crossing"', 'crossing_line = &"abyss.crossin"'),
    # The prologue.
    ("New Game skips the prologue", M, "	if (prologue_scene_.is_valid()) {", "	if (false) {"),
    ("Skipping the prologue starts without the introduction", M, "	start_session(core::Beat::Shore, true);\n}", "	start_session(core::Beat::Shore, false);\n}"),
    ("The prologue never ends by itself", M, "		if (last) {\n			finish_prologue(false);", "		if (last) {\n			(void)0;"),
    ("The prologue loses its last line", PR, 'ending_lines = PackedStringArray("prologue.raider", "prologue.escape", "prologue.drift", "prologue.dry")', 'ending_lines = PackedStringArray("prologue.raider", "prologue.escape", "prologue.drift")'),
    # Sound and the sailor.
    ("Footsteps are counted but never heard", P, "	footsteps->play();\n	footstep_count_++;", "	footstep_count_++;"),
    ("Every surface sounds like the Shore", P, "	const int surface = surface_at(static_cast<float>(get_global_position().x));", "	const int surface = 0;"),
    ("Standing still makes footsteps", P, "	if (!is_on_floor() || std::abs(p_moved_pixels) < 0.01f) {", "	if (!is_on_floor()) {"),
    ("Every step is the same sound", P, "	const int pick = p_landing && variants.size() > 1 ? variants.size() - 1 : static_cast<int>((footstep_seed_ >> 16) % static_cast<uint32_t>(steps));", "	const int pick = 0;"),
    ("He breathes the same in every beat", D, "	const Ref<AudioStream> stream = index < breath_streams_.size() ? Ref<AudioStream>(breath_streams_[index]) : Ref<AudioStream>();", "	const Ref<AudioStream> stream = breath_streams_.is_empty() ? Ref<AudioStream>() : Ref<AudioStream>(breath_streams_[0]);"),
    ("Control returns with him still staggered", P, "		visual->set_position(Vector2());\n		visual->set_rotation(0.0f);\n", ""),
    ("A one-shot sound plays on restore", W, '[node name="GateSound" type="AudioStreamPlayer2D" parent="Monolith"]\nposition = Vector2(4300, -60)', '[node name="GateSound" type="AudioStreamPlayer2D" parent="Monolith"]\nposition = Vector2(4300, -60)\nautoplay = true'),
    # The finished section.
    ("The cave's greybox shows through the finished art", W, '[node name="Panel" type="Polygon2D" parent="Props/CaveCarving"]\nvisible = false\n', '[node name="Panel" type="Polygon2D" parent="Props/CaveCarving"]\n'),
]
