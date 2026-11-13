#!/usr/bin/env python3
"""Transcribes spoken lines with a local speech recogniser and compares each with project/narration/script.txt.

    python tools/audio/check_narration.py [--words] [--folder DIR] [LINE ...]

With no line named, every recording in project/assets/narration is checked. Each line is reported as word for word, or
with the words that differ, and with its length, pace and level. --words also prints when each word is said, for
timing a picture to a phrase. --folder checks takes kept somewhere else, named <line id>.ogg. Exits 1 if any line
differs, so a take that a machine mishears is looked at before it is kept.

A transcript says which words a machine hears. It does not say whether the voice sounds right: that is for a
person listening. A rare name can be misheard from a good recording, and such a line is recorded as an exception
with the evidence, not passed quietly.

Needs, in the voice environment: transformers, torch, soundfile, scipy, and the Whisper small.en model
(openai/whisper-small.en, MIT licence), which runs locally.
"""

import argparse
import difflib
import math
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "project" / "narration" / "script.txt"
AUDIO = ROOT / "project" / "assets" / "narration"
MODEL = "openai/whisper-small.en"
# The recogniser writes small numbers as digits or as words, as it pleases.
# Words that sound the same. No recogniser can tell them apart, so hearing one for the other is not a difference, and
# is reported beside the verdict.
HOMOPHONES = [{"rowed", "rode", "road"}, {"sea", "see"}, {"tide", "tied"}, {"two", "too", "to"}, {"knelt", "nelt"}, {"their", "there"}]
# A difference already looked at and recorded with the evidence, by line: (script's word, heard). It is still printed,
# as an exception, and no longer fails the run. Whether the word sounds right is for a person listening.
RECORDED = {"ending.innsmouth": ("innsmouth", "insemouth")}  # docs/evidence/m3/voice-audition/README.md
NUMBERS = {"1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine", "10": "ten"}


def read_script():
    words = {}
    for line in SCRIPT.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        line_id, _kind, text = line.split("|", 2)
        words[line_id] = text
    return words


def normal(text):
    """Lower case, no punctuation, so only the words are compared."""
    return [NUMBERS.get(word, word) for word in re.sub(r"[^a-z0-9' ]", " ", text.lower().replace("’", "'")).split()]


def differences(script_words, heard_words):
    """Each place the transcript departs from the script, as (script's words, heard words), and the homophones heard."""
    out, same_sound = [], []
    matcher = difflib.SequenceMatcher(None, script_words, heard_words, autojunk=False)
    for tag, a0, a1, b0, b1 in matcher.get_opcodes():
        if tag == "equal":
            continue
        ours, theirs = script_words[a0:a1], heard_words[b0:b1]
        if len(ours) == len(theirs) and all(a == b or any(a in group and b in group for group in HOMOPHONES) for a, b in zip(ours, theirs)):
            same_sound += [f"'{a}' heard as '{b}'" for a, b in zip(ours, theirs) if a != b]
            continue
        out.append((" ".join(ours), " ".join(theirs)))
    return out, same_sound


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("lines", nargs="*", help="line ids; all recordings if none")
    parser.add_argument("--folder", type=Path, default=AUDIO)
    parser.add_argument("--words", action="store_true", help="also print when each word is said")
    args = parser.parse_args()
    script = read_script()
    ids = args.lines or sorted(path.stem for path in args.folder.glob("*.ogg"))
    unknown = [line_id for line_id in ids if line_id not in script]
    if unknown:
        print(f"not in the script: {unknown}")
        return 2
    missing = [line_id for line_id in ids if not (args.folder / f"{line_id}.ogg").exists()]
    if missing:
        print(f"no recording: {missing}")
        return 2

    from transformers import pipeline

    recogniser = pipeline("automatic-speech-recognition", model=MODEL, device="cpu")
    differing = 0
    for line_id in ids:
        audio, rate = sf.read(str(args.folder / f"{line_id}.ogg"), always_2d=True)
        audio = audio.mean(axis=1)
        seconds = len(audio) / rate
        rms = 20 * math.log10(math.sqrt(float(np.mean(audio**2))) + 1e-12)
        peak = 20 * math.log10(float(np.max(np.abs(audio))) + 1e-12)
        at_16k = signal.resample_poly(audio, 16000, rate) if rate != 16000 else audio
        result = recogniser({"raw": at_16k.astype(np.float32), "sampling_rate": 16000}, return_timestamps="word")
        heard = result["text"].strip()
        diff, same_sound = differences(normal(script[line_id]), normal(heard))
        excepted = [pair for pair in diff if pair == RECORDED.get(line_id)]
        diff = [pair for pair in diff if pair not in excepted]
        verdict = "word for word" if not diff else "DIFFERS: " + "; ".join(f"script '{a}' heard '{b}'" for a, b in diff)
        if excepted:
            verdict += " (a recorded exception: " + ", ".join(f"'{a}' heard as '{b}'" for a, b in excepted) + ")"
        if same_sound:
            verdict += " (same sound: " + ", ".join(same_sound) + ")"
        differing += bool(diff)
        print(f"{line_id}: {verdict}")
        print(f"   {seconds:.2f} s, {len(script[line_id]) / seconds:.1f} chars/s, {rms:.1f} dB RMS, peak {peak:.1f} dBFS")
        print(f"   script: {script[line_id]}")
        print(f"   heard:  {heard}")
        if args.words:
            print("   words:  " + " ".join(f"{chunk['text'].strip()}@{chunk['timestamp'][0]:.2f}" for chunk in result["chunks"] if chunk["timestamp"][0] is not None))
    print(f"{len(ids)} lines, {differing} differing")
    return 1 if differing else 0


if __name__ == "__main__":
    sys.exit(main())
