# M2 Review Package

**To:** ChatGPT (independent reviewer), and the owner for the manual checks. **Date:** 2026-11-03.
**Status: accepted by the owner for merge on 2026-11-03 ([record](../evidence/m2/owner-acceptance-2026-11-03.md)),** based on their manual testing, the completed review and the required automated checks.
That is not a statement that every item in §8 was tested, and deferred checks stay deferred to M6. Any later reviewer, please state which checks you rerun and which rely on the supplied CI evidence.

**Start at §11.** It covers this round: the Examine failure, the main menu and save moved in from M3, the controller work, and the Settings
audio note. §1–§10 are the earlier record. They are updated where they would mislead, and otherwise describe the state at their time.

- **Repository:** https://github.com/shamsuzzamansadi/dagon, branch `m2/interaction-and-usability`
- **Base:** `main` at `6c7eae2`, where M1 is accepted with documented deferrals
- **Commits:** `c1f1ca6` implements M2, `23511f0` names failed tests in CI annotations, `6ea0509` fixes a focus bug and
  corrects a test, `9748394` adds the CI storage probe, `37f26fd` adds this package, `24882e3` corrects review round 1, and `d78f5a6` records it.
  `803d8f2` fixes Examine and brings the main menu, save and `GameSession` forward, `8da9a2e` adds controller labels, `8dde394` keeps editor
  settings out of the repository, and `79981ea` records the investigation.
- **The tested code and the build for the owner's check: `3426d3b`,** which adds the Settings audio note and closes two test gaps. Every commit after it
  changes only documents and evidence, which §8's build does not contain. A file cannot name its own commit, so the pull request and the final report name the branch's last commit and its CI run.

**Who has verified what.** Each row covers only the commit it names. **A review result does not carry over to later code changes.**

| Result | Who ran it |
|---|---|
| 58 native unit test cases (856 assertions) and the art check, at `37f26fd` | **Independently rerun by the reviewer,** ChatGPT |
| The M2 source, scenes, tests, storage paths and CI configuration, at `37f26fd` | **Reviewed by the reviewer,** with the findings in §10 |
| CI run 41454712313 succeeded for `37f26fd` on both platforms | **Checked by the reviewer** through the GitHub API |
| The review round 1 fixes, at `d78f5a6` | **Reviewed by the reviewer** |
| The Examine wiring fix, the exported-pack test coverage, the menu, session and save paths, and the controller labels, at `79981ea` | **Reviewed by the reviewer:** no new blocking code defect identified in those areas |
| 83 native unit test cases (994 assertions) and the art check with zero problems, at `79981ea` | **Independently rerun by the reviewer** |
| CI run 41653352896 succeeded for `79981ea` on Windows and Linux, and the commits were on GitHub | **Checked by the reviewer** |
| Godot integration tests and Windows gameplay, at every commit | **Not independently rerun by the reviewer.** CI and the developer only |
| Everything after `79981ea`: the audio note and five new or stronger tests (§11) | **CI and the developer. Not reviewed** |
| Deliberate breakage | **Developer** (§4, §10, §11) |
| The screens, from scripted captures with software rendering | **Developer** |
| The real Windows build at `3426d3b`, with input posted to its window | **Developer, scripted** (§11). Not a physical keyboard or controller |
| Manual testing of "the current build", which looked correct | **The owner,** who accepted M2 for merge. Not itemized, and the build was not named ([record](../evidence/m2/owner-acceptance-2026-11-03.md)) |
| Physical Xbox controls, on an earlier build they did not name | **The owner,** positive for the controls they tried ([record](../evidence/m2/xbox-feedback-2026-11-03.md)). **Not a pass for this build or for later behaviour** |
| All PlayStation hardware | **Nobody yet.** Deferred to M6, not passed (§7, §8) |

## 1. What was built

| Area | Files |
|---|---|
| Interaction | `src/interactable.*`, `src/interactor.*`, in `player.tscn` |
| Prompts, captions, fade | `src/hud.*`, `scenes/ui/hud.tscn` |
| Story triggers | `src/story_trigger.*` |
| Kill plane and session checkpoints | `src/game_director.*`, and `src/game_session.*` since the save work ([D31](../decisions.md), §11) |
| Pause menu | `src/menu_controller.*`, `scenes/ui/pause_menu.tscn` |
| Settings and rebinding | `src/settings_menu.*`, `scenes/ui/settings_menu.tscn`, `src/core/settings_data.*` (plain C++) |
| Storage | `src/storage.*`: stateless, with one root |
| Global state | `src/global_state.*` |
| Volume controls and buses prepared, not audio | `project/default_bus_layout.tres`: `Music` and `Effects` buses. `AudioNote` in `scenes/ui/settings_menu.tscn` ([D42](../decisions.md)) |
| UI font and theme | `tools/art/gen_ui.py`, `project/assets/ui/` |
| Tests | `tests/unit/test_settings_data.cpp`, `project/tests/test_{interaction,director,pause_menu,settings}.gd`. §11 lists this round's |
| Test storage | `tools/test_storage.sh`, `project/tests/harness.gd`, `run_tests.gd`, `user_dir_probe.gd` |

