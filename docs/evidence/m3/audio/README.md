# The first sound pass

**Status: an initial pass, brought forward from M4 and M5 by the owner ([D70](../../../decisions.md)). It is not final production audio. The developer cannot hear, so every sound here has been measured, not listened to. The owner has played builds with sound, but has not yet given a documented listening review of this pass.** Whether any of it works is the owner's ear to decide. To judge it, use [the listening package](../listening/README.md): the two voices on the same passages at the same loudness, and a recording of the game playing with its mix.

## How it was made

Every sound is synthesized by [`tools/audio/make_sounds.py`](../../../../tools/audio/make_sounds.py) from noise, oscillators, filters and a synthetic reverb, with fixed seeds. No recording, sample library or model was used, so it is original and the project's own, released with the project's assets. Running the tool again gives the same files. `--check` measures what is there and fails on clipping, DC offset or a loop that does not join. [Its last measurements](measurements.txt): 38 files, 4.1 MB, no problems. Ogg files carry a random stream serial, so regenerating changes their bytes but not their sound; unchanged files are not recommitted.

| Measured | Range |
|---|---|
| Peaks | -1.4 to -18 dBFS. Nothing near clipping |
| Loudness, as RMS | Ambience -28 to -32 dB, music -19 to -24 dB, effects -16 to -23 dB, breathing -26 to -34 dB |
| Loops | Every loop's last sample joins its first within its own typical step |

## What sounds where

**Buses:** ambience, effects, footsteps and breathing on Effects. Music on Music. Spoken lines on Narration. Each has its volume in Settings. The ducking prepared on Music and Effects for speech is still unheard.

| Scene or event | What plays | Kind |
|---|---|---|
| Prologue | A slow minor pad under one bowed line. Under its pictures: the sea at night, oars, a calm sea against the hull, the wind on the dry seabed. All of it fades over the last line | Music, ambience, effect |
| The Shore | A thin, far-off sea and wind, both positional. Wet sand underfoot. His breathing, slow and spent | Ambience, footsteps, breathing |
| The cave | Still air with a low resonance, and drips somewhere behind, with reverb. Rock underfoot. **Restrained music from the mouth,** low and sparse, starting as he enters and not looped, so it has thinned to nothing out on the seabed | Ambience, footsteps, music |
| The ritual, far off | A slow drum and a low hum, heavily distant | Effect, in its clip |
| The Exposed Abyss | Wind on open mud, a far groan now and then, mud settling. Three emitters, so it moves past him | Ambience |
| The crossing | The slab creaks, comes down hard, and debris settles | Effect |
| The Monolith | A held drone in the stone. His breathing quicker | Ambience, breathing |
| A stone accepts | A stone slides, and a soft tone holds | Effect |
| The stones reject | A grind and a thud | Effect |
| The stones answer | A low cluster that tightens and swells. The gate rises with a long rumble | Music, effect |
| The reveal | A deep swell building to the hand at 7 s. Water displaced as it rises, **then pouring off it as it stands.** Its call, deep and rhythmic, twice. The hand on the stone. His gasp | Music, effects |
| The escape | The returning sea, roaring, following him. Rock coming down, three times. His breathing, running | Effect, effects, breathing |
| The collapse | He falls. The sea comes over him | Effects |
| The ending | A restrained resolution: the same minor colour opening out, a few notes in the quiet. **Under it, the sea at night,** close and quiet, through every line and the credits | Music, ambience |

## Silence on purpose

- **No music on the Shore or across the open Abyss.** Wind, sea and footsteps carry those stretches. The cave's music is short and unlooped, so the seabed is quiet again. Music is kept for the moments it marks: the prologue, the cave, the stones answering, the reveal, the ending.
- **The watcher on the ridge and the figure in the canyon make no sound.** They are glimpsed, and a sound would point at them.
- **Nothing sounds on restoring a checkpoint** except the ambience of where he is. Tests check that no one-shot plays.

## Missing, and not to be taken for silence

- **The interface:** no sound for menus, buttons or the pause.
- **Examining:** no sound when a caption appears.
- **Spoken lines:** voice A, the owner's choice, speaks the talisman, the carving and all four lines of the epilogue. Everything else, including the fragments in the escape and the prologue, is captions until M5.
- **The mix by ear,** and every level here, which the owner may well want changed.

## How sound behaves

Each of these is tested in `project/tests/test_revision.gd` or `test_narration.gd`.

- **Pause** holds every sound, and resuming carries on.
- **Restart, scene change and quit** stop it with the world. Quitting first stops all sound, then waits a moment of real time, because the engine reports a sound still playing at shutdown as leaked ([D78](../../../decisions.md)).
- **Restore** plays no one-shot sound, and no music: an atmosphere clip restored at its end updates its values only ([D85](../../../decisions.md)).
- **No stacking:** each one-shot has its own player, which restarts rather than doubling.
- **The mix is limited at −1 dB** on the Master bus, and was measured on a recording of play: no clipping, no clicks, silence while paused ([report](../listening/mix-check.txt), [D91](../../../decisions.md)).
- **Missing audio never blocks anything:** a test takes every stream away and plays the final sequence to the ending.
- **Footsteps** follow walking, change from sand to rock where the cave begins, vary between takes, and are heavier on landing.
