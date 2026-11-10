#pragma once

#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/variant/string_name.hpp>

namespace dagon {

// A volume the player walks into. It never latches itself: whether a trigger is used up is
// GameDirector's decision, made only when it accepts the event.
class StoryTrigger : public godot::Area2D {
	GDCLASS(StoryTrigger, godot::Area2D)

public:
	void _ready() override;

	bool is_player_inside() const;

	void set_trigger_id(const godot::StringName &p_value) { trigger_id_ = p_value; }
	godot::StringName get_trigger_id() const { return trigger_id_; }
	void set_enabled(bool p_value) { enabled_ = p_value; }
	bool is_enabled() const { return enabled_; }
	// For a background event: a world rebuilt at this beat or later treats it as already past.
	void set_spent_from_beat(int p_value) { spent_from_beat_ = p_value; }
	int get_spent_from_beat() const { return spent_from_beat_; }

protected:
	static void _bind_methods();

private:
	void on_body_entered(godot::Node2D *p_body);

	godot::StringName trigger_id_;
	bool enabled_ = true;
	int spent_from_beat_ = 100; // Never.
};

} // namespace dagon
