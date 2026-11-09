extends RefCounted
## The whole game, played from the main menu to the ending and back, by RoutePlayer. No teleports, no direct calls
## and no injected states. These also run on the exported pack, where a scene connection the export dropped shows.

const RoutePlayer := preload("res://tests/route_player.gd")
const TITLE := "res://scenes/ui/title.tscn"
const ITEMS := "Center/Main/Panel/Items/"
const SAVE_FILE := "save.dat"
const AWAKENED_SAVE := "dagon_save=1\nbeat=awakened\ncheckpoint=Awakened\n"
const SHORE_SAVE := "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n"
const ENDED := 6
const FLEE_FRAMES := 720
# The sea starts at x = 4540 after 2.5 s and comes on at 64 px/s: about 4.3 s to a sailor standing at the ledge.
const SEA_FRAMES := 270


func _title(h) -> Control:
	await h.load_main_fixture(TITLE)
	await h.steps(3)
	return h.fixture


func _focus(h) -> Control:
	return h.tree.root.get_viewport().gui_get_focus_owner()


func _ending_lines(ending: Node) -> Array:
	return ending.get_node("Center/Card/Items/Lines").get_children().map(func(line: Label) -> String: return line.text)


func _check_ending(h, ending: Node, what: String) -> void:
	h.check(ending.get_node_or_null("Center/Card") != null, "%s: the scene is %s" % [what, ending.name])
	h.check(ending.get_node("Center/Card").visible, "%s: the epilogue is not showing" % what)
	var lines := _ending_lines(ending)
	h.check(lines.size() >= 1 and lines[0].contains("the sea never left"), "%s: the epilogue starts '%s'" % [what, lines])
	h.check(_focus(h) == ending.get_node("Center/Card/Items/Continue"), "%s: focus is on %s" % [what, _focus(h)])
	h.check(not h.tree.paused, "%s: the ending is paused" % what)


## From the epilogue, with the keyboard, to the main menu: each press moves on, and nobody has to wait.
func _through_credits_to_main_menu(h, ending: Node) -> Control:
	var total: int = ending.ending_lines.size()
	for i in total:
		h.check(not ending.get_node("Center/Credits").visible, "the credits came after only %d presses" % i)
		await h.tap_key(KEY_ENTER)
	h.check(_ending_lines(ending).size() == total or ending.get_node("Center/Credits").visible, "some of the epilogue never showed")
	h.check(ending.get_node("Center/Credits").visible, "Continue did not show the credits")
	h.check(_focus(h) == ending.get_node("Center/Credits/Items/MainMenu"), "focus is on %s" % _focus(h))
	await h.tap_key(KEY_ENTER)
	return await h.wait_for_scene("MenuController")


## A game that starts fresh has nothing left from any earlier one.
func _check_clean_start(h, route, what: String) -> void:
	h.check(not h.tree.paused, "%s: paused" % what)
	h.check_near(Engine.time_scale, 1.0, 0.0, "%s: the time scale" % what)
	var director: Node = route.director()
	h.check(director.get_beat() == 0, "%s: at beat %d" % [what, director.get_beat()])
	h.check(not director.is_cinematic_active(), "%s: a cinematic is active" % what)
	h.check(not director.has_pending_event(), "%s: an event is pending" % what)
	h.check(not director.is_recovery_pending(), "%s: a recovery is pending" % what)
	h.check(route.player().is_control_enabled(), "%s: control is locked" % what)
	var world: Node = route.world()
	var camera: Camera2D = world.get_node("CameraRig")
	h.check(camera.get_target() == route.player(), "%s: the camera follows %s" % [what, camera.get_target()])
	h.check(camera.zoom == Vector2.ONE, "%s: zoom %s" % [what, camera.zoom])
	h.check(camera.limit_top == -220 and camera.limit_right == 4544, "%s: limits %d, %d" % [what, camera.limit_top, camera.limit_right])
	h.check(camera.offset == Vector2.ZERO and is_zero_approx(camera.get_trauma()), "%s: shake left over" % what)
	h.check(not world.get_node("Hud/Fade").visible or world.get_node("Hud/Fade").modulate.a < 1.0, "%s: the screen is black" % what)
	for trigger_name in ["EnterAbyss", "ReachMonolith", "Witness", "Collapse"]:
		h.check(world.get_node("Triggers/" + trigger_name).enabled, "%s: %s is spent" % [what, trigger_name])
	var puzzle: Node = world.get_node("Monolith/Puzzle")
	h.check(not puzzle.is_solved() and puzzle.get_progress() == 0, "%s: the puzzle kept progress" % what)
	h.check(world.get_node("Monolith/Gate").collision_layer != 0 and world.get_node("Monolith/Gate").visible, "%s: the gate is open" % what)
	h.check(world.get_node("Monolith/Mural").caption.contains("Ruins"), "%s: the mural reads '%s'" % [what, world.get_node("Monolith/Mural").caption])
	h.check(not world.get_node("Monolith/MuralLit").visible, "%s: the mural is lit" % what)
	h.check(world.get_node("Tint").color.is_equal_approx(Color.WHITE), "%s: the tint is %s" % [what, world.get_node("Tint").color])
	h.check(not world.get_node("Cinematics").is_playing(), "%s: a clip is playing" % what)
	h.check(h.tree.root.find_children("*", "GameDirector", true, false).size() == 1, "%s: more than one director" % what)
	h.check(h.tree.root.find_children("*", "Camera2D", true, false).size() == 1, "%s: more than one camera" % what)


