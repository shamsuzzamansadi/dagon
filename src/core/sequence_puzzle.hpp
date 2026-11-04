#pragma once

// Plain-C++ rules for pressing stones in order. No Godot headers. Time is passed in, so tests need no clock.

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace dagon::core {

enum class PuzzleResult {
	Accepted,
	Rejected,
	Solved,
	Ignored,
};

enum class PuzzleState {
	Idle,
	Progress,
	Rejecting,
	Solved,
};

class SequencePuzzle {
public:
	void configure(std::vector<std::string> p_solution, double p_reset_delay);

	// Asks what a press does at this moment, and applies it.
	PuzzleResult submit(std::string_view p_id, double p_now);

	// Ends the lockout once its time has passed. True only on the call that ended it.
	bool update(double p_now);

	// Clears the current attempt. A solved puzzle stays solved.
	void reset();

	// Goes straight to the solved state, for a world restored from a checkpoint.
	void restore_solved();

	PuzzleState state() const { return state_; }
	std::size_t progress() const { return progress_; }
	std::size_t length() const { return solution_.size(); }
	bool is_solved() const { return state_ == PuzzleState::Solved; }
	bool knows(std::string_view p_id) const;

private:
	std::vector<std::string> solution_;
	double reset_delay_ = 1.0;
	double rejecting_until_ = 0.0;
	std::size_t progress_ = 0;
	PuzzleState state_ = PuzzleState::Idle;
};

} // namespace dagon::core
