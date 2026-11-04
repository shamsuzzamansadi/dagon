#!/usr/bin/env python3
"""Plays the real exported game from New Game to the ending, with real window-system key events. Standard library only.

The build is run exactly as shipped, with its own window and nothing added to it. Keys reach it through the operating
system: XTEST on Linux and window messages on Windows. What the driver knows comes from what the build prints under
--verbose, which is what a player sees: the prompt, the caption, the beat and the menus.

  route_check.py <exported binary> <log dir> --display :99      Linux: on this X display. Never give it a real desktop.
  route_check.py <exported binary> <log dir> --windows-ci       Windows: only on a throwaway CI runner.

It plays four runs, each a new process on the same isolated storage:
  1. New Game to the ending, stopping to read everything that offers a prompt along the ground, and letting the epilogue finish.
  2. New Game to the ending again, reading nothing, as the shortest honest route.
  3. Continue from the Awakened save to the ending, by standing still until the flee times out.
  4. Continue from the same save, to show it is still there after the ending.

Runs 1 and 2 report how long each act took. These are scripted, by a driver that knows the puzzle. They are not playtests,
and say nothing about how long a person will take.
"""
import argparse
import os
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

PHASE_SECONDS = 240.0
HOP_HOLD_SECONDS = 0.2
HOP_EVERY_SECONDS = 0.7
FLEE_TIMEOUT_SECONDS = 12.0
# Wall clock over a real window, so generous on the slow side only.
FLEE_MAX_SECONDS = 16.0

# Linux: a keysym name for xdotool. Windows: virtual key, scan code.
KEYS = {
    "enter": ("Return", 0x0D, 0x1C),
    "space": ("space", 0x20, 0x39),
    "left": ("a", 0x41, 0x1E),
    "right": ("d", 0x44, 0x20),
    "examine": ("e", 0x45, 0x12),
    "menu_down": ("Down", 0x28, 0x50),
    "menu_up": ("Up", 0x26, 0x48),
    "menu_right": ("Right", 0x27, 0x4D),
}
EXTENDED_KEYS = ("menu_down", "menu_up", "menu_right")


class RouteFailed(Exception):
    pass


class LinuxKeys:
    def __init__(self, display):
        self.env = dict(os.environ, DISPLAY=display)

    def attach(self, process):
        pass

    def press(self, key):
        subprocess.run(["xdotool", "keydown", KEYS[key][0]], env=self.env, check=True)

    def release(self, key):
        subprocess.run(["xdotool", "keyup", KEYS[key][0]], env=self.env, check=True)


class WindowsKeys:
    """Window messages to the game's window, which is what M2's scripted Windows runs used. Nothing else receives them."""

    WM_KEYDOWN = 0x0100
    WM_KEYUP = 0x0101

    def __init__(self):
        import ctypes
        from ctypes import wintypes

        self.ctypes = ctypes
        self.user32 = ctypes.WinDLL("user32", use_last_error=True)
        self.user32.PostMessageW.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]
        self.wintypes = wintypes
        self.window = None

    def attach(self, process):
        ctypes = self.ctypes
        found = []
        callback_type = ctypes.WINFUNCTYPE(ctypes.c_bool, self.wintypes.HWND, self.wintypes.LPARAM)

        def visit(window, _):
            owner = self.wintypes.DWORD()
            self.user32.GetWindowThreadProcessId(window, ctypes.byref(owner))
            if owner.value == process.pid and self.user32.IsWindowVisible(window):
                found.append(window)
                return False
            return True

        for _ in range(300):
            self.user32.EnumWindows(callback_type(visit), 0)
            if found:
                self.window = found[0]
                return
            time.sleep(0.1)
        raise RouteFailed("the game opened no window")

    def _post(self, message, key, up):
        _, virtual_key, scan_code = KEYS[key]
        extended = 1 << 24 if key in EXTENDED_KEYS else 0
        lparam = 1 | (scan_code << 16) | extended | ((3 << 30) if up else 0)
        if not self.user32.PostMessageW(self.window, message, virtual_key, lparam):
            raise RouteFailed("a key message could not be posted")

    def press(self, key):
        self._post(self.WM_KEYDOWN, key, False)

    def release(self, key):
        self._post(self.WM_KEYUP, key, True)


