extends SceneTree
## Extension-load check.
## Run: godot --headless --path project --script res://tests/check_classes.gd

const EXPECTED := {
	"PlayerController": {
		"base": "CharacterBody2D",
		"properties": ["walk_speed", "acceleration", "deceleration", "air_control", "gravity_scale", "max_fall_speed", "jump_velocity", "jump_cut", "coyote_time", "jump_buffer_time", "action_move_left", "action_move_right", "action_jump", "visual_path", "sprite_path", "walk_pixels_per_frame"],
		"methods": ["set_control_enabled", "is_control_enabled", "teleport", "get_facing", "face", "show_pose", "get_shown_pose"],
		"signals": ["jumped", "landed"],
	},
	"CameraRig": {
		"base": "Camera2D",
		"properties": ["target_path", "look_ahead", "vertical_offset", "pixel_lock", "lock_speed", "max_shake", "trauma_decay"],
		"methods": ["get_target", "aim_at", "add_trauma", "get_trauma", "restore_view"],
		"signals": [],
	},
	"Interactable": {
		"base": "Area2D",
		"properties": ["interaction_id", "prompt", "caption", "line_id", "one_shot", "enabled", "cooldown"],
		"methods": ["try_interact", "is_available", "use_line"],
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
		"properties": ["trigger_id", "enabled", "spent_from_beat"],
		"methods": ["is_player_inside"],
		"signals": ["triggered"],
	},
	"Hud": {
		"base": "CanvasLayer",
		"properties": ["interactor_path", "notice_label_path", "prompt_label_path", "caption_label_path", "fade_rect_path", "voice_path", "caption_hold_seconds"],
		"methods": ["on_focus_changed", "on_interacted", "show_caption", "hide_caption", "say", "is_speaking", "get_current_line", "show_notice", "set_input_device", "fade_to_black", "fade_from_black"],
		"signals": ["fade_finished"],
	},
	"PuzzleController": {
		"base": "Node",
		"properties": ["solution", "reset_delay", "indicators", "stones"],
		"methods": ["submit", "reset", "is_solved", "is_rejecting", "get_progress", "restore_solved"],
		"signals": ["step_accepted", "failed", "solved"],
	},
	"GameDirector": {
		"base": "Node",
		"properties": ["player_path", "hud_path", "kill_plane_path", "camera_rig_path", "atmosphere_path", "cinematics_path", "monolith_gate_path", "puzzle_path", "mural_path", "mural_solved_line", "background_path", "background_triggers", "awakened_visuals", "checkpoints", "story_triggers", "ending_scene", "flee_timeout"],
		"methods": ["wake", "restart_checkpoint", "get_active_checkpoint", "get_beat", "is_safe_to_save", "is_in_final_sequence", "set_start_beat", "get_start_beat", "fade_in", "show_notice", "on_puzzle_solved", "start_cinematic", "finalize_cinematic", "is_cinematic_active", "get_generation", "get_active_clip", "has_pending_event", "is_recovery_pending", "get_flee_elapsed", "haptic_cue"],
		"signals": ["checkpoint_reached", "player_respawned", "beat_changed", "cinematic_started", "cinematic_finalized", "overlap_rechecked", "contract_error", "background_event_started"],
	},
	"GameSession": {
		"base": "Node",
		"properties": ["world_scene", "director_path", "menu_path"],
		"methods": ["set_start", "set_waking", "is_waking", "set_active_device", "get_active_device", "restart_checkpoint", "retry_save", "is_checkpoint_saved", "has_any_save", "is_in_final_sequence", "get_session_beat", "get_persisted_beat", "get_world", "get_director"],
		"signals": [],
	},
	"MenuController": {
		"base": "Control",
		"properties": ["mode", "game_scene", "title_scene_path", "session_path", "main_panel_path", "confirm_panel_path", "controls_panel_path", "credits_panel_path", "settings_menu_path", "first_button_path", "continue_button_path", "new_game_button_path", "settings_button_path", "controls_button_path", "credits_button_path", "quit_button_path", "quit_to_menu_button_path", "confirm_cancel_button_path", "confirm_ok_button_path", "confirm_message_label_path", "controls_title_label_path", "controls_text_label_path", "controls_back_button_path", "credits_back_button_path", "save_status_label_path", "ending_box_path", "voice_path", "ending_lines"],
		"methods": ["set_active_device", "get_active_device", "is_open", "open", "resume", "restart_checkpoint", "ask_quit_to_desktop", "ask_quit_to_main_menu", "show_intro", "new_game", "continue_game", "open_credits", "quit_now", "quit_to_main_menu", "advance_ending", "get_ending_line", "refresh_save_status", "open_settings", "open_controls", "confirm", "cancel_confirm", "back"],
		"signals": [],
	},
	"SettingsMenu": {
		"base": "Control",
		"properties": ["music_slider_path", "effects_slider_path", "narration_slider_path", "subtitles_button_path", "vibration_button_path", "key_button_paths", "message_label_path", "conflict_row_path", "swap_button_path"],
		"methods": ["open", "back", "begin_capture", "swap_conflict", "cancel_conflict", "restore_defaults", "set_music_volume", "set_effects_volume", "set_narration_volume", "toggle_subtitles", "toggle_vibration", "is_capturing", "has_conflict", "describe_key"],
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
