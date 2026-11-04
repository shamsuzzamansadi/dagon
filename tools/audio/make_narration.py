#!/usr/bin/env python3
"""Speaks lines of project/narration/script.txt into project/assets/narration/<id>.ogg. The script is the only source of words.

Only lines named on the command line are made. The owner approves a sample direction before the rest are generated, so there
is deliberately no option to make them all (docs/roadmap.md, M3 narration).

    python tools/audio/make_narration.py shore.talisman cave.carving ending.innsmouth

Needs, in a throwaway environment: pip install kokoro-onnx==0.4.9 soundfile numpy
and these two files beside each other, whose checksums are recorded in docs/evidence/m3/narration/README.md:
    https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx
    https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin

Model: Kokoro-82M, Apache-2.0, https://huggingface.co/hexgrad/Kokoro-82M . Nothing is purchased, and no person's voice is cloned.
"""
import argparse
import os
import re
import sys
from pathlib import Path

import numpy as np
import soundfile
import espeakng_loader
from kokoro_onnx import Kokoro

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "project" / "narration" / "script.txt"
OUT = ROOT / "project" / "assets" / "narration"

VOICE = "am_michael"
LANGUAGE = "en-us"
# Slower than the model's default, which reads like an announcer. A tired man, thinking as he goes.
SPEED = 0.92
# Silence added between phrases, which is most of what can be directed in this model. Longer after a full stop, as he decides to go
# on. The model leaves about half a second of its own at each one.
PAUSE_AFTER = {".": 0.28, "?": 0.28, "!": 0.2, ",": 0.04, ":": 0.15, ";": 0.15}
# A very slight slowing at the end of a line, for the fatigue of finishing a thought.
LAST_PHRASE_SPEED = 0.88
TARGET_RMS_DB = -24.0
PEAK_LIMIT_DB = -3.0
FADE_SECONDS = 0.012
TAIL_SECONDS = 0.25


def read_script():
    lines = {}
    for line in SCRIPT.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        line_id, _, text = line.split("|", 2)
        lines[line_id.strip()] = text.strip()
    return lines


def phrases(text):
    """Splits at punctuation, keeping each mark for its pause. The spoken words are exactly the script's."""
    spoken = text.replace('"', "")
    parts = re.findall(r"[^.,;:?!]+(?:\.\.\.|[.,;:?!])?", spoken)
    return [part.strip() for part in parts if part.strip() and any(ch.isalnum() for ch in part)]


def speak(model, text):
    pieces = []
    rate = None
    parts = phrases(text)
    for index, phrase in enumerate(parts):
        speed = LAST_PHRASE_SPEED if index == len(parts) - 1 else SPEED
        samples, rate = model.create(phrase, voice=VOICE, speed=speed, lang=LANGUAGE)
        fade = int(FADE_SECONDS * rate)
        samples = np.array(samples, dtype=np.float32)
        samples[:fade] *= np.linspace(0.0, 1.0, fade)
        samples[-fade:] *= np.linspace(1.0, 0.0, fade)
        pieces.append(samples)
        ending = phrase[-1]
        pause = 0.0 if index == len(parts) - 1 else PAUSE_AFTER.get(ending, 0.1)
        pieces.append(np.zeros(int(pause * rate), dtype=np.float32))
    pieces.append(np.zeros(int(TAIL_SECONDS * rate), dtype=np.float32))
    return np.concatenate(pieces), rate


def level(audio):
    """The same loudness for every line, measured where he is speaking, with the peak held down."""
    voiced = audio[np.abs(audio) > 0.01]
    rms = float(np.sqrt(np.mean(voiced**2)))
    gain = 10 ** (TARGET_RMS_DB / 20) / rms
    peak = float(np.max(np.abs(audio))) * gain
    limit = 10 ** (PEAK_LIMIT_DB / 20)
    if peak > limit:
        gain *= limit / peak
    return audio * gain


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("lines", nargs="+", help="the ids of the lines to speak")
    parser.add_argument("--model", default="kokoro-v1.0.onnx")
    parser.add_argument("--voices", default="voices-v1.0.bin")
    args = parser.parse_args()
    script = read_script()
    missing = [line for line in args.lines if line not in script]
    if missing:
        sys.exit(f"not in the script: {missing}")
    OUT.mkdir(parents=True, exist_ok=True)
    # The loader knows where its own phoneme data is. Otherwise espeak looks in the path it was built at.
    # espeak also has a short limit on this path, so a deep folder needs ESPEAK_DATA_PATH set to a shorter link to it.
    os.environ.setdefault("ESPEAK_DATA_PATH", espeakng_loader.get_data_path())
    model = Kokoro(args.model, args.voices)
    for line_id in args.lines:
        audio, rate = speak(model, script[line_id])
        audio = level(audio)
        voiced = audio[np.abs(audio) > 0.01]
        path = OUT / f"{line_id}.ogg"
        soundfile.write(path, audio, rate, format="OGG", subtype="VORBIS")
        rms = 20 * np.log10(np.sqrt(np.mean(voiced**2)))
        peak = 20 * np.log10(np.max(np.abs(audio)))
        print(f"{line_id}: {len(audio) / rate:.2f} s, {rms:.1f} dB rms, {peak:.1f} dB peak, {len(script[line_id])} characters, voice {VOICE}, speed {SPEED}")


if __name__ == "__main__":
    main()
