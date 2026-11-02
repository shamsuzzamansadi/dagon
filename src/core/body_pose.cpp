#include "core/body_pose.hpp"

#include <cmath>

namespace dagon::core {

BodyPose select_body_pose(bool p_grounded, float p_moved_pixels, float p_velocity_y, float p_airborne_time) {
	const BodyPose ground_pose = std::abs(p_moved_pixels) > 0.01f ? BodyPose::Walk : BodyPose::Idle;
	if (p_grounded) {
		return ground_pose;
	}
	if (p_velocity_y < 0.0f) {
		return BodyPose::Jump;
	}
	return p_airborne_time >= FALL_POSE_DELAY ? BodyPose::Fall : ground_pose;
}

int walk_frame_index(float p_walk_distance, float p_pixels_per_frame, int p_frame_count) {
	if (p_pixels_per_frame <= 0.0f || p_frame_count <= 0) {
		return 0;
	}
	const int steps = static_cast<int>(std::floor(std::abs(p_walk_distance) / p_pixels_per_frame));
	return steps % p_frame_count;
}

} // namespace dagon::core
