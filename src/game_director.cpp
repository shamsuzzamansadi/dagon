#include "game_director.hpp"

#include "global_state.hpp"
#include "haptics.hpp"
#include "menu_controller.hpp"

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>

#include <algorithm>
#include <cmath>
#include <limits>

using namespace godot;

namespace dagon {

namespace {

const char *const CLIP_AWAKEN = "monolith_awaken";
const char *const CLIP_REVEAL = "dagon_reveal";
const char *const CLIP_COLLAPSE = "collapse";
const char *const LINE_MONOLITH = "monolith.first";

// A clip gets its own length and this long again before the watchdog ends it.
constexpr double WATCHDOG_MARGIN_SECONDS = 2.0;
constexpr int WORLD_COLLISION_LAYER = 1;

// Measured on 4.7.2 (docs/evidence/m3/overlap-latency.txt). A body moved in the physics phase of frame F is in the
// overlap list at F + 2. One moved in the idle phase of F, which is where a clip ends, is only there at F + 3, as
// that frame's server step has already gone by. Three covers both.
constexpr uint64_t RECHECK_FRAMES = 3;

const char *atmosphere_clip(core::Beat p_beat) {
	switch (p_beat) {
		case core::Beat::Shore:
			return "beat_shore";
		case core::Beat::Abyss:
			return "beat_abyss";
		case core::Beat::Monolith:
		case core::Beat::Awakened:
			return "beat_monolith";
		case core::Beat::Witness:
			return "beat_witness";
		case core::Beat::Fleeing:
			return "beat_fleeing";
		case core::Beat::Ended:
			break;
	}
	return "";
}

} // namespace

void GameDirector::_bind_methods() {
	ClassDB::bind_method(D_METHOD("restart_checkpoint"), &GameDirector::restart_checkpoint);
	ClassDB::bind_method(D_METHOD("get_active_checkpoint"), &GameDirector::get_active_checkpoint);
	ClassDB::bind_method(D_METHOD("get_beat"), &GameDirector::get_beat);
	ClassDB::bind_method(D_METHOD("is_safe_to_save"), &GameDirector::is_safe_to_save);
	ClassDB::bind_method(D_METHOD("is_in_final_sequence"), &GameDirector::is_in_final_sequence);
	ClassDB::bind_method(D_METHOD("set_start_beat", "beat"), &GameDirector::set_start_beat);
	ClassDB::bind_method(D_METHOD("get_start_beat"), &GameDirector::get_start_beat);
	ClassDB::bind_method(D_METHOD("fade_in"), &GameDirector::fade_in);
	ClassDB::bind_method(D_METHOD("show_notice", "text"), &GameDirector::show_notice);
	ClassDB::bind_method(D_METHOD("on_puzzle_solved"), &GameDirector::on_puzzle_solved);
	ClassDB::bind_method(D_METHOD("start_cinematic", "clip"), &GameDirector::start_cinematic);
	ClassDB::bind_method(D_METHOD("finalize_cinematic", "generation"), &GameDirector::finalize_cinematic);
	ClassDB::bind_method(D_METHOD("is_cinematic_active"), &GameDirector::is_cinematic_active);
	ClassDB::bind_method(D_METHOD("get_generation"), &GameDirector::get_generation);
	ClassDB::bind_method(D_METHOD("get_active_clip"), &GameDirector::get_active_clip);
	ClassDB::bind_method(D_METHOD("has_pending_event"), &GameDirector::has_pending_event);
	ClassDB::bind_method(D_METHOD("is_recovery_pending"), &GameDirector::is_recovery_pending);
	ClassDB::bind_method(D_METHOD("get_flee_elapsed"), &GameDirector::get_flee_elapsed);
	ClassDB::bind_method(D_METHOD("get_tide_front"), &GameDirector::get_tide_front);
	ClassDB::bind_method(D_METHOD("is_crossing_lowered"), &GameDirector::is_crossing_lowered);
	ClassDB::bind_method(D_METHOD("is_crossing_moving"), &GameDirector::is_crossing_moving);
	ClassDB::bind_method(D_METHOD("haptic_cue", "cue"), &GameDirector::haptic_cue);

#define DAGON_BIND_PATH(m_name, m_type)                                                  \
	ClassDB::bind_method(D_METHOD("set_" #m_name, "path"), &GameDirector::set_##m_name); \
	ClassDB::bind_method(D_METHOD("get_" #m_name), &GameDirector::get_##m_name);         \
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, #m_name, PROPERTY_HINT_NODE_PATH_VALID_TYPES, m_type), "set_" #m_name, "get_" #m_name)

	DAGON_BIND_PATH(player_path, "PlayerController");
	DAGON_BIND_PATH(hud_path, "Hud");
	DAGON_BIND_PATH(kill_plane_path, "StoryTrigger");
	DAGON_BIND_PATH(camera_rig_path, "CameraRig");
	DAGON_BIND_PATH(atmosphere_path, "AnimationPlayer");
	DAGON_BIND_PATH(cinematics_path, "AnimationPlayer");
	DAGON_BIND_PATH(monolith_gate_path, "CollisionObject2D");
	DAGON_BIND_PATH(rockfall_path, "CollisionObject2D");
	DAGON_BIND_PATH(puzzle_path, "PuzzleController");
	DAGON_BIND_PATH(mural_path, "Interactable");
	DAGON_BIND_PATH(background_path, "AnimationPlayer");
	DAGON_BIND_PATH(tide_path, "Node2D");
	DAGON_BIND_PATH(crossing_path, "Node2D");
	DAGON_BIND_PATH(crossing_trigger_path, "StoryTrigger");
	DAGON_BIND_PATH(crossing_sound_path, "AudioStreamPlayer2D");
	DAGON_BIND_PATH(breath_path, "AudioStreamPlayer2D");

#undef DAGON_BIND_PATH

	ClassDB::bind_method(D_METHOD("set_checkpoints", "paths"), &GameDirector::set_checkpoints);
	ClassDB::bind_method(D_METHOD("get_checkpoints"), &GameDirector::get_checkpoints);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "checkpoints"), "set_checkpoints", "get_checkpoints");
	ClassDB::bind_method(D_METHOD("set_story_triggers", "paths"), &GameDirector::set_story_triggers);
	ClassDB::bind_method(D_METHOD("get_story_triggers"), &GameDirector::get_story_triggers);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "story_triggers"), "set_story_triggers", "get_story_triggers");
	ClassDB::bind_method(D_METHOD("set_awakened_visuals", "paths"), &GameDirector::set_awakened_visuals);
	ClassDB::bind_method(D_METHOD("get_awakened_visuals"), &GameDirector::get_awakened_visuals);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "awakened_visuals"), "set_awakened_visuals", "get_awakened_visuals");
	ClassDB::bind_method(D_METHOD("set_background_triggers", "paths"), &GameDirector::set_background_triggers);
	ClassDB::bind_method(D_METHOD("get_background_triggers"), &GameDirector::get_background_triggers);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "background_triggers"), "set_background_triggers", "get_background_triggers");
	ClassDB::bind_method(D_METHOD("set_mural_solved_line", "id"), &GameDirector::set_mural_solved_line);
	ClassDB::bind_method(D_METHOD("get_mural_solved_line"), &GameDirector::get_mural_solved_line);
	ADD_PROPERTY(PropertyInfo(Variant::STRING_NAME, "mural_solved_line"), "set_mural_solved_line", "get_mural_solved_line");
	ClassDB::bind_method(D_METHOD("set_ending_scene", "scene"), &GameDirector::set_ending_scene);
	ClassDB::bind_method(D_METHOD("get_ending_scene"), &GameDirector::get_ending_scene);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "ending_scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_ending_scene", "get_ending_scene");
	ClassDB::bind_method(D_METHOD("set_flee_timeout", "seconds"), &GameDirector::set_flee_timeout);
	ClassDB::bind_method(D_METHOD("get_flee_timeout"), &GameDirector::get_flee_timeout);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "flee_timeout"), "set_flee_timeout", "get_flee_timeout");

