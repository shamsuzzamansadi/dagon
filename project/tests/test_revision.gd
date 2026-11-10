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
const ONE_SHOTS := ["Sound/MusicCave", "Sound/WaterCascade", "Monolith/StoneAccept", "Monolith/StoneReject", "Monolith/GateSound", "Sound/MusicAwaken", "Sound/MusicReveal", "Sound/WaterSurge", "Sound/CreatureCall", "Sound/CreatureTurn", "Sound/HandImpact", "Sound/BodyFall", "Sound/SeaRush", "Sound/RitualDrum", "Crossing/Sound", "Tide/Roar", "Rockfall/SoundNear", "Rockfall/SoundMid", "Rockfall/SoundFar", "Player/Gasp"]


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


## Holds a direction and hops each time the sailor stands on something, as anyone climbing ledges does.
func _climb(h, key: Key, reached: Callable, max_frames: int) -> bool:
	var player := _player(h)
	h.send(h.key_event(key, true))
	for i in max_frames:
		if reached.call():
			h.send(h.key_event(key, false))
			return true
		if player.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(16)
			h.send(h.key_event(KEY_SPACE, false))
		await h.steps(1)
	h.send(h.key_event(key, false))
	return false


func _push_in_reach(h) -> bool:
	return _player(h).get_node("Interactor").get_focus() == h.fixture.get_node("CrossingStone/Push")


## Up the ledges to the stone, and push it: it falls on the raised end, and the slab comes down level.
func _climb_and_push(h) -> bool:
	await h.stand_at(_player(h), Vector2(1990, -2))
	var up: bool = await _climb(h, KEY_D, func() -> bool: return _push_in_reach(h), 600)
	h.check(up, "climbing did not reach the stone, at %s" % _player(h).global_position)
	await h.tap_key(KEY_E)
	return _director(h).is_crossing_lowered()


func test_the_slab_starts_raised_out_of_reach_and_the_gap_cannot_be_crossed_along_the_ground(h) -> void:
	var world := await _world(h, ABYSS)
	var crossing: Node2D = world.get_node("Crossing")
	var director := _director(h)
	h.check(not director.is_crossing_lowered(), "the slab starts down")
	h.check(absf(crossing.rotation - director.crossing_raised_rotation) < 0.001, "the slab starts at %.3f" % crossing.rotation)
	var near_end: Vector2 = crossing.global_transform * Vector2(-80, -4)
	h.check(near_end.y < -30.0, "the slab's near end is in reach, at %s" % near_end)
	# Along the ground, under the ledges and down into the hollow, hopping at everything: no way over.
	await h.stand_at(_player(h), Vector2(RIM_X - 140.0, -2))
	var across: bool = await _walk_hopping(h, KEY_D, func() -> bool: return _player(h).global_position.x > FAR_RIM_X + 10.0, 600)
	h.check(not across, "the gap was crossed without the stone")
	h.check(not director.is_crossing_lowered(), "walking brought the slab down")


func test_climbing_the_ledges_and_pushing_the_stone_brings_the_slab_down_and_it_can_be_crossed(h) -> void:
	var world := await _world(h, ABYSS)
	var crossing: Node2D = world.get_node("Crossing")
	var director := _director(h)
	h.check(await _climb_and_push(h), "pushing the stone did not bring the slab down")
	await h.wait_until(func() -> bool: return not director.is_crossing_moving(), 120, "the slab to settle")
	h.check(absf(crossing.rotation) < 0.001, "the slab is not level: %.3f" % crossing.rotation)
	var stone: Node2D = world.get_node("CrossingStone")
	var rest: Vector2 = crossing.global_transform * director.crossing_weight_rest
	h.check(stone.global_position.distance_to(rest) < 1.0, "the stone is at %s, not on the slab's end at %s" % [stone.global_position, rest])
	h.check(stone.collision_layer == 0, "the fallen stone still blocks")
	h.check(not world.get_node("CrossingStone/Push").is_available(), "the stone can be pushed again")
	var across: bool = await _walk_hopping(h, KEY_D, func() -> bool: return _player(h).global_position.x > FAR_RIM_X + 10.0, 600)
	h.check(across, "could not cross the lowered slab, stopped at %s" % _player(h).global_position)


