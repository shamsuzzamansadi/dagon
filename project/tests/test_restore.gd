extends RefCounted
## Checkpoints: for every savable beat, the rebuilt world is the right one, nothing replays, and the game can go on.

const RoutePlayer := preload("res://tests/route_player.gd")
const GAME := "res://scenes/level/game.tscn"
const TITLE := "res://scenes/ui/title.tscn"
const ITEMS := "Center/Main/Panel/Items/"
const SAVE_FILE := "save.dat"
const BACKUP_FILE := "save.bak"
const SHORE := 0
const ABYSS := 1
const MONOLITH := 2
const AWAKENED := 3
const WITNESS := 4
const FLEEING := 5
const ENDED := 6
const SAVES := [
	"dagon_save=1\nbeat=shore\ncheckpoint=Shore\n",
	"dagon_save=1\nbeat=abyss\ncheckpoint=PastTheTrench\n",
	"dagon_save=1\nbeat=monolith\ncheckpoint=Monolith\n",
	"dagon_save=1\nbeat=awakened\ncheckpoint=Awakened\n",
]
const CHECKPOINT_X := [150.0, 750.0, 3660.0, 4250.0]
const STATUS_WORDS := ["shore", "trench", "monolith", "before the final sequence"]
const TINTS := [Color(1, 1, 1, 1), Color(0.84, 0.88, 0.95, 1), Color(0.7, 0.76, 0.87, 1), Color(0.7, 0.76, 0.87, 1)]
const WITNESS_X := 4420.0
const COLLAPSE_X := 3760.0
const WAVE_X := 4170.0
const KNEEL_X := 3990.0
const EYE_X := 4080.0
const MURAL_X := 3898.0
const GATE_X := 4300.0


func _write(h, file_name: String, text: String) -> void:
	h.write_storage_file(file_name, text.to_utf8_buffer())


