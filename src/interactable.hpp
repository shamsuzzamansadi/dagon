#pragma once

#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>

namespace dagon {

// Something the player can examine. try_interact() is the single guard against duplicate activation.
class Interactable : public godot::Area2D {
	GDCLASS(Interactable, godot::Area2D)

public:
	void _physics_process(double p_delta) override;

	// False if disabled, already consumed or cooling down. On true, emits interacted.
	bool try_interact();
	// The same check, with no side effects.
	bool is_available() const;

	void set_interaction_id(const godot::StringName &p_value) { interaction_id_ = p_value; }
	godot::StringName get_interaction_id() const { return interaction_id_; }
	void set_prompt(const godot::String &p_value) { prompt_ = p_value; }
	godot::String get_prompt() const { return prompt_; }
	void set_caption(const godot::String &p_value) { caption_ = p_value; }
	godot::String get_caption() const { return caption_; }
	void set_one_shot(bool p_value) { one_shot_ = p_value; }
	bool is_one_shot() const { return one_shot_; }
	void set_enabled(bool p_value) { enabled_ = p_value; }
	bool is_enabled() const { return enabled_; }
	void set_cooldown(float p_value) { cooldown_ = p_value; }
	float get_cooldown() const { return cooldown_; }

protected:
	static void _bind_methods();

private:
	godot::StringName interaction_id_;
	godot::String prompt_ = "Examine";
	godot::String caption_;
	bool one_shot_ = false;
	bool enabled_ = true;
	float cooldown_ = 0.4f;

	bool consumed_ = false;
	float cooldown_left_ = 0.0f;
};

} // namespace dagon
