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
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the save before How to Play holds: %s" % h.read_storage_file(SAVE_FILE))
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return h.is_prologue(h.tree.current_scene), 60, "the prologue")
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
		if h.is_prologue(h.tree.current_scene) or h.is_introduction(h.tree.current_scene):
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
		await h.tap_key(KEY_ENTER)
		await h.wait_until(func() -> bool: return h.is_prologue(h.tree.current_scene), 60, "the prologue")
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
		# Each opens on him getting up, with nothing over the game, and hands him the same game when he is up.
		var waking: bool = session.get_director().is_cinematic_active() and session.get_node("World/Player").get_shown_pose() == &"wake"
		var covered: bool = session.get_node("PauseLayer/PauseMenu").is_open() or h.tree.paused
		await h.wait_for_control(session.get_node("World/Player"))
		states.append([session.get_session_beat(), waking, covered, session.get_node("World/Player").global_position.round(), h.read_storage_file(SAVE_FILE)])
		await h.unload_fixture()
	h.check(states[0] == states[1] and states[1] == states[2], "the three ways in differ: %s" % str(states))
	h.check(states[0][0] == 0 and states[0][1] and not states[0][2] and states[0][4] == SHORE_SAVE, "the game did not start at the Shore, on him getting up, with nothing over it: %s" % str(states[0]))


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


## The director's own rule, behind the stone's one-shot prompt: once pushed, a second push, however it arrives, while
## the slab is on its way down or after it has settled, neither restarts it nor plays it again. No key can send one, as
## the prompt is gone (M3's breakage, "The slab comes down again for each weight", survived for that reason), so this
## sends the stone's signal itself.
func test_a_second_push_from_anywhere_neither_restarts_the_slab_nor_raises_it_again(h) -> void:
	var world := await _world(h, ABYSS)
	var crossing: Node2D = world.get_node("Crossing")
	var sound: AudioStreamPlayer2D = world.get_node("Crossing/Sound")
	var push: Node = world.get_node("CrossingStone/Push")
	var director := _director(h)
	await _climb_and_push(h)
	var pushed := Engine.get_process_frames()
	await h.steps(6)
	push.interacted.emit(push.interaction_id)
	await h.wait_until(func() -> bool: return not director.is_crossing_moving(), 240, "the slab to settle")
	var frames := Engine.get_process_frames() - pushed
	var expected := roundi((director.crossing_fall_seconds + director.crossing_lower_seconds) * 60.0)
	h.check(frames <= expected + 3, "a second push mid-fall made the slab take %d frames, not %d" % [frames, expected])
	sound.stop()
	push.interacted.emit(push.interaction_id)
	var highest := [0.0]
	for i in expected + 10:
		await h.steps(1)
		highest[0] = maxf(highest[0], absf(crossing.rotation))
	h.check(highest[0] < 0.001, "a push after it settled raised the slab to %.3f" % highest[0])
	h.check(not director.is_crossing_moving(), "a push after it settled set the slab moving")
	h.check(not sound.playing, "a push after it settled played the slab's sound")


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


## "The first soon after he sets off": after a stop, whatever he had walked before it, the first step comes within
## half a step's length. M3's breakage "Standing still makes footsteps" removed the line that does this, and survived:
## standing still stayed silent, as the test above checks, and only this changed.
func test_after_a_stop_the_first_step_comes_soon_after_he_sets_off(h) -> void:
	var world := await _world(h)
	var player := _player(h)
	await h.stand_at(player, Vector2(300, -2))
	await h.steps(10)
	# Stopped just after a step: almost none of the next step's length is walked when he stands.
	var before: int = player.get_footstep_count()
	h.send(h.key_event(KEY_D, true))
	await h.wait_until(func() -> bool: return player.get_footstep_count() > before + 1, 120, "two steps")
	h.send(h.key_event(KEY_D, false))
	await h.wait_until(func() -> bool: return absf(player.velocity.x) < 0.01, 120, "him to stand")
	await h.steps(20)
	var count: int = player.get_footstep_count()
	var from_x := player.global_position.x
	h.send(h.key_event(KEY_D, true))
	await h.wait_until(func() -> bool: return player.get_footstep_count() > count, 120, "the first step after the stop")
	h.send(h.key_event(KEY_D, false))
	var walked := player.global_position.x - from_x
	h.check(walked <= player.footstep_spacing * 0.5, "the first step after a stop came %.1f px on, a step is %.1f" % [walked, player.footstep_spacing])


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
	for part in ["Body", "Head", "Head/Crest", "Arm", "Ridge"]:
		var shape: Polygon2D = world.get_node("Dagon/" + part)
		var art: Sprite2D = world.get_node("Dagon/%s/Art" % part)
		h.check(is_zero_approx(shape.color.a), "the flat %s still draws over its art" % part)
		h.check(art.texture != null, "%s has no art" % part)
		var box := Rect2(shape.polygon[0], Vector2.ZERO)
		for point in shape.polygon:
			box = box.expand(point)
		h.check(art.position.distance_to(box.position) <= 1.0, "%s's art is placed at %s, its shape at %s" % [part, art.position, box.position])


