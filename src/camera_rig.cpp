#include "camera_rig.hpp"

#include "player_controller.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

#include <cmath>

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

	ClassDB::bind_method(D_METHOD("set_pixel_lock", "enabled"), &CameraRig::set_pixel_lock);
	ClassDB::bind_method(D_METHOD("is_pixel_lock"), &CameraRig::is_pixel_lock);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "pixel_lock"), "set_pixel_lock", "is_pixel_lock");

	ClassDB::bind_method(D_METHOD("set_lock_speed", "value"), &CameraRig::set_lock_speed);
	ClassDB::bind_method(D_METHOD("get_lock_speed"), &CameraRig::get_lock_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "lock_speed"), "set_lock_speed", "get_lock_speed");
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
	locked_offset_ = desired_offset(*target);
	if (pixel_lock_) {
		place_locked(*target, 0.0f);
	} else {
		set_global_position(target->get_global_position() + locked_offset_);
	}
	reset_smoothing();
}

void CameraRig::_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	const Node2D *target = target_.get();
	if (target == nullptr) {
		return;
	}
	if (pixel_lock_) {
		place_locked(*target, static_cast<float>(p_delta));
	} else {
		set_global_position(target->get_global_position() + desired_offset(*target));
	}
}

PackedStringArray CameraRig::_get_configuration_warnings() const {
	PackedStringArray warnings = Camera2D::_get_configuration_warnings();
	if (target_path_.is_empty()) {
		warnings.push_back("target_path is not set, so the camera will not follow anything.");
	}
	if (pixel_lock_ && is_position_smoothing_enabled()) {
		warnings.push_back("Position smoothing defeats pixel_lock: the character will flicker by a pixel while followed.");
	}
	return warnings;
}

Vector2 CameraRig::desired_offset(const Node2D &p_target) const {
	const PlayerController *player = Object::cast_to<PlayerController>(&p_target);
	const float facing = player != nullptr ? static_cast<float>(player->get_facing()) : 0.0f;
	return Vector2(facing * look_ahead_, vertical_offset_);
}

void CameraRig::place_locked(const Node2D &p_target, float p_delta) {
	const float blend = 1.0f - std::exp(-lock_speed_ * p_delta);
	locked_offset_ = locked_offset_.lerp(desired_offset(p_target), blend);
	// Same rounding as the renderer's 2D pixel snap, so the target and camera move together.
	const Vector2 position = p_target.get_global_position();
	const Vector2 whole_position(std::floor(position.x + 0.5f), std::floor(position.y + 0.5f));
	const Vector2 whole_offset(std::floor(locked_offset_.x + 0.5f), std::floor(locked_offset_.y + 0.5f));
	set_global_position(whole_position + whole_offset);
}

} // namespace dagon
