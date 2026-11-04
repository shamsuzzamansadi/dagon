#include "story_trigger.hpp"

#include "player_controller.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>

using namespace godot;

namespace dagon {

void StoryTrigger::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_player_inside"), &StoryTrigger::is_player_inside);

	ClassDB::bind_method(D_METHOD("set_trigger_id", "value"), &StoryTrigger::set_trigger_id);
	ClassDB::bind_method(D_METHOD("get_trigger_id"), &StoryTrigger::get_trigger_id);
	ADD_PROPERTY(PropertyInfo(Variant::STRING_NAME, "trigger_id"), "set_trigger_id", "get_trigger_id");
	ClassDB::bind_method(D_METHOD("set_enabled", "value"), &StoryTrigger::set_enabled);
	ClassDB::bind_method(D_METHOD("is_enabled"), &StoryTrigger::is_enabled);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enabled"), "set_enabled", "is_enabled");
	ClassDB::bind_method(D_METHOD("set_spent_from_beat", "beat"), &StoryTrigger::set_spent_from_beat);
	ClassDB::bind_method(D_METHOD("get_spent_from_beat"), &StoryTrigger::get_spent_from_beat);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "spent_from_beat"), "set_spent_from_beat", "get_spent_from_beat");

	ADD_SIGNAL(MethodInfo("triggered", PropertyInfo(Variant::STRING_NAME, "trigger_id")));
}

void StoryTrigger::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	connect("body_entered", callable_mp(this, &StoryTrigger::on_body_entered));
}

bool StoryTrigger::is_player_inside() const {
	const TypedArray<Node2D> bodies = get_overlapping_bodies();
	for (int i = 0; i < bodies.size(); i++) {
		if (Object::cast_to<PlayerController>(bodies[i]) != nullptr) {
			return true;
		}
	}
	return false;
}

void StoryTrigger::on_body_entered(Node2D *p_body) {
	if (enabled_ && Object::cast_to<PlayerController>(p_body) != nullptr) {
		emit_signal("triggered", trigger_id_);
	}
}

} // namespace dagon
