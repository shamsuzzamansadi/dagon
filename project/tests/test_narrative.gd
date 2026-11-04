extends RefCounted
## The exploration and the background events: the talisman, the cave, the ritual and the watcher, the two ways past
## each shelf, and which of it happens again after a restart.

const RoutePlayer := preload("res://tests/route_player.gd")
const ARENA := "res://tests/fixtures/story_arena.tscn"
const WORLD := "res://scenes/level/shore.tscn"
const GAME := "res://scenes/level/game.tscn"
const ABYSS := 1
const MONOLITH := 2
const AWAKENED := 3
const RITUAL_X := 1030.0
const SHELF_A_LEFT_ROCK := 2796.0
const SHELF_A_X := 2900.0
const RELIEF_X := 2908.0
const CAIRN_X := 2960.0
const SHELF_B_LEFT_ROCK := 3395.0
const STATUE_X := 3500.0
const CANYON_X := 3500.0
const ON_SHELF_Y := -38.0


func _world(h, beat := 0) -> Node2D:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(world)
	await h.landed_on_floor(world.get_node("Player"))
	return world


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("Player")


func _prompt(h) -> Label:
	return h.fixture.get_node("Hud/Prompt")


func _caption(h) -> Label:
	return h.fixture.get_node("Hud/Caption")


## ---- Clues and connections ----


func test_the_talisman_can_be_examined_and_can_be_missed(h) -> void:
	var world := await _world(h)
	var talisman: Node = world.get_node("Props/Talisman")
	h.check(talisman.global_position.x < 640.0, "the talisman is past the Shore's art: %.0f" % talisman.global_position.x)
	await h.stand_at(_player(h), Vector2(talisman.global_position.x, -2))
	h.check(_prompt(h).visible and _prompt(h).text.ends_with("Examine"), "the prompt reads '%s'" % _prompt(h).text)
	await h.tap_key(KEY_E)
	h.check(_caption(h).text.contains("An eye, cut above a line of waves"), "the caption reads '%s'" % _caption(h).text)
	h.check(not talisman.one_shot, "a one-shot talisman")


func test_the_same_mark_runs_from_the_talisman_to_the_mural(h) -> void:
	var world := await _world(h)
	for pair in [["Props/Talisman", "eye"], ["Props/Talisman", "waves"], ["Props/CaveCarving", "eye"], ["Props/CaveCarving", "waves"]]:
		h.check(world.get_node(pair[0]).caption.contains(pair[1]), "%s lacks '%s': %s" % [pair[0], pair[1], world.get_node(pair[0]).caption])
	h.check(FileAccess.get_file_as_string("res://narration/script.txt").contains("and over it, that eye"), "the mural's second caption does not recall the mark")
	h.check(FileAccess.get_file_as_string("res://narration/script.txt").contains("That eye, above those waves"), "the epilogue does not recall the mark")
	h.check(world.get_node("RitualLayer/MarkEye") != null and world.get_node("Monolith/MuralLit/Symbol") != null, "the mark is missing from the ritual or the mural")


func test_the_required_clues_all_lie_on_the_ground_and_need_no_side_route(h) -> void:
	var world := await _world(h)
	for tablet in ["TabletWave", "TabletKneel", "TabletEye"]:
		var node: Node2D = world.get_node("Props/" + tablet)
		h.check(node.global_position.y > -20.0, "%s is off the ground: %.0f" % [tablet, node.global_position.y])
	# Standing on the ground below each, the prompt is there.
	for tablet in ["TabletWave", "TabletKneel", "TabletEye"]:
		await h.stand_at(_player(h), Vector2(world.get_node("Props/" + tablet).global_position.x, -2))
		h.check(_prompt(h).visible, "no prompt at %s" % tablet)


func test_every_stone_and_mural_keeps_the_approved_solution(h) -> void:
	var world := await _world(h, MONOLITH)
	h.check(world.get_node("Monolith/Puzzle").solution == PackedStringArray(["glyph_wave", "glyph_kneel", "glyph_eye"]), "the solution changed")


