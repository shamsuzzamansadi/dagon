#include "hud.hpp"

#include "interactable.hpp"
#include "storage.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input_event_joypad_button.hpp>
#include <godot_cpp/classes/input_event_joypad_motion.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/property_tweener.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/variant/callable.hpp>

#include <cmath>

using namespace godot;

namespace dagon {

namespace {

constexpr float CAPTION_FADE_SECONDS = 0.25f;
constexpr float NOTICE_HOLD_SECONDS = 2.5f;
constexpr double STICK_MOVED = 0.5;
const char *const GAMEPAD_INTERACT_LABEL = "X";

} // namespace

void Hud::_bind_methods() {
	ClassDB::bind_method(D_METHOD("on_focus_changed", "target"), &Hud::on_focus_changed);
	ClassDB::bind_method(D_METHOD("on_interacted", "target"), &Hud::on_interacted);
	ClassDB::bind_method(D_METHOD("show_caption", "text"), &Hud::show_caption);
	ClassDB::bind_method(D_METHOD("hide_caption"), &Hud::hide_caption);
	ClassDB::bind_method(D_METHOD("show_notice", "text"), &Hud::show_notice);
	ClassDB::bind_method(D_METHOD("fade_to_black", "seconds"), &Hud::fade_to_black);
	ClassDB::bind_method(D_METHOD("fade_from_black", "seconds"), &Hud::fade_from_black);

	ClassDB::bind_method(D_METHOD("set_interactor_path", "path"), &Hud::set_interactor_path);
	ClassDB::bind_method(D_METHOD("get_interactor_path"), &Hud::get_interactor_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "interactor_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Interactor"), "set_interactor_path", "get_interactor_path");
	ClassDB::bind_method(D_METHOD("set_notice_label_path", "path"), &Hud::set_notice_label_path);
	ClassDB::bind_method(D_METHOD("get_notice_label_path"), &Hud::get_notice_label_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "notice_label_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Label"), "set_notice_label_path", "get_notice_label_path");
	ClassDB::bind_method(D_METHOD("set_prompt_label_path", "path"), &Hud::set_prompt_label_path);
	ClassDB::bind_method(D_METHOD("get_prompt_label_path"), &Hud::get_prompt_label_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "prompt_label_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Label"), "set_prompt_label_path", "get_prompt_label_path");
	ClassDB::bind_method(D_METHOD("set_caption_label_path", "path"), &Hud::set_caption_label_path);
	ClassDB::bind_method(D_METHOD("get_caption_label_path"), &Hud::get_caption_label_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "caption_label_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Label"), "set_caption_label_path", "get_caption_label_path");
	ClassDB::bind_method(D_METHOD("set_fade_rect_path", "path"), &Hud::set_fade_rect_path);
	ClassDB::bind_method(D_METHOD("get_fade_rect_path"), &Hud::get_fade_rect_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "fade_rect_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "ColorRect"), "set_fade_rect_path", "get_fade_rect_path");
	ClassDB::bind_method(D_METHOD("set_caption_hold_seconds", "value"), &Hud::set_caption_hold_seconds);
	ClassDB::bind_method(D_METHOD("get_caption_hold_seconds"), &Hud::get_caption_hold_seconds);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "caption_hold_seconds"), "set_caption_hold_seconds", "get_caption_hold_seconds");

	ADD_SIGNAL(MethodInfo("fade_finished"));
}

void Hud::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	prompt_label_.set(get_node<Label>(prompt_label_path_));
	caption_label_.set(get_node<Label>(caption_label_path_));
	fade_rect_.set(get_node<ColorRect>(fade_rect_path_));
	notice_label_.set(get_node<Label>(notice_label_path_));
	if (prompt_label_.get() == nullptr || caption_label_.get() == nullptr || fade_rect_.get() == nullptr || notice_label_.get() == nullptr) {
		ERR_PRINT("Hud: a label or the fade rect path is not set; part of the HUD will not show.");
	}

	// In code, not in the scene: the interactor is inside an instanced scene, and a scene connection
	// from there loads from text but is silently dropped whenever the scene is packed, as export does.
	Interactor *interactor = interactor_path_.is_empty() ? nullptr : get_node<Interactor>(interactor_path_);
	if (interactor == nullptr) {
		ERR_PRINT("Hud: interactor_path does not point to an Interactor; prompts and captions will not show.");
		return;
	}
	interactor->connect("focus_changed", Callable(this, "on_focus_changed"));
	interactor->connect("interacted", Callable(this, "on_interacted"));
}

void Hud::_notification(int p_what) {
	// The player may have rebound the interact key in the pause menu.
	if (p_what == NOTIFICATION_UNPAUSED && !Engine::get_singleton()->is_editor_hint()) {
		refresh_prompt();
	}
}

