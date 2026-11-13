# M4's listening package: the whole game, with its sound

**For the owner's ears. Outside the game: nothing here is in the build.** M4's plan gives the reveal's level and the mix to the owner's listening (item 4). This is what to listen to.

**The developer cannot hear, and has seen this only as frames.** Everything marked *measured* was measured by `tools/audio/listening.py`. Nobody on the project has listened to any of it.

## The recording

**[m4-full-game.mp4](m4-full-game.mp4)**, 5 min 39 s, picture and sound together, recorded by Godot's Movie Maker from the game at `e24d726` (`project/tests/record_play.gd`, on a private display, software-rendered at 960 × 540, 30 frames a second). **It is not a person playing:** a script plays from the main menu, lets the prologue run, reads everything it passes and lets each line finish, pauses once on the Shore, solves the stones with one deliberate mistake, runs from the sea to the ending and the credits, then Continues and stands still until the sea comes. Its stages and frames are in [stages.txt](stages.txt).

Everything M4 added is in it: the prologue spoken and joined to the Shore, the waking, all of item 3's art, the menu and examine sounds, the Abyss's three beds, the heavier rock and sea, and every story line spoken.

## The same soundtrack, cut by stage

| File | What to listen for |
|---|---|
| [mix/01-opening-prologue.ogg](mix/01-opening-prologue.ogg) | The prologue's four lines over its music and sea, and the join into the game |
| [mix/02-shore.ogg](mix/02-shore.ogg) | Sea and wind, wet sand, his breathing; the boat, the fish and the talisman spoken, each with the examine sound under it |
| [mix/03-pause-and-resume.ogg](mix/03-pause-and-resume.ogg) | Pausing and resuming: the menu's knock, everything stopping, the menu's going-back sound, everything coming back |
| [mix/04-cave.ogg](mix/04-cave.ogg) | The cave, its music, the carving spoken |
| [mix/05-seabed-and-crossing.ogg](mix/05-seabed-and-crossing.ogg) | The open mud; the ritual far off, spoken; the stone pushed, the slab down, spoken |
| [mix/06-stones-and-gate.ogg](mix/06-stones-and-gate.ogg) | **The Abyss deepening:** the open mud, the deeper mud with its slow swell, the canyon; the Monolith spoken; a wrong stone, the right ones, the stones answering, spoken; the gate |
| [mix/07-reveal.ogg](mix/07-reveal.ogg) | **The reveal, loudest in the game:** water, cascade, its call, the hand on the stone, his gasp, the music, and its three lines |
| [mix/08-escape-running.ogg](mix/08-escape-running.ogg) | **The heavier rock and sea:** the roar behind him, three blocks coming down, the two lines, the fall, the sea closing over him |
| [mix/09-ending.ogg](mix/09-ending.ogg) | The epilogue's four spoken lines over its music and sea, the credits fading |
| [mix/10-escape-standing-still.ogg](mix/10-escape-standing-still.ogg) | The other outcome: standing still until the sea comes |

## Measured

On the recording's soundtrack ([full report](mix-check.txt)): `MIX_CHECK problems=0`.

| Check | Result |
|---|---|
| Clipping | **None.** Peak −1.0 dBFS, true peak −1.0 dBTP: the Master bus's limiter, as in M3 |
| Loudness by stage, integrated | Prologue −21.5 LUFS, the Shore −21.3, the cave −23.3, the seabed −26.8, the crossing to the stones −25.8, the stones answering −19.9, **the reveal −17.4** (loudest 3 s −15.6), **running −18.3** (loudest 3 s −14.6), the ending −21.1, the credits −36.9. In M3's recording the reveal was −15.6 and running −18.5: the reveal is a little quieter overall now that its lines are spoken, the run's loudest moments louder |
| Clicks, single-sample steps | None |
| While paused, and on the main menu after the ending | Silence, −120 dBFS |
| Sudden changes, over 30 dB within 20 ms | Eight. **Expected:** the menu's knocks starting from silence on New Game (1.5 s), Begin (3.5 s) and the main menu (305.5 s); coming back from the pause (68.7 s); the recording's end. **Not expected:** a 20 ms drop to −88 dB exactly at the cut from the prologue into the game (36.6 s), below |

**The drop at the cut.** For about 20 ms, the length of one buffer, the sound falls from −36 to −88 dB and comes back, at the frame the prologue's scene gives way to the game's. The opening recorded again at the same commit with `record_prologue.gd`, the tool item 2 measured it with, has **no** drop there ([report](opening-recheck.txt)): its only sudden changes are the knock on New Game and its own end. Both scripts let the prologue end by itself. So it comes and goes between recordings of the same build, and **its cause is not established.** Whether it can be heard is for the owner's ear; if it can, it is the change of scene, which M4 did not touch after item 2.

**What this does not say:** whether anything sounds right, whether the voice sits well over the music, whether the reveal is too loud or the run too heavy, whether the menu and examine sounds are welcome. Those are the owner's, and the plan sets the mix from the owner's notes.