func _block(h, file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(h.storage_dir.path_join(file_name))


func _unblock(h, file_name: String) -> void:
	DirAccess.remove_absolute(h.storage_dir.path_join(file_name))


func _session(h, beat: int) -> Node:
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(beat, true, false)
	await h.load_with(session, true)
	await h.landed_on_floor(session.get_world().get_node("Player"))
	return session


func _world(session: Node) -> Node:
	return session.get_world()


func _player(session: Node) -> CharacterBody2D:
	return session.get_world().get_node("Player")


func _menu(session: Node) -> Control:
	return session.get_node("PauseLayer/PauseMenu")


func _quit_message(session: Node) -> String:
	return _menu(session).get_node("Center/Confirm/Items/Message").text


func _check_world(h, session: Node, beat: int, what: String) -> void:
	var world := _world(session)
	var director: Node = session.get_director()
	h.check(director.get_beat() == beat, "%s: at beat %d" % [what, director.get_beat()])
	h.check(director.get_active_checkpoint() == beat, "%s: the checkpoint is %d" % [what, director.get_active_checkpoint()])
	h.check(session.get_session_beat() == beat, "%s: the session is at %d" % [what, session.get_session_beat()])
	h.check_near(_player(session).global_position.x, CHECKPOINT_X[beat], 2.0, "%s: x" % what)
	h.check(_player(session).is_control_enabled(), "%s: control is locked" % what)
	h.check(director.is_safe_to_save(), "%s: not safe to save" % what)
	h.check(not director.is_cinematic_active(), "%s: a cinematic is active" % what)
	h.check(not director.has_pending_event(), "%s: an event is pending" % what)

	# Each trigger is spent exactly if its beat has passed.
	var spent := {"EnterAbyss": beat >= ABYSS, "ReachMonolith": beat >= MONOLITH, "Witness": false, "Collapse": false}
	for trigger_name: String in spent:
		h.check(world.get_node("Triggers/" + trigger_name).enabled != spent[trigger_name], "%s: %s enabled=%s" % [what, trigger_name, world.get_node("Triggers/" + trigger_name).enabled])

	var solved := beat >= AWAKENED
	var puzzle: Node = world.get_node("Monolith/Puzzle")
	h.check(puzzle.is_solved() == solved, "%s: solved=%s" % [what, puzzle.is_solved()])
	h.check(puzzle.get_progress() == (3 if solved else 0), "%s: progress %d" % [what, puzzle.get_progress()])
	for stone_name in ["GlyphWave", "GlyphKneel", "GlyphEye"]:
		h.check(world.get_node("Monolith/%s/Lit" % stone_name).visible == solved, "%s: %s lit=%s" % [what, stone_name, world.get_node("Monolith/%s/Lit" % stone_name).visible])
		h.check(world.get_node("Monolith/" + stone_name).enabled != solved, "%s: %s enabled=%s" % [what, stone_name, world.get_node("Monolith/" + stone_name).enabled])
	var mural: Node = world.get_node("Monolith/Mural")
	h.check(mural.caption.contains("swimmer") == solved, "%s: the mural reads '%s'" % [what, mural.caption])
	h.check(mural.caption.contains("Ruins") != solved, "%s: the mural reads '%s'" % [what, mural.caption])
	h.check(world.get_node("Monolith/MuralLit").visible == solved, "%s: mural lit=%s" % [what, world.get_node("Monolith/MuralLit").visible])
	if solved:
		h.check(is_equal_approx(world.get_node("Monolith/MuralLit").modulate.a, 1.0), "%s: the lit mural is faded" % what)
	var gate: StaticBody2D = world.get_node("Monolith/Gate")
	h.check((gate.collision_layer == 0) == solved, "%s: gate layer %d" % [what, gate.collision_layer])
	h.check(gate.visible != solved, "%s: gate visible=%s" % [what, gate.visible])

	h.check(world.get_node("Tint").color.is_equal_approx(TINTS[beat]), "%s: the tint is %s" % [what, world.get_node("Tint").color])
	var cinematics: AnimationPlayer = world.get_node("Cinematics")
	h.check(not cinematics.is_playing() and cinematics.assigned_animation == &"", "%s: clip '%s' ran" % [what, cinematics.assigned_animation])
	h.check(not world.get_node("Atmosphere").is_playing(), "%s: an atmosphere clip is running" % what)
	h.check(not world.get_node("Hud/Notice").visible, "%s: a save notice shows" % what)
	h.check(not world.get_node("Hud/Caption").visible, "%s: a caption shows" % what)
	var camera: Camera2D = world.get_node("CameraRig")
	h.check(camera.zoom == Vector2.ONE and is_zero_approx(camera.get_trauma()) and camera.get_target() == _player(session), "%s: the camera is not at rest" % what)


func test_every_savable_beat_rebuilds_the_right_world_with_nothing_replayed(h) -> void:
	for beat in SAVES.size():
		_write(h, SAVE_FILE, SAVES[beat])
		var session := await _session(h, beat)
		var director: Node = session.get_director()
		var signals := []
		director.checkpoint_reached.connect(func(reached: int) -> void: signals.append(["checkpoint", reached]))
		director.beat_changed.connect(func(reached: int) -> void: signals.append(["beat", reached]))
		director.cinematic_started.connect(func(clip: StringName, _generation: int) -> void: signals.append(["clip", clip]))
		await h.steps(30)
		_check_world(h, session, beat, "beat %d" % beat)
		h.check(signals.is_empty(), "beat %d replayed %s" % [beat, str(signals)])
		h.check(h.read_storage_file(SAVE_FILE) == SAVES[beat], "beat %d: restoring changed the save" % beat)
		h.check(not FileAccess.file_exists(h.storage_dir.path_join(BACKUP_FILE)), "beat %d: restoring wrote a backup" % beat)
		await h.unload_fixture()
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))


func test_restart_checkpoint_rebuilds_the_same_world_at_every_beat(h) -> void:
	for beat in SAVES.size():
		_write(h, SAVE_FILE, SAVES[beat])
		var session := await _session(h, beat)
		var old_world := _world(session)
		_player(session).teleport(Vector2(CHECKPOINT_X[beat] - 60.0, -2))
		await h.steps(5)
		_menu(session).restart_checkpoint()
		h.check(_world(session) != old_world, "beat %d: the world was not rebuilt" % beat)
		await h.steps(30)
		_check_world(h, session, beat, "restarted beat %d" % beat)
		await h.unload_fixture()
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))


