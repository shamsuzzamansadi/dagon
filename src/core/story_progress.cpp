#include "core/story_progress.hpp"

#include <array>
#include <utility>

namespace dagon::core {

namespace {

constexpr std::array<std::pair<std::string_view, Beat>, 7> BEAT_NAMES = { {
		{ "shore", Beat::Shore },
		{ "abyss", Beat::Abyss },
		{ "monolith", Beat::Monolith },
		{ "awakened", Beat::Awakened },
		{ "witness", Beat::Witness },
		{ "fleeing", Beat::Fleeing },
		{ "ended", Beat::Ended },
} };

} // namespace

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
		case Event::FleeTimeout:
			return Beat::Ended;
	}
	return Beat::Ended;
}

const char *awaited_trigger(Beat p_beat) {
	switch (p_beat) {
		case Beat::Shore:
			return "enter_abyss";
		case Beat::Abyss:
			return "reach_monolith";
		case Beat::Awakened:
			return "witness";
		case Beat::Fleeing:
			return "collapse";
		case Beat::Monolith:
		case Beat::Witness:
		case Beat::Ended:
			break;
	}
	return "";
}

bool is_savable(Beat p_beat) {
	return p_beat == Beat::Shore || p_beat == Beat::Abyss || p_beat == Beat::Monolith || p_beat == Beat::Awakened;
}

Beat checkpoint_beat(Beat p_beat) {
	return is_savable(p_beat) ? p_beat : Beat::Awakened;
}

bool has_player_control(Beat p_beat) {
	return p_beat != Beat::Witness && p_beat != Beat::Ended;
}

const char *beat_name(Beat p_beat) {
	for (const auto &entry : BEAT_NAMES) {
		if (entry.second == p_beat) {
			return entry.first.data();
		}
	}
	return "";
}

std::optional<Beat> beat_from_name(std::string_view p_name) {
	for (const auto &entry : BEAT_NAMES) {
		if (entry.first == p_name) {
			return entry.second;
		}
	}
	return std::nullopt;
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
