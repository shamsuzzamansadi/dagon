extends RefCounted
## Tests of the main menu, driven by real input events, each in its own test directory.

const TITLE := "res://scenes/ui/title.tscn"
const ITEMS := "Center/Main/Panel/Items/"
const SAVE_FILE := "save.dat"
const BACKUP_FILE := "save.bak"
const SETTINGS_FILE := "settings.cfg"
const SHORE_SAVE := "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n"
const ABYSS_SAVE := "dagon_save=1\nbeat=abyss\ncheckpoint=PastTheTrench\n"
const ABYSS_X := 750.0
const SHORE_X := 150.0


func _write(h, file_name: String, text: String) -> void:
	h.write_storage_file(file_name, text.to_utf8_buffer())


func _setup(h) -> Control:
	await h.load_main_fixture(TITLE)
	# Focus moves by screen position, so let the containers lay themselves out, as they have long
	# before a person could press anything.
	await h.steps(3)
	return h.fixture


func _button(title: Control, button_name: String) -> Button:
	return title.get_node(ITEMS + button_name)


func _status(title: Control) -> String:
	return title.get_node(ITEMS + "SaveStatus").text


func _focus(title: Control) -> Control:
	return title.get_viewport().gui_get_focus_owner()


func _confirm_panel(title: Control) -> Control:
	return title.get_node("Center/Confirm")


func _confirm_message(title: Control) -> String:
	return title.get_node("Center/Confirm/Items/Message").text


func _confirm_ok(title: Control) -> Button:
	return title.get_node("Center/Confirm/Items/Buttons/Ok")