func test_solving_changes_the_mural_in_picture_as_well_as_words(h) -> void:
	var world := await _world(h, MONOLITH)
	var lit: Node2D = world.get_node("Monolith/MuralLit")
	h.check(not lit.visible, "the mural starts lit")
	h.check(lit.get_child_count() >= 8, "only %d lit shapes" % lit.get_child_count())
	var puzzle: Node = world.get_node("Monolith/Puzzle")
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		puzzle.submit(id)
	await h.wait_until(func() -> bool: return not world.get_node("GameDirector").is_cinematic_active(), 600, "the cinematic to finish")
	h.check(lit.visible and is_equal_approx(lit.modulate.a, 1.0), "the mural is not lit")
	h.check(world.get_node("Monolith/Mural").caption.contains("swimmer"), "the mural reads '%s'" % world.get_node("Monolith/Mural").caption)
	h.check(world.get_node("Monolith/Mural").line_id == &"mural.after", "the mural uses %s" % world.get_node("Monolith/Mural").line_id)


## ---- Route choices ----


func _climb(h, rock_x: float, shelf_x: float) -> void:
	var player := _player(h)
	await h.stand_at(player, Vector2(rock_x, -16))
	h.send(h.key_event(KEY_D, true))
	await h.wait_until(func() -> bool: return player.global_position.x > rock_x + 12.0, 40, "the run-up on the rock")
	h.send(h.key_event(KEY_SPACE, true))
	await h.wait_until(func() -> bool: return player.global_position.x > shelf_x, 200, "the walk along the shelf")
	h.send(h.key_event(KEY_D, false))
	h.send(h.key_event(KEY_SPACE, false))
	await h.steps(20)


func test_the_shelf_can_be_climbed_by_hopping_from_the_rock(h) -> void:
	await _world(h, ABYSS)
	await _climb(h, SHELF_A_LEFT_ROCK, 2850.0)
	h.check(_player(h).global_position.y < -30.0, "not on the shelf: y=%.1f" % _player(h).global_position.y)
	h.check(_player(h).is_on_floor(), "not standing on the shelf")


func test_the_shelf_cannot_be_reached_from_the_ground_so_it_is_a_choice_of_route(h) -> void:
	await _world(h, ABYSS)
	var player := _player(h)
	await h.stand_at(player, Vector2(2900, -2))
	h.send(h.key_event(KEY_SPACE, true))
	await h.steps(50)
	h.send(h.key_event(KEY_SPACE, false))
	await h.steps(30)
	h.check(player.global_position.y > -5.0, "a hop reached the shelf from below: y=%.1f" % player.global_position.y)


func test_the_way_underneath_stays_open_in_both_directions(h) -> void:
	await _world(h, ABYSS)
	var player := _player(h)
	for leg in [[2825.0, KEY_D, 2990.0], [2990.0, KEY_A, 2825.0]]:
		await h.stand_at(player, Vector2(leg[0], -2))
		var going_right: bool = leg[1] == KEY_D
		h.send(h.key_event(leg[1], true))
		await h.wait_until(func() -> bool: return player.global_position.x >= leg[2] if going_right else player.global_position.x <= leg[2], 200, "the walk under the shelf")
		h.send(h.key_event(leg[1], false))
		h.check(player.global_position.y > -5.0, "the walk under the shelf left the ground: y=%.1f" % player.global_position.y)


func test_each_side_of_the_first_shelf_has_its_own_thing_to_find(h) -> void:
	var world := await _world(h, ABYSS)
	var player := _player(h)
	# Below: the relief, and no way to the cairn.
	await h.stand_at(player, Vector2(RELIEF_X, -2))
	h.check(player.get_node("Interactor").get_focus() == world.get_node("Props/Relief"), "below, the focus is %s" % player.get_node("Interactor").get_focus())
	await h.stand_at(player, Vector2(CAIRN_X, -2))
	h.check(player.get_node("Interactor").get_focus() != world.get_node("Props/Cairn"), "the cairn can be reached from below")
	# Above: the cairn, and no way to the relief.
	await h.stand_at(player, Vector2(CAIRN_X, ON_SHELF_Y))
	h.check(player.get_node("Interactor").get_focus() == world.get_node("Props/Cairn"), "above, the focus is %s" % player.get_node("Interactor").get_focus())
	await h.stand_at(player, Vector2(RELIEF_X, ON_SHELF_Y))
	h.check(player.get_node("Interactor").get_focus() != world.get_node("Props/Relief"), "the relief can be reached from above")


