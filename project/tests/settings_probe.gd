extends SceneTree
## Subprocess for test_settings_survive_a_relaunch: prints what a fresh process loads from the same directory.


func _initialize() -> void:
	_run()


func _run() -> void:
	var scene: Node = (load("res://scenes/level/shore.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await physics_frame
	var keys := []
	for event in InputMap.action_get_events("jump"):
		if event is InputEventKey:
			keys.append(event.physical_keycode)
	print("PROBE jump_keys=%s music_db=%.2f" % [str(keys), AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))])
	quit(0)
