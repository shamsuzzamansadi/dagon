extends SceneTree
## Subprocess for the quit, relaunch and Continue tests. A new process has nothing in memory, so only the
## file on disk can carry progress across. Start with "-- new_game" or "-- continue".


func _initialize() -> void:
	_run()


func _wait_for_session() -> Node:
	for i in 120:
		await physics_frame
		if is_instance_valid(current_scene) and current_scene.is_class("GameSession") and current_scene.is_node_ready():
			return current_scene
	return null


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var title: Node = (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	await physics_frame
	var status: Label = title.get_node("Center/Main/Panel/Items/SaveStatus")
	print("PROBE status='%s' continue_disabled=%s" % [status.text, title.get_node("Center/Main/Panel/Items/Continue").disabled])

	if args[0] == "new_game":
		title.new_game()
	else:
		title.continue_game()
	var session := await _wait_for_session()
	if session == null:
		print("PROBE no session")
		quit(1)
		return
	session.get_node("PauseLayer/PauseMenu").resume()
	var player: Node2D = session.get_world().get_node("Player")
	for i in 30:
		await physics_frame
	print("PROBE started beat=%d x=%.0f" % [session.get_session_beat(), player.global_position.x])

	if args.size() > 1 and args[1] == "cross_the_trigger":
		player.teleport(Vector2(735, -2))
		for i in 40:
			await physics_frame
		print("PROBE crossed beat=%d persisted=%d" % [session.get_session_beat(), session.get_persisted_beat()])
	quit(0)
