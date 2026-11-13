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
const WITNESS := 4
const FLEEING := 5
const ENDED := 6
const WITNESS_X := 4420.0
const COLLAPSE_X := 3760.0
const ROCK_XS := [4212.0, 4035.0, 3838.0]
const RITUAL_X := 1030.0
const SHELF_A_LEFT_ROCK := 2796.0
const SHELF_A_X := 2900.0
const RELIEF_X := 2908.0
const CAIRN_X := 2960.0
const SHELF_B_RIGHT_ROCK := 3598.0
const WAVE_TABLET_X := 1320.0
const KNEEL_TABLET_X := 2848.0
const EYE_TABLET_X := 3445.0
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


## Each route past the first two shelves holds something the puzzle can use, so a choice of route has a stake.
func test_the_clues_are_spread_over_both_levels_so_the_routes_matter(h) -> void:
	var world := await _world(h)
	var player := _player(h)
	var interactor: Node = player.get_node("Interactor")
	await h.stand_at(player, Vector2(WAVE_TABLET_X, -2))
	h.check(interactor.get_focus() == world.get_node("Props/TabletWave"), "the first tablet is not on the way: focus %s" % interactor.get_focus())
	# The second: in the recess, and out of reach from the shelf over it.
	await h.stand_at(player, Vector2(KNEEL_TABLET_X, -2))
	h.check(interactor.get_focus() == world.get_node("Props/TabletKneel"), "the second tablet is not in the recess: focus %s" % interactor.get_focus())
	await h.stand_at(player, Vector2(KNEEL_TABLET_X, ON_SHELF_Y))
	h.check(interactor.get_focus() != world.get_node("Props/TabletKneel"), "the second tablet can be read from the shelf over it")
	# The third: on the shelf, and out of reach from the ground under it.
	await h.stand_at(player, Vector2(EYE_TABLET_X, ON_SHELF_Y))
	h.check(interactor.get_focus() == world.get_node("Props/TabletEye"), "the third tablet is not on the shelf: focus %s" % interactor.get_focus())
	await h.stand_at(player, Vector2(EYE_TABLET_X, -2))
	h.check(interactor.get_focus() != world.get_node("Props/TabletEye"), "the third tablet can be read from the ground")


func test_a_slab_stands_under_the_shelf_without_passing_through_it(h) -> void:
	var world := await _world(h)
	var slab: Polygon2D = world.get_node("Props/TabletKneel/Art")
	var top := INF
	for point in slab.polygon:
		top = minf(top, (slab.global_transform * point).y)
	h.check(top > -28.0, "the slab's top is at %.1f, into the shelf above it" % top)


## Walk under it, see the slab above, find the way up at the far end, and come back along the shelf.
func test_the_second_shelf_has_one_way_up_from_its_far_end_and_it_leads_back_to_the_slab(h) -> void:
	var world := await _world(h, ABYSS)
	var player := _player(h)
	# No rock on the near side, so a run and a hop stay on the ground.
	await h.stand_at(player, Vector2(3380, -2))
	h.send(h.key_event(KEY_D, true))
	h.send(h.key_event(KEY_SPACE, true))
	await h.wait_until(func() -> bool: return player.global_position.x > 3480.0, 200, "the walk under the shelf")
	h.send(h.key_event(KEY_D, false))
	h.send(h.key_event(KEY_SPACE, false))
	await h.steps(30)
	h.check(player.global_position.y > -5.0, "got above the shelf from the near side: y=%.1f" % player.global_position.y)
	# From the far rock, by keys alone, back along it.
	await h.stand_at(player, Vector2(SHELF_B_RIGHT_ROCK, -16))
	h.send(h.key_event(KEY_A, true))
	await h.wait_until(func() -> bool: return player.global_position.x < 3590.0, 40, "the run-up on the far rock")
	h.send(h.key_event(KEY_SPACE, true))
	await h.wait_until(func() -> bool: return player.global_position.x < EYE_TABLET_X + 8.0, 300, "the walk along the shelf")
	h.send(h.key_event(KEY_A, false))
	h.send(h.key_event(KEY_SPACE, false))
	await h.steps(20)
	h.check(player.global_position.y < -30.0, "not on the shelf: y=%.1f" % player.global_position.y)
	h.check(player.get_node("Interactor").get_focus() == world.get_node("Props/TabletEye"), "no third tablet here: focus %s" % player.get_node("Interactor").get_focus())
	await h.tap_key(KEY_E)
	h.check(_caption(h).text.contains("He saw them"), "the third tablet reads '%s'" % _caption(h).text)