## The ridge beside the walkway stands in water before the reveal (D116): the water is drawn over the creature and
## under the walkway, shown from the start, covers the ridge's foot where it stands, and no clip moves or hides it.
## The ritual's strip of ground is drawn over the four who kneel and lit as the backdrop it copies (D118).
func test_the_ridge_stands_in_water_and_the_ritual_ground_lies_before_the_kneelers(h) -> void:
	var world := await _world(h, AWAKENED)
	var water: Sprite2D = world.get_node("TrenchFront/Shallows")
	var dagon: Node2D = world.get_node("Dagon")
	h.check(water.visible and water.texture != null and water.get_parent().visible, "the water at the ridge's foot is not shown")
	h.check(water.get_parent().get_index() > dagon.get_index(), "the water is drawn under the creature")
	h.check(water.get_parent().get_index() < world.get_node("AbyssGround").get_index(), "the water is drawn over the walkway")
	var ridge: Sprite2D = world.get_node("Dagon/Ridge/Art")
	var foot := ridge.global_position.y + ridge.texture.get_height()
	h.check(foot > 0.0 and water.global_position.y + water.texture.get_height() >= 0.0, "the ridge's foot is not under the water and the walkway: %.0f" % foot)
	for player_name in ["Cinematics", "Atmosphere", "Background"]:
		var player: AnimationPlayer = world.get_node(player_name)
		for clip_name in player.get_animation_list():
			var clip := player.get_animation(clip_name)
			for track in clip.get_track_count():
				h.check(not String(clip.track_get_path(track)).begins_with("TrenchFront/Shallows"), "%s moves the water at the ridge's foot" % clip_name)
	var ground: Sprite2D = world.get_node("RitualLayer/Ground")
	var figures: Node2D = world.get_node("RitualLayer/Figures")
	h.check(ground.get_index() > figures.get_index(), "the ritual's ground is drawn under the kneelers")
	h.check(ground.light_mask == (world.get_node("RitualLayer/Backdrop") as CanvasItem).light_mask, "the ritual's ground is lit unlike the backdrop it copies")


const EMERGE := "res://assets/reveal/emerge.gdshader"


