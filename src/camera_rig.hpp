#pragma once

#include "node_ref.hpp"

#include <godot_cpp/classes/camera2d.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

namespace dagon {

// Follows a target with a look-ahead. Smoothing and level limits are the
// built-in Camera2D properties, set in the scene.
class CameraRig : public godot::Camera2D {
	GDCLASS(CameraRig, godot::Camera2D)

public:
	void _ready() override;
	void _process(double p_delta) override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	void set_target_path(const godot::NodePath &p_value) { target_path_ = p_value; }
	godot::NodePath get_target_path() const { return target_path_; }
	void set_look_ahead(float p_value) { look_ahead_ = p_value; }
	float get_look_ahead() const { return look_ahead_; }
	void set_vertical_offset(float p_value) { vertical_offset_ = p_value; }
	float get_vertical_offset() const { return vertical_offset_; }
	void set_pixel_lock(bool p_value) { pixel_lock_ = p_value; }
	bool is_pixel_lock() const { return pixel_lock_; }
	void set_lock_speed(float p_value) { lock_speed_ = p_value; }
	float get_lock_speed() const { return lock_speed_; }

protected:
	static void _bind_methods();

private:
	godot::Vector2 desired_offset(const godot::Node2D &p_target) const;
	void place_locked(const godot::Node2D &p_target, float p_delta);

	godot::NodePath target_path_;
	NodeRef<godot::Node2D> target_;
	float look_ahead_ = 24.0f;
	float vertical_offset_ = -40.0f;

	// Pixel lock keeps the camera a whole number of pixels from the target. Otherwise the target
	// and a smoothed camera round separately and the character flickers by a pixel on screen.
	bool pixel_lock_ = false;
	float lock_speed_ = 2.5f;
	godot::Vector2 locked_offset_;
};

} // namespace dagon
