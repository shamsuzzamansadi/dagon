# Evidence: M3

Everything here is automated or scripted, with one exception. **The one human record in this folder is `owner-playtest-2026-11-04.md`.** Nothing else here is a human test, and none of it says how the game feels. The owner's manual check is in the [review package](../../reviews/m3-review-package.md), and its result will have its own record.

| File | What it is | How it was made |
|---|---|---|
| `overlap-latency.txt`, `overlap-latency-probe.gd.txt` | How many physics frames pass before a moved body reaches an Area2D's overlap list on Godot 4.7.2. This is why the recheck waits 3 frames ([D49](../../decisions.md)) | The probe script, run headless with `--fixed-fps 60` |
| `breakage-first-pass-at-2cae7bb.txt` | The first full pass of deliberate breakage, of 84, before the owner's update | Scratch clones, with storage isolated. Simulated input only |
| `breakage-focused-at-35ff084.txt` | The focused pass for the owner's update, and the gaps from the first pass. The one a usage limit interrupted the reading of | The same |
| `breakage.txt` | The last focused pass, at the final tested commit: what the one before left open, and the changes after the owner's playtest | The same |
| `breakage-tool.py.txt` | The tool that ran them, with each deliberate change. Kept because its home was temporary | Developer |
| `route/` | Transcripts of the exported route from CI, with the pacing lines, and what the game logged | `tools/route_check.py` on the `dagon-linux` and `dagon-windows` builds |
| `route/screens/` | Screens from the exported route on Linux, under Xvfb with software rendering (`llvmpipe`). **Not a real GPU, and not a statement about how the game looks on a player's display** | `--shots` |
| `walk/` | Each stretch of the greybox, and stills of each stage of the reveal, reached by seeking the clips. **To judge staging only:** they cannot show timing | `tests/capture_m3.gd` on a private display, with software rendering |
| `owner-playtest-2026-11-04.md` | **The owner's own feedback on the M3 build. Not accepted.** The one human record here | Written down as the owner gave it |
| `narration/` | The voice samples' source, rights, direction, measurements and approval status. **The owner has heard them, and they are not an approved voice.** The developer cannot hear audio | [Its README](narration/README.md) |
| `fresh-clone.txt` | A clean clone from GitHub, built and tested following the README, with the suite repeated | Developer's machine, Ubuntu 24.04 under WSL2 |
