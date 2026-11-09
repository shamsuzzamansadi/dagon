#!/usr/bin/env python3
"""The listening package, and measurements of the game's real mix. Measurement only: nothing here can judge how
anything sounds. That needs a person listening.

    listening.py voices OUT_DIR
        Voice candidates A and B speaking the same passages, matched to the same integrated loudness (ITU-R BS.1770),
        so neither wins by being louder. From docs/evidence/m3/voice-audition/.

    listening.py excerpts RECORDING.wav RUN.log OUT_DIR
        Cuts the soundtrack of a recording made by project/tests/record_play.gd into labelled excerpts, by the
        "RECORD <stage> frame=<n>" lines it printed. These are the game's own mix during play, not reconstructions.

    listening.py check RECORDING.wav RUN.log
        Measures that soundtrack: peak and true peak, loudness per stage, sudden drops and jumps, clicks, silence
        while paused, and what is still sounding on the main menu. Prints a report.
"""

import math
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

ROOT = Path(__file__).resolve().parents[2]
AUDITION = ROOT / "docs" / "evidence" / "m3" / "voice-audition"
FPS = 30
PASSAGES = ["shore.talisman", "ending.innsmouth"]
TARGET_LUFS = -23.0

# Which stretch of a recording each excerpt covers, by its RECORD stages, and what it is for.
EXCERPTS = [
    ("01-opening-prologue", "prologue", "shore", "The whole prologue, unskipped: its music, the sea, the oars, the calm, the wind"),
    ("02-shore", "shore", "pause", "The Shore: sea, wind, wet sand underfoot, his tired breathing, the talisman's voice"),
    ("03-pause-and-resume", "pause", "resume", "Pausing on the Shore and resuming, with 4 s either side: everything should stop, then come back"),
    ("04-cave", "cave", "seabed", "The cave: its air and drips, the restrained music, rock underfoot, the carving's voice"),
    ("05-seabed-and-crossing", "seabed", "crossed", "Out on the seabed, the ritual far off, the climb, the stone pushed and the slab down"),
    ("06-stones-and-gate", "crossed", "gate-open", "The Abyss to the Monolith, a wrong stone, the right ones, the stones answering, the gate"),
    ("07-reveal", "gate-open", "escape-running", "The reveal: the water, the cascade, its call, the hand on the stone, his gasp, the music"),
    ("08-escape-running", "escape-running", "ending", "Running from the sea: the roar behind, the rock, his breathing, the fall, the sea over him"),
    ("09-ending", "ending", "main-menu", "The ending: music and the sea under the four lines, one of them voiced, and the credits"),
    ("10-escape-standing-still", "escape-standing-still", "ending-again", "The other outcome: standing still at the ledge until the sea comes"),
]


def read(path):
    x, rate = sf.read(str(path), always_2d=True)
    return x, rate


