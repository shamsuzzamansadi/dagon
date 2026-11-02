extends Node
## Test-only post-step observation point.
##
## SceneTree.physics_frame fires BEFORE node _physics_process callbacks, so
## awaiting it does not mean the player finished the step being measured. This
## node has a process priority higher than every gameplay node, so stepped is
## emitted after the player's move_and_slide() in the same tick.
## test_movement.gd::test_probe_observes_after_player_step proves that ordering.

## The same is true of SceneTree.process_frame and _process, so processed marks the end of a
## rendered frame's processing, after the camera has moved.

signal stepped(physics_frame: int)
signal processed

func _init() -> void:
	process_physics_priority = 1000
	process_priority = 1000
	# Tests of the pause menu keep stepping while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	stepped.emit(Engine.get_physics_frames())


func _process(_delta: float) -> void:
	processed.emit()
