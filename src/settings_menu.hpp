#pragma once

#include "core/settings_data.hpp"
#include "node_ref.hpp"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/h_slider.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/string.hpp>

#include <array>

namespace dagon {

// Volumes, keyboard bindings and Restore Defaults. Every change is saved and applied at once.
class SettingsMenu : public godot::Control {
	GDCLASS(SettingsMenu, godot::Control)

public:
	void _ready() override;
	void _input(const godot::Ref<godot::InputEvent> &p_event) override;

	void open();
	// Closes one level: a conflict first, then the menu. A capture cancels through _input.
	void back();

	void begin_capture(int p_action);
	void swap_conflict();
	void cancel_conflict();
	void restore_defaults();
	void set_music_volume(double p_value);
	void set_effects_volume(double p_value);

	bool is_capturing() const { return state_ == State::Capturing; }
	bool has_conflict() const { return state_ == State::Conflict; }

	void set_music_slider_path(const godot::NodePath &p_value) { music_slider_path_ = p_value; }
	godot::NodePath get_music_slider_path() const { return music_slider_path_; }
	void set_effects_slider_path(const godot::NodePath &p_value) { effects_slider_path_ = p_value; }
	godot::NodePath get_effects_slider_path() const { return effects_slider_path_; }
	void set_key_button_paths(const godot::Array &p_value) { key_button_paths_ = p_value; }
	godot::Array get_key_button_paths() const { return key_button_paths_; }
	void set_message_label_path(const godot::NodePath &p_value) { message_label_path_ = p_value; }
	godot::NodePath get_message_label_path() const { return message_label_path_; }
	void set_conflict_row_path(const godot::NodePath &p_value) { conflict_row_path_ = p_value; }
	godot::NodePath get_conflict_row_path() const { return conflict_row_path_; }
	void set_swap_button_path(const godot::NodePath &p_value) { swap_button_path_ = p_value; }
	godot::NodePath get_swap_button_path() const { return swap_button_path_; }

protected:
	static void _bind_methods();

private:
	enum class State {
		Idle,
		Capturing,
		Conflict,
	};

	void capture_key(int p_key);
	void cancel_capture();
	void finish_capture();
	void commit();
	void refresh_controls();
	void set_message(const godot::String &p_text);
	void set_conflict_row_visible(bool p_visible);
	godot::String action_label(core::GameAction p_action) const;

	godot::NodePath music_slider_path_;
	godot::NodePath effects_slider_path_;
	godot::Array key_button_paths_;
	godot::NodePath message_label_path_;
	godot::NodePath conflict_row_path_;
	godot::NodePath swap_button_path_;

	NodeRef<godot::HSlider> music_slider_;
	NodeRef<godot::HSlider> effects_slider_;
	std::array<NodeRef<godot::Button>, core::GAME_ACTION_COUNT> key_buttons_;
	NodeRef<godot::Label> message_label_;
	NodeRef<godot::Control> conflict_row_;
	NodeRef<godot::Button> swap_button_;

	core::Settings settings_;
	// A write failed, so settings_ is newer than the file and must not be replaced by it.
	bool unsaved_ = false;
	State state_ = State::Idle;
	core::GameAction capture_action_ = core::GameAction::MoveLeft;
	core::GameAction conflict_other_ = core::GameAction::MoveLeft;
};

} // namespace dagon
