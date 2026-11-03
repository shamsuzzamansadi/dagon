extends SceneTree
## One-off: what does each packed scene really hold, before and after a re-pack, and in a mounted pack?
const SCENES := ["res://scenes/level/shore.tscn", "res://scenes/player/player.tscn", "res://scenes/player/sailor_player.tscn", "res://scenes/ui/hud.tscn", "res://scenes/ui/pause_menu.tscn", "res://scenes/ui/settings_menu.tscn"]
func _initialize() -> void:
	_run()
func _dump(ps: PackedScene) -> Array:
	var st := ps.get_state()
	var lines := []
	for i in st.get_node_count():
		var props := []
		for p in st.get_node_property_count(i):
			var v = st.get_node_property_value(i, p)
			props.append("%s=%s" % [st.get_node_property_name(i, p), ("<res>" if v is Resource else str(v))])
		props.sort()
		lines.append("node %s %s %s" % [st.get_node_path(i), st.get_node_type(i), ",".join(props)])
	for c in st.get_connection_count():
		lines.append("conn %s.%s -> %s.%s binds=%s" % [st.get_connection_source(c), st.get_connection_signal(c), st.get_connection_target(c), st.get_connection_method(c), st.get_connection_binds(c)])
	lines.sort()
	return lines
func _run() -> void:
	var source := {}
	for path in SCENES:
		source[path] = _dump(load(path))
	var pack := OS.get_environment("INSPECT_PACK")
	print("== connections per scene, as written")
	for path in SCENES:
		var ps: PackedScene = load(path)
		print("  ", path.get_file(), ": ", ps.get_state().get_connection_count())
	print("== re-packing the source scene the way a save or export does")
	var ps: PackedScene = load("res://scenes/level/shore.tscn")
	var node := ps.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var again := PackedScene.new()
	print("  pack result: ", again.pack(node))
	print("  shore.tscn connections before: ", ps.get_state().get_connection_count(), ", after: ", again.get_state().get_connection_count())
	print("== the same re-pack, with the Player instance marked editable")
	node.set_editable_instance(node.get_node("Player"), true)
	var editable := PackedScene.new()
	editable.pack(node)
	print("  connections: ", editable.get_state().get_connection_count())
	node.free()
	if pack != "":
		print("== mounted: ", pack, " ", ProjectSettings.load_resource_pack(pack, true))
		for path in SCENES:
			var exported: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			var lines := _dump(exported)
			var missing := []
			var added := []
			for l in source[path]:
				if not l in lines: missing.append(l)
			for l in lines:
				if not l in source[path]: added.append(l)
			print("  ", path.get_file(), ": exported connections=", exported.get_state().get_connection_count(), " only in source=", missing.size(), " only in export=", added.size())
			for l in missing: print("     - ", l.substr(0, 170))
			for l in added: print("     + ", l.substr(0, 170))
	quit(0)