## Missing a tablet costs a guess and nothing more: the mural still has the order, and the way back is open.
func test_a_missed_tablet_can_still_be_gone_back_for_or_done_without(h) -> void:
	var world := await _world(h, MONOLITH)
	var player := _player(h)
	var before: String = FileAccess.get_file_as_string("res://narration/script.txt").split("mural.before|optional|")[1].split("\n")[0]
	h.check(before.find("Water") < before.find("bent shape") and before.find("bent shape") < before.find("round"), "the mural lost the order: %s" % before)
	await h.stand_at(player, Vector2(world.get_node("Monolith/GlyphKneel").global_position.x, -2))
	await _walk_hopping(h, KEY_A, func() -> bool: return player.global_position.x < KNEEL_TABLET_X, 1600)
	h.check(player.global_position.x < KNEEL_TABLET_X, "the way back stopped at x=%.1f" % player.global_position.x)


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
	clips.seek(animation.length - 0.1, true)
	await h.steps(1)
	h.check(world.get_node("Hud/Fade").visible and world.get_node("Hud/Fade").modulate.a > 0.95, "the screen is not black by the end")
	clips.stop(true)


## ---- The escape ----


## Holds a direction, and hops on meeting something, as someone seeing it late would.
func _walk_hopping(h, key: Key, reached: Callable, max_frames: int) -> void:
	var player := _player(h)
	h.send(h.key_event(key, true))
	for i in max_frames:
		if reached.call():
			break
		if player.is_on_wall() and player.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(10)
			h.send(h.key_event(KEY_SPACE, false))
		await h.steps(1)
	h.send(h.key_event(key, false))


func _begin_the_flee(h) -> Node2D:
	var world := await _world(h, AWAKENED)
	var director: Node = world.get_node("GameDirector")
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 20, "the flee to begin")
	await h.steps(3)
	return world


func test_the_way_back_stays_clear_until_the_flee_begins(h) -> void:
	var world := await _world(h, AWAKENED)
	var director: Node = world.get_node("GameDirector")
	var rockfall: CollisionObject2D = world.get_node("Rockfall")
	h.check(not rockfall.visible and rockfall.collision_layer == 0, "rock is there at Awakened")
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	await h.steps(3)
	h.check(not rockfall.visible and rockfall.collision_layer == 0, "rock is there during the reveal")
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 20, "the flee to begin")
	await h.steps(3)
	h.check(rockfall.visible, "no rock to be seen in the flee")
	h.check(rockfall.collision_layer == 1, "the rock cannot be stood on: layer %d" % rockfall.collision_layer)


func test_rock_stops_a_walk_and_a_hop_clears_it_in_either_direction(h) -> void:
	var world := await _begin_the_flee(h)
	var player := _player(h)
	for rock_x in ROCK_XS:
		await h.stand_at(player, Vector2(rock_x + 40.0, -2))
		h.send(h.key_event(KEY_A, true))
		await h.steps(70)
		h.check(player.global_position.x > rock_x, "walked through the rock at %.0f: x=%.1f" % [rock_x, player.global_position.x])
		h.send(h.key_event(KEY_SPACE, true))
		await h.wait_until(func() -> bool: return player.global_position.x < rock_x - 22.0, 90, "the hop to the left of the rock at %.0f" % rock_x)
		h.send(h.key_event(KEY_A, false))
		h.send(h.key_event(KEY_SPACE, false))
		h.check(player.global_position.x < rock_x - 22.0, "a hop did not clear the rock at %.0f: x=%.1f" % [rock_x, player.global_position.x])
		await h.steps(20)
		h.send(h.key_event(KEY_D, true))
		h.send(h.key_event(KEY_SPACE, true))
		await h.wait_until(func() -> bool: return player.global_position.x > rock_x + 22.0, 90, "the hop back over the rock at %.0f" % rock_x)
		h.send(h.key_event(KEY_D, false))
		h.send(h.key_event(KEY_SPACE, false))
		h.check(player.global_position.x > rock_x + 22.0, "the rock at %.0f cannot be crossed back: x=%.1f" % [rock_x, player.global_position.x])
		await h.steps(20)
	h.check(world != null, "no world")