func _block(h, file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(h.storage_dir.path_join(file_name))


func _unblock(h, file_name: String) -> void:
	DirAccess.remove_absolute(h.storage_dir.path_join(file_name))


func test_with_no_save_continue_is_disabled_and_explained(h) -> void:
	var title := await _setup(h)
	h.check(_button(title, "Continue").disabled, "Continue is enabled with no save")
	h.check(_status(title) == "No saved game yet.", "the status reads '%s'" % _status(title))
	h.check(_focus(title) == _button(title, "NewGame"), "focus is on %s" % _focus(title))
	await h.tap_key(KEY_DOWN)
	h.check(_focus(title) == _button(title, "Settings"), "Down did not skip the disabled Continue: %s" % _focus(title))
	_button(title, "Continue").emit_signal("pressed")
	await h.steps(2)
	h.check(h.tree.current_scene == title, "a disabled Continue changed the scene")


func test_a_usable_save_enables_continue_and_says_where_it_resumes(h) -> void:
	_write(h, SAVE_FILE, ABYSS_SAVE)
	var title := await _setup(h)
	h.check(not _button(title, "Continue").disabled, "Continue is disabled")
	h.check(_status(title).contains("trench"), "the status reads '%s'" % _status(title))
	h.check(_focus(title) == _button(title, "Continue"), "focus is on %s" % _focus(title))
	await h.tap_key(KEY_UP)
	h.check(_focus(title) == _button(title, "NewGame"), "Up from Continue reached %s" % _focus(title))


func test_unusable_saves_are_explained_and_nothing_is_changed(h) -> void:
	var cases := {
		"binary noise": [PackedByteArray([0, 255, 254, 1, 61, 128, 10, 0, 200]), "damaged"],
		"truncated": ["dagon_save=1\nbeat=aby".to_utf8_buffer(), "damaged"],
		"a mismatched checkpoint": ["dagon_save=1\nbeat=abyss\ncheckpoint=Shore\n".to_utf8_buffer(), "damaged"],
		"the final sequence": ["dagon_save=1\nbeat=witness\ncheckpoint=\n".to_utf8_buffer(), "damaged"],
		"another version": ["dagon_save=99\nbeat=shore\ncheckpoint=Shore\n".to_utf8_buffer(), "another version"],
		"a beat this build lacks": ["dagon_save=1\nbeat=monolith\ncheckpoint=Monolith\n".to_utf8_buffer(), "another version"],
	}
	for case_name in cases:
		h.write_storage_file(SAVE_FILE, cases[case_name][0])
		var title := await _setup(h)
		h.check(_button(title, "Continue").disabled, "%s: Continue is enabled" % case_name)
		h.check(_status(title).contains(cases[case_name][1]), "%s: the status reads '%s'" % [case_name, _status(title)])
		h.check(FileAccess.get_file_as_bytes(h.storage_dir.path_join(SAVE_FILE)) == cases[case_name][0], "%s: looking at the save changed it" % case_name)
		h.tree.current_scene = null
		h.fixture.queue_free()
		h.probe.queue_free()
		await h.tree.process_frame
		await h.tree.physics_frame


func test_every_state_an_interrupted_replacement_can_leave_loads_a_usable_save(h) -> void:
	var cases := [
		["the new save never finished", {SAVE_FILE: SHORE_SAVE, SAVE_FILE + ".tmp": "dagon_sa"}, "shore"],
		["the backup never finished", {SAVE_FILE: SHORE_SAVE, BACKUP_FILE + ".tmp": "dagon_sa", SAVE_FILE + ".tmp": ABYSS_SAVE}, "shore"],
		["the backup moved, the save did not", {SAVE_FILE: SHORE_SAVE, BACKUP_FILE: SHORE_SAVE, SAVE_FILE + ".tmp": ABYSS_SAVE}, "shore"],
		["the save was replaced", {SAVE_FILE: ABYSS_SAVE, BACKUP_FILE: SHORE_SAVE}, "trench"],
		["the save is gone, the backup is good", {BACKUP_FILE: ABYSS_SAVE, SAVE_FILE + ".tmp": "dagon_sa"}, "trench"],
		["the save is corrupt, the backup is good", {SAVE_FILE: "damaged", BACKUP_FILE: ABYSS_SAVE}, "trench"],
	]
	for entry in cases:
		for file_name: String in entry[1]:
			h.write_storage_file(file_name, (entry[1][file_name] as String).to_utf8_buffer())
		var title := await _setup(h)
		h.check(not _button(title, "Continue").disabled, "%s: Continue is disabled" % entry[0])
		h.check(_status(title).contains(entry[2]), "%s: the status reads '%s'" % [entry[0], _status(title)])
		for file_name: String in entry[1]:
			h.check(h.read_storage_file(file_name) == entry[1][file_name], "%s: loading changed %s" % [entry[0], file_name])
			DirAccess.remove_absolute(h.storage_dir.path_join(file_name))
		h.tree.current_scene = null
		h.fixture.queue_free()
		h.probe.queue_free()
		await h.tree.process_frame
		await h.tree.physics_frame


func test_both_files_corrupt_is_explained(h) -> void:
	_write(h, SAVE_FILE, "damaged")
	_write(h, BACKUP_FILE, "damaged too")
	var title := await _setup(h)
	h.check(_button(title, "Continue").disabled, "Continue is enabled")
	h.check(_status(title).contains("damaged"), "the status reads '%s'" % _status(title))


func test_a_backup_alone_being_damaged_is_explained(h) -> void:
	_write(h, BACKUP_FILE, "damaged")
	var title := await _setup(h)
	h.check(_button(title, "Continue").disabled, "Continue is enabled")
	h.check(_status(title).contains("damaged"), "the status reads '%s'" % _status(title))


func test_new_game_with_no_save_saves_first_then_starts_with_the_introduction(h) -> void:
	var title := await _setup(h)
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the file holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(session.get_session_beat() == 0 and session.get_persisted_beat() == 0, "the session is at %d, persisted %d" % [session.get_session_beat(), session.get_persisted_beat()])
	h.check(not is_instance_valid(title) or not title.is_inside_tree(), "the main menu stayed in the tree")
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	var panel: Control = menu.get_node("Center/Controls")
	h.check(h.tree.paused, "the introduction does not pause the game")
	h.check(panel.visible, "no introduction")
	h.check(panel.get_node("Items/Title").text == "How to Play", "the title reads '%s'" % panel.get_node("Items/Title").text)
	h.check(panel.get_node("Items/Back").text == "Begin", "the button reads '%s'" % panel.get_node("Items/Back").text)
	h.check(menu.get_viewport().gui_get_focus_owner() == panel.get_node("Items/Back"), "focus is on %s" % menu.get_viewport().gui_get_focus_owner())
	var text: String = panel.get_node("Items/Text").text
	for line in ["Walk: A and D", "Jump: Space", "Examine: E", "Pause: Esc", "under Controls"]:
		h.check(text.contains(line), "the text lacks '%s': %s" % [line, text])
	h.check(not text.contains("controller"), "the short introduction lists a device not in use: %s" % text)


## Every way into the game starts from a clean slate, whatever was left behind.
func test_starting_a_game_clears_a_time_scale_and_a_pause_left_behind(h) -> void:
	for start: String in ["new_game", "continue_game"]:
		if start == "continue_game":
			_write(h, SAVE_FILE, ABYSS_SAVE)
		var title := await _setup(h)
		Engine.time_scale = 0.5
		h.tree.paused = true
		title.call(start)
		var was_paused: bool = h.tree.paused
		var time_scale: float = Engine.time_scale
		h.tree.paused = false
		Engine.time_scale = 1.0
		h.check(not was_paused, "%s: still paused" % start)
		h.check_near(time_scale, 1.0, 0.0, "%s: the time scale" % start)
		await h.wait_for_scene("GameSession")
		await h.unload_fixture()


func test_beginning_with_the_jump_key_starts_play_without_jumping(h) -> void:
	await _setup(h)
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	var player: CharacterBody2D = session.get_node("World/Player")
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	await h.tap_key(KEY_SPACE)
	await h.steps(10)
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	h.check(not menu.is_open(), "Space did not close the introduction")
	h.check(not h.tree.paused, "still paused")
	h.check(jumps[0] == 0, "beginning with Space jumped")
	h.check(session.get_node("World/Hud/Prompt").visible, "no prompt once play began")
	await h.tap_key(KEY_ESCAPE)
	h.check(menu.get_node("Center/Main").visible and not menu.get_node("Center/Controls").visible, "Esc in play did not open the normal pause menu")


func test_the_introduction_can_be_closed_with_back_and_uses_the_current_keys(h) -> void:
	_write(h, SETTINGS_FILE, "dagon_settings=1\nmusic_volume=1\neffects_volume=1\nkey_move_left=74\nkey_move_right=76\nkey_jump=75\nkey_interact=85\n")
	await _setup(h)
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	var text: String = menu.get_node("Center/Controls/Items/Text").text
	for line in ["Walk: J and L", "Jump: K", "Examine: U"]:
		h.check(text.contains(line), "the text lacks '%s': %s" % [line, text])
	await h.tap_key(KEY_ESCAPE)
	h.check(not menu.is_open() and not h.tree.paused, "Esc did not begin play")
	h.check(session.get_node("World/Hud/Prompt").text == "[U] Examine", "the prompt reads '%s'" % session.get_node("World/Hud/Prompt").text)


func test_the_introduction_appears_only_for_a_new_game(h) -> void:
	_write(h, SAVE_FILE, SHORE_SAVE)
	await _setup(h)
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	h.check(not h.tree.paused, "Continue paused the game")
	h.check(not session.get_node("PauseLayer/PauseMenu").is_open(), "Continue showed the introduction")


func test_continue_restores_the_saved_checkpoint(h) -> void:
	_write(h, SAVE_FILE, ABYSS_SAVE)
	var title := await _setup(h)
	h.check(_focus(title) == _button(title, "Continue"), "focus is on %s" % _focus(title))
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	h.check(session.get_session_beat() == 1 and session.get_persisted_beat() == 1, "the session is at %d, persisted %d" % [session.get_session_beat(), session.get_persisted_beat()])
	await h.steps(30)
	var player: CharacterBody2D = session.get_node("World/Player")
	h.check_near(player.global_position.x, ABYSS_X, 1.0, "x after Continue")
	h.check(player.is_on_floor(), "not on the floor after Continue")
	h.check(not session.get_node("World/Triggers/EnterAbyss").enabled, "the used trigger came back")
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "Continue changed the save")
	h.check(not session.get_node("World/Hud/Notice").visible, "Continue showed a save notice")


