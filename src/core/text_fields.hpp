#pragma once

// Small helpers shared by the plain-text file formats. No Godot headers.

#include <charconv>
#include <optional>
#include <string_view>
#include <system_error>

namespace dagon::core {

inline std::string_view trim(std::string_view p_text) {
	const std::string_view blank = " \t\r";
	const std::size_t first = p_text.find_first_not_of(blank);
	if (first == std::string_view::npos) {
		return {};
	}
	return p_text.substr(first, p_text.find_last_not_of(blank) - first + 1);
}

// Takes the next line off the front of r_text.
inline std::string_view next_line(std::string_view &r_text) {
	const std::size_t end = r_text.find('\n');
	const std::string_view line = r_text.substr(0, end);
	r_text = end == std::string_view::npos ? std::string_view{} : r_text.substr(end + 1);
	return trim(line);
}

template <typename T>
std::optional<T> parse_number(std::string_view p_text) {
	T value{};
	const char *const end = p_text.data() + p_text.size();
	const std::from_chars_result result = std::from_chars(p_text.data(), end, value);
	if (result.ec != std::errc{} || result.ptr != end) {
		return std::nullopt;
	}
	return value;
}

} // namespace dagon::core
