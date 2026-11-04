#include "core/sequence_puzzle.hpp"

#include <algorithm>
#include <utility>

namespace dagon::core {

void SequencePuzzle::configure(std::vector<std::string> p_solution, double p_reset_delay) {
	solution_ = std::move(p_solution);
	reset_delay_ = p_reset_delay;
	rejecting_until_ = 0.0;
	progress_ = 0;
	state_ = PuzzleState::Idle;
}

bool SequencePuzzle::knows(std::string_view p_id) const {
	return std::find(solution_.begin(), solution_.end(), p_id) != solution_.end();
}

PuzzleResult SequencePuzzle::submit(std::string_view p_id, double p_now) {
	update(p_now);
	if (state_ == PuzzleState::Solved || state_ == PuzzleState::Rejecting || !knows(p_id)) {
		return PuzzleResult::Ignored;
	}
	if (solution_[progress_] == p_id) {
		progress_++;
		if (progress_ == solution_.size()) {
			state_ = PuzzleState::Solved;
			return PuzzleResult::Solved;
		}
		state_ = PuzzleState::Progress;
		return PuzzleResult::Accepted;
	}
	// A stone already lit in this attempt does nothing, with no penalty.
	const auto accepted_end = solution_.begin() + static_cast<std::ptrdiff_t>(progress_);
	if (std::find(solution_.begin(), accepted_end, p_id) != accepted_end) {
		return PuzzleResult::Ignored;
	}
	state_ = PuzzleState::Rejecting;
	rejecting_until_ = p_now + reset_delay_;
	progress_ = 0;
	return PuzzleResult::Rejected;
}

bool SequencePuzzle::update(double p_now) {
	if (state_ != PuzzleState::Rejecting || p_now < rejecting_until_) {
		return false;
	}
	state_ = PuzzleState::Idle;
	return true;
}

void SequencePuzzle::reset() {
	if (state_ == PuzzleState::Solved) {
		return;
	}
	progress_ = 0;
	state_ = PuzzleState::Idle;
}

void SequencePuzzle::restore_solved() {
	progress_ = solution_.size();
	state_ = PuzzleState::Solved;
}

} // namespace dagon::core
