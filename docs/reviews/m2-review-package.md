# M2 Review Package

**To:** ChatGPT (independent reviewer), and the owner for the manual checks. **Date:** 2026-11-02.
**Status: implemented on branch `m2/interaction-and-usability`, at the M2 review gate, not merged. M2 is not accepted.**
No review or rerun of this implementation is reported yet. Please state which checks you rerun and which rely on the
supplied CI evidence.

- **Repository:** https://github.com/shamsuzzamansadi/dagon, branch `m2/interaction-and-usability`
- **Base:** `main` at `6c7eae2`, where M1 is accepted with documented deferrals
- **Commits:** `c1f1ca6` implements M2, `23511f0` names failed tests in CI annotations, `6ea0509` fixes a focus bug and
  corrects a test, then a commit adds the CI storage probe. Later commits change only documents.

**Who has verified what:**

| Result | Who ran it |
|---|---|
| 58 unit test cases, 107 integration tests, extension load, smoke on both scenes, release exports, Linux and MSVC | **CI and the developer** (§3). Not independently rerun. |
| Deliberate breakage | **Developer** (§4) |
| The screens, from scripted captures with software rendering | **Developer** |
| Physical keyboard, physical controller, real GPU, how any of it feels | **Nobody yet** (§7) |

## 1. What was built

| Area | Files |
|---|---|
| Interaction | `src/interactable.*`, `src/interactor.*`, in `player.tscn` |
| Prompts, captions, fade | `src/hud.*`, `scenes/ui/hud.tscn` |
| Story triggers | `src/story_trigger.*` |
| Session checkpoints and kill plane | `src/game_director.*`: only these parts ([D31](../decisions.md)) |
| Pause menu | `src/menu_controller.*`, `scenes/ui/pause_menu.tscn` |
| Settings and rebinding | `src/settings_menu.*`, `scenes/ui/settings_menu.tscn`, `src/core/settings_data.*` (plain C++) |
| Storage | `src/storage.*`: stateless, with one root |
| Global state | `src/global_state.*` |
| Volumes, for audio later | `project/default_bus_layout.tres`: `Music` and `Effects` buses |
| UI font and theme | `tools/art/gen_ui.py`, `project/assets/ui/` |
| Tests | `tests/unit/test_settings_data.cpp`, `project/tests/test_{interaction,director,pause_menu,settings}.gd` |
| Test storage | `tools/test_storage.sh`, `project/tests/harness.gd`, `run_tests.gd`, `user_dir_probe.gd` |

Content added to the Shore: the lifeboat and the fish by the rock can be examined, there is one checkpoint past the trench
(x = 750), and a kill plane sits under the whole level. The caption text is new and subject to the owner's review.

**Unchanged:** movement tuning, the collision, the camera and the accepted art, all still covered by the M1 tests.

## 2. Scope against the roadmap

| Requirement | Status |
|---|---|
| Pause menu: Resume, Restart Checkpoint, Settings, Quit to Desktop | Done |
| Pausing stops gameplay while the menu stays responsive | Done; tested |
| Keyboard and gamepad menu navigation, reliable focus, usable Back | Done; simulated input only |
| Persistent settings, saved apart from progress | Done; tested across a real relaunch |
| Keyboard rebinding, conflicts explained, Restore Defaults, no way to get trapped | Done |
| Music and effects settings prepared | Done: stored, and set on their buses. **Nothing audible until M4.** |
| Interaction, focus, prompts and captions, story-trigger infrastructure | Done |
| Kill plane and session respawn checkpoints | Done |
| Tests with isolated storage, at every entry point | Done |
| Saves, Continue, main menu, `GameSession` world replacement | **Not started: M3, as planned** |
| M4 artwork, audio | **Not started** |

**Pause and Restart in M2:** Restart Checkpoint teleports the player to the active checkpoint. There is no story state to
restore yet, so it does not rebuild the world. From M3 it does (`GameSession`).

## 3. Results

