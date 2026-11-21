#include "core/window_fit.hpp"

#include <algorithm>

namespace dagon::core {

WindowFit fit_window(int p_available_width, int p_available_height, int p_picture_width, int p_picture_height, int p_preferred_scale) {
	WindowFit fit;
	const int width = std::max(1, p_picture_width);
	const int height = std::max(1, p_picture_height);
	for (int scale = std::max(1, p_preferred_scale); scale >= 1; scale--) {
		if (width * scale <= p_available_width && height * scale <= p_available_height) {
			fit.scale = scale;
			break;
		}
	}
	fit.width = width * fit.scale;
	fit.height = height * fit.scale;
	return fit;
}

} // namespace dagon::core
