#include "camera_rig.hpp"

#include "player_controller.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

namespace dagon {

void CameraRig::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_target_path", "path"), &CameraRig::set_target_path);
	ClassDB::bind_method(D_METHOD("get_target_path"), &CameraRig::get_target_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "target_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Node2D"), "set_target_path", "get_target_path");

	ClassDB::bind_method(D_METHOD("set_look_ahead", "value"), &CameraRig::set_look_ahead);
	ClassDB::bind_method(D_METHOD("get_look_ahead"), &CameraRig::get_look_ahead);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "look_ahead"), "set_look_ahead", "get_look_ahead");

	ClassDB::bind_method(D_METHOD("set_vertical_offset", "value"), &CameraRig::set_vertical_offset);
	ClassDB::bind_method(D_METHOD("get_vertical_offset"), &CameraRig::get_vertical_offset);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "vertical_offset"), "set_vertical_offset", "get_vertical_offset");
}

void CameraRig::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	Node2D *target = target_path_.is_empty() ? nullptr : get_node<Node2D>(target_path_);
	if (target == nullptr) {
		ERR_PRINT("CameraRig: target_path does not point to a Node2D; the camera will not follow.");
		return;
	}
	target_.set(target);
	set_global_position(desired_position(*target));
	reset_smoothing();
}

void CameraRig::_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	if (const Node2D *target = target_.get()) {
		set_global_position(desired_position(*target));
	}
}

PackedStringArray CameraRig::_get_configuration_warnings() const {
	PackedStringArray warnings = Camera2D::_get_configuration_warnings();
	if (target_path_.is_empty()) {
		warnings.push_back("target_path is not set, so the camera will not follow anything.");
	}
	return warnings;
}

Vector2 CameraRig::desired_position(const Node2D &p_target) const {
	const PlayerController *player = Object::cast_to<PlayerController>(&p_target);
	const float facing = player != nullptr ? static_cast<float>(player->get_facing()) : 0.0f;
	return p_target.get_global_position() + Vector2(facing * look_ahead_, vertical_offset_);
}

} // namespace dagon
