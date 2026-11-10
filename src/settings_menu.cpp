#include "settings_menu.hpp"

#include "storage.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

namespace dagon {

namespace {

const char *const SAVE_FAILED_MESSAGE = "Could not save settings. They may be lost when you leave.";

} // namespace

void SettingsMenu::_bind_methods() {
	ClassDB::bind_method(D_METHOD("open"), &SettingsMenu::open);
	ClassDB::bind_method(D_METHOD("back"), &SettingsMenu::back);
	ClassDB::bind_method(D_METHOD("begin_capture", "action"), &SettingsMenu::begin_capture);
	ClassDB::bind_method(D_METHOD("swap_conflict"), &SettingsMenu::swap_conflict);
	ClassDB::bind_method(D_METHOD("cancel_conflict"), &SettingsMenu::cancel_conflict);
	ClassDB::bind_method(D_METHOD("restore_defaults"), &SettingsMenu::restore_defaults);
	ClassDB::bind_method(D_METHOD("set_music_volume", "value"), &SettingsMenu::set_music_volume);
	ClassDB::bind_method(D_METHOD("set_effects_volume", "value"), &SettingsMenu::set_effects_volume);
	ClassDB::bind_method(D_METHOD("set_narration_volume", "value"), &SettingsMenu::set_narration_volume);
	ClassDB::bind_method(D_METHOD("toggle_subtitles"), &SettingsMenu::toggle_subtitles);
	ClassDB::bind_method(D_METHOD("toggle_vibration"), &SettingsMenu::toggle_vibration);
	ClassDB::bind_method(D_METHOD("is_capturing"), &SettingsMenu::is_capturing);
	ClassDB::bind_method(D_METHOD("has_conflict"), &SettingsMenu::has_conflict);
	ClassDB::bind_method(D_METHOD("describe_key", "key", "layout_label"), &SettingsMenu::describe_key);

#define DAGON_BIND_PATH(m_name)                                                          \
	ClassDB::bind_method(D_METHOD("set_" #m_name, "path"), &SettingsMenu::set_##m_name); \
	ClassDB::bind_method(D_METHOD("get_" #m_name), &SettingsMenu::get_##m_name);         \
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, #m_name), "set_" #m_name, "get_" #m_name)

	DAGON_BIND_PATH(music_slider_path);
	DAGON_BIND_PATH(effects_slider_path);
	DAGON_BIND_PATH(narration_slider_path);
	DAGON_BIND_PATH(subtitles_button_path);
	DAGON_BIND_PATH(vibration_button_path);
	DAGON_BIND_PATH(message_label_path);
	DAGON_BIND_PATH(conflict_row_path);
	DAGON_BIND_PATH(swap_button_path);

#undef DAGON_BIND_PATH

	ClassDB::bind_method(D_METHOD("set_key_button_paths", "paths"), &SettingsMenu::set_key_button_paths);
	ClassDB::bind_method(D_METHOD("get_key_button_paths"), &SettingsMenu::get_key_button_paths);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "key_button_paths"), "set_key_button_paths", "get_key_button_paths");

	ADD_SIGNAL(MethodInfo("closed"));
}

void SettingsMenu::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	music_slider_.set(get_node<HSlider>(music_slider_path_));
	effects_slider_.set(get_node<HSlider>(effects_slider_path_));
	narration_slider_.set(get_node<HSlider>(narration_slider_path_));
	subtitles_button_.set(get_node<Button>(subtitles_button_path_));
	vibration_button_.set(get_node<Button>(vibration_button_path_));
	message_label_.set(get_node<Label>(message_label_path_));
	conflict_row_.set(get_node<Control>(conflict_row_path_));
	swap_button_.set(get_node<Button>(swap_button_path_));
	if (key_button_paths_.size() != core::GAME_ACTION_COUNT) {
		ERR_PRINT("SettingsMenu: key_button_paths needs one button per rebindable action.");
		return;
	}
	for (int i = 0; i < core::GAME_ACTION_COUNT; i++) {
		key_buttons_[static_cast<std::size_t>(i)].set(get_node<Button>(key_button_paths_[i]));
	}
	set_conflict_row_visible(false);
}

void SettingsMenu::open() {
	if (!unsaved_) {
		settings_ = storage::load_settings();
	}
	state_ = State::Idle;
	set_conflict_row_visible(false);
	show_idle_message();
	refresh_controls();
	focus_current();
}

void SettingsMenu::focus_current() {
	Control *control = music_slider_.get();
	if (state_ == State::Conflict) {
		control = swap_button_.get();
	}
	if (control != nullptr) {
		control->grab_focus();
	}
}

void SettingsMenu::back() {
	if (state_ == State::Conflict) {
		cancel_conflict();
		return;
	}
	if (state_ == State::Capturing) {
		cancel_capture();
		return;
	}
	emit_signal("closed");
}

void SettingsMenu::begin_capture(int p_action) {
	ERR_FAIL_INDEX(p_action, core::GAME_ACTION_COUNT);
	capture_action_ = static_cast<core::GameAction>(p_action);
	state_ = State::Capturing;
	set_conflict_row_visible(false);
	if (Button *button = key_buttons_[static_cast<std::size_t>(p_action)].get()) {
		button->set_text("...");
	}
	set_message(String("Press a key for ") + action_label(capture_action_) + ". " + cancel_keys() + " cancels.");
}

// Runs before the GUI and before MenuController, so a captured key does nothing else.
void SettingsMenu::_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint() || state_ != State::Capturing) {
		return;
	}
	if (p_event->is_action_pressed("ui_cancel")) {
		cancel_capture();
		get_viewport()->set_input_as_handled();
		return;
	}
	const Ref<InputEventKey> key = p_event;
	if (key.is_valid()) {
		if (key->is_pressed() && !key->is_echo()) {
			capture_key(static_cast<int>(key->get_physical_keycode()));
		}
		get_viewport()->set_input_as_handled();
		return;
	}
	const Ref<InputEventMouseButton> mouse = p_event;
	if (mouse.is_valid() && mouse->is_pressed()) {
		cancel_capture();
	}
	// A pad or mouse cannot be bound here, and it must not move focus away mid-capture.
	get_viewport()->set_input_as_handled();
}

