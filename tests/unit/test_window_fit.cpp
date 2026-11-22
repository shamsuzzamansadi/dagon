#include "core/window_fit.hpp"

#include "doctest.h"

using namespace dagon::core;

TEST_CASE("a 1080p screen keeps the window at three times the picture") {
	// 1920 x 1080 less a taskbar and a title bar.
	const WindowFit fit = fit_window(1904, 1001, 480, 270, 3);
	CHECK(fit.scale == 3);
	CHECK(fit.width == 1440);
	CHECK(fit.height == 810);
}

TEST_CASE("a 720p screen gets twice the picture, which fits with its frame") {
	const WindowFit fit = fit_window(1264, 641, 480, 270, 3);
	CHECK(fit.scale == 2);
	CHECK(fit.width == 960);
	CHECK(fit.height == 540);
}

TEST_CASE("a larger screen does not grow the window past the preferred scale") {
	CHECK(fit_window(3824, 2121, 480, 270, 3).scale == 3);
}

TEST_CASE("exactly enough room is enough") {
	CHECK(fit_window(1440, 810, 480, 270, 3).scale == 3);
	CHECK(fit_window(1439, 810, 480, 270, 3).scale == 2);
}

TEST_CASE("a screen too small for any multiple still gets the picture at its own size") {
	const WindowFit fit = fit_window(400, 200, 480, 270, 3);
	CHECK(fit.scale == 1);
	CHECK(fit.width == 480);
	CHECK(fit.height == 270);
}

TEST_CASE("nonsense sizes give a window rather than nothing") {
	CHECK(fit_window(0, 0, 0, 0, 0).scale == 1);
	CHECK(fit_window(-5, -5, 480, 270, -1).width == 480);
}