#define DAGON_BIND_FLOAT(m_name)                                                          \
	ClassDB::bind_method(D_METHOD("set_" #m_name, "value"), &GameDirector::set_##m_name); \
	ClassDB::bind_method(D_METHOD("get_" #m_name), &GameDirector::get_##m_name);          \
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, #m_name), "set_" #m_name, "get_" #m_name)

	DAGON_BIND_FLOAT(tide_start_x);
	DAGON_BIND_FLOAT(tide_speed);
	DAGON_BIND_FLOAT(tide_delay);
	DAGON_BIND_FLOAT(flee_look_ahead);
	DAGON_BIND_FLOAT(crossing_raised_rotation);
	DAGON_BIND_FLOAT(crossing_lower_seconds);

#undef DAGON_BIND_FLOAT

	ClassDB::bind_method(D_METHOD("set_breath_streams", "streams"), &GameDirector::set_breath_streams);
	ClassDB::bind_method(D_METHOD("get_breath_streams"), &GameDirector::get_breath_streams);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "breath_streams"), "set_breath_streams", "get_breath_streams");
	ClassDB::bind_method(D_METHOD("set_crossing_line", "id"), &GameDirector::set_crossing_line);
	ClassDB::bind_method(D_METHOD("get_crossing_line"), &GameDirector::get_crossing_line);
	ADD_PROPERTY(PropertyInfo(Variant::STRING_NAME, "crossing_line"), "set_crossing_line", "get_crossing_line");
	ClassDB::bind_method(D_METHOD("set_idle_speeds", "speeds"), &GameDirector::set_idle_speeds);
	ClassDB::bind_method(D_METHOD("get_idle_speeds"), &GameDirector::get_idle_speeds);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "idle_speeds"), "set_idle_speeds", "get_idle_speeds");

	ADD_SIGNAL(MethodInfo("checkpoint_reached", PropertyInfo(Variant::INT, "index")));
	ADD_SIGNAL(MethodInfo("player_respawned"));
	ADD_SIGNAL(MethodInfo("beat_changed", PropertyInfo(Variant::INT, "beat")));
	ADD_SIGNAL(MethodInfo("cinematic_started", PropertyInfo(Variant::STRING_NAME, "clip"), PropertyInfo(Variant::INT, "generation")));
	ADD_SIGNAL(MethodInfo("cinematic_finalized", PropertyInfo(Variant::STRING_NAME, "clip"), PropertyInfo(Variant::INT, "generation")));
	ADD_SIGNAL(MethodInfo("overlap_rechecked", PropertyInfo(Variant::INT, "physics_frame")));
	ADD_SIGNAL(MethodInfo("contract_error", PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("background_event_started", PropertyInfo(Variant::STRING_NAME, "event")));
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
	camera_rig_.set(camera_rig_path_.is_empty() ? nullptr : get_node<CameraRig>(camera_rig_path_));
	atmosphere_.set(atmosphere_path_.is_empty() ? nullptr : get_node<AnimationPlayer>(atmosphere_path_));
	cinematics_.set(cinematics_path_.is_empty() ? nullptr : get_node<AnimationPlayer>(cinematics_path_));
	background_.set(background_path_.is_empty() ? nullptr : get_node<AnimationPlayer>(background_path_));
	monolith_gate_.set(monolith_gate_path_.is_empty() ? nullptr : get_node<CollisionObject2D>(monolith_gate_path_));
	rockfall_.set(rockfall_path_.is_empty() ? nullptr : get_node<CollisionObject2D>(rockfall_path_));
	tide_node_.set(tide_path_.is_empty() ? nullptr : get_node<Node2D>(tide_path_));
	crossing_.set(crossing_path_.is_empty() ? nullptr : get_node<Node2D>(crossing_path_));
	crossing_sound_.set(crossing_sound_path_.is_empty() ? nullptr : get_node<AudioStreamPlayer2D>(crossing_sound_path_));
	breath_.set(breath_path_.is_empty() ? nullptr : get_node<AudioStreamPlayer2D>(breath_path_));
	if (Node2D *crossing = crossing_.get()) {
		crossing->set_rotation(crossing_raised_rotation_);
	}
	if (!crossing_trigger_path_.is_empty()) {
		if (StoryTrigger *trigger = get_node<StoryTrigger>(crossing_trigger_path_)) {
			crossing_trigger_.set(trigger);
			trigger->connect("triggered", callable_mp(this, &GameDirector::on_crossing_trigger));
		} else {
			ERR_PRINT("GameDirector: crossing_trigger_path does not point to a StoryTrigger.");
		}
	}
	puzzle_.set(puzzle_path_.is_empty() ? nullptr : get_node<PuzzleController>(puzzle_path_));
	mural_.set(mural_path_.is_empty() ? nullptr : get_node<Interactable>(mural_path_));

	for (int i = 0; i < awakened_visual_paths_.size(); i++) {
		NodeRef<CanvasItem> visual;
		visual.set(get_node<CanvasItem>(awakened_visual_paths_[i]));
		if (visual.get() == nullptr) {
			ERR_PRINT("GameDirector: an entry in awakened_visuals does not point to a CanvasItem.");
		}
		awakened_visuals_.push_back(visual);
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

	for (int i = 0; i < background_trigger_paths_.size(); i++) {
		NodeRef<StoryTrigger> trigger;
		trigger.set(get_node<StoryTrigger>(background_trigger_paths_[i]));
		if (StoryTrigger *background_trigger = trigger.get()) {
			background_trigger->connect("triggered", callable_mp(this, &GameDirector::on_background_trigger));
		} else {
			ERR_PRINT("GameDirector: an entry in background_triggers does not point to a StoryTrigger.");
		}
		background_triggers_.push_back(trigger);
	}

	if (!kill_plane_path_.is_empty()) {
		if (StoryTrigger *kill_plane = get_node<StoryTrigger>(kill_plane_path_)) {
			kill_plane_.set(kill_plane);
			kill_plane->connect("triggered", callable_mp(this, &GameDirector::on_out_of_bounds));
		} else {
			ERR_PRINT("GameDirector: kill_plane_path does not point to a StoryTrigger.");
		}
	}

	if (AnimationPlayer *cinematics = cinematics_.get()) {
		cinematics->connect("animation_finished", callable_mp(this, &GameDirector::on_animation_finished));
	}

	restore_start_beat();
}

// The one restore path. A new game comes through here too, at the first beat.
void GameDirector::restore_start_beat() {
	const core::Beat beat = static_cast<core::Beat>(start_beat_);
	if (!progress_.restore(beat)) {
		ERR_PRINT("GameDirector: the start beat may not be restored; starting at the first checkpoint.");
		return;
	}
	// Each outcome is applied directly. Nothing is emitted and no clip plays, so no event can replay.
	for (int reached = 0; reached <= start_beat_; reached++) {
		apply_outcome(static_cast<core::Beat>(reached));
	}
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
	// What lies behind this checkpoint stays behind it. What lies ahead has not happened yet in this world.
	for (const NodeRef<StoryTrigger> &reference : background_triggers_) {
		StoryTrigger *trigger = reference.get();
		if (trigger != nullptr && trigger->get_spent_from_beat() <= start_beat_) {
			trigger->set_enabled(false);
		}
	}
	play_atmosphere(beat, true);
	play_breath(beat);
	PlayerController *player = player_.get();
	const std::size_t index = static_cast<std::size_t>(start_beat_);
	if (start_beat_ > 0 && player != nullptr && index < checkpoints_.size()) {
		if (const Marker2D *checkpoint = checkpoints_[index].get()) {
			player->teleport(checkpoint->get_global_position());
		}
	}
	schedule_recheck();
}

PackedStringArray GameDirector::_get_configuration_warnings() const {
	PackedStringArray warnings = Node::_get_configuration_warnings();
	if (player_path_.is_empty()) {
		warnings.push_back("player_path is not set, so the player cannot be respawned.");
	}
	if (checkpoint_paths_.is_empty()) {
		warnings.push_back("checkpoints is empty, so there is nowhere to respawn.");
	}
	if (cinematics_path_.is_empty()) {
		warnings.push_back("cinematics_path is not set, so every cinematic reports a missing clip.");
	}
	if (monolith_gate_path_.is_empty()) {
		warnings.push_back("monolith_gate_path is not set, so the gate cannot open.");
	}
	if (ending_scene_.is_null()) {
		warnings.push_back("ending_scene is not set, so the game cannot end.");
	}
	return warnings;
}

void GameDirector::_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	// Both clocks stop with the tree, so pausing holds the watchdog and the flee alike.
	if (active_.has_value()) {
		active_->elapsed += p_delta;
		if (active_->elapsed >= active_->deadline) {
			report_contract_error(String("GameDirector: cinematic '") + active_->clip + "' passed its deadline.");
			finalize_cinematic(active_->generation);
		}
		return;
	}
	if (progress_.beat() == core::Beat::Fleeing) {
		update_flee(p_delta);
	}
}

