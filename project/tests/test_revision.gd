extends RefCounted
## The owner's revision of 2026-11-09: the prologue, the crossing in Act II, the returning sea, the first sound pass,
## the sailor's reactions, and the finished reference section. Focused on what is new and what could go wrong with it.

const RoutePlayer := preload("res://tests/route_player.gd")
const TITLE := "res://scenes/ui/title.tscn"
const PROLOGUE := "res://scenes/ui/prologue.tscn"
const WORLD := "res://scenes/level/shore.tscn"
const GAME := "res://scenes/level/game.tscn"
const SAVE_FILE := "save.dat"
const SHORE_SAVE := "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n"
const ABYSS_SAVE := "dagon_save=1\nbeat=abyss\ncheckpoint=PastTheTrench\n"
const AWAKENED_SAVE := "dagon_save=1\nbeat=awakened\ncheckpoint=Awakened\n"
const ABYSS := 1
const MONOLITH := 2
const AWAKENED := 3
const WITNESS := 4
const FLEEING := 5
const ENDED := 6
const WITNESS_X := 4420.0
const COLLAPSE_X := 3760.0
const RIM_X := 2120.0
const FAR_RIM_X := 2300.0
const ONE_SHOTS := ["Monolith/StoneAccept", "Monolith/StoneReject", "Monolith/GateSound", "Sound/MusicAwaken", "Sound/MusicReveal", "Sound/WaterSurge", "Sound/CreatureCall", "Sound/CreatureTurn", "Sound/HandImpact", "Sound/BodyFall", "Sound/SeaRush", "Sound/RitualDrum", "Crossing/Sound", "Tide/Roar", "Rockfall/SoundNear", "Rockfall/SoundMid", "Rockfall/SoundFar", "Player/Gasp"]


func _world(h, beat := 0) -> Node2D:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(world)
	await h.landed_on_floor(world.get_node("Player"))
	return world


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("Player")


func _director(h) -> Node:
	return h.fixture.get_node("GameDirector")


## Holds a direction, and hops on meeting something, as someone seeing it late would.
func _walk_hopping(h, key: Key, reached: Callable, max_frames: int) -> bool:
	var player := _player(h)
	h.send(h.key_event(key, true))
	for i in max_frames:
		if reached.call():
			h.send(h.key_event(key, false))
			return true
		if player.is_on_wall() and player.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(10)
			h.send(h.key_event(KEY_SPACE, false))
		await h.steps(1)
	h.send(h.key_event(key, false))
	return false


func _wait_real_time(h, msec: int) -> void:
	var until := Time.get_ticks_msec() + msec
	while Time.get_ticks_msec() < until:
		await h.steps(1)


func _title(h) -> Control:
	var title: Control = await h.load_main_fixture(TITLE)
	await h.steps(3)
	return title


## ---- The prologue ----


func test_new_game_writes_the_save_first_then_shows_the_prologue(h) -> void:
	await _title(h)
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.has_method("skip_prologue"), 60, "the prologue")
	var prologue: Node = h.tree.current_scene
	h.check(prologue.get_mode() == 3, "the prologue is in mode %d" % prologue.get_mode())
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the save before the prologue holds: %s" % h.read_storage_file(SAVE_FILE))
	await h.steps(3)
	var lines: Node = prologue.get_node("Card/Items/Lines")
	h.check(lines.get_child_count() == 1 and lines.get_child(0).text.contains("raider"), "the first line is missing")
	h.check(prologue.get_node("Panels/Raider").visible and not prologue.get_node("Panels/Escape").visible, "the first picture is not the one shown")
	h.check(prologue.get_node("Music").playing and prologue.get_node("Music").bus == &"Music", "the prologue's music is not playing on the Music bus")


