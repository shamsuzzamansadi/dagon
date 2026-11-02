#include "core/movement.hpp"

#include <algorithm>
#include <cmath>

namespace dagon::core {

namespace {

float move_toward(float p_from, float p_to, float p_max_delta) {
	if (std::abs(p_to - p_from) <= p_max_delta) {
		return p_to;
	}
	return p_from + std::copysign(p_max_delta, p_to - p_from);
}

} // namespace

StepResult step(MoveState &p_state, const MoveParams &p_params, const MoveInput &p_input, Vec2 p_velocity, FloorContact p_contact, float p_delta) {
	const bool grounded = p_contact == FloorContact::Grounded;

	StepResult result;
	result.landed = grounded && !p_state.was_on_floor;
	p_state.was_on_floor = grounded;

	p_state.coyote_timer = grounded ? p_params.coyote_time : std::max(0.0f, p_state.coyote_timer - p_delta);
	p_state.buffer_timer = p_input.jump_pressed ? p_params.jump_buffer_time : std::max(0.0f, p_state.buffer_timer - p_delta);

	// Variable jump height: runs before a new jump can start, so a jump that
	// begins on this step keeps its full speed for at least one step.
	if (p_state.jump_active) {
		if (p_velocity.y >= 0.0f) {
			p_state.jump_active = false;
		} else if (!p_input.jump_held) {
			p_velocity.y *= p_params.jump_cut;
			p_state.jump_active = false;
		}
	}

	if (p_state.buffer_timer > 0.0f && p_state.coyote_timer > 0.0f) {
		p_velocity.y = -p_params.jump_velocity;
		p_state.buffer_timer = 0.0f;
		p_state.coyote_timer = 0.0f; // Spent; this is what prevents a double jump.
		p_state.jump_active = true;
		result.jumped = true;
	} else if (grounded) {
		p_velocity.y = std::min(p_velocity.y, 0.0f);
	} else {
		p_velocity.y = std::min(p_velocity.y + p_params.gravity * p_delta, p_params.max_fall_speed);
	}

	const float axis = std::clamp(p_input.axis, -1.0f, 1.0f);
	const float base_rate = axis != 0.0f ? p_params.acceleration : p_params.deceleration;
	const float rate = grounded ? base_rate : base_rate * p_params.air_control;
	p_velocity.x = move_toward(p_velocity.x, axis * p_params.walk_speed, rate * p_delta);

	result.velocity = p_velocity;
	return result;
}

void clear_jump_intent(MoveState &p_state) {
	p_state.buffer_timer = 0.0f;
}

} // namespace dagon::core
