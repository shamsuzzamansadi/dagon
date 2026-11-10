#include "haptics.hpp"

#include "storage.hpp"

#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>

using namespace godot;

namespace dagon::haptics {

namespace {

constexpr int NO_CONTROLLER = -1;

struct Cue {
	const char *name;
	float weak;
	float strong;
	float seconds;
};

// Restrained, and never long: the point is a shudder at the moment, not a rumbling scene.
constexpr Cue CUES[] = {
	{ "awaken", 0.2f, 0.4f, 0.6f },
	{ "reveal", 0.3f, 0.7f, 0.9f },
	{ "collapse", 0.4f, 0.5f, 0.7f },
};

} // namespace

bool play(int p_device, const StringName &p_cue) {
	if (p_device <= NO_CONTROLLER || !storage::vibration_enabled()) {
		return false;
	}
	for (const Cue &cue : CUES) {
		if (p_cue == StringName(cue.name)) {
			Input::get_singleton()->start_joy_vibration(p_device, cue.weak, cue.strong, cue.seconds);
			print_verbose("dagon: vibration cue=", p_cue, " device=", p_device);
			return true;
		}
	}
	ERR_PRINT(String("haptics: there is no cue named '") + String(p_cue) + "'.");
	return false;
}

void stop(int p_device) {
	if (p_device > NO_CONTROLLER) {
		Input::get_singleton()->stop_joy_vibration(p_device);
	}
}

} // namespace dagon::haptics
