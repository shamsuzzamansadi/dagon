#include "game_director.hpp"

#include "global_state.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

namespace dagon {

void GameDirector::_bind_methods() {
	ClassDB::bind_method(D_METHOD("restart_checkpoint"), &GameDirector::restart_checkpoint);
	ClassDB::bind_method(D_METHOD("get_active_checkpoint"), &GameDirector::get_active_checkpoint);

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
	// Forward only. Anything but the next trigger is rejected, changes nothing and stays armed.
	const std::size_t next = static_cast<std::size_t>(active_checkpoint_);
	if (next >= story_triggers_.size() || next + 1 >= checkpoints_.size()) {
		return;
	}
	StoryTrigger *trigger = story_triggers_[next].get();
	if (trigger == nullptr || trigger->get_trigger_id() != p_trigger_id) {
		return;
	}
	trigger->set_enabled(false);
	active_checkpoint_++;
	emit_signal("checkpoint_reached", active_checkpoint_);
}

void GameDirector::on_out_of_bounds(const StringName &p_trigger_id) {
	(void)p_trigger_id;
	restart_checkpoint();
}

void GameDirector::restart_checkpoint() {
	PlayerController *player = player_.get();
	if (player == nullptr || static_cast<std::size_t>(active_checkpoint_) >= checkpoints_.size()) {
		return;
	}
	const Marker2D *checkpoint = checkpoints_[static_cast<std::size_t>(active_checkpoint_)].get();
	if (checkpoint == nullptr) {
		return;
	}
	player->teleport(checkpoint->get_global_position());
	if (Hud *hud = hud_.get()) {
		hud->hide_caption();
		hud->fade_from_black(RESPAWN_FADE_SECONDS);
	}
	emit_signal("player_respawned");
}

} // namespace dagon
