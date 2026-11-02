#pragma once

#include "game_director.hpp"
#include "node_ref.hpp"
#include "settings_menu.hpp"

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/node_path.hpp>

namespace dagon {

// The pause menu. M3 adds the main menu's and ending's modes.
class MenuController : public godot::Control {
	GDCLASS(MenuController, godot::Control)

public:
	void _ready() override;
	void _unhandled_input(const godot::Ref<godot::InputEvent> &p_event) override;

	bool is_open() const { return screen_ != Screen::Closed; }

	void open();
	void resume();
	void restart_checkpoint();
	void open_settings();
	void ask_quit();
	void cancel_quit();
	void confirm_quit();
	// Closes one level.
	void back();

	void set_director_path(const godot::NodePath &p_value) { director_path_ = p_value; }
	godot::NodePath get_director_path() const { return director_path_; }
	void set_main_panel_path(const godot::NodePath &p_value) { main_panel_path_ = p_value; }
	godot::NodePath get_main_panel_path() const { return main_panel_path_; }
	void set_quit_panel_path(const godot::NodePath &p_value) { quit_panel_path_ = p_value; }
	godot::NodePath get_quit_panel_path() const { return quit_panel_path_; }
	void set_settings_menu_path(const godot::NodePath &p_value) { settings_menu_path_ = p_value; }
	godot::NodePath get_settings_menu_path() const { return settings_menu_path_; }
	void set_resume_button_path(const godot::NodePath &p_value) { resume_button_path_ = p_value; }
	godot::NodePath get_resume_button_path() const { return resume_button_path_; }
	void set_settings_button_path(const godot::NodePath &p_value) { settings_button_path_ = p_value; }
	godot::NodePath get_settings_button_path() const { return settings_button_path_; }
	void set_quit_button_path(const godot::NodePath &p_value) { quit_button_path_ = p_value; }
	godot::NodePath get_quit_button_path() const { return quit_button_path_; }
	void set_quit_cancel_button_path(const godot::NodePath &p_value) { quit_cancel_button_path_ = p_value; }
	godot::NodePath get_quit_cancel_button_path() const { return quit_cancel_button_path_; }

protected:
	static void _bind_methods();

private:
	enum class Screen {
		Closed,
		Main,
		Settings,
		QuitConfirm,
	};

	void show_screen(Screen p_screen);
	void focus_path(const godot::NodePath &p_path);
	void focus_default();
	void on_settings_closed();

	godot::NodePath director_path_;
	godot::NodePath main_panel_path_;
	godot::NodePath quit_panel_path_;
	godot::NodePath settings_menu_path_;
	godot::NodePath resume_button_path_;
	godot::NodePath settings_button_path_;
	godot::NodePath quit_button_path_;
	godot::NodePath quit_cancel_button_path_;

	NodeRef<GameDirector> director_;
	NodeRef<godot::Control> main_panel_;
	NodeRef<godot::Control> quit_panel_;
	NodeRef<SettingsMenu> settings_menu_;
	Screen screen_ = Screen::Closed;
	godot::NodePath default_focus_path_;
};

} // namespace dagon
