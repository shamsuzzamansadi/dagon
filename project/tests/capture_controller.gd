extends SceneTree
## Records the Examine prompt, the controls screens and the introduction for one controller name, through
## Movie Maker mode. Evidence, not a test. The name stands in for a device: these are not physical-device images.
## DAGON_TEST_CONTROLLER=<name, or empty> DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --write-movie <dir>/frame.png --fixed-fps 60 --resolution 480x270 --script res://tests/capture_controller.gd

const StepProbe := preload("res://tests/step_probe.gd")

var _probe: Node
var _use_pad := false


func _initialize() -> void:
	_run()


func _steps(count: int) -> void:
	for i in count:
		await _probe.stepped


func _mark(what: String) -> void:
	await _steps(4)
	print("CAPTURE %d %s" % [Engine.get_frames_drawn(), what])
	await _steps(4)


func _press(button: JoyButton, key: Key) -> void:
	for pressed in [true, false]:
		var event: InputEvent
		if _use_pad:
			event = InputEventJoypadButton.new()
			event.button_index = button
		else:
			event = InputEventKey.new()
			event.physical_keycode = key
			event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _steps(2)


func _run() -> void:
	_use_pad = not OS.get_environment("DAGON_TEST_CONTROLLER").is_empty()
	var title: Node = (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	_probe = StepProbe.new()
	root.add_child(title)
	current_scene = title
	root.add_child(_probe)
	await _steps(10)
	await _mark("main menu")

	# Only so the screens below describe this device.
	await _press(JOY_BUTTON_Y, KEY_T)
	title.open_controls()
	await _mark("controls from the main menu")
	await _press(JOY_BUTTON_B, KEY_ESCAPE)

	title.new_game()
	while not (is_instance_valid(current_scene) and current_scene.is_class("GameSession") and current_scene.is_node_ready()):
		await _steps(1)
	var session: Node = current_scene
	await _steps(10)
	await _mark("introduction")
	await _press(JOY_BUTTON_A, KEY_ENTER)
	await _steps(30)
	await _mark("prompt beside the boat")
	await _press(JOY_BUTTON_X, KEY_E)
	await _steps(20)
	await _mark("caption")
	await _press(JOY_BUTTON_START, KEY_ESCAPE)
	await _steps(4)
	session.get_node("PauseLayer/PauseMenu").open_controls()
	await _mark("controls from the pause menu")
	quit(0)
