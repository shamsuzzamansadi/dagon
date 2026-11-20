extends SceneTree
## Short scenes for Godot's Movie Maker to record with their sound, for the owner's visual passes of 2026-11-19.
## Evidence, not a test. DAGON_RECORD_SCENE picks the scene:
##   ritual         from the first checkpoint, walking in with real keys until the ritual begins, then standing to
##                  watch it
##   approach       from the Awakened checkpoint along the walkway beside the ridge, into the reveal: the walk, the last
##                  still moment and the first movement in one take, to five seconds into the clip
##   emergence      the same walk into the reveal, held to nine seconds into the clip: the shoulder rising out of the
##                  water, the body, and the hand landing beside the carving
##   escape-run     the reveal, then running left with real keys from the moment he can, through the collapse
##   escape-caught  the reveal, then standing still until the sea has him, through the collapse
##   emergence-timing  the walk into the reveal at the game's own pace, not Movie Maker's, printing each frame's real
##                  length through the reveal's first seven seconds: a stall shows as one long frame, after which the
##                  clip jumps ahead
##   emergence-parts  the emergence with each part of the creature, the water before it, the walkway and the Monolith
##                  drawn in one flat colour of its own and nothing else shown, so that where the arm meets the body,
##                  and the creature the water, can be measured frame by frame (notes/owner-1119c/parts.py)
## On a private display:
## DISPLAY=:77 DAGON_RECORD_SCENE=approach DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project \
##     --resolution 960x540 --write-movie <out.avi> --fixed-fps 30 --script res://tests/record_visual.gd
## It prints "RECORD <stage> frame=<n>" at each stage, and in the last three a "TRACE" line each frame with where the
## creature, the camera, the sailor and the sea are.

const Harness := preload("res://tests/harness.gd")
const RoutePlayer := preload("res://tests/route_player.gd")
const ABYSS := 1
const AWAKENED := 3

var h
var route


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _trace() -> void:
	var world: Node = route.world()
	if not is_instance_valid(world):
		return
	var clips: AnimationPlayer = world.get_node("Cinematics")
	var dagon: Node2D = world.get_node("Dagon")
	var arm: Node2D = world.get_node("Dagon/Arm")
	var camera: Camera2D = world.get_node("CameraRig")
	var tide: Node2D = world.get_node("Tide")
	var clip := "%s@%.3f" % [clips.current_animation, clips.current_animation_position] if clips.is_playing() else "-"
	var center := camera.get_screen_center_position()
	print("TRACE frame=%d clip=%s dagon=%.2f,%.2f arm=%.2f,%.2f,%.4f camera=%.1f,%.1f zoom=%.3f sailor=%.1f,%.1f tide=%.1f,%s flee=%.3f" % [
		Engine.get_process_frames(), clip, dagon.position.x, dagon.position.y, arm.position.x, arm.position.y,
		arm.rotation, center.x, center.y, camera.zoom.x, route.player().global_position.x,
		route.player().global_position.y, tide.global_position.x, "shown" if tide.visible else "hidden",
		route.director().get_flee_elapsed()])


## Steps until the condition holds, tracing every frame.
func _traced(done: Callable, max_steps: int) -> void:
	for i in max_steps:
		if done.call():
			return
		_trace()
		await h.steps(1)


const FLAT := "shader_type canvas_item;\nrender_mode unshaded;\nuniform vec4 tone : source_color;\nvoid fragment() {\n\tCOLOR = vec4(tone.rgb, texture(TEXTURE, UV).a > 0.0 ? 1.0 : 0.0);\n}\n"
const PARTS := {"Dagon/Body/Art": Color(0, 1, 0), "Dagon/Arm/Art": Color(1, 0, 0), "Dagon/Ridge/Art": Color(0, 0, 1),
	"Dagon/Head/Art": Color(1, 1, 0), "Dagon/Head/Crest/Art": Color(1, 1, 0), "TrenchFront/Shallows": Color(0, 1, 1),
	"TrenchFront/Surge": Color(1, 1, 1), "Terrain/Art": Color(0.5, 0.5, 0.5), "Monolith/Art": Color(1, 0, 1),
	"Dagon/Shoulder/Art": Color(0, 1, 0), "AbyssGround/Tile3": Color(0.5, 0.5, 0.5)}


## Every part named in PARTS in its own flat colour, whatever its fade, and nothing else drawn.
func _flatten(world: Node) -> void:
	var shader := Shader.new()
	shader.code = FLAT
	var keep := {}
	for path in PARTS:
		var node: CanvasItem = world.get_node_or_null(path)
		if node == null:
			continue
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("tone", PARTS[path])
		node.material = material
		var at: Node = node
		while at != world:
			keep[at] = true
			at = at.get_parent()
	for node in world.find_children("*", "CanvasItem", true, false):
		if not keep.has(node):
			node.self_modulate = Color(1, 1, 1, 0)
	for node in world.find_children("*", "CanvasLayer", true, false):
		node.visible = false
	for node in world.find_children("*", "CPUParticles2D", true, false):
		node.visible = false


func _run() -> void:
	h = Harness.new(self)
	var scene := OS.get_environment("DAGON_RECORD_SCENE")
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(ABYSS if scene == "ritual" else AWAKENED, true, false)
	await h.load_with(session, true)
	route = RoutePlayer.new(h)
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
	elif scene == "approach":
		await route.walk_into_the_reveal()
		_mark("reveal")
		var clips: AnimationPlayer = route.world().get_node("Cinematics")
		await h.wait_until(func() -> bool: return clips.current_animation_position >= 1.5, 60 * 5, "the first movement")
		_mark("first-movement")
		await h.wait_until(func() -> bool: return clips.current_animation_position >= 5.0, 60 * 10, "five seconds in")
		_mark("reveal-5s")
	elif scene == "emergence-timing":
		await route.walk_into_the_reveal()
		_mark("reveal")
		var clips: AnimationPlayer = route.world().get_node("Cinematics")
		var last := Time.get_ticks_usec()
		while clips.is_playing() and clips.current_animation_position < 7.0:
			await process_frame
			var now := Time.get_ticks_usec()
			print("FRAME clip=%.3f ms=%.1f" % [clips.current_animation_position, (now - last) / 1000.0])
			last = now
	elif scene == "emergence" or scene == "emergence-parts":
		if scene == "emergence-parts":
			_flatten(route.world())
		await route.walk_into_the_reveal()
		_mark("reveal")
		var clips: AnimationPlayer = route.world().get_node("Cinematics")
		for at in [1.5, 3.0, 4.3, 5.5, 7.0, 9.0]:
			await _traced(func() -> bool: return clips.current_animation_position >= at, 60 * 12)
			_mark("reveal-%.1fs" % at)
	else:
		await route.walk_into_the_reveal()
		_mark("reveal")
		var director: Node = route.director()
		var body: CharacterBody2D = route.player()
		await _traced(func() -> bool: return body.is_control_enabled() and not director.is_cinematic_active(), 60 * 30)
		_mark("escape")
		if scene == "escape-run":
			await route.walk(KEY_A, func() -> bool:
				_trace()
				return not body.is_control_enabled(), 60 * 40)
		else:
			await _traced(func() -> bool: return not body.is_control_enabled(), 60 * 40)
		_mark("collapse")
		var clips: AnimationPlayer = route.world().get_node("Cinematics")
		await _traced(func() -> bool: return not is_instance_valid(clips) or not clips.is_playing() or clips.current_animation_position >= 5.9, 60 * 10)
		_mark("collapse-end")
		await h.steps(15)
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	await h.steps(3)
	quit(0)
