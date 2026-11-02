#pragma once

// Plain-C++ movement rules. No Godot headers: this file is compiled into both
// the extension and the native unit-test binary.
//
// Screen coordinates: +x is right, +y is down, so a jump has negative y velocity.
//
// CharacterBody2D owns velocity. MoveState holds only timers and flags, and
// step() receives the post-collision velocity and returns the next one.

namespace dagon::core {

struct Vec2 {
	float x = 0.0f;
	float y = 0.0f;
};

enum class FloorContact {
	Airborne,
	Grounded,
	// Contact has not been measured since a teleport. Treated as airborne for
	// eligibility: no grounded jump, no coyote refresh, no landing.
	Unknown,
};

struct MoveParams {
	float walk_speed = 70.0f;
	float acceleration = 600.0f;
	float deceleration = 800.0f;
	float air_control = 0.6f; // Fraction of acceleration/deceleration while airborne.
	float gravity = 700.0f;
	float jump_velocity = 190.0f; // Upward speed; positive.
	float jump_cut = 0.5f; // Applied to upward speed when jump is released early.
	float coyote_time = 0.1f;
	float jump_buffer_time = 0.1f;
	float max_fall_speed = 320.0f;
};

struct MoveInput {
	float axis = 0.0f; // -1 left, +1 right.
	bool jump_pressed = false; // True only on the step the press happened.
	bool jump_held = false;
};

// Default-constructed state means "airborne with no jump pending".
struct MoveState {
	float coyote_timer = 0.0f;
	float buffer_timer = 0.0f;
	bool was_on_floor = false;
	bool jump_active = false;
};

struct StepResult {
	Vec2 velocity;
	bool jumped = false;
	bool landed = false;
};

StepResult step(MoveState &p_state, const MoveParams &p_params, const MoveInput &p_input, Vec2 p_velocity, FloorContact p_contact, float p_delta);

// Forgets a buffered jump, so input from before a control lock cannot fire during it.
void clear_jump_intent(MoveState &p_state);

} // namespace dagon::core
