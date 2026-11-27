# M7 listening kit: the reveal by ear, from `b271316`

For the owner (M7 plan, item 2, as approved on 2026-11-27: [record](../../evidence/m7/plan-approval-2026-11-27.md)). The question: **is each of the reveal's three spoken lines understood in the full mix,** on headphones and on speakers? Above all the third, which comes over the creature's second call. It has been open since M5.

**Please do step 1 before opening anything else in this folder.** The words are only in step 2, so that what you report is what you heard, not what you read.

## Step 1: listen, and note what you understood

1. **[1-reveal-full-mix.wav](1-reveal-full-mix.wav), 17.4 s.** The game's own mix of the walk into the reveal and the whole reveal, as it plays: music, effects and voice together, with nothing added or taken away. Optional, for context: the same moment as a video with the captions hidden, [1-reveal-full-mix-no-captions.mp4](1-reveal-full-mix-no-captions.mp4).
2. Listen **once on headphones and once on speakers,** at the volume you would play at. You can listen more than once; please note how many times.
3. Fill in the [listening sheet](listening-sheet.md): what you understood of each line, in your own words, and how easily.
4. Send the sheet as it is, **before step 2.**

**What it is:** recorded from the game at `b271316`, the game in `v0.2.0-alpha.2`, by Godot's Movie Maker on a private display, from the last checkpoint (scripted, not played). The game writes 32-bit samples; this file keeps their top 16 bits so that any player opens it. Its peak is 1.3 dB below full scale, so nothing clips. **Nobody has listened to it yet;** the developer cannot hear.

**Use this clip, not M6's.** M6's kit was recorded at `a4250f0`. The reveal's sounds, lines and mix settings are unchanged since then. Recorded voice-only, each of the three lines is identical sample for sample in both takes. But on `b271316` the walk into the reveal is 5 frames (0.17 s) shorter, because M6 moved the Awakened checkpoint clear of the statue (D127). So the continuous sounds beneath the lines fall at a slightly different point, and the full mix differs sample by sample, though the loudness of each part is within 0.5%. This clip is the submission build's own. Two takes on `b271316` gave byte-identical sound.

## Step 2: only after reporting

The folder [after-you-report](after-you-report/README.md) holds the three lines' words with their times, and the voice alone, with the music and effects muted. The second step compares what you heard with the words. The voice alone shows what each line sounds like without what plays beneath it.

## Where the lines fall in the file

| | At about | Notes |
|---|---|---|
| The reveal begins | 2.8 s | The walk before it fills the first 2.8 s |
| The creature's first call | 6.1 s | |
| **Line 1** | **7.1 s** | |
| **Line 2** | **11.0 s** | |
| The creature's second call | 14.2 s | |
| **Line 3** | **15.0 s** | **Over the second call: the line M5 left flagged** |

The lines' times come from the game's own record of when each line starts, and the calls' times from their fixed places in the reveal. The lines are spoken in one synthesized voice.

## After your sheet

- **Every line understood, on both:** the check is recorded as passed, in your words, on this clip.
- **A line not understood, or understood only with effort:** the developer brings you the specific finding (which line, on headphones or speakers, and what you heard) and **the smallest proposed fix.** That would be one targeted change to the mix, such as lowering the music and the second call beneath line 3. Before-and-after takes rendered from the game come with it, for your ear; the developer cannot judge it by ear. A fix ships only as `v0.2.0-alpha.3`, after your acceptance of that build and your explicit approval to publish it. Until then `v0.2.0-alpha.2` stays the submission build, and its captions show every line.

## Optional, in the game itself

The same moment can be heard in play with the captions off: Settings, then Subtitles off, then play to the reveal. That is your choice. The sheet asks about the file above.