func test_continue_never_shows_the_prologue(h) -> void:
	h.write_storage_file(SAVE_FILE, ABYSS_SAVE.to_utf8_buffer())
	await _title(h)
	h.prologues_skipped = 0
	await h.tap_key(KEY_ENTER)
	var seen := [false]
	for i in 60:
		await h.steps(1)
		if is_instance_valid(h.tree.current_scene) and h.tree.current_scene.has_method("skip_prologue"):
			seen[0] = true
		if is_instance_valid(h.tree.current_scene) and h.tree.current_scene.is_class("GameSession"):
			break
	h.check(not seen[0], "Continue showed the prologue")
	h.check(is_instance_valid(h.tree.current_scene) and h.tree.current_scene.is_class("GameSession"), "Continue did not start the game")
	h.check(h.tree.current_scene.get_session_beat() == ABYSS, "Continue started at beat %d" % h.tree.current_scene.get_session_beat())


## Watched to the end, pressed through, or skipped: each starts the same game, from the same save.
func test_finishing_pressing_through_and_skipping_the_prologue_reach_the_same_state(h) -> void:
	var states := []
	for how in ["skip", "press", "watch"]:
		DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))
		await _title(h)
		await h.tap_key(KEY_ENTER)
		await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.has_method("skip_prologue"), 60, "the prologue")
		await h.steps(3)
		match how:
			"skip":
				await h.tap_key(KEY_ESCAPE)
			"press":
				for i in 4:
					await h.tap_key(KEY_ENTER)
					await h.steps(2)
			"watch":
				await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.is_class("GameSession"), 3000, "the prologue to finish by itself")
		await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.is_class("GameSession") and h.tree.current_scene.is_node_ready(), 120, "the game after the prologue (%s)" % how)
		var session: Node = h.tree.current_scene
		h.fixture = session
		await h.steps(5)
		states.append([session.get_session_beat(), session.get_node("PauseLayer/PauseMenu").is_open(), h.read_storage_file(SAVE_FILE)])
		await h.unload_fixture()
	h.check(states[0] == states[1] and states[1] == states[2], "the three ways in differ: %s" % str(states))
	h.check(states[0][0] == 0 and states[0][1] and states[0][2] == SHORE_SAVE, "the game did not start at the Shore with its introduction: %s" % str(states[0]))


func test_the_prologue_is_short_and_one_line_at_a_time(h) -> void:
	var prologue: Node = (load(PROLOGUE) as PackedScene).instantiate()
	h.check(prologue.ending_lines.size() == 4, "the prologue has %d lines" % prologue.ending_lines.size())
	h.check(prologue.get_node("Panels").get_child_count() == prologue.ending_lines.size(), "a line without a picture")
	var words := 0
	for id in prologue.ending_lines:
		words += narration_text(id).split(" ").size()
	h.check(words < 120, "the prologue runs to %d words" % words)
	prologue.free()


func narration_text(id: String) -> String:
	for line in FileAccess.get_file_as_string("res://narration/script.txt").split("\n"):
		if line.begins_with(id + "|"):
			return line.split("|")[2]
	return ""


## The epilogue's rescue follows from the prologue's boat, and Innsmouth reads as a town to someone who has never
## heard of it.
func test_the_story_hangs_together_from_the_prologue_to_the_epilogue(h) -> void:
	h.check(narration_text("prologue.escape").contains("boat"), "the prologue loses the boat")
	h.check(narration_text("shore.boat").begins_with("My boat"), "the Shore does not recognize his own boat")
	h.check(narration_text("ending.found").contains("boat"), "the rescue does not find him in the boat")
	h.check(narration_text("ending.innsmouth").contains("town called Innsmouth"), "Innsmouth is not explained")
	h.check(not narration_text("ending.innsmouth").contains("Last spring"), "the epilogue still says 'last spring'")


## ---- The crossing in Act II ----


