# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-10, after the owner's choice of voice and the fully voiced epilogue.

## Where things are

| | |
|---|---|
| **Milestone** | M3, expanded by the owner on 2026-11-09 ([D70](decisions.md)), refined ([D82–D86](decisions.md)), given a focused completion pass ([D87–D93](decisions.md)), and voiced in the owner's chosen voice ([D94](decisions.md)). **The agreed M3 work is done. Not owner-accepted. Independent follow-up review not yet done. Not merged** |
| **Branch and pull request** | `m3/complete-gameplay`, draft [#3](https://github.com/shamsuzzamansadi/dagon/pull/3), based on `main` at `15ba96c` |
| **The build to play, and its CI** | Named in the pull request: the push run's `dagon-windows` artifact for the head commit, with its zip SHA-256 ([D93](decisions.md)). Not recorded here, so that no commit is made only to record the last one's CI |
| **Hold** | Do not tag, publish, mark a release accepted, or start general M4 production. **Stopped at independent review and owner acceptance** |
| **Merge, when the gates are met** | Authorized by the owner: once the agreed M3 tasks are complete, blocking review findings resolved, required CI green, **and the owner explicitly accepts the final playtest build**, squash-merge #3, verify CI on `main`, delete the local and remote branch, prune stale references, preserving unrelated and unique unmerged work. No tag or release. Do not ask again about the method or the cleanup. **Agreeing to the workflow is not acceptance of any build** |

## M3 requirements: done

Each is in the code, tested, and described in the review package's §0, with its decision.

| Requirement | Where |
|---|---|
| The route, puzzle, cinematic contract, saves, narration plumbing and vibration, from before the revision | Package §1–§12 |
| A short skippable prologue: captivity, escape, drift, waking, each picture with restrained motion and its own sound; Skip and Continue reach the same state | D71, D88 |
| One environmental interaction in Act II: a stone pushed onto a raised slab, with a readable carving where the action is | D72, D83, D87 |
| A visible returning sea in the escape, with a bounded fallback | D73 |
| The stranded tentacle, the Shore's remains, and the carvings that echo them | D82, D84 |
| The sailor's progression: breathing, stagger, recognition, broken lines | D76, D84 |
| A script whose chronology holds, from the prologue to Innsmouth | D81, D86 |
| An initial sound pass across the route, music in five places, the mix measured and fixed where it failed | D74, D85, D91 |
| One finished reference section, and a coherent boundary into the greybox | D77, D89 |
| The monolith, the creature and the reveal as a payoff, readable at the game's scale | D84, D90 |
| A short visual epilogue, **fully voiced in voice A** | D86, D94 |
| A voice audition, a listening package, and recordings of play and of the ending with sound | D79, D92, D94 |

## Unresolved: blocking acceptance

| Blocker | Who |
|---|---|
| **The owner's playtest of the named build, and listening to the voiced ending and the mix.** Nobody has judged any of the sound by ear: the developer cannot hear, and the owner's choice of voice is not a review of the result | The owner |
| **ChatGPT's follow-up review of the latest code.** It reviewed `5fe820b` and saw frames of the game and the reference; **it has not reviewed anything since, and has never evaluated the audio** | ChatGPT |
| **The owner's explicit acceptance of a final build.** Then the merge workflow above | The owner |

**Open, not blocking unless the review says so:** two breakage survivors from the revision, unresolved interpretations for the reviewer; "Innsmouth" heard by a speech recogniser as "Insemouth", for the owner's ear; first-time duration unmeasured; physical Xbox vibration, PlayStation hardware, and the M2 J/caption event, deferred as before.

## Deferred to M4 and M5, explicitly

1. **Art, past x = 1440:** the Exposed Abyss's ground, canyon walls, rib arch and far view; the shelves and tablets; the crossing's ledges, slab and stone; the trench, gate and stones at the monolith; the lit mural's panel; the creature's own animation; the ritual and watcher beyond silhouettes; the escape's rockfall and returning sea. The same list is in the [roadmap](roadmap.md).
2. **Narration:** the rest of the script in voice A: the prologue, the escape's fragments and the other spoken lines. Captions until then.
3. **Sound:** the final mix by ear, interface sounds, a sound for examining.
4. **Engagement:** two external first-time players and their timings, for M6.

**M3 is not to be expanded further without the owner.**

## Owner feedback, and review

- **2026-11-04:** improved but not engaging enough ([record](evidence/m3/owner-playtest-2026-11-04.md)).
- **2026-11-09, on `5fe820b`:** functional, but too brief, too passive and not atmospheric enough ([record](evidence/m3/owner-playtest-2026-11-09.md)).
- **2026-11-09, on a build of `53e8d23`:** improved substantially; remaining concerns were the ending's narration, uneven visuals, limited active play, and audio without a listening review ([build identity](evidence/m3/build-identity-53e8d23.md)).
- **2026-11-10:** chose voice A from the [listening package](evidence/m3/listening/README.md).
- **ChatGPT** reviewed `5fe820b` within stated limits ([record](evidence/m3/review-chatgpt-at-5fe820b.md)). **No review since; no evaluation of any soundtrack.**
- **Not accepted.**

## Results, each with its commit

| Result | Commit | Who | Outcome |
|---|---|---|---|
| Native tests, 127 | The voiced epilogue's commit | Developer | Pass |
| Check script: import, 11 classes, 421 integration tests, three smoke runs, no leak or error lines | The same | Developer | Pass |
| Export check: 421 tests on the exported Linux pack | The same | Developer | Pass |
| Exported Linux route, four runs | The same | Developer, scripted | In the package's §0.5 |
| The six spoken lines transcribed against the script | The same | Developer, Whisper `small.en` | Word for word, but for "Innsmouth" |
| The ending recorded with its sound, and measured | The same | Developer, Movie Maker | No clipping, no clicks, no sudden changes. Not listened to |
| CI on GCC, Clang and MSVC, with the exported routes | The voiced epilogue's commit | CI | **In the pull request** |
| CI | `2182d50` | CI | Pass, both runs |
| Focused breakage of the revision, 23 entries | `b4bd9c2` | Developer, scripted | 21 caught, 2 not caught |

## Temporary resources

These may be gone. Everything finished is pushed.

| What | Where |
|---|---|
| Native clone | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Voice environment and models, for `tools/audio/make_audition.py --speak` | `$S/tts/`, `$S/voice-models/`, `$S/hf/`; speech data linked from `~/.cache/dagon-voice-short/data` |
| Private X display | `$S/xns.sh`, run with `unshare -rm` (docs/toolchain.md §6a). One at a time |
| Recordings' raw files | `$S/rec/`, `$S/rec-ending/` |

## Next concrete action

None until the owner's playtest and ChatGPT's follow-up review report back. Then fix what they find. On the owner's explicit acceptance of a final build, the merge workflow above.
