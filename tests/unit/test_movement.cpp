#include "core/movement.hpp"

#include "doctest.h"

using dagon::core::clear_jump_intent;
using dagon::core::FloorContact;
using dagon::core::MoveInput;
using dagon::core::MoveParams;
using dagon::core::MoveState;
using dagon::core::step;
using dagon::core::StepResult;
using dagon::core::Vec2;

namespace {

constexpr float DT = 1.0f / 60.0f;

MoveInput walk(float p_axis) {
	MoveInput input;
	input.axis = p_axis;
	return input;
}

MoveInput press_jump() {
	MoveInput input;
	input.jump_pressed = true;
	input.jump_held = true;
	return input;
}

MoveInput hold_jump() {
	MoveInput input;
	input.jump_held = true;
	return input;
}

// A state that has been standing on the floor for a while.
MoveState standing(const MoveParams &p_params) {
	MoveState state;
	step(state, p_params, MoveInput{}, Vec2{}, FloorContact::Grounded, DT);
	return state;
}

} // namespace

TEST_SUITE("horizontal") {
	TEST_CASE("accelerates to the speed cap and does not exceed it") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity;
		for (int i = 0; i < 120; i++) {
			velocity = step(state, params, walk(1.0f), velocity, FloorContact::Grounded, DT).velocity;
			CHECK(velocity.x <= doctest::Approx(params.walk_speed));
		}
		CHECK(velocity.x == doctest::Approx(params.walk_speed));
	}

	TEST_CASE("acceleration is gradual, not instant") {
		const MoveParams params;
		MoveState state = standing(params);
		const StepResult result = step(state, params, walk(1.0f), Vec2{}, FloorContact::Grounded, DT);
		CHECK(result.velocity.x == doctest::Approx(params.acceleration * DT));
		CHECK(result.velocity.x < params.walk_speed);
	}

	TEST_CASE("decelerates to exactly zero with no input") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity{ params.walk_speed, 0.0f };
		for (int i = 0; i < 60; i++) {
			velocity = step(state, params, MoveInput{}, velocity, FloorContact::Grounded, DT).velocity;
		}
		CHECK(velocity.x == 0.0f);
	}

	TEST_CASE("moves left with negative axis") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity;
		for (int i = 0; i < 120; i++) {
			velocity = step(state, params, walk(-1.0f), velocity, FloorContact::Grounded, DT).velocity;
		}
		CHECK(velocity.x == doctest::Approx(-params.walk_speed));
	}

	TEST_CASE("axis outside -1..1 cannot exceed the speed cap") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity;
		for (int i = 0; i < 120; i++) {
			velocity = step(state, params, walk(5.0f), velocity, FloorContact::Grounded, DT).velocity;
		}
		CHECK(velocity.x == doctest::Approx(params.walk_speed));
	}

	TEST_CASE("air control is weaker than ground control") {
		const MoveParams params;
		MoveState ground = standing(params);
		MoveState air;
		const float ground_step = step(ground, params, walk(1.0f), Vec2{}, FloorContact::Grounded, DT).velocity.x;
		const float air_step = step(air, params, walk(1.0f), Vec2{}, FloorContact::Airborne, DT).velocity.x;
		CHECK(air_step == doctest::Approx(ground_step * params.air_control));
	}

	TEST_CASE("post-collision velocity is honoured: a wall stop is not undone") {
		// Godot zeroed x on a wall hit; the next step must build from 0, not from a stored speed.
		const MoveParams params;
		MoveState state = standing(params);
		const StepResult result = step(state, params, walk(1.0f), Vec2{ 0.0f, 0.0f }, FloorContact::Grounded, DT);
		CHECK(result.velocity.x == doctest::Approx(params.acceleration * DT));
	}
}

