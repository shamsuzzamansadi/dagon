# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.**

**Last updated:** 2026-11-04, at the M3 review handoff.

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

## Owner feedback, on the latest build they played

Recorded in full in [evidence/m3/owner-playtest-2026-11-04.md](evidence/m3/owner-playtest-2026-11-04.md). **M3 is NOT owner-accepted.** That build came before `2ce855a`. In short: improved, but not yet a sufficiently engaging game. Very linear, and can be completed in under three minutes. Examine captions and props have not added enough meaningful activity. Cave and later art visibly unfinished. Music and sound insufficient. **The narration sounds noticeably synthetic and is not an approved final voice.** The reveal, escape and ending need a stronger payoff.

ChatGPT inspected sampled video frames, but did not listen to the audio.

## Done

Everything in the approved scope above has been built. After the owner's playtest, three small in-scope changes were added at `2ce855a` ([D67–D69](decisions.md)): clues placed so that routes matter, rock across the escape, the sea coming back over the ending. **No person has played them.** They do not answer the feedback in full. The review package is [reviews/m3-review-package.md](reviews/m3-review-package.md), and pull request #3 names the final commit and its CI run.

## Results, each with its commit

**The tested code and the build to play are `2ce855a`,** fingerprint `sha256:8645ded9104896405f1df83694c40cf22321ba63b1287f925a2118adf9f18c2e`. Later commits add only documents and evidence.

**The exact Windows build for the owner's playtest:** [`dagon-windows`, artifact 13316306928](https://github.com/shamsuzzamansadi/dagon/actions/runs/41818800097/artifacts/13316306928), from run `41818800097`, zip SHA-256 `d293bf4758f20fad1c39eb0765a67eec252ef77634968be4c07c24b32df1b566`.

| Result | Commit | Who | Outcome |
|---|---|---|---|
| CI run `41818800097`: GCC, Clang, MSVC, exported pack, exported route on Linux and Windows, release tools | `2ce855a` | CI | **Green.** 120 native cases, 385 integration tests. Release job skipped, as it should be. Logs and builds expire 2027-02-02 |
| CI runs `41828833074` (push) and `41828841443` (pull request): the same checks | `506a8f8`, documents and evidence only | CI | **Green.** Same counts. Pull request #3 names the CI of any later documents-only commit |
| Fresh clone by the README, with 10 repeats of the suite and the exported route | `2ce855a` | Developer, scripted, software rendering | All pass. No tracked files changed. `evidence/m3/fresh-clone.txt` |
| Focused deliberate breakage, 19 entries | `2ce855a` | Developer, scripted | 17 caught, 2 not. `evidence/m3/breakage.txt` |
| Focused deliberate breakage, 58 entries. The pass the limit interrupted the reading of | `35ff084` | Developer, scripted | 54 caught, 4 not. `evidence/m3/breakage-focused-at-35ff084.txt` |
| Full deliberate breakage, 84 entries | `2cae7bb` | Developer, scripted | `evidence/m3/breakage-first-pass-at-2cae7bb.txt` |
| Exported route, scripted, knowing the puzzle | `2ce855a` | CI | About 2 min direct, about 4 min reading the ground route. **Not a playtest** |
| Owner's playtest | A build before `2ce855a`, exact build not recorded | The owner | **Not accepted.** Under three minutes, by the owner's report |
| First-time player | | **Nobody** | **Unknown** |
| Independent review | | **Not yet done** | |
| Xbox vibration by feel, PlayStation hardware, the M2 J/caption event | | **Not done** | Deferred or unresolved. Do not infer a pass |

## Findings from the breakage passes

- **Real gaps, closed at `75fe57e`:** "The voice goes on into the credits", which had no test, and "A background event replays on every crossing", whose test crossed back while the clip was still playing.
- **Still not caught, read as changing nothing observable. A reading, not a proof:** "The gate changes in a physics callback" and "Restoring leaves the atmosphere clip running".

## Known problems

- **Engagement:** see the owner's feedback, and the package §12. One real thing to work out in the whole game. A proposal is written. Not started, and it needs a decision.
- **Art and sound:** nothing past the Shore is production art, and only three voice samples sound. M4 and M5.
- **GitHub refused this machine's SSH key for a while** on 2026-11-04 (`Permission denied (publickey)`), then accepted it again later the same day. The cause is not established, so it may recur. If it does, pushing to the HTTPS URL with the logged-in `gh` as credential helper works, but `gh`'s token has no `workflow` scope, so a commit that changes `.github/workflows` needs SSH or the owner.

## Remaining work

**Independent work is complete until the decisions below.** Nothing else is authorized to start. After the review and the owner's answers: any review fixes, which void the fingerprint, then the owner's acceptance of an identified build, then the normal squash merge and the release record in its own pull request.

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
| Breakage tool and working clones. A copy of the tool and the results are committed under `evidence/m3/` | `$S/mut/` |
| Package template and the script that fills it. The package itself is committed, so edit that instead | `$S/m3-package-template.md`, `$S/gen/fill_package.py` |
| Fresh-clone script, Xvfb start script | `$S/fresh.sh`, `$S/xvfb-start.sh` |
| Private X display, for local graphical runs | `:77`. Never use WSLg's `:0` |
| Background task outputs | `/tmp/claude-1000/-mnt-c-Users-sadi-projects-dagon/621ac8dc-276d-4bbd-8143-03866a5a9d1a/tasks/` |

## Next concrete action

**Wait for independent review by ChatGPT and the owner's answers to the package §12:** engagement, voice, date, and whether M3 can be accepted with the proposal as follow-up work. Do not merge, tag, publish, delete the branch or start M4 meanwhile.
