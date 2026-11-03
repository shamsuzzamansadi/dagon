#pragma once

#include "core/story_progress.hpp"
#include "hud.hpp"
#include "node_ref.hpp"
#include "player_controller.hpp"
#include "story_trigger.hpp"

#include <godot_cpp/classes/marker2d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <vector>

namespace dagon {

// Where the story is, in this world: triggers, checkpoints and the kill plane. Cinematics arrive in M3.
class GameDirector : public godot::Node {
	GDCLASS(GameDirector, godot::Node)

public:
	void _ready() override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	// Set before this node enters the tree. The world starts at this beat, with each earlier outcome
	// applied and no event replayed.
	void set_start_beat(int p_beat) { start_beat_ = p_beat; }
	int get_start_beat() const { return start_beat_; }

	// Returns the player to the active checkpoint, in this world.
	void restart_checkpoint();
	int get_active_checkpoint() const { return static_cast<int>(progress_.beat()); }

	void fade_in();
	void show_notice(const godot::String &p_text);
	void set_input_device(int p_device);

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
	void restore_start_beat();

	godot::NodePath player_path_;
	godot::NodePath hud_path_;
	godot::NodePath kill_plane_path_;
	// In beat order: checkpoint N belongs to beat N.
	godot::Array checkpoint_paths_;
	godot::Array story_trigger_paths_;

	NodeRef<PlayerController> player_;
	NodeRef<Hud> hud_;
	std::vector<NodeRef<godot::Marker2D>> checkpoints_;
	std::vector<NodeRef<StoryTrigger>> story_triggers_;
	core::StoryProgress progress_;
	int start_beat_ = 0;
};

} // namespace dagon
