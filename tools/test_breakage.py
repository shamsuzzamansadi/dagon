#!/usr/bin/env python3
"""Tests of tools/breakage.py's verdicts, with a fake build and fake test runs: no Godot, no compiler.

    python tools/test_breakage.py
"""

import io
import queue
import sys
import threading
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import breakage  # noqa: E402
from breakage import BUILD_FAILED, CAUGHT, INFRA, NOT_APPLIED, NOT_CAUGHT, NOT_RUN, Outcome  # noqa: E402

CLEAN = Outcome(0, 0, 0, 100, 0)
FAILING = Outcome(0, 0, 1, 97, 3, ["FAIL some.test"])


class FakeRunner:
    """Builds and tests on cue. files holds the code; outcomes is what each test run shows, in order."""

    def __init__(self, files, outcomes, builds=None, restores=True):
        self.files = dict(files)
        self.original = dict(files)
        self.outcomes = list(outcomes)
        self.builds = list(builds or [])
        self.restores = restores
        self.tests_run = 0

    def build(self):
        return (self.builds.pop(0) if self.builds else True), "build log"

    def prepare(self):
        pass

    def test(self):
        self.tests_run += 1
        return self.outcomes.pop(0)

    def read(self, path):
        return self.files[path]

    def write(self, path, text):
        self.files[path] = text

    def restore(self, path):
        if self.restores:
            self.files[path] = self.original[path]
        return self.files[path] == self.original[path]


def run(runner, breakages):
    jobs = queue.Queue()
    for pair in enumerate(breakages):
        jobs.put(pair)
    results = {}
    ok = breakage.run_worker(runner, jobs, results, io.StringIO(), threading.Lock())
    return ok, results, jobs


class Verdicts(unittest.TestCase):
    def test_a_complete_run_with_failures_is_caught(self):
        self.assertEqual(breakage.verdict(FAILING), CAUGHT)

    def test_a_complete_clean_run_is_not_caught(self):
        self.assertEqual(breakage.verdict(CLEAN), NOT_CAUGHT)

    def test_unit_failures_alone_are_caught(self):
        self.assertEqual(breakage.verdict(Outcome(1, 2, 0, 100, 0)), CAUGHT)

    def test_a_crash_or_timeout_is_never_caught(self):
        self.assertEqual(breakage.verdict(Outcome(0, 0, None, None, None)), INFRA)
        self.assertEqual(breakage.verdict(Outcome(None, None, 0, 100, 0)), INFRA)

    def test_a_run_with_no_result_line_is_never_caught(self):
        self.assertEqual(breakage.verdict(Outcome(0, 0, 134, None, None)), INFRA)

    def test_a_run_with_no_unit_summary_is_never_caught(self):
        self.assertEqual(breakage.verdict(Outcome(1, None, 0, 100, 0)), INFRA)

    def test_an_exit_code_that_disagrees_with_its_counts_is_never_trusted(self):
        self.assertEqual(breakage.verdict(Outcome(0, 0, 1, 100, 0)), INFRA)
        self.assertEqual(breakage.verdict(Outcome(0, 0, 0, 97, 3)), INFRA)
        self.assertEqual(breakage.verdict(Outcome(1, 0, 0, 100, 0)), INFRA)

    def test_a_run_of_no_tests_is_never_trusted(self):
        self.assertEqual(breakage.verdict(Outcome(0, 0, 0, 0, 0)), INFRA)

    def test_the_parsers_read_the_real_summary_lines(self):
        self.assertEqual(breakage.parse_unit("[doctest] test cases:  127 |  125 passed | 2 failed | 0 skipped"), 2)
        self.assertIsNone(breakage.parse_unit("Segmentation fault"))
        self.assertEqual(breakage.parse_result("PASS a\nRESULT passed=10 failed=0\nRESULT passed=405 failed=2\n"), (405, 2))
        self.assertEqual(breakage.parse_result("PASS a\nhandle_crash: Program crashed\n"), (None, None))


