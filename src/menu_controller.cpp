#include "menu_controller.hpp"

#include "game_session.hpp"
#include "global_state.hpp"
#include "input_labels.hpp"
#include "storage.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/variant/typed_array.hpp>

using namespace godot;

namespace dagon {

namespace {

const char *const REPLACE_SAVE_MESSAGE = "Start a new game? This replaces your saved game.";
const char *const REPLACE_DAMAGED_SAVE_MESSAGE = "Start a new game? This replaces the save that cannot be used.";
const char *const NEW_GAME_FAILED_MESSAGE = "Could not create a new save, so the game did not start. Your existing save was not changed.";
const char *const QUIT_SAVED_MESSAGE = "Continue resumes from your last saved checkpoint. Anything since then is not kept.";
const char *const QUIT_FINAL_SEQUENCE_MESSAGE = "Continue resumes before the final sequence, which will play again.";
const char *const QUIT_NOT_SAVED_MESSAGE = "Your latest checkpoint could not be saved. Continue resumes from your earlier save.";
const char *const QUIT_NO_SAVE_MESSAGE = "Your progress could not be saved, so there is nothing to continue.";
const char *const QUIT_SETTINGS_KEPT = " Your settings are kept.";
const char *const QUIT_SETTINGS_LOST = " Your latest settings could not be saved, so they will be lost.";
// The only way for the export check to reach the game in a build with no input device or script.
const char *const AUTOSTART_VARIABLE = "DAGON_AUTOSTART";

} // namespace

void MenuController::_bind_methods() {
	BIND_ENUM_CONSTANT(MODE_PAUSE);
	BIND_ENUM_CONSTANT(MODE_TITLE);
	BIND_ENUM_CONSTANT(MODE_ENDING);

	ClassDB::bind_method(D_METHOD("is_open"), &MenuController::is_open);
	ClassDB::bind_method(D_METHOD("open"), &MenuController::open);
	ClassDB::bind_method(D_METHOD("resume"), &MenuController::resume);
	ClassDB::bind_method(D_METHOD("restart_checkpoint"), &MenuController::restart_checkpoint);
	ClassDB::bind_method(D_METHOD("ask_quit_to_desktop"), &MenuController::ask_quit_to_desktop);
	ClassDB::bind_method(D_METHOD("ask_quit_to_main_menu"), &MenuController::ask_quit_to_main_menu);
	ClassDB::bind_method(D_METHOD("show_intro"), &MenuController::show_intro);
	ClassDB::bind_method(D_METHOD("new_game"), &MenuController::new_game);
	ClassDB::bind_method(D_METHOD("continue_game"), &MenuController::continue_game);
	ClassDB::bind_method(D_METHOD("open_credits"), &MenuController::open_credits);
	ClassDB::bind_method(D_METHOD("quit_now"), &MenuController::quit_now);
	ClassDB::bind_method(D_METHOD("quit_to_main_menu"), &MenuController::quit_to_main_menu);
	ClassDB::bind_method(D_METHOD("refresh_save_status"), &MenuController::refresh_save_status);
	ClassDB::bind_method(D_METHOD("open_settings"), &MenuController::open_settings);
	ClassDB::bind_method(D_METHOD("open_controls"), &MenuController::open_controls);
	ClassDB::bind_method(D_METHOD("confirm"), &MenuController::confirm);
	ClassDB::bind_method(D_METHOD("cancel_confirm"), &MenuController::cancel_confirm);
	ClassDB::bind_method(D_METHOD("back"), &MenuController::back);
	ClassDB::bind_method(D_METHOD("autostart"), &MenuController::autostart);
	ClassDB::bind_method(D_METHOD("set_active_device", "device"), &MenuController::set_active_device);
	ClassDB::bind_method(D_METHOD("get_active_device"), &MenuController::get_active_device);

	ClassDB::bind_method(D_METHOD("set_mode", "mode"), &MenuController::set_mode);
	ClassDB::bind_method(D_METHOD("get_mode"), &MenuController::get_mode);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "mode", PROPERTY_HINT_ENUM, "Pause,Title,Ending"), "set_mode", "get_mode");
	ClassDB::bind_method(D_METHOD("set_game_scene", "scene"), &MenuController::set_game_scene);
	ClassDB::bind_method(D_METHOD("get_game_scene"), &MenuController::get_game_scene);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "game_scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_game_scene", "get_game_scene");
	// A path, because the game scene and the main menu refer to each other.
	ClassDB::bind_method(D_METHOD("set_title_scene_path", "path"), &MenuController::set_title_scene_path);
	ClassDB::bind_method(D_METHOD("get_title_scene_path"), &MenuController::get_title_scene_path);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "title_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_title_scene_path", "get_title_scene_path");

