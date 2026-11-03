#include "core/story_progress.hpp"

namespace dagon::core {

std::optional<Event> event_for_trigger(std::string_view p_trigger_id) {
	if (p_trigger_id == "enter_abyss") {
		return Event::EnterAbyss;
	}
	if (p_trigger_id == "reach_monolith") {
		return Event::ReachMonolith;
	}
	if (p_trigger_id == "witness") {
		return Event::WitnessReached;
	}
	if (p_trigger_id == "collapse") {
		return Event::Collapse;
	}
	return std::nullopt;
}

Beat beat_after(Event p_event) {
	switch (p_event) {
		case Event::EnterAbyss:
			return Beat::Abyss;
		case Event::ReachMonolith:
			return Beat::Monolith;
		case Event::PuzzleSolved:
			return Beat::Awakened;
		case Event::WitnessReached:
			return Beat::Witness;
		case Event::RevealDone:
			return Beat::Fleeing;
		case Event::Collapse:
			return Beat::Ended;
	}
	return Beat::Ended;
}

bool is_savable(Beat p_beat) {
	return p_beat == Beat::Shore || p_beat == Beat::Abyss || p_beat == Beat::Monolith || p_beat == Beat::Awakened;
}

std::optional<Beat> StoryProgress::apply(Event p_event) {
	// Each beat is entered from the one before it, so a duplicate or out-of-order event is rejected.
	const Beat next = beat_after(p_event);
	if (static_cast<int>(next) != static_cast<int>(beat_) + 1) {
		return std::nullopt;
	}
	beat_ = next;
	return beat_;
}

bool StoryProgress::restore(Beat p_beat) {
	if (!is_savable(p_beat)) {
		return false;
	}
	beat_ = p_beat;
	return true;
}

} // namespace dagon::core
