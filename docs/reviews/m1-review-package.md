# M1 Review Package

**To:** ChatGPT (independent reviewer). **Date:** 2026-11-02.
**Status: M1 is accepted by the owner with documented deferrals (§16).** That does not mean every manual check passed.
The independent technical review is complete, with limits (§17).

**Updated by the Shore integration.** The code you are asked to review is now the current `main`, and
§15 says what changed since §1–§14 were written. Those sections describe `7a2f849` (CI run
[41412946061](https://github.com/shamsuzzamansadi/dagon/actions/runs/41412946061)).

- **Repository:** https://github.com/shamsuzzamansadi/dagon
- **Code commit for review:** `3301ae08edad7a143c5578e796573c042f6e7f62`, the merge that made the Shore the
  entry scene. Later commits change only documents.
- **CI run for that commit, both platforms green:**
  https://github.com/shamsuzzamansadi/dagon/actions/runs/41432275970

**Who has verified what:**
| Result | Who ran it |
|---|---|
| Native C++ tests, GCC 13.3: 29 cases, 763 assertions (the suite before §13) | **Independently reproduced by the reviewer** |
| Native tests at `3301ae0` (46 cases, 802 assertions), and the art check | **Independently rerun by the reviewer** (§17) |
| Code at `3301ae0`: movement fixes, player animation, camera, scene and test wiring, build, CI and export scripts | **Reviewed by the reviewer:** no new blocking findings (§17) |
| Godot integration tests, smoke, extension load, engine rendering, release exports, Linux and MSVC CI | **Supplied by the developer and CI. Not independently rerun,** because Godot was unavailable in the review environment (§17) |
| Windows launch and rendered gameplay | **Owner, two sessions** (§6); commit and input device not confirmed for either |
| General movement and camera feel | **Owner: positive, in general terms** (§6) |
| Human Linux run, with software rendering; A, D, Left Arrow, Right Arrow and Space worked | **Owner** (§16) |
| Physical gamepad; native Linux hardware-accelerated rendering | **Untested. Deferred to M6, before release** (§16) |
| Sampled frames of the owner's second recording, and the updated documents | **Reviewer.** Not code verification and not a full motion analysis. |
| Shore art direction | **Accepted by the owner** from screenshots and a recording of the preview. That is an art decision, not code review or a feel check. |

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
G0, `4115e2a` M1, then `b94e742`, `422ff54` and `7a2f849` fixes. All commits use the owner's identity with no
AI trailers. `.claude/settings.json` was verified before the first commit. Nothing was
force-pushed.

## 2. Theme fit (G0)

SHIFT fits with no change to scope: physical, interpretive and perceptual shifts, with concrete
player-visible evidence in `docs/jam.md` §4 and `docs/gdd.md`. The itch.io FAQ returned HTTP 403
here, so FAQ facts are the ones you verified; the GitHub announcement was read directly.

## 3. Results by platform (CI run 41412946061, commit `7a2f849`)

| Check | Linux | Windows |
|---|---|---|
| Runner image | `ubuntu-22.04` | `windows-2022` |
| Compiler | g++ 11.4.0 | **MSVC 19.44.35229** |
| Our sources | `-std=c++20` | `/std:c++20 /Zc:__cplusplus` |
| godot-cpp | `-std=c++17` | `/std:c++17 /Zc:__cplusplus` |
| Debug / release | `-O2 -DDEBUG_ENABLED` / `-O3` | `/MT /O2 /DDEBUG_ENABLED` / `/MT /O2` |
| Unit tests (38 cases) | pass | pass (built with `cl`) |
| Prepared clean import | exit 0 | exit 0 |
| Extension load, **debug** library, in the editor | 2 classes, 0 problems | 2 classes, 0 problems |
| Integration tests | 23 passed, 0 failed | 23 passed, 0 failed |
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
| Fresh clone of `7a2f849` following the README commands exactly: 38 unit, 23 integration, extension load, smoke, Linux export run | All pass | `docs/evidence/m1/clean-checkout/` |
| Full clean build, including godot-cpp | 95 s debug, 94 s release, 12 cores | |
| Integration repeated at `7a2f849` | 20 of 20 clean runs (23 tests each) | `integration-repeat.txt` |
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
| Horizontal velocity left at walk speed at a wall | `test_d_cannot_pass_walls` reports `got 70.000` |
| Player stops while grounded on the slope | Slope test fails in about 2 s, with `stopped at x=490.0`, not at the watchdog |
| Zero forgiveness windows, before the fix | 4 of 38 unit test cases failed (`zero-forgiveness-before-fix.txt`) |

**M1 review follow-ups closed:** the `StepProbe` post-step point exists and is proven;
teleport tests 7f and 7g pass.

## 6. Human checks and gaps

**Done so far: a user Windows launch and partial gameplay check (reported 2026-11-02).** The owner
downloaded and launched the Windows build and gave the reviewer a gameplay recording. It shows the
game running and the character moving through the greybox level.
- **Not assigned to a commit:** the exact artifact and commit tested have not been confirmed.
- **Does not establish** that all mappings, movement feel, jumping behaviour or physical gamepad
  support pass. Those stay open below.
- **Measured from the recording** ([evidence](../evidence/m1/windows-recording-2026-11-02.md)): walking
  speed 70.4 px/s against 70 configured; correct right-wall stop; flat-ground jumps peaking at 23–27 px.
- **New defect it exposed:** the character flickers by 1 game pixel on screen while the camera
  follows. The M1 engine capture confirms it, and my M1 frame inspection missed it. Cosmetic. Fixed
  after this package in both scenes (§15).

**Second session: the owner's run of the standard Windows build (reported 2026-11-02).**
[Record](../evidence/m1/windows-playtest-2026-11-02-standard-build.md). A launch and a rendered gameplay session
took place. The owner's words: "I like the illustrated Shore, and the controls/camera generally felt fine during
this session."
- **Not inferred from the recording:** the exact artifact and commit, the input device, every mapping, or physical
  gamepad coverage.
- **What the reviewer did:** inspected sampled video frames and the updated documents. That is not independent code
  verification or a full motion analysis.
- **The developer has not seen this recording,** so nothing is measured from it.
- **The artwork disappearing after the cliff opening** is the documented boundary between the illustrated Shore and
  the unfinished greybox, not a new defect.

**Third session: the owner's run of the Linux executable (reported 2026-11-02).**
[Record](../evidence/m1/linux-playtest-2026-11-02.md). A, D, Left Arrow, Right Arrow and Space worked correctly, by the
owner's confirmation. The run used software rendering (Mesa llvmpipe, under WSL Ubuntu 24.04), with a V-Sync warning
observed, so it is not native Linux GPU validation.

The outcome of all three sessions is in §16. Second-display readability belongs to M4.

The owner has now seen the game rendered on their Windows machine. The GPU and renderer were not recorded.

Also open:
- Integration stability in CI: 9 consecutive green runs with MSVC before the Shore merge (`422ff54` to
  `a9b262c`), against a target of 10. Only the latest ran today's 47 tests, so this stays open. 20 of 20
  locally at `7a2f849`, and 10 of 10 at `a9b262c`.
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
- `41408640443` (`422ff54`) and `41410989051` (`e49aae3`): green with MSVC, before the §13 fix.
- `41412946061` (`7a2f849`): green with MSVC. **This is the evidence for this package.**

## 8. Import workaround on the actual project

Full table: `docs/evidence/m1/import/README.md`. The probe reproduction is in
`docs/evidence/import-crash/reproduce.sh`.

| Project | Filesystem | Unprepared | Prepared |
|---|---|---|---|
| **Game, fresh clone** | ext4 | **134 ×6** | 0 ×3, plus each fresh-clone check run |
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

**Labelled greybox, not the intended look.** Recorded before `7a2f849`. That fix does not change
behaviour at the default timer values, so it was not re-recorded.

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

## 12. Reviewer's acceptances for M1 (2026-11-02)

Recorded in `docs/decisions.md` §3, each limited as stated: `StepProbe` ordering in the current
fixture, with its regression test; C++20 with C++17 godot-cpp for the tested compiler configurations,
not universal ABI certification; platform-native export checks; the prepared-import workaround
with strict failure handling, with the root cause unresolved and the exceptional result kept in
the evidence.

## 13. Review round 1 corrections (commit `7a2f849`)

| Finding | Reproduced? | Change | Verification |
|---|---|---|---|
| **Grounded jump broke when either forgiveness timer was zero** | **Yes.** New tests failed before the fix: 4 of 38 cases. Besides the reported failures, a window at zero also disabled the *other* window. | `movement.cpp`: `jump_requested = pressed \|\| buffer_timer > 0`, `can_jump = grounded \|\| coyote_timer > 0`. Zero disables only that window. | 9 new unit test cases: each timer zero and both zero; late airborne jump rejected at zero coyote; earlier airborne request not retained at zero buffer; the other window still works; no double jump; stale contact and control lock unaffected. Plus one integration test through the real editor properties. |
| **Wall assertion tolerance was full walk speed** | By inspection | `test_d`: tolerance 0.5 px/s, checked at both walls | Forcing walk speed fails with `got 70.000` |
| **Slope test could run to the global watchdog** | By inspection, then a forced stop | `for` loop limited to 120 steps, plus an assertion that the player reaches the endpoint | `walk_speed = 0` fails in about 2 s with a clear message |

No failures in the final runs.

## 14. Status

**M1 is accepted by the owner with documented deferrals (§16).** The independent technical review is complete, with
limits (§17). M2 proceeds with its defined scope.

## 15. Shore integration (after §1–§14)

The owner accepted the Shore's art direction and authorized integrating it (D19, D20). **That does not
close any check in §6.**

| Area | Change | Commit |
|---|---|---|
| Camera | Pixel lock on by default; greybox loses position smoothing. Fixes the §6 flicker in both scenes (D22). The camera now follows rigidly, which changes how the greybox feels from what the owner recorded. | `54c1f7e`, `4436339` |
| Entry scene | `shore.tscn` is the main scene, on the greybox's whole collision, spawn and camera limits. Art to x = 640, greybox beyond. The greybox stays, excluded from exports. The preview builds are gone. | `c8a577b` |
| Art | The rock's top is drawn on its collision; the right cliff has a cleft where the preview's wall was. 646 of 172,800 pixels in `terrain.png`. | `c8a577b` |
| Documents | Story wording (D21), later direction (D23), status. | Later commits |

**Playable extent is unchanged from M1:** x = 24 to 1376, including the trench and steps. A test compares
the polygons. The former preview stopped at x = 620.

**Tests:** 47 integration tests, up from 33. Every greybox test also runs on the entry scene.
- Added: the camera holds the character still walking both ways, turning slides one way without a jump,
  the game starts in the Shore, the Shore has the whole greybox level, the seam where the art ends, feet
  on the rock, feet at the rock's corners.
- Replaced by stricter versions: the preview's crossing test (x = 40 to 600, now the full level), its pixel
  lock test (one direction in one scene, now both ways in both scenes), and its ground comparison (9 shared
  points, now the whole polygon).
- Unit tests are unchanged at 46 cases (38 at `7a2f849`; the preview added 8 for body pose).
- `check_art.py` now also compares the drawn ground with the scene's collision.
- Deliberate breakage, including a gap it found in my own tests: `docs/evidence/shore/mutation/`.
- The greybox has its own 600-frame smoke run now that a plain run does not start it.

**Measured:** 0 on-screen changes at 30, 60 and 144 fps in both scenes, against 113 changes and 69
flickers back with the M1 camera (`docs/evidence/shore/camera-jitter.txt`). This is software rendering at
a fixed frame rate, not a real GPU or a real variable frame rate.

**Verified before merging (commit `a9b262c`):**

| Check | Result | Who ran it |
|---|---|---|
| CI run [41431582414](https://github.com/shamsuzzamansadi/dagon/actions/runs/41431582414), Windows with MSVC 19.44.35229 | 46 unit, 47 integration, extension load, smoke on both scenes, art check, release export: all pass. The exported release library loaded and started in `shore.tscn`, headless. | CI |
| Same run, Linux with g++ 11.4.0 | The same checks, all pass | CI |
| Fresh clone following the README, Ubuntu 24.04, GCC 13.3.0 | The same checks, all pass; the suite repeated 10 of 10 clean; regenerating the art changes nothing | Developer |
| Local attempt to export Windows from Linux | Fails: the MSVC library exists only on a Windows runner. Expected (§9, item 3), and the Windows export is proven by CI above. | Developer |

CI reports come from public annotations, as in §3. At the time of merging, nobody had run this build on real
Windows hardware or judged how it feels; §6 records the owner's later session. The merge itself, `3301ae0`, is
green on both platforms in CI run
[41432275970](https://github.com/shamsuzzamansadi/dagon/actions/runs/41432275970).

**For your judgment:**
1. Removing the camera's smoothing is the one behaviour change to the M1 greybox. The owner's later feedback on the
   camera is generally positive (§6).
2. `test_camera_slides_one_way_when_turning` allows 3 px per frame, based on a 2 px peak at `lock_speed` 2.5.
3. The capsule can rest up to 4 px past the rock's corners, drawn up to 2 px low. I recorded this for M4
   rather than change the capsule.

## 16. M1 acceptance (2026-11-02)

**Accepted by the owner with documented deferrals,** for progression to M2, based on the independent technical review,
the supplied CI evidence, and the owner's Windows and Linux playtests. This is not a statement that every manual check
passed.

This is every criterion in `roadmap.md`, with evidence at `3301ae0`. "Met" means met on evidence supplied by the
developer and CI, except where §17 records an independent rerun.

| # | Criterion (short) | Status | Evidence |
|---|---|---|---|
| 1 | Clean clone, godot-cpp at `507ed9d`, `.gitignore` | Met | Fresh clone at `a9b262c`; same code as `3301ae0` |
| 2 | Linux debug and release builds | Met | Same clone; CI |
| 3 | C++20 `static_assert` on GCC and MSVC | Met | `src/register_types.cpp`; CI |
| 4 | MSVC debug and release builds, `cl` version recorded | Met | CI: 19.44.35229 |
| 5 | Unit tests on Linux and Windows | Met | CI: 46 cases on both. The reviewer also reran the native suite (§17) |
| 6 | Extension load, including MSVC debug and release | Met, as adapted | `check_classes.gd` on debug; release through the exported game's proof line, because official release templates cannot run `--script` (§3) |
| 7 | Integration tests (a)–(g) | Met | CI: 47 passed on both |
| 8 | 600 headless frames, no `ERROR:` | Met | CI: Shore and greybox on both |
| 9 | Prepared clean import, exit 0 | Met | CI; §8. The root cause stays unknown, as accepted in §12 |
| 10 | Export templates verified; release exports | Met | CI and local. CI verifies SHA-512 on a cache miss only (§11) |
| **11** | **Human run on Windows and Linux: walk and jump feel responsive on keyboard and physical gamepad** | **Accepted with deferrals, not fully passed** | The table below |
| 12 | CI green on push | Met | CI run 41432275970 |
| 13 | README clean-checkout instructions | Met | `README.md`; followed on Linux by the fresh clone. There is no recorded hand run of the Windows commands; the criterion only requires them to be there |
| 14 | Review package prepared | Met | This document |

**Criterion 11 and the owner's checks, as accepted:**

| Check | Outcome | Basis |
|---|---|---|
| Windows launch and rendered gameplay | Done, in two sessions | [Record](../evidence/m1/windows-playtest-2026-11-02-standard-build.md) |
| Movement and camera on Windows | **Positive general feedback from the owner:** "the controls/camera generally felt fine" | Same record |
| Human Linux run | **Done, with software rendering** (Mesa llvmpipe, LLVM 20.1.2, under WSL Ubuntu 24.04). A V-Sync warning was observed. | [Record](../evidence/m1/linux-playtest-2026-11-02.md) |
| Keys | **A, D, Left Arrow, Right Arrow and Space worked,** in the Linux test | The owner's confirmation |
| Physical gamepad | **Untested. Deferred to M6, before release.** | Owner's deferral |
| Native Linux hardware-accelerated rendering | **Not validated. Deferred to M6, before release.** | Owner's deferral |
| Exact provenance of the recorded builds | **Unconfirmed,** and not inferred from timestamps or appearance. The owner accepts this limitation for M1. Later milestone playtests identify the exact artifact or run. | Owner's acceptance |

**Recording the renderer in later runs.** Read it from the run, and do not infer it from the environment: a Linux run
under WSL is not automatically software-rendered. Start the game with `--log-file playtest.log` and find the line
containing `Using Device`. This was confirmed on a Linux release export. The "software rendering" notes elsewhere in this
package are what this development machine's logs reported (`llvmpipe`), and describe only those captures.

**Tracked, but not criteria for this gate:**
- CI streak on a stable suite (M1–M3).
- The upstream report for the import crash.
- Second-display readability (M4).
- The save and settings design (D25, D26) is approved for implementation and is not built (§17). That says nothing
  about M1's code.

## 17. Independent technical review (2026-11-02)

Reported by the reviewer (ChatGPT) and relayed by the owner. Code commit
`3301ae08edad7a143c5578e796573c042f6e7f62`, with updated documents from `54ab860`.

**Verdict: no new blocking findings in the reviewed M1 implementation, and the previous three findings (§13) are
resolved. The independent technical review item is complete, with the limits below.**

| Done independently by the reviewer | Result |
|---|---|
| Located the exact review archive in the upload, and checked its SHA-256 against the supplied value | Verified |
| All 286 manifest file checksums | Verified |
| Rebuilt the code tree, including the pinned godot-cpp gitlink | Matched `8c158dbdf26e6cf8e5826b0f129678448db017b0` |
| Compiled and ran the native suite | 46 test cases and 802 assertions passed |
| Ran the art checker | Zero problems |
| Reviewed the movement fixes, player animation integration, camera changes, scene and test wiring, and build, CI and export scripts | No new blocking findings |

**Not rerun by the reviewer,** because Godot was unavailable in the review environment: the Godot integration tests,
engine rendering and release exports. Those results rely on the supplied CI evidence, and are not independent reruns.

This review was not M1 acceptance, which the owner gave separately (§16).

**D26 and `GameSession`.** The revised design is approved for implementation. A scene-owned session checkpoint that
survives world replacement is a reasonable scoped exception to literal scene reload, with no singleton, and the planned
11 classes are acceptable. No further architecture review is needed for these approved classes. During M3:
- World replacement removes the old world's active signals and callbacks.
- The new director has its checkpoint before it enters the tree.
- Verify restart after an autosave failure, pause reset, and repeated restart without duplicate events.
