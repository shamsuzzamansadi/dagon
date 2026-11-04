extends RefCounted
## Tests of the game scene: the world, the session checkpoint, and what reaches the disk.

const GAME := "res://scenes/level/game.tscn"
const SAVE_FILE := "save.dat"
const BACKUP_FILE := "save.bak"
const SHORE_SAVE := "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n"
const ABYSS_SAVE := "dagon_save=1\nbeat=abyss\ncheckpoint=PastTheTrench\n"
const PAST_THE_TRIGGER := Vector2(735, -2)
const SHORE_X := 150.0
const ABYSS_X := 750.0


func _setup(h) -> Node:
	await h.load_fixture(GAME)
	await h.landed_on_floor(_player(h))
	return h.fixture


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("World/Player")


func _menu(h) -> Control:
	return h.fixture.get_node("PauseLayer/PauseMenu")


func _prompt(h) -> Label:
	return h.fixture.get_node("World/Hud/Prompt")


func _caption(h) -> Label:
	return h.fixture.get_node("World/Hud/Caption")


func _notice(h) -> Label:
	return h.fixture.get_node("World/Hud/Notice")


func _quit_message(h) -> String:
	return _menu(h).get_node("Center/Confirm/Items/Message").text


func _write(h, file_name: String, text: String) -> void:
	h.write_storage_file(file_name, text.to_utf8_buffer())


