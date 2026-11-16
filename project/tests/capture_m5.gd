extends SceneTree
## Saves frames of the reveal as it plays, and of the ending's four pictures, at the game's own scale. Evidence for M5,
## not a test. The reveal is not sought: the sailor walks into it from the Awakened checkpoint with real keys, and a
## frame is saved each half second of the clip, so particles, light and the camera are as a player sees them, and one
## frame cannot be put right while another breaks. Needs a real window, so on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 --fixed-fps 60 \
##     --script res://tests/capture_m5.gd -- <output dir> [reveal|ending]

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const AWAKENED := 3
const STEP := 0.5

var h
var out := ""


func _initialize() -> void:
	_run()


func _save(shot: String) -> void:
	root.get_texture().get_image().save_png(out.path_join(shot + ".png"))
	print("CAPTURE %s" % shot)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	var only: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	h = Harness.new(self)
	if only.is_empty() or only == "reveal":
		await _reveal()
	if only.is_empty() or only == "ending":
		await _ending()
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)


func _reveal() -> void:
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(AWAKENED, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	_save("reveal-before")
	await route.walk_into_the_reveal()
	var clips: AnimationPlayer = route.world().get_node("Cinematics")
	var next := 0.0
	for i in 60 * 20:
		if not route.director().is_cinematic_active():
			break
		var at := clips.current_animation_position if clips.is_playing() else 99.0
		if at >= next and at < 90.0:
			await process_frame
			_save("reveal-%04.1f" % next)
			next += STEP
		await h.steps(1)
	await h.steps(30)
	_save("reveal-after-0.5")
	await h.steps(90)
	_save("reveal-after-2.0")
	session.queue_free()
	await h.steps(3)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _ending() -> void:
	var ending: Node = (load("res://scenes/ui/ending.tscn") as PackedScene).instantiate()
	root.add_child(ending)
	for line in ending.ending_lines.size():
		await _frames(100)
		_save("ending-%d-a" % (line + 1))
		await _frames(150)
		_save("ending-%d-b" % (line + 1))
		if line + 1 < ending.ending_lines.size():
			ending.advance_ending()
	for sound in ending.find_children("*", "AudioStreamPlayer", true, false):
		sound.stop()
	ending.queue_free()
	await _frames(3)
