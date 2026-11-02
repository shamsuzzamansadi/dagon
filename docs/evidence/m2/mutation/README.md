# Deliberate breakage

Each change was made alone in a scratch clone, then the unit tests and Godot checks were run. `user://` was redirected,
so nothing could touch real files on the machine. The full output is in `breakage-at-c1f1ca6.txt`.

**33 changes: 32 were caught, including the runner's refusal to start without a test directory, and 1 slipped through.**

| Slipped through | Why | What happened |
|---|---|---|
| A new caption keeps the old caption's timer | The test checked at the moment the old timer would end, so it passed even if that timer was never stopped | The test now checks after that moment. It catches the change: `recheck-at-6ea0509.txt` |

**Caught in an unusual way:** with Quit wired straight to quitting, the test run really does quit partway. `tools/run_godot_checks.sh`
fails it because the `RESULT` line is missing.

**What was changed:**

| Area | Changes |
|---|---|
| Interaction | Press not consumed; no cooldown; focus ignores availability; focus ignores the control lock; `focus_changed` every frame |
| Triggers and checkpoints | Trigger latches itself; any trigger accepted out of order; accepted trigger not consumed; kill plane not connected |
| HUD | New caption keeps the old timer; prompt not refreshed after pausing; prompt ignores the gamepad |
| Pause menu | Pausing does not pause; Back closes everything; focus not brought back; Restart leaves the game paused; menu stops with the game; Resume fires on press; Quit has no confirmation; no gamepad buttons on menu actions |
| Settings | Esc in a capture also reaches the menu; a capture lets pad input through; failed write not reported; reopening forgets unsaved changes; resetting global state reverts bindings |
| Rebinding and storage | Old key stays active; arrow keys removed; volumes on the wrong bus; storage ignores the test directory; a key in use is simply taken; Esc can be rebound; damaged keys are kept |
| The runner | Started with no test directory |

**Not exercised by these changes:** the read-back check in `storage::replace_file`, because nothing here makes a write
succeed with the wrong contents.
