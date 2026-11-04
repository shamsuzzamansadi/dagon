#include "core/narration.hpp"

#include "doctest.h"

#include <string>

using namespace dagon::core;

TEST_CASE("a script gives each line its id, priority and exact words") {
	const ParsedScript parsed = parse_narration_script("# a comment\n\nshore.boat|optional|The boat. It lies there.\nstory.run|story|I ran.\n");
	CHECK(parsed.problems == 0);
	REQUIRE(parsed.lines.size() == 2);
	CHECK(parsed.lines[0].id == "shore.boat");
	CHECK(parsed.lines[0].priority == LinePriority::Optional);
	CHECK(parsed.lines[0].text == "The boat. It lies there.");
	CHECK(parsed.lines[1].priority == LinePriority::Story);
}

TEST_CASE("the words may contain a separator, and windows line endings do not change them") {
	const ParsedScript parsed = parse_narration_script("a|story|One | two.\r\nb|optional|Three.\r\n");
	CHECK(parsed.problems == 0);
	REQUIRE(parsed.lines.size() == 2);
	CHECK(parsed.lines[0].text == "One | two.");
	CHECK(parsed.lines[1].text == "Three.");
}

TEST_CASE("an unusable line is counted and left out, never guessed at") {
	SUBCASE("no fields") {
		CHECK(parse_narration_script("just some words\n").problems == 1);
	}
	SUBCASE("one field short") {
		CHECK(parse_narration_script("a|story\n").problems == 1);
	}
	SUBCASE("no id") {
		CHECK(parse_narration_script("|story|Words.\n").problems == 1);
	}
	SUBCASE("no words") {
		CHECK(parse_narration_script("a|story|  \n").problems == 1);
	}
	SUBCASE("an unknown priority") {
		CHECK(parse_narration_script("a|urgent|Words.\n").problems == 1);
	}
	SUBCASE("binary noise") {
		CHECK(parse_narration_script(std::string("\x00\xff\xfe\x01\n", 5)).problems == 1);
	}
}

TEST_CASE("an id given twice keeps the first, and counts as a problem") {
	const ParsedScript parsed = parse_narration_script("a|story|First.\na|optional|Second.\n");
	CHECK(parsed.problems == 1);
	REQUIRE(parsed.lines.size() == 1);
	CHECK(parsed.lines[0].text == "First.");
}

TEST_CASE("a line is found by its id, or not at all") {
	const ParsedScript parsed = parse_narration_script("a|story|First.\n");
	REQUIRE(find_line(parsed.lines, "a") != nullptr);
	CHECK(find_line(parsed.lines, "a")->text == "First.");
	CHECK(find_line(parsed.lines, "b") == nullptr);
	CHECK(find_line(parsed.lines, "") == nullptr);
}

TEST_CASE("with nothing speaking, any line starts") {
	CHECK(decide_line(false, "", LinePriority::Optional, "a", LinePriority::Optional) == LineDecision::Start);
	CHECK(decide_line(false, "a", LinePriority::Story, "a", LinePriority::Optional) == LineDecision::Start);
}

TEST_CASE("the line already being said never restarts or stacks") {
	CHECK(decide_line(true, "a", LinePriority::Optional, "a", LinePriority::Optional) == LineDecision::Ignore);
	CHECK(decide_line(true, "a", LinePriority::Story, "a", LinePriority::Story) == LineDecision::Ignore);
}

TEST_CASE("something optional replaces something optional, and cannot touch a story moment") {
	CHECK(decide_line(true, "a", LinePriority::Optional, "b", LinePriority::Optional) == LineDecision::Start);
	CHECK(decide_line(true, "a", LinePriority::Story, "b", LinePriority::Optional) == LineDecision::Ignore);
}

TEST_CASE("a story moment replaces anything else") {
	CHECK(decide_line(true, "a", LinePriority::Optional, "b", LinePriority::Story) == LineDecision::Start);
	CHECK(decide_line(true, "a", LinePriority::Story, "b", LinePriority::Story) == LineDecision::Start);
}

TEST_CASE("a caption with audio lasts through the line and a brief margin") {
	CHECK(line_seconds(30, 5.0, 4.0) == doctest::Approx(5.8));
}

TEST_CASE("a long caption stays long enough to read, even if the audio is short") {
	CHECK(line_seconds(150, 3.0, 4.0) == doctest::Approx(10.0));
}

TEST_CASE("text alone is held for its reading time, and never less than the minimum") {
	CHECK(line_seconds(150, 0.0, 4.0) == doctest::Approx(10.0));
	CHECK(line_seconds(5, 0.0, 4.0) == doctest::Approx(4.0));
}
