# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-04, during the resumed M3 task.

## Where things are

| | |
|---|---|
| **Milestone** | M3, complete gameplay in greybox. **Implemented. Not owner-accepted, not independently reviewed, not merged** |
| **Branch and pull request** | `m3/complete-gameplay`, draft [#3](https://github.com/shamsuzzamansadi/dagon/pull/3), based on `main` at `15ba96c` |
| **Hold** | Do not merge, tag, publish, delete the branch or start general M4 production. Stop at a reviewable result |
| **Dependency** | Independent review by ChatGPT, and the owner's decisions listed below |

## Approved scope, and exclusions

**In M3:** the continuous four-act route, clue tablets, the Wave → Kneel → Eye puzzle, the full cinematic contract with placeholder clips, the flee and ending, checkpoint restore. From the owner's update of 2026-11-04: purposeful small route choices, the talisman, ritual and watcher, worship imagery, Innsmouth epilogue, staged reveal, narration plumbing with three samples, optional controller vibration.

**Excluded by the owner:** a new act, combat, enemy AI, inventory, branching story. Slower movement, forced waiting, empty corridors, or more text as a way of adding time.

**Assigned to M4 and M5, and not to be started silently:** final environments and art, final Dagon, music, ambience, sound effects, final narration and the mix. See the [roadmap](roadmap.md).

**Not to reopen:** the release engineering work, which is complete and accepted.

## Owner feedback on the current build

Recorded in full in [evidence/m3/owner-playtest-2026-11-04.md](evidence/m3/owner-playtest-2026-11-04.md). **The build is NOT owner-accepted.** In short: improved, but not yet a sufficiently engaging game. Very linear, and can be completed in under three minutes. Examine captions and props have not added enough meaningful activity. Cave and later art visibly unfinished. Music and sound insufficient. **The narration sounds noticeably synthetic and is not an approved final voice.** The reveal, escape and ending need a stronger payoff.

ChatGPT inspected sampled video frames, but did not listen to the audio.

## Done

Everything in the approved scope above has been built. The review package is [reviews/m3-review-package.md](reviews/m3-review-package.md) once written.

## Results, each with its commit

| Result | Commit | Who | Outcome |
|---|---|---|---|
| CI run `41806608806`: GCC, Clang, MSVC, exported pack, exported route on Linux and Windows, release tools | `35ff084` | CI | Green. Release job skipped, as it should be |
| Focused deliberate breakage, 58 entries | `35ff084` | Developer, scripted | 54 caught, 4 not. See "Findings" |
| Full deliberate breakage, 84 entries | `2cae7bb` | Developer, scripted | Recorded in `evidence/m3/breakage-first-pass-at-2cae7bb.txt` |
| Owner's playtest | A build before this update's final commit | The owner | Not accepted. See above |

## Findings from the interrupted pass

- **"The voice goes on into the credits":** a real test gap. A test was added.
- **"A background event replays on every crossing":** a real test gap. The test crossed back while the clip was still playing, which hid it.
- **"The gate changes in a physics callback" and "Restoring leaves the atmosphere clip running":** expected to change nothing observable. To be stated plainly in the package.

## Remaining work

1. Close the two test gaps above.
2. Assess engagement against the approved scope, make the small changes that fit it, and propose the rest.
3. Candidate commit, CI, focused breakage for what changed, fresh clone, evidence, pacing from CI.
4. Fill in the review package, update pull request #3, pull into the owner's working copy, and hand off.

## Owner decisions pending

- **Voice direction.** The three samples are not approved. Do not generate more with this voice.
- **Whether to add anything beyond the approved scope for engagement.** The proposal goes in the review package.
- **The schedule.** The owner's target of completion before 20 November conflicts with the roadmap's dates. The roadmap has a proposed plan, which needs M3 closed by about 6 November.
- **Physical checks:** Xbox vibration, and everything already deferred to M6. The M2 J/caption event is still unresolved, with no cause established.

## Temporary resources

These may be gone. Nothing in them is the only copy of finished work unless stated.

| What | Where |
|---|---|
| Native clone for builds and CI work | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Breakage tool and results | `$S/mut/breakage.py`, `$S/mut/summary.txt`, `$S/mut/out-*.txt` |
| Package template, with tokens to fill | `$S/m3-package-template.md` |
| Fresh-clone script, Xvfb start script | `$S/fresh.sh`, `$S/xvfb-start.sh` |
| Private X display, for local graphical runs | `:77`. Never use WSLg's `:0` |
| Background task outputs | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/tasks/` |

## Next concrete action

Close the two test gaps, then the engagement assessment.