#define DAGON_BIND_PATH(m_name)                                                            \
	ClassDB::bind_method(D_METHOD("set_" #m_name, "path"), &MenuController::set_##m_name); \
	ClassDB::bind_method(D_METHOD("get_" #m_name), &MenuController::get_##m_name);         \
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, #m_name), "set_" #m_name, "get_" #m_name)

	DAGON_BIND_PATH(session_path);
	DAGON_BIND_PATH(main_panel_path);
	DAGON_BIND_PATH(confirm_panel_path);
	DAGON_BIND_PATH(controls_panel_path);
	DAGON_BIND_PATH(credits_panel_path);
	DAGON_BIND_PATH(settings_menu_path);
	DAGON_BIND_PATH(first_button_path);
	DAGON_BIND_PATH(continue_button_path);
	DAGON_BIND_PATH(new_game_button_path);
	DAGON_BIND_PATH(settings_button_path);
	DAGON_BIND_PATH(controls_button_path);
	DAGON_BIND_PATH(credits_button_path);
	DAGON_BIND_PATH(quit_button_path);
	DAGON_BIND_PATH(quit_to_menu_button_path);
	DAGON_BIND_PATH(confirm_cancel_button_path);
	DAGON_BIND_PATH(confirm_ok_button_path);
	DAGON_BIND_PATH(confirm_message_label_path);
	DAGON_BIND_PATH(controls_title_label_path);
	DAGON_BIND_PATH(controls_text_label_path);
	DAGON_BIND_PATH(controls_back_button_path);
	DAGON_BIND_PATH(credits_back_button_path);
	DAGON_BIND_PATH(save_status_label_path);

#undef DAGON_BIND_PATH
}

void MenuController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	storage::apply_settings(storage::load_settings());

	session_.set(session_path_.is_empty() ? nullptr : get_node<GameSession>(session_path_));
	main_panel_.set(get_node<Control>(main_panel_path_));
	// The ending has only its card and the credits.
	if (mode_ != MODE_ENDING) {
		confirm_panel_.set(get_node<Control>(confirm_panel_path_));
		controls_panel_.set(get_node<Control>(controls_panel_path_));
		settings_menu_.set(get_node<SettingsMenu>(settings_menu_path_));
		confirm_message_label_.set(get_node<Label>(confirm_message_label_path_));
	}
	if (main_panel_.get() == nullptr || (mode_ != MODE_ENDING && (confirm_panel_.get() == nullptr || controls_panel_.get() == nullptr || settings_menu_.get() == nullptr))) {
		ERR_PRINT("MenuController: a panel path is not set; the menu cannot open.");
		main_panel_.set(nullptr);
		return;
	}
	if (SettingsMenu *settings = settings_menu_.get()) {
		settings->connect("closed", callable_mp(this, &MenuController::on_settings_closed));
	}

	Input *input = Input::get_singleton();
	input->connect("joy_connection_changed", callable_mp(this, &MenuController::on_joy_connection_changed));
	const TypedArray<int> controllers = input->get_connected_joypads();
	for (int i = 0; i < controllers.size(); i++) {
		input_labels::log_controller(controllers[i]);
	}
	if (SettingsMenu *settings = settings_menu_.get()) {
		settings->set_cancel_label(input_labels::back_label(active_device_));
	}

	if (mode_ == MODE_ENDING) {
		credits_panel_.set(get_node<Control>(credits_panel_path_));
		show_screen(Screen::Main);
		focus_path(first_button_path_);
		print_verbose("dagon: ending card shown");
	} else if (mode_ == MODE_TITLE) {
		credits_panel_.set(get_node<Control>(credits_panel_path_));
		save_status_label_.set(get_node<Label>(save_status_label_path_));
		continue_button_.set(get_node<Button>(continue_button_path_));
		show_screen(Screen::Main);
		refresh_save_status();
		focus_path(can_continue_ ? continue_button_path_ : new_game_button_path_);
		if (!OS::get_singleton()->get_environment(AUTOSTART_VARIABLE).is_empty()) {
			call_deferred("autostart");
		}
	} else {
		show_screen(Screen::Closed);
	}
}

void MenuController::autostart() {
	const String choice = OS::get_singleton()->get_environment(AUTOSTART_VARIABLE);
	if (choice == String("new_game")) {
		new_game();
	} else if (choice == String("continue")) {
		continue_game();
	}
}

void MenuController::_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	const int device = input_labels::device_from_event(p_event, active_device_);
	if (device != active_device_) {
		set_active_device(device);
	}
}

void MenuController::set_active_device(int p_device) {
	active_device_ = p_device;
	if (GameSession *session = session_.get()) {
		session->set_active_device(p_device);
	}
	if (SettingsMenu *settings = settings_menu_.get()) {
		settings->set_cancel_label(input_labels::back_label(p_device));
	}
	if (screen_ == Screen::Controls) {
		refresh_controls_text();
	}
}

void MenuController::on_joy_connection_changed(int p_device, bool p_connected) {
	if (p_connected) {
		input_labels::log_controller(p_device);
	}
	// A controller that is gone cannot be what the player is using. Coming back changes nothing until it is
	// pressed, so a reconnection can never relabel what is on screen by itself.
	if (!p_connected && p_device == active_device_) {
		set_active_device(input_labels::KEYBOARD);
	} else if (screen_ == Screen::Controls) {
		refresh_controls_text();
	}
}

void MenuController::_unhandled_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint() || main_panel_.get() == nullptr) {
		return;
	}
	const bool pause_pressed = mode_ == MODE_PAUSE && p_event->is_action_pressed("pause");
	// Esc is both of these, and it must still act only once.
	if (pause_pressed || (is_open() && p_event->is_action_pressed("ui_cancel"))) {
		if (is_open()) {
			back();
		} else {
			open();
		}
		get_viewport()->set_input_as_handled();
		return;
	}
	if (!is_open()) {
		return;
	}
	// Focus is always set on the way into a screen, and a click on empty space leaves it alone. If it
	// is ever lost all the same, the next press brings it back, so the menu cannot strand a keyboard or pad.
	if (get_viewport()->gui_get_focus_owner() == nullptr && (p_event->is_action_pressed("ui_up") || p_event->is_action_pressed("ui_down") || p_event->is_action_pressed("ui_left") || p_event->is_action_pressed("ui_right") || p_event->is_action_pressed("ui_accept"))) {
		focus_default();
		get_viewport()->set_input_as_handled();
	}
}