func test_the_slab_starts_raised_and_walking_up_it_from_the_hollow_brings_it_down_level(h) -> void:
	var world := await _world(h, ABYSS)
	var crossing: Node2D = world.get_node("Crossing")
	var director := _director(h)
	h.check(not director.is_crossing_lowered(), "the slab starts down")
	h.check(absf(crossing.rotation - director.crossing_raised_rotation) < 0.001, "the slab starts at %.3f" % crossing.rotation)
	await h.stand_at(_player(h), Vector2(RIM_X, -2))
	var across: bool = await _walk_hopping(h, KEY_D, func() -> bool: return _player(h).global_position.x > FAR_RIM_X + 10.0, 900)
	h.check(across, "walking and hopping did not get across, stopped at %s" % _player(h).global_position)
	h.check(director.is_crossing_lowered(), "the slab is not down")
	h.check(absf(crossing.rotation) < 0.001, "the slab is not level: %.3f" % crossing.rotation)
	h.check(not world.get_node("Triggers/CrossingWeight").enabled, "the weight trigger is still armed")


func test_the_slab_comes_down_once_with_one_sound_and_one_line(h) -> void:
	var world := await _world(h, ABYSS)
	var sound: AudioStreamPlayer2D = world.get_node("Crossing/Sound")
	var hud: Node = world.get_node("Hud")
	var director := _director(h)
	await h.stand_at(_player(h), Vector2(2262, -40))
	await h.steps(5)
	h.check(director.is_crossing_lowered(), "a weight beyond the stone did not bring it down")
	h.check(sound.playing, "the slab came down in silence")
	h.check(world.get_node("Hud/Caption").visible and world.get_node("Hud/Caption").text.contains("tipped"), "no line as it came down: '%s'" % world.get_node("Hud/Caption").text)
	await h.wait_until(func() -> bool: return not director.is_crossing_moving(), 120, "the slab to settle")
	# Walking back over it, and onto the spot again, changes nothing and says nothing.
	hud.hide_caption()
	await h.steps(2)
	sound.stop()
	await h.stand_at(_player(h), Vector2(2180, -2))
	await h.stand_at(_player(h), Vector2(2262, -2))
	await h.steps(10)
	h.check(not sound.playing, "the slab's sound played again")
	h.check(not world.get_node("Hud/Caption").visible, "the line was said again")


func test_a_world_restored_at_the_abyss_has_the_slab_up_and_from_the_monolith_on_has_it_down(h) -> void:
	for pair in [[ABYSS, false], [MONOLITH, true], [AWAKENED, true]]:
		var world := await _world(h, pair[0])
		var director := _director(h)
		h.check(director.is_crossing_lowered() == pair[1], "at beat %d the slab is %s" % [pair[0], "down" if director.is_crossing_lowered() else "up"])
		h.check(not world.get_node("Crossing/Sound").playing, "restoring beat %d played the slab's sound" % pair[0])
		h.check(not world.get_node("Hud/Caption").visible, "restoring beat %d said something" % pair[0])
		await h.unload_fixture()


func test_once_down_the_crossing_can_be_walked_both_ways(h) -> void:
	var world := await _world(h, MONOLITH)
	h.check(_director(h).is_crossing_lowered(), "the slab is up at the Monolith")
	await h.stand_at(_player(h), Vector2(FAR_RIM_X + 30.0, -2))
	var back: bool = await _walk_hopping(h, KEY_A, func() -> bool: return _player(h).global_position.x < RIM_X, 600)
	h.check(back, "could not walk back over the slab: at %s" % _player(h).global_position)
	h.check(_player(h).global_position.y < 2.0, "fell into the hollow going back")
	var again: bool = await _walk_hopping(h, KEY_D, func() -> bool: return _player(h).global_position.x > FAR_RIM_X + 10.0, 600)
	h.check(again, "could not walk forward over the slab: at %s" % _player(h).global_position)
	h.check(world != null, "no world")


## ---- The returning sea ----


func _begin_the_flee(h) -> Node2D:
	var world := await _world(h, AWAKENED)
	var director := _director(h)
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 20, "the flee to begin")
	await h.steps(2)
	return world


