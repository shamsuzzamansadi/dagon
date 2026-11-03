extends SceneTree
## Records the M2 interaction and menus with scripted input through Movie Maker mode. Evidence, not a test.
## Run with a throwaway storage directory, because this changes settings:
## DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --write-movie <dir>/frame.png --fixed-fps 60 --resolution 480x270 --script res://tests/capture_m2.gd

const StepProbe := preload("res://tests/step_probe.gd")

var _probe: Node


func _initialize() -> void:
	_run()


func _steps(count: int) -> void:
	for i in count:
		await _probe.stepped


func _mark(what: String) -> void:
	print("CAPTURE %d %s" % [Engine.get_frames_drawn(), what])


func _send_key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _steps(2)


func _send_action(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _steps(2)


func _run() -> void:
	var scene: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	_probe = StepProbe.new()
	root.add_child(scene)
	root.add_child(_probe)

	await _steps(60)
	_mark("prompt beside the boat")
	await _steps(30)
	await _send_action("interact")
	await _steps(40)
	_mark("caption")
	await _steps(30)

	await _send_key(KEY_ESCAPE)
	await _steps(10)
	_mark("pause menu")
	await _steps(30)

	await _send_action("ui_down")
	await _send_action("ui_down")
	await _send_action("ui_accept")
	await _steps(10)
	_mark("settings")
	await _steps(30)

	var settings: Control = scene.get_node("PauseLayer/PauseMenu/Settings")
	settings.begin_capture(3)
	await _steps(10)
	_mark("capturing a key")
	await _steps(30)
	await _send_key(KEY_LEFT)
	await _steps(10)
	_mark("reserved key refused")
	await _steps(30)
	await _send_key(KEY_SPACE)
	await _steps(10)
	_mark("conflict")
	await _steps(30)
	await _send_key(KEY_ESCAPE)
	await _steps(5)
	await _send_key(KEY_ESCAPE)
	await _steps(5)

	await _send_action("ui_down")
	await _send_action("ui_accept")
	await _steps(10)
	_mark("quit confirmation")
	await _steps(30)
	await _send_key(KEY_ESCAPE)
	await _steps(5)
	await _send_key(KEY_ESCAPE)
	await _steps(30)
	_mark("resumed")
	await _steps(10)
	quit(0)