## What matters most: New Game to the ending, with the keys, the way it is meant to be played. On the way, every
## prop is read, one wrong stone is pressed, the outbound crossing of collapse happens, and the reveal plays.
func test_the_whole_game_can_be_played_from_new_game_to_the_ending_and_back_to_a_clean_new_game(h) -> void:
	var title := await _title(h)
	h.check(_focus(h) == title.get_node(ITEMS + "NewGame"), "focus is on %s" % _focus(h))
	var route = RoutePlayer.new(h)
	await route.start_new_game()
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "New Game saved: %s" % h.read_storage_file(SAVE_FILE))
	var beats := []
	var clips := []
	route.director().beat_changed.connect(func(beat: int) -> void: beats.append(beat))
	route.director().cinematic_started.connect(func(clip: StringName, _generation: int) -> void: clips.append(clip))
	route.world().get_node("Triggers/Collapse").triggered.connect(func(_id: StringName) -> void: clips.append(&"collapse crossed"))

	await route.solve_with_one_mistake()
	h.check(beats == [1, 2, 3], "up to the stones, the beats ran %s" % str(beats))
	h.check(clips.has(&"collapse crossed"), "the way out did not cross collapse")
	h.check(route.world().get_node("Triggers/Collapse").enabled, "the outbound crossing consumed collapse")
	# Along the ground. The third tablet is up on a shelf, and this walk does not need it.
	for id in [&"lifeboat", &"fish", &"fossil_a", &"tablet_wave", &"fossil_b", &"footprint", &"tablet_kneel", &"mural"]:
		h.check(route.captions.has(id), "the walk never offered %s" % id)
	h.check(not route.captions.has(&"tablet_eye"), "the ground walk reached the tablet on the shelf")
	h.check(route.captions.get(&"tablet_wave", "").contains("The waters rose first"), "the first tablet read '%s'" % route.captions.get(&"tablet_wave", ""))
	h.check(route.captions.get(&"mural", "").contains("Ruins"), "the mural first read '%s'" % route.captions.get(&"mural", ""))

	await route.wait_for_control()
	h.check(route.director().get_beat() == 3, "after the stones, beat %d" % route.director().get_beat())
	h.check(h.read_storage_file(SAVE_FILE) == AWAKENED_SAVE, "the file holds: %s" % h.read_storage_file(SAVE_FILE))
	h.check(route.world().get_node("Hud/Notice").text == "Checkpoint saved", "the notice reads '%s'" % route.world().get_node("Hud/Notice").text)

	# The same mural now reads differently: walk back to it, and read it again.
	await route.walk_to_prompt(KEY_A, "Examine", 300)
	await h.wait_until(func() -> bool: return route.player().get_node("Interactor").get_focus().is_available(), 40, "the mural's cooldown")
	await h.tap_key(KEY_E)
	h.check(route.caption().text.contains("swimmer"), "the mural now reads '%s'" % route.caption().text)

	await route.walk_into_the_reveal()
	h.check(route.director().get_beat() == 4, "at the ledge, beat %d" % route.director().get_beat())
	h.check(h.read_storage_file(SAVE_FILE) == AWAKENED_SAVE, "the reveal changed the save")
	await route.wait_for_control()
	h.check(route.director().get_beat() == 5, "after the reveal, beat %d" % route.director().get_beat())
	await route.flee_left()
	h.check(route.director().get_beat() == ENDED, "at the end of the run, beat %d" % route.director().get_beat())
	h.check(beats == [1, 2, 3, 4, 5, 6], "the beats ran %s" % str(beats))
	h.check(clips.filter(func(clip: StringName) -> bool: return clip != &"collapse crossed") == [&"monolith_awaken", &"dagon_reveal", &"collapse"], "the clips ran %s" % str(clips))
	var ending: Node = await h.wait_for_scene("MenuController", 400)
	_check_ending(h, ending, "running")
	h.check(h.read_storage_file(SAVE_FILE) == AWAKENED_SAVE, "the ending changed the save")

	var menu: Control = await _through_credits_to_main_menu(h, ending)
	h.check(menu.get_node_or_null(ITEMS + "Continue") != null, "not the main menu: %s" % menu.name)
	h.check(not menu.get_node(ITEMS + "Continue").disabled, "Continue is disabled after the ending")
	h.check(_focus(h) == menu.get_node(ITEMS + "Continue"), "focus is on %s" % _focus(h))
	h.check(menu.get_node(ITEMS + "SaveStatus").text.contains("before the final sequence"), "the status reads '%s'" % menu.get_node(ITEMS + "SaveStatus").text)

	# New Game again: up to the button, into the confirmation, across to New Game, and press.
	await h.tap_key(KEY_UP)
	h.check(_focus(h) == menu.get_node(ITEMS + "NewGame"), "focus is on %s" % _focus(h))
	await h.tap_key(KEY_ENTER)
	h.check(menu.get_node("Center/Confirm").visible, "no confirmation before replacing the save")
	await h.tap_key(KEY_RIGHT)
	await h.tap_key(KEY_ENTER)
	var again = RoutePlayer.new(h)
	await h.wait_for_scene("GameSession")
	await h.tap_key(KEY_ENTER)
	await h.landed_on_floor(again.player())
	_check_clean_start(h, again, "after the ending")
	h.check(h.read_storage_file(SAVE_FILE) == SHORE_SAVE, "the new game saved: %s" % h.read_storage_file(SAVE_FILE))
	# It really plays: the first trigger still fires, once.
	await again.walk(KEY_D, func() -> bool: return again.director().get_beat() == 1, 900)
	await h.steps(5)
	h.check(again.director().get_beat() == 1, "the new game is at beat %d" % again.director().get_beat())


