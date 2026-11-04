extends RefCounted
## The stones at the monolith in the real world, pressed through the real input path.

const WORLD := "res://scenes/level/shore.tscn"
const MONOLITH_BEAT := 2
const AWAKENED_BEAT := 3
const KNEEL_X := 3990.0
const EYE_X := 4080.0
const WAVE_X := 4170.0
const MURAL_X := 3898.0
const REJECTED_TEXT := "The stones grind and go dark."
const ACCEPTED_TEXT := "The stone lights, and holds."


func _world(h, beat := MONOLITH_BEAT) -> Node2D:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(world)
	await h.landed_on_floor(world.get_node("Player"))
	return world


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("Player")


func _puzzle(h) -> Node:
	return h.fixture.get_node("Monolith/Puzzle")


func _stone(h, stone_name: String) -> Node:
	return h.fixture.get_node("Monolith/" + stone_name)


func _lit(h) -> Array:
	var lit := []
	for stone_name in ["GlyphWave", "GlyphKneel", "GlyphEye"]:
		if _stone(h, stone_name).get_node("Lit").visible:
			lit.append(stone_name)
	return lit


func _caption(h) -> Label:
	return h.fixture.get_node("Hud/Caption")


func _prompt(h) -> Label:
	return h.fixture.get_node("Hud/Prompt")


## Beside a stone, waiting out its cooldown, and pressing as a person would: only if a prompt is showing.
func _press(h, x: float) -> void:
	await h.stand_at(_player(h), Vector2(x, -2))
	await h.tap_key(KEY_E)


func test_the_stones_are_not_in_the_solutions_order_on_the_ground(h) -> void:
	await _world(h)
	var solution: PackedStringArray = _puzzle(h).solution
	h.check(solution == PackedStringArray(["glyph_wave", "glyph_kneel", "glyph_eye"]), "the solution is %s" % str(solution))
	var left_to_right := [_stone(h, "GlyphKneel"), _stone(h, "GlyphEye"), _stone(h, "GlyphWave")]
	h.check(left_to_right[0].global_position.x < left_to_right[1].global_position.x and left_to_right[1].global_position.x < left_to_right[2].global_position.x, "the stones moved")
	h.check(left_to_right.map(func(stone: Node) -> StringName: return stone.interaction_id) != Array(solution).map(func(id: String) -> StringName: return StringName(id)), "the row spells out the answer")


## Three stones sit well apart, so standing at one never offers another.
func test_only_one_stone_is_ever_in_reach(h) -> void:
	await _world(h)
	var interactor: Node = _player(h).get_node("Interactor")
	for pair in [["GlyphKneel", KNEEL_X], ["GlyphEye", EYE_X], ["GlyphWave", WAVE_X]]:
		await h.stand_at(_player(h), Vector2(pair[1], -2))
		h.check(interactor.get_focus() == _stone(h, pair[0]), "at %s the focus is %s" % [pair[0], interactor.get_focus()])
		var names := {"GlyphKneel": "kneeling", "GlyphEye": "eye", "GlyphWave": "wave"}
		h.check(_prompt(h).text == "[E] Press the %s stone" % names[pair[0]], "the prompt reads '%s'" % _prompt(h).text)


