extends RefCounted
## Tests of Interactable and Interactor. Presses go through Input.parse_input_event, so they reach
## _unhandled_input the way a real press does (docs/roadmap.md, M2 follow-up).

const ARENA := "res://tests/fixtures/interaction_arena.tscn"


## Anything still listening after the Interactor. Unhandled input runs in reverse tree order, so this
## node goes first in the tree.
class Listener extends Node:
	var presses := 0

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("interact"):
			presses += 1


func _setup(h) -> CharacterBody2D:
	await h.load_fixture(ARENA)
	var player: CharacterBody2D = h.fixture.get_node("Player")
	await h.landed_on_floor(player)
	return player


func _interactor(player: Node) -> Node:
	return player.get_node("Interactor")


func test_focus_is_gained_in_range_and_lost_out_of_range(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var interactor := _interactor(player)
	await h.stand_at(player, Vector2(225, -2))
	h.check(interactor.get_focus() == h.fixture.get_node("Near"), "no focus in range")
	await h.stand_at(player, Vector2(300, -2))
	h.check(interactor.get_focus() == null, "kept focus out of range")


func test_the_nearest_available_thing_has_focus(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var interactor := _interactor(player)
	await h.stand_at(player, Vector2(411, -2))
	h.check(interactor.get_focus() == h.fixture.get_node("First"), "First is nearest at x=411")
	await h.stand_at(player, Vector2(419, -2))
	h.check(interactor.get_focus() == h.fixture.get_node("Second"), "Second is nearest at x=419")
	h.fixture.get_node("Second").enabled = false
	await h.steps(1)
	h.check(interactor.get_focus() == h.fixture.get_node("First"), "focus did not fall back when the nearest was disabled")


func test_focus_changed_fires_only_when_the_focus_changes(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var changes := []
	_interactor(player).focus_changed.connect(func(target: Object) -> void: changes.append(target))
	await h.stand_at(player, Vector2(225, -2))
	await h.steps(30)
	h.check(changes.size() == 1, "expected 1 change walking into range, got %d" % changes.size())
	h.check(changes[0] == h.fixture.get_node("Near"), "the change did not name the target")


func test_disabling_the_focused_thing_clears_focus_in_one_frame(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var interactor := _interactor(player)
	await h.stand_at(player, Vector2(225, -2))
	h.fixture.get_node("Near").enabled = false
	await h.steps(1)
	h.check(interactor.get_focus() == null, "focus survived the object being disabled")


func test_freeing_the_focused_thing_clears_focus_without_a_crash(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var interactor := _interactor(player)
	await h.stand_at(player, Vector2(225, -2))
	var changes := []
	interactor.focus_changed.connect(func(target: Object) -> void: changes.append(target))
	h.fixture.get_node("Near").queue_free()
	await h.steps(2)
	h.check(interactor.get_focus() == null, "focus survived the object being freed")
	h.check(changes.size() == 1 and changes[0] == null, "expected one change to nothing, got %s" % str(changes))
	h.send(h.action_event("interact", true))
	await h.steps(1)
	h.send(h.action_event("interact", false))


func test_a_press_reaches_the_focused_thing_through_the_event_path(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(225, -2))
	var ids := []
	h.fixture.get_node("Near").interacted.connect(func(id: StringName) -> void: ids.append(id))
	var targets := []
	_interactor(player).interacted.connect(func(target: Object) -> void: targets.append(target))
	await h.tap_action("interact")
	h.check(ids == [&"near"], "Interactable.interacted gave %s" % str(ids))
	h.check(targets == [h.fixture.get_node("Near")], "Interactor.interacted gave %s" % str(targets))


func test_a_double_press_is_one_event_until_the_cooldown_ends(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(225, -2))
	var near: Node = h.fixture.get_node("Near")
	var count := [0]
	near.interacted.connect(func(_id: StringName) -> void: count[0] += 1)
	await h.tap_action("interact")
	await h.tap_action("interact")
	h.check(count[0] == 1, "two quick presses gave %d events" % count[0])
	await h.wait_until(near.is_available, 60, "the cooldown to end")
	await h.steps(1)
	await h.tap_action("interact")
	h.check(count[0] == 2, "a press after the cooldown gave %d events in total" % count[0])


func test_a_one_shot_works_once_and_stops_taking_focus(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(595, -2))
	var once: Node = h.fixture.get_node("Once")
	var count := [0]
	once.interacted.connect(func(_id: StringName) -> void: count[0] += 1)
	await h.tap_action("interact")
	await h.steps(60)
	h.check(count[0] == 1, "one_shot gave %d events" % count[0])
	h.check(not once.is_available(), "one_shot is still available")
	h.check(_interactor(player).get_focus() == null, "one_shot kept focus after it was used")
	await h.tap_action("interact")
	h.check(count[0] == 1, "one_shot fired again")


func test_a_handled_press_reaches_nothing_else(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	var listener := Listener.new()
	h.fixture.add_child(listener)
	h.fixture.move_child(listener, 0)
	await h.stand_at(player, Vector2(225, -2))
	await h.tap_action("interact")
	h.check(listener.presses == 0, "a press with focus also reached another consumer")
	await h.stand_at(player, Vector2(300, -2))
	await h.tap_action("interact")
	h.check(listener.presses == 1, "a press with no focus was swallowed")


func test_a_locked_player_cannot_interact(h) -> void:
	var player: CharacterBody2D = await _setup(h)
	await h.stand_at(player, Vector2(225, -2))
	var near: Node = h.fixture.get_node("Near")
	var count := [0]
	near.interacted.connect(func(_id: StringName) -> void: count[0] += 1)
	player.set_control_enabled(false)
	await h.steps(1)
	h.check(_interactor(player).get_focus() == null, "focus survived the control lock")
	await h.tap_action("interact")
	h.check(count[0] == 0, "a locked player interacted")
	player.set_control_enabled(true)
	await h.steps(1)
	h.check(_interactor(player).get_focus() == near, "focus did not return after the lock")
