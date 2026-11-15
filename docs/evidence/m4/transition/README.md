# The cut from the prologue into the game: a gap in the sound, found and closed

**Measured, not heard.** Everything here is measured from the game's own mix. Nobody has listened to it, and nothing here says whether the gap was audible, whether anything clicked, or whether the change sounds right. That is for the owner's ear.

## What was reported

ChatGPT, analysing the audio signal of the owner's recording of 2026-11-15 ([record](../owner-playtest-2026-11-15.md)), found about 42 ms below −65 dB at the transition. M4's own full-game recording had shown a 20 ms drop there, cause not established ([listening](../listening/README.md)). The owner's recording is an operating-system capture of real-time play; its file is not on the developer's machine.

## How it was measured

Godot's Movie Maker writes the game's own mix, so what it records is the game's output, not a recorder's. It runs frame by frame, not in real time. Captures were made of the editor build with a probe script (`probe_cut.gd`), shifting the timing a frame at a time, at 30 and 60 frames a second, letting the last line end and pressing Continue on it; and of **the exported release build** itself, driven with window-system keys on a private display, the prologue left to end, four runs each. Each measured: anything below −65 dB within half a second of the cut, and the deepest 20 ms window against the level before it. The scripts are kept here as `.txt`; every result is in [measurements.txt](measurements.txt).

## What was found

| Build | Runs with a gap below −65 dB | Its length | Deepest 20 ms dip at the cut |
|---|---|---|---|
| Editor, before | 6 of 8: all four at 30 fps, two of four at 60. Pressing Continue on the last line, measured with the first attempt below, which behaved the same: 1 of 2 | 23.0 ms at 30 fps, 12.1 to 12.3 ms at 60 | 10 to 52 dB |
| **Exported, `4fcdd6b`** | **3 of 4** | **12.3 ms** | **10.0 to 14.1 dB** |

The gap is about three quarters of a frame at either rate, and starts as the prologue's scene leaves.

**Narrowing the cause, by experiment:**

1. **Putting the game in and making it current in the same frame,** so no frame has neither scene, **changed nothing:** the same gaps, to the sample.
2. **Keeping the prologue alive half a second after the cut removed the gap** at both rates. So the prologue's own sound goes on fine; the gap is the instant it stops while the game's has not yet come up.
3. A trace in 20 ms steps shows the game's own sound coming up over about 60 to 80 ms after the cut. No clip or code fades it in on purpose.

**So: scene audio lifecycle in the game's output, not an intended fade and not the recording.** The game's positional sound is silent for part of its first frame and comes up over the next few. **Why it does that inside the engine is not established.** Whether the owner's 42 ms is this same gap, lengthened by real-time output and the capture, is likely but not shown: the owner's file was not measured here.

## What changed (D103)

Only at this cut: the game goes in and becomes current in the same frame, and the prologue stays 0.3 s, hidden and taking no input, its sound held 0.1 s while the game's comes up and then faded out over 0.15 s, and then it goes. **The voice still stops at once on Skip or Continue,** as before and as tested. The title's New Game and Continue are unchanged.

| Build | Runs with a gap below −65 dB | Deepest 20 ms dip round the cut |
|---|---|---|
| Editor, with the change | **0 of 8**, both paths, both rates | about 7 dB: the game's own ambience settling about 4 dB under the last picture's |
| **Exported, `ced2499`** | **0 of 4** | **5.5 to 6.3 dB, 0.13 to 0.24 s after the cut** |

The overlap lifts the loudest 20 ms window after the cut by about 2 dB more than before, for about a tenth of a second.

**To listen:** [cut-export-baseline.ogg](cut-export-baseline.ogg) and [cut-export-fixed.ogg](cut-export-fixed.ogg), three seconds each, the cut in the middle, from the exported runs above. **Not real-time output:** the owner's own playthrough is the test of that.

## Tested

`test_narration.gd`: at the cut, the last picture's sea and wind still play, the prologue is hidden, then gone, and the voice stopped. `test_revision.gd`: skipping leaves none of the prologue's sound in the game, now checked after the handover. Integration 440 passed, 0 failed, and the exported route `runs=4 failed=0`, on `ced2499`.