func test_pressing_the_stones_in_order_lights_each_and_solves_the_puzzle(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	var accepted := []
	var solved := [0]
	puzzle.step_accepted.connect(func(index: int) -> void: accepted.append(index))
	puzzle.solved.connect(func() -> void: solved[0] += 1)
	h.check(_lit(h).is_empty(), "lit at the start: %s" % str(_lit(h)))
	await _press(h, WAVE_X)
	h.check(_lit(h) == ["GlyphWave"], "lit after the first: %s" % str(_lit(h)))
	h.check(_caption(h).visible and _caption(h).text == ACCEPTED_TEXT, "the caption reads '%s'" % _caption(h).text)
	await _press(h, KNEEL_X)
	h.check(_lit(h) == ["GlyphWave", "GlyphKneel"], "lit after the second: %s" % str(_lit(h)))
	h.check(puzzle.get_progress() == 2, "progress %d" % puzzle.get_progress())
	await _press(h, EYE_X)
	h.check(_lit(h) == ["GlyphWave", "GlyphKneel", "GlyphEye"], "lit after the third: %s" % str(_lit(h)))
	h.check(accepted == [0, 1, 2], "accepted %s" % str(accepted))
	h.check(solved[0] == 1, "solved %d times" % solved[0])
	h.check(puzzle.is_solved(), "not solved")
	h.check(h.fixture.get_node("GameDirector").get_beat() == AWAKENED_BEAT, "the story did not move")


func test_a_wrong_stone_goes_dark_locks_out_and_then_lets_the_player_try_again(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	var failed := [0]
	puzzle.failed.connect(func() -> void: failed[0] += 1)
	await _press(h, WAVE_X)
	h.check(_lit(h) == ["GlyphWave"], "lit after the first: %s" % str(_lit(h)))
	await h.stand_at(_player(h), Vector2(EYE_X, -2))
	await h.tap_key(KEY_E)
	h.check(failed[0] == 1, "failed %d times" % failed[0])
	h.check(_lit(h).is_empty(), "lit after a wrong stone: %s" % str(_lit(h)))
	h.check(_caption(h).text == REJECTED_TEXT, "the caption reads '%s'" % _caption(h).text)
	h.check(puzzle.is_rejecting(), "not locked out")
	h.check(puzzle.get_progress() == 0, "progress kept: %d" % puzzle.get_progress())

	# During the lockout a press reaches nothing, and the prompt says so by being gone.
	await h.steps(2)
	h.check(not _prompt(h).visible, "a prompt during the lockout: '%s'" % _prompt(h).text)
	await h.tap_key(KEY_E)
	h.check(puzzle.is_rejecting() and failed[0] == 1, "a press during the lockout counted")
	puzzle.submit(&"glyph_wave")
	h.check(_lit(h).is_empty(), "a direct submit during the lockout lit a stone")

	await h.wait_until(func() -> bool: return not puzzle.is_rejecting(), 70, "the lockout to end")
	await h.steps(2)
	h.check(_prompt(h).visible, "no prompt after the lockout")
	h.check(_lit(h).is_empty(), "lit after the lockout: %s" % str(_lit(h)))
	await _press(h, WAVE_X)
	await _press(h, KNEEL_X)
	await _press(h, EYE_X)
	h.check(puzzle.is_solved(), "the stones could not be solved after a failure")


func test_the_lockout_lasts_its_delay_and_stops_while_paused(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	h.check_near(puzzle.reset_delay, 1.0, 0.0, "the default delay")
	puzzle.submit(&"glyph_eye")
	h.check(puzzle.is_rejecting(), "not locked out")
	await h.steps(55)
	h.check(puzzle.is_rejecting(), "the lockout ended early")
	h.tree.paused = true
	await h.steps(60)
	h.check(puzzle.is_rejecting(), "the lockout ran while paused")
	h.tree.paused = false
	await h.wait_until(func() -> bool: return not puzzle.is_rejecting(), 10, "the lockout to end")


func test_pressing_a_lit_stone_again_does_nothing_and_costs_nothing(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	var failed := [0]
	var accepted := []
	puzzle.failed.connect(func() -> void: failed[0] += 1)
	puzzle.step_accepted.connect(func(index: int) -> void: accepted.append(index))
	await _press(h, WAVE_X)
	var stone := _stone(h, "GlyphWave")
	await h.wait_until(stone.is_available, 40, "the stone's cooldown")
	await h.tap_key(KEY_E)
	await h.wait_until(stone.is_available, 40, "the stone's cooldown")
	await h.tap_key(KEY_E)
	h.check(accepted == [0], "accepted %s" % str(accepted))
	h.check(failed[0] == 0, "a repeated press failed")
	h.check(_lit(h) == ["GlyphWave"], "lit: %s" % str(_lit(h)))
	h.check(puzzle.get_progress() == 1, "progress %d" % puzzle.get_progress())
	await _press(h, KNEEL_X)
	await _press(h, WAVE_X)
	h.check(puzzle.get_progress() == 2, "an earlier lit stone cost progress: %d" % puzzle.get_progress())
	h.check(failed[0] == 0, "an earlier lit stone failed")


func test_mashing_one_press_through_the_cooldown_counts_once(h) -> void:
	await _world(h)
	var accepted := []
	_puzzle(h).step_accepted.connect(func(index: int) -> void: accepted.append(index))
	await h.stand_at(_player(h), Vector2(WAVE_X, -2))
	for i in 5:
		await h.tap_key(KEY_E)
	h.check(accepted == [0], "five quick presses gave %s" % str(accepted))


func test_every_order_of_stones_that_fails_can_still_go_on_to_solve_it(h) -> void:
	for first in [&"glyph_kneel", &"glyph_eye"]:
		await _world(h)
		var puzzle := _puzzle(h)
		puzzle.submit(first)
		h.check(puzzle.is_rejecting(), "%s was accepted" % first)
		await h.steps(62)
		for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
			puzzle.submit(id)
		h.check(puzzle.is_solved(), "not solved after failing with %s" % first)
		await h.steps(2)
		await h.unload_fixture()


func test_solved_is_terminal_and_the_stones_stop_reacting(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	var signals := [0]
	var director: Node = h.fixture.get_node("GameDirector")
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		puzzle.submit(id)
	puzzle.step_accepted.connect(func(_index: int) -> void: signals[0] += 1)
	puzzle.failed.connect(func() -> void: signals[0] += 1)
	puzzle.solved.connect(func() -> void: signals[0] += 1)
	await h.wait_until(func() -> bool: return not director.is_cinematic_active(), 400, "the cinematic to finish")
	for stone_name in ["GlyphWave", "GlyphKneel", "GlyphEye"]:
		h.check(not _stone(h, stone_name).enabled, "%s still reacts" % stone_name)
	await h.stand_at(_player(h), Vector2(WAVE_X, -2))
	h.check(not _prompt(h).visible, "a solved stone offers: '%s'" % _prompt(h).text)
	await h.tap_key(KEY_E)
	for id in [&"glyph_wave", &"glyph_eye", &"glyph_kneel"]:
		puzzle.submit(id)
	puzzle.reset()
	h.check(puzzle.is_solved(), "solved was undone")
	h.check(_lit(h).size() == 3, "lit: %s" % str(_lit(h)))
	h.check(signals[0] == 0, "a solved puzzle emitted %d signals" % signals[0])


func test_an_unknown_id_is_a_reported_wiring_bug_with_no_effect(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	var trap := []
	puzzle.submit(&"glyph_wave")
	puzzle.failed.connect(func() -> void: trap.append("failed"))
	puzzle.step_accepted.connect(func(_index: int) -> void: trap.append("accepted"))
	h.quiet_errors()
	puzzle.submit(&"not_a_stone")
	h.loud_errors()
	h.check(trap.is_empty(), "an unknown id gave %s" % str(trap))
	h.check(puzzle.get_progress() == 1 and not puzzle.is_rejecting(), "an unknown id changed the attempt")


func test_reset_clears_an_attempt_and_a_lockout(h) -> void:
	await _world(h)
	var puzzle := _puzzle(h)
	puzzle.submit(&"glyph_wave")
	puzzle.reset()
	h.check(puzzle.get_progress() == 0, "progress kept")
	h.check(_lit(h).is_empty(), "lit: %s" % str(_lit(h)))
	puzzle.submit(&"glyph_eye")
	h.check(puzzle.is_rejecting(), "not locked out")
	puzzle.reset()
	h.check(not puzzle.is_rejecting(), "still locked out")
	h.check(_stone(h, "GlyphEye").enabled, "a stone stayed disabled")


func test_the_mural_reads_differently_before_and_after_and_a_missing_clip_changes_nothing_about_that(h) -> void:
	await _world(h)
	var mural: Node = h.fixture.get_node("Monolith/Mural")
	var before: String = mural.caption
	h.check(before.contains("Ruins"), "the first caption reads '%s'" % before)
	h.check(not before.contains("swimmer"), "the first caption gives it away: '%s'" % before)
	h.check(not h.fixture.get_node("Monolith/MuralLit").visible, "the mural is lit before solving")
	await _press(h, MURAL_X)
	h.check(_caption(h).text == before, "examining shows '%s'" % _caption(h).text)

	var clips: AnimationPlayer = h.fixture.get_node("Cinematics")
	var library: AnimationLibrary = clips.get_animation_library(&"").duplicate(true)
	clips.remove_animation_library(&"")
	library.remove_animation(&"monolith_awaken")
	clips.add_animation_library(&"", library)
	h.quiet_errors()
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		_puzzle(h).submit(id)
	h.loud_errors()
	await h.steps(2)
	h.check(mural.caption.contains("swimmer"), "the second caption reads '%s'" % mural.caption)
	h.check(mural.caption != before, "the caption did not change")
	h.check(h.fixture.get_node("Monolith/MuralLit").visible, "the mural did not light")
	await h.wait_until(mural.is_available, 40, "the mural's cooldown")
	await _press(h, MURAL_X)
	h.check(_caption(h).text == mural.caption, "examining shows '%s'" % _caption(h).text)


func test_each_tablet_shows_its_own_line_in_the_story_order(h) -> void:
	var world: Node = await _world(h)
	var tablets := [world.get_node("Props/TabletWave"), world.get_node("Props/TabletKneel"), world.get_node("Props/TabletEye")]
	h.check(tablets[0].global_position.x < tablets[1].global_position.x and tablets[1].global_position.x < tablets[2].global_position.x, "the tablets are out of order along the walk")
	for pair in [[0, "The waters rose first"], [1, "they bowed"], [2, "He saw them"]]:
		h.check(tablets[pair[0]].caption.contains(pair[1]), "tablet %d reads '%s'" % [pair[0], tablets[pair[0]].caption])
		h.check(not tablets[pair[0]].one_shot, "a tablet is one-shot")
	for tablet in tablets:
		await h.stand_at(_player(h), Vector2(tablet.global_position.x, -2))
		await h.tap_key(KEY_E)
		h.check(_caption(h).text == tablet.caption, "at %s the caption reads '%s'" % [tablet.name, _caption(h).text])
