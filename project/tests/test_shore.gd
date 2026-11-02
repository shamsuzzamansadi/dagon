extends "res://tests/test_level.gd"
## Tests of the entry scene: everything in test_level.gd runs again here, so the Shore keeps the
## greybox's traversal and camera coverage. The tests below cover the sailor's animation and that the
## art sits on the same movement and collision as the greybox.

const SHORE := "res://scenes/level/shore.tscn"
const ART_END_X := 640.0
const ROCK_LEFT := 200
const ROCK_RIGHT := 240
const ROCK_TOP := -14


func _scene_path() -> String:
	return SHORE


func _sprite(player: Node) -> AnimatedSprite2D:
	return player.get_node("Visual/Sailor")


## Rows are read from the file, because a headless run has no texture data to read back.
func _first_drawn_y(art: Sprite2D, x: int) -> int:
	var image := Image.load_from_file(ProjectSettings.globalize_path(art.texture.resource_path))
	for row in image.get_height():
		if image.get_pixel(x, row).a > 0.0:
			return row + int(art.position.y)
	return 1 << 16


func test_the_game_starts_in_the_shore(h) -> void:
	h.check(ProjectSettings.get_setting("application/run/main_scene") == SHORE, "main scene is %s" % ProjectSettings.get_setting("application/run/main_scene"))


func test_shore_shows_the_sailor_not_the_placeholder(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	h.check(player.get_node("Visual/Silhouette").visible == false, "greybox silhouette is visible")
	h.check(player.get_node("Visual/LanternMarker").visible == false, "greybox lantern marker is visible")
	h.check(_sprite(player).visible, "sailor sprite is hidden")


func test_shore_keeps_movement_tuning_and_body(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var greybox: Node = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	for property in ["walk_speed", "acceleration", "deceleration", "air_control", "jump_velocity", "jump_cut", "coyote_time", "jump_buffer_time", "max_fall_speed", "gravity_scale", "floor_snap_length", "collision_layer", "collision_mask"]:
		h.check(player.get(property) == greybox.get(property), "%s differs from the greybox" % property)
	var shape: CapsuleShape2D = player.get_node("CollisionShape2D").shape
	h.check(is_equal_approx(shape.radius, 6.0) and is_equal_approx(shape.height, 24.0), "collision capsule changed")
	greybox.free()


## The whole M1 test level is still here, not just the part with art.
func test_shore_has_the_whole_greybox_level(h) -> void:
	var shore: Node = (load(SHORE) as PackedScene).instantiate()
	var level: Node = (load(LEVEL) as PackedScene).instantiate()
	h.check(shore.get_node("Terrain/Ground").polygon == level.get_node("Terrain/Ground").polygon, "collision differs from the greybox")
	h.check(shore.get_node("Player").position == level.get_node("Player").position, "spawn point differs from the greybox")
	for limit in ["limit_left", "limit_top", "limit_right", "limit_bottom"]:
		h.check(shore.get_node("CameraRig").get(limit) == level.get_node("CameraRig").get(limit), "%s differs from the greybox" % limit)
	shore.free()
	level.free()


## Past the art, the backdrop must hide every parallax layer running out, and no gap may show.
func test_art_ends_where_the_greybox_begins(h) -> void:
	await _setup(h)
	var art: Sprite2D = h.fixture.get_node("Terrain/Art")
	h.check_near(art.position.x + art.texture.get_width(), ART_END_X, 0.0, "right edge of the terrain art")
	var camera: Camera2D = h.fixture.get_node("CameraRig")
	var ground: Rect2 = _bounds(h.fixture.get_node("Terrain/GreyboxGround").polygon)
	h.check_near(ground.position.x, ART_END_X, 0.0, "left edge of the greybox ground")
	h.check_near(ground.end.x, camera.limit_right, 0.0, "right edge of the greybox ground")
	var backdrop: Rect2 = _bounds(h.fixture.get_node("GreyboxBackdrop").polygon)
	h.check_near(backdrop.position.x, ART_END_X, 0.0, "left edge of the backdrop")
	h.check_near(backdrop.end.x, camera.limit_right, 0.0, "right edge of the backdrop")
	h.check(backdrop.position.y <= camera.limit_top and backdrop.end.y >= camera.limit_bottom, "the backdrop does not fill the view's height")


func _bounds(polygon: PackedVector2Array) -> Rect2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	return bounds


## The mismatch this replaces: rounded shoulders drawn on a rectangular collision left the feet in
## the air at the rock's corners, by up to 5 px. Lands the real body on the rock and compares.
func test_feet_rest_on_the_drawn_rock(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	var art: Sprite2D = h.fixture.get_node("Terrain/Art")
	for x in range(ROCK_LEFT, ROCK_RIGHT):
		h.check(_first_drawn_y(art, x) == ROCK_TOP, "the rock's top at x=%d is drawn at y=%d" % [x, _first_drawn_y(art, x)])
	for x in [ROCK_LEFT, ROCK_LEFT + 1, 210, 220, 230, ROCK_RIGHT - 2, ROCK_RIGHT - 1]:
		player.teleport(Vector2(x + 0.5, ROCK_TOP - 12))
		await h.steps(30)  # is_on_floor() is out of date until the body has moved again.
		h.check(player.is_on_floor(), "did not land at x=%d" % x)
		var feet_y := floori(player.global_position.y + 0.5)
		h.check(feet_y == ROCK_TOP, "standing at x=%d, the feet are drawn at y=%d, the rock at y=%d" % [x, feet_y, ROCK_TOP])


## The capsule's round bottom can overhang a corner, sinking a little as it does. Art cannot fix
## that without changing the capsule, so this holds it to what docs/shore-preview.md records.
func test_feet_stay_close_to_the_rock_at_its_corners(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.landed_on_floor(player)
	for x in [ROCK_LEFT - 3.0, ROCK_RIGHT + 3.0]:
		player.teleport(Vector2(x, ROCK_TOP - 12))
		await h.steps(30)
		h.check(player.is_on_floor(), "did not stop on the corner at x=%.1f" % x)
		h.check(player.global_position.y <= ROCK_TOP + 2.0, "overhanging at x=%.1f, the feet sank to y=%.2f" % [x, player.global_position.y])


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
