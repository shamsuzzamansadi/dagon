extends SceneTree
## The stone gate, for Godot's Movie Maker to record with its sound: from the Monolith checkpoint, a try at getting past
## the closed gate by walking and jumping into it, then the stones solved with one mistake, the awakening as the gate
## rises, and the walk through the open gate to the edge of the reveal. Evidence, not a test. On a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 960x540 --write-movie <out.avi> \
##     --fixed-fps 30 --script res://tests/record_gate.gd
## It prints "RECORD <stage> frame=<n>" at each stage, and what the try at the closed gate reached.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const MONOLITH := 2
const GATE_LEFT := 4292.0

var h


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _run() -> void:
	h = Harness.new(self)
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(MONOLITH, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	# The closed gate: walk into it and jump at it for four seconds.
	route.player().teleport(Vector2(4230, -2))
	await h.steps(20)
	_mark("closed-gate")
	h.send(h.key_event(KEY_D, true))
	var furthest := 0.0
	for i in 240:
		if i % 24 == 0:
			await h.tap_key(KEY_SPACE)
		else:
			await h.steps(1)
		furthest = maxf(furthest, route.player().global_position.x)
	h.send(h.key_event(KEY_D, false))
	print("RECORD gate-try furthest_x=%.1f gate_left=%.1f beat=%d" % [furthest, GATE_LEFT, route.director().get_beat()])
	await h.steps(20)
	# The stones, from before the first of them.
	route.player().teleport(Vector2(3700, -2))
	await h.steps(20)
	_mark("to-the-stones")
	await route.solve_with_one_mistake()
	_mark("stones-solved")
	await route.wait_for_control()
	_mark("gate-open")
	await route.walk(KEY_D, func() -> bool: return route.player().global_position.x > 4380.0, 900)
	_mark("through-the-gate")
	print("RECORD after x=%.1f beat=%d" % [route.player().global_position.x, route.director().get_beat()])
	await h.steps(30)
	_mark("end")
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
