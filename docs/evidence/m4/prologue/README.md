# The prologue, spoken

**[prologue-voiced.mp4](prologue-voiced.mp4)**, 44 s, picture and sound together: New Game from the main menu, then the whole prologue at its own pace with nothing pressed, each of its four lines in voice A over its own picture, then the game's first moments. Recorded from the game by Godot's Movie Maker (`project/tests/record_prologue.gd`), software-rendered at the game's own 480 × 270, shown at twice that size. The file was first committed at 480 × 270; this double-size copy was made from that file, not from the raw recording, with its sound stream copied unchanged. **It is the game playing, with its real mix. It is not a person playing.** [stages.txt](stages.txt) gives the frame each stage begins at, 30 to the second.

**This recording is of `2ccde53`, before the prologue was joined to the Shore.** The How to Play card still comes between the last picture and the game, and the game is silent under it. [The recording of the joined opening](../opening/README.md) replaces it for listening; this one is kept as the record of the first measurement.

**The developer cannot hear.** What follows is measured. Whether the voice sounds right over these pictures, and whether the music and the sea sit well under it, are for the owner's ear.

## What was measured

By `tools/audio/listening.py narration`, from three recordings of the same run: the game's real mix, the voice alone (music and effects muted), and the music and effects alone (the voice silent, so nothing ducks for it). The run is rendered from the same first sample each time, so the real mix less the voice alone is what plays beneath the voice. Where nobody speaks, that difference matches the third recording to within −39 dB, which is the check that the subtraction holds. [Full report](narration-check.txt).

| Line | Spoken for | Voice | Beneath it | Ducked by | Voice above it |
|---|---|---|---|---|---|
| `prologue.raider` | 7.0 s | −20.8 LUFS | −37.1 dB | 4.8 dB | **14.0 dB** |
| `prologue.escape` | 7.5 s | −20.9 LUFS | −32.1 dB | 4.9 dB | **8.9 dB** |
| `prologue.drift` | 7.9 s | −21.2 LUFS | −35.4 dB | 5.3 dB | **11.9 dB** |
| `prologue.dry` | 3.6 s | −20.6 LUFS | −41.8 dB | 4.2 dB | **18.9 dB** |

"Beneath it" and "ducked by" are RMS levels while the voice is speaking. The music and each picture's sound keep playing under every line: none is silent beneath the voice, and each is 4 to 5 dB lower than it would be with nobody speaking, which is the Music and Effects buses ducking for the Narration bus, as in M3.

**One change came from this measurement.** As first recorded, the voice was only 6.0 dB above what played beneath the escape line, against 9 to 15 dB for the others. Lowering that picture's oars and sea by 4 dB moved it by 0.3 dB: the music, which swells there, was what was close to the voice. **The prologue's music was lowered by 3.5 dB, from −4 to −7.5 dB.** The oars and the sea are as the owner heard them in M3. The last line's bed is lowest because the music and the wind fade out over it, as before (D91).

The mix as a whole ([report](mix-check.txt)): peak −2.9 dBFS, true peak −2.9 dBTP, no clipping, no clicks. Each line's stretch sits between −20.8 and −21.8 LUFS. Two sudden changes, both expected: the Shore's ambience starting from silence when the How to Play card is answered, which the next piece of work removes, and the end of the recording.

## What the tests hold

`project/tests/test_narration.gd`, in the integration suite:

- Every prologue line has its own recording, plays on the Narration bus under its own words, over its own picture and no other, with the music and that picture's sound still playing.
- The card does not move on before the voice could have ended, pressed or not. Left alone, each line gives way only after its whole recording.
- Continue moves on, and the next recording replaces the last. Continue on the last line starts the game.
- Skip, on any of the four lines, stops the voice at once and starts the game. No narration is playing in the game after either.
- The existing prologue tests are unchanged and pass: the save is written first, Continue from the main menu never shows the prologue, finishing, pressing through and skipping reach the same state, and no sound of a picture carries into the next or into the game.

Headless runs have no audio device, so these prove what is asked of the audio and when. They do not prove how anything sounds.
