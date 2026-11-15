# The stone gate rises again

**The owner, 2026-11-15:** the stone gate no longer visibly rises after the final puzzle ([record](../owner-playtest-2026-11-15.md)). **ChatGPT**, from the owner's recording and the source at `4b959cf`, found why.

## The defect

The awakening clip raised `Monolith/Gate/Visual`, the greybox polygon, 260 px. M4's stretch E (`5ed5c01`) hid that polygon and drew the slab as `Monolith/Gate/Drawn`, its **sibling**, which the clip never moved. So the gate stood still for the whole awakening, and then vanished when the clip was finalized, as `GameDirector::open_gate()` turns its collision off and hides it. Introduced by M4's art; M3's gate rose.

**The same slip once more,** found by a scan of every clip for tracks on hidden nodes: the reveal raised `Trench/Water`, the hidden greybox water, 14 px as the creature rises, and the drawn trench did not follow.

## The fix (`8484212`)

- **The gate:** the one track now moves `Drawn`, from its own offset `(-8, -150)` to `(-8, -410)`, the same 260 px over the same 1.5 to 3.5 s. **The collision body is not moved;** `open_gate()` is unchanged and still opens and hides the gate when the clip is finalized, on every exit path.
- **The trench water:** its own sprite, `Trench/WaterDrawn`, the same pixels as the backdrop beneath it and 14 rows deeper so nothing opens below it as it rises; the track moves it from its offset. The backdrop is byte for byte unchanged.

## Seen

- [gate-before.mp4](gate-before.mp4) and [gate-after.mp4](gate-after.mp4): 10.5 s each with sound, from the last stone to two seconds after control returns. Recorded by Movie Maker from the editor build (`project/tests/record_gate.gd`), at twice the game's size.
- [gate-before-after.png](gate-before-after.png): the same moments side by side, before on the left. The closed gate during the try at it; 1.5, 2.5 and 3.5 s into the awakening (before: standing; after: full, half risen, gone above the frame); the open passage once control is back; walking through.
- **In the exported release build itself,** played in real time with window-system keys by `tools/route_check.py`: [exported-before-fix.png](exported-before-fix.png), at `ced2499`, the gate standing through "The stones answered"; [exported-awakening.png](exported-awakening.png), at `8b30b33`, screenshots taken 0.6, 1.6, 2.3, 2.9, 3.5, 4.3 and 6.5 s after the game logged the awakening clip starting: the slab full, then rising, then gone.

Looked at by the developer only.

## Checked against what the owner asked

| | Result | How, and on what |
|---|---|---|
| **1. Before solving, walking and jumping cannot pass the gate or start the encounter** | Blocked. **Exported game:** from a save at the Monolith, Continue, then twelve seconds of walking right and jumping with window-system keys: he stands against the closed gate ([exported-closed-gate.png](exported-closed-gate.png)); no beat reached and no clip started after the restore ([log](exported-closed-gate.txt)). **Editor:** the furthest he got was x = 4286, short of the gate's face at 4292; the beat stayed the Monolith ([record](record-gate-after.txt)) | `8b30b33`'s export; scripted, not a person |
| **2. Solving visibly raises the drawn gate, with its sound and clear feedback** | The slab rises from 1.5 to 3.5 s; the clip starts the gate's sound at 1.4 s, the music at 0.1 s and the line "The stones answered" at 0.2 s, as before. **Exported:** seen in [exported-awakening.png](exported-awakening.png) | `8b30b33`; **the sound was not heard,** only that it is the same clip with the same sounds |
| **3. Control and passage after the cinematic** | Control returns and he walks through the open gate into the reveal: the exported route, `runs=4 failed=0`, and `record_gate.gd` reaching x = 4382 at the Awakened beat | `8b30b33`, local and CI |
| **4. Skip, missing clip, restart, save and Continue** | **The awakening cannot be skipped;** a press during it skips only its line (tested). A **missing, looping, ping-pong or stuck** awakening clip still opens the gate and returns control (`test_cinematics.gd`). **Restore and Continue at every savable beat** keep the gate open or closed, and now also hold a closed gate's drawn slab where its collision is, shown (`test_restore.gd`); the exported route Continues from the Awakened save and after the ending. **The prologue's Skip** starts a new game at the Shore with the gate closed, as restoring the Shore beat does | Integration 442/0 on `8b30b33`, GCC, Clang, MSVC |

**When this was written, not tested by the owner:** the Skip case, and the try at passing the closed gate; both above are scripted. **Since, the owner's third report of 2026-11-15** ([record](../owner-playtest-2026-11-15.md)): the owner personally tested the closed gate and the gate's opening, both satisfactory; and the owner's video shows the prologue's Skip reaching the Shore, confirmed from frames by ChatGPT, which did not listen.

## Regression checks

- `test_puzzle.gd`, **the rendered gate:** solving with real presses raises `Drawn` more than 60 px by 2.5 s into the clip while it is still shown; the gate's body neither moves nor opens before the clip ends; afterwards the way is open.
- `test_revision.gd`, **any clip:** no value track animates a node that is hidden in the scene unless the clip also shows it. It is what found the trench water.
- `test_restore.gd`: a closed gate's slab at its own place and shown, at every savable beat.
- **Deliberate breakage:** the gate's track put back on the hidden shape fails the rendered-gate test and the clip check; the water's, the clip check; the closed gate drawn raised, the restore and gate tests. Controls held ([result](../breakage.txt))
