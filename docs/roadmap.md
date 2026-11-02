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
| M2 Interaction | Nov 6–8 | Interactable, Interactor, StoryTrigger, Hud (prompt, caption, fade), `interact` and `pause` mappings, kill plane and checkpoints, PauseMenu, `reset_global_state` | Integration tests: focus, disabled or freed focus, double press, one-shot, trigger re-arm, respawn, pause → restart |
| M3 Complete gameplay (greybox) | Nov 9–14 | Full 4-act greybox layout, SequencePuzzle and PuzzleController, StoryProgress and GameDirector with the full cinematic contract, placeholder clips, flee timer, Title and Ending scenes | Start→end greybox playthrough. All M3 regression tests in architecture §8. |
| M4 Atmosphere | Nov 15–19 | **Final asset-production decision before Nov 15.** **First deliverable: one short playable Shore section near final quality, shown for visual review before the treatment spreads** ([GDD §8](gdd.md)). Then parallax, CanvasModulate, lantern, occluders, fog shader, ambience per act, footsteps, silhouette art through the level | Visual review evidence and acceptance checklist in GDD §8; readability on 2 displays; smoke test clean; frame time checked |
| M5 Cinematic horror | Nov 20–23 | Dagon silhouette and animation, the `monolith_awaken`, `dagon_reveal` and `collapse` clips, shake, baked audio sweeps, epilogue | Full playthrough with final content; GDD §8 checklist on the reveal; cinematic regression tests still green |
| M6 Stabilization | Nov 24–27 | Fixes from at least 2 external playtests, timing (10–15 min), performance, release workflow, native runs on Windows and Linux | Release candidate artifacts from CI launched on real Windows and Linux; GDD §8 checklist on every scene |
| M7 Publication prep | Nov 28–29 | itch page assets, README, CREDITS, licenses, release notes, AI disclosure text (jam.md §5), tag | The owner uploads and submits. **Internal target: submitted by Nov 29 21:37 UTC.** Downloaded build verified on both OSes. |
| Buffer | Nov 30 – Dec 1 21:37 UTC | Only fixes to upload or packaging problems. No features. | — |

**Cut order if the schedule slips (approved):**
1. Stretch work.
2. Optional props.
3. Extra parallax layers.
4. Elaborate effects.
5. Animation variety.

Never cut the playable loop, readable clues, the reveal, or the export checks.

## Status checklist

- [x] Phase A approved (2026-10-28).
- [x] Repository created and in use: https://github.com/shamsuzzamansadi/dagon
- [x] G0: theme SHIFT, fit recorded in jam.md §4 (2026-11-02).
- [ ] **M1 Foundation: implemented; at the M1 review gate. NOT accepted.** Evidence and
  open items are in [reviews/m1-review-package.md](reviews/m1-review-package.md).
  Outstanding before acceptance: human movement-feel and physical-gamepad check,
  native run of the Windows export, independent review.
- [ ] M2–M7 not started.

## Review follow-ups by milestone (Phase A final review, 2026-10-28)

| Milestone | Follow-up | Where specified |
|---|---|---|
| M1 | Test observation point: `SceneTree.physics_frame` fires *before* node `_physics_process`. Use the `StepProbe` post-step point and **verify** its ordering with a test. | architecture §8 |
| M1 | Re-collect the import-crash evidence on the real project with `reproduce.sh`-style capture (exit status, stdout and stderr per run). | toolchain §5, evidence README |
| M2 | Test Interactor delivery and consumption with `Input.parse_input_event()` and `InputEventAction`. `action_press` covers polled input only. | architecture §8 |
| M3 | `call_deferred` does not wait for a physics frame. Overlap re-checks wait for a completed physics step (`physics_frames >= recorded + 2`). | architecture §5, GameDirector |
| M3 | Out-of-bounds during a cinematic is kept as `recovery_pending`, then re-checked after finalization. Regression: entering the kill plane while control is locked. | architecture §5 and §8 |

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
8. The greybox scene runs 600 headless frames with no `ERROR:` output. *Scene
   load.*

**Runtime and export**
9. `tools/prepare_project.sh` then a single headless import exits 0 on a clean
   checkout, locally and in CI. Any non-zero exit fails. The import-crash
   evidence is re-collected on the real project for the M1 package. *Scene
   load.*
10. The export templates are downloaded and their SHA-512 verified against
    the official `SHA512-SUMS.txt` (local and CI).
    - The Linux release export is created headless and runs
      `--headless --quit-after 300` with exit 0 and no `ERROR:` lines.
    - The Windows release export is created.

    *Desktop export.*
11. A human runs the Windows export natively and the Linux build: walk and jump
    feel responsive on keyboard and on a physical gamepad. *Manual playtest.
    Reported separately, never assumed.*

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
