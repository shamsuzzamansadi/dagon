#pragma once

// Plain-C++ rules for where the story is. Forward only. No Godot headers.

#include <optional>
#include <string_view>

namespace dagon::core {

enum class Beat {
	Shore,
	Abyss,
	Monolith,
	Awakened,
	Witness,
	Fleeing,
	Ended,
};

enum class Event {
	EnterAbyss,
	ReachMonolith,
	PuzzleSolved,
	WitnessReached,
	RevealDone,
	Collapse,
	FleeTimeout,
};

std::optional<Event> event_for_trigger(std::string_view p_trigger_id);
Beat beat_after(Event p_event);

// The trigger this beat is waiting for, or nothing if a trigger cannot move it on.
const char *awaited_trigger(Beat p_beat);

// The reveal and escape are never saved, so quitting during them replays them from the checkpoint before.
bool is_savable(Beat p_beat);

// The latest savable beat at or before this one, which is where a fall returns the player.
Beat checkpoint_beat(Beat p_beat);

// Whether the player can move in this beat once any cinematic has finished.
bool has_player_control(Beat p_beat);

// The beat's stable name, used in the save file and the logs.
const char *beat_name(Beat p_beat);
std::optional<Beat> beat_from_name(std::string_view p_name);

class StoryProgress {
public:
	Beat beat() const { return beat_; }

	// The new beat, or nothing if this event cannot happen now. A rejection changes nothing.
	std::optional<Beat> apply(Event p_event);

	// Returns to a saved beat. False, with nothing changed, for one that may not be saved.
	bool restore(Beat p_beat);

private:
	Beat beat_ = Beat::Shore;
};

} // namespace dagon::core
