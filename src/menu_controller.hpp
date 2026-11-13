#pragma once

#include "core/save_data.hpp"
#include "node_ref.hpp"
#include "settings_menu.hpp"

#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
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
		MODE_ENDING,
		// Shown by New Game only, between writing the new save and the Shore. Continue never comes here.
		MODE_PROLOGUE,
	};

	void _ready() override;
	void _process(double p_delta) override;
	void _input(const godot::Ref<godot::InputEvent> &p_event) override;
	void _unhandled_input(const godot::Ref<godot::InputEvent> &p_event) override;
	void _notification(int p_what);

	// Keyboard, or a controller's device number. This node keeps running while the game is paused, so
	// it is what notices a change of device, and it passes the news on.
	void set_active_device(int p_device);
	int get_active_device() const { return active_device_; }

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

	// Ending, and the pause menu's confirmed Quit to Main Menu.
	void quit_to_main_menu();
	// Ending: the next line of the epilogue, or the credits after the last. Never makes anyone wait.
	void advance_ending();
	int get_ending_line() const { return ending_line_; }
	// Skipping and finishing lead to the same place, by the same call.
	void skip_prologue();
	bool is_prologue_finished() const { return prologue_finished_; }

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
	void set_prologue_scene(const godot::Ref<godot::PackedScene> &p_value) { prologue_scene_ = p_value; }
	godot::Ref<godot::PackedScene> get_prologue_scene() const { return prologue_scene_; }
	void set_ending_lines(const godot::PackedStringArray &p_value) { ending_lines_ = p_value; }
	godot::PackedStringArray get_ending_lines() const { return ending_lines_; }
	void set_title_scene_path(const godot::String &p_value) { title_scene_path_ = p_value; }
	godot::String get_title_scene_path() const { return title_scene_path_; }

#define DAGON_PATH_PROPERTY(m_name)                                            \
	void set_##m_name(const godot::NodePath &p_value) { m_name##_ = p_value; } \
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
	DAGON_PATH_PROPERTY(ending_box_path)
	DAGON_PATH_PROPERTY(voice_path)
	DAGON_PATH_PROPERTY(panels_path)
	DAGON_PATH_PROPERTY(move_sound_path)
	DAGON_PATH_PROPERTY(accept_sound_path)
	DAGON_PATH_PROPERTY(back_sound_path)

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
	void on_gui_focus_changed(godot::Control *p_control);
	void on_button_pressed();
	static void play(const NodeRef<godot::AudioStreamPlayer> &p_sound);
	void on_joy_connection_changed(int p_device, bool p_connected);
	void refresh_controls_text();
	void autostart();
	void ask_confirm(ConfirmAction p_action, const godot::String &p_message, const godot::String &p_ok_text);
	godot::String quit_message(ConfirmAction p_action);
	void write_new_game();
	void start_session(core::Beat p_beat, bool p_show_intro, bool p_waking = false);
	void begin_prologue();
	void show_next_ending_line();
	bool is_sequence() const { return mode_ == MODE_ENDING || mode_ == MODE_PROLOGUE; }
	void show_panel(int p_index);
	static void start_panel(godot::Node *p_panel);
	void fade_sounds(double p_seconds, const godot::Node *p_keep_under = nullptr);
	static void stop_panel(godot::Node *p_panel);
	void finish_prologue(bool p_skipped);
	godot::Control *panel(const NodeRef<godot::Control> &p_panel) const { return p_panel.get(); }

	Mode mode_ = MODE_PAUSE;
	godot::Ref<godot::PackedScene> game_scene_;
	godot::Ref<godot::PackedScene> prologue_scene_;
	bool prologue_finished_ = false;
	bool quiet_ = false;
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
	godot::NodePath ending_box_path_;
	godot::NodePath panels_path_;
	godot::NodePath move_sound_path_;
	godot::NodePath accept_sound_path_;
	godot::NodePath back_sound_path_;
	godot::NodePath voice_path_;
	godot::PackedStringArray ending_lines_;

	NodeRef<GameSession> session_;
	NodeRef<godot::Control> main_panel_;
	NodeRef<godot::Control> confirm_panel_;
	NodeRef<godot::Control> controls_panel_;
	NodeRef<godot::Control> credits_panel_;
	NodeRef<SettingsMenu> settings_menu_;
	NodeRef<godot::Label> confirm_message_label_;
	NodeRef<godot::Label> save_status_label_;
	NodeRef<godot::Button> continue_button_;
	NodeRef<godot::AudioStreamPlayer> voice_;
	NodeRef<godot::AudioStreamPlayer> move_sound_;
	NodeRef<godot::AudioStreamPlayer> accept_sound_;
	NodeRef<godot::AudioStreamPlayer> back_sound_;
	// Set while the menu moves focus itself, on the way into a screen: only the player's own moves are heard.
	bool quiet_focus_ = false;
	int ending_line_ = -1;
	double ending_line_left_ = 0.0;
	Screen screen_ = Screen::Closed;
	ConfirmAction confirm_action_ = ConfirmAction::QuitToDesktop;
	godot::NodePath default_focus_path_;
	int active_device_ = -1;
	bool intro_ = false;
	bool can_continue_ = false;
	bool save_file_exists_ = false;
	core::SaveData loaded_save_;
};

} // namespace dagon

VARIANT_ENUM_CAST(dagon::MenuController::Mode);
