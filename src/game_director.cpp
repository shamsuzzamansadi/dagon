#include "game_director.hpp"

#include "global_state.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

#include <optional>

using namespace godot;

namespace dagon {

void GameDirector::_bind_methods() {
	ClassDB::bind_method(D_METHOD("restart_checkpoint"), &GameDirector::restart_checkpoint);
	ClassDB::bind_method(D_METHOD("get_active_checkpoint"), &GameDirector::get_active_checkpoint);
	ClassDB::bind_method(D_METHOD("set_start_beat", "beat"), &GameDirector::set_start_beat);
	ClassDB::bind_method(D_METHOD("get_start_beat"), &GameDirector::get_start_beat);
	ClassDB::bind_method(D_METHOD("fade_in"), &GameDirector::fade_in);
	ClassDB::bind_method(D_METHOD("show_notice", "text"), &GameDirector::show_notice);

	ClassDB::bind_method(D_METHOD("set_player_path", "path"), &GameDirector::set_player_path);
	ClassDB::bind_method(D_METHOD("get_player_path"), &GameDirector::get_player_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "player_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "PlayerController"), "set_player_path", "get_player_path");
	ClassDB::bind_method(D_METHOD("set_hud_path", "path"), &GameDirector::set_hud_path);
	ClassDB::bind_method(D_METHOD("get_hud_path"), &GameDirector::get_hud_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "hud_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Hud"), "set_hud_path", "get_hud_path");
	ClassDB::bind_method(D_METHOD("set_kill_plane_path", "path"), &GameDirector::set_kill_plane_path);
	ClassDB::bind_method(D_METHOD("get_kill_plane_path"), &GameDirector::get_kill_plane_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "kill_plane_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "StoryTrigger"), "set_kill_plane_path", "get_kill_plane_path");
	ClassDB::bind_method(D_METHOD("set_checkpoints", "paths"), &GameDirector::set_checkpoints);
	ClassDB::bind_method(D_METHOD("get_checkpoints"), &GameDirector::get_checkpoints);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "checkpoints"), "set_checkpoints", "get_checkpoints");
	ClassDB::bind_method(D_METHOD("set_story_triggers", "paths"), &GameDirector::set_story_triggers);
	ClassDB::bind_method(D_METHOD("get_story_triggers"), &GameDirector::get_story_triggers);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "story_triggers"), "set_story_triggers", "get_story_triggers");

	ADD_SIGNAL(MethodInfo("checkpoint_reached", PropertyInfo(Variant::INT, "index")));
	ADD_SIGNAL(MethodInfo("player_respawned"));
}

void GameDirector::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	const bool was_dirty = reset_global_state();
#if defined(DEBUG_ENABLED)
	if (was_dirty) {
		WARN_PRINT("GameDirector: engine-global state was left changed by the previous scene.");
	}
#else
	(void)was_dirty;
#endif

	player_.set(player_path_.is_empty() ? nullptr : get_node<PlayerController>(player_path_));
	hud_.set(hud_path_.is_empty() ? nullptr : get_node<Hud>(hud_path_));
	if (player_.get() == nullptr) {
		ERR_PRINT("GameDirector: player_path does not point to a PlayerController.");
	}

	for (int i = 0; i < checkpoint_paths_.size(); i++) {
		NodeRef<Marker2D> checkpoint;
		checkpoint.set(get_node<Marker2D>(checkpoint_paths_[i]));
		if (checkpoint.get() == nullptr) {
			ERR_PRINT("GameDirector: an entry in checkpoints does not point to a Marker2D.");
		}
		checkpoints_.push_back(checkpoint);
	}

	for (int i = 0; i < story_trigger_paths_.size(); i++) {
		NodeRef<StoryTrigger> trigger;
		trigger.set(get_node<StoryTrigger>(story_trigger_paths_[i]));
		if (StoryTrigger *story_trigger = trigger.get()) {
			story_trigger->connect("triggered", callable_mp(this, &GameDirector::on_story_trigger));
		} else {
			ERR_PRINT("GameDirector: an entry in story_triggers does not point to a StoryTrigger.");
		}
		story_triggers_.push_back(trigger);
	}

	if (!kill_plane_path_.is_empty()) {
		if (StoryTrigger *kill_plane = get_node<StoryTrigger>(kill_plane_path_)) {
			kill_plane->connect("triggered", callable_mp(this, &GameDirector::on_out_of_bounds));
		} else {
			ERR_PRINT("GameDirector: kill_plane_path does not point to a StoryTrigger.");
		}
	}

	restore_start_beat();
}

