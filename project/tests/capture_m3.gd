extends SceneTree
## Saves a screen from each stretch of the greybox walk. Evidence, not a test. Needs a real window, so run it on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 --script res://tests/capture_m3.gd -- <output dir>

const SPOTS := [
	["shore-talisman", 330.0, -40.0],
	["cave-mouth", 700.0, -40.0],
	["cave-carving", 830.0, -40.0],
	["act2-first-tablet", 1320.0, -40.0],
	["act2-rib-arch", 1880.0, -40.0],
	["act2-crevasse", 2120.0, -40.0],
	["act2-shelf-from-below", 2908.0, -6.0],
	["act2-shelf-from-above", 2940.0, -60.0],
	["act2-third-tablet", 3240.0, -40.0],
	["act3-shelf-statue", 3490.0, -60.0],
	["act3-mural-before", 3898.0, -40.0],
	["act3-stones-and-statues", 4060.0, -40.0],
	["act3-gate-closed", 4230.0, -40.0],
]

## The moments of each timed scene, reached by seeking its clip. Stills, to judge staging: timing needs the clip itself.
const STILLS := [
	["ritual-1-figures-kneel", "Background", &"ritual_tableau", 3.5, Vector2(1030, -2)],
	["ritual-2-watcher-moves", "Background", &"ritual_tableau", 7.5, Vector2(1030, -2)],
	["watcher-on-the-ridge", "Background", &"watcher_ridge", 1.5, Vector2(2900, -38)],
	["canyon-figure", "Background", &"canyon_figure", 1.0, Vector2(3500, -2)],
	["awaken-1-response", "Cinematics", &"monolith_awaken", 2.0, Vector2(4080, -2)],
	["awaken-2-stillness", "Cinematics", &"monolith_awaken", 4.5, Vector2(4080, -2)],
	["reveal-1-stillness", "Cinematics", &"dagon_reveal", 1.5, Vector2(4420, -2)],
	["reveal-2-rising", "Cinematics", &"dagon_reveal", 5.0, Vector2(4420, -2)],
	["reveal-3-hand-comes-down", "Cinematics", &"dagon_reveal", 7.2, Vector2(4420, -2)],
	["reveal-4-eye-opens", "Cinematics", &"dagon_reveal", 10.0, Vector2(4420, -2)],
	["reveal-5-head-turns", "Cinematics", &"dagon_reveal", 12.4, Vector2(4420, -2)],
	["collapse-1-falling", "Cinematics", &"collapse", 1.0, Vector2(3760, -2)],
	["collapse-2-lying-still", "Cinematics", &"collapse", 2.6, Vector2(3760, -2)],
]


func _initialize() -> void:
	_run()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(1, true, false)
	root.add_child(session)
	await _frames(5)
	var player: Node2D = session.get_world().get_node("Player")
	for spot in SPOTS:
		player.teleport(Vector2(spot[1], spot[2]))
		await _frames(70)
		_save(out, spot[0])
	for still in STILLS:
		session.restart_checkpoint()
		await _frames(3)
		var world: Node = session.get_world()
		world.get_node("Dagon").position.y = 0.0
		for path in session.get_director().background_triggers:
			session.get_director().get_node(path).enabled = false
		player = world.get_node("Player")
		player.teleport(still[4])
		await _frames(40)
		_show_as_it_would_be(world, still)
		var clips: AnimationPlayer = world.get_node(still[1])
		clips.play(still[2])
		clips.seek(still[3], true)
		clips.pause()
		await _frames(30)
		_save(out, still[0])
	quit(0)


func _show_as_it_would_be(world: Node, still: Array) -> void:
	var clip := String(still[2])
	if clip == "dagon_reveal" or clip == "collapse" or clip == "monolith_awaken":
		world.get_node("Monolith/Gate").hide()


func _save(out: String, shot: String) -> void:
	get_root().get_texture().get_image().save_png(out.path_join(shot + ".png"))
	print("CAPTURE %s" % shot)
