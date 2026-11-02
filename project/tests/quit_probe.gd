extends SceneTree
## Subprocess for test_quit_to_desktop_exits_the_game: quitting really has to end the process.


func _initialize() -> void:
	_run()


func _run() -> void:
	var scene: Node = (load("res://scenes/level/shore.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await physics_frame
	var menu: Control = scene.get_node("PauseLayer/PauseMenu")
	menu.open()
	await physics_frame
	print("PROBE confirm_quit called")
	menu.confirm_quit()
	for i in 60:
		await process_frame
	print("PROBE still running")
	quit(3)
