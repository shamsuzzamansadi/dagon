#pragma once

// Plain-C++ rule for the game's window: how large a whole-number multiple of the game's picture fits on the screen.
// Whole numbers keep every pixel the same size. No Godot headers.

namespace dagon::core {

struct WindowFit {
	int scale = 1;
	int width = 0;
	int height = 0;
};

// The largest scale from 1 to p_preferred_scale at which the picture fits in the space available, which is the
// screen's usable area less the window's own frame. Scale 1 when even that does not fit, so there is always a window.
WindowFit fit_window(int p_available_width, int p_available_height, int p_picture_width, int p_picture_height, int p_preferred_scale);

} // namespace dagon::core