func test_a_partial_attempt_is_not_kept(h) -> void:
	_write(h, SAVE_FILE, SAVES[MONOLITH])
	var session := await _session(h, MONOLITH)
	var puzzle: Node = _world(session).get_node("Monolith/Puzzle")
	puzzle.submit(&"glyph_wave")
	h.check(puzzle.get_progress() == 1, "the press did not count")
	_menu(session).restart_checkpoint()
	await h.steps(5)
	_check_world(h, session, MONOLITH, "after restarting mid-attempt")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[MONOLITH], "an attempt reached the save")


## A restored Awakened world behaves as solved, in play as well as in its properties.
func test_a_restored_awakened_world_plays_correctly(h) -> void:
	var session := await _session(h, AWAKENED)
	var player := _player(session)
	var world := _world(session)
	var caption: Label = world.get_node("Hud/Caption")
	var prompt: Label = world.get_node("Hud/Prompt")

	# The mural has its second caption.
	await h.stand_at(player, Vector2(MURAL_X, -2))
	h.check(prompt.visible, "no prompt at the mural")
	await h.tap_key(KEY_E)
	h.check(caption.text.contains("swimmer"), "the mural reads '%s'" % caption.text)

	# The stones stay lit and stop reacting.
	var signals := [0]
	var puzzle: Node = world.get_node("Monolith/Puzzle")
	puzzle.solved.connect(func() -> void: signals[0] += 1)
	puzzle.failed.connect(func() -> void: signals[0] += 1)
	for x in [KNEEL_X, EYE_X, WAVE_X]:
		await h.stand_at(player, Vector2(x, -2))
		h.check(not prompt.visible, "a restored stone offers '%s'" % prompt.text)
		await h.tap_key(KEY_E)
	h.check(signals[0] == 0, "a restored stone reacted %d times" % signals[0])

	# The gate is open to a walking player.
	await h.stand_at(player, Vector2(GATE_X - 30.0, -2))
	Input.action_press("move_right")
	await h.wait_until(func() -> bool: return player.global_position.x > GATE_X + 20.0, 90, "the player to walk through the open gate")

	# The final sequence can start from here.
	await h.wait_until(func() -> bool: return session.get_director().get_beat() == WITNESS, 240, "the reveal to start")
	Input.action_release("move_right")


func test_each_save_continues_from_the_main_menu_with_the_right_wording(h) -> void:
	for beat in SAVES.size():
		_write(h, SAVE_FILE, SAVES[beat])
		var title: Control = await h.load_main_fixture(TITLE)
		await h.steps(3)
		var status: String = title.get_node(ITEMS + "SaveStatus").text
		h.check(status.contains(STATUS_WORDS[beat]), "beat %d: the status reads '%s'" % [beat, status])
		h.check(not title.get_node(ITEMS + "Continue").disabled, "beat %d: Continue is disabled" % beat)
		await h.tap_key(KEY_ENTER)
		var session: Node = await h.wait_for_scene("GameSession")
		await h.landed_on_floor(_player(session))
		await h.steps(30)
		_check_world(h, session, beat, "Continue at beat %d" % beat)
		h.check(session.get_persisted_beat() == beat, "beat %d: persisted %d" % [beat, session.get_persisted_beat()])
		h.check(not _menu(session).is_open(), "beat %d: Continue showed the introduction" % beat)
		await h.unload_fixture()
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))


