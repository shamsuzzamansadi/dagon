#pragma once

// Plain-C++ rules for the one checkpoint save slot: the file format and what it may hold. No Godot headers.

#include "core/story_progress.hpp"

#include <string>
#include <string_view>

namespace dagon::core {

// Stable progress only: no node references, no positions between checkpoints and no cutscene state.
struct SaveData {
	Beat beat = Beat::Shore;
};

enum class SaveStatus {
	Ok,
	Missing,
	Corrupt,
	Incompatible,
};

struct ParsedSave {
	SaveStatus status = SaveStatus::Ok;
	SaveData save;
};

// Never throws, whatever the input. Only Ok gives a save that can be used.
ParsedSave parse_save(std::string_view p_text);
std::string serialize_save(const SaveData &p_save);

// The stable name of the checkpoint that belongs to this beat, which is also its Marker2D's name.
const char *checkpoint_id(Beat p_beat);

// What the main menu says about Continue. An Awakened save stays after the ending, and resumes before it.
std::string continue_note(Beat p_beat);
std::string unusable_save_note(SaveStatus p_status);

} // namespace dagon::core
