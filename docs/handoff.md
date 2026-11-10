# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-10, at the start of M4.

## Where things are

| | |
|---|---|
| **Milestone** | **M3 accepted by the owner on 2026-11-10 at `3980bc3`,** as the completed, agreed milestone, with the documented M4/M5 and hardware and playtesting deferrals ([record](evidence/m3/owner-acceptance-2026-11-10.md)). **Milestone acceptance, not approval of a finished release.** Squash-merged into `main` through [#3](https://github.com/shamsuzzamansadi/dagon/pull/3) with this record |
| **Review** | ChatGPT's limited follow-up review at `3980bc3`: native tests, breakage-tool, release-tool and art checks passed independently; no new blocking code defect in the areas reviewed; integration, exported-route and listening not rerun or judged ([record](evidence/m3/review-chatgpt-at-3980bc3.md)) |
| **Acceptance fingerprint** | `sha256:892b1072136b806ee25340c4cc3f8cefaa36880ae5d7399bd70e6e42f744e453` |
| **Releases** | **None.** `release/v0.1.0-pre-alpha.1.json` stays `planned`. Do not tag or publish without the owner asking |
| **Merged** | Squash commit `ad6df8c` on `main`, through [#3](https://github.com/shamsuzzamansadi/dagon/pull/3). `main`'s CI, run [42817688574](https://github.com/shamsuzzamansadi/dagon/actions/runs/42817688574), passed: GCC, Clang, MSVC, the release tools, and the release gate, which found the record `planned` and published nothing. The M3 branch is deleted, locally and remotely |
| **Now** | **M4, Atmosphere, on `m4/atmosphere`,** from `ad6df8c`. **[The plan](m4-plan.md) is proposed, for the owner.** Nothing is implemented yet |

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

## Temporary resources

These may be gone. Everything finished is pushed.

| What | Where |
|---|---|
| Native clone | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Voice environment and models, for `tools/audio/make_audition.py --speak` | `$S/tts/`, `$S/voice-models/`, `$S/hf/`; speech data linked from `~/.cache/dagon-voice-short/data` |
| Private X display | `$S/xns.sh`, run with `unshare -rm` (docs/toolchain.md §6a). One at a time |

## Next concrete action

The owner's word on [the M4 plan](m4-plan.md). Then its first item: the prologue spoken in voice A.
