# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-11, during M4, after its second item and a recovery from a lost working folder.

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
| 3 | Environment art past x = 1440, in route order | **Started, nothing committed.** `tools/art/gen_abyss.py` draws the Abyss's ground from the scene's own collision, and `project/tests/capture_m4.gd` captures the route by stretch; neither is wired into `generate.py`, the scene or `check_art.py` yet. Both sit uncommitted in the native clone | |
| 4 | Audio polish | Not started | |
| 5 | Further narration | Not started beyond the two Shore lines of item 2 | |
| 6 | Validation, review package, identified build | Not started. **No draft pull request yet:** it is opened with this push | |

**Results on `6e4a4ab`,** all run on the native Linux clone after the tree was recovered (see below), GCC: `scons unit_tests` 127 test cases passed; `tools/run_godot_checks.sh` (debug build): import, classes, integration **434 passed, 0 failed**, three smoke runs, all ok; release build; `tools/export_check.sh linux` ok; the exported route by `tools/route_check.py` on a private display: `ROUTE_RESULT runs=4 failed=0`. CI on this commit: check the pull request.

**Measured on the opening's recording, not heard:** each prologue line 9.1 to 13.9 dB above the music and sea under it; the bed ducks 4.4 to 5.3 dB for the voice; the mix peaks at −2.8 dBFS; no sudden change in level at the cut into the game. Whether it sounds right is the owner's to judge.

**An interruption on 2026-11-11, and what it cost.** The machine restarted and emptied `/tmp`, where the native clone, the voice tools and item 2's uncommitted work and validation logs were. Nothing pushed was lost. Item 2 was rebuilt by replaying the session's own recorded edit commands onto a fresh clone of `ecad573`, each checked against its recorded output; the two voice lines were regenerated with the same seed and settings (same durations, pace and peaks, transcribed again); the recording was made again and its measurements came out the same. **The earlier validation results were not carried over: every result above is from a fresh run on the recovered tree.** The step 1 video's double-size copy was made from its committed file, since its raw recording was gone. The clone and tools now live under the home folder, not `/tmp`.

**Risks, as of this update:** art is the largest item and has barely begun; about an hour of the 11–14 November window went to the recovery. If art runs late, the plan's own fallback applies: the stretches nearest the reveal first, the Abyss's middle keeping the finished far view over simpler ground, identified as unfinished.

## Working resources

Outside the repository, but no longer in `/tmp`. Everything finished is pushed.

| What | Where |
|---|---|
| Native clone, where M4 is built and tested | `~/.cache/dagon-m4/S/work` (call its parent `$S`). Session scratch: `~/.cache/dagon-m4/N` (`$N`) |
| Build | `$S/venv/bin/scons`, with `SCONS_CACHE=~/.cache/dagon-scons`. The same environment has Pillow, NumPy, SciPy and soundfile for `tools/art` and `tools/audio/listening.py`, and `imageio_ffmpeg`'s `ffmpeg` for encoding |
| Voice environment and models, for `tools/audio/make_audition.py --speak` and `check_narration.py` | `$S/tts/` (conda, Python 3.11: torch 2.6.0 CPU, chatterbox-tts 0.1.2, kokoro-onnx 0.4.9, numpy 1.26.4, setuptools < 81, soundfile, scipy), `$S/voice-models/` (Kokoro v1.0 model and voices), `$S/hf/` (set `HF_HOME=$S/hf`); speech data linked from `~/.cache/dagon-voice-short/data` (set `ESPEAK_DATA_PATH` to it) |
| Private X display | `$S/xns.sh`, run with `unshare -rm` (docs/toolchain.md §6a), from packages unpacked into `$S/xroot`. One at a time |
| Helpers | `$N/focus.sh <text>` (focused integration run; empty text runs everything), `$N/record.sh <script> <dir>` (Movie Maker on the private display), `$N/cap.sh <dir> [filter]` (route captures and contact sheets) |
| The session's recorded commands, used for the recovery | `~/.cache/dagon-m4/replay/` |

## Next concrete action

Item 3 of [the plan](m4-plan.md), first stretch: wire `gen_abyss.ground_tiles()` into `tools/art/generate.py` and the scene (sprites under `Terrain`, the greybox ground hidden, collision untouched), add the Abyss surface to `check_art.py`, then the canyon walls and far view in place of `GreyboxBackdrop`, `CanyonRim` and `FarRidges/Silhouette`, keeping the watcher and the distant shape reading. Capture with `$N/cap.sh`, look, commit and push; then the rib arch.