func _block(h, file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(h.storage_dir.path_join(file_name))


func _unblock(h, file_name: String) -> void:
	DirAccess.remove_absolute(h.storage_dir.path_join(file_name))


func _has_file(h, file_name: String) -> bool:
	return FileAccess.file_exists(h.storage_dir.path_join(file_name))


## Pressed and released through the real input path, the way a person plays.
func _hold(h, key: Key, frames: int) -> void:
	h.send(h.key_event(key, true))
	await h.steps(frames)
	h.send(h.key_event(key, false))
	await h.steps(2)


## The reported defect, played the way a person plays it: no teleports, no direct calls, real key events.
func test_examine_works_through_normal_play_at_the_boat_and_the_fish(h) -> void:
	await _setup(h)
	var boat: Node = h.fixture.get_node("World/Props/Lifeboat")
	var fish: Node = h.fixture.get_node("World/Props/FishNearRock")

	await h.steps(5)
	h.check(_prompt(h).visible, "no prompt beside the boat at the start")
	h.check(_prompt(h).text == "[E] Examine", "the prompt reads '%s'" % _prompt(h).text)
	await h.tap_key(KEY_E)
	h.check(_caption(h).visible and _caption(h).text == boat.caption, "pressing E at the boat shows '%s'" % _caption(h).text)

	await _hold(h, KEY_D, 22)
	h.check(_prompt(h).visible, "no prompt at the fish, at x=%.0f" % _player(h).global_position.x)
	await h.wait_until(fish.is_available, 30, "the fish to be available")
	await h.tap_key(KEY_E)
	h.check(_caption(h).visible and _caption(h).text == fish.caption, "pressing E at the fish shows '%s'" % _caption(h).text)


func test_examine_still_works_after_restarting(h) -> void:
	await _setup(h)
	await _hold(h, KEY_D, 22)
	var old_player := _player(h)
	await h.tap_key(KEY_ESCAPE)
	await h.tap_key(KEY_DOWN)
	await h.tap_key(KEY_ENTER)
	await h.steps(5)
	h.check(_player(h) != old_player, "restarting did not rebuild the world")
	h.check(_prompt(h).visible and _prompt(h).text == "[E] Examine", "after restarting the prompt reads '%s'" % _prompt(h).text)
	await h.tap_key(KEY_E)
	h.check(_caption(h).visible and _caption(h).text == h.fixture.get_node("World/Props/Lifeboat").caption, "after restarting E shows '%s'" % _caption(h).text)


func test_examine_follows_a_rebound_key_at_the_boat_and_the_fish(h) -> void:
	await _setup(h)
	var settings: Control = _menu(h).get_node("Settings")
	await h.tap_key(KEY_ESCAPE)
	_menu(h).open_settings()
	await h.steps(1)
	settings.begin_capture(3)
	await h.tap_key(KEY_J)
	await h.tap_key(KEY_ESCAPE)
	await h.tap_key(KEY_ESCAPE)
	await h.steps(2)
	h.check(not _menu(h).is_open(), "the menu stayed open")
	h.check(_prompt(h).text == "[J] Examine", "after rebinding the prompt reads '%s'" % _prompt(h).text)
	await h.tap_key(KEY_E)
	h.check(not _caption(h).visible, "the old key still examines")
	await h.tap_key(KEY_J)
	h.check(_caption(h).visible, "the new key does not examine at the boat")
	await _hold(h, KEY_D, 22)
	h.check(_prompt(h).text == "[J] Examine", "at the fish the prompt reads '%s'" % _prompt(h).text)
	var fish: Node = h.fixture.get_node("World/Props/FishNearRock")
	await h.wait_until(fish.is_available, 30, "the fish to be available")
	await h.tap_key(KEY_J)
	h.check(_caption(h).text == fish.caption, "the new key at the fish shows '%s'" % _caption(h).text)


func test_the_hud_is_connected_in_code_and_only_once_after_restarts(h) -> void:
	await _setup(h)
	for i in 3:
		_menu(h).restart_checkpoint()
		await h.steps(2)
		var interactor: Node = h.fixture.get_node("World/Player/Interactor")
		h.check(interactor.focus_changed.get_connections().size() == 1, "focus_changed has %d connections" % interactor.focus_changed.get_connections().size())
		h.check(interactor.interacted.get_connections().size() == 1, "interacted has %d connections" % interactor.interacted.get_connections().size())


func test_a_checkpoint_is_saved_and_the_notice_is_truthful(h) -> void:
	var session := await _setup(h)
	h.check(not _notice(h).visible, "a notice before anything was saved")
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(session.get_session_beat() == 1, "the session beat is %d" % session.get_session_beat())
	h.check(session.get_persisted_beat() == 1, "the persisted beat is %d" % session.get_persisted_beat())
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the file holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(_notice(h).visible and _notice(h).text == "Checkpoint saved", "the notice reads '%s'" % _notice(h).text)
	await h.wait_until(func() -> bool: return not _notice(h).visible, 240, "the notice to fade")
	h.check(not h.tree.paused, "the notice paused the game")


func test_saved_checkpoints_name_real_markers(h) -> void:
	await _setup(h)
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(h.fixture.has_node("World/Checkpoints/PastTheTrench"), "no marker named by the abyss save")
	h.check(h.fixture.has_node("World/Checkpoints/Shore"), "no marker named by the shore save")
	var director: Node = h.fixture.get_director()
	h.check(director.get_node(director.checkpoints[0]).name == &"Shore", "checkpoint 0 is %s" % director.get_node(director.checkpoints[0]).name)
	h.check(director.get_node(director.checkpoints[1]).name == &"PastTheTrench", "checkpoint 1 is %s" % director.get_node(director.checkpoints[1]).name)
	h.check(director.get_node(director.checkpoints[2]).name == &"Monolith", "checkpoint 2 is %s" % director.get_node(director.checkpoints[2]).name)
	h.check(director.get_node(director.checkpoints[3]).name == &"Awakened", "checkpoint 3 is %s" % director.get_node(director.checkpoints[3]).name)
	var world: Node = (load("res://scenes/level/shore.tscn") as PackedScene).instantiate()
	h.check(world.get_node("Player").position == world.get_node("Checkpoints/Shore").position, "the spawn point is not the shore checkpoint")
	world.free()


func test_starting_at_a_saved_beat_applies_outcomes_without_replaying_them(h) -> void:
	_write(h, SAVE_FILE, ABYSS_SAVE)
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(1, true, false)
	h.fixture = session
	h.probe = preload("res://tests/step_probe.gd").new()
	h.tree.root.add_child(h.probe)
	h.tree.root.add_child(session)
	# The director had its beat before it entered the tree, so _ready has already applied it.
	var director: Node = session.get_director()
	h.check(director.get_active_checkpoint() == 1, "the director is at beat %d" % director.get_active_checkpoint())
	h.check(not session.get_world().get_node("Triggers/EnterAbyss").enabled, "the used trigger was not consumed")
	h.check_near(_player(h).global_position.x, ABYSS_X, 1.0, "x straight after entering the tree")
	var emitted := [0]
	director.checkpoint_reached.connect(func(_beat: int) -> void: emitted[0] += 1)
	await h.steps(30)
	h.check(_player(h).is_on_floor(), "the player did not land")
	h.check(emitted[0] == 0, "restoring emitted %d checkpoints" % emitted[0])
	h.check(not _notice(h).visible, "restoring showed a save notice")
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "restoring changed the save")
	h.check(not _has_file(h, BACKUP_FILE), "restoring wrote a backup")
	h.check(not _menu(h).is_open(), "Continue showed the new-game introduction")
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(emitted[0] == 0, "crossing the used trigger emitted %d checkpoints" % emitted[0])


