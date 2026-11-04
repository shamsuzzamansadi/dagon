extends RefCounted
## The cinematic contract, architecture §5 and §8, on a small arena whose clips last a quarter of a second.
## A test that meets a broken clip names the error it expects, and any other error still fails it.

const ARENA := "res://tests/fixtures/story_arena.tscn"
const SHORE := 0
const ABYSS := 1
const MONOLITH := 2
const AWAKENED := 3
const WITNESS := 4
const FLEEING := 5
const ENDED := 6
const ENTER_ABYSS_X := 300.0
const REACH_MONOLITH_X := 500.0
const COLLAPSE_X := 620.0
const WITNESS_X := 860.0
const CHECKPOINT_X := [100.0, 350.0, 550.0, 760.0]
## Nothing is near here.
const CLEAR := Vector2(200, -2)


func _arena(h, beat := SHORE, as_main := false) -> Node2D:
	var arena: Node2D = (load(ARENA) as PackedScene).instantiate()
	arena.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(arena, as_main)
	await h.landed_on_floor(arena.get_node("Player"))
	return arena


func _director(h) -> Node:
	return h.fixture.get_node("GameDirector")


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("Player")


func _camera(h) -> Camera2D:
	return h.fixture.get_node("CameraRig")


func _clips(h) -> AnimationPlayer:
	return h.fixture.get_node("Cinematics")


func _gate(h) -> StaticBody2D:
	return h.fixture.get_node("Gate")


## A clip library this test can change: the loaded scene shares its own with every later instance.
func _own_clips(h) -> AnimationLibrary:
	var clips := _clips(h)
	var library: AnimationLibrary = clips.get_animation_library(&"").duplicate(true)
	clips.remove_animation_library(&"")
	clips.add_animation_library(&"", library)
	return library


func _break_clip(h, clip: StringName, how: String) -> void:
	var library := _own_clips(h)
	match how:
		"missing":
			library.remove_animation(clip)
		"looping":
			library.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		"linear_ping_pong":
			library.get_animation(clip).loop_mode = Animation.LOOP_PINGPONG
		"stuck":
			_clips(h).speed_scale = 0.0


## What the Director must say for each failure. The watchdog would rescue the others anyway, so this is what tells them apart.
func _reason(how: String) -> String:
	return {"missing": "missing", "looping": "loops", "linear_ping_pong": "loops", "stuck": "deadline"}[how]


func _log_beats(h) -> Array:
	var beats := []
	_director(h).beat_changed.connect(func(beat: int) -> void: beats.append(beat))
	return beats


func _solve(h) -> void:
	h.fixture.get_node("Puzzle").submit(&"one")


func _finish_clip(h) -> void:
	await h.wait_until(func() -> bool: return not _director(h).is_cinematic_active(), 300, "the cinematic to finish")


func _settle(h) -> void:
	await h.steps(4)


## Into the reveal's trigger, and no longer than it takes the clip to start. The clips here are shorter than stand_at.
func _enter_witness(h) -> void:
	_player(h).teleport(Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return _director(h).is_cinematic_active(), 8, "the reveal to start")


func _at_fleeing(h) -> void:
	await _arena(h, AWAKENED, true)
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	h.check(_director(h).get_beat() == FLEEING, "not fleeing: beat %d" % _director(h).get_beat())


func _check_camera_is_back(h, what: String) -> void:
	var camera := _camera(h)
	h.check(camera.get_target() == _player(h), "%s: the camera follows %s" % [what, camera.get_target()])
	h.check(camera.zoom == Vector2.ONE, "%s: zoom is %s" % [what, camera.zoom])
	h.check(camera.limit_top == -220, "%s: limit_top is %d" % [what, camera.limit_top])
	h.check(is_zero_approx(camera.get_trauma()), "%s: shake remains: %.2f" % [what, camera.get_trauma()])
	h.check(camera.offset == Vector2.ZERO, "%s: offset is %s" % [what, camera.offset])


## ---- The route through the beats ----


func test_the_beats_run_in_order_each_entered_once(h) -> void:
	await _arena(h, SHORE, true)
	var director := _director(h)
	var beats := _log_beats(h)
	var saved := []
	director.checkpoint_reached.connect(func(beat: int) -> void: saved.append(beat))
	h.check(director.get_beat() == SHORE, "started at beat %d" % director.get_beat())
	await h.stand_at(_player(h), Vector2(ENTER_ABYSS_X, -2))
	await h.stand_at(_player(h), Vector2(REACH_MONOLITH_X, -2))
	await h.stand_at(_player(h), Vector2(CHECKPOINT_X[2], -2))
	_solve(h)
	h.check(director.is_cinematic_active(), "solving started no cinematic")
	await _finish_clip(h)
	h.check(director.get_beat() == AWAKENED, "beat %d after the first cinematic" % director.get_beat())
	await h.stand_at(_player(h), Vector2(CHECKPOINT_X[3], -2))
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	h.check(director.get_beat() == FLEEING, "beat %d after the reveal" % director.get_beat())
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 20, "collapse to fire")
	h.check(beats == [ABYSS, MONOLITH, AWAKENED, WITNESS, FLEEING, ENDED], "beats ran %s" % str(beats))
	h.check(saved == [ABYSS, MONOLITH, AWAKENED], "checkpoints reached %s" % str(saved))