## Standing still, the returning sea reaches him within a few seconds, and the game ends exactly as running does.
func test_standing_still_the_sea_reaches_him_and_the_ending_is_the_same(h) -> void:
	h.write_storage_file(SAVE_FILE, AWAKENED_SAVE.to_utf8_buffer())
	await _title(h)
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	h.check(route.director().get_beat() == 3, "Continue started at beat %d" % route.director().get_beat())
	await route.walk_into_the_reveal()
	await route.wait_for_control()
	h.check(route.director().get_beat() == 5, "not fleeing: %d" % route.director().get_beat())
	var from_frame: int = Engine.get_physics_frames()
	var ended_at := [-1]
	route.director().beat_changed.connect(func(beat: int) -> void:
		if beat == ENDED:
			ended_at[0] = Engine.get_physics_frames())
	await h.wait_until(func() -> bool: return ended_at[0] >= 0, SEA_FRAMES + 120, "the sea to reach him")
	# wait_for_control spends a few frames after control returned, so this is the sea's remainder.
	h.check(ended_at[0] - from_frame <= SEA_FRAMES, "the sea took %d frames after control returned" % (ended_at[0] - from_frame))
	h.check(ended_at[0] - from_frame >= SEA_FRAMES - 60, "the flee ended after only %d frames" % (ended_at[0] - from_frame))
	var ending: Node = await h.wait_for_scene("MenuController", 400)
	_check_ending(h, ending, "waiting")
	h.check(h.read_storage_file(SAVE_FILE) == AWAKENED_SAVE, "the ending changed the save")


