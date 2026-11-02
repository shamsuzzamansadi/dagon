extends SceneTree
## Records the greybox development scene with scripted input through Movie Maker
## mode. This is evidence for reviewers, not a test, and it plays the same way every time.
## Run: godot --path project --write-movie <dir>/frame.png --fixed-fps 60 --resolution 480x270 --script res://tests/capture_demo.gd

const StepProbe := preload("res://tests/step_probe.gd")
const SECONDS := 15


func _initialize() -> void:
	_run()


func _run() -> void:
	var level: Node = (load("res://scenes/level/level.tscn") as PackedScene).instantiate()
	var probe: Node = StepProbe.new()
	root.add_child(level)
	root.add_child(probe)
	var player: CharacterBody2D = level.get_node("Player")
	await probe.stepped
	Input.action_press("move_right")
	var last_x := player.global_position.x
	var stalled := 0
	for i in SECONDS * 60:
		await probe.stepped
		stalled = stalled + 1 if absf(player.global_position.x - last_x) < 0.2 else 0
		last_x = player.global_position.x
		if stalled >= 6 and player.is_on_floor():
			Input.action_press("jump")
			await create_timer(0.2, true, true).timeout
			Input.action_release("jump")
			stalled = 0
	quit(0)
