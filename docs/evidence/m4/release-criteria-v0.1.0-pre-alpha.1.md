# The pre-alpha criteria for `v0.1.0-pre-alpha.1`, and what shows each is met

The label promises four things ([release.md](../../release.md)). Each is shown below on the accepted candidate, `8b30b33`, CI push run [43738445550](https://github.com/shamsuzzamansadi/dagon/actions/runs/43738445550), fingerprint `sha256:614f29b68865e037d9d0be817c537e7452b608626f50efc584760a2d508a7f6e`.

**Who checked what.** "Scripted" means a program pressed the keys: the integration suite inside the editor build, or `tools/route_check.py` on the exported release build with window-system key events. Neither is a person playing. The owner's own checks are listed last, in the owner's words, and nothing is added to them.

| Criterion | Met by | Scripted or a person |
|---|---|---|
| **A usable playable slice** | The exported Linux and Windows builds are played from New Game through the prologue, the Shore, the cave, the Abyss, the crossing, the stones and the gate, the reveal and the flight to the ending and the credits: `ROUTE_RESULT runs=4 failed=0` on both in CI. Integration 442 passed, 0 failed on GCC, Clang and MSVC | Scripted. **The owner:** the overall gameplay feels good and has improved substantially; accepted this candidate ([record](owner-acceptance-2026-11-15.md)) |
| **Working controls** | Movement, jumping, pushing, interacting, the menus, rebinding and the controller layouts: `test_movement.gd`, `test_controller.gd`, `test_settings.gd`, `test_pause_menu.gd`, `test_title.gd`. The exported route is driven only by real key events | Scripted. Controller layouts are tested through a stand-in for the driver's name ([D41](../../decisions.md)), not on hardware. **Physical controllers are deferred,** and listed under "Not tested" in the release notes |
| **Working interactions** | Examining with its prompt, caption and sound, the pushed stone and the slab, the stones' puzzle with a wrong press, the gate: `test_interaction.gd`, `test_narrative.gd`, `test_puzzle.gd`, `test_level.gd`; the exported route's first run reads everything that offers a prompt and solves the puzzle | Scripted. **The owner:** tested the closed gate and the gate's opening after the puzzle, both satisfactory |
| **Checkpoint persistence** | Restore and Continue at every savable beat: `test_restore.gd`, `test_session.gd`; the storage's interrupted-write cases: `tools/test_storage.sh`; the exported route's third and fourth runs Continue from the Awakened save, in new processes, before and after the ending; an exported Continue from a Monolith save ([gate](gate/README.md)) | Scripted |

**Evidence in the repository:** the [review package](../../reviews/m4-review-package.md) (§0 first), the [gate's record](gate/README.md), the [deliberate breakage](breakage.txt), and the CI run above.

**Not shown by any of this:** that the art or the sound is final, how the game sounds, how it plays on hardware not named, or how long a first playthrough takes.
