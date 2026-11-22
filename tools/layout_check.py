#!/usr/bin/env python3
"""Key names under a keyboard layout, on the exported build (M6 plan, item 5).

Starts the shipped game with the four game keys moved onto keys whose letters differ between layouts: Left on the key
a US keyboard calls Z, Jump on its semicolon key, Examine on its Y, Right left on D. Puts the game under the layout
asked for, then opens Settings, the main menu's Controls, How to Play, the first prompt, and the pause menu's Settings
and Controls, saving a screenshot of each. The game logs the key names it shows in Settings and in the prompt, with
the layout it read them through; the check compares them with what that layout prints on those keys.

  layout_check.py <exported binary> <out dir> --layout de --display :77   Linux: a private X display only. Its layout
                                                                         is set with setxkbmap.
  layout_check.py <exported binary> <out dir> --layout de --windows-ci   Windows: only on a throwaway CI runner. The
                                                                         game's window is asked to switch to the
                                                                         layout, and the switch is read back.
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

# Godot's physical key codes: what a US keyboard prints on each key.
KEY_Z, KEY_D, KEY_SEMICOLON, KEY_Y = 90, 68, 59, 89

# The settings file the game reads: version 1, its defaults, and the four keys in Settings' order.
SETTINGS = (
    "dagon_settings=1\nmusic_volume=1\neffects_volume=1\nnarration_volume=1\nsubtitles=1\nvibration=1\nfullscreen=0\n"
    f"key_move_left={KEY_Z}\nkey_move_right={KEY_D}\nkey_jump={KEY_SEMICOLON}\nkey_interact={KEY_Y}\n"
)

# What each layout prints on those keys, in Settings' order: Left, Right, Jump, Examine.
EXPECTED = {
    "us": ["Z", "D", "Semicolon", "Y"],
    "de": ["Y", "D", "Ö", "Z"],
}
# Windows layout identifiers, for LoadKeyboardLayout, and the language each one reports.
WINDOWS_LAYOUTS = {"us": ("00000409", 0x0409), "de": ("00000407", 0x0407)}


class WindowsLayout:
    """Asks the game's window to change its input language, the way the language bar does, and reads it back."""

    WM_INPUTLANGCHANGEREQUEST = 0x0050
    KLF_ACTIVATE = 0x00000001

    def __init__(self, keys):
        import ctypes
        from ctypes import wintypes

        self.keys = keys
        self.user32 = ctypes.WinDLL("user32", use_last_error=True)
        self.user32.LoadKeyboardLayoutW.restype = wintypes.HKL
        self.user32.LoadKeyboardLayoutW.argtypes = [wintypes.LPCWSTR, wintypes.UINT]
        self.user32.GetKeyboardLayout.restype = wintypes.HKL
        self.user32.GetKeyboardLayout.argtypes = [wintypes.DWORD]
        self.user32.GetWindowThreadProcessId.restype = wintypes.DWORD
        self.user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
        self.user32.PostMessageW.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]

    def current(self):
        thread = self.user32.GetWindowThreadProcessId(self.keys.window, None)
        layout = self.user32.GetKeyboardLayout(thread) or 0
        return layout & 0xFFFF, layout

    def switch(self, name):
        identifier, language = WINDOWS_LAYOUTS[name]
        before = self.current()
        layout = self.user32.LoadKeyboardLayoutW(identifier, self.KLF_ACTIVATE)
        if not layout:
            raise RouteFailed(f"Windows could not load the layout {identifier}")
        if not self.user32.PostMessageW(self.keys.window, self.WM_INPUTLANGCHANGEREQUEST, 0, layout):
            raise RouteFailed("the layout request could not be posted")
        for _ in range(50):
            time.sleep(0.1)
            if self.current()[0] == language:
                break
        after = self.current()
        note = f"layout: the game's thread was {before[0]:#06x} ({before[1]:#x}), is {after[0]:#06x} ({after[1]:#x})"
        if after[0] != language:
            raise RouteFailed(note + f", not {language:#06x}")
        return note


def windows_shot(path):
    try:
        from PIL import ImageGrab
    except ImportError:
        return "no screenshot: Pillow is not installed"
    ImageGrab.grab().save(path)
    return f"screenshot {path.name}"


