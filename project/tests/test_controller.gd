extends RefCounted
## Tests of the controller mappings, labels and prompts. These inject events and name a controller, so they
## check the game's logic for each layout. They are not physical-device tests, and say nothing about a real
## Xbox or PlayStation controller, or about console platforms.

const GAME := "res://scenes/level/game.tscn"
const TITLE := "res://scenes/ui/title.tscn"
const XBOX := "Xbox Series Controller"
const PLAYSTATION := "PS5 Controller"
const OTHER := "Generic USB Joystick"
const SETTINGS_FILE := "settings.cfg"

## Which button is which, as named on each controller.
const LAYOUTS := {
	XBOX: {"prompt": "[X] Examine", "jump": "Jump: A\n", "examine": "Examine: X,", "pause": "Pause: Menu\n", "confirm": "A to confirm", "back": "B for Back", "heading": "Xbox controller", "cancel": "Esc or B cancels"},
	PLAYSTATION: {"prompt": "[Square] Examine", "jump": "Jump: Cross\n", "examine": "Examine: Square,", "pause": "Pause: Options\n", "confirm": "Cross to confirm", "back": "Circle for Back", "heading": "PlayStation controller", "cancel": "Esc or Circle cancels"},
	OTHER: {"prompt": "[Left face button] Examine", "jump": "Jump: bottom face button\n", "examine": "Examine: left face button,", "pause": "Pause: Start\n", "confirm": "bottom face button to confirm", "back": "right face button for Back", "heading": "Controller", "cancel": "Esc or right face button cancels"},
}


func _setup(h, controller_name: String = "") -> Node:
	h.use_controller(controller_name)
	await h.load_fixture(GAME)
	await h.landed_on_floor(_player(h))
	await h.steps(3)
	return h.fixture


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("World/Player")


func _menu(h) -> Control:
	return h.fixture.get_node("PauseLayer/PauseMenu")


func _prompt(h) -> Label:
	return h.fixture.get_node("World/Hud/Prompt")


func _caption(h) -> Label:
	return h.fixture.get_node("World/Hud/Caption")


func _controls_text(h) -> String:
	return _menu(h).get_node("Center/Controls/Items/Text").text


