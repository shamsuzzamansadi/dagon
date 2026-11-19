# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.** M4's step-by-step record is in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-19. **M5 is implemented, independently reviewed, and played by the owner on 2026-11-19; the review's three findings and the owner's five points are addressed. It waits for the owner's playtest of the new candidate and acceptance.** Not accepted, not merged, nothing tagged or released. M6 is not started.

## Where things are

| | |
|---|---|
| **Milestone** | **M5, Cinematic horror and polish:** scope approved by the owner on 2026-11-16 ([plan](m5-plan.md)); all six items implemented ([package](reviews/m5-review-package.md) §1). M4 was accepted on 2026-11-15 at `8b30b33` ([record](evidence/m4/owner-acceptance-2026-11-15.md)) |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6), from `main` at `09d854e`. **Not for merging** until the owner accepts and says so |
| **Independent review** | ChatGPT, 2026-11-18, of `cd28f55`: three findings, addressed ([package](reviews/m5-review-package.md) §13). It did not rerun the Godot tests or exported routes, or listen |
| **The owner's playtest** | 2026-11-19, of `20929cf` (artifact 14478607459), on Windows: five points, addressed ([record](evidence/m5/owner-playtest-2026-11-19.md), [clips](evidence/m5/playtest-2026-11-19/README.md), package §14). **Not acceptance** |
| **The candidate** | **`59562c6`**, push run [44519096516](https://github.com/shamsuzzamansadi/dagon/actions/runs/44519096516), `dagon-windows`, artifact [14526884514](https://github.com/shamsuzzamansadi/dagon/actions/runs/44519096516/artifacts/14526884514), zip SHA-256 **`f8cf8ecf0cdd7cacce1358725fed382d13ba8427b35d6b6caf18d54da948e8c4`**. Linux: `dagon-linux`, `9d4f2bb276e54b9acaabce37b93f64f744ba06e47ea0a7ff16ab8eb59e3377f4`. Both zips downloaded and hashed; they match GitHub's digests. **It replaces `20929cf`** |
| **Acceptance fingerprint** | `sha256:cb51c11a6e49f4d3323b7eb5d4efbe32d8179e6c34a74b5c9ae27b96ff4778e6`, the same from `55f3d25`, where the game last changed, to the final head. `20929cf`'s: `sha256:17cc0b91…c1bc`. M4's, on `main`: `sha256:614f29b6…7f6e` |
| **Releases** | Only [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), untouched. **No release record is added in M5;** `v0.2.0-alpha.1` needs the owner's word and acceptance |

## Since the owner's playtest of 2026-11-19

| # | The owner's point | Done | Commit |
|---|---|---|---|
| 1 | The raider's gun pointed into the moon | Trained left on the captured ship, clear of the moon (D115) | `c415efa` |
| 2 | [E] Examine at the mural while `monolith.first` was said; a press cut it at 3.8 s | The prompt says **Skip line** while a press would only skip, with the key's or button's label (D113); three focused tests; a controller test's expectation brought up to date | `bde9cae`, `59562c6` |
| 3 | The camera left the head as "Its head turned. I ran." came up | A larger turn, and the wide view held to 12.8 s within the same 14 s (D114); a test | `55f3d25` |
| 4 | The last picture's reflection and crest | The road under the moon; the crest on the head (D115) | `c415efa` |
| 5 | The audio bound's wording | A constant-gain estimate; the limiter caveat, the flagged second call and the master level kept | `ede8c71` |

**Results.** **CI** on the candidate, push run 44519096516: integration 451/0 from source and on the exported pack on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the exported route 4/0 on Linux and Windows; native 127/127. **Local,** native clone, clean tree at `59562c6` (logs in `~/work/dagon-m4/notes/int-59562c6`): the full gate passed: debug and release builds, integration 451/0, three smoke runs, the Linux export check (451/0 on the pack), and the exported route `runs=4 failed=0`, its reading run showing [E] Skip line at the mural during `monolith.first`. **CI on `ede8c71` failed** on one controller test whose expectation predated D113; corrected in `59562c6`. The final head's CI is linked in the pull request's description.

## Open

**For the owner:** the playtest of the candidate; listening (the [package](evidence/m5/listening/README.md)'s places; "Its head turned. I ran." under the second call stays flagged); vibration by feel; acceptance or changes. The questions are in the [package](reviews/m5-review-package.md) §9.

**Known, recorded** (package §7): the band figures are a diagnostic, and the 0.4 dB a constant-gain estimate; no measure of intelligibility was made; the creature's two-pixel blocks at full zoom; frame time not measured; amber in the ending's pictures beyond the lantern; the full-game recording predates the changes of 2026-11-18 and 11-19; its sound differs from the candidate's only from 12.0 to 13.9 s of the reveal, by 35 dB or more below the mix.

**For M6, unmeasured:** two external first-time players and their timings, so **first-time duration is unknown;** all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering. **Carried:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## Owner feedback, and review, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` ([reports](evidence/m4/owner-playtest-2026-11-15.md), [acceptance](evidence/m4/owner-acceptance-2026-11-15.md)).
- **2026-11-16:** approved M5's scope and refinements.
- **2026-11-18:** ChatGPT's independent review of `cd28f55`; addressed in `10bf2b3` and `20929cf`.
- **2026-11-19:** the owner played `20929cf` ([record](evidence/m5/owner-playtest-2026-11-19.md)); five points, addressed. Final acceptance pending.

## Working resources

Outside the repository and outside `/tmp`. Everything finished is pushed.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`, on `m5/polish`. The folder's name is M4's; check its branch |
| M4's helpers and logs, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `integration_point.sh <name>`; `notes/` (integration logs) |
| M5's working files, `~/work/dagon-m5` | `bin/`: `cap5.sh <absolute dir> [reveal\|ending]`, `record5.sh <script> <absolute dir> [project]` (a relative directory writes no video). `notes/owner-1119/`: the playtest's work: recordings of both builds (`rec/`), captures, focused test logs. `base/`: a worktree at `20929cf`, the build the owner played, for "before" recordings, with an untracked `record_mural.gd`; remove it with `git worktree remove --force`. `candidate-59562c6/`: the candidate's two zips |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv`, `tts`, the private X server |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m5/polish` |

## Next concrete action

**Nothing, until the owner plays the candidate and answers.** Then: act on the owner's notes within M5's scope, on `m5/polish`, with a new identified candidate if anything shipped changes. **A merge, a tag, a release or M6 needs the owner's explicit word.**
