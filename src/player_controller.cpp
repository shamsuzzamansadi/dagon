#include "player_controller.hpp"

#include "core/body_pose.hpp"

#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/sprite_frames.hpp>
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
	ClassDB::bind_method(D_METHOD("face", "direction"), &PlayerController::face);

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
	ClassDB::bind_method(D_METHOD("set_sprite_path", "path"), &PlayerController::set_sprite_path);
	ClassDB::bind_method(D_METHOD("get_sprite_path"), &PlayerController::get_sprite_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "sprite_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "AnimatedSprite2D"), "set_sprite_path", "get_sprite_path");
	ClassDB::bind_method(D_METHOD("set_walk_pixels_per_frame", "value"), &PlayerController::set_walk_pixels_per_frame);
	ClassDB::bind_method(D_METHOD("get_walk_pixels_per_frame"), &PlayerController::get_walk_pixels_per_frame);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "walk_pixels_per_frame"), "set_walk_pixels_per_frame", "get_walk_pixels_per_frame");

	ClassDB::bind_method(D_METHOD("set_idle_speed", "value"), &PlayerController::set_idle_speed);
	ClassDB::bind_method(D_METHOD("get_idle_speed"), &PlayerController::get_idle_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "idle_speed"), "set_idle_speed", "get_idle_speed");
	ADD_GROUP("Footsteps", "footstep");
	ClassDB::bind_method(D_METHOD("set_footsteps_path", "path"), &PlayerController::set_footsteps_path);
	ClassDB::bind_method(D_METHOD("get_footsteps_path"), &PlayerController::get_footsteps_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "footsteps_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "AudioStreamPlayer2D"), "set_footsteps_path", "get_footsteps_path");
	ClassDB::bind_method(D_METHOD("set_footstep_sets", "sets"), &PlayerController::set_footstep_sets);
	ClassDB::bind_method(D_METHOD("get_footstep_sets"), &PlayerController::get_footstep_sets);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "footstep_sets"), "set_footstep_sets", "get_footstep_sets");
	ClassDB::bind_method(D_METHOD("set_footstep_surface_edges", "edges"), &PlayerController::set_footstep_surface_edges);
	ClassDB::bind_method(D_METHOD("get_footstep_surface_edges"), &PlayerController::get_footstep_surface_edges);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "footstep_surface_edges"), "set_footstep_surface_edges", "get_footstep_surface_edges");
	ClassDB::bind_method(D_METHOD("set_footstep_spacing", "pixels"), &PlayerController::set_footstep_spacing);
	ClassDB::bind_method(D_METHOD("get_footstep_spacing"), &PlayerController::get_footstep_spacing);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "footstep_spacing"), "set_footstep_spacing", "get_footstep_spacing");
	ADD_GROUP("", "");
	ClassDB::bind_method(D_METHOD("get_footstep_count"), &PlayerController::get_footstep_count);
	ClassDB::bind_method(D_METHOD("surface_at", "x"), &PlayerController::surface_at);

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

	if (!footsteps_path_.is_empty()) {
		AudioStreamPlayer2D *footsteps = get_node<AudioStreamPlayer2D>(footsteps_path_);
		if (footsteps == nullptr) {
			ERR_PRINT("PlayerController: footsteps_path does not point to an AudioStreamPlayer2D; he walks in silence.");
		}
		footsteps_.set(footsteps);
	}

	if (!sprite_path_.is_empty()) {
		AnimatedSprite2D *sprite = get_node<AnimatedSprite2D>(sprite_path_);
		const Ref<SpriteFrames> frames = sprite != nullptr ? sprite->get_sprite_frames() : Ref<SpriteFrames>();
		const bool complete = frames.is_valid() && frames->has_animation("idle") && frames->has_animation("walk") && frames->has_animation("jump") && frames->has_animation("fall");
		if (complete) {
			sprite_.set(sprite);
		} else {
			ERR_PRINT("PlayerController: sprite_path needs an AnimatedSprite2D with idle, walk, jump and fall animations.");
		}
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
	const float previous_x = get_global_position().x;
	const core::StepResult result = core::step(state_, params_, input, core::Vec2{ velocity.x, velocity.y }, contact, static_cast<float>(p_delta));

	set_velocity(Vector2(result.velocity.x, result.velocity.y));
	move_and_slide();
	contact_stale_ = false;

	update_facing(input.axis);
	update_sprite(get_global_position().x - previous_x, static_cast<float>(p_delta));
	update_footsteps(get_global_position().x - previous_x, result.landed);

	if (result.landed) {
		// For the exported-route driver, which hops the moment the sailor lands, as a player climbing does.
		print_verbose("dagon: landed");
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
		return;
	}
	// A cinematic may have moved or tilted him, and a clip stopped early may not have put him back.
	if (Node2D *visual = visual_.get()) {
		visual->set_position(Vector2());
		visual->set_rotation(0.0f);
	}
}