func test_continue_from_a_backup_leaves_the_files_alone_until_the_next_save(h) -> void:
	_write(h, SAVE_FILE, "damaged")
	_write(h, BACKUP_FILE, ABYSS_SAVE)
	await _setup(h)
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	await h.steps(30)
	h.check_near(session.get_node("World/Player").global_position.x, ABYSS_X, 1.0, "x after Continue")
	h.check(h.read_storage_file(SAVE_FILE) == "damaged", "Continue rewrote the save")
	h.check(h.read_storage_file(BACKUP_FILE) == ABYSS_SAVE, "Continue changed the backup")


func test_new_game_asks_first_with_cancel_focused_and_cancelling_changes_nothing(h) -> void:
	_write(h, SAVE_FILE, ABYSS_SAVE)
	var title := await _setup(h)
	_button(title, "NewGame").grab_focus()
	await h.tap_key(KEY_ENTER)
	h.check(_confirm_panel(title).visible, "no confirmation before replacing progress")
	h.check(_confirm_message(title).contains("replaces your saved game"), "the message reads '%s'" % _confirm_message(title))
	h.check(_focus(title) == title.get_node("Center/Confirm/Items/Buttons/Cancel"), "focus is on %s" % _focus(title))
	await h.tap_key(KEY_ESCAPE)
	h.check(not _confirm_panel(title).visible, "Esc did not cancel")
	h.check(_focus(title) == _button(title, "NewGame"), "focus returned to %s" % _focus(title))
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "cancelling changed the save")
	h.check(h.tree.current_scene == title, "cancelling changed the scene")

	# Pressing the focused button is also Cancel, so a double press cannot replace progress.
	await h.tap_key(KEY_ENTER)
	await h.tap_key(KEY_ENTER)
	h.check(not _confirm_panel(title).visible and h.tree.current_scene == title, "pressing the focused button did not cancel")
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "a double press changed the save")