func test_a_good_backup_of_each_beat_restores_it_when_the_primary_is_damaged(h) -> void:
	for beat in SAVES.size():
		_write(h, SAVE_FILE, "damaged")
		_write(h, BACKUP_FILE, SAVES[beat])
		var title: Control = await h.load_main_fixture(TITLE)
		await h.steps(3)
		h.check(title.get_node(ITEMS + "SaveStatus").text.contains(STATUS_WORDS[beat]), "beat %d: the status reads '%s'" % [beat, title.get_node(ITEMS + "SaveStatus").text])
		await h.tap_key(KEY_ENTER)
		var session: Node = await h.wait_for_scene("GameSession")
		await h.landed_on_floor(_player(session))
		await h.steps(30)
		_check_world(h, session, beat, "Continue from a backup at beat %d" % beat)
		h.check(h.read_storage_file(SAVE_FILE) == "damaged", "beat %d: Continue rewrote the save" % beat)
		h.check(h.read_storage_file(BACKUP_FILE) == SAVES[beat], "beat %d: Continue changed the backup" % beat)
		await h.unload_fixture()
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))
		DirAccess.remove_absolute(h.storage_dir.path_join(BACKUP_FILE))


## From every checkpoint, with the keys alone, the game can be played to its end. Nobody is ever stuck.
func test_from_every_savable_beat_the_keys_alone_reach_the_ending(h) -> void:
	for beat in SAVES.size():
		_write(h, SAVE_FILE, SAVES[beat])
		var title: Control = await h.load_main_fixture(TITLE)
		await h.steps(3)
		h.check(title != null, "no title")
		await h.tap_key(KEY_ENTER)
		await h.wait_for_scene("GameSession")
		var route = RoutePlayer.new(h)
		await h.landed_on_floor(route.player())
		# Before the Monolith the slab is still up: the stone has to be pushed first, as anyone has to.
		if not route.director().is_crossing_lowered():
			await route.cross_the_gap()
		if beat < AWAKENED:
			await route.solve_with_one_mistake()
			await route.wait_for_control()
		h.check(route.director().get_beat() == AWAKENED, "from beat %d: at %d before the ledge" % [beat, route.director().get_beat()])
		await route.walk_into_the_reveal()
		await route.wait_for_control()
		h.check(route.director().get_beat() == FLEEING, "from beat %d: at %d after the reveal" % [beat, route.director().get_beat()])
		await route.flee_left()
		var ending: Node = await h.wait_for_scene("MenuController", 400)
		h.check(ending.get_node_or_null("Center/Card") != null, "from beat %d: the scene is %s" % [beat, ending.name])
		await h.unload_fixture()
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))
		DirAccess.remove_absolute(h.storage_dir.path_join(BACKUP_FILE))


## ---- What may not be saved ----


func test_witness_fleeing_and_ended_are_never_written_and_restart_replays_them(h) -> void:
	_write(h, SAVE_FILE, SAVES[AWAKENED])
	var session := await _session(h, AWAKENED)
	var director: Node = session.get_director()
	var world := _world(session)
	_player(session).teleport(Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 12, "the reveal to start")
	h.check(not session.retry_save() or session.is_checkpoint_saved(), "a retry during the reveal failed oddly")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "the reveal wrote: %s" % h.read_storage_file(SAVE_FILE))

	# Mid-reveal: Restart Checkpoint goes back before it, with nothing of the clip left.
	await h.steps(30)
	h.check(world.get_node("CameraRig").zoom != Vector2.ONE or world.get_node("CameraRig").get_target() != _player(session), "the clip did not touch the camera")
	await h.tap_key(KEY_ESCAPE)
	h.check(h.tree.paused, "Esc did not pause the reveal")
	_menu(session).restart_checkpoint()
	h.check(not h.tree.paused, "restarting during the reveal left the game paused")
	await h.steps(30)
	_check_world(h, session, AWAKENED, "restarted during the reveal")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "restarting wrote: %s" % h.read_storage_file(SAVE_FILE))

	# Replays in full, into the flee.
	director = session.get_director()
	_player(session).teleport(Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 1000, "the replayed reveal to end")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "the flee wrote: %s" % h.read_storage_file(SAVE_FILE))
	h.check(session.get_session_beat() == AWAKENED, "the session moved to %d" % session.get_session_beat())
	h.check(director.get_active_checkpoint() == AWAKENED, "the active checkpoint is %d" % director.get_active_checkpoint())

	# Mid-flee: restart again.
	_menu(session).restart_checkpoint()
	await h.steps(30)
	_check_world(h, session, AWAKENED, "restarted during the flee")


