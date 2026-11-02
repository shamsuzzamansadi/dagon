# Evidence: the Shore as the entry scene

Software rendering (llvmpipe) throughout. Nothing here has been seen on a real GPU or the owner's display.

| File | What it is | How it was made |
|---|---|---|
| `startup-release-build-3x.png`, `-native-480x270.png`, `startup-release-build.gif` | **The standard build's startup scene**, unedited, with no input | Linux release export of `4436339`: `./dagon.x86_64 --write-movie … --fixed-fps 60 --quit-after 300`. Its log shows `Completed load for: 'res://scenes/level/shore.tscn'` |
| `standing-on-the-rock-3x.png` | Feet on the rock's top | `tests/capture_shore.gd`, scripted input, debug library, `c8a577b` |
| `art-meets-greybox-3x.png`, `greybox-trench-3x.png` | Where the art ends, and the greybox past it | Same capture |
| `camera-jitter.txt`, `measure_jitter.py` | On-screen position measured on rendered frames, in both scenes | See the file |
| `terrain-diff.txt` | Exactly which pixels of the accepted art changed | Pixel comparison with `c32a65e` |
| `mutation/` | Deliberate breakage and the checks that caught it | See its README |

The Windows build could not be captured here: artifacts cannot be downloaded without a token, and this
machine builds only for Linux. Both builds are exported from the same project. CI checks that the Windows
export starts in the Shore, headless, on the runner. A person has not yet seen this scene on Windows.
