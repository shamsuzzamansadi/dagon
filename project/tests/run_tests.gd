extends SceneTree
## Hand-rolled headless test runner.
##
## Run: godot --headless --path project --fixed-fps 60 --script res://tests/run_tests.gd
## Prints one PASS/FAIL line per test and a final RESULT line. Exit code 0 only
## when every test passed.

const Harness := preload("res://tests/harness.gd")
const SUITES: Array[Script] = [
	preload("res://tests/test_movement.gd"),
	preload("res://tests/test_level.gd"),
]
const REQUIRED_CLASSES: Array[String] = ["PlayerController", "CameraRig"]

## Watchdog in rendered frames, so a broken await cannot hang the run forever.
const MAX_FRAMES := 40000

## A GDScript runtime error silently aborts the running test function, which
## would otherwise count as a pass. Any engine or script error fails the test.
class ErrorTrap extends Logger:
	var errors: PackedStringArray = []
	var mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		errors.append("%s:%d %s: %s %s" % [file, line, function, code, rationale])
		mutex.unlock()

	func take() -> PackedStringArray:
		mutex.lock()
		var taken := errors.duplicate()
		errors.clear()
		mutex.unlock()
		return taken


var _frames := 0
var _trap := ErrorTrap.new()


func _initialize() -> void:
	OS.add_logger(_trap)
	_run()


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > MAX_FRAMES:
		printerr("ERROR: test watchdog fired after %d frames" % MAX_FRAMES)
		quit(3)
	return false


func _run() -> void:
	for class_id in REQUIRED_CLASSES:
		if not ClassDB.class_exists(class_id):
			print("FAIL class %s is not registered; the extension did not load" % class_id)
			print("RESULT passed=0 failed=1")
			quit(1)
			return

	var passed := 0
	var failed := 0
	for suite in SUITES:
		var instance: RefCounted = suite.new()
		for method in instance.get_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			_trap.take()
			var harness := Harness.new(self)
			await instance.call(test_name, harness)
			await harness.unload_fixture()
			for error in _trap.take():
				harness.fail("logged error: %s" % error)
			if harness.failures.is_empty():
				passed += 1
				print("PASS %s" % test_name)
			else:
				failed += 1
				print("FAIL %s" % test_name)
				for failure in harness.failures:
					print("     %s" % failure)
	OS.remove_logger(_trap)
	print("RESULT passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 and passed > 0 else 1)
