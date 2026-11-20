# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.** M4's step-by-step record is in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-20. **M5 is implemented, independently reviewed, and played by the owner three times on 2026-11-19; the review's three findings, the owner's five points, four visual points and three points in motion are addressed. It waits for the owner's playtest of the new candidate and explicit acceptance.** Not accepted, not merged, nothing tagged or released. M6 is not started.

## Where things are

| | |
|---|---|
| **Milestone** | **M5, Cinematic horror and polish:** scope approved by the owner on 2026-11-16 ([plan](m5-plan.md)); all six items implemented ([package](reviews/m5-review-package.md) §1). M4 was accepted on 2026-11-15 at `8b30b33` ([record](evidence/m4/owner-acceptance-2026-11-15.md)) |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6), from `main` at `09d854e`. **Not for merging** until the owner accepts and says so |
| **Independent review** | ChatGPT, 2026-11-18, of `cd28f55`: three findings, addressed ([package](reviews/m5-review-package.md) §13). It did not rerun the Godot tests or exported routes, or listen |
| **The owner's playtests** | All on 2026-11-19. `20929cf` (artifact 14478607459): five points ([record](evidence/m5/owner-playtest-2026-11-19.md), package §14). `59562c6` (artifact 14526884514): "the build is better"; four visual points ([record](evidence/m5/owner-playtest-2026-11-19-59562c6.md), §15). `ea86ae9` (artifact 14556713598): broadly satisfied with the visual fixes; three points in motion ([record](evidence/m5/owner-playtest-2026-11-19-ea86ae9.md), [clips](evidence/m5/motion-pass-2026-11-19/README.md), §16). **None is acceptance** |
| **The candidate** | **`b7303bf`**, push run [44731893136](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136), `dagon-windows`, artifact [14627487176](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136/artifacts/14627487176), zip SHA-256 **`97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`**. Linux: `dagon-linux`, `bbf8858ea174cb8346d92544d2ea5d2ab6a9b6de386e9197c800769712327505`. Both zips downloaded and hashed; they match GitHub's digests. **It replaces `ea86ae9`,** and `d8626f7`, the pass's first candidate, never given to the owner |
| **Acceptance fingerprint** | `sha256:1f724cdc2c582c997c9b7b780ff092f4763c0077b5defe9805c6cce37533dc8d`, the same from `b7303bf` to the final head. `ea86ae9`'s: `sha256:a4f4d974…3304`; `59562c6`'s: `sha256:cb51c11a…78e6`; `20929cf`'s: `sha256:17cc0b91…c1bc`. M4's, on `main`: `sha256:614f29b6…7f6e` |
| **Releases** | Only [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), untouched. **No release record is added in M5;** `v0.2.0-alpha.1` needs the owner's word and acceptance |

## Since the owner's playtest of `ea86ae9`

| # | The owner's point | Done | Commit |
|---|---|---|---|
| 1 | Dagon emerging from the water: the internal edge, the waterline, the same shape becoming the shoulder | The body, head and crest come out of the fog from the ridge outward, through the project's first shader, driven by the clip's unchanged fades; the water runs before the whole creature; the shader and a particle drawn unseen from the level's start, so the reveal does not stall on a first draw (D119) | `d8626f7`, `b7303bf` |
| 2 | The detached hand | The arm's root rounded about the shoulder and the body's own pixels laid over it; its fade-in brings it out from the shoulder to the hand (D120) | `d8626f7` |
| 3 | The advancing sea into the collapse, running and caught | The same sea comes on over him at the collapse and rises to fill the view; the screen-space sea is gone (D121) | `d8626f7` |

