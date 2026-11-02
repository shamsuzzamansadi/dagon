extends RefCounted
## Small helper handed to each test. Rules (docs/architecture.md §8): inject
## input, await N probe steps, then observe; bounded waits; tolerances.

const StepProbe := preload("res://tests/step_probe.gd")

var tree: SceneTree
var fixture: Node
var probe: Node
var failures: PackedStringArray = []


func _init(p_tree: SceneTree) -> void:
	tree = p_tree


func load_fixture(path: String) -> Node:
	fixture = (load(path) as PackedScene).instantiate()
	probe = StepProbe.new()
	tree.root.add_child(fixture)
	tree.root.add_child(probe)
	await steps(1)
	return fixture


func unload_fixture() -> void:
	release_all_actions()
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


func fail(message: String) -> void:
	failures.append(message)


func check(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func check_near(actual: float, expected: float, tolerance: float, what: String) -> void:
	if absf(actual - expected) > tolerance:
		fail("%s: expected %.3f ±%.3f, got %.3f" % [what, expected, tolerance, actual])
