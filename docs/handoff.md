# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-10, during M4, after its first item.

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
| 1 | The prologue spoken in voice A | **Done.** Four lines, each transcribed word for word; tests; a recording with sound; the voice measured at 8.9 to 18.9 dB above the music and sea beneath it ([narration record](evidence/m4/narration/README.md), [recording and measurements](evidence/m4/prologue/README.md), D95, D96). **Not listened to by anyone yet** | `2ccde53` |
| 2 | Continuity from the prologue into the Shore; the Shore's first lines voiced | **Next.** Design settled, nothing committed: see below | |
| 3 | Environment art past x = 1440, in route order | Not started | |
| 4 | Audio polish | Not started | |
| 5 | Further narration | Not started | |
| 6 | Validation, review package, identified build | Not started. **No draft pull request yet** | |

**Results on `2ccde53`:** `tools/run_godot_checks.sh` on the native Linux clone, GCC debug build of the unchanged C++: import, classes, integration **424 passed, 0 failed**, three smoke runs, all ok. CI has not run on it yet. No C++ changed, so the library is M3's.

**The design for item 2, decided but not built:**
- The How to Play card moves to the main menu, before the prologue: New Game, How to Play, Begin, prologue, Shore. Nothing then sits between the last picture and the game. Continue is unchanged.
- The last picture becomes the Shore's own opening view, with the man lying, then sitting, where the sailor starts.
- In the game, a new game opens on a short cinematic under the existing contract (`shore_wake`): he rises from sitting. `PlayerController` gets a pose that only shows while control is locked, and is cleared when control returns, so a stuck clip cannot leave him on the ground. Continue and Restart never play it.
- `shore.boat` and `shore.fish` spoken in voice A.
- Tests, the route player, `record_play.gd`, `session_probe.gd` and `tools/route_check.py` expect the card after the prologue, and change with it.

**Risks, as of this update:** art is the largest item and has not started; the window is four days. The voice tools run only from the temporary folder below, which a reboot would remove; rebuilding it takes about half an hour.

## Temporary resources

These may be gone. Everything finished is pushed.

| What | Where |
|---|---|
| Native clone, where M4 is being built and tested | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Voice environment and models, for `tools/audio/make_audition.py --speak` and `check_narration.py` | `$S/tts/`, `$S/voice-models/`, `$S/hf/` (set `HF_HOME=$S/hf HF_HUB_OFFLINE=1`); speech data linked from `~/.cache/dagon-voice-short/data` (set `ESPEAK_DATA_PATH` to it) |
| Encoder for recordings | the `ffmpeg` inside `$S/venv`'s `imageio_ffmpeg` |
| The prologue's rejected takes | the M4 session's scratch folder, `takes/seed-7` to `seed-10`; not kept in the repository |
| Private X display | `$S/xns.sh`, run with `unshare -rm` (docs/toolchain.md §6a). One at a time |

## Next concrete action

Item 2 of [the plan](m4-plan.md): build the continuity into the Shore as designed above, starting with the pose in `PlayerController` and the `shore_wake` clip, then the card's move and the tests that follow it. Open the draft pull request once it holds together.
