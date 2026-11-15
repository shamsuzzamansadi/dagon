# Owner acceptance of M4 and of the first pre-alpha release, 2026-11-15

**Stated by the owner, in their message on 2026-11-15:**

> I explicitly accept the Windows candidate from commit 8b30b33 for M4 completion and the first pre-alpha release.
>
> Accepted artifact:
> - dagon-windows, artifact 14172420108
> - ZIP SHA-256: 6f914484562a24c7285836b0aa78d1573319c9586bebece830dd2a88d1fe306d
>
> This acceptance includes the documented M5 deferrals. Preserve the exact limits of my playtest and ChatGPT's review; do not claim additional manual or auditory checks.

**Earlier the same day, the owner had authorized the release itself,** conditional on this acceptance: "after the current M4 fixes and final validation, merge M4 into main and publish our first pre-alpha release. This supersedes my earlier 'no tag or release' hold for this release." and "Once I accept that build, you are authorized to complete the merge and release workflow without asking again for permission to merge, tag, publish, or clean up the completed branch."

**What this establishes:** the owner accepts M4 as complete, and accepts the build below for release as `v0.1.0-pre-alpha.1`, with the deferrals to M5 that the [roadmap](../../roadmap.md) lists. It is both a milestone acceptance and a release acceptance, because the owner said both.

## Which build

| | |
|---|---|
| **Commit** | `8b30b33`, named by the owner |
| **The accepted artifact, named by the owner** | `dagon-windows`, [artifact 14172420108](https://github.com/shamsuzzamansadi/dagon/actions/runs/43738445550/artifacts/14172420108) of CI push run [43738445550](https://github.com/shamsuzzamansadi/dagon/actions/runs/43738445550), zip SHA-256 `6f914484562a24c7285836b0aa78d1573319c9586bebece830dd2a88d1fe306d` |
| **Its CI** | Run 43738445550: GCC, Clang, MSVC and the release tools all passed |
| **Acceptance fingerprint** | `sha256:614f29b68865e037d9d0be817c537e7452b608626f50efc584760a2d508a7f6e` (`python tools/release_gate.py fingerprint --commit 8b30b33`). The later commits on the branch are documents and this release's record only, and leave it unchanged, as does the squash merge |

**The published packages are not the bytes the owner ran.** They are built by `main`'s CI from the merged commit, whose fingerprint is the same ([release.md](../../release.md), "What an owner's acceptance covers").

## What the owner tested, in the owner's words, and no more

All in the [playtest record](owner-playtest-2026-11-15.md), three reports on 2026-11-15:

| The owner said | On which build |
|---|---|
| The overall gameplay feels good and has improved substantially; the sailor is hard to distinguish in the prologue's boat | Not stated |
| Personally tested the improved sailor readability and the prologue-to-Shore audio transition: both improvements are present. The stone gate no longer visibly rose | The candidate then named, `ced2499`'s |
| Personally tested the closed gate and the restored gate-opening behaviour: both satisfactory | Not stated; the candidate then named was `8b30b33`'s |
| The owner's second gameplay video shows the prologue's Skip reaching the Shore and gameplay continuing | Not stated |

**The owner did not say that the sailor's readability and the transition were tested again on `8b30b33`.** That commit changes the gate's and the trench water's animation tracks and their tests, and nothing in the prologue or the transition.

## ChatGPT's part, and its limits

- **Inspected sampled frames** of the owner's recordings, and **analysed the audio signal** of the first. **It did not listen to any soundtrack, approve the mix, or verify every spoken word.**
- Found the cause of the gate not rising, from the owner's recording and the source.
- Confirmed **from frames** that the prologue's Skip reaches the Shore and play continues. **Nothing about the sound at the Skip is recorded as passed.**

## What this does not establish

- **Any manual or listening check beyond the table above.** The developer's checks are scripted or measured, and say so where they are recorded.
- **That the mix, the newer sounds or the narration have been judged by ear.** The [listening package](listening/README.md) is still waiting for the owner's notes.
- **Approval of the game as finished,** of its art as final, or of anything labelled stable. The release is a pre-alpha prerelease.
- **Anything on hardware not named,** or with first-time players.

## Deferred, and not passed

- **To M5,** in the [roadmap](../../roadmap.md): the reveal's background seam; the creature's separation from its background; the creature's final art and animation and the reveal, collapse and ending clips; the ritual and the watcher beyond silhouettes; the five issues in the ending's four pictures; the mix by ear.
- **Hardware:** all physical PlayStation hardware; individual physical Xbox actions, including disconnecting and reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering.
- **Playtesting, for M6:** two external first-time players, their timings, and first-time duration, all unmeasured.
- **Carried over:** the unresolved M2 J/caption event.