func test_confirming_a_new_game_replaces_the_save_and_starts_from_the_beginning(h) -> void:
	_write(h, SAVE_FILE, ABYSS_SAVE)
	var title := await _setup(h)
	title.new_game()
	_confirm_ok(title).grab_focus()
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the save holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(h.read_storage_file(BACKUP_FILE) == ABYSS_SAVE, "the backup holds: %s" % h.read_storage_file(BACKUP_FILE))
	h.check(session.get_session_beat() == 0, "the new game started at beat %d" % session.get_session_beat())
	await h.steps(5)
	h.check_near(session.get_node("World/Player").global_position.x, SHORE_X, 1.0, "x in the new game")
	h.check(session.get_node("World/Triggers/EnterAbyss").enabled, "the new game kept an old outcome")


func test_a_damaged_save_is_named_when_a_new_game_would_replace_it(h) -> void:
	_write(h, SAVE_FILE, "damaged")
	var title := await _setup(h)
	title.new_game()
	h.check(_confirm_panel(title).visible, "no confirmation before replacing the damaged file")
	h.check(_confirm_message(title).contains("cannot be used"), "the message reads '%s'" % _confirm_message(title))
	h.check(h.read_storage_file(SAVE_FILE) == "damaged", "asking changed the file")


func test_a_failed_new_game_stays_in_the_menu_and_never_loads_the_old_save(h) -> void:
	_write(h, SAVE_FILE, ABYSS_SAVE)
	var title := await _setup(h)
	_block(h, SAVE_FILE + ".tmp")
	title.new_game()
	_confirm_ok(title).grab_focus()
	await h.tap_key(KEY_ENTER)
	await h.steps(10)
	h.check(h.tree.current_scene == title, "the game started after a failed save")
	h.check(_confirm_panel(title).visible, "the error is not showing")
	h.check(_confirm_message(title).contains("Could not create a new save"), "the message reads '%s'" % _confirm_message(title))
	h.check(_confirm_message(title).contains("was not changed"), "the message reads '%s'" % _confirm_message(title))
	h.check(_confirm_ok(title).text == "Retry", "the button reads '%s'" % _confirm_ok(title).text)
	h.check(_focus(title) == title.get_node("Center/Confirm/Items/Buttons/Cancel"), "focus is on %s" % _focus(title))
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the failure changed the old save")

	# Retry fails the same way while the problem lasts.
	_confirm_ok(title).grab_focus()
	await h.tap_key(KEY_ENTER)
	await h.steps(5)
	h.check(h.tree.current_scene == title, "the retry started the game")

	# Once writing works, Retry starts the new game, not the old one.
	_unblock(h, SAVE_FILE + ".tmp")
	_confirm_ok(title).grab_focus()
	await h.tap_key(KEY_ENTER)
	var session: Node = await h.wait_for_scene("GameSession")
	h.check(session.get_session_beat() == 0, "the retry started at beat %d" % session.get_session_beat())
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the save holds: %s" % h.read_storage_file(SAVE_FILE))


func test_a_failed_new_game_with_no_save_is_explained_too(h) -> void:
	var title := await _setup(h)
	_block(h, SAVE_FILE + ".tmp")
	await h.tap_key(KEY_ENTER)
	await h.steps(10)
	h.check(h.tree.current_scene == title, "the game started with no save written")
	h.check(_confirm_message(title).contains("Could not create a new save"), "the message reads '%s'" % _confirm_message(title))
	await h.tap_key(KEY_ESCAPE)
	h.check(not _confirm_panel(title).visible, "Esc did not leave the error")
	h.check(_focus(title) == _button(title, "NewGame"), "focus returned to %s" % _focus(title))