func test_the_sea_is_hidden_until_the_flee_then_rises_and_comes_on_behind_him(h) -> void:
	var world := await _world(h, AWAKENED)
	var tide: Node2D = world.get_node("Tide")
	h.check(not tide.visible, "the sea is there before the flee")
	await h.unload_fixture()
	world = await _begin_the_flee(h)
	tide = world.get_node("Tide")
	var director := _director(h)
	h.check(tide.visible, "no sea in the flee")
	h.check_near(tide.global_position.x, director.tide_start_x, 1.0, "the sea's start")
	_player(h).teleport(Vector2(3780, -2))
	await h.steps(240)
	h.check(tide.global_position.x < director.tide_start_x - 40.0, "the sea did not come on: %.1f" % tide.global_position.x)
	h.check_near(tide.global_position.x, director.get_tide_front(), 0.5, "the drawn sea against the rule")
	h.check(world.get_node("Tide/Roar").playing, "the sea is silent")


func test_with_its_picture_gone_the_sea_still_ends_the_flee(h) -> void:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(AWAKENED)
	# The director has no picture of the sea to move. The rule is its own, so the flee still ends.
	world.get_node("GameDirector").tide_path = NodePath()
	await h.load_with(world)
	await h.landed_on_floor(world.get_node("Player"))
	var director := _director(h)
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 20, "the flee to begin")
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 400, "the sea to reach him")
	h.check(director.get_beat() == ENDED, "with no picture of the sea, the flee never ended")


