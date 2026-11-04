#pragma once

#include "core/save_data.hpp"
#include "core/settings_data.hpp"

#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/variant/string.hpp>

#include <string>

// Stateless file access. Nothing is cached between calls, so the file on disk is what crosses a
// scene change or a relaunch, and no singleton is needed (docs/architecture.md §5, Persistence).
namespace dagon::storage {

// user://, unless DAGON_STORAGE_DIR is set. Tests set it, so no entry point can reach a player's files.
godot::String root();

bool read_file(const godot::String &p_name, std::string &r_text);

// Writes beside the file, checks what was written, then moves it into place.
bool replace_file(const godot::String &p_name, const std::string &p_text);

core::Settings load_settings();
bool save_settings(const core::Settings &p_settings);

// Sets the audio bus volumes, the InputMap and the two switches below. Safe to call any number of times.
void apply_settings(const core::Settings &p_settings);

// The player's switches, as they stand now, including any that could not be saved. Kept on the Engine singleton,
// as the volumes are on the AudioServer: they change only through Settings (docs/architecture.md §7 rule 8).
bool subtitles_enabled();
bool vibration_enabled();

// What the save slot holds, for the main menu. The session never reads it.
struct LoadedSave {
	core::SaveStatus status = core::SaveStatus::Missing;
	core::SaveData save;
	bool from_backup = false;
	bool any_file = false;
};

// Tries the save, then its backup. Never changes a file.
LoadedSave load_game();

// Once a valid save exists, at least one valid file stays on disk at every moment, and a corrupt
// save never replaces a valid backup. Returns true only when the new save is in place.
bool save_game(const core::SaveData &p_save);

// A key's name, for showing in the UI: the letter on the player's own layout if the font can draw it,
// otherwise the key's name on a US keyboard.
godot::String key_name(int p_key, const godot::Ref<godot::Font> &p_font);
godot::String displayed_key_name(int p_key, int p_layout_label, const godot::Ref<godot::Font> &p_font);
int current_key(const godot::StringName &p_action);

} // namespace dagon::storage