## Pushing the wrong way until the timer runs out: the same again.
func test_pushing_against_the_wall_reaches_the_same_ending(h) -> void:
	h.write_storage_file(SAVE_FILE, AWAKENED_SAVE.to_utf8_buffer())
	await _title(h)
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.walk_into_the_reveal()
	await route.wait_for_control()
	h.send(h.key_event(KEY_D, true))
	# Pressed against the wall he is nearer the trench, so the sea has him sooner than standing at the ledge.
	await h.steps(120)
	h.check(route.director().get_beat() == 5, "the flee ended early")
	h.check(route.player().global_position.x < 4520.0, "the player got past the wall")
	var ending: Node = await h.wait_for_scene("MenuController", 600)
	h.send(h.key_event(KEY_D, false))
	_check_ending(h, ending, "pushing")


func test_pausing_during_the_flee_does_not_use_up_its_time(h) -> void:
	h.write_storage_file(SAVE_FILE, AWAKENED_SAVE.to_utf8_buffer())
	await _title(h)
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.walk_into_the_reveal()
	await route.wait_for_control()
	# Running a little first, so that the sea has started to come on before the pause.
	h.send(h.key_event(KEY_A, true))
	await h.steps(170)
	h.send(h.key_event(KEY_A, false))
	var front: float = route.director().get_tide_front()
	h.check(front < 4540.0, "the sea had not started to come on: %.1f" % front)
	await h.tap_key(KEY_ESCAPE)
	h.check(h.tree.paused, "Esc did not pause")
	await h.steps(900)
	h.check(route.director().get_beat() == 5, "the flee ended while paused")
	h.check_near(route.director().get_tide_front(), front, 0.01, "the sea while paused")
	await h.tap_key(KEY_ESCAPE)
	h.check(not h.tree.paused, "Esc did not resume")
	await h.steps(20)
	h.check(route.director().get_beat() == 5, "the flee used up paused time")
	h.check(route.director().get_tide_front() < front, "the sea did not come on again after resuming")
	await h.wait_for_scene("MenuController", 900)


## Abandoning a cinematic through the pause menu, and starting over from nothing.
func test_pause_during_a_cinematic_then_quit_to_the_main_menu_then_new_game_starts_clean(h) -> void:
	h.write_storage_file(SAVE_FILE, AWAKENED_SAVE.to_utf8_buffer())
	await _title(h)
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	await route.walk_into_the_reveal()
	await h.steps(240)
	h.check(route.director().is_cinematic_active(), "the reveal is not running")
	h.check(route.world().get_node("CameraRig").zoom != Vector2.ONE, "the reveal did not touch the camera")
	await h.tap_key(KEY_ESCAPE)
	h.check(h.tree.paused, "Esc did not pause the reveal")
	var clips: AnimationPlayer = route.world().get_node("Cinematics")
	var position := clips.current_animation_position
	await h.steps(30)
	h.check(is_equal_approx(clips.current_animation_position, position), "the reveal ran on while paused")
	route.pause_menu().ask_quit_to_main_menu()
	await h.steps(1)
	route.pause_menu().get_node("Center/Confirm/Items/Buttons/Ok").grab_focus()
	await h.tap_key(KEY_ENTER)
	var title: Node = await h.wait_for_scene("MenuController")
	h.check(not h.tree.paused, "the main menu is paused")
	title.get_node(ITEMS + "NewGame").grab_focus()
	await h.tap_key(KEY_ENTER)
	await h.tap_key(KEY_RIGHT)
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	await h.tap_key(KEY_ENTER)
	var again = RoutePlayer.new(h)
	await h.landed_on_floor(again.player())
	_check_clean_start(h, again, "after quitting the reveal")


