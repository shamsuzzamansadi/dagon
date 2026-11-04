#include "core/story_progress.hpp"

#include "doctest.h"

#include <optional>
#include <string>

using namespace dagon::core;

TEST_CASE("the story starts at the shore and moves forward one beat at a time") {
	StoryProgress progress;
	CHECK(progress.beat() == Beat::Shore);
	CHECK(progress.apply(Event::EnterAbyss) == Beat::Abyss);
	CHECK(progress.apply(Event::ReachMonolith) == Beat::Monolith);
	CHECK(progress.apply(Event::PuzzleSolved) == Beat::Awakened);
	CHECK(progress.apply(Event::WitnessReached) == Beat::Witness);
	CHECK(progress.apply(Event::RevealDone) == Beat::Fleeing);
	CHECK(progress.apply(Event::Collapse) == Beat::Ended);
	CHECK(progress.beat() == Beat::Ended);
}

TEST_CASE("an out-of-order event is rejected and changes nothing") {
	StoryProgress progress;
	CHECK_FALSE(progress.apply(Event::ReachMonolith).has_value());
	CHECK_FALSE(progress.apply(Event::Collapse).has_value());
	CHECK(progress.beat() == Beat::Shore);
}

TEST_CASE("a duplicate event is rejected and changes nothing") {
	StoryProgress progress;
	CHECK(progress.apply(Event::EnterAbyss).has_value());
	CHECK_FALSE(progress.apply(Event::EnterAbyss).has_value());
	CHECK(progress.beat() == Beat::Abyss);
}

TEST_CASE("nothing moves past the ending") {
	StoryProgress progress;
	for (const Event event : { Event::EnterAbyss, Event::ReachMonolith, Event::PuzzleSolved, Event::WitnessReached, Event::RevealDone, Event::Collapse }) {
		CHECK(progress.apply(event).has_value());
	}
	CHECK_FALSE(progress.apply(Event::Collapse).has_value());
	CHECK(progress.beat() == Beat::Ended);
}

TEST_CASE("both ways out of the flee reach the same ending, and only from the flee") {
	const auto at_fleeing = [] {
		StoryProgress progress;
		for (const Event event : { Event::EnterAbyss, Event::ReachMonolith, Event::PuzzleSolved, Event::WitnessReached, Event::RevealDone }) {
			progress.apply(event);
		}
		return progress;
	};
	StoryProgress by_collapse = at_fleeing();
	CHECK(by_collapse.apply(Event::Collapse) == Beat::Ended);
	StoryProgress by_timeout = at_fleeing();
	CHECK(by_timeout.apply(Event::FleeTimeout) == Beat::Ended);
	// Whichever comes first, the other has nothing left to do.
	CHECK_FALSE(by_collapse.apply(Event::FleeTimeout).has_value());
	CHECK_FALSE(by_timeout.apply(Event::Collapse).has_value());

	StoryProgress early;
	CHECK(early.restore(Beat::Awakened));
	CHECK_FALSE(early.apply(Event::Collapse).has_value());
	CHECK_FALSE(early.apply(Event::FleeTimeout).has_value());
	CHECK(early.beat() == Beat::Awakened);
}

TEST_CASE("the outbound crossing of collapse is rejected at every beat before the flee") {
	for (const Beat beat : { Beat::Shore, Beat::Abyss, Beat::Monolith, Beat::Awakened }) {
		StoryProgress progress;
		CHECK(progress.restore(beat));
		CHECK_FALSE(progress.apply(Event::Collapse).has_value());
		CHECK(progress.beat() == beat);
	}
}

TEST_CASE("each beat names the trigger it is waiting for") {
	CHECK(std::string(awaited_trigger(Beat::Shore)) == "enter_abyss");
	CHECK(std::string(awaited_trigger(Beat::Abyss)) == "reach_monolith");
	CHECK(std::string(awaited_trigger(Beat::Monolith)).empty());
	CHECK(std::string(awaited_trigger(Beat::Awakened)) == "witness");
	CHECK(std::string(awaited_trigger(Beat::Witness)).empty());
	CHECK(std::string(awaited_trigger(Beat::Fleeing)) == "collapse");
	CHECK(std::string(awaited_trigger(Beat::Ended)).empty());
}

