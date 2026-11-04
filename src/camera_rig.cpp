#include "camera_rig.hpp"

#include "player_controller.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace dagon {

void CameraRig::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_target"), &CameraRig::get_target);
	ClassDB::bind_method(D_METHOD("aim_at", "path"), &CameraRig::aim_at);
	ClassDB::bind_method(D_METHOD("add_trauma", "amount"), &CameraRig::add_trauma);
	ClassDB::bind_method(D_METHOD("get_trauma"), &CameraRig::get_trauma);
	ClassDB::bind_method(D_METHOD("restore_view", "target"), &CameraRig::restore_view);

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

	ClassDB::bind_method(D_METHOD("set_max_shake", "value"), &CameraRig::set_max_shake);
	ClassDB::bind_method(D_METHOD("get_max_shake"), &CameraRig::get_max_shake);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_shake"), "set_max_shake", "get_max_shake");

	ClassDB::bind_method(D_METHOD("set_trauma_decay", "value"), &CameraRig::set_trauma_decay);
	ClassDB::bind_method(D_METHOD("get_trauma_decay"), &CameraRig::get_trauma_decay);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "trauma_decay"), "set_trauma_decay", "get_trauma_decay");
}

void CameraRig::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	default_zoom_ = get_zoom();
	default_limit_left_ = get_limit(SIDE_LEFT);
	default_limit_top_ = get_limit(SIDE_TOP);
	default_limit_right_ = get_limit(SIDE_RIGHT);
	default_limit_bottom_ = get_limit(SIDE_BOTTOM);
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
	update_shake(static_cast<float>(p_delta));
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

void CameraRig::set_target(Node2D *p_target) {
	target_.set(p_target);
	if (p_target != nullptr) {
		locked_offset_ = desired_offset(*p_target);
	}
}

void CameraRig::aim_at(const NodePath &p_path) {
	Node2D *target = get_node<Node2D>(p_path);
	if (target == nullptr) {
		ERR_PRINT("CameraRig: aim_at was given a path that does not point to a Node2D.");
		return;
	}
	set_target(target);
}

void CameraRig::add_trauma(float p_amount) {
	trauma_ = std::clamp(trauma_ + p_amount, 0.0f, 1.0f);
}

void CameraRig::restore_view(Node2D *p_target) {
	set_target(p_target);
	set_zoom(default_zoom_);
	set_limit(SIDE_LEFT, default_limit_left_);
	set_limit(SIDE_TOP, default_limit_top_);
	set_limit(SIDE_RIGHT, default_limit_right_);
	set_limit(SIDE_BOTTOM, default_limit_bottom_);
	trauma_ = 0.0f;
	set_offset(Vector2());
}

// Whole pixels, as everything else on screen is. The shake is its square, so a small amount stays small.
void CameraRig::update_shake(float p_delta) {
	if (trauma_ <= 0.0f) {
		return;
	}
	trauma_ = std::max(trauma_ - trauma_decay_ * p_delta, 0.0f);
	shake_time_ += p_delta;
	const float amount = trauma_ * trauma_ * max_shake_;
	set_offset(Vector2(std::round(amount * std::sin(shake_time_ * 37.0f)), std::round(amount * std::sin(shake_time_ * 53.0f + 1.0f))));
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
