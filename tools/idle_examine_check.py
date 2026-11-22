#!/usr/bin/env python3
"""M2's unexplained examine, tried again on the exported build (M6 plan, item 11).

In one scripted Windows run in M2, on the owner's desktop and a loaded machine, an examine fired at the boat while
nothing was being pressed: after Examine had been rebound to J in the pause menu's Settings and the game resumed, in a
six-second wait. It never came back, and its cause was not established (docs/evidence/m2/review-round-2/README.md).

This repeats M2's steps exactly, in a new process each time, with keys sent to the game's window only: New Game, the
introduction, the prologue skipped; at the boat, E examines; the pause menu's Settings, Examine rebound to J; back to
the game; **then six seconds of pressing nothing,** watching the game's own log for anything examined or said. Then E,
which must do nothing, and J, which must examine. With --busy, that many processes keep the processors busy throughout,
as M2's loaded runs did.

  idle_examine_check.py <exported binary> <out dir> --runs 10 [--busy 9] --display :77   Linux, a private X display
  idle_examine_check.py <exported binary> <out dir> --runs 10 [--busy 9] --windows-ci    Windows, a CI runner only
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import route_check  # noqa: E402
from route_check import Game, LinuxKeys, RouteFailed, WindowsKeys  # noqa: E402

route_check.KEYS["j"] = ("j", 0x4A, 0x24)

# What the game logs when a line is said, shown or cut short: the result of any examine.
EXAMINED = ("dagon: line: ", "dagon: caption: ", "dagon: line skipped")


def idle_run(game, out_name, notes):
    game.wait_for("dagon: save status=")
    time.sleep(0.5)
    game.tap("enter")
    game.wait_for("dagon: introduction shown")
    time.sleep(0.5)
    game.tap("enter")
    game.wait_for("dagon: prologue shown")
    time.sleep(0.5)
    game.tap("escape")
    game.wait_for("dagon: prologue finished skipped=true", 10)
    game.wait_for("dagon: prompt: [E] Examine", 20)
    time.sleep(0.3)
    game.tap("examine")
    game.wait_for("dagon: line: ", 5)
    # The line said to its end, as in M2, where the earlier caption had gone before the wait: the prompt is Examine again.
    game.wait_for("dagon: prompt: [E] Examine", 30)
    time.sleep(0.3)

    # The pause menu's Settings: Music has focus, and eight presses down reach Examine's key.
    game.tap("escape")
    time.sleep(0.2)
    game.tap("menu_down")
    game.tap("menu_down")
    game.tap("enter")
    time.sleep(0.3)
    for _ in range(8):
        game.tap("menu_down")
    game.tap("enter")
    time.sleep(0.2)
    game.tap("j")
    # Settings logs its key names as it opens, and again when one changes.
    game.wait_for("dagon: key labels: A D Space J", 5)
    time.sleep(0.3)
    game.tap("escape")
    time.sleep(0.2)
    game.tap("escape")

    # Nothing pressed: anything said or shown in these six seconds came from nowhere.
    deadline = time.monotonic() + 6.0
    stray = []
    while time.monotonic() < deadline:
        line = game._next_line(deadline)
        if line.startswith(EXAMINED):
            stray.append(line)
    notes.append(f"{out_name}: during the six seconds with nothing pressed: " + ("nothing examined or said" if not stray else f"{len(stray)} lines: {stray}"))

    # E is no longer Examine; J is.
    game.tap("examine")
    old_key = []
    deadline = time.monotonic() + 1.5
    while time.monotonic() < deadline:
        line = game._next_line(deadline)
        if line.startswith(EXAMINED):
            old_key.append(line)
    game.tap("j")
    game.wait_for("dagon: line: ", 5)
    if old_key:
        raise RouteFailed(f"the old key E still examined: {old_key}")
    return stray


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("binary", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--runs", type=int, default=10)
    parser.add_argument("--busy", type=int, default=0, help="Processes kept busy throughout, to load the machine.")
    parser.add_argument("--display", help="Linux: the private X display to run on. Never a real desktop.")
    parser.add_argument("--windows-ci", action="store_true", help="Windows: only on a throwaway CI runner.")
    args = parser.parse_args()
    args.binary = args.binary.resolve()
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out.resolve()

    if sys.platform == "win32":
        if not args.windows_ci or os.environ.get("CI") != "true":
            sys.exit("idle_examine_check: this posts keys to a window. On Windows it runs only with --windows-ci, on a CI runner.")
        keys = WindowsKeys()
    else:
        if not args.display:
            sys.exit("idle_examine_check: name the private X display with --display. It never uses the desktop's.")
        keys = LinuxKeys(args.display)

    busy = [subprocess.Popen([sys.executable, "-c", "while True: pass"]) for _ in range(args.busy)]
    notes = []
    strays = 0
    failures = []
    try:
        for run in range(1, args.runs + 1):
            storage = tempfile.mkdtemp(prefix="dagon-idle-")
            env = dict(os.environ, DAGON_STORAGE_DIR=storage.replace("\\", "/"), XDG_DATA_HOME=storage, APPDATA=storage, LOCALAPPDATA=storage)
            if args.display:
                env["DISPLAY"] = args.display
            env.pop("WAYLAND_DISPLAY", None)
            env.pop("DAGON_AUTOSTART", None)
            name = f"idle-{run:02d}" + (f"-busy{args.busy}" if args.busy else "")
            try:
                with open(out / f"{name}-route.log", "w", encoding="utf-8") as transcript:
                    game = Game(args.binary, keys, env, transcript, None, out / f"{name}-game.log")
                    try:
                        stray = idle_run(game, name, notes)
                        strays += 1 if stray else 0
                        if game.errors:
                            failures.append(f"{name}: the game logged errors: {game.errors[:3]}")
                    except RouteFailed as error:
                        failures.append(f"{name}: {error}")
                    finally:
                        game.close()
            finally:
                shutil.rmtree(storage, ignore_errors=True)
            print(f"IDLE {notes[-1] if notes and notes[-1].startswith(name) else name + ': did not reach the wait'}", flush=True)
    finally:
        for process in busy:
            process.kill()
    for failure in failures:
        print(f"IDLE FAILED: {failure}")
    print(f"IDLE_RESULT runs={args.runs} busy={args.busy} examined_with_nothing_pressed={strays} failed={len(failures)}")
    return 1 if strays or failures else 0


if __name__ == "__main__":
    sys.exit(main())
