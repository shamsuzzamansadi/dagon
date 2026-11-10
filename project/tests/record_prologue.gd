extends SceneTree
## Plays New Game from the main menu: the whole prologue at its own pace, nothing pressed, then the game's first
## moments and his first steps on the Shore, for Godot's Movie Maker to record with its sound. Evidence, not a test.
## On a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 960x540 --write-movie <out.avi> \
##     --fixed-fps 30 --script res://tests/record_prologue.gd
## It prints "RECORD <stage> frame=<n>" at each stage.
## For measuring the mix, DAGON_RECORD_ONLY=voice records the narration with the music and effects muted, and
## DAGON_RECORD_ONLY=bed records the music and effects with the voice silent, so nothing ducks for it. Neither is the
## game's mix, and neither is for listening: tools/audio/listening.py narration compares them with the real one.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")

var h


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _run() -> void:
	h = Harness.new(self)
	await h.load_main_fixture("res://scenes/ui/title.tscn")
	_mark("title")
	await h.steps(60)
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.has_method("skip_prologue"), 120, "the prologue")
	var prologue: Node = current_scene
	var only := OS.get_environment("DAGON_RECORD_ONLY")
	if only == "voice":
		for bus in ["Music", "Effects"]:
			AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)
	elif only == "bed":
		prologue.get_node("Voice").volume_db = -80.0
	for line in prologue.ending_lines.size():
		await h.wait_until(func() -> bool: return not is_instance_valid(prologue) or prologue.get_ending_line() >= line, 60 * 60, "line %d" % line)
		_mark("line-%d-%s" % [line + 1, prologue.ending_lines[line]])
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.is_class("GameSession") and current_scene.is_node_ready(), 60 * 60, "the game")
	h.fixture = current_scene
	_mark("game")
	var route = RoutePlayer.new(h)
	# Whatever the game shows first is left on screen long enough to be seen and heard, then answered as a player would.
	await h.steps(60 * 4)
	if route.pause_menu().is_open():
		_mark("introduction-answered")
		await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return route.player().is_control_enabled(), 60 * 30, "control")
	_mark("control")
	await h.steps(60 * 2)
	_mark("first-steps")
	await route.walk(KEY_D, func() -> bool: return route.player().global_position.x > 240.0, 60 * 20)
	await h.steps(60 * 2)
	_mark("end")
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
