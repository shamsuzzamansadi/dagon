#include "core/sequence_puzzle.hpp"

#include "doctest.h"

#include <algorithm>
#include <array>
#include <string>
#include <vector>

using namespace dagon::core;

namespace {

constexpr double DELAY = 1.0;

SequencePuzzle stones() {
	SequencePuzzle puzzle;
	puzzle.configure({ "wave", "kneel", "eye" }, DELAY);
	return puzzle;
}

} // namespace

TEST_CASE("the right stones in order solve the puzzle") {
	SequencePuzzle puzzle = stones();
	CHECK(puzzle.state() == PuzzleState::Idle);
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Accepted);
	CHECK(puzzle.state() == PuzzleState::Progress);
	CHECK(puzzle.progress() == 1);
	CHECK(puzzle.submit("kneel", 0.0) == PuzzleResult::Accepted);
	CHECK(puzzle.progress() == 2);
	CHECK(puzzle.submit("eye", 0.0) == PuzzleResult::Solved);
	CHECK(puzzle.is_solved());
	CHECK(puzzle.state() == PuzzleState::Solved);
}

TEST_CASE("a stone already lit in this attempt does nothing and costs nothing") {
	SequencePuzzle puzzle = stones();
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Accepted);
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Ignored);
	CHECK(puzzle.progress() == 1);
	CHECK(puzzle.state() == PuzzleState::Progress);
	CHECK(puzzle.submit("kneel", 0.0) == PuzzleResult::Accepted);
	// An earlier stone too, not only the latest one.
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Ignored);
	CHECK(puzzle.submit("kneel", 0.0) == PuzzleResult::Ignored);
	CHECK(puzzle.progress() == 2);
	CHECK(puzzle.submit("eye", 0.0) == PuzzleResult::Solved);
}

TEST_CASE("a wrong stone starts a lockout and clears the attempt") {
	SequencePuzzle puzzle = stones();
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Accepted);
	CHECK(puzzle.submit("eye", 5.0) == PuzzleResult::Rejected);
	CHECK(puzzle.state() == PuzzleState::Rejecting);
	CHECK(puzzle.progress() == 0);
}

TEST_CASE("presses are ignored during the lockout and work again exactly when it ends") {
	SequencePuzzle puzzle = stones();
	CHECK(puzzle.submit("eye", 10.0) == PuzzleResult::Rejected);
	CHECK(puzzle.submit("wave", 10.0) == PuzzleResult::Ignored);
	CHECK(puzzle.submit("wave", 10.999) == PuzzleResult::Ignored);
	CHECK(puzzle.state() == PuzzleState::Rejecting);
	CHECK(puzzle.progress() == 0);
	// A press at the moment the lockout ends counts, and starts a fresh attempt.
	CHECK(puzzle.submit("wave", 11.0) == PuzzleResult::Accepted);
	CHECK(puzzle.progress() == 1);
}

TEST_CASE("update ends the lockout once and only when its time has passed") {
	SequencePuzzle puzzle = stones();
	CHECK_FALSE(puzzle.update(0.0));
	CHECK(puzzle.submit("kneel", 2.0) == PuzzleResult::Rejected);
	CHECK_FALSE(puzzle.update(2.5));
	CHECK(puzzle.state() == PuzzleState::Rejecting);
	CHECK(puzzle.update(3.0));
	CHECK(puzzle.state() == PuzzleState::Idle);
	CHECK_FALSE(puzzle.update(4.0));
}

TEST_CASE("every order of three distinct stones ends in a solve or a rejection, and only one order solves it") {
	std::array<std::string, 3> order = { "eye", "kneel", "wave" };
	int solved = 0;
	int orders = 0;
	do {
		SequencePuzzle puzzle = stones();
		PuzzleResult last = PuzzleResult::Ignored;
		for (const std::string &id : order) {
			last = puzzle.submit(id, 0.0);
			if (last == PuzzleResult::Rejected) {
				break;
			}
		}
		CHECK((last == PuzzleResult::Solved || last == PuzzleResult::Rejected));
		solved += last == PuzzleResult::Solved ? 1 : 0;
		orders++;
	} while (std::next_permutation(order.begin(), order.end()));
	CHECK(orders == 6);
	CHECK(solved == 1);
}

