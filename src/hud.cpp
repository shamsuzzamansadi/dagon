#include "hud.hpp"

#include "core/narration.hpp"
#include "input_labels.hpp"
#include "interactable.hpp"
#include "narration.hpp"
#include "storage.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/property_tweener.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/variant/callable.hpp>

using namespace godot;

namespace dagon {

namespace {

constexpr float CAPTION_FADE_SECONDS = 0.25f;
constexpr float NOTICE_HOLD_SECONDS = 2.5f;

} // namespace

void Hud::_bind_methods() {
	ClassDB::bind_method(D_METHOD("on_focus_changed", "target"), &Hud::on_focus_changed);
	ClassDB::bind_method(D_METHOD("on_interacted", "target"), &Hud::on_interacted);
	ClassDB::bind_method(D_METHOD("show_caption", "text"), &Hud::show_caption);
	ClassDB::bind_method(D_METHOD("hide_caption"), &Hud::hide_caption);
	ClassDB::bind_method(D_METHOD("say", "id"), &Hud::say);
	ClassDB::bind_method(D_METHOD("is_speaking"), &Hud::is_speaking);
	ClassDB::bind_method(D_METHOD("get_current_line"), &Hud::get_current_line);
	ClassDB::bind_method(D_METHOD("show_notice", "text"), &Hud::show_notice);
	ClassDB::bind_method(D_METHOD("set_input_device", "device"), &Hud::set_input_device);
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
	ClassDB::bind_method(D_METHOD("set_voice_path", "path"), &Hud::set_voice_path);
	ClassDB::bind_method(D_METHOD("get_voice_path"), &Hud::get_voice_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "voice_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "AudioStreamPlayer"), "set_voice_path", "get_voice_path");
	ClassDB::bind_method(D_METHOD("set_examine_sound_path", "path"), &Hud::set_examine_sound_path);
	ClassDB::bind_method(D_METHOD("get_examine_sound_path"), &Hud::get_examine_sound_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "examine_sound_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "AudioStreamPlayer"), "set_examine_sound_path", "get_examine_sound_path");
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
	voice_.set(voice_path_.is_empty() ? nullptr : get_node<AudioStreamPlayer>(voice_path_));
	examine_sound_.set(examine_sound_path_.is_empty() ? nullptr : get_node<AudioStreamPlayer>(examine_sound_path_));
	script_ = narration::load_script().lines;

	// In code, not in the scene: the interactor is inside an instanced scene, and a scene connection
	// from there loads from text but is silently dropped whenever the scene is packed, as export does.
	Interactor *interactor = interactor_path_.is_empty() ? nullptr : get_node<Interactor>(interactor_path_);
	if (interactor == nullptr) {
		ERR_PRINT("Hud: interactor_path does not point to an Interactor; prompts and captions will not show.");
		return;
	}
	interactor_.set(interactor);
	interactor->connect("focus_changed", Callable(this, "on_focus_changed"));
	interactor->connect("interacted", Callable(this, "on_interacted"));
}

void Hud::_notification(int p_what) {
	// The player may have rebound the interact key in the pause menu.
	if (p_what == NOTIFICATION_UNPAUSED && !Engine::get_singleton()->is_editor_hint()) {
		refresh_prompt();
	}
}

// The same press that examines also cuts a line short. Hud comes after the player in the tree, so it sees the press
// first. It lets one through if that press is a move in the game, such as a stone, or if it would start another
// optional line. Otherwise it uses it up, so that skipping can never examine, and a press at something optional during
// a story moment only ever skips.
void Hud::_unhandled_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint() || !speaking_ || !p_event->is_action_pressed("interact")) {
		return;
	}
	const Interactor *interactor = interactor_.get();
	const Interactable *focus = interactor != nullptr ? interactor->get_focus() : nullptr;
	if (focus != nullptr && focus->is_available()) {
		const bool is_a_move_in_the_game = focus->get_line_id().is_empty();
		const bool starts_another_optional_line = focus->get_line_id() != current_line_ && current_priority_ == core::LinePriority::Optional;
		if (is_a_move_in_the_game || starts_another_optional_line) {
			return;
		}
	}
	print_verbose("dagon: line skipped: ", current_line_);
	hide_caption();
	get_viewport()->set_input_as_handled();
}

void Hud::set_input_device(int p_device) {
	input_device_ = p_device;
	refresh_prompt();
}

void Hud::on_focus_changed(Object *p_target) {
	const Interactable *target = Object::cast_to<Interactable>(p_target);
	prompt_text_ = target != nullptr ? target->get_prompt() : String();
	if (target != nullptr && !target->get_line_id().is_empty()) {
		print_verbose("dagon: focus: ", target->get_line_id());
	}
	refresh_prompt();
}

void Hud::refresh_prompt() {
	Label *label = prompt_label_.get();
	if (label == nullptr) {
		return;
	}
	if (prompt_text_.is_empty()) {
		if (label->is_visible()) {
			print_verbose("dagon: prompt hidden");
		}
		label->hide();
		return;
	}
	label->set_text(String("[") + input_labels::interact_label(input_device_, label->get_theme_font("font")) + "] " + prompt_text_);
	label->show();
	// Positive proof for the export check, which cannot see the screen.
	print_verbose("dagon: prompt: ", label->get_text());
}

void Hud::on_interacted(Object *p_target) {
	const Interactable *target = Object::cast_to<Interactable>(p_target);
	if (target == nullptr) {
		return;
	}
	// Examining has a sound of its own; what is pushed or pressed has its own sound from what it does.
	const bool examined = !target->get_line_id().is_empty() || !target->get_caption().is_empty();
	if (AudioStreamPlayer *sound = examine_sound_.get(); sound != nullptr && examined) {
		sound->play();
	}
	if (!target->get_line_id().is_empty()) {
		say(target->get_line_id());
	} else if (!target->get_caption().is_empty()) {
		show_caption(target->get_caption());
	}
}

void Hud::show_caption(const String &p_text) {
	hide_caption();
	run_caption(p_text, core::line_seconds(static_cast<std::size_t>(p_text.length()), 0.0, caption_hold_seconds_), true);
}

void Hud::say(const StringName &p_id) {
	const String id = p_id;
	const CharString id_text = id.utf8();
	const core::NarrationLine *line = core::find_line(script_, id_text.get_data());
	if (line == nullptr) {
		ERR_PRINT(String("Hud: no line in the script has the id '") + id + "'.");
		return;
	}
	const std::string current = String(current_line_).utf8().get_data();
	if (core::decide_line(speaking_, current, current_priority_, line->id, line->priority) == core::LineDecision::Ignore) {
		return;
	}
	const core::LinePriority priority = line->priority;
	const String text = String::utf8(line->text.c_str());
	hide_caption();

	const Ref<AudioStream> stream = narration::line_audio(p_id);
	AudioStreamPlayer *voice = voice_.get();
	const bool voiced = stream.is_valid() && voice != nullptr;
	if (voiced) {
		voice->set_stream(stream);
		voice->play();
	}
	speaking_ = true;
	current_line_ = p_id;
	current_priority_ = priority;
	// Subtitles only ever hide what can be heard, so text with no voice always shows.
	const bool visible = !voiced || storage::subtitles_enabled();
	const double seconds = core::line_seconds(static_cast<std::size_t>(text.length()), voiced ? stream->get_length() : 0.0, caption_hold_seconds_);
	print_verbose("dagon: line: ", p_id, " voiced=", voiced, " seconds=", seconds);
	run_caption(text, seconds, visible);
}

void Hud::run_caption(const String &p_text, double p_hold_seconds, bool p_visible) {
	Label *label = caption_label_.get();
	if (label == nullptr) {
		return;
	}
	caption_tween_ = create_tween();
	if (p_visible) {
		label->set_text(p_text);
		label->set_modulate(Color(1, 1, 1, 0));
		label->show();
		// Positive proof, as with the prompt.
		print_verbose("dagon: caption: ", p_text);
		caption_tween_->tween_property(label, "modulate:a", 1.0, CAPTION_FADE_SECONDS);
	}
	caption_tween_->tween_interval(p_hold_seconds);
	if (p_visible) {
		caption_tween_->tween_property(label, "modulate:a", 0.0, CAPTION_FADE_SECONDS);
	}
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
	if (AudioStreamPlayer *voice = voice_.get()) {
		voice->stop();
	}
	speaking_ = false;
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
	print_verbose("dagon: notice: ", p_text);
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
