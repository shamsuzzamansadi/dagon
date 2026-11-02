#pragma once

// Plain-C++ rules for the player's settings: the file format and key rebinding. No Godot headers.

#include <array>
#include <string>
#include <string_view>

namespace dagon::core {

enum class GameAction {
	MoveLeft,
	MoveRight,
	Jump,
	Interact,
};

inline constexpr int GAME_ACTION_COUNT = 4;

// Godot's Key values. A Godot test checks that these still match the engine's.
inline constexpr int KEY_CODE_A = 65;
inline constexpr int KEY_CODE_D = 68;
inline constexpr int KEY_CODE_E = 69;
inline constexpr int KEY_CODE_SPACE = 32;
inline constexpr int KEY_CODE_ESCAPE = 4194305;
inline constexpr int KEY_CODE_LEFT = 4194319;
inline constexpr int KEY_CODE_RIGHT = 4194321;

// Each gameplay action has exactly one rebindable key, so swapping two can never leave one unbound.
struct Settings {
	float music_volume = 1.0f;
	float effects_volume = 1.0f;
	std::array<int, GAME_ACTION_COUNT> keys = { KEY_CODE_A, KEY_CODE_D, KEY_CODE_SPACE, KEY_CODE_E };
};

enum class ParseStatus {
	Ok,
	Repaired, // Readable, but something invalid fell back to its default.
	Corrupt,
	Incompatible,
};

struct ParsedSettings {
	ParseStatus status = ParseStatus::Ok;
	Settings settings;
};

// Corrupt and Incompatible return the defaults. Never throws, whatever the input.
ParsedSettings parse_settings(std::string_view p_text);
std::string serialize_settings(const Settings &p_settings);

const char *action_name(GameAction p_action);

// Esc always opens and closes the pause menu, and the arrows always move, so nobody can lock themselves out.
bool is_reserved_key(int p_key);

enum class AssignResult {
	Assigned,
	Unchanged,
	Reserved,
	Conflict, // Nothing changed: the key belongs to another action, named in other.
};

struct Assignment {
	AssignResult result = AssignResult::Unchanged;
	GameAction other = GameAction::MoveLeft;
};

Assignment assign_key(Settings &r_settings, GameAction p_action, int p_key);
void swap_keys(Settings &r_settings, GameAction p_first, GameAction p_second);

} // namespace dagon::core
