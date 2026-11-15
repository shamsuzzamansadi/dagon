# The owner's playtest of 2026-11-15, and ChatGPT's analysis of the owner's recording

**Recorded as relayed to the developer on 2026-11-15.** The owner's words are summarised, limited to what was said.

## The owner

- The overall gameplay feels good and has improved substantially.
- **The main visible problem:** the sailor is difficult to distinguish inside the boat during the prologue.
- **This is not explicit acceptance of the final M4 build.**

Which build the owner played is not stated in the message. The last build named for the owner before it was `dagon-windows` from run 43503636921, the push run of `4fcdd6b` (zip SHA-256 `1ec506451d71dd0072473f8fe6cd15d691b9e2aa9487ed19e67f8e9883aded8a`).

## ChatGPT, on the owner's recording `20261115-1457-33.7080549.mp4`

**ChatGPT inspected sampled visual frames across the recording and analysed the audio signal. It did not listen to the soundtrack, approve the mix, or verify every spoken word.** It reported:

- About **42 ms below −65 dB around 00:35.398 to 00:35.440**, coinciding with the transition from the prologue into the game.
- The recording measures about **−26.8 LUFS with a −14.7 dBFS peak.** The recording's gain is unknown, so this says nothing about the game's own level, and the master volume is not raised because of it.
- **During the reveal, the straight background boundary is visible.**

The recording itself is not on the developer's machine and is not in the repository; nothing here was measured from it by the developer.

## What was done about it

- The sailor in the boat: [prologue-readability](prologue-readability/README.md).
- The gap at the transition: [transition](transition/README.md).
- The reveal's boundary, and the creature's separation from the background: **open, M5** ([roadmap](../../roadmap.md)).

## The owner's second report, later on 2026-11-15

**The owner, in their words as relayed:**

- **Personally tested** the improved sailor readability and the prologue-to-Shore audio transition: **both improvements are present.**
- **Has not yet tested the Skip case.**
- **Noticed that the stone gate no longer visibly rises after the final puzzle.**
- **This is not final build acceptance.** The merge and the first pre-alpha release, already authorized, stay conditional on resolving this finding and the owner's final acceptance.

The build was the candidate then named: `dagon-windows` from run 43731646562, the push run of `ced2499`.

**ChatGPT**, from the owner's gameplay recording and the source at `4b959cf`, found the cause: the awakening clip's track targets `Monolith/Gate/Visual:position`; `Visual` is hidden; the visible slab is `Monolith/Gate/Drawn`, its sibling, which does not inherit the movement; and `GameDirector::open_gate()` separately disables the collision and hides the gate. What was done: [gate](gate/README.md).

## The owner's third report, later on 2026-11-15

**The owner, in their words as relayed:**

- **Personally tested** the closed gate and the restored gate-opening behaviour: **both are satisfactory.**
- The owner's second gameplay video shows the prologue's Skip reaching the Shore and gameplay continuing.
- **This is not yet explicit acceptance of the entire release candidate.**

The message does not name the build. The candidate named for the owner before it was `dagon-windows` from run 43738445550, the push run of `8b30b33`.

**ChatGPT inspected frames from both of the owner's videos.** The Skip path is confirmed **visually:** it reaches the Shore and play goes on. **ChatGPT did not listen to the audio, so nothing about the sound at the Skip, or anywhere else, is recorded as passed.** The videos are not on the developer's machine; nothing here was seen or measured by the developer.

**The ending's pictures, for M5** (the four panels `Found`, `Listen`, `Shop` and `Rising` of `ending.tscn`); listed in the [roadmap](../../roadmap.md), not changed in M4:

1. **The rescue:** the small boat looks empty.
2. **The window:** the sailor's head, shoulders and anxious posture are unclear, and there are ambiguous marks.
3. **Innsmouth:** the line says bracelet; the picture reads as a rectangular plaque or box.
4. **The last sea:** the crest does not recognisably match the creature of the reveal.
5. The four panels differ in style, framing and level of detail.

**The owner advances the later ending cards quickly in the recording.** That is the owner's pressing, not a finding: no timing or cut-off narration defect is recorded from it, and none has been reproduced.