void PlayerController::teleport(const Vector2 &p_position) {
	set_global_position(p_position);
	set_velocity(Vector2());
	state_ = core::MoveState{};
	contact_stale_ = true;
}

void PlayerController::update_sprite(float p_moved_pixels, float p_delta) {
	AnimatedSprite2D *sprite = sprite_.get();
	if (sprite == nullptr) {
		return;
	}

	const bool grounded = is_on_floor();
	airborne_time_ = grounded ? 0.0f : airborne_time_ + p_delta;
	const core::BodyPose pose = core::select_body_pose(grounded, p_moved_pixels, get_velocity().y, airborne_time_);

	switch (pose) {
		case core::BodyPose::Walk: {
			if (!was_walking_) {
				// Start on the passing frame, the closest match to the standing pose.
				walk_distance_ = 2.0f * walk_pixels_per_frame_;
				sprite->set_animation("walk");
				sprite->pause();
			}
			walk_distance_ += std::abs(p_moved_pixels);
			const int frame_count = sprite->get_sprite_frames()->get_frame_count("walk");
			sprite->set_frame(core::walk_frame_index(walk_distance_, walk_pixels_per_frame_, frame_count));
			break;
		}
		case core::BodyPose::Idle:
			if (sprite->get_animation() != StringName("idle") || !sprite->is_playing()) {
				sprite->play("idle");
			}
			sprite->set_speed_scale(idle_speed_);
			break;
		case core::BodyPose::Jump:
		case core::BodyPose::Fall: {
			const StringName name = pose == core::BodyPose::Jump ? "jump" : "fall";
			if (sprite->get_animation() != name) {
				sprite->set_animation(name);
				sprite->pause();
			}
			break;
		}
	}
	was_walking_ = pose == core::BodyPose::Walk;
}

int PlayerController::surface_at(float p_x) const {
	int surface = 0;
	for (int i = 0; i < footstep_surface_edges_.size(); i++) {
		if (p_x >= footstep_surface_edges_[i]) {
			surface = i + 1;
		}
	}
	return surface;
}

// A step each time he has walked its length on the ground, the first soon after he sets off, and one on landing.
void PlayerController::update_footsteps(float p_moved_pixels, bool p_landed) {
	if (p_landed) {
		play_footstep(true);
		footstep_distance_ = 0.0f;
		return;
	}
	if (!is_on_floor() || std::abs(p_moved_pixels) < 0.01f) {
		footstep_distance_ = footstep_spacing_ * 0.6f;
		return;
	}
	footstep_distance_ += std::abs(p_moved_pixels);
	if (footstep_distance_ >= footstep_spacing_) {
		footstep_distance_ -= footstep_spacing_;
		play_footstep(false);
	}
}

void PlayerController::play_footstep(bool p_landing) {
	AudioStreamPlayer2D *footsteps = footsteps_.get();
	if (footsteps == nullptr) {
		return;
	}
	const int surface = surface_at(static_cast<float>(get_global_position().x));
	const Array variants = surface < footstep_sets_.size() ? Array(footstep_sets_[surface]) : Array();
	if (variants.is_empty()) {
		return;
	}
	// A small fixed-seed generator: the same walk sounds the same, and no step repeats the one before.
	footstep_seed_ = footstep_seed_ * 1664525u + 1013904223u;
	const int steps = variants.size() > 1 ? variants.size() - 1 : 1;
	const int pick = p_landing && variants.size() > 1 ? variants.size() - 1 : static_cast<int>((footstep_seed_ >> 16) % static_cast<uint32_t>(steps));
	const Ref<AudioStream> stream = variants[pick];
	if (stream.is_null()) {
		return;
	}
	footsteps->set_stream(stream);
	footsteps->set_pitch_scale(0.94f + 0.12f * static_cast<float>((footstep_seed_ >> 8) & 0xff) / 255.0f);
	footsteps->play();
	footstep_count_++;
}

void PlayerController::update_facing(float p_axis) {
	if (p_axis == 0.0f) {
		return;
	}
	face(p_axis > 0.0f ? 1 : -1);
}

void PlayerController::face(int p_direction) {
	const int facing = p_direction < 0 ? -1 : 1;
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