func test_reentering_a_trigger_gives_one_beat(h) -> void:
	await _arena(h)
	var beats := _log_beats(h)
	for i in 3:
		await h.stand_at(_player(h), Vector2(ENTER_ABYSS_X, -2))
		await h.stand_at(_player(h), Vector2(ENTER_ABYSS_X - 50.0, -2))
	h.check(beats == [ABYSS], "three entries gave %s" % str(beats))
	h.check(not h.fixture.get_node("EnterAbyss").enabled, "the accepted trigger was not consumed")


## The example in the architecture: the way out over collapse is refused, and consumes nothing.
func test_the_outbound_crossing_of_collapse_is_rejected_and_fires_later_in_fleeing(h) -> void:
	await _arena(h, MONOLITH, true)
	var director := _director(h)
	var collapse: Area2D = h.fixture.get_node("Collapse")
	var beats := _log_beats(h)
	await h.stand_at(_player(h), Vector2(COLLAPSE_X, -2))
	h.check(beats.is_empty(), "the outbound crossing gave %s" % str(beats))
	h.check(collapse.enabled, "the outbound crossing consumed the trigger")
	_solve(h)
	await _finish_clip(h)
	await h.stand_at(_player(h), Vector2(COLLAPSE_X, -2))
	h.check(director.get_beat() == AWAKENED, "a crossing at Awakened moved the story to %d" % director.get_beat())
	h.check(collapse.enabled, "a crossing at Awakened consumed the trigger")
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	h.check(director.get_beat() == FLEEING, "not fleeing: %d" % director.get_beat())
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 20, "the return crossing to fire")
	h.check(not collapse.enabled, "the accepted crossing was not consumed")


func test_a_player_already_in_the_awaited_trigger_when_a_beat_begins_fires_it(h) -> void:
	await _arena(h)
	var director := _director(h)
	var beats := _log_beats(h)
	await h.stand_at(_player(h), Vector2(REACH_MONOLITH_X, -2))
	h.check(beats.is_empty(), "standing there early gave %s" % str(beats))
	# The earlier trigger comes to the player, who never leaves the later one.
	h.fixture.get_node("EnterAbyss").position.x = REACH_MONOLITH_X
	await h.wait_until(func() -> bool: return director.get_beat() == MONOLITH, 12, "the awaited trigger to fire")
	h.check(beats == [ABYSS, MONOLITH], "the beats ran %s" % str(beats))


func test_a_restored_player_standing_in_the_awaited_trigger_fires_it(h) -> void:
	var arena: Node2D = (load(ARENA) as PackedScene).instantiate()
	arena.get_node("GameDirector").set_start_beat(ABYSS)
	arena.get_node("Checkpoint1").position.x = REACH_MONOLITH_X
	await h.load_with(arena)
	await h.wait_until(func() -> bool: return _director(h).get_beat() == MONOLITH, 12, "the awaited trigger to fire")


func test_a_rejected_event_is_rejected_everywhere_and_consumes_nothing(h) -> void:
	await _arena(h)
	var director := _director(h)
	var beats := _log_beats(h)
	for x in [REACH_MONOLITH_X, COLLAPSE_X, WITNESS_X]:
		await h.stand_at(_player(h), Vector2(x, -2))
	director.on_puzzle_solved()
	h.check(beats.is_empty(), "out-of-order events gave %s" % str(beats))
	for trigger_name in ["ReachMonolith", "Collapse", "Witness"]:
		h.check(h.fixture.get_node(trigger_name).enabled, "%s was consumed by a rejection" % trigger_name)


## Should the stones ever be solved early, the story takes it up when it arrives, and no one is stuck.
func test_a_puzzle_solved_before_its_beat_is_taken_up_when_the_beat_begins(h) -> void:
	await _arena(h, ABYSS)
	var director := _director(h)
	_solve(h)
	h.check(director.get_beat() == ABYSS, "an early solve moved the story to %d" % director.get_beat())
	await h.stand_at(_player(h), Vector2(REACH_MONOLITH_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == AWAKENED, 30, "the solve to be taken up")


## Crossing collapse is dropped during the reveal, so only the recheck can notice someone still standing in it.
func test_a_player_still_inside_collapse_when_the_flee_begins_ends_it_at_once(h) -> void:
	await _arena(h, AWAKENED, true)
	var director := _director(h)
	h.fixture.get_node("Collapse").position.x = WITNESS_X
	_player(h).teleport(Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 40, "the flee to begin")
	h.check(director.get_beat() == FLEEING, "the flee did not begin")
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 8, "the recheck to find the player in collapse")