// The consequence is decided here, in code: the water's picture only follows it, so a missing one changes nothing.
void GameDirector::update_flee(double p_delta) {
	flee_elapsed_ += p_delta;
	const float front = core::tide_front(tide_, flee_elapsed_);
	if (Node2D *tide = tide_node_.get()) {
		tide->set_global_position(Vector2(front, tide->get_global_position().y));
	}
	const PlayerController *player = player_.get();
	const float sailor_x = player != nullptr ? static_cast<float>(player->get_global_position().x) : -std::numeric_limits<float>::infinity();
	const core::FleeEnd end = core::flee_end(tide_, flee_elapsed_, sailor_x, flee_timeout_);
	if (end == core::FleeEnd::None) {
		return;
	}
	print_verbose("dagon: flee ended by ", end == core::FleeEnd::Overtaken ? "the sea" : "the fallback", " after ", flee_elapsed_, " s");
	process_event(core::Event::FleeTimeout, EventSource::Internal);
}

void GameDirector::_notification(int p_what) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	// A cue is never resumed: it belongs to a moment, and that moment has gone by.
	if (p_what == NOTIFICATION_PAUSED || p_what == NOTIFICATION_EXIT_TREE) {
		haptics::stop(input_device_);
	}
}

void GameDirector::_physics_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	update_crossing(p_delta);
	// Starting a cinematic clears the flag, so this can never run during one.
	if (!recheck_pending_) {
		return;
	}
	const uint64_t frame = Engine::get_singleton()->get_physics_frames();
	if (frame < recheck_after_ + RECHECK_FRAMES) {
		return;
	}
	recheck_pending_ = false;
	emit_signal("overlap_rechecked", static_cast<int64_t>(frame));
	run_recheck();
}