void SettingsMenu::capture_key(int p_key) {
	if (p_key == KEY_NONE) {
		set_message(String("That key cannot be used. Press another key, or ") + cancel_keys() + " to cancel.");
		return;
	}
	const core::Assignment assignment = core::assign_key(settings_, capture_action_, p_key);
	switch (assignment.result) {
		case core::AssignResult::Assigned:
			finish_capture();
			commit();
			break;
		case core::AssignResult::Unchanged:
			finish_capture();
			break;
		case core::AssignResult::Reserved:
			set_message(key_label(p_key) + " is kept for the game. Press another key, or " + cancel_keys() + " to cancel.");
			break;
		case core::AssignResult::Conflict:
			conflict_other_ = assignment.other;
			state_ = State::Conflict;
			set_message(key_label(p_key) + " is already " + action_label(conflict_other_) + ". Swap them?");
			set_conflict_row_visible(true);
			if (Button *button = swap_button_.get()) {
				button->grab_focus();
			}
			break;
	}
}

void SettingsMenu::cancel_capture() {
	finish_capture();
}

void SettingsMenu::finish_capture() {
	state_ = State::Idle;
	show_idle_message();
	refresh_controls();
}

void SettingsMenu::swap_conflict() {
	if (state_ != State::Conflict) {
		return;
	}
	core::swap_keys(settings_, capture_action_, conflict_other_);
	cancel_conflict();
	commit();
}

void SettingsMenu::cancel_conflict() {
	if (state_ != State::Conflict) {
		return;
	}
	state_ = State::Idle;
	set_conflict_row_visible(false);
	show_idle_message();
	refresh_controls();
	if (Button *button = key_buttons_[static_cast<std::size_t>(capture_action_)].get()) {
		button->grab_focus();
	}
}

void SettingsMenu::restore_defaults() {
	settings_ = core::Settings{};
	state_ = State::Idle;
	set_conflict_row_visible(false);
	refresh_controls();
	commit();
	if (!unsaved_) {
		set_message("Defaults restored.");
	}
}

void SettingsMenu::set_music_volume(double p_value) {
	settings_.music_volume = static_cast<float>(p_value);
	commit();
}

void SettingsMenu::set_effects_volume(double p_value) {
	settings_.effects_volume = static_cast<float>(p_value);
	commit();
}

void SettingsMenu::set_narration_volume(double p_value) {
	settings_.narration_volume = static_cast<float>(p_value);
	commit();
}

void SettingsMenu::toggle_subtitles() {
	settings_.subtitles = !settings_.subtitles;
	commit();
}

void SettingsMenu::toggle_vibration() {
	settings_.vibration = !settings_.vibration;
	commit();
}

void SettingsMenu::commit() {
	storage::apply_settings(settings_);
	refresh_controls();
	unsaved_ = !storage::save_settings(settings_);
	// A capture or conflict keeps its own instructions. The warning returns when they end.
	if (state_ == State::Idle) {
		show_idle_message();
	}
}

void SettingsMenu::show_idle_message() {
	set_message(unsaved_ ? SAVE_FAILED_MESSAGE : "");
}

void SettingsMenu::refresh_controls() {
	if (HSlider *slider = music_slider_.get()) {
		slider->set_value_no_signal(settings_.music_volume);
	}
	if (HSlider *slider = effects_slider_.get()) {
		slider->set_value_no_signal(settings_.effects_volume);
	}
	if (HSlider *slider = narration_slider_.get()) {
		slider->set_value_no_signal(settings_.narration_volume);
	}
	if (Button *button = subtitles_button_.get()) {
		button->set_text(settings_.subtitles ? "Subtitles: On" : "Subtitles: Off");
	}
	if (Button *button = vibration_button_.get()) {
		button->set_text(settings_.vibration ? "Controller vibration: On" : "Controller vibration: Off");
	}
	for (std::size_t i = 0; i < key_buttons_.size(); i++) {
		if (Button *button = key_buttons_[i].get()) {
			button->set_text(key_label(settings_.keys[i]));
		}
	}
}

String SettingsMenu::cancel_keys() const {
	return cancel_label_.is_empty() ? String("Esc") : String("Esc or ") + cancel_label_;
}

String SettingsMenu::key_label(int p_key) const {
	const Label *label = message_label_.get();
	return storage::key_name(p_key, label != nullptr ? label->get_theme_font("font") : Ref<Font>());
}

String SettingsMenu::describe_key(int p_key, int p_layout_label) const {
	const Label *label = message_label_.get();
	return storage::displayed_key_name(p_key, p_layout_label, label != nullptr ? label->get_theme_font("font") : Ref<Font>());
}

void SettingsMenu::set_message(const String &p_text) {
	if (Label *label = message_label_.get()) {
		label->set_text(p_text);
	}
}

void SettingsMenu::set_conflict_row_visible(bool p_visible) {
	if (Control *row = conflict_row_.get()) {
		row->set_visible(p_visible);
	}
}

String SettingsMenu::action_label(core::GameAction p_action) const {
	switch (p_action) {
		case core::GameAction::MoveLeft:
			return "Move Left";
		case core::GameAction::MoveRight:
			return "Move Right";
		case core::GameAction::Jump:
			return "Jump";
		case core::GameAction::Interact:
			return "Interact";
	}
	return "";
}

} // namespace dagon
