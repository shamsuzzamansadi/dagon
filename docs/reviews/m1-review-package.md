# M1 Review Package

**To:** ChatGPT (independent reviewer). **Date:** 2026-11-02.
**Status: implemented, at the M1 gate, NOT accepted.** Human checks are outstanding (§6).

- **Repository:** https://github.com/shamsuzzamansadi/dagon
- **Code commit reviewed:** `422ff54eb33ab0059c6c430f8a1fa1c5fd5f2048`
- **CI run for that commit, both platforms green:**
  https://github.com/shamsuzzamansadi/dagon/actions/runs/41408640443
- A later commit adds only this package, evidence and status documents.

## 1. What was built

| Area | Files |
|---|---|
| Movement rules (plain C++20, no Godot) | `src/core/movement.{hpp,cpp}` |
| Player and camera | `src/player_controller.*`, `src/camera_rig.*`, `src/node_ref.hpp`, `src/register_types.cpp` |
| Game content | `project/scenes/player/player.tscn`, `project/scenes/level/level.tscn` (Act I greybox) |
| Input | `project/project.godot`: keyboard and gamepad for `move_left`, `move_right`, `jump` |
| Unit tests | `tests/unit/test_movement.cpp` (doctest v2.5.3) |
| Godot tests | `project/tests/` (runner, `StepProbe`, arena fixture, two suites, class check) |
| Scripts and CI | `tools/`, `.github/workflows/ci.yml`, `SConstruct` |

Not implemented, as agreed: interaction, puzzle, story, menus, final art, atmosphere.

**Git history:** `bdd992c` pre-jam docs (written 2026-10-28, committed unchanged), `cb36649`
G0, `4115e2a` M1, `b94e742` and `422ff54` fixes. All commits use the owner's identity with no
AI trailers. `.claude/settings.json` was verified before the first commit. Nothing was
force-pushed.

## 2. Theme fit (G0)

SHIFT fits with no change to scope: physical, interpretive and perceptual shifts, with concrete
player-visible evidence in `docs/jam.md` §4 and `docs/gdd.md`. The itch.io FAQ returned HTTP 403
here, so FAQ facts are the ones you verified; the GitHub announcement was read directly.

## 3. Results by platform (CI run 41408640443)

| Check | Linux | Windows |
|---|---|---|
| Runner image | `ubuntu-22.04` | `windows-2022` |
| Compiler | g++ 11.4.0 | **MSVC 19.44.35229** |
| Our sources | `-std=c++20` | `/std:c++20 /Zc:__cplusplus` |
| godot-cpp | `-std=c++17` | `/std:c++17 /Zc:__cplusplus` |
| Debug / release | `-O2 -DDEBUG_ENABLED` / `-O3` | `/MT /O2 /DDEBUG_ENABLED` / `/MT /O2` |
| Unit tests (29 cases) | pass | pass (built with `cl`) |
| Prepared clean import | exit 0 | exit 0 |
| Extension load, **debug** library, in the editor | 2 classes, 0 problems | 2 classes, 0 problems |
| Integration tests | 22 passed, 0 failed | 22 passed, 0 failed |
| 600-frame smoke, no ERROR lines | pass | pass |
| Release export created | yes | yes |
| **Release** library loaded in the exported game (`--verbose` proof line, exit 0) | yes | yes, on the runner |

**How the release library was checked:** the exported game runs `--headless --verbose
--quit-after 300`. It must exit 0, print no ERROR lines, and print `dagon: extension initialized
build=release compiler=... __cplusplus=202002`. `check_classes.gd` itself runs only against the
debug library, because official release templates cannot run `--script`.

**Evidence access:** CI evidence comes from public annotations and step results. I have no API
token, so I could not read full job logs or download artifacts. They exist on the run page
(`logs-*`, `dagon-*`) for anyone signed in. `first-error :: missing` in the annotations means no
error line was found.

