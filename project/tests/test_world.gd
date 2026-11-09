extends RefCounted
## The four-act level itself: can it be crossed, does it match the design, and is everything wired.

const WORLD := "res://scenes/level/shore.tscn"
const TITLE := "res://scenes/ui/title.tscn"
const WITNESS_X := 4420.0
const COLLAPSE_X := 3760.0
const GATE_X := 4300.0
const WALL_X := 4520.0
const ART_END_X := 640.0
const AWAKENED_BEAT := 3
## The font's drawable characters decide what can be written, so all text is checked against it.
const TEXT_NODES := ["Props/Lifeboat", "Props/FishNearRock", "Props/Talisman", "Props/CaveCarving", "Props/FossilA", "Props/FossilB", "Props/TabletWave", "Props/TabletKneel", "Props/TabletEye", "Props/Footprint", "Props/Relief", "Props/Cairn", "Props/Statue", "Monolith/Mural"]


func _world(h, beat := 0) -> Node2D:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(world)
	await h.landed_on_floor(world.get_node("Player"))
	return world


## Walks in one direction, hopping when blocked, as a player would. Real key events.
func _walk(h, player: CharacterBody2D, key: Key, reached: Callable, max_steps: int) -> bool:
	h.send(h.key_event(key, true))
	var last_x := player.global_position.x
	var stalled := 0
	for i in max_steps:
		await h.steps(1)
		if reached.call():
			h.send(h.key_event(key, false))
			return true
		stalled = stalled + 1 if absf(player.global_position.x - last_x) < 0.2 else 0
		last_x = player.global_position.x
		if stalled >= 6 and player.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(12)
			h.send(h.key_event(KEY_SPACE, false))
			stalled = 0
	h.send(h.key_event(key, false))
	return false


func test_the_whole_level_can_be_walked_in_both_directions_with_nothing_but_keys(h) -> void:
	var world := await _world(h, AWAKENED_BEAT)
	var player: CharacterBody2D = world.get_node("Player")
	player.teleport(Vector2(40, -2))
	await h.landed_on_floor(player)
	var right: bool = await _walk(h, player, KEY_D, func() -> bool: return player.global_position.x > WITNESS_X - 30.0, 6000)
	h.check(right, "stuck going right at x=%.1f" % player.global_position.x)
	var left: bool = await _walk(h, player, KEY_A, func() -> bool: return player.global_position.x < 40.0, 6000)
	h.check(left, "stuck going left at x=%.1f" % player.global_position.x)


func test_the_gate_blocks_the_way_until_the_puzzle_is_solved(h) -> void:
	var world := await _world(h, 2)
	var player: CharacterBody2D = world.get_node("Player")
	var gate: StaticBody2D = world.get_node("Monolith/Gate")
	h.check(gate.collision_layer != 0, "the gate starts open")
	await h.stand_at(player, Vector2(GATE_X - 30.0, -2))
	var reached: bool = await _walk(h, player, KEY_D, func() -> bool: return player.global_position.x > GATE_X + 20.0, 180)
	h.check(not reached, "the player got past a closed gate, to x=%.1f" % player.global_position.x)
	h.check(gate.visible, "the gate is hidden before it opens")


func test_a_closed_gate_cannot_be_jumped(h) -> void:
	var world := await _world(h, 2)
	var player: CharacterBody2D = world.get_node("Player")
	await h.stand_at(player, Vector2(GATE_X - 20.0, -2))
	h.send(h.key_event(KEY_D, true))
	for i in 5:
		h.send(h.key_event(KEY_SPACE, true))
		await h.steps(30)
		h.send(h.key_event(KEY_SPACE, false))
		await h.steps(30)
	h.send(h.key_event(KEY_D, false))
	h.check(player.global_position.x < GATE_X, "the player jumped the gate, to x=%.1f" % player.global_position.x)