## The owner's playtest of 2026-11-19 of ea86ae9, the emergence. The creature comes out of the fog from the ridge
## outward (D119): the body, the head and the crest draw through one shader, each with its own map of how far it lies
## from the ridge, at half its drawing's size, and the fades that drive it are the clip's own, where they were. The
## water runs before the whole creature, from the ridge's foot across the trench and down below the lowest the camera
## shows, its shake included, so nothing of it shows under the waterline; the trench's own water, behind it, is no
## longer moved.
func test_the_creature_comes_out_from_the_ridge_and_out_of_one_water(h) -> void:
	var world := await _world(h, AWAKENED)
	for path in ["Dagon/Body/Art", "Dagon/Head/Art", "Dagon/Head/Crest/Art"]:
		var art: Sprite2D = world.get_node(path)
		var material := art.material as ShaderMaterial
		h.check(material != null and material.shader != null and material.shader.resource_path == EMERGE, "%s does not come out from the ridge" % path)
		if material == null:
			continue
		var reach: Texture2D = material.get_shader_parameter("reach")
		h.check(reach != null and reach.get_size() * 2.0 == art.texture.get_size(), "%s's reach is not half the size of its drawing" % path)
	var clip: Animation = world.get_node("Cinematics").get_animation(&"dagon_reveal")
	for path in ["Dagon/Body:modulate", "Dagon/Head:modulate"]:
		var track := clip.find_track(NodePath(path), Animation.TYPE_VALUE)
		h.check(track >= 0 and clip.track_get_key_count(track) == 2, "%s is not one fade" % path)
		if track < 0:
			continue
		h.check(is_equal_approx(clip.track_get_key_time(track, 0), 3.0) and is_equal_approx(clip.track_get_key_time(track, 1), 4.3), "%s no longer fades from 3.0 to 4.3 s" % path)
		h.check(clip.track_get_key_value(track, 0).a == 0.0 and clip.track_get_key_value(track, 1).a == 1.0, "%s does not fade from 0 to 1" % path)
	h.check(clip.find_track(NodePath("Trench/WaterDrawn:position"), Animation.TYPE_VALUE) < 0, "the reveal still moves the trench's water")
	var water: Sprite2D = world.get_node("TrenchFront/Shallows")
	var shown := Rect2(water.global_position, water.texture.get_size())
	var body: Sprite2D = world.get_node("Dagon/Body/Art")
	var camera: Camera2D = world.get_node("CameraRig")
	var widest := clip.find_track(NodePath("CameraRig:limit_right"), Animation.TYPE_VALUE)
	h.check(shown.position.x <= body.global_position.x and shown.end.x >= float(clip.track_get_key_value(widest, 0)), "the water %s does not run before the whole creature" % shown)
	h.check(shown.end.y >= camera.limit_bottom + camera.max_shake, "the water stops at y=%.0f, above the lowest the camera shows" % shown.end.y)
	var image := water.texture.get_image()
	var gaps := 0
	for y in image.get_height():
		for x in image.get_width():
			gaps += 1 if image.get_pixel(x, y).a < 1.0 else 0
	h.check(gaps == 0, "the water has %d clear pixels" % gaps)


## The shader and the particles are drawn from the moment the level loads, beside the camera and showing nothing, so
## that neither is first drawn, and the game stalled, in the middle of the reveal (D119): the crest through its own
## material, at an alpha Godot draws, below which its map brings out none of it; and one clear particle.
func test_the_reveal_does_not_stall_on_a_first_draw(h) -> void:
	var world := await _world(h, AWAKENED)
	var camera: Node = world.get_node("CameraRig")
	var warm: Sprite2D = world.get_node("CameraRig/Warm/Emerge")
	var crest: Sprite2D = world.get_node("Dagon/Head/Crest/Art")
	h.check(warm.is_visible_in_tree() and warm.get_parent().get_parent() == camera, "the shader's warm-up is not drawn beside the camera")
	h.check(warm.material == crest.material and warm.texture == crest.texture, "the warm-up is not the crest through its own material")
	var alpha := warm.modulate.a
	h.check(alpha >= 0.01, "the warm-up at alpha %.3f may not be drawn at all" % alpha)
	var reach: Image = ((crest.material as ShaderMaterial).get_shader_parameter("reach") as Texture2D).get_image()
	var drawing := crest.texture.get_image()
	var nearest := 1.0
	for y in reach.get_height():
		for x in reach.get_width():
			if drawing.get_pixel(x * 2, y * 2).a > 0.0 or drawing.get_pixel(x * 2 + 1, y * 2 + 1).a > 0.0:
				nearest = minf(nearest, reach.get_pixel(x, y).r)
	h.check(alpha * 1.25 < nearest - 0.05, "at alpha %.2f the warm-up would show the crest where its reach is %.2f" % [alpha, nearest])
	var particles: CPUParticles2D = world.get_node("CameraRig/Warm/Particles")
	h.check(particles.is_visible_in_tree() and particles.emitting and particles.color.a == 0.0, "the particles' warm-up is missing, still, or seen")


