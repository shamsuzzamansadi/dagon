extends SceneTree
## The game's last four minutes, for Godot's Movie Maker to record with its sound: from the Awakened checkpoint,
## through the open gate into the reveal, the flight from the sea, the fall, and the ending with every line left to
## run, then the credits. It marks each spoken line as it starts, so tools/audio/listening.py narration can measure
## the voice against what plays beneath it. Evidence, not a test. On a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 960x540 --write-movie <out.avi> \
##     --fixed-fps 30 --script res://tests/record_finale.gd
## It prints "RECORD <stage> frame=<n>" at each stage. DAGON_RECORD_ONLY=voice records the narration with the music
## and effects muted, and =bed the music and effects with the voice silent. Neither is the game's mix.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const AWAKENED := 3

var h
var only := ""
var spoken := 0


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


## Steps until the condition holds, marking every story line the Hud starts on the way. With a runner, hops when he
## is stopped by something, as anyone running would.
func _until(hud: Node, done: Callable, max_steps: int, runner: CharacterBody2D = null) -> void:
	var last := &""
	var last_x := runner.global_position.x if runner != null else 0.0
	var stalled := 0
	for i in max_steps:
		if done.call():
			return
		var line: StringName = hud.get_current_line() if is_instance_valid(hud) else &""
		if line != last:
			if line != &"":
				spoken += 1
				_mark("line-%d-%s" % [spoken, line])
			last = line
		if runner != null and is_instance_valid(runner):
			stalled = stalled + 1 if absf(runner.global_position.x - last_x) < 0.2 else 0
			last_x = runner.global_position.x
			if stalled >= 6 and runner.is_on_floor():
				h.send(h.key_event(KEY_SPACE, true))
				await h.steps(12)
				h.send(h.key_event(KEY_SPACE, false))
				stalled = 0
		await h.steps(1)


func _run() -> void:
	h = Harness.new(self)
	only = OS.get_environment("DAGON_RECORD_ONLY")
	if only == "voice":
		for bus in ["Music", "Effects"]:
			AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(AWAKENED, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	var hud: Node = route.world().get_node("Hud")
	if only == "bed":
		hud.get_node("Voice").volume_db = -80.0
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	_mark("gate-open")
	await h.steps(60)
	await route.walk_into_the_reveal()
	_mark("reveal")
	await _until(hud, func() -> bool: return route.player().is_control_enabled() and not route.director().is_cinematic_active(), 60 * 30)
	_mark("escape-running")
	h.send(h.key_event(KEY_A, true))
	var body: CharacterBody2D = route.player()
	await _until(hud, func() -> bool: return not is_instance_valid(body) or not body.is_control_enabled(), 60 * 40, body)
	h.send(h.key_event(KEY_A, false))
	_mark("collapse")
	var ending: Node = await h.wait_for_scene("MenuController", 600)
	_mark("ending")
	if only == "bed":
		ending.get_node("Voice").volume_db = -80.0
	for line in ending.ending_lines.size():
		await h.wait_until(func() -> bool: return ending.get_ending_line() >= line, 60 * 60, "line %d" % line)
		spoken += 1
		_mark("line-%d-%s" % [spoken, ending.ending_lines[line]])
	# The last line, spoken and read to its end, as a player who presses nothing hears it, and a moment after.
	var shown := Engine.get_process_frames()
	await h.wait_until(func() -> bool: return not ending.get_node("Voice").playing and Engine.get_process_frames() - shown > 30 * 9, 60 * 40, "the last line to end")
	await h.steps(60 * 3)
	_mark("last-line-over")
	await h.tap_key(KEY_ENTER)
	_mark("credits")
	await h.steps(60 * 6)
	_mark("end")
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