## Nobody can fall somewhere they cannot get out of. Pillar 3.
## The gap in Act II: wider than any hop, with a way down into it on the near side and a way back out, so nobody is
## ever stuck in it. Crossing it is the slab's job (test_revision.gd).
func test_the_gap_cannot_be_hopped_and_a_fall_into_it_can_always_be_climbed_out_of(h) -> void:
	var world := await _world(h, 1)
	var player: CharacterBody2D = world.get_node("Player")
	# A running hop from the near rim falls short, onto the slab or into the hollow.
	await h.stand_at(player, Vector2(2120.0, -2))
	h.send(h.key_event(KEY_D, true))
	await h.wait_until(func() -> bool: return player.global_position.x >= 2146.0, 60, "the run-up")
	h.send(h.key_event(KEY_SPACE, true))
	await h.steps(45)
	h.send(h.key_event(KEY_SPACE, false))
	h.send(h.key_event(KEY_D, false))
	await h.steps(30)
	h.check(player.global_position.x < 2290.0 or player.global_position.y > 4.0, "a hop crossed the gap: at %s" % player.global_position)
	# Down in the hollow, under the slab's raised end, the steps on the near side lead back up, by walking and hopping.
	await h.stand_at(player, Vector2(2160.0, 24.0))
	h.check(player.global_position.y > 20.0, "not down in the hollow: y=%.1f" % player.global_position.y)
	var out_left: bool = await _walk(h, player, KEY_A, func() -> bool: return player.global_position.x < 2144.0 and player.global_position.y < 2.0, 300)
	h.check(out_left, "could not climb out to the left, at %s" % player.global_position)


func test_the_way_right_ends_in_a_solid_wall_the_player_presses_against(h) -> void:
	var world := await _world(h, AWAKENED_BEAT)
	var player: CharacterBody2D = world.get_node("Player")
	await h.stand_at(player, Vector2(WALL_X - 30.0, -2))
	h.send(h.key_event(KEY_D, true))
	for i in 3:
		h.send(h.key_event(KEY_SPACE, true))
		await h.steps(35)
		h.send(h.key_event(KEY_SPACE, false))
		await h.steps(25)
	h.send(h.key_event(KEY_D, false))
	h.check(player.global_position.x < WALL_X, "the player got through the wall, to x=%.1f" % player.global_position.x)
	h.check(world.get_node("Triggers/Witness").global_position.x < WALL_X, "the Witness trigger is behind the wall")


## Running left from the Witness reaches the collapse point in 8 to 10 seconds, by the GDD, on open ground.
func test_running_left_from_the_witness_reaches_collapse_in_eight_to_ten_seconds(h) -> void:
	var world := await _world(h, AWAKENED_BEAT)
	var player: CharacterBody2D = world.get_node("Player")
	var director: Node = world.get_node("GameDirector")
	# The route itself, measured before the story can end it.
	world.get_node("Triggers/Collapse").enabled = false
	await h.stand_at(player, Vector2(WITNESS_X - 30.0, -2))
	h.check(director.get_beat() == AWAKENED_BEAT, "the walk moved the story to %d" % director.get_beat())
	await h.stand_at(player, Vector2(WITNESS_X, -2))
	if director.is_cinematic_active():
		await h.wait_until(func() -> bool: return not director.is_cinematic_active(), 900, "the reveal to finish")
	await h.steps(4)
	var frames := 0
	h.send(h.key_event(KEY_A, true))
	# Hopping only on meeting each rock, as someone seeing it late would.
	while player.global_position.x > COLLAPSE_X and frames < 1000:
		if player.is_on_wall() and player.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(10)
			h.send(h.key_event(KEY_SPACE, false))
			frames += 10
		await h.steps(1)
		frames += 1
	h.send(h.key_event(KEY_A, false))
	var seconds := frames / 60.0
	h.check(seconds >= 8.0 and seconds <= 10.0, "the run took %.2f seconds" % seconds)
	h.check(seconds < director.flee_timeout, "the run is longer than the flee's %.1f seconds" % director.flee_timeout)


## The sea ends the flee now. The timeout is only the bounded guard behind it (D73).
func test_the_flee_fallback_is_long_enough_never_to_end_a_flee_first(h) -> void:
	var world := await _world(h)
	var director: Node = world.get_node("GameDirector")
	h.check_near(director.flee_timeout, 30.0, 0.0, "the fallback")
	# Even standing still, the sea arrives long before the fallback.
	var standing_caught: float = director.tide_delay + (director.tide_start_x - 4426.0) / director.tide_speed
	h.check(standing_caught < director.flee_timeout / 4.0, "the sea takes %.1f s to reach a sailor who stands still" % standing_caught)


func test_the_kill_plane_catches_a_fall_at_each_act(h) -> void:
	var world := await _world(h, 2)
	var player: CharacterBody2D = world.get_node("Player")
	var respawns := [0]
	world.get_node("GameDirector").player_respawned.connect(func() -> void: respawns[0] += 1)
	var count := 0
	for x in [40.0, 1000.0, 2163.0, 3000.0, 3900.0, 4500.0]:
		player.teleport(Vector2(x, 100))
		await h.steps(30)
		count += 1
		h.check(respawns[0] == count, "a fall at x=%.0f gave %d respawns in total" % [x, respawns[0]])
		h.check_near(player.global_position.x, 3660.0, 1.0, "respawn x after a fall at x=%.0f" % x)


