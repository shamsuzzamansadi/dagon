# The listening package

**For the owner's ears. It is outside the game: nothing here is in the build, and none of it is reachable from the game's menus.** It is made from the game's own assets and from a recording of the game playing.

**I cannot hear.** Everything below marked *measured* was measured by `tools/audio/listening.py` and `tools/audio/make_sounds.py --check`. Nothing here has been listened to by anyone on the project except where the owner has said so. Whether the voice is right, and whether the mix works, are judgments only a person listening can make.

## 1. The voice: A or B, the same words at the same loudness

| File | Candidate | Passage |
|---|---|---|
| [voice-A-shore.talisman.ogg](voice-A-shore.talisman.ogg) | A: Chatterbox in the timbre of Kokoro's stock `am_onyx`, lower, American | The talisman, on the Shore |
| [voice-B-shore.talisman.ogg](voice-B-shore.talisman.ogg) | B: Chatterbox in the timbre of Kokoro's stock `bm_george`, older, British | The same |
| [voice-A-ending.innsmouth.ogg](voice-A-ending.innsmouth.ogg) | A | The epilogue's third line, Innsmouth |
| [voice-B-ending.innsmouth.ogg](voice-B-ending.innsmouth.ogg) | B | The same |

*Measured:* each set to −23.0 LUFS integrated (ITU-R BS.1770), true peak −2.3 to −7.7 dBTP, so neither wins by being louder. As made, they were already within 0.4 LU of each other. The full audition, its rights and its watermark are in [../voice-audition/](../voice-audition/README.md).

**The question for the owner: A, B, a person reading, or neither?** Then the rest of the epilogue, three lines, is spoken in that voice first. Nothing more is generated before that choice.

## 2. The mix, during play

**[in-game-capture.mp4](in-game-capture.mp4)**, 5 min 23 s, picture and sound together, recorded by Godot's Movie Maker from the game itself (`project/tests/record_play.gd`). It is the game playing, with its real mix. **It is not a person playing:** a script plays the route, reads everything it passes and lets each line run to its end, pauses once on the Shore, pushes one wrong stone, runs from the sea, then Continues and stands still until the sea comes. Software-rendered, at the game's own 480 × 270, shown at twice that size.

The same soundtrack, cut by stage:

| File | What to listen for |
|---|---|
| [mix/01-opening-prologue.ogg](mix/01-opening-prologue.ogg) | The whole prologue, unskipped: its music, the sea, the oars, the calm, the wind, fading out as the game begins |
| [mix/02-shore.ogg](mix/02-shore.ogg) | Sea, wind, wet sand underfoot, his tired breathing, the talisman's voice (A) |
| [mix/03-pause-and-resume.ogg](mix/03-pause-and-resume.ogg) | Pausing and resuming, with 4 s either side: everything stops, then comes back |
| [mix/04-cave.ogg](mix/04-cave.ogg) | The cave's air and drips, its restrained music, rock underfoot, the carving's voice (A) |
| [mix/05-seabed-and-crossing.ogg](mix/05-seabed-and-crossing.ogg) | The seabed, the ritual far off, the climb, the stone pushed and the slab coming down |
| [mix/06-stones-and-gate.ogg](mix/06-stones-and-gate.ogg) | The Abyss to the Monolith, a wrong stone, the right ones, the stones answering, the gate |
| [mix/07-reveal.ogg](mix/07-reveal.ogg) | The water, the cascade, its call, the hand on the stone, his gasp, the music |
| [mix/08-escape-running.ogg](mix/08-escape-running.ogg) | The roar behind him, the rock, his breathing, the fall, the sea over him |
| [mix/09-ending.ogg](mix/09-ending.ogg) | Music and the sea under the four lines, one of them voiced, then the credits fading |
| [mix/10-escape-standing-still.ogg](mix/10-escape-standing-still.ogg) | The other outcome: standing still at the ledge until the sea comes |

## 3. What was measured, and what that does not say

*Measured on the recording's soundtrack* ([full report](mix-check.txt)):

| Check | Result |
|---|---|
| Clipping | **None.** Peak −1.0 dBFS, true peak −1.0 dBTP. The first recording clipped in the reveal, at +0.1 dBTP; the Master bus now has a −1 dB limiter and the reveal's sounds were lowered |
| Loudness by stage | Ambience −24 to −32 LUFS; the cave with its music −24; the stones answering −21.5; **the reveal −15.6**, the loudest, and the escape −18.5; the ending −23. The reveal is about 15 LU above the quiet stretches: contrast by design, and the first thing to judge by ear |
| Sudden changes, over 30 dB in 20 ms | **Two expected:** the pause cutting everything, and coming back. **Two starts from silence:** the Shore's ambience when the game begins after the introduction card, and the game again after Continue. **No cut** at the end of the prologue or of the ending any more: both now fade first. The first recording had both |
| Clicks, single-sample steps | None found |
| While paused | Silence, −120 dBFS |
| The main menu after the ending | Silent: the main menu has no music, by design |

*Measured on the files* ([measurements](../audio/measurements.txt)): 40 files, no clipping, no DC offset, every loop joining within its own typical step.

*Tested by the integration suite:* pause holds every sound and resuming carries on; restart, scene change and quit stop it; restore plays no one-shot and no music; one-shots restart rather than stack; with every stream removed, the final sequence still reaches the ending; Music, Effects and Narration volumes; only one line is spoken at a time, a new one stopping the last; moving on in the epilogue stops its line, and the credits stop it; each prologue picture's sound starts and stops with it, and none carries into the game.

**None of this says whether anything sounds good,** whether the levels feel right, whether the voice suits him, or whether the reveal is too loud or not loud enough. Those are listening judgments.

## Who has evaluated what

| Who | What |
|---|---|
| The developer (Claude) | **Cannot hear.** Made every sound by synthesis, measured the files and the mix, wrote the tests above. No listening judgment |
| The owner | **Has played builds with sound,** including `5fe820b` and a build of `53e8d23`, and judged the earlier narration voice noticeably synthetic. **No documented listening review of this sound pass, of candidates A and B, or of this package yet** |
| ChatGPT | Reviewed sampled video frames of the game and of the owner's illustrated reference. **Did not evaluate the soundtrack** |
