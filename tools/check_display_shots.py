"""check_display_shots.py <final dir>...: for each screenshot of capture_display.gd, with the window's place, size and
scale from its run.log, checks that the game's picture is a whole multiple of 480 x 270 (each scale x scale block one
colour: sharp pixels, right shape) and that the window's bars around it, if any, are black."""
import re, sys, glob, os
import numpy as np
from PIL import Image
for d in sys.argv[1:]:
    rows = [l for l in open(os.path.join(d, "run.log")) if l.startswith("DISPLAY ") and " key-" not in l]
    shots = sorted(glob.glob(os.path.join(d, "*.png")))
    for line, shot in zip(rows, shots):
        m = re.search(r"DISPLAY (\S+) mode=(\S+) window=\((\d+), (\d+)\) at=\((-?\d+), (-?\d+)\).*scale=(\d+)", line)
        stage, mode, ww, wh, x, y, k = m.group(1), m.group(2), *map(int, m.groups()[2:])
        a = np.asarray(Image.open(shot).convert("RGB")).astype(int)
        pw, ph = 480 * k, 270 * k
        ox, oy = x + (ww - pw) // 2, y + (wh - ph) // 2
        pic = a[oy:oy + ph, ox:ox + pw]
        blocks = pic.reshape(270, k, 480, k, 3)
        uneven = int((blocks != blocks[:, :1, :, :1, :]).any(axis=(1, 3, 4)).sum())
        win = a[y:y + wh, x:x + ww].copy()
        win[oy - y:oy - y + ph, ox - x:ox - x + pw] = 0
        bars = int((win.max(axis=2) > 8).sum())
        print(f"{os.path.basename(shot):42s} {mode:10s} window {ww}x{wh} picture {pw}x{ph} at {ox},{oy} (x{k}, {pw/ph:.4f}): blocks not one colour {uneven} of {270*480}; non-black pixels in the bars {bars}")
