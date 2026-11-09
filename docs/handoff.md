# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-09, during the owner's revision of M3.

## Where things are

| | |
|---|---|
| **Milestone** | M3, expanded by the owner on 2026-11-09 ([D70](decisions.md)). **Implemented. Not owner-accepted. Independent follow-up review not yet done. Not merged** |
| **Branch and pull request** | `m3/complete-gameplay`, draft [#3](https://github.com/shamsuzzamansadi/dagon/pull/3), based on `main` at `15ba96c` |
| **Hold** | Do not merge, tag, publish, delete the branch, mark a release accepted, or start general M4 production. Stop at a reviewable result |
| **Dependency** | ChatGPT's follow-up review, the owner's playtest, and the owner's choice of voice |

## Approved scope, and exclusions

**In M3, as the owner expanded it on 2026-11-09:** a short skippable prologue, one environmental interaction in Act II, a visible returning sea in the escape, a stranded tentacle echoed in the carvings, the sailor's reactions, a script review for chronology, **an initial sound pass across the route with selective music, one visually finished reference section from the cave entrance, and a replacement voice audition.** Everything from before stays: the route, the puzzle, the cinematic contract, saves, narration plumbing, vibration.

**Excluded by the owner:** a playable ship level, a sailing simulation, a new act, combat, enemy AI, inventory, branching story, a sanity meter, inverted controls, constant distortion. Lengthening play by slower movement, empty corridors, repeated puzzles or compulsory narration waits. Mass-producing narration with an unapproved voice. Spending money.

**Still with M4 and M5:** finished art beyond the reference section, the final Dagon, the final mix by ear, final narration once a voice is chosen.

**Not to reopen:** the release engineering work, which is complete and accepted. D78 changed three of its scripts only so that a run ends quietly.

## Owner feedback, and review

- **2026-11-04:** improved but not engaging enough ([record](evidence/m3/owner-playtest-2026-11-04.md)).
- **2026-11-09, on `5fe820b`, which the owner reports playing; no artifact checksum verified:** functional, but too brief, too passive and not atmospheric enough. The synthetic voice is not approved ([record](evidence/m3/owner-playtest-2026-11-09.md)).
- **ChatGPT reviewed `5fe820b`:** independently ran the native and release-tool tests, the art check and the release record, verified CI, and did a limited static review. It did not rerun the integration suite, the exported route or breakage, and did not listen ([record](evidence/m3/review-chatgpt-at-5fe820b.md)).
- **Not accepted. No voice approved.**

## Done in the revision

Commits `033c363`, `b4bd9c2` and `42b2193`, and any after them on the branch. D70–D81 record each choice. The review package's §13 sets out what changed, before and after.

## Results, each with its commit

| Result | Commit | Who | Outcome |
|---|---|---|---|
| Local check script: import, 11 classes, 407 integration tests, three smoke runs, no leak or error lines | `42b2193`'s tree | Developer | Pass |
| Native tests: 127 cases | `033c363` onwards | Developer | Pass |
| Breakage tool's own tests: 23 | `b4bd9c2` onwards | Developer | Pass |
| Focused breakage of the revision, 23 entries, fail-closed | `b4bd9c2` | Developer, scripted | 19 caught, 2 not caught, 2 INFRA, being rerun. Controls held. See the package |
| CI | `033c363`, `b4bd9c2` | CI | **Failed:** the test runner quit with sound playing, reported as a leak. Fixed in `42b2193` |
| CI | `42b2193` | CI | **Running when this was written** |
| Earlier results | before `5fe820b` | | Kept in the package and `evidence/m3/`. Still valid for what did not change |

## Known problems

- **First-time duration is unmeasured.** Scripted runs are not playtests.
- **Nobody on the project has heard the sound pass or the voice candidates.**
- **Art past x = 1440 is greybox,** by design of this revision.

## Owner decisions pending

- **The voice:** A, B, a person, or neither ([audition](evidence/m3/voice-audition/README.md)).
- **The schedule:** completion before 20 November; a move to 24 November is not approved. The dependencies are in the [roadmap](roadmap.md).
- **Acceptance of M3,** after the follow-up review and the owner's playtest.
- **Physical checks:** Xbox vibration, and what is deferred to M6. The M2 J/caption event is still unresolved.

## Temporary resources

These may be gone. Everything finished is pushed.

| What | Where |
|---|---|
| Native clone | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Breakage workers and results | `$S/brk/`, `$S/brk2/` |
| Voice environment and models, for `tools/audio/make_audition.py` | `$S/tts/`, `$S/voice-models/`, `$S/hf/` |
| Private X display | `$S/xns.sh`, run with `unshare -rm` (docs/toolchain.md §6a) |

## Next concrete action

Finish the review package and the pull request, confirm CI on the final commit, and hand off for review and the owner's playtest. Then stop.
