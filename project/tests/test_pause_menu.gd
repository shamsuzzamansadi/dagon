extends RefCounted
## Tests of the pause menu in the game scene, driven by real input events.

const GAME := "res://scenes/level/game.tscn"
const ITEMS := "PauseLayer/PauseMenu/Center/Main/Items/"


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(GAME)
	var player: CharacterBody2D = _player(h)
	await h.landed_on_floor(player)
	return player


## Restarting rebuilds the world, so this is always the current player.
func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("World/Player")


func _menu(h) -> Control:
	return h.fixture.get_node("PauseLayer/PauseMenu")


func _button(h, button_name: String) -> Button:
	return h.fixture.get_node(ITEMS + button_name)


func _focus(h) -> Control:
	return _menu(h).get_viewport().gui_get_focus_owner()


## Checks the mapping data. Physical keyboards and controllers are a manual check.
func test_menus_and_new_actions_have_keyboard_and_gamepad_events(h) -> void:
	var expected := {
		"interact": [h.key_event(KEY_E, true), h.pad_event(JOY_BUTTON_X, true)],
		"pause": [h.key_event(KEY_ESCAPE, true), h.pad_event(JOY_BUTTON_START, true)],
		"ui_accept": [h.key_event(KEY_ENTER, true), h.key_event(KEY_SPACE, true), h.pad_event(JOY_BUTTON_A, true)],
		"ui_cancel": [h.key_event(KEY_ESCAPE, true), h.pad_event(JOY_BUTTON_B, true)],
		"ui_up": [h.key_event(KEY_UP, true), h.pad_event(JOY_BUTTON_DPAD_UP, true)],
		"ui_down": [h.key_event(KEY_DOWN, true), h.pad_event(JOY_BUTTON_DPAD_DOWN, true)],
		"ui_left": [h.key_event(KEY_LEFT, true), h.pad_event(JOY_BUTTON_DPAD_LEFT, true)],
		"ui_right": [h.key_event(KEY_RIGHT, true), h.pad_event(JOY_BUTTON_DPAD_RIGHT, true)],
	}
	for action: String in expected:
		for event: InputEvent in expected[action]:
			h.check(InputMap.event_is_action(event, action), "%s does not trigger %s" % [event.as_text(), action])