void Hud::_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	bool gamepad = using_gamepad_;
	const Ref<InputEventJoypadButton> button = p_event;
	const Ref<InputEventJoypadMotion> motion = p_event;
	const Ref<InputEventKey> key = p_event;
	if (button.is_valid() || (motion.is_valid() && std::abs(motion->get_axis_value()) > STICK_MOVED)) {
		gamepad = true;
	} else if (key.is_valid()) {
		gamepad = false;
	}
	if (gamepad != using_gamepad_) {
		using_gamepad_ = gamepad;
		refresh_prompt();
	}
}

void Hud::on_focus_changed(Object *p_target) {
	const Interactable *target = Object::cast_to<Interactable>(p_target);
	prompt_text_ = target != nullptr ? target->get_prompt() : String();
	refresh_prompt();
}

void Hud::refresh_prompt() {
	Label *label = prompt_label_.get();
	if (label == nullptr) {
		return;
	}
	if (prompt_text_.is_empty()) {
		label->hide();
		return;
	}
	const String key = using_gamepad_ ? String(GAMEPAD_INTERACT_LABEL) : storage::key_name(storage::current_key("interact"), label->get_theme_font("font"));
	label->set_text(String("[") + key + "] " + prompt_text_);
	label->show();
	// Positive proof for the export check, which cannot see the screen.
	print_verbose("dagon: prompt: ", label->get_text());
}

void Hud::on_interacted(Object *p_target) {
	const Interactable *target = Object::cast_to<Interactable>(p_target);
	if (target != nullptr && !target->get_caption().is_empty()) {
		show_caption(target->get_caption());
	}
}

void Hud::show_caption(const String &p_text) {
	Label *label = caption_label_.get();
	if (label == nullptr) {
		return;
	}
	if (caption_tween_.is_valid()) {
		caption_tween_->kill();
	}
	label->set_text(p_text);
	label->set_modulate(Color(1, 1, 1, 0));
	label->show();
	caption_tween_ = create_tween();
	caption_tween_->tween_property(label, "modulate:a", 1.0, CAPTION_FADE_SECONDS);
	caption_tween_->tween_interval(caption_hold_seconds_);
	caption_tween_->tween_property(label, "modulate:a", 0.0, CAPTION_FADE_SECONDS);
	caption_tween_->tween_callback(callable_mp(this, &Hud::on_caption_finished));
}

void Hud::hide_caption() {
	if (caption_tween_.is_valid()) {
		caption_tween_->kill();
	}
	on_caption_finished();
}

void Hud::on_caption_finished() {
	if (Label *label = caption_label_.get()) {
		label->hide();
	}
}

void Hud::show_notice(const String &p_text) {
	Label *label = notice_label_.get();
	if (label == nullptr) {
		return;
	}
	if (notice_tween_.is_valid()) {
		notice_tween_->kill();
	}
	label->set_text(p_text);
	label->set_modulate(Color(1, 1, 1, 1));
	label->show();
	notice_tween_ = create_tween();
	notice_tween_->tween_interval(NOTICE_HOLD_SECONDS);
	notice_tween_->tween_property(label, "modulate:a", 0.0, CAPTION_FADE_SECONDS);
	notice_tween_->tween_callback(callable_mp(this, &Hud::on_notice_finished));
}

void Hud::on_notice_finished() {
	if (Label *label = notice_label_.get()) {
		label->hide();
	}
}

void Hud::fade_to_black(float p_seconds) {
	ColorRect *rect = fade_rect_.get();
	if (rect == nullptr) {
		return;
	}
	if (fade_tween_.is_valid()) {
		fade_tween_->kill();
	}
	rect->show();
	fade_tween_ = create_tween();
	fade_tween_->tween_property(rect, "modulate:a", 1.0, p_seconds);
	fade_tween_->tween_callback(callable_mp(this, &Hud::on_fade_finished));
}

void Hud::fade_from_black(float p_seconds) {
	ColorRect *rect = fade_rect_.get();
	if (rect == nullptr) {
		return;
	}
	if (fade_tween_.is_valid()) {
		fade_tween_->kill();
	}
	rect->set_modulate(Color(1, 1, 1, 1));
	rect->show();
	fade_tween_ = create_tween();
	fade_tween_->tween_property(rect, "modulate:a", 0.0, p_seconds);
	fade_tween_->tween_callback(callable_mp(this, &Hud::on_fade_finished));
}

void Hud::on_fade_finished() {
	ColorRect *rect = fade_rect_.get();
	if (rect != nullptr && rect->get_modulate().a <= 0.0f) {
		rect->hide();
	}
	emit_signal("fade_finished");
}

} // namespace dagon