void GameDirector::schedule_recheck() {
	recheck_after_ = Engine::get_singleton()->get_physics_frames();
	recheck_pending_ = true;
}

void GameDirector::run_recheck() {
	check_awaited_event();
	// A new cinematic keeps any recovery waiting, and its own finalization schedules another recheck.
	if (active_.has_value() || progress_.beat() == core::Beat::Ended) {
		return;
	}
	const StoryTrigger *kill_plane = kill_plane_.get();
	if (recovery_pending_ || (kill_plane != nullptr && kill_plane->is_player_inside())) {
		recovery_pending_ = false;
		restart_checkpoint();
	}
}

void GameDirector::check_awaited_event() {
	const core::Beat beat = progress_.beat();
	// Should the stones ever be solved before this beat began, it is taken up here and no one is stuck.
	if (beat == core::Beat::Monolith) {
		const PuzzleController *puzzle = puzzle_.get();
		if (puzzle != nullptr && puzzle->is_solved()) {
			process_event(core::Event::PuzzleSolved, EventSource::Internal);
		}
		return;
	}
	const StringName awaited = core::awaited_trigger(beat);
	if (awaited.is_empty()) {
		return;
	}
	for (const NodeRef<StoryTrigger> &reference : story_triggers_) {
		const StoryTrigger *trigger = reference.get();
		if (trigger != nullptr && trigger->get_trigger_id() == awaited && trigger->is_enabled() && trigger->is_player_inside()) {
			on_story_trigger(awaited);
			return;
		}
	}
}

