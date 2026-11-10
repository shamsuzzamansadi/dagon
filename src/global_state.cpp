#include "global_state.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/classes/time.hpp>

using namespace godot;

namespace {

// Measured: a sound stopped two real-time frames before the end was always let go. This is several.
constexpr int64_t QUIT_DELAY_MSEC = 150;
constexpr int64_t QUIT_DELAY_FRAMES = 3;
int64_t quit_requested_at = -1;
int64_t quit_requested_frame = 0;

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
	const int64_t frames = static_cast<int64_t>(Engine::get_singleton()->get_process_frames()) - quit_requested_frame;
	return waited >= QUIT_DELAY_MSEC && frames >= QUIT_DELAY_FRAMES;
}

bool is_run_over() {
	static const int64_t frames = OS::get_singleton()->get_environment("DAGON_QUIT_AFTER_FRAMES").to_int();
	return frames > 0 && static_cast<int64_t>(Engine::get_singleton()->get_process_frames()) >= frames;
}

} // namespace dagon
