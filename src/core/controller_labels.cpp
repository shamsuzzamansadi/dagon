#include "core/controller_labels.hpp"

#include <algorithm>
#include <array>
#include <cctype>

namespace dagon::core {

namespace {

constexpr int MICROSOFT_VENDOR_ID = 0x045E;
constexpr int SONY_VENDOR_ID = 0x054C;

constexpr std::array<std::string_view, 3> XBOX_NAMES = { "xbox", "xinput", "x-box" };
constexpr std::array<std::string_view, 7> PLAYSTATION_NAMES = { "playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony" };

std::string lowercase(std::string_view p_text) {
	std::string lowered(p_text);
	std::transform(lowered.begin(), lowered.end(), lowered.begin(), [](unsigned char p_char) { return static_cast<char>(std::tolower(p_char)); });
	return lowered;
}

template <std::size_t N>
bool contains_any(const std::string &p_text, const std::array<std::string_view, N> &p_words) {
	return std::any_of(p_words.begin(), p_words.end(), [&p_text](std::string_view p_word) { return p_text.find(p_word) != std::string::npos; });
}

std::string walk_line() {
	return "Walk: left stick or D-pad\n";
}

std::string controls_lines(const std::string &p_jump, const std::string &p_examine, const std::string &p_pause, const std::string &p_confirm, const std::string &p_back) {
	return walk_line() + "Jump: " + p_jump + "\nExamine: " + p_examine + ", when a prompt appears\nPause: " + p_pause + "\nMenus: left stick or D-pad to move, " + p_confirm + " to confirm, " + p_back + " for Back";
}

} // namespace

ControllerFamily controller_family(std::string_view p_name, int p_vendor_id) {
	const std::string name = lowercase(p_name);
	if (contains_any(name, PLAYSTATION_NAMES)) {
		return ControllerFamily::PlayStation;
	}
	if (contains_any(name, XBOX_NAMES)) {
		return ControllerFamily::Xbox;
	}
	if (p_vendor_id == SONY_VENDOR_ID) {
		return ControllerFamily::PlayStation;
	}
	if (p_vendor_id == MICROSOFT_VENDOR_ID) {
		return ControllerFamily::Xbox;
	}
	return ControllerFamily::Unknown;
}

std::string pad_label(ControllerFamily p_family, PadButton p_button) {
	switch (p_family) {
		case ControllerFamily::Xbox:
			switch (p_button) {
				case PadButton::South:
					return "A";
				case PadButton::East:
					return "B";
				case PadButton::West:
					return "X";
				case PadButton::Start:
					return "Menu";
			}
			break;
		case ControllerFamily::PlayStation:
			switch (p_button) {
				case PadButton::South:
					return "Cross";
				case PadButton::East:
					return "Circle";
				case PadButton::West:
					return "Square";
				case PadButton::Start:
					return "Options";
			}
			break;
		case ControllerFamily::Unknown:
			switch (p_button) {
				case PadButton::South:
					return "bottom face button";
				case PadButton::East:
					return "right face button";
				case PadButton::West:
					return "left face button";
				case PadButton::Start:
					return "Start";
			}
			break;
	}
	return "";
}

std::string pad_label_capitalized(ControllerFamily p_family, PadButton p_button) {
	std::string label = pad_label(p_family, p_button);
	if (!label.empty()) {
		label[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(label[0])));
	}
	return label;
}

std::string controller_controls_text(ControllerFamily p_family) {
	std::string heading = "Controller";
	if (p_family == ControllerFamily::Xbox) {
		heading = "Xbox controller";
	} else if (p_family == ControllerFamily::PlayStation) {
		heading = "PlayStation controller";
	}
	return heading + "\n" + controls_lines(pad_label(p_family, PadButton::South), pad_label(p_family, PadButton::West), pad_label(p_family, PadButton::Start), pad_label(p_family, PadButton::South), pad_label(p_family, PadButton::East));
}

std::string any_controller_controls_text() {
	const auto both = [](PadButton p_button) { return pad_label(ControllerFamily::Xbox, p_button) + " / " + pad_label(ControllerFamily::PlayStation, p_button); };
	return "Xbox / PlayStation controller\n" + controls_lines(both(PadButton::South), both(PadButton::West), both(PadButton::Start), both(PadButton::South), both(PadButton::East));
}

} // namespace dagon::core