## The owner's playtest of 2026-11-19 of ea86ae9: the hand looked detached from the body. The arm turns about one point
## on the body's outline, within the turn its drawing is made for (D107), and the body's own pixels where the arm
## crosses the body are laid over it from the moment it shows, lit as the body is (D120): so wherever the arm lies over
## the body, at any moment of its swing, the body is drawn over it, and its root never shows. Its fade-in brings it
## out from the shoulder to the hand, through the same shader as the body: its map is 0 at the shoulder and greatest
## at the fingertips.
func test_the_arm_comes_out_from_under_the_shoulder(h) -> void:
	const SHOULDER := Vector2(-305, -166)
	var world := await _world(h, AWAKENED)
	var clip: Animation = world.get_node("Cinematics").get_animation(&"dagon_reveal")
	var moves := clip.find_track(NodePath("Dagon/Arm:position"), Animation.TYPE_VALUE)
	var turns := clip.find_track(NodePath("Dagon/Arm:rotation"), Animation.TYPE_VALUE)
	h.check(moves >= 0 and turns >= 0 and clip.track_get_key_count(moves) == clip.track_get_key_count(turns), "the arm's keys do not pair")
	for key in clip.track_get_key_count(turns):
		var turn: float = clip.track_get_key_value(turns, key)
		var at: Vector2 = clip.track_get_key_value(moves, key)
		h.check(turn >= -0.5001 and turn <= 0.2201, "at %.2f s the arm turns %.3f, past what its shoulder is drawn for" % [clip.track_get_key_time(turns, key), turn])
		h.check((at + SHOULDER.rotated(turn)).distance_to(SHOULDER) < 0.6, "at %.2f s the arm does not turn about its shoulder" % clip.track_get_key_time(turns, key))
	var arm: Node2D = world.get_node("Dagon/Arm")
	var arm_material := (world.get_node("Dagon/Arm/Art") as CanvasItem).material as ShaderMaterial
	h.check(arm_material != null and arm_material.shader != null and arm_material.shader.resource_path == EMERGE, "the arm does not come out from the shoulder")
	if arm_material != null:
		var arm_reach: Image = (arm_material.get_shader_parameter("reach") as Texture2D).get_image()
		var arm_drawn: Sprite2D = world.get_node("Dagon/Arm/Art")
		h.check(arm_reach.get_size() * 2 == Vector2i(arm_drawn.texture.get_size()), "the arm's reach is not half the size of its drawing")
		var at_shoulder := Vector2i((SHOULDER - arm_drawn.position) / 2.0)
		h.check(arm_reach.get_pixelv(at_shoulder).r == 0.0, "the arm does not start at the shoulder")
		var fingertip := Vector2i((Vector2(-490, -244) - arm_drawn.position) / 2.0)
		h.check(arm_reach.get_pixelv(fingertip).r > 0.9, "the arm's hand is not the last of it to come")
	var over: Node2D = world.get_node("Dagon/Shoulder")
	h.check(not over.visible, "the shoulder over the arm shows before the arm")
	var arm_shows := clip.find_track(NodePath("Dagon/Arm:visible"), Animation.TYPE_VALUE)
	var over_shows := clip.find_track(NodePath("Dagon/Shoulder:visible"), Animation.TYPE_VALUE)
	h.check(over_shows >= 0 and clip.track_get_key_time(over_shows, 0) == clip.track_get_key_time(arm_shows, 0), "the shoulder does not show with the arm")
	h.check(over.z_index == arm.z_index and over.get_index() > arm.get_index(), "the shoulder is drawn under the arm")
	var rims := clip.find_track(NodePath("Dagon/Rims:modulate"), Animation.TYPE_VALUE)
	var lit := clip.find_track(NodePath("Dagon/Shoulder/Lit:modulate"), Animation.TYPE_VALUE)
	h.check(lit >= 0 and clip.track_get_key_count(lit) == clip.track_get_key_count(rims), "the shoulder is not lit as the body is")
	if lit >= 0:
		for key in clip.track_get_key_count(rims):
			h.check(clip.track_get_key_time(lit, key) == clip.track_get_key_time(rims, key) and clip.track_get_key_value(lit, key) == clip.track_get_key_value(rims, key), "the shoulder's light differs from the body's at key %d" % key)
	# Its pixels are the body's own, where it lies.
	var body: Sprite2D = world.get_node("Dagon/Body/Art")
	var body_image := body.texture.get_image()
	var art: Sprite2D = world.get_node("Dagon/Shoulder/Art")
	var art_image := art.texture.get_image()
	var offset := Vector2i(art.position - body.position)
	var differ := 0
	for y in art_image.get_height():
		for x in art_image.get_width():
			if art_image.get_pixel(x, y).a > 0.0 and art_image.get_pixel(x, y) != body_image.get_pixelv(offset + Vector2i(x, y)):
				differ += 1
	h.check(differ == 0, "%d of the shoulder's pixels are not the body's" % differ)
	# Wherever the arm lies over the body, the shoulder lies over the arm: as it comes, at the top of its swing, just
	# before it lands, as it lands, and at rest.
	await h.stand_at(_player(h), Vector2(4420, -2))
	var clips: AnimationPlayer = world.get_node("Cinematics")
	var arm_art: Sprite2D = world.get_node("Dagon/Arm/Art")
	var arm_image := arm_art.texture.get_image()
	for seconds in [5.6, 6.5, 6.95, 7.0, 10.0]:
		clips.seek(seconds, true)
		await h.steps(1)
		var open := 0
		for y in arm_image.get_height():
			for x in arm_image.get_width():
				if arm_image.get_pixel(x, y).a == 0.0:
					continue
				var p: Vector2 = arm.transform * (arm_art.position + Vector2(x, y) + Vector2(0.5, 0.5))
				var on_body := Vector2i((p - body.position).floor())
				if on_body.x < 0 or on_body.y < 0 or on_body.x >= body_image.get_width() or on_body.y >= body_image.get_height() or body_image.get_pixelv(on_body).a == 0.0:
					continue
				var on_art := Vector2i((p - art.position).floor())
				var covered := on_art.x >= 0 and on_art.y >= 0 and on_art.x < art_image.get_width() and on_art.y < art_image.get_height() and art_image.get_pixelv(on_art).a > 0.0
				open += 0 if covered else 1
		h.check(open == 0, "at %.2f s %d of the arm's pixels lie over the body and out from under the shoulder" % [seconds, open])


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


