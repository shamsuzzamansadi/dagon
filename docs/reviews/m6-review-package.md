# M6 Review Package: Stabilization

**To:** the owner. **Status: accepted by the owner on 2026-11-21 as a milestone, with the outstanding human checks (§5) carried forward as accepted deferrals** ([record](../evidence/m6/owner-acceptance-2026-11-21.md)). The owner asked for the README for players and a native macOS Apple Silicon build before the merge (§8). **No M6 version is published:** the candidate `v0.2.0-alpha.2` is prepared by `main`'s CI, and a tag needs the owner's word (§7). M5's alpha, `v0.2.0-alpha.1`, is published from `a4250f0` (§9). M7 is not started.

| | |
|---|---|
| **Plan** | [m6-plan.md](../m6-plan.md), approved by the owner on 2026-11-20 |
| **Branch and pull request** | `m6/stabilization`, draft [#7](https://github.com/shamsuzzamansadi/dagon/pull/7), from `main` at `a4250f0` (M5's merge) |
| **The playtest baseline** | **`a4250f0`,** the same for both first-time players, unchanged since the kit was sent ([kit](../m6/playtest-kit/README.md)). What a player sees differently on the branch since is listed there by commit |
| **The owner-test build** | **`a30be86`,** CI push run [44913367672](https://github.com/shamsuzzamansadi/dagon/actions/runs/44913367672): every M6 game change through `1229ae6`, for the owner's own checks ([owner-test build](../m6/owner-test-build.md)). Fingerprint `sha256:14e30e9c…b4f04f` |
| **The current head** | See the pull request; the state of each item is in the [handoff](../handoff.md) |

**Kept apart throughout:** **automated** results (scripts, tests, CI; never a person), **human observations** (only what a person reported, in their words), and **outstanding checks** (not yet done by anyone). Nothing a script did is recorded as a person's.

## 1. Delivered, item by item

| # | Item | State | Kind | Evidence |
|---|---|---|---|---|
| 1 | Two first-time playtests | The kit and the baseline, verified; **the sessions are the owner's to arrange** | D done; P outstanding | [kit](../m6/playtest-kit/README.md) |
| 2 | Timing against 10–15 min | Waits on item 1. Scripted on the baseline: 4 min 3 s to the first ending card reading everything, 2 min 7 s straight through, after the prologue | D | [measurement](../m6/playtest-kit/measurement.md) |
| 3 | Listening to the reveal by ear | The kit, the full mix first and the words apart; **the owner's sheet is outstanding** | D done; P outstanding | [kit](../m6/listening-kit/README.md) |
| 4 | Physical controllers | The sheet; **results pending until someone tests the actual hardware** | D done; H outstanding | [sheet](../m6/controller-checks/README.md) |
| 5 | German key names on the real Windows build | **Passed in CI** on the shipped Windows build, every run since `77d5302` | D | [evidence](../evidence/m6/layouts/README.md) |
| 6 | 720p and 1080p, windowed and fullscreen | A Display setting and a fitted window (D122), checked at both sizes; across a relaunch in CI | D done; H outstanding | [displays](../evidence/m6/displays/README.md) |
| 7 | Native runs | Sheets for the ThinkPad and the Windows desktop, with the frame log; **the runs are outstanding** | D done; H outstanding | [sheets](../m6/native-checks/README.md) |
| 8 | Frame times | No frame over 33 ms in play in any act, on the software renderer; one long frame at each of three scene changes, the handover traced | D done; H outstanding | [frames](../evidence/m6/frames/README.md) |
| 9 | M6 verification | The matrix, with its gaps filled; **the owner's pass over the menus is outstanding** | D done; P outstanding | [matrix](../evidence/m6/verification-matrix.md) |
| 10 | GDD §8 on every scene | The developer's view; F1, F2 and F3 found and fixed; **the owner's playtest of `a30be86`: satisfactory** for the route played (§4) | D done; P done for that route | [review](../evidence/m6/visual-review/README.md), [F2/F3](../evidence/m6/cave-and-checkpoint/README.md) |
| 11 | Carried items | M3's two survivors: tests that fail under their breakages. M2's examine: not reproduced in any run, 6 here and 20 in each CI run since `1f68ceb` (10 on Windows, 10 on Linux) | D | [matrix](../evidence/m6/verification-matrix.md) |
| 12 | Validation and handoff | This package; the breakage of what M6 adds, 10 of 10 caught; the owner's acceptance; the candidate's artifacts from `main`'s CI and a tag proposal | D, P | §3, §7 |
| — | The README for players, and a native macOS Apple Silicon build (owner, 2026-11-21) | Done: the Mac build made and checked by CI on Apple Silicon (D129); shutdown waits for the mixer (D130) | D | §8 |

## 2. What changed, by commit

| Commit | What |
|---|---|
| `7aae883` | The plan, as approved |
| `4246872`, `c9492de` | The playtest kit, the listening kit, the native-check sheets; the downloaded baseline played to the ending |
| `0cb97e0` | **Game:** the Display setting and the fitted window (D122) |
| `77d5302` | Key names under the US and German layouts, in CI (`tools/layout_check.py`); Settings logs the names it shows (verbose) |
| `1f68ceb` | **Game:** the frame log, `DAGON_FRAME_LOG` (D123). Tests for M3's two survivors; M2's examine tried again (`tools/idle_examine_check.py`); CI's `desktop-checks` |
| `c1811ca` | **Game:** Settings says Examine (D124). The verification matrix; the Display setting across a relaunch (`tools/display_relaunch_check.py`) |
| `2ff6cf2` | **Game:** the distant shape where it belongs (D125). The GDD §8 review |
| `1229ae6` | **Game:** the cave's boundaries follow the rock (D126); the Awakened checkpoint clear of the statue (D127). Before/after walks |
| `a7510ab`, `a30be86` | Records only; `a30be86` is the owner-test build |

## 3. Automated results

| What ran | Where | Result |
|---|---|---|
| Native unit tests (`scons unit_tests`) | Local, GCC | 135 of 135 |
| Integration, classes, three smoke runs (`run_godot_checks.sh`) | Local, editor build | **460 passed, 0 failed,** on `1229ae6`'s tree |
| The same on the exported pack (`export_check.sh linux`) | Local | 460 passed, 0 failed |
| `check_art.py`, Pillow alone | Local | 0 problems; its new clip-edge check reports 456 on the old cave |
| The exported route, four runs | Local, private display | `runs=4 failed=0` on `1229ae6`'s export; also on the downloaded baseline |
| Required CI: linux, linux-clang, windows, release-tools | GitHub | Passed on every head pushed in M6. `77d5302`'s run as a whole failed, on its new, non-required Linux layout leg (Xvfb keeps the US keymap), corrected in `1f68ceb`; for the current head see the pull request |
| `desktop-checks`, Windows and Linux | GitHub, throwaway runners | German key names (Windows), M2's examine 10 runs a side, the Display setting across a relaunch: passed on `1f68ceb`, `c1811ca`, and since |
| Deliberate breakage of what M6 adds (`tools/breakage_m6.py`) | Local, three isolated clones of `a30be86` | **10 of 10 caught,** controls held (460 passed before and after in each): the Display setting saved, read, pressed and restored; the window's fit, twice (caught by the native tests); Settings' Examine, twice; the distant shape's place; the Awakened checkpoint ([record](../evidence/m6/breakage-a30be86.txt)). The cave's boundaries are held by `check_art.py` instead |

## 4. Human observations

**2026-11-21, the owner, on the owner-test build `a30be86`, Windows desktop: owner playtest satisfactory** for the route played, New Game through the running escape, all four epilogue panels, the credits and the return to the main menu: "I'm satisfied with the current visuals and gameplay. I'm requesting no further changes based on this run." Two observations left open: at 6:39 to 6:43 the recording shows only the centre of Settings during the display switch, and what the monitor showed is not confirmed; Continue after the credits was not selected, so D127 has scripted coverage only there. ChatGPT reviewed the footage and compared audio samples with the owner's 20 November recording: **a signal check, not listening** ([record](../m6/owner-test-build.md)).

**2026-11-21, the owner: M6 accepted** as a milestone, "with the outstanding human checks carried forward" ([record](../evidence/m6/owner-acceptance-2026-11-21.md)).

**2026-11-22, the owner,** in answer to the developer's question: they heard the M5 build's main audio (music, effects, narration, the reveal) in play, on `b7303bf`, with sound. The reveal's intelligibility by ear stays open ([record](../evidence/m5/release-authorization-2026-11-22.md)).

The owner's words from M5's acceptance stand in their own record ([M5 acceptance](../evidence/m5/owner-acceptance-2026-11-20.md)), among them that the intelligibility of the reveal's dialogue by ear remained open for M6 (item 3).

## 5. Outstanding checks

| Check | Who | Item |
|---|---|---|
| Two first-time players, recorded with sound, and their answers | The players, through the owner | 1, then 2 |
| The reveal in the full mix, on headphones and on speakers | The owner | 3 |
| Xbox and PlayStation controllers, by the sheet | Whoever has them | 4 |
| The Ubuntu ThinkPad and the Windows desktop, by the sheets, with the frame log | The owner | 6, 7, 8 |
| A pass over the menus | The owner | 9 |
| What the monitor shows during the display switch (open from the owner's playtest, 6:39 to 6:43) | The owner | 6 |
| Continue after the credits, by a person (open from the owner's playtest) | The owner | 9, 10 |

## 6. Unresolved, and known

- **M2's examine** was not reproduced in any run (6 here, 20 in each CI run since `1f68ceb`); the original was on the owner's desktop, where a real key cannot be ruled out. Recorded as not reproduced.
- **The prologue's handover to the game** is one 61–72 ms frame on the software renderer, traced; whether it is long on a graphics card is for the owner's machines' frame logs.
- **German key names on Linux** cannot be set on Xvfb; checked on Windows, the real build M2 deferred.
- **From the owner's playtest, left open by the owner:** the display switch as the monitor showed it, and Continue after the credits by a person (§4).
- **The cave's drifting motes** are not seeded alike from run to run, so two takes never match there exactly.

## 7. The candidate

**The roadmap names no version for M6;** its exit gate asks for release-candidate artifacts from CI, launched on real Windows and Linux. So M6 publishes nothing: [`release/v0.2.0-alpha.2.json`](../../release/v0.2.0-alpha.2.json) is in `candidate` state, and `main`'s CI on #7's merge packages it as the `release-candidate-v0.2.0-alpha.2` artifact, for Linux, Windows and macOS, with notes that list every outstanding human check under "Not tested". **The version is a proposal.** The owner's acceptance covers the owner-test build's fingerprint, not the merged one (§8), so the gate reports it as remaining, and publishing needs the owner's word.

## 8. What the merge adds to what the owner played

At the owner's request, before the merge: **the README for players** (a spoiler-free description, a picture of the Shore, the Releases link and downloads, launch steps for each system, the controls, a short build section), and **a native macOS build for Apple Silicon** (D129): one arm64 target, minimum macOS 11, built with Apple Clang on CI's `macos-15` runner against the pinned Godot and godot-cpp; the extension bundled in the app; the app signed ad hoc and not notarized, zipped keeping its permissions; packaged and smoke-tested on a Mac. It needed, in files every build carries: the extension's macOS libraries, a macOS export preset, ETC2 and ASTC import (no texture gains a variant), and an Apple-only way of reading and writing the settings file's numbers. Found on the way, and fixed for every system: the test harness nested each test's storage folder in the last; one test waited on a busy runner's mixer by a fixed time; and quitting now also waits for the mixer to let go of every sound (D130). **No person has played the merged build.**

## 9. M5's alpha

`v0.2.0-alpha.1` was published on 2026-11-22 from `a4250f0`, M5's accepted merge, as built by `main`'s own run of it, and tagged there (D128), at the owner's request ([record](../evidence/release-workflow/publication-v0.2.0-alpha.1.md)). Its packages hold `a4250f0`'s exports byte for byte. The two first-time players stay on `a4250f0`, the same game.