Content added to the Shore: the lifeboat and the fish by the rock can be examined, there is one checkpoint past the trench
(x = 750), and a kill plane sits under the whole level. The caption text is new and subject to the owner's review.

**Unchanged:** movement tuning, the collision, the camera and the accepted art, all still covered by the M1 tests.

## 2. Scope against the roadmap

| Requirement | Status |
|---|---|
| Pause menu: Resume, Restart Checkpoint, Settings, Quit to Desktop | Done, and it now also has Controls and Quit to Main Menu (§11) |
| Pausing stops gameplay while the menu stays responsive | Done; tested |
| Keyboard and gamepad menu navigation, reliable focus, usable Back | Done; simulated input only |
| Persistent settings, saved apart from progress | Done; tested across a real relaunch |
| Keyboard rebinding, conflicts explained, Restore Defaults, no way to get trapped | Done |
| Music and effects settings prepared | **Volume controls and buses prepared.** Stored, and set on their buses. Settings says "This build has no audio yet." ([D42](../decisions.md)) |
| Interaction, focus, prompts and captions, story-trigger infrastructure | Done |
| Kill plane and session respawn checkpoints | Done |
| Tests with isolated storage, at every entry point | Done |
| Saves, Continue, main menu, Controls, Credits, `GameSession` world replacement | **Done, moved here from M3 by the owner (D36).** See §11. |
| Controller labels, prompts by device, mappings explained | **Done, requested by the owner.** See §11. |
| M4 artwork. Audio itself: environmental audio, footsteps, object and interaction sounds, story cues (M4, M5) | **Not started, by plan.** Audio is not complete until it has been heard and checked in gameplay |

**Pause and Restart:** Restart Checkpoint rebuilds the world at the session checkpoint (`GameSession`). It first did this by teleporting,
until the save work brought `GameSession` forward.

## 3. Results

**The latest results are in §11.** This section records the first complete run, before review round 1.

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
then its test was corrected and it is now caught.** Not exercised: the read-back check in `storage::replace_file`. This round's breakage is in §11.

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

1. **One rebindable key per action (D32).** The Left and Right arrows and Esc are kept, and cannot be assigned elsewhere.
   This makes lockout and unbound actions impossible by construction, at the cost of some flexibility. Up and Down stay free.
2. **`GameDirector` starts in M2 (D31),** so no temporary class is needed. It first had only the session checkpoint and kill plane. Since the save work it also holds `StoryProgress`, and the checkpoint moved to `GameSession` (§11).
3. **`reset_global_state()` leaves settings alone (D33).** This narrows architecture §7 rule 8, which said it would
   re-apply them. Nothing else may change them, so the reset has nothing to undo.
4. **The environment variable `DAGON_STORAGE_DIR` is honoured in release builds too.** That keeps the exported game's smoke
   run isolated. A player could point their own settings elsewhere with it, which seems harmless for a local game.
5. **Closing the window shows no dialog.** The confirmation is on Quit to Desktop in the menu.
6. **Quit's wording** now says what Continue resumes from, as D27 requires.

## 7. Not established, and limits

- **Physical input:** the automated tests inject events. They prove the logic for each layout, not physical devices, and §11 lists what has
  physically been tried. Testing a controller on Windows does not establish Xbox or PlayStation console support, and consoles are not targets.
- **Real rendering:** the `tests/capture_*.gd` captures use software rendering. The Windows screenshots in §11 are from a real GPU.
- **Non-QWERTY layouts:** a key's name now falls back when the font cannot draw it. Bangla is proven on the real build (§11). German has not been read back after the fix. **The owner asked to keep system keyboard-layout changes out of further testing on their active desktop, so this stays a stated limit,** at low risk because German's A, D and E match English.
- **Audio:** this build has none. M2 delivers volume controls and buses prepared, not audio. A slider moves a bus and a saved value, and nobody can hear either, so "working" here means only that. Audio stays in M4 and M5 and is not complete until heard in gameplay.
- **Slider focus** is a brighter grabber and track, quieter than the button outline. Whether that is clear enough is a
  manual check.
