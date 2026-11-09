# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-09, at the end of the owner's refinements of M3.

## Where things are

| | |
|---|---|
| **Milestone** | M3, expanded by the owner on 2026-11-09 ([D70](decisions.md)) and refined the same day ([D82–D86](decisions.md)). **Implemented. Not owner-accepted. Independent follow-up review not yet done. Not merged** |
| **Branch and pull request** | `m3/complete-gameplay`, draft [#3](https://github.com/shamsuzzamansadi/dagon/pull/3), based on `main` at `15ba96c` |
| **The build to play, and its CI** | Named in the pull request, with the Windows artifact's SHA-256. Not recorded here, so that no commit is made only to record the last one's CI |
| **Hold** | Do not merge, tag, publish, delete the branch, mark a release accepted, or start general M4 production. **Stopped at independent review and the owner's playtest** |
| **Dependency** | ChatGPT's follow-up review, the owner's playtest, and the owner's choice of voice |

## Approved scope, and exclusions

**In M3, as the owner expanded it on 2026-11-09:** a short skippable prologue, one environmental interaction in Act II, a visible returning sea in the escape, a stranded tentacle echoed in the carvings, the sailor's reactions, a script review for chronology, an initial sound pass across the route with selective music, one visually finished reference section from the cave entrance, and a replacement voice audition. **Then the ten refinements:** the opening, the exposed seabed and the arm, observation that helps at the gap, the monolith and the reveal as a payoff, the sailor's progression, a complete initial sound experience, the voice kept separate, the ending's consequence, bounded art, and validation. Everything from before stays.

**The owner's reference:** an illustrated adaptation of the story, for dramatic structure only. Nothing from it is used. ChatGPT inspected sampled frames of it and did not evaluate its soundtrack. That is not a review of this game.

**Excluded by the owner:** a playable ship level, a sailing simulation, a new act, combat, enemy AI, inventory, branching story, a sanity meter, inverted controls, constant distortion. Lengthening play by slower movement, empty corridors, repeated puzzles or compulsory narration waits. Mass-producing narration with an unapproved voice. Cloning the reference's narrator or any person. Spending money.

**Still with M4 and M5:** finished art for the rest of the route past x = 1440, the creature's own animation, the final mix by ear, final narration once a voice is chosen.

**Not to reopen:** the release engineering work, which is complete and accepted. D78 changed three of its scripts only so that a run ends quietly.

## Owner feedback, and review

- **2026-11-04:** improved but not engaging enough ([record](evidence/m3/owner-playtest-2026-11-04.md)).
- **2026-11-09, on `5fe820b`, which the owner reports playing; no artifact checksum verified:** functional, but too brief, too passive and not atmospheric enough. The synthetic voice is not approved ([record](evidence/m3/owner-playtest-2026-11-09.md)).
- **ChatGPT reviewed `5fe820b`** within stated limits ([record](evidence/m3/review-chatgpt-at-5fe820b.md)).
- **Not accepted. No voice approved.**

## Done

The revision and the refinements are on the branch. D70–D86 record each choice. **The review package's §0 sets out what changed, the pacing, the sound, the art, the tests and the owner's checklist.**

## Results, each with its commit

| Result | Commit | Who | Outcome |
|---|---|---|---|
| Local check script: import, 11 classes, 414 integration tests, three smoke runs, no leak or error lines | The refinements' commit | Developer | Pass |
| Native tests: 127 cases | The same | Developer | Pass |
| Export check: 414 tests on the exported Linux pack | The same | Developer | Pass |
| Exported Linux route, four runs, on a private virtual display | The same | Developer, scripted | Pass. Timings in the package's §0.2 |
| CI on GCC, Clang and MSVC, with the exported routes on Linux and Windows | The refinements' commit | CI | **In the pull request** |
| CI | `525a8b2` | CI | Pass. It corrected the route driver, which still waited for the boat's old caption and failed CI on `42b2193` |
| Focused breakage of the revision, 23 entries, fail-closed | `b4bd9c2` | Developer, scripted | 21 caught, 2 not caught, which are unresolved interpretations for the reviewer. Controls held |
| Earlier results | before `5fe820b` | | Kept in the package and `evidence/m3/`. Still valid for what did not change |

## Known problems

- **First-time duration is unmeasured.** Scripted runs are not playtests.
- **Nobody on the project has heard the sound pass or the voice candidates.**
- **Art past x = 1440 is greybox,** apart from the monolith and the creature. The lit mural's panel, the slab and the carved stone by the gap are plain shapes.

## Owner decisions pending

- **The voice:** A, B, a person, or neither ([audition](evidence/m3/voice-audition/README.md)). Then the whole epilogue is narrated first.
- **The schedule:** completion before 20 November; a move to 24 November is not approved. The concrete risks are in the package's §0.8.
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

None until the follow-up review and the owner's playtest report back. Then act on them, and on the owner's choice of voice.