## The pictures keep what matters above row 190 (tools/art/gen_ending.py). The card sizes to its line, so the
## longest line sets how high it comes: it may not come higher than that row, in any of the four.
func test_the_epilogue_card_stays_below_what_the_pictures_show(h) -> void:
	const CLEAR_OF_THE_CARD := 190.0
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	var card: Control = ending.get_node("Center/Card")
	for line in ending.ending_lines.size():
		await h.steps(4)
		h.check(ending.get_ending_line() == line, "line %d is not showing" % line)
		var top := card.get_global_rect().position.y
		h.check(top >= CLEAR_OF_THE_CARD, "at line %d the card's top is at %.0f, over the picture" % [line, top])
		h.check(top < 262.0 and card.get_global_rect().end.y <= 270.0, "at line %d the card is off the screen: %s" % [line, card.get_global_rect()])
		if line + 1 < ending.ending_lines.size():
			ending.advance_ending()


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
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return h.is_prologue(h.tree.current_scene), 60, "the prologue")
	await h.steps(10)
	h.tree.current_scene.skip_prologue()
	await h.wait_until(func() -> bool: return is_instance_valid(h.tree.current_scene) and h.tree.current_scene.is_class("GameSession"), 60, "the game")
	# Its sound goes on under the game's for a quarter of a second, fading, so the cut has no gap (D103). Then nothing.
	await h.steps(30)
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
	# The last picture is the Shore, and its sea and wind are the Shore's: they hold their level into the game (D97).
	var untouched: Node = (load("res://scenes/ui/prologue.tscn") as PackedScene).instantiate()
	for sound_name in ["Sea", "Wind"]:
		var sound: AudioStreamPlayer = prologue.get_node("Panels/Dry/" + sound_name)
		var as_placed: float = untouched.get_node("Panels/Dry/" + sound_name).volume_db
		h.check(sound.playing and is_equal_approx(sound.volume_db, as_placed), "the last picture's %s is at %.1f dB, placed at %.1f" % [sound_name, sound.volume_db, as_placed])
	untouched.free()
	var world: Node = (load("res://scenes/level/shore.tscn") as PackedScene).instantiate()
	h.check(prologue.get_node("Panels/Dry/Sea").stream == world.get_node("Sound/ShoreSea").stream and prologue.get_node("Panels/Dry/Wind").stream == world.get_node("Sound/ShoreWind").stream, "the last picture does not sound like the Shore")
	world.free()
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