func test_the_statue_stands_on_the_second_shelf_and_the_way_below_still_goes_on(h) -> void:
	var world := await _world(h, ABYSS)
	var player := _player(h)
	await h.stand_at(player, Vector2(STATUE_X, ON_SHELF_Y))
	h.check(player.get_node("Interactor").get_focus() == world.get_node("Props/Statue"), "above, the focus is %s" % player.get_node("Interactor").get_focus())
	await h.tap_key(KEY_E)
	h.check(_caption(h).text.contains("on its knees"), "the statue reads '%s'" % _caption(h).text)


func test_a_drop_from_either_shelf_can_be_climbed_back_from_either_end(h) -> void:
	var world := await _world(h, ABYSS)
	h.check(world != null, "no world")
	var player := _player(h)
	# Back up from the right of the first shelf, against the way of the walk.
	await h.stand_at(player, Vector2(3020, -16))
	h.send(h.key_event(KEY_A, true))
	await h.wait_until(func() -> bool: return player.global_position.x < 3008.0, 40, "the run-up on the far rock")
	h.send(h.key_event(KEY_SPACE, true))
	await h.wait_until(func() -> bool: return player.global_position.x < 2970.0, 120, "the walk along the shelf")
	h.send(h.key_event(KEY_A, false))
	h.send(h.key_event(KEY_SPACE, false))
	await h.steps(20)
	h.check(player.global_position.y < -30.0, "not on the shelf from its far end: y=%.1f" % player.global_position.y)


## ---- Background events ----


func test_the_ritual_plays_when_the_cave_opens_and_only_once(h) -> void:
	var world := await _world(h, ABYSS)
	var director: Node = world.get_node("GameDirector")
	var started := []
	director.background_event_started.connect(func(event: StringName) -> void: started.append(event))
	var figures: Node2D = world.get_node("RitualLayer/Figures")
	h.check(not figures.visible, "the figures show before their moment")
	h.check(world.get_node("Background").assigned_animation == &"", "a clip ran early")
	await h.stand_at(_player(h), Vector2(RITUAL_X, -2))
	h.check(started == [&"ritual_tableau"], "started %s" % str(started))
	h.check(figures.visible, "no figures")
	h.check(world.get_node("Background").is_playing(), "the clip is not playing")
	await h.stand_at(_player(h), Vector2(RITUAL_X - 40.0, -2))
	await h.stand_at(_player(h), Vector2(RITUAL_X, -2))
	h.check(started == [&"ritual_tableau"], "walking back over it gave %s" % str(started))
	# A clip still playing would turn a second crossing away by itself, so this one comes after it has ended.
	var background: AnimationPlayer = world.get_node("Background")
	background.seek(background.current_animation_length, true)
	await h.steps(2)
	h.check(not background.is_playing(), "the clip did not end")
	await h.stand_at(_player(h), Vector2(RITUAL_X - 40.0, -2))
	await h.stand_at(_player(h), Vector2(RITUAL_X, -2))
	h.check(started == [&"ritual_tableau"], "crossing after it ended gave %s" % str(started))


func test_the_ritual_says_its_line_and_is_bounded(h) -> void:
	var world := await _world(h, ABYSS)
	var background: AnimationPlayer = world.get_node("Background")
	var hud: Node = world.get_node("Hud")
	await h.stand_at(_player(h), Vector2(RITUAL_X, -2))
	await h.wait_until(func() -> bool: return hud.get_current_line() == &"abyss.ritual", 180, "the line")
	h.check(background.is_playing(), "the clip ended early")
	await h.wait_until(func() -> bool: return not background.is_playing(), 800, "the clip to end")
	h.check(not world.get_node("RitualLayer/Figures").visible, "the figures stayed after their moment")
	# What stands there still stands, and the player has lost nothing if they looked away.
	h.check(world.get_node("RitualLayer/MarkStone").visible, "the stones went away")


