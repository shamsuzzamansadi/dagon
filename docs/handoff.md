# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-09, at the end of the owner's focused completion pass of M3.

## Where things are

| | |
|---|---|
| **Milestone** | M3, expanded by the owner on 2026-11-09 ([D70](decisions.md)), refined ([D82–D86](decisions.md)), and given a focused completion pass ([D87–D93](decisions.md)). **Implemented, apart from the voice. Not owner-accepted. Independent follow-up review not yet done. Not merged** |
| **Branch and pull request** | `m3/complete-gameplay`, draft [#3](https://github.com/shamsuzzamansadi/dagon/pull/3), based on `main` at `15ba96c` |
| **The build to play, and its CI** | Named in the pull request: the push run's `dagon-windows` artifact, with its zip SHA-256 ([D93](decisions.md)). Not recorded here, so that no commit is made only to record the last one's CI |
| **Hold** | Do not tag, publish, delete the branch, mark a release accepted, or start general M4 production. **Stopped at independent review and owner acceptance** |
| **Merge, when the gates are met** | Authorized by the owner on 2026-11-09: once the agreed M3 tasks are complete, blocking review findings resolved, required CI green, **and the owner explicitly accepts the final playtest build**, squash-merge #3, verify CI on `main`, delete the local and remote branch, prune. No tag or release. **Agreeing to the workflow is not acceptance of any build** |
| **Dependency** | The owner's choice of voice; ChatGPT's follow-up review; the owner's playtest and listening |

## Approved scope, and exclusions

**In M3:** a short skippable prologue, one environmental interaction in Act II, a visible returning sea, a stranded tentacle echoed in the carvings, the sailor's reactions, a script review, an initial sound pass with selective music, one finished reference section, a replacement voice audition; the ten refinements; and the completion pass: the ending's narration once a voice is chosen, the opening verified and given motion and sound, active play at the crossing, the boundary at x = 1440 and the reveal's readability, a listening package and a recording of play with sound.

**Excluded by the owner:** a playable ship level, a sailing simulation, a new act, combat, enemy AI, inventory, branching story, a sanity meter, inverted controls, constant distortion. Lengthening play by slower movement, empty corridors, repeated actions, forced narration or another unrelated puzzle. Generating narration in bulk with an unapproved voice. Cloning the reference's narrator or any person. Spending money. An unrestricted art rewrite.

**For M4 and M5:** the greybox art listed in the [roadmap](roadmap.md) and the package's §0.4, the creature's own animation, the final mix by ear, final narration. **M3 is not to be expanded further without the owner.**

**Not to reopen:** the release engineering work, which is complete and accepted.

## Owner feedback, and review

- **2026-11-04:** improved but not engaging enough ([record](evidence/m3/owner-playtest-2026-11-04.md)).
- **2026-11-09, on `5fe820b`:** functional, but too brief, too passive and not atmospheric enough ([record](evidence/m3/owner-playtest-2026-11-09.md)).
- **2026-11-09, on a build of `53e8d23`:** improved substantially. Remaining concerns: the ending's narration, uneven visuals, limited active play, audio without a listening review. The owner's zip was the pull-request run's; the handoff had named the push run's. Same source ([record](evidence/m3/build-identity-53e8d23.md)).
- **ChatGPT** reviewed `5fe820b` within stated limits ([record](evidence/m3/review-chatgpt-at-5fe820b.md)), and sampled frames of the reference video. **It did not evaluate any soundtrack.**
- **Who has heard what:** the developer cannot hear; the owner has played builds with sound and judged the earlier voice synthetic; no documented listening review of the sound pass or of A and B yet ([listening package](evidence/m3/listening/README.md)).
- **Not accepted. No voice approved.**

## Results, each with its commit

| Result | Commit | Who | Outcome |
|---|---|---|---|
| Local check script: import, 11 classes, the integration suite, three smoke runs, no leak or error lines | The completion pass's commit | Developer | Pass. The count is in the package's §0.5 |
| Native tests: 127 cases | The same | Developer | Pass |
| Export check on the exported Linux pack | The same | Developer | Pass |
| Exported Linux route, four runs, with the climb and the push | The same | Developer, scripted | Pass. Timings in the package's §0.2 |
| A recording of play with sound, measured | The same | Developer, Movie Maker | No clipping, no clicks, silence while paused. Not listened to |
| CI on GCC, Clang and MSVC, with the exported routes | The completion pass's commit | CI | **In the pull request** |
| CI | `53e8d23` | CI | Pass, both runs |
| Focused breakage of the revision, 23 entries | `b4bd9c2` | Developer, scripted | 21 caught, 2 not caught: unresolved interpretations for the reviewer |

## Known problems

- **The epilogue is one line voiced in four,** pending the voice.
- **First-time duration is unmeasured.** Scripted runs are not playtests.
- **Art past x = 1440 is greybox,** apart from what the package's §0.4 lists.

## Owner decisions pending

- **The voice:** A, B, a person, or neither, from the [listening package](evidence/m3/listening/README.md). Then `python tools/audio/make_audition.py --models DIR --speak <A|B> ending.found ending.listen ending.rising`, a test run, and a recording of the ending to listen to.
- **Acceptance of M3,** after the follow-up review and the owner's playtest.
- **The schedule:** completion before 20 November; 24 November is not approved. Risks in the package's §0.7.
- **Physical checks:** Xbox vibration; the M2 J/caption event is unresolved.

## Temporary resources

These may be gone. Everything finished is pushed.

| What | Where |
|---|---|
| Native clone | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Voice environment and models, for `tools/audio/make_audition.py` | `$S/tts/`, `$S/voice-models/`, `$S/hf/` |
| Private X display | `$S/xns.sh`, run with `unshare -rm` (docs/toolchain.md §6a). One at a time: two at once share the display's socket |
| The recording's raw files | `$S/rec/` |

## Next concrete action

None until the owner chooses a voice, and the follow-up review and the owner's playtest report back. Then the epilogue's three lines, and whatever the review asks.
