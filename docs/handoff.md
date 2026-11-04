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

Everything in the approved scope above has been built. After the owner's playtest, three small in-scope changes were added at `2ce855a` ([D67–D69](decisions.md)): clues placed so that routes matter, rock across the escape, the sea coming back over the ending. **No person has played them.** They do not answer the feedback in full.

## Results, each with its commit

| Result | Commit | Who | Outcome |
|---|---|---|---|
| CI run `41806608806`: GCC, Clang, MSVC, exported pack, exported route on Linux and Windows, release tools | `35ff084` | CI | Green. Release job skipped, as it should be. **Superseded by the candidate below** |
| Focused deliberate breakage, 58 entries | `35ff084` | Developer, scripted | 54 caught, 4 not. See "Findings" |
| Full deliberate breakage, 84 entries | `2cae7bb` | Developer, scripted | Recorded in `evidence/m3/breakage-first-pass-at-2cae7bb.txt` |
| Local check script, 385 integration tests | `2ce855a` | Developer | Pass |
| CI run `41818800097` | `2ce855a` | CI | **Running when this was written.** Check it |
| Last focused breakage, 18 entries | `2ce855a` | Developer, scripted | **Running when this was written.** `$S/mut/summary.txt` |
| Owner's playtest | A build before `2ce855a`, exact build not recorded | The owner | Not accepted. See above |

## Findings from the interrupted pass

- **"The voice goes on into the credits":** a real test gap. A test was added at `75fe57e`.
- **"A background event replays on every crossing":** a real test gap. The test crossed back while the clip was still playing, which hid it. Fixed at `75fe57e`.
- **"The gate changes in a physics callback" and "Restoring leaves the atmosphere clip running":** expected to change nothing observable. To be stated plainly in the package.

## Known problems

- **Engagement:** see the owner's feedback, and the proposal in the package §12. Not started, and needs a decision.
- **GitHub began refusing this machine's SSH key** during the resumed session (`Permission denied (publickey)`), having accepted it minutes earlier. The cause is not established. The clone's `origin` is that SSH remote. Pushing to the HTTPS URL with the logged-in `gh` as credential helper works, but `gh`'s token has no `workflow` scope, so a commit that changes `.github/workflows` needs the SSH route or the owner.

## Remaining work

1. Read the CI and breakage results above, and act on any concrete finding.
2. Fresh clone at the candidate, evidence copied into `docs/evidence/m3/`, pacing from CI.
3. Fill in the review package from the template, update pull request #3, pull into the owner's working copy, and hand off. Then stop.

## Owner decisions pending

- **Voice direction.** The three samples are not approved. Do not generate more with this voice.
- **Whether to add anything beyond the approved scope for engagement,** and whether the 10–15 minute target stays. The proposal is in the review package §12.
- **The schedule.** The owner's target of completion before 20 November conflicts with the roadmap's dates. The roadmap has a proposed plan, which needs M3 closed by about 6 November.
- **Physical checks:** Xbox vibration, and everything already deferred to M6. The M2 J/caption event is still unresolved, with no cause established.

## Temporary resources

These may be gone. Nothing in them is the only copy of finished work unless stated.

| What | Where |
|---|---|
| Native clone for builds and CI work | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/scratchpad/work` (call its parent `$S`) |
| Breakage tool and results | `$S/mut/breakage.py`, `$S/mut/summary.txt`, `$S/mut/out-*.txt` |
| Package template, with tokens to fill. **The only copy until the package is written** | `$S/m3-package-template.md` |
| Fresh-clone script, Xvfb start script | `$S/fresh.sh`, `$S/xvfb-start.sh` |
| Private X display, for local graphical runs | `:77`. Never use WSLg's `:0` |
| Background task outputs | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/tasks/` |

## Next concrete action

Read CI run `41818800097` and the breakage summary. Then the fresh clone and the package.