void MenuController::show_screen(Screen p_screen) {
	screen_ = p_screen;
	set_visible(p_screen != Screen::Closed);
	main_panel_.get()->set_visible(p_screen == Screen::Main);
	if (Control *confirm = confirm_panel_.get()) {
		confirm->set_visible(p_screen == Screen::Confirm);
	}
	if (Control *controls = controls_panel_.get()) {
		controls->set_visible(p_screen == Screen::Controls);
	}
	if (SettingsMenu *settings = settings_menu_.get()) {
		settings->set_visible(p_screen == Screen::Settings);
	}
	if (Control *credits = credits_panel_.get()) {
		credits->set_visible(p_screen == Screen::Credits);
	}
}

void MenuController::focus_path(const NodePath &p_path) {
	default_focus_path_ = p_path;
	focus_default();
}

void MenuController::focus_default() {
	if (screen_ == Screen::Settings) {
		settings_menu_.get()->focus_current();
		return;
	}
	if (Control *control = get_node<Control>(default_focus_path_)) {
		control->grab_focus();
	}
}

void MenuController::open() {
	if (main_panel_.get() == nullptr) {
		return;
	}
	get_tree()->set_pause(true);
	show_screen(Screen::Main);
	focus_path(first_button_path_);
}

void MenuController::resume() {
	if (main_panel_.get() == nullptr) {
		return;
	}
	intro_ = false;
	show_screen(Screen::Closed);
	get_tree()->set_pause(false);
}