void GameDirector::on_story_trigger(const StringName &p_trigger_id) {
	const String id = p_trigger_id;
	const std::optional<core::Event> event = core::event_for_trigger(id.utf8().get_data());
	if (event.has_value()) {
		process_event(*event, EventSource::Trigger);
	}
}

// Presentation only: nothing waits on these, and nothing depends on them. One at a time, and none during a cinematic.
// A trigger met at such a moment stays armed for the next time the player crosses it.
void GameDirector::on_background_trigger(const StringName &p_trigger_id) {
	AnimationPlayer *background = background_.get();
	if (active_.has_value() || background == nullptr || background->is_playing()) {
		return;
	}
	if (!background->has_animation(p_trigger_id)) {
		ERR_PRINT(String("GameDirector: no background clip for the trigger '") + String(p_trigger_id) + "'.");
		return;
	}
	for (const NodeRef<StoryTrigger> &reference : background_triggers_) {
		StoryTrigger *trigger = reference.get();
		if (trigger != nullptr && trigger->get_trigger_id() == p_trigger_id) {
			trigger->set_enabled(false);
		}
	}
	print_verbose("dagon: background event: ", p_trigger_id);
	emit_signal("background_event_started", p_trigger_id);
	background->play(p_trigger_id);
}

// A weight on its raised end brings the slab down level. It stays down, and nothing is saved: from the Monolith on,
// the world is rebuilt with it down, as everyone who got there crossed it.
void GameDirector::on_crossing_trigger(const StringName &p_trigger_id) {
	(void)p_trigger_id;
	lower_crossing(false);
}