func _stick(h, x: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = x
	h.send(event)


## Checks the mapping data the labels depend on. Whether a real controller reports these buttons is a manual check.
func test_each_action_is_on_the_button_the_labels_name(h) -> void:
	var expected := {
		JOY_BUTTON_A: ["jump", "ui_accept"],
		JOY_BUTTON_X: ["interact"],
		JOY_BUTTON_B: ["ui_cancel"],
		JOY_BUTTON_START: ["pause"],
	}
	for button: JoyButton in expected:
		var event: InputEventJoypadButton = h.pad_event(button, true)
		for action in ["jump", "interact", "pause", "ui_accept", "ui_cancel"]:
			var should: bool = action in expected[button]
			h.check(InputMap.event_is_action(event, action) == should, "button %d and %s: expected %s" % [button, action, should])
	h.check(not InputMap.event_is_action(h.pad_event(JOY_BUTTON_Y, true), "interact"), "the north button is Interact")
	for pair in [[JOY_BUTTON_DPAD_LEFT, "move_left"], [JOY_BUTTON_DPAD_RIGHT, "move_right"], [JOY_BUTTON_DPAD_UP, "ui_up"], [JOY_BUTTON_DPAD_DOWN, "ui_down"], [JOY_BUTTON_DPAD_LEFT, "ui_left"], [JOY_BUTTON_DPAD_RIGHT, "ui_right"]]:
		h.check(InputMap.event_is_action(h.pad_event(pair[0], true), pair[1]), "D-pad button %d is not %s" % [pair[0], pair[1]])


func test_the_prompt_names_the_button_for_each_layout_and_returns_to_the_key(h) -> void:
	for controller_name: String in LAYOUTS:
		await _setup(h, controller_name)
		h.check(_prompt(h).text == "[E] Examine", "%s: before any button the prompt reads '%s'" % [controller_name, _prompt(h).text])
		await h.tap_pad(JOY_BUTTON_Y)
		h.check(_prompt(h).text == LAYOUTS[controller_name]["prompt"], "%s: the prompt reads '%s'" % [controller_name, _prompt(h).text])
		await h.tap_key(KEY_T)
		h.check(_prompt(h).text == "[E] Examine", "%s: after a key the prompt reads '%s'" % [controller_name, _prompt(h).text])
		await h.unload_fixture()


func test_playstation_never_shows_an_xbox_letter(h) -> void:
	await _setup(h, PLAYSTATION)
	await h.tap_pad(JOY_BUTTON_Y)
	h.check(_prompt(h).text == "[Square] Examine", "the prompt reads '%s'" % _prompt(h).text)
	_menu(h).open()
	_menu(h).open_controls()
	var text := _controls_text(h)
	var pad_part := text.substr(text.find("PlayStation controller"))
	for wrong in ["Jump: A", "Jump: X", "Examine: X", "Xbox", "B for Back"]:
		h.check(not pad_part.contains(wrong), "the PlayStation text contains '%s': %s" % [wrong, pad_part])


func test_a_stick_resting_near_centre_does_not_change_the_device(h) -> void:
	await _setup(h, XBOX)
	_stick(h, 0.2)
	await h.steps(2)
	h.check(_prompt(h).text == "[E] Examine", "a small stick movement relabelled the prompt: '%s'" % _prompt(h).text)
	_stick(h, 0.9)
	await h.steps(2)
	h.check(_prompt(h).text == "[X] Examine", "a real stick movement did not: '%s'" % _prompt(h).text)
	_stick(h, 0.0)


func test_only_a_real_action_changes_the_device(h) -> void:
	await _setup(h, XBOX)
	var key_released: InputEventKey = h.key_event(KEY_T, false)
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_LEFT
	trigger.axis_value = -1.0
	h.send(trigger)
	h.send(h.pad_event(JOY_BUTTON_Y, false))
	await h.steps(2)
	h.check(_prompt(h).text == "[E] Examine", "a resting trigger or a button release relabelled the prompt: '%s'" % _prompt(h).text)
	await h.tap_pad(JOY_BUTTON_Y)
	h.send(key_released)
	await h.steps(2)
	h.check(_prompt(h).text == "[X] Examine", "a key release relabelled the prompt: '%s'" % _prompt(h).text)


func test_the_longest_prompt_fits_on_screen(h) -> void:
	await _setup(h, OTHER)
	await h.tap_pad(JOY_BUTTON_Y)
	await h.steps(3)
	var prompt := _prompt(h)
	h.check(prompt.text == "[Left face button] Examine", "the prompt reads '%s'" % prompt.text)
	h.check(prompt.get_viewport_rect().encloses(prompt.get_global_rect()), "the prompt is clipped: %s" % prompt.get_global_rect())
	h.check(prompt.get_theme_font("font").get_string_size(prompt.text, HORIZONTAL_ALIGNMENT_LEFT, -1, prompt.get_theme_font_size("font_size")).x <= prompt.size.x, "the prompt text overflows its label")


func test_the_left_stick_moves_through_the_menu(h) -> void:
	await _setup(h, XBOX)
	var menu := _menu(h)
	await h.tap_pad(JOY_BUTTON_START)
	var viewport := menu.get_viewport()
	h.check(viewport.gui_get_focus_owner() == menu.get_node("Center/Main/Items/Resume"), "Resume is not focused")
	var down := InputEventJoypadMotion.new()
	down.axis = JOY_AXIS_LEFT_Y
	down.axis_value = 1.0
	await h.send_between_ticks(down)
	h.check(viewport.gui_get_focus_owner() == menu.get_node("Center/Main/Items/RestartCheckpoint"), "the stick moved focus to %s" % viewport.gui_get_focus_owner())
	var rest := InputEventJoypadMotion.new()
	rest.axis = JOY_AXIS_LEFT_Y
	rest.axis_value = 0.0
	await h.send_between_ticks(rest)


func test_arrow_keys_still_walk_and_navigate_after_rebinding(h) -> void:
	await _setup(h)
	_menu(h).open()
	_menu(h).open_settings()
	await h.steps(1)
	_menu(h).get_node("Settings").begin_capture(0)
	await h.tap_key(KEY_J)
	await h.tap_key(KEY_ESCAPE)
	await h.tap_key(KEY_ESCAPE)
	await h.steps(2)
	h.check(InputMap.event_is_action(h.key_event(KEY_LEFT, true), "move_left"), "the Left arrow no longer walks left, though Controls says it does")
	h.check(InputMap.event_is_action(h.key_event(KEY_J, true), "move_left"), "J was not bound")
	_menu(h).open()
	_menu(h).open_controls()
	h.check(_controls_text(h).contains("Walk: J and D, or the Left and Right arrows"), "Controls reads: %s" % _controls_text(h))


func test_a_controller_can_work_the_main_menu(h) -> void:
	h.use_controller(PLAYSTATION)
	await h.load_main_fixture(TITLE)
	await h.steps(3)
	var title: Node = h.fixture
	var viewport: Viewport = title.get_viewport()
	var items := "Center/Main/Panel/Items/"
	h.check(viewport.gui_get_focus_owner() == title.get_node(items + "NewGame"), "New Game is not focused")
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	h.check(viewport.gui_get_focus_owner() == title.get_node(items + "Settings"), "with no save, down reached %s" % viewport.gui_get_focus_owner())
	await h.tap_pad(JOY_BUTTON_A)
	h.check(title.get_node("Settings").visible, "Cross did not open Settings")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(not title.get_node("Settings").visible, "Circle did not leave Settings")
	h.check(viewport.gui_get_focus_owner() == title.get_node(items + "Settings"), "focus went to %s" % viewport.gui_get_focus_owner())
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_A)
	var text: String = title.get_node("Center/Controls/Items/Text").text
	h.check(title.get_node("Center/Controls").visible, "Cross did not open Controls")
	h.check(text.contains("PlayStation controller") and text.contains("Examine: Square,") and text.contains("Circle for Back"), "Controls reads: %s" % text)
	await h.tap_pad(JOY_BUTTON_B)
	h.check(viewport.gui_get_focus_owner() == title.get_node(items + "Controls"), "focus went to %s" % viewport.gui_get_focus_owner())
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_A)
	h.check(title.get_node("Center/Credits").visible, "Cross did not open Credits")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(title.get_node("Center/Main").visible, "Circle did not leave Credits")


