#include "global_state.hpp"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/core/print_string.hpp>

using namespace godot;

namespace {

// Measured: a sound stopped two real-time frames before the end was always let go. This is several.
constexpr int64_t QUIT_DELAY_MSEC = 150;
constexpr int64_t QUIT_DELAY_FRAMES = 3;
// The mixer lets a stopped sound go on its next mix, and the main loop frees it in a frame after that. On a busy machine
// that can take longer than any fixed wait, so the quit also waits for a mix that began after the stop, and then for
// these frames; never longer than the cap in all, should the mixer not be running (D130).
constexpr int64_t FRAMES_AFTER_MIX = 3;
constexpr int64_t QUIT_DELAY_MAX_MSEC = 3000;
int64_t quit_requested_at = -1;
int64_t quit_requested_frame = 0;
int64_t mixed_after_stop_frame = -1;

} // namespace

namespace dagon {

bool reset_global_state() {
	bool dirty = false;

	Engine *engine = Engine::get_singleton();
	SceneTree *tree = Object::cast_to<SceneTree>(engine->get_main_loop());
	if (tree != nullptr && tree->is_paused()) {
		tree->set_pause(false);
		dirty = true;
	}
	if (engine->get_time_scale() != 1.0) {
		engine->set_time_scale(1.0);
		dirty = true;
	}
	Input *input = Input::get_singleton();
	if (input->get_mouse_mode() != Input::MOUSE_MODE_VISIBLE) {
		input->set_mouse_mode(Input::MOUSE_MODE_VISIBLE);
		dirty = true;
	}
	return dirty;
}

void stop_all_sound(Node *p_root) {
	if (p_root == nullptr) {
		return;
	}
	for (const char *type : { "AudioStreamPlayer", "AudioStreamPlayer2D" }) {
		const TypedArray<Node> players = p_root->find_children("*", type, true, false);
		for (int i = 0; i < players.size(); i++) {
			Node *player = Object::cast_to<Node>(players[i]);
			if (player != nullptr) {
				player->call("stop");
			}
		}
	}
}

void quit_quietly(SceneTree *p_tree) {
	if (p_tree == nullptr || quit_requested_at >= 0) {
		return;
	}
	stop_all_sound(p_tree->get_root());
	quit_requested_at = static_cast<int64_t>(Time::get_singleton()->get_ticks_msec());
	quit_requested_frame = static_cast<int64_t>(Engine::get_singleton()->get_process_frames());
}

bool is_quit_due() {
	if (quit_requested_at < 0) {
		return false;
	}
	// Wall clock, not game time: a run at a fixed frame rate can pass many frames in a few milliseconds.
	const int64_t waited = static_cast<int64_t>(Time::get_singleton()->get_ticks_msec()) - quit_requested_at;
	const int64_t frame = static_cast<int64_t>(Engine::get_singleton()->get_process_frames());
	if (waited >= QUIT_DELAY_MAX_MSEC) {
		return true;
	}
	if (mixed_after_stop_frame < 0) {
		// The last mix began this long ago; one that began after the stop has taken it into account.
		const double since_mix_msec = AudioServer::get_singleton()->get_time_since_last_mix() * 1000.0;
		if (static_cast<double>(waited) - since_mix_msec > 1.0) {
			mixed_after_stop_frame = frame;
		}
	}
	return waited >= QUIT_DELAY_MSEC && frame - quit_requested_frame >= QUIT_DELAY_FRAMES && mixed_after_stop_frame >= 0 &&
			frame - mixed_after_stop_frame >= FRAMES_AFTER_MIX;
}

bool is_run_over() {
	static const int64_t frames = OS::get_singleton()->get_environment("DAGON_QUIT_AFTER_FRAMES").to_int();
	return frames > 0 && static_cast<int64_t>(Engine::get_singleton()->get_process_frames()) >= frames;
}

namespace {

struct FrameLog {
	bool checked = false;
	double threshold_ms = 0.0;
	uint64_t frame = 0;
	uint64_t last_usec = 0;
	uint64_t second_start_usec = 0;
	int64_t second = 0;
	int64_t count = 0;
	int64_t over_frame_budget = 0;
	double worst_ms = 0.0;
};

FrameLog frame_log;

// Longer than this misses a 30 Hz refresh: a frame the player could see stick.
constexpr double FRAME_BUDGET_MS = 1000.0 / 30.0;

} // namespace

void note_frame() {
	if (!frame_log.checked) {
		frame_log.checked = true;
		frame_log.threshold_ms = OS::get_singleton()->get_environment("DAGON_FRAME_LOG").to_float();
		SceneTree *tree = Object::cast_to<SceneTree>(Engine::get_singleton()->get_main_loop());
		if (frame_log.threshold_ms > 0.0 && tree != nullptr) {
			RenderingServer::get_singleton()->viewport_set_measure_render_time(tree->get_root()->get_viewport_rid(), true);
		}
	}
	if (frame_log.threshold_ms <= 0.0) {
		return;
	}
	const uint64_t frame = Engine::get_singleton()->get_process_frames();
	if (frame_log.last_usec != 0 && frame == frame_log.frame) {
		return;
	}
	frame_log.frame = frame;
	const uint64_t now = Time::get_singleton()->get_ticks_usec();
	if (frame_log.last_usec == 0) {
		frame_log.last_usec = now;
		frame_log.second_start_usec = now;
		return;
	}
	const double ms = static_cast<double>(now - frame_log.last_usec) / 1000.0;
	frame_log.last_usec = now;
	frame_log.count++;
	frame_log.worst_ms = ms > frame_log.worst_ms ? ms : frame_log.worst_ms;
	if (ms > FRAME_BUDGET_MS) {
		frame_log.over_frame_budget++;
	}
	if (ms >= frame_log.threshold_ms) {
		RenderingServer *rendering = RenderingServer::get_singleton();
		SceneTree *tree = Object::cast_to<SceneTree>(Engine::get_singleton()->get_main_loop());
		const RID viewport = tree != nullptr ? tree->get_root()->get_viewport_rid() : RID();
		print_line("dagon: long frame ms=", String::num(ms, 1), " frame=", static_cast<int64_t>(frame), " render_cpu_ms=", String::num(viewport.is_valid() ? rendering->viewport_get_measured_render_time_cpu(viewport) : -1.0, 1), " setup_cpu_ms=", String::num(rendering->get_frame_setup_time_cpu(), 1));
	}
	if (now - frame_log.second_start_usec >= 1000000) {
		print_line("dagon: frames second=", frame_log.second, " count=", frame_log.count, " worst_ms=", String::num(frame_log.worst_ms, 1), " over_33ms=", frame_log.over_frame_budget);
		frame_log.second++;
		frame_log.second_start_usec = now;
		frame_log.count = 0;
		frame_log.over_frame_budget = 0;
		frame_log.worst_ms = 0.0;
	}
}

} // namespace dagon