func test_the_fallback_ends_a_flee_that_the_sea_cannot(h) -> void:
	var world := await _begin_the_flee(h)
	var director := _director(h)
	director.tide_speed = 0.0
	director.flee_timeout = 1.0
	_player(h).teleport(Vector2(4000, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == ENDED, 120, "the fallback")
	h.check(director.get_beat() == ENDED, "the fallback did not end the flee")
	h.check(world != null, "no world")


func test_restarting_during_the_flee_puts_the_sea_back_where_it_was(h) -> void:
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(AWAKENED, true, false)
	await h.load_with(session)
	await h.steps(5)
	var director: Node = session.get_director()
	await h.stand_at(session.get_world().get_node("Player"), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 20, "the flee to begin")
	await h.steps(200)
	session.restart_checkpoint()
	await h.steps(5)
	var world: Node = session.get_world()
	h.check(not world.get_node("Tide").visible, "the sea is still there after a restart")
	h.check(not world.get_node("Tide/Roar").playing, "the sea is still roaring after a restart")
	h.check(session.get_director().get_beat() == AWAKENED, "restarted at beat %d" % session.get_director().get_beat())


## ---- Sound ----


func test_every_sound_is_on_its_bus_and_the_ambience_loops(h) -> void:
	var world := await _world(h)
	for player in world.get_node("Sound").get_children():
		if player is AudioStreamPlayer2D:
			h.check(player.bus == &"Effects", "%s is on %s" % [player.name, player.bus])
			h.check(player.autoplay and player.stream.loop, "%s is not a looping ambience" % player.name)
		elif player is AudioStreamPlayer:
			var music: bool = player.name.begins_with("Music")
			h.check(player.bus == (&"Music" if music else &"Effects"), "%s is on %s" % [player.name, player.bus])
			h.check(not player.autoplay, "%s plays by itself" % player.name)
	for path in ["Player/Footsteps", "Player/Breath", "Player/Gasp"]:
		h.check(world.get_node(path).bus == &"Effects", "%s is on %s" % [path, world.get_node(path).bus])
	var ending: Node = (load("res://scenes/ui/ending.tscn") as PackedScene).instantiate()
	h.check(ending.get_node("Music").bus == &"Music", "the ending's music is on %s" % ending.get_node("Music").bus)
	ending.free()


func test_no_one_shot_sound_plays_in_a_world_restored_at_any_beat(h) -> void:
	for beat in [0, ABYSS, MONOLITH, AWAKENED]:
		var world := await _world(h, beat)
		await h.steps(10)
		for path in ONE_SHOTS:
			h.check(not world.get_node(path).playing, "restoring beat %d played %s" % [beat, path])
		h.check(world.get_node("Sound/ShoreSea").playing, "restoring beat %d left the ambience silent" % beat)
		await h.unload_fixture()


func test_footsteps_follow_walking_and_change_where_the_rock_begins(h) -> void:
	var world := await _world(h)
	var player := _player(h)
	var steps: AudioStreamPlayer2D = world.get_node("Player/Footsteps")
	h.check(player.surface_at(300.0) == 0 and player.surface_at(700.0) == 1, "the surfaces are %d and %d" % [player.surface_at(300.0), player.surface_at(700.0)])
	await h.steps(10)
	var before: int = player.get_footstep_count()
	await h.steps(30)
	h.check(player.get_footstep_count() == before, "standing still made footsteps")
	for leg in [[300.0, "sand"], [760.0, "rock"]]:
		await h.stand_at(player, Vector2(leg[0], -2))
		await h.steps(10)
		var heard := {}
		var sounding := [false]
		before = player.get_footstep_count()
		h.send(h.key_event(KEY_D, true))
		for i in 60:
			await h.steps(1)
			if steps.playing and steps.stream != null:
				sounding[0] = true
				heard[steps.stream.resource_path.get_file()] = true
		h.send(h.key_event(KEY_D, false))
		h.check(player.get_footstep_count() >= before + 3, "a second of walking on %s made %d steps" % [leg[1], player.get_footstep_count() - before])
		h.check(sounding[0], "the steps on %s made no sound" % leg[1])
		h.check(not heard.is_empty() and heard.keys().all(func(file: String) -> bool: return file.begins_with(leg[1])), "walking on %s sounded like %s" % [leg[1], heard.keys()])
		h.check(heard.size() >= 2, "every step on %s was the same sound: %s" % [leg[1], heard.keys()])


func test_his_breathing_and_its_pace_follow_the_story(h) -> void:
	for pair in [[0, "tired", 0.7], [ABYSS, "", 0.9], [MONOLITH, "uneasy", 1.15]]:
		var world := await _world(h, pair[0])
		var breath: AudioStreamPlayer2D = world.get_node("Player/Breath")
		if pair[1] == "":
			h.check(not breath.playing, "beat %d breathes aloud" % pair[0])
		else:
			h.check(breath.playing and breath.stream.resource_path.contains(pair[1]), "beat %d breathes %s" % [pair[0], breath.stream.resource_path if breath.stream else "nothing"])
		h.check_near(_player(h).idle_speed, pair[2], 0.001, "the pace of his breathing at beat %d" % pair[0])
		await h.unload_fixture()
	await _begin_the_flee(h)
	h.check(h.fixture.get_node("Player/Breath").stream.resource_path.contains("panic"), "he is not out of breath running")


func test_pausing_holds_every_sound_and_resuming_carries_on(h) -> void:
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(0, true, false)
	await h.load_with(session)
	await h.steps(30)
	var sea: AudioStreamPlayer2D = session.get_world().get_node("Sound/ShoreSea")
	h.check(sea.playing, "no sea on the Shore")
	await h.tap_key(KEY_ESCAPE)
	h.check(h.tree.paused, "Esc did not pause")
	var held := sea.get_playback_position()
	# Sound runs in real time, and these frames do not, so the waits are by the clock.
	await _wait_real_time(h, 400)
	h.check_near(sea.get_playback_position(), held, 0.06, "the sea while paused")
	await h.tap_key(KEY_ESCAPE)
	await _wait_real_time(h, 400)
	h.check(sea.get_playback_position() > held + 0.2, "the sea did not carry on after resuming")


## A missing sound must never stop anything: every stream is taken away, and the whole final sequence still plays out.
func test_with_every_sound_missing_the_final_sequence_still_reaches_the_ending(h) -> void:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(AWAKENED)
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for player in world.find_children("*", type, true, false):
			player.stream = null
	world.get_node("GameDirector").breath_streams = []
	world.get_node("Player").footstep_sets = []
	await h.load_with(world, true)
	await h.landed_on_floor(world.get_node("Player"))
	var director := _director(h)
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == FLEEING, 1200, "the reveal to play out")
	_player(h).teleport(Vector2(COLLAPSE_X, -2))
	var ending: Node = await h.wait_for_scene("MenuController", 600)
	h.check(ending.get_node_or_null("Center/Card") != null, "the silent game did not reach the ending")


