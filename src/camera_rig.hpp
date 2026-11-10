#pragma once

#include "node_ref.hpp"

#include <godot_cpp/classes/camera2d.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

namespace dagon {

// Follows a target with a look-ahead, locked to whole pixels. Level limits are
// the built-in Camera2D properties, set in the scene.
class CameraRig : public godot::Camera2D {
	GDCLASS(CameraRig, godot::Camera2D)

public:
	void _ready() override;
	void _process(double p_delta) override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	// What the camera follows now. Clips retarget it through aim_at, by a path, as a method track can hold one.
	void set_target(godot::Node2D *p_target);
	godot::Node2D *get_target() const { return target_.get(); }
	void aim_at(const godot::NodePath &p_path);

	// Screen shake: decays by itself, and stops while the game is paused.
	void add_trauma(float p_amount);
	float get_trauma() const { return trauma_; }

	// Target, zoom, limits and shake all go back to how the scene set them, whatever a clip left behind.
	void restore_view(godot::Node2D *p_target);

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
	void set_max_shake(float p_value) { max_shake_ = p_value; }
	float get_max_shake() const { return max_shake_; }
	void set_trauma_decay(float p_value) { trauma_decay_ = p_value; }
	float get_trauma_decay() const { return trauma_decay_; }

protected:
	static void _bind_methods();

private:
	godot::Vector2 desired_offset(const godot::Node2D &p_target) const;
	void place_locked(const godot::Node2D &p_target, float p_delta);
	void update_shake(float p_delta);

	godot::NodePath target_path_;
	NodeRef<godot::Node2D> target_;
	float look_ahead_ = 24.0f;
	float vertical_offset_ = -40.0f;

	// Pixel lock keeps the camera a whole number of pixels from the target. Otherwise the target
	// and a smoothed camera round separately and the character flickers by a pixel on screen.
	bool pixel_lock_ = true;
	float lock_speed_ = 2.5f;
	godot::Vector2 locked_offset_;

	float max_shake_ = 8.0f;
	float trauma_decay_ = 0.8f;
	float trauma_ = 0.0f;
	float shake_time_ = 0.0f;

	// As the scene set them, for restore_view.
	godot::Vector2 default_zoom_ = godot::Vector2(1, 1);
	int default_limit_left_ = 0;
	int default_limit_top_ = 0;
	int default_limit_right_ = 0;
	int default_limit_bottom_ = 0;
};

} // namespace dagon
