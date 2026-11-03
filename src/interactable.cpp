#include "interactable.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

namespace dagon {

void Interactable::_bind_methods() {
	ClassDB::bind_method(D_METHOD("try_interact"), &Interactable::try_interact);
	ClassDB::bind_method(D_METHOD("is_available"), &Interactable::is_available);

	ClassDB::bind_method(D_METHOD("set_interaction_id", "value"), &Interactable::set_interaction_id);
	ClassDB::bind_method(D_METHOD("get_interaction_id"), &Interactable::get_interaction_id);
	ADD_PROPERTY(PropertyInfo(Variant::STRING_NAME, "interaction_id"), "set_interaction_id", "get_interaction_id");
	ClassDB::bind_method(D_METHOD("set_prompt", "value"), &Interactable::set_prompt);
	ClassDB::bind_method(D_METHOD("get_prompt"), &Interactable::get_prompt);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "prompt"), "set_prompt", "get_prompt");
	ClassDB::bind_method(D_METHOD("set_caption", "value"), &Interactable::set_caption);
	ClassDB::bind_method(D_METHOD("get_caption"), &Interactable::get_caption);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "caption", PROPERTY_HINT_MULTILINE_TEXT), "set_caption", "get_caption");
	ClassDB::bind_method(D_METHOD("set_one_shot", "value"), &Interactable::set_one_shot);
	ClassDB::bind_method(D_METHOD("is_one_shot"), &Interactable::is_one_shot);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "one_shot"), "set_one_shot", "is_one_shot");
	ClassDB::bind_method(D_METHOD("set_enabled", "value"), &Interactable::set_enabled);
	ClassDB::bind_method(D_METHOD("is_enabled"), &Interactable::is_enabled);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enabled"), "set_enabled", "is_enabled");
	ClassDB::bind_method(D_METHOD("set_cooldown", "value"), &Interactable::set_cooldown);
	ClassDB::bind_method(D_METHOD("get_cooldown"), &Interactable::get_cooldown);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "cooldown"), "set_cooldown", "get_cooldown");

	ADD_SIGNAL(MethodInfo("interacted", PropertyInfo(Variant::STRING_NAME, "interaction_id")));
}

void Interactable::_physics_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	if (cooldown_left_ > 0.0f) {
		cooldown_left_ -= static_cast<float>(p_delta);
	}
}

bool Interactable::is_available() const {
	return enabled_ && !consumed_ && cooldown_left_ <= 0.0f;
}

bool Interactable::try_interact() {
	if (!is_available()) {
		return false;
	}
	consumed_ = one_shot_;
	cooldown_left_ = cooldown_;
	emit_signal("interacted", interaction_id_);
	return true;
}

} // namespace dagon
