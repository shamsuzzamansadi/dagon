# `v0.2.0-alpha.2`, the M6 candidate: as `main`'s CI prepared it, and the tag proposal

**A candidate, not a release.** Nothing is tagged or published for M6. Checked by the developer on 2026-11-22.

## The merge and `main`'s CI

| | |
|---|---|
| **#7's last head** | `85aedf6`: `617b297` from `m6/macos` (the README for players, the Mac build, D129, D130) and one commit of documents. Push run [45036602284](https://github.com/shamsuzzamansadi/dagon/actions/runs/45036602284) and pull-request run [45036606328](https://github.com/shamsuzzamansadi/dagon/actions/runs/45036606328): every job passed, `macos` included |
| **Before it, on `617b297`** | Push run [45012866751](https://github.com/shamsuzzamansadi/dagon/actions/runs/45012866751) and the three-platform packaging rehearsal [45012877847](https://github.com/shamsuzzamansadi/dagon/actions/runs/45012877847), every job passed ([review package](../../reviews/m6-review-package.md) §8) |
| **The squash merge** | [`b271316`](https://github.com/shamsuzzamansadi/dagon/commit/b271316371532074eb2c5fb312afa7c0a2d822c4), 2026-11-22, at the owner's authorization of 2026-11-21 ([record](owner-acceptance-2026-11-21.md)). Its tree is `85aedf6`'s exactly. `m6/stabilization` and `m6/macos` are deleted |
| **`main`'s CI on it** | Push run [45038841566](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566): every job passed; the release gate found `v0.1.0-pre-alpha.1` and `v0.2.0-alpha.1` already published, prepared `v0.2.0-alpha.2` as a candidate, and skipped publishing |

## The candidate artifact

`release-candidate-v0.2.0-alpha.2`, artifact [14761047666](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566/artifacts/14761047666) of run 45038841566, `sha256:8bbd25367ad8addec2a7c0c6626f3895578cf49f6c64ea64018bbdc2431da360`. GitHub keeps it until 2026-12-06; the run's own exports, which a release would ship (D128), until 2027-02-20.

| Package | SHA-256 |
|---|---|
| `dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz` | `6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05` |
| `dagon-v0.2.0-alpha.2-macos-arm64.zip` | `9daca1d1f76982248a8ba91029c0dca99cfc8fee3387d411063a09a933cb5586` |
| `dagon-v0.2.0-alpha.2-windows-x86_64.zip` | `f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148` |

**Checked, by the developer, on the downloaded artifact:** its hash equals GitHub's digest; `sha256sum -c SHA256SUMS.txt` passes for all three packages, and the notes' table carries the same hashes; `PROVENANCE.txt` names source commit `b271316` and run 45038841566, and the fingerprint `sha256:96c145f475ab1b890f9f4363d96e0a028c5bf3c8cb6111f8f97174561ee8135b`; the Windows and Linux packages hold exactly the game's three files, `LICENSE` and `CREDITS.md`, the Mac package `DAGON.app`, `LICENSE` and `CREDITS.md`; the notes list all seven deferred checks under "Not tested" and say that no owner acceptance covers this build. Each package was smoke-tested by that run on a GitHub-hosted runner of its system, macOS 15.8.2 on arm64 for the Mac: start, New Game to a save, quit, and Continue in a new process. **No person has launched any of them.**

## The tag proposal, for the owner's word

- **Version `v0.2.0-alpha.2`,** an alpha, as the record names it. The roadmap names no version for M6.
- **The tag on `b271316`,** M6's squash merge, and the packages `main`'s own run 45038841566 built and tested there, for Linux, Windows and macOS on Apple Silicon (D128), as in this candidate. The record would name that commit and run as its `source`, as `v0.2.0-alpha.1`'s does.
- **What publishing needs from the owner,** which the gate reports as remaining: an acceptance that covers `b271316`'s fingerprint, `sha256:96c145f4…8135b`. The owner's acceptance of 2026-11-21 covers `a30be86`'s, `sha256:14e30e9c…b4f04f`; the merge adds the README and the Mac build's files to it. Either the owner launches the candidate's packages and says what they saw, or the owner accepts that fingerprint knowingly on CI's evidence alone, with no person having played the merged build on any system, or any Mac build.
- **Also open against the roadmap's M6 exit gate:** "release candidate artifacts from CI launched on real Windows and Linux". CI launched them on hosted runners; the native runs on the owner's machines are among the deferred checks.
- **The notes keep every outstanding human check** under "Not tested", as the owner asked on 2026-11-21.

After the owner's word, a pull request of records only would set `release/v0.2.0-alpha.2.json` to `publish`, with that `source` and the owner's statement, and `main`'s CI on its merge would publish. Until then the record stays `candidate`.
