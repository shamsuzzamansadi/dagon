extends RefCounted
## Tests of the settings menu, key rebinding and the settings file, each in its own test directory.

const GAME := "res://scenes/level/game.tscn"
const MENU := "PauseLayer/PauseMenu"
const ITEMS := "PauseLayer/PauseMenu/Settings/Center/Panel/Items/"
const SETTINGS_FILE := "settings.cfg"
const JUMP := 2
const INTERACT := 3
const AUDIO_NOTE := "Narration samples only. No music or effects yet."


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(GAME)
	var player: CharacterBody2D = h.fixture.get_node("World/Player")
	await h.landed_on_floor(player)
	return player


func _open(h) -> Control:
	var menu: Control = h.fixture.get_node(MENU)
	menu.open()
	menu.open_settings()
	await h.steps(1)
	return menu.get_node("Settings")


func _key_button(h, row: String) -> Button:
	return h.fixture.get_node(ITEMS + "Columns/Keys/" + row + "/Key")


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


func _focus(h) -> Control:
	return h.fixture.get_node(MENU).get_viewport().gui_get_focus_owner()


func _lose_focus(h) -> void:
	h.fixture.get_node(MENU).get_viewport().gui_release_focus()
	h.check(_focus(h) == null, "the test did not lose focus")


## Ways a player can press something with nothing focused: pressed and released events.
func _recovery_presses(h) -> Dictionary:
	return {
		"Down key": [h.key_event(KEY_DOWN, true), h.key_event(KEY_DOWN, false)],
		"D-pad": [h.pad_event(JOY_BUTTON_DPAD_DOWN, true), h.pad_event(JOY_BUTTON_DPAD_DOWN, false)],
		"Enter": [h.key_event(KEY_ENTER, true), h.key_event(KEY_ENTER, false)],
		"south button": [h.pad_event(JOY_BUTTON_A, true), h.pad_event(JOY_BUTTON_A, false)],
	}


## A folder where the temporary file has to go, so the write fails on every platform.
func _block_writes(h) -> void:
	DirAccess.make_dir_recursive_absolute(h.storage_dir.path_join(SETTINGS_FILE + ".tmp"))


func _allow_writes(h) -> void:
	DirAccess.remove_absolute(h.storage_dir.path_join(SETTINGS_FILE + ".tmp"))


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
	h.check_near(h.fixture.get_node(ITEMS + "Columns/Audio/Music/Slider").value, 1.0, 0.001, "the music slider")
	h.check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), 0.0, 0.01, "the Music bus")
	h.check(_message(h).contains("restored"), "no confirmation: '%s'" % _message(h))
	h.check(h.read_storage_file(SETTINGS_FILE).contains("key_jump=%d" % KEY_SPACE), "the defaults were not saved")


func test_volumes_reach_their_own_buses(h) -> void:
	await _setup(h)
	await _open(h)
	var music: HSlider = h.fixture.get_node(ITEMS + "Columns/Audio/Music/Slider")
	var effects: HSlider = h.fixture.get_node(ITEMS + "Columns/Audio/Effects/Slider")
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
	var music: HSlider = h.fixture.get_node(ITEMS + "Columns/Audio/Music/Slider")
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
	var expected := ["Columns/Audio/Music/Slider", "Columns/Audio/Effects/Slider", "Columns/Audio/Narration/Slider", "Columns/Audio/Subtitles", "Columns/Audio/Vibration", "Columns/Keys/MoveLeft/Key", "Columns/Keys/MoveRight/Key", "Columns/Keys/Jump/Key", "Columns/Keys/Interact/Key", "RestoreDefaults", "Back"]
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
	h.check_near(h.fixture.get_node(ITEMS + "Columns/Audio/Music/Slider").value, 0.5, 0.001, "the music slider")
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
	var prompt: Label = h.fixture.get_node("World/Hud/Prompt")
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
		await h.load_fixture(GAME)
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
	_block_writes(h)
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
	_allow_writes(h)
	menu.open()
	menu.open_settings()
	await h.steps(1)
	settings.set_music_volume(0.5)
	h.check(h.read_storage_file(SETTINGS_FILE).contains("key_jump=%d" % KEY_J), "the recovered write did not save the key")
	h.check(_message(h) == "", "the failure message stayed after a good write: '%s'" % _message(h))


