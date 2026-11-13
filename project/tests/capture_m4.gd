extends SceneTree
## Saves a screen from each stretch of the route past the reference section, in the order a player meets them, at the
## game's own scale. Evidence for M4's environment art, not a test. Needs a real window, so on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 \
##     --script res://tests/capture_m4.gd -- <output dir> [text]
## With text, only the spots whose name contains it. Each spot: name, the beat the world is built at, where he stands.

const ABYSS := 1
const MONOLITH := 2
const AWAKENED := 3
const SPOTS := [
	["a1-where-the-reference-section-ends", ABYSS, 1440.0, -40.0],
	["a2-onto-the-open-seabed", ABYSS, 1600.0, -40.0],
	["a3-toward-the-ribs", ABYSS, 1740.0, -40.0],
	["b1-under-the-rib-arch", ABYSS, 1880.0, -40.0],
	["b2-the-skull-and-the-carving", ABYSS, 1990.0, -40.0],
	["c1-the-ledges-and-the-stone", ABYSS, 2080.0, -40.0],
	["c2-on-the-shelf-by-the-stone", ABYSS, 2110.0, -70.0],
	["c3-the-gap-and-the-raised-slab", ABYSS, 2200.0, 30.0],
	["c4-the-slab-down", MONOLITH, 2220.0, -40.0],
	["c5-past-the-gap", MONOLITH, 2400.0, -40.0],
	["d1-the-footprint", ABYSS, 2600.0, -40.0],
	["d2-the-first-shelf-from-below", ABYSS, 2850.0, -6.0],
	["d3-on-the-first-shelf", ABYSS, 2940.0, -60.0],
	["d4-between-the-shelves", ABYSS, 3200.0, -40.0],
	["d5-the-second-shelf-from-below", ABYSS, 3400.0, -6.0],
	["d6-on-the-second-shelf", ABYSS, 3480.0, -60.0],
	["e1-the-canyon-opens", MONOLITH, 3640.0, -40.0],
	["e2-the-mural", MONOLITH, 3898.0, -40.0],
	["e3-the-stones", MONOLITH, 4080.0, -40.0],
	["e4-the-gate", MONOLITH, 4240.0, -40.0],
	["f1-the-mural-lit", AWAKENED, 3898.0, -40.0],
	["f2-the-stones-lit", AWAKENED, 4080.0, -40.0],
	["f3-through-the-gate", AWAKENED, 4330.0, -40.0],
]


func _initialize() -> void:
	_run()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var only: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	var beat := -1
	var session: Node = null
	for spot in SPOTS:
		if not only.is_empty() and not String(spot[0]).contains(only):
			continue
		if spot[1] != beat:
			if session != null:
				session.queue_free()
				await _frames(3)
			beat = spot[1]
			session = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
			session.set_start(beat, true, false)
			root.add_child(session)
			await _frames(5)
			# What only passes by is kept out of a picture of the place.
			for path in session.get_director().background_triggers:
				session.get_director().get_node(path).enabled = false
		var player: Node2D = session.get_world().get_node("Player")
		player.teleport(Vector2(spot[2], spot[3]))
		await _frames(80)
		root.get_texture().get_image().save_png(out.path_join(String(spot[0]) + ".png"))
		print("CAPTURE %s" % spot[0])
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
