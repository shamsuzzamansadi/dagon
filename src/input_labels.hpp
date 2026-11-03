#pragma once

#include "core/controller_labels.hpp"

#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/string.hpp>

// Stateless: what to call a control on screen, for whichever device the player is using.
namespace dagon::input_labels {

inline constexpr int KEYBOARD = -1;

// The device behind this event, or p_current if the event says nothing about who is playing.
int device_from_event(const godot::Ref<godot::InputEvent> &p_event, int p_current);

core::ControllerFamily family_of(int p_device);
void log_controller(int p_device);

// What the Examine prompt asks the player to press.
godot::String interact_label(int p_device, const godot::Ref<godot::Font> &p_font);

// Keyboard and controller, for Controls. The introduction shows only the device in use.
godot::String controls_text(int p_active_device, bool p_short, const godot::Ref<godot::Font> &p_font);

// What cancels a key capture, besides Esc, or empty on a keyboard.
godot::String back_label(int p_device);

} // namespace dagon::input_labels
