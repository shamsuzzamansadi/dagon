# Roadmap: seven milestone gates within Game Off 2026

**Window:** 2026-11-01 (theme announcement) to **2026-12-01 21:37 UTC** (hard
deadline). See [jam.md](jam.md).

Each milestone ends with a gate: build → tests → runtime check → honest
report → review package → confirmed fixes. Allow about half a day per gate for
the review round trip.

Complete gameplay comes before atmosphere (approved, D11). Stretch work
starts only after M6 is green, and is time-boxed.

## Schedule (dates are UTC targets, not promises)

| Gate | Target window | Scope | Exit gate |
|---|---|---|---|
| G0 Start | Nov 1–2 | Theme read and theme-fit note (jam.md §4); owner approves any proposal | Theme fit recorded; no open blocking rule question |
| M1 Foundation | Nov 2–5 | See "M1 scope" below | M1 acceptance below |
| M2 Interaction and usability | Nov 6–8 | Interactable, Interactor, StoryTrigger, Hud (prompt, caption, fade), `interact` and `pause` mappings, kill plane and checkpoints, `reset_global_state`. Pause menu, persistent settings and keyboard rebinding ("M2 usability" below). **Moved from M3 by the owner (D36):** main menu, Controls, Credits and one persistent checkpoint save slot ("Menus and save" below). Controller labels and mappings explained | Integration tests: focus, disabled or freed focus, double press, one-shot, trigger re-arm, respawn, pause → Restart Checkpoint. M2 usability checks, and the checks in "Menus and save" for the beats that exist. Exported-pack suite. |
| M3 Complete gameplay (greybox) | Nov 9–14 | Full 4-act greybox layout, SequencePuzzle and PuzzleController, GameDirector's full cinematic contract, placeholder clips, flee timer, Ending scene. Saving extended to each beat as it is built | Start→end greybox playthrough. All M3 regression tests in architecture §8, including quit, relaunch and Continue at each beat. |
| M4 Atmosphere | Nov 15–19 | **Final asset-production decision before Nov 15.** **First deliverable: one short playable Shore section near final quality, shown for visual review before the treatment spreads** ([GDD §8](gdd.md)). Its art direction is already accepted (D19); this brings that section to final quality. Then later environments in the accepted Shore style, parallax, CanvasModulate, lantern, occluders, fog shader, ambience per act, footsteps and object sounds, silhouette art through the level, and a coherent transition beyond the Shore. Volume settings connected | Visual review evidence and acceptance checklist in GDD §8; readability on 2 displays; smoke test clean; frame time checked; audio heard in gameplay before it is marked complete |
| M5 Cinematic horror | Nov 20–23 | Dagon silhouette and animation, the `monolith_awaken`, `dagon_reveal` and `collapse` clips, shake, baked audio sweeps, story-trigger cues, epilogue | Full playthrough with final content; GDD §8 checklist on the reveal; cinematic regression tests still green; audio heard in gameplay before it is marked complete |
| M6 Stabilization | Nov 24–27 | Fixes from at least 2 external playtests, timing (10–15 min), performance, release workflow, native runs on Windows and Linux, usability verification ("M6 verification" below) | Release candidate artifacts from CI launched on real Windows and Linux; GDD §8 checklist on every scene; M6 verification passed |
| M7 Publication prep | Nov 28–29 | itch page assets, README, CREDITS, licenses, release notes, AI disclosure text (jam.md §5), tag | The owner uploads and submits. **Internal target: submitted by Nov 29 21:37 UTC.** Downloaded build verified on both OSes. |
| Buffer | Nov 30 – Dec 1 21:37 UTC | Only fixes to upload or packaging problems. No features. | — |

**Cut order if the schedule slips (approved):**
1. Stretch work.
2. Optional props.
3. Extra parallax layers.
4. Elaborate effects.
5. Animation variety.

Never cut the playable loop, readable clues, the reveal, or the export checks.

**Priority (owner, [D28](decisions.md)):** gameplay progression, correctness, basic menus, safe checkpoint
persistence, readable visuals, and essential environmental and story audio come ahead of optional display features
and additional decorative polish. If the schedule slips, the specific tradeoff is flagged early. Requested key
rebinding and save support are never removed silently (risk R20).

## Status checklist

- [x] Phase A approved (2026-10-28).
- [x] Repository created and in use: https://github.com/shamsuzzamansadi/dagon
- [x] G0: theme SHIFT, fit recorded in jam.md §4 (2026-11-02).
- [x] **M1 independent technical review complete (2026-11-02), with limits** ([package §17](reviews/m1-review-package.md)).
  No new blocking findings at `3301ae0`. The reviewer reran the native tests and the art check. Godot integration
  tests, engine rendering and release exports rely on the supplied CI evidence.
