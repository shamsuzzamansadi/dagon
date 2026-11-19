# The reveal: its composition, the creature, and how it moves

**Asked for by the owner** (roadmap, "M5: carried from M4", and the M5 scope of 2026-11-16): remove the straight boundary beside the arm; separate the creature from what is behind it by light, contrast, depth and water; restrained animation with weight, breathing and water; keep the hand and the carving together; change nothing of the story, puzzle, collision, progression or the cinematic contract.

**Looked at by the developer only,** as frames from the game at its own 480 × 270, software-rendered on a private display. Frames cannot show timing or motion as a person sees them, and nobody has played it. Whether it reads is the owner's to say.

## Seen

- **[before-after.png](before-after.png):** the same moments of the clip, `main` at `09d854e` on the left, M5 on the right: before the reveal, then 2.5, 4.0, 5.5, 7.0, 8.5, 10.0, 12.0 and 13.0 s into it, and two seconds into the flight. Taken as the clip plays, the sailor having walked into it with real keys (`project/tests/capture_m5.gd`), not by seeking.
- **Every half second of the clip, after:** [0 to 5.5 s](after-every-half-second-1.png), [6 to 11.5 s](after-every-half-second-2.png), [12 to 13.5 s](after-every-half-second-3.png). So that no frame was put right at another's cost.
- **[reveal-before.mp4](reveal-before.mp4) and [reveal-after.mp4](reveal-after.mp4):** 17.5 s each, with the game's sound, from two seconds before the reveal to the first step of the flight, at twice the game's size. Recorded by Movie Maker (`project/tests/record_finale.gd`). The two runs' stage and line marks fall on the same frames ([marks](marks.txt)).

## What changed

| | Before | After | Decision |
|---|---|---|---|
| **The boundary at x = 4544** | Left of it the Shore's screen-fixed sky, which does not cover the view at half zoom; right of it the trench's backdrop | The trench's night begins behind the Monolith, which covers its edge. One sky behind the stone, the arm and the creature | D105 |
| **Behind the arm and the snout** | The canyon's wall, dark, to the top of the view | The wall falls away behind the Monolith. The arm crosses open night to the stone; the snout is against the lightest of the sky | D105 |
| **The creature's art** | Flat dark parts with a teal edge on the left and separate teal lines | Drawn for the size it is seen at, lit from above and the right as the Monolith is: head with jaw, teeth, brow and gill covers; a webbed crest; scales and belly plates; spines down the back; a webbed hand with claws. A dark base, and a lit image that fades in | D106 |
| **Before the reveal** | A flat near-black hump against the dark wall | The same shoulder, drawn, against the sky past the gate | D105, D106 |
| **Appearing** | The body and head appeared in one frame at 3 s | They come out of the fog over 1.3 s | D107 |
| **Rising** | A straight line from 3 s to 9 s, after a 12 px jump as the clip began | From rest: it stirs at 1.5 s with the water's first sound, rises fast and slows, sinks a little as the hand lands, then breathes | D107 |
| **The arm** | Slid in a straight line, from below | Turns about its shoulder: lifts, and falls onto the stone at 7 s, where the impact sounds | D107 |
| **The head** | Still; only the pupil moved | Goes back as it calls; turns down toward him from 11.4 s, with "Its head turned"; the crest lifts; the eye opens over a quarter second | D107 |
| **Water** | Dots thrown up at the trench; dots falling in a box before the body | A mound of white water heaved up before it and falling back; spray thrown wider; water pouring from its shoulders, jaw and arm; spray standing behind and before it | D108 |

**Unchanged, and held by tests:** the clip's length, 14 s; every line and its time (4.3, 8.2, 12.2 s); every sound's time; the camera's shake, and its keys to 12 s; the haptic cue; the light on the carving from 7 s and the hand beside it; control locked until the end; the director's outcomes on every exit path. **No C++ changed for the reveal.** After the owner's playtest of 2026-11-19 the head's turn was enlarged and the wide view held to 12.8 s, within the same 14 s and with every line and sound where it was (D114, `tools/scene/stage_turn_m5.py`; [clips](../playtest-2026-11-19/README.md)).

## GDD §8's checklist on the reveal, by the developer, from the frames

| | | |
|---|---|---|
| 1 | Player, ground and important props distinguishable | The sailor, lit by his lantern, stands clear on the ledge in every frame; the Monolith is the lightest thing in view; the creature is dark against a lighter sky and haze |
| 2 | One coherent style | The creature shares the Monolith's light and the palette. **It is drawn in blocks of two pixels:** at full zoom, in the clip's first and last two seconds, they are coarser than the stone beside it |
| 3 | Camera stable and intentional | Unchanged from M3 |
| 4 | No unintended seams, clipping, stretching or repetition | The seam is gone. **The haze is a smooth fall, not dithered pixels,** as the fog bank past the gate already was |
| 5 | Text readable and aligned | Unchanged. The waterline lies under the caption at half zoom, by the camera's limits; what shows the water is above it |
| 6 | Mood without an explanatory paragraph | For the owner |
| 7 | Considered in a still and in play | Stills: the developer's view is yes. **In play: nobody has looked** |
| 8 | Performance and regression checks pass | Integration suite and CI: see the [review package](../../../reviews/m5-review-package.md). **Frame time was not measured;** three small particle emitters and nine sprites were added |

## Checked

- `test_narrative.gd`: the parts show in order and the eye last (kept); the hand rests on the Monolith and the head is in frame at the widest view (kept); **one backdrop stands behind every view the clip takes** (new); **the drawn parts move, turn and light with their tracks, and nothing still pours at the end** (new).
- `test_revision.gd`: no clip animates a hidden node, **now following parents** (tightened); **every clear shape a clip moves carries a shown drawing** (new); each part's art sits on its shape (kept, the ridge added).
- `test_cinematics.gd`, `test_restore.gd`, `test_puzzle.gd`: unchanged and passing: pause, a missing, looping or stuck clip, the watchdog, restore at each beat, the gate.
- Deliberate breakage: [result](../breakage.txt).