func test_everything_the_director_needs_is_wired(h) -> void:
	var world := await _world(h)
	var director: Node = world.get_node("GameDirector")
	for property in ["player_path", "hud_path", "kill_plane_path", "camera_rig_path", "atmosphere_path", "cinematics_path", "monolith_gate_path", "puzzle_path", "mural_path"]:
		h.check(director.get_node_or_null(director.get(property)) != null, "%s does not resolve" % property)
	h.check(director.ending_scene != null, "no ending scene")
	h.check(director.mural_solved_line == &"mural.after", "the second mural line is %s" % director.mural_solved_line)
	for path in director.awakened_visuals:
		h.check(director.get_node_or_null(path) != null, "%s does not resolve" % path)

	var ids := []
	for path in director.story_triggers:
		var trigger: Node = director.get_node(path)
		ids.append(trigger.trigger_id)
		h.check(trigger.triggered.get_connections().size() == 1, "%s has %d connections" % [trigger.name, trigger.triggered.get_connections().size()])
	h.check(ids == [&"enter_abyss", &"reach_monolith", &"witness", &"collapse"], "the triggers are %s" % str(ids))
	h.check(world.get_node("Triggers/KillPlane").triggered.get_connections().size() == 1, "the kill plane is not connected")

	var names := []
	for path in director.checkpoints:
		names.append(String(director.get_node(path).name))
	h.check(names == ["Shore", "PastTheTrench", "Monolith", "Awakened"], "the checkpoints are %s" % str(names))

	var puzzle: Node = world.get_node("Monolith/Puzzle")
	for stone_name in ["GlyphWave", "GlyphKneel", "GlyphEye"]:
		var stone: Node = world.get_node("Monolith/" + stone_name)
		h.check(stone.interacted.is_connected(puzzle.submit), "%s is not connected to the puzzle" % stone_name)
		h.check(puzzle.solution.has(String(stone.interaction_id)), "%s is not in the solution" % stone_name)
		h.check(stone.caption.is_empty(), "%s has its own caption, which would hide the feedback" % stone_name)
		h.check(not stone.one_shot, "%s is one-shot" % stone_name)
	h.check(puzzle.solved.is_connected(director.on_puzzle_solved), "the puzzle is not connected to the director")
	h.check(puzzle.indicators.size() == 3 and puzzle.stones.size() == 3, "the puzzle has %d indicators and %d stones" % [puzzle.indicators.size(), puzzle.stones.size()])

	var cinematics: AnimationPlayer = world.get_node("Cinematics")
	for clip in [&"monolith_awaken", &"dagon_reveal", &"collapse"]:
		h.check(cinematics.has_animation(clip), "no clip %s" % clip)
		h.check(cinematics.get_animation(clip).loop_mode == Animation.LOOP_NONE, "%s loops" % clip)
		h.check(cinematics.get_animation(clip).length > 0.0, "%s is empty" % clip)
		h.check(cinematics.get_animation(clip).get_track_count() > 0, "%s has no tracks" % clip)
	var atmosphere: AnimationPlayer = world.get_node("Atmosphere")
	for clip in [&"beat_shore", &"beat_abyss", &"beat_monolith", &"beat_witness", &"beat_fleeing"]:
		h.check(atmosphere.has_animation(clip), "no clip %s" % clip)


## A renamed node in a clip fails silently at runtime, so every track's target is resolved here.
func test_every_clip_track_points_at_something_real(h) -> void:
	var world := await _world(h)
	for player_name in ["Cinematics", "Atmosphere"]:
		var player: AnimationPlayer = world.get_node(player_name)
		for clip in player.get_animation_list():
			var animation := player.get_animation(clip)
			for track in animation.get_track_count():
				var path: NodePath = animation.track_get_path(track)
				var target: Node = world.get_node_or_null(NodePath(String(path.get_concatenated_names())))
				h.check(target != null, "%s track %d has no target: %s" % [clip, track, path])
				if target == null or animation.track_get_type(track) != Animation.TYPE_METHOD:
					continue
				for key in animation.track_get_key_count(track):
					var method: StringName = animation.method_track_get_name(track, key)
					h.check(target.has_method(method), "%s calls %s, which %s lacks" % [clip, method, target.name])
					for argument in animation.method_track_get_params(track, key):
						if argument is NodePath:
							h.check(target.get_node_or_null(argument) != null, "%s aims at %s, which does not resolve" % [clip, argument])


