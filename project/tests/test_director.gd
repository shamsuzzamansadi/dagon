extends RefCounted
## Tests of StoryTrigger, the session checkpoint and the kill plane, and of the HUD on the entry scene.

const ARENA := "res://tests/fixtures/director_arena.tscn"
const SHORE := "res://scenes/level/shore.tscn"


func _arena(h) -> CharacterBody2D:
	await h.load_fixture(ARENA)
	var player: CharacterBody2D = h.fixture.get_node("Player")
	await h.landed_on_floor(player)
	return player


func _shore(h) -> CharacterBody2D:
	await h.load_fixture(SHORE)
	var player: CharacterBody2D = h.fixture.get_node("Player")
	await h.landed_on_floor(player)
	return player


func test_a_trigger_fires_on_every_entry_and_never_latches_itself(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	var player: CharacterBody2D = h.fixture.get_node("Player")
	var trigger: Area2D = ClassDB.instantiate("StoryTrigger")
	trigger.trigger_id = &"loose"
	trigger.collision_layer = 8
	trigger.collision_mask = 2
	trigger.position = Vector2(300, -30)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(10, 60)
	trigger.add_child(shape)
	h.fixture.add_child(trigger)
	var ids := []
	trigger.triggered.connect(func(id: StringName) -> void: ids.append(id))

	await h.stand_at(player, Vector2(300, -2))
	h.check(ids == [&"loose"], "first entry gave %s" % str(ids))
	h.check(trigger.is_player_inside(), "is_player_inside() is false while inside")
	await h.stand_at(player, Vector2(200, -2))
	h.check(not trigger.is_player_inside(), "is_player_inside() is true after leaving")
	await h.stand_at(player, Vector2(300, -2))
	h.check(ids.size() == 2, "a second entry gave %d events in total" % ids.size())
	await h.stand_at(player, Vector2(200, -2))
	trigger.enabled = false
	await h.stand_at(player, Vector2(300, -2))
	h.check(ids.size() == 2, "a disabled trigger fired")
	h.check(trigger.is_player_inside(), "a disabled trigger stopped tracking the player")


func test_triggers_advance_the_checkpoint_in_order(h) -> void:
	var player: CharacterBody2D = await _arena(h)
	var director: Node = h.fixture.get_node("GameDirector")
	var reached := []
	director.checkpoint_reached.connect(func(index: int) -> void: reached.append(index))
	h.check(director.get_active_checkpoint() == 0, "the session did not start at checkpoint 0")
	await h.stand_at(player, Vector2(300, -2))
	h.check(director.get_active_checkpoint() == 1, "trigger A gave checkpoint %d" % director.get_active_checkpoint())
	h.check(not h.fixture.get_node("TriggerA").enabled, "an accepted trigger was not consumed")
	await h.stand_at(player, Vector2(500, -2))
	h.check(director.get_active_checkpoint() == 2, "trigger B gave checkpoint %d" % director.get_active_checkpoint())
	h.check(reached == [1, 2], "checkpoint_reached gave %s" % str(reached))


func test_a_rejected_trigger_changes_nothing_and_stays_armed(h) -> void:
	var player: CharacterBody2D = await _arena(h)
	var director: Node = h.fixture.get_node("GameDirector")
	var trigger_b: Area2D = h.fixture.get_node("TriggerB")
	await h.stand_at(player, Vector2(500, -2))
	h.check(director.get_active_checkpoint() == 0, "an out-of-order trigger moved the checkpoint")
	h.check(trigger_b.enabled, "a rejected trigger was consumed")
	await h.stand_at(player, Vector2(300, -2))
	await h.stand_at(player, Vector2(500, -2))
	h.check(director.get_active_checkpoint() == 2, "the rejected trigger did not work when its turn came")


func test_walking_back_over_a_used_trigger_changes_nothing(h) -> void:
	var player: CharacterBody2D = await _arena(h)
	var director: Node = h.fixture.get_node("GameDirector")
	var reached := []
	await h.stand_at(player, Vector2(300, -2))
	director.checkpoint_reached.connect(func(index: int) -> void: reached.append(index))
	await h.stand_at(player, Vector2(250, -2))
	await h.stand_at(player, Vector2(300, -2))
	h.check(director.get_active_checkpoint() == 1, "re-entry moved the checkpoint")
	h.check(reached.is_empty(), "re-entry emitted %s" % str(reached))


func test_the_kill_plane_respawns_at_the_active_checkpoint_every_time(h) -> void:
	var player: CharacterBody2D = await _arena(h)
	var director: Node = h.fixture.get_node("GameDirector")
	var respawns := [0]
	director.player_respawned.connect(func() -> void: respawns[0] += 1)

	player.teleport(Vector2(400, 180))
	await h.steps(30)
	h.check_near(player.global_position.x, 100.0, 1.0, "respawn x at checkpoint 0")
	h.check(player.is_on_floor(), "the player did not land after respawning")
	h.check(respawns[0] == 1, "first fall gave %d respawns" % respawns[0])

	await h.stand_at(player, Vector2(300, -2))
	player.teleport(Vector2(400, 180))
	await h.steps(30)
	h.check_near(player.global_position.x, 350.0, 1.0, "respawn x at checkpoint 1")
	h.check(respawns[0] == 2, "second fall gave %d respawns in total" % respawns[0])
	h.check(h.fixture.get_node("KillPlane").enabled, "the kill plane was consumed")


func test_a_fall_keeps_a_buffered_jump_from_firing_in_midair(h) -> void:
	var player: CharacterBody2D = await _arena(h)
	var jumps := [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	player.teleport(Vector2(400, 180))
	await h.steps(2)
	h.check(jumps[0] == 0, "falling out of the world jumped")


func test_the_shore_kill_plane_catches_a_fall_anywhere_in_the_level(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	for x in [40.0, 700.0, 1360.0]:
		player.teleport(Vector2(x, 100))
		await h.steps(30)
		h.check_near(player.global_position.x, 150.0, 1.0, "respawn x after a fall at x=%.0f" % x)
		h.check(player.is_on_floor(), "not on the floor after a fall at x=%.0f" % x)


func test_the_shore_checkpoint_moves_past_the_trench(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	var director: Node = h.fixture.get_node("GameDirector")
	await h.stand_at(player, Vector2(725, -2))
	Input.action_press("move_right")
	await h.wait_until(func() -> bool: return director.get_active_checkpoint() == 1, 60, "the checkpoint to move")
	Input.action_release("move_right")
	player.teleport(Vector2(300, 100))
	await h.steps(30)
	h.check_near(player.global_position.x, 750.0, 1.0, "respawn x past the trench")


func test_every_scene_connection_is_in_place(h) -> void:
	await _shore(h)
	var interactor: Node = h.fixture.get_node("Player/Interactor")
	var hud: Node = h.fixture.get_node("Hud")
	h.check(interactor.focus_changed.is_connected(hud.on_focus_changed), "focus_changed is not connected to the Hud")
	h.check(interactor.interacted.is_connected(hud.on_interacted), "interacted is not connected to the Hud")
	var director: Node = h.fixture.get_node("GameDirector")
	h.check(not director.checkpoints.is_empty(), "the director has no checkpoints")
	for path in director.checkpoints + director.story_triggers + [director.kill_plane_path, director.player_path, director.hud_path]:
		h.check(director.get_node_or_null(path) != null, "the director's path %s does not resolve" % path)
	h.check(h.fixture.get_node("Triggers/EnterAbyss").triggered.get_connections().size() == 1, "EnterAbyss is not connected to the director")
	h.check(h.fixture.get_node("Triggers/KillPlane").triggered.get_connections().size() == 1, "KillPlane is not connected to the director")
	for prop in h.fixture.get_node("Props").get_children():
		h.check(prop.interaction_id != &"" and prop.caption != "", "%s has no id or caption" % prop.name)


func test_the_prompt_follows_focus_and_names_the_key(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	var prompt: Label = h.fixture.get_node("Hud/Prompt")
	await h.stand_at(player, Vector2(150, -2))
	h.check(prompt.visible, "no prompt beside the boat")
	h.check(prompt.text == "[E] Examine", "prompt reads '%s'" % prompt.text)
	await h.stand_at(player, Vector2(280, -2))
	h.check(not prompt.visible, "the prompt stayed with nothing in range")


func test_the_prompt_follows_the_last_device_used(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	var prompt: Label = h.fixture.get_node("Hud/Prompt")
	await h.stand_at(player, Vector2(150, -2))
	await h.tap_pad(JOY_BUTTON_LEFT_SHOULDER)
	h.check(prompt.text == "[X] Examine", "after a pad button it reads '%s'" % prompt.text)
	await h.tap_key(KEY_T)
	h.check(prompt.text == "[E] Examine", "after a key it reads '%s'" % prompt.text)


func test_examining_shows_the_caption_and_never_pauses(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	var caption: Label = h.fixture.get_node("Hud/Caption")
	await h.stand_at(player, Vector2(150, -2))
	await h.tap_action("interact")
	h.check(caption.visible, "no caption after examining")
	h.check(caption.text == h.fixture.get_node("Props/Lifeboat").caption, "caption reads '%s'" % caption.text)
	h.check(not h.tree.paused, "a caption paused the game")
	var start_x := player.global_position.x
	Input.action_press("move_right")
	await h.steps(20)
	Input.action_release("move_right")
	h.check(player.global_position.x > start_x + 5.0, "the player could not move during a caption")
	await h.wait_until(func() -> bool: return not caption.visible, 300, "the caption to fade")


func test_a_new_caption_replaces_the_old_one_and_restarts_its_time(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	var caption: Label = h.fixture.get_node("Hud/Caption")
	var hud: Node = h.fixture.get_node("Hud")
	hud.show_caption("first")
	await h.steps(120)
	hud.show_caption("second")
	h.check(caption.text == "second", "caption reads '%s'" % caption.text)
	# The first caption's fade would have finished by now, had it not been replaced.
	await h.steps(150)
	h.check(caption.visible, "the replaced caption's timer ended the new one")
	h.check(player != null, "fixture lost the player")


func test_fading_to_black_covers_the_screen_and_reports_it(h) -> void:
	await _shore(h)
	var fade: ColorRect = h.fixture.get_node("Hud/Fade")
	var hud: Node = h.fixture.get_node("Hud")
	fade.modulate.a = 0.0
	var finished := [0]
	hud.fade_finished.connect(func() -> void: finished[0] += 1)
	hud.fade_to_black(0.2)
	await h.wait_until(func() -> bool: return finished[0] == 1, 60, "the fade to finish")
	h.check(fade.visible and is_equal_approx(fade.modulate.a, 1.0), "the screen is not covered: alpha %.2f" % fade.modulate.a)


func test_respawning_fades_in_and_clears(h) -> void:
	var player: CharacterBody2D = await _shore(h)
	var fade: ColorRect = h.fixture.get_node("Hud/Fade")
	var hud: Node = h.fixture.get_node("Hud")
	var finished := [0]
	hud.fade_finished.connect(func() -> void: finished[0] += 1)
	h.fixture.get_node("GameDirector").restart_checkpoint()
	await h.steps(1)
	h.check(fade.visible, "no fade on respawn")
	h.check(player != null, "fixture lost the player")
	await h.wait_until(func() -> bool: return not fade.visible, 60, "the fade to clear")
	h.check(finished[0] == 1, "fade_finished fired %d times" % finished[0])
