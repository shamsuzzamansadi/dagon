# The publication of `v0.2.0-alpha.1`, M5's alpha, from `a4250f0`

**Published on 2026-11-22 by the release workflow,** from M5's accepted merge `a4250f0`, at the owner's request of 2026-11-21 ([authorization](../m5/release-authorization-2026-11-22.md)): <https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.1>. It is the first release to ship an earlier commit on `main` ([D128](../../decisions.md)).

## How

| Step | What happened |
|---|---|
| The record | [`release/v0.2.0-alpha.1.json`](../../../release/v0.2.0-alpha.1.json), `state: publish`, with source `a4250f0` and `main`'s own push run of it, [44748633376](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376), in [#8](https://github.com/shamsuzzamansadi/dagon/pull/8) |
| Before the merge | #8's required checks passed on its head, `7b49f24`, push and pull request. Its rehearsal, run [45004382916](https://github.com/shamsuzzamansadi/dagon/actions/runs/45004382916), packaged `a4250f0`'s own exports. **The six game files in its packages were byte for byte `a4250f0`'s CI exports,** and their `LICENSE` and `CREDITS.md` were `a4250f0`'s. The gate, run by the developer against GitHub's live state: "v0.2.0-alpha.1 has passed every gate" |
| The merge | Squash merge of #8 into `main`: `6b17c79` |
| `main`'s CI, first attempt | Run [45005786156](https://github.com/shamsuzzamansadi/dagon/actions/runs/45005786156). **Windows failed:** all 455 integration tests passed, then the engine reported "2 resources still in use at exit", Ogg sounds the mixer had not yet let go. The gate therefore blocked the release, naming CI as the blocker, and **nothing was packaged or published.** The same tree's Windows jobs had passed twice in #8 |
| Second attempt | **The failed jobs were run again once.** Windows passed; the gate passed; the Linux and Windows packages were made and smoke-tested on their own systems; the notes, checksums and provenance were prepared; the release was created as a draft, its files checked against their checksums, and only then published |
| The cause, afterwards | The same report came from GitHub's Apple Silicon runner during M6's Mac work: on a busy machine the fixed 150 ms after stopping every sound (D78) was not always enough. M6 fixes it by also waiting for the mixer itself ([D130](../../decisions.md)). It is not in `a4250f0`, and it changes nothing a player sees |

## Verified afterwards, by the developer

| | |
|---|---|
| **The release** | Published, marked a prerelease, immutable, named for its tag; target `a4250f060ee7cb8051f9ffef9a976bf68f58d630` |
| **The tag** | `v0.2.0-alpha.1` → commit `a4250f060ee7cb8051f9ffef9a976bf68f58d630`, read from the remote |
| **Files** | `dagon-v0.2.0-alpha.1-linux-x86_64.tar.gz`, `dagon-v0.2.0-alpha.1-windows-x86_64.zip`, `SHA256SUMS.txt`, `PROVENANCE.txt`: downloaded into a clean folder; `sha256sum -c SHA256SUMS.txt` OK for both packages; each equal to GitHub's own digest |
| **SHA-256** | Linux `d0b0de62785bcf82047808df2dfc9d31bf6438d9688d8520e26d7f0bbbafb43a`, Windows `323898b3701fca607a97b1b512e3a39829e3a639eb40a54b153625c131c1762d` |
| **The game inside** | The six game files are byte for byte the exports of `a4250f0`'s run 44748633376; the Linux game keeps its executable bit |
| **Provenance** | Source commit `a4250f0…`; built and tested by run 44748633376; packaged, smoke-tested and published by run 45005786156 at `6b17c79`; acceptance fingerprint `sha256:1f724cdc…3dc8d`, the one the owner accepted; MSVC 19.44, GCC 11.4, Clang 18.1.3 (validation), Godot 4.7.2, godot-cpp `507ed9d` |
| **`v0.1.0-pre-alpha.1`** | Untouched: published, a prerelease, target `760a539…`, its four files |

**Not established by any of this:** anything a person checked on this build beyond the owner's own statements in the [record](../m5/release-authorization-2026-11-22.md); the release notes list what was not tested.