func test_settings_controls_and_credits_open_and_back_returns_focus(h) -> void:
	var title := await _setup(h)
	var main: Control = title.get_node("Center/Main")
	for entry in [["Settings", title.get_node("Settings")], ["Controls", title.get_node("Center/Controls")], ["Credits", title.get_node("Center/Credits")]]:
		var button := _button(title, entry[0])
		button.grab_focus()
		await h.tap_key(KEY_ENTER)
		h.check(entry[1].visible and not main.visible, "%s did not replace the main panel" % entry[0])
		h.check(_focus(title) != null and _focus(title).is_visible_in_tree(), "%s has no visible focus: %s" % [entry[0], _focus(title)])
		await h.tap_key(KEY_ESCAPE)
		h.check(main.visible and not entry[1].visible, "Esc did not leave %s" % entry[0])
		h.check(_focus(title) == button, "focus returned from %s to %s" % [entry[0], _focus(title)])


func test_the_gamepad_can_work_the_main_menu(h) -> void:
	var title := await _setup(h)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	h.check(_focus(title) == _button(title, "Controls"), "the D-pad reached %s" % _focus(title))
	await h.tap_pad(JOY_BUTTON_A)
	h.check(title.get_node("Center/Controls").visible, "the south button did not open Controls")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(title.get_node("Center/Main").visible, "the east button did not go back")


func test_back_and_pause_do_nothing_at_the_root(h) -> void:
	var title := await _setup(h)
	await h.tap_key(KEY_ESCAPE)
	await h.tap_pad(JOY_BUTTON_B)
	await h.tap_pad(JOY_BUTTON_START)
	h.check(h.tree.current_scene == title and title.get_node("Center/Main").visible, "the root changed")
	h.check(not h.tree.paused, "the main menu paused the tree")
	h.check(_focus(title) == _button(title, "NewGame"), "focus moved to %s" % _focus(title))


func test_controls_on_the_main_menu_show_a_rebound_key_at_once(h) -> void:
	var title := await _setup(h)
	title.open_settings()
	await h.steps(1)
	title.get_node("Settings").begin_capture(2)
	await h.tap_key(KEY_J)
	await h.tap_key(KEY_ESCAPE)
	title.open_controls()
	h.check(title.get_node("Center/Controls/Items/Text").text.contains("Jump: J"), "the text reads: %s" % title.get_node("Center/Controls/Items/Text").text)
	h.check(h.read_storage_file(SETTINGS_FILE).contains("key_jump=%d" % KEY_J), "the key was not saved")
	h.check(not FileAccess.file_exists(h.storage_dir.path_join(SAVE_FILE)), "changing a setting wrote a save")


func test_credits_use_the_attribution_and_license_records(h) -> void:
	var title := await _setup(h)
	title.open_credits()
	var text: String = title.get_node("Center/Credits/Items/Text").text
	for line in ["shamsuzzamansadi", "Claude", "ChatGPT", "Lovecraft", "public domain", "Godot Engine", "godot-cpp", "MIT License", "CC BY 4.0", "Game Off 2026"]:
		h.check(text.contains(line), "the credits lack '%s'" % line)
	var font: Font = title.get_node("Center/Credits/Items/Text").get_theme_font("font")
	for i in text.length():
		h.check(text.unicode_at(i) == 10 or text.unicode_at(i) == 32 or font.has_char(text.unicode_at(i)), "the font cannot draw '%s'" % text[i])


func test_every_button_is_connected_and_every_screen_fits(h) -> void:
	var title := await _setup(h)
	for pair in [["NewGame", title.new_game], ["Continue", title.continue_game], ["Settings", title.open_settings], ["Controls", title.open_controls], ["Credits", title.open_credits], ["Quit", title.quit_now]]:
		h.check(_button(title, pair[0]).pressed.is_connected(pair[1]), "%s is not connected" % pair[0])
	var viewport := title.get_viewport_rect()
	for screen in [title.open_controls, title.open_credits, title.back, title.open_settings]:
		screen.call()
		await h.steps(2)
		for panel: Control in [title.get_node("Center/Main/Panel"), title.get_node("Center/Controls"), title.get_node("Center/Credits"), title.get_node("Settings/Center/Panel")]:
			if panel.is_visible_in_tree():
				h.check(viewport.encloses(panel.get_global_rect()), "%s is clipped: %s" % [panel.name, panel.get_global_rect()])
		title.back()
		await h.steps(1)


func test_quit_on_the_main_menu_exits_the_game(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	var output := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/title_quit_probe.gd"], output, true)
	h.check(code == 0, "the probe exited with %d" % code)
	h.check("PROBE quitting" in output[0] and not "PROBE still running" in output[0], "the game kept running: %s" % output[0])
