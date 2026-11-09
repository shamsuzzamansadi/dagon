# The first sound pass

**Status: an initial pass, brought forward from M4 and M5 by the owner ([D70](../../../decisions.md)). It is not final production audio. The developer cannot hear, so every sound here has been measured and never listened to.** Whether any of it works is the owner's ear to decide.

## How it was made

Every sound is synthesized by [`tools/audio/make_sounds.py`](../../../../tools/audio/make_sounds.py) from noise, oscillators, filters and a synthetic reverb, with fixed seeds. No recording, sample library or model was used, so it is original and the project's own, released with the project's assets. Running the tool again gives the same files. `--check` measures what is there and fails on clipping, DC offset or a loop that does not join. [Its last measurements](measurements.txt): 35 files, 3.6 MB, no problems.

| Measured | Range |
|---|---|
| Peaks | -1.4 to -18 dBFS. Nothing near clipping |
| Loudness, as RMS | Ambience -28 to -32 dB, music -19 to -24 dB, effects -16 to -23 dB, breathing -26 to -34 dB |
| Loops | Every loop's last sample joins its first within its own typical step |

## What sounds where

**Buses:** ambience, effects, footsteps and breathing on Effects. Music on Music. Spoken lines on Narration. Each has its volume in Settings. The ducking prepared on Music and Effects for speech is still unheard.

| Scene or event | What plays | Kind |
|---|---|---|
| Prologue | A slow minor pad under one bowed line | Music |
| The Shore | A thin, far-off sea and wind, both positional. Wet sand underfoot. His breathing, slow and spent | Ambience, footsteps, breathing |
| The cave | Still air with a low resonance, and drips somewhere behind, with reverb. Rock underfoot | Ambience, footsteps |
| The ritual, far off | A slow drum and a low hum, heavily distant | Effect, in its clip |
| The Exposed Abyss | Wind on open mud, a far groan now and then, mud settling. Three emitters, so it moves past him | Ambience |
| The crossing | The slab creaks, comes down hard, and debris settles | Effect |
| The Monolith | A held drone in the stone. His breathing quicker | Ambience, breathing |
| A stone accepts | A stone slides, and a soft tone holds | Effect |
| The stones reject | A grind and a thud | Effect |
| The stones answer | A low cluster that tightens and swells. The gate rises with a long rumble | Music, effect |
| The reveal | A deep swell building to the hand at 7 s. Water displaced as it rises. Its call, deep and rhythmic, twice. The hand on the stone. His gasp | Music, effects |
| The escape | The returning sea, roaring, following him. Rock coming down, three times. His breathing, running | Effect, effects, breathing |
| The collapse | He falls. The sea comes over him | Effects |
| The ending | A restrained resolution: the same minor colour opening out, a few notes in the quiet | Music |

## Silence on purpose

- **No music on the Shore, in the cave or across the Abyss.** Wind, sea and footsteps carry those stretches, and the music is kept for the moments it marks: the prologue, the stones answering, the reveal, the ending.
- **The watcher on the ridge and the figure in the canyon make no sound.** They are glimpsed, and a sound would point at them.
- **Nothing sounds on restoring a checkpoint** except the ambience of where he is. Tests check that no one-shot plays.

## Missing, and not to be taken for silence

- **The interface:** no sound for menus, buttons or the pause.
- **Examining:** no sound when a caption appears.
- **The prologue:** no sea, ship or oar sounds under its pictures. Only its music.
- **The reveal:** the body rising and the water running off it have no sound of their own beyond the surge.
- **Spoken lines:** only the three audition lines have a voice. Everything else, including the fragments in the escape and the prologue, is captions until a voice is chosen.
- **The mix by ear,** and every level here, which the owner may well want changed.

## How sound behaves

Each of these is tested in `project/tests/test_revision.gd` or `test_narration.gd`.

- **Pause** holds every sound, and resuming carries on.
- **Restart, scene change and quit** stop it with the world. Quitting first stops all sound, then waits a moment of real time, because the engine reports a sound still playing at shutdown as leaked ([D78](../../../decisions.md)).
- **Restore** plays no one-shot sound.
- **No stacking:** each one-shot has its own player, which restarts rather than doubling.
- **Missing audio never blocks anything:** a test takes every stream away and plays the final sequence to the ending.
- **Footsteps** follow walking, change from sand to rock where the cave begins, vary between takes, and are heavier on landing.
