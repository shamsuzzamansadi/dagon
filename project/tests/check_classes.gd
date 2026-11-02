extends SceneTree
## Extension-load check.
## Run: godot --headless --path project --script res://tests/check_classes.gd

const EXPECTED := {
	"PlayerController": {
		"base": "CharacterBody2D",
		"properties": ["walk_speed", "acceleration", "deceleration", "air_control", "gravity_scale", "max_fall_speed", "jump_velocity", "jump_cut", "coyote_time", "jump_buffer_time", "action_move_left", "action_move_right", "action_jump", "visual_path"],
		"methods": ["set_control_enabled", "is_control_enabled", "teleport", "get_facing"],
		"signals": ["jumped", "landed"],
	},
	"CameraRig": {
		"base": "Camera2D",
		"properties": ["target_path", "look_ahead", "vertical_offset"],
		"methods": [],
		"signals": [],
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
