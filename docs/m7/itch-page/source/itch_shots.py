#!/usr/bin/env python3
"""Frames for the itch.io page from the exported game as shipped, on a private X display only.

  itch_shots.py <route_check.py> <exported binary> <out dir> --display :77

Plays New Game the way route_check.py's direct run does, with its Game class and window-system keys, and saves a frame
of the whole display about every 0.4 s from the main menu to the ritual in the Abyss, then stops before the crossing,
whose sky holds a shape the reveal explains. Nothing past that is played or captured.
"""
import argparse
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path


def load_route_check(path):
    spec = importlib.util.spec_from_file_location("route_check", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("route_check", type=Path)
    parser.add_argument("binary", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--display", required=True)
    args = parser.parse_args()
    rc = load_route_check(args.route_check)
    frames = args.out / "frames"
    frames.mkdir(parents=True, exist_ok=False)
    storage = tempfile.mkdtemp(prefix="dagon-test-")
    env = dict(os.environ, DISPLAY=args.display, DAGON_STORAGE_DIR=storage, XDG_DATA_HOME=storage)
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DAGON_AUTOSTART", None)
    keys = rc.LinuxKeys(args.display)
    index = open(args.out / "frames.txt", "w", encoding="utf-8")
    stop = threading.Event()
    marker = {"text": "start"}

    def grab_loop(game):
        n = 0
        while not stop.is_set():
            n += 1
            name = f"{n:04d}.png"
            t = time.monotonic() - game.started
            subprocess.run(["import", "-display", args.display, "-window", "root", str(frames / name)], check=False)
            index.write(f"{name} {t:7.2f} {marker['text']}\n")
            index.flush()
            time.sleep(0.25)

    with open(args.out / "transcript.log", "w", encoding="utf-8") as transcript:
        game = rc.Game(args.binary.resolve(), keys, env, transcript, None, (args.out / "game.log").resolve())
        grabber = threading.Thread(target=grab_loop, args=(game,), daemon=True)
        try:
            line = game.wait_for("dagon: save status=")
            grabber.start()
            marker["text"] = "main-menu"
            time.sleep(1.5)
            if "status=0" in line:
                pass
            else:
                game.tap("menu_up")
                game.tap("enter")
                time.sleep(0.3)
                game.tap("menu_right")
            game.tap("enter")
            game.wait_for("dagon: introduction shown")
            marker["text"] = "introduction"
            time.sleep(1.0)
            game.tap("enter")
            game.wait_for("dagon: prologue shown")
            for line_id in ("prologue.raider", "prologue.escape", "prologue.drift", "prologue.dry"):
                marker["text"] = line_id
                game.wait_for(f"dagon: prologue line: {line_id}", 30)
            game.wait_for("dagon: prologue finished", 30)
            marker["text"] = "shore-wake"
            game.wait_for("dagon: cinematic finalized clip=shore_wake", 15)
            marker["text"] = "shore"
            time.sleep(1.0)
            game.walk_until("right", "dagon: beat=abyss")
            marker["text"] = "cave"
            game.walk_until("right", "dagon: background event: ritual_tableau")
            marker["text"] = "ritual"
            time.sleep(8.0)
            marker["text"] = "after-ritual"
            game.walk_until("right", "dagon: focus: abyss.tablet", seconds=20)
            marker["text"] = "tablet"
            time.sleep(1.5)
        finally:
            stop.set()
            time.sleep(0.6)
            game.close()
            index.close()
            shutil.rmtree(storage, ignore_errors=True)
    print(f"ITCH_SHOTS frames={len(list(frames.glob('*.png')))} errors={len(game.errors)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
