#pragma once

// Plain-C++ rules for naming controller buttons. No Godot headers.
//
// Bindings are by position, so the west button is Interact on every controller. Only its name differs:
// X on Xbox and Square on PlayStation. PlayStation's Cross is a different button, the south one.

#include <string>
#include <string_view>

namespace dagon::core {

enum class ControllerFamily {
	Xbox,
	PlayStation,
	Unknown,
};

// The buttons the game uses, by position. Back is East, confirm and Jump are South, Interact is West.
enum class PadButton {
	South,
	East,
	West,
	Start,
};

// From the name the driver reports and its USB vendor id, or 0 if there is none.
ControllerFamily controller_family(std::string_view p_name, int p_vendor_id);

// As printed on the controller, or a position when the controller is not recognized.
std::string pad_label(ControllerFamily p_family, PadButton p_button);

// The same, for the start of a line or a prompt.
std::string pad_label_capitalized(ControllerFamily p_family, PadButton p_button);

// The controller part of Controls, for one controller.
std::string controller_controls_text(ControllerFamily p_family);

// The same when no controller is connected, naming both recognized layouts.
std::string any_controller_controls_text();

} // namespace dagon::core