func test_a_rebound_key_comes_back_after_using_a_controller(h) -> void:
	await _setup(h, XBOX)
	_menu(h).open()
	_menu(h).open_settings()
	await h.steps(1)
	_menu(h).get_node("Settings").begin_capture(3)
	await h.tap_key(KEY_J)
	await h.tap_key(KEY_ESCAPE)
	await h.tap_key(KEY_ESCAPE)
	await h.steps(2)
	h.check(_prompt(h).text == "[J] Examine", "after rebinding the prompt reads '%s'" % _prompt(h).text)
	await h.tap_pad(JOY_BUTTON_Y)
	h.check(_prompt(h).text == "[X] Examine", "the pad prompt reads '%s'" % _prompt(h).text)
	await h.tap_key(KEY_T)
	h.check(_prompt(h).text == "[J] Examine", "back on the keyboard the prompt reads '%s'" % _prompt(h).text)
	var text: String = h.read_storage_file(SETTINGS_FILE)
	h.check(text.contains("key_interact=%d" % KEY_J), "the rebound key was not saved")


## The reported defect, with a controller: stick to walk, west button to examine, no teleports.
func test_examine_works_with_a_controller_at_the_boat_and_the_fish(h) -> void:
	for controller_name: String in [XBOX, PLAYSTATION]:
		await _setup(h, controller_name)
		var boat: Node = h.fixture.get_node("World/Props/Lifeboat")
		var fish: Node = h.fixture.get_node("World/Props/FishNearRock")
		await h.tap_pad(JOY_BUTTON_X)
		h.check(_prompt(h).text == LAYOUTS[controller_name]["prompt"], "%s: at the boat the prompt reads '%s'" % [controller_name, _prompt(h).text])
		h.check(_caption(h).visible and _caption(h).text == boat.caption, "%s: west at the boat shows '%s'" % [controller_name, _caption(h).text])

		_stick(h, 1.0)
		await h.steps(22)
		_stick(h, 0.0)
		await h.steps(5)
		h.check(_prompt(h).text == LAYOUTS[controller_name]["prompt"], "%s: at the fish the prompt reads '%s'" % [controller_name, _prompt(h).text])
		await h.wait_until(fish.is_available, 30, "the fish to be available")
		await h.tap_pad(JOY_BUTTON_X)
		h.check(_caption(h).visible and _caption(h).text == fish.caption, "%s: west at the fish shows '%s'" % [controller_name, _caption(h).text])
		await h.unload_fixture()


