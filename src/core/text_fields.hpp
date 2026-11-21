#pragma once

// Small helpers shared by the plain-text file formats. No Godot headers.

#include <charconv>
#include <optional>
#include <string_view>
#include <system_error>

#if defined(__APPLE__)
#include <array>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <type_traits>
// After <cstdio> and <cstdlib>, so that it declares their functions that take a locale.
#include <xlocale.h>
#endif

namespace dagon::core {

#if defined(__APPLE__)
// Apple's C++ library has no from_chars for floats, and its to_chars for floats needs macOS 13.3, above the macOS
// build's minimum (D128). These two stand in on Apple platforms only, and always read and write a "." for the
// decimal point, as from_chars and to_chars do, whatever the process's locale.
inline locale_t c_locale() {
	static const locale_t locale = newlocale(LC_ALL_MASK, "C", nullptr);
	return locale;
}

// What from_chars accepts, and nothing else: no leading space or "+", no hexadecimal, the whole text used.
template <typename T>
std::optional<T> parse_float(std::string_view p_text) {
	if (p_text.empty() || p_text.front() == '+' || p_text.front() == ' ' || p_text.front() == '\t') {
		return std::nullopt;
	}
	const std::string_view unsigned_text = p_text.substr(p_text.front() == '-' ? 1 : 0);
	if (unsigned_text.size() >= 2 && unsigned_text[0] == '0' && (unsigned_text[1] == 'x' || unsigned_text[1] == 'X')) {
		return std::nullopt;
	}
	const std::string text(p_text);
	char *end = nullptr;
	errno = 0;
	T value{};
	if constexpr (std::is_same_v<T, float>) {
		value = strtof_l(text.c_str(), &end, c_locale());
	} else {
		value = static_cast<T>(strtod_l(text.c_str(), &end, c_locale()));
	}
	if (end != text.c_str() + text.size() || errno == ERANGE) {
		return std::nullopt;
	}
	return value;
}

// The shortest text that reads back as the same float, as to_chars gives.
inline std::string format_float(float p_value) {
	std::array<char, 32> buffer{};
	for (int precision = 1; precision <= 9; precision++) {
		snprintf_l(buffer.data(), buffer.size(), c_locale(), "%.*g", precision, static_cast<double>(p_value));
		if (strtof_l(buffer.data(), nullptr, c_locale()) == p_value) {
			break;
		}
	}
	return std::string(buffer.data());
}
#endif

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
#if defined(__APPLE__)
	if constexpr (std::is_floating_point_v<T>) {
		return parse_float<T>(p_text);
	} else
#endif
	{
		T value{};
		const char *const end = p_text.data() + p_text.size();
		const std::from_chars_result result = std::from_chars(p_text.data(), end, value);
		if (result.ec != std::errc{} || result.ptr != end) {
			return std::nullopt;
		}
		return value;
	}
}

} // namespace dagon::core