TEST_SUITE("gravity") {
	TEST_CASE("applies while airborne") {
		const MoveParams params;
		MoveState state;
		const StepResult result = step(state, params, MoveInput{}, Vec2{}, FloorContact::Airborne, DT);
		CHECK(result.velocity.y == doctest::Approx(params.gravity * DT));
	}

	TEST_CASE("fall speed is clamped") {
		const MoveParams params;
		MoveState state;
		Vec2 velocity;
		for (int i = 0; i < 600; i++) {
			velocity = step(state, params, MoveInput{}, velocity, FloorContact::Airborne, DT).velocity;
			CHECK(velocity.y <= doctest::Approx(params.max_fall_speed));
		}
		CHECK(velocity.y == doctest::Approx(params.max_fall_speed));
	}

	TEST_CASE("grounded clears downward velocity") {
		const MoveParams params;
		MoveState state = standing(params);
		const StepResult result = step(state, params, MoveInput{}, Vec2{ 0.0f, 100.0f }, FloorContact::Grounded, DT);
		CHECK(result.velocity.y == 0.0f);
	}

	TEST_CASE("a ceiling bonk reported by the body starts the fall from zero") {
		const MoveParams params;
		MoveState state;
		const StepResult result = step(state, params, hold_jump(), Vec2{ 0.0f, 0.0f }, FloorContact::Airborne, DT);
		CHECK(result.velocity.y == doctest::Approx(params.gravity * DT));
	}
}

TEST_SUITE("jump") {
	TEST_CASE("jumps from the ground at jump velocity") {
		const MoveParams params;
		MoveState state = standing(params);
		const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT);
		CHECK(result.jumped);
		CHECK(result.velocity.y == doctest::Approx(-params.jump_velocity));
	}

	TEST_CASE("cannot jump in mid-air without coyote time") {
		const MoveParams params;
		MoveState state;
		const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT);
		CHECK_FALSE(result.jumped);
		CHECK(result.velocity.y > 0.0f);
	}

	TEST_CASE("coyote time allows a jump just after leaving a ledge") {
		const MoveParams params;
		MoveState state = standing(params);
		step(state, params, MoveInput{}, Vec2{}, FloorContact::Airborne, DT);
		const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT);
		CHECK(result.jumped);
	}

	TEST_CASE("coyote time expires") {
		const MoveParams params;
		MoveState state = standing(params);
		const int steps = static_cast<int>(params.coyote_time / DT) + 2;
		for (int i = 0; i < steps; i++) {
			step(state, params, MoveInput{}, Vec2{}, FloorContact::Airborne, DT);
		}
		const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT);
		CHECK_FALSE(result.jumped);
	}

	TEST_CASE("no double jump") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity = step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT).velocity;
		// One step later we are airborne, inside what would be the coyote window.
		const StepResult second = step(state, params, press_jump(), velocity, FloorContact::Airborne, DT);
		CHECK_FALSE(second.jumped);
	}

	TEST_CASE("holding jump does not repeat it on landing") {
		const MoveParams params;
		MoveState state = standing(params);
		step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT);
		for (int i = 0; i < 30; i++) {
			step(state, params, hold_jump(), Vec2{ 0.0f, 10.0f }, FloorContact::Airborne, DT);
		}
		const StepResult landing = step(state, params, hold_jump(), Vec2{ 0.0f, 10.0f }, FloorContact::Grounded, DT);
		CHECK(landing.landed);
		CHECK_FALSE(landing.jumped);
	}

	TEST_CASE("jump buffer fires on landing") {
		const MoveParams params;
		MoveState state;
		step(state, params, press_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Airborne, DT);
		const StepResult landing = step(state, params, hold_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Grounded, DT);
		CHECK(landing.landed);
		CHECK(landing.jumped);
		CHECK(landing.velocity.y == doctest::Approx(-params.jump_velocity));
	}

	TEST_CASE("jump buffer expires") {
		const MoveParams params;
		MoveState state;
		step(state, params, press_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Airborne, DT);
		const int steps = static_cast<int>(params.jump_buffer_time / DT) + 2;
		for (int i = 0; i < steps; i++) {
			step(state, params, MoveInput{}, Vec2{ 0.0f, 50.0f }, FloorContact::Airborne, DT);
		}
		const StepResult landing = step(state, params, MoveInput{}, Vec2{ 0.0f, 50.0f }, FloorContact::Grounded, DT);
		CHECK(landing.landed);
		CHECK_FALSE(landing.jumped);
	}

	TEST_CASE("releasing jump early cuts upward speed once") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity = step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT).velocity;
		const float before_release = velocity.y;
		velocity = step(state, params, MoveInput{}, velocity, FloorContact::Airborne, DT).velocity;
		CHECK(velocity.y == doctest::Approx(before_release * params.jump_cut + params.gravity * DT));
		const float after_cut = velocity.y;
		velocity = step(state, params, MoveInput{}, velocity, FloorContact::Airborne, DT).velocity;
		CHECK(velocity.y == doctest::Approx(after_cut + params.gravity * DT));
	}

	TEST_CASE("holding jump is not cut") {
		const MoveParams params;
		MoveState state = standing(params);
		Vec2 velocity = step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT).velocity;
		const float before = velocity.y;
		velocity = step(state, params, hold_jump(), velocity, FloorContact::Airborne, DT).velocity;
		CHECK(velocity.y == doctest::Approx(before + params.gravity * DT));
	}

	TEST_CASE("cleared intent cannot fire later") {
		const MoveParams params;
		MoveState state;
		step(state, params, press_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Airborne, DT);
		clear_jump_intent(state);
		const StepResult landing = step(state, params, MoveInput{}, Vec2{ 0.0f, 50.0f }, FloorContact::Grounded, DT);
		CHECK_FALSE(landing.jumped);
	}
}