**Results.** **CI** on the candidate, push run 44731893136: integration 455/0 from source and on the exported pack on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the exported route 4/0 on Linux and Windows; native 127/127; the art check. **Local,** native clone, clean tree at `050ec57`, the same game as the candidate by its fingerprint (logs in `~/work/dagon-m4/notes/int-050ec57`): passed on its first attempt, debug and release builds, integration 455/0 and three smoke runs, the export check 455/0 on the pack, the exported route `runs=4 failed=0`. **CI failed on `d8626f7` and `050ec57`, on the art check alone,** which had come to import NumPy; fixed in `b7303bf` ([package](reviews/m5-review-package.md) §6). **Breakage:** **9 caught, 0 not caught, controls held** ([result](evidence/m5/breakage-motion.txt)): the body fading in whole over the ridge, the water short of the walkway's end, the shoulder never shown or set aside from the arm's root, the arm fading in whole, the shader first drawn in the reveal or its warm-up too clear to be drawn, the sea stopping at the collapse or falling short of a runner. The final head's CI is linked in the pull request's description.

## Open

**For the owner:** the playtest of the candidate, above all the motion pass in play; listening (the [package](evidence/m5/listening/README.md)'s places; "Its head turned. I ran." under the second call stays flagged); vibration by feel; acceptance or changes. The questions are in the [package](reviews/m5-review-package.md) §9.

**Known, recorded** (package §7): the band figures are a diagnostic, and the 0.4 dB a constant-gain estimate; no measure of intelligibility was made; the creature's two-pixel blocks at full zoom; the arm still comes in at 5.5 s, now from the shoulder, and the sea's rush at the collapse is fast; the escape's raider is seen from astern, its gun out of frame; frame time not measured; amber in the ending's pictures beyond the lantern; the full-game recording predates the changes of 2026-11-18 and 11-19.

**For M6, unmeasured:** two external first-time players and their timings, so **first-time duration is unknown;** all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering. **Carried:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## Owner feedback, and review, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` ([reports](evidence/m4/owner-playtest-2026-11-15.md), [acceptance](evidence/m4/owner-acceptance-2026-11-15.md)).
- **2026-11-16:** approved M5's scope and refinements.
- **2026-11-18:** ChatGPT's independent review of `cd28f55`; addressed in `10bf2b3` and `20929cf`.
- **2026-11-19:** the owner played `20929cf` ([record](evidence/m5/owner-playtest-2026-11-19.md)); five points, addressed in `59562c6`. Then `59562c6` ([record](evidence/m5/owner-playtest-2026-11-19-59562c6.md)); four visual points, addressed in `ea86ae9`. Then `ea86ae9` ([record](evidence/m5/owner-playtest-2026-11-19-ea86ae9.md)); three points in motion, addressed in `b7303bf`. Final acceptance pending.

## Working resources

Outside the repository and outside `/tmp`. Everything finished is pushed.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`, on `m5/polish`. The folder's name is M4's; check its branch. **The Windows working copy stays on `main`;** work is done in the clone and pushed |
| M4's helpers and logs, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `integration_point.sh <name>`; `integration_point_v.sh` and `integration_point_m.sh`, the same with `exported_burst.sh` or `exported_motion.sh` taking silent video of the exported game; `focus.sh <name>`; `notes/` (integration logs) |
| M5's working files, `~/work/dagon-m5` | `bin/`: `capv.sh`, `recv.sh`, and `recp.sh <script> <absolute dir> <name> [project] [scene]` (Movie Maker, lossless PNG frames and a WAV). `notes/owner-1119c/`: the motion pass: takes of both builds (`rec/`), contact sheets (`sheets/`), `clip.sh` (cuts a take into a clip with its sound), `below.py` and `parts.py` (the waterline and the arm, measured on the flat-colour take), `stills.py`, prototypes (`proto/`). `base/`: a worktree at `ea86ae9`, the build the owner played, with its `godot-cpp` a link to the clone's and the new `record_visual.gd` copied in; remove it with `git worktree remove --force`. `breakage-b7303bf/`: the breakage run's clones. `candidate-b7303bf/`: the candidate's two zips |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv`, `tts`, the private X server |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m5/polish` |

## Next concrete action

**Nothing, until the owner plays the candidate and answers.** Then: act on the owner's notes within M5's scope, on `m5/polish`, with a new identified candidate if anything shipped changes. **A merge, a tag, a release or M6 needs the owner's explicit word.**
