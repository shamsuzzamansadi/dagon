#pragma once

#include "core/settings_data.hpp"

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

// Sets the audio bus volumes and the InputMap. Safe to call any number of times.
void apply_settings(const core::Settings &p_settings);

// The action's rebindable key, for showing in the UI.
godot::String key_name(int p_key);
int current_key(const godot::StringName &p_action);

} // namespace dagon::storage