func test_an_autosave_failure_keeps_the_session_checkpoint_and_says_so(h) -> void:
	var session := await _setup(h)
	h.check(session.retry_save(), "the first save failed")
	_block(h, SAVE_FILE + ".tmp")
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(session.get_session_beat() == 1, "the session lost the checkpoint")
	h.check(session.get_persisted_beat() == 0, "the persisted beat is %d" % session.get_persisted_beat())
	h.check(_notice(h).text == "Could not save this checkpoint", "the notice reads '%s'" % _notice(h).text)
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the failed save changed the file")

	# Restart Checkpoint uses the session's value, and reads no file.
	_menu(h).restart_checkpoint()
	await h.steps(30)
	h.check_near(_player(h).global_position.x, ABYSS_X, 1.0, "x after restarting")
	h.check(not h.fixture.get_node("World/Triggers/EnterAbyss").enabled, "the rebuilt world forgot the used trigger")

	# Quitting says what is really on disk.
	_menu(h).open()
	_menu(h).ask_quit_to_desktop()
	h.check(_quit_message(h).contains("could not be saved") and _quit_message(h).contains("earlier save"), "the quit text reads '%s'" % _quit_message(h))
	h.check(not _quit_message(h).contains("last saved checkpoint"), "the quit text implies it was saved: '%s'" % _quit_message(h))


func test_quitting_retries_a_failed_save_and_reports_the_result(h) -> void:
	var session := await _setup(h)
	h.check(session.retry_save(), "the first save failed")
	_block(h, SAVE_FILE + ".tmp")
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	_unblock(h, SAVE_FILE + ".tmp")
	_menu(h).open()
	_menu(h).ask_quit_to_main_menu()
	h.check(session.get_persisted_beat() == 1, "the retry did not save")
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the file holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(_quit_message(h).contains("last saved checkpoint"), "the quit text reads '%s'" % _quit_message(h))


func test_quitting_with_no_save_at_all_says_there_is_nothing_to_continue(h) -> void:
	await _setup(h)
	_block(h, SAVE_FILE + ".tmp")
	_menu(h).open()
	_menu(h).ask_quit_to_desktop()
	h.check(_quit_message(h).contains("nothing to continue"), "the quit text reads '%s'" % _quit_message(h))


func test_restarting_reads_no_file(h) -> void:
	var session := await _setup(h)
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	_write(h, SAVE_FILE, "damaged")
	_write(h, BACKUP_FILE, "damaged")
	_menu(h).restart_checkpoint()
	await h.steps(30)
	h.check_near(_player(h).global_position.x, ABYSS_X, 1.0, "x after restarting")
	h.check(session.get_session_beat() == 1, "the session beat is %d" % session.get_session_beat())
	h.check(h.read_storage_file(SAVE_FILE) == "damaged", "restarting wrote the save")


func test_replacing_the_world_cuts_off_the_old_one(h) -> void:
	var session := await _setup(h)
	var old_world: Node = session.get_world()
	var old_director: Node = session.get_director()
	var old_player := _player(h)
	_menu(h).restart_checkpoint()
	h.check(is_instance_valid(old_world) and not old_world.is_inside_tree(), "the old world is still in the tree")
	h.check(old_director.checkpoint_reached.get_connections().is_empty(), "the old director can still reach the session")
	h.check(session.get_world() != old_world, "the world was not replaced")
	h.check(session.get_child_count() == 2, "the session has %d children" % session.get_child_count())
	h.check(session.get_child(0) == session.get_world(), "the world is not the first child")
	await h.steps(2)
	h.check(not is_instance_valid(old_world), "the old world was not freed")
	h.check(not is_instance_valid(old_player), "the old player was not freed")
	h.check(h.tree.root.find_children("*", "Camera2D", true, false).size() == 1, "more than one camera")
	h.check(h.tree.root.find_children("*", "Hud", true, false).size() == 1, "more than one Hud")