void MenuController::restart_checkpoint() {
	resume();
	reset_global_state();
	if (GameSession *session = session_.get()) {
		session->restart_checkpoint();
	}
}

void MenuController::show_intro() {
	if (main_panel_.get() == nullptr) {
		return;
	}
	intro_ = true;
	get_tree()->set_pause(true);
	refresh_controls_text();
	if (Label *title = get_node<Label>(controls_title_label_path_)) {
		title->set_text("How to Play");
	}
	if (Button *button = get_node<Button>(controls_back_button_path_)) {
		button->set_text("Begin");
	}
	show_screen(Screen::Controls);
	focus_path(controls_back_button_path_);
	// The export check has nobody to press Begin, and needs play to start to see a prompt.
	print_verbose("dagon: introduction shown");
	if (!OS::get_singleton()->get_environment(AUTOSTART_VARIABLE).is_empty()) {
		call_deferred("resume");
	}
}

void MenuController::open_controls() {
	refresh_controls_text();
	if (Label *title = get_node<Label>(controls_title_label_path_)) {
		title->set_text("Controls");
	}
	if (Button *button = get_node<Button>(controls_back_button_path_)) {
		button->set_text("Back");
	}
	show_screen(Screen::Controls);
	focus_path(controls_back_button_path_);
}

void MenuController::refresh_controls_text() {
	if (Label *label = get_node<Label>(controls_text_label_path_)) {
		label->set_text(input_labels::controls_text(active_device_, intro_, label->get_theme_font("font")));
	}
}

void MenuController::open_settings() {
	show_screen(Screen::Settings);
	settings_menu_.get()->open();
}

void MenuController::on_settings_closed() {
	show_screen(Screen::Main);
	focus_path(settings_button_path_);
}

void MenuController::open_credits() {
	show_screen(Screen::Credits);
	focus_path(credits_back_button_path_);
}

void MenuController::ask_confirm(ConfirmAction p_action, const String &p_message, const String &p_ok_text) {
	confirm_action_ = p_action;
	if (Label *label = confirm_message_label_.get()) {
		label->set_text(p_message);
	}
	if (Button *button = get_node<Button>(confirm_ok_button_path_)) {
		button->set_text(p_ok_text);
	}
	show_screen(Screen::Confirm);
	focus_path(confirm_cancel_button_path_);
}

String MenuController::quit_message(ConfirmAction p_action) {
	String message = p_action == ConfirmAction::QuitToDesktop ? "Quit to desktop? " : "Return to the main menu? ";
	GameSession *session = session_.get();
	if (session == nullptr) {
		return message;
	}
	if (session->retry_save()) {
		message += session->is_in_final_sequence() ? QUIT_FINAL_SEQUENCE_MESSAGE : QUIT_SAVED_MESSAGE;
	} else {
		message += session->has_any_save() ? QUIT_NOT_SAVED_MESSAGE : QUIT_NO_SAVE_MESSAGE;
	}
	message += settings_menu_.get()->has_unsaved_changes() ? QUIT_SETTINGS_LOST : QUIT_SETTINGS_KEPT;
	return message;
}

void MenuController::ask_quit_to_desktop() {
	ask_confirm(ConfirmAction::QuitToDesktop, quit_message(ConfirmAction::QuitToDesktop), "Quit");
}

void MenuController::ask_quit_to_main_menu() {
	ask_confirm(ConfirmAction::QuitToMainMenu, quit_message(ConfirmAction::QuitToMainMenu), "Main Menu");
}