TEST_CASE("every beat a trigger waits for is entered by that trigger's successor") {
	for (const Beat beat : { Beat::Shore, Beat::Abyss, Beat::Awakened, Beat::Fleeing }) {
		const std::optional<Event> event = event_for_trigger(awaited_trigger(beat));
		REQUIRE(event.has_value());
		CHECK(static_cast<int>(beat_after(*event)) == static_cast<int>(beat) + 1);
	}
}

TEST_CASE("a fall returns to the latest checkpoint, including during the final sequence") {
	CHECK(checkpoint_beat(Beat::Shore) == Beat::Shore);
	CHECK(checkpoint_beat(Beat::Monolith) == Beat::Monolith);
	CHECK(checkpoint_beat(Beat::Awakened) == Beat::Awakened);
	CHECK(checkpoint_beat(Beat::Witness) == Beat::Awakened);
	CHECK(checkpoint_beat(Beat::Fleeing) == Beat::Awakened);
	CHECK(checkpoint_beat(Beat::Ended) == Beat::Awakened);
}

TEST_CASE("the player has control except during the reveal and the ending") {
	for (const Beat beat : { Beat::Shore, Beat::Abyss, Beat::Monolith, Beat::Awakened, Beat::Fleeing }) {
		CHECK(has_player_control(beat));
	}
	CHECK_FALSE(has_player_control(Beat::Witness));
	CHECK_FALSE(has_player_control(Beat::Ended));
}

TEST_CASE("beat names round trip") {
	for (const Beat beat : { Beat::Shore, Beat::Abyss, Beat::Monolith, Beat::Awakened, Beat::Witness, Beat::Fleeing, Beat::Ended }) {
		CHECK(beat_from_name(beat_name(beat)) == beat);
	}
	CHECK_FALSE(beat_from_name("atlantis").has_value());
}

TEST_CASE("only the beats before the final sequence can be saved") {
	CHECK(is_savable(Beat::Shore));
	CHECK(is_savable(Beat::Abyss));
	CHECK(is_savable(Beat::Monolith));
	CHECK(is_savable(Beat::Awakened));
	CHECK_FALSE(is_savable(Beat::Witness));
	CHECK_FALSE(is_savable(Beat::Fleeing));
	CHECK_FALSE(is_savable(Beat::Ended));
}

TEST_CASE("restoring accepts savable beats and refuses the final sequence") {
	StoryProgress progress;
	CHECK(progress.restore(Beat::Abyss));
	CHECK(progress.beat() == Beat::Abyss);
	CHECK_FALSE(progress.restore(Beat::Witness));
	CHECK_FALSE(progress.restore(Beat::Fleeing));
	CHECK_FALSE(progress.restore(Beat::Ended));
	CHECK(progress.beat() == Beat::Abyss);
}

TEST_CASE("the story continues normally after a restore") {
	StoryProgress progress;
	CHECK(progress.restore(Beat::Abyss));
	CHECK_FALSE(progress.apply(Event::EnterAbyss).has_value());
	CHECK(progress.apply(Event::ReachMonolith) == Beat::Monolith);
}

TEST_CASE("triggers name their events and an unknown one names nothing") {
	CHECK(event_for_trigger("enter_abyss") == Event::EnterAbyss);
	CHECK(event_for_trigger("reach_monolith") == Event::ReachMonolith);
	CHECK(event_for_trigger("witness") == Event::WitnessReached);
	CHECK(event_for_trigger("collapse") == Event::Collapse);
	// Only an internal event can be the timeout or the end of the reveal.
	CHECK_FALSE(event_for_trigger("flee_timeout").has_value());
	CHECK_FALSE(event_for_trigger("reveal_done").has_value());
	CHECK_FALSE(event_for_trigger("out_of_bounds").has_value());
	CHECK_FALSE(event_for_trigger("").has_value());
}
