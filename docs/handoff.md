# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.** M4's step-by-step record is in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-19. **M5 is implemented, independently reviewed, and played by the owner twice on 2026-11-19; the review's three findings, the owner's five points and the owner's four visual points are addressed. It waits for the owner's playtest of the new candidate and acceptance.** Not accepted, not merged, nothing tagged or released. M6 is not started.

## Where things are

| | |
|---|---|
| **Milestone** | **M5, Cinematic horror and polish:** scope approved by the owner on 2026-11-16 ([plan](m5-plan.md)); all six items implemented ([package](reviews/m5-review-package.md) §1). M4 was accepted on 2026-11-15 at `8b30b33` ([record](evidence/m4/owner-acceptance-2026-11-15.md)) |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6), from `main` at `09d854e`. **Not for merging** until the owner accepts and says so |
| **Independent review** | ChatGPT, 2026-11-18, of `cd28f55`: three findings, addressed ([package](reviews/m5-review-package.md) §13). It did not rerun the Godot tests or exported routes, or listen |
| **The owner's playtests** | 2026-11-19, of `20929cf` (artifact 14478607459): five points, addressed ([record](evidence/m5/owner-playtest-2026-11-19.md), package §14). The same day, of `59562c6` (artifact 14526884514): "the build is better"; four visual points, addressed ([record](evidence/m5/owner-playtest-2026-11-19-59562c6.md), [clips](evidence/m5/visual-pass-2026-11-19/README.md), package §15). **Neither is acceptance** |
| **The candidate** | **`ea86ae9`**, push run [44575980858](https://github.com/shamsuzzamansadi/dagon/actions/runs/44575980858), `dagon-windows`, artifact [14556713598](https://github.com/shamsuzzamansadi/dagon/actions/runs/44575980858/artifacts/14556713598), zip SHA-256 **`1a8dc2735587cf129c32c049929fba9a18471bc24726da46068506ee43b1e67e`**. Linux: `dagon-linux`, `ab9bd6a799df0653a9b289804543b06640be1db7eb4d037321b148665bf79155`. Both zips downloaded and hashed; they match GitHub's digests. **It replaces `59562c6`** |
| **Acceptance fingerprint** | `sha256:a4f4d974921b965119fdc04524f23d7bf088e220fc633ab1aec31cbf5ac13304`, the same from `a495d42`, where the game last changed, to the final head. `59562c6`'s: `sha256:cb51c11a…78e6`; `20929cf`'s: `sha256:17cc0b91…c1bc`. M4's, on `main`: `sha256:614f29b6…7f6e` |
| **Releases** | Only [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), untouched. **No release record is added in M5;** `v0.2.0-alpha.1` needs the owner's word and acceptance |

## Since the owner's playtest of `59562c6`

| # | The owner's point | Done | Commit |
|---|---|---|---|
| 1 | The captivity: the gun's base to meet the deck; the guard to have a head, shoulders and planted feet | A pedestal through the rail to the deck; the guard at an opening in the rail; a ship's bow, anchor, waterline band and funnel (D117) | `758007d` |
| 2 | The escape's hull read as a wall or a cliff | The same raider from astern, with the funnel's band, rail, davits, rudder, white at its waterline and its reflection (D117) | `758007d` |
| 3 | The ritual's figures: heads, bowed torsos, kneeling; the watcher told apart | Four hooded kneeling figures bowed toward the marked stone; a watcher with a pale face and a crooked staff; a strip of the backdrop's ground hides what the bow takes below the crest (D118) | `a495d42` |
| 4 | The ridge, his shoulder, embedded in water, its contour followed into the rising shoulder | Its edge is the body's own up its left and over its top, and it goes below the walkway; water past the walkway at its foot (D116) | `a495d42` |

**Results.** **CI** on the candidate, push run 44575980858: integration 452/0 from source and on the exported pack on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the exported route 4/0 on Linux and Windows; native 127/127; the art check. **Local,** native clone, clean tree at `ea86ae9` (logs in `~/work/dagon-m4/notes/int-ea86ae9`): the full gate: debug and release builds, integration 452/0, three smoke runs, the Linux export check (452/0 on the pack), and the exported route `runs=4 failed=0` on its second and third attempts, with stills and silent video of the exported game ([record](evidence/m5/visual-pass-2026-11-19/exported/README.md)). **Its first attempt failed** in its first run: on the climb to the stone a hop was not taken after a landing, and nothing there changed. The final head's CI is linked in the pull request's description.

## Open

**For the owner:** the playtest of the candidate, above all the visual pass in play; listening (the [package](evidence/m5/listening/README.md)'s places; "Its head turned. I ran." under the second call stays flagged); vibration by feel; acceptance or changes. The questions are in the [package](reviews/m5-review-package.md) §9.

**Known, recorded** (package §7): the band figures are a diagnostic, and the 0.4 dB a constant-gain estimate; no measure of intelligibility was made; the creature's two-pixel blocks at full zoom; for the second the body fades in, the ridge's right side shows inside it; the escape's raider is seen from astern, its gun out of frame; frame time not measured; amber in the ending's pictures beyond the lantern; the full-game recording predates the changes of 2026-11-18 and 11-19.

**For M6, unmeasured:** two external first-time players and their timings, so **first-time duration is unknown;** all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering. **Carried:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## Owner feedback, and review, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` ([reports](evidence/m4/owner-playtest-2026-11-15.md), [acceptance](evidence/m4/owner-acceptance-2026-11-15.md)).
- **2026-11-16:** approved M5's scope and refinements.
- **2026-11-18:** ChatGPT's independent review of `cd28f55`; addressed in `10bf2b3` and `20929cf`.
- **2026-11-19:** the owner played `20929cf` ([record](evidence/m5/owner-playtest-2026-11-19.md)); five points, addressed in `59562c6`. Then played `59562c6` ([record](evidence/m5/owner-playtest-2026-11-19-59562c6.md)); four visual points, addressed in `ea86ae9`. Final acceptance pending.

## Working resources

Outside the repository and outside `/tmp`. Everything finished is pushed.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`, on `m5/polish`. The folder's name is M4's; check its branch |
| M4's helpers and logs, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `integration_point.sh <name>`, and `integration_point_v.sh`, the same with `exported_burst.sh` taking short silent video of the exported game; `focus.sh <name>`; `notes/` (integration logs) |
| M5's working files, `~/work/dagon-m5` | `bin/`: `cap5.sh`, `record5.sh`, `capv.sh <absolute dir> [prologue\|ritual\|approach] [project]` (stills), `recv.sh <script> <absolute dir> <name> [project] [scene]` (Movie Maker at 1440 × 810). `notes/owner-1119b/`: the visual pass's work: the owner's recording, its frames, stills of both builds (`before/`, `after/`), recordings (`rec/`), art trials (`art/`). `base/`: a worktree at `59562c6`, the build the owner played, for "before" stills and recordings, its `godot-cpp` a link to the clone's, with the untracked evidence scripts; remove it with `git worktree remove --force`. `candidate-ea86ae9/`: the candidate's two zips |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv`, `tts`, the private X server |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m5/polish` |

## Next concrete action

**Nothing, until the owner plays the candidate and answers.** Then: act on the owner's notes within M5's scope, on `m5/polish`, with a new identified candidate if anything shipped changes. **A merge, a tag, a release or M6 needs the owner's explicit word.**
