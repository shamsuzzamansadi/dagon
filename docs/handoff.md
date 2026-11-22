# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull requests and CI before relying on it.** M5's step-by-step record is in the [M5 package](reviews/m5-review-package.md); M4's in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-22. **M6 is accepted by the owner, on 2026-11-21, as a milestone, with the outstanding human checks carried forward as accepted deferrals** ([record](evidence/m6/owner-acceptance-2026-11-21.md)), and merged into `main` by the squash merge of [#7](https://github.com/shamsuzzamansadi/dagon/pull/7), after the README for players and a native macOS Apple Silicon build were added at the owner's request. **M5's alpha, [`v0.2.0-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.1), is published, from `a4250f0`** ([record](evidence/release-workflow/publication-v0.2.0-alpha.1.md)). **No M6 version is published:** `main`'s CI prepares the candidate `v0.2.0-alpha.2`'s artifacts, and a tag waits for the owner's word on the proposal. M7 is not started.

## Where things are

| | |
|---|---|
| **Milestones** | M1 to M6 accepted ([roadmap](roadmap.md)). M6: [record](evidence/m6/owner-acceptance-2026-11-21.md), [package](reviews/m6-review-package.md). M5: [record](evidence/m5/owner-acceptance-2026-11-20.md) |
| **The accepted build** | `b7303bf`, `dagon-windows`, artifact [14627487176](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136/artifacts/14627487176) of push run 44731893136, zip SHA-256 `97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`. Fingerprint `sha256:1f724cdc2c582c997c9b7b780ff092f4763c0077b5defe9805c6cce37533dc8d`, unchanged by the documents after it and by the squash merge |
| **What the owner tested** | The running route on that build, recorded: the ridge reads as Dagon's shoulder, the arm stays connected through the hand landing, the same wave overtakes the fallen sailor. The standing-still ending has scripted coverage only. ChatGPT compared the owner's video frames and measured the recorded audio against the owner's earlier clip; it did not listen |
| **The owner-test build** | **`a30be86`,** every M6 game change through `1229ae6`, CI push run [44913367672](https://github.com/shamsuzzamansadi/dagon/actions/runs/44913367672) (all passed): Windows zip `c138e0d4…1c9a`, Linux zip `2e281dc2…f83b`, both verified. For the owner's checks on the Windows desktop and the ThinkPad, with the checklist and the results by build and device: [owner-test build](m6/owner-test-build.md). **Owner playtest satisfactory on 21 November** (Windows), for the route played; two observations open. The players stay on `a4250f0` |
| **Branch and pull request** | `main` only, after #7's squash merge; `m6/stabilization` and `m6/macos` are deleted after it. #8, M5's release, is merged |
| **The Mac build** | arm64 only, minimum macOS 11, built and checked by CI's `macos` job on `macos-15`; signed ad hoc, not notarized (D129). On `617b297`, push run 45012866751 and rehearsal 45012877847 passed: the release zip, unpacked on Apple Silicon, saved, quit, relaunched and continued (review package §8). No person has run it |
| **The M6 candidate** | [`release/v0.2.0-alpha.2.json`](../release/v0.2.0-alpha.2.json), `state: candidate`, Linux, Windows and macOS: `main`'s CI packages it as `release-candidate-v0.2.0-alpha.2` and never publishes it. **Prepared on #7's merge `b271316` by run 45038841566, and verified** ([record](evidence/m6/candidate-v0.2.0-alpha.2.md)): checksums, provenance naming `b271316`, the three packages, the seven checks under "Not tested". Fingerprint `sha256:96c145f4…8135b`, which the owner's acceptance does not cover: a tag needs the owner's word on the [proposal](evidence/m6/candidate-v0.2.0-alpha.2.md#the-tag-proposal-for-the-owners-word) |
| **Releases** | [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), at `760a539`, untouched; [`v0.2.0-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.1), M5's alpha, tagged on `a4250f0`, from `main`'s own run 44748633376 of it (D128), published on 2026-11-22, verified ([record](evidence/release-workflow/publication-v0.2.0-alpha.1.md)) |

## M6 progress, by plan item

M6 is merged as `b271316`; check against `git log` on `main` before relying on this.

| # | Item | State | Where |
|---|---|---|---|
| 1 | Two first-time playtests | **Kit with the owner.** Baseline `main` at `a4250f0`: Windows zip `caed3727…cbae`, Linux zip `d0c77bd8…e6de`, both verified; the downloaded Linux build played to the ending, `runs=4 failed=0`. **Waiting for the players' recordings** | [kit](m6/playtest-kit/README.md) |
| 2 | Timing options | Waits on item 1. Scripted on the baseline: 4 min 3 s to the first ending card reading everything, 2 min 7 s straight through, after the prologue | [measurement](m6/playtest-kit/measurement.md) |
| 3 | Listening | **Kit with the owner:** the reveal in the full mix first, the words after. Waiting for the owner's sheet | [kit](m6/listening-kit/README.md) |
| 4 | Controllers | **Sheet ready** (M2's X1–X18, vibration by feel, the ending); **results pending until someone tests the actual hardware.** Simulated-input tests rerun with every gate | [sheet](m6/controller-checks/README.md) |
| 5 | German key labels | **Passed in CI on the shipped Windows build** of `77d5302` (run 44786112032): the game's thread switched to German, Settings Y D Ö Z, the prompt [Z]; US control Z D Semicolon Y. Linux runs US only (Xvfb keeps US whatever `setxkbmap` says). From `1f68ceb` the job is `desktop-checks` | [evidence](evidence/m6/layouts/README.md) |
| 6 | Displays | **Done on the branch, by script:** a Display setting (window or fullscreen) and a window that fits its screen (D122); checked at 1280 × 720 and 1920 × 1080 with a window manager. The owner's screens: in the native checks. Open from the owner's playtest: at 6:39 to 6:43 the recording shows only the centre of Settings during the display switch; what the monitor showed is not confirmed | [evidence](evidence/m6/displays/README.md) |
| 7 | Native runs | Sheets with the owner, for the Ubuntu ThinkPad and the Windows desktop, **to be run on the [owner-test build](m6/owner-test-build.md) `a30be86`** | [sheets](m6/native-checks/README.md) |
| 8 | Frame times | **Measured, on llvmpipe:** no frame over 33 ms in play in any act, all four exported runs; one long frame at each of three scene changes, the prologue handover (61–72 ms) traced and a warm-up tried and not kept. `DAGON_FRAME_LOG` (D123) in the native-check sheets for the owner's machines | [evidence](evidence/m6/frames/README.md) |
| 9 | Verification matrix | **Drafted;** gaps filled: the Display setting across a relaunch (`tools/display_relaunch_check.py`, also in CI), Settings' "Interact" renamed Examine (D124). Passed in CI on `c1811ca`, Windows and Linux: the display relaunch (on Windows the window fitted to 960 × 540 on the runner's 1024 × 768). Waiting: the owner's pass over the menus (the owner's playtest did not select Continue after the credits: D127 has scripted coverage only there) | [matrix](evidence/m6/verification-matrix.md) |
| 10 | GDD §8 review | **Done, the developer's view,** from 22 screenshots of the exported route. **All three findings fixed:** F1, the distant shape (D125, `2ff6cf2`); **F2, the cave's boundaries follow the rock (D126), and F3, the Awakened checkpoint clear of the statue (D127), at the owner's request of 2026-11-21, in `1229ae6`,** with before/after walks at normal speed. None is in the playtest baseline. **The owner's eye in play:** owner playtest satisfactory on `a30be86`, 21 November, satisfied with the visuals and gameplay, no changes requested ([record](m6/owner-test-build.md)) | [review](evidence/m6/visual-review/README.md), [F2/F3](evidence/m6/cave-and-checkpoint/README.md) |
| 11 | Carried items | **Both M3 survivors have tests that fail under their breakages** (`test_revision.gd`). **M2's examine:** `tools/idle_examine_check.py` repeats its steps; not reproduced in 6 runs here (3 idle, 3 with 9 busy processes), nor in CI on `1f68ceb` and `c1811ca`: 10 runs each on Windows and Linux (5 idle, 5 with all four processors busy), nothing examined or said with nothing pressed | `tools/idle_examine_check.py` |
| 12 | Validation and handoff | The [package](reviews/m6-review-package.md); breakage of what M6 adds, 10 of 10 caught; the owner's acceptance; the candidate's artifacts from `main`'s CI, and a tag proposal for the owner | this page |
| — | The Mac build (owner, 2026-11-21) | **Done, by CI:** built, unit- and integration-tested, exported, packaged and smoke-tested on Apple Silicon (D129). Shutdown waits for the mixer (D130); on `617b297` the Windows runs end with `dagon: quitting`, exit 0, nothing in use at exit | [D129](decisions.md) |

**Resuming after an interruption:** `cd ~/work/dagon-m4/clone && git switch main && git pull`, then this page and the open pull requests. Graphical runs one at a time: two private displays at once can share an X server and steal each other's keyboard focus (it broke a route run on 2026-11-20). The display checks need `XNS_WM=1` (Openbox, unpacked into `~/.cache/dagon-m4/S/xroot`); `~/work/dagon-m6/tools/capdisplay.sh <WxH> <new dir>` runs them.

**Open from M5, as the owner said:** the intelligibility of the reveal's dialogue by ear (item 3).

**Carried:** the unresolved M2 J/caption event and the two breakage survivors of M3's revision (item 11). **Known, recorded** ([M5 package](reviews/m5-review-package.md) §7): the band figures are a diagnostic; the creature's two-pixel blocks at full zoom; amber in the ending's pictures beyond the lantern.

## Owner feedback, and review, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` and the first pre-alpha release ([acceptance](evidence/m4/owner-acceptance-2026-11-15.md)).
- **2026-11-16:** approved M5's scope.
- **2026-11-18:** ChatGPT's independent review of `cd28f55`.
- **2026-11-19:** the owner played `20929cf`, `59562c6` and `ea86ae9` ([records](evidence/m5/)), with five points, four visual points and three points in motion, addressed in turn.
- **2026-11-20:** the owner played `b7303bf` and accepted M5 ([record](evidence/m5/owner-acceptance-2026-11-20.md)); authorized the squash merge and the branch's clean-up, and no tag or release.
- **2026-11-21:** asked for F2 and F3 (done in `1229ae6`); named `a30be86` the owner-test build; played it on Windows: **owner playtest satisfactory** for the route played, New Game through the running escape, the epilogue, the credits and the main menu; no changes requested; two observations left open ([record](m6/owner-test-build.md)). ChatGPT's comparison of the footage and audio samples is recorded as a signal check.
- **2026-11-21, later:** accepted M6 with the human checks carried forward; asked for the README and a native macOS Apple Silicon build before the merge; asked for M5's alpha to be published from `a4250f0`, and for M6 to get release-candidate artifacts and a tag proposal ([record](evidence/m6/owner-acceptance-2026-11-21.md)).
- **2026-11-22:** stated, in answer to the developer's question, that they heard the M5 build's main audio in play; `v0.2.0-alpha.1` published from `a4250f0` ([authorization](evidence/m5/release-authorization-2026-11-22.md), [publication](evidence/release-workflow/publication-v0.2.0-alpha.1.md)).

## Working resources

Outside the repository and outside `/tmp`.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`; `~/work/dagon-m4/m5-release` was #8's worktree. The folder's name is M4's. **The Windows working copy follows `main`;** work is done in the clone and pushed |
| Helpers, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `integration_point.sh <name>` and its `_v` and `_m` forms with silent video of the exported game, `focus.sh <name>`; `notes/` |
| M6's working files, `~/work/dagon-m6` | `baseline-a4250f0/` (the baseline's zips, unpacked, and its route runs), `listening/` (the listening kit's takes), `displays/` (display runs), `tools/` (`recl.sh`, `capdisplay.sh`, `pack_list.gd`), `m6-plan-draft.md` |
| M5's working files, `~/work/dagon-m5` | `bin/` (`recp.sh` for lossless Movie Maker takes, `timing.sh` for frame times at the game's own pace), `notes/` (the passes' takes, sheets and scripts), the accepted candidate's zips |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv`, `tts`, the private X server |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin <branch>`; a change to `.github/workflows` only over SSH, `git push git@github.com:shamsuzzamansadi/dagon.git <branch>` |

## Next concrete action

**The owner's word on the [tag proposal](evidence/m6/candidate-v0.2.0-alpha.2.md#the-tag-proposal-for-the-owners-word),** brought to them on 2026-11-22: `v0.2.0-alpha.2` on `b271316`, from `main`'s run 45038841566. Done before it: #7's merge, `main`'s CI on it, the candidate's verification. **Until then nothing more: publishing an M6 version and starting M7 need the owner's word.** The human checks stay pending until people do them: the two first-time players (on `a4250f0`) and their timings, the owner's listening sheet, the display switch as the monitor shows it, Continue after the credits, controllers, the native runs, and any Mac.
