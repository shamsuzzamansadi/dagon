# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-13, during M4's sixth item: items 1 to 5 done, breakage and the recording done; the final integration point, review package and Windows build remain. **The M4 window ends on 14 November.**

## Where things are

| | |
|---|---|
| **Milestone** | **M3 accepted by the owner on 2026-11-10 at `3980bc3`,** as the completed, agreed milestone, with the documented M4/M5 and hardware and playtesting deferrals ([record](evidence/m3/owner-acceptance-2026-11-10.md)). **Milestone acceptance, not approval of a finished release.** Squash-merged into `main` through [#3](https://github.com/shamsuzzamansadi/dagon/pull/3) with this record |
| **Review** | ChatGPT's limited follow-up review at `3980bc3`: native tests, breakage-tool, release-tool and art checks passed independently; no new blocking code defect in the areas reviewed; integration, exported-route and listening not rerun or judged ([record](evidence/m3/review-chatgpt-at-3980bc3.md)) |
| **Acceptance fingerprint** | `sha256:892b1072136b806ee25340c4cc3f8cefaa36880ae5d7399bd70e6e42f744e453` |
| **Releases** | **None.** `release/v0.1.0-pre-alpha.1.json` stays `planned`. Do not tag or publish without the owner asking |
| **Merged** | Squash commit `ad6df8c` on `main`, through [#3](https://github.com/shamsuzzamansadi/dagon/pull/3). `main`'s CI, run [42817688574](https://github.com/shamsuzzamansadi/dagon/actions/runs/42817688574), passed: GCC, Clang, MSVC, the release tools, and the release gate, which found the record `planned` and published nothing. The M3 branch is deleted, locally and remotely |
| **Now** | **M4, Atmosphere, on `m4/atmosphere`,** from `ad6df8c`. **The owner approved [the plan](m4-plan.md) on 2026-11-10** and authorized its implementation in order, stopping at independent review and owner acceptance: no merge, tag, release or itch.io submission. **Window: 11–14 November. The owner's target is still completion before 20 November** |

## M3 requirements: done and accepted

| Requirement | Where |
|---|---|
| The route, puzzle, cinematic contract, saves, narration plumbing and vibration | Package §1–§12 |
| A short skippable prologue: captivity, escape, drift, waking, with restrained motion and its own sound | D71, D88 |
| One environmental interaction in Act II: a stone pushed onto a raised slab, with a readable carving | D72, D83, D87 |
| A visible returning sea in the escape, with a bounded fallback | D73 |
| The stranded tentacle, the Shore's remains, and the carvings that echo them | D82, D84 |
| The sailor's progression | D76, D84 |
| A script whose chronology holds | D81, D86 |
| An initial sound pass, music in five places, the mix measured and fixed | D74, D85, D91 |
| One finished reference section, and a coherent boundary into the greybox | D77, D89 |
| The monolith, the creature and the reveal as a payoff | D84, D90 |
| A short visual epilogue, fully voiced in voice A, the owner's choice | D86, D94 |
| A voice audition, a listening package, and recordings with sound | D79, D92, D94 |

## Deferred, and not passed

**To M4 and M5** (the [roadmap](roadmap.md) lists them):

1. **Narration:** the rest of the script in voice A, the prologue first.
2. **Art past x = 1440:** the Exposed Abyss's ground, canyon walls, rib arch and far view; the shelves and tablets; the crossing's ledges, slab and stone; the trench, gate and stones at the monolith; the lit mural's panel; the creature's own animation; the ritual and watcher beyond silhouettes; the escape's rockfall and returning sea.
3. **Sound:** the final mix by ear, interface sounds, a sound for examining.

**Hardware:** all physical PlayStation hardware; individual physical Xbox actions, including disconnecting and reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering.

**Playtesting, for M6:** two external first-time players, their timings, and first-time duration, all unmeasured so far.

**Carried over:** the unresolved M2 J/caption event. The two breakage survivors of the revision, which the reviewer considered non-blocking.

**M3 is closed. Its deferrals are M4's and later milestones' work, not reasons to reopen it.**

## Owner feedback, in order

- **2026-11-04:** improved but not engaging enough ([record](evidence/m3/owner-playtest-2026-11-04.md)).
- **2026-11-09, on `5fe820b`:** functional, but too brief, too passive and not atmospheric enough ([record](evidence/m3/owner-playtest-2026-11-09.md)).
- **2026-11-09, on a build of `53e8d23`:** improved substantially; four concerns, answered by D87–D93.
- **2026-11-10:** chose voice A; then accepted M3 at `3980bc3`.

## M4 progress

| # | Item of [the plan](m4-plan.md) | State | Commit |
|---|---|---|---|
| 1 | The prologue spoken in voice A | **Done.** Four lines, each transcribed word for word; tests; a recording with sound; the voice measured against the music and sea beneath it ([narration record](evidence/m4/narration/README.md), [recording and measurements](evidence/m4/prologue/README.md), D95, D96). **Not listened to by anyone yet** | `2ccde53` |
| 2 | Continuity from the prologue into the Shore; the Shore's first lines voiced | **Done.** New Game, How to Play, Begin, prologue, then straight into the game with nothing between: the last picture is the Shore's own opening view, the sailor gets up beside his boat under the cinematic contract (`shore_wake`), and the last picture carries the Shore's sea and wind so the sound does not drop at the cut. `shore.boat` and `shore.fish` in voice A, word for word; twelve lines voiced in all ([recording and measurements](evidence/m4/opening/README.md), D97–D99). Continue and Restart never show the prologue or the waking. **Not listened to by anyone yet** | `6e4a4ab` |
| 3 | Environment art past x = 1440, in route order | **Done: seven stretches, no greybox shape left on the route** ([captures](evidence/m4/art/README.md), D100). A ground and far view; B the rib arch; C the crossing; D the shelves, tablets and props; E the canyon, the puzzle stones, the gate and the trench behind the reveal; F the mural, faint and lit; G the flight's rock, dust, the two seas and the fog's edge (M3 deferred these with the art past 1440). What still shows as a flat shape is M5's: the creature and the ritual's far figures. **Known:** a seam beside the creature's arm at the reveal, from the Shore's screen-fixed sky; the greybox had it; the reveal's composition is M5's. **Looked at by the developer only** | `622ca0e` A, `cdb1ba6` B, `a9bbd3c` C, `b5bd3b2` D, `5ed5c01` E, `c8cb324` F, `27d918f` G |
| 4 | Audio polish | **Made and measured; not heard by anyone** ([record](evidence/m4/audio/README.md), D101). Interface sounds, an examine sound, three Abyss beds, weight for the rockfall and both seas. The game's mix recorded and measured, and cut into a [listening package](evidence/m4/listening/README.md) for the owner. **Waiting on:** the owner's listening, to set the reveal's level and the mix | `6eea116`; package `5d83ea6` |
| 5 | Further narration | **Done: every story line spoken,** 22 lines in all, each word-checked; the reveal's lines respaced so each is heard out, and a test holds every clip to it ([record](evidence/m4/narration/README.md), D102). Examine lines stay text. **Not listened to by anyone** | `8589ebd` |
| 6 | Validation, review package, identified build | **Under way.** Done: focused breakage of M4's new logic ([result](evidence/m4/breakage.txt)); the whole game recorded with sound. Left: the integration point on the final code, the review package, the Windows build named with its checksum, the pull request's text. **Draft pull request: [#4](https://github.com/shamsuzzamansadi/dagon/pull/4),** open, not for merging | `e24d726`, `5d83ea6`, `d0d0606` |

**Results on `6e4a4ab`,** all run on the native Linux clone after the tree was recovered (see below), GCC: `scons unit_tests` 127 test cases passed; `tools/run_godot_checks.sh` (debug build): import, classes, integration **434 passed, 0 failed**, three smoke runs, all ok; release build; `tools/export_check.sh linux` ok; the exported route by `tools/route_check.py` on a private display: `ROUTE_RESULT runs=4 failed=0`. CI on this commit: check the pull request.

**CI on `3c3e550`** (item 2 and its handoff): runs [42976363793](https://github.com/shamsuzzamansadi/dagon/actions/runs/42976363793) and [42976444602](https://github.com/shamsuzzamansadi/dagon/actions/runs/42976444602), both passed: GCC, Clang, MSVC and the release tools.

**Results on `622ca0e`** (stretch A), native Linux clone, GCC debug: `tools/art/check_art.py` problems=0, including the new comparison of the Abyss's ground with the collision (3080 columns) and of the far cliff with the watcher and the distant shape; integration **435 passed, 0 failed**.

**CI on `7781ea4`** (stretch A and its handoff; the code is `622ca0e`'s): pull-request run [43441243947](https://github.com/shamsuzzamansadi/dagon/actions/runs/43441243947) **passed**: GCC, Clang, MSVC and the release tools. Push run [43441235507](https://github.com/shamsuzzamansadi/dagon/actions/runs/43441235507): GCC, Clang and the release tools passed; its Windows job was still running when this was written.

**Results on `cdb1ba6` to `27d918f`** (art B to G), native Linux clone, GCC debug, each on its own commit: `check_art.py` problems=0; integration **435 passed, 0 failed**. Captures, and frames of the reveal and the flight as they play, looked at by the developer only. CI on each of `cdb1ba6` to `c8cb324` passed (GCC, Clang, MSVC, release tools).

**The integration point, on `27d918f`** (all of item 3; [logs](#working-resources) in `$W/notes/int-27d918f`): debug and release builds up to date; `tools/run_godot_checks.sh`: clean import, classes, integration **435 passed, 0 failed**, three smoke runs, all ok; `tools/export_check.sh linux` ok (release extension loaded, new game and continue ran); the exported route by `tools/route_check.py` on a private display: **`ROUTE_RESULT runs=4 failed=0`**. No C++ changed between `6e4a4ab` and `27d918f`, so `6e4a4ab`'s unit tests (127 passed) stand for it.

**Results on `6eea116`** (item 4), GCC debug: integration **438 passed, 0 failed**, three new tests among them. A first run found the scene-changing presses playing a sound outside the tree (fixed: such a press is not played) and the two new beds not looping (fixed in their import settings); both were caught by the suite.

**How the art goes in.** Static pieces are baked into the ground strip in `gen_abyss.ground()`, painted before the mud so it lies against their feet; their greybox polygons are hidden, not deleted. Moving pieces get a `Drawn` sprite on their own body (the slab on `Crossing`, the boulder on `CrossingStone`), so the puzzle moves the drawing. Still to come that way: the gate and the three puzzle stones with their lit signs. The recorded wiring scripts are in `$W/notes/drafts/` (below).

**Measured on the opening's recording, not heard:** each prologue line 9.1 to 13.9 dB above the music and sea under it; the bed ducks 4.4 to 5.3 dB for the voice; the mix peaks at −2.8 dBFS; no sudden change in level at the cut into the game. Whether it sounds right is the owner's to judge.

**An interruption on 2026-11-11, and what it cost.** The machine restarted and emptied `/tmp`, where the native clone, the voice tools and item 2's uncommitted work and validation logs were. Nothing pushed was lost. Item 2 was rebuilt by replaying the session's own recorded edit commands onto a fresh clone of `ecad573`, each checked against its recorded output; the two voice lines were regenerated with the same seed and settings (same durations, pace and peaks, transcribed again); the recording was made again and its measurements came out the same. **The earlier validation results were not carried over: every result above is from a fresh run on the recovered tree.** The step 1 video's double-size copy was made from its committed file, since its raw recording was gone. The clone and tools now live under the home folder, not `/tmp`.

**Results on `8589ebd`** (item 5), GCC debug: narration tests 46 passed; integration **439 passed, 0 failed**, after a clean import (an incremental import once crashed Godot at shutdown, signal 11, leaving one recording without its import file; a clean import did not). 22 recordings transcribed word for word, Innsmouth's recorded exception aside. CI passed on `0212a95`, `8589ebd`, `e24d726` and `5d83ea6`: GCC, Clang, MSVC, release tools.

**Breakage, at `e24d726`** (`tools/breakage_m4.py`, 17 entries, 3 workers, controls held): **16 caught, 1 not caught.** The survivor, dropping `waking_ = false`, had no effect but `is_waking()` reporting a spent waking as pending; `d0d0606` adds that check, and the breakage alone, re-run with its controls on `d0d0606`: **caught; the clean controls passed, the one after it 439 passed, 0 failed**.

**The recording, at `e24d726`** (`record_play.gd`, 5 min 39 s): `MIX_CHECK problems=0`; no clipping, true peak −1.0 dBTP; the reveal −17.4 LUFS. **One unexpected change: a 20 ms drop at the cut into the game,** absent from a second recording of the same build with `record_prologue.gd`; cause not established; recorded as such.

**Risks and forecast, as of this update (13 November, evening):** items 1 to 5 are done; item 6 needs the integration point on the final code (checks, export, exported route: about 25 minutes), the review package and the Windows artifact from CI, all within 14 November. **No blocker on the developer's side.** What then waits is the owner's listening (the mix), the independent review and the owner's decision. Nothing has been dropped or reduced.

## Working resources

Outside the repository, outside `/tmp` and outside caches. Everything finished is pushed.

| What | Where |
|---|---|
| Durable work, `$W` = `~/work/dagon-m4` | `$W/clone`: the native clone, where M4 is built and tested. `$W/notes`: logs, captures by stretch (`cap-b`, `cap-c`, ...), commit messages, `drafts/` (the recorded wiring scripts `wire_a.py`, `wire_b.py`, `wire_c.py`, and handoff edits), `proto/` (offline previews), `setup-logs/`. `$W/replay`: the session commands used in the 11 November recovery |
| Helpers, `$W/bin` | `env.sh` (source it: sets `W`, `S`, `CLONE`, `NOTES`, `SCONS_CACHE`, `GODOT`, `FF`), `xns.sh` (private X display in `unshare -rm`, docs/toolchain.md §6a; one at a time), `cap.sh <dir> [filter]` (route captures and sheets), `focus.sh <text>` (integration run; empty text runs everything), `record.sh <script> <dir>` (Movie Maker on the private display) |
| Rebuildable environments, `$S` = `~/.cache/dagon-m4/S` | `$S/venv` (scons, Pillow, NumPy, SciPy, soundfile, `imageio_ffmpeg`); `SCONS_CACHE=~/.cache/dagon-scons`; voice: `$S/tts/` (conda, Python 3.11: torch 2.6.0 CPU, chatterbox-tts 0.1.2, kokoro-onnx 0.4.9, numpy 1.26.4, setuptools < 81, soundfile, scipy), `$S/voice-models/`, `$S/hf/` (`HF_HOME`), speech data in `~/.cache/dagon-voice-short/data` (`ESPEAK_DATA_PATH`); X: `$S/xroot`, `$S/xdeb`, `$S/ovl`. `~/.cache/dagon-m4/voice-src/tree` is a clean checkout of `ecad573` |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m4/atmosphere` |

## Next concrete action

Item 6: run `$W/bin/integration_point.sh int-<commit>` on the final code commit (release build first: C++ changed in `6eea116`); then CI on it; download its push run's `dagon-windows` and take its SHA-256; finish `docs/reviews/m4-review-package.md` from the draft in `$W/notes/m4-review-package.draft.md`; update the pull request's text. Stop there for review and the owner.
