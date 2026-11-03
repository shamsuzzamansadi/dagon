#include "core/save_data.hpp"

#include "doctest.h"

#include <string>

using namespace dagon::core;

namespace {

SaveData save_at(Beat p_beat) {
	SaveData save;
	save.beat = p_beat;
	return save;
}

} // namespace

TEST_CASE("every beat this build has survives a round trip through the file format") {
	for (const Beat beat : { Beat::Shore, Beat::Abyss }) {
		const ParsedSave parsed = parse_save(serialize_save(save_at(beat)));
		CHECK(parsed.status == SaveStatus::Ok);
		CHECK(parsed.save.beat == beat);
	}
}

TEST_CASE("the file holds the version, the beat and the checkpoint's stable name") {
	const std::string text = serialize_save(save_at(Beat::Abyss));
	CHECK(text == "dagon_save=1\nbeat=abyss\ncheckpoint=PastTheTrench\n");
}

TEST_CASE("windows line endings parse the same") {
	CHECK(parse_save("dagon_save=1\r\nbeat=abyss\r\ncheckpoint=PastTheTrench\r\n").status == SaveStatus::Ok);
}

TEST_CASE("damaged input is corrupt, never a crash or a guess") {
	SUBCASE("empty") {
		CHECK(parse_save("").status == SaveStatus::Corrupt);
	}
	SUBCASE("binary noise") {
		CHECK(parse_save(std::string("\x00\xff\xfe\x01=\x80\n\x00", 8)).status == SaveStatus::Corrupt);
	}
	SUBCASE("another file's header") {
		CHECK(parse_save("dagon_settings=1\nbeat=shore\ncheckpoint=Shore\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("a version that is not a number") {
		CHECK(parse_save("dagon_save=one\nbeat=shore\ncheckpoint=Shore\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("truncated after the header") {
		CHECK(parse_save("dagon_save=1\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("truncated inside a field") {
		CHECK(parse_save("dagon_save=1\nbeat=abyss\ncheckpo").status == SaveStatus::Corrupt);
	}
	SUBCASE("no checkpoint") {
		CHECK(parse_save("dagon_save=1\nbeat=abyss\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("no beat") {
		CHECK(parse_save("dagon_save=1\ncheckpoint=Shore\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("an unknown beat") {
		CHECK(parse_save("dagon_save=1\nbeat=atlantis\ncheckpoint=Shore\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("a checkpoint that belongs to another beat") {
		CHECK(parse_save("dagon_save=1\nbeat=abyss\ncheckpoint=Shore\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("a field given twice") {
		CHECK(parse_save("dagon_save=1\nbeat=shore\nbeat=abyss\ncheckpoint=Shore\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("an unknown field") {
		CHECK(parse_save("dagon_save=1\nbeat=shore\ncheckpoint=Shore\nposition=500\n").status == SaveStatus::Corrupt);
	}
	SUBCASE("a line with no equals sign") {
		CHECK(parse_save("dagon_save=1\nbeat=shore\ncheckpoint=Shore\ngarbage\n").status == SaveStatus::Corrupt);
	}
}

TEST_CASE("another version is incompatible, not corrupt") {
	CHECK(parse_save("dagon_save=2\nbeat=shore\ncheckpoint=Shore\n").status == SaveStatus::Incompatible);
	CHECK(parse_save("dagon_save=0\n").status == SaveStatus::Incompatible);
}

TEST_CASE("a beat this build has no content for is incompatible") {
	CHECK(parse_save("dagon_save=1\nbeat=monolith\ncheckpoint=Monolith\n").status == SaveStatus::Incompatible);
	CHECK(parse_save("dagon_save=1\nbeat=awakened\ncheckpoint=Awakened\n").status == SaveStatus::Incompatible);
}

TEST_CASE("the final sequence can never be loaded from a save") {
	for (const char *const beat : { "witness", "fleeing", "ended" }) {
		const std::string text = std::string("dagon_save=1\nbeat=") + beat + "\ncheckpoint=\n";
		CHECK(parse_save(text).status == SaveStatus::Corrupt);
	}
}

TEST_CASE("a rejected save never hands back progress") {
	const ParsedSave parsed = parse_save("dagon_save=1\nbeat=abyss\ncheckpoint=Shore\n");
	CHECK(parsed.status == SaveStatus::Corrupt);
	CHECK(parsed.save.beat == Beat::Shore);
}

TEST_CASE("the menu explains each state of the slot") {
	CHECK(continue_note(Beat::Shore).find("shore") != std::string::npos);
	CHECK(continue_note(Beat::Abyss).find("trench") != std::string::npos);
	CHECK(continue_note(Beat::Awakened).find("before the final sequence") != std::string::npos);
	CHECK(unusable_save_note(SaveStatus::Missing).find("No saved game") != std::string::npos);
	CHECK(unusable_save_note(SaveStatus::Corrupt).find("damaged") != std::string::npos);
	CHECK(unusable_save_note(SaveStatus::Incompatible).find("another version") != std::string::npos);
}