def run(game, layout_name, switch, shoot, notes):
    expected = EXPECTED[layout_name]
    found = {}

    def note(text):
        notes.append(text)
        print(f"LAYOUT {text}", flush=True)

    def labels_after(seconds=10):
        line = game.wait_for("dagon: key labels: ", seconds)
        shown = line.split("dagon: key labels: ", 1)[1]
        names, _, layout = shown.partition(" layout=")
        return names.split(" "), layout

    game.wait_for("dagon: save status=")
    time.sleep(1.0)
    if switch is not None:
        note(switch())

    # The main menu, with no save: New Game has focus, and Continue is passed over.
    game.tap("menu_down")
    game.tap("enter")
    names, layout = labels_after()
    note(f"Settings, main menu: {' '.join(names)} (layout {layout})")
    found["settings"] = names
    time.sleep(0.5)
    note(shoot("01-settings"))
    game.tap("escape")
    time.sleep(0.5)
    game.tap("menu_down")
    game.tap("enter")
    time.sleep(0.8)
    note(shoot("02-controls-main-menu"))
    game.tap("escape")
    time.sleep(0.5)
    game.tap("menu_up")
    game.tap("menu_up")
    game.tap("enter")

    game.wait_for("dagon: introduction shown")
    time.sleep(0.8)
    note(shoot("03-how-to-play"))
    game.tap("enter")
    game.wait_for("dagon: prologue shown")
    time.sleep(0.5)
    game.tap("escape")
    game.wait_for("dagon: prologue finished skipped=true", 10)
    game.wait_for("dagon: cinematic finalized clip=shore_wake", 15)
    line = game.wait_for("dagon: prompt: [", 20)
    prompt = line.split("dagon: prompt: ", 1)[1]
    note(f"the first prompt: {prompt}")
    found["prompt"] = prompt[1 : prompt.index("]")]
    time.sleep(0.5)
    note(shoot("04-first-prompt"))

    # The pause menu: Resume, Restart from Checkpoint, Settings, Controls. Its Settings is a menu of its own.
    game.tap("escape")
    time.sleep(0.6)
    game.tap("menu_down")
    game.tap("menu_down")
    game.tap("enter")
    names, layout = labels_after()
    note(f"Settings, pause menu: {' '.join(names)} (layout {layout})")
    found["pause settings"] = names
    time.sleep(0.5)
    note(shoot("05-settings-pause-menu"))
    game.tap("escape")
    time.sleep(0.5)
    game.tap("menu_down")
    game.tap("enter")
    time.sleep(0.8)
    note(shoot("06-controls-pause-menu"))

    failures = []
    for where in ("settings", "pause settings"):
        if found[where] != expected:
            failures.append(f"{where} shows {found[where]}, {layout_name} prints {expected}")
    if found["prompt"] != expected[3]:
        failures.append(f"the prompt shows [{found['prompt']}], {layout_name} prints {expected[3]} on that key")
    return failures


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("binary", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--layout", choices=sorted(EXPECTED), required=True)
    parser.add_argument("--display", help="Linux: the private X display to run on. Never a real desktop.")
    parser.add_argument("--windows-ci", action="store_true", help="Windows: only on a throwaway CI runner.")
    args = parser.parse_args()
    args.binary = args.binary.resolve()
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out.resolve()

    env_extra = {}
    if sys.platform == "win32":
        if not args.windows_ci or os.environ.get("CI") != "true":
            sys.exit("layout_check: this changes a window's layout and posts keys to it. On Windows it runs only with --windows-ci, on a CI runner.")
        keys = WindowsKeys()
        layout = WindowsLayout(keys)
        switch = lambda: layout.switch(args.layout)
        shoot = lambda name: windows_shot(out / f"{args.layout}-{name}.png")
    else:
        if not args.display:
            sys.exit("layout_check: name the private X display with --display. It never uses the desktop's.")
        keys = LinuxKeys(args.display)
        subprocess.run(["setxkbmap", "-display", args.display, args.layout], check=True)
        query = subprocess.run(["setxkbmap", "-display", args.display, "-query"], capture_output=True, text=True, check=True).stdout
        env_extra["DISPLAY"] = args.display
        switch = lambda: "layout: the display's, " + " ".join(query.split())
        shoot = lambda name: (
            subprocess.run(["import", "-display", args.display, "-window", "root", str(out / f"{args.layout}-{name}.png")], check=False),
            f"screenshot {args.layout}-{name}.png",
        )[1]

    storage = tempfile.mkdtemp(prefix="dagon-layout-")
    Path(storage, "settings.cfg").write_text(SETTINGS, encoding="utf-8")
    env = dict(os.environ, DAGON_STORAGE_DIR=storage.replace("\\", "/"), XDG_DATA_HOME=storage, APPDATA=storage, LOCALAPPDATA=storage, **env_extra)
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DAGON_AUTOSTART", None)

    notes = []
    failures = []
    try:
        with open(out / f"{args.layout}-route.log", "w", encoding="utf-8") as transcript:
            game = Game(args.binary, keys, env, transcript, None, out / f"{args.layout}-game.log")
            try:
                failures = run(game, args.layout, switch, shoot, notes)
                if game.errors:
                    failures.append(f"the game logged errors: {game.errors[:3]}")
            except RouteFailed as error:
                failures.append(str(error))
            finally:
                game.close()
    finally:
        shutil.rmtree(storage, ignore_errors=True)
    for failure in failures:
        print(f"LAYOUT FAILED: {failure}")
    print(f"LAYOUT_RESULT layout={args.layout} failed={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
