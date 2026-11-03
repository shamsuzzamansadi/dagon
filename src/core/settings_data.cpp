#include "core/settings_data.hpp"

#include "core/text_fields.hpp"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <optional>
#include <set>

namespace dagon::core {

namespace {

constexpr int SETTINGS_VERSION = 1;
constexpr std::string_view VERSION_FIELD = "dagon_settings";
constexpr std::string_view MUSIC_FIELD = "music_volume";
constexpr std::string_view EFFECTS_FIELD = "effects_volume";
constexpr std::string_view KEY_FIELD_PREFIX = "key_";
constexpr int MAX_KEY_CODE = 0x7FFFFFF;

constexpr std::array<GameAction, GAME_ACTION_COUNT> ALL_ACTIONS = {
	GameAction::MoveLeft,
	GameAction::MoveRight,
	GameAction::Jump,
	GameAction::Interact,
};

std::size_t index_of(GameAction p_action) {
	return static_cast<std::size_t>(p_action);
}

std::optional<float> parse_volume(std::string_view p_text) {
	const std::optional<float> value = parse_number<float>(p_text);
	if (!value.has_value() || !std::isfinite(*value) || *value < 0.0f || *value > 1.0f) {
		return std::nullopt;
	}
	return value;
}

bool keys_are_valid(const std::array<int, GAME_ACTION_COUNT> &p_keys) {
	std::set<int> seen;
	for (const int key : p_keys) {
		if (key <= 0 || key > MAX_KEY_CODE || is_reserved_key(key) || !seen.insert(key).second) {
			return false;
		}
	}
	return true;
}

void append_number(std::string &r_text, std::string_view p_field, float p_value) {
	std::array<char, 32> buffer{};
	const std::to_chars_result result = std::to_chars(buffer.data(), buffer.data() + buffer.size(), p_value);
	r_text.append(p_field).append("=").append(buffer.data(), result.ptr).append("\n");
}

} // namespace

const char *action_name(GameAction p_action) {
	switch (p_action) {
		case GameAction::MoveLeft:
			return "move_left";
		case GameAction::MoveRight:
			return "move_right";
		case GameAction::Jump:
			return "jump";
		case GameAction::Interact:
			return "interact";
	}
	return "";
}

bool is_reserved_key(int p_key) {
	return p_key == KEY_CODE_ESCAPE || p_key == KEY_CODE_LEFT || p_key == KEY_CODE_RIGHT;
}

ParsedSettings parse_settings(std::string_view p_text) {
	ParsedSettings parsed;

	const std::string_view header = next_line(p_text);
	const std::size_t header_equals = header.find('=');
	if (header_equals == std::string_view::npos || trim(header.substr(0, header_equals)) != VERSION_FIELD) {
		parsed.status = ParseStatus::Corrupt;
		return parsed;
	}
	const std::optional<int> version = parse_number<int>(trim(header.substr(header_equals + 1)));
	if (!version.has_value()) {
		parsed.status = ParseStatus::Corrupt;
		return parsed;
	}
	if (*version != SETTINGS_VERSION) {
		parsed.status = ParseStatus::Incompatible;
		return parsed;
	}

	// Keys only make sense as a complete set, so anything wrong with one resets them all.
	std::array<int, GAME_ACTION_COUNT> keys{};
	bool repaired = false;
	bool music_found = false;
	bool effects_found = false;
	while (!p_text.empty()) {
		const std::string_view line = next_line(p_text);
		if (line.empty()) {
			continue;
		}
		const std::size_t equals = line.find('=');
		if (equals == std::string_view::npos) {
			repaired = true;
			continue;
		}
		const std::string_view field = trim(line.substr(0, equals));
		const std::string_view value = trim(line.substr(equals + 1));
		if (field == MUSIC_FIELD || field == EFFECTS_FIELD) {
			const std::optional<float> volume = parse_volume(value);
			if (!volume.has_value()) {
				repaired = true;
			} else if (field == MUSIC_FIELD) {
				parsed.settings.music_volume = *volume;
				music_found = true;
			} else {
				parsed.settings.effects_volume = *volume;
				effects_found = true;
			}
		} else if (field.substr(0, KEY_FIELD_PREFIX.size()) == KEY_FIELD_PREFIX) {
			const std::string_view name = field.substr(KEY_FIELD_PREFIX.size());
			const auto action = std::find_if(ALL_ACTIONS.begin(), ALL_ACTIONS.end(), [name](GameAction p_action) { return name == action_name(p_action); });
			const std::optional<int> key = parse_number<int>(value);
			if (action != ALL_ACTIONS.end() && key.has_value()) {
				keys[index_of(*action)] = *key;
			} else {
				repaired = true;
			}
		}
	}

	if (keys_are_valid(keys)) {
		parsed.settings.keys = keys;
	} else {
		repaired = true;
	}
	if (repaired || !music_found || !effects_found) {
		parsed.status = ParseStatus::Repaired;
	}
	return parsed;
}

std::string serialize_settings(const Settings &p_settings) {
	std::string text;
	text.append(VERSION_FIELD).append("=").append(std::to_string(SETTINGS_VERSION)).append("\n");
	append_number(text, MUSIC_FIELD, p_settings.music_volume);
	append_number(text, EFFECTS_FIELD, p_settings.effects_volume);
	for (const GameAction action : ALL_ACTIONS) {
		text.append(KEY_FIELD_PREFIX).append(action_name(action)).append("=").append(std::to_string(p_settings.keys[index_of(action)])).append("\n");
	}
	return text;
}

Assignment assign_key(Settings &r_settings, GameAction p_action, int p_key) {
	Assignment assignment;
	if (is_reserved_key(p_key) || p_key <= 0 || p_key > MAX_KEY_CODE) {
		assignment.result = AssignResult::Reserved;
		return assignment;
	}
	if (r_settings.keys[index_of(p_action)] == p_key) {
		assignment.result = AssignResult::Unchanged;
		return assignment;
	}
	for (const GameAction other : ALL_ACTIONS) {
		if (other != p_action && r_settings.keys[index_of(other)] == p_key) {
			assignment.result = AssignResult::Conflict;
			assignment.other = other;
			return assignment;
		}
	}
	r_settings.keys[index_of(p_action)] = p_key;
	assignment.result = AssignResult::Assigned;
	return assignment;
}

void swap_keys(Settings &r_settings, GameAction p_first, GameAction p_second) {
	std::swap(r_settings.keys[index_of(p_first)], r_settings.keys[index_of(p_second)]);
}

} // namespace dagon::core