## Both outcomes stay open: a player who runs and hops gets there in time, and one who stops at the rock is caught.
func test_running_and_hopping_reaches_the_end_in_time_and_stopping_at_a_rock_runs_it_out(h) -> void:
	var world := await _begin_the_flee(h)
	var player := _player(h)
	var director: Node = world.get_node("GameDirector")
	var at_end := [-1.0, 0.0]
	director.beat_changed.connect(func(beat: int) -> void:
		if beat == ENDED:
			at_end[0] = director.get_flee_elapsed()
			at_end[1] = player.global_position.x)
	await _walk_hopping(h, KEY_A, func() -> bool: return at_end[0] >= 0.0, 800)
	h.check(at_end[0] >= 0.0 and at_end[0] < 11.0, "a run with a hop at each rock took %.2f s of 12" % at_end[0])
	h.check(at_end[1] <= COLLAPSE_X + 16.0, "the run ended at x=%.1f, short of collapse" % at_end[1])


func test_walking_into_a_rock_and_stopping_there_times_out_to_the_same_end(h) -> void:
	var world := await _begin_the_flee(h)
	var player := _player(h)
	var director: Node = world.get_node("GameDirector")
	director.flee_timeout = 2.0
	var at_end := [-1.0]
	director.beat_changed.connect(func(beat: int) -> void:
		if beat == ENDED:
			at_end[0] = player.global_position.x)
	await h.stand_at(player, Vector2(ROCK_XS[0] + 30.0, -2))
	h.send(h.key_event(KEY_A, true))
	await h.wait_until(func() -> bool: return at_end[0] >= 0.0, 200, "the flee to time out")
	h.send(h.key_event(KEY_A, false))
	h.check(at_end[0] > ROCK_XS[0], "got past the rock with no hop: x=%.1f" % at_end[0])


## It all lands before someone running flat out could be under it, so none can fall on the player, and he sees it land.
func test_each_rock_lands_before_a_run_could_reach_it(h) -> void:
	var world := await _world(h, AWAKENED)
	var clip: Animation = world.get_node("Atmosphere").get_animation(&"beat_fleeing")
	var speed: float = _player(h).walk_speed
	var names := ["Near", "Mid", "Far"]
	for i in names.size():
		var track := clip.find_track(NodePath("Rockfall/Rock%s:position" % names[i]), Animation.TYPE_VALUE)
		h.check(track >= 0, "the %s rock has no fall" % names[i])
		var keys := clip.track_get_key_count(track)
		var lands := clip.track_get_key_time(track, keys - 1)
		h.check(clip.track_get_key_value(track, keys - 1).x == ROCK_XS[i], "the %s rock lands away from where it stands" % names[i])
		h.check(lands < (WITNESS_X - ROCK_XS[i] - 20.0) / speed, "the %s rock lands at %.1f s, when a run could be there" % [names[i], lands])


## A clip is only a picture of it: with no clip at all the rock is there, where it stands.
func test_the_rock_rests_where_it_collides_with_no_clip_to_drop_it(h) -> void:
	var world := await _world(h, AWAKENED)
	var names := ["Near", "Mid", "Far"]
	for i in names.size():
		var rock: Polygon2D = world.get_node("Rockfall/Rock%s" % names[i])
		var shape: CollisionPolygon2D = world.get_node("Rockfall/Shape%s" % names[i])
		h.check(rock.position == Vector2(ROCK_XS[i], 0), "the %s rock stands at %s" % [names[i], rock.position])
		for j in shape.polygon.size():
			h.check(rock.polygon[j] + rock.position == shape.polygon[j], "the %s rock is not drawn where it collides" % names[i])


func test_restarting_during_the_flee_clears_the_way_back(h) -> void:
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(AWAKENED, true, false)
	await h.load_with(session)
	await h.steps(5)
	var director: Node = session.get_director()
	await h.stand_at(session.get_world().get_node("Player"), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 20, "the flee to begin")
	await h.steps(3)
	h.check(session.get_world().get_node("Rockfall").visible, "no rock in the flee")
	session.restart_checkpoint()
	await h.steps(5)
	var rockfall: CollisionObject2D = session.get_world().get_node("Rockfall")
	h.check(session.get_director().get_beat() == AWAKENED, "restarted at beat %d" % session.get_director().get_beat())
	h.check(not rockfall.visible and rockfall.collision_layer == 0, "the rock is still there after a restart")


