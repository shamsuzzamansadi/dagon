extends SceneTree
## Stills at the game's own 480 x 270 for the owner's visual pass of 2026-11-19: the captivity and the escape with
## their lines on the card; the ritual as the sailor walks into it, each moment once with the caption and once with
## the Hud hidden, to see whether the picture tells it alone; and the walk beside the ridge to the reveal. Evidence,
## not a test. Needs a real window, so on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 --fixed-fps 60 \
##     --script res://tests/capture_visual.gd -- <output dir> [prologue|ritual|approach]

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const ABYSS := 1
const AWAKENED := 3

var h
var out := ""


func _initialize() -> void:
	_run()


func _save(shot: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(out.path_join(shot + ".png"))
	print("CAPTURE %s" % shot)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	var only: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	h = Harness.new(self)
	if only.is_empty() or only == "prologue":
		await _prologue()
	if only.is_empty() or only == "ritual":
		await _ritual()
	if only.is_empty() or only == "approach":
		await _approach()
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _prologue() -> void:
	var prologue: Node = (load("res://scenes/ui/prologue.tscn") as PackedScene).instantiate()
	root.add_child(prologue)
	await _frames(90)
	await _save("prologue-1-captivity")
	prologue.advance_ending()
	await _frames(90)
	await _save("prologue-2-escape")
	await _frames(60 * 8)
	await _save("prologue-2-escape-lamp-out")
	for sound in prologue.find_children("*", "AudioStreamPlayer", true, false):
		sound.stop()
	prologue.queue_free()
	await _frames(3)


## Walks in from the first checkpoint with real keys until the ritual begins, stops, and lets it play. At each moment
## the clip is held for the two stills, with the caption and without the Hud.
func _ritual() -> void:
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(ABYSS, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	var clips: AnimationPlayer = route.world().get_node("Background")
	await route.walk(KEY_D, func() -> bool: return clips.is_playing() and clips.current_animation == "ritual_tableau", 60 * 30)
	var hud: CanvasLayer = route.world().get_node("Hud")
	for at in [1.5, 3.5, 5.5, 7.5, 9.5]:
		await h.wait_until(func() -> bool: return clips.current_animation_position >= at, 60 * 15, "the ritual at %.1f s" % at)
		clips.pause()
		await _save("ritual-%04.1f-caption" % at)
		hud.hide()
		await h.steps(2)
		await _save("ritual-%04.1f-no-caption" % at)
		hud.show()
		clips.play()
	session.queue_free()
	await h.steps(3)


## From the Awakened checkpoint along the walkway beside the ridge, into the reveal's first seconds.
func _approach() -> void:
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(AWAKENED, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	await h.steps(30)
	await _save("approach-0-start")
	var body := route.player()
	h.send(h.key_event(KEY_D, true))
	var shot := 1
	for i in 60 * 15:
		await h.steps(1)
		if not body.is_control_enabled():
			break
		if i % 45 == 44:
			await _save("approach-%d-x%d" % [shot, roundi(body.global_position.x)])
			shot += 1
	h.send(h.key_event(KEY_D, false))
	var clips: AnimationPlayer = route.world().get_node("Cinematics")
	for at in [0.0, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5]:
		await h.wait_until(func() -> bool: return clips.current_animation_position >= at, 60 * 10, "the reveal at %.1f s" % at)
		await _save("reveal-%03.1f" % at)
	session.queue_free()
	await h.steps(3)