func test_the_watcher_is_there_for_long_enough_to_be_seen(h) -> void:
	var world := await _world(h, ABYSS)
	var background: AnimationPlayer = world.get_node("Background")
	h.check(background.get_animation(&"ritual_tableau").length >= 10.0, "the ritual lasts %.1f s" % background.get_animation(&"ritual_tableau").length)
	h.check(background.get_animation(&"watcher_ridge").length >= 3.0, "the watcher lasts %.1f s" % background.get_animation(&"watcher_ridge").length)
	h.check(background.get_animation(&"canyon_figure").length >= 2.0, "the canyon figure lasts %.1f s" % background.get_animation(&"canyon_figure").length)


func test_the_ritual_sits_in_view_when_it_begins_and_for_most_of_its_length(h) -> void:
	var world := await _world(h, ABYSS)
	var player := _player(h)
	await h.stand_at(player, Vector2(RITUAL_X - 30.0, -2))
	await h.steps(120)
	var figure: Node2D = world.get_node("RitualLayer/Figures/Watcher")
	h.send(h.key_event(KEY_D, true))
	var seen := 0
	var frames := 0
	await h.wait_until(func() -> bool: return world.get_node("Background").is_playing(), 120, "the clip to start")
	while world.get_node("Background").is_playing() and frames < 900:
		await h.steps(1)
		frames += 1
		var on_screen: Vector2 = figure.get_global_transform_with_canvas() * Vector2(828, -40)
		if world.get_viewport_rect().has_point(on_screen):
			seen += 1
	h.send(h.key_event(KEY_D, false))
	h.check(seen >= 360, "a walking player has the watcher in view for only %.1f s of %.1f s" % [seen / 60.0, frames / 60.0])


func test_the_watcher_on_the_ridge_only_shows_from_the_shelf(h) -> void:
	var world := await _world(h, ABYSS)
	var started := []
	world.get_node("GameDirector").background_event_started.connect(func(event: StringName) -> void: started.append(event))
	await h.stand_at(_player(h), Vector2(SHELF_A_X, -2))
	h.check(started.is_empty(), "the ground below started %s" % str(started))
	await h.stand_at(_player(h), Vector2(SHELF_A_X, ON_SHELF_Y))
	h.check(started == [&"watcher_ridge"], "the shelf started %s" % str(started))


func test_a_figure_crosses_the_canyon_on_either_route(h) -> void:
	for y in [-2.0, ON_SHELF_Y]:
		var world := await _world(h, ABYSS)
		var started := []
		world.get_node("GameDirector").background_event_started.connect(func(event: StringName) -> void: started.append(event))
		await h.stand_at(_player(h), Vector2(CANYON_X, y))
		h.check(started == [&"canyon_figure"], "at y=%.0f, started %s" % [y, str(started)])
		await h.unload_fixture()


func test_missing_every_background_event_changes_nothing_about_the_story(h) -> void:
	var world := await _world(h, ABYSS)
	var director: Node = world.get_node("GameDirector")
	for path in director.background_triggers:
		director.get_node(path).enabled = false
	await h.stand_at(_player(h), Vector2(3620, -2))
	h.check(director.get_beat() == MONOLITH, "the story stopped at %d" % director.get_beat())


func test_pausing_holds_a_background_event(h) -> void:
	var world := await _world(h, ABYSS)
	var background: AnimationPlayer = world.get_node("Background")
	await h.stand_at(_player(h), Vector2(RITUAL_X, -2))
	h.tree.paused = true
	var position := background.current_animation_position
	await h.steps(60)
	h.check(is_equal_approx(background.current_animation_position, position), "the ritual went on while paused")
	h.tree.paused = false
	await h.steps(10)
	h.check(background.current_animation_position > position, "the ritual did not carry on")


