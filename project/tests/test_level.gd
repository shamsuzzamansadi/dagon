extends RefCounted
## Tests of the Act I greybox and the input map.

const LEVEL := "res://scenes/level/level.tscn"
const LIMIT_RIGHT := 1400
const WALL_LEFT := 24.0
const WALL_RIGHT := 1376.0


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(LEVEL)
	return h.fixture.get_node("Player")


## Walks in one direction, jumping when blocked, as a player would.
func _traverse(h, player: CharacterBody2D, action: String, reached: Callable, max_steps: int) -> bool:
	Input.action_press(action)
	var last_x := player.global_position.x
	var stalled := 0
	for i in max_steps:
		await h.steps(1)
		if reached.call():
			Input.action_release(action)
			return true
		stalled = stalled + 1 if absf(player.global_position.x - last_x) < 0.2 else 0
		last_x = player.global_position.x
		if stalled >= 6 and player.is_on_floor():
			Input.action_press("jump")
			await h.steps(12)
			Input.action_release("jump")
			stalled = 0
	Input.action_release(action)
	return false


func test_level_loads_with_player_and_camera(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	h.check(player != null and player.is_class("PlayerController"), "no PlayerController in the level")
	var camera: Camera2D = h.fixture.get_node("CameraRig")
	h.check(camera != null and camera.is_class("CameraRig"), "no CameraRig in the level")
	h.check(camera.is_current(), "CameraRig is not the current camera")
	h.check(await h.wait_until(player.is_on_floor, 60, "landing in the level"), "did not land in the level")


func test_act1_can_be_crossed_in_both_directions(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var reached_end: bool = await _traverse(h, player, "move_right", func() -> bool: return player.global_position.x > WALL_RIGHT - 20.0, 1800)
	h.check(reached_end, "stuck going right at x=%.1f" % player.global_position.x)
	var reached_start: bool = await _traverse(h, player, "move_left", func() -> bool: return player.global_position.x < WALL_LEFT + 20.0, 1800)
	h.check(reached_start, "stuck going left at x=%.1f" % player.global_position.x)


func test_rock_requires_a_jump(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(170, -2))
	Input.action_press("move_right")
	await h.steps(120)
	h.check(player.global_position.x < 200.0, "walked through the rock at x=%.1f" % player.global_position.x)
	Input.action_press("jump")
	await h.steps(60)
	h.check(player.global_position.x > 200.0, "could not jump onto the rock")


func test_slope_keeps_contact_going_down(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(490, -12))
	await h.landed_on_floor(player)
	Input.action_press("move_right")
	var airborne_steps := 0
	while player.global_position.x < 535.0 and airborne_steps < 60:
		await h.steps(1)
		if not player.is_on_floor():
			airborne_steps += 1
	h.check(airborne_steps <= 2, "lost floor contact for %d steps walking down the slope" % airborne_steps)


func test_camera_follows_the_player(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var camera: Camera2D = h.fixture.get_node("CameraRig")
	await h.landed_on_floor(player)
	player.teleport(Vector2(1000, -2))
	await h.landed_on_floor(player)
	await h.wait_until(func() -> bool: return absf(camera.get_screen_center_position().x - player.global_position.x) < 40.0, 240, "the camera to catch up")
	h.check(absf(camera.get_screen_center_position().x - player.global_position.x) < 40.0, "camera center %.1f is far from player %.1f" % [camera.get_screen_center_position().x, player.global_position.x])


func test_camera_stays_inside_level_limits(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var camera: Camera2D = h.fixture.get_node("CameraRig")
	await h.landed_on_floor(player)
	var half_width: float = h.fixture.get_viewport_rect().size.x / 2.0
	h.check_near(half_width, 240.0, 0.5, "half viewport width")

	player.teleport(Vector2(WALL_LEFT + 10.0, -2))
	await h.steps(240)
	h.check_near(camera.get_screen_center_position().x, half_width, 2.0, "camera center at the left limit")

	player.teleport(Vector2(WALL_RIGHT - 10.0, -2))
	await h.steps(240)
	h.check_near(camera.get_screen_center_position().x, LIMIT_RIGHT - half_width, 2.0, "camera center at the right limit")


func _key(physical_keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	event.pressed = pressed
	return event


func _pad_button(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _pad_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


## Checks the mapping data. Physical keyboards and controllers are a manual check.
func test_input_map_has_keyboard_and_gamepad_events(h) -> void:
	var expected := {
		"move_left": [_key(KEY_A, true), _key(KEY_LEFT, true), _pad_button(JOY_BUTTON_DPAD_LEFT, true), _pad_axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D, true), _key(KEY_RIGHT, true), _pad_button(JOY_BUTTON_DPAD_RIGHT, true), _pad_axis(JOY_AXIS_LEFT_X, 1.0)],
		"jump": [_key(KEY_SPACE, true), _pad_button(JOY_BUTTON_A, true)],
	}
	for action: String in expected:
		h.check(InputMap.has_action(action), "missing action %s" % action)
		for event: InputEvent in expected[action]:
			h.check(InputMap.event_is_action(event, action), "%s does not trigger %s" % [event.as_text(), action])


## Sends events through Input instead of action_press, so the mapping is what moves the player.
func test_key_and_pad_events_drive_the_player(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)

	var start_x := player.global_position.x
	Input.parse_input_event(_key(KEY_D, true))
	Input.flush_buffered_events()
	await h.steps(30)
	Input.parse_input_event(_key(KEY_D, false))
	Input.flush_buffered_events()
	h.check(player.global_position.x - start_x > 15.0, "D key did not move the player")

	await h.steps(20)
	start_x = player.global_position.x
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_X, -1.0))
	Input.flush_buffered_events()
	await h.steps(30)
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_X, 0.0))
	Input.flush_buffered_events()
	h.check(start_x - player.global_position.x > 15.0, "left stick did not move the player")

	await h.steps(20)
	var jumped := [0]
	player.jumped.connect(func() -> void: jumped[0] += 1)
	Input.parse_input_event(_pad_button(JOY_BUTTON_A, true))
	Input.flush_buffered_events()
	await h.steps(3)
	Input.parse_input_event(_pad_button(JOY_BUTTON_A, false))
	Input.flush_buffered_events()
	h.check(jumped[0] == 1, "south button did not jump")