func test_nothing_in_a_clip_is_left_out_of_the_acts_and_the_acts_are_in_order(h) -> void:
	var world := await _world(h)
	var along := [
		world.get_node("Triggers/EnterAbyss").global_position.x,
		world.get_node("Props/FossilA").global_position.x,
		world.get_node("Props/TabletWave").global_position.x,
		world.get_node("Props/FossilB").global_position.x,
		world.get_node("Props/Footprint").global_position.x,
		world.get_node("Props/TabletKneel").global_position.x,
		world.get_node("Props/TabletEye").global_position.x,
		world.get_node("Triggers/ReachMonolith").global_position.x,
		world.get_node("Checkpoints/Monolith").global_position.x,
		world.get_node("Triggers/Collapse").global_position.x,
		world.get_node("Monolith/Mural").global_position.x,
		world.get_node("Monolith/GlyphKneel").global_position.x,
		world.get_node("Checkpoints/Awakened").global_position.x,
		world.get_node("Monolith/Gate").global_position.x,
		world.get_node("Triggers/Witness").global_position.x,
	]
	var sorted := along.duplicate()
	sorted.sort()
	h.check(along == sorted, "out of order along the walk: %s" % str(along))
	h.check(along[0] > ART_END_X, "the story starts inside the Shore's art")


## The kill plane is the one thing under the whole level, however far a camera can see.
func test_the_kill_plane_and_backdrop_cover_the_whole_width(h) -> void:
	var world := await _world(h)
	var kill_plane: Area2D = world.get_node("Triggers/KillPlane")
	var size: Vector2 = kill_plane.get_node("Shape").shape.size
	h.check(kill_plane.global_position.x - size.x / 2.0 <= 0.0, "the kill plane starts too far right")
	h.check(kill_plane.global_position.x + size.x / 2.0 >= world.get_node("CameraRig").limit_right, "the kill plane stops short")


## A polygon that crosses itself fails to triangulate and simply is not drawn, with nothing logged and no test noticing.
## The rib arch was lost that way until someone looked at a screenshot.
func test_every_polygon_in_the_world_can_actually_be_drawn(h) -> void:
	var world := await _world(h)
	var polygons := world.find_children("*", "Polygon2D", true, false)
	h.check(polygons.size() > 50, "only %d polygons" % polygons.size())
	for polygon: Polygon2D in polygons:
		h.check(not Geometry2D.triangulate_polygon(polygon.polygon).is_empty(), "%s cannot be triangulated" % world.get_path_to(polygon))


## Every line of the script, whoever says it. The file is read here as the game reads it, line by line.
func _script_lines() -> Dictionary:
	var lines := {}
	for line in FileAccess.get_file_as_string("res://narration/script.txt").split("\n"):
		if line.is_empty() or line.begins_with("#"):
			continue
		var fields := line.split("|", true, 2)
		lines[fields[0]] = fields[2]
	return lines


func test_all_text_can_be_drawn_in_the_game_font(h) -> void:
	var world := await _world(h)
	var label: Label = world.get_node("Hud/Caption")
	var font: Font = label.get_theme_font("font")
	var texts: Array[String] = []
	for path in TEXT_NODES:
		texts.append(world.get_node(path).caption)
		texts.append(world.get_node(path).prompt)
	for text in _script_lines().values():
		texts.append(text)
	for stone_name in ["GlyphWave", "GlyphKneel", "GlyphEye"]:
		texts.append(world.get_node("Monolith/" + stone_name).prompt)
	for connection in world.get_node("Monolith/Puzzle").failed.get_connections():
		texts.append(str(connection["callable"].get_bound_arguments()))
	for text in texts:
		h.check(not text.is_empty(), "an empty text")
		for i in text.length():
			h.check(text.unicode_at(i) == 10 or text.unicode_at(i) == 32 or font.has_char(text.unicode_at(i)), "the font cannot draw '%s' in '%s'" % [text[i], text])


func test_every_caption_fits_its_line_in_the_hud(h) -> void:
	var world := await _world(h)
	var label: Label = world.get_node("Hud/Caption")
	var font: Font = label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var lines := _script_lines()
	for id: String in lines:
		if id.begins_with("ending."):
			continue
		var size: Vector2 = font.get_multiline_string_size(lines[id], HORIZONTAL_ALIGNMENT_CENTER, label.size.x, font_size)
		h.check(size.y <= label.size.y + 1.0, "%s needs %.0f px of a %.0f px caption: %s" % [id, size.y, label.size.y, lines[id]])
