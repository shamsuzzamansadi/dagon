extends RefCounted
## Plays the game the way a person does. Everything it does is a real key event. Everything it decides comes from
## what a player can see: where the sailor stands, what the prompt says, and what the menus show.

var h
var captions := {}
## When set, every line examined is let run to its end, spoken or read, before walking on: how a careful player plays,
## and what a recording of the mix needs. The tests leave it off.
var read_through := false


func _init(harness) -> void:
	h = harness


func session() -> Node:
	return h.tree.current_scene


func world() -> Node:
	return session().get_world()


func player() -> CharacterBody2D:
	return world().get_node("Player")


func director() -> Node:
	return session().get_director()


func prompt() -> Label:
	return world().get_node("Hud/Prompt")


func caption() -> Label:
	return world().get_node("Hud/Caption")


func pause_menu() -> Control:
	return session().get_node("PauseLayer/PauseMenu")


## New Game from the main menu: How to Play, Begin, the prologue skipped, and the sailor on his feet.
func start_new_game() -> void:
	await h.tap_key(KEY_ENTER)
	h.check(h.is_introduction(h.tree.current_scene), "New Game showed no introduction")
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	h.check(h.introductions_begun == 0, "Begin did not leave the introduction")
	h.check(not h.tree.paused and not pause_menu().is_open(), "the game began paused")
	await h.landed_on_floor(player())
	await h.wait_for_control(player())


## Holds a key until the condition holds, hopping when the sailor is blocked, as anyone would. With examine on, it
## stops to read everything that offers a prompt, once each.
func walk(key: Key, reached: Callable, max_steps: int, examine := false) -> bool:
	var body := player()
	var last_x := body.global_position.x
	var stalled := 0
	h.send(h.key_event(key, true))
	for i in max_steps:
		await h.steps(1)
		if reached.call():
			h.send(h.key_event(key, false))
			await h.steps(1)
			return true
		if examine and prompt().visible:
			var focus: Node = body.get_node("Interactor").get_focus()
			if focus != null and focus.is_available() and focus.prompt == "Examine" and not captions.has(focus.interaction_id):
				h.send(h.key_event(key, false))
				await h.tap_key(KEY_E)
				# A story moment being spoken is cut short by the first press, and the second examines.
				if caption().text != focus.caption or not caption().visible:
					await h.tap_key(KEY_E)
				captions[focus.interaction_id] = caption().text
				if read_through:
					await h.wait_until(func() -> bool: return not caption().visible, 60 * 30, "the line to end")
				h.send(h.key_event(key, true))
				last_x = body.global_position.x
				stalled = 0
				continue
		stalled = stalled + 1 if absf(body.global_position.x - last_x) < 0.2 else 0
		last_x = body.global_position.x
		if stalled >= 6 and body.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(12)
			h.send(h.key_event(KEY_SPACE, false))
			stalled = 0
	h.send(h.key_event(key, false))
	h.fail("walking did not arrive, at x=%.1f, control %s, on floor %s, beat %d, cinematic %s, paused %s, time scale %.2f" % [body.global_position.x, body.is_control_enabled(), body.is_on_floor(), director().get_beat(), director().is_cinematic_active(), h.tree.paused, Engine.time_scale])
	return false


func walk_to_prompt(key: Key, text: String, max_steps: int, examine := false) -> bool:
	return await walk(key, func() -> bool: return prompt().visible and prompt().text.ends_with(text), max_steps, examine)


## Holds a key and hops each time the sailor stands on something, until the prompt shows: climbing ledges.
func climb_to_prompt(key: Key, text: String, max_steps: int) -> bool:
	var body := player()
	h.send(h.key_event(key, true))
	for i in max_steps:
		if prompt().visible and prompt().text.ends_with(text):
			h.send(h.key_event(key, false))
			await h.steps(1)
			return true
		if body.is_on_floor():
			h.send(h.key_event(KEY_SPACE, true))
			await h.steps(16)
			h.send(h.key_event(KEY_SPACE, false))
		await h.steps(1)
	h.send(h.key_event(key, false))
	h.fail("climbing did not reach '%s', at %s" % [text, body.global_position])
	return false


## From the Shore, reading everything on the way, to the carving at the ledges. Then up them, and push the stone.
func cross_the_gap() -> void:
	await walk(KEY_D, func() -> bool: return captions.has(&"crossing_mark"), 3000, true)
	await climb_to_prompt(KEY_D, "Push the stone", 600)
	await h.tap_key(KEY_E)
	await h.wait_until(func() -> bool: return director().is_crossing_lowered() and not director().is_crossing_moving(), 120, "the slab to come down")


## At the stone whose prompt is showing: waits for it to be ready, and presses.
func press_stone(text: String) -> void:
	await h.wait_until(func() -> bool:
		var focus: Node = player().get_node("Interactor").get_focus()
		return focus != null and focus.is_available() and prompt().text.ends_with(text), 90, "the stone '%s' to be ready" % text)
	await h.tap_key(KEY_E)


func wait_for_control(max_steps := 900) -> void:
	await h.wait_until(func() -> bool: return player().is_control_enabled() and not director().is_cinematic_active(), max_steps, "control to come back")
	await h.steps(4)


## From wherever the sailor is on the way to the stones: one wrong stone, one good one, then the rest.
func solve_with_one_mistake() -> void:
	await walk_to_prompt(KEY_D, "Press the kneeling stone", 4000, true)
	await press_stone("Press the kneeling stone")
	await h.steps(2)
	h.check(caption().text == "The stones grind and go dark.", "a wrong stone shows '%s'" % caption().text)
	await walk_to_prompt(KEY_D, "Press the wave stone", 400)
	await press_stone("Press the wave stone")
	await walk_to_prompt(KEY_A, "Press the kneeling stone", 400)
	await press_stone("Press the kneeling stone")
	await walk_to_prompt(KEY_D, "Press the eye stone", 300)
	await press_stone("Press the eye stone")


## Through the open gate and into the reveal.
func walk_into_the_reveal() -> void:
	await walk(KEY_D, func() -> bool: return not player().is_control_enabled(), 900)


## Back the way the sailor came, until the world ends for him.
func flee_left() -> void:
	await walk(KEY_A, func() -> bool: return not player().is_control_enabled(), 900)
