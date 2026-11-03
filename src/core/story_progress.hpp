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
};

std::optional<Event> event_for_trigger(std::string_view p_trigger_id);
Beat beat_after(Event p_event);

// The reveal and escape are never saved, so quitting during them replays them from the checkpoint before.
bool is_savable(Beat p_beat);

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
