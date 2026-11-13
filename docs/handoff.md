# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-13, during M4's third item, after stretches B and C. **The M4 window ends on 14 November.**

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
| 3 | Environment art past x = 1440, in route order | **Three stretches of six done: A, the Abyss's ground and far view; B, the rib arch; C, the crossing's ledges, post, slab and stone** ([captures](evidence/m4/art/README.md), D100). The seam at 1440 is gone and the Abyss is open to the sky. **Still greybox, in order: D the shelves, tablets and other props; E the canyon, trench, gate and puzzle stones; F the lit mural.** Drafts for D and E are in `gen_abyss.py`, unvalidated; nothing yet for the trench or the lit mural | `622ca0e` (A), `cdb1ba6` (B), `a9bbd3c` (C) |
| 4 | Audio polish | Not started | |
| 5 | Further narration | Not started beyond the two Shore lines of item 2 | |
| 6 | Validation, review package, identified build | Not started. **Draft pull request: [#4](https://github.com/shamsuzzamansadi/dagon/pull/4),** open, not for merging | |

**Results on `6e4a4ab`,** all run on the native Linux clone after the tree was recovered (see below), GCC: `scons unit_tests` 127 test cases passed; `tools/run_godot_checks.sh` (debug build): import, classes, integration **434 passed, 0 failed**, three smoke runs, all ok; release build; `tools/export_check.sh linux` ok; the exported route by `tools/route_check.py` on a private display: `ROUTE_RESULT runs=4 failed=0`. CI on this commit: check the pull request.

**CI on `3c3e550`** (item 2 and its handoff): runs [42976363793](https://github.com/shamsuzzamansadi/dagon/actions/runs/42976363793) and [42976444602](https://github.com/shamsuzzamansadi/dagon/actions/runs/42976444602), both passed: GCC, Clang, MSVC and the release tools.

**Results on `622ca0e`** (stretch A), native Linux clone, GCC debug: `tools/art/check_art.py` problems=0, including the new comparison of the Abyss's ground with the collision (3080 columns) and of the far cliff with the watcher and the distant shape; integration **435 passed, 0 failed**.

**CI on `7781ea4`** (stretch A and its handoff; the code is `622ca0e`'s): pull-request run [43441243947](https://github.com/shamsuzzamansadi/dagon/actions/runs/43441243947) **passed**: GCC, Clang, MSVC and the release tools. Push run [43441235507](https://github.com/shamsuzzamansadi/dagon/actions/runs/43441235507): GCC, Clang and the release tools passed; its Windows job was still running when this was written.

**Results on `cdb1ba6`** (B) **and `a9bbd3c`** (C), native Linux clone, GCC debug, each on its own commit: `check_art.py` problems=0 (C adds the slab and stone to its palette check); integration **435 passed, 0 failed**. Captures looked at by the developer only, at game scale and zoomed, with the approach and the way out of each stretch. **Not run locally since `6e4a4ab`:** the smoke runs of `tools/run_godot_checks.sh`, the release build, the export check and the exported route; they are due at the next integration point, after the art. CI on `cdb1ba6` and `a9bbd3c`: read it from the pull request.

**How the art goes in.** Static pieces are baked into the ground strip in `gen_abyss.ground()`, painted before the mud so it lies against their feet; their greybox polygons are hidden, not deleted. Moving pieces get a `Drawn` sprite on their own body (the slab on `Crossing`, the boulder on `CrossingStone`), so the puzzle moves the drawing. Still to come that way: the gate and the three puzzle stones with their lit signs. The recorded wiring scripts are in `$W/notes/drafts/` (below).

**Measured on the opening's recording, not heard:** each prologue line 9.1 to 13.9 dB above the music and sea under it; the bed ducks 4.4 to 5.3 dB for the voice; the mix peaks at −2.8 dBFS; no sudden change in level at the cut into the game. Whether it sounds right is the owner's to judge.

**An interruption on 2026-11-11, and what it cost.** The machine restarted and emptied `/tmp`, where the native clone, the voice tools and item 2's uncommitted work and validation logs were. Nothing pushed was lost. Item 2 was rebuilt by replaying the session's own recorded edit commands onto a fresh clone of `ecad573`, each checked against its recorded output; the two voice lines were regenerated with the same seed and settings (same durations, pace and peaks, transcribed again); the recording was made again and its measurements came out the same. **The earlier validation results were not carried over: every result above is from a fresh run on the recovered tree.** The step 1 video's double-size copy was made from its committed file, since its raw recording was gone. The clone and tools now live under the home folder, not `/tmp`.

**Risks and forecast, as of this update (13 November, 15:40):** three art stretches of six are done; D, E and F remain, and E and F need new drawing (the trench, the lit mural). Then the integration point, items 4 and 5, and item 6's validation, recording and identified build. **The 14 November window will not hold for all of it.** Realistic: the art and its integration point by the end of 14 November; audio polish and further narration on 15 November; validation, the review package, the recording and the Windows build by 16 November. The mix by ear waits on the owner's listening, which only the owner can give. Nothing has been dropped or reduced; this eats into M5's 15–17 November, and the owner's target of completion before 20 November still stands. Whether to move M5 is the owner's decision.

## Working resources

Outside the repository, outside `/tmp` and outside caches. Everything finished is pushed.

| What | Where |
|---|---|
| Durable work, `$W` = `~/work/dagon-m4` | `$W/clone`: the native clone, where M4 is built and tested. `$W/notes`: logs, captures by stretch (`cap-b`, `cap-c`, ...), commit messages, `drafts/` (the recorded wiring scripts `wire_a.py`, `wire_b.py`, `wire_c.py`, and handoff edits), `proto/` (offline previews), `setup-logs/`. `$W/replay`: the session commands used in the 11 November recovery |
| Helpers, `$W/bin` | `env.sh` (source it: sets `W`, `S`, `CLONE`, `NOTES`, `SCONS_CACHE`, `GODOT`, `FF`), `xns.sh` (private X display in `unshare -rm`, docs/toolchain.md §6a; one at a time), `cap.sh <dir> [filter]` (route captures and sheets), `focus.sh <text>` (integration run; empty text runs everything), `record.sh <script> <dir>` (Movie Maker on the private display) |
| Rebuildable environments, `$S` = `~/.cache/dagon-m4/S` | `$S/venv` (scons, Pillow, NumPy, SciPy, soundfile, `imageio_ffmpeg`); `SCONS_CACHE=~/.cache/dagon-scons`; voice: `$S/tts/` (conda, Python 3.11: torch 2.6.0 CPU, chatterbox-tts 0.1.2, kokoro-onnx 0.4.9, numpy 1.26.4, setuptools < 81, soundfile, scipy), `$S/voice-models/`, `$S/hf/` (`HF_HOME`), speech data in `~/.cache/dagon-voice-short/data` (`ESPEAK_DATA_PATH`); X: `$S/xroot`, `$S/xdeb`, `$S/ovl`. `~/.cache/dagon-m4/voice-src/tree` is a clean checkout of `ecad573` |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m4/atmosphere` |

## Next concrete action

Item 3, stretch D: the shelves, tablets and other props (`draw_props_behind`, `draw_props`, `draw_footprint` in `gen_abyss.py`; also the three prints `ActArt/PrintDown0` to `2` and the alcove, which no draft covers), baked into the ground strip as B and C were; hide their greybox; regenerate; import; capture with `$W/bin/cap.sh $W/notes/cap-d d`; look, including the way in and out; `check_art.py`; integration; evidence row; commit and push. Then E and F. Then the integration point: `tools/run_godot_checks.sh`, `scons unit_tests`, the release build, `tools/export_check.sh linux` and the exported route by `tools/route_check.py`, all on one commit.
