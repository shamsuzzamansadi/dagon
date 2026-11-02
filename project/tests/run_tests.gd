extends SceneTree
## Hand-rolled headless test runner.
##
## Run: godot --headless --path project --fixed-fps 60 --script res://tests/run_tests.gd
## Prints one PASS/FAIL line per test and a final RESULT line. Exit code 0 only
## when every test passed. Run through tools/run_godot_checks.sh, which also
## fails on any ERROR line, since a GDScript runtime error does not fail a test.

const Harness := preload("res://tests/harness.gd")
const SUITES: Array[Script] = [
	preload("res://tests/test_movement.gd"),
	preload("res://tests/test_level.gd"),
]

## Watchdog in rendered frames, so a broken await cannot hang the run forever.
const MAX_FRAMES := 40000

var _frames := 0


func _initialize() -> void:
	_run()


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > MAX_FRAMES:
		printerr("ERROR: test watchdog fired after %d frames" % MAX_FRAMES)
		quit(3)
	return false


func _run() -> void:
	var passed := 0
	var failed := 0
	for suite in SUITES:
		var instance: RefCounted = suite.new()
		for method in instance.get_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			var harness := Harness.new(self)
			await instance.call(test_name, harness)
			await harness.unload_fixture()
			if harness.failures.is_empty():
				passed += 1
				print("PASS %s" % test_name)
			else:
				failed += 1
				print("FAIL %s" % test_name)
				for failure in harness.failures:
					print("     %s" % failure)
	print("RESULT passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 and passed > 0 else 1)
