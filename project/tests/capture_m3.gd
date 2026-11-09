extends SceneTree
## Saves a screen from each stretch of the walk, each timed scene, and each picture of the prologue and the epilogue. Evidence, not a test. Needs a real window, so run it on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 --script res://tests/capture_m3.gd -- <output dir>

const SPOTS := [
	["shore-talisman", 330.0, -40.0],
	["shore-remains", 400.0, -40.0],
	["shore-tentacle", 560.0, -40.0],
	["section-1-cave-entrance", 680.0, -40.0],
	["section-2-cave-carving", 830.0, -40.0],
	["section-3-the-mouth", 990.0, -40.0],
	["section-4-out-on-the-seabed", 1130.0, -40.0],
	["section-5-first-tablet", 1320.0, -40.0],
	["section-6-where-the-greybox-begins", 1440.0, -40.0],
	["act2-the-slab-raised", 2160.0, -40.0],
	["act2-rib-arch", 1880.0, -40.0],
	["act2-crevasse", 2120.0, -40.0],
	["act2-crossing-clue", 2060.0, -40.0],
	["act2-shelf-from-below", 2908.0, -6.0],
	["act2-shelf-from-above", 2940.0, -60.0],
	["act2-second-tablet-in-the-recess", 2848.0, -6.0],
	["act3-third-tablet-seen-from-below", 3360.0, -6.0],
	["act3-third-tablet-on-the-shelf", 3470.0, -60.0],
	["act3-shelf-statue", 3490.0, -60.0],
	["act3-monolith-approach", 3640.0, -40.0],
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
	["mural-lit", "Cinematics", &"monolith_awaken", 6.0, Vector2(3898, -2)],
	["reveal-1-stillness", "Cinematics", &"dagon_reveal", 1.5, Vector2(4420, -2)],
	["reveal-2-splash", "Cinematics", &"dagon_reveal", 3.4, Vector2(4420, -2)],
	["reveal-2-rising", "Cinematics", &"dagon_reveal", 5.0, Vector2(4420, -2)],
	["reveal-3-hand-comes-down", "Cinematics", &"dagon_reveal", 7.2, Vector2(4420, -2)],
	["reveal-4-eye-opens", "Cinematics", &"dagon_reveal", 10.0, Vector2(4420, -2)],
	["reveal-5-head-turns", "Cinematics", &"dagon_reveal", 12.4, Vector2(4420, -2)],
	["flee-1-rock-coming-down", "Atmosphere", &"beat_fleeing", 0.65, Vector2(4364, -2)],
	["flee-2-rock-across-the-way", "Atmosphere", &"beat_fleeing", 2.8, Vector2(4240, -2)],
	["flee-3-the-last-rock", "Atmosphere", &"beat_fleeing", 5.6, Vector2(3990, -2)],
	["flee-4-the-sea-coming", "Atmosphere", &"beat_fleeing", 4.0, Vector2(4330, -2)],
	["collapse-1-falling", "Cinematics", &"collapse", 1.0, Vector2(3760, -2)],
	["collapse-2-lying-still", "Cinematics", &"collapse", 2.4, Vector2(3760, -2)],
	["collapse-3-the-sea-comes", "Cinematics", &"collapse", 3.6, Vector2(3760, -2)],
	["collapse-4-the-sea-over-him", "Cinematics", &"collapse", 4.5, Vector2(3760, -2)],
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
	# The prologue and the epilogue: one picture for each line, as Continue moves it on.
	session.queue_free()
	await _frames(3)
	for pair in [["prologue", "res://scenes/ui/prologue.tscn"], ["ending", "res://scenes/ui/ending.tscn"]]:
		var sequence: Node = (load(pair[1]) as PackedScene).instantiate()
		root.add_child(sequence)
		for line in sequence.ending_lines.size():
			await _frames(90)
			_save(out, "%s-%d" % [pair[0], line + 1])
			if line + 1 < sequence.ending_lines.size():
				sequence.advance_ending()
		for sound in sequence.find_children("*", "AudioStreamPlayer", true, false):
			sound.stop()
		sequence.queue_free()
		await _frames(3)
	# As the game does: stop every sound, and give the mixer real time to let go of it before quitting.
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)


func _show_as_it_would_be(world: Node, still: Array) -> void:
	var clip := String(still[2])
	if clip == "dagon_reveal" or clip == "collapse" or clip == "monolith_awaken" or clip == "beat_fleeing":
		world.get_node("Monolith/Gate").hide()
	if clip == "beat_fleeing":
		world.get_node("Rockfall").show()
		world.get_node("Rockfall").set_deferred("collision_layer", 1)
		# The sea's place is the director's to set, by its rule. Shown here where the rule has it at this moment.
		var director: Node = world.get_node("GameDirector")
		var tide: Node2D = world.get_node("Tide")
		tide.show()
		tide.global_position.x = director.tide_start_x - director.tide_speed * maxf(0.0, still[3] - director.tide_delay)


func _save(out: String, shot: String) -> void:
	get_root().get_texture().get_image().save_png(out.path_join(shot + ".png"))
	print("CAPTURE %s" % shot)
