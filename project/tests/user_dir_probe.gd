extends SceneTree
## Checks the storage path real players use. Every test redirects storage, so this is the only check of
## user:// itself. It writes there, so it runs only on CI's throwaway machines, and refuses anywhere else.
## Run with DAGON_STORAGE_DIR unset and CI set: godot --headless --path project --script res://tests/user_dir_probe.gd

const FILE_PATH := "user://settings.cfg"


func _initialize() -> void:
	_run()


func _fail(message: String) -> void:
	print("USER_DIR_PROBE FAILED: %s" % message)
	quit(1)


func _run() -> void:
	if OS.get_environment("CI").is_empty() or not OS.get_environment("DAGON_STORAGE_DIR").is_empty():
		_fail("this needs CI set and DAGON_STORAGE_DIR unset, because it writes to the real user folder")
		return
	if FileAccess.file_exists(FILE_PATH):
		_fail("%s already exists, so this is not a throwaway machine" % FILE_PATH)
		return

	var scene: Node = (load("res://scenes/level/shore.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await physics_frame
	var menu: Control = scene.get_node("PauseLayer/PauseMenu")
	menu.open()
	menu.open_settings()
	await physics_frame

	var settings: Control = menu.get_node("Settings")
	settings.set_music_volume(0.5)
	if not FileAccess.file_exists(FILE_PATH) or not FileAccess.get_file_as_string(FILE_PATH).contains("music_volume=0.5"):
		_fail("the first write did not reach %s" % FILE_PATH)
		return
	# Replacing a file that exists is the case that differs between platforms.
	settings.set_music_volume(0.2)
	if not FileAccess.get_file_as_string(FILE_PATH).contains("music_volume=0.2"):
		_fail("the second write did not replace %s" % FILE_PATH)
		return
	if FileAccess.file_exists(FILE_PATH + ".tmp"):
		_fail("a temporary file was left behind")
		return
	print("USER_DIR_PROBE ok %s" % ProjectSettings.globalize_path(FILE_PATH).get_base_dir())
	quit(0)