- **UI styling** is functional, not the M4 pass. Interactable rim highlights (GDD §3) are deferred to M4.
- **Mouse:** buttons respond to it, and one test covers a click on empty space. The requirement was keyboard and gamepad.

## 8. Manual acceptance check (owner)

**Result: the owner accepted M2 on 2026-11-03 after manual testing.** They did not itemize what they ran, so no step or row below is recorded as individually passed. They said "the current build" without naming it. What could be checked points to the build below, without proving which copy was launched ([record](../evidence/m2/owner-acceptance-2026-11-03.md)). This section remains as it was asked.

**Use exactly this build:** `dagon-windows` from CI run **[41682543058](https://github.com/shamsuzzamansadi/dagon/actions/runs/41682543058)**, commit **`3426d3b`**, zip SHA-256 `cbfca7c95e25852e5c7a45438806751a0e8df637d093bd7f1e34253d0fa2a434`. Earlier downloads do not count. Your earlier
Xbox feedback is [on record](../evidence/m2/xbox-feedback-2026-11-03.md), but it came from an earlier build, and it is not a pass for anything below.

**Expected throughout:** no audio, and art ending at the cliff opening. **Please do not change your system's keyboard layout for this check,** and use the one you already have. Your real settings and save file are used, as in normal play. For a clean start,
delete nothing: use **Restore Defaults** and **New Game**.

**This is separate from the developer's run.** §11's Windows run sent scripted window messages to this same build. It says nothing about your keyboard or controller.

**A. Menus, keyboard**

1. **Launch:** the main menu appears, with art behind it. With no save: New Game is highlighted, Continue is greyed out, and it says why. With a save: Continue is highlighted, saying where it resumes.
2. **Controls and Credits:** open each from the main menu. Is the text readable, and does Back return you? Is anything wrong in Credits?
3. **Settings:** directly below the Music and Effects sliders, it reads **"This build has no audio yet."** on one line, not cut off. Press Down from Music: the highlight goes to Effects, then straight to Move Left, and never lands on the note. Move each slider a little and leave it there. You will hear nothing, which is expected.

**B. Examine, keyboard**

4. **New Game:** if you have a save, it asks first, with Cancel highlighted. How to Play appears, showing the keyboard. Choose Begin. The sailor does not jump.
5. **At the boat:** a prompt names your key. Stand still for a few seconds first: nothing should appear by itself (see "One unexplained event" in §11). Press your key: the boat's caption appears.
6. **At the fish:** walk a little right. The prompt stays. Press it again: the fish's caption appears.

**C. Quit, relaunch, Continue**

7. **Save:** walk past the trench. "Checkpoint saved" shows briefly. Pause, then **Quit to Main Menu.** Cancel is highlighted, and the text says what is kept. Confirm: Continue is now highlighted, saying where it resumes.
8. **Relaunch:** Quit to Desktop, and start the game again. Continue is highlighted. Choose it: you are past the trench. In Settings, the sliders are where you left them in step 3.

**D. Xbox mappings.** Please press these exact buttons. In every build up to `d78f5a6`, Interact showed nothing on any device, so a test on one of those could not have confirmed them:

| # | Where | Press | Expected label or behaviour |
|---|---|---|---|
| X1 | Main menu | Left stick down, then D-pad down | The highlight moves one item each |
| X2 | On Controls | **A** | Controls opens. A section headed **Xbox controller** reads Jump: A, Examine: X, Pause: Menu, and "A to confirm, B for Back" |
| X3 | Controls | **B** | Back on the main menu, with Controls highlighted |
| X4 | On New Game | **A**. If it asks about replacing your save: D-pad right, then **A** | How to Play shows **only** the Xbox section |
| X5 | Begin | **A** | Play starts, and the sailor does **not** jump |
| X6 | Beside the boat | Nothing | The prompt reads **`[X] Examine`**, because the controller was the last thing used |
| X7 | Beside the boat | **X** | The boat's caption |
| X8 | Walk right to the fish | Left stick, then **X** | **`[X] Examine`** stays, then the fish's caption |
| X9 | Anywhere | **A** | The sailor jumps, with no caption |
| X10 | Beside something | **Y**, **LB**, **RB**, **View** | Nothing happens |
| X11 | Playing | **Menu** | Pauses, with Resume highlighted |
| X12 | Paused | **A** on Resume. Then pause and press **Menu**. Then pause and press **B** | Each resumes, with no jump and no caption |

**E. Optional.** These are outside the short check. Anything you skip stays pending, and stays listed as pending in the record.

| # | Where | Press | Expected label or behaviour |
|---|---|---|---|
| X13 | Paused | **X** | Nothing happens, and no caption afterwards |
| X14 | Beside the boat | A keyboard key, then a controller button | The prompt switches to your key, then back to `[X]` |
| X15 | Settings, on Interact | **A**, read the message, then **B** | "Press a key for Interact. **Esc or B cancels.**" B cancels only the capture, and a second B leaves Settings |
| X16 | Paused, on Quit to Main Menu | **A**, then **B** | The confirmation has Cancel highlighted, and B cancels it |
| X17 | Beside the boat | **Unplug it or switch it off,** while walking if you can | The prompt becomes your key, the game does not pause, and **the sailor does not keep walking** |
| X18 | After X17 | Reconnect, wait, then press a button | The prompt stays on your key until you press, then reads `[X]`. **X** examines |

X17's "keeps walking" is the one thing no automated test can reach, because tests cannot unplug a device.

Also optional: setting Interact to J in Settings, which the prompt should then name. Setting Interact to Jump's key, which names the clash and offers Swap or Cancel. The Left and Right arrows, which are refused as bindings. Clicking empty space and the sliders with the mouse, which keeps the highlight. Whether you can always tell what is highlighted, including on sliders.

**Deferred to M6, and not passed:** anything not individually reported, and **all physical PlayStation hardware.** If you have a PlayStation controller, the same tables apply with Cross, Circle, Square and
Options in place of A, B, X and Menu, and the prompt should read `[Square] Examine`. Native Linux GPU validation stays deferred to M6.

**Please report:** that you used the build above, pass or fail for A, B, C and D, anything confusing or wrong, and how the menus read on your display. Optional, if a label looks wrong: start with `dagon.exe --verbose --log-file playtest.log`, and
send the line starting `dagon: controller`. It names what your controller reports.

## 9. Carried to M3

- **Saving at each later beat.** Only Shore and Abyss exist as built worlds, so a save refers to no later beat (`LAST_BUILT_BEAT`). As each beat arrives, it needs the
  roadmap's regression test: the restored world is correct, no clip or cue replays, and consumed triggers stay consumed.
- Overlap re-checks after a beat, since today's layout has no trigger inside another.
- `GameDirector`'s cinematic contract, the Ending scene, and the final-sequence replay rules, which today are enforced by `is_savable` but have no real sequence to exercise them.

## 10. Review round 1

**Reported by the reviewer (ChatGPT) on `37f26fd`, relayed by the owner.** The findings came from source inspection, not from
running the engine. Each was reproduced with a regression test before anything was changed
([before the fixes](../evidence/m2/review-round-1/before-the-fixes.txt): 9 tests failing on the unfixed code).

| Finding | Reproduced? | Fix | Regression tests |
|---|---|---|---|
| **1. Settings focus recovery** used a hidden main-menu button | **Yes, and worse than described.** The engine releases focus from a hidden control at once, so focus stayed empty and could never come back anywhere in Settings or a conflict. | Recovery follows the active screen. Settings returns to a visible control, and a conflict returns to Swap without ending it. Nothing pending is reset. | `test_focus_lost_in_settings_comes_back_to_a_usable_control`, `test_focus_lost_in_a_conflict_comes_back_inside_the_choice`, `test_losing_focus_during_a_capture_changes_nothing`, `test_recovering_focus_keeps_unsaved_settings`, and two more in the pause menu suite |
| **2. Save-status feedback:** a stale warning after a good write, and none on reopening | **Yes, both.** The same fault also hid the warning when a capture or conflict was cancelled, or an unchanged key chosen. | The warning shows exactly while something is unsaved. Capture and conflict text replaces it, and it returns when they end. | `test_a_good_write_removes_the_warning_on_the_same_screen`, `test_reopening_with_unsaved_changes_still_says_so`, `test_instructions_replace_the_warning_and_it_returns_afterwards` |
| **3. Reserved-key wording** said "arrow keys", but only Left, Right and Esc are reserved | **Wording only.** `test_up_and_down_can_be_rebound_and_the_menu_still_works` passed on the unfixed code, so no behaviour needed changing, and no key was newly reserved. | The screen says "Left/Right arrows always move. Esc always pauses." D32, the GDD, the architecture and the README match. | That test, and `test_the_settings_screen_says_exactly_which_keys_are_kept` |

**Found while fixing these, in the same family, and also fixed:**
- The quit confirmation always said "Your settings are kept", even after a failed save. It now says otherwise.
  `test_quitting_with_unsaved_settings_does_not_claim_they_are_kept`
- "Defaults restored." stayed on screen after a later change, and a restore after an earlier failure needed care to report
  correctly. `test_restore_defaults_reports_what_really_happened`

**Nothing was disproved, but one correction to my own reasoning:** my code comment said a mouse click on empty space drops focus. Measured on
4.7.2, it does not, and focus stays where it was. `test_clicking_empty_space_keeps_focus_and_the_keyboard_working` records that, and
the comment is corrected. So finding 1 is real whenever focus is lost, but I found no ordinary way for a player to lose it: this is a
defensive recovery. That is why the manual checklist cannot trigger it directly.

**Can the new tests fail?** [10 deliberate breakages](../evidence/m2/review-round-1/breakage-of-the-fixes.txt), one at a time, including
each original bug put back: all 10 were caught, and the control passed before and after.

**Results at `24882e3`:**

| Check | Result | Who ran it |
|---|---|---|
| CI run [41630751633](https://github.com/shamsuzzamansadi/dagon/actions/runs/41630751633), Windows with MSVC 19.44.35229, Linux with g++ 11.4.0 | 58 unit test cases and **121 integration tests** pass on both. Smoke on both scenes, art check, the real storage probe, and release exports starting in `shore.tscn`, headless: all pass. | CI |
| Fresh clone of the commit, Ubuntu 24.04, GCC 13.3.0, Godot 4.7.2 | The same tests pass, and the integration suite repeated **10 of 10 clean** | Developer |

**By suite now:** movement 15, greybox 10, Shore 22, interaction 10, director and HUD 15, pause menu 17, settings 32.

**The reviewer has since reviewed these fixes, at `d78f5a6`.** The reviewer did not rerun the Godot tests. That review covers those fixes at that commit, and no later change. M2 acceptance stays pending the owner's manual check (§8).

## 11. Review round 2: Examine, the main menu and save, controllers, and the audio note

**The owner's reports, 2026-11-03:** Examine did nothing in the Windows build, under three keyboard layouts. Boxes appeared for key names under Bangla. A physical Xbox controller's tried controls worked, but
the menus did not explain the mappings, and the interaction button was unclear. **The owner also moved the main menu and save here from M3 (D36).**

### Root cause of the Examine failure

**The export silently drops a scene connection that starts inside an instanced scene.** `shore.tscn` connected `Player/Interactor` to `Hud`. Every test ran from the text scene, which keeps the
connection, so all of them passed while no exported build could ever show a prompt or caption, on any device. Full evidence, including what was ruled out: [evidence/m2/examine/](../evidence/m2/examine/README.md).

**My own review evidence hid this.** I captioned a startup image "with the prompt beside the boat" without looking at it. It shows no prompt. It is [corrected and disclosed](../evidence/m2/README.md).

**The boxes are a separate defect:** the layout's letter was drawn in an ASCII-only font. A letter the font cannot draw now falls back to the key's US name.

**Reviewer's result at `79981ea`, as relayed by the owner:** the Examine wiring fix, the exported-pack test coverage, the menu, session and save paths and the controller labels were reviewed, with no new blocking code defect identified in those areas. The reviewer independently ran 83 native test cases (994 assertions) and the art check, with zero problems, and confirmed CI run 41653352896 on both platforms. **The Godot integration tests and Windows gameplay were not independently rerun.** The relayed result covers the areas as a whole, so questions 1–5 here are kept as they were asked, not marked as answered one by one.

**Questions put to the reviewer:**

1. **Are other connections exposed?** `pause_menu.tscn` and `settings_menu.tscn` have scene connections between their own nodes, and these survive (the suite on the pack exercises them). `title.tscn` has them too. Is the rule in D37 the right boundary?
2. **The suite on the pack (D38)** runs from a debug process that mounts the exported `.pck`, because a release template cannot run scripts. Exported release builds are separately checked by proof lines. Does that leave a gap?

### What changed

| Area | Files |
|---|---|
| Examine | `src/hud.*` connects in code. `tools/export_check.sh` runs the suite on the pack, and New Game and Continue in the exported build |
| Key names | `storage::displayed_key_name` |
| Main menu, Controls, Credits, introduction | `scenes/ui/title.tscn`, `src/menu_controller.*`, `scenes/ui/pause_menu.tscn` |
| One save slot | `src/core/save_data.*`, `src/core/story_progress.*`, `src/storage.*` (safe replacement, with a backup) |
| World replacement | `src/game_session.*`, `scenes/level/game.tscn`. `src/game_director.*` gained `StoryProgress` |
| Controller labels | `src/core/controller_labels.*` (plain C++), `src/input_labels.*`, `src/hud.*`, `src/menu_controller.*` |
| Tests | `test_session.gd`, `test_title.gd`, `test_controller.gd`, `session_probe.gd`, `title_quit_probe.gd`, `test_story_progress.cpp`, `test_save_data.cpp`, `test_controller_labels.cpp` |

**Unchanged:** movement tuning, collision, the camera and the accepted art. The font gained Ä, Ö, Ü and ß. No environmental art, and no audio: only volume controls and buses prepared.

**D26 and D27 are applied as designed.** New Game never reads the old save and confirms before replacing it. A failed write stays in the menu with Retry. The session checkpoint and persisted save are separate. Replacement goes through a
temporary file, with a backup taken only from a valid primary. Witness, Fleeing and Ended are not savable, so an unfinished sequence replays from the checkpoint before it.

**Scheduling tradeoff:** see the roadmap, "Menus and save". No dates move, M3 gets lighter, and M2's larger review is now the thing M3 waits on.

### Controllers

| Button (by position) | Action | Xbox | PlayStation | Unrecognized |
|---|---|---|---|---|
| South | Jump, confirm | A | Cross | Bottom face button |
| West | Interact | X | Square | Left face button |
| East | Back | B | Circle | Right face button |
| Start | Pause | Menu | Options | Start |

**The mapping is verified at two levels:** a test reads the real `InputMap`, and the engine's own event names agree that button 2 is "Left Action, Sony Square, Xbox X". The same data drives the prompt and Controls.

**Tests simulate; only the owner's hands are physical.** `test_controller.gd` names a controller through `DAGON_TEST_CONTROLLER` and injects events, because Godot cannot create a device from a script. That proves the labels, routing and focus for each layout. It proves nothing about a real controller's buttons reaching the game.

| What | Automated, simulated | Physically tried |
|---|---|---|
| Prompts and Controls per layout, both menus | Yes | |
| West button examines at the boat and fish, Xbox and PlayStation | Yes, on the exported pack too | Not individually reported: X7, X8 |
| Switching device, disconnect, reconnect, another device's disconnection | Yes, by emitting the engine's signal | Not individually reported: X14, X17, X18. **Deferred to M6** |
| Focus, confirm and Back, in both menus, by D-pad and left stick | Yes | Not individually reported: X1–X3, X15, X16 |
| Resume or Begin without a jump or examine | Yes | Not individually reported: X5, X12, X13 |
| Driver reports a real controller, and the game classifies it | | **Yes:** `XInput Controller`, vendor `0x045E`, classified as Xbox, on this Windows machine, with nothing pressed |
| "The controls I tried worked correctly" | | **Owner, unspecified buttons** |
| Any PlayStation hardware | Labels only | **No. Deferred to M6** |
| Console platforms | | **Not established, and not a target** |

**Questions put to the reviewer, continued:**

3. **Recognition by name, then vendor (D39).** A third-party pad in XInput mode reports as Xbox. Is that right, given that its buttons follow the Xbox layout?
4. **Ownership of the active device (D40).** `MenuController` tracks it and passes it down. Is there a path where the Hud shows a stale device?
5. **The stick's test (a finding about the harness).** A stick's menu navigation failed inside the suite but worked in isolation. Tests resume inside a physics tick, and the engine's stick navigation needs `is_action_just_pressed`, which input from mid-tick only satisfies on the next tick. Sending it from a process frame passes. Real input does not arrive mid-tick, so I treated this as test-only, and `harness.send_between_ticks` documents it.

### After the review at `79981ea`: what changed

**None of this has been reviewed, and the results above do not extend to it.** A focused follow-up needs only `git diff 79981ea 3426d3b`.

| Change | File | Why |
|---|---|---|
| The note "This build has no audio yet." below the sliders | `scenes/ui/settings_menu.tscn` | The owner's clarification ([D42](../decisions.md)). A plain `Label`, with no code change |
| Three tests of the note | `tests/test_settings.gd` | See below |
| A new game and Continue clear a pause or time scale left behind | `tests/test_title.gd` | Breakage showed nothing tested it |
| The main menu keeps the active controller, checked by what the player reads | `tests/test_controller.gd` | Breakage showed the old check could not fail: Controls list every connected controller whichever is active |
| Documents, and the workflow in D43 | `README.md`, `docs/` | |

**The game's C++ did not change after `8da9a2e`.** `git diff --stat 8da9a2e 3426d3b -- src` is empty, and `project/` differs only by that one scene and those three test files.

### The audio note

| Requirement | Result | How it was checked |
|---|---|---|
| Reads exactly "This build has no audio yet.", directly below the sliders | Yes, in both menus | `test_the_audio_note_shows_and_fits_in_both_menus`. Seen on the real build: [from the main menu](../evidence/m2/review-round-2/windows/04-settings-note-music-focused.png), [from the pause menu](../evidence/m2/review-round-2/windows/12a-settings-note-from-pause-menu.png) |
| Fits without clipping | One line: 132 px of text in a 232 px row. The panel is 213 px tall on the 270 px canvas, and it still fits in the tallest states | `test_the_audio_note_and_all_of_settings_fit_in_every_state`: capture, refusal with the longest device name, conflict, and a failed save |
| Does not interfere with navigation or focus | It takes no focus or clicks. Up and Down, by arrow keys and D-pad, and Down by left stick, step over it | `test_the_audio_note_never_takes_focus_from_keys_or_a_controller` (simulated). On the real build, with posted keys: [Effects](../evidence/m2/review-round-2/windows/04a-settings-effects-focused.png), then [Move Left](../evidence/m2/review-round-2/windows/04b-settings-focus-stepped-over-the-note-to-move-left.png) |
| Sliders and saved values unchanged | Same behaviour: separate buses, saved, and restored after a relaunch | The existing tests still pass, breakage of the sliders is caught (below), and the scripted Windows run read `settings.cfg` before and after a relaunch |
| **Physically** checked | Not individually reported. The owner accepted the build they tested, without itemizing this | The owner |

**Described as "volume controls and buses prepared", never "audio implemented".** Environmental audio, footsteps, object and interaction sounds and story cues stay in M4 and M5. The note and its tests are removed when audio is connected, and the roadmap says so.

### Results

**At the tested commit, `3426d3b`:**

| Check | Result | Who ran it |
|---|---|---|
| CI run [41682543058](https://github.com/shamsuzzamansadi/dagon/actions/runs/41682543058), Windows with MSVC 19.44.35229, Linux with g++ 11.4.0 | **83 unit test cases pass, and 195 integration tests pass from source and again on the exported pack,** on both. Extension load with 10 classes and 0 problems, smoke on each scene, art check with 0 problems, the real storage probe, and release exports that start on the main menu and run New Game and Continue: all pass | CI |
| Fresh clone from GitHub, following the README, Ubuntu 24.04, GCC 13.3.0, Godot 4.7.2 | **Still running when this was committed.** It builds with no compiler warnings. 83 test cases and 994 assertions pass, and so do all 195 integration tests. The art check finds 0 problems, and the art regenerates identically. The suite's repeats had reached 7 of 10, all clean. The ten repeats and the Linux export check had not finished, so this line is not yet a complete result. | Developer |

**By suite:** movement 15, greybox 10, Shore 22, interaction 10, director and HUD 14, pause menu 18, settings 37, session 21, main menu 25, controller 23.

**Not rerun by the reviewer.** The reviewer's own runs are the 83 native test cases (994 assertions) and the art check, at `79981ea`. CI at `79981ea` was run [41653352896](https://github.com/shamsuzzamansadi/dagon/actions/runs/41653352896), which the reviewer confirmed.

### On the real Windows build: developer-scripted, not physical

**Everything in this section is scripted window messages, sent to the game's window only.** That reaches the game's real input path, and says nothing about a physical keyboard or controller. No controller button was pressed. **The owner's manual testing is separate (§8).**

**Build:** `dagon-windows` from CI run [41682543058](https://github.com/shamsuzzamansadi/dagon/actions/runs/41682543058), commit `3426d3b`, SHA-256 `cbfca7c95e25852e5c7a45438806751a0e8df637d093bd7f1e34253d0fa2a434`, which equals GitHub's digest. This is the same zip §8 asks the owner to test. Isolated data folders, on an NVIDIA GeForce RTX 5060 Ti with OpenGL 3.3, at 1440×810. I viewed all 30 [screenshots](../evidence/m2/review-round-2/windows/). Text output: [windows-run-summary.txt](../evidence/m2/review-round-2/windows-run-summary.txt).

| Step | Result | Screenshots |
|---|---|---|
| Launch | Main menu. New Game focused, Continue disabled, "No saved game yet." | `01` |
| Controls and Credits from the main menu | Both open and return | `02`, `03` |
| Settings from the main menu | The note is on one line below the sliders. Music moves to 0.9 and Effects to 0.7, and `settings.cfg` shows both. Focus goes Effects, Move Left, and back up to Effects | `04`–`04c` |
| New Game | The save is written, and How to Play shows | `05` |
| Prompt and caption at the boat, then the fish | `[E] Examine`, then each caption | `06`–`09` |
| Pause, Restart Checkpoint, then again at the boat | Prompt and caption both work | `10`–`12` |
| Settings from the pause menu | The note is there, and five Down presses still reach Interact, because the note takes none | `12a` |
| Rebind Interact to J | `[J] Examine`, no caption. E does nothing. J shows the boat's, then the fish's caption | `13`–`17` |
| Controls from the pause menu | Shows J | `18` |
| Walk and hop to the checkpoint past the trench | "Checkpoint saved", and `save.dat` holds `beat=abyss checkpoint=PastTheTrench` | `19` |
| Quit to Main Menu | The confirmation says what is kept, with Cancel focused. Continue is focused afterwards | `20`, `21` |
| Quit to Desktop | Exit code 0 | |
| Relaunch | Continue is focused. The volumes and J have survived. Continue returns to the checkpoint, and so does Restart | `23`–`26` |
| Physical input during the run | **None,** as reported by the driver, with the game's window focused | |
| Keyboard layout | Read as `04090409` before and after every run. **The driver has no call that can change it** | |

**Not run on this build:** another keyboard layout, at the owner's request, and any controller. No controller was connected to these runs, so physical controller behaviour rests on the owner's own testing alone, plus the simulated suite on the exported pack.

**One unexplained event, disclosed.** In the first run of this build, on a loaded machine, an examine fired once with nothing posted to the game for six seconds, so screenshots 14 and 15 were wrong, although the run's exit status was clean. That run did not yet record physical input, and the game's window had focus on the owner's desktop, so a real J key is possible but not shown. A focused test showed the old key does nothing, and three more full runs, one idle and two with 9 busy threads, roughly the first run's load, were all correct. **It did not reproduce, and its cause is not established.** Details and frames: [the record](../evidence/m2/review-round-2/README.md).

**The earlier run, at `8da9a2e`:** every step in the [record](../evidence/m2/examine/README.md) passed on that `dagon-windows` artifact, including the Bangla layout with no boxes. **Found by looking, not by the run's exit status:** in my first pass, the boat caption was still fading from an earlier step, so "E does nothing" and "J examines the boat" looked identical and proved nothing. I changed the steps to wait for the caption to clear, and reran them.

### Can the tests fail?

**The final run, at `3426d3b`: [57 deliberate breakages](../evidence/m2/review-round-2/breakage-at-3426d3b.txt), one at a time, and all 57 caught.** Every control passed, before and after. Simulated input only.

- **The original Examine defect, put back:** the source suite still passes all 195, and the export check fails with "the exported game showed no prompt beside the boat". That is the exact gap D38 closes.
- **14 are new, for the note and the sliders:** the note removed, reworded to claim audio, hidden, focusable, clickable, too wide, clipped, wrapped, or moved away from the sliders, either slider disconnected, Effects moving the Music volume, and either volume neither applied nor saved.

**The earlier run, at `8da9a2e`: [43 breakages](../evidence/m2/review-round-2/breakage-at-8da9a2e.txt), 40 caught and 3 not.** It tested the same game code as the reviewer's `79981ea`. It is superseded, and these are the three:

| Not caught | Why | What happened |
|---|---|---|
| An unknown controller gets Xbox's letter | **An invalid result, caused by my own tooling.** A second script force-reverted that working copy during this change, so the change was not in the build. A separate clean run caught it by unit test | Caught in the final run |
| Quit to Main Menu forgets the device | **A real test gap.** The check read Controls, which list every connected controller whichever is active, so it could not fail | The test now reads what a key capture tells the player, and the reported device. Caught in the final run |
| A new game leaves the old state | **A real test gap.** Nothing tested the reset when starting a game | A new test covers New Game and Continue. Caught in the final run |

**The state of the two runs the owner asked to collect:** this breakage run was still going, and finished. The fresh clone of `79981ea` had already stopped: it [ended after repeat 5 of 10](../evidence/m2/review-round-2/fresh-clone-at-79981ea-incomplete.txt) when its session ended, with everything it reached passing. It is not a complete result, and the results above replace it.

**Not exercised:** the read-back check in `storage::replace_file`, as in §4.

**M2 is accepted by the owner for merge ([record](../evidence/m2/owner-acceptance-2026-11-03.md)).** The reviewer's results still stop at `79981ea`, and exclude the Godot integration tests and Windows gameplay. All physical PlayStation hardware, and the other checks the record lists, stay deferred to M6 and are not passed.
