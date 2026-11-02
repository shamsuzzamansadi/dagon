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

protected:
	static void _bind_methods();

private:
	godot::Vector2 desired_position(const godot::Node2D &p_target) const;

	godot::NodePath target_path_;
	NodeRef<godot::Node2D> target_;
	float look_ahead_ = 24.0f;
	float vertical_offset_ = -40.0f;
};

} // namespace dagon
