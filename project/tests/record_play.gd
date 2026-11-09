extends SceneTree
## Plays the game from the main menu through both endings, as a person would, with its sound, for Godot's Movie
## Maker to record picture and mix together. Evidence, not a test. On a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 960x540 --write-movie <out.avi> \
##     --fixed-fps 30 --script res://tests/record_play.gd
## It prints "RECORD <stage> frame=<n>" at each stage, so the recording can be cut into labelled excerpts.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")

var h


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _game() -> Node:
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.is_class("GameSession") and current_scene.is_node_ready(), 60 * 90, "the game")
	h.fixture = current_scene
	return current_scene


func _run() -> void:
	h = Harness.new(self)
	await h.load_main_fixture("res://scenes/ui/title.tscn")
	_mark("title")
	await h.steps(90)
	await h.tap_key(KEY_ENTER)
	# The whole prologue, unskipped, at its own pace.
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.has_method("skip_prologue"), 120, "the prologue")
	_mark("prologue")
	await _game()
	var route = RoutePlayer.new(h)
	route.read_through = true
	await h.steps(90)
	await h.tap_key(KEY_ENTER)
	await h.landed_on_floor(route.player())
	_mark("shore")
	await route.walk(KEY_D, func() -> bool: return route.player().global_position.x > 330.0, 900, true)
	# A pause on the Shore: every sound should stop, and come back.
	_mark("pause")
	await h.tap_key(KEY_ESCAPE)
	await h.steps(120)
	await h.tap_key(KEY_ESCAPE)
	if route.pause_menu().is_open():
		await h.tap_key(KEY_ENTER)
	_mark("resume")
	await route.walk(KEY_D, func() -> bool: return route.director().get_beat() == 1, 3000, true)
	_mark("cave")
	await route.walk(KEY_D, func() -> bool: return route.player().global_position.x > 1440.0, 3000, true)
	_mark("seabed")
	await route.cross_the_gap()
	_mark("crossed")
	await route.solve_with_one_mistake()
	_mark("stones-solved")
	await route.wait_for_control()
	_mark("gate-open")
	await route.walk_into_the_reveal()
	_mark("reveal")
	await route.wait_for_control()
	_mark("escape-running")
	await route.flee_left()
	var ending: Node = await h.wait_for_scene("MenuController", 600)
	_mark("ending")
	await h.wait_until(func() -> bool: return ending.get_ending_line() == ending.ending_lines.size() - 1, 60 * 90, "the last line")
	await h.steps(60 * 8)
	await h.tap_key(KEY_ENTER)
	_mark("credits")
	await h.steps(60 * 4)
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.has_method("continue_game"), 120, "the main menu")
	_mark("main-menu")
	await h.steps(60)
	# Continue, and the other ending: at the ledge, stand still and let the sea come.
	await h.tap_key(KEY_ENTER)
	await _game()
	route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	_mark("continue")
	await route.walk_into_the_reveal()
	await route.wait_for_control()
	_mark("escape-standing-still")
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.has_method("advance_ending"), 60 * 40, "the sea")
	_mark("ending-again")
	await h.steps(60 * 6)
	_mark("end")
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
