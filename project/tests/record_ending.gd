extends SceneTree
## Plays the ending as it comes after the collapse: every line at its own pace, nothing pressed, then into the credits
## and back to the main menu, for Godot's Movie Maker to record with its sound. Evidence, not a test. On a private
## display:
## DISPLAY=:77 DAGON_STORAGE_DIR=<dagon-test-dir> godot --path project --resolution 960x540 --write-movie <out.avi> \
##     --fixed-fps 30 --script res://tests/record_ending.gd
## It prints "RECORD <stage> frame=<n>" at each stage.

const Harness := preload("res://tests/harness.gd")

var h


func _initialize() -> void:
	_run()


func _mark(stage: String) -> void:
	print("RECORD %s frame=%d" % [stage, Engine.get_process_frames()])


func _run() -> void:
	h = Harness.new(self)
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	for line in ending.ending_lines.size():
		await h.wait_until(func() -> bool: return ending.get_ending_line() == line, 60 * 60, "line %d" % line)
		_mark("line-%d-%s" % [line + 1, ending.ending_lines[line]])
	# The last line, spoken and read to its end, as a player who presses nothing hears it, and a moment after.
	# In frames, as Movie Maker does not run in real time: 30 to the second.
	var shown := Engine.get_process_frames()
	await h.wait_until(func() -> bool: return not ending.get_node("Voice").playing and Engine.get_process_frames() - shown > 30 * 9, 60 * 40, "the last line to end")
	await h.steps(60 * 3)
	await h.tap_key(KEY_ENTER)
	_mark("credits")
	await h.steps(60 * 6)
	await h.tap_key(KEY_ENTER)
	await h.wait_until(func() -> bool: return is_instance_valid(current_scene) and current_scene.has_method("continue_game"), 120, "the main menu")
	_mark("main-menu")
	await h.steps(60 * 2)
	_mark("end")
	for sound in root.find_children("*", "AudioStreamPlayer", true, false):
		sound.stop()
	var until := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < until:
		await process_frame
	quit(0)
