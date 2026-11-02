#pragma once

#include "hud.hpp"
#include "node_ref.hpp"
#include "player_controller.hpp"
#include "story_trigger.hpp"

#include <godot_cpp/classes/marker2d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <vector>

namespace dagon {

// M2 holds only the session checkpoint and the kill plane. M3 adds StoryProgress and cinematics.
class GameDirector : public godot::Node {
	GDCLASS(GameDirector, godot::Node)

public:
	void _ready() override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	// Returns the player to the active checkpoint.
	void restart_checkpoint();
	int get_active_checkpoint() const { return active_checkpoint_; }

	void set_player_path(const godot::NodePath &p_value) { player_path_ = p_value; }
	godot::NodePath get_player_path() const { return player_path_; }
	void set_hud_path(const godot::NodePath &p_value) { hud_path_ = p_value; }
	godot::NodePath get_hud_path() const { return hud_path_; }
	void set_kill_plane_path(const godot::NodePath &p_value) { kill_plane_path_ = p_value; }
	godot::NodePath get_kill_plane_path() const { return kill_plane_path_; }
	void set_checkpoints(const godot::Array &p_value) { checkpoint_paths_ = p_value; }
	godot::Array get_checkpoints() const { return checkpoint_paths_; }
	void set_story_triggers(const godot::Array &p_value) { story_trigger_paths_ = p_value; }
	godot::Array get_story_triggers() const { return story_trigger_paths_; }

protected:
	static void _bind_methods();

private:
	void on_story_trigger(const godot::StringName &p_trigger_id);
	void on_out_of_bounds(const godot::StringName &p_trigger_id);

	godot::NodePath player_path_;
	godot::NodePath hud_path_;
	godot::NodePath kill_plane_path_;
	// Trigger N activates checkpoint N + 1. Checkpoint 0 is where the session starts.
	godot::Array checkpoint_paths_;
	godot::Array story_trigger_paths_;

	NodeRef<PlayerController> player_;
	NodeRef<Hud> hud_;
	std::vector<NodeRef<godot::Marker2D>> checkpoints_;
	std::vector<NodeRef<StoryTrigger>> story_triggers_;
	int active_checkpoint_ = 0;
};

} // namespace dagon
