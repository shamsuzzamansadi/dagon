"""limiter_use.py MIX LOG: how much of each stage sits at the limiter's ceiling (-1 dBFS). Measurement only."""
import sys, re
import numpy as np, soundfile as sf
x, rate = sf.read(sys.argv[1]); peak = np.abs(x).max(1)
marks = [(m.group(1), int(m.group(2))) for m in re.finditer(r"RECORD (\S+) frame=(\d+)", open(sys.argv[2]).read())]
first = marks[0][1]; w = int(0.01 * rate); ceil = 10 ** (-1.05 / 20)
for (stage, f), (_, f2) in zip(marks, marks[1:]):
    a, b = int((f - first) / 30 * rate), int((f2 - first) / 30 * rate)
    wins = [peak[i:i + w].max() >= ceil for i in range(a, b - w, w)]
    if wins:
        t = [a / rate + i * 0.01 for i, v in enumerate(wins) if v]
        print(f"{stage:26} {a / rate:6.1f}-{b / rate:6.1f} s  at the ceiling {100 * sum(wins) / len(wins):5.1f} % of 10 ms windows" + (f"  first {t[0]:.2f} s, last {t[-1]:.2f} s" if t else ""))
