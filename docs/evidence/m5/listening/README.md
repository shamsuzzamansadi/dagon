# M5's listening package: the whole game, with its sound

**For the owner's ears. Outside the game: nothing here is in the build.** Recorded from the game at `b1cb401`. **Its sound is the current candidate's, with one small exception:** from 12.0 to 13.9 s of the reveal (about 3:52.9 to 3:54.8 here) the camera now holds longer on the head, and the positional sounds that follow it differ by 35 to 65 dB below the mix; recordings of the finale from the build the owner played and from the candidate are otherwise identical, sample for sample, as the takes of 2026-11-16 and 11-18 were **One picture differs:** the window in the epilogue, from 4:27.7, shows the raised hand as it was before the independent review; the corrected one is in [the ending's record](../ending/README.md).

**The developer cannot hear, and has seen this only as frames.** Everything marked *measured* was measured by the tools named in the [audio review](../audio/README.md). **Nobody on the project has listened to any of it, in M4 or in M5.** No listening pass is claimed here.

## The recording

**[m5-full-game.mp4](m5-full-game.mp4)**, 5 min 38 s, picture and sound together, at the game's own 480 × 270, recorded by Godot's Movie Maker (`project/tests/record_play.gd`, on a private display, software-rendered, 30 frames a second). **It is not a person playing:** a script plays from the main menu, lets the prologue run, reads everything it passes and lets each line finish, pauses once on the Shore, solves the stones with one deliberate mistake, runs from the sea to the ending and the credits, then Continues and stands still until the sea comes. [stages.txt](stages.txt) has each stage's time.

The same soundtrack, cut by stage, is in [mix/](mix/), named as M4's were.

## What needs the owner's ears, and where

Times are in `m5-full-game.mp4`. Each has a measurement beside it, which is not an answer. **The in-band figures** compare the voice's power within 300 to 4000 Hz with what plays beneath it (the mix less the voice, [checked](../audio/subtraction-check.txt) to the sample). They are a diagnostic of level, not a measure of whether a line is understood, and the 6 dB the tools flag is a prompt to listen, not a threshold.

| # | At | Listen for | Measured |
|---|---|---|---|
| **1** | **3:45.2 to 3:48.7** | **The one change M5 made to the mix.** "It was no ridge. It had been beside me the whole way." Is the line clear over the water? Does the water drop noticeably as he begins to speak, and does that sound wrong? Compare [reveal-before.mp4](../reveal/reveal-before.mp4) and [reveal-after.mp4](../reveal/reveal-after.mp4), where the line begins at 0:06.3 | Within 300 to 4000 Hz the line was 2.7 dB above its bed, and is 6.0 dB above: the water is lower, which does not say the line is heard. The cascade is 7 dB lower and the surge 5 dB lower from that moment |
| **2** | **3:40.9 to 3:55.0** | **The reveal as a whole,** which M4 left to the owner's ear and nobody has heard: is it too loud, too quiet, too crowded? The surge at 3:42.4, the cascade at 3:43.9, the call at 3:44.2, the hand and the gasp at 3:47.9 | −18.0 LUFS; its loudest three seconds −16.6; the game's peak −1.2 dBFS; the limiter not reached |
| **3** | **3:52.3 to 3:54.9** | "Its head turned. I ran." under the creature's second call, which starts at 3:52.3. **Left unchanged.** Is the line heard? | In band 6.7 dB above its bed, and 4.0 dB below it for half a second |
| **4** | **3:55.0 to 4:05** | The flight: the sea's roar behind him, three blocks at 3:55.8, 3:57.6 and 4:00.4, "Don't look back" at 3:58.2, "The sea is coming back" at 4:01.8. Too heavy? Are both lines heard? | −18.3 LUFS, loudest three seconds −14.6, the loudest in the game. In band the lines are 8.2 and 10.2 dB above their beds |
| **5** | **4:05 to 4:10.9** | The fall, and the cut into the epilogue. Abrupt? | −25.0 LUFS; no sudden change |
| **6** | **4:10.9 to 5:00.5** | The epilogue: the voice over its music and the night sea, four lines at 4:10.9, 4:27.7, 4:34.9 and 4:52.4, and the fade into the credits. Now with the new pictures | In band the voice is 10.3 to 17.2 dB above its bed |
| **7** | **0:36.6** | The cut from the prologue into the game, repaired in M4 and **never listened to** | No drop at the cut in this recording |
| **8** | Throughout | **Carried from M4, not heard by anyone:** the voice in every line; the menu's sounds (0:01.5, 0:03.5, 1:06.7); the examine sound under each examined line; the Abyss's three beds from 2:00.7; the stones and the gate at 3:28.6 | [M4's package](../../m4/listening/README.md) lists them; their levels are as they were |

## Measured

On this recording's soundtrack ([full report](mix-check.txt)): `MIX_CHECK problems=0`.

| Check | Result |
|---|---|
| Clipping | **None.** Peak −1.2 dBFS, true peak −1.2 dBTP |
| Loudness by stage, integrated | Prologue −21.5 LUFS, the Shore −21.3, the cave −23.3, the seabed −26.8, the crossing to the stones −25.8, the stones answering −19.9, **the reveal −18.0** (M4: −17.4), running −18.3, the ending −21.1, the credits −36.9. **Every stage but the reveal measures as it did in M4's recording** |
| Clicks, single-sample steps | None |
| While paused, and on the main menu after the ending | Silence, −120 dBFS |
| Sudden changes, over 30 dB within 20 ms | Six, all expected: the menu's knocks from silence on New Game (1.5 s), Begin (3.5 s) and the main menu (305.5 s); coming back from the pause (68.7 s); the recording's end. **The 20 ms drop M4's recording had at the cut into the game (36.6 s) is not there** |

**What this does not say:** whether anything sounds right. That is the owner's, and the roadmap does not let audio be marked complete until a person has heard it in the game.
