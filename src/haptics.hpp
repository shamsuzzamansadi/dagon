#pragma once

#include <godot_cpp/variant/string_name.hpp>

// Stateless, and all of the game's controller vibration. A cue is brief and replaces any before it, so cues cannot
// stack. Only GameDirector calls these: it knows the device in use, and it stops them on pause, on a change of
// device, and when its world goes away.
namespace dagon::haptics {

// Vibrates the controller in use, if the player allows it. False, with nothing done, for a keyboard, a player who
// has it switched off, or an unknown cue. A controller with no motors ignores the request.
bool play(int p_device, const godot::StringName &p_cue);

void stop(int p_device);

} // namespace dagon::haptics
