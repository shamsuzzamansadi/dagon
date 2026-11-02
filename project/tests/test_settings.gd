extends RefCounted
## Tests of the settings menu, key rebinding and the settings file, each in its own test directory.

const SHORE := "res://scenes/level/shore.tscn"
const MENU := "PauseLayer/PauseMenu"
const ITEMS := "PauseLayer/PauseMenu/Settings/Center/Panel/Items/"
const SETTINGS_FILE := "settings.cfg"
const JUMP := 2
const INTERACT := 3


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(SHORE)
	var player: CharacterBody2D = h.fixture.get_node("Player")
	await h.landed_on_floor(player)
	return player


func _open(h) -> Control:
	var menu: Control = h.fixture.get_node(MENU)
	menu.open()
	menu.open_settings()
	await h.steps(1)
	return menu.get_node("Settings")


func _key_button(h, row: String) -> Button:
	return h.fixture.get_node(ITEMS + row + "/Key")


func _message(h) -> String:
	return h.fixture.get_node(ITEMS + "Message").text


func _keys_of(action: String) -> Array:
	var keys := []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(event.physical_keycode)
	return keys


func _bytes(text: String) -> PackedByteArray:
	return text.to_utf8_buffer()


func test_settings_are_written_to_the_test_directory(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.set_music_volume(0.5)
	h.check(FileAccess.file_exists(h.storage_dir.path_join(SETTINGS_FILE)), "no settings file in %s" % h.storage_dir)
	h.check(h.storage_dir.contains("dagon-test-"), "the test is not using a test directory: %s" % h.storage_dir)


func test_the_core_key_codes_match_the_engine(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.restore_defaults()
	var text: String = h.read_storage_file(SETTINGS_FILE)
	for line in ["key_move_left=%d" % KEY_A, "key_move_right=%d" % KEY_D, "key_jump=%d" % KEY_SPACE, "key_interact=%d" % KEY_E]:
		h.check(text.contains(line), "the default file lacks %s:\n%s" % [line, text])
	# Reserved keys are checked through behaviour, against the engine's own values.
	for reserved in [KEY_LEFT, KEY_RIGHT]:
		settings.begin_capture(JUMP)
		await h.tap_key(reserved)
		h.check(settings.is_capturing(), "%s was not refused" % OS.get_keycode_string(reserved))
		await h.tap_key(KEY_ESCAPE)


func test_a_rebound_key_drives_the_action_and_the_old_one_does_not(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var settings := await _open(h)
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	_key_button(h, "Jump").grab_focus()
	await h.tap_action("ui_accept")
	h.check(settings.is_capturing(), "pressing the row did not start a capture")
	h.check(_message(h).contains("Jump"), "the capture message reads '%s'" % _message(h))
	await h.tap_key(KEY_J)
	h.check(not settings.is_capturing(), "still capturing after a key")
	h.check(_key_button(h, "Jump").text == "J", "the row reads '%s'" % _key_button(h, "Jump").text)
	h.check(_keys_of("jump") == [KEY_J], "jump is bound to %s" % str(_keys_of("jump")))
	h.check(h.read_storage_file(SETTINGS_FILE).contains("key_jump=%d" % KEY_J), "the new key was not saved")

	settings.back()
	h.fixture.get_node(MENU).resume()
	await h.steps(5)
	await h.tap_key(KEY_SPACE)
	await h.steps(5)
	h.check(jumps[0] == 0, "the old key still jumps")
	await h.tap_key(KEY_J)
	await h.steps(2)
	h.check(jumps[0] == 1, "the new key did not jump")


func test_a_captured_key_does_nothing_else(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	var menu: Control = h.fixture.get_node(MENU)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_ENTER)
	h.check(_keys_of("jump") == [KEY_ENTER], "Enter was not captured: %s" % str(_keys_of("jump")))
	h.check(not settings.is_capturing(), "Enter was not accepted as a key")
	h.check(menu.is_open() and settings.visible, "the captured key also acted on the menu")


func test_escape_cancels_a_capture_and_changes_nothing(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(JUMP)
	h.check(_key_button(h, "Jump").text == "...", "the row reads '%s' while capturing" % _key_button(h, "Jump").text)
	await h.tap_key(KEY_ESCAPE)
	h.check(not settings.is_capturing(), "Esc did not cancel the capture")
	h.check(settings.visible, "one Esc cancelled the capture and also closed Settings")
	h.check(_keys_of("jump") == [KEY_SPACE], "jump changed to %s" % str(_keys_of("jump")))
	h.check(_key_button(h, "Jump").text == "Space", "the row reads '%s'" % _key_button(h, "Jump").text)


func test_a_gamepad_can_cancel_a_capture_and_cannot_wander_off(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	_key_button(h, "Jump").grab_focus()
	settings.begin_capture(JUMP)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	h.check(settings.is_capturing(), "a pad button ended the capture")
	h.check(_key_button(h, "Jump").has_focus(), "a pad button moved focus during the capture")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(not settings.is_capturing(), "the east button did not cancel the capture")
	h.check(settings.visible, "the east button cancelled and also closed Settings")


func test_reserved_keys_are_refused_with_an_explanation(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_LEFT)
	h.check(settings.is_capturing(), "a reserved key ended the capture")
	h.check(_message(h).contains("Left"), "the message does not name the key: '%s'" % _message(h))
	h.check(_keys_of("jump") == [KEY_SPACE], "jump changed to %s" % str(_keys_of("jump")))
	await h.tap_key(KEY_K)
	h.check(_keys_of("jump") == [KEY_K], "another key was not accepted after the refusal")


func test_a_conflict_is_explained_and_can_be_swapped(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_SPACE)
	h.check(settings.has_conflict(), "no conflict for a key already in use")
	h.check(_message(h).contains("Space") and _message(h).contains("Jump"), "the message does not explain the conflict: '%s'" % _message(h))
	h.check(_keys_of("interact") == [KEY_E] and _keys_of("jump") == [KEY_SPACE], "keys changed before the choice")
	var swap: Button = h.fixture.get_node(ITEMS + "Conflict/Swap")
	h.check(swap.visible and swap.has_focus(), "the choice is not offered with focus")
	await h.tap_action("ui_accept")
	h.check(not settings.has_conflict(), "the conflict stayed after swapping")
	h.check(_keys_of("interact") == [KEY_SPACE], "interact is bound to %s" % str(_keys_of("interact")))
	h.check(_keys_of("jump") == [KEY_E], "jump is bound to %s" % str(_keys_of("jump")))
	h.check(_key_button(h, "Interact").has_focus(), "focus did not return to the row")
	h.check(_key_button(h, "Jump").text == "E" and _key_button(h, "Interact").text == "Space", "the rows did not update")


func test_cancelling_a_conflict_changes_nothing(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	var menu: Control = h.fixture.get_node(MENU)
	for cancel in ["button", "back"]:
		settings.begin_capture(INTERACT)
		await h.tap_key(KEY_SPACE)
		if cancel == "button":
			h.fixture.get_node(ITEMS + "Conflict/Cancel").grab_focus()
			await h.tap_action("ui_accept")
		else:
			await h.tap_key(KEY_ESCAPE)
		h.check(not settings.has_conflict(), "%s did not cancel the conflict" % cancel)
		h.check(settings.visible and menu.is_open(), "%s also closed Settings" % cancel)
		h.check(_keys_of("interact") == [KEY_E] and _keys_of("jump") == [KEY_SPACE], "%s changed the keys" % cancel)
		h.check(not h.fixture.get_node(ITEMS + "Conflict").visible, "%s left the choice showing" % cancel)


func test_focus_cannot_leave_a_conflict_choice(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_SPACE)
	var swap: Button = h.fixture.get_node(ITEMS + "Conflict/Swap")
	var cancel: Button = h.fixture.get_node(ITEMS + "Conflict/Cancel")
	await h.tap_action("ui_down")
	h.check(swap.has_focus(), "down left the choice")
	await h.tap_action("ui_up")
	h.check(swap.has_focus(), "up left the choice")
	await h.tap_action("ui_right")
	h.check(cancel.has_focus(), "right did not reach Cancel")


func test_the_arrows_still_move_after_rebinding(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(1)
	await h.tap_key(KEY_L)
	h.check(KEY_RIGHT in _keys_of("move_right") and KEY_L in _keys_of("move_right") and not KEY_D in _keys_of("move_right"), "move_right is bound to %s" % str(_keys_of("move_right")))
	settings.back()
	h.fixture.get_node(MENU).resume()
	await h.stand_at(player, Vector2(250, -2))
	var x := player.global_position.x
	h.send(h.key_event(KEY_RIGHT, true))
	await h.steps(20)
	h.send(h.key_event(KEY_RIGHT, false))
	h.check(player.global_position.x > x + 5.0, "the right arrow stopped moving the player")


func test_restore_defaults_brings_everything_back(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_J)
	settings.set_music_volume(0.2)
	h.fixture.get_node(ITEMS + "RestoreDefaults").grab_focus()
	await h.tap_action("ui_accept")
	h.check(_keys_of("jump") == [KEY_SPACE], "jump is bound to %s" % str(_keys_of("jump")))
	h.check(_key_button(h, "Jump").text == "Space", "the row reads '%s'" % _key_button(h, "Jump").text)
	h.check_near(h.fixture.get_node(ITEMS + "Music/Slider").value, 1.0, 0.001, "the music slider")
	h.check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), 0.0, 0.01, "the Music bus")
	h.check(_message(h).contains("restored"), "no confirmation: '%s'" % _message(h))
	h.check(h.read_storage_file(SETTINGS_FILE).contains("key_jump=%d" % KEY_SPACE), "the defaults were not saved")


func test_volumes_reach_their_own_buses(h) -> void:
	await _setup(h)
	await _open(h)
	var music: HSlider = h.fixture.get_node(ITEMS + "Music/Slider")
	var effects: HSlider = h.fixture.get_node(ITEMS + "Effects/Slider")
	var music_bus := AudioServer.get_bus_index("Music")
	var effects_bus := AudioServer.get_bus_index("Effects")
	music.value = 0.5
	h.check_near(AudioServer.get_bus_volume_db(music_bus), linear_to_db(0.5), 0.05, "the Music bus at 50%")
	h.check_near(AudioServer.get_bus_volume_db(effects_bus), 0.0, 0.01, "the Effects bus, unchanged")
	effects.value = 0.0
	h.check(AudioServer.is_bus_mute(effects_bus), "0% did not mute the Effects bus")
	h.check(not AudioServer.is_bus_mute(music_bus), "the Music bus was muted too")
	effects.value = 0.3
	h.check(not AudioServer.is_bus_mute(effects_bus), "raising the volume did not unmute")
	var text: String = h.read_storage_file(SETTINGS_FILE)
	h.check(text.contains("music_volume=0.5") and text.contains("effects_volume=0.3"), "the volumes were not saved:\n%s" % text)


func test_a_focused_slider_moves_with_the_keys_and_the_change_is_kept(h) -> void:
	await _setup(h)
	await _open(h)
	var music: HSlider = h.fixture.get_node(ITEMS + "Music/Slider")
	h.check(music.has_focus(), "the first control in Settings does not have focus")
	await h.tap_action("ui_left")
	h.check_near(music.value, 0.9, 0.001, "the music slider after one press left")
	h.check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.9), 0.05, "the Music bus")
	h.check(h.read_storage_file(SETTINGS_FILE).contains("music_volume=0.9"), "the change was not saved")
	await h.tap_action("ui_right")
	h.check_near(music.value, 1.0, 0.001, "the music slider after one press right")


func test_focus_can_walk_every_row_and_nothing_traps_it(h) -> void:
	await _setup(h)
	await _open(h)
	var expected := ["Music/Slider", "Effects/Slider", "MoveLeft/Key", "MoveRight/Key", "Jump/Key", "Interact/Key", "RestoreDefaults", "Back"]
	for path in expected:
		h.check(h.fixture.get_node(ITEMS + path).has_focus(), "going down, %s does not have focus" % path)
		await h.tap_action("ui_down")
	expected.reverse()
	for path in expected:
		h.check(h.fixture.get_node(ITEMS + path).has_focus(), "going up, %s does not have focus" % path)
		await h.tap_action("ui_up")


func test_a_scene_loads_the_saved_settings(h) -> void:
	h.write_storage_file(SETTINGS_FILE, _bytes("dagon_settings=1\nmusic_volume=0.5\neffects_volume=1\nkey_move_left=74\nkey_move_right=76\nkey_jump=75\nkey_interact=85\n"))
	await _setup(h)
	h.check(_keys_of("jump") == [KEY_K], "jump is bound to %s" % str(_keys_of("jump")))
	h.check(_keys_of("move_left").has(KEY_J) and _keys_of("move_left").has(KEY_LEFT), "move_left is bound to %s" % str(_keys_of("move_left")))
	h.check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.5), 0.05, "the Music bus")
	var settings := await _open(h)
	h.check(_key_button(h, "Jump").text == "K", "the row reads '%s'" % _key_button(h, "Jump").text)
	h.check_near(h.fixture.get_node(ITEMS + "Music/Slider").value, 0.5, 0.001, "the music slider")
	settings.back()


func test_the_prompt_names_a_rebound_key(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(150, -2))
	var settings := await _open(h)
	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_U)
	settings.back()
	h.fixture.get_node(MENU).resume()
	await h.steps(2)
	var prompt: Label = h.fixture.get_node("Hud/Prompt")
	h.check(prompt.text == "[U] Examine", "the prompt reads '%s'" % prompt.text)