## The Abyss is not one sound throughout: open mud, then the deeper mud, then the canyon, in the order he walks them.
func test_the_abyss_sounds_deeper_as_he_goes_on(h) -> void:
	var world := await _world(h, 1)
	var names := ["Sound/AbyssNear", "Sound/AbyssMid", "Sound/AbyssFar"]
	var files := ["abyss.ogg", "abyss_deep.ogg", "canyon.ogg"]
	for i in names.size():
		var sound: AudioStreamPlayer2D = world.get_node(names[i])
		h.check(sound.stream.resource_path.ends_with("/" + files[i]), "%s plays %s" % [names[i], sound.stream.resource_path])
		if i > 0:
			h.check(sound.global_position.x > world.get_node(names[i - 1]).global_position.x, "%s is not further on than %s" % [names[i], names[i - 1]])


## A clip moves only what can be seen: no track animates a node that is hidden in the scene and that the clip itself
## never shows. Art drawn over a greybox shape must be what the clip moves, or the motion is lost: the gate's rise and
## the trench's water were, for a while in M4. Hidden means hidden where it stands: a node under a hidden parent is
## hidden too, unless the clip shows that parent.
## What a clip moves must draw something. A shape kept only for its outline draws nothing itself (its colour is
## clear), so it has to carry a drawing that is shown: otherwise the clip moves nothing anyone can see, which is how
## the gate stood still in M4.
func test_every_shape_a_clip_moves_or_fades_draws_something(h) -> void:
	var world := await _world(h)
	var checked := 0
	for player_name in ["Cinematics", "Atmosphere", "Background"]:
		var player: AnimationPlayer = world.get_node(player_name)
		for clip_name in player.get_animation_list():
			var clip := player.get_animation(clip_name)
			for track in clip.get_track_count():
				if clip.track_get_type(track) != Animation.TYPE_VALUE:
					continue
				var path := String(clip.track_get_path(track))
				var shape := world.get_node_or_null(path.get_slice(":", 0)) as Polygon2D
				if shape == null or shape.color.a > 0.0 or not shape.vertex_colors.is_empty():
					continue
				checked += 1
				var drawings := shape.find_children("*", "Sprite2D", true, false)
				var seen := false
				for drawing in drawings:
					seen = seen or (drawing.texture != null and drawing.visible)
				h.check(seen, "%s animates %s, a shape that draws nothing and carries no shown drawing" % [clip_name, path])
	h.check(checked >= 10, "only %d clear shapes were checked" % checked)


## The rock across the way back and the returning sea are shown by the director, as outcomes of the flight, not by its
## clip: test_narrative and this file hold that they show with no clip at all.
const SHOWN_BY_THE_DIRECTOR := ["Rockfall", "Tide"]


## The nodes a clip shows. A :visible track counts only if it is enabled and has a key, within the clip, that sets
## true: a track whose every key is false hides its node, it never shows it, so its being there proves nothing.
static func _shown_by(clip: Animation) -> Dictionary:
	var shown := {}
	for track in clip.get_track_count():
		var path := String(clip.track_get_path(track))
		if clip.track_get_type(track) != Animation.TYPE_VALUE or not path.ends_with(":visible") or not clip.track_is_enabled(track):
			continue
		for key in clip.track_get_key_count(track):
			var value = clip.track_get_key_value(track, key)
			if value is bool and value and clip.track_get_key_time(track, key) <= clip.length:
				shown[path.get_slice(":", 0)] = true
	return shown


