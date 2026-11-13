#pragma once

#include "core/save_data.hpp"
#include "game_director.hpp"
#include "node_ref.hpp"

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/variant/node_path.hpp>

namespace dagon {

class MenuController;

// Holds the world and one small value that outlives it: the session checkpoint. That is the latest
// safe checkpoint reached this session, kept apart from what last reached the disk, so that Restart
// Checkpoint still works after a failed autosave. No singleton: this lives and dies with the scene.
class GameSession : public godot::Node {
	GDCLASS(GameSession, godot::Node)

public:
	void _ready() override;
	void _process(double p_delta) override;
	void _notification(int p_what);

	// Set by the main menu before this node enters the tree. It never reads the save itself.
	void set_start(int p_beat, bool p_persisted, bool p_show_intro);
	// A new game, straight from the prologue: the first world opens on him getting up. Never a rebuilt world.
	void set_waking(bool p_waking) { waking_ = p_waking; }
	bool is_waking() const { return waking_; }

	// The device in use. It has to outlive the world, like the session checkpoint.
	void set_active_device(int p_device);
	int get_active_device() const { return active_device_; }

	// Rebuilds the world at the session checkpoint. Reads no file.
	void restart_checkpoint();

	// Tries the write again if the latest checkpoint is not on disk. True if it is on disk now.
	bool retry_save();
	bool is_checkpoint_saved() const { return persisted_beat_ == session_beat_; }
	bool has_any_save() const { return persisted_beat_ >= 0; }

	// Whether quitting now loses a final sequence that will play again.
	bool is_in_final_sequence() const { return director_.get() != nullptr && director_.get()->is_in_final_sequence(); }

	int get_session_beat() const { return session_beat_; }
	int get_persisted_beat() const { return persisted_beat_; }
	godot::Node *get_world() const { return world_.get(); }
	GameDirector *get_director() const { return director_.get(); }

	void set_world_scene(const godot::Ref<godot::PackedScene> &p_value) { world_scene_ = p_value; }
	godot::Ref<godot::PackedScene> get_world_scene() const { return world_scene_; }
	void set_director_path(const godot::NodePath &p_value) { director_path_ = p_value; }
	godot::NodePath get_director_path() const { return director_path_; }
	void set_menu_path(const godot::NodePath &p_value) { menu_path_ = p_value; }
	godot::NodePath get_menu_path() const { return menu_path_; }

protected:
	static void _bind_methods();

private:
	bool quiet_ = false;
	void build_world();
	void remove_world();
	void on_checkpoint_reached(int p_beat);
	bool write_session_checkpoint();

	godot::Ref<godot::PackedScene> world_scene_;
	godot::NodePath director_path_;
	godot::NodePath menu_path_;

	NodeRef<godot::Node> world_;
	NodeRef<GameDirector> director_;
	int session_beat_ = 0;
	int persisted_beat_ = -1; // None yet.
	bool show_intro_ = false;
	bool waking_ = false;
	int active_device_ = -1;
};

} // namespace dagon