- [x] **M1 Foundation: accepted by the owner with documented deferrals (2026-11-02),** not every manual check having
  passed ([package §16](reviews/m1-review-package.md)). The owner reports positive general feedback on Windows movement
  and camera ([record](evidence/m1/windows-playtest-2026-11-02-standard-build.md)), and ran Linux with software
  rendering ([record](evidence/m1/linux-playtest-2026-11-02.md)). **Deferred to M6, before release:** physical gamepad
  testing, and native Linux hardware-accelerated rendering validation. The exact provenance of the recorded builds stays
  unconfirmed, which the owner accepts for M1.
- [x] **Shore art direction accepted by the owner (2026-11-02) and integrated as the entry scene**
  ([D19, D20](decisions.md), [shore-preview.md](shore-preview.md)). The art stops at the cliff opening
  (x = 640), and everything past it is unfinished greybox: a documented boundary, not a finished
  transition. **This is not M4,** and it closes none of the M1 checks above.
- [ ] **M2: implemented on branch `m2/interaction-and-usability`, at the M2 review gate, not merged**
  ([package](reviews/m2-review-package.md)). The main menu and save moved here from M3 (D36). Acceptance waits on the focused
  follow-up review and the owner's manual checks. M3–M7 not started.
- **Every later playtest identifies the exact artifact or run it tested.**

## Review follow-ups by milestone (Phase A final review, 2026-10-28)

| Milestone | Follow-up | Where specified |
|---|---|---|
| M1 | Test observation point: `SceneTree.physics_frame` fires *before* node `_physics_process`. Use the `StepProbe` post-step point and **verify** its ordering with a test. | architecture §8 |
| M1 | Re-collect the import-crash evidence on the real project with `reproduce.sh`-style capture (exit status, stdout and stderr per run). | toolchain §5, evidence README |
| M2 | Test Interactor delivery and consumption with `Input.parse_input_event()` and `InputEventAction`. `action_press` covers polled input only. | architecture §8 |
| M3 | `call_deferred` does not wait for a physics frame. Overlap re-checks wait for a completed physics step (`physics_frames >= recorded + 2`). | architecture §5, GameDirector |
| M3 | Out-of-bounds during a cinematic is kept as `recovery_pending`, then re-checked after finalization. Regression: entering the kill plane while control is locked. | architecture §5 and §8 |
| M3–M4 | The art ends at x = 640, at a straight edge of the right cliff, and its cleft is a placeholder way through. Replace both as the later environments arrive, in the accepted Shore style. | [shore-preview.md](shore-preview.md) |
| M4 | Sailor animation: stop, turn and landing frames, coat motion, and turning that mirrors the lantern to the other hand. The walk speed stays unchanged: the owner's general feedback so far is positive. | [shore-preview.md](shore-preview.md) |
| M4 | Rest of the first M4 deliverable: sound, caption and prompt styling, fog and lantern pass, readability on a second display, and the sailor's size on screen. | GDD §8, [shore-preview.md](shore-preview.md) |

## Owner direction for later milestones (recorded 2026-11-02, not started)

Priority stays on correct
gameplay, coherent visuals and bug fixes. No new art redesign is requested. Later environments arrive
through the planned milestones, in the accepted Shore style.

Decisions: [D23–D26](decisions.md). Player-facing rules: [GDD §11](gdd.md). Design: architecture §5.

**SHIFT (M3, M5).** At each relevant story beat, carry SHIFT through a visible event and sound, not only
documents. No dimension-switching mechanic, no wider scope ([jam.md](jam.md) §4).

### M2 usability

- Pause menu: Resume, Restart Checkpoint, Settings, Quit to Desktop. Pausing stops gameplay appropriately
  while the menu stays responsive.
- Keyboard and gamepad menu navigation, reliable focus, and a usable Back/Cancel action.
- Basic persistent settings, saved separately from game progress: music volume, effects volume and key
  bindings. M2 delivers volume controls and buses prepared, not audio. They are connected when audio exists (M4), and until
  then Settings says "This build has no audio yet." ([D42](decisions.md)).
- Keyboard rebinding for gameplay actions. Conflicts are explained, defaults can be restored, and menu
  navigation and Back cannot be rebound, so nobody can trap themselves.

**Exit checks:**
- While paused, movement, timers and clips stop and the menu still takes input. Resume continues; Restart
  Checkpoint returns to the active checkpoint, unpaused.
- A control always has focus. Leaving Settings returns focus to where it was. One Back press closes one level.
- Conflicts are explained, no action ends up unbound, a key capture can be cancelled from keyboard or gamepad,
  defaults restore, and bindings survive a relaunch.
- Missing or corrupt settings fall back to defaults, with no way to get stuck.
- Simulated input does not prove physical devices, so the owner checks a real keyboard and controller.
- Controls explains the controller in both menus, and prompts name the button for the device in use (D39). A controller
  must produce the prompt and caption at the boat and the fish, as the keyboard does.

