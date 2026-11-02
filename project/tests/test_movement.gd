extends RefCounted
## Movement integration tests against the real PlayerController and Godot physics.

const ARENA := "res://tests/fixtures/movement_arena.tscn"
const FLOOR_Y := 0.0

## Far enough above the floor that the fall outlasts jump_buffer_time.
const HIGH_AIR := Vector2(300, -120)


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(ARENA)
	return h.fixture.get_node("Player")


## The contract every other test relies on. physics_frame fires before the
## player's step and the probe fires after it, within the same tick.
func test_probe_observes_after_player_step(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	Input.action_press("move_right")
	await h.steps(30)
	var before_step := []
	var after_step := []
	var record_before := func() -> void: before_step.append([Engine.get_physics_frames(), player.global_position.x])
	var record_after := func(_frame: int) -> void: after_step.append([Engine.get_physics_frames(), player.global_position.x])
	h.tree.physics_frame.connect(record_before)
	h.probe.stepped.connect(record_after)
	await h.steps(10)
	h.tree.physics_frame.disconnect(record_before)
	h.probe.stepped.disconnect(record_after)
	h.check(before_step.size() >= 8, "physics_frame was not observed")
	var compared := 0
	for before in before_step:
		for after in after_step:
			if after[0] == before[0]:
				compared += 1
				h.check(after[1] > before[1] + 0.5, "probe at tick %d did not see that tick's movement: before=%.3f after=%.3f" % [before[0], before[1], after[1]])
	h.check(compared >= 8, "too few ticks observed by both signals: %d" % compared)


func test_physics_tick_is_fixed(h) -> void:
	await _setup(h)
	h.check(Engine.physics_ticks_per_second == 60, "physics tick rate is %d" % Engine.physics_ticks_per_second)
	var start := Engine.get_physics_frames()
	await h.steps(20)
	h.check(Engine.get_physics_frames() - start == 20, "one probe step must equal one physics tick")


func test_a_lands_on_floor_after_spawn(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var landed := [0]
	player.landed.connect(func() -> void: landed[0] += 1)
	h.check(await h.wait_until(player.is_on_floor, 60, "landing within 60 steps"), "did not land within 60 steps")
	await h.steps(5)
	h.check_near(player.global_position.y, FLOOR_Y, 2.0, "resting y")
	h.check_near(player.velocity.y, 0.0, 1.0, "resting vertical velocity")
	h.check(landed[0] == 1, "landed fired %d times" % landed[0])


func test_b_walks_right_and_left(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var start_x := player.global_position.x
	Input.action_press("move_right")
	await h.steps(60)
	h.check(player.global_position.x - start_x > 50.0, "moved only %.1f px in 60 steps" % (player.global_position.x - start_x))
	h.check_near(player.velocity.x, player.walk_speed, player.walk_speed * 0.01, "speed at cap")
	h.check(player.get_facing() == 1, "should face right")
	Input.action_release("move_right")
	await h.wait_until(func() -> bool: return is_zero_approx(player.velocity.x), 30, "stopping")
	var stopped_x := player.global_position.x
	Input.action_press("move_left")
	await h.steps(60)
	h.check(stopped_x - player.global_position.x > 50.0, "did not walk back left")
	h.check(player.get_facing() == -1, "should face left")


func test_c_jump_leaves_floor_and_lands(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var jumped := [0]
	var landed := [0]
	player.jumped.connect(func() -> void: jumped[0] += 1)
	player.landed.connect(func() -> void: landed[0] += 1)
	var floor_y := player.global_position.y
	Input.action_press("jump")
	await h.wait_until(func() -> bool: return not player.is_on_floor(), 5, "leaving the floor")
	var peak := floor_y
	for i in 90:
		await h.steps(1)
		peak = minf(peak, player.global_position.y)
		if player.is_on_floor():
			break
	Input.action_release("jump")
	h.check(player.is_on_floor(), "did not land within 90 steps")
	h.check(jumped[0] == 1, "jumped fired %d times" % jumped[0])
	h.check(landed[0] == 1, "landed fired %d times" % landed[0])
	h.check(floor_y - peak > 20.0, "jump height only %.1f px" % (floor_y - peak))


func test_c_short_press_jumps_lower_than_held(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var floor_y := player.global_position.y
	Input.action_press("jump")
	await h.steps(3)
	Input.action_release("jump")
	var short_peak := floor_y
	for i in 90:
		await h.steps(1)
		short_peak = minf(short_peak, player.global_position.y)
		if player.is_on_floor():
			break
	h.check(floor_y - short_peak < 18.0, "short press rose %.1f px" % (floor_y - short_peak))


func test_d_cannot_pass_walls(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(960, -2))
	Input.action_press("move_right")
	await h.steps(120)
	var body_half_width := 6.0
	h.check_near(player.global_position.x, 1000.0 - body_half_width, 2.0, "x against the right wall")
	h.check_near(player.velocity.x, 0.0, player.walk_speed, "wall limits velocity")
	Input.action_release("move_right")
	player.teleport(Vector2(40, -2))
	Input.action_press("move_left")
	await h.steps(120)
	h.check_near(player.global_position.x, body_half_width, 2.0, "x against the left wall")


func test_ceiling_stops_upward_velocity(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(700, -2))
	await h.landed_on_floor(player)
	Input.action_press("jump")
	var lowest_head_room := INF
	var was_rising_after_contact := false
	for i in 60:
		await h.steps(1)
		var player_top: float = player.global_position.y - 24.0
		lowest_head_room = minf(lowest_head_room, player_top - (-32.0))
		if player.is_on_ceiling() and player.velocity.y < -1.0:
			was_rising_after_contact = true
		if player.is_on_floor() and i > 5:
			break
	h.check(lowest_head_room > -2.0, "player went through the ceiling by %.1f px" % -lowest_head_room)
	h.check(lowest_head_room < 2.0, "the jump never reached the ceiling; head room %.1f px" % lowest_head_room)
	h.check(not was_rising_after_contact, "velocity stayed upward after hitting the ceiling")


func test_e_disabled_control_ignores_input(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var jumped := [0]
	player.jumped.connect(func() -> void: jumped[0] += 1)
	player.set_control_enabled(false)
	var start := player.global_position
	Input.action_press("move_right")
	Input.action_press("jump")
	await h.steps(30)
	h.check_near(player.global_position.x, start.x, 0.5, "x with control disabled")
	h.check_near(player.global_position.y, start.y, 0.5, "y with control disabled")
	h.check(jumped[0] == 0, "jumped while control was disabled")
	h.release_all_actions()
	player.set_control_enabled(true)
	Input.action_press("move_right")
	await h.steps(30)
	h.check(player.global_position.x - start.x > 10.0, "control did not return")


func test_e_gravity_applies_while_control_disabled(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	player.set_control_enabled(false)
	h.check(await h.wait_until(player.is_on_floor, 60, "falling with control disabled"), "gravity did not apply")


func test_e_buffered_jump_does_not_fire_after_lock(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(300, -3))
	Input.action_press("jump")
	await h.steps(1)
	player.set_control_enabled(false)
	var jumped := [0]
	player.jumped.connect(func() -> void: jumped[0] += 1)
	await h.steps(20)
	h.check(player.is_on_floor(), "should have landed")
	h.check(jumped[0] == 0, "a jump buffered before the lock fired during it")


## Roadmap M1 7f. Begins grounded, so is_on_floor() still holds a stale true when jump is read.
func test_f_teleport_invalidates_stale_floor_contact(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	await h.steps(5)
	h.check(player.is_on_floor(), "precondition: grounded before the teleport")
	var jumped := [0]
	var landed := [0]
	player.jumped.connect(func() -> void: jumped[0] += 1)
	player.landed.connect(func() -> void: landed[0] += 1)

	player.teleport(HIGH_AIR)
	h.check(player.is_on_floor(), "precondition: is_on_floor() must still be stale immediately after teleport")
	Input.action_press("jump")
	await h.steps(1)
	Input.action_release("jump")
	h.check(jumped[0] == 0, "stale contact granted a jump")
	h.check(player.velocity.y >= 0.0, "moving up after teleport: vy=%.1f" % player.velocity.y)
	h.check(landed[0] == 0, "false landing on the first step")

	await h.steps(10)
	h.check(jumped[0] == 0, "coyote or buffered jump fired in mid-air")
	h.check(landed[0] == 0, "false landing in mid-air")

	await h.landed_on_floor(player)
	await h.steps(5)
	h.check(jumped[0] == 0, "the expired buffer fired on landing")
	h.check(landed[0] == 1, "landed fired %d times on genuine contact" % landed[0])

	Input.action_press("jump")
	await h.steps(2)
	h.check(jumped[0] == 1, "normal jump did not work after the real landing")
	h.check(player.velocity.y < 0.0, "not rising after the normal jump")


## Roadmap M1 7g. A press just before genuine contact is a valid buffered jump.
func test_g_buffered_jump_survives_teleport(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	await h.steps(5)
	var jumped := [0]
	var landed := [0]
	player.jumped.connect(func() -> void: jumped[0] += 1)
	player.landed.connect(func() -> void: landed[0] += 1)

	player.teleport(Vector2(300, -2))
	Input.action_press("jump")
	await h.wait_until(func() -> bool: return jumped[0] > 0, 8, "the buffered jump on landing")
	h.check(jumped[0] == 1, "buffered jump fired %d times" % jumped[0])
	h.check(landed[0] == 1, "expected the genuine landing before the jump, got %d" % landed[0])
	h.check(player.velocity.y < 0.0, "not rising from the buffered jump")


func test_teleport_clears_velocity(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	Input.action_press("move_right")
	await h.steps(30)
	Input.action_release("move_right")
	player.teleport(Vector2(400, -2))
	h.check_near(player.velocity.x, 0.0, 0.001, "x velocity after teleport")
	h.check_near(player.velocity.y, 0.0, 0.001, "y velocity after teleport")
	h.check_near(player.global_position.x, 400.0, 0.001, "x position after teleport")