## ---- Locks and the camera ----


func test_a_cinematic_locks_control_and_its_end_gives_it_back(h) -> void:
	await _arena(h, MONOLITH)
	var player := _player(h)
	var director := _director(h)
	await h.stand_at(player, Vector2(CHECKPOINT_X[2], -2))
	h.check(player.is_control_enabled(), "no control before the cinematic")
	h.check(director.is_safe_to_save(), "not safe to save before the cinematic")
	_solve(h)
	h.check(not player.is_control_enabled(), "the cinematic did not lock control")
	h.check(not director.is_safe_to_save(), "safe to save during a cinematic")
	var x := player.global_position.x
	Input.action_press("move_right")
	await h.steps(8)
	Input.action_release("move_right")
	h.check_near(player.global_position.x, x, 0.5, "x while locked")
	h.check(player.get_node("Interactor").get_focus() == null, "something has focus during a cinematic")
	await _finish_clip(h)
	h.check(player.is_control_enabled(), "the cinematic's end did not give control back")
	h.check(director.is_safe_to_save(), "not safe to save after the cinematic")
	Input.action_press("move_right")
	await h.steps(10)
	Input.action_release("move_right")
	h.check(player.global_position.x > x + 3.0, "the player could not move afterwards")


func test_a_clip_moves_the_camera_and_finalizing_puts_it_back(h) -> void:
	await _arena(h, MONOLITH)
	_solve(h)
	await h.wait_until(func() -> bool: return _camera(h).get_target() == h.fixture.get_node("Mark"), 30, "the clip to aim the camera")
	h.check(_camera(h).zoom != Vector2.ONE, "the clip did not zoom")
	h.check(_camera(h).limit_top == -900, "the clip did not move the limit: %d" % _camera(h).limit_top)
	await _finish_clip(h)
	_check_camera_is_back(h, "after the clip")


func test_the_reveal_keeps_control_locked_right_up_to_reveal_done(h) -> void:
	await _arena(h, AWAKENED)
	var director := _director(h)
	var seen := []
	director.cinematic_finalized.connect(func(clip: StringName, _generation: int) -> void:
		seen.append([clip, _player(h).is_control_enabled(), director.get_beat()]))
	director.beat_changed.connect(func(beat: int) -> void:
		seen.append([beat, _player(h).is_control_enabled()]))
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	h.check(seen[0] == [WITNESS, true], "entering the Witness gave %s" % str(seen[0]))
	h.check(seen[1] == [&"dagon_reveal", false, WITNESS], "finalizing the reveal gave %s" % str(seen[1]))
	h.check(seen[2][0] == FLEEING, "next came %s" % str(seen[2]))
	h.check(_player(h).is_control_enabled(), "the flee did not give control back")


func test_each_clip_is_a_real_animation_that_really_plays(h) -> void:
	await _arena(h, MONOLITH)
	var clips := _clips(h)
	_solve(h)
	h.check(clips.is_playing() and clips.current_animation == &"monolith_awaken", "playing '%s'" % clips.current_animation)
	await h.steps(2)
	h.check(clips.current_animation_position > 0.0, "the clip did not advance")


## ---- The three ways a clip can fail ----


func _check_awaken_recovered(h, how: String) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var errors := []
	var saved := []
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	director.checkpoint_reached.connect(func(beat: int) -> void: saved.append(beat))
	_break_clip(h, &"monolith_awaken", how)
	h.expect_error(_reason(how))
	_solve(h)
	await _finish_clip(h)
	await _settle(h)
	h.check(errors.size() == 1 and errors[0].contains(_reason(how)), "%s: reported %s" % [how, str(errors)])
	h.check(director.get_beat() == AWAKENED, "%s: beat %d" % [how, director.get_beat()])
	h.check(_gate(h).collision_layer == 0, "%s: the gate stayed solid" % how)
	h.check(not _gate(h).visible, "%s: the gate stayed visible" % how)
	h.check(h.fixture.get_node("Mural").caption == "after", "%s: the mural reads '%s'" % [how, h.fixture.get_node("Mural").caption])
	h.check(h.fixture.get_node("MuralLit").visible, "%s: the mural is not lit" % how)
	h.check(_player(h).is_control_enabled(), "%s: control stayed locked" % how)
	h.check(saved == [AWAKENED], "%s: checkpoints reached %s" % [how, str(saved)])
	_check_camera_is_back(h, how)
	h.check(not _clips(h).is_playing(), "%s: a clip is still playing" % how)
	# And the way is really open.
	await h.stand_at(_player(h), Vector2(CHECKPOINT_X[3], -2))
	Input.action_press("move_right")
	await h.wait_until(func() -> bool: return _player(h).global_position.x > 810.0, 90, "the player to walk through the gate (%s)" % how)
	Input.action_release("move_right")


