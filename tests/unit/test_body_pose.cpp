#include "core/body_pose.hpp"

#include "doctest.h"

using dagon::core::BodyPose;
using dagon::core::FALL_POSE_DELAY;
using dagon::core::select_body_pose;
using dagon::core::walk_frame_index;

TEST_SUITE("body pose") {
	TEST_CASE("idle when grounded and not moving, even while pushing against a wall") {
		CHECK(select_body_pose(true, 0.0f, 0.0f, 0.0f) == BodyPose::Idle);
	}

	TEST_CASE("walk when grounded and moving in either direction") {
		CHECK(select_body_pose(true, 1.2f, 0.0f, 0.0f) == BodyPose::Walk);
		CHECK(select_body_pose(true, -1.2f, 0.0f, 0.0f) == BodyPose::Walk);
	}

	TEST_CASE("jump while rising") {
		CHECK(select_body_pose(false, 0.0f, -100.0f, 0.0f) == BodyPose::Jump);
	}

	TEST_CASE("a brief airborne moment keeps the walk pose, so a slope crest does not flicker") {
		CHECK(select_body_pose(false, 1.0f, 10.0f, FALL_POSE_DELAY * 0.5f) == BodyPose::Walk);
	}

	TEST_CASE("fall after the delay") {
		CHECK(select_body_pose(false, 1.0f, 10.0f, FALL_POSE_DELAY) == BodyPose::Fall);
	}
}

TEST_SUITE("walk frames") {
	TEST_CASE("advance one frame per stride increment and wrap") {
		CHECK(walk_frame_index(0.0f, 4.0f, 8) == 0);
		CHECK(walk_frame_index(3.9f, 4.0f, 8) == 0);
		CHECK(walk_frame_index(4.0f, 4.0f, 8) == 1);
		CHECK(walk_frame_index(28.0f, 4.0f, 8) == 7);
		CHECK(walk_frame_index(32.0f, 4.0f, 8) == 0);
	}

	TEST_CASE("depends on distance only: the same distance gives the same frame at any speed") {
		float slow = 0.0f;
		for (int i = 0; i < 100; i++) {
			slow += 0.5f;
		}
		CHECK(walk_frame_index(slow, 4.0f, 8) == walk_frame_index(50.0f, 4.0f, 8));
	}

	TEST_CASE("invalid settings are safe") {
		CHECK(walk_frame_index(10.0f, 0.0f, 8) == 0);
		CHECK(walk_frame_index(10.0f, 4.0f, 0) == 0);
	}
}