func test_repeated_restarts_produce_no_duplicate_events(h) -> void:
	var session := await _setup(h)
	for i in 4:
		await h.tap_action("pause")
		_menu(h).restart_checkpoint()
		await h.steps(5)
		h.check(not h.tree.paused, "paused after restart %d" % i)
	var emitted := [0]
	session.get_director().checkpoint_reached.connect(func(_beat: int) -> void: emitted[0] += 1)
	var examined := [0]
	h.fixture.get_node("World/Player/Interactor").interacted.connect(func(_target: Object) -> void: examined[0] += 1)
	await h.tap_key(KEY_E)
	h.check(examined[0] == 1, "one press examined %d times" % examined[0])
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(emitted[0] == 1, "one crossing gave %d checkpoints" % emitted[0])
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the file holds: %s" % h.read_storage_file(SAVE_FILE))


func test_restarting_clears_a_time_scale_and_a_pause_left_behind(h) -> void:
	await _setup(h)
	Engine.time_scale = 0.5
	h.tree.paused = true
	_menu(h).restart_checkpoint()
	h.check(not h.tree.paused, "still paused")
	h.check_near(Engine.time_scale, 1.0, 0.0, "the time scale")
	Engine.time_scale = 1.0


func _final_sequence_session(h) -> Node:
	var session: Node = ClassDB.instantiate("GameSession")
	session.world_scene = load("res://tests/fixtures/story_arena.tscn")
	session.director_path = NodePath("GameDirector")
	session.set_start(3, true, false)
	h.fixture = session
	h.probe = preload("res://tests/step_probe.gd").new()
	h.tree.root.add_child(h.probe)
	h.tree.root.add_child(session)
	await h.steps(1)
	return session


## Approved behaviour (D27): the reveal and escape are never saved. Quitting or restarting replays them.
func test_the_final_sequence_is_not_a_checkpoint_and_replays_after_a_restart(h) -> void:
	_write(h, SAVE_FILE, "unchanged")
	var session := await _final_sequence_session(h)
	var player: CharacterBody2D = session.get_world().get_node("Player")
	var beats := []
	var saved := []
	session.get_director().beat_changed.connect(func(beat: int) -> void: beats.append(beat))
	session.get_director().checkpoint_reached.connect(func(beat: int) -> void: saved.append(beat))
	await h.stand_at(player, Vector2(860, -2))
	h.check(beats == [4, 5], "the director reached %s" % str(beats))
	h.check(saved.is_empty(), "the final sequence reached checkpoints %s" % str(saved))
	h.check(session.get_session_beat() == 3, "the session adopted beat %d" % session.get_session_beat())
	h.check(session.get_persisted_beat() == 3, "the persisted beat is %d" % session.get_persisted_beat())
	h.check(h.read_storage_file(SAVE_FILE) == "unchanged", "the final sequence wrote a save")

	session.restart_checkpoint()
	await h.steps(30)
	var world: Node = session.get_world()
	h.check(world.get_node("Witness").enabled, "the reveal's trigger is not armed again")
	h.check(not world.get_node("EnterAbyss").enabled and not world.get_node("ReachMonolith").enabled, "an earlier trigger came back")
	h.check_near(world.get_node("Player").global_position.x, 760.0, 1.0, "x after restarting")
	var again := []
	session.get_director().beat_changed.connect(func(beat: int) -> void: again.append(beat))
	await h.stand_at(world.get_node("Player"), Vector2(860, -2))
	h.check(again == [4, 5], "the reveal did not replay: %s" % str(again))


func test_writing_keeps_the_old_save_as_the_backup(h) -> void:
	var session := await _setup(h)
	h.check(session.retry_save(), "the first save failed")
	h.check(not _has_file(h, BACKUP_FILE), "a backup before there was anything to back up")
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the save holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(h.read_storage_file(BACKUP_FILE) == SHORE_SAVE, "the backup holds: %s" % h.read_storage_file(BACKUP_FILE))
	h.check(not _has_file(h, SAVE_FILE + ".tmp") and not _has_file(h, BACKUP_FILE + ".tmp"), "a temporary file was left behind")


func test_a_corrupt_save_never_overwrites_a_valid_backup(h) -> void:
	var session := await _setup(h)
	_write(h, SAVE_FILE, "damaged")
	_write(h, BACKUP_FILE, SHORE_SAVE)
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(session.get_persisted_beat() == 1, "the write failed")
	h.check(h.read_storage_file(BACKUP_FILE) == SHORE_SAVE, "the backup became: %s" % h.read_storage_file(BACKUP_FILE))
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the save holds: %s" % h.read_storage_file(SAVE_FILE))


