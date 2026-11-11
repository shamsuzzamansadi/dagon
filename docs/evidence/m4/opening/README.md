# From the prologue into the Shore

**[opening-voiced.mp4](opening-voiced.mp4)**, 58 s, picture and sound together: New Game from the main menu, How to Play, Begin, the whole prologue at its own pace with nothing pressed, then straight into the game as he gets up, looks at his boat and at the fish, and walks on. Recorded from the game by Godot's Movie Maker (`project/tests/record_prologue.gd`), software-rendered at the game's own 480 × 270, shown at twice that size. **It is the game playing, with its real mix. It is not a person playing.** [stages.txt](stages.txt) gives the frame each stage begins at, 30 to the second: the game begins at frame 1114, 37.1 s in, and he has control at 39.4 s.

**The developer cannot hear, and has seen this only as frames.** What follows is measured from the recording or held by tests. Whether the change from picture to game is felt, whether the two Shore lines sound right, and whether the sea and wind sit well under them, are for the owner's eyes and ears.

## What changed (D97, D98)

- **How to Play comes first, on the main menu:** New Game, How to Play, Begin, the prologue, the game. Nothing stands between the last picture and the game any more. Continue shows neither, as before.
- **The last picture is the Shore itself,** as a new game opens on it, photographed from the game (`project/tests/capture_opening.gd`): the boat, the rock, the sea far out, and him asleep beside the boat, then sitting up as the line says "When I woke".
- **The game opens on him sitting there, and he gets up:** he reaches for the lantern, takes it, and stands, in 2.2 s. Then the game is the player's. Only a new game does this. Continue and Restart Checkpoint find him on his feet.
- **The last picture sounds like the Shore:** the same sea and wind, at the level the game has where he wakes, and they are no longer faded out, so the game carries on from them. The prologue's music still fades out over the last line.
- **The Shore's first two lines are spoken,** in voice A: the boat and the fish.

## The cut, measured on the recording

Frames either side of it: [the last frame of the picture](last-picture.png), [the first frame of the game](first-frame-of-the-game.png).

| Compared, above the card (rows 0 to 214 of 270) | Largest difference, of 255 | Pixels differing by more than 4 |
|---|---|---|
| **The last frame of the picture and the first of the game** | **5** | **14 of 103,200** |
| Two frames of the game 1.1 s apart, as he reaches for the lantern, for scale | 230 | 6,882 |

The recording is JPEG-compressed, which accounts for differences of that size. Below row 215 the prologue's card goes and the Shore's foreground shows.

| Sound, RMS in half-second steps | −1.5 s | −1.0 s | −0.5 s | the cut | +0.5 s | +1.0 s |
|---|---|---|---|---|---|---|
| With the card moved, but the last picture's sound still faded out: an intermediate build of this work, not a commit | −60.5 | −65.4 | −68.3 | −35.0 | −34.9 | −36.7 |
| **Now** | **−34.9** | **−34.8** | **−32.9** | **−35.0** | **−34.9** | **−36.7** |

dBFS. In that intermediate build the prologue faded to silence and the Shore's sea and wind started from nothing, a jump of 54 dB within 20 ms. At `2ccde53` the How to Play card stood there, over a silent, paused game. **Now there is no sudden change at the cut,** by `tools/audio/listening.py check` ([report](mix-check.txt)): the only one in the recording is its own end. Peak −2.8 dBFS, true peak −2.8 dBTP, no clipping, no clicks. The sea and wind do not continue sample for sample, as the picture's players and the game's are different players of the same loops; whether that can be heard is a listening judgment.

## The voice over the prologue, measured again

The last picture's bed changed, so the whole measurement was made again, by `listening.py narration` from three recordings of the same run ([report](narration-check.txt), method in [the prologue's record](../prologue/README.md)):

| Line | Voice | Beneath it | Ducked by | Voice above it |
|---|---|---|---|---|
| `prologue.raider` | −20.9 LUFS | −37.0 dB | 4.7 dB | **13.9 dB** |
| `prologue.escape` | −20.9 LUFS | −32.2 dB | 4.9 dB | **9.1 dB** |
| `prologue.drift` | −21.2 LUFS | −35.3 dB | 5.3 dB | **11.9 dB** |
| `prologue.dry` | −20.6 LUFS | −34.4 dB | 4.4 dB | **11.6 dB** |

The last line had 18.9 dB before, over a bed that was fading away. It has 11.6 dB now, over the Shore's sea and wind held level.

**Not measured:** the two Shore lines against the Shore's ambience. That ambience is placed in the world and changes as he walks, and the tool measures only the prologue's lines. Their files are at the same level as every other line, −24.0 dB RMS, and the Music and Effects buses duck for them as for any line. The whole mix is measured again in M4's audio work, with a fresh recording for listening.

## What the tests hold

`project/tests/test_opening.gd`, new, and the changed tests of the title, the controller, the prologue and the route, all in the integration suite:

- New Game writes the save first, then shows How to Play on the main menu, not paused, with the keys or buttons of the device in use. Begin, by Enter, Space, Esc or a controller's A, starts the prologue at its first line, and the same press does not move the prologue on.
- Finishing the prologue, pressing through it and skipping it all open the same game: at the Shore, with nothing over it and nothing paused, on him getting up, and the same save.
- While he gets up, keys do nothing and are not saved up; a jump key pressed then does not jump. No prompt shows. Control comes within the clip's 2.2 s, he stands exactly as he idles, where he started, and then he walks. The save and the checkpoint are untouched.
- **Continue never shows any of it,** at the Shore or later. Restart Checkpoint never does, after he is up or while he is getting up.
- Pausing holds it, and resuming finishes it.
- **The picture cannot hold the game:** with no clip he simply stands and the game is the player's, with the error the contract reports; a clip that sticks is ended by the watchdog and he is handed over standing; a pose shows only while control is locked and never outlives it.
- The last picture is the game's size, its two pieces are where he starts, and the card sits under him. He is asleep as the last line begins and sitting before it ends.
- The last picture's sea and wind are the Shore's own streams and hold their level through the last line, while the music fades.
- Every recording named in [the narration record](../narration/README.md) exists, plays under its own caption, and no other line has one.

Headless runs have no screen and no audio device. These prove what the game does and when. The recording is what shows it.

## One thing done for the checks, not for players

`tools/export_check.sh` and the package smoke test start New Game with nobody there and count frames, not seconds: 300 of them, which a headless run gets through in well under the 2.2 s he takes to get up. **With `DAGON_AUTOSTART` set, he is already standing.** Nothing else about those checks changed. The exported route (`tools/route_check.py`), which plays the shipped build with real key presses in real time, waits for him to get up like a player.