class Game:
    """One run of the exported game, with its output read line by line."""

    def __init__(self, binary, keys, env, transcript, shots, log_path):
        self.keys = keys
        self.transcript = transcript
        self.shots = shots
        self.log_path = log_path
        self.lines = queue.Queue()
        self.started = time.monotonic()
        log_path.unlink(missing_ok=True)
        # The log file, because a Windows GUI build has no stdout to read. The project flushes it on every line.
        # The dummy audio driver, because a CI runner has no sound card, and the build has no audio yet.
        self.process = subprocess.Popen(
            [str(binary), "--verbose", "--audio-driver", "Dummy", "--log-file", str(log_path)], cwd=Path(binary).parent, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        threading.Thread(target=self._read, daemon=True).start()
        keys.attach(self.process)
        self.errors = []
        self.held = set()
        self.seen = []
        self.reading_seconds = 0.0
        self.read_lines = set()

    def _read(self):
        while not self.log_path.exists():
            if self.process.poll() is not None:
                self.lines.put(None)
                return
            time.sleep(0.02)
        with open(self.log_path, encoding="utf-8", errors="replace") as log:
            partial = ""
            while True:
                exited = self.process.poll() is not None
                chunk = log.read()
                if chunk:
                    partial += chunk
                    *complete, partial = partial.split("\n")
                    arrived = time.monotonic()
                    for line in complete:
                        self.lines.put((arrived, line.rstrip("\r")))
                elif exited:
                    self.lines.put(None)
                    return
                else:
                    time.sleep(0.01)

    def _note(self, arrived, text):
        self.transcript.write(f"{arrived - self.started:8.2f}  {text}\n")
        self.transcript.flush()

    def _next_line(self, deadline):
        try:
            entry = self.lines.get(timeout=max(deadline - time.monotonic(), 0.01))
        except queue.Empty:
            return ""
        if entry is None:
            raise RouteFailed(f"the game exited with {self.process.wait()} before the route finished")
        arrived, line = entry
        if line.startswith(("ERROR", "SCRIPT ERROR", "USER ERROR")):
            self.errors.append(line)
            self._note(arrived, f"!! {line}")
        elif line.startswith("dagon:"):
            self._note(arrived, line)
            self.seen.append((arrived, line))
        return line

    def wait_for(self, text, seconds=PHASE_SECONDS, unless=None):
        """Returns when a line contains the text, or fails. With unless, a line containing that fails at once."""
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            line = self._next_line(deadline)
            if unless and unless in line:
                raise RouteFailed(f"saw '{line}' while waiting for '{text}'")
            if text in line:
                return line
        raise RouteFailed(f"no '{text}' within {seconds:.0f} s")

    def walk_until(self, direction, text, seconds=PHASE_SECONDS, hop=True, unless=None, read=False):
        """Holds a direction until a line contains the text. Hopping as it goes crosses every obstacle in the level.
        With read, it stops at each thing that offers to be examined, once, and reads it to the end."""
        self.press(direction)
        deadline = time.monotonic() + seconds
        next_hop = time.monotonic() + HOP_EVERY_SECONDS
        hop_ends = 0.0
        try:
            while time.monotonic() < deadline:
                now = time.monotonic()
                if hop and not hop_ends and now >= next_hop:
                    self.press("space")
                    hop_ends = now + HOP_HOLD_SECONDS
                if hop_ends and now >= hop_ends:
                    self.release("space")
                    hop_ends = 0.0
                    next_hop = now + HOP_EVERY_SECONDS
                line = self._next_line(min(deadline, time.monotonic() + 0.03))
                if unless and unless in line:
                    raise RouteFailed(f"saw '{line}' while walking to '{text}'")
                if text in line:
                    return line
                if read and "dagon: focus: " in line and line.split("dagon: focus: ")[1].strip() not in self.read_lines:
                    if hop_ends:
                        self.release("space")
                        hop_ends = 0.0
                    self.release(direction)
                    deadline += self.read_what_is_offered()
                    self.press(direction)
                    next_hop = time.monotonic() + HOP_EVERY_SECONDS
            raise RouteFailed(f"walking {direction}: no '{text}' within {seconds:.0f} s")
        finally:
            if "space" in self.held:
                self.release("space")
            self.release(direction)

    def read_what_is_offered(self):
        """Examines what the prompt offers, and waits until its caption has run. Returns how long that took."""
        started = time.monotonic()
        time.sleep(0.25)
        self.tap("examine")
        seconds = self._wait_for_line_length()
        if seconds is None:
            # A story moment being said takes the first press, which cuts it short. The second examines.
            self.tap("examine")
            seconds = self._wait_for_line_length()
        if seconds is not None:
            time.sleep(seconds)
        took = time.monotonic() - started
        self.reading_seconds += took
        return took

    def _wait_for_line_length(self):
        deadline = time.monotonic() + 1.0
        while time.monotonic() < deadline:
            line = self._next_line(deadline)
            if "dagon: line: " in line and " seconds=" in line:
                self.read_lines.add(line.split("dagon: line: ")[1].split(" ")[0])
                return float(line.rsplit("seconds=", 1)[1])
        return None

    def press(self, key):
        self.keys.press(key)
        self.held.add(key)

    def release(self, key):
        self.keys.release(key)
        self.held.discard(key)

    def tap(self, key):
        self.press(key)
        time.sleep(0.12)
        self.release(key)
        time.sleep(0.12)

    def shot(self, name):
        if self.shots is not None:
            subprocess.run(["import", "-display", self.keys.env["DISPLAY"], "-window", "root", str(self.shots / f"{name}.png")], check=False)

    def quit_from_main_menu(self):
        """Focus starts on Continue when there is a save: four down to Quit to Desktop."""
        time.sleep(0.5)
        for _ in range(4):
            self.tap("menu_down")
        self.tap("enter")
        try:
            code = self.process.wait(timeout=20)
        except subprocess.TimeoutExpired as error:
            raise RouteFailed("Quit to Desktop did not end the game") from error
        if code != 0:
            raise RouteFailed(f"Quit to Desktop exited with {code}")
        self._note(time.monotonic(), f"exit {code}")

    def close(self):
        for key in list(self.held):
            self.keys.release(key)
        if self.process.poll() is None:
            self.process.kill()
            self.process.wait()


def press_at_stone(game, text, expected):
    game.tap("examine")
    game.wait_for(expected, 5, unless="beat=ended")
    time.sleep(0.5)
    game.shot(text)


def first_time(game, text, after=0.0):
    for arrived, line in game.seen:
        if arrived >= after and text in line:
            return arrived
    raise RouteFailed(f"the timing has no '{text}'")


def report_timing(game, profile, begun):
    """How the run's time was spent, from when each line arrived. Scripted, knowing the puzzle: not a playtest."""
    abyss = first_time(game, "dagon: beat=abyss")
    monolith = first_time(game, "dagon: beat=monolith")
    witness = first_time(game, "dagon: beat=witness")
    ended = first_time(game, "dagon: beat=ended")
    card = first_time(game, "dagon: ending card shown")
    menu = first_time(game, "dagon: save status=", card)
    stones = first_time(game, "Press the kneeling stone", monolith)
    solved = first_time(game, "dagon: puzzle solved")
    cinematics = 0.0
    start = None
    for arrived, line in game.seen:
        if "dagon: cinematic start" in line:
            start = arrived
        elif "dagon: cinematic finalized" in line and start is not None:
            cinematics += arrived - start
            start = None
    solving = solved - stones
    exploring = (ended - begun) - cinematics - solving - game.reading_seconds
    text = (
        f"ROUTE_TIMING profile={profile} puzzle=known-to-the-script one-deliberate-mistake total={menu - begun:.0f}s to-ending-card={card - begun:.0f}s"
        f" | acts: shore={abyss - begun:.0f}s abyss={monolith - abyss:.0f}s monolith={witness - monolith:.0f}s witness-and-escape={ended - witness:.0f}s collapse={card - ended:.0f}s epilogue-and-credits={menu - card:.0f}s"
        f" | spent: walking={exploring:.0f}s reading={game.reading_seconds:.0f}s solving={solving:.0f}s cinematics={cinematics:.0f}s"
    )
    print(text)
    game.transcript.write(text + "\n")


def run_new_game_to_the_ending(game, read):
    profile = "reading" if read else "direct"
    name = lambda shot: f"{shot}" if read else f"direct-{shot}"
    line = game.wait_for("dagon: save status=")
    time.sleep(0.5)
    game.shot(name("01-main-menu"))
    # With a save, Continue has focus, and New Game asks first with Cancel highlighted.
    if "status=0" in line:
        game.tap("menu_up")
        game.tap("enter")
        time.sleep(0.3)
        game.tap("menu_right")
    game.tap("enter")
    game.wait_for("dagon: introduction shown")
    time.sleep(0.5)
    game.shot(name("02-introduction"))
    game.tap("enter")
    begun = time.monotonic()

    game.wait_for("dagon: prompt: [E] Examine")
    time.sleep(0.3)
    if read:
        game.read_what_is_offered()
    else:
        game.tap("examine")
        game.wait_for("dagon: caption: The lifeboat")
    time.sleep(0.2)
    game.shot(name("03-boat-caption"))

    game.walk_until("right", "dagon: beat=abyss", read=read)
    game.wait_for("Checkpoint saved", 5)
    game.shot(name("04-abyss"))
    game.walk_until("right", "dagon: background event: ritual_tableau", read=read)
    time.sleep(3.6)
    game.shot(name("05-ritual"))
    game.walk_until("right", "dagon: beat=monolith", read=read)
    game.wait_for("Checkpoint saved", 5)
    game.shot(name("06-monolith"))

    # The kneeling stone is the first one reached, and it is the wrong one to press first.
    game.walk_until("right", "Press the kneeling stone", hop=False, read=read)
    time.sleep(0.2)
    press_at_stone(game, name("07-wrong-stone"), "dagon: puzzle rejected")
    # The lockout passes on the way to the wave stone.
    game.walk_until("right", "Press the wave stone", hop=False)
    time.sleep(0.2)
    press_at_stone(game, name("08-first-stone"), "dagon: puzzle accepted step=0")
    game.walk_until("left", "Press the kneeling stone", hop=False)
    time.sleep(0.2)
    press_at_stone(game, name("09-second-stone"), "dagon: puzzle accepted step=1")
    game.walk_until("right", "Press the eye stone", hop=False)
    time.sleep(0.2)
    game.tap("examine")
    game.wait_for("dagon: puzzle solved", 5)
    game.wait_for("dagon: beat=awakened", 5)
    time.sleep(2.0)
    game.shot(name("10-awakening"))
    game.wait_for("dagon: cinematic finalized clip=monolith_awaken", 20)
    game.wait_for("Checkpoint saved", 5)
    time.sleep(0.3)
    game.shot(name("11-gate-open"))

    game.walk_until("right", "dagon: beat=witness", hop=False)
    time.sleep(10.0)
    game.shot(name("12-reveal"))
    game.wait_for("dagon: cinematic finalized clip=dagon_reveal", 20)
    game.wait_for("dagon: beat=fleeing", 5)
    time.sleep(0.5)
    game.shot(name("13-fleeing"))
    game.walk_until("left", "dagon: beat=ended", 20, hop=False)
    time.sleep(1.5)
    game.shot(name("14-collapse"))
    game.wait_for("dagon: ending card shown", 20)
    time.sleep(0.5)
    game.shot(name("15-epilogue-first-line"))
    if read:
        # All of it, at the pace it sets itself.
        game.wait_for("dagon: ending line: ending.rising", 90)
        time.sleep(6.0)
        game.shot(name("16-epilogue-whole"))
    else:
        for _ in range(3):
            time.sleep(0.4)
            game.tap("enter")
    time.sleep(0.5)
    game.tap("enter")
    time.sleep(0.5)
    game.shot(name("17-credits"))
    game.tap("enter")
    game.wait_for("dagon: save status=", 20)
    time.sleep(0.5)
    game.shot(name("18-main-menu-after-the-ending"))
    report_timing(game, profile, begun)
    game.quit_from_main_menu()


def run_new_game_reading(game):
    run_new_game_to_the_ending(game, True)


def run_new_game_direct(game):
    run_new_game_to_the_ending(game, False)


def run_continue_and_wait_out_the_flee(game):
    game.wait_for("dagon: save status=")
    time.sleep(0.5)
    game.tap("enter")
    game.wait_for("dagon: session start beat=3 persisted=3")
    game.walk_until("right", "dagon: beat=witness", hop=False)
    game.wait_for("dagon: beat=fleeing", 30)
    started = time.monotonic()
    # No input at all from here.
    game.wait_for("dagon: beat=ended", FLEE_MAX_SECONDS)
    took = time.monotonic() - started
    game._note(time.monotonic(), f"the flee timed out after {took:.2f} s of wall clock")
    if took < FLEE_TIMEOUT_SECONDS - 1.0:
        raise RouteFailed(f"the flee timed out after only {took:.2f} s")
    game.wait_for("dagon: ending card shown", 20)
    for _ in range(3):
        time.sleep(0.4)
        game.tap("enter")
    time.sleep(0.5)
    game.tap("enter")
    time.sleep(0.5)
    game.tap("enter")
    game.wait_for("dagon: save status=", 20)
    game.quit_from_main_menu()


def run_continue_after_the_ending(game):
    game.wait_for("dagon: save status=")
    time.sleep(0.5)
    game.tap("enter")
    game.wait_for("dagon: session start beat=3 persisted=3")
    time.sleep(1.0)
    game.shot("19-continue-after-the-ending")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("binary", type=Path)
    parser.add_argument("logs", type=Path)
    parser.add_argument("--display", help="Linux: the X display to run on. Never a real desktop.")
    parser.add_argument("--windows-ci", action="store_true", help="Windows: run on this machine's desktop. Only for a throwaway CI runner.")
    parser.add_argument("--shots", type=Path, help="Linux: also save screenshots here, with ImageMagick's import.")
    args = parser.parse_args()
    args.binary = args.binary.resolve()

    if sys.platform == "win32":
        if not args.windows_ci or os.environ.get("CI") != "true":
            sys.exit("route_check: this posts keys to a real window. It runs on Windows only with --windows-ci, on a CI runner.")
        keys = WindowsKeys()
    else:
        if not args.display:
            sys.exit("route_check: name the private X display with --display. It never uses the desktop's.")
        if shutil.which("xdotool") is None:
            sys.exit("route_check: xdotool is not installed.")
        keys = LinuxKeys(args.display)

    args.logs.mkdir(parents=True, exist_ok=True)
    if args.shots:
        args.shots.mkdir(parents=True, exist_ok=True)
    storage = tempfile.mkdtemp(prefix="dagon-test-")
    env = dict(os.environ, DAGON_STORAGE_DIR=storage.replace("\\", "/"), XDG_DATA_HOME=storage, APPDATA=storage, LOCALAPPDATA=storage)
    if args.display:
        env["DISPLAY"] = args.display
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DAGON_AUTOSTART", None)

    runs = [
        ("new-game-reading-everything", run_new_game_reading),
        ("new-game-direct", run_new_game_direct),
        ("continue-and-wait-out-the-flee", run_continue_and_wait_out_the_flee),
        ("continue-after-the-ending", run_continue_after_the_ending),
    ]
    failures = 0
    try:
        for name, run in runs:
            with open(args.logs / f"route-{name}.log", "w", encoding="utf-8") as transcript:
                game = Game(args.binary, keys, env, transcript, args.shots, args.logs.resolve() / f"game-{name}.log")
                try:
                    run(game)
                    if game.errors:
                        raise RouteFailed(f"the game logged errors: {game.errors[:3]}")
                    print(f"ROUTE {name}: ok")
                except RouteFailed as error:
                    failures += 1
                    transcript.write(f"FAILED: {error}\n")
                    print(f"ROUTE {name}: FAILED: {error}")
                finally:
                    game.close()
            if failures:
                break
        for file_name in ("save.dat", "save.bak"):
            path = Path(storage) / file_name
            print(f"ROUTE {file_name}: " + (path.read_text().replace(chr(10), " ") if path.exists() else "absent"))
    finally:
        shutil.rmtree(storage, ignore_errors=True)
    print(f"ROUTE_RESULT runs={len(runs)} failed={failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