func test_no_other_button_examines(h) -> void:
	await _setup(h, XBOX)
	for button in [JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_BACK]:
		await h.tap_pad(button)
	h.check(not _caption(h).visible, "a button other than west examined")


func test_controls_explain_the_controller_in_both_menus(h) -> void:
	for controller_name: String in LAYOUTS:
		await _setup(h, controller_name)
		await h.tap_pad(JOY_BUTTON_START)
		_menu(h).open_controls()
		var text := _controls_text(h)
		h.check(text.contains("Keyboard"), "%s: the keyboard is missing: %s" % [controller_name, text])
		for key: String in ["heading", "jump", "examine", "pause", "confirm", "back"]:
			h.check(text.contains(LAYOUTS[controller_name][key]), "%s: lacks '%s': %s" % [controller_name, LAYOUTS[controller_name][key], text])
		for line in ["Walk: left stick or D-pad", "left stick or D-pad to move", "Controller buttons are fixed"]:
			h.check(text.contains(line), "%s: lacks '%s'" % [controller_name, line])
		await h.unload_fixture()

		h.use_controller(controller_name)
		await h.load_main_fixture(TITLE)
		await h.steps(3)
		await h.tap_pad(JOY_BUTTON_Y)
		h.fixture.open_controls()
		var title_text: String = h.fixture.get_node("Center/Controls/Items/Text").text
		for key: String in ["heading", "jump", "examine", "pause", "confirm", "back"]:
			h.check(title_text.contains(LAYOUTS[controller_name][key]), "%s on the main menu: lacks '%s': %s" % [controller_name, LAYOUTS[controller_name][key], title_text])
		await h.unload_fixture()


func test_controls_change_when_the_device_does_while_they_are_open(h) -> void:
	await _setup(h, XBOX)
	_menu(h).open()
	_menu(h).open_controls()
	h.use_controller(PLAYSTATION)
	await h.tap_pad(JOY_BUTTON_Y)
	h.check(_controls_text(h).contains("PlayStation controller"), "the open screen did not follow the device: %s" % _controls_text(h))


func test_the_controls_screens_fit_on_every_layout(h) -> void:
	for controller_name: String in ["", XBOX, PLAYSTATION, OTHER]:
		await _setup(h, controller_name)
		_menu(h).open()
		_menu(h).open_controls()
		await h.steps(3)
		var panel: Control = _menu(h).get_node("Center/Controls")
		h.check(_menu(h).get_viewport_rect().encloses(panel.get_global_rect()), "'%s': the panel is clipped: %s" % [controller_name, panel.get_global_rect()])
		await h.unload_fixture()