CI run [41453463059](https://github.com/shamsuzzamansadi/dagon/actions/runs/41453463059), commit `6ea0509`:

| Check | Linux (g++ 11.4.0) | Windows (MSVC 19.44.35229) |
|---|---|---|
| Unit tests | 58 cases pass | 58 cases pass |
| Extension load | 9 classes, 0 problems | 9 classes, 0 problems |
| Integration tests | 107 pass | 107 pass |
| Smoke: entry scene and greybox | Pass | Pass |
| Art check | 0 problems | 0 problems |
| Release library in the exported game, starting in `shore.tscn`, headless | Yes | Yes |

The CI run for the storage probe is on the branch's next commits, because it was added after this run.

**Fresh clone from GitHub, following the README, at `6ea0509`** (developer; Ubuntu 24.04, GCC 13.3.0, Godot 4.7.2): builds with no
compiler warnings; 58 unit test cases and 856 assertions pass; 107 integration tests pass, and repeated **10 of 10 clean**; the art
regenerates identically; and the Linux release export starts in `shore.tscn`, headless.

**By suite:** movement 15, greybox 10, Shore 22, interaction 10, director and HUD 15, pause menu 14, settings 21. The unit
suite gained 12 cases.

**M2 review follow-up closed:** Interactor delivery and consumption are tested through `Input.parse_input_event()`, which
reaches `_unhandled_input`, including a check that a handled press reaches nothing else.

## 4. Can the tests fail?

**33 deliberate breakages, in [evidence/m2/mutation/](../evidence/m2/mutation/README.md): 32 were caught and 1 slipped through,
then its test was corrected and it is now caught.** Not exercised: the read-back check in `storage::replace_file`.

## 5. Defects found while building

| Defect | How it was found | Fix |
|---|---|---|
| **A real memory bug: `NodePath` self-assignment.** `focus_path(default_focus_path_)` assigned a member to itself, and `NodePath::operator=` destroys before copying. GCC happened to survive it, and MSVC did not. | `test_focus_comes_back_after_it_is_lost` failed only on the Windows runner. My first guess at the failing test was wrong, so I published the test's name through CI annotations first and read the real failure. | `focus_default()`, which never assigns |
| **No gamepad on `ui_accept` and `ui_cancel`.** In 4.7.2 the engine's defaults have none, so a controller could not press or back out. | Printing the InputMap before writing tests against it | The project defines them (D35) |
| **A project-wide theme breaks a clean import.** The engine loads it at startup, before the assets exist, and logs `ERROR` lines. | Reading the first import's log | The theme is set on the UI scenes |
| **Failed saves silently undone.** The message said a change lasts until quitting, but reopening Settings or restarting re-read the file. | Reviewing the failure path after looking at the screens | `reset_global_state` leaves settings alone (D33), and the menu keeps unsaved values |
| Key-label lookup logs an error on the headless display server | The first test run | Skipped there. Real windows use the player's keyboard layout. |
| A caption test could not fail | Deliberate breakage | Corrected (§4) |
| Every test redirected storage, so the path real players use was never exercised | Reviewing my own coverage | `user_dir_probe.gd` in CI, which refuses to run anywhere but a throwaway machine |

## 6. For your judgment

1. **One rebindable key per action (D32).** The arrow keys and Esc are kept, and cannot be assigned elsewhere. This makes
   lockout and unbound actions impossible by construction, at the cost of some flexibility.
2. **`GameDirector` starts in M2 (D31),** with only the session checkpoint and kill plane, so no temporary class is needed.
3. **`reset_global_state()` leaves settings alone (D33).** This narrows architecture §7 rule 8, which said it would
   re-apply them. Nothing else may change them, so the reset has nothing to undo.
4. **The environment variable `DAGON_STORAGE_DIR` is honoured in release builds too.** That keeps the exported game's smoke
   run isolated. A player could point their own settings elsewhere with it, which seems harmless for a local game.
5. **Closing the window shows no dialog.** The confirmation is on Quit to Desktop in the menu.
6. **Quit's wording in M2** says progress is not saved, because no save exists yet. M3 replaces it, as D27 requires.

## 7. Not established, and limits

- **Physical input:** everything above uses simulated input. Physical gamepad testing stays deferred to M6 (D29).
- **Real rendering:** captures used software rendering. Nobody has seen these screens on a real GPU.
- **Non-QWERTY layouts:** key labels use the display server's layout lookup in windowed runs, seen only on this QWERTY
  machine. The headless tests use the physical key's name.
- **Slider focus** is a brighter grabber and track, quieter than the button outline. Whether that is clear enough is a
  manual check.
- **UI styling** is functional, not the M4 pass. Interactable rim highlights (GDD §3) are deferred to M4.
- **Mouse:** buttons respond to it, but no test covers it, because the requirement was keyboard and gamepad.

## 8. Manual test checklist (owner)

**First, note which build you are testing:** the run ID or commit, from the Actions page you downloaded it from. Later
milestones identify the exact artifact, as D29 requires. Expected throughout: no audio, and art ending at the cliff opening.

1. **Start:** the game opens beside the boat with `[E] Examine` showing.
2. **Examine:** press E. A caption appears and fades after about 4 seconds, and you can keep walking meanwhile. Walk right to
   the fish by the rock and press E there.
3. **Pause:** press Esc. The sailor and the sea stop, and Resume is highlighted. Esc again resumes.
4. **Menu navigation:** pause, move with the arrow keys, choose with Enter or Space. Can you always tell what is highlighted,
   including on the volume sliders?
5. **Resume with Space:** choose Resume by pressing Space. The sailor should not jump.
6. **Rebind:** pause, Settings. Choose Jump and press J. Resume: J jumps and Space does not.
7. **Conflict:** in Settings, choose Interact and press J. It should say J is already Jump, and offer Swap or Cancel. Swap,
   resume, and check that the prompt beside the boat now names the new key.
8. **Lockout:** in Settings, choose Jump and press Left Arrow. It should refuse, and Esc should cancel.
9. **Persistence:** rebind something, then pause and Quit to Desktop. It should ask first, with Cancel highlighted, and say
   progress is not saved. Quit, relaunch, and check that the binding is still there.
10. **Restore Defaults:** Settings, Restore Defaults. A, D, Space and E should work again.
11. **Checkpoint:** walk right through the cleft and past the trench. Pause, Restart Checkpoint: you return just past the
    trench, unpaused. In a fresh launch, before going that far, it returns you to the boat.

**Please report:** the build, anything confusing or wrong, and how the menus and captions read on your display. A controller
is optional here (Start, D-pad, south and east buttons, and `[X]` in the prompt), since physical gamepad testing stays deferred
to M6. Reporting the renderer is also optional: start the game with `--log-file playtest.log` and find `Using Device`.

## 9. Carried to M3

- `GameSession` and the save slot, with the D26 conditions: remove the old world's active signals and callbacks, give the new
  director its checkpoint before it enters the tree, and verify restart after an autosave failure, pause reset and repeated
  restart.
- `Quit to Main Menu`, the main menu, and the main scene moving to it. M1's `test_the_game_starts_in_the_shore` and the export
  check then change with it.
- `GameDirector` gains `StoryProgress` and the session checkpoint moves to `GameSession`. Overlap re-checks after a beat are
  M3 too, since M2's layout has no trigger inside another.
- `storage::replace_file` gains the backup rules for saves.
