extends SceneTree
## Records the Shore preview with scripted input through Movie Maker mode. Evidence, not a test.
## Run: godot --path project --write-movie <dir>/frame.png --fixed-fps 60 --resolution 480x270 --script res://tests/capture_preview.gd

const StepProbe := preload("res://tests/step_probe.gd")

var _probe: Node


func _initialize() -> void:
	_run()


func _steps(count: int) -> void:
	for i in count:
		await _probe.stepped


func _walk(action: String, player: CharacterBody2D, goal_x: float) -> void:
	Input.action_press(action)
	for i in 1200:
		await _probe.stepped
		var x := player.global_position.x
		if (action == "move_right" and x >= goal_x) or (action == "move_left" and x <= goal_x):
			break
	Input.action_release(action)


func _jump() -> void:
	Input.action_press("jump")
	await _steps(14)
	Input.action_release("jump")


func _run() -> void:
	var scene: Node = (load("res://scenes/preview/shore_preview.tscn") as PackedScene).instantiate()
	_probe = StepProbe.new()
	root.add_child(scene)
	root.add_child(_probe)
	var player: CharacterBody2D = scene.get_node("Player")

	await _steps(150)  # Idle beside the boat: breathing, and the sea moving.
	await _walk("move_left", player, 118.0)  # A few steps left, in front of the boat.
	await _steps(70)
	await _walk("move_right", player, 188.0)
	await _jump()  # Up onto the rock.
	await _walk("move_right", player, 250.0)
	await _walk("move_right", player, 560.0)  # Over the slope, scrolling the view.
	await _steps(80)
	await _walk("move_left", player, 262.0)
	await _steps(90)
	quit(0)