func test_a_failure_at_each_step_of_replacing_leaves_a_usable_save(h) -> void:
	# The new save cannot be written: nothing else may change.
	var session := await _setup(h)
	h.check(session.retry_save(), "the first save failed")
	_block(h, SAVE_FILE + ".tmp")
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	h.check(not session.is_checkpoint_saved(), "a blocked write reported success")
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "step 1: the save holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(not _has_file(h, BACKUP_FILE), "step 1: a backup appeared")
	_unblock(h, SAVE_FILE + ".tmp")

	# The backup cannot be written: the save stays, and the temporary file does not linger.
	_block(h, BACKUP_FILE + ".tmp")
	h.check(not session.retry_save(), "a blocked backup reported success")
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "step 2: the save holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(not _has_file(h, SAVE_FILE + ".tmp"), "step 2: the temporary save stayed")
	_unblock(h, BACKUP_FILE + ".tmp")

	# Nothing is blocked now, so the same checkpoint finally reaches the disk.
	h.check(session.retry_save(), "the retry failed")
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the retry left: %s" % h.read_storage_file(SAVE_FILE))
	h.check(h.read_storage_file(BACKUP_FILE) == SHORE_SAVE, "the retry's backup holds: %s" % h.read_storage_file(BACKUP_FILE))


func test_quitting_to_the_main_menu_unpauses_and_keeps_the_save(h) -> void:
	await h.load_main_fixture(GAME)
	await h.landed_on_floor(_player(h))
	await h.stand_at(_player(h), PAST_THE_TRIGGER)
	await h.tap_action("pause")
	_menu(h).ask_quit_to_main_menu()
	await h.steps(1)
	h.check(_menu(h).get_node("Center/Confirm").visible, "no confirmation")
	h.check(_quit_message(h).contains("Return to the main menu"), "the text reads '%s'" % _quit_message(h))
	_menu(h).confirm()
	var title: Node = await h.wait_for_scene("MenuController")
	h.check(not h.tree.paused, "the main menu is paused")
	h.check(h.read_storage_file(SAVE_FILE) == ABYSS_SAVE, "the save holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(not title.get_node("Center/Main/Panel/Items/Continue").disabled, "Continue is disabled")
	h.check(title.get_node("Center/Main/Panel/Items/SaveStatus").text.contains("trench"), "the status reads '%s'" % title.get_node("Center/Main/Panel/Items/SaveStatus").text)
	h.check(title.get_viewport().gui_get_focus_owner() == title.get_node("Center/Main/Panel/Items/Continue"), "focus is on %s" % title.get_viewport().gui_get_focus_owner())


func _run_probe(h, args: Array) -> String:
	var output := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--quit-after", "2000", "--script", "res://tests/session_probe.gd", "--"] + args, output, true)
	h.check(code == 0, "the probe %s exited with %d: %s" % [str(args), code, output[0]])
	return output[0]


func test_continue_restores_the_checkpoint_after_quitting_and_relaunching(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	var first := _run_probe(h, ["new_game", "cross_the_trigger"])
	h.check("status='No saved game yet.' continue_disabled=true" in first, "the first launch saw: %s" % first)
	h.check("PROBE started beat=0 x=150" in first, "New Game started: %s" % first)
	h.check("PROBE crossed beat=1 persisted=1" in first, "the checkpoint was not saved: %s" % first)
	var second := _run_probe(h, ["continue"])
	h.check("trench" in second and "continue_disabled=false" in second, "the second launch saw: %s" % second)
	h.check("PROBE started beat=1 x=750" in second, "Continue started: %s" % second)


func test_continue_after_an_autosave_failure_uses_the_last_valid_save(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	_run_probe(h, ["new_game"])
	_block(h, SAVE_FILE + ".tmp")
	var failed := _run_probe(h, ["continue", "cross_the_trigger"])
	h.check("PROBE crossed beat=1 persisted=0" in failed, "the session did not keep them apart: %s" % failed)
	_unblock(h, SAVE_FILE + ".tmp")
	var relaunched := _run_probe(h, ["continue"])
	h.check("PROBE started beat=0 x=150" in relaunched, "Continue after the failure started: %s" % relaunched)