## ---- The sea comes back ----


func test_the_sea_comes_back_over_him_and_then_the_screen_fades(h) -> void:
	var world := await _world(h, AWAKENED)
	var sea: CanvasLayer = world.get_node("ReturningSea")
	h.check(not sea.visible, "the sea is there before its moment")
	var clip: Animation = world.get_node("Cinematics").get_animation(&"collapse")
	var rise := clip.find_track(NodePath("ReturningSea/Water:position"), Animation.TYPE_VALUE)
	var show := clip.find_track(NodePath("ReturningSea:visible"), Animation.TYPE_VALUE)
	var fade := clip.find_track(NodePath("Hud/Fade:modulate"), Animation.TYPE_VALUE)
	h.check(rise >= 0 and show >= 0 and fade >= 0, "a track is missing: %d %d %d" % [rise, show, fade])
	var last := clip.track_get_key_count(rise) - 1
	h.check(clip.track_get_key_value(rise, 0).y >= 270.0, "the water starts on screen: %s" % clip.track_get_key_value(rise, 0))
	h.check(clip.track_get_key_value(rise, last).y <= 0.0, "the water never covers the screen: %s" % clip.track_get_key_value(rise, last))
	# He has finished falling first, and it is up to him before the fade begins.
	h.check(clip.track_get_key_time(show, 0) > 1.3, "the sea arrives while he is still falling")
	var halfway: Vector2 = clip.value_track_interpolate(rise, clip.track_get_key_time(fade, 0))
	h.check(halfway.y < 180.0, "the fade begins with the water only at y=%.0f" % halfway.y)
	h.check(clip.track_get_key_time(fade, 1) < clip.length, "the fade is not finished by the end of the clip")
	# The clip is a picture: a restored world has none of it, and the collapse's outcome does not depend on it.
	h.check(world.get_node("ReturningSea/Water").position.y >= 270.0, "the water rests on screen")


func test_the_water_covers_the_whole_screen_at_its_height(h) -> void:
	var world := await _world(h, AWAKENED)
	var water: Polygon2D = world.get_node("ReturningSea/Water")
	var clip: Animation = world.get_node("Cinematics").get_animation(&"collapse")
	var rise := clip.find_track(NodePath("ReturningSea/Water:position"), Animation.TYPE_VALUE)
	var top: Vector2 = clip.track_get_key_value(rise, clip.track_get_key_count(rise) - 1)
	var box := Rect2(water.polygon[0], Vector2.ZERO)
	for point in water.polygon:
		box = box.expand(point)
	box.position += top
	h.check(box.has_point(Vector2(0, 0)) and box.has_point(Vector2(479, 269)), "the water reaches %s at its height" % box)


## Examining is heard, under the line; pressing a stone is heard only as the stone, with no examining sound on it.
func test_examining_has_a_sound_and_pressing_a_stone_does_not(h) -> void:
	var world := await _world(h, MONOLITH)
	var sound: AudioStreamPlayer = world.get_node("Hud/SoundExamine")
	h.check(sound.stream != null and sound.stream.resource_path.ends_with("examine.ogg"), "examining plays %s" % sound.stream)
	var wav := AudioStreamWAV.new()
	var bytes := PackedByteArray()
	bytes.resize(44100 * 10)
	wav.data = bytes
	sound.stream = wav
	var player := _player(h)
	await h.stand_at(player, Vector2(world.get_node("Monolith/Mural").global_position.x, -2))
	await h.tap_key(KEY_E)
	h.check(sound.playing, "examining the mural is not heard")
	sound.stop()
	await h.stand_at(player, Vector2(world.get_node("Monolith/GlyphKneel").global_position.x, -2))
	await h.tap_key(KEY_E)
	h.check(not sound.playing, "pressing a stone was heard as examining it")
	for path in ["Monolith/StoneAccept", "Monolith/StoneReject", "Hud/Voice"]:
		world.get_node(path).stop()
