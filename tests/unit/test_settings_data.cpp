#include "core/settings_data.hpp"

#include "doctest.h"

#include <set>
#include <string>

using namespace dagon::core;

namespace {

Settings custom_settings() {
	Settings settings;
	settings.music_volume = 0.3f;
	settings.effects_volume = 0.7f;
	settings.keys = { 74, 76, 75, 85 };
	return settings;
}

bool keys_are_the_defaults(const Settings &p_settings) {
	return p_settings.keys == Settings{}.keys;
}

} // namespace

TEST_CASE("settings survive a round trip through the file format") {
	const Settings original = custom_settings();
	const ParsedSettings parsed = parse_settings(serialize_settings(original));
	CHECK(parsed.status == ParseStatus::Ok);
	CHECK(parsed.settings.music_volume == doctest::Approx(0.3f));
	CHECK(parsed.settings.effects_volume == doctest::Approx(0.7f));
	CHECK(parsed.settings.keys == original.keys);
}

TEST_CASE("the default settings are themselves valid") {
	const ParsedSettings parsed = parse_settings(serialize_settings(Settings{}));
	CHECK(parsed.status == ParseStatus::Ok);
	CHECK(keys_are_the_defaults(parsed.settings));
}

TEST_CASE("windows line endings parse the same") {
	const ParsedSettings parsed = parse_settings("dagon_settings=1\r\nmusic_volume=0.5\r\neffects_volume=0.5\r\nkey_move_left=74\r\nkey_move_right=76\r\nkey_jump=75\r\nkey_interact=85\r\n");
	CHECK(parsed.status == ParseStatus::Ok);
	CHECK(parsed.settings.keys[0] == 74);
}

TEST_CASE("unusable input gives the defaults and says why") {
	SUBCASE("empty") {
		const ParsedSettings parsed = parse_settings("");
		CHECK(parsed.status == ParseStatus::Corrupt);
		CHECK(keys_are_the_defaults(parsed.settings));
	}
	SUBCASE("binary noise") {
		const std::string noise("\x00\xff\xfe\x01=\x80\n\x00", 8);
		const ParsedSettings parsed = parse_settings(noise);
		CHECK(parsed.status == ParseStatus::Corrupt);
		CHECK(keys_are_the_defaults(parsed.settings));
	}
	SUBCASE("a header that is not a number") {
		CHECK(parse_settings("dagon_settings=one\n").status == ParseStatus::Corrupt);
	}
	SUBCASE("another version") {
		const ParsedSettings parsed = parse_settings("dagon_settings=2\nmusic_volume=0.1\n");
		CHECK(parsed.status == ParseStatus::Incompatible);
		CHECK(parsed.settings.music_volume == doctest::Approx(1.0f));
	}
}

TEST_CASE("a damaged field falls back without losing the valid ones") {
	std::string text = serialize_settings(custom_settings());

	SUBCASE("a volume out of range") {
		text.replace(text.find("music_volume=0.3"), 16, "music_volume=7.5");
		const ParsedSettings parsed = parse_settings(text);
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(parsed.settings.music_volume == doctest::Approx(1.0f));
		CHECK(parsed.settings.effects_volume == doctest::Approx(0.7f));
		CHECK(parsed.settings.keys == custom_settings().keys);
	}
	SUBCASE("a volume that is not a number") {
		text.replace(text.find("music_volume=0.3"), 16, "music_volume=nan");
		const ParsedSettings parsed = parse_settings(text);
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(parsed.settings.music_volume == doctest::Approx(1.0f));
	}
	SUBCASE("a truncated file") {
		const ParsedSettings parsed = parse_settings(text.substr(0, text.find("key_jump")));
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(parsed.settings.music_volume == doctest::Approx(0.3f));
		CHECK(keys_are_the_defaults(parsed.settings));
	}
	SUBCASE("a line with no equals sign") {
		const ParsedSettings parsed = parse_settings(text + "garbage\n");
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(parsed.settings.keys == custom_settings().keys);
	}
}

TEST_CASE("keys that could trap the player reset the whole set") {
	const auto with_keys = [](int p_left, int p_right, int p_jump, int p_interact) {
		return "dagon_settings=1\nmusic_volume=1\neffects_volume=1\nkey_move_left=" + std::to_string(p_left) + "\nkey_move_right=" + std::to_string(p_right) + "\nkey_jump=" + std::to_string(p_jump) + "\nkey_interact=" + std::to_string(p_interact) + "\n";
	};
	SUBCASE("two actions on one key") {
		const ParsedSettings parsed = parse_settings(with_keys(74, 74, 75, 85));
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(keys_are_the_defaults(parsed.settings));
	}
	SUBCASE("a reserved key") {
		const ParsedSettings parsed = parse_settings(with_keys(KEY_CODE_ESCAPE, 76, 75, 85));
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(keys_are_the_defaults(parsed.settings));
	}
	SUBCASE("an action with no key") {
		const ParsedSettings parsed = parse_settings(with_keys(0, 76, 75, 85));
		CHECK(parsed.status == ParseStatus::Repaired);
		CHECK(keys_are_the_defaults(parsed.settings));
	}
}

TEST_CASE("assigning a free key changes only that action") {
	Settings settings;
	const Assignment assignment = assign_key(settings, GameAction::Jump, 75);
	CHECK(assignment.result == AssignResult::Assigned);
	CHECK(settings.keys[static_cast<int>(GameAction::Jump)] == 75);
	CHECK(settings.keys[static_cast<int>(GameAction::MoveLeft)] == KEY_CODE_A);
}

TEST_CASE("assigning the key an action already has changes nothing") {
	Settings settings;
	CHECK(assign_key(settings, GameAction::Jump, KEY_CODE_SPACE).result == AssignResult::Unchanged);
	CHECK(keys_are_the_defaults(settings));
}

TEST_CASE("reserved keys are refused") {
	Settings settings;
	for (const int key : { KEY_CODE_ESCAPE, KEY_CODE_LEFT, KEY_CODE_RIGHT }) {
		CHECK(assign_key(settings, GameAction::Jump, key).result == AssignResult::Reserved);
	}
	CHECK(assign_key(settings, GameAction::Jump, 0).result == AssignResult::Reserved);
	CHECK(keys_are_the_defaults(settings));
}

TEST_CASE("a conflict names the other action and changes nothing") {
	Settings settings;
	const Assignment assignment = assign_key(settings, GameAction::Interact, KEY_CODE_SPACE);
	CHECK(assignment.result == AssignResult::Conflict);
	CHECK(assignment.other == GameAction::Jump);
	CHECK(keys_are_the_defaults(settings));
}

TEST_CASE("swapping exchanges two keys and leaves no action unbound") {
	Settings settings;
	swap_keys(settings, GameAction::Interact, GameAction::Jump);
	CHECK(settings.keys[static_cast<int>(GameAction::Interact)] == KEY_CODE_SPACE);
	CHECK(settings.keys[static_cast<int>(GameAction::Jump)] == KEY_CODE_E);
	const std::set<int> distinct(settings.keys.begin(), settings.keys.end());
	CHECK(distinct.size() == GAME_ACTION_COUNT);
	CHECK(parse_settings(serialize_settings(settings)).status == ParseStatus::Ok);
}

TEST_CASE("every action has a name that survives the format") {
	for (const GameAction action : { GameAction::MoveLeft, GameAction::MoveRight, GameAction::Jump, GameAction::Interact }) {
		CHECK(std::string(action_name(action)).size() > 0);
	}
	CHECK(serialize_settings(Settings{}).find("key_interact=69") != std::string::npos);
}