void MenuController::cancel_confirm() {
	show_screen(Screen::Main);
	switch (confirm_action_) {
		case ConfirmAction::QuitToDesktop:
			focus_path(quit_button_path_);
			break;
		case ConfirmAction::QuitToMainMenu:
			focus_path(quit_to_menu_button_path_);
			break;
		case ConfirmAction::NewGame:
			focus_path(new_game_button_path_);
			break;
	}
}

void MenuController::confirm() {
	switch (confirm_action_) {
		case ConfirmAction::QuitToDesktop:
			quit_now();
			break;
		case ConfirmAction::QuitToMainMenu:
			quit_to_main_menu();
			break;
		case ConfirmAction::NewGame:
			write_new_game();
			break;
	}
}

void MenuController::quit_now() {
	get_tree()->quit();
}

void MenuController::quit_to_main_menu() {
	const Ref<PackedScene> scene = ResourceLoader::get_singleton()->load(title_scene_path_);
	MenuController *title = scene.is_valid() ? Object::cast_to<MenuController>(scene->instantiate()) : nullptr;
	ERR_FAIL_NULL_MSG(title, "MenuController: title_scene_path could not be loaded; staying in the game.");
	reset_global_state();
	title->set_active_device(active_device_);
	get_tree()->change_scene_to_node(title);
}

void MenuController::refresh_save_status() {
	const storage::LoadedSave loaded = storage::load_game();
	can_continue_ = loaded.status == core::SaveStatus::Ok;
	save_file_exists_ = loaded.any_file;
	loaded_save_ = loaded.save;
	print_verbose("dagon: save status=", static_cast<int>(loaded.status), " backup=", loaded.from_backup);

	if (Button *button = continue_button_.get()) {
		button->set_disabled(!can_continue_);
		// A disabled button cannot be pressed, so focus passes over it.
		button->set_focus_mode(can_continue_ ? Control::FOCUS_ALL : Control::FOCUS_NONE);
	}
	if (Label *label = save_status_label_.get()) {
		const std::string note = can_continue_ ? core::continue_note(loaded.save.beat) : core::unusable_save_note(loaded.status);
		label->set_text(String(note.c_str()));
	}
}

void MenuController::new_game() {
	refresh_save_status();
	if (!save_file_exists_) {
		write_new_game();
		return;
	}
	ask_confirm(ConfirmAction::NewGame, can_continue_ ? REPLACE_SAVE_MESSAGE : REPLACE_DAMAGED_SAVE_MESSAGE, "New Game");
}

void MenuController::write_new_game() {
	// The write comes first. If it fails the player stays here, and no path reads the old save.
	const core::SaveData fresh;
	if (!storage::save_game(fresh)) {
		ask_confirm(ConfirmAction::NewGame, NEW_GAME_FAILED_MESSAGE, "Retry");
		return;
	}
	start_session(fresh.beat, true);
}

void MenuController::continue_game() {
	if (!can_continue_) {
		return;
	}
	start_session(loaded_save_.beat, false);
}

void MenuController::start_session(core::Beat p_beat, bool p_show_intro) {
	ERR_FAIL_COND_MSG(game_scene_.is_null(), "MenuController: game_scene is not set; the game cannot start.");
	reset_global_state();
	GameSession *session = Object::cast_to<GameSession>(game_scene_->instantiate());
	ERR_FAIL_NULL_MSG(session, "MenuController: game_scene's root is not a GameSession.");
	session->set_start(static_cast<int>(p_beat), true, p_show_intro);
	session->set_active_device(active_device_);
	get_tree()->change_scene_to_node(session);
}

void MenuController::back() {
	switch (screen_) {
		case Screen::Main:
			if (mode_ == MODE_PAUSE) {
				resume();
			}
			break;
		case Screen::Settings:
			settings_menu_.get()->back();
			break;
		case Screen::Controls:
			if (intro_) {
				resume();
			} else {
				show_screen(Screen::Main);
				focus_path(controls_button_path_);
			}
			break;
		case Screen::Credits:
			show_screen(Screen::Main);
			focus_path(credits_button_path_);
			break;
		case Screen::Confirm:
			cancel_confirm();
			break;
		case Screen::Closed:
			break;
	}
}

} // namespace dagon
