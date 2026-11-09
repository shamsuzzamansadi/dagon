#include "core/flee.hpp"

#include "doctest.h"

using namespace dagon::core;

TEST_CASE("the sea waits while it rises, then comes on at its speed") {
	const TideParams tide;
	CHECK(tide_front(tide, 0.0) == doctest::Approx(4540.0));
	CHECK(tide_front(tide, 2.5) == doctest::Approx(4540.0));
	CHECK(tide_front(tide, 3.5) == doctest::Approx(4476.0));
	CHECK(tide_front(tide, 12.5) == doctest::Approx(3900.0));
}

TEST_CASE("the front never moves back, even with a negative speed or time") {
	TideParams tide;
	tide.speed = -10.0f;
	CHECK(tide_front(tide, 50.0) == doctest::Approx(4540.0));
	CHECK(tide_front(TideParams{}, -3.0) == doctest::Approx(4540.0));
}

TEST_CASE("standing still at the ledge, the sea has him in under five seconds") {
	const TideParams tide;
	const float ledge = 4420.0f;
	CHECK(flee_end(tide, 4.0, ledge, 30.0) == FleeEnd::None);
	CHECK(flee_end(tide, 4.4, ledge, 30.0) == FleeEnd::Overtaken);
}

TEST_CASE("running flat out to the collapse point keeps well ahead of it") {
	const TideParams tide;
	// The route measured about 10.2 s from the ledge to x = 3760, hopping three falls of rock.
	for (double t = 0.0; t <= 10.2; t += 0.05) {
		const float x = static_cast<float>(4420.0 - 660.0 * (t / 10.2));
		REQUIRE(flee_end(tide, t, x, 30.0) == FleeEnd::None);
	}
	CHECK(tide_front(tide, 10.2) - 3760.0f > 250.0f);
}

TEST_CASE("losing a few seconds at the rock makes it close, and losing more lets it catch him") {
	const TideParams tide;
	auto caught = [&](double lost) {
		for (double t = 0.0; t <= 10.2 + lost; t += 0.05) {
			const double moving = t < 1.0 ? t : (t < 1.0 + lost ? 1.0 : t - lost);
			const float x = static_cast<float>(4420.0 - 660.0 * (moving / 10.2));
			if (flee_end(tide, t, x, 30.0) == FleeEnd::Overtaken) {
				return true;
			}
		}
		return false;
	};
	CHECK_FALSE(caught(3.0));
	CHECK(caught(6.0));
}

TEST_CASE("the fallback ends a flee that nothing else ends") {
	const TideParams tide;
	CHECK(flee_end(tide, 29.9, -1.0e9f, 30.0) == FleeEnd::None);
	CHECK(flee_end(tide, 30.0, -1.0e9f, 30.0) == FleeEnd::Fallback);
}

TEST_CASE("being reached comes before the fallback when both are true") {
	CHECK(flee_end(TideParams{}, 40.0, 4500.0f, 30.0) == FleeEnd::Overtaken);
}
