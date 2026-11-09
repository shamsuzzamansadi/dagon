#!/usr/bin/env python3
"""Generates the replacement voice audition: the Shore, cave and ending lines, by two candidate voices.

Both candidates are Chatterbox (Resemble AI, MIT licence) performing the lines, given only a timbre to speak in.
That timbre comes from a stock voice of Kokoro-82M (Apache-2.0), itself synthetic, so no real person's voice is
cloned or imitated. Nothing is bought, and everything runs locally.

    A  Chatterbox, in the timbre of Kokoro's stock voice am_onyx: lower, American
    B  Chatterbox, in the timbre of Kokoro's stock voice bm_george: older, British

Chatterbox marks everything it makes with Resemble AI's imperceptible Perth watermark. That is disclosed with the
samples. Needs, in its own environment: chatterbox-tts 0.1.2, kokoro-onnx 0.4.9, soundfile, and the Kokoro model
files (kokoro-v1.0.onnx, voices-v1.0.bin) in --models.

    python tools/audio/make_audition.py --models DIR --out docs/evidence/m3/voice-audition [--install A]

--install copies that candidate's three files into project/assets/narration, so they play in the game with their
captions. The words always come from project/narration/script.txt, so a caption and its audio cannot drift apart.

Once the owner has chosen a candidate, and only then, the same voice speaks further lines straight into the game:

    python tools/audio/make_audition.py --models DIR --speak A ending.found ending.listen ending.rising

--speak makes only the lines it names, in the chosen candidate's voice and settings, trimmed and levelled as above,
into project/assets/narration/<id>.ogg. There is deliberately no option to speak every line at once.
"""

import argparse
import math
import shutil
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "project" / "narration" / "script.txt"
LINES = ["shore.talisman", "cave.carving", "ending.innsmouth"]
# Each candidate's timbre speed and guidance weight were set so that it speaks at about 11 to 14 characters a second,
# the pace of a tired man talking quietly. A's first pass, at 0.9 and 0.35, came out near 16, too brisk.
CANDIDATES = {
    "A": {"timbre_voice": "am_onyx", "lang": "en-us", "timbre_speed": 0.78, "cfg": 0.25, "exaggeration": 0.3},
    "B": {"timbre_voice": "bm_george", "lang": "en-gb", "timbre_speed": 0.9, "cfg": 0.35, "exaggeration": 0.35},
}
# Spoken by the stock voice only to give Chatterbox a timbre. Never shipped.
TIMBRE_TEXT = "I have told this before, to people who did not believe it. The sea was very still that night, and I was very tired."
TARGET_RMS_DB = -24.0


def read_script():
    words = {}
    for line in SCRIPT.read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        line_id, _kind, text = line.split("|", 2)
        words[line_id] = text
    return words


def trim_and_level(audio, rate):
    """Silence trimmed to a short tail at each end, level set by RMS, and nothing over -1 dBFS."""
    audio = np.asarray(audio, dtype=np.float64).squeeze()
    gate = 10 ** (-45 / 20) * np.max(np.abs(audio))
    loud = np.nonzero(np.abs(audio) > gate)[0]
    if len(loud):
        start = max(0, loud[0] - int(0.08 * rate))
        end = min(len(audio), loud[-1] + int(0.25 * rate))
        audio = audio[start:end]
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
    parser.add_argument("--models", required=True, type=Path)
    parser.add_argument("--install", choices=sorted(CANDIDATES))
    parser.add_argument("--only", choices=sorted(CANDIDATES), help="regenerate one candidate and keep the other's files")
    parser.add_argument("--speak", nargs="+", metavar=("CANDIDATE", "LINE"), help="after the owner's choice: speak these lines in that voice, into the game")
    parser.add_argument("--out", type=Path, default=ROOT / "docs" / "evidence" / "m3" / "voice-audition")
    args = parser.parse_args()
    if args.speak and (args.speak[0] not in CANDIDATES or len(args.speak) < 2):
        parser.error("--speak needs a candidate, A or B, then one or more line ids")

    import os

    import espeakng_loader

    # As in make_narration.py: espeak needs telling where its phoneme data is, and has a short limit on that path,
    # so a deep folder needs ESPEAK_DATA_PATH set to a shorter link to it.
    os.environ.setdefault("ESPEAK_DATA_PATH", espeakng_loader.get_data_path())
    from kokoro_onnx import Kokoro
    from chatterbox.tts import ChatterboxTTS
    import torch

    torch.manual_seed(1)
    words = read_script()
    kokoro = Kokoro(str(args.models / "kokoro-v1.0.onnx"), str(args.models / "voices-v1.0.bin"))
    model = ChatterboxTTS.from_pretrained(device="cuda" if torch.cuda.is_available() else "cpu")
    report = []
    if args.speak:
        name, line_ids = args.speak[0], args.speak[1:]
        unknown = [line_id for line_id in line_ids if line_id not in words]
        if unknown:
            print(f"not in the script: {unknown}")
            return 2
        spec = CANDIDATES[name]
        timbre, rate = kokoro.create(TIMBRE_TEXT, voice=spec["timbre_voice"], speed=spec["timbre_speed"], lang=spec["lang"])
        timbre_path = args.models / f"timbre_{name}.wav"
        sf.write(timbre_path, timbre, rate)
        target = ROOT / "project" / "assets" / "narration"
        target.mkdir(parents=True, exist_ok=True)
        for line_id in line_ids:
            torch.manual_seed(7)
            wav = model.generate(words[line_id], audio_prompt_path=str(timbre_path), exaggeration=spec["exaggeration"], cfg_weight=spec["cfg"])
            audio = trim_and_level(wav.cpu().numpy(), model.sr)
            sf.write(target / f"{line_id}.ogg", audio, model.sr, format="OGG", subtype="VORBIS")
            seconds = len(audio) / model.sr
            print(f"{name} {line_id} {seconds:.2f}s {len(words[line_id]) / seconds:.1f} chars/s -> {target / (line_id + '.ogg')}", flush=True)
        return 0
    for name, spec in CANDIDATES.items():
        if args.only and name != args.only:
            report.extend(line for line in (args.out / "measurements.txt").read_text().splitlines() if line.startswith(name + " ")) if (args.out / "measurements.txt").exists() else None
            continue
        folder = args.out / name
        folder.mkdir(parents=True, exist_ok=True)
        timbre, rate = kokoro.create(TIMBRE_TEXT, voice=spec["timbre_voice"], speed=spec["timbre_speed"], lang=spec["lang"])
        timbre_path = args.models / f"timbre_{name}.wav"
        sf.write(timbre_path, timbre, rate)
        for line_id in LINES:
            torch.manual_seed(7)
            wav = model.generate(words[line_id], audio_prompt_path=str(timbre_path), exaggeration=spec["exaggeration"], cfg_weight=spec["cfg"])
            audio = trim_and_level(wav.cpu().numpy(), model.sr)
            path = folder / f"{line_id}.ogg"
            sf.write(path, audio, model.sr, format="OGG", subtype="VORBIS")
            seconds = len(audio) / model.sr
            report.append(f"{name} {line_id} {seconds:.2f}s {len(words[line_id]) / seconds:.1f} chars/s")
            print(report[-1], flush=True)
    if args.install:
        target = ROOT / "project" / "assets" / "narration"
        target.mkdir(parents=True, exist_ok=True)
        for line_id in LINES:
            shutil.copyfile(args.out / args.install / f"{line_id}.ogg", target / f"{line_id}.ogg")
        print(f"installed candidate {args.install} in {target}")
    (args.out / "measurements.txt").write_text("\n".join(report) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