void GameDirector::lower_crossing(bool p_instant) {
	if (StoryTrigger *trigger = crossing_trigger_.get()) {
		trigger->set_enabled(false);
	}
	Node2D *crossing = crossing_.get();
	if (p_instant) {
		crossing_lowered_ = true;
		crossing_moving_ = false;
		if (crossing != nullptr) {
			crossing->set_rotation(0.0f);
		}
		return;
	}
	// Already down, or on its way: a second weight changes nothing, and plays nothing.
	if (crossing_lowered_) {
		return;
	}
	crossing_lowered_ = true;
	print_verbose("dagon: crossing lowered");
	if (crossing == nullptr || crossing_lower_seconds_ <= 0.0f) {
		if (crossing != nullptr) {
			crossing->set_rotation(0.0f);
		}
		return;
	}
	crossing_moving_ = true;
	crossing_elapsed_ = 0.0;
	if (AudioStreamPlayer2D *sound = crossing_sound_.get()) {
		sound->play();
	}
	if (Hud *hud = hud_.get(); hud != nullptr && !crossing_line_.is_empty()) {
		hud->say(crossing_line_);
	}
}

void GameDirector::update_crossing(double p_delta) {
	if (!crossing_moving_) {
		return;
	}
	crossing_elapsed_ += p_delta;
	const double t = std::clamp(crossing_elapsed_ / static_cast<double>(crossing_lower_seconds_), 0.0, 1.0);
	// Slow to start, then down hard: something heavy giving way.
	const double eased = t * t;
	if (Node2D *crossing = crossing_.get()) {
		crossing->set_rotation(static_cast<float>(static_cast<double>(crossing_raised_rotation_) * (1.0 - eased)));
	}
	if (t >= 1.0) {
		crossing_moving_ = false;
		if (CameraRig *camera = camera_rig_.get()) {
			camera->add_trauma(0.45f);
		}
	}
}

void GameDirector::play_breath(core::Beat p_beat) {
	const int index = static_cast<int>(p_beat);
	if (PlayerController *player = player_.get(); player != nullptr && index < idle_speeds_.size()) {
		player->set_idle_speed(idle_speeds_[index]);
	}
	AudioStreamPlayer2D *breath = breath_.get();
	if (breath == nullptr) {
		return;
	}
	const Ref<AudioStream> stream = index < breath_streams_.size() ? Ref<AudioStream>(breath_streams_[index]) : Ref<AudioStream>();
	if (stream.is_null()) {
		breath->stop();
		return;
	}
	if (breath->get_stream() == stream && breath->is_playing()) {
		return;
	}
	breath->set_stream(stream);
	breath->play();
}

void GameDirector::on_puzzle_solved() {
	process_event(core::Event::PuzzleSolved, EventSource::Internal);
}

bool GameDirector::process_event(core::Event p_event, EventSource p_source) {
	if (active_.has_value()) {
		// A trigger is dropped and stays armed: the recheck after finalization finds it again.
		if (p_source == EventSource::Internal) {
			if (pending_.has_value()) {
				report_contract_error("GameDirector: more than one event pending during a cinematic.");
			} else {
				pending_ = p_event;
			}
		}
		return false;
	}
	// A rejection changes nothing, and the trigger stays armed.
	const std::optional<core::Beat> beat = progress_.apply(p_event);
	if (!beat.has_value()) {
		print_verbose("dagon: event rejected at beat=", core::beat_name(progress_.beat()));
		return false;
	}
	consume_trigger(p_event);
	enter_beat(*beat);
	return true;
}

void GameDirector::consume_trigger(core::Event p_event) {
	for (const NodeRef<StoryTrigger> &reference : story_triggers_) {
		StoryTrigger *trigger = reference.get();
		if (trigger == nullptr) {
			continue;
		}
		const String id = trigger->get_trigger_id();
		if (core::event_for_trigger(id.utf8().get_data()) == p_event) {
			trigger->set_enabled(false);
		}
	}
}

void GameDirector::enter_beat(core::Beat p_beat) {
	play_breath(p_beat);
	print_verbose("dagon: beat=", core::beat_name(p_beat));
	emit_signal("beat_changed", static_cast<int>(p_beat));
	switch (p_beat) {
		case core::Beat::Shore:
			break;
		case core::Beat::Abyss:
		case core::Beat::Monolith:
			play_atmosphere(p_beat, false);
			apply_outcome(p_beat);
			emit_signal("checkpoint_reached", static_cast<int>(p_beat));
			// Only here, on the way in. A world restored at this beat does not come through this path.
			if (p_beat == core::Beat::Monolith) {
				if (Hud *hud = hud_.get()) {
					hud->say(LINE_MONOLITH);
				}
			}
			schedule_recheck();
			break;
		case core::Beat::Awakened:
			start_cinematic(CLIP_AWAKEN);
			break;
		case core::Beat::Witness:
			play_atmosphere(p_beat, false);
			start_cinematic(CLIP_REVEAL);
			break;
		case core::Beat::Fleeing:
			play_atmosphere(p_beat, false);
			apply_outcome(p_beat);
			schedule_recheck();
			break;
		case core::Beat::Ended:
			start_cinematic(CLIP_COLLAPSE);
			break;
	}
}