void GameDirector::restore_start_beat() {
	const core::Beat beat = static_cast<core::Beat>(start_beat_);
	if (!progress_.restore(beat)) {
		ERR_PRINT("GameDirector: the start beat may not be restored; starting at the first checkpoint.");
		return;
	}
	// Each outcome is applied directly. Nothing is emitted, so no event can replay.
	for (const NodeRef<StoryTrigger> &reference : story_triggers_) {
		StoryTrigger *trigger = reference.get();
		if (trigger == nullptr) {
			continue;
		}
		const String id = trigger->get_trigger_id();
		const std::optional<core::Event> event = core::event_for_trigger(id.utf8().get_data());
		if (event.has_value() && static_cast<int>(core::beat_after(*event)) <= start_beat_) {
			trigger->set_enabled(false);
		}
	}
	PlayerController *player = player_.get();
	const std::size_t index = static_cast<std::size_t>(start_beat_);
	if (start_beat_ > 0 && player != nullptr && index < checkpoints_.size()) {
		if (const Marker2D *checkpoint = checkpoints_[index].get()) {
			player->teleport(checkpoint->get_global_position());
		}
	}
}

PackedStringArray GameDirector::_get_configuration_warnings() const {
	PackedStringArray warnings = Node::_get_configuration_warnings();
	if (player_path_.is_empty()) {
		warnings.push_back("player_path is not set, so the player cannot be respawned.");
	}
	if (checkpoint_paths_.is_empty()) {
		warnings.push_back("checkpoints is empty, so there is nowhere to respawn.");
	}
	return warnings;
}

void GameDirector::on_story_trigger(const StringName &p_trigger_id) {
	const String id = p_trigger_id;
	const std::optional<core::Event> event = core::event_for_trigger(id.utf8().get_data());
	if (!event.has_value()) {
		return;
	}
	// A rejected event changes nothing, and its trigger stays armed.
	const std::optional<core::Beat> beat = progress_.apply(*event);
	if (!beat.has_value()) {
		return;
	}
	for (const NodeRef<StoryTrigger> &reference : story_triggers_) {
		StoryTrigger *trigger = reference.get();
		if (trigger != nullptr && trigger->get_trigger_id() == p_trigger_id) {
			trigger->set_enabled(false);
		}
	}
	emit_signal("checkpoint_reached", static_cast<int>(*beat));
}

void GameDirector::on_out_of_bounds(const StringName &p_trigger_id) {
	(void)p_trigger_id;
	restart_checkpoint();
}

void GameDirector::restart_checkpoint() {
	PlayerController *player = player_.get();
	const std::size_t index = static_cast<std::size_t>(get_active_checkpoint());
	if (player == nullptr || index >= checkpoints_.size()) {
		return;
	}
	const Marker2D *checkpoint = checkpoints_[index].get();
	if (checkpoint == nullptr) {
		return;
	}
	player->teleport(checkpoint->get_global_position());
	if (Hud *hud = hud_.get()) {
		hud->hide_caption();
	}
	fade_in();
	emit_signal("player_respawned");
}

void GameDirector::fade_in() {
	if (Hud *hud = hud_.get()) {
		hud->fade_from_black(RESPAWN_FADE_SECONDS);
	}
}

void GameDirector::show_notice(const String &p_text) {
	if (Hud *hud = hud_.get()) {
		hud->show_notice(p_text);
	}
}

} // namespace dagon
