#include "core/save_data.hpp"

#include "core/text_fields.hpp"

#include <optional>

namespace dagon::core {

namespace {

constexpr int SAVE_VERSION = 1;
constexpr std::string_view VERSION_FIELD = "dagon_save";
constexpr std::string_view BEAT_FIELD = "beat";
constexpr std::string_view CHECKPOINT_FIELD = "checkpoint";

ParsedSave rejected(SaveStatus p_status) {
	ParsedSave parsed;
	parsed.status = p_status;
	return parsed;
}

} // namespace

const char *checkpoint_id(Beat p_beat) {
	switch (p_beat) {
		case Beat::Shore:
			return "Shore";
		case Beat::Abyss:
			return "PastTheTrench";
		case Beat::Monolith:
			return "Monolith";
		case Beat::Awakened:
			return "Awakened";
		case Beat::Witness:
		case Beat::Fleeing:
		case Beat::Ended:
			break;
	}
	return "";
}

ParsedSave parse_save(std::string_view p_text) {
	const std::string_view header = next_line(p_text);
	const std::size_t header_equals = header.find('=');
	if (header_equals == std::string_view::npos || trim(header.substr(0, header_equals)) != VERSION_FIELD) {
		return rejected(SaveStatus::Corrupt);
	}
	const std::optional<int> version = parse_number<int>(trim(header.substr(header_equals + 1)));
	if (!version.has_value()) {
		return rejected(SaveStatus::Corrupt);
	}
	if (*version != SAVE_VERSION) {
		return rejected(SaveStatus::Incompatible);
	}

	// Unlike settings, nothing here has a safe default: any damage makes the whole save unusable.
	std::optional<std::string_view> beat_text;
	std::optional<std::string_view> checkpoint_text;
	while (!p_text.empty()) {
		const std::string_view line = next_line(p_text);
		if (line.empty()) {
			continue;
		}
		const std::size_t equals = line.find('=');
		if (equals == std::string_view::npos) {
			return rejected(SaveStatus::Corrupt);
		}
		const std::string_view field = trim(line.substr(0, equals));
		const std::string_view value = trim(line.substr(equals + 1));
		if (field == BEAT_FIELD && !beat_text.has_value()) {
			beat_text = value;
		} else if (field == CHECKPOINT_FIELD && !checkpoint_text.has_value()) {
			checkpoint_text = value;
		} else {
			return rejected(SaveStatus::Corrupt);
		}
	}
	if (!beat_text.has_value() || !checkpoint_text.has_value()) {
		return rejected(SaveStatus::Corrupt);
	}

	const std::optional<Beat> beat = beat_from_name(*beat_text);
	if (!beat.has_value() || !is_savable(*beat) || *checkpoint_text != checkpoint_id(*beat)) {
		return rejected(SaveStatus::Corrupt);
	}
	ParsedSave parsed;
	parsed.save.beat = *beat;
	return parsed;
}

std::string serialize_save(const SaveData &p_save) {
	std::string text;
	text.append(VERSION_FIELD).append("=").append(std::to_string(SAVE_VERSION)).append("\n");
	text.append(BEAT_FIELD).append("=").append(beat_name(p_save.beat)).append("\n");
	text.append(CHECKPOINT_FIELD).append("=").append(checkpoint_id(p_save.beat)).append("\n");
	return text;
}

std::string continue_note(Beat p_beat) {
	switch (p_beat) {
		case Beat::Shore:
			return "Continue from the shore.";
		case Beat::Abyss:
			return "Continue from past the trench.";
		case Beat::Monolith:
			return "Continue from the monolith.";
		case Beat::Awakened:
			return "Continue resumes before the final sequence.";
		case Beat::Witness:
		case Beat::Fleeing:
		case Beat::Ended:
			break;
	}
	return "";
}

std::string unusable_save_note(SaveStatus p_status) {
	switch (p_status) {
		case SaveStatus::Missing:
			return "No saved game yet.";
		case SaveStatus::Corrupt:
			return "The saved game is damaged and cannot be used.";
		case SaveStatus::Incompatible:
			return "The saved game is from another version and cannot be used.";
		case SaveStatus::Ok:
			break;
	}
	return "";
}

} // namespace dagon::core