class Worker(unittest.TestCase):
    ENTRY = ("A change", "src/x.cpp", "keep();", "")

    def test_a_failing_control_runs_nothing_and_fails_the_worker(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [FAILING])
        ok, results, jobs = run(runner, [self.ENTRY])
        self.assertFalse(ok)
        self.assertEqual(results, {})
        self.assertEqual(jobs.qsize(), 1)

    def test_a_control_that_does_not_build_fails_the_worker(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [], builds=[False])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertFalse(ok)
        self.assertEqual(runner.tests_run, 0)

    def test_text_that_is_not_there_is_not_applied_and_not_counted(self):
        runner = FakeRunner({"src/x.cpp": "other();"}, [CLEAN, CLEAN])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertTrue(ok)
        self.assertEqual(results[0][1], NOT_APPLIED)

    def test_text_that_occurs_twice_is_not_applied(self):
        runner = FakeRunner({"src/x.cpp": "keep(); keep();"}, [CLEAN, CLEAN])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertEqual(results[0][1], NOT_APPLIED)

    def test_a_breakage_that_does_not_build_is_build_failed_not_caught(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [CLEAN, CLEAN], builds=[True, False, True])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertTrue(ok)
        self.assertEqual(results[0][1], BUILD_FAILED)
        self.assertEqual(runner.files["src/x.cpp"], "keep();")

    def test_a_breakage_whose_run_crashes_is_infra_not_caught(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [CLEAN, Outcome(0, 0, None, None, None), CLEAN])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertEqual(results[0][1], INFRA)

    def test_a_breakage_the_tests_notice_is_caught_and_the_file_is_put_back(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [CLEAN, FAILING, CLEAN])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertTrue(ok)
        self.assertEqual(results[0][1], CAUGHT)
        self.assertEqual(results[0][2], 3)
        self.assertEqual(runner.files["src/x.cpp"], "keep();")

    def test_a_control_that_fails_afterwards_fails_the_worker(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [CLEAN, FAILING, FAILING])
        ok, results, _ = run(runner, [self.ENTRY])
        self.assertFalse(ok)

    def test_a_file_that_cannot_be_put_back_stops_the_worker(self):
        runner = FakeRunner({"src/x.cpp": "keep();"}, [CLEAN, FAILING, CLEAN], restores=False)
        ok, results, _ = run(runner, [self.ENTRY, ("Another", "src/x.cpp", "keep();", "")])
        self.assertFalse(ok)


class Summary(unittest.TestCase):
    BREAKAGES = [("One", "a", "x", "y"), ("Two", "a", "x", "z")]

    def test_a_run_with_every_verdict_valid_and_every_control_held_is_valid(self):
        results = {0: ("One", CAUGHT, 2, ""), 1: ("Two", NOT_CAUGHT, 0, "")}
        _, _, complete, valid = breakage.summarize(self.BREAKAGES, results, [True, True])
        self.assertTrue(complete and valid)

    def test_a_breakage_that_never_ran_makes_the_run_invalid(self):
        lines, tally, complete, valid = breakage.summarize(self.BREAKAGES, {0: ("One", CAUGHT, 2, "")}, [True])
        self.assertFalse(complete or valid)
        self.assertEqual(tally[NOT_RUN], 1)
        self.assertEqual(len(lines), 2)

    def test_any_invalid_verdict_makes_the_run_invalid(self):
        for bad in (INFRA, BUILD_FAILED, NOT_APPLIED):
            results = {0: ("One", CAUGHT, 2, ""), 1: ("Two", bad, None, "")}
            self.assertFalse(breakage.summarize(self.BREAKAGES, results, [True])[3], bad)

    def test_a_failed_control_makes_the_run_invalid_whatever_the_verdicts(self):
        results = {0: ("One", CAUGHT, 2, ""), 1: ("Two", CAUGHT, 1, "")}
        self.assertFalse(breakage.summarize(self.BREAKAGES, results, [True, False])[3])

    def test_two_breakages_with_one_name_make_the_summary_incomplete(self):
        twins = [("One", "a", "x", "y"), ("One", "a", "x", "z")]
        results = {0: ("One", CAUGHT, 1, ""), 1: ("One", CAUGHT, 1, "")}
        self.assertFalse(breakage.summarize(twins, results, [True])[2])


if __name__ == "__main__":
    unittest.main(verbosity=1)
