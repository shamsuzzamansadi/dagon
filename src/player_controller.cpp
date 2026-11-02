#include "player_controller.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

#include <cmath>

using namespace godot;

namespace dagon {

void PlayerController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_control_enabled", "enabled"), &PlayerController::set_control_enabled);
	ClassDB::bind_method(D_METHOD("is_control_enabled"), &PlayerController::is_control_enabled);
	ClassDB::bind_method(D_METHOD("teleport", "position"), &PlayerController::teleport);
	ClassDB::bind_method(D_METHOD("get_facing"), &PlayerController::get_facing);

#define DAGON_BIND_FLOAT(m_name)                                                               \
	ClassDB::bind_method(D_METHOD("set_" #m_name, "value"), &PlayerController::set_##m_name);  \
	ClassDB::bind_method(D_METHOD("get_" #m_name), &PlayerController::get_##m_name);           \
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, #m_name), "set_" #m_name, "get_" #m_name)

	ADD_GROUP("Movement", "");
	DAGON_BIND_FLOAT(walk_speed);
	DAGON_BIND_FLOAT(acceleration);
	DAGON_BIND_FLOAT(deceleration);
	DAGON_BIND_FLOAT(air_control);
	DAGON_BIND_FLOAT(gravity_scale);
	DAGON_BIND_FLOAT(max_fall_speed);
	ADD_GROUP("Jump", "");
	DAGON_BIND_FLOAT(jump_velocity);
	DAGON_BIND_FLOAT(jump_cut);
	DAGON_BIND_FLOAT(coyote_time);
	DAGON_BIND_FLOAT(jump_buffer_time);

#undef DAGON_BIND_FLOAT

#define DAGON_BIND_ACTION(m_name)                                                                     \
	ClassDB::bind_method(D_METHOD("set_action_" #m_name, "value"), &PlayerController::set_action_##m_name); \
	ClassDB::bind_method(D_METHOD("get_action_" #m_name), &PlayerController::get_action_##m_name);  \
	ADD_PROPERTY(PropertyInfo(Variant::STRING_NAME, "action_" #m_name), "set_action_" #m_name, "get_action_" #m_name)

	ADD_GROUP("Input Actions", "");
	DAGON_BIND_ACTION(move_left);
	DAGON_BIND_ACTION(move_right);
	DAGON_BIND_ACTION(jump);

#undef DAGON_BIND_ACTION

	ADD_GROUP("", "");
	ClassDB::bind_method(D_METHOD("set_visual_path", "path"), &PlayerController::set_visual_path);
	ClassDB::bind_method(D_METHOD("get_visual_path"), &PlayerController::get_visual_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "visual_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Node2D"), "set_visual_path", "get_visual_path");

	ADD_SIGNAL(MethodInfo("jumped"));
	ADD_SIGNAL(MethodInfo("landed"));
}

void PlayerController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	project_gravity_ = ProjectSettings::get_singleton()->get_setting("physics/2d/default_gravity", 700.0);

	InputMap *input_map = InputMap::get_singleton();
	input_actions_valid_ = input_map->has_action(action_move_left_) && input_map->has_action(action_move_right_) && input_map->has_action(action_jump_);
	if (!input_actions_valid_) {
		ERR_PRINT("PlayerController: an input action is missing from the project's InputMap; input is disabled.");
	}

	if (!visual_path_.is_empty()) {
		Node2D *visual = get_node<Node2D>(visual_path_);
		if (visual == nullptr) {
			ERR_PRINT("PlayerController: visual_path does not point to a Node2D; facing will not be shown.");
		}
		visual_.set(visual);
	}
}

void PlayerController::_physics_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	core::MoveInput input;
	if (control_enabled_ && input_actions_valid_) {
		Input *godot_input = Input::get_singleton();
		input.axis = godot_input->get_axis(action_move_left_, action_move_right_);
		input.jump_pressed = godot_input->is_action_just_pressed(action_jump_);
		input.jump_held = godot_input->is_action_pressed(action_jump_);
	}

	core::FloorContact contact = core::FloorContact::Unknown;
	if (!contact_stale_) {
		contact = is_on_floor() ? core::FloorContact::Grounded : core::FloorContact::Airborne;
	}

	params_.gravity = project_gravity_ * gravity_scale_;

	// velocity holds the post-collision result of the previous move_and_slide().
	const Vector2 velocity = get_velocity();
	const core::StepResult result = core::step(state_, params_, input, core::Vec2{ velocity.x, velocity.y }, contact, static_cast<float>(p_delta));

	set_velocity(Vector2(result.velocity.x, result.velocity.y));
	move_and_slide();
	contact_stale_ = false;

	update_facing(input.axis);

	if (result.landed) {
		emit_signal("landed");
	}
	if (result.jumped) {
		emit_signal("jumped");
	}
}

PackedStringArray PlayerController::_get_configuration_warnings() const {
	PackedStringArray warnings = CharacterBody2D::_get_configuration_warnings();
	if (visual_path_.is_empty()) {
		warnings.push_back("visual_path is not set, so facing will not be shown.");
	}
	return warnings;
}

void PlayerController::set_control_enabled(bool p_enabled) {
	control_enabled_ = p_enabled;
	if (!p_enabled) {
		core::clear_jump_intent(state_);
	}
}

void PlayerController::teleport(const Vector2 &p_position) {
	set_global_position(p_position);
	set_velocity(Vector2());
	state_ = core::MoveState{};
	contact_stale_ = true;
}

void PlayerController::update_facing(float p_axis) {
	if (p_axis == 0.0f) {
		return;
	}
	const int facing = p_axis > 0.0f ? 1 : -1;
	if (facing == facing_) {
		return;
	}
	facing_ = facing;
	if (Node2D *visual = visual_.get()) {
		Vector2 scale = visual->get_scale();
		scale.x = std::abs(scale.x) * static_cast<float>(facing_);
		visual->set_scale(scale);
	}
}

} // namespace dagon
