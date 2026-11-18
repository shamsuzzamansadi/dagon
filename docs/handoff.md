# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull request and CI before relying on it.** M4's step-by-step record is in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-18. **M5 is implemented, independently reviewed, and the review's three findings are addressed. It waits for the owner's playtest and acceptance.** Not accepted, not merged, nothing tagged or released. M6 is not started.

## Where things are

| | |
|---|---|
| **Milestone** | **M5, Cinematic horror and polish:** scope approved by the owner on 2026-11-16 ([plan](m5-plan.md)); all six items implemented ([package](reviews/m5-review-package.md) §1). M4 was accepted on 2026-11-15 at `8b30b33` ([record](evidence/m4/owner-acceptance-2026-11-15.md)) |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6), from `main` at `09d854e`. **Not for merging** until the owner accepts and says so |
| **Independent review** | ChatGPT, 2026-11-18, of `cd28f55`: checked the final head's CI and rehearsal conclusions, the fingerprints, the art checker, selected code and the frames. **It did not rerun the Godot tests or exported routes, or listen.** Three findings, addressed ([package](reviews/m5-review-package.md) §13) |
| **The candidate** | **`20929cf`**, push run [44412125349](https://github.com/shamsuzzamansadi/dagon/actions/runs/44412125349), `dagon-windows`, artifact [14478607459](https://github.com/shamsuzzamansadi/dagon/actions/runs/44412125349/artifacts/14478607459), zip SHA-256 **`3e5f8d657ac813633e3f8ea67ad4c0bcd4d0e81c32725d1c3ef4c9eb77e00ca8`**. Linux: `dagon-linux`, `4435d3c550ab23ee152d63077811762182685de2e933628d0d37dea3269c9272`. Both zips downloaded and hashed; they match GitHub's digests. **It replaces `5aab2a4`,** whose window picture had the detached hand |
| **Acceptance fingerprint** | `sha256:17cc0b9108ee7153b92efbbd6b21223db4cb97df4fa9b5fabd77f37e7de8c1bc`, the same from `10bf2b3`, where the game last changed, to the final head. The first candidate's: `sha256:76ac6c4e…af61`. M4's, on `main`: `sha256:614f29b6…7f6e` |
| **Releases** | Only [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), untouched. **No release record is added in M5;** `v0.2.0-alpha.1` needs the owner's word and acceptance |
| **Merged since M4** | #5, the record of the first publication: `09d854e`, 2026-11-16, its branch deleted |

## M5, item by item

| # | Item | State | Commit |
|---|---|---|---|
| 1 | The reveal's composition: the seam gone, the creature apart from its background | Done ([record](evidence/m5/reveal/README.md), D105, D106) | `420ac08` |
| 2 | The creature's animation, inside the same 14 s | Done (D107, D108). No line, sound time, camera key or C++ changed | `420ac08` |
| 3 | The ending's four pictures | Done ([record](evidence/m5/ending/README.md), D110); the window's hand joined to its sleeve after the review | `4e48a97`, `10bf2b3` |
| 4 | The far figures (roadmap art list, item 7) | Done ([record](evidence/m5/figures/README.md), D111) | `5504431` |
| 5 | Audio review and listening package | Measured; one local change, the water lowered under the reveal's first line ([review](evidence/m5/audio/README.md), D112); [listening package](evidence/m5/listening/README.md). After the review: the subtraction checked to the sample, and the figures called what they are, a diagnostic of level. **Nobody has listened** | `b1cb401`, `5aab2a4`, `20929cf` |
| 6 | Validation, review package, candidate | Done ([package](reviews/m5-review-package.md)) | `d9d3ab6`, final head |

**Results.** **CI** on the candidate, push run 44412125349: integration 447/0 from source and on the exported pack on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the exported route 4/0 on Linux and Windows; native 127/127. **After the review, local** (native clone, `10bf2b3`): `test_revision`, `test_narrative` and the ending's tests all passed; the hidden-art check's demonstration ([record](evidence/m5/hidden-art-check.txt)); `check_art` 0; the ending looked at in the game with its cards. **Before the review, local** (`5aab2a4`, logs in `~/work/dagon-m4/notes/int-5aab2a4`): the full gate, integration 446/0, export ok, route 4/0. **Breakage** (`tools/breakage_m5.py`, `d9d3ab6`): 12 of 12 caught; not run again. The final head's CI is linked in the pull request's description.

## Open

**For the owner:** the playtest of the candidate; listening (the [package](evidence/m5/listening/README.md)'s eight places; the reveal's level and the mix have waited on this since M4; "Its head turned. I ran." stays flagged); vibration by feel; acceptance or changes. The questions are in the [package](reviews/m5-review-package.md) §9.

**Known, recorded** (package §7): the band figures are a diagnostic, and no measure of intelligibility was made; the creature's two-pixel blocks at full zoom; frame time not measured; amber in the ending's pictures beyond the lantern; the full recording's epilogue shows the window as first submitted (its sound is the candidate's).

**For M6, unmeasured:** two external first-time players and their timings, so **first-time duration is unknown;** all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering. **Carried:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## Owner feedback, and review, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` ([reports](evidence/m4/owner-playtest-2026-11-15.md), [acceptance](evidence/m4/owner-acceptance-2026-11-15.md)). The reveal's seam, the creature against its background and five issues in the ending's pictures were carried to M5.
- **2026-11-16:** approved M5's scope and refinements.
- **2026-11-18:** ChatGPT's independent review of `cd28f55`: the window's detached hand, the hidden-art check's false-only tracks, the audio evidence's claims. Addressed in `10bf2b3` and `20929cf`. No feedback from the owner on M5's build yet.

## Working resources

Outside the repository and outside `/tmp`. Everything finished is pushed.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`, on `m5/polish`. The folder's name is M4's; check its branch |
| M4's helpers and logs, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `focus.sh <text>`, `record.sh`, `integration_point.sh <name>`; `notes/` (integration logs, including `int-5aab2a4`) |
| M5's working files, `~/work/dagon-m5` | `bin/`: `cap5.sh <absolute dir> [reveal\|ending]`, `record5.sh <script> <absolute dir> [project]` (a relative directory writes no video), `evidence_art.py`. `notes/`: captures, recordings and takes, measurements, the breakage log, CI logs; `notes/review1/`: the review's captures, the finale recorded again, the focused test logs, the subtraction checks. `base/`: a worktree of the clone at `09d854e`, for "before" recordings; remove it with `git worktree remove`. `candidate-20929cf/`: the candidate's two zips |
| Breakage workers | `~/.cache/dagon-m4/breakage/w0..w2`, clones at `d9d3ab6` |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv` (scons, Pillow, NumPy, SciPy, soundfile, ffmpeg), `tts` (the voice and Whisper), the private X server. As M4's handoff lists |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin m5/polish` |

## Next concrete action

**Nothing, until the owner plays and answers.** Then: act on the owner's notes within M5's scope, on `m5/polish`, with a new identified candidate if anything shipped changes. **A merge, a tag, a release or M6 needs the owner's explicit word.**