TEST_SUITE("zero forgiveness windows") {
	// Zero disables only that forgiveness window. A fresh press on the ground always jumps.
	MoveParams with_times(float p_coyote_time, float p_jump_buffer_time) {
		MoveParams params;
		params.coyote_time = p_coyote_time;
		params.jump_buffer_time = p_jump_buffer_time;
		return params;
	}

	TEST_CASE("grounded jump works when either or both windows are zero") {
		const float times[][2] = { { 0.0f, 0.1f }, { 0.1f, 0.0f }, { 0.0f, 0.0f } };
		for (const auto &pair : times) {
			CAPTURE(pair[0]);
			CAPTURE(pair[1]);
			const MoveParams params = with_times(pair[0], pair[1]);
			MoveState state = standing(params);
			const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT);
			CHECK(result.jumped);
			CHECK(result.velocity.y == doctest::Approx(-params.jump_velocity));
		}
	}

	TEST_CASE("zero coyote time rejects a jump on the first airborne step") {
		const MoveParams params = with_times(0.0f, 0.1f);
		MoveState state = standing(params);
		const StepResult late = step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT);
		CHECK_FALSE(late.jumped);
	}

	TEST_CASE("zero coyote time keeps jump buffering") {
		const MoveParams params = with_times(0.0f, 0.1f);
		MoveState state;
		step(state, params, press_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Airborne, DT);
		const StepResult landing = step(state, params, hold_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Grounded, DT);
		CHECK(landing.jumped);
	}

	TEST_CASE("zero buffering does not retain an airborne request") {
		const MoveParams params = with_times(0.1f, 0.0f);
		MoveState state;
		const StepResult airborne = step(state, params, press_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Airborne, DT);
		CHECK_FALSE(airborne.jumped);
		const StepResult landing = step(state, params, hold_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Grounded, DT);
		CHECK(landing.landed);
		CHECK_FALSE(landing.jumped);
	}

	TEST_CASE("zero buffering keeps coyote time") {
		const MoveParams params = with_times(0.1f, 0.0f);
		MoveState state = standing(params);
		step(state, params, MoveInput{}, Vec2{}, FloorContact::Airborne, DT);
		const StepResult late = step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT);
		CHECK(late.jumped);
	}

	TEST_CASE("both zero: only a press on the ground jumps") {
		const MoveParams params = with_times(0.0f, 0.0f);
		MoveState state = standing(params);
		CHECK_FALSE(step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT).jumped);
		const StepResult landing = step(state, params, hold_jump(), Vec2{ 0.0f, 50.0f }, FloorContact::Grounded, DT);
		CHECK(landing.landed);
		CHECK_FALSE(landing.jumped);
		CHECK(step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT).jumped);
	}

	TEST_CASE("no double jump with either or both windows zero") {
		const float times[][2] = { { 0.0f, 0.1f }, { 0.1f, 0.0f }, { 0.0f, 0.0f } };
		for (const auto &pair : times) {
			CAPTURE(pair[0]);
			CAPTURE(pair[1]);
			const MoveParams params = with_times(pair[0], pair[1]);
			MoveState state = standing(params);
			const Vec2 velocity = step(state, params, press_jump(), Vec2{}, FloorContact::Grounded, DT).velocity;
			CHECK_FALSE(step(state, params, press_jump(), velocity, FloorContact::Airborne, DT).jumped);
		}
	}

	TEST_CASE("unknown contact grants no jump with either or both windows zero") {
		const float times[][2] = { { 0.0f, 0.1f }, { 0.1f, 0.0f }, { 0.0f, 0.0f } };
		for (const auto &pair : times) {
			CAPTURE(pair[0]);
			CAPTURE(pair[1]);
			const MoveParams params = with_times(pair[0], pair[1]);
			MoveState state; // teleport() resets to this.
			CHECK_FALSE(step(state, params, press_jump(), Vec2{}, FloorContact::Unknown, DT).jumped);
		}
	}

	TEST_CASE("control lock: no input means no jump with either or both windows zero") {
		const float times[][2] = { { 0.0f, 0.1f }, { 0.1f, 0.0f }, { 0.0f, 0.0f } };
		for (const auto &pair : times) {
			CAPTURE(pair[0]);
			CAPTURE(pair[1]);
			const MoveParams params = with_times(pair[0], pair[1]);
			MoveState state = standing(params);
			CHECK_FALSE(step(state, params, MoveInput{}, Vec2{}, FloorContact::Grounded, DT).jumped);
		}
	}
}