### Menus and save (moved from M3 to M2 by the owner, 2026-11-03, D36)

**Scheduling tradeoff, flagged as D28 asks.** M2 was on Nov 6–8 and M3 on Nov 9–14. This work was planned for M3's window and was
done before M2's gate instead, so **no target date moves, and M3 gets lighter by this much.** The cost is one that dates do not
show: M2 now has more to review, and M3 cannot start until M2 is accepted, so a long review round takes time directly from the
4-act greybox, which is the part of the game that matters most. If that gate runs past about Nov 9, the first thing to give way is
the Nov 15 start of M4's polish, by the existing cut order, not the playable loop. Only the Shore and Abyss beats are built, so **the checks below
for later beats stay in M3,** as those beats arrive.

- Main menu on launch: New Game, Continue, Settings, Controls, Credits, Quit to Desktop. It is the main scene.
- The pause menu gains Controls and Quit to Main Menu.
- Starting a new game shows a short introduction to the controls.
- One persistent checkpoint save slot. Continue restores the last safe checkpoint after the application has
  been closed and reopened. **This is an intentional scope change: the GDD excluded saves (D25).** No multiple
  slots, and no saving at an arbitrary position.
- It saves stable story and puzzle progress and checkpoint identity, not live node references or mid-cutscene
  state.
- Completed world outcomes restore correctly, without replaying one-shot events or creating softlocks. An unfinished
  reveal or escape may replay from the preceding safe checkpoint (D27).
- Safe file replacement and versioned data. Missing, corrupt or incompatible saves are handled gracefully.
- New Game confirms before replacing existing progress. The game shows when checkpoint progress has been saved.
- Restart Checkpoint uses the session checkpoint, and Continue after a relaunch uses the last valid disk save (D26).
- The last checkpoint stays after the ending, and the menu explains that Continue resumes before the final sequence.
- Quitting or returning to the main menu makes the checkpoint behaviour clear, and never implies that unsaved progress
  has been persisted.

**Exit checks,** with focused failure-path tests for each behaviour in [D26](decisions.md):
- Unit: save data round trip; missing, truncated, corrupt and wrong-version data; beats that may not be saved
  are refused.
- For each savable beat: the restored world is correct, no clip or cue replays, consumed triggers stay
  consumed, and the player can always go on.
- Two separate processes, in one unique test directory: the first saves and exits, the second Continues.
- New Game with a failed write stays in the menu with an error and Retry, and the old save is unchanged and unread.
- After an autosave failure, Restart Checkpoint returns to the session checkpoint, Continue after a relaunch returns to
  the last valid disk save, and the quit text says so.
- Replacing the world removes the old world's active signals and callbacks, and the new director has its checkpoint
  before it enters the tree. Restart resets pause, and repeated restarts produce no duplicate events.
- Every on-disk state an interrupted replacement can leave loads a usable save, and a corrupt primary never overwrites
  a valid backup.
- Every scene that reads files in `_ready` uses the test directory, and the real `user://` listing is unchanged by a run.
- New Game's confirmation defaults to Cancel, Continue is unavailable without a usable save, and a failed write
  shows no "saved" notice.

### M4 and M5 audio and transition

- Keep the planned original environmental audio and footsteps and object sounds (M4), and story-trigger cues
  (M5), as in GDD §7.
- Make the transition beyond the Shore visually and sonically coherent, replacing the documented boundary at
  the cliff opening.
- Deliver a compact event-to-sound list and show the mix in gameplay. Check loop seams, abrupt transitions,
  clipping, repeated-trigger stacking and whether important cues stay audible.
- Connect the music and effects volume settings prepared in M2. **When audio is connected, remove the temporary Settings note,
  "This build has no audio yet.", and its tests** ([D42](decisions.md)).
- **Audio is not marked complete until a person has heard it in gameplay.** Automated checks cannot do this.

### M6 verification

Verify settings and save persistence, rebinding, menu focus, quit/relaunch/continue, and display usability.
720p and 1080p presentation stays secondary to correctness and readable visuals.

**Deferred from M1, and required before release:**
- Physical controller testing. **Moved earlier in part:** the owner reports that the Xbox controls they tried worked
  ([record](evidence/m2/xbox-feedback-2026-11-03.md)), and the M2 manual checklist names each Xbox button. Whatever that leaves
  open stays here, including all PlayStation hardware. Labels and mappings themselves were not deferred, and are M2 work.
- Native Linux hardware-accelerated rendering validation. The M1 Linux run used software rendering.

- **Displays:** ordinary players on 1280×720 and 1920×1080, windowed and fullscreen. Text stays readable
  and nothing clips.
- **Resolution:** keep the 480×270 canvas and the pixel-art direction unless there is a demonstrated reason
  to change them. It scales exactly 4× to 1080p.
