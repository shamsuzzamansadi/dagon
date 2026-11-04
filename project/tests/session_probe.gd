extends SceneTree
## Subprocess for the quit, relaunch and Continue tests. A new process has nothing in memory, so only the
## file on disk can carry progress across. Start with "-- new_game" or "-- continue", then one instruction:
## cross_the_trigger, advance_to=<beat>, report_world, enter_reveal or play_to_ending.

const STONES := [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]
const WITNESS_X := 4420.0
const COLLAPSE_X := 3760.0


func _initialize() -> void:
	_run()


func _wait_for_session() -> Node:
	for i in 120:
		await physics_frame
		if is_instance_valid(current_scene) and current_scene.is_class("GameSession") and current_scene.is_node_ready():
			return current_scene
	return null


func _physics(count: int) -> void:
	for i in count:
		await physics_frame


func _wait_for(condition: Callable, frames: int) -> bool:
	for i in frames:
		if condition.call():
			return true
		await physics_frame
	return condition.call()


func _stand_at(player: Node2D, x: float) -> void:
	player.teleport(Vector2(x, -2))
	await _physics(40)


## Walks the story to a beat through its real triggers, stones and clips.
func _advance(session: Node, target: int) -> void:
	var world: Node = session.get_world()
	var player: Node2D = world.get_node("Player")
	var director: Node = session.get_director()
	if director.get_beat() < 1 and target >= 1:
		await _stand_at(player, world.get_node("Triggers/EnterAbyss").global_position.x)
	if director.get_beat() < 2 and target >= 2:
		await _stand_at(player, world.get_node("Triggers/ReachMonolith").global_position.x)
	if director.get_beat() < 3 and target >= 3:
		for id in STONES:
			world.get_node("Monolith/Puzzle").submit(id)
		await _wait_for(func() -> bool: return not director.is_cinematic_active(), 800)
		await _physics(4)
	print("PROBE reached beat=%d persisted=%d" % [session.get_session_beat(), session.get_persisted_beat()])


func _report_world(session: Node) -> void:
	var world: Node = session.get_world()
	var director: Node = session.get_director()
	var player: CharacterBody2D = world.get_node("Player")
	await _physics(40)
	var lit := 0
	for stone_name in ["GlyphWave", "GlyphKneel", "GlyphEye"]:
		if world.get_node("Monolith/%s/Lit" % stone_name).visible:
			lit += 1
	var mural: String = "after" if world.get_node("Monolith/Mural").caption.contains("swimmer") else "before"
	print("PROBE world beat=%d x=%.0f spent=%s,%s armed=%s,%s solved=%s lit=%d gate=%d mural=%s clip='%s' on_floor=%s control=%s" % [
		director.get_beat(), player.global_position.x,
		not world.get_node("Triggers/EnterAbyss").enabled, not world.get_node("Triggers/ReachMonolith").enabled,
		world.get_node("Triggers/Witness").enabled, world.get_node("Triggers/Collapse").enabled,
		world.get_node("Monolith/Puzzle").is_solved(), lit, world.get_node("Monolith/Gate").collision_layer, mural,
		world.get_node("Cinematics").assigned_animation, player.is_on_floor(), player.is_control_enabled(),
	])


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

	var instruction: String = args[1] if args.size() > 1 else ""
	if instruction == "cross_the_trigger":
		player.teleport(Vector2(735, -2))
		for i in 40:
			await physics_frame
		print("PROBE crossed beat=%d persisted=%d" % [session.get_session_beat(), session.get_persisted_beat()])
	elif instruction.begins_with("advance_to="):
		await _advance(session, int(instruction.get_slice("=", 1)))
	elif instruction == "report_world":
		await _report_world(session)
	elif instruction == "enter_reveal":
		player.teleport(Vector2(WITNESS_X, -2))
		await _physics(30)
		print("PROBE in the reveal beat=%d" % session.get_director().get_beat())
	elif instruction == "play_to_ending":
		var director: Node = session.get_director()
		player.teleport(Vector2(WITNESS_X, -2))
		await _wait_for(func() -> bool: return director.get_beat() == 5, 1000)
		player.teleport(Vector2(COLLAPSE_X, -2))
		await _wait_for(func() -> bool: return is_instance_valid(current_scene) and current_scene.has_method("open_credits") and current_scene.get_node_or_null("Center/Card") != null, 400)
		print("PROBE ending reached" if current_scene.get_node_or_null("Center/Card") != null else "PROBE no ending")
	quit(0)