func test_bindings_survive_restart_checkpoint(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_J)
	settings.back()
	h.fixture.get_node(MENU).restart_checkpoint()
	await h.steps(2)
	h.check(_keys_of("jump") == [KEY_J], "reset_global_state lost the binding: %s" % str(_keys_of("jump")))


func test_damaged_files_fall_back_to_defaults_without_errors(h) -> void:
	var cases := {
		"binary noise": PackedByteArray([0, 255, 254, 1, 61, 128, 10, 0, 200]),
		"another version": _bytes("dagon_settings=99\nkey_jump=75\n"),
		"truncated": _bytes("dagon_settings=1\nmusic_volume=0.5\nkey_move_le"),
		"two actions on one key": _bytes("dagon_settings=1\nmusic_volume=1\neffects_volume=1\nkey_move_left=74\nkey_move_right=74\nkey_jump=75\nkey_interact=85\n"),
		"Esc rebound": _bytes("dagon_settings=1\nmusic_volume=1\neffects_volume=1\nkey_move_left=74\nkey_move_right=76\nkey_jump=%d\nkey_interact=85\n" % KEY_ESCAPE),
	}
	for case_name in cases:
		h.write_storage_file(SETTINGS_FILE, cases[case_name])
		await h.load_fixture(SHORE)
		h.check(_keys_of("jump") == [KEY_SPACE], "%s: jump is bound to %s" % [case_name, str(_keys_of("jump"))])
		h.check(KEY_ESCAPE in _keys_of("pause"), "%s: the pause key is gone" % case_name)
		h.check(FileAccess.get_file_as_bytes(h.storage_dir.path_join(SETTINGS_FILE)) == cases[case_name], "%s: loading changed the file" % case_name)
		h.fixture.queue_free()
		h.probe.queue_free()
		await h.tree.process_frame
		await h.tree.physics_frame