func test_the_slab_comes_down_once_with_one_sound_and_one_line(h) -> void:
	var world := await _world(h, ABYSS)
	var sound: AudioStreamPlayer2D = world.get_node("Crossing/Sound")
	var hud: Node = world.get_node("Hud")
	var director := _director(h)
	await _climb_and_push(h)
	await h.steps(2)
	h.check(sound.playing, "the slab came down in silence")
	h.check(world.get_node("Hud/Caption").visible and world.get_node("Hud/Caption").text.contains("struck the raised end"), "no line as it came down: '%s'" % world.get_node("Hud/Caption").text)
	await h.wait_until(func() -> bool: return not director.is_crossing_moving(), 120, "the slab to settle")
	# Pressing again where the stone was, and walking over the slab, change nothing and say nothing.
	hud.hide_caption()
	await h.steps(2)
	sound.stop()
	await h.tap_key(KEY_E)
	await h.steps(10)
	h.check(not sound.playing, "the slab's sound played again")
	h.check(not world.get_node("Hud/Caption").visible or not world.get_node("Hud/Caption").text.contains("struck"), "the line was said again")


func test_a_world_restored_at_the_abyss_has_the_slab_up_and_from_the_monolith_on_has_it_down(h) -> void:
	for pair in [[ABYSS, false], [MONOLITH, true], [AWAKENED, true]]:
		var world := await _world(h, pair[0])
		var director := _director(h)
		var stone: Node2D = world.get_node("CrossingStone")
		var rest: Vector2 = world.get_node("Crossing").global_transform * director.crossing_weight_rest
		h.check(director.is_crossing_lowered() == pair[1], "at beat %d the slab is %s" % [pair[0], "down" if director.is_crossing_lowered() else "up"])
		h.check((stone.global_position.distance_to(rest) < 1.0) == pair[1], "at beat %d the stone is at %s" % [pair[0], stone.global_position])
		h.check(world.get_node("CrossingStone/Push").is_available() != pair[1], "at beat %d the stone's push is wrong" % pair[0])
		h.check(not world.get_node("Crossing/Sound").playing, "restoring beat %d played the slab's sound" % pair[0])
		h.check(not world.get_node("Hud/Caption").visible, "restoring beat %d said something" % pair[0])
		await h.unload_fixture()


func test_once_down_the_crossing_can_be_walked_both_ways(h) -> void:
	var world := await _world(h, MONOLITH)
	h.check(_director(h).is_crossing_lowered(), "the slab is up at the Monolith")
	await h.stand_at(_player(h), Vector2(FAR_RIM_X + 30.0, -2))
	var back: bool = await _walk_hopping(h, KEY_A, func() -> bool: return _player(h).global_position.x < RIM_X - 120.0, 600)
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
	h.check(narration_text("cave.carving").contains("arm") and narration_text("mural.after").contains("arm wrapped round a standing stone"), "the carvings do not echo the arm")
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


## ---- The payoff ----


func test_the_tentacle_is_large_enough_to_read_and_its_caption_does_not_claim_to_know(h) -> void:
	var world := await _world(h)
	var arm: Sprite2D = world.get_node("Tentacle")
	h.check(arm.texture.get_width() >= 80, "the arm is only %d px long" % arm.texture.get_width())
	var line := narration_text("shore.tentacle")
	h.check(line.contains("I told myself") and line.contains("could not see"), "the arm's caption is too sure: %s" % line)
	for remains in ["Ribs", "FishByTheBoat", "FishOnTheRise", "FishByTheArm"]:
		h.check(world.get_node(remains).texture != null, "%s is not on the Shore" % remains)