## 4. Local verification (Ubuntu 24.04 on WSL2, GCC 13.3.0, Godot 4.7.2, SCons 4.9.1)

| Check | Result | Evidence |
|---|---|---|
| Fresh clone following the README commands exactly (at `b94e742`; later commits changed CI, docs and `require_msvc` only) | All pass | `docs/evidence/m1/clean-checkout/` |
| Full clean build, including godot-cpp | 92 s debug, 95 s release, 12 cores | |
| Integration repeated | 20 of 20 clean runs | `integration-repeat.txt` |
| Export templates | Official SHA-512 verified | `tools/install_export_templates.sh` |
| Exported Linux build in a **window** | Exit 0, no errors | `linux-export/windowed-run.txt` |

The windowed run and recording used **llvmpipe software OpenGL**, not a real GPU.

**Reproduce:**
```sh
git clone --recurse-submodules https://github.com/shamsuzzamansadi/dagon.git && cd dagon
python3 -m venv .venv && .venv/bin/pip install scons==4.9.1
.venv/bin/scons platform=linux target=template_debug show_flags=yes
.venv/bin/scons platform=linux target=template_release
.venv/bin/scons unit_tests
sh tools/install_export_templates.sh
GODOT=/path/to/godot sh tools/run_godot_checks.sh
GODOT=/path/to/godot sh tools/export_check.sh linux
```

## 5. Can the tests fail? (deliberate breakage, `docs/evidence/m1/mutation/`)

| Break | Caught by |
|---|---|
| Teleport does not invalidate contact | `test_f`; shows `vy=-190`, a real mid-air jump |
| `Unknown` contact treated as grounded | 6 unit test cases fail |
| `StepProbe` runs before the player | `test_probe_observes_after_player_step` |
| Runtime script error inside a test | That test fails (after the fix in §7) |
| Extension missing | Run fails immediately (after the fix in §7) |

**M1 review follow-ups closed:** the `StepProbe` post-step point exists and is proven;
teleport tests 7f and 7g pass.

## 6. Not verified: human checks and gaps

These are **not done**, and CI cannot do them:

| Item | Who | How |
|---|---|---|
| **Movement feel:** walk, stop, jump, land, tuning values | Owner | Play either build |
| **Physical gamepad and keyboard mapping.** Tests only inject synthetic events. | Owner | Same, with a controller |
| **Windows export on real hardware.** It ran only headless on a CI runner. | Owner | Run page → sign in → download `dagon-windows` → run `dagon.exe` |
| Rendering on a real GPU | Owner | Same |
| Second display readability | — | M4 |

Also open:
- Integration stability in CI: 3 green runs so far against a target of 10 consecutive. 20 of 20 locally.
- Green CI says nothing about visual quality, movement feel or audio.

## 7. Defects found during M1

| Defect | How it was found | Fix |
|---|---|---|
| **`.gitignore` `bin/` excluded `project/bin/dagon.gdextension`**, so clones could not load the extension. It also dropped the probe's `.gdextension` from the evidence package. | Fresh clone | `/bin/` |
| **Tests reported PASS after a runtime script error**: a test aborted silently. | Same fresh-clone run: 20 false passes, caught only by the outer log scan | Runner traps logged errors with `Logger`; checks classes first |
| **Windows CI was green while building with MinGW**: `windows-2025` ships MSVC 19.51, SCons 4.9.1 cannot detect it, and godot-cpp silently falls back. | Reading the compiler annotation. Confirmed by a throwaway 12-job matrix (since deleted). | Pin `windows-2022`; `require_msvc=yes` now fails rather than falls back |
| Annotation step failed on missing logs (run `41404094043`) | That failed run | Report-only `tools/ci_annotate.sh`, always exit 0, so job results come only from real steps |
| Harness freed nodes while inside signal emission, leaving old fixtures alive | First test run | `queue_free` |
| Relative `--log-file` path | Export check | Absolute paths |