- **720p:** 270 does not divide 720 evenly (2.67×). Choose and test an aspect-preserving presentation with
  no stretching or uneven-looking pixels. The current integer scale mode would give 2× (960×540) with bars,
  which is the first candidate to test, not a decision.
- **Not yet checked:** the default 1440×810 window is larger than a 720p screen, and there is no fullscreen
  option yet.

## M1 scope

- Reproducible setup and pinned dependencies (toolchain §1), plus
  `tools/prepare_project.{sh,ps1}`.
- C++20 movement core (`core::step` with `FloorContact`) and meaningful unit
  tests.
- PlayerController, a basic CameraRig (follow and limits), a small Act I
  greybox.
- **Keyboard and gamepad mappings for `move_left`, `move_right` and `jump`.**
- Extension-load, movement integration and smoke tests.
- Linux and Windows build validation, desktop export checks, Windows runtime
  extension load.
- The approved export-template download with official checksum verification.
- Clean-checkout build instructions.

Not in M1: interaction, puzzle, story, menus, final atmosphere.

## M1 acceptance criteria

Each criterion names its verification level (see architecture §8).

**Build**
1. A clean `git clone --recurse-submodules` puts godot-cpp at `507ed9d`.
   `.gitignore` excludes `.godot/`, `project/bin/*/`, the build outputs and
   `.venv/`.
2. On Linux, `scons platform=linux target=template_debug` and `template_release`
   succeed using only the README commands. *Compilation.*
3. `static_assert(__cplusplus >= 202002L)` compiles in our sources on GCC and
   MSVC. *Compilation (CI).*
4. Windows MSVC `template_debug` and `template_release` builds succeed in CI.
   *Compilation (CI).* The **exact `cl` version** is recorded from the log;
   `windows-latest` is not treated as a pin.

**Tests**
5. `scons unit_tests` builds and passes on Linux and Windows. Coverage:
   - acceleration to cap and deceleration to 0
   - jump only when grounded or within coyote time
   - jump buffer
   - jump cut
   - fall-speed clamp
   - no double jump
   - `Unknown` contact grants no jump, no coyote refresh and no landing

   *Unit.*
6. Headless `check_classes.gd` on Linux, **and on Windows against the MSVC
   debug and release libraries**: `PlayerController` and `CameraRig` are
   registered, and their exported properties exist. *Extension load.*
7. Headless integration, following the rules in architecture §8, including a
   test that verifies the `StepProbe` post-step observation point:
   - (a) the player lands on the floor within 60 frames of spawning;
   - (b) holding `move_right` for 60 frames moves x by more than 50 px;
   - (c) pressing `jump` leaves the floor and the player lands again within
     90 frames;
   - (d) the player cannot pass the end wall;
   - (e) with control disabled, input does not move the player;
   - (f) **teleport contact invalidation:** start grounded, teleport to a
     mid-air point high enough that the fall lasts longer than
     `jump_buffer_time`, and press `jump` in the same frame (before any fresh
     `move_and_slide`). Expect no jump, no coyote jump, and no `landed` until
     real contact. Then `landed` fires exactly once, and a normal jump works
     afterwards;
   - (g) **buffered jump preserved:** teleport to just above the floor and
     press `jump`. The buffered jump fires on the genuine landing.

   *Gameplay test.*
8. The greybox scene runs 600 headless frames with no `ERROR:` output, and so does the
   entry scene (the Shore). *Scene load.*

**Runtime and export**
9. `tools/prepare_project.sh` then a single headless import exits 0 on a clean
   checkout, locally and in CI. Any non-zero exit fails. The import-crash
   evidence is re-collected on the real project for the M1 package. *Scene
   load.*
10. The export templates are downloaded and their SHA-512 verified against
    the official `SHA512-SUMS.txt` (local and CI).
    - The Linux release export is created headless and runs
      `--headless --quit-after 300` with exit 0 and no `ERROR:` lines, starting in the Shore.
    - The Windows release export is created.

    *Desktop export.*
11. A human runs the Windows export natively and the Linux build: walk and jump
    feel responsive on keyboard and on a physical gamepad. *Manual playtest.
    Reported separately, never assumed.* **Accepted with deferrals, not fully passed:**
    see [package §16](reviews/m1-review-package.md).

**Process**
12. CI is green on push: build matrix, unit tests, Godot tests, Windows load.
13. `README.md` has clean-checkout instructions for Linux and Windows,
    including the prepare script.
14. The M1 review package is prepared:
    - commit hash and revised documents;
    - exact tool versions, commands, logs and results;
    - import-workaround evidence;
    - export artifacts and runtime results;
    - automated checks and human playtests reported separately;
    - failures, skipped checks, unavailable platforms and remaining risks.

    The work then **stops at the M1 gate**.
