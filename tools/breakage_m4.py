"""Deliberate breakages for M4's new logic, for tools/breakage.py. Each breaks one thing M4 added, in the way it could
plausibly go wrong: the prologue's voice and its join to the Shore (items 1 and 2), the menu and examining sounds, the
Abyss's beds (item 4), and the spacing that lets the reveal's lines be heard out (item 5). Art is checked by
tools/art/check_art.py and by looking, not here."""

D = "src/game_director.cpp"
S = "src/game_session.cpp"
M = "src/menu_controller.cpp"
H = "src/hud.cpp"
W = "project/scenes/level/shore.tscn"
PR = "project/scenes/ui/prologue.tscn"

BREAKAGES = [
    # Items 1 and 2: the prologue spoken, and nothing between it and the Shore.
    ("The prologue is silent", PR, 'voice_path = NodePath("Voice")\n', ""),
    ("A new game opens on him already standing", S, "			director->wake();\n", ""),
    ("Every world built shows the waking, Continue and Restart too", S, "		waking_ = false;\n", ""),
    ("He wakes outside the Shore", D, "	if (progress_.beat() != core::Beat::Shore || active_.has_value()) {", "	if (active_.has_value()) {"),
    ("The waking has no pose", D, "			player->show_pose(POSE_WAKE);\n", "			(void)player;\n"),
    ("Finishing the prologue starts on him standing", M, "	start_session(core::Beat::Shore, false, !unattended);", "	start_session(core::Beat::Shore, false, false);\n	(void)unattended;"),
    ("The last picture's sea and wind fade before the cut", M, " || (p_keep_under != nullptr && sound->get_parent() == p_keep_under)) {", ") {\n			(void)p_keep_under;"),
    # Item 4: the menus and examining.
    ("The menu's own focus is heard as a move", M, "	quiet_focus_ = true;\n	if (screen_ == Screen::Settings) {", "	quiet_focus_ = false;\n	if (screen_ == Screen::Settings) {"),
    ("Settings' own focus is heard as a move", M, "	quiet_focus_ = true;\n	settings_menu_.get()->open();", "	quiet_focus_ = false;\n	settings_menu_.get()->open();"),
    ("Moving between choices is silent", M, "		play(move_sound_);\n", ""),
    ("Choosing is silent", M, "		Object::cast_to<Node>(buttons[i])->connect(\"pressed\", callable_mp(this, &MenuController::on_button_pressed));\n", "		(void)buttons[i];\n"),
    ("Going back is silent", M, "			play(back_sound_);\n			back();", "			back();"),
    ("A press that changes the scene still tries to sound", M, "sound != nullptr && sound->is_inside_tree()) {", "sound != nullptr) {"),
    ("Examining is silent", H, "	if (AudioStreamPlayer *sound = examine_sound_.get(); sound != nullptr && examined) {\n		sound->play();", "	if (AudioStreamPlayer *sound = examine_sound_.get(); sound != nullptr && examined) {\n		(void)sound;"),
    ("Pressing a stone is heard as examining", H, "sound != nullptr && examined) {", "sound != nullptr) {\n		(void)examined;"),
    ("The Abyss is one sound again", W, 'stream = ExtResource("a_abyss_deep")', 'stream = ExtResource("a_abyss")'),
    # Item 5: the reveal's lines heard out.
    ("The recognition is cut off by the run", W, '"times": PackedFloat32Array(8.2),', '"times": PackedFloat32Array(9.6),'),
]
