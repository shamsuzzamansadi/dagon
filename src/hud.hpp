#pragma once

#include "core/narration.hpp"
#include "interactor.hpp"
#include "node_ref.hpp"

#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/color_rect.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/tween.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <string>
#include <vector>

namespace dagon {

inline constexpr float RESPAWN_FADE_SECONDS = 0.35f;

// The prompt, captions and fade. Tweens are bound to this node, so they die with it.
class Hud : public godot::CanvasLayer {
	GDCLASS(Hud, godot::CanvasLayer)

public:
	void _ready() override;
	void _notification(int p_what);
	void _unhandled_input(const godot::Ref<godot::InputEvent> &p_event) override;

	// Set by the session. The Hud pauses with the world, so it cannot track input itself.
	void set_input_device(int p_device);

	// From Interactor.focus_changed and Interactor.interacted.
	void on_focus_changed(godot::Object *p_target);
	void on_interacted(godot::Object *p_target);

	// A caption never pauses the game. A new one replaces the old one. This is for feedback the player has just
	// caused, such as a stone's response, so it replaces anything, and is not a line.
	void show_caption(const godot::String &p_text);
	// Stops whatever is showing or being said, together.
	void hide_caption();

	// A line of the narration script: its caption, and its voice if it has one. There is no queue, and
	// core::decide_line says what happens if something is already being said.
	void say(const godot::StringName &p_id);
	bool is_speaking() const { return speaking_; }
	godot::StringName get_current_line() const { return speaking_ ? current_line_ : godot::StringName(); }

	// A brief line about saving, which never pauses the game.
	void show_notice(const godot::String &p_text);

	void fade_to_black(float p_seconds);
	void fade_from_black(float p_seconds);

	void set_interactor_path(const godot::NodePath &p_value) { interactor_path_ = p_value; }
	godot::NodePath get_interactor_path() const { return interactor_path_; }
	void set_notice_label_path(const godot::NodePath &p_value) { notice_label_path_ = p_value; }
	godot::NodePath get_notice_label_path() const { return notice_label_path_; }
	void set_prompt_label_path(const godot::NodePath &p_value) { prompt_label_path_ = p_value; }
	godot::NodePath get_prompt_label_path() const { return prompt_label_path_; }
	void set_caption_label_path(const godot::NodePath &p_value) { caption_label_path_ = p_value; }
	godot::NodePath get_caption_label_path() const { return caption_label_path_; }
	void set_voice_path(const godot::NodePath &p_value) { voice_path_ = p_value; }
	godot::NodePath get_voice_path() const { return voice_path_; }
	void set_examine_sound_path(const godot::NodePath &p_value) { examine_sound_path_ = p_value; }
	godot::NodePath get_examine_sound_path() const { return examine_sound_path_; }
	void set_fade_rect_path(const godot::NodePath &p_value) { fade_rect_path_ = p_value; }
	godot::NodePath get_fade_rect_path() const { return fade_rect_path_; }
	void set_caption_hold_seconds(float p_value) { caption_hold_seconds_ = p_value; }
	float get_caption_hold_seconds() const { return caption_hold_seconds_; }

protected:
	static void _bind_methods();

private:
	void refresh_prompt();
	void on_caption_finished();
	void run_caption(const godot::String &p_text, double p_hold_seconds, bool p_visible);
	void on_notice_finished();
	void on_fade_finished();

	godot::NodePath interactor_path_;
	godot::NodePath notice_label_path_;
	godot::NodePath prompt_label_path_;
	godot::NodePath caption_label_path_;
	godot::NodePath fade_rect_path_;
	godot::NodePath voice_path_;
	godot::NodePath examine_sound_path_;
	float caption_hold_seconds_ = 4.0f;

	NodeRef<godot::Label> notice_label_;
	NodeRef<godot::Label> prompt_label_;
	NodeRef<godot::Label> caption_label_;
	NodeRef<godot::ColorRect> fade_rect_;
	NodeRef<godot::AudioStreamPlayer> voice_;
	NodeRef<godot::AudioStreamPlayer> examine_sound_;
	NodeRef<Interactor> interactor_;
	godot::Ref<godot::Tween> notice_tween_;
	godot::Ref<godot::Tween> caption_tween_;
	godot::Ref<godot::Tween> fade_tween_;
	godot::String prompt_text_;
	int input_device_ = -1;
	std::vector<core::NarrationLine> script_;
	bool speaking_ = false;
	godot::StringName current_line_;
	core::LinePriority current_priority_ = core::LinePriority::Optional;
};

} // namespace dagon