func test_pausing_stops_gameplay_and_focuses_resume(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var sprite: AnimatedSprite2D = player.get_node("Visual/Sailor")
	Input.action_press("move_right")
	await h.steps(30)
	await h.tap_action("pause")
	h.check(h.tree.paused, "the tree did not pause")
	h.check(_menu(h).is_open() and _menu(h).visible, "the menu did not open")
	h.check(_focus(h) == _button(h, "Resume"), "focus is on %s" % _focus(h))
	var x := player.global_position.x
	var frame := sprite.frame
	await h.steps(30)
	h.check(player.global_position.x == x, "the player moved while paused")
	h.check(sprite.frame == frame, "the sailor animated while paused")


func test_resuming_continues_gameplay(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	Input.action_press("move_right")
	await h.tap_action("pause")
	var x := player.global_position.x
	await h.tap_action("pause")
	h.check(not h.tree.paused, "still paused after resuming")
	h.check(not _menu(h).visible, "the menu stayed open")
	await h.steps(20)
	h.check(player.global_position.x > x + 5.0, "the player did not continue")
	h.check(_focus(h) == null, "a hidden button kept focus")


func test_one_escape_press_acts_once(h) -> void:
	await _setup(h)
	await h.tap_key(KEY_ESCAPE)
	h.check(_menu(h).is_open(), "Esc did not open the menu")
	await h.tap_key(KEY_ESCAPE)
	h.check(not _menu(h).is_open(), "Esc did not close the menu")
	h.check(not h.tree.paused, "Esc closed the menu but left the game paused")


func test_the_gamepad_can_open_navigate_press_and_back_out(h) -> void:
	await _setup(h)
	await h.tap_pad(JOY_BUTTON_START)
	h.check(_menu(h).is_open(), "Start did not open the menu")
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	h.check(_focus(h) == _button(h, "RestartCheckpoint"), "D-pad down moved focus to %s" % _focus(h))
	await h.tap_pad(JOY_BUTTON_DPAD_UP)
	h.check(_focus(h) == _button(h, "Resume"), "D-pad up moved focus to %s" % _focus(h))
	await h.tap_pad(JOY_BUTTON_B)
	h.check(not _menu(h).is_open(), "the east button did not back out")
	await h.tap_pad(JOY_BUTTON_START)
	await h.tap_pad(JOY_BUTTON_A)
	h.check(not _menu(h).is_open(), "the south button did not press Resume")
	h.check(not h.tree.paused, "still paused after pressing Resume")


func test_resuming_with_the_jump_button_does_not_jump(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	await h.tap_pad(JOY_BUTTON_START)
	await h.tap_pad(JOY_BUTTON_A)
	await h.steps(10)
	h.check(not h.tree.paused, "the south button did not resume")
	h.check(jumps[0] == 0, "resuming with the south button made the sailor jump")
	await h.tap_key(KEY_ESCAPE)
	await h.tap_key(KEY_SPACE)
	await h.steps(10)
	h.check(not h.tree.paused, "Space did not resume")
	h.check(jumps[0] == 0, "resuming with Space made the sailor jump")


func test_nothing_can_be_examined_while_paused(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(150, -2))
	var count := [0]
	h.fixture.get_node("World/Props/Lifeboat").interacted.connect(func(_id: StringName) -> void: count[0] += 1)
	await h.tap_action("pause")
	await h.tap_action("interact")
	h.check(count[0] == 0, "examined something while paused")
	h.check(not h.fixture.get_node("World/Hud/Caption").visible, "a caption appeared while paused")


func test_restart_checkpoint_returns_to_the_checkpoint_and_unpauses(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(500, -12))
	await h.tap_action("pause")
	await h.tap_action("ui_down")
	h.check(_focus(h) == _button(h, "RestartCheckpoint"), "focus is on %s" % _focus(h))
	await h.tap_action("ui_accept")
	h.check(not h.tree.paused, "still paused after restarting")
	h.check(not _menu(h).is_open(), "the menu stayed open after restarting")
	await h.steps(30)
	h.check_near(_player(h).global_position.x, 150.0, 1.0, "x after restarting")
	h.check(_player(h).is_on_floor(), "not on the floor after restarting")


func test_restart_checkpoint_uses_the_newest_checkpoint_repeatedly(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var session: Node = h.fixture
	await h.stand_at(player, Vector2(735, -2))
	h.check(session.get_session_beat() == 1, "the checkpoint did not move")
	var menu := _menu(h)
	for i in 3:
		await h.stand_at(_player(h), Vector2(1000, -30))
		menu.open()
		await h.steps(1)
		menu.restart_checkpoint()
		await h.steps(30)
		h.check_near(_player(h).global_position.x, 750.0, 1.0, "x after restart %d" % i)
		h.check(not h.tree.paused, "paused after restart %d" % i)


func test_back_closes_one_level_and_focus_returns(h) -> void:
	await _setup(h)
	await h.tap_action("pause")
	_button(h, "Settings").grab_focus()
	await h.tap_action("ui_accept")
	var settings: Control = h.fixture.get_node("PauseLayer/PauseMenu/Settings")
	h.check(settings.visible, "Settings did not open")
	h.check(not h.fixture.get_node("PauseLayer/PauseMenu/Center/Main").visible, "the main panel stayed visible under Settings")
	h.check(_focus(h) == settings.get_node("Center/Panel/Items/Music/Slider"), "focus in Settings is on %s" % _focus(h))
	await h.tap_key(KEY_ESCAPE)
	h.check(_menu(h).is_open(), "one Esc closed the whole menu")
	h.check(not settings.visible, "Esc did not close Settings")
	h.check(_focus(h) == _button(h, "Settings"), "focus returned to %s" % _focus(h))
	h.check(h.tree.paused, "the game unpaused while the menu was still open")


func test_quit_asks_first_with_cancel_focused_and_says_what_is_kept(h) -> void:
	await _setup(h)
	var menu := _menu(h)
	await h.tap_action("pause")
	_button(h, "Quit").grab_focus()
	await h.tap_action("ui_accept")
	var panel: Control = h.fixture.get_node("PauseLayer/PauseMenu/Center/Confirm")
	h.check(panel.visible, "no confirmation before quitting")
	var message: String = panel.get_node("Items/Message").text
	h.check(message.contains("Continue resumes from your last saved checkpoint"), "the message does not say what Continue will do: '%s'" % message)
	h.check(message.contains("not kept"), "the message implies everything is kept: '%s'" % message)
	h.check(_focus(h) == panel.get_node("Items/Buttons/Cancel"), "focus is on %s" % _focus(h))
	await h.tap_key(KEY_ESCAPE)
	h.check(not panel.visible and menu.is_open(), "Esc did not return to the menu")
	h.check(_focus(h) == _button(h, "Quit"), "focus returned to %s" % _focus(h))
	_button(h, "Quit").grab_focus()
	await h.tap_action("ui_accept")
	await h.tap_action("ui_accept")
	h.check(menu.is_open() and not panel.visible, "pressing the focused Cancel did not cancel")


func test_quit_to_desktop_exits_the_game(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	var output := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/quit_probe.gd"], output, true)
	h.check(code == 0, "the quit probe exited with %d" % code)
	h.check("PROBE confirm called" in output[0], "the probe did not reach quit: %s" % output[0])
	h.check(not "PROBE still running" in output[0], "the game kept running after quitting")


func test_controls_open_from_the_pause_menu_with_the_current_keys(h) -> void:
	await _setup(h)
	var menu := _menu(h)
	var panel: Control = menu.get_node("Center/Controls")
	var text: Label = panel.get_node("Items/Text")
	await h.tap_action("pause")
	_button(h, "Controls").grab_focus()
	await h.tap_action("ui_accept")
	h.check(panel.visible and not menu.get_node("Center/Main").visible, "Controls did not replace the main panel")
	h.check(_focus(h) == panel.get_node("Items/Back"), "focus is on %s" % _focus(h))
	for line in ["Keyboard", "Walk: A and D", "Jump: Space", "Examine: E", "Pause: Esc", "Enter or Space to confirm", "Esc for Back", "Xbox / PlayStation controller", "Jump: A / Cross", "Examine: X / Square"]:
		h.check(text.text.contains(line), "the text lacks '%s': %s" % [line, text.text])
	h.check(panel.get_node("Items/Title").text == "Controls", "the title reads '%s'" % panel.get_node("Items/Title").text)
	await h.tap_key(KEY_ESCAPE)
	h.check(menu.is_open() and not panel.visible, "Back did not close only Controls")
	h.check(_focus(h) == _button(h, "Controls"), "focus returned to %s" % _focus(h))
	h.check(h.tree.paused, "closing Controls unpaused the game")


func test_focus_comes_back_after_it_is_lost(h) -> void:
	await _setup(h)
	await h.tap_action("pause")
	_menu(h).get_viewport().gui_release_focus()
	h.check(_focus(h) == null, "the test did not lose focus")
	await h.tap_action("ui_down")
	h.check(_focus(h) == _button(h, "Resume"), "a press did not bring focus back: %s" % _focus(h))


func test_focus_lost_after_leaving_settings_comes_back_to_a_visible_button(h) -> void:
	await _setup(h)
	var menu := _menu(h)
	await h.tap_action("pause")
	menu.open_settings()
	await h.steps(1)
	await h.tap_key(KEY_ESCAPE)
	menu.get_viewport().gui_release_focus()
	await h.tap_key(KEY_DOWN)
	h.check(_focus(h) == _button(h, "Settings"), "focus came back to %s" % _focus(h))
	h.check(_focus(h) != null and _focus(h).is_visible_in_tree(), "the recovered button is not visible")


func test_focus_lost_in_the_quit_confirmation_stays_in_it(h) -> void:
	await _setup(h)
	var menu := _menu(h)
	await h.tap_action("pause")
	menu.ask_quit_to_desktop()
	await h.steps(1)
	var panel: Control = h.fixture.get_node("PauseLayer/PauseMenu/Center/Confirm")
	menu.get_viewport().gui_release_focus()
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	h.check(_focus(h) == panel.get_node("Items/Buttons/Cancel"), "focus came back to %s" % _focus(h))
	h.check(panel.visible, "recovering focus closed the confirmation")
	await h.tap_action("ui_accept")
	h.check(not panel.visible and menu.is_open(), "the recovered Cancel did not cancel")


## Measured on 4.7.2: clicking something that takes no focus leaves focus where it was.
func test_clicking_empty_space_keeps_focus_and_the_keyboard_working(h) -> void:
	await _setup(h)
	await h.tap_action("pause")
	var click_pressed := InputEventMouseButton.new()
	click_pressed.button_index = MOUSE_BUTTON_LEFT
	click_pressed.position = Vector2(5, 5)
	click_pressed.global_position = click_pressed.position
	click_pressed.pressed = true
	var click_released: InputEventMouseButton = click_pressed.duplicate()
	click_released.pressed = false
	await h.tap(click_pressed, click_released)
	h.check(_focus(h) == _button(h, "Resume"), "a click on empty space moved focus to %s" % _focus(h))
	h.check(_menu(h).is_open(), "a click on empty space closed the menu")
	await h.tap_key(KEY_DOWN)
	h.check(_focus(h) == _button(h, "RestartCheckpoint"), "the keyboard stopped working: %s" % _focus(h))


func test_every_button_is_connected(h) -> void:
	await _setup(h)
	var menu := _menu(h)
	for pair in [["Resume", menu.resume], ["RestartCheckpoint", menu.restart_checkpoint], ["Settings", menu.open_settings], ["Controls", menu.open_controls], ["QuitToMenu", menu.ask_quit_to_main_menu], ["Quit", menu.ask_quit_to_desktop]]:
		h.check(_button(h, pair[0]).pressed.is_connected(pair[1]), "%s is not connected" % pair[0])
	var buttons := "PauseLayer/PauseMenu/Center/Confirm/Items/Buttons/"
	h.check(h.fixture.get_node(buttons + "Cancel").pressed.is_connected(menu.cancel_confirm), "Cancel is not connected")
	h.check(h.fixture.get_node(buttons + "Ok").pressed.is_connected(menu.confirm), "Ok is not connected")
