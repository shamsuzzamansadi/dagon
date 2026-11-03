#include "core/controller_labels.hpp"

#include "doctest.h"

#include <string>

using namespace dagon::core;

TEST_CASE("names that drivers report are recognized, whatever their case") {
	for (const char *const name : { "Xbox Series Controller", "Xbox 360 Controller", "XInput Gamepad", "XInput Controller", "XBOX ONE CONTROLLER", "Microsoft X-Box pad" }) {
		CHECK(controller_family(name, 0) == ControllerFamily::Xbox);
	}
	for (const char *const name : { "PS5 Controller", "PS4 Controller", "PS3 Controller", "DualSense Wireless Controller", "Sony DualShock 4", "PLAYSTATION(R)3 Controller" }) {
		CHECK(controller_family(name, 0) == ControllerFamily::PlayStation);
	}
}

TEST_CASE("the vendor id settles a name that says nothing") {
	CHECK(controller_family("Wireless Controller", 0x054C) == ControllerFamily::PlayStation);
	CHECK(controller_family("Gamepad", 0x045E) == ControllerFamily::Xbox);
}

TEST_CASE("anything else is not guessed at") {
	for (const char *const name : { "", "Generic USB Joystick", "Nintendo Switch Pro Controller", "8BitDo Pro 2", "Gamepads Inc" }) {
		CHECK(controller_family(name, 0) == ControllerFamily::Unknown);
	}
	CHECK(controller_family("Wireless Controller", 0x057E) == ControllerFamily::Unknown);
}

TEST_CASE("Interact is X on Xbox and Square on PlayStation, never Cross") {
	CHECK(pad_label(ControllerFamily::Xbox, PadButton::West) == "X");
	CHECK(pad_label(ControllerFamily::PlayStation, PadButton::West) == "Square");
	CHECK(pad_label(ControllerFamily::PlayStation, PadButton::South) == "Cross");
	CHECK(pad_label(ControllerFamily::PlayStation, PadButton::West) != pad_label(ControllerFamily::PlayStation, PadButton::South));
}

TEST_CASE("each layout names every button the game uses") {
	CHECK(pad_label(ControllerFamily::Xbox, PadButton::South) == "A");
	CHECK(pad_label(ControllerFamily::Xbox, PadButton::East) == "B");
	CHECK(pad_label(ControllerFamily::Xbox, PadButton::Start) == "Menu");
	CHECK(pad_label(ControllerFamily::PlayStation, PadButton::East) == "Circle");
	CHECK(pad_label(ControllerFamily::PlayStation, PadButton::Start) == "Options");
}

TEST_CASE("an unknown controller gets positions, not another brand's letters") {
	CHECK(pad_label(ControllerFamily::Unknown, PadButton::South) == "bottom face button");
	CHECK(pad_label(ControllerFamily::Unknown, PadButton::East) == "right face button");
	CHECK(pad_label(ControllerFamily::Unknown, PadButton::West) == "left face button");
	CHECK(pad_label_capitalized(ControllerFamily::Unknown, PadButton::West) == "Left face button");
	CHECK(pad_label_capitalized(ControllerFamily::Xbox, PadButton::West) == "X");
}

TEST_CASE("Controls explains movement, jump, interact, pause, navigation, confirm and Back") {
	const std::string xbox = controller_controls_text(ControllerFamily::Xbox);
	CHECK(xbox.find("Xbox controller") == 0);
	for (const char *const line : { "Walk: left stick or D-pad", "Jump: A\n", "Examine: X, when a prompt appears", "Pause: Menu\n", "Menus: left stick or D-pad to move", "A to confirm", "B for Back" }) {
		CHECK(xbox.find(line) != std::string::npos);
	}
	const std::string playstation = controller_controls_text(ControllerFamily::PlayStation);
	CHECK(playstation.find("PlayStation controller") == 0);
	for (const char *const line : { "Jump: Cross\n", "Examine: Square, when a prompt appears", "Pause: Options\n", "Cross to confirm", "Circle for Back" }) {
		CHECK(playstation.find(line) != std::string::npos);
	}
	const std::string unknown = controller_controls_text(ControllerFamily::Unknown);
	CHECK(unknown.find("Controller\n") == 0);
	for (const char *const line : { "Jump: bottom face button", "Examine: left face button", "Pause: Start", "bottom face button to confirm", "right face button for Back" }) {
		CHECK(unknown.find(line) != std::string::npos);
	}
}

TEST_CASE("with no controller connected, both layouts are named") {
	const std::string text = any_controller_controls_text();
	for (const char *const line : { "Xbox / PlayStation controller", "Jump: A / Cross", "Examine: X / Square", "Pause: Menu / Options", "A / Cross to confirm", "B / Circle for Back" }) {
		CHECK(text.find(line) != std::string::npos);
	}
}