## What a clip moves or fades under a node that is hidden and that the clip never shows, as "track: hidden node",
## and the number of tracks looked at. The director's two are left out by their exact paths.
static func _hidden_and_never_shown(world: Node, clip: Animation) -> Array:
	var shown := _shown_by(clip)
	var found := []
	var checked := 0
	for track in clip.get_track_count():
		var path := String(clip.track_get_path(track))
		if clip.track_get_type(track) != Animation.TYPE_VALUE or path.ends_with(":visible"):
			continue
		var node := world.get_node_or_null(path.get_slice(":", 0))
		if node == null:
			found.append("%s: missing" % path)
			continue
		if not node is CanvasItem:
			continue
		checked += 1
		var at: Node = node
		while at != world and at != null:
			var at_path := String(world.get_path_to(at))
			if at is CanvasItem and not at.visible and not shown.has(at_path) and not SHOWN_BY_THE_DIRECTOR.has(at_path):
				found.append("%s: %s" % [path, at_path])
			at = at.get_parent()
	return [found, checked]


func test_no_clip_animates_a_hidden_node_it_never_shows(h) -> void:
	var world := await _world(h)
	var checked := 0
	for player_name in ["Cinematics", "Atmosphere", "Background"]:
		var player: AnimationPlayer = world.get_node(player_name)
		for clip_name in player.get_animation_list():
			var result := _hidden_and_never_shown(world, player.get_animation(clip_name))
			checked += result[1]
			for problem in result[0]:
				h.check(false, "%s animates %s, which is hidden and never shown by it" % [clip_name, problem])
	h.check(checked > 10, "only %d tracks were checked" % checked)


## The check above, on a made-up clip: a :visible track whose keys are all false does not excuse moving a hidden node,
## nor does a true key on a disabled track or past the clip's end; a true key within the clip does, and the
## director's exemption covers only its own node.
func test_a_visibility_track_that_only_hides_does_not_count_as_showing(h) -> void:
	var world := Node2D.new()
	var hidden := Sprite2D.new()
	hidden.name = "Hidden"
	hidden.visible = false
	world.add_child(hidden)
	var rock := Sprite2D.new()
	rock.name = "Rockfall"
	rock.visible = false
	world.add_child(rock)
	var under_rock := Sprite2D.new()
	under_rock.name = "Stone"
	under_rock.visible = false
	rock.add_child(under_rock)

	var clip := Animation.new()
	clip.length = 2.0
	var moves := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(moves, "Hidden:position")
	clip.track_insert_key(moves, 0.0, Vector2.ZERO)
	clip.track_insert_key(moves, 1.0, Vector2(10, 0))
	var shows := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(shows, "Hidden:visible")
	clip.track_insert_key(shows, 0.0, false)
	clip.track_insert_key(shows, 1.0, false)
	h.check(_hidden_and_never_shown(world, clip)[0] == ["Hidden:position: Hidden"], "a track of false keys was taken as showing the node: %s" % [_hidden_and_never_shown(world, clip)[0]])

	clip.track_insert_key(shows, 3.0, true)
	h.check(_hidden_and_never_shown(world, clip)[0] == ["Hidden:position: Hidden"], "a true key after the clip's end was taken as showing the node")
	clip.track_remove_key_at_time(shows, 3.0)
	clip.track_insert_key(shows, 1.5, true)
	clip.track_set_enabled(shows, false)
	h.check(_hidden_and_never_shown(world, clip)[0] == ["Hidden:position: Hidden"], "a true key on a disabled track was taken as showing the node")
	clip.track_set_enabled(shows, true)
	h.check(_hidden_and_never_shown(world, clip)[0].is_empty(), "a true key within the clip was not taken as showing the node: %s" % [_hidden_and_never_shown(world, clip)[0]])

	var rock_clip := Animation.new()
	rock_clip.length = 1.0
	var rock_moves := rock_clip.add_track(Animation.TYPE_VALUE)
	rock_clip.track_set_path(rock_moves, "Rockfall:position")
	rock_clip.track_insert_key(rock_moves, 0.0, Vector2.ZERO)
	var stone_moves := rock_clip.add_track(Animation.TYPE_VALUE)
	rock_clip.track_set_path(stone_moves, "Rockfall/Stone:position")
	rock_clip.track_insert_key(stone_moves, 0.0, Vector2.ZERO)
	h.check(_hidden_and_never_shown(world, rock_clip)[0] == ["Rockfall/Stone:position: Rockfall/Stone"], "the director's exemption reached past its own node: %s" % [_hidden_and_never_shown(world, rock_clip)[0]])
	world.free()
