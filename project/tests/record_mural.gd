extends SceneTree
## The owner's playtest of 2026-11-19, at the Monolith: walking in, the sailor reaches the mural while monolith.first is
## being said; a press there cuts the line short, and the next press examines the mural. For Godot's Movie Maker to
## record with its sound, so the prompt each build shows can be seen against what each press does. Evidence, not a
## test (test_narration holds the behaviour). On a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 960x540 --write-movie <out.avi> \
##     --fixed-fps 30 --script res://tests/record_mural.gd
## It prints "RECORD <stage> frame=<n>" at each stage, and the prompt's text at each press.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const ABYSS := 1
const MURAL_X := 3898.0

var h


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _run() -> void:
	h = Harness.new(self)
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(ABYSS, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	var hud: Node = route.world().get_node("Hud")
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	# Past the low block he jumps on the way, short of where the Monolith's line begins.
	route.player().teleport(Vector2(3560, -2))
	await h.steps(60)
	_mark("walking")
	h.send(h.key_event(KEY_D, true))
	var marked := false
	for i in 60 * 12:
		if not marked and hud.get_current_line() == &"monolith.first":
			_mark("line-monolith.first")
			marked = true
		if route.player().global_position.x >= MURAL_X - 4.0:
			break
		if route.player().is_on_floor() and i > 0 and i % 40 == 0 and route.player().get_real_velocity().x < 1.0:
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(12)
			h.send(h.key_event(KEY_SPACE, false))
		await h.steps(1)
	h.send(h.key_event(KEY_D, false))
	_mark("at-the-mural line=%s" % hud.get_current_line())
	await h.steps(45)
	print("PROMPT before the first press: %s" % route.prompt().text)
	_mark("press-1")
	await h.tap_key(KEY_E)
	await h.steps(2)
	print("PROMPT after the first press: %s; line=%s" % [route.prompt().text, hud.get_current_line()])
	await h.steps(80)
	print("PROMPT before the second press: %s" % route.prompt().text)
	_mark("press-2")
	await h.tap_key(KEY_E)
	await h.steps(2)
	print("PROMPT after the second press: %s; line=%s" % [route.prompt().text, hud.get_current_line()])
	await h.steps(60 * 3)
	_mark("end")
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
