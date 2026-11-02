#pragma once

#include "interactable.hpp"
#include "node_ref.hpp"
#include "player_controller.hpp"

#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <vector>

namespace dagon {

// The player's sensor. Focus is recomputed every physics frame, so a focused object that is
// disabled, consumed or freed loses focus within one frame, with no extra signals.
class Interactor : public godot::Area2D {
	GDCLASS(Interactor, godot::Area2D)

public:
	void _ready() override;
	void _physics_process(double p_delta) override;
	void _unhandled_input(const godot::Ref<godot::InputEvent> &p_event) override;

	Interactable *get_focus() const { return focus_.get(); }

	void set_action_interact(const godot::StringName &p_value) { action_interact_ = p_value; }
	godot::StringName get_action_interact() const { return action_interact_; }

protected:
	static void _bind_methods();

private:
	void on_area_entered(godot::Area2D *p_area);
	void on_area_exited(godot::Area2D *p_area);
	void update_focus();
	Interactable *nearest_available();

	std::vector<NodeRef<Interactable>> candidates_;
	NodeRef<Interactable> focus_;
	bool has_focus_ = false;
	NodeRef<PlayerController> player_;
	godot::StringName action_interact_ = "interact";
	bool input_action_valid_ = false;
};

} // namespace dagon