## The arena has one event and no story around it, so that only the rule itself is being tested.
func test_a_background_event_met_during_a_cinematic_stays_armed_for_next_time(h) -> void:
	var arena: Node2D = (load(ARENA) as PackedScene).instantiate()
	await h.load_with(arena)
	await h.landed_on_floor(arena.get_node("Player"))
	var director: Node = arena.get_node("GameDirector")
	var started := []
	director.background_event_started.connect(func(event: StringName) -> void: started.append(event))
	director.start_cinematic(&"side_show")
	arena.get_node("Player").teleport(Vector2(250, -2))
	await h.steps(5)
	h.check(started.is_empty(), "a background event ran during a cinematic: %s" % str(started))
	h.check(arena.get_node("Sight").enabled, "the event was used up")
	await h.wait_until(func() -> bool: return not director.is_cinematic_active(), 40, "the cinematic to end")
	arena.get_node("Player").teleport(Vector2(180, -2))
	await h.steps(20)
	arena.get_node("Player").teleport(Vector2(250, -2))
	await h.steps(5)
	h.check(started == [&"tableau"], "the next crossing gave %s" % str(started))


## ---- Which events come back: docs/architecture.md §5, Background events ----


func test_a_restored_world_past_the_events_never_plays_them(h) -> void:
	for beat in [MONOLITH, AWAKENED]:
		var world := await _world(h, beat)
		var director: Node = world.get_node("GameDirector")
		for path in director.background_triggers:
			h.check(not director.get_node(path).enabled, "at beat %d, %s is armed" % [beat, path])
		var started := []
		director.background_event_started.connect(func(event: StringName) -> void: started.append(event))
		for x in [RITUAL_X, CANYON_X]:
			await h.stand_at(_player(h), Vector2(x, -2))
		await h.stand_at(_player(h), Vector2(SHELF_A_X, ON_SHELF_Y))
		h.check(started.is_empty(), "at beat %d, walking back started %s" % [beat, str(started)])
		h.check(not world.get_node("RitualLayer/Figures").visible, "at beat %d, the figures show" % beat)
		await h.unload_fixture()


func test_a_restored_world_before_the_events_has_them_still_ahead(h) -> void:
	for beat in [0, ABYSS]:
		var world := await _world(h, beat)
		var director: Node = world.get_node("GameDirector")
		for path in director.background_triggers:
			h.check(director.get_node(path).enabled, "at beat %d, %s is used up" % [beat, path])
		await h.unload_fixture()


func test_restarting_at_the_abyss_lets_the_ritual_happen_again_exactly_once(h) -> void:
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(ABYSS, true, false)
	await h.load_with(session)
	var player: CharacterBody2D = session.get_world().get_node("Player")
	await h.stand_at(player, Vector2(RITUAL_X, -2))
	h.check(session.get_world().get_node("Background").is_playing(), "the ritual did not play")
	session.restart_checkpoint()
	await h.steps(3)
	var world: Node = session.get_world()
	h.check(not world.get_node("Background").is_playing(), "the ritual carried over into the new world")
	h.check(not world.get_node("RitualLayer/Figures").visible, "the figures carried over")
	var started := []
	session.get_director().background_event_started.connect(func(event: StringName) -> void: started.append(event))
	await h.stand_at(world.get_node("Player"), Vector2(RITUAL_X, -2))
	h.check(started == [&"ritual_tableau"], "the second world started %s" % str(started))


