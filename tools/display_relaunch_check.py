#!/usr/bin/env python3
"""The Display setting across a relaunch, on the exported build (M6 plan, item 9).

First launch, with fullscreen saved: the game must open fullscreen. In Settings, Display is pressed for a window, and
the game quits to the desktop from the main menu. Second launch, from the same storage: the game must open in a window,
and the settings file must say so. Read from the game's own log ("dagon: display fullscreen", "dagon: window check"),
with a screenshot at each stage.

  display_relaunch_check.py <exported binary> <out dir> --display :77   Linux: a private X display with a window manager
  display_relaunch_check.py <exported binary> <out dir> --windows-ci    Windows: only on a throwaway CI runner
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
from route_check import Game, LinuxKeys, RouteFailed, WindowsKeys  # noqa: E402

SETTINGS = (
    "dagon_settings=1\nmusic_volume=1\neffects_volume=1\nnarration_volume=1\nsubtitles=1\nvibration=1\nfullscreen=1\n"
    "key_move_left=65\nkey_move_right=68\nkey_jump=32\nkey_interact=69\n"
)
WINDOWED, FULLSCREEN = 0, 3


def lines_for(game, seconds):
    """Every line the game logs in the next few seconds."""
    seen = []
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        line = game._next_line(deadline)
        if line:
            seen.append(line)
    return seen


def first_launch(game, shoot, notes):
    game.wait_for("dagon: save status=")
    seen = lines_for(game, 2.0)
    went_fullscreen = any(line.startswith("dagon: display fullscreen") for line in seen) or any(
        line.startswith("dagon: display fullscreen") for _, line in game.seen
    )
    notes.append(f"first launch, fullscreen saved: {'fullscreen' if went_fullscreen else 'NOT fullscreen'}")
    notes.append(shoot("01-opened-fullscreen"))
    if not went_fullscreen:
        raise RouteFailed("with fullscreen saved, the game did not open fullscreen")
    # Settings; Music has focus, and nine presses down reach Display.
    game.tap("menu_down")
    game.tap("enter")
    game.wait_for("dagon: key labels: ", 5)
    time.sleep(0.3)
    for _ in range(9):
        game.tap("menu_down")
    game.tap("enter")
    game.wait_for("dagon: display windowed", 5)
    line = game.wait_for("dagon: window check mode=", 5)
    notes.append(f"Display pressed in Settings: {line}")
    time.sleep(1.0)
    notes.append(shoot("02-switched-to-a-window"))
    # Back to the main menu, where focus returns to Settings: three down to Quit to Desktop.
    game.tap("escape")
    time.sleep(0.5)
    for _ in range(3):
        game.tap("menu_down")
    game.tap("enter")
    try:
        code = game.process.wait(timeout=20)
    except subprocess.TimeoutExpired as error:
        raise RouteFailed("Quit to Desktop did not end the game") from error
    notes.append(f"quit to the desktop: exit {code}")
    if code != 0:
        raise RouteFailed(f"Quit to Desktop exited with {code}")


def second_launch(game, shoot, notes, storage):
    game.wait_for("dagon: save status=")
    seen = lines_for(game, 2.0) + [line for _, line in game.seen]
    fullscreen = [line for line in seen if line.startswith("dagon: display fullscreen")]
    checks = [line for line in seen if line.startswith("dagon: window check mode=")]
    saved = Path(storage, "settings.cfg").read_text(encoding="utf-8")
    notes.append(f"second launch: {checks[0] if checks else 'no window check'}; settings file fullscreen={'1' if 'fullscreen=1' in saved else '0'}")
    notes.append(shoot("03-relaunched-in-a-window"))
    if fullscreen:
        raise RouteFailed("after switching to a window, the relaunched game opened fullscreen")
    if not checks or not checks[0].startswith(f"dagon: window check mode={WINDOWED} "):
        raise RouteFailed(f"the relaunched game is not in a window: {checks[:1]}")
    if "fullscreen=0" not in saved:
        raise RouteFailed("the settings file does not say windowed")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("binary", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--display", help="Linux: the private X display to run on. Never a real desktop.")
    parser.add_argument("--windows-ci", action="store_true", help="Windows: only on a throwaway CI runner.")
    args = parser.parse_args()
    args.binary = args.binary.resolve()
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out.resolve()

    if sys.platform == "win32":
        if not args.windows_ci or os.environ.get("CI") != "true":
            sys.exit("display_relaunch_check: this posts keys to a window. On Windows it runs only with --windows-ci, on a CI runner.")
        keys = WindowsKeys()

        def shoot(name):
            try:
                from PIL import ImageGrab
            except ImportError:
                return "no screenshot: Pillow is not installed"
            ImageGrab.grab().save(out / f"display-{name}.png")
            return f"screenshot display-{name}.png"
    else:
        if not args.display:
            sys.exit("display_relaunch_check: name the private X display with --display. It never uses the desktop's.")
        keys = LinuxKeys(args.display)

        def shoot(name):
            subprocess.run(["import", "-display", args.display, "-window", "root", str(out / f"display-{name}.png")], check=False)
            return f"screenshot display-{name}.png"

    storage = tempfile.mkdtemp(prefix="dagon-display-")
    Path(storage, "settings.cfg").write_text(SETTINGS, encoding="utf-8")
    env = dict(os.environ, DAGON_STORAGE_DIR=storage.replace("\\", "/"), XDG_DATA_HOME=storage, APPDATA=storage, LOCALAPPDATA=storage)
    if args.display:
        env["DISPLAY"] = args.display
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DAGON_AUTOSTART", None)

    notes = []
    failures = []
    try:
        for name, run in (("first", first_launch), ("second", second_launch)):
            with open(out / f"display-{name}-route.log", "w", encoding="utf-8") as transcript:
                game = Game(args.binary, keys, env, transcript, None, out / f"display-{name}-game.log")
                try:
                    if run is second_launch:
                        run(game, shoot, notes, storage)
                    else:
                        run(game, shoot, notes)
                    if game.errors:
                        failures.append(f"{name} launch: the game logged errors: {game.errors[:3]}")
                except RouteFailed as error:
                    failures.append(f"{name} launch: {error}")
                finally:
                    game.close()
            if failures:
                break
    finally:
        shutil.rmtree(storage, ignore_errors=True)
    for note in notes:
        print(f"DISPLAY {note}")
    for failure in failures:
        print(f"DISPLAY FAILED: {failure}")
    print(f"DISPLAY_RESULT failed={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