func test_saving_is_refused_during_a_cinematic_and_works_after_it(h) -> void:
	_write(h, SAVE_FILE, SAVES[ABYSS])
	var session: Node = (load(GAME) as PackedScene).instantiate()
	# Starts at Monolith with the disk still behind it, as after a failed write.
	session.set_start(MONOLITH, false, false)
	await h.load_with(session, true)
	var director: Node = session.get_director()
	await h.steps(2)
	h.check(not session.is_checkpoint_saved(), "the session thinks Monolith is on disk")
	var puzzle: Node = _world(session).get_node("Monolith/Puzzle")
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		puzzle.submit(id)
	h.check(director.is_cinematic_active(), "no cinematic")
	h.check(not director.is_safe_to_save(), "safe to save during a cinematic")
	h.check(not session.retry_save(), "a save during a cinematic reported success")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[ABYSS], "a cinematic let a save through: %s" % h.read_storage_file(SAVE_FILE))
	await h.wait_until(func() -> bool: return not director.is_cinematic_active(), 500, "the cinematic to finish")
	h.check(session.is_checkpoint_saved(), "the finalized checkpoint was not saved")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "the file holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(h.read_storage_file(BACKUP_FILE) == SAVES[ABYSS], "the backup holds: %s" % h.read_storage_file(BACKUP_FILE))


func test_the_awakened_save_waits_for_the_cinematic_to_finalize(h) -> void:
	_write(h, SAVE_FILE, SAVES[MONOLITH])
	var session := await _session(h, MONOLITH)
	var director: Node = session.get_director()
	var puzzle: Node = _world(session).get_node("Monolith/Puzzle")
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		puzzle.submit(id)
	await h.steps(30)
	h.check(director.get_beat() == AWAKENED and director.is_cinematic_active(), "not in the cinematic")
	h.check(session.get_session_beat() == MONOLITH, "the session moved on during the cinematic: %d" % session.get_session_beat())
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[MONOLITH], "the save moved on during the cinematic")
	# Restarting here returns to before the stones, and they can be pressed again.
	_menu(session).restart_checkpoint()
	await h.steps(30)
	_check_world(h, session, MONOLITH, "restarted during the awakening")


func test_an_autosave_failure_at_awakened_keeps_the_session_checkpoint_and_says_so(h) -> void:
	_write(h, SAVE_FILE, SAVES[MONOLITH])
	var session := await _session(h, MONOLITH)
	var director: Node = session.get_director()
	_block(h, SAVE_FILE + ".tmp")
	var puzzle: Node = _world(session).get_node("Monolith/Puzzle")
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		puzzle.submit(id)
	await h.wait_until(func() -> bool: return not director.is_cinematic_active(), 500, "the cinematic to finish")
	h.check(session.get_session_beat() == AWAKENED, "the session lost the checkpoint: %d" % session.get_session_beat())
	h.check(session.get_persisted_beat() == MONOLITH, "the persisted beat is %d" % session.get_persisted_beat())
	h.check(_world(session).get_node("Hud/Notice").text == "Could not save this checkpoint", "the notice reads '%s'" % _world(session).get_node("Hud/Notice").text)
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[MONOLITH], "the failed save changed the file")

	# Restart Checkpoint reads no file and returns to the session's checkpoint.
	_menu(session).restart_checkpoint()
	await h.steps(30)
	_check_world(h, session, AWAKENED, "restarted after a failed write")

	_menu(session).open()
	_menu(session).ask_quit_to_main_menu()
	h.check(_quit_message(session).contains("could not be saved") and _quit_message(session).contains("earlier save"), "the quit text reads '%s'" % _quit_message(session))
	_menu(session).cancel_confirm()
	_menu(session).resume()

	# The next write that works catches up.
	_unblock(h, SAVE_FILE + ".tmp")
	h.check(session.retry_save(), "the retry failed")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "the file holds: %s" % h.read_storage_file(SAVE_FILE))