func test_a_disconnected_controller_hands_back_to_the_keyboard(h) -> void:
	await _setup(h, XBOX)
	await h.tap_pad(JOY_BUTTON_Y)
	h.check(_prompt(h).text == "[X] Examine", "the prompt reads '%s'" % _prompt(h).text)
	Input.joy_connection_changed.emit(0, false)
	await h.steps(2)
	h.check(_prompt(h).text == "[E] Examine", "after disconnecting the prompt reads '%s'" % _prompt(h).text)
	h.check(not h.tree.paused, "disconnecting paused the game")

	# Reconnecting changes nothing until the controller is pressed.
	Input.joy_connection_changed.emit(0, true)
	await h.steps(2)
	h.check(_prompt(h).text == "[E] Examine", "reconnecting relabelled the prompt: '%s'" % _prompt(h).text)
	await h.tap_pad(JOY_BUTTON_Y)
	h.check(_prompt(h).text == "[X] Examine", "after reconnecting and pressing the prompt reads '%s'" % _prompt(h).text)
	await h.tap_pad(JOY_BUTTON_X)
	h.check(_caption(h).visible, "the reconnected controller cannot examine")


func test_another_controller_disconnecting_changes_nothing(h) -> void:
	await _setup(h, XBOX)
	await h.tap_pad(JOY_BUTTON_Y)
	Input.joy_connection_changed.emit(3, false)
	await h.steps(2)
	h.check(_prompt(h).text == "[X] Examine", "another device's disconnection relabelled the prompt: '%s'" % _prompt(h).text)


func test_a_disconnection_while_paused_keeps_the_menu_working(h) -> void:
	await _setup(h, XBOX)
	await h.tap_pad(JOY_BUTTON_START)
	_menu(h).open_controls()
	Input.joy_connection_changed.emit(0, false)
	await h.steps(2)
	h.check(_menu(h).is_open() and h.tree.paused, "the menu closed")
	h.check(_menu(h).get_viewport().gui_get_focus_owner() != null, "focus was lost")
	await h.tap_key(KEY_ESCAPE)
	await h.tap_key(KEY_ESCAPE)
	h.check(not _menu(h).is_open(), "the keyboard cannot leave the menu")
	h.check(_prompt(h).text == "[E] Examine", "the prompt reads '%s'" % _prompt(h).text)


func test_the_device_survives_restarting_and_new_worlds_are_labelled_at_once(h) -> void:
	await _setup(h, PLAYSTATION)
	await h.tap_pad(JOY_BUTTON_START)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_A)
	await h.steps(3)
	h.check(not h.tree.paused, "still paused after restarting")
	h.check(_prompt(h).text == "[Square] Examine", "after restarting the prompt reads '%s'" % _prompt(h).text)


func test_the_device_carries_through_the_main_menu_new_game_and_back(h) -> void:
	h.use_controller(XBOX)
	await h.load_main_fixture(TITLE)
	await h.steps(3)
	await h.tap_pad(JOY_BUTTON_A)
	var session: Node = await h.wait_for_scene("GameSession")
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	var text: String = menu.get_node("Center/Controls/Items/Text").text
	h.check(text.contains("Xbox controller") and text.contains("Jump: A"), "the introduction on a controller reads: %s" % text)
	h.check(not text.contains("Keyboard"), "the short introduction lists the keyboard too: %s" % text)
	await h.tap_pad(JOY_BUTTON_A)
	await h.steps(3)
	h.check(session.get_node("World/Hud/Prompt").text == "[X] Examine", "after Begin the prompt reads '%s'" % session.get_node("World/Hud/Prompt").text)

	await h.tap_pad(JOY_BUTTON_START)
	menu.ask_quit_to_main_menu()
	menu.confirm()
	var title: Node = await h.wait_for_scene("MenuController")
	title.open_controls()
	h.check(title.get_node("Center/Controls/Items/Text").text.contains("Xbox controller"), "the main menu forgot the controller")