## ---- The sailor ----


func test_the_reveal_staggers_him_and_he_stands_straight_when_control_returns(h) -> void:
	var world := await _world(h, AWAKENED)
	var clip: Animation = world.get_node("Cinematics").get_animation(&"dagon_reveal")
	h.check(clip.find_track(NodePath("Player/Visual:position"), Animation.TYPE_VALUE) >= 0, "no stagger in the reveal")
	var director := _director(h)
	await h.stand_at(_player(h), Vector2(WITNESS_X, -2))
	await h.wait_until(func() -> bool: return director.get_beat() == WITNESS, 20, "the reveal to start")
	var clips: AnimationPlayer = world.get_node("Cinematics")
	clips.seek(8.0, true)
	await h.steps(2)
	h.check(world.get_node("Player/Visual").position.x < -1.0, "he did not stagger back: %s" % world.get_node("Player/Visual").position)
	# A clip cut short there must not leave him leaning.
	director.finalize_cinematic(director.get_generation())
	await h.wait_until(func() -> bool: return _player(h).is_control_enabled(), 60, "control to return")
	h.check(world.get_node("Player/Visual").position == Vector2.ZERO and is_zero_approx(world.get_node("Player/Visual").rotation), "control returned with him still staggered")


## ---- What is new to see ----


func test_the_shore_has_the_arm_and_the_carvings_echo_it(h) -> void:
	var world := await _world(h)
	var arm: Node = world.get_node("Props/Tentacle")
	h.check(arm.line_id == &"shore.tentacle", "the arm says %s" % arm.line_id)
	h.check(world.get_node("Tentacle").texture != null, "the arm is not drawn")
	h.check(narration_text("shore.tentacle").contains("sucker") and not narration_text("shore.tentacle").contains("Dagon"), "the arm's line overreaches")
	h.check(narration_text("cave.carving").contains("arm") and narration_text("mural.after").contains("arms"), "the carvings do not echo the arm")
	for path in ["Props/Relief/Arm", "Monolith/MuralLit/ArmLeft", "Monolith/MuralLit/ArmRight"]:
		h.check(world.get_node_or_null(path) != null, "%s is missing" % path)


func test_the_finished_section_is_clipped_to_itself_and_its_greybox_is_gone(h) -> void:
	var world := await _world(h)
	for path in ["AbyssView", "CaveView"]:
		h.check(world.get_node(path).clip_children == CanvasItem.CLIP_CHILDREN_ONLY, "%s does not clip" % path)
	for path in ["Props/CaveCarving/Panel", "Props/FossilA/Art", "Props/TabletWave/Art", "ActArt/CaveBack", "ActArt/CaveRoof", "RitualLayer/Rise", "RitualLayer/Haze"]:
		h.check(not world.get_node(path).visible, "the greybox %s still shows in the finished section" % path)
	for path in ["Props/CaveCarving", "Props/FossilA", "Props/TabletWave"]:
		h.check(world.get_node(path).line_id != &"", "%s lost its line" % path)
	h.check(world.get_node("ReferenceSection/MoonShaft").enabled, "the moonlight through the mouth is off")
