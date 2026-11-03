#include "global_state.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/scene_tree.hpp>

using namespace godot;

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

} // namespace dagon
