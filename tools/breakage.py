#!/usr/bin/env python3
"""Deliberate breakage: makes one change to the code at a time, and records whether the tests notice.

It fails closed. A result counts only if everything around it worked:

  - Each worker's clean control must build and pass, before its first breakage and after its last. If it does not,
    nothing that worker ran counts, and the run fails.
  - A breakage whose text is not found in its file was never made. It is NOT APPLIED, never "not caught".
  - A breakage that does not build proves nothing about the tests. It is BUILD FAILED, never "caught".
  - A test run that crashes, times out, or ends without its result line is INFRA, never "caught".
  - Only a complete test run with failing tests is CAUGHT, and only a complete, clean run is NOT CAUGHT.
  - The file is put back after each breakage, and checked to be back.
  - The summary must name every breakage exactly once.

Exit status: 0 when every breakage has a valid verdict, CAUGHT or NOT CAUGHT, and the summary is complete.
2 when anything is invalid. A NOT CAUGHT is a finding to look into, not a failure of the tool.

    python tools/breakage.py ENTRIES.py WORKDIR [--workers N] [--only TEXT ...]

ENTRIES.py defines BREAKAGES, a list of (name, path, old text, new text). WORKDIR holds the clones, w0, w1 and so on,
each a clone of the commit under test with its submodules, made beforehand. Simulated input only: it runs the
project's own unit and integration tests, with storage isolated by tools/test_storage.sh's rules.
"""

import argparse
import importlib.util
import os
import queue
import re
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass, field

CAUGHT = "CAUGHT"
NOT_CAUGHT = "NOT CAUGHT"
NOT_APPLIED = "NOT APPLIED"
BUILD_FAILED = "BUILD FAILED"
INFRA = "INFRA"
NOT_RUN = "NOT RUN"
VALID = (CAUGHT, NOT_CAUGHT)

TEST_TIMEOUT_SECONDS = 1500
BUILD_TIMEOUT_SECONDS = 1800


@dataclass
class Outcome:
    """What one run of the tests showed. exit is None when the process never finished."""

    unit_exit: int | None
    unit_cases_failed: int | None
    godot_exit: int | None
    passed: int | None
    failed: int | None
    failures: list = field(default_factory=list)


def parse_unit(text):
    """The failed count from doctest's summary line, or None if it never printed one."""
    match = re.search(r"\[doctest\] test cases:\s*(\d+)\s*\|\s*(\d+) passed\s*\|\s*(\d+) failed", text)
    return int(match.group(3)) if match else None


def parse_result(text):
    """passed and failed from the runner's last RESULT line, or (None, None) if there is none."""
    matches = re.findall(r"^RESULT passed=(\d+) failed=(\d+)\s*$", text, re.M)
    if not matches:
        return None, None
    passed, failed = matches[-1]
    return int(passed), int(failed)


def verdict(outcome):
    """CAUGHT, NOT CAUGHT or INFRA, from one complete outcome. Never CAUGHT for a run that did not complete."""
    if outcome.unit_exit is None or outcome.godot_exit is None:
        return INFRA
    if outcome.unit_cases_failed is None or outcome.passed is None or outcome.failed is None:
        return INFRA
    if outcome.passed == 0 and outcome.failed == 0:
        return INFRA
    # The unit tests' exit code and its summary must agree, and so must the runner's.
    if (outcome.unit_exit != 0) != (outcome.unit_cases_failed > 0):
        return INFRA
    if (outcome.godot_exit != 0) != (outcome.failed > 0):
        return INFRA
    if outcome.unit_cases_failed > 0 or outcome.failed > 0:
        return CAUGHT
    return NOT_CAUGHT


def control_is_clean(outcome):
    return verdict(outcome) == NOT_CAUGHT


