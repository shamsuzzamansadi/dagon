#pragma once

#include "core/movement.hpp"
#include "node_ref.hpp"

#include <godot_cpp/classes/animated_sprite2d.hpp>
#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string_name.hpp>

namespace dagon {

class PlayerController : public godot::CharacterBody2D {
	GDCLASS(PlayerController, godot::CharacterBody2D)

public:
	void _ready() override;
	void _physics_process(double p_delta) override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	// While disabled, input is ignored and any buffered jump is forgotten. Gravity still applies.
	void set_control_enabled(bool p_enabled);
	bool is_control_enabled() const { return control_enabled_; }

	// Moves the player and invalidates floor contact until a fresh move_and_slide().
	void teleport(const godot::Vector2 &p_position);

	int get_facing() const { return facing_; }
	// Turns the sailor without moving him, as walking that way would. -1 is left, and 1 is right.
	void face(int p_direction);

	void set_walk_speed(float p_value) { params_.walk_speed = p_value; }
	float get_walk_speed() const { return params_.walk_speed; }
	void set_acceleration(float p_value) { params_.acceleration = p_value; }
	float get_acceleration() const { return params_.acceleration; }
	void set_deceleration(float p_value) { params_.deceleration = p_value; }
	float get_deceleration() const { return params_.deceleration; }
	void set_air_control(float p_value) { params_.air_control = p_value; }
	float get_air_control() const { return params_.air_control; }
	void set_jump_velocity(float p_value) { params_.jump_velocity = p_value; }
	float get_jump_velocity() const { return params_.jump_velocity; }
	void set_jump_cut(float p_value) { params_.jump_cut = p_value; }
	float get_jump_cut() const { return params_.jump_cut; }
	void set_coyote_time(float p_value) { params_.coyote_time = p_value; }
	float get_coyote_time() const { return params_.coyote_time; }
	void set_jump_buffer_time(float p_value) { params_.jump_buffer_time = p_value; }
	float get_jump_buffer_time() const { return params_.jump_buffer_time; }
	void set_max_fall_speed(float p_value) { params_.max_fall_speed = p_value; }
	float get_max_fall_speed() const { return params_.max_fall_speed; }
	void set_gravity_scale(float p_value) { gravity_scale_ = p_value; }
	float get_gravity_scale() const { return gravity_scale_; }

	void set_action_move_left(const godot::StringName &p_value) { action_move_left_ = p_value; }
	godot::StringName get_action_move_left() const { return action_move_left_; }
	void set_action_move_right(const godot::StringName &p_value) { action_move_right_ = p_value; }
	godot::StringName get_action_move_right() const { return action_move_right_; }
	void set_action_jump(const godot::StringName &p_value) { action_jump_ = p_value; }
	godot::StringName get_action_jump() const { return action_jump_; }

	void set_visual_path(const godot::NodePath &p_value) { visual_path_ = p_value; }
	godot::NodePath get_visual_path() const { return visual_path_; }
	void set_sprite_path(const godot::NodePath &p_value) { sprite_path_ = p_value; }
	godot::NodePath get_sprite_path() const { return sprite_path_; }
	void set_walk_pixels_per_frame(float p_value) { walk_pixels_per_frame_ = p_value; }
	float get_walk_pixels_per_frame() const { return walk_pixels_per_frame_; }

protected:
	static void _bind_methods();

private:
	void update_facing(float p_axis);
	void update_sprite(float p_moved_pixels, float p_delta);

	core::MoveParams params_;
	core::MoveState state_;
	float gravity_scale_ = 1.0f;
	float project_gravity_ = 700.0f;
	bool control_enabled_ = true;
	bool input_actions_valid_ = false;
	bool contact_stale_ = false;
	int facing_ = 1;

	godot::StringName action_move_left_ = "move_left";
	godot::StringName action_move_right_ = "move_right";
	godot::StringName action_jump_ = "jump";

	godot::NodePath visual_path_;
	NodeRef<godot::Node2D> visual_;

	// Optional: scenes without a sprite, such as the greybox, skip all of this.
	godot::NodePath sprite_path_;
	NodeRef<godot::AnimatedSprite2D> sprite_;
	float walk_pixels_per_frame_ = 4.0f;
	float walk_distance_ = 0.0f;
	float airborne_time_ = 0.0f;
	bool was_walking_ = false;
};

} // namespace dagon