TEST_SUITE("landing") {
	TEST_CASE("fires once, on the first grounded step") {
		const MoveParams params;
		MoveState state;
		step(state, params, MoveInput{}, Vec2{}, FloorContact::Airborne, DT);
		CHECK(step(state, params, MoveInput{}, Vec2{}, FloorContact::Grounded, DT).landed);
		CHECK_FALSE(step(state, params, MoveInput{}, Vec2{}, FloorContact::Grounded, DT).landed);
	}
}

TEST_SUITE("unknown contact after a teleport") {
	TEST_CASE("grants no jump from a reset state") {
		const MoveParams params;
		MoveState state; // teleport() resets to this.
		const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Unknown, DT);
		CHECK_FALSE(result.jumped);
	}

	TEST_CASE("does not refresh coyote time") {
		const MoveParams params;
		MoveState state;
		step(state, params, MoveInput{}, Vec2{}, FloorContact::Unknown, DT);
		CHECK(state.coyote_timer == 0.0f);
		const StepResult result = step(state, params, press_jump(), Vec2{}, FloorContact::Airborne, DT);
		CHECK_FALSE(result.jumped);
	}

	TEST_CASE("emits no landing and leaves was_on_floor false") {
		const MoveParams params;
		MoveState state;
		const StepResult result = step(state, params, MoveInput{}, Vec2{}, FloorContact::Unknown, DT);
		CHECK_FALSE(result.landed);
		CHECK_FALSE(state.was_on_floor);
	}

	TEST_CASE("applies gravity like airborne") {
		const MoveParams params;
		MoveState state;
		const StepResult result = step(state, params, MoveInput{}, Vec2{}, FloorContact::Unknown, DT);
		CHECK(result.velocity.y == doctest::Approx(params.gravity * DT));
	}

	TEST_CASE("buffers a jump that fires on genuine contact") {
		const MoveParams params;
		MoveState state;
		const StepResult unknown = step(state, params, press_jump(), Vec2{}, FloorContact::Unknown, DT);
		CHECK_FALSE(unknown.jumped);
		const StepResult landing = step(state, params, hold_jump(), unknown.velocity, FloorContact::Grounded, DT);
		CHECK(landing.landed);
		CHECK(landing.jumped);
	}

	TEST_CASE("the first real contact counts as one landing") {
		const MoveParams params;
		MoveState state;
		step(state, params, MoveInput{}, Vec2{}, FloorContact::Unknown, DT);
		CHECK(step(state, params, MoveInput{}, Vec2{}, FloorContact::Grounded, DT).landed);
		CHECK_FALSE(step(state, params, MoveInput{}, Vec2{}, FloorContact::Grounded, DT).landed);
	}
}
