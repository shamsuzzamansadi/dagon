#include "core/flee.hpp"

#include <algorithm>

namespace dagon::core {

float tide_front(const TideParams &p_tide, double p_elapsed) {
	const double moving = std::max(0.0, p_elapsed - static_cast<double>(p_tide.delay));
	const double travelled = std::max(0.0, static_cast<double>(p_tide.speed)) * moving;
	return static_cast<float>(static_cast<double>(p_tide.start_x) - travelled);
}

FleeEnd flee_end(const TideParams &p_tide, double p_elapsed, float p_sailor_x, double p_fallback_seconds) {
	if (p_sailor_x >= tide_front(p_tide, p_elapsed) - p_tide.reach) {
		return FleeEnd::Overtaken;
	}
	if (p_elapsed >= p_fallback_seconds) {
		return FleeEnd::Fallback;
	}
	return FleeEnd::None;
}

} // namespace dagon::core
