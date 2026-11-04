# Evidence: M3

Everything here is automated or scripted. **Nothing in this folder is a human test.** The owner's manual check is in the
[review package](../../reviews/m3-review-package.md), and its result will have its own record.

| File | What it is | How it was made |
|---|---|---|
| `overlap-latency.txt`, `overlap-latency-probe.gd.txt` | How many physics frames pass before a moved body reaches an Area2D's overlap list on Godot 4.7.2. This is why the recheck waits 3 frames ([D49](../../decisions.md)) | The probe script, run headless with `--fixed-fps 60` |
| `breakage.txt` | Deliberate breakage of M3's work, one change at a time, and what caught each | Scratch clones, with storage isolated. Simulated input only |
| `route/` | Transcripts of the exported route from CI, and what the game logged | `tools/route_check.py` on the `dagon-linux` and `dagon-windows` builds |
| `route/screens/` | Screens from the exported route on Linux, under Xvfb with software rendering (`llvmpipe`). **Not a real GPU, and not a statement about how the game looks on a player's display** | `--shots` |
| `fresh-clone.txt` | A clean clone from GitHub, built and tested following the README, with the suite repeated | Developer's machine, Ubuntu 24.04 under WSL2 |
