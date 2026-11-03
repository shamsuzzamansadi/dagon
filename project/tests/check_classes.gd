extends SceneTree
## Extension-load check.
## Run: godot --headless --path project --script res://tests/check_classes.gd

const EXPECTED := {
	"PlayerController": {
		"base": "CharacterBody2D",
		"properties": ["walk_speed", "acceleration", "deceleration", "air_control", "gravity_scale", "max_fall_speed", "jump_velocity", "jump_cut", "coyote_time", "jump_buffer_time", "action_move_left", "action_move_right", "action_jump", "visual_path", "sprite_path", "walk_pixels_per_frame"],
		"methods": ["set_control_enabled", "is_control_enabled", "teleport", "get_facing"],
		"signals": ["jumped", "landed"],
	},
	"CameraRig": {
		"base": "Camera2D",
		"properties": ["target_path", "look_ahead", "vertical_offset", "pixel_lock", "lock_speed"],
		"methods": [],
		"signals": [],
	},
	"Interactable": {
		"base": "Area2D",
		"properties": ["interaction_id", "prompt", "caption", "one_shot", "enabled", "cooldown"],
		"methods": ["try_interact", "is_available"],
		"signals": ["interacted"],
	},
	"Interactor": {
		"base": "Area2D",
		"properties": ["action_interact"],
		"methods": ["get_focus"],
		"signals": ["focus_changed", "interacted"],
	},
	"StoryTrigger": {
		"base": "Area2D",
		"properties": ["trigger_id", "enabled"],
		"methods": ["is_player_inside"],
		"signals": ["triggered"],
	},
	"Hud": {
		"base": "CanvasLayer",
		"properties": ["prompt_label_path", "caption_label_path", "fade_rect_path", "caption_hold_seconds"],
		"methods": ["on_focus_changed", "on_interacted", "show_caption", "hide_caption", "fade_to_black", "fade_from_black"],
		"signals": ["fade_finished"],
	},
	"GameDirector": {
		"base": "Node",
		"properties": ["player_path", "hud_path", "kill_plane_path", "checkpoints", "story_triggers"],
		"methods": ["restart_checkpoint", "get_active_checkpoint"],
		"signals": ["checkpoint_reached", "player_respawned"],
	},
	"MenuController": {
		"base": "Control",
		"properties": ["director_path", "main_panel_path", "quit_panel_path", "settings_menu_path", "resume_button_path", "settings_button_path", "quit_button_path", "quit_cancel_button_path", "quit_message_label_path"],
		"methods": ["is_open", "open", "resume", "restart_checkpoint", "open_settings", "ask_quit", "cancel_quit", "confirm_quit", "back"],
		"signals": [],
	},
	"SettingsMenu": {
		"base": "Control",
		"properties": ["music_slider_path", "effects_slider_path", "key_button_paths", "message_label_path", "conflict_row_path", "swap_button_path"],
		"methods": ["open", "back", "begin_capture", "swap_conflict", "cancel_conflict", "restore_defaults", "set_music_volume", "set_effects_volume", "is_capturing", "has_conflict"],
		"signals": ["closed"],
	},
}


func _initialize() -> void:
	var problems := PackedStringArray()
	for class_id: String in EXPECTED:
		var spec: Dictionary = EXPECTED[class_id]
		if not ClassDB.class_exists(class_id):
			problems.append("class %s is not registered" % class_id)
			continue
		if ClassDB.get_parent_class(class_id) != spec["base"]:
			problems.append("%s has base %s" % [class_id, ClassDB.get_parent_class(class_id)])
		if not ClassDB.can_instantiate(class_id):
			problems.append("%s cannot be instantiated" % class_id)
		var properties := ClassDB.class_get_property_list(class_id, true).map(func(p: Dictionary) -> String: return p["name"])
		for property: String in spec["properties"]:
			if not properties.has(property):
				problems.append("%s lacks property %s" % [class_id, property])
		for method: String in spec["methods"]:
			if not ClassDB.class_has_method(class_id, method, true):
				problems.append("%s lacks method %s" % [class_id, method])
		for signal_id: String in spec["signals"]:
			if not ClassDB.class_has_signal(class_id, signal_id):
				problems.append("%s lacks signal %s" % [class_id, signal_id])
	for problem in problems:
		print("PROBLEM %s" % problem)
	print("CHECK_CLASSES classes=%d problems=%d" % [EXPECTED.size(), problems.size()])
	quit(0 if problems.is_empty() else 1)