func test_quitting_during_the_final_sequence_says_it_will_replay(h) -> void:
	_write(h, SAVE_FILE, SAVES[AWAKENED])
	var session := await _session(h, AWAKENED)
	var director: Node = session.get_director()
	_player(session).teleport(Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 12, "the reveal to start")
	await h.tap_key(KEY_ESCAPE)
	_menu(session).ask_quit_to_main_menu()
	h.check(_quit_message(session).contains("before the final sequence"), "the quit text reads '%s'" % _quit_message(session))
	h.check(_quit_message(session).contains("play again"), "the quit text reads '%s'" % _quit_message(session))
	_menu(session).confirm()
	var title: Node = await h.wait_for_scene("MenuController")
	h.check(not h.tree.paused, "the main menu is paused")
	h.check(title.get_node(ITEMS + "SaveStatus").text.contains("before the final sequence"), "the status reads '%s'" % title.get_node(ITEMS + "SaveStatus").text)
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "quitting changed the save")


func test_ordinary_quit_wording_stays_ordinary_before_the_final_sequence(h) -> void:
	_write(h, SAVE_FILE, SAVES[MONOLITH])
	var session := await _session(h, MONOLITH)
	_menu(session).open()
	_menu(session).ask_quit_to_desktop()
	h.check(_quit_message(session).contains("last saved checkpoint"), "the quit text reads '%s'" % _quit_message(session))
	h.check(not _quit_message(session).contains("final sequence"), "the quit text reads '%s'" % _quit_message(session))


## Nothing of an abandoned cinematic reaches the next world: no event, no save, no clip, and no callback.
func test_repeated_restarts_during_a_cinematic_leave_nothing_behind(h) -> void:
	_write(h, SAVE_FILE, SAVES[MONOLITH])
	var session := await _session(h, MONOLITH)
	for i in 3:
		var puzzle: Node = _world(session).get_node("Monolith/Puzzle")
		for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
			puzzle.submit(id)
		await h.steps(5)
		h.check(session.get_director().is_cinematic_active(), "round %d: no cinematic" % i)
		await h.tap_key(KEY_ESCAPE)
		_menu(session).restart_checkpoint()
		await h.steps(3)
		h.check(not h.tree.paused, "round %d: paused" % i)
		h.check(session.get_session_beat() == MONOLITH, "round %d: the session moved to %d" % [i, session.get_session_beat()])
		h.check(h.tree.root.find_children("*", "GameDirector", true, false).size() == 1, "round %d: more than one director" % i)
	await h.steps(30)
	_check_world(h, session, MONOLITH, "after the restarts")
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[MONOLITH], "the abandoned cinematics saved: %s" % h.read_storage_file(SAVE_FILE))
	# Long enough for any leftover clip or watchdog of the old worlds to have fired.
	var finalized := [0]
	session.get_director().cinematic_finalized.connect(func(_clip: StringName, _generation: int) -> void: finalized[0] += 1)
	await h.steps(420)
	h.check(finalized[0] == 0, "a leftover finalized %d times" % finalized[0])
	h.check(session.get_session_beat() == MONOLITH, "a leftover moved the session to %d" % session.get_session_beat())
	_check_world(h, session, MONOLITH, "well after the restarts")


## ---- Saves written by other versions ----


func test_the_save_format_has_not_changed_so_an_m2_save_still_continues(h) -> void:
	for pair in [[SHORE, "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n"], [ABYSS, "dagon_save=1\nbeat=abyss\ncheckpoint=PastTheTrench\n"]]:
		_write(h, SAVE_FILE, pair[1])
		await h.load_main_fixture(TITLE)
		await h.steps(3)
		await h.tap_key(KEY_ENTER)
		var session: Node = await h.wait_for_scene("GameSession")
		await h.landed_on_floor(_player(session))
		h.check(session.get_director().get_beat() == pair[0], "the M2 save continued at beat %d" % session.get_director().get_beat())
		await h.unload_fixture()


