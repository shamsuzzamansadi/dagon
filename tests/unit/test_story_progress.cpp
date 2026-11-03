#include "core/story_progress.hpp"

#include "doctest.h"

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
	CHECK_FALSE(event_for_trigger("out_of_bounds").has_value());
	CHECK_FALSE(event_for_trigger("").has_value());
}