TEST_CASE("remembering what failed needs at most three failed attempts") {
	SequencePuzzle puzzle = stones();
	double now = 0.0;
	int failures = 0;
	CHECK(puzzle.submit("eye", now) == PuzzleResult::Rejected);
	failures++;
	now += DELAY;
	CHECK(puzzle.submit("kneel", now) == PuzzleResult::Rejected);
	failures++;
	now += DELAY;
	CHECK(puzzle.submit("wave", now) == PuzzleResult::Accepted);
	CHECK(puzzle.submit("eye", now) == PuzzleResult::Rejected);
	failures++;
	now += DELAY;
	CHECK(puzzle.submit("wave", now) == PuzzleResult::Accepted);
	CHECK(puzzle.submit("kneel", now) == PuzzleResult::Accepted);
	CHECK(puzzle.submit("eye", now) == PuzzleResult::Solved);
	CHECK(failures == 3);
}

TEST_CASE("solved is terminal") {
	SequencePuzzle puzzle = stones();
	puzzle.submit("wave", 0.0);
	puzzle.submit("kneel", 0.0);
	puzzle.submit("eye", 0.0);
	for (const char *const id : { "wave", "kneel", "eye", "nothing" }) {
		CHECK(puzzle.submit(id, 100.0) == PuzzleResult::Ignored);
	}
	puzzle.reset();
	CHECK(puzzle.is_solved());
	CHECK_FALSE(puzzle.update(1000.0));
	CHECK(puzzle.is_solved());
}

TEST_CASE("an unknown stone changes nothing, whatever the state") {
	SequencePuzzle puzzle = stones();
	CHECK_FALSE(puzzle.knows("nothing"));
	CHECK(puzzle.knows("kneel"));
	CHECK(puzzle.submit("nothing", 0.0) == PuzzleResult::Ignored);
	CHECK(puzzle.state() == PuzzleState::Idle);
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Accepted);
	CHECK(puzzle.submit("", 0.0) == PuzzleResult::Ignored);
	CHECK(puzzle.progress() == 1);
}

TEST_CASE("reset clears an attempt or a lockout") {
	SequencePuzzle puzzle = stones();
	puzzle.submit("wave", 0.0);
	puzzle.reset();
	CHECK(puzzle.state() == PuzzleState::Idle);
	CHECK(puzzle.progress() == 0);
	puzzle.submit("eye", 0.0);
	CHECK(puzzle.state() == PuzzleState::Rejecting);
	puzzle.reset();
	CHECK(puzzle.state() == PuzzleState::Idle);
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Accepted);
}

TEST_CASE("restoring goes straight to solved") {
	SequencePuzzle puzzle = stones();
	puzzle.submit("wave", 0.0);
	puzzle.restore_solved();
	CHECK(puzzle.is_solved());
	CHECK(puzzle.progress() == puzzle.length());
	CHECK(puzzle.submit("wave", 0.0) == PuzzleResult::Ignored);
}

TEST_CASE("any length works, and an empty solution never solves") {
	SequencePuzzle one;
	one.configure({ "a" }, DELAY);
	CHECK(one.submit("a", 0.0) == PuzzleResult::Solved);

	SequencePuzzle repeated;
	repeated.configure({ "a", "a", "b" }, DELAY);
	CHECK(repeated.submit("a", 0.0) == PuzzleResult::Accepted);
	CHECK(repeated.submit("a", 0.0) == PuzzleResult::Accepted);
	CHECK(repeated.submit("b", 0.0) == PuzzleResult::Solved);

	SequencePuzzle empty;
	empty.configure({}, DELAY);
	CHECK(empty.submit("a", 0.0) == PuzzleResult::Ignored);
	CHECK_FALSE(empty.is_solved());
}

TEST_CASE("configuring starts again") {
	SequencePuzzle puzzle = stones();
	puzzle.restore_solved();
	puzzle.configure({ "x", "y" }, 2.0);
	CHECK(puzzle.state() == PuzzleState::Idle);
	CHECK(puzzle.length() == 2);
	CHECK(puzzle.submit("y", 0.0) == PuzzleResult::Rejected);
	CHECK_FALSE(puzzle.update(1.5));
	CHECK(puzzle.update(2.0));
}
