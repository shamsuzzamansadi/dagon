extends SceneTree
## M6's display check (docs/evidence/m6/displays): through the real menus, on a private X display of the size under test, the
## title in its window, Settings, Display switched to fullscreen, the menus walked with keys in fullscreen, an in-game
## caption among the longest, back to a window from the pause menu's Settings, and the ending's longest line. At each
## stage it prints the window's mode, size and position, the screen's, and the game's own picture size, and saves a
## screenshot of the whole screen with ImageMagick's import. Evidence, not a test. On a private display:
## XNS_SCREEN=1280x720x24 xns.sh sh -c 'DAGON_STORAGE_DIR=<dir> godot --path project --script res://tests/capture_display.gd -- <out dir> <label>'

const Harness := preload("res://tests/harness.gd")
const TITLE := "res://scenes/ui/title.tscn"
const ENDING := "res://scenes/ui/ending.tscn"
const GAME := "res://scenes/level/game.tscn"
const ABYSS := 1
const TITLE_ITEMS := "Center/Main/Panel/Items/"
const SETTINGS_ITEMS := "Center/Panel/Items/"
const MODES := {0: "windowed", 1: "minimized", 2: "maximized", 3: "fullscreen", 4: "exclusive-fullscreen"}

var h
var out := ""
var label := ""
var shot := 0


func _initialize() -> void:
	_run()


func _report(stage: String) -> void:
	var picture := root.get_visible_rect().size
	var window := DisplayServer.window_get_size()
	var scale := mini(window.x / int(picture.x), window.y / int(picture.y))
	print("DISPLAY %s mode=%s window=%s at=%s screen=%s usable=%s picture=%s scale=%d focus=%s" % [stage,
		MODES.get(DisplayServer.window_get_mode(), "?"), window, DisplayServer.window_get_position(),
		DisplayServer.screen_get_size(), DisplayServer.screen_get_usable_rect(), picture, scale,
		root.gui_get_focus_owner().name if root.gui_get_focus_owner() != null else "none"])


func _shot(stage: String) -> void:
	await h.steps(20)
	shot += 1
	_report(stage)
	var path := out.path_join("%s-%02d-%s.png" % [label, shot, stage])
	var output := []
	var code := OS.execute("import", ["-window", "root", path], output, true)
	print("SHOT %s code=%d" % [path, code])


func _press(node_path: String, scene: Node) -> void:
	(scene.get_node(node_path) as Control).grab_focus()
	await h.steps(2)
	await h.tap_action("ui_accept")
	await h.steps(10)


func _run() -> void:
	h = Harness.new(self)
	var args := OS.get_cmdline_user_args()
	out = args[0]
	label = args[1]
	DirAccess.make_dir_recursive_absolute(out)

	# The title, as the game opens it: its settings are applied, and a window too big for the screen is fitted.
	var title: Node = await h.load_with((load(TITLE) as PackedScene).instantiate(), true)
	await h.steps(30)
	await _shot("title-window")
	await _press(TITLE_ITEMS + "Settings", title)
	var settings: Node = title.get_node("Settings")
	await _shot("settings-window")

	# Fullscreen, from the Display button, the way a player does it.
	await _press(SETTINGS_ITEMS + "Columns/Keys/Display", settings)
	await h.steps(30)
	await _shot("settings-fullscreen")
	# The menus by keys, in fullscreen: down to Back, and up again to Display.
	for action in ["ui_down", "ui_down", "ui_up", "ui_up", "ui_up"]:
		await h.tap_action(action)
		await h.steps(4)
		_report("key-" + action)
	await _shot("settings-fullscreen-keys")
	await h.tap_action("ui_cancel")
	await h.steps(10)
	await _shot("title-fullscreen")

	# In the game, fullscreen: one of the longest captions the player reads. The title goes first; the window keeps
	# its mode, which belongs to the display, not the scene.
	await h.unload_fixture()
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_start(ABYSS, true, false)
	await h.load_with(session, true)
	var world: Node = session.get_world()
	await h.steps(60)
	var hud: Node = world.get_node("Hud")
	hud.say(&"abyss.relief")
	await h.steps(45)
	await _shot("caption-fullscreen")

	# Back to a window from the pause menu's Settings, reached as a player reaches it.
	await h.tap_key(KEY_ESCAPE)
	await h.steps(15)
	await h.tap_action("ui_down")
	await h.tap_action("ui_down")
	await h.tap_action("ui_accept")
	await h.steps(15)
	var pause_settings: Node = root.find_child("PauseMenu", true, false).get_node("Settings")
	await _press(SETTINGS_ITEMS + "Columns/Keys/Display", pause_settings)
	await h.steps(30)
	await _shot("pause-settings-windowed")
	await h.tap_action("ui_cancel")
	await h.steps(5)
	await h.tap_key(KEY_ESCAPE)
	await h.steps(10)
	hud.say(&"abyss.relief")
	await h.steps(45)
	await _shot("caption-window")

	# The ending's longest line, in the window.
	await h.unload_fixture()
	var ending: Node = await h.load_with((load(ENDING) as PackedScene).instantiate(), true)
	await h.wait_until(func() -> bool: return ending.get_ending_line() >= 2, 60 * 40, "the third ending line")
	await h.steps(60)
	await _shot("ending-longest-window")

	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for sound in root.find_children("*", type, true, false):
			sound.stop()
	await h.steps(3)
	quit(0)
