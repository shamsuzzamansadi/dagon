extends "res://tests/test_level.gd"
## Tests of the entry scene: everything in test_level.gd runs again here, so the Shore keeps the
## greybox's traversal and camera coverage. The tests below cover the sailor's animation and that the
## art sits on the same movement and collision as the greybox.

const SHORE := "res://scenes/level/shore.tscn"
const ART_END_X := 640.0
const SECTION_END_X := 1440.0
const ROCK_LEFT := 200
const ROCK_RIGHT := 240
const ROCK_TOP := -14


func _scene_path() -> String:
	return SHORE


func _end_wall_x() -> float:
	return 4520.0


func _limit_right() -> int:
	return 4544


func _sprite(player: Node) -> AnimatedSprite2D:
	return player.get_node("Visual/Sailor")


## Rows are read from the file, because a headless run has no texture data to read back.
func _first_drawn_y(art: Sprite2D, x: int) -> int:
	var image := Image.load_from_file(ProjectSettings.globalize_path(art.texture.resource_path))
	for row in image.get_height():
		if image.get_pixel(x, row).a > 0.0:
			return row + int(art.position.y)
	return 1 << 16


func test_the_game_starts_in_the_main_menu_and_plays_on_the_shore(h) -> void:
	const TITLE := "res://scenes/ui/title.tscn"
	h.check(ProjectSettings.get_setting("application/run/main_scene") == TITLE, "main scene is %s" % ProjectSettings.get_setting("application/run/main_scene"))
	var title: Node = (load(TITLE) as PackedScene).instantiate()
	var game: Node = title.game_scene.instantiate()
	h.check(game.world_scene.resource_path.get_file() == SHORE.get_file(), "the game plays %s" % game.world_scene.resource_path)
	game.free()
	title.free()


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


## M1's level is still here, point for point, up to the end of its steps. The acts carry on from there.
func test_shore_keeps_the_greybox_level_up_to_where_the_acts_carry_on(h) -> void:
	const COMMON_POINTS := 21
	var shore: Node = (load(SHORE) as PackedScene).instantiate()
	var level: Node = (load(LEVEL) as PackedScene).instantiate()
	var shore_polygon: PackedVector2Array = shore.get_node("Terrain/Ground").polygon
	var level_polygon: PackedVector2Array = level.get_node("Terrain/Ground").polygon
	h.check(level_polygon[COMMON_POINTS - 1] == Vector2(980, 0), "the common part ends at %s" % level_polygon[COMMON_POINTS - 1])
	h.check(shore_polygon.slice(0, COMMON_POINTS) == level_polygon.slice(0, COMMON_POINTS), "collision differs from the greybox before x = 980")
	h.check(shore.get_node("Player").position == level.get_node("Player").position, "spawn point differs from the greybox")
	for limit in ["limit_left", "limit_top", "limit_bottom"]:
		h.check(shore.get_node("CameraRig").get(limit) == level.get_node("CameraRig").get(limit), "%s differs from the greybox" % limit)
	h.check(shore.get_node("CameraRig").limit_right == _limit_right(), "limit_right is %d" % shore.get_node("CameraRig").limit_right)
	shore.free()
	level.free()


## No gap may show along the route: the Shore's art meets the finished reference section, and that meets the Abyss's
## ground, which runs on to the end. The far view runs on behind it, and the greybox that stood there is hidden.
func test_the_art_runs_unbroken_to_the_end_of_the_route(h) -> void:
	await _setup(h)
	var art: Sprite2D = h.fixture.get_node("Terrain/Art")
	h.check_near(art.position.x + art.texture.get_width(), ART_END_X, 0.0, "right edge of the terrain art")
	var section: Sprite2D = h.fixture.get_node("ReferenceSection/Front")
	h.check(section.position.x <= ART_END_X, "the reference section starts at %.0f, leaving a gap after the Shore" % section.position.x)
	h.check_near(section.position.x + section.texture.get_width(), SECTION_END_X, 0.0, "right edge of the reference section")
	var camera: Camera2D = h.fixture.get_node("CameraRig")
	var edge := SECTION_END_X
	for tile in h.fixture.get_node("AbyssGround").get_children():
		h.check_near(tile.position.x, edge, 0.0, "left edge of %s" % tile.name)
		h.check_near(tile.position.y, section.position.y, 0.0, "top of %s" % tile.name)
		edge = tile.position.x + tile.texture.get_width()
	h.check_near(edge, camera.limit_right, 0.0, "right edge of the Abyss's ground")
	# The far view: one clip from the cave to the end, and the plain carried on where the reference section's stops.
	var view: Rect2 = _bounds(h.fixture.get_node("AbyssView").polygon)
	h.check_near(view.end.x, camera.limit_right, 0.0, "right edge of the far view's clip")
	h.check(view.position.y <= camera.limit_top and view.end.y >= camera.limit_bottom, "the far view's clip does not fill the view's height")
	var far: Sprite2D = h.fixture.get_node("AbyssView/Far/Art")
	var plain: Sprite2D = h.fixture.get_node("AbyssView/Far/Plain")
	h.check_near(plain.position.x, far.position.x + far.texture.get_width(), 0.0, "left edge of the far plain")
	h.check_near(plain.position.y, far.position.y, 0.0, "top of the far plain")
	var parallax: Parallax2D = h.fixture.get_node("AbyssView/Far")
	h.check(plain.position.x + plain.texture.get_width() >= camera.limit_right * parallax.scroll_scale.x + 480.0, "the far plain ends before the route does, even with the camera pulled back")
	for path in ["Terrain/GreyboxGround", "Terrain/GroundBlend", "GreyboxBackdrop", "CanyonRim", "FarRidges/Silhouette"]:
		h.check(not h.fixture.get_node(path).visible, "the greybox %s still shows" % path)


## The watcher drops behind the far cliff and the distant shape rises from behind it, so the cliff is drawn after both.
func test_the_far_cliff_is_in_front_of_the_watcher_and_the_distant_shape(h) -> void:
	await _setup(h)
	var ridges: Node = h.fixture.get_node("FarRidges")
	var cliff: Sprite2D = ridges.get_node("Escarpment")
	h.check(cliff.get_index() > ridges.get_node("WatcherFar").get_index(), "the watcher is drawn over the far cliff")
	h.check(cliff.get_index() > ridges.get_node("DistantShape").get_index(), "the distant shape is drawn over the far cliff")
	h.check_near((ridges as Parallax2D).scroll_scale.x, (h.fixture.get_node("AbyssView/Far") as Parallax2D).scroll_scale.x, 0.0, "the far cliff does not move with the plain it stands on")


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
