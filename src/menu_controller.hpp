#pragma once

#include "core/save_data.hpp"
#include "node_ref.hpp"
#include "settings_menu.hpp"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/string.hpp>

namespace dagon {

class GameSession;

// The main menu and the pause menu. They share their screens and behave differently only at the root:
// Back at the main menu does nothing, and at the pause menu it resumes.
class MenuController : public godot::Control {
	GDCLASS(MenuController, godot::Control)

public:
	enum Mode {
		MODE_PAUSE,
		MODE_TITLE,
	};

	void _ready() override;
	void _unhandled_input(const godot::Ref<godot::InputEvent> &p_event) override;

	bool is_open() const { return screen_ != Screen::Closed; }

	// Pause menu.
	void open();
	void resume();
	void restart_checkpoint();
	void ask_quit_to_desktop();
	void ask_quit_to_main_menu();
	// The controls, shown once when a new game starts. Closing them starts play.
	void show_intro();

	// Main menu.
	void new_game();
	void continue_game();
	void open_credits();
	void quit_now();
	void refresh_save_status();

	// Both.
	void open_settings();
	void open_controls();
	void confirm();
	void cancel_confirm();
	// Closes one level.
	void back();

	void set_mode(int p_value) { mode_ = static_cast<Mode>(p_value); }
	int get_mode() const { return mode_; }
	void set_game_scene(const godot::Ref<godot::PackedScene> &p_value) { game_scene_ = p_value; }
	godot::Ref<godot::PackedScene> get_game_scene() const { return game_scene_; }
	void set_title_scene_path(const godot::String &p_value) { title_scene_path_ = p_value; }
	godot::String get_title_scene_path() const { return title_scene_path_; }

#define DAGON_PATH_PROPERTY(m_name)                                                       \
	void set_##m_name(const godot::NodePath &p_value) { m_name##_ = p_value; }            \
	godot::NodePath get_##m_name() const { return m_name##_; }

	DAGON_PATH_PROPERTY(session_path)
	DAGON_PATH_PROPERTY(main_panel_path)
	DAGON_PATH_PROPERTY(confirm_panel_path)
	DAGON_PATH_PROPERTY(controls_panel_path)
	DAGON_PATH_PROPERTY(credits_panel_path)
	DAGON_PATH_PROPERTY(settings_menu_path)
	DAGON_PATH_PROPERTY(first_button_path)
	DAGON_PATH_PROPERTY(continue_button_path)
	DAGON_PATH_PROPERTY(new_game_button_path)
	DAGON_PATH_PROPERTY(settings_button_path)
	DAGON_PATH_PROPERTY(controls_button_path)
	DAGON_PATH_PROPERTY(credits_button_path)
	DAGON_PATH_PROPERTY(quit_button_path)
	DAGON_PATH_PROPERTY(quit_to_menu_button_path)
	DAGON_PATH_PROPERTY(confirm_cancel_button_path)
	DAGON_PATH_PROPERTY(confirm_ok_button_path)
	DAGON_PATH_PROPERTY(confirm_message_label_path)
	DAGON_PATH_PROPERTY(controls_title_label_path)
	DAGON_PATH_PROPERTY(controls_text_label_path)
	DAGON_PATH_PROPERTY(controls_back_button_path)
	DAGON_PATH_PROPERTY(credits_back_button_path)
	DAGON_PATH_PROPERTY(save_status_label_path)

#undef DAGON_PATH_PROPERTY

protected:
	static void _bind_methods();

private:
	enum class Screen {
		Closed,
		Main,
		Settings,
		Controls,
		Credits,
		Confirm,
	};

	enum class ConfirmAction {
		QuitToDesktop,
		QuitToMainMenu,
		NewGame,
	};

	void show_screen(Screen p_screen);
	void focus_path(const godot::NodePath &p_path);
	void focus_default();
	void on_settings_closed();
	void refresh_controls_text();
	void autostart();
	void ask_confirm(ConfirmAction p_action, const godot::String &p_message, const godot::String &p_ok_text);
	godot::String quit_message(ConfirmAction p_action);
	void quit_to_main_menu();
	void write_new_game();
	void start_session(core::Beat p_beat, bool p_show_intro);
	godot::Control *panel(const NodeRef<godot::Control> &p_panel) const { return p_panel.get(); }

	Mode mode_ = MODE_PAUSE;
	godot::Ref<godot::PackedScene> game_scene_;
	godot::String title_scene_path_;

	godot::NodePath session_path_;
	godot::NodePath main_panel_path_;
	godot::NodePath confirm_panel_path_;
	godot::NodePath controls_panel_path_;
	godot::NodePath credits_panel_path_;
	godot::NodePath settings_menu_path_;
	godot::NodePath first_button_path_;
	godot::NodePath continue_button_path_;
	godot::NodePath new_game_button_path_;
	godot::NodePath settings_button_path_;
	godot::NodePath controls_button_path_;
	godot::NodePath credits_button_path_;
	godot::NodePath quit_button_path_;
	godot::NodePath quit_to_menu_button_path_;
	godot::NodePath confirm_cancel_button_path_;
	godot::NodePath confirm_ok_button_path_;
	godot::NodePath confirm_message_label_path_;
	godot::NodePath controls_title_label_path_;
	godot::NodePath controls_text_label_path_;
	godot::NodePath controls_back_button_path_;
	godot::NodePath credits_back_button_path_;
	godot::NodePath save_status_label_path_;

	NodeRef<GameSession> session_;
	NodeRef<godot::Control> main_panel_;
	NodeRef<godot::Control> confirm_panel_;
	NodeRef<godot::Control> controls_panel_;
	NodeRef<godot::Control> credits_panel_;
	NodeRef<SettingsMenu> settings_menu_;
	NodeRef<godot::Label> confirm_message_label_;
	NodeRef<godot::Label> save_status_label_;
	NodeRef<godot::Button> continue_button_;
	Screen screen_ = Screen::Closed;
	ConfirmAction confirm_action_ = ConfirmAction::QuitToDesktop;
	godot::NodePath default_focus_path_;
	bool intro_ = false;
	bool can_continue_ = false;
	bool save_file_exists_ = false;
	core::SaveData loaded_save_;
};

} // namespace dagon

VARIANT_ENUM_CAST(dagon::MenuController::Mode);
