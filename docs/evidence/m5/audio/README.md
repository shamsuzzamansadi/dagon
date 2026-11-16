# M5's audio review: the reveal, the flight and the ending

**Everything here is a measurement or a transcript. Nobody has listened to any of it.** The developer cannot hear. A local speech recogniser wrote the transcripts. What any of it sounds like is the owner's to judge, from the [listening package](../listening/README.md).

**One change was made,** to two sounds in one clip (D112). No bus, limiter, ducking or master level was touched, no other sound was made again, and no line was recorded again.

## How it was measured

`project/tests/record_finale.gd` plays from the Awakened checkpoint through the reveal, the flight, the fall and the whole epilogue with nothing pressed, and Movie Maker records it with the game's sound. It marks each spoken line as it starts. The same run is recorded three times: the game's mix, the voice alone (music and effects muted), and the bed alone (the voice silent, so nothing ducks). Movie Maker renders each from the same first sample, and the three runs' marks fall on the same frames, so the mix less the voice is what played beneath each line.

| Tool | Says |
|---|---|
| `tools/audio/listening.py narration` | Each line's level, what is beneath it across the whole spectrum, and how far the bed ducks |
| `tools/audio/voice_band.py` (new) | The same, within 300 to 4000 Hz, where speech is understood |
| `tools/audio/listening.py check` | Peak, loudness by stage, sudden changes, clicks |
| `tools/audio/limiter_use.py` (new) | How much of each stage sits at the Master limiter's ceiling |
| `tools/audio/check_narration.py --folder` | What a recogniser hears in each line, cut from the voice-alone recording of the game |

## Found, and what was done

| Asked | Measured | Done |
|---|---|---|
| **Excessive masking** | Across the whole spectrum, the reveal's three lines and the flight's first stand **between 3.1 dB below and 1.8 dB above** what plays under them ([table](finale-narration-after.txt)); the tool flags anything under 6 dB. Most of that bed is below 300 Hz: the surge's and the music's sub-bass and the call's low voice. **Within the voice's band** ([before](finale-band-before.txt)) "It was no ridge. It had been beside me the whole way." stood **2.7 dB** above its bed, and 2.3 dB below it in its worst half second; the other lines 6.7 to 17.2 dB above | **The water's cascade and surge, both loudest as that line begins, are keyed 7 and 5 dB lower from 4.3 s of the reveal's clip,** and put back at its end. The line now stands **6.0 dB** above its bed in band, its worst half second 1.0 dB above ([after](finale-band-after.txt)). The reveal as a whole measures −18.0 LUFS, from −17.4; its loudest three seconds −16.6, from −15.6. **Left as it was:** "Its head turned. I ran." stands 6.7 dB above its bed in band, and 4.0 dB below it for half a second as the creature's second call swells |
| **Overlapping speech** | One player speaks every line in play and one in the epilogue, and a line replaces the line before it, so two cannot sound together. Each line's last sound falls before the next begins: by 0.4 s and 0.25 s in the reveal, and 3.3 s from its last line to the flight's first; 1.6 s and 0.75 s in the flight (the fall came 0.75 s after "The sea is coming back." in this run, which runs without stopping); 1.7, 1.6, 1.8 s in the epilogue | Nothing |
| **Complete spoken lines** | **Nine lines of nine word for word,** cut from the game's own voice-alone recording ([transcripts](finale-transcripts.txt)), "Innsmouth" being the exception recorded in M3 | Nothing |
| **Clipping** | None. Peak −1.2 dBFS in the whole game after the change. Before it, the limiter was reached in one 10 ms window of the whole game, at the hand's impact; now in none ([by stage](finale-limiter.txt)) | Nothing more |
| **Abrupt transitions** | From the reveal into the flight, the flight into the fall, the fall into the epilogue, between its pictures and into the credits: **no change of more than 30 dB within 20 ms, and no isolated sample step** ([report](finale-mix-check.txt)). In the whole game the only sudden changes are the menu's knocks from silence, the pause, and the recording's end ([report](../listening/mix-check.txt)). **M4's drop at the cut into the game does not appear** | Nothing |
| **Voice A, the ducking, the prologue-to-Shore handover** | Unchanged: no narration file, bus or `MenuController` code differs from `main` | Nothing |

## GDD §7's Witness row, against what plays

| The design | In the game |
|---|---|
| A sub-bass swell | The surge's 33 Hz swell from 1.5 s; the music's low note building to 7 s |
| A low-pass sweep that opens up | The reveal's music: its brass crossfades from a 220 Hz to a 1400 Hz filter as it builds |
| A roar built from layered processed sources | The creature's call at 3.3 s (25 partials, a growl, two formants, breath, a hall) and again as its head turns; the water's cascade from 3 s |
| Silence at the collapse | The fall is the game's quietest stretch after the reveal, −25.0 LUFS, the sea's rush over it; then the epilogue |

## What sounds when: the reveal, the flight, the fall, the epilogue

Times in seconds from each clip's start. In the full recording the reveal begins at 3:40.9, the flight at 3:55.0, the epilogue at 4:10.9.

| | At | Sound | Level in the scene |
|---|---|---|---|
| **Reveal** | 0.05 | Music, building to 7 s | −4 dB, Music |
| | 1.5 | The surge, as the ridge stirs | −4 dB, **−9 dB from 4.3 s** |
| | 3.0 | The cascade, as the body comes out of the fog | −6 dB, **−13 dB from 4.3 s** |
| | 3.3 | Its call | −3 dB |
| | 4.3 | *"It was no ridge. It had been beside me the whole way."* | Narration |
| | 7.0 | The hand on the stone; his gasp; vibration | −3 dB |
| | 8.2 | *"The carving. The same arm, round the same stone."* | Narration |
| | 11.4 | Its call again, as the head turns | 0 dB |
| | 12.2 | *"Its head turned. I ran."* | Narration |
| **Flight** | 0 | The returning sea's roar, following him | at its place |
| | 0.8, 2.6, 5.4 | Three blocks coming down | at their places |
| | 3.2 | *"Don't look back. Don't..."* | Narration |
| | 6.8 | *"The sea. The sea is coming back."* | Narration |
| **Fall** | 0.6 | His body; vibration at 0.9 | 0 dB |
| | 2.4 | The sea over him | 0 dB |
| **Epilogue** | 0 | Music and the night sea, under four spoken lines | −3 dB, −6 dB |

## Not done, and why

- **The reveal's level and the mix were to be set by the owner's ear in M4, and still are.** No listening is recorded from anyone. M5 moved two sounds by measurement and nothing else.
- **"Its head turned. I ran." under the second call:** measured, left, and listed for the owner's ear.
