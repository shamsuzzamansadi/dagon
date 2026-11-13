extends RefCounted
## M4: the way from the prologue's last picture into the game. A new game opens on the sailor getting up beside his
## boat, under the cinematic contract, with nothing between the picture and the game. Continue and Restart never show
## it. These prove what the game does and when. They cannot show that the cut cannot be seen: that takes a recording.

const WORLD := "res://scenes/level/shore.tscn"
const GAME := "res://scenes/level/game.tscn"
const TITLE := "res://scenes/ui/title.tscn"
const PROLOGUE := "res://scenes/ui/prologue.tscn"
const SAVE_FILE := "save.dat"
const SHORE_SAVE := "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n"
const WAKE := &"shore_wake"
const SHORE := 0
const ABYSS := 1


func _new_game(h) -> Node:
	await h.load_main_fixture(TITLE)
	await h.steps(3)
	await h.tap_key(KEY_ENTER)
	return await h.wait_for_scene("GameSession")


func _session(h, beat: int, waking: bool) -> Node:
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(beat, true, false)
	session.set_waking(waking)
	await h.load_with(session, true)
	return session


func _player(session: Node) -> CharacterBody2D:
	return session.get_world().get_node("Player")


func _sprite(session: Node) -> AnimatedSprite2D:
	return _player(session).get_node("Visual/Sailor")


## ---- A new game ----


func test_a_new_game_opens_on_him_getting_up_and_then_the_game_is_his(h) -> void:
	var session := await _new_game(h)
	var director: Node = session.get_director()
	var player := _player(session)
	var sprite := _sprite(session)
	h.check(director.get_beat() == SHORE, "the new game is at beat %d" % director.get_beat())
	h.check(director.is_cinematic_active(), "no cinematic as the game opens")
	h.check(not session.is_waking(), "the waking is still asked for after it has begun")
	h.check(session.get_world().get_node("Cinematics").current_animation == WAKE, "the clip playing is '%s'" % session.get_world().get_node("Cinematics").current_animation)
	h.check(not player.is_control_enabled(), "he can be walked before he is up")
	h.check(sprite.animation == &"wake" and sprite.frame == 0, "he is shown as %s, frame %d, as the game opens" % [sprite.animation, sprite.frame])
	h.check(not h.tree.paused and not session.get_node("PauseLayer/PauseMenu").is_open(), "something is over the game")
	var start: Vector2 = player.global_position
	# Keys held while he gets up do nothing, and are not saved up either.
	h.send(h.key_event(KEY_D, true))
	await h.tap_key(KEY_SPACE)
	await h.steps(30)
	h.check(player.global_position.distance_to(start) < 3.0, "he moved while getting up: %s" % player.global_position)
	h.check(not session.get_world().get_node("Hud/Prompt").visible, "a prompt shows while he cannot act")
	h.send(h.key_event(KEY_D, false))
	var clip: Animation = session.get_world().get_node("Cinematics").get_animation(WAKE)
	var steps := 0
	while not player.is_control_enabled() and steps < 600:
		await h.steps(1)
		steps += 1
	h.check(player.is_control_enabled(), "control never came")
	h.check(steps <= int(clip.length * 60.0) + 10, "control took %d steps for a clip of %.1f s" % [steps, clip.length])
	h.check(clip.length <= 3.0, "getting up takes %.1f s, which is a wait" % clip.length)
	await h.steps(3)
	h.check(not director.is_cinematic_active(), "the cinematic is still active")
	h.check(player.get_shown_pose() == &"" and sprite.animation == &"idle", "he is still shown as %s" % sprite.animation)
	h.check(player.global_position.distance_to(start) < 3.0, "he ended at %s" % player.global_position)
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "getting up changed the save: %s" % h.read_storage_file(SAVE_FILE))
	h.check(session.get_session_beat() == SHORE and session.get_persisted_beat() == SHORE, "the checkpoint moved")
	# And now the keys work.
	h.send(h.key_event(KEY_D, true))
	await h.steps(30)
	h.send(h.key_event(KEY_D, false))
	h.check(player.global_position.x > start.x + 10.0, "he cannot walk once he is up")
	h.check(sprite.animation == &"walk" or sprite.animation == &"idle", "walking shows %s" % sprite.animation)


