#include "menu_controller.hpp"

#include "global_state.hpp"
#include "storage.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

namespace dagon {

void MenuController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_open"), &MenuController::is_open);
	ClassDB::bind_method(D_METHOD("open"), &MenuController::open);
	ClassDB::bind_method(D_METHOD("resume"), &MenuController::resume);
	ClassDB::bind_method(D_METHOD("restart_checkpoint"), &MenuController::restart_checkpoint);
	ClassDB::bind_method(D_METHOD("open_settings"), &MenuController::open_settings);
	ClassDB::bind_method(D_METHOD("ask_quit"), &MenuController::ask_quit);
	ClassDB::bind_method(D_METHOD("cancel_quit"), &MenuController::cancel_quit);
	ClassDB::bind_method(D_METHOD("confirm_quit"), &MenuController::confirm_quit);
	ClassDB::bind_method(D_METHOD("back"), &MenuController::back);

#define DAGON_BIND_PATH(m_name)                                                                          \
	ClassDB::bind_method(D_METHOD("set_" #m_name, "path"), &MenuController::set_##m_name);               \
	ClassDB::bind_method(D_METHOD("get_" #m_name), &MenuController::get_##m_name);                       \
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, #m_name), "set_" #m_name, "get_" #m_name)

	DAGON_BIND_PATH(director_path);
	DAGON_BIND_PATH(main_panel_path);
	DAGON_BIND_PATH(quit_panel_path);
	DAGON_BIND_PATH(settings_menu_path);
	DAGON_BIND_PATH(resume_button_path);
	DAGON_BIND_PATH(settings_button_path);
	DAGON_BIND_PATH(quit_button_path);
	DAGON_BIND_PATH(quit_cancel_button_path);

#undef DAGON_BIND_PATH
}

void MenuController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	storage::apply_settings(storage::load_settings());

	director_.set(director_path_.is_empty() ? nullptr : get_node<GameDirector>(director_path_));
	main_panel_.set(get_node<Control>(main_panel_path_));
	quit_panel_.set(get_node<Control>(quit_panel_path_));
	settings_menu_.set(get_node<SettingsMenu>(settings_menu_path_));
	if (main_panel_.get() == nullptr || quit_panel_.get() == nullptr || settings_menu_.get() == nullptr) {
		ERR_PRINT("MenuController: a panel path is not set; the menu cannot open.");
		return;
	}
	settings_menu_.get()->connect("closed", callable_mp(this, &MenuController::on_settings_closed));
	show_screen(Screen::Closed);
}

void MenuController::_unhandled_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint() || main_panel_.get() == nullptr) {
		return;
	}
	// Esc is both of these, and it must still act only once.
	if (p_event->is_action_pressed("pause") || (is_open() && p_event->is_action_pressed("ui_cancel"))) {
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
	// A mouse click on nothing drops focus. The next press brings it back, so the menu stays usable.
	if (get_viewport()->gui_get_focus_owner() == nullptr && (p_event->is_action_pressed("ui_up") || p_event->is_action_pressed("ui_down") || p_event->is_action_pressed("ui_left") || p_event->is_action_pressed("ui_right") || p_event->is_action_pressed("ui_accept"))) {
		focus_default();
		get_viewport()->set_input_as_handled();
	}
}

void MenuController::show_screen(Screen p_screen) {
	screen_ = p_screen;
	set_visible(p_screen != Screen::Closed);
	main_panel_.get()->set_visible(p_screen == Screen::Main);
	quit_panel_.get()->set_visible(p_screen == Screen::QuitConfirm);
	settings_menu_.get()->set_visible(p_screen == Screen::Settings);
}

void MenuController::focus_path(const NodePath &p_path) {
	default_focus_path_ = p_path;
	focus_default();
}

void MenuController::focus_default() {
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
	focus_path(resume_button_path_);
}

void MenuController::resume() {
	if (main_panel_.get() == nullptr) {
		return;
	}
	show_screen(Screen::Closed);
	get_tree()->set_pause(false);
}

void MenuController::restart_checkpoint() {
	resume();
	reset_global_state();
	if (GameDirector *director = director_.get()) {
		director->restart_checkpoint();
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

void MenuController::ask_quit() {
	show_screen(Screen::QuitConfirm);
	focus_path(quit_cancel_button_path_);
}

void MenuController::cancel_quit() {
	show_screen(Screen::Main);
	focus_path(quit_button_path_);
}

void MenuController::confirm_quit() {
	get_tree()->quit();
}

void MenuController::back() {
	switch (screen_) {
		case Screen::Main:
			resume();
			break;
		case Screen::Settings:
			settings_menu_.get()->back();
			break;
		case Screen::QuitConfirm:
			cancel_quit();
			break;
		case Screen::Closed:
			break;
	}
}

} // namespace dagon