func test_a_controller_can_work_every_level_of_the_pause_menu(h) -> void:
	await _setup(h, XBOX)
	var menu := _menu(h)
	await h.tap_pad(JOY_BUTTON_START)
	h.check(menu.is_open(), "Menu did not pause")
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_A)
	var settings: Control = menu.get_node("Settings")
	h.check(settings.visible, "A did not open Settings")
	h.check(menu.get_viewport().gui_get_focus_owner() != null and menu.get_viewport().gui_get_focus_owner().is_visible_in_tree(), "no visible focus in Settings")

	# A key capture says which button cancels it, and that button does.
	settings.begin_capture(2)
	h.check(menu.get_node("Settings/Center/Panel/Items/Message").text.contains(LAYOUTS[XBOX]["cancel"]), "the capture reads '%s'" % menu.get_node("Settings/Center/Panel/Items/Message").text)
	await h.tap_pad(JOY_BUTTON_B)
	h.check(not settings.is_capturing() and settings.visible, "B did not cancel just the capture")

	await h.tap_pad(JOY_BUTTON_B)
	h.check(menu.is_open() and not settings.visible, "B did not leave Settings")
	await h.tap_pad(JOY_BUTTON_DPAD_DOWN)
	await h.tap_pad(JOY_BUTTON_A)
	h.check(menu.get_node("Center/Controls").visible, "A did not open Controls")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(menu.get_node("Center/Main").visible, "B did not leave Controls")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(not menu.is_open() and not h.tree.paused, "B did not resume")


func test_resuming_with_a_controller_neither_jumps_nor_examines(h) -> void:
	await _setup(h, XBOX)
	var jumps := [0]
	_player(h).jumped.connect(func() -> void: jumps[0] += 1)
	var examined := [0]
	h.fixture.get_node("World/Player/Interactor").interacted.connect(func(_target: Object) -> void: examined[0] += 1)

	# A confirms Resume, and is also Jump.
	await h.tap_pad(JOY_BUTTON_START)
	await h.tap_pad(JOY_BUTTON_A)
	await h.steps(10)
	h.check(not h.tree.paused, "A did not resume")
	h.check(jumps[0] == 0, "confirming with A jumped")

	# Menu closes what it opened.
	await h.tap_pad(JOY_BUTTON_START)
	h.check(_menu(h).is_open(), "Menu did not pause")
	await h.tap_pad(JOY_BUTTON_START)
	await h.steps(10)
	h.check(not h.tree.paused, "Menu did not resume")
	h.check(jumps[0] == 0 and examined[0] == 0, "resuming with Menu acted on the world")

	# X does nothing in the menu, whenever it is released.
	await h.tap_pad(JOY_BUTTON_START)
	await h.tap_pad(JOY_BUTTON_X)
	h.check(examined[0] == 0, "X examined through the menu")
	h.send(h.pad_event(JOY_BUTTON_X, true))
	await h.steps(1)
	await h.tap_pad(JOY_BUTTON_B)
	h.send(h.pad_event(JOY_BUTTON_X, false))
	await h.steps(10)
	h.check(not h.tree.paused, "B did not resume")
	h.check(examined[0] == 0, "X held across resuming examined")
	h.check(not _caption(h).visible, "a caption appeared")


func test_beginning_with_a_controller_does_not_jump(h) -> void:
	h.use_controller(XBOX)
	await h.load_main_fixture(TITLE)
	await h.steps(3)
	await h.tap_pad(JOY_BUTTON_A)
	var session: Node = await h.wait_for_scene("GameSession")
	var player: CharacterBody2D = session.get_node("World/Player")
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	await h.tap_pad(JOY_BUTTON_A)
	await h.steps(10)
	h.check(not h.tree.paused, "A did not begin play")
	h.check(jumps[0] == 0, "beginning with A jumped")