func test_the_waking_frames_end_on_him_standing_within_the_clip(h) -> void:
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	var frames: SpriteFrames = world.get_node("Player/Visual/Sailor").sprite_frames
	h.check(frames.has_animation(&"wake") and not frames.get_animation_loop(&"wake"), "the waking animation is missing, or loops")
	var seconds := frames.get_frame_count(&"wake") / frames.get_animation_speed(&"wake")
	var clip: Animation = world.get_node("Cinematics").get_animation(WAKE)
	h.check(clip != null and clip.loop_mode == Animation.LOOP_NONE, "the clip is missing, or loops")
	h.check(seconds <= clip.length and clip.length - seconds < 0.6, "the frames take %.2f s and the clip %.2f s" % [seconds, clip.length])
	var last: AtlasTexture = frames.get_frame_texture(&"wake", frames.get_frame_count(&"wake") - 1)
	var idle: AtlasTexture = frames.get_frame_texture(&"idle", 0)
	# Pixel by pixel where he is drawn: the import gives transparent pixels the colour of their neighbours.
	var sheet: Image = last.atlas.get_image()
	var differing := 0
	for y in int(last.region.size.y):
		for x in int(last.region.size.x):
			var up: Color = sheet.get_pixelv(Vector2i(last.region.position) + Vector2i(x, y))
			var standing: Color = sheet.get_pixelv(Vector2i(idle.region.position) + Vector2i(x, y))
			if up.a != standing.a or (up.a > 0.0 and up != standing):
				differing += 1
	h.check(differing == 0, "the last waking frame differs from him standing as he idles, in %d pixels" % differing)
	world.free()


## ---- Never again ----


func test_continue_and_restart_never_show_the_waking(h) -> void:
	h.write_storage_file(SAVE_FILE, SHORE_SAVE.to_utf8_buffer())
	var session := await _new_game(h)
	h.check(h.introductions_begun == 0 and h.prologues_skipped == 0, "Continue at the Shore showed the introduction or the prologue")
	await h.steps(3)
	h.check(not session.is_waking() and not session.get_director().is_cinematic_active(), "Continue at the Shore plays the waking")
	h.check(_player(session).is_control_enabled() and _sprite(session).animation != &"wake", "Continue at the Shore does not hand him over at once")
	await h.unload_fixture()
	# A new game, then Restart Checkpoint once he is up: the Shore again, on his feet.
	DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))
	session = await _new_game(h)
	await h.wait_for_control(_player(session))
	session.get_node("PauseLayer/PauseMenu").restart_checkpoint()
	await h.steps(3)
	h.check(not session.get_director().is_cinematic_active() and _player(session).is_control_enabled(), "Restart plays the waking again")
	h.check(_sprite(session).animation != &"wake", "Restart shows him getting up")
	await h.unload_fixture()
	# Restart while he is still getting up: the rebuilt world owes nothing to the old one.
	DirAccess.remove_absolute(h.storage_dir.path_join(SAVE_FILE))
	session = await _new_game(h)
	await h.steps(20)
	h.check(session.get_director().is_cinematic_active(), "he was up already")
	session.get_node("PauseLayer/PauseMenu").restart_checkpoint()
	await h.steps(3)
	h.check(not session.get_director().is_cinematic_active() and _player(session).is_control_enabled(), "Restart during the waking left control locked")
	h.check(_sprite(session).animation != &"wake", "Restart during the waking left him on the ground")


func test_a_world_restored_at_a_later_beat_cannot_be_woken(h) -> void:
	var session := await _session(h, ABYSS, true)
	await h.steps(3)
	h.check(not session.get_director().is_cinematic_active(), "a world at the Abyss plays the waking")
	h.check(_player(session).is_control_enabled(), "control is locked at the Abyss")


## ---- The picture cannot hold the game ----


func test_pausing_holds_the_waking_and_resuming_finishes_it(h) -> void:
	var session := await _new_game(h)
	await h.steps(20)
	await h.tap_key(KEY_ESCAPE)
	h.check(h.tree.paused and session.get_node("PauseLayer/PauseMenu").is_open(), "Esc did not pause during the waking")
	var frame := _sprite(session).frame
	await h.steps(400)
	h.check(session.get_director().is_cinematic_active() and not _player(session).is_control_enabled(), "the waking ran on while paused")
	h.check(_sprite(session).frame == frame, "he went on getting up while paused")
	await h.tap_key(KEY_ESCAPE)
	await h.wait_for_control(_player(session))
	h.check(_player(session).is_control_enabled() and _sprite(session).animation != &"wake", "resuming did not finish the waking")


func test_with_no_clip_he_simply_stands_and_the_game_is_his(h) -> void:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	# In a copy of the library: the scene's own is shared by every world built after this one.
	var clips: AnimationPlayer = world.get_node("Cinematics")
	var library: AnimationLibrary = clips.get_animation_library(&"").duplicate()
	library.remove_animation(WAKE)
	clips.remove_animation_library(&"")
	clips.add_animation_library(&"", library)
	await h.load_with(world)
	var director: Node = world.get_node("GameDirector")
	var player: CharacterBody2D = world.get_node("Player")
	h.expect_error("cinematic clip 'shore_wake' is missing")
	director.wake()
	h.check(not director.is_cinematic_active() and player.is_control_enabled(), "a missing clip keeps control")
	h.check(player.get_shown_pose() == &"", "a missing clip leaves a pose behind, for the next cinematic to show")
	await h.steps(5)
	h.check(player.get_node("Visual/Sailor").animation != &"wake", "he is on the ground with no clip to raise him")


