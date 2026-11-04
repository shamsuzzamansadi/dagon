extends SceneTree
## Saves a screen from each stretch of the greybox walk. Evidence, not a test. Needs a real window, so run it on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 --script res://tests/capture_m3.gd -- <output dir>

const SPOTS := [
	["act2-trench-and-steps", 860.0],
	["act2-fossil", 1130.0],
	["act2-first-tablet", 1320.0],
	["act2-mound", 1500.0],
	["act2-rib-arch", 1880.0],
	["act2-crevasse", 2120.0],
	["act2-second-tablet", 2380.0],
	["act2-footprint", 2600.0],
	["act2-steps-up", 2740.0],
	["act2-plateau", 2900.0],
	["act2-third-tablet", 3240.0],
	["act3-canyon", 3560.0],
	["act3-mural-before", 3898.0],
	["act3-gate-closed", 4230.0],
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
		player.teleport(Vector2(spot[1], -40))
		await _frames(70)
		get_root().get_texture().get_image().save_png(out.path_join(spot[0] + ".png"))
		print("CAPTURE %s x=%.0f" % [spot[0], player.global_position.x])
	quit(0)
