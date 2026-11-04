#pragma once

#include "camera_rig.hpp"
#include "core/story_progress.hpp"
#include "hud.hpp"
#include "interactable.hpp"
#include "node_ref.hpp"
#include "player_controller.hpp"
#include "puzzle_controller.hpp"
#include "story_trigger.hpp"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/collision_object2d.hpp>
#include <godot_cpp/classes/marker2d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <cstdint>
#include <optional>
#include <vector>

namespace dagon {

// Where the story is, in this world: its beats, their outcomes, the input lock, and the cinematics that lock it.
// Every gameplay consequence is applied here in C++. A clip is only a picture of it, so a clip that is missing,
// looping or stuck can never stop the game going on. docs/architecture.md §5 has the contract.
class GameDirector : public godot::Node {
	GDCLASS(GameDirector, godot::Node)

public:
	void _ready() override;
	void _process(double p_delta) override;
	void _physics_process(double p_delta) override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	// Set before this node enters the tree. The world starts at this beat, with each earlier outcome
	// applied and no event replayed.
	void set_start_beat(int p_beat) { start_beat_ = p_beat; }
	int get_start_beat() const { return start_beat_; }

	int get_beat() const { return static_cast<int>(progress_.beat()); }
	// The checkpoint that a fall returns to. The final sequence has none of its own.
	int get_active_checkpoint() const { return static_cast<int>(core::checkpoint_beat(progress_.beat())); }
	// Saving needs no cinematic in progress, and a player in control.
	bool is_safe_to_save() const;
	bool is_in_final_sequence() const { return !core::is_savable(progress_.beat()); }

	// Returns the player to the active checkpoint, in this world.
	void restart_checkpoint();

	// From PuzzleController.solved.
	void on_puzzle_solved();

	// Returns false, leaving the active cinematic alone, if one is already running.
	bool start_cinematic(const godot::StringName &p_clip);
	// Stale and duplicate generations have no effect.
	void finalize_cinematic(int64_t p_generation);
	bool is_cinematic_active() const { return active_.has_value(); }
	int64_t get_generation() const { return generation_; }
	godot::StringName get_active_clip() const { return active_.has_value() ? active_->clip : godot::StringName(); }
	bool has_pending_event() const { return pending_.has_value(); }
	bool is_recovery_pending() const { return recovery_pending_; }
	double get_flee_elapsed() const { return flee_elapsed_; }

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
	void set_camera_rig_path(const godot::NodePath &p_value) { camera_rig_path_ = p_value; }
	godot::NodePath get_camera_rig_path() const { return camera_rig_path_; }
	void set_atmosphere_path(const godot::NodePath &p_value) { atmosphere_path_ = p_value; }
	godot::NodePath get_atmosphere_path() const { return atmosphere_path_; }
	void set_cinematics_path(const godot::NodePath &p_value) { cinematics_path_ = p_value; }
	godot::NodePath get_cinematics_path() const { return cinematics_path_; }
	void set_monolith_gate_path(const godot::NodePath &p_value) { monolith_gate_path_ = p_value; }
	godot::NodePath get_monolith_gate_path() const { return monolith_gate_path_; }
	void set_puzzle_path(const godot::NodePath &p_value) { puzzle_path_ = p_value; }
	godot::NodePath get_puzzle_path() const { return puzzle_path_; }
	void set_mural_path(const godot::NodePath &p_value) { mural_path_ = p_value; }
	godot::NodePath get_mural_path() const { return mural_path_; }
	void set_mural_solved_caption(const godot::String &p_value) { mural_solved_caption_ = p_value; }
	godot::String get_mural_solved_caption() const { return mural_solved_caption_; }
	void set_awakened_visuals(const godot::Array &p_value) { awakened_visual_paths_ = p_value; }
	godot::Array get_awakened_visuals() const { return awakened_visual_paths_; }
	void set_ending_scene(const godot::Ref<godot::PackedScene> &p_value) { ending_scene_ = p_value; }
	godot::Ref<godot::PackedScene> get_ending_scene() const { return ending_scene_; }
	void set_flee_timeout(double p_value) { flee_timeout_ = p_value; }
	double get_flee_timeout() const { return flee_timeout_; }

protected:
	static void _bind_methods();

private:
	enum class EventSource {
		Trigger,
		Internal,
	};

	struct ActiveCinematic {
		godot::StringName clip;
		int64_t generation = 0;
		core::Beat beat = core::Beat::Shore;
		double elapsed = 0.0;
		double deadline = 0.0;
	};

	void on_story_trigger(const godot::StringName &p_trigger_id);
	void on_out_of_bounds(const godot::StringName &p_trigger_id);
	void on_animation_finished(const godot::StringName &p_clip);

	// Applies an event if no cinematic holds it back. True if the story moved.
	bool process_event(core::Event p_event, EventSource p_source);
	void enter_beat(core::Beat p_beat);
	// Idempotent, and plays nothing: the same call serves the end of a cinematic and a restored world.
	void apply_outcome(core::Beat p_beat);
	void after_cinematic(const godot::StringName &p_clip);
	void go_to_ending();
	void schedule_recheck();
	void run_recheck();
	void check_awaited_event();
	void set_player_control(bool p_enabled);
	void restore_camera();
	void open_gate();
	void play_atmosphere(core::Beat p_beat, bool p_instant);
	void consume_trigger(core::Event p_event);
	void report_contract_error(const godot::String &p_message);
	void restore_start_beat();

	godot::NodePath player_path_;
	godot::NodePath hud_path_;
	godot::NodePath kill_plane_path_;
	// In beat order: checkpoint N belongs to beat N.
	godot::Array checkpoint_paths_;
	godot::Array story_trigger_paths_;
	godot::NodePath camera_rig_path_;
	godot::NodePath atmosphere_path_;
	godot::NodePath cinematics_path_;
	godot::NodePath monolith_gate_path_;
	godot::NodePath puzzle_path_;
	godot::NodePath mural_path_;
	godot::String mural_solved_caption_;
	godot::Array awakened_visual_paths_;
	godot::Ref<godot::PackedScene> ending_scene_;
	double flee_timeout_ = 12.0;

	NodeRef<PlayerController> player_;
	NodeRef<Hud> hud_;
	NodeRef<StoryTrigger> kill_plane_;
	NodeRef<CameraRig> camera_rig_;
	NodeRef<godot::AnimationPlayer> atmosphere_;
	NodeRef<godot::AnimationPlayer> cinematics_;
	NodeRef<godot::CollisionObject2D> monolith_gate_;
	NodeRef<PuzzleController> puzzle_;
	NodeRef<Interactable> mural_;
	std::vector<NodeRef<godot::CanvasItem>> awakened_visuals_;
	std::vector<NodeRef<godot::Marker2D>> checkpoints_;
	std::vector<NodeRef<StoryTrigger>> story_triggers_;

	core::StoryProgress progress_;
	int start_beat_ = 0;
	int input_device_ = -1;

	std::optional<ActiveCinematic> active_;
	int64_t generation_ = 0;
	std::optional<core::Event> pending_;
	bool recheck_pending_ = false;
	uint64_t recheck_after_ = 0;
	bool recovery_pending_ = false;
	double flee_elapsed_ = 0.0;
	bool ending_started_ = false;
};

} // namespace dagon
