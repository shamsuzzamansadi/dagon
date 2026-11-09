#pragma once

// Plain-C++ rules for the escape: where the returning sea has reached, and when it has the sailor. No Godot headers.

namespace dagon::core {

struct TideParams {
	// Where the water's front starts, at the trench edge.
	float start_x = 4540.0f;
	// Leftward, in pixels a second. Under walking pace, so running away always gains on it.
	float speed = 64.0f;
	// Seconds of the flee before it starts to come on, while it rises out of the trench.
	float delay = 2.5f;
	// How far ahead of its drawn front it already has him: the spray, and his heels.
	float reach = 6.0f;
};

enum class FleeEnd {
	None,
	// The water reached him.
	Overtaken,
	// The bounded guard against anything that could leave the flee running for ever.
	Fallback,
};

// The front's x this long into the flee. It never moves right, and never past where it started.
float tide_front(const TideParams &p_tide, double p_elapsed);

// Whether the flee ends now, and why. Reaching the collapse point is a trigger, not decided here.
FleeEnd flee_end(const TideParams &p_tide, double p_elapsed, float p_sailor_x, double p_fallback_seconds);

} // namespace dagon::core