**Old runs, for clarity:**
- `41404094043` (`4115e2a`): failed, because of the missing `.gdextension`.
- `41404645138` (`b94e742`): green, **but Windows was MinGW. It is not MSVC evidence.**
- `41408640443` (`422ff54`): green with MSVC. **This is the evidence for this package.**

## 8. Import workaround on the actual project

Full table: `docs/evidence/m1/import/README.md`. The probe reproduction is in
`docs/evidence/import-crash/reproduce.sh`.

| Project | Filesystem | Unprepared | Prepared |
|---|---|---|---|
| **Game, fresh clone** | ext4 | **134 ×4** | 0 ×3 |
| Game, working copy | 9p (`/mnt/c`) | 0 ×6 | 0 ×6 |
| Probe | ext4 | 134 ×3 (control, same day) | 0 ×3 |
| Probe | 9p | 134 ×3 | not run |

Supported: the crash is real on a fresh clone of the game, and preparation prevented it in every
trial. **Root cause not established.** The filesystem alone does not explain the working-copy
exception. Windows was tested only with preparation. **Correction:** the message of `b94e742`
says the crash does not reproduce on this project; that is wrong, and it came from testing only
the working copy. No upstream issue is filed.

## 9. Deviations from the plan, for your judgment

1. `max_physics_steps_per_frame = 1` was **not** set. It would slow the shipped game below 60 FPS,
   and `--fixed-fps` already gives one step per frame in tests. Tests assert the tick rate.
2. `export_presets.cfg` is hand-written. The earlier claim that the editor must generate it was wrong.
3. Exports run on each platform's own runner, not all from Linux.
4. CameraRig has follow, look-ahead and limits only. `set_target` and shake wait until they are
   used (M3/M5). PlayerController has no `footstep` signal or animation until M4.
5. Added `set_control_enabled(false)` clearing a buffered jump, with a test. Otherwise a press just
   before a lock would jump during a cutscene.
6. `godot-cpp` entered history in the G0 commit `cb36649` by accident (it was already staged). This
   is harmless and left as is, per the no-rewrite rule.

## 10. Greybox evidence

**Labelled greybox, not the intended look:**
`docs/evidence/m1/greybox-screenshot.png`, `docs/evidence/m1/greybox-movement.gif` (15 s, scripted
input, native 480×270, rendered through Movie Maker mode with llvmpipe). I inspected the frames:
player, ground, rock, slope, trench and steps are distinct, and the camera looks stable. That is my
reading of frames, not a playtest.

| Placeholder | Replaced in |
|---|---|
| Rigid polygon sailor with **no animation**: it visibly glides | M4 (character treatment, first deliverable) |
| Amber square lantern marker, no light | M4 |
| Flat terrain polygons and blocky rock and steps | M3 layout, M4 art |
| Lifeboat polygon, not interactable | M3 interaction, M4 art |
| Flat background, no parallax or fog | M4 |
| No audio | M4 |
| Movement values are first guesses | After the owner's feel check |
| No icon | M7 |

The visual bar is recorded in `docs/gdd.md` §8, with the first M4 deliverable and its evidence
requirements. No M4 work has started.

## 11. Remaining risks

- The owner's feel check could change tuning, or expose movement problems.
- `windows-2022` will retire eventually. SCons 4.11.1 detected MSVC on `windows-2025` in a dry run only.
- CI's Godot and templates come from a cache after the first verified download. The SHA-512 check
  runs only on a cache miss.
- An upstream action warns about the Node 20 deprecation. No effect yet.
- Art and audio capacity against the "made with love" bar (R2) is the largest project risk. It
  remains untested until the first M4 review.

## 12. Where review would help most

1. Is `test_probe_observes_after_player_step` enough to prove the observation contract?
2. D2: MSVC 19.44 with `/MT` on both sides and a clean headless run. Is anything further needed
   before treating the C++17/C++20 mix as validated for this project?
3. Should the unexplained working-copy exit 0 block M1, or stay an open item?
4. Any objection to the §9 deviations?
