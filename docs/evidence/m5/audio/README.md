# M5's audio review: the reveal, the flight and the ending

**Everything here is a measurement or a transcript. Nobody has listened to any of it.** The developer cannot hear. A local speech recogniser wrote the transcripts. What any of it sounds like is the owner's to judge, from the [listening package](../listening/README.md).

**One change was made,** to two sounds in one clip (D112). No bus, limiter, ducking or master level was touched, no other sound was made again, and no line was recorded again.

## How it was measured

`project/tests/record_finale.gd` plays from the Awakened checkpoint through the reveal, the flight, the fall and the whole epilogue with nothing pressed, and Movie Maker records it with the game's sound. It marks each spoken line as it starts. The same run is recorded three times: the game's mix, the voice alone (music and effects muted), and the bed alone (the voice silent, so nothing ducks). What played beneath each line is taken as the mix less the voice. **That the three runs' marks fall on the same frames does not show the subtraction holds,** so after the independent review it was tested on the takes behind every figure below, by `tools/audio/subtraction_check.py` ([after the change](subtraction-check.txt), [before it](subtraction-check-before.txt)):

- **Aligned to the sample.** The mix and bed-alone takes are the same, sample for sample, until the voice begins: they first differ by one 16-bit step, 0.2 ms before the voice take's first sample that is not zero, where the voice is still under one step. For all nine lines, on both channels, mix and voice correlate best at a lag of 0 samples. A take of the mix recorded again on 2026-11-18, at the review's head, is identical to the 2026-11-16 take for all 93.8 s they share.
- **The voice processed alike in both takes.** The Narration bus has no effects. The Master limiter (ceiling −1 dB) never reached its ceiling in the mix or the voice take after the change (peaks −1.3 and −3.2 dBFS); before it, the mix reached it once, at 11.67 s, outside any spoken stretch. The voice's gain in the mix, by least squares, is 0.983 to 1.009 on each channel of each line.
- **What that can leave.** Even if all of that gain's distance from 1 were voice left behind, it would lie at least 26.9 dB under what is beneath, and move a figure for what is beneath by at most 0.4 dB.
- **Where the takes are not alike.** The bed-alone take reached the limiter's ceiling at 10.70 and 11.67 s, inside the reveal's first line, where the mix did not. For that line, `listening.py narration`'s unducked level and how far it ducks are **estimates.** No figure in the masking row uses the bed-alone take.

So the figures below are measurements of what played beneath each line, to within 0.4 dB. **What they measure is still only level** ([below](#what-the-figures-are-and-are-not)).

| Tool | Says |
|---|---|
| `tools/audio/listening.py narration` | Each line's level, what is beneath it across the whole spectrum, and how far the bed ducks |
| `tools/audio/voice_band.py` (new) | The same within 300 to 4000 Hz, the band that carries most of speech: a diagnostic of level, not of intelligibility |
| `tools/audio/subtraction_check.py` (new, after the review) | Whether the mix less the voice is what played beneath: alignment to the sample, the voice's processing in both takes, what could be left, the limiter |
| `tools/audio/listening.py check` | Peak, loudness by stage, sudden changes, clicks |
| `tools/audio/limiter_use.py` (new) | How much of each stage sits at the Master limiter's ceiling |
| `tools/audio/check_narration.py --folder` | What a recogniser hears in each line, cut from the voice-alone recording of the game |

## Found, and what was done

| Asked | Measured | Done |
|---|---|---|
| **Excessive masking** | Across the whole spectrum, the reveal's three lines and the flight's first stand **between 3.1 dB below and 1.8 dB above** what plays under them ([table](finale-narration-after.txt)); the tool flags anything under 6 dB, as a prompt to listen. Most of that bed is below 300 Hz: the surge's and the music's sub-bass and the call's low voice. **Within 300 to 4000 Hz** ([before](finale-band-before.txt)) "It was no ridge. It had been beside me the whole way." stood **2.7 dB** above its bed, and 2.3 dB below it in its worst half second; the other lines 6.7 to 17.2 dB above | **The water's cascade and surge, both loudest as that line begins, are keyed 7 and 5 dB lower from 4.3 s of the reveal's clip,** and put back at its end. The line now stands **6.0 dB** above its bed in that band, its worst half second 1.0 dB above ([after](finale-band-after.txt)): the water is lower beneath it, which is not to say the line is now heard. The reveal as a whole measures −18.0 LUFS, from −17.4; its loudest three seconds −16.6, from −15.6. **Left as it was:** "Its head turned. I ran." stands 6.7 dB above its bed in band, and 4.0 dB below it for half a second as the creature's second call swells |
| **Overlapping speech** | One player speaks every line in play and one in the epilogue, and a line replaces the line before it, so two cannot sound together. Each line's last sound falls before the next begins: by 0.4 s and 0.25 s in the reveal, and 3.3 s from its last line to the flight's first; 1.6 s and 0.75 s in the flight (the fall came 0.75 s after "The sea is coming back." in this run, which runs without stopping); 1.7, 1.6, 1.8 s in the epilogue | Nothing |
| **Complete spoken lines** | **Nine lines of nine word for word,** cut from the game's own voice-alone recording ([transcripts](finale-transcripts.txt)), "Innsmouth" being the exception recorded in M3. The recogniser heard each line with nothing under it: this shows every line is recorded whole and plays in full in the game, **not that it can be understood in the mix** | Nothing |
| **Clipping** | None. Peak −1.2 dBFS in the whole game after the change. Before it, the limiter was reached in one 10 ms window of the whole game, at the hand's impact; now in none ([by stage](finale-limiter.txt)) | Nothing more |
| **Abrupt transitions** | From the reveal into the flight, the flight into the fall, the fall into the epilogue, between its pictures and into the credits: **no change of more than 30 dB within 20 ms, and no isolated sample step** ([report](finale-mix-check.txt)). In the whole game the only sudden changes are the menu's knocks from silence, the pause, and the recording's end ([report](../listening/mix-check.txt)). **M4's drop at the cut into the game does not appear** | Nothing |
| **Voice A, the ducking, the prologue-to-Shore handover** | Unchanged: no narration file, bus or `MenuController` code differs from `main` | Nothing |

## What the figures are, and are not

- **A diagnostic, not a measure of intelligibility.** The comparison is of power within 300 to 4000 Hz over each line's spoken stretch, and in its worst half second. It models no ear: no critical bands, no masking across frequency or time, no dependence on level, nothing of which words matter. A line well above its bed can still be hard to follow, and one near it can be clear.
- **6 dB is not an auditory acceptance threshold.** It is the margin `listening.py narration` has flagged since M4, and should be read as a prompt to listen. Reaching it is not a pass and falling short is not a failure. D112 took the reveal's first line from 2.7 to 6.0 dB in band: that it now reaches 6 says only that the water beneath it is lower.
- **The transcripts are of the voice alone.** They show the lines are complete; they say nothing of hearing them over the music and effects. No recogniser was run on the mix, and a recogniser's result would not stand for a listener's either.
- **Only a listener can say whether a line is heard.** "Its head turned. I ran." under the creature's second call stays flagged for the owner's ear, and was not changed to reach a number.

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
- **No measure of intelligibility** was made, and none of the figures here is one.