func test_the_ending_has_a_working_controller_route_and_back_does_nothing_at_its_root(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	await h.steps(3)
	await h.tap_key(KEY_ESCAPE)
	await h.tap_pad(JOY_BUTTON_B)
	h.check(ending.get_node("Center/Card").visible and h.tree.current_scene == ending, "Back left the epilogue")
	for i in ending.ending_lines.size():
		await h.tap_pad(JOY_BUTTON_A)
	h.check(ending.get_node("Center/Credits").visible, "the south button did not continue")
	await h.tap_pad(JOY_BUTTON_B)
	h.check(ending.get_node("Center/Card").visible, "the east button did not go back from the credits")
	h.check(_focus(h) == ending.get_node("Center/Card/Items/Continue"), "focus returned to %s" % _focus(h))
	await h.tap_pad(JOY_BUTTON_A)
	await h.tap_pad(JOY_BUTTON_A)
	var title: Node = await h.wait_for_scene("MenuController")
	h.check(title.get_node_or_null(ITEMS + "NewGame") != null, "the ending led to %s" % title.name)


func test_the_epilogue_fills_itself_in_without_anyone_pressing_anything(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	await h.steps(3)
	var total: int = ending.ending_lines.size()
	h.check(_ending_lines(ending).size() == 1, "the card starts with %d lines" % _ending_lines(ending).size())
	await h.wait_until(func() -> bool: return _ending_lines(ending).size() == total, 3600, "every line to show")
	h.check(ending.get_node("Center/Card").visible, "the card went away by itself")
	h.check(_focus(h) == ending.get_node("Center/Card/Items/Continue"), "focus is on %s" % _focus(h))


func test_the_epilogue_names_innsmouth_and_stands_on_its_own(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	await h.steps(3)
	for i in ending.ending_lines.size() - 1:
		await h.tap_key(KEY_ENTER)
	var text := " ".join(_ending_lines(ending))
	for phrase in ["Innsmouth", "That eye, above those waves", "They tell me the sea never left", "finished rising"]:
		h.check(text.contains(phrase), "the epilogue lacks '%s': %s" % [phrase, text])


func test_the_ending_screens_fit_and_their_text_can_be_drawn(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	await h.steps(3)
	for i in ending.ending_lines.size() - 1:
		await h.tap_key(KEY_ENTER)
	await h.steps(2)
	var viewport: Rect2 = ending.get_viewport_rect()
	h.check(_ending_lines(ending).size() == ending.ending_lines.size(), "not every line showed")
	h.check(viewport.encloses(ending.get_node("Center/Card").get_global_rect()), "the epilogue is clipped: %s" % ending.get_node("Center/Card").get_global_rect())
	var font: Font = ending.get_node("Center/Credits/Items/Text").get_theme_font("font")
	var text: String = "\n".join(_ending_lines(ending))
	for i in text.length():
		h.check(text.unicode_at(i) == 10 or text.unicode_at(i) == 32 or font.has_char(text.unicode_at(i)), "the font cannot draw '%s'" % text[i])
	ending.open_credits()
	await h.steps(2)
	h.check(viewport.encloses(ending.get_node("Center/Credits").get_global_rect()), "the credits are clipped: %s" % ending.get_node("Center/Credits").get_global_rect())
	var title: Node = (load(TITLE) as PackedScene).instantiate()
	h.check(ending.get_node("Center/Credits/Items/Text").text == title.get_node("Center/Credits/Items/Text").text, "the two credits screens differ")
	title.free()
	for pair in [["Center/Card/Items/Continue", ending.advance_ending], ["Center/Credits/Items/MainMenu", ending.quit_to_main_menu]]:
		h.check(ending.get_node(pair[0]).pressed.is_connected(pair[1]), "%s is not connected" % pair[0])


func test_the_device_in_use_carries_through_the_ending_to_the_main_menu(h) -> void:
	h.use_controller("Xbox Wireless Controller")
	h.write_storage_file(SAVE_FILE, AWAKENED_SAVE.to_utf8_buffer())
	await _title(h)
	await h.tap_pad(JOY_BUTTON_A)
	await h.wait_for_scene("GameSession")
	var route = RoutePlayer.new(h)
	await h.landed_on_floor(route.player())
	h.check(h.tree.current_scene.get_active_device() == 0, "the session has device %d" % h.tree.current_scene.get_active_device())
	route.director().flee_timeout = 0.2
	# The controller's own D-pad, as any key would hand the device back to the keyboard.
	h.send(h.pad_event(JOY_BUTTON_DPAD_RIGHT, true))
	await h.wait_until(func() -> bool: return not route.player().is_control_enabled(), 300, "the walk into the reveal")
	h.send(h.pad_event(JOY_BUTTON_DPAD_RIGHT, false))
	var ending: Node = await h.wait_for_scene("MenuController", 1500)
	h.check(ending.get_active_device() == 0, "the ending has device %d" % ending.get_active_device())
	for i in ending.ending_lines.size() + 1:
		await h.tap_pad(JOY_BUTTON_A)
	var title: Node = await h.wait_for_scene("MenuController")
	h.check(title.get_active_device() == 0, "the main menu has device %d" % title.get_active_device())
