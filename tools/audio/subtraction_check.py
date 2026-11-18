"""subtraction_check.py MIX VOICE BED LOG: whether "the mix less the voice" is what played beneath each spoken line.

voice_band.py and listening.py narration take what played beneath a line to be the mix take less the voice-alone take:
two separate Movie Maker runs of record_finale.gd. That holds only if the takes are aligned to the sample and the voice
is processed the same way in both. Event marks on the same video frames show neither. This reports:

  render         the first sample at which the mix and bed takes differ, at all and by more than one 16-bit step,
                 against the voice take's first sound: before it nothing ducks, so two runs that render alike are the
                 same there, sample for sample. A voice begins below one step, so the first may come a little before it
  between lines  from a second after any voice (past the ducking's release) to the next, how far the mix take's
                 difference from the bed take lies below the bed
  each line      per channel, over the spoken stretch: the lag of the peak of the cross-correlation of mix and voice
                 within 50 ms; the voice's gain in the mix by least squares; the correlation of what is left with the
                 voice; and, if all of that gain's distance from 1 were voice left in, its level against what is beneath,
                 wideband and in 300-4000 Hz
  the limiter    each take's peak against the Master limiter's ceiling, and where a take reaches it within a spoken
                 stretch: a take whose limiter acted there was not processed as the others were

The gain's distance from 1 also holds the bed's chance likeness to the voice, so the leftover it implies is an upper
bound. Measurement only: it says whether the subtraction is sound, not how anything sounds.
"""
import math
import pathlib
import re
import sys

import numpy as np
import soundfile as sf
from scipy import signal

FPS = 30
LAYOUT = pathlib.Path(__file__).resolve().parents[2] / "project" / "default_bus_layout.tres"


def db(x):
    p = float(np.mean(np.asarray(x, dtype=float) ** 2)) if len(x) else 0.0
    return 10 * math.log10(p) if p > 0 else -999.0


def main(mix_path, voice_path, bed_path, log_path):
    mix, rate = sf.read(mix_path)
    voice, r2 = sf.read(voice_path)
    bed, r3 = sf.read(bed_path)
    assert rate == r2 == r3, "the takes differ in rate"
    n = min(len(mix), len(voice), len(bed))
    mix, voice, bed = mix[:n], voice[:n], bed[:n]
    marks = [(m.group(1), int(m.group(2))) for m in re.finditer(r"RECORD (\S+) frame=(\d+)", open(log_path).read())]
    first = marks[0][1]
    per_frame = rate / FPS
    ceiling = 10 ** (float(re.search(r"ceiling_db = (\S+)", LAYOUT.read_text()).group(1)) / 20)
    sos = signal.butter(4, (300, 4000), "band", fs=rate, output="sos")
    print(f"takes: {n / rate:.1f} s in common at {rate} Hz, {per_frame:g} samples a frame")

    lines = []
    for (stage, f), (_, f2) in zip(marks, marks[1:]):
        if not stage.startswith("line-"):
            continue
        a, z = int((f - first) * per_frame), int((f2 - first) * per_frame)
        w = int(0.05 * rate)
        active = [i for i in range(a, z - w, w) if db(voice[i:i + w].mean(1)) > -50]
        if active:
            lines.append((stage, active[0], active[-1] + w))

    step = 1 / 32768
    differ = np.nonzero((mix != bed).any(axis=1))[0]
    beyond = np.nonzero((np.abs(mix - bed) > step * 1.5).any(axis=1))[0]
    sounding = (voice != 0).any(axis=1)
    first_voice = int(np.argmax(sounding))
    at = differ[0] / rate if len(differ) else float("nan")
    big = beyond[0] / rate if len(beyond) else float("nan")
    print(f"\nrender: mix and bed takes first differ at {at:.4f} s, and by more than one 16-bit step at {big:.4f} s;"
          f" the voice take's first sound, the first sample not zero, is at {first_voice / rate:.4f} s:"
          f" {'the same, sample for sample, before the voice to within one step' if len(beyond) == 0 or beyond[0] >= first_voice else 'THEY DIFFER BEFORE THE VOICE'}")

    idx = np.arange(n)
    last_sound = np.maximum.accumulate(np.where(sounding, idx, -1))
    clear = (last_sound >= 0) & (idx - last_sound > rate) & ~sounding
    gap = mix[clear].mean(1) - bed[clear].mean(1)
    second = rate
    windows = [(i, db(bed[i:i + second].mean(1)) - db(mix[i:i + second].mean(1) - bed[i:i + second].mean(1)))
               for i in range(0, n - second, second) if clear[i:i + second].all()]
    least = min(windows, key=lambda w: w[1]) if windows else (0, float("nan"))
    print(f"between lines: from a second after any voice ({clear.mean() * 100:.0f}% of the take), mix less bed {db(gap):.1f} dB,"
          f" the bed {db(bed[clear].mean(1)):.1f} dB: {db(bed[clear].mean(1)) - db(gap):.1f} dB below it;"
          f" in the closest whole second, at {least[0] / rate:.0f} s, {least[1]:.1f} dB below it")

    print(f"\n{'line':26} {'ch':>2} {'lag':>4} {'gain':>7} {'corr':>7} | {'leftover against beneath, at most':>33}")
    print(f"{'':26} {'':>2} {'smp':>4} {'':>7} {'':>7} | {'wide dB':>16} {'300-4k dB':>16}")
    worst = -999.0
    for stage, a, z in lines:
        for ch in (0, 1):
            m, v = mix[a:z, ch], voice[a:z, ch]
            reach = int(0.05 * rate)
            c = signal.correlate(m, v, mode="full", method="fft")[len(v) - 1 - reach:len(v) + reach]
            lag = int(np.argmax(c)) - reach
            gain = float(np.dot(m, v) / np.dot(v, v))
            under = m - v
            corr = float(np.dot(under, v) / math.sqrt(np.dot(under, under) * np.dot(v, v)))
            left_wide = 20 * math.log10(max(abs(gain - 1), 1e-9)) + db(v) - db(under)
            vb, ub = signal.sosfilt(sos, v), signal.sosfilt(sos, under)
            left_band = 20 * math.log10(max(abs(gain - 1), 1e-9)) + db(vb) - db(ub)
            worst = max(worst, left_wide, left_band)
            print(f"{stage:26} {ch:>2} {lag:>+4d} {gain:7.4f} {corr:+7.4f} | {left_wide:16.1f} {left_band:16.1f}")
    print(f"\nthe largest leftover against beneath: {worst:.1f} dB, which moves the beneath level by at most"
          f" {10 * math.log10(1 + 10 ** (worst / 10) + 2 * 10 ** (worst / 20)):.2f} dB")

    print(f"\nthe limiter: ceiling {20 * math.log10(ceiling):.1f} dBFS")
    for name, take in (("mix", mix), ("voice", voice), ("bed", bed)):
        peak = float(np.max(np.abs(take)))
        at_ceiling = np.nonzero(np.abs(take).max(1) >= ceiling * 0.999)[0]
        within = sorted({stage for stage, a, z in lines for i in at_ceiling if a <= i < z})
        times = sorted({round(i / rate, 2) for i in at_ceiling})
        print(f"  {name:5} peak {20 * math.log10(peak):6.2f} dBFS; {len(at_ceiling)} samples at the ceiling"
              f"{', at ' + ', '.join(f'{t:.2f}' for t in times[:6]) + ' s' if times else ''}"
              f"{'; within ' + ', '.join(within) if within else ''}")


if __name__ == "__main__":
    main(*sys.argv[1:5])
