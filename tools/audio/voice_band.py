"""voice_band.py MIX VOICE BED LOG: per spoken line, the voice against what is beneath it, wideband and in the speech band
(300-4000 Hz), and the loudest sources. Measurement only."""
import sys, re, math
import numpy as np, soundfile as sf
from scipy import signal
mix, rate = sf.read(sys.argv[1]); voice, _ = sf.read(sys.argv[2]); bed, _ = sf.read(sys.argv[3])
n = min(len(mix), len(voice), len(bed)); mix, voice, bed = mix[:n].mean(1), voice[:n].mean(1), bed[:n].mean(1)
under = mix - voice
sos = signal.butter(4, (300, 4000), "band", fs=rate, output="sos")
marks = [(m.group(1), int(m.group(2))) for m in re.finditer(r"RECORD (\S+) frame=(\d+)", open(sys.argv[4]).read())]
first = marks[0][1]
def db(x): 
    p = float(np.mean(x ** 2)) if len(x) else 0; return 10 * math.log10(p) if p > 0 else -120
print(f"{'line':26} {'wide: voice':>11} {'beneath':>8} {'above':>6} | {'300-4k: voice':>13} {'beneath':>8} {'above':>6} | worst 0.5 s in band")
for (stage, f), (_, f2) in zip(marks, marks[1:]):
    if not stage.startswith("line-"): continue
    a, b = int((f - first) / 30 * rate), int((f2 - first) / 30 * rate)
    w = int(0.05 * rate)
    idx = [i for i in range(a, b - w, w) if db(voice[i:i + w]) > -50]
    if not idx: continue
    a2, b2 = idx[0], idx[-1] + w
    v, u = voice[a2:b2], under[a2:b2]
    vb, ub = signal.sosfilt(sos, v), signal.sosfilt(sos, u)
    half = int(0.5 * rate); worst = min((db(vb[i:i + half]) - db(ub[i:i + half]) for i in range(0, max(1, len(vb) - half), half // 2) if db(vb[i:i + half]) > -45), default=float("nan"))
    print(f"{stage:26} {db(v):11.1f} {db(u):8.1f} {db(v) - db(u):6.1f} | {db(vb):13.1f} {db(ub):8.1f} {db(vb) - db(ub):6.1f} | {worst:6.1f}")
