#pragma once

// Plain-C++ rules for choosing the character's animation. No Godot headers.

namespace dagon::core {

enum class BodyPose {
	Idle,
	Walk,
	Jump,
	Fall,
};

// Short airborne moments, such as the crest of a slope, keep the ground pose.
inline constexpr float FALL_POSE_DELAY = 0.08f;

BodyPose select_body_pose(bool p_grounded, float p_moved_pixels, float p_velocity_y, float p_airborne_time);

// The walk cycle is driven by distance travelled, not time. One frame per p_pixels_per_frame
// keeps a planted foot still in the world at any speed.
int walk_frame_index(float p_walk_distance, float p_pixels_per_frame, int p_frame_count);

} // namespace dagon::core
