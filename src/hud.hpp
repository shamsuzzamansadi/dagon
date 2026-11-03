#pragma once

#include "interactor.hpp"
#include "node_ref.hpp"

#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/color_rect.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/tween.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/string.hpp>

namespace dagon {

inline constexpr float RESPAWN_FADE_SECONDS = 0.35f;

// The prompt, captions and fade. Tweens are bound to this node, so they die with it.
class Hud : public godot::CanvasLayer {
	GDCLASS(Hud, godot::CanvasLayer)

public:
	void _ready() override;
	void _notification(int p_what);

	// Set by the session. The Hud pauses with the world, so it cannot track input itself.
	void set_input_device(int p_device);

	// From Interactor.focus_changed and Interactor.interacted.
	void on_focus_changed(godot::Object *p_target);
	void on_interacted(godot::Object *p_target);

	// A caption never pauses the game. A new one replaces the old one.
	void show_caption(const godot::String &p_text);
	void hide_caption();

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
	void set_fade_rect_path(const godot::NodePath &p_value) { fade_rect_path_ = p_value; }
	godot::NodePath get_fade_rect_path() const { return fade_rect_path_; }
	void set_caption_hold_seconds(float p_value) { caption_hold_seconds_ = p_value; }
	float get_caption_hold_seconds() const { return caption_hold_seconds_; }

protected:
	static void _bind_methods();

private:
	void refresh_prompt();
	void on_caption_finished();
	void on_notice_finished();
	void on_fade_finished();

	godot::NodePath interactor_path_;
	godot::NodePath notice_label_path_;
	godot::NodePath prompt_label_path_;
	godot::NodePath caption_label_path_;
	godot::NodePath fade_rect_path_;
	float caption_hold_seconds_ = 4.0f;

	NodeRef<godot::Label> notice_label_;
	NodeRef<godot::Label> prompt_label_;
	NodeRef<godot::Label> caption_label_;
	NodeRef<godot::ColorRect> fade_rect_;
	godot::Ref<godot::Tween> notice_tween_;
	godot::Ref<godot::Tween> caption_tween_;
	godot::Ref<godot::Tween> fade_tween_;
	godot::String prompt_text_;
	int input_device_ = -1;
};

} // namespace dagon