func test_no_new_save_state_comes_with_any_of_this(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(ABYSS, true, false)
	await h.load_with(session)
	await h.stand_at(session.get_world().get_node("Player"), Vector2(RITUAL_X, -2))
	await h.stand_at(session.get_world().get_node("Player"), Vector2(3620, -2))
	var text: String = h.read_storage_file("save.dat")
	h.check(text == "dagon_save=1\nbeat=monolith\ncheckpoint=Monolith\n", "the file holds: %s" % text)


## ---- Reveal staging ----


func test_the_reveal_shows_a_head_body_and_hand_with_highlights_that_appear_in_order(h) -> void:
	var world := await _world(h, AWAKENED)
	var director: Node = world.get_node("GameDirector")
	for part in ["Body", "Head", "Crest", "Arm", "Eye", "Pupil", "Rims"]:
		h.check(not world.get_node("Dagon/" + part).visible, "%s shows before the reveal" % part)
	h.check(world.get_node("Dagon/Ridge").visible, "the far ridge does not show before the reveal")
	await h.stand_at(_player(h), Vector2(4420, -2))
	var clips: AnimationPlayer = world.get_node("Cinematics")
	h.check(clips.current_animation == &"dagon_reveal", "playing '%s'" % clips.current_animation)
	var order := {}
	var parts := ["Body", "Head", "Rims", "Arm", "Eye"]
	while director.is_cinematic_active():
		await h.steps(1)
		for part in parts:
			if world.get_node("Dagon/" + part).visible and not order.has(part):
				order[part] = clips.current_animation_position
	for part in parts:
		h.check(order.has(part), "%s never showed" % part)
	h.check(order["Body"] <= order["Rims"] and order["Rims"] <= order["Arm"] and order["Arm"] < order["Eye"], "the order was %s" % str(order))
	h.check(order["Eye"] > 8.0, "the eye opened after only %.1f s" % order["Eye"])


func test_the_hand_rests_on_the_monolith_and_the_head_is_in_frame_at_the_widest_view(h) -> void:
	var world := await _world(h, AWAKENED)
	var clips: AnimationPlayer = world.get_node("Cinematics")
	await h.stand_at(_player(h), Vector2(4420, -2))
	clips.seek(10.0, true)
	await h.steps(1)
	var camera: Camera2D = world.get_node("CameraRig")
	h.check(camera.zoom.x <= 0.55, "the camera is at zoom %.2f at the widest moment" % camera.zoom.x)
	var view := Rect2(camera.get_screen_center_position() - Vector2(240, 135) / camera.zoom.x, Vector2(480, 270) / camera.zoom.x)
	var head_center: Vector2 = world.get_node("Dagon/Head").to_global(Vector2(-15, -325))
	h.check(view.has_point(head_center), "the head at %s is out of the view %s" % [head_center, view])
	var hand: Vector2 = world.get_node("Dagon/Arm").to_global(Vector2(-460, -240))
	h.check(view.has_point(hand), "the hand at %s is out of the view %s" % [hand, view])
	h.check(hand.x > 3860.0 and hand.x < 4296.0, "the hand at x=%.0f is not on the monolith" % hand.x)
	h.check(hand.y > -520.0 and hand.y < 0.0, "the hand at y=%.0f is not on the monolith" % hand.y)
	h.check(world.get_node("Dagon/Arm").z_index > 0, "the hand is drawn behind the monolith")


func test_after_the_reveal_the_sailor_turns_back_and_the_camera_is_where_play_needs_it(h) -> void:
	var world := await _world(h, AWAKENED)
	var director: Node = world.get_node("GameDirector")
	var player := _player(h)
	await h.stand_at(player, Vector2(4420, -2))
	h.check(player.get_facing() == 1, "the sailor faces %d walking in" % player.get_facing())
	await h.wait_until(func() -> bool: return director.get_beat() == 5, 1000, "the flee")
	h.check(player.get_facing() == -1, "the sailor faces %d in the flee" % player.get_facing())
	var camera: Camera2D = world.get_node("CameraRig")
	h.check(camera.zoom == Vector2.ONE and camera.limit_right == 4544 and camera.limit_top == -220, "the camera was left at %s, %d, %d" % [camera.zoom, camera.limit_right, camera.limit_top])


func test_the_collapse_is_seen_before_the_fade(h) -> void:
	var world := await _world(h, AWAKENED)
	var clips: AnimationPlayer = world.get_node("Cinematics")
	var animation := clips.get_animation(&"collapse")
	h.check(animation.length >= 4.0, "the collapse lasts %.1f s" % animation.length)
	var visual: Node2D = world.get_node("Player/Visual")
	clips.play(&"collapse")
	clips.seek(2.0, true)
	await h.steps(1)
	h.check(visual.rotation > 1.0, "at 2 s the sailor stands at %.2f rad" % visual.rotation)
	h.check(not world.get_node("Hud/Fade").visible or world.get_node("Hud/Fade").modulate.a < 0.1, "the screen is already going at 2 s")
	clips.seek(4.7, true)
	await h.steps(1)
	h.check(world.get_node("Hud/Fade").visible and world.get_node("Hud/Fade").modulate.a > 0.95, "the screen is not black by the end")
	clips.stop(true)
