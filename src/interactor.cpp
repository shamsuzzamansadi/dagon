#include "interactor.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

#include <algorithm>
#include <limits>

using namespace godot;

namespace dagon {

void Interactor::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_focus"), &Interactor::get_focus);
	ClassDB::bind_method(D_METHOD("set_action_interact", "value"), &Interactor::set_action_interact);
	ClassDB::bind_method(D_METHOD("get_action_interact"), &Interactor::get_action_interact);
	ADD_PROPERTY(PropertyInfo(Variant::STRING_NAME, "action_interact"), "set_action_interact", "get_action_interact");

	ADD_SIGNAL(MethodInfo("focus_changed", PropertyInfo(Variant::OBJECT, "target")));
	ADD_SIGNAL(MethodInfo("interacted", PropertyInfo(Variant::OBJECT, "target")));
}

void Interactor::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	PlayerController *player = Object::cast_to<PlayerController>(get_parent());
	if (player == nullptr) {
		ERR_PRINT("Interactor: must be a child of a PlayerController, or it cannot follow the player's control lock.");
	}
	player_.set(player);

	input_action_valid_ = InputMap::get_singleton()->has_action(action_interact_);
	if (!input_action_valid_) {
		ERR_PRINT("Interactor: the interact action is missing from the project's InputMap; input is disabled.");
	}

	connect("area_entered", callable_mp(this, &Interactor::on_area_entered));
	connect("area_exited", callable_mp(this, &Interactor::on_area_exited));
}

void Interactor::_physics_process(double p_delta) {
	(void)p_delta;
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	update_focus();
}

void Interactor::_unhandled_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint() || !input_action_valid_ || !p_event->is_action_pressed(action_interact_)) {
		return;
	}
	update_focus();
	Interactable *target = focus_.get();
	if (target == nullptr) {
		return;
	}
	get_viewport()->set_input_as_handled();
	if (target->try_interact()) {
		emit_signal("interacted", target);
	}
}

void Interactor::on_area_entered(Area2D *p_area) {
	Interactable *interactable = Object::cast_to<Interactable>(p_area);
	if (interactable != nullptr) {
		NodeRef<Interactable> candidate;
		candidate.set(interactable);
		candidates_.push_back(candidate);
	}
}

void Interactor::on_area_exited(Area2D *p_area) {
	candidates_.erase(std::remove_if(candidates_.begin(), candidates_.end(), [p_area](const NodeRef<Interactable> &p_candidate) { return p_candidate.get() == p_area; }), candidates_.end());
}

Interactable *Interactor::nearest_available() {
	candidates_.erase(std::remove_if(candidates_.begin(), candidates_.end(), [](const NodeRef<Interactable> &p_candidate) { return p_candidate.get() == nullptr; }), candidates_.end());

	const PlayerController *player = player_.get();
	if (player == nullptr || !player->is_control_enabled()) {
		return nullptr;
	}

	Interactable *nearest = nullptr;
	float nearest_distance = std::numeric_limits<float>::max();
	const Vector2 position = get_global_position();
	for (const NodeRef<Interactable> &candidate : candidates_) {
		Interactable *interactable = candidate.get();
		if (!interactable->is_available()) {
			continue;
		}
		const float distance = position.distance_squared_to(interactable->get_global_position());
		if (distance < nearest_distance) {
			nearest_distance = distance;
			nearest = interactable;
		}
	}
	return nearest;
}

void Interactor::update_focus() {
	Interactable *nearest = nearest_available();
	// A freed focus reads as nullptr here, so has_focus_ is what shows it changed.
	if (nearest == focus_.get() && (nearest != nullptr || !has_focus_)) {
		return;
	}
	focus_.set(nearest);
	has_focus_ = nearest != nullptr;
	emit_signal("focus_changed", nearest);
}

} // namespace dagon
