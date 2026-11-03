extends SceneTree
## Subprocess for test_quit_on_the_main_menu_exits_the_game.


func _initialize() -> void:
	_run()


func _run() -> void:
	var title: Node = (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await physics_frame
	print("PROBE quitting")
	title.quit_now()
	for i in 60:
		await process_frame
	print("PROBE still running")
	quit(3)