func test_a_missing_awaken_clip_still_opens_the_gate_and_returns_control(h) -> void:
	await _check_awaken_recovered(h, "missing")


func test_a_looping_awaken_clip_is_refused_and_recovers(h) -> void:
	await _check_awaken_recovered(h, "looping")


func test_a_ping_pong_awaken_clip_is_refused_and_recovers(h) -> void:
	await _check_awaken_recovered(h, "linear_ping_pong")


func test_a_stuck_awaken_clip_is_ended_by_the_watchdog(h) -> void:
	await _check_awaken_recovered(h, "stuck")


func _check_reveal_recovered(h, how: String) -> void:
	await _arena(h, AWAKENED)
	var director := _director(h)
	var errors := []
	var beats := _log_beats(h)
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	_break_clip(h, &"dagon_reveal", how)
	h.expect_error(_reason(how))
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	h.check(errors.size() == 1 and errors[0].contains(_reason(how)), "%s: reported %s" % [how, str(errors)])
	h.check(beats == [WITNESS, FLEEING], "%s: beats ran %s" % [how, str(beats)])
	h.check(_player(h).is_control_enabled(), "%s: control stayed locked" % how)
	_check_camera_is_back(h, how)
	h.check(director.get_flee_elapsed() < 1.0, "%s: the flee timer is at %.2f" % [how, director.get_flee_elapsed()])
	h.check(not h.fixture.get_node("Witness").enabled, "%s: the reveal's trigger is still armed" % how)
	h.check(h.fixture.get_node("Collapse").enabled, "%s: collapse is not armed" % how)


func test_a_missing_reveal_clip_still_raises_reveal_done_once(h) -> void:
	await _check_reveal_recovered(h, "missing")


func test_a_looping_reveal_clip_still_raises_reveal_done_once(h) -> void:
	await _check_reveal_recovered(h, "looping")


func test_a_stuck_reveal_clip_still_raises_reveal_done_once(h) -> void:
	await _check_reveal_recovered(h, "stuck")


func _check_collapse_recovered(h, how: String) -> void:
	await _arena(h, AWAKENED, true)
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	h.check(_director(h).get_beat() == FLEEING, "%s: not fleeing" % how)
	var errors := []
	_director(h).contract_error.connect(func(message: String) -> void: errors.append(message))
	_break_clip(h, &"collapse", how)
	h.expect_error(_reason(how))
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	var ending: Node = await h.wait_for_scene("MenuController", 240)
	h.check(errors.size() == 1 and errors[0].contains(_reason(how)), "%s: reported %s" % [how, str(errors)])
	h.check(ending.get_node_or_null("Center/Card") != null, "%s: the scene after the collapse is %s" % [how, ending.name])
	h.check(not h.tree.paused, "%s: the ending is paused" % how)


func test_a_missing_collapse_clip_still_reaches_the_ending(h) -> void:
	await _check_collapse_recovered(h, "missing")


func test_a_looping_collapse_clip_still_reaches_the_ending(h) -> void:
	await _check_collapse_recovered(h, "looping")


func test_a_stuck_collapse_clip_still_reaches_the_ending(h) -> void:
	await _check_collapse_recovered(h, "stuck")


func test_a_scene_with_no_clip_player_at_all_still_progresses(h) -> void:
	var arena: Node2D = (load(ARENA) as PackedScene).instantiate()
	var director: Node = arena.get_node("GameDirector")
	director.cinematics_path = NodePath("")
	director.set_start_beat(MONOLITH)
	await h.load_with(arena)
	var errors := []
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	h.expect_error("missing")
	_solve(h)
	await _settle(h)
	h.check(errors.size() == 1, "reported %s" % str(errors))
	h.check(director.get_beat() == AWAKENED, "beat %d" % director.get_beat())
	h.check(_gate(h).collision_layer == 0, "the gate stayed solid")
	h.check(_player(h).is_control_enabled(), "control stayed locked")