class Runner:
    """Runs the real build and tests in one clone. Replaced by a fake in tools/test_breakage.py."""

    def __init__(self, cwd, scons, godot, env):
        self.cwd = cwd
        self.scons = scons
        self.godot = godot
        self.env = env

    def _run(self, cmd, timeout, env=None):
        try:
            result = subprocess.run(cmd, cwd=self.cwd, env=env or self.env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace", timeout=timeout)
            return result.returncode, result.stdout
        except subprocess.TimeoutExpired as error:
            out = error.stdout if isinstance(error.stdout, str) else ""
            return None, out + "\nTIMED OUT\n"

    def build(self):
        code, out = self._run([self.scons, "platform=linux", "target=template_debug", "-j3"], BUILD_TIMEOUT_SECONDS)
        return code == 0, out

    def prepare(self):
        self._run(["sh", "tools/prepare_project.sh"], 300)
        self._run([self.godot, "--headless", "--path", "project", "--import"], 600)

    def test(self):
        unit_exit, unit_out = self._run([self.scons, "unit_tests"], BUILD_TIMEOUT_SECONDS)
        storage = tempfile.mkdtemp(prefix="dagon-test-", dir=self.env.get("TMPDIR"))
        try:
            godot_exit, godot_out = self._run([self.godot, "--headless", "--path", "project", "--fixed-fps", "60", "--script", "res://tests/run_tests.gd"], TEST_TIMEOUT_SECONDS, dict(self.env, DAGON_STORAGE_DIR=storage))
        finally:
            subprocess.run(["rm", "-rf", "--", storage], check=False)
        passed, failed = parse_result(godot_out)
        failures = [line for line in godot_out.splitlines() if line.startswith("FAIL")][:40]
        return Outcome(unit_exit, parse_unit(unit_out), godot_exit, passed, failed, failures)

    def read(self, path):
        with open(os.path.join(self.cwd, path)) as handle:
            return handle.read()

    def write(self, path, text):
        with open(os.path.join(self.cwd, path), "w") as handle:
            handle.write(text)

    def restore(self, path):
        subprocess.run(["git", "checkout", "--", path], cwd=self.cwd, check=False)
        return subprocess.run(["git", "diff", "--quiet", "--", path], cwd=self.cwd).returncode == 0


def run_worker(runner, jobs, results, log, lock):
    """One worker: control, then breakages, then control again. Returns False if a control failed."""

    def say(text):
        with lock:
            log.write(text + "\n")
            log.flush()

    built, out = runner.build()
    if not built:
        say("CONTROL DID NOT BUILD\n" + out[-1500:])
        return False
    runner.prepare()
    before = runner.test()
    say(f"control before: {verdict(before)} passed={before.passed} failed={before.failed} unit_failed={before.unit_cases_failed}")
    if not control_is_clean(before):
        say("CONTROL BEFORE FAILED: this worker's results do not count")
        return False
    while True:
        try:
            order, (name, path, old, new) = jobs.get_nowait()
        except queue.Empty:
            break
        text = runner.read(path)
        if text.count(old) != 1:
            results[order] = (name, NOT_APPLIED, None, f"the text occurs {text.count(old)} times in {path}")
            say(f"=== {name}: {NOT_APPLIED}")
            continue
        runner.write(path, text.replace(old, new))
        needs_build = path.startswith("src")
        outcome = None
        if needs_build:
            built, out = runner.build()
            if not built:
                results[order] = (name, BUILD_FAILED, None, out[-400:])
        if not needs_build or built:
            outcome = runner.test()
            results[order] = (name, verdict(outcome), outcome.failed, "\n".join(outcome.failures[:6]))
        say(f"=== {name}: {results[order][1]}" + (f" ({outcome.failed} failing)" if outcome and outcome.failed else ""))
        if not runner.restore(path):
            say(f"COULD NOT RESTORE {path}: stopping this worker")
            return False
        if needs_build:
            runner.build()
    after = runner.test()
    say(f"control after: {verdict(after)} passed={after.passed} failed={after.failed}")
    if not control_is_clean(after):
        say("CONTROL AFTER FAILED: this worker's results do not count")
        return False
    return True


def summarize(breakages, results, worker_ok):
    """Every breakage exactly once, with its verdict. The run is valid only if every control held, every breakage
    ran, and each verdict is CAUGHT or NOT CAUGHT."""
    lines = []
    tally = {}
    for order, entry in enumerate(breakages):
        verdict_text, count = (results[order][1], results[order][2]) if order in results else (NOT_RUN, None)
        tally[verdict_text] = tally.get(verdict_text, 0) + 1
        lines.append(f"{verdict_text:13} {'' if count is None else count:>4}  {entry[0]}")
    names_unique = len({entry[0] for entry in breakages}) == len(breakages)
    complete = names_unique and all(order in results for order in range(len(breakages)))
    valid = complete and all(worker_ok) and all(v in VALID for v in tally)
    return lines, tally, complete, valid


def load_entries(path):
    spec = importlib.util.spec_from_file_location("breakage_entries", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.BREAKAGES


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("entries")
    parser.add_argument("workdir")
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--only", nargs="*", default=[])
    parser.add_argument("--scons", default="scons")
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    args = parser.parse_args(argv)
    breakages = load_entries(args.entries)
    if args.only:
        breakages = [b for b in breakages if any(o in b[0] for o in args.only)]
    jobs = queue.Queue()
    for pair in enumerate(breakages):
        jobs.put(pair)
    results = {}
    lock = threading.Lock()
    worker_ok = [False] * args.workers
    logs = [open(os.path.join(args.workdir, f"out-{i}.txt"), "w") for i in range(args.workers)]

    def work(index):
        runner = Runner(os.path.join(args.workdir, f"w{index}"), args.scons, args.godot, dict(os.environ))
        worker_ok[index] = run_worker(runner, jobs, results, logs[index], lock)

    threads = [threading.Thread(target=work, args=(i,)) for i in range(args.workers)]
    started = time.time()
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    for log in logs:
        log.close()
    lines, tally, complete, valid = summarize(breakages, results, worker_ok)
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=os.path.join(args.workdir, "w0"), stdout=subprocess.PIPE, text=True).stdout.strip()
    footer = f"commit {commit}, {len(breakages)} breakages, {tally}, controls {'held' if all(worker_ok) else 'FAILED'}, summary {'complete' if complete else 'INCOMPLETE'}, {time.time() - started:.0f} s"
    with open(os.path.join(args.workdir, "summary.txt"), "w") as out:
        out.write("\n".join(lines) + "\n\n" + footer + "\n")
    print("\n".join(lines) + "\n\n" + footer)
    print(f"BREAKAGE_RESULT valid={'yes' if valid else 'no'}")
    return 0 if valid else 2


if __name__ == "__main__":
    sys.exit(main())
