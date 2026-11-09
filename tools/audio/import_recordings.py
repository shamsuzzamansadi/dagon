#!/usr/bin/env python3
"""The recording route for narration: a person reads the lines, and this brings their recordings into the game.

    python tools/audio/import_recordings.py --sheet > lines.txt      every line, by ID, to read from
    python tools/audio/import_recordings.py FOLDER [--only ID ...]    FOLDER holds <line id>.wav (or .flac, .ogg)

Each recording is trimmed to a short tail of silence, set to the same level as the other narration (-24 dB RMS,
nothing over -1 dBFS), and written as project/assets/narration/<line id>.ogg, where the game plays it under that
line's caption. An ID that is not in project/narration/script.txt is refused, so a recording cannot drift from its
caption. Needs numpy and soundfile.

Record somewhere quiet, close to the microphone, at 44.1 or 48 kHz. Read each line as written; if a word must change,
change it in the script first, so the caption changes with it. The reader's permission, and how they wish to be
credited, go in CREDITS.md before anything is shipped.
"""

import argparse
import math
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "project" / "narration" / "script.txt"
OUT = ROOT / "project" / "assets" / "narration"
TARGET_RMS_DB = -24.0


def read_script():
    lines = {}
    for line in SCRIPT.read_text().splitlines():
        if line and not line.startswith("#"):
            line_id, kind, text = line.split("|", 2)
            lines[line_id] = (kind, text)
    return lines


def prepare(audio, rate):
    audio = np.asarray(audio, dtype=np.float64)
    if audio.ndim > 1:
        audio = audio.mean(axis=1)
    gate = 10 ** (-45 / 20) * np.max(np.abs(audio))
    loud = np.nonzero(np.abs(audio) > gate)[0]
    if len(loud):
        audio = audio[max(0, loud[0] - int(0.08 * rate)) : min(len(audio), loud[-1] + int(0.25 * rate))]
    rms = math.sqrt(float(np.mean(audio**2))) + 1e-12
    audio = audio * (10 ** (TARGET_RMS_DB / 20) / rms)
    peak = float(np.max(np.abs(audio)))
    if peak > 10 ** (-1 / 20):
        audio = audio * (10 ** (-1 / 20) / peak)
    fade = int(0.01 * rate)
    audio[:fade] *= np.linspace(0, 1, fade)
    audio[-fade:] *= np.linspace(1, 0, fade)
    return audio


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", nargs="?", type=Path)
    parser.add_argument("--sheet", action="store_true")
    parser.add_argument("--only", nargs="*", default=[])
    args = parser.parse_args()
    lines = read_script()
    if args.sheet:
        for line_id, (kind, text) in lines.items():
            print(f"{line_id}  [{kind}]\n    {text}\n")
        return 0
    if args.folder is None:
        parser.error("give a folder of recordings, or --sheet")
    problems = 0
    for path in sorted(args.folder.iterdir()):
        if path.suffix.lower() not in (".wav", ".flac", ".ogg"):
            continue
        line_id = path.stem
        if args.only and line_id not in args.only:
            continue
        if line_id not in lines:
            print(f"REFUSED {path.name}: no line {line_id} in the script")
            problems += 1
            continue
        audio, rate = sf.read(path)
        prepared = prepare(audio, rate)
        OUT.mkdir(parents=True, exist_ok=True)
        sf.write(OUT / f"{line_id}.ogg", prepared, rate, format="OGG", subtype="VORBIS")
        seconds = len(prepared) / rate
        print(f"{line_id}: {seconds:.2f} s, {len(lines[line_id][1]) / seconds:.1f} characters a second")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
