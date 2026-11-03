extends SceneTree
## One-off: the live state of the entry scene in whichever build runs this.
func _initialize() -> void:
	_run()
func _describe(n: Node, depth: int) -> void:
	var extra := ""
	if n is CollisionObject2D:
		extra += " layer=%d mask=%d" % [n.collision_layer, n.collision_mask]
	if n is Area2D:
		extra += " monitoring=%s monitorable=%s overlaps=%d" % [n.monitoring, n.monitorable, n.get_overlapping_areas().size()]
	if n is CollisionShape2D:
		extra += " shape=%s disabled=%s" % [n.shape, n.disabled]
	if n is Node2D:
		extra += " pos=%s" % n.global_position
	print("  ".repeat(depth), n.name, " <", n.get_class(), ">", extra)
	for c in n.get_children():
		_describe(c, depth + 1)
func _run() -> void:
	var pack := OS.get_environment("INSPECT_PACK")
	if pack != "":
		print("mounted ", pack, ": ", ProjectSettings.load_resource_pack(pack, true))
	var scene: Node = (load("res://scenes/level/shore.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for i in 30:
		await physics_frame
	print("--- player subtree"); _describe(scene.get_node("Player"), 0)
	print("--- props"); if scene.has_node("Props"): _describe(scene.get_node("Props"), 0)
	else: print("NO Props NODE")
	print("--- hud"); _describe(scene.get_node("Hud"), 0)
	var i: Node = scene.get_node_or_null("Player/Interactor")
	print("interactor: ", i)
	if i:
		print("focus: ", i.get_focus())
		print("focus_changed connections: ", i.focus_changed.get_connections())
		print("interacted connections: ", i.interacted.get_connections())
	var p: Label = scene.get_node("Hud/Prompt")
	print("prompt visible=", p.visible, " text='", p.text, "' rect=", p.get_global_rect())
	print("scene connections on Hud: ", scene.get_node("Hud").get_incoming_connections().size())
	quit(0)
