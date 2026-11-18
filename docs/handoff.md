# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.** M4's step-by-step record is in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-18. **M5 is implemented and handed off for independent review and the owner's playtest.** Not accepted, not merged, nothing tagged or released. **Waiting on:** ChatGPT's review, the owner's listening and playtest. M6 is not started.

## Where things are

| | |
|---|---|
| **Milestone** | **M5, Cinematic horror and polish:** scope approved by the owner on 2026-11-16 ([plan](m5-plan.md)); all six items implemented ([package](reviews/m5-review-package.md) §1). M4 was accepted on 2026-11-15 at `8b30b33` ([record](evidence/m4/owner-acceptance-2026-11-15.md)) |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6), from `main` at `09d854e`. **Not for merging** until the owner accepts and says so |
| **The candidate** | **`5aab2a4`**, push run [43904143559](https://github.com/shamsuzzamansadi/dagon/actions/runs/43904143559), `dagon-windows`, artifact [14246287757](https://github.com/shamsuzzamansadi/dagon/actions/runs/43904143559/artifacts/14246287757), zip SHA-256 **`2f052d978b9deef480bd25e90e00895d349df0ec18236d85891664ca7b9c0418`**. Linux: `dagon-linux`, `478f021a84572e977c2d24efc2df71ab4409b3db20ab2cdb9e233283aff5bc29`. Both zips downloaded and hashed; they match GitHub's digests |
| **Acceptance fingerprint** | `sha256:76ac6c4e42ad47297ffc71d8610fb5aaa56b59cb84cf6beb787b7d51b144af61`, the same from `b1cb401`, where the game last changed, to the final head. M4's, on `main`: `sha256:614f29b6…7f6e` |
| **Releases** | Only [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), untouched. `main`'s CI after #5 ([43835351375](https://github.com/shamsuzzamansadi/dagon/actions/runs/43835351375)) found it already published and published nothing. **No release record is added in M5;** `v0.2.0-alpha.1` needs the owner's word and acceptance |
| **Merged since M4** | #5, the record of the first publication: `09d854e`, 2026-11-16, its branch deleted |

## M5, item by item

| # | Item | State | Commit |
|---|---|---|---|
| 1 | The reveal's composition: the seam gone, the creature apart from its background | Done ([record](evidence/m5/reveal/README.md), D105, D106) | `420ac08` |
| 2 | The creature's animation, inside the same 14 s | Done (D107, D108). No line, sound time, camera key or C++ changed | `420ac08` |
| 3 | The ending's four pictures | Done ([record](evidence/m5/ending/README.md), D110) | `4e48a97` |
| 4 | The far figures (roadmap art list, item 7) | Done ([record](evidence/m5/figures/README.md), D111) | `5504431` |
| 5 | Audio review and listening package | Measured; one local change, the water lowered under the reveal's first line ([review](evidence/m5/audio/README.md), D112); [listening package](evidence/m5/listening/README.md) with timestamps. **Nobody has listened** | `b1cb401`, `5aab2a4` |
| 6 | Validation, review package, candidate | Done ([package](reviews/m5-review-package.md)) | `d9d3ab6`, final head |

**Results on `5aab2a4`,** local, native Linux clone, clean tree (logs in `~/work/dagon-m4/notes/int-5aab2a4`): debug and release builds; `run_godot_checks.sh` all ok, integration **446/0**; `export_check.sh linux` ok; the exported route **`runs=4 failed=0`**. **CI**, push run 43904143559: integration 446/0 from source and on the exported pack on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the exported route 4/0 on Linux and Windows; native 127/127. **Breakage** (`tools/breakage_m5.py`, at `d9d3ab6`): 12 of 12 caught, controls held. The final head's CI and the packaging rehearsal are linked in the pull request's description.

**What the owner asked to be preserved is held by tests:** the gate's movement, the reveal's sequencing, narration completion, pause, save and Continue, every cinematic completion path, and no clip moving hidden art ([package](reviews/m5-review-package.md) §6).

## Open

**For the owner:** listening (the [package](evidence/m5/listening/README.md)'s eight places; the reveal's level and the mix have waited on this since M4); the playtest of the candidate; vibration by feel; acceptance or changes. The questions are in the [package](reviews/m5-review-package.md) §9.

**Known, recorded** (package §7): "Its head turned. I ran." under the second call, measured and left; the creature's two-pixel blocks at full zoom; frame time not measured; amber in the ending's pictures beyond the lantern.

**For M6, unmeasured:** two external first-time players and their timings, so **first-time duration is unknown;** all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering. **Carried:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## Owner feedback, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` ([reports](evidence/m4/owner-playtest-2026-11-15.md), [acceptance](evidence/m4/owner-acceptance-2026-11-15.md)). The reveal's seam, the creature against its background and five issues in the ending's pictures were carried to M5.
- **2026-11-16:** approved M5's scope and refinements. No feedback on M5's build yet.

## Working resources

Outside the repository and outside `/tmp`. Everything finished is pushed.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`, on `m5/polish`. The folder's name is M4's; check its branch |
| M4's helpers and logs, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `focus.sh <text>`, `record.sh`, `integration_point.sh <name>`; `notes/` (integration logs, including `int-5aab2a4`) |
| M5's working files, `~/work/dagon-m5` | `bin/`: `cap5.sh <dir> [reveal\|ending]` (frames of the reveal as it plays, and the ending), `record5.sh <script> <dir> [project]`, `evidence_art.py`. `notes/`: captures (`cap-before`, `cap-final`, ...), the full recordings (`rec-5504431`, `rec-b1cb401`), the finale's takes (`fin-*`: mix, voice, bed, before), measurements, the breakage log, the CI log. `base/`: a worktree of the clone at `09d854e`, for "before" recordings; remove it with `git worktree remove`. `candidate-5aab2a4/`: the candidate's two zips |
| Breakage workers | `~/.cache/dagon-m4/breakage/w0..w2`, clones at `d9d3ab6` |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv` (scons, Pillow, NumPy, SciPy, soundfile, ffmpeg), `tts` (the voice and Whisper), the private X server. As M4's handoff lists |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m5/polish` |

## Next concrete action

**Nothing, until the review and the owner answer.** Then: act on ChatGPT's findings and the owner's notes within M5's scope, on `m5/polish`, with a new identified candidate if anything shipped changes. **A merge, a tag, a release or M6 needs the owner's explicit word.**