func test_focus_lost_in_settings_comes_back_to_a_usable_control(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	var menu: Control = h.fixture.get_node(MENU)
	var presses := _recovery_presses(h)
	for press: String in presses:
		_lose_focus(h)
		await h.tap(presses[press][0], presses[press][1])
		var focus := _focus(h)
		h.check(focus != null and focus.is_visible_in_tree() and settings.is_ancestor_of(focus), "after %s, focus is on %s" % [press, focus])
		h.check(settings.visible and menu.is_open(), "%s changed the screen" % press)

	# What came back has to work: it responds, and focus can move on from it.
	var music: HSlider = h.fixture.get_node(ITEMS + "Columns/Audio/Music/Slider")
	h.check(music.has_focus(), "recovered to %s" % _focus(h))
	await h.tap_action("ui_left")
	h.check_near(music.value, 0.9, 0.001, "the recovered slider after a press left")
	await h.tap_action("ui_down")
	h.check(h.fixture.get_node(ITEMS + "Columns/Audio/Effects/Slider").has_focus(), "focus did not move on: %s" % _focus(h))

	# Back still closes one level.
	await h.tap_key(KEY_ESCAPE)
	h.check(menu.is_open() and not settings.visible, "Back after recovering did not close only Settings")


func test_focus_lost_in_a_conflict_comes_back_inside_the_choice(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_SPACE)
	var swap: Button = h.fixture.get_node(ITEMS + "Conflict/Swap")
	var cancel: Button = h.fixture.get_node(ITEMS + "Conflict/Cancel")
	var message := _message(h)
	var presses := _recovery_presses(h)
	for press: String in presses:
		_lose_focus(h)
		await h.tap(presses[press][0], presses[press][1])
		h.check(_focus(h) == swap or _focus(h) == cancel, "after %s, focus is on %s" % [press, _focus(h)])
		h.check(settings.has_conflict(), "%s ended the conflict" % press)
		h.check(_message(h) == message, "%s changed the message to '%s'" % [press, _message(h)])
		h.check(_keys_of("interact") == [KEY_E] and _keys_of("jump") == [KEY_SPACE], "%s changed the keys" % press)

	# The recovered choice works.
	h.check(swap.has_focus(), "recovered to %s" % _focus(h))
	await h.tap_action("ui_accept")
	h.check(not settings.has_conflict(), "the recovered Swap did nothing")
	h.check(_keys_of("interact") == [KEY_SPACE] and _keys_of("jump") == [KEY_E], "the recovered Swap did not swap")


func test_losing_focus_during_a_capture_changes_nothing(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.begin_capture(JUMP)
	_lose_focus(h)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	h.check(settings.is_capturing(), "a pad press ended the capture")
	h.check(_focus(h) == null, "a pad press moved focus during the capture: %s" % _focus(h))
	await h.tap_pad(JOY_BUTTON_B)
	h.check(not settings.is_capturing(), "the east button did not cancel the capture")
	h.check(settings.visible, "cancelling the capture also closed Settings")
	h.check(_keys_of("jump") == [KEY_SPACE], "the capture changed the key: %s" % str(_keys_of("jump")))
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	var focus := _focus(h)
	h.check(focus != null and focus.is_visible_in_tree() and settings.is_ancestor_of(focus), "after the capture, focus is on %s" % focus)


func test_recovering_focus_keeps_unsaved_settings(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	_block_writes(h)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_J)
	_lose_focus(h)
	await h.tap_key(KEY_DOWN)
	h.check(_keys_of("jump") == [KEY_J], "recovering focus lost the key: %s" % str(_keys_of("jump")))
	h.check(_key_button(h, "Jump").text == "J", "the row reads '%s'" % _key_button(h, "Jump").text)
	h.check(_message(h).contains("Could not save"), "recovering focus lost the warning: '%s'" % _message(h))


func test_a_good_write_removes_the_warning_on_the_same_screen(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	_block_writes(h)
	settings.set_music_volume(0.5)
	h.check(_message(h).contains("Could not save"), "the failed write was not reported: '%s'" % _message(h))
	_allow_writes(h)
	settings.set_music_volume(0.4)
	h.check(_message(h) == "", "the warning stayed after a good write: '%s'" % _message(h))
	h.check(h.read_storage_file(SETTINGS_FILE).contains("music_volume=0.4"), "the retry did not save")


func test_reopening_with_unsaved_changes_still_says_so(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	var menu: Control = h.fixture.get_node(MENU)
	_block_writes(h)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_J)
	settings.back()
	menu.open_settings()
	await h.steps(1)
	h.check(_message(h).contains("Could not save"), "reopening hid the warning: '%s'" % _message(h))
	h.check(_key_button(h, "Jump").text == "J", "reopening lost the unsaved key: '%s'" % _key_button(h, "Jump").text)

	settings.back()
	menu.restart_checkpoint()
	await h.steps(2)
	menu.open()
	menu.open_settings()
	await h.steps(1)
	h.check(_message(h).contains("Could not save"), "restarting hid the warning: '%s'" % _message(h))
	h.check(_keys_of("jump") == [KEY_J], "restarting lost the unsaved key: %s" % str(_keys_of("jump")))

	# Saved at last: the warning goes, and stays gone on reopening.
	_allow_writes(h)
	settings.set_music_volume(0.5)
	settings.back()
	menu.open_settings()
	await h.steps(1)
	h.check(_message(h) == "", "the warning came back after a good write: '%s'" % _message(h))


func test_instructions_replace_the_warning_and_it_returns_afterwards(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	_block_writes(h)
	settings.set_music_volume(0.5)

	settings.begin_capture(JUMP)
	h.check(_message(h).contains("Press a key"), "no capture instruction: '%s'" % _message(h))
	await h.tap_key(KEY_ESCAPE)
	h.check(_message(h).contains("Could not save"), "cancelling a capture hid the warning: '%s'" % _message(h))

	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_SPACE)
	h.check(_message(h).contains("Space") and _message(h).contains("Jump"), "no conflict explanation: '%s'" % _message(h))
	await h.tap_key(KEY_ESCAPE)
	h.check(_message(h).contains("Could not save"), "cancelling a conflict hid the warning: '%s'" % _message(h))

	# A slider moved with the mouse during a conflict must not wipe the explanation.
	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_SPACE)
	settings.set_music_volume(0.3)
	h.check(_message(h).contains("Space") and _message(h).contains("Jump"), "a change during a conflict wiped its explanation: '%s'" % _message(h))
	await h.tap_key(KEY_ESCAPE)
	h.check(_message(h).contains("Could not save"), "the warning did not return after the conflict: '%s'" % _message(h))

	# The key an action already has changes nothing, so it is still unsaved.
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_SPACE)
	h.check(_message(h).contains("Could not save"), "an unchanged key hid the warning: '%s'" % _message(h))


func test_restore_defaults_reports_what_really_happened(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	settings.restore_defaults()
	h.check(_message(h).contains("restored"), "no confirmation: '%s'" % _message(h))
	settings.set_music_volume(0.5)
	h.check(_message(h) == "", "the confirmation outlived a later change: '%s'" % _message(h))

	_block_writes(h)
	settings.restore_defaults()
	h.check(_message(h).contains("Could not save"), "a failed restore was not reported: '%s'" % _message(h))
	h.check(_keys_of("jump") == [KEY_SPACE], "the failed restore did not apply: %s" % str(_keys_of("jump")))

	_allow_writes(h)
	settings.restore_defaults()
	h.check(_message(h).contains("restored"), "a restore after a failure reads: '%s'" % _message(h))
	h.check(h.read_storage_file(SETTINGS_FILE).contains("music_volume=1"), "the restore did not save")


func test_quitting_with_unsaved_settings_does_not_claim_they_are_kept(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	var menu: Control = h.fixture.get_node(MENU)
	var message: Label = menu.get_node("Center/Confirm/Items/Message")
	settings.back()
	menu.ask_quit_to_desktop()
	h.check(message.text.contains("settings are kept"), "the normal message reads '%s'" % message.text)
	menu.cancel_confirm()

	_block_writes(h)
	menu.open_settings()
	await h.steps(1)
	settings.set_music_volume(0.5)
	settings.back()
	menu.ask_quit_to_desktop()
	h.check(not message.text.contains("settings are kept"), "it claims unsaved settings are kept: '%s'" % message.text)
	h.check(message.text.contains("settings could not be saved"), "it does not mention the failed save: '%s'" % message.text)
	menu.cancel_confirm()

	_allow_writes(h)
	menu.open_settings()
	await h.steps(1)
	settings.set_music_volume(0.4)
	settings.back()
	menu.ask_quit_to_desktop()
	h.check(message.text.contains("settings are kept"), "the message did not recover: '%s'" % message.text)


func test_the_settings_screen_says_exactly_which_keys_are_kept(h) -> void:
	await _setup(h)
	await _open(h)
	var note: String = h.fixture.get_node(ITEMS + "Columns/Keys/Note").text
	h.check(note == "Left/Right arrows always move. Esc always pauses.", "the note reads '%s'" % note)


## The note says how far audio has come (D42). Replace it, and these tests, when music and effects are connected.
func _check_audio_note(h, settings: Control, where: String) -> void:
	var panel: Control = settings.get_node("Center/Panel")
	var items: Control = panel.get_node("Items/Columns/Audio")
	var note: Label = items.get_node("AudioNote")
	h.check(note.text == AUDIO_NOTE, "%s: the note reads '%s'" % [where, note.text])
	h.check(note.is_visible_in_tree(), "%s: the note is not showing" % where)
	h.check(note.get_line_count() <= 2 and note.get_visible_line_count() == note.get_line_count(), "%s: the note takes %d lines, %d showing" % [where, note.get_line_count(), note.get_visible_line_count()])
	h.check(items.get_global_rect().encloses(note.get_global_rect()), "%s: the note is outside its panel" % where)
	h.check(settings.get_viewport_rect().encloses(panel.get_global_rect()), "%s: the panel is clipped: %s" % [where, panel.get_global_rect()])
	h.check(note.get_index() == items.get_node("Narration").get_index() + 1, "%s: the note is not directly below the volumes" % where)
	h.check(note.focus_mode == Control.FOCUS_NONE, "%s: the note can take focus" % where)
	h.check(note.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s: the note can take clicks" % where)


func test_the_audio_note_shows_and_fits_in_both_menus(h) -> void:
	await _setup(h)
	_check_audio_note(h, await _open(h), "the pause menu")
	await h.unload_fixture()
	var title: Control = await h.load_main_fixture("res://scenes/ui/title.tscn")
	await h.steps(3)
	title.open_settings()
	await h.steps(2)
	_check_audio_note(h, title.get_node("Settings"), "the main menu")


## Capture, refusal and conflict text make the panel taller. The longest device name makes that text longest.
func test_the_audio_note_and_all_of_settings_fit_in_every_state(h) -> void:
	h.use_controller("Generic USB Joystick")
	await _setup(h)
	var settings := await _open(h)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	var message: Label = h.fixture.get_node(ITEMS + "Message")
	var states := {
		"capture": func() -> void: settings.begin_capture(JUMP),
		"refused": func() -> void: await h.tap_key(KEY_LEFT),
		"conflict": func() -> void: await h.tap_key(KEY_E),
		"cancelled": func() -> void: settings.cancel_conflict(),
	}
	for state: String in states:
		await states[state].call()
		await h.steps(2)
		_check_audio_note(h, settings, state)
		h.check(message.get_visible_line_count() == message.get_line_count(), "%s: only %d of %d message lines show" % [state, message.get_visible_line_count(), message.get_line_count()])
		if state == "refused":
			h.check(message.text.contains("right face button"), "this state did not use the longest name: '%s'" % message.text)
		if state == "conflict":
			h.check(settings.has_conflict(), "the conflict state was not reached")
	_block_writes(h)
	settings.set_music_volume(0.5)
	await h.steps(2)
	h.check(message.text.contains("Could not save"), "the failed-save state was not reached: '%s'" % message.text)
	_check_audio_note(h, settings, "failed save")
	_allow_writes(h)


func test_the_audio_note_never_takes_focus_from_keys_or_a_controller(h) -> void:
	h.use_controller("Xbox Series Controller")
	await _setup(h)
	await _open(h)
	var note: Control = h.fixture.get_node(ITEMS + "Columns/Audio/AudioNote")
	var viewport: Viewport = note.get_viewport()
	var rows := ["Columns/Audio/Music/Slider", "Columns/Audio/Effects/Slider", "Columns/Audio/Narration/Slider", "Columns/Audio/Subtitles", "Columns/Audio/Vibration", "Columns/Keys/MoveLeft/Key", "Columns/Keys/MoveRight/Key", "Columns/Keys/Jump/Key", "Columns/Keys/Interact/Key", "RestoreDefaults", "Back"]
	var devices := {
		"arrow keys": [func() -> void: await h.tap_key(KEY_DOWN), func() -> void: await h.tap_key(KEY_UP)],
		"D-pad": [func() -> void: await h.tap_pad(JOY_BUTTON_DPAD_DOWN), func() -> void: await h.tap_pad(JOY_BUTTON_DPAD_UP)],
	}
	for device: String in devices:
		for direction in 2:
			var walk := rows.duplicate()
			if direction == 1:
				walk.reverse()
			for path: String in walk:
				h.check(h.fixture.get_node(ITEMS + path).has_focus(), "%s, way %d: %s does not have focus, %s does" % [device, direction, path, viewport.gui_get_focus_owner()])
				h.check(viewport.gui_get_focus_owner() != note, "%s: the note has focus" % device)
				await devices[device][direction].call()

	# Back on the first row, the stick crosses the note too, by the same path as the D-pad.
	var narration: Control = h.fixture.get_node(ITEMS + "Columns/Audio/Narration/Slider")
	narration.grab_focus()
	var down := InputEventJoypadMotion.new()
	down.axis = JOY_AXIS_LEFT_Y
	down.axis_value = 1.0
	await h.send_between_ticks(down)
	h.check(h.fixture.get_node(ITEMS + "Columns/Audio/Subtitles").has_focus(), "the stick moved focus from Narration to %s" % viewport.gui_get_focus_owner())
	var rest := InputEventJoypadMotion.new()
	rest.axis = JOY_AXIS_LEFT_Y
	rest.axis_value = 0.0
	await h.send_between_ticks(rest)


func test_up_and_down_can_be_rebound_and_the_menu_still_works(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var settings := await _open(h)
	var menu: Control = h.fixture.get_node(MENU)
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	settings.begin_capture(JUMP)
	await h.tap_key(KEY_UP)
	settings.begin_capture(INTERACT)
	await h.tap_key(KEY_DOWN)
	h.check(_keys_of("jump") == [KEY_UP], "Up was not accepted: %s" % str(_keys_of("jump")))
	h.check(_keys_of("interact") == [KEY_DOWN], "Down was not accepted: %s" % str(_keys_of("interact")))
	h.check(_key_button(h, "Jump").text == "Up" and _key_button(h, "Interact").text == "Down", "the rows did not update")

	# The same keys still navigate the menus, and pressing them there does nothing to the game.
	_key_button(h, "Interact").grab_focus()
	await h.tap_key(KEY_UP)
	h.check(_key_button(h, "Jump").has_focus(), "Up did not move focus up: %s" % _focus(h))
	await h.tap_key(KEY_DOWN)
	h.check(_key_button(h, "Interact").has_focus(), "Down did not move focus down: %s" % _focus(h))
	h.check(jumps[0] == 0, "navigating with Up jumped")

	# Back still closes one level at a time.
	await h.tap_key(KEY_ESCAPE)
	h.check(menu.is_open() and not settings.visible, "Esc did not close only Settings")
	await h.tap_key(KEY_DOWN)
	h.check(_focus(h) == menu.get_node("Center/Main/Items/Controls"), "Down did not move focus in the main menu: %s" % _focus(h))
	await h.tap_key(KEY_ESCAPE)
	h.check(not menu.is_open() and not h.tree.paused, "Esc did not resume")

	# And in the game they are the new keys.
	await h.steps(5)
	await h.tap_key(KEY_UP)
	await h.steps(2)
	h.check(jumps[0] == 1, "Up did not jump in the game")


## Measured on Windows with a Bangla layout: the layout puts Bengali letters on A, D and E, which the
## game's font cannot draw. The key is still named, by its position on a US keyboard.
func test_a_key_is_named_even_when_the_font_cannot_draw_the_layout_letter(h) -> void:
	await _setup(h)
	var settings := await _open(h)
	var cases := [
		[KEY_A, 0x09BE, "A", "Bangla on A"],
		[KEY_D, 0x09A1, "D", "Bangla on D"],
		[KEY_E, 0x09C0, "E", "Bangla on E"],
		[KEY_E, KEY_E, "E", "English"],
		[KEY_Y, KEY_Z, "Z", "German swaps Y and Z"],
		[KEY_SEMICOLON, 0x00D6, "\u00d6", "German O-umlaut"],
		[KEY_SPACE, KEY_SPACE, "Space", "a named key"],
		[KEY_E, KEY_NONE, "E", "no layout information"],
	]
	for entry in cases:
		var shown: String = settings.describe_key(entry[0], entry[1])
		h.check(shown == entry[2], "%s reads '%s', expected '%s'" % [entry[3], shown, entry[2]])


func test_the_font_can_draw_every_ascii_key_name(h) -> void:
	await _setup(h)
	var label: Label = h.fixture.get_node(ITEMS + "Message")
	var font := label.get_theme_font("font")
	for code in range(33, 127):
		h.check(font.has_char(code), "the font lacks '%s'" % char(code))


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