func test_the_watchdog_stops_a_stuck_clip_so_its_method_track_cannot_move_the_camera(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var errors := []
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	var clips := _clips(h)
	h.check(director.start_cinematic(&"late_aim"), "the clip did not start")
	clips.speed_scale = 0.0
	h.expect_error("deadline")
	await _finish_clip(h)
	h.check(errors.size() == 1, "reported %s" % str(errors))
	h.check(not clips.is_playing(), "the watchdog left the clip playing")
	clips.speed_scale = 1.0
	await h.steps(45)
	h.check(_camera(h).get_target() == _player(h), "the stuck clip moved the camera after finalization")


func test_the_watchdog_waits_for_the_clips_own_length_plus_the_margin(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	director.start_cinematic(&"side_show")
	_clips(h).speed_scale = 0.0
	# 0.25 s of clip and 2 s of margin: 135 frames.
	await h.steps(125)
	h.check(director.is_cinematic_active(), "the watchdog fired early")
	h.expect_error("deadline")
	await h.steps(20)
	h.check(not director.is_cinematic_active(), "the watchdog did not fire")


## ---- Reentrancy and stale completions ----


func test_starting_a_cinematic_during_one_is_refused_and_leaves_it_untouched(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var errors := []
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	h.check(director.start_cinematic(&"side_show"), "the first did not start")
	var generation: int = director.get_generation()
	await h.steps(2)
	h.expect_error("refused")
	h.check(not director.start_cinematic(&"late_aim"), "the second was not refused")
	h.check(errors.size() == 1, "reported %s" % str(errors))
	h.check(director.is_cinematic_active() and director.get_active_clip() == &"side_show", "the active one is now '%s'" % director.get_active_clip())
	h.check(director.get_generation() == generation, "the generation moved")
	h.check(_clips(h).current_animation == &"side_show", "the player now plays '%s'" % _clips(h).current_animation)
	await _finish_clip(h)
	h.check(_player(h).is_control_enabled(), "control did not come back")


func test_a_duplicate_completion_applies_the_outcome_once(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var finalized := []
	var saved := []
	director.cinematic_finalized.connect(func(clip: StringName, generation: int) -> void: finalized.append([clip, generation]))
	director.checkpoint_reached.connect(func(beat: int) -> void: saved.append(beat))
	_solve(h)
	var generation: int = director.get_generation()
	await _finish_clip(h)
	h.check(finalized.size() == 1, "finalized %s" % str(finalized))
	_clips(h).animation_finished.emit(&"monolith_awaken")
	director.finalize_cinematic(generation)
	director.finalize_cinematic(generation)
	await _settle(h)
	h.check(finalized.size() == 1, "duplicates finalized %s" % str(finalized))
	h.check(saved == [AWAKENED], "duplicates reached %s" % str(saved))


func test_a_duplicate_reveal_completion_raises_reveal_done_once(h) -> void:
	await _arena(h, AWAKENED)
	var director := _director(h)
	var beats := _log_beats(h)
	await _enter_witness(h)
	var generation: int = director.get_generation()
	# Twice in the same frame, before the deferred step has had a chance to run.
	director.finalize_cinematic(generation)
	director.finalize_cinematic(generation)
	_clips(h).animation_finished.emit(&"dagon_reveal")
	await _settle(h)
	h.check(beats == [WITNESS, FLEEING], "the beats ran %s" % str(beats))


func test_a_stale_completion_has_no_effect_on_a_newer_cinematic(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var player := _player(h)
	director.start_cinematic(&"side_show")
	var old_generation: int = director.get_generation()
	director.finalize_cinematic(old_generation)
	await _settle(h)
	director.start_cinematic(&"side_show")
	var new_generation: int = director.get_generation()
	h.check(new_generation > old_generation, "the generation did not grow")
	await h.steps(3)
	var camera_target: Node = _camera(h).get_target()
	h.check(camera_target == h.fixture.get_node("Mark"), "the new clip did not aim the camera")
	director.finalize_cinematic(old_generation)
	await h.steps(1)
	h.check(director.is_cinematic_active(), "a stale finalize ended the newer cinematic")
	h.check(not player.is_control_enabled(), "a stale finalize gave control back")
	h.check(_camera(h).get_target() == camera_target, "a stale finalize moved the camera")
	h.check(_clips(h).is_playing(), "a stale finalize stopped the clip")


func test_a_completion_for_another_clip_is_ignored(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	director.start_cinematic(&"side_show")
	_clips(h).animation_finished.emit(&"late_aim")
	_clips(h).animation_finished.emit(&"monolith_awaken")
	await h.steps(1)
	h.check(director.is_cinematic_active(), "another clip's completion ended this one")
	await _finish_clip(h)


## ---- Events held back during a cinematic ----


func test_a_trigger_during_a_cinematic_is_dropped_unconsumed_and_rechecked_after(h) -> void:
	await _arena(h, ABYSS)
	var director := _director(h)
	var beats := _log_beats(h)
	director.start_cinematic(&"side_show")
	_player(h).teleport(Vector2(REACH_MONOLITH_X, -2))
	await h.steps(5)
	h.check(beats.is_empty(), "a trigger moved the story during a cinematic: %s" % str(beats))
	h.check(h.fixture.get_node("ReachMonolith").enabled, "a dropped trigger was consumed")
	await _finish_clip(h)
	await h.wait_until(func() -> bool: return director.get_beat() == MONOLITH, 12, "the recheck to find the trigger")
	h.check(beats == [MONOLITH], "the beats ran %s" % str(beats))


func test_a_puzzle_solved_during_a_cinematic_waits_in_the_pending_slot(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var beats := _log_beats(h)
	director.start_cinematic(&"side_show")
	_solve(h)
	h.check(director.has_pending_event(), "the event is not pending")
	h.check(beats.is_empty(), "the event was applied during the cinematic: %s" % str(beats))
	await h.wait_until(func() -> bool: return beats == [AWAKENED], 30, "the pending event to apply")
	h.check(not director.has_pending_event(), "the event stayed pending")
	h.check(director.is_cinematic_active() and director.get_active_clip() == &"monolith_awaken", "the pending event did not start its cinematic: '%s'" % director.get_active_clip())
	await _finish_clip(h)


func test_a_second_pending_event_is_a_reported_logic_error(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var errors := []
	var beats := _log_beats(h)
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	director.start_cinematic(&"side_show")
	director.on_puzzle_solved()
	h.expect_error("pending")
	director.on_puzzle_solved()
	h.check(errors.size() == 1 and errors[0].contains("pending"), "reported %s" % str(errors))
	await h.wait_until(func() -> bool: return beats == [AWAKENED], 30, "the one pending event to apply")
	await _finish_clip(h)
	h.check(beats == [AWAKENED], "the beats ran %s" % str(beats))


## RevealDone comes first, then the pending event, then the fresh recheck.
func test_after_a_cinematic_the_steps_run_in_their_order(h) -> void:
	await _arena(h, AWAKENED)
	var director := _director(h)
	var log := []
	director.beat_changed.connect(func(beat: int) -> void: log.append(["beat", beat, Engine.get_physics_frames()]))
	director.cinematic_finalized.connect(func(clip: StringName, _generation: int) -> void: log.append(["finalized", clip, Engine.get_physics_frames()]))
	director.overlap_rechecked.connect(func(frame: int) -> void: log.append(["rechecked", frame]))
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await _finish_clip(h)
	await _settle(h)
	var names := log.map(func(entry: Array) -> Variant: return entry[1] if entry[0] != "rechecked" else "rechecked")
	var from: int = names.find(&"dagon_reveal")
	h.check(from >= 0, "no finalization in %s" % str(log))
	h.check(names.slice(from, from + 3) == [&"dagon_reveal", FLEEING, "rechecked"], "the steps ran %s" % str(names.slice(from)))


## The next trigger is already under the player when the first cinematic ends. The second must keep its own lock
## and camera, whatever the first one's finalizer did.
func test_a_trigger_already_overlapping_during_finalization_starts_a_cinematic_that_keeps_its_lock_and_camera(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var player := _player(h)
	var beats := _log_beats(h)
	await h.stand_at(player, Vector2(WITNESS_X, -2))
	h.check(beats.is_empty(), "the Witness trigger fired early: %s" % str(beats))
	h.check(h.fixture.get_node("Witness").is_player_inside(), "the player is not in the trigger")
	_solve(h)
	h.check(director.get_active_clip() == &"monolith_awaken", "playing '%s'" % director.get_active_clip())
	await h.wait_until(func() -> bool: return director.get_active_clip() == &"dagon_reveal", 60, "the second cinematic to start")
	h.check(beats == [AWAKENED, WITNESS], "the beats ran %s" % str(beats))
	h.check(not player.is_control_enabled(), "the first finalizer overwrote the second's lock")
	await h.wait_until(func() -> bool: return _camera(h).get_target() == h.fixture.get_node("Mark"), 12, "the second clip to aim the camera")
	# Long enough for anything left over from the first to have arrived.
	await h.steps(4)
	h.check(_camera(h).get_target() == h.fixture.get_node("Mark"), "the first finalizer overwrote the second's camera")
	h.check(not player.is_control_enabled(), "control came back during the second cinematic")
	await _finish_clip(h)
	await _settle(h)
	h.check(director.get_beat() == FLEEING, "beat %d after the second cinematic" % director.get_beat())
	h.check(player.is_control_enabled(), "control did not come back in the end")
	_check_camera_is_back(h, "after both")


## ---- call_deferred is not a physics step ----


## The overlap list is stale inside the deferred flush. A player teleported out as the clip ends is still listed
## as inside at that moment, and a check made then would fire for someone who has left.
func test_the_recheck_never_trusts_an_overlap_list_from_before_the_physics_step(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var player := _player(h)
	var beats := _log_beats(h)
	await h.stand_at(player, Vector2(WITNESS_X, -2))
	director.cinematic_finalized.connect(func(_clip: StringName, _generation: int) -> void: player.teleport(CLEAR))
	_solve(h)
	await _finish_clip(h)
	h.check(h.fixture.get_node("Witness").is_player_inside(), "the list is already fresh: this test no longer proves anything")
	await _settle(h)
	await h.steps(6)
	h.check(beats == [AWAKENED], "a stale overlap list fired the trigger: %s" % str(beats))
	h.check(h.fixture.get_node("Witness").enabled, "a stale overlap list consumed the trigger")


## Exact frames, as the architecture said to verify here (docs/evidence/m3/overlap-latency.txt). A clip ends in the
## idle phase, too late for that frame's server step, so a move made then reaches the overlap list three frames on.
func test_the_recheck_runs_three_physics_frames_after_an_idle_finalization_with_fresh_overlaps(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var player := _player(h)
	var finalized_frame := [-1]
	var entered_frame := [-1]
	var rechecked_frame := [-1]
	var inside_at_recheck := [false]
	var trigger: Area2D = h.fixture.get_node("Witness")
	# Disabled as a story trigger, so that only the overlap list changes and the story stays where it is.
	director.cinematic_finalized.connect(func(_clip: StringName, _generation: int) -> void:
		finalized_frame[0] = Engine.get_physics_frames()
		h.check(not Engine.is_in_physics_frame(), "the clip ended inside a physics frame, so this measures something else")
		trigger.enabled = false
		player.teleport(Vector2(WITNESS_X, -2)))
	trigger.body_entered.connect(func(_body: Node2D) -> void: entered_frame[0] = Engine.get_physics_frames())
	director.overlap_rechecked.connect(func(frame: int) -> void:
		rechecked_frame[0] = frame
		inside_at_recheck[0] = trigger.is_player_inside())
	_solve(h)
	await _finish_clip(h)
	await h.steps(6)
	h.check(finalized_frame[0] >= 0, "no finalization")
	h.check(rechecked_frame[0] - finalized_frame[0] == 3, "rechecked %d frames after finalizing" % (rechecked_frame[0] - finalized_frame[0]))
	h.check(entered_frame[0] - finalized_frame[0] == 3, "the engine's latency changed: the overlap arrived %d frames after the move" % (entered_frame[0] - finalized_frame[0]))
	h.check(entered_frame[0] <= rechecked_frame[0], "the recheck at frame %d ran before the overlap at %d" % [rechecked_frame[0], entered_frame[0]])
	h.check(inside_at_recheck[0], "the overlap list was still stale at the recheck")


## ---- Out of bounds while locked ----


func test_falling_into_the_kill_plane_while_locked_recovers_after_finalization(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var player := _player(h)
	var respawns := [0]
	director.player_respawned.connect(func() -> void: respawns[0] += 1)
	_solve(h)
	h.check(not player.is_control_enabled(), "control is not locked")
	# Gravity still applies. The clip is short, so the fall must already be under way.
	player.teleport(Vector2(400, 180))
	await h.wait_until(func() -> bool: return director.is_recovery_pending(), 12, "the fall to be noticed")
	h.check(respawns[0] == 0, "respawned during the cinematic")
	h.check(director.is_cinematic_active(), "the cinematic ended before the fall reached the kill plane")
	await _finish_clip(h)
	await h.wait_until(func() -> bool: return respawns[0] == 1, 12, "the recovery")
	h.check(not director.is_recovery_pending(), "the recovery stayed pending")
	await h.steps(30)
	h.check_near(player.global_position.x, CHECKPOINT_X[3], 1.0, "x after recovering at the Awakened checkpoint")
	h.check(player.is_on_floor(), "not on the floor after recovering")
	h.check(respawns[0] == 1, "recovered %d times" % respawns[0])
	h.check(player.is_control_enabled(), "control stayed locked after recovering")


func test_falling_during_the_reveal_recovers_after_reveal_done(h) -> void:
	await _arena(h, AWAKENED)
	var director := _director(h)
	var player := _player(h)
	var respawns := [0]
	director.player_respawned.connect(func() -> void: respawns[0] += 1)
	await _enter_witness(h)
	player.teleport(Vector2(400, 180))
	await _finish_clip(h)
	await h.wait_until(func() -> bool: return respawns[0] == 1, 20, "the recovery")
	await h.steps(30)
	h.check(director.get_beat() == FLEEING, "beat %d" % director.get_beat())
	h.check_near(player.global_position.x, CHECKPOINT_X[3], 1.0, "x after recovering")
	h.check(player.is_control_enabled(), "control stayed locked")


## The list says inside, though the signal came before the flag could matter: the recheck looks for itself.
func test_a_player_still_inside_the_kill_plane_after_finalization_is_recovered(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var player := _player(h)
	var respawns := [0]
	director.player_respawned.connect(func() -> void: respawns[0] += 1)
	var kill_plane: Area2D = h.fixture.get_node("KillPlane")
	# The story never hears of it, as a disabled trigger does not signal. Only the list can show it.
	kill_plane.enabled = false
	director.start_cinematic(&"side_show")
	player.teleport(Vector2(400, 180))
	await _finish_clip(h)
	h.check(not director.is_recovery_pending(), "the flag was set, so this proves nothing")
	await h.wait_until(func() -> bool: return respawns[0] == 1, 30, "the recheck to find the player in the kill plane")


func test_outside_a_cinematic_the_kill_plane_recovers_at_once_and_during_the_flee_too(h) -> void:
	await _at_fleeing(h)
	var player := _player(h)
	var respawns := [0]
	_director(h).player_respawned.connect(func() -> void: respawns[0] += 1)
	player.teleport(Vector2(400, 180))
	await h.steps(30)
	h.check(respawns[0] == 1, "respawned %d times" % respawns[0])
	h.check_near(player.global_position.x, CHECKPOINT_X[3], 1.0, "x after falling during the flee")
	h.check(_director(h).get_beat() == FLEEING, "falling moved the story to %d" % _director(h).get_beat())


## ---- The flee ----


func test_the_flee_timer_ends_the_flee_at_its_timeout(h) -> void:
	await _at_fleeing(h)
	var director := _director(h)
	director.flee_timeout = 2.0
	var beats := _log_beats(h)
	await h.steps(50)
	h.check(beats.is_empty(), "the flee ended early: %s" % str(beats))
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 80, "the timeout")
	h.check(beats == [ENDED], "the timeout gave %s" % str(beats))
	await h.wait_for_scene("MenuController")


func test_reaching_collapse_ends_the_flee_and_the_timer_then_has_nothing_to_do(h) -> void:
	await _at_fleeing(h)
	var director := _director(h)
	director.flee_timeout = 1.0
	var beats := _log_beats(h)
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 20, "collapse to fire")
	await h.wait_for_scene("MenuController")
	h.check(beats == [ENDED], "both routes fired: %s" % str(beats))


func test_control_locks_when_the_flee_ends(h) -> void:
	await _at_fleeing(h)
	var player := _player(h)
	player.teleport(Vector2(COLLAPSE_X, -2))
	await h.wait_until(func() -> bool: return _director(h).get_beat() == ENDED, 20, "collapse to fire")
	h.check(not player.is_control_enabled(), "the collapse left control on")


## ---- Pause ----


func test_pausing_stops_the_clip_and_the_watchdog(h) -> void:
	await _arena(h, MONOLITH)
	var director := _director(h)
	var clips := _clips(h)
	var errors := []
	director.contract_error.connect(func(message: String) -> void: errors.append(message))
	_solve(h)
	await h.steps(4)
	h.tree.paused = true
	var position := clips.current_animation_position
	await h.steps(200)
	h.check(is_equal_approx(clips.current_animation_position, position), "the clip advanced while paused")
	h.check(director.is_cinematic_active(), "a pause ended the cinematic")
	h.check(errors.is_empty(), "the watchdog fired while paused: %s" % str(errors))
	h.tree.paused = false
	await _finish_clip(h)
	h.check(errors.is_empty(), "the clip needed the watchdog after the pause: %s" % str(errors))


func test_pausing_stops_the_flee_timer(h) -> void:
	await _at_fleeing(h)
	var director := _director(h)
	director.flee_timeout = 1.0
	await h.steps(20)
	h.tree.paused = true
	var elapsed: float = director.get_flee_elapsed()
	await h.steps(120)
	h.check(is_equal_approx(director.get_flee_elapsed(), elapsed), "the flee timer ran while paused")
	h.check(director.get_beat() == FLEEING, "the flee ended while paused")
	h.tree.paused = false
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 60, "the flee timer to carry on")
	await h.wait_for_scene("MenuController")


## ---- The ending ----


func test_the_ending_scene_replaces_the_world_with_nothing_left_of_it(h) -> void:
	await _at_fleeing(h)
	var old_director := _director(h)
	var old_camera := _camera(h)
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	var ending: Node = await h.wait_for_scene("MenuController")
	h.check(ending.mode == 2, "the ending's mode is %d" % ending.mode)
	await h.steps(2)
	h.check(not is_instance_valid(old_director), "the old director was not freed")
	h.check(not is_instance_valid(old_camera), "the old camera was not freed")
	h.check(h.tree.root.find_children("*", "GameDirector", true, false).is_empty(), "a director remains")
	h.check(h.tree.root.find_children("*", "Camera2D", true, false).is_empty(), "a camera remains")
	h.check(not h.tree.paused, "the ending is paused")


func test_a_time_scale_left_behind_is_cleared_on_the_way_to_the_ending(h) -> void:
	await _at_fleeing(h)
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	await h.wait_until(func() -> bool: return _director(h).get_beat() == ENDED, 20, "collapse to fire")
	Engine.time_scale = 2.0
	await h.wait_for_scene("MenuController")
	h.check_near(Engine.time_scale, 1.0, 0.0, "the time scale in the ending")


func test_a_world_replaced_before_its_deferred_step_runs_does_nothing_more(h) -> void:
	await _arena(h, AWAKENED, true)
	var director := _director(h)
	var beats := _log_beats(h)
	await _enter_witness(h)
	director.finalize_cinematic(director.get_generation())
	# Out of the tree in the same frame the finalizer queued its deferred step.
	h.fixture.get_parent().remove_child(h.fixture)
	await h.tree.process_frame
	await h.tree.process_frame
	h.check(beats == [WITNESS], "a world out of the tree went on to %s" % str(beats))
	h.tree.root.add_child(h.fixture)