void GameDirector::apply_outcome(core::Beat p_beat) {
	switch (p_beat) {
		case core::Beat::Monolith:
			lower_crossing(true);
			break;
		case core::Beat::Awakened:
			open_gate();
			if (PuzzleController *puzzle = puzzle_.get()) {
				puzzle->restore_solved();
			}
			if (Interactable *mural = mural_.get()) {
				mural->use_line(mural_solved_line_);
			}
			for (const NodeRef<CanvasItem> &reference : awakened_visuals_) {
				if (CanvasItem *visual = reference.get()) {
					visual->set_visible(true);
					visual->set_modulate(Color(1, 1, 1, 1));
				}
			}
			break;
		case core::Beat::Fleeing:
			set_player_control(true);
			flee_elapsed_ = 0.0;
			// The cue to run: he turns back the way he came, and the camera leads that way.
			if (PlayerController *player = player_.get()) {
				player->face(-1);
			}
			bring_down_rockfall();
			if (Node2D *tide = tide_node_.get()) {
				tide->set_global_position(Vector2(core::tide_front(tide_, 0.0), tide->get_global_position().y));
				tide->set_visible(true);
			}
			// The camera looks back the way he came, toward what is following him.
			if (CameraRig *camera = camera_rig_.get()) {
				camera->set_look_ahead(flee_look_ahead_);
			}
			break;
		case core::Beat::Shore:
		case core::Beat::Abyss:
		case core::Beat::Witness:
		case core::Beat::Ended:
			break;
	}
}

void GameDirector::open_gate() {
	if (CollisionObject2D *gate = monolith_gate_.get()) {
		// Deferred: this can run from inside a physics callback, where the server refuses state changes.
		gate->set_deferred("collision_layer", 0);
		gate->set_visible(false);
	}
}

void GameDirector::bring_down_rockfall() {
	if (CollisionObject2D *rockfall = rockfall_.get()) {
		// Deferred like the gate. He is on the ledge, so none of it can land on him.
		rockfall->set_deferred("collision_layer", WORLD_COLLISION_LAYER);
		rockfall->set_visible(true);
	}
}

bool GameDirector::start_cinematic(const StringName &p_clip) {
	if (active_.has_value()) {
		// Only a bug can reach this, as events do not apply during a cinematic. The active one is left alone.
		report_contract_error(String("GameDirector: cinematic '") + p_clip + "' refused, because '" + active_->clip + "' is active.");
		return false;
	}
	generation_++;
	ActiveCinematic record;
	record.clip = p_clip;
	record.generation = generation_;
	record.beat = progress_.beat();
	active_ = record;
	recheck_pending_ = false;
	set_player_control(false);
	print_verbose("dagon: cinematic start clip=", p_clip, " generation=", generation_);
	emit_signal("cinematic_started", p_clip, generation_);

	AnimationPlayer *player = cinematics_.get();
	const Ref<Animation> animation = (player != nullptr && player->has_animation(p_clip)) ? player->get_animation(p_clip) : Ref<Animation>();
	if (animation.is_null()) {
		report_contract_error(String("GameDirector: cinematic clip '") + p_clip + "' is missing.");
		finalize_cinematic(generation_);
		return true;
	}
	if (animation->get_loop_mode() != Animation::LOOP_NONE) {
		report_contract_error(String("GameDirector: cinematic clip '") + p_clip + "' loops, so it would never end.");
		finalize_cinematic(generation_);
		return true;
	}
	active_->deadline = animation->get_length() + WATCHDOG_MARGIN_SECONDS;
	player->play(p_clip);
	return true;
}

void GameDirector::on_animation_finished(const StringName &p_clip) {
	if (active_.has_value() && p_clip == active_->clip) {
		finalize_cinematic(active_->generation);
	}
}