def to_48k(x, rate):
    if rate == 48000:
        return x
    g = math.gcd(48000, rate)
    return signal.resample_poly(x, 48000 // g, rate // g, axis=0)


def k_weight(x):
    """The K-weighting of BS.1770, at 48 kHz."""
    b1, a1 = [1.53512485958697, -2.69169618940638, 1.19839281085285], [1.0, -1.69065929318241, 0.73248077421585]
    b2, a2 = [1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621]
    return signal.lfilter(b2, a2, signal.lfilter(b1, a1, x, axis=0), axis=0)


def block_loudness(x48, block=0.4, overlap=0.75):
    k = k_weight(x48)
    n = int(block * 48000)
    step = max(1, int(n * (1 - overlap)))
    out = []
    for start in range(0, max(1, len(k) - n + 1), step):
        z = np.mean(k[start : start + n] ** 2, axis=0).sum()
        out.append(-0.691 + 10 * math.log10(z) if z > 0 else -120.0)
    return np.array(out)


def integrated(x, rate):
    blocks = block_loudness(to_48k(x, rate))
    above = blocks[blocks > -70]
    if len(above) == 0:
        return -120.0
    relative = 10 * math.log10(np.mean(10 ** (above / 10))) - 10
    gated = above[above > relative]
    return 10 * math.log10(np.mean(10 ** (gated / 10)))


def true_peak_db(x, rate):
    up = signal.resample_poly(x, 4, 1, axis=0)
    peak = np.max(np.abs(up))
    return 20 * math.log10(peak) if peak > 0 else -120.0


def peak_db(x):
    peak = np.max(np.abs(x))
    return 20 * math.log10(peak) if peak > 0 else -120.0


def write_ogg(path, x, rate):
    with sf.SoundFile(str(path), "w", rate, x.shape[1], format="OGG", subtype="VORBIS") as out:
        for start in range(0, len(x), 32768):
            out.write(x[start : start + 32768])


def voices(out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    for passage in PASSAGES:
        for candidate in "AB":
            x, rate = read(AUDITION / candidate / f"{passage}.ogg")
            before = integrated(x, rate)
            gain = 10 ** ((TARGET_LUFS - before) / 20)
            y = x * gain
            tp = true_peak_db(y, rate)
            if tp > -1.0:
                y *= 10 ** ((-1.0 - tp) / 20)
            name = f"voice-{candidate}-{passage}.ogg"
            write_ogg(out_dir / name, y, rate)
            rows.append((name, before, integrated(y, rate), true_peak_db(y, rate), len(x) / rate))
    print(f"{'file':40} {'as made':>8} {'here':>8} {'true pk':>8} {'s':>5}")
    for name, before, after, tp, seconds in rows:
        print(f"{name:40} {before:8.1f} {after:8.1f} {tp:8.1f} {seconds:5.1f}")
    return 0


def stages(log_path):
    found = {}
    for line in Path(log_path).read_text(errors="replace").splitlines():
        m = re.match(r"RECORD (\S+) frame=(\d+)", line)
        if m:
            found.setdefault(m.group(1), int(m.group(2)))
    return found


def span(marks, first, until, first_frame):
    """Seconds into the recording, from the frame numbers the script printed. The movie starts at the first frame."""
    return (marks[first] - first_frame) / FPS, (marks[until] - first_frame) / FPS


def excerpts(recording, log_path, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    x, rate = read(recording)
    marks = stages(log_path)
    first = min(marks.values())
    for name, a, b, use in EXCERPTS:
        if a not in marks or b not in marks:
            print(f"MISSING stages for {name}")
            continue
        start, end = span(marks, a, b, first)
        if name.startswith("03-"):
            start, end = start - 4.0, end + 4.0
        piece = x[int(start * rate) : int(end * rate)].copy()
        fade = min(len(piece) // 4, int(0.3 * rate))
        if fade:
            ramp = np.linspace(0, 1, fade)[:, None]
            piece[:fade] *= ramp
            piece[-fade:] *= ramp[::-1]
        write_ogg(out_dir / f"{name}.ogg", piece, rate)
        print(f"{name:28} {start:7.1f}-{end:7.1f} s  {use}")
    return 0


def check(recording, log_path):
    x, rate = read(recording)
    marks = stages(log_path)
    first = min(marks.values())
    seconds = len(x) / rate
    problems = 0
    print(f"recording: {seconds:.1f} s, {x.shape[1]} channels, {rate} Hz")
    pk, tp = peak_db(x), true_peak_db(x, rate)
    print(f"peak {pk:.1f} dBFS, true peak {tp:.1f} dBTP{'  <- clipping' if pk >= -0.1 else ''}")
    problems += pk >= -0.1
    # Loudness by stage.
    order = sorted(marks.items(), key=lambda kv: kv[1])
    print("\nloudness by stage (integrated LUFS, and the loudest 3 s)")
    for (stage, frame), nxt in zip(order, order[1:] + [("end", int(first + seconds * FPS))]):
        start, end = (frame - first) / FPS, (nxt[1] - first) / FPS
        piece = x[int(start * rate) : int(end * rate)]
        if len(piece) < rate:
            continue
        short = block_loudness(to_48k(piece, rate), block=3.0, overlap=0.9)
        print(f"  {stage:24} {start:7.1f}-{end:7.1f} s  {integrated(piece, rate):7.1f} LUFS  max short-term {short.max():6.1f}")
    # Sudden changes: 20 ms windows, a drop or rise of more than 30 dB from one to the next, above the floor.
    w = int(0.02 * rate)
    rms = np.array([np.sqrt(np.mean(x[i : i + w] ** 2)) for i in range(0, len(x) - w, w)])
    db = 20 * np.log10(np.maximum(rms, 1e-9))
    jumps = [(i * w / rate, db[i], db[i + 1]) for i in range(len(db) - 1) if abs(db[i + 1] - db[i]) > 30 and max(db[i], db[i + 1]) > -60]
    print(f"\nsudden changes over 30 dB within 20 ms: {len(jumps)}")
    for t, a, b in jumps[:20]:
        print(f"  at {t:7.2f} s ({where(marks, first, t)}): {a:6.1f} -> {b:6.1f} dB")
    # Clicks: a single-sample step far larger than the sound around it.
    mono = x.mean(axis=1)
    step = np.abs(np.diff(mono))
    local = np.sqrt(signal.convolve(mono**2, np.ones(441) / 441, mode="same"))[1:] + 1e-6
    clicks = np.where((step > 0.2) & (step > 12 * local))[0]
    print(f"\nisolated sample steps (possible clicks): {len(clicks)}")
    for i in clicks[:10]:
        print(f"  at {i / rate:7.2f} s ({where(marks, first, i / rate)})")
    # The pause: everything should stop.
    if "pause" in marks and "resume" in marks:
        start, end = span(marks, "pause", "resume", first)
        inner = x[int((start + 0.5) * rate) : int((end - 0.3) * rate)]
        level = peak_db(inner) if len(inner) else -120.0
        print(f"\nwhile paused: peak {level:.1f} dBFS{'  <- sound while paused' if level > -50 else ''}")
        problems += level > -50
    if "main-menu" in marks and "continue" in marks:
        start, end = span(marks, "main-menu", "continue", first)
        inner = x[int((start + 0.3) * rate) : int((end - 0.5) * rate)]
        print(f"main menu after the ending: peak {peak_db(inner):.1f} dBFS, {integrated(inner, rate):.1f} LUFS")
    print(f"\nMIX_CHECK problems={problems}")
    return 1 if problems else 0


def where(marks, first, t):
    frame = first + t * FPS
    before = [s for s, f in marks.items() if f <= frame]
    return max(before, key=lambda s: marks[s]) if before else "start"


def main(argv):
    if len(argv) >= 2 and argv[0] == "voices":
        return voices(Path(argv[1]))
    if len(argv) >= 4 and argv[0] == "excerpts":
        return excerpts(Path(argv[1]), argv[2], Path(argv[3]))
    if len(argv) >= 3 and argv[0] == "check":
        return check(Path(argv[1]), argv[2])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
