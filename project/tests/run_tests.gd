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
	preload("res://tests/test_shore.gd"),
	preload("res://tests/test_interaction.gd"),
	preload("res://tests/test_director.gd"),
	preload("res://tests/test_pause_menu.gd"),
	preload("res://tests/test_settings.gd"),
	preload("res://tests/test_session.gd"),
	preload("res://tests/test_title.gd"),
	preload("res://tests/test_controller.gd"),
	preload("res://tests/test_cinematics.gd"),
	preload("res://tests/test_puzzle.gd"),
	preload("res://tests/test_world.gd"),
	preload("res://tests/test_restore.gd"),
	preload("res://tests/test_route.gd"),
]
const REQUIRED_CLASSES: Array[String] = ["PlayerController", "CameraRig", "Interactable", "Interactor", "StoryTrigger", "Hud", "PuzzleController", "GameDirector", "GameSession", "MenuController", "SettingsMenu"]
const STORAGE_VARIABLE := "DAGON_STORAGE_DIR"
const STORAGE_MARKER := "dagon-test-"
## Set by tools/export_check.sh. Export rewrites scenes, so the same tests also run on what actually ships.
const PACK_VARIABLE := "DAGON_TEST_PACK"

## Watchdog in rendered frames, so a broken await cannot hang the run forever.
const MAX_FRAMES := 400000

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


## The player's real files, apart from the engine's own logs. A run must leave this unchanged.
func _player_files(path: String, found: Array[String]) -> Array[String]:
	var directory := DirAccess.open(path)
	if directory == null:
		return found
	for file_name in directory.get_files():
		var file_path := path.path_join(file_name)
		found.append("%s %d %d" % [file_path, FileAccess.get_size(file_path), FileAccess.get_modified_time(file_path)])
	for folder in directory.get_directories():
		if folder != "logs" and folder != "shader_cache":
			_player_files(path.path_join(folder), found)
	return found


func _run() -> void:
	# Scenes read settings in _ready, so a run with no test directory could load or overwrite a player's.
	if not OS.get_environment(STORAGE_VARIABLE).contains(STORAGE_MARKER):
		print("FAIL %s must name a %s* directory; tools/run_godot_checks.sh creates one" % [STORAGE_VARIABLE, STORAGE_MARKER])
		print("RESULT passed=0 failed=1")
		quit(1)
		return
	var empty_list: Array[String] = []
	var player_files_before := _player_files(OS.get_user_data_dir(), empty_list)

	var pack := OS.get_environment(PACK_VARIABLE)
	if not pack.is_empty():
		if not ProjectSettings.load_resource_pack(pack, true):
			print("FAIL could not mount %s" % pack)
			print("RESULT passed=0 failed=1")
			quit(1)
			return
		print("PACK mounted %s" % pack)

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
		var suite_name: String = suite.resource_path.get_file().get_basename()
		for method in instance.get_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			_trap.take()
			var harness := Harness.new(self)
			await instance.call(test_name, harness)
			await harness.unload_fixture()
			for error in _trap.take():
				if not harness.accepts_error(error):
					harness.fail("logged error: %s" % error)
			for text in harness.unseen_expected_errors():
				harness.fail("expected an error that never came: %s" % text)
			if harness.failures.is_empty():
				passed += 1
				print("PASS %s.%s" % [suite_name, test_name])
			else:
				failed += 1
				print("FAIL %s.%s" % [suite_name, test_name])
				for failure in harness.failures:
					print("     %s" % failure)
	var after_list: Array[String] = []
	if _player_files(OS.get_user_data_dir(), after_list) != player_files_before:
		failed += 1
		print("FAIL the test run changed the player's real files in %s" % OS.get_user_data_dir())
	OS.remove_logger(_trap)
	print("RESULT passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 and passed > 0 else 1)