void GameDirector::finalize_cinematic(int64_t p_generation) {
	if (!active_.has_value() || p_generation != active_->generation) {
		return;
	}
	const ActiveCinematic finished = *active_;
	// Stopped first, so a method track left in a stuck clip cannot move the camera afterwards.
	AnimationPlayer *player = cinematics_.get();
	if (player != nullptr && player->get_assigned_animation() == finished.clip) {
		player->stop(true);
	}
	apply_outcome(finished.beat);
	restore_camera();
	set_player_control(core::has_player_control(finished.beat));
	active_.reset();
	print_verbose("dagon: cinematic finalized clip=", finished.clip, " generation=", finished.generation);
	emit_signal("cinematic_finalized", finished.clip, finished.generation);
	if (finished.clip == StringName(CLIP_AWAKEN)) {
		emit_signal("checkpoint_reached", static_cast<int>(finished.beat));
	}
	// Never synchronous, so that a beat started next cannot be overwritten by this finalizer.
	callable_mp(this, &GameDirector::after_cinematic).call_deferred(finished.clip);
}

void GameDirector::after_cinematic(const StringName &p_clip) {
	// A world replaced in this same frame is out of the tree by now, and has no say in anything.
	if (!is_inside_tree()) {
		return;
	}
	// The scene change is the Ended beat's outcome. It happens here and not in the finalizer, which can be
	// running inside a physics callback, because the tree takes the current scene out at once.
	if (progress_.beat() == core::Beat::Ended) {
		if (p_clip == StringName(CLIP_COLLAPSE)) {
			go_to_ending();
		}
		return;
	}
	if (p_clip == StringName(CLIP_REVEAL)) {
		process_event(core::Event::RevealDone, EventSource::Internal);
		if (active_.has_value()) {
			return;
		}
	}
	if (pending_.has_value()) {
		const core::Event event = *pending_;
		pending_.reset();
		process_event(event, EventSource::Internal);
		if (active_.has_value()) {
			return;
		}
	}
	// call_deferred runs in this frame's flush, with overlap lists from before the camera and player moved.
	schedule_recheck();
}

void GameDirector::go_to_ending() {
	if (ending_started_) {
		return;
	}
	ending_started_ = true;
	if (ending_scene_.is_null()) {
		ERR_PRINT("GameDirector: ending_scene is not set; the pause menu is the only way on from here.");
		return;
	}
	reset_global_state();
	Node *ending = ending_scene_->instantiate();
	ERR_FAIL_NULL_MSG(ending, "GameDirector: ending_scene could not be instantiated.");
	if (MenuController *menu = Object::cast_to<MenuController>(ending)) {
		menu->set_active_device(input_device_);
	}
	print_verbose("dagon: ending");
	get_tree()->change_scene_to_node(ending);
}

void GameDirector::set_player_control(bool p_enabled) {
	if (PlayerController *player = player_.get()) {
		player->set_control_enabled(p_enabled);
	}
}

void GameDirector::restore_camera() {
	if (CameraRig *camera = camera_rig_.get()) {
		camera->restore_view(player_.get());
	}
}

void GameDirector::play_atmosphere(core::Beat p_beat, bool p_instant) {
	AnimationPlayer *atmosphere = atmosphere_.get();
	const StringName clip = atmosphere_clip(p_beat);
	// Nothing waits on these, and nothing depends on them.
	if (atmosphere == nullptr || !atmosphere->has_animation(clip)) {
		return;
	}
	atmosphere->play(clip);
	if (p_instant) {
		// Straight to where the clip ends. Its method keys are skipped, so no cue plays.
		atmosphere->seek(atmosphere->get_animation(clip)->get_length(), true);
		atmosphere->stop(true);
	}
}

void GameDirector::on_out_of_bounds(const StringName &p_trigger_id) {
	(void)p_trigger_id;
	// Gravity still applies during a cinematic, so a locked player can fall too. Not lost, only delayed.
	if (active_.has_value()) {
		recovery_pending_ = true;
		return;
	}
	restart_checkpoint();
}

bool GameDirector::is_safe_to_save() const {
	const PlayerController *player = player_.get();
	return !active_.has_value() && (player == nullptr || player->is_control_enabled());
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

void GameDirector::haptic_cue(const StringName &p_cue) {
	haptics::play(input_device_, p_cue);
}

void GameDirector::set_input_device(int p_device) {
	if (p_device != input_device_) {
		haptics::stop(input_device_);
	}
	input_device_ = p_device;
	if (Hud *hud = hud_.get()) {
		hud->set_input_device(p_device);
	}
}

void GameDirector::show_notice(const String &p_text) {
	if (Hud *hud = hud_.get()) {
		hud->show_notice(p_text);
	}
}

void GameDirector::report_contract_error(const String &p_message) {
	ERR_PRINT(p_message);
	emit_signal("contract_error", p_message);
}

} // namespace dagon
