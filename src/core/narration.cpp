#include "core/narration.hpp"

#include "core/text_fields.hpp"

#include <algorithm>

namespace dagon::core {

namespace {

constexpr double READING_CHARACTERS_PER_SECOND = 15.0;
constexpr double AUDIO_MARGIN_SECONDS = 0.8;

} // namespace

ParsedScript parse_narration_script(std::string_view p_text) {
	ParsedScript parsed;
	while (!p_text.empty()) {
		const std::string_view line = next_line(p_text);
		if (line.empty() || line.front() == '#') {
			continue;
		}
		const std::size_t first = line.find('|');
		const std::size_t second = first == std::string_view::npos ? first : line.find('|', first + 1);
		if (second == std::string_view::npos) {
			parsed.problems++;
			continue;
		}
		const std::string_view id = trim(line.substr(0, first));
		const std::string_view priority = trim(line.substr(first + 1, second - first - 1));
		const std::string_view text = trim(line.substr(second + 1));
		const bool known_priority = priority == "optional" || priority == "story";
		if (id.empty() || text.empty() || !known_priority || find_line(parsed.lines, id) != nullptr) {
			parsed.problems++;
			continue;
		}
		NarrationLine entry;
		entry.id = std::string(id);
		entry.priority = priority == "story" ? LinePriority::Story : LinePriority::Optional;
		entry.text = std::string(text);
		parsed.lines.push_back(std::move(entry));
	}
	return parsed;
}

const NarrationLine *find_line(const std::vector<NarrationLine> &p_lines, std::string_view p_id) {
	const auto found = std::find_if(p_lines.begin(), p_lines.end(), [p_id](const NarrationLine &p_line) { return p_line.id == p_id; });
	return found == p_lines.end() ? nullptr : &*found;
}

LineDecision decide_line(bool p_speaking, std::string_view p_current_id, LinePriority p_current, std::string_view p_id, LinePriority p_priority) {
	if (!p_speaking) {
		return LineDecision::Start;
	}
	// Asking for what is already being said never restarts it, however many times.
	if (p_current_id == p_id) {
		return LineDecision::Ignore;
	}
	if (p_priority == LinePriority::Optional && p_current == LinePriority::Story) {
		return LineDecision::Ignore;
	}
	return LineDecision::Start;
}

double line_seconds(std::size_t p_characters, double p_audio_seconds, double p_minimum_seconds) {
	const double reading = static_cast<double>(p_characters) / READING_CHARACTERS_PER_SECOND;
	if (p_audio_seconds > 0.0) {
		return std::max(p_audio_seconds + AUDIO_MARGIN_SECONDS, reading);
	}
	return std::max(reading, p_minimum_seconds);
}

} // namespace dagon::core
