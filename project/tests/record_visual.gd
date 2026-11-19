extends SceneTree
## Short scenes for Godot's Movie Maker to record with their sound, for the owner's visual pass of 2026-11-19.
## Evidence, not a test. DAGON_RECORD_SCENE picks the scene:
##   ritual    from the first checkpoint, walking in with real keys until the ritual begins, then standing to watch it
##   approach  from the Awakened checkpoint along the walkway beside the ridge, into the reveal: the walk, the last
##             still moment and the first movement in one take, to five seconds into the clip
## On a private display:
## DISPLAY=:77 DAGON_RECORD_SCENE=approach DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project \
##     --resolution 960x540 --write-movie <out.avi> --fixed-fps 30 --script res://tests/record_visual.gd
## It prints "RECORD <stage> frame=<n>" at each stage.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const ABYSS := 1
const AWAKENED := 3

var h


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _run() -> void:
	h = Harness.new(self)
	var scene := OS.get_environment("DAGON_RECORD_SCENE")
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(ABYSS if scene == "ritual" else AWAKENED, true, false)
	await h.load_with(session, true)
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.wait_for_control()
	_mark("control")
	await h.steps(30)
	if scene == "ritual":
		var clips: AnimationPlayer = route.world().get_node("Background")
		await route.walk(KEY_D, func() -> bool: return clips.is_playing() and clips.current_animation == "ritual_tableau", 60 * 30)
		_mark("ritual")
		await h.wait_until(func() -> bool: return not clips.is_playing() or clips.current_animation_position >= 11.0, 60 * 15, "the ritual")
		_mark("ritual-11s")
	else:
		await route.walk_into_the_reveal()
		_mark("reveal")
		var clips: AnimationPlayer = route.world().get_node("Cinematics")
		await h.wait_until(func() -> bool: return clips.current_animation_position >= 1.5, 60 * 5, "the first movement")
		_mark("first-movement")
		await h.wait_until(func() -> bool: return clips.current_animation_position >= 5.0, 60 * 10, "five seconds in")
		_mark("reveal-5s")
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	await h.steps(3)
	quit(0)
