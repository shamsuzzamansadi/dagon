#!/usr/bin/env python3
"""Frame times by part of the game, from logs of a run with DAGON_FRAME_LOG set (M6 plan, item 8).

  frame_report.py <game log> [<game log> ...]

Each log is one run of the game, such as route_check.py's game-*.log files or a player's godot.log. The game prints,
once a second, the frames in it and the longest ("dagon: frames"), and each frame over the threshold on its own line
("dagon: long frame"). This sorts them into the part of the game they came in, by the lines the game logs as it goes,
and prints one table per run: seconds, frames a second (lowest, median), the longest frame, and the frames that
missed a 30 Hz refresh. Then every long frame, with the last thing the game said before it.
"""

import re
import statistics
import sys
from pathlib import Path

# The game's own lines that start each part, in the order they come; a run may start at any of them (Continue).
PARTS = [
    ("dagon: save status=", "menu"),
    ("dagon: introduction shown", "how to play"),
    ("dagon: prologue shown", "prologue"),
    ("dagon: prologue finished", "shore"),
    ("dagon: beat=abyss", "abyss"),
    ("dagon: beat=monolith", "monolith"),
    ("dagon: beat=awakened", "awakening"),
    ("dagon: beat=witness", "reveal"),
    ("dagon: beat=fleeing", "flight"),
    ("dagon: beat=ended", "collapse"),
    ("dagon: ending card shown", "ending"),
]
SECOND = re.compile(r"dagon: frames second=(\d+) count=(\d+) worst_ms=([\d.]+) over_33ms=(\d+)")
LONG = re.compile(r"dagon: long frame ms=([\d.]+) frame=(\d+)(.*)")


def read(path):
    part = "start"
    order = ["start"]
    seconds = {}
    long_frames = []
    said = ""
    for raw in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        for marker, name in PARTS:
            if line.startswith(marker):
                part = name
                if name not in order:
                    order.append(name)
        second = SECOND.match(line)
        if second:
            seconds.setdefault(part, []).append((int(second[2]), float(second[3]), int(second[4])))
            continue
        long_frame = LONG.match(line)
        if long_frame:
            long_frames.append((part, float(long_frame[1]), int(long_frame[2]), long_frame[3].strip(), said))
            continue
        if line.startswith("dagon:"):
            said = line[:100]
    return order, seconds, long_frames


def report(path):
    order, seconds, long_frames = read(path)
    print(f"## {Path(path).name}\n")
    print("| Part | Seconds | Frames a second, lowest / median | Longest frame, ms | Frames over 33 ms |")
    print("|---|---|---|---|---|")
    total = []
    for part in order:
        rows = seconds.get(part, [])
        if not rows:
            continue
        total += rows
        counts = [count for count, _, _ in rows]
        print(f"| {part} | {len(rows)} | {min(counts)} / {statistics.median(counts):.0f} | {max(w for _, w, _ in rows):.1f} | {sum(o for _, _, o in rows)} |")
    if total:
        counts = [count for count, _, _ in total]
        print(f"| **whole run** | {len(total)} | {min(counts)} / {statistics.median(counts):.0f} | {max(w for _, w, _ in total):.1f} | {sum(o for _, _, o in total)} |")
    print()
    if long_frames:
        print("Long frames:\n")
        for part, ms, frame, extra, said in long_frames:
            print(f"- {ms:.1f} ms, frame {frame}, in {part}" + (f" ({extra})" if extra else "") + f"; the game had last said: `{said}`")
    else:
        print("No long frames.")
    print()


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for path in sys.argv[1:]:
        report(path)


if __name__ == "__main__":
    main()
