#include "input_labels.hpp"

#include "storage.hpp"

#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_joypad_button.hpp>
#include <godot_cpp/classes/input_event_joypad_motion.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#include <cmath>

using namespace godot;

namespace dagon::input_labels {

namespace {

constexpr double STICK_MOVED = 0.5;
// Stands in for the driver's name. Tests have no real controller, and this also shows a layout's labels
// without owning that hardware. It does not make a controller physically verified.
const char *const NAME_OVERRIDE_VARIABLE = "DAGON_TEST_CONTROLLER";

String override_name() {
	return OS::get_singleton()->get_environment(NAME_OVERRIDE_VARIABLE);
}

String controller_name(int p_device) {
	const String name = override_name();
	return name.is_empty() ? Input::get_singleton()->get_joy_name(p_device) : name;
}

int vendor_id(int p_device) {
	Input *input = Input::get_singleton();
	// An event can arrive from a controller that has just gone.
	if (!input->get_connected_joypads().has(p_device)) {
		return 0;
	}
	const Dictionary info = input->get_joy_info(p_device);
	// Some drivers report this as text.
	const Variant vendor = info.get("vendor_id", 0);
	return vendor.get_type() == Variant::STRING ? static_cast<int>(String(vendor).to_int()) : static_cast<int>(vendor);
}

String to_godot(const std::string &p_text) {
	return String::utf8(p_text.c_str());
}

String keyboard_text(const Ref<Font> &p_font) {
	const auto key = [&p_font](const char *p_action) { return storage::key_name(storage::current_key(p_action), p_font); };
	String text = "Keyboard\n";
	text += String("Walk: ") + key("move_left") + " and " + key("move_right") + ", or the Left and Right arrows\n";
	text += String("Jump: ") + key("jump") + "\n";
	text += String("Examine: ") + key("interact") + ", when a prompt appears\n";
	text += "Pause: Esc\n";
	text += "Menus: arrow keys to move, Enter or Space to confirm, Esc for Back";
	return text;
}

// A controller to describe when the keyboard is in use: the first connected one, if any.
int first_connected_controller() {
	if (!override_name().is_empty()) {
		return 0;
	}
	const TypedArray<int> devices = Input::get_singleton()->get_connected_joypads();
	return devices.is_empty() ? KEYBOARD : static_cast<int>(devices[0]);
}

} // namespace

int device_from_event(const Ref<InputEvent> &p_event, int p_current) {
	// Only a press counts: a key let go after picking up the controller says nothing.
	const Ref<InputEventKey> key = p_event;
	if (key.is_valid() && key->is_pressed()) {
		return KEYBOARD;
	}
	const Ref<InputEventJoypadButton> button = p_event;
	if (button.is_valid() && button->is_pressed()) {
		return button->get_device();
	}
	const Ref<InputEventJoypadMotion> motion = p_event;
	// Sticks only, because some drivers report an untouched trigger at full deflection.
	if (motion.is_valid() && motion->get_axis() <= JOY_AXIS_RIGHT_Y && std::abs(motion->get_axis_value()) > STICK_MOVED) {
		return motion->get_device();
	}
	return p_current;
}

core::ControllerFamily family_of(int p_device) {
	return core::controller_family(controller_name(p_device).utf8().get_data(), vendor_id(p_device));
}

void log_controller(int p_device) {
	print_verbose("dagon: controller device=", p_device, " name='", controller_name(p_device), "' vendor=", vendor_id(p_device), " family=", static_cast<int>(family_of(p_device)));
}

String interact_label(int p_device, const Ref<Font> &p_font) {
	if (p_device == KEYBOARD) {
		return storage::key_name(storage::current_key("interact"), p_font);
	}
	return to_godot(core::pad_label_capitalized(family_of(p_device), core::PadButton::West));
}

String controls_text(int p_active_device, bool p_short, const Ref<Font> &p_font) {
	if (p_short) {
		String section = p_active_device == KEYBOARD ? keyboard_text(p_font) : to_godot(core::controller_controls_text(family_of(p_active_device)));
		section += "\n\nAll the controls are under Controls in the pause menu.";
		return section;
	}
	const int described = p_active_device != KEYBOARD ? p_active_device : first_connected_controller();
	const std::string controller = described != KEYBOARD ? core::controller_controls_text(family_of(described)) : core::any_controller_controls_text();
	String text = keyboard_text(p_font) + "\n\n" + to_godot(controller);
	text += "\n\nSettings changes keyboard keys. Controller buttons are fixed.";
	return text;
}

String back_label(int p_device) {
	return p_device == KEYBOARD ? String() : to_godot(core::pad_label(family_of(p_device), core::PadButton::East));
}

} // namespace dagon::input_labels