func test_a_clip_that_sticks_still_hands_him_over_standing(h) -> void:
	var session := await _new_game(h)
	var clips: AnimationPlayer = session.get_world().get_node("Cinematics")
	await h.steps(10)
	clips.pause()
	h.expect_error("cinematic 'shore_wake' passed its deadline")
	var steps := 0
	while not _player(session).is_control_enabled() and steps < 600:
		await h.steps(1)
		steps += 1
	h.check(_player(session).is_control_enabled(), "a stuck clip kept control for good")
	await h.steps(3)
	h.check(_player(session).get_shown_pose() == &"" and _sprite(session).animation == &"idle", "a stuck clip left him as %s" % _sprite(session).animation)


func test_a_pose_shows_only_while_control_is_locked_and_never_outlives_it(h) -> void:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	await h.load_with(world)
	var player: CharacterBody2D = world.get_node("Player")
	var sprite: AnimatedSprite2D = player.get_node("Visual/Sailor")
	await h.landed_on_floor(player)
	player.show_pose(&"wake")
	await h.steps(5)
	h.check(sprite.animation != &"wake", "a pose shows while the player has control")
	player.set_control_enabled(false)
	await h.steps(2)
	h.check(sprite.animation == &"wake", "a pose does not show with control locked")
	player.set_control_enabled(true)
	await h.steps(2)
	h.check(player.get_shown_pose() == &"" and sprite.animation == &"idle", "the pose outlived the lock")
	player.set_control_enabled(false)
	await h.steps(2)
	h.check(sprite.animation == &"idle", "an old pose came back with the next lock")
	player.show_pose(&"no_such_animation")
	await h.steps(2)
	h.check(sprite.animation == &"idle", "a pose with no frames changed what is shown")
	player.set_control_enabled(true)


## ---- The last picture ----


## The prologue's last picture is the Shore as the game opens on it, and its two pieces sit where the sailor is.
## project/tests/capture_opening.gd makes all three, and prints where the pieces go.
func test_the_last_picture_is_the_size_of_the_game_and_its_pieces_fit_it(h) -> void:
	var prologue: Node = (load(PROLOGUE) as PackedScene).instantiate()
	var panel: TextureRect = prologue.get_node("Panels/Dry")
	h.check(panel.texture.get_size() == Vector2(480, 270), "the last picture is %s" % panel.texture.get_size())
	var lying: TextureRect = panel.get_node("Lying")
	var sitting: TextureRect = panel.get_node("Sitting")
	for piece in [lying, sitting]:
		var rect := Rect2(piece.offset_left, piece.offset_top, piece.offset_right - piece.offset_left, piece.offset_bottom - piece.offset_top)
		h.check(rect.size == piece.texture.get_size(), "%s is drawn at %s from a piece of %s" % [piece.name, rect.size, piece.texture.get_size()])
		h.check(Rect2(0, 0, 480, 270).encloses(rect), "%s is off the picture: %s" % [piece.name, rect])
	h.check(lying.position == sitting.position, "the two pieces are in different places")
	# Where the sailor stands in the game's opening view, which the pieces must cover.
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	var start: Vector2 = world.get_node("Player").position
	world.free()
	var feet := Vector2(lying.offset_left + lying.texture.get_width() / 2.0, lying.offset_top + lying.texture.get_height() - 2.0)
	h.check(is_equal_approx(feet.x, start.x), "the pieces are centred on x=%.0f and he starts at x=%.0f, with the camera at its left limit" % [feet.x, start.x])
	prologue.free()


## The last line is spoken as he sits up, and the card is under him, not over him.
func test_the_last_line_leaves_him_in_view_and_sitting_before_it_ends(h) -> void:
	var prologue: Node = await h.load_main_fixture(PROLOGUE)
	for line in prologue.ending_lines.size() - 1:
		await h.steps(3)
		prologue.advance_ending()
	await h.steps(5)
	var panel: Node = prologue.get_node("Panels/Dry")
	h.check(panel.get_node("Lying").modulate.a > 0.9 and panel.get_node("Sitting").modulate.a < 0.1, "he is not asleep as the last line begins")
	var card: Rect2 = prologue.get_node("Card").get_global_rect()
	var figure: Rect2 = panel.get_node("Sitting").get_global_rect()
	h.check(card.position.y >= figure.end.y - 4.0, "the card, from y=%.0f, covers him, down to y=%.0f" % [card.position.y, figure.end.y])
	var stream: AudioStream = load("res://assets/narration/prologue.dry.ogg")
	await h.steps(int(stream.get_length() * 60.0) - 10)
	h.check(prologue.get_ending_line() == prologue.ending_lines.size() - 1, "the last line ended early")
	h.check(panel.get_node("Sitting").modulate.a > 0.9 and panel.get_node("Lying").modulate.a < 0.1, "he is not sitting up by the end of the line")
