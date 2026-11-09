extends RefCounted
## Small helper handed to each test. Rules (docs/architecture.md §8): inject
## input, await N probe steps, then observe; bounded waits; tolerances.

const StepProbe := preload("res://tests/step_probe.gd")

## Set by tools/test_storage.sh for the whole run. Each test gets its own folder inside it.
const STORAGE_VARIABLE := "DAGON_STORAGE_DIR"

static var _tests_started := 0

var tree: SceneTree
var fixture: Node
var probe: Node
var failures: PackedStringArray = []
var storage_dir: String
var _run_storage_dir: String
var _expected_errors := {}


## How many prologues wait_for_scene skipped on the way to a game, since the last fixture.
var prologues_skipped := 0

func _init(p_tree: SceneTree) -> void:
	tree = p_tree
	_run_storage_dir = OS.get_environment(STORAGE_VARIABLE)
	_tests_started += 1
	use_storage("%s/test_%d" % [_run_storage_dir, _tests_started])


## Everything that reads or writes a file goes through this variable, so no test can reach a player's files.
func use_storage(path: String) -> void:
	storage_dir = path
	DirAccess.make_dir_recursive_absolute(path)
	OS.set_environment(STORAGE_VARIABLE, path)


func write_storage_file(file_name: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(storage_dir.path_join(file_name), FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func read_storage_file(file_name: String) -> String:
	return FileAccess.get_file_as_string(storage_dir.path_join(file_name))


## There is no way to make a real device in a test. This names what the game takes device 0 to be, and
## everything after that runs for real. It says nothing about physical controllers.
func use_controller(controller_name: String) -> void:
	OS.set_environment("DAGON_TEST_CONTROLLER", controller_name)


func load_fixture(path: String) -> Node:
	fixture = (load(path) as PackedScene).instantiate()
	probe = StepProbe.new()
	tree.root.add_child(fixture)
	tree.root.add_child(probe)
	await steps(1)
	return fixture


## For a scene that changes scene: the tree only replaces its current scene.
func load_main_fixture(path: String) -> Node:
	fixture = (load(path) as PackedScene).instantiate()
	probe = StepProbe.new()
	tree.root.add_child(fixture)
	tree.current_scene = fixture
	tree.root.add_child(probe)
	await steps(1)
	return fixture


## A world or a session, built with its start value in place before it enters the tree, as the game builds them.
func load_with(node: Node, as_main := false) -> Node:
	fixture = node
	probe = StepProbe.new()
	tree.root.add_child(probe)
	tree.root.add_child(node)
	if as_main:
		tree.current_scene = node
	await steps(1)
	return node


## Waits for a scene change to finish, and returns the new scene.
func wait_for_scene(type_name: String, max_steps := 60) -> Node:
	# New Game shows the prologue before the game. A test waiting for the game skips it, as a player can, and the
	# tests of the prologue itself say so. Continue never shows it, which they check too.
	if type_name == "GameSession":
		await wait_until(func() -> bool: return is_instance_valid(tree.current_scene) and tree.current_scene.is_node_ready() and (tree.current_scene.is_class(type_name) or tree.current_scene.has_method("skip_prologue")), max_steps, "the scene to change to %s" % type_name)
		if is_instance_valid(tree.current_scene) and tree.current_scene.has_method("skip_prologue") and not tree.current_scene.is_class(type_name):
			prologues_skipped += 1
			tree.current_scene.skip_prologue()
	await wait_until(func() -> bool: return is_instance_valid(tree.current_scene) and tree.current_scene.is_class(type_name) and tree.current_scene.is_node_ready(), max_steps, "the scene to change to %s" % type_name)
	fixture = tree.current_scene
	await steps(1)
	return fixture


## For a test that sets out to cause an engine error. The runner fails a test on any error it logs, except one whose
## text contains this. It also fails the test if no such error ever came, so a test cannot expect something by habit.
func expect_error(text: String) -> void:
	_expected_errors[text] = false


func accepts_error(error: String) -> bool:
	for text: String in _expected_errors:
		if error.contains(text):
			_expected_errors[text] = true
			return true
	return false


func unseen_expected_errors() -> Array[String]:
	var unseen: Array[String] = []
	for text: String in _expected_errors:
		if not _expected_errors[text]:
			unseen.append(text)
	return unseen


func unload_fixture() -> void:
	release_all_actions()
	tree.paused = false
	Engine.time_scale = 1.0
	OS.set_environment("DAGON_TEST_CONTROLLER", "")
	if is_instance_valid(tree.current_scene) and tree.current_scene != fixture:
		tree.current_scene.queue_free()
	tree.current_scene = null
	InputMap.load_from_project_settings()
	Engine.remove_meta(&"dagon_subtitles")
	Engine.remove_meta(&"dagon_vibration")
	Input.stop_joy_vibration(0)
	for bus in ["Music", "Effects", "Narration"]:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, 0.0)
	# A test resumes inside the probe's signal emission, where free() is refused.
	if is_instance_valid(fixture):
		fixture.queue_free()
	if is_instance_valid(probe):
		probe.queue_free()
	await tree.process_frame
	await tree.physics_frame


func release_all_actions() -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)


## Waits for N completed physics ticks, observed after the player has moved.
func steps(count: int) -> void:
	for i in count:
		await probe.stepped


## Steps until condition returns true. Returns false after max_steps, with a failure recorded.
func wait_until(condition: Callable, max_steps: int, description: String) -> bool:
	for i in max_steps:
		if condition.call():
			return true
		await probe.stepped
	if condition.call():
		return true
	fail("timed out after %d steps waiting for %s" % [max_steps, description])
	return false


func landed_on_floor(player: CharacterBody2D) -> bool:
	return await wait_until(player.is_on_floor, 120, "the player to land")


## Moves the player and waits until it stands there, since is_on_floor() is out of date right after a teleport.
func stand_at(player: CharacterBody2D, position: Vector2) -> void:
	player.teleport(position)
	await steps(30)
	check(player.is_on_floor(), "the player did not land at %s" % position)


## Event-path input: delivered to _input and _unhandled_input, not just the polled state.
func send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Tests resume inside a physics tick, where no real input arrives. The engine's menu navigation by stick
## needs is_action_just_pressed, which input from mid-tick only satisfies from the next tick.
func send_between_ticks(event: InputEvent) -> void:
	await tree.process_frame
	send(event)


func action_event(action: String, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func key_event(physical_keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	event.keycode = physical_keycode
	event.pressed = pressed
	return event


func pad_event(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


## A press and release with a step between them, as a person's would have.
func tap(pressed_event: InputEvent, released_event: InputEvent) -> void:
	send(pressed_event)
	await steps(1)
	send(released_event)
	await steps(1)


func tap_action(action: String) -> void:
	await tap(action_event(action, true), action_event(action, false))


func tap_key(physical_keycode: Key) -> void:
	await tap(key_event(physical_keycode, true), key_event(physical_keycode, false))


func tap_pad(button: JoyButton) -> void:
	await tap(pad_event(button, true), pad_event(button, false))


func fail(message: String) -> void:
	failures.append(message)


func check(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func check_near(actual: float, expected: float, tolerance: float, what: String) -> void:
	if absf(actual - expected) > tolerance:
		fail("%s: expected %.3f ±%.3f, got %.3f" % [what, expected, tolerance, actual])