## The clue stands where the action is: on the rock above the ledges, large enough to read at the game's scale.
func test_the_carving_at_the_ledges_shows_how_the_gap_is_crossed(h) -> void:
	var world := await _world(h, ABYSS)
	var mark: Node = world.get_node("Props/CrossingMark")
	var art: Sprite2D = world.get_node("Props/CrossingMark/Art")
	h.check(art.texture.get_width() >= 72 and art.texture.get_height() >= 40, "the carving is only %s" % art.texture.get_size())
	var ledges_left: float = world.get_node("CrossingLedges/Low").polygon[0].x
	h.check(absf(mark.global_position.x - ledges_left) < 60.0, "the carving is not at the ledges: %.0f" % mark.global_position.x)
	await h.stand_at(_player(h), Vector2(mark.global_position.x, -2))
	h.check(_player(h).get_node("Interactor").get_focus() == mark, "the carving cannot be examined from below it")
	var line := narration_text("abyss.crossing_mark")
	h.check(line.contains("stone dropped on the raised end") and line.contains("level"), "the carving's line does not say what it shows: %s" % line)
	h.check(world.get_node("ActArt/PrintDown0").polygon[0].x < ledges_left, "the footprints do not lead to the ledges")


func test_the_monolith_and_the_creature_are_drawn_over_the_shapes_the_clips_move(h) -> void:
	var world := await _world(h, AWAKENED)
	h.check(world.get_node("Monolith/Art").visible and not world.get_node("Monolith/Back").visible, "the monolith is still the greybox block")
	for part in ["Body", "Head", "Crest", "Arm"]:
		var shape: Polygon2D = world.get_node("Dagon/" + part)
		var art: Sprite2D = world.get_node("Dagon/%s/Art" % part)
		h.check(is_zero_approx(shape.color.a), "the flat %s still draws over its art" % part)
		h.check(art.texture != null, "%s has no art" % part)
		var box := Rect2(shape.polygon[0], Vector2.ZERO)
		for point in shape.polygon:
			box = box.expand(point)
		h.check(art.position.distance_to(box.position) <= 1.0, "%s's art is placed at %s, its shape at %s" % [part, art.position, box.position])


## The great carving high on the stone, the lit mural, and the reveal show the same thing: an arm round a stone.
func test_the_lit_mural_carries_the_motif_the_reveal_then_shows(h) -> void:
	var world := await _world(h, AWAKENED)
	var pillar: Polygon2D = world.get_node("Monolith/MuralLit/ArmRight")
	var arm: Polygon2D = world.get_node("Monolith/MuralLit/ArmLeft")
	var pillar_box := Rect2(pillar.polygon[0], Vector2.ZERO)
	for point in pillar.polygon:
		pillar_box = pillar_box.expand(point)
	var arm_box := Rect2(arm.polygon[0], Vector2.ZERO)
	for point in arm.polygon:
		arm_box = arm_box.expand(point)
	h.check(pillar_box.size.y > pillar_box.size.x * 2.0, "the stone on the mural is not a standing stone")
	h.check(arm_box.position.x <= pillar_box.position.x + 1.0 and arm_box.end.x > pillar_box.end.x, "the arm on the mural does not reach round the stone")
	var clip: Animation = world.get_node("Cinematics").get_animation(&"dagon_reveal")
	var says := []
	for track in clip.get_track_count():
		if clip.track_get_type(track) == Animation.TYPE_METHOD:
			for key in clip.track_get_key_count(track):
				if clip.method_track_get_name(track, key) == &"say":
					says.append(String(clip.method_track_get_params(track, key)[0]))
	h.check(says.has("story.recoil") and narration_text("story.recoil").contains("same arm"), "the reveal does not name what he recognises")


func test_the_cave_music_starts_on_the_way_in_and_never_on_restore(h) -> void:
	var world := await _world(h, 0)
	var music: AudioStreamPlayer = world.get_node("Sound/MusicCave")
	h.check(not music.playing, "the cave's music plays on the Shore")
	await h.stand_at(_player(h), Vector2(660, -2))
	h.check(await _walk_hopping(h, KEY_D, func() -> bool: return _director(h).get_beat() == ABYSS, 600), "the sailor did not reach the cave")
	await h.steps(5)
	h.check(music.playing and music.bus == &"Music", "the cave's music did not start on the Music bus")
	await h.unload_fixture()
	world = await _world(h, ABYSS)
	await h.steps(10)
	h.check(not world.get_node("Sound/MusicCave").playing, "restoring in the cave replayed its music")


