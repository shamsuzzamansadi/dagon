# The first publication: `v0.1.0-pre-alpha.1`, 2026-11-15

**[https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1)**, published 2026-11-15 at 19:10:42 UTC by `main`'s CI, run [43748080655](https://github.com/shamsuzzamansadi/dagon/actions/runs/43748080655), from the squash merge of [#4](https://github.com/shamsuzzamansadi/dagon/pull/4), `760a539`. Asked for by the owner, and accepted by the owner on the build from `8b30b33` ([record](../m4/owner-acceptance-2026-11-15.md)), fingerprint `sha256:614f29b68865e037d9d0be817c537e7452b608626f50efc584760a2d508a7f6e`, which `760a539` has too: its tree is identical to the accepted pull request's head.

## The run

Every job of run 43748080655 succeeded: `linux`, `linux-clang`, `windows`, `release-tools`, then `release / gate`, `package-linux` and `package-windows` (each smoke-tests its own package on its own OS), `prepare` and `publish`. Before the merge, a rehearsal on the pull request's head, run [43746490349](https://github.com/shamsuzzamansadi/dagon/actions/runs/43746490349), had passed the gate, packaging, smoke tests and preparation.

**The `publish` job's own output,** in full apart from the setup:

```
https://github.com/shamsuzzamansadi/dagon/releases/tag/untagged-12de4936fa931b8661cb
https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1
verified v0.1.0-pre-alpha.1: complete, consistent and at 760a5397e801c4e2bb8a3adc88b6c45063ee3107
```

The first line is the draft, created without a tag; the uploaded files were then downloaded and checked against `SHA256SUMS.txt` (quiet when they match); the second is the release once published, which created the tag; the third is the check after publishing.

## Checked afterwards, by the developer, from outside the workflow

| | Result |
|---|---|
| **Tag** | `v0.1.0-pre-alpha.1`, a lightweight tag at `760a5397e801c4e2bb8a3adc88b6c45063ee3107`, the merged `main` commit CI tested |
| **Release** | Published, **prerelease**, not a draft, **immutable** (`isImmutable: true`), target `760a5397e801c4e2bb8a3adc88b6c45063ee3107` |
| **Assets** | Exactly four: `dagon-v0.1.0-pre-alpha.1-linux-x86_64.tar.gz` (35,182,847 bytes), `dagon-v0.1.0-pre-alpha.1-windows-x86_64.zip` (44,380,284 bytes), `SHA256SUMS.txt`, `PROVENANCE.txt`. GitHub's own digest of each matches |
| **Checksums** | Downloaded again; `sha256sum -c SHA256SUMS.txt`: both packages OK. Linux `605f110908b5855e434167084f33832d00b002442254da26573869bdb197acd2`; Windows `09e7e2e56aeaaca199789a46dfa2653841e7113055825e82270225e346b27f1a` |
| **Contents** | Each package: the game, its `.pck`, its GDExtension library, `LICENSE` and `CREDITS.md`, in one folder named for the version |
| **Provenance** | Version, source commit `760a5397e801c4e2bb8a3adc88b6c45063ee3107`, the run that built and tested it, the acceptance fingerprint above, MSVC 19.44.35230 for Windows, GCC 11.4.0 for Linux, Clang 18.1.3 for validation only, Godot 4.7.2.stable.official.ed1daf0bf, godot-cpp `507ed9d` |
| **Notes** | The summary, the known limitations including the M5 work, what is not tested, the owner's acceptance in its own limits, the downloads and the provenance, as written by `tools/release_gate.py prepare` from the record |
| **`release_gate.py verify`, run locally against the live repository** | `verified v0.1.0-pre-alpha.1: complete, consistent and at 760a539...` |
| **The gate, run locally as a later `main` push would** | `v0.1.0-pre-alpha.1 is already published ... A release is never replaced.` |
| **The downloaded Linux package, smoke-tested locally** (`package_release.py smoke`) | Starts, runs New Game with a prompt, saves, and continues |

The Windows package was smoke-tested by the `package-windows` job on `windows-2022`; it was not run again by the developer. **Nobody has played the published packages by hand.** Their bytes are not the artifact the owner ran; the same files went in ([release.md](../../release.md), "What an owner's acceptance covers").

## What this proves of what was unproven, and what it does not

- **Proven once:** the write path from the workflow (a draft created, uploaded to, checked, published, verified); **a tag created by publication while the `v*` ruleset was active,** with no bypass actors and the rules `update`, `deletion` and `non_fast_forward`, unchanged; **immutable releases on** during publication, and the release immutable afterwards; **the release's target kept as the commit after publishing,** so the consistency check holds.
- **Still unproven:** removing a failed draft on a retry (nothing failed); the ruleset refusing to move or delete the tag (not attempted: trying would be an attempt to alter a published release).
- **No protection was changed** before, during or after.
