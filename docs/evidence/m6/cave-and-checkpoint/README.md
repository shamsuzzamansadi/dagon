# F2 and F3 from the GDD §8 review: the cave's two boundaries, and the Awakened checkpoint

The owner asked on 2026-11-21 for both, F2 first ([review](../visual-review/README.md)). **Neither is in the playtest baseline** (`a4250f0`): both first-time players see the old cave and the old checkpoint; see the [kit](../../../m6/playtest-kit/README.md).

## F2: the cave's boundaries follow the rock ([D126](../../../decisions.md))

**Before:** the cave between the Shore and the Abyss was drawn inside a plain rectangle, so it showed three straight vertical edges, from the top of the screen to the ground:

- **At the mouth,** where the Shore's cliff, whose image ends in a straight column at x = 640, met the cave's darker roof, which started on the same straight line; and below the roof, where the cliff's dark cleft met the cave's interior along it.
- **Beside the cliff,** the Abyss's far plain (`AbyssView`, from x = 600) showed through the gap beside the cliff's lower part, as a dark block with a straight left side and a flat top.
- **At the exit,** a strip of the cave's interior wall showed past the rock rib, to x = 1050, with a straight edge against the sky.

**Now:**

- **The joint at the mouth wanders like the cliff's own outer edge:** the cave's roof reaches back over the cliff's last dozen columns along a slow, weathered line with a little roughness (`gen_cave.py`, `mouth_edges`), joined by a dark line, the cliff keeping its own strata.
- **The passage's Shore side has a narrow rib of dark rock,** ragged on the side facing the cave, framing the way in as the exit's rib frames the way out (`draw_passage_jamb`).
- **The Abyss's far view starts behind the cliff** (`AbyssView` from x = 630), so the Shore's sea and sky carry on behind the cliff, as everywhere else on the Shore.
- **The interior's clip (`CaveView`) lies under rock on both sides:** behind the cliff on the left, down the middle of the exit's rib on the right, so the rib's own lit edge meets the sky. Its polygon comes from the generator (`cave_clip_polygon`).

**Collision and traversal are unchanged:** only `cave_front.png` (world x 616 to 645 changed, nothing else) and the two clip polygons, which draw nothing and collide with nothing. The walks below reach the same place on the same frame before and after (he sets off at frame 63 and stops at 217 at the mouth, 224 at the exit, in both).

**Held by `check_art.py`** (`check_clip_edges`, with Pillow alone): on every drawn row, each side of `CaveView` and the left side of `AbyssView` lies under rock drawn in front of it, the cliff's straight end is covered, and the scene's `CaveView` polygon is the generator's. On the scene and art as they were, it reports 456 problems (the left side on 146 rows, the right on 178, `AbyssView` on 131, and the polygon); now none.

**The walks,** normal speed, the game's own sound, recorded by Movie Maker at 480 × 270 and shown at 1440 × 810 with nearest-neighbour scaling, from just before he sets off to a moment after he stops (`record_visual.gd`, scenes `cave-mouth` and `cave-exit`, on the branch's editor build):

| | Before | After | What to look at |
|---|---|---|---|
| **The mouth,** from the Shore into the passage, against the cliff | [before-cave-mouth.mp4](before-cave-mouth.mp4) | [after-cave-mouth.mp4](after-cave-mouth.mp4) | The joint between the cliff and the cave's roof, top to bottom; the dark block beside the cliff's foot; the passage's Shore side as he drops into it |
| **The exit,** out past the rib into the Abyss, against the sky | [before-cave-exit.mp4](before-cave-exit.mp4) | [after-cave-exit.mp4](after-cave-exit.mp4) | Just right of the rib: a strip of wall with a straight edge before, the sky after |

Stills at the same moments: the mouth, [before](mouth-before-660.png) and [after](mouth-after-660.png) (and [before](mouth-before-600.png) and [after](mouth-after-600.png) a little earlier, for the block beside the cliff); the exit, [before](exit-before-980.png) and [after](exit-after-980.png), [before](exit-before-1060.png) and [after](exit-after-1060.png). The cave's drifting motes are not seeded alike from run to run, so they differ between any two takes.

## F3: the Awakened checkpoint clear of the kneeling statue ([D127](../../../decisions.md))

**Before:** Continue at the Awakened checkpoint, which is where Continue resumes after the ending, stood the sailor at x = 4250, in front of the kneeling statue by the gate (drawn at x 4225 to 4252): his back merged with it. **Now x = 4262, 12 px on:** his drawn back, 4 px behind his position, is 6 px clear of the statue's last column. That is the smallest move that clears it; leftward would take 38 px. [Before](continue-before.png), [after](continue-after.png).

**Progression unchanged, no save migration:** a save names its checkpoint (`checkpoint=Awakened`), never a position, so every existing save, from any build, continues at the new place. Nothing lies between: the gate stays ahead (x 4300) and so does the reveal's trigger (x 4415 to 4425); the nearest interactable, the wave stone, is 92 px behind. The walk's order of places (`test_world`) holds.

**Verified:**

- `test_restore` (19 passed), with the checkpoint's place moved to 4262: among them, each savable beat saved in one process and continued in another, which checks the restored position, the stones solved and lit, **the gate open**, the mural, standing on the floor and **control returned**; and from every savable beat, the keys alone reach the ending.
- **On the exported build,** from a post-ending save exactly as the route leaves it after the ending (`beat=awakened`, `checkpoint=Awakened`, with the Monolith save as backup): the main menu reads it as usable, Continue starts the Awakened beat, he stands where the after picture shows, and walking right reaches the reveal 4.1 s after Continue: control returned, and the gate open (a closed gate at x 4300 would stop him). No errors logged.
- **The exported route's four runs on the exported Linux build of this change,** on a private display: `runs=4 failed=0`, reading everything, straight through, continuing and waiting for the sea, and continuing after the ending, whose Continue stands him clear of the statue. The full local gate: 460 passed, 0 failed, and `CHECK_ART problems=0`.