func test_the_epilogue_shows_a_picture_for_each_line_over_the_sea(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	await h.steps(3)
	var panels: Node = ending.get_node("Panels")
	h.check(panels.get_child_count() == ending.ending_lines.size(), "%d pictures for %d lines" % [panels.get_child_count(), ending.ending_lines.size()])
	for line in ending.ending_lines.size():
		await h.steps(2)
		var shown := []
		for panel in panels.get_children():
			if panel.visible:
				shown.append(panel.name)
		h.check(shown.size() == 1 and shown[0] == panels.get_child(line).name, "at line %d the pictures shown are %s" % [line, shown])
		if line + 1 < ending.ending_lines.size():
			await h.tap_key(KEY_ENTER)
	h.check(ending.get_node("Sea").playing and ending.get_node("Sea").bus == &"Effects", "no sea under the epilogue")
	h.check(ending.get_node("Music").playing and ending.get_node("Music").bus == &"Music", "no music under the epilogue")



func test_the_prologue_card_stays_under_its_pictures(h) -> void:
	var prologue: Node = await h.load_main_fixture("res://scenes/ui/prologue.tscn")
	var viewport: Rect2 = prologue.get_viewport_rect()
	for line in prologue.ending_lines.size():
		await h.steps(2)
		var card: Rect2 = prologue.get_node("Card").get_global_rect()
		h.check(viewport.encloses(card), "line %d is clipped: %s" % [line, card])
		h.check(card.position.y >= viewport.size.y * 0.66, "line %d's card covers its picture from y=%.0f" % [line, card.position.y])
		if line + 1 < prologue.ending_lines.size():
			prologue.advance_ending()


## Each picture of the prologue moves a little and has its own sound. Both start with it and stop with it.
func test_each_prologue_picture_moves_and_sounds_while_it_shows_and_nothing_carries_over(h) -> void:
	var prologue: Node = await h.load_main_fixture("res://scenes/ui/prologue.tscn")
	var panels: Node = prologue.get_node("Panels")
	for line in prologue.ending_lines.size():
		await h.steps(20)
		var shown: Node = panels.get_child(line)
		var sounds := shown.get_children().filter(func(node: Node) -> bool: return node is AudioStreamPlayer)
		h.check(not sounds.is_empty(), "%s has no sound" % shown.name)
		for sound in sounds:
			h.check(sound.playing and sound.bus == &"Effects", "%s/%s is not playing on Effects" % [shown.name, sound.name])
		h.check(shown.get_node("Motion").is_playing(), "%s does not move" % shown.name)
		for other in panels.get_children():
			if other == shown:
				continue
			for node in other.get_children():
				h.check(not (node is AudioStreamPlayer and node.playing), "%s/%s still plays under %s" % [other.name, node.name, shown.name])
			h.check(not other.get_node("Motion").is_playing(), "%s still moves under %s" % [other.name, shown.name])
		if shown.name == "Escape":
			var from: float = shown.get_node("Boat").position.x
			await h.steps(120)
			h.check(shown.get_node("Boat").position.x > from + 4.0, "the boat does not pull away")
		if shown.name == "Dry":
			# The line holds about 3.8 s, so he is sitting up well before it ends.
			await h.steps(110)
			h.check(shown.get_node("Sitting").modulate.a > 0.9 and shown.get_node("Lying").modulate.a < 0.1, "he does not sit up")
		if line + 1 < prologue.ending_lines.size():
			prologue.advance_ending()


func test_skipping_the_prologue_leaves_none_of_its_sound_in_the_game(h) -> void:
	await _title(h)
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.has_method("skip_prologue"), 60, "the prologue")
	await h.steps(10)
	h.tree.current_scene.skip_prologue()
	await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.is_class("GameSession"), 60, "the game")
	await h.steps(5)
	for name in ["Oars", "Water", "Wind"]:
		for node in h.tree.root.find_children(name, "AudioStreamPlayer", true, false):
			h.check(not node.playing, "the prologue's %s still plays in the game" % name)
	h.check(h.tree.root.find_children("Prologue", "MenuController", true, false).is_empty(), "the prologue is still there")