func test_a_save_from_a_later_version_is_refused_and_left_alone(h) -> void:
	var future := "dagon_save=2\nbeat=awakened\ncheckpoint=Awakened\nsomething_new=1\n"
	_write(h, SAVE_FILE, future)
	var title: Control = await h.load_main_fixture(TITLE)
	await h.steps(3)
	h.check(title.get_node(ITEMS + "Continue").disabled, "Continue is enabled")
	h.check(title.get_node(ITEMS + "SaveStatus").text.contains("another version"), "the status reads '%s'" % title.get_node(ITEMS + "SaveStatus").text)
	h.check(h.read_storage_file(SAVE_FILE) == future, "looking at the save changed it")


## ---- Two separate processes ----


func _run_probe(h, args: Array) -> String:
	var output := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60", "--quit-after", "20000", "--script", "res://tests/session_probe.gd", "--"] + args, output, true)
	h.check(code == 0, "the probe %s exited with %d: %s" % [str(args), code, output[0]])
	return output[0]


func test_each_beat_saved_in_one_process_continues_correctly_in_another(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	for beat in SAVES.size():
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))
		DirAccess.remove_absolute(h.storage_dir.path_join(BACKUP_FILE))
		var first := _run_probe(h, ["new_game", "advance_to=%d" % beat])
		h.check("PROBE reached beat=%d persisted=%d" % [beat, beat] in first, "the first process did not reach beat %d: %s" % [beat, first])
		h.check(h.read_storage_file(SAVE_FILE) == SAVES[beat], "beat %d wrote: %s" % [beat, h.read_storage_file(SAVE_FILE)])
		var second := _run_probe(h, ["continue", "report_world"])
		h.check(STATUS_WORDS[beat] in second and "continue_disabled=false" in second, "the second process saw: %s" % second)
		var solved := beat >= AWAKENED
		var expected := "PROBE world beat=%d x=%.0f spent=%s,%s armed=true,true solved=%s lit=%d gate=%d mural=%s clip='' on_floor=true control=true" % [beat, CHECKPOINT_X[beat], beat >= ABYSS, beat >= MONOLITH, solved, 3 if solved else 0, 0 if solved else 1, "after" if solved else "before"]
		h.check(expected in second, "the second process at beat %d did not report: %s\ngot: %s" % [beat, expected, second])
		h.check(h.read_storage_file(SAVE_FILE) == SAVES[beat], "Continue changed the save at beat %d" % beat)


func test_a_failed_write_at_awakened_leaves_the_earlier_save_for_the_next_process(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	_run_probe(h, ["new_game", "advance_to=%d" % MONOLITH])
	_block(h, SAVE_FILE + ".tmp")
	var failed := _run_probe(h, ["continue", "advance_to=%d" % AWAKENED])
	h.check("PROBE reached beat=%d persisted=%d" % [AWAKENED, MONOLITH] in failed, "the session did not keep them apart: %s" % failed)
	_unblock(h, SAVE_FILE + ".tmp")
	var relaunched := _run_probe(h, ["continue", "report_world"])
	h.check("PROBE world beat=%d" % MONOLITH in relaunched, "Continue after the failure: %s" % relaunched)


func test_the_final_sequence_in_one_process_leaves_awakened_for_the_next(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	_write(h, SAVE_FILE, SAVES[AWAKENED])
	var quit_midway := _run_probe(h, ["continue", "enter_reveal"])
	h.check("PROBE in the reveal beat=4" in quit_midway, "the first process: %s" % quit_midway)
	h.check(h.read_storage_file(SAVE_FILE) == SAVES[AWAKENED], "the reveal wrote: %s" % h.read_storage_file(SAVE_FILE))
	var again := _run_probe(h, ["continue", "report_world"])
	h.check("PROBE world beat=%d" % AWAKENED in again, "Continue after the reveal: %s" % again)
	var to_the_end := _run_probe(h, ["continue", "play_to_ending"])
	h.check("PROBE ending reached" in to_the_end, "the last process: %s" % to_the_end)
	var after := _run_probe(h, ["continue", "report_world"])
	h.check("before the final sequence" in after, "the main menu after the ending said: %s" % after)
	h.check("PROBE world beat=%d" % AWAKENED in after, "Continue after the ending: %s" % after)
