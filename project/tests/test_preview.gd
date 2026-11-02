extends RefCounted
## Tests of the Shore art preview: the sailor's animation, the camera's pixel lock, and that the
## art sits on the same movement and collision as the greybox.

const PREVIEW := "res://scenes/preview/shore_preview.tscn"
const LEVEL := "res://scenes/level/level.tscn"


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(PREVIEW)
	return h.fixture.get_node("Player")


func _sprite(player: Node) -> AnimatedSprite2D:
	return player.get_node("Visual/Sailor")


func test_preview_shows_the_sailor_not_the_placeholder(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	h.check(player.get_node("Visual/Silhouette").visible == false, "greybox silhouette is visible")
	h.check(player.get_node("Visual/LanternMarker").visible == false, "greybox lantern marker is visible")
	h.check(_sprite(player).visible, "sailor sprite is hidden")


func test_preview_keeps_movement_tuning_and_body(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var greybox: Node = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	for property in ["walk_speed", "acceleration", "deceleration", "air_control", "jump_velocity", "jump_cut", "coyote_time", "jump_buffer_time", "max_fall_speed", "gravity_scale", "floor_snap_length", "collision_layer", "collision_mask"]:
		h.check(player.get(property) == greybox.get(property), "%s differs from the greybox" % property)
	var shape: CapsuleShape2D = player.get_node("CollisionShape2D").shape
	h.check(is_equal_approx(shape.radius, 6.0) and is_equal_approx(shape.height, 24.0), "collision capsule changed")
	greybox.free()


func test_preview_ground_matches_the_greybox_collision(h) -> void:
	await _setup(h)
	var level: Node = (load(LEVEL) as PackedScene).instantiate()
	var greybox_points: PackedVector2Array = level.get_node("Terrain/Ground").polygon
	var preview_points: PackedVector2Array = h.fixture.get_node("Terrain/Ground").polygon
	var compared := 0
	for point in greybox_points:
		if point.x >= 24.0 and point.x <= 540.0 and point.y > -300.0:
			compared += 1
			h.check(preview_points.has(point), "greybox point %s is missing from the preview" % point)
	h.check(compared == 9, "compared %d points, expected all 9 shared ones" % compared)
	level.free()


func test_idle_plays_the_idle_animation(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	await h.steps(5)
	var sprite := _sprite(player)
	h.check(sprite.animation == &"idle", "animation is %s" % sprite.animation)
	h.check(sprite.is_playing(), "idle is not playing")


## This is what stops foot sliding: the frame depends on distance walked and nothing else.
func test_walk_frame_follows_distance_travelled(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var sprite := _sprite(player)
	# Open ground from x=250 to the slope at 360, so nothing interrupts the walk.
	player.teleport(Vector2(250, -2))
	await h.landed_on_floor(player)
	Input.action_press("move_right")
	await h.wait_until(func() -> bool: return sprite.animation == &"walk", 10, "the walk to start")
	var start_x := player.global_position.x
	var start_frame := sprite.frame
	for i in 60:
		await h.steps(1)
		var travelled := player.global_position.x - start_x
		var expected: int = (start_frame + floori(travelled / player.walk_pixels_per_frame)) % 8
		var difference: int = absi(sprite.frame - expected)
		h.check(difference <= 1 or difference == 7, "at %.1f px the frame is %d, expected about %d" % [travelled, sprite.frame, expected])
	h.check(not sprite.is_playing(), "the walk must not advance on its own clock")


func test_walking_into_a_wall_does_not_moonwalk(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(40, -2))
	Input.action_press("move_left")
	await h.steps(90)
	h.check(_sprite(player).animation == &"idle", "pushing against a wall shows %s" % _sprite(player).animation)


func test_facing_flips_the_whole_figure(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var visual: Node2D = player.get_node("Visual")
	Input.action_press("move_left")
	await h.steps(5)
	h.check(visual.scale.x < 0.0, "not flipped when walking left")
	Input.action_release("move_left")
	Input.action_press("move_right")
	await h.steps(5)
	h.check(visual.scale.x > 0.0, "not flipped back when walking right")


func test_jump_and_fall_poses(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var sprite := _sprite(player)
	var seen := {}
	Input.action_press("jump")
	for i in 60:
		await h.steps(1)
		seen[sprite.animation] = true
		if i > 5 and player.is_on_floor():
			break
	Input.action_release("jump")
	h.check(seen.has(&"jump"), "no jump pose; saw %s" % str(seen.keys()))
	h.check(seen.has(&"fall"), "no fall pose; saw %s" % str(seen.keys()))
	await h.steps(5)
	h.check(sprite.animation == &"idle", "did not return to idle after landing")


## The defect from the owner's recording: the character flickered by a pixel while followed.
## Measures where the sailor lands on screen, through the same transform the renderer uses. It reads
## at physics_frame because that fires before anything moves: the player and canvas are still exactly
## as they were last drawn. Godot applies a camera's transform after processing, so a read during
## processing would pair the new player position with the old camera.
func test_pixel_lock_holds_the_sailor_still_on_screen(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	player.teleport(Vector2(250, -2))
	await h.landed_on_floor(player)
	Input.action_press("move_right")
	# Let the look-ahead settle, staying on flat ground before the slope at 360.
	await h.steps(50)
	var screen_positions := {}
	for i in 40:
		await h.tree.physics_frame
		var on_screen: float = player.get_global_transform_with_canvas().origin.x
		screen_positions[int(floorf(on_screen + 0.5))] = true
	h.check(screen_positions.size() == 1, "the sailor's screen position varied while walking: %s" % str(screen_positions.keys()))


func test_preview_can_be_crossed_in_both_directions(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	for leg in [["move_right", 600.0], ["move_left", 40.0]]:
		var action: String = leg[0]
		var goal: float = leg[1]
		Input.action_press(action)
		var last_x := player.global_position.x
		var stalled := 0
		var reached := false
		for i in 900:
			await h.steps(1)
			if (action == "move_right" and player.global_position.x >= goal) or (action == "move_left" and player.global_position.x <= goal):
				reached = true
				break
			stalled = stalled + 1 if absf(player.global_position.x - last_x) < 0.2 else 0
			last_x = player.global_position.x
			if stalled >= 6 and player.is_on_floor():
				Input.action_press("jump")
				await h.steps(12)
				Input.action_release("jump")
				stalled = 0
		Input.action_release(action)
		h.check(reached, "stuck going %s at x=%.1f" % [action, player.global_position.x])