## As the hand comes down beside its carving, the carving is lit, so the eye goes from one to the other. Only then.
func test_the_carving_is_lit_only_while_the_hand_is_beside_it(h) -> void:
	var world := await _world(h, AWAKENED)
	var light: PointLight2D = world.get_node("Monolith/CarvingLight")
	h.check(is_zero_approx(light.energy), "the carving is lit before the reveal")
	var clip: AnimationPlayer = world.get_node("Cinematics")
	clip.play(&"dagon_reveal")
	clip.seek(8.0, true)
	clip.pause()
	h.check(light.energy > 1.0, "the carving is not lit as the hand comes down: %.2f" % light.energy)
	var monolith: Sprite2D = world.get_node("Monolith/Art")
	var carving := monolith.global_position + Vector2(253, 200)
	h.check(light.global_position.distance_to(carving) < 10.0, "the light is not on the carving of the swimmer")
	clip.seek(clip.current_animation_length, true)
	h.check(is_zero_approx(light.energy), "the carving stays lit after the reveal")
	clip.stop()


func test_the_master_bus_is_limited_below_full_scale(h) -> void:
	var master := AudioServer.get_bus_index(&"Master")
	var limited := false
	for i in AudioServer.get_bus_effect_count(master):
		var effect := AudioServer.get_bus_effect(master, i)
		if effect is AudioEffectHardLimiter and AudioServer.is_bus_effect_enabled(master, i):
			limited = effect.ceiling_db <= -1.0
	h.check(limited, "nothing keeps the mix below full scale")


func test_the_prologue_fades_over_its_last_line_and_the_ending_under_the_credits(h) -> void:
	var prologue: Node = await h.load_main_fixture("res://scenes/ui/prologue.tscn")
	var music: AudioStreamPlayer = prologue.get_node("Music")
	var start: float = music.volume_db
	for line in prologue.ending_lines.size() - 1:
		await h.steps(5)
		prologue.advance_ending()
	await h.steps(150)
	h.check(music.playing and music.volume_db < start - 12.0, "the prologue's music is at %.1f dB on its last line" % music.volume_db)
	h.check(prologue.get_node("Panels/Dry/Wind").volume_db < -14.0 - 12.0, "the wind does not fade with it")
	await h.unload_fixture()
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	var sea: AudioStreamPlayer = ending.get_node("Sea")
	var sea_start: float = sea.volume_db
	await h.steps(3)
	ending.open_credits()
	await h.steps(200)
	h.check(sea.playing and sea.volume_db < sea_start - 12.0, "the sea under the credits is at %.1f dB" % sea.volume_db)
	h.check(ending.get_node("Music").volume_db < -3.0 - 12.0, "the ending's music does not fade under the credits")


## The epilogue's card is its text, so turning subtitles off never hides it, voiced line or not.
func test_the_epilogue_shows_every_line_with_subtitles_off(h) -> void:
	h.write_storage_file("settings.cfg", "dagon_settings=1\nsubtitles=0\n".to_utf8_buffer())
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	for line in ending.ending_lines.size():
		await h.steps(3)
		var lines: Node = ending.get_node("Center/Card/Items/Lines")
		h.check(ending.get_node("Center/Card").visible and lines.get_child_count() == 1 and not lines.get_child(0).text.is_empty(), "line %d is not shown with subtitles off" % line)
		h.check(lines.get_child(0).text == narration_text(ending.ending_lines[line]), "line %d does not match the script" % line)
		if line + 1 < ending.ending_lines.size():
			ending.advance_ending()