func test_a_failed_write_is_reported_and_the_change_still_applies(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	# A folder where the temporary file has to go, so the write fails on every platform.
	DirAccess.make_dir_recursive_absolute(h.storage_dir.path_join(SETTINGS_FILE + ".tmp"))
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_J)
	h.check(_keys_of("jump") == [KEY_J], "the change did not apply: %s" % str(_keys_of("jump")))
	h.check(_message(h).contains("Could not save"), "the failure was not reported: '%s'" % _message(h))
	h.check(settings.visible, "the failure closed Settings")

	# The message says the change lasts until quitting, so reopening Settings or restarting must not undo it.
	var menu: Control = h.fixture.get_node(MENU)
	settings.back()
	menu.open_settings()
	await h.steps(1)
	h.check(_key_button(h, "Jump").text == "J", "reopening Settings lost the unsaved key: '%s'" % _key_button(h, "Jump").text)
	settings.back()
	menu.restart_checkpoint()
	await h.steps(2)
	h.check(_keys_of("jump") == [KEY_J], "restarting lost the unsaved key: %s" % str(_keys_of("jump")))

	# Once writing works again, the next change saves it all.
	DirAccess.remove_absolute(h.storage_dir.path_join(SETTINGS_FILE + ".tmp"))
	menu.open()
	menu.open_settings()
	await h.steps(1)
	settings.set_music_volume(0.5)
	h.check(h.read_storage_file(SETTINGS_FILE).contains("key_jump=%d" % KEY_J), "the recovered write did not save the key")
	h.check(_message(h) == "", "the failure message stayed after a good write: '%s'" % _message(h))


func test_settings_survive_a_relaunch(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_J)
	settings.set_music_volume(0.5)
	var output := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/settings_probe.gd"], output, true)
	h.check(code == 0, "the relaunch exited with %d: %s" % [code, output[0]])
	h.check("PROBE jump_keys=[%d] music_db=-6.02" % KEY_J in output[0], "a new process loaded something else: %s" % output[0])
