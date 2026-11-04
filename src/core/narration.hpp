#pragma once

// Plain-C++ rules for spoken lines and their captions. No Godot headers. The script is one file, read by the game
// and by the tool that makes the audio, so what is said and what is shown cannot drift apart.

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace dagon::core {

enum class LinePriority {
	Optional, // What the player chose to examine.
	Story, // An essential moment, which nothing optional may delay or cover.
};

struct NarrationLine {
	std::string id;
	LinePriority priority = LinePriority::Optional;
	std::string text;
};

struct ParsedScript {
	std::vector<NarrationLine> lines;
	// Lines that could not be used. A shipped script has none, and a test holds it to that.
	int problems = 0;
};

// One line each: id|optional or story|text. Blank lines and lines starting with # are skipped. Never throws.
ParsedScript parse_narration_script(std::string_view p_text);
const NarrationLine *find_line(const std::vector<NarrationLine> &p_lines, std::string_view p_id);

// What happens to a line asked for while another may be speaking. There is no queue, so nothing can pile up.
enum class LineDecision {
	Start, // It replaces anything speaking: the audio and caption stop together.
	Ignore,
};

LineDecision decide_line(bool p_speaking, std::string_view p_current_id, LinePriority p_current, std::string_view p_id, LinePriority p_priority);

// How long a caption stays. With audio, through the spoken line and a brief margin, and never less than the
// reading time. Without audio, the reading time, and never less than the minimum, so text alone is enough.
double line_seconds(std::size_t p_characters, double p_audio_seconds, double p_minimum_seconds);

} // namespace dagon::core
