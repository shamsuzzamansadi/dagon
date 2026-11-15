extends SceneTree
## Photographs the Shore as a new game opens on it, for the prologue's last picture, so that picture and the game's
## first frame are the same view and the cut between them cannot be seen. Not a test, and not evidence: it writes three
## of the game's own images. Run it again whenever the Shore's opening view or the sailor's waking frames change. Needs
## a real window, so on a private display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 1440x810 \
##     --script res://tests/capture_opening.gd -- project/assets/prologue
## prologue_4_dry.png is the view with nobody in it. prologue_4_lying.png and prologue_4_sitting.png are him alone, cut
## from the same small piece of it: asleep, and sitting up as the game finds him. It prints where that piece goes, which
## scenes/ui/prologue.tscn must agree with, and a test holds it to.

const PIECE := Vector2i(48, 40)


func _initialize() -> void:
	_run()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var session: Node = (load("res://scenes/level/game.tscn") as PackedScene).instantiate()
	session.set_start(0, true, false)
	root.add_child(session)
	await _frames(90)
	var world: Node = session.get_world()
	var player: Node2D = world.get_node("Player")
	var sprite: AnimatedSprite2D = player.get_node("Visual/Sailor")
	world.get_node("Hud").visible = false
	player.set_control_enabled(false)
	# The moonlight on the water moves. Held on one frame, so the three photographs agree.
	var glints: AnimatedSprite2D = world.get_node("MoonPath/Glints")
	glints.pause()
	glints.frame = 0
	var at := Vector2i(player.get_global_transform_with_canvas().origin.round()) - Vector2i(PIECE.x / 2, PIECE.y - 2)
	sprite.visible = false
	await _frames(5)
	var empty: Image = root.get_texture().get_image()
	empty.save_png(out.path_join("prologue_4_dry.png"))
	sprite.visible = true
	for pair in [["sleep", "prologue_4_lying.png"], ["wake", "prologue_4_sitting.png"]]:
		player.show_pose(pair[0])
		sprite.pause()
		sprite.frame = 0
		await _frames(5)
		# Only him: whatever is the same as the empty view is left clear, so nothing doubles as the picture fades in.
		var piece: Image = root.get_texture().get_image().get_region(Rect2i(at, PIECE))
		piece.convert(Image.FORMAT_RGBA8)
		for y in PIECE.y:
			for x in PIECE.x:
				if piece.get_pixel(x, y).is_equal_approx(empty.get_pixelv(at + Vector2i(x, y))):
					piece.set_pixel(x, y, Color(0, 0, 0, 0))
		piece.save_png(out.path_join(pair[1]))
	print("OPENING piece at=%d,%d size=%d,%d view=%s" % [at.x, at.y, PIECE.x, PIECE.y, root.get_texture().get_size()])
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
