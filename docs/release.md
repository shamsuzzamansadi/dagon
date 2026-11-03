# Releases

How a milestone prerelease is built, gated and published. The rules come from the owner, 2026-11-03 ([D45, D46](decisions.md)).

**Reaching a milestone publishes nothing.** A prerelease happens when a record in `release/` asks for it, that record has been merged through the normal pull request, and every gate passes on the `main` commit CI has just tested.

## Targets

| Milestone | Version | Promise | If it is not true |
|---|---|---|---|
| M3 | `v0.1.0-pre-alpha.1` | A usable playable slice, with working controls, interactions, checkpoint persistence and clearly documented limitations | Not published |
| M5 | `v0.2.0-alpha.1` | The intended game is playable from beginning to end, with its principal gameplay and audio connected | Keep the pre-alpha label: `v0.1.0-pre-alpha.N` |
| M7 | `v0.3.0-rc.1` | Intended scope complete, no known release-blocking defects, and final acceptance checks passed | Keep the earlier label |

**A correction is a new version:** `v0.1.0-pre-alpha.2`. A published version is never replaced.

**Never under this authorization:** itch.io, the jam submission, or a stable or 1.0 label. `tools/release_gate.py` has no way to express a stable version.

## The path to a release

1. **Normal work:** feature branch, pull request, review, CI on GCC, Clang and MSVC, owner acceptance, squash merge, CI on `main`, branch deleted.
2. **The owner tests a build and says so.** Their statement goes in an evidence record, limited to what they said (M2's is [the model](evidence/m2/owner-acceptance-2026-11-03.md)). **Acceptance is never inferred or written on their behalf.**
3. **The release record** is updated to `state: publish`, in a pull request, and squash-merged.
4. **That push to `main` runs CI as usual.** Nothing extra is tested. Then, in the same run, `release.yml`:

| Job | What it does | Can write? |
|---|---|---|
| `gate` | Reads the record, checks every gate, and names every blocker | No |
| `package-linux`, `package-windows` | Packages the run's own export with the license and credits, then extracts the package and runs it headless on its own OS: main menu, New Game with a prompt, a save, and Continue | No |
| `prepare` | Writes the release notes, `SHA256SUMS.txt` and `PROVENANCE.txt` | No |
| `publish` | Creates a draft, checks the uploaded files against their checksums, and only then publishes. The tag appears at that moment, at the tested commit | Yes |

## Release states

| `state` | What happens on each `main` push |
|---|---|
| `planned` | Reports which gates are open. Nothing else |
| `candidate` | Also prepares the packages, notes and checksums as a `release-candidate-*` artifact, and reports what remains. Never publishes |
| `publish` | Publishes if every gate passes. **Otherwise CI fails on that commit, naming each blocker,** and nothing is published |

## The gates

| Gate | Blocks when |
|---|---|
| CI | Any of GCC, Clang, MSVC or the release tools did not succeed on this commit |
| Owner acceptance | It is not `accepted`, its record does not exist, or it does not state the build tested and what it covers |
| Gameplay unchanged | This commit's gameplay fingerprint differs from the one accepted |
| Label criteria | Any criterion for the version's label is not `met`, or has no evidence file. **`deferred` is not `met`** |
| Limitations | The notes have no summary, or no known limitations |
| Release candidate | Any check is still deferred |
| Duplicates | The tag or release exists, or more than one release is requested at once |
| Package | A file is missing or extra, the smoke test fails, there is not exactly one package per OS, or the provenance is incomplete |

## What an owner's acceptance covers

**An acceptance covers a gameplay fingerprint: a hash of the files that make up the game.** Get it with `python tools/release_gate.py fingerprint --commit <the commit they tested>`.

| | Files |
|---|---|
| **Changing these voids the acceptance** | `src/`, `project/` apart from `project/tests/`, `SConstruct`, `methods.py`, the `godot-cpp` version, and the Godot and template install scripts |
| **Changing these does not** | Documents, tests, this workflow and everything else in the repository |

So it survives a squash merge and a documents-only commit with no new playthrough, and no one needs to ask again.

**What this does not establish:**

- **That the bytes are the ones the owner played,** unless they tested `main`'s own artifact. The same files went in, and `main`'s CI built and tested them. The record states which build they actually ran.
- **Anything about the CI runner's compiler or image.** Those are not files in the repository. They are recorded in `PROVENANCE.txt`.
- **Anything the owner did not state.** Deferred checks stay deferred, and appear in the notes under "Not tested".

**M2's acceptance** ([record](evidence/m2/owner-acceptance-2026-11-03.md)) covers `sha256:d69bb9bfc9657b18777a14fb3d5d10546df3261269d91a1f3b76668d78eeb0de`. No release was planned for M2. M3's gameplay will change that fingerprint, so M3 needs its own acceptance.

## Authentication, races and immutability

- **Only the run's own `GITHUB_TOKEN`.** No secrets are stored or used. Everything has read-only access except the `publish` job, which has `contents: write`, and only runs for a push to `main`.
- **One publication at a time:** the `release-publication` concurrency group, which never cancels one in progress. Inside it, the publisher checks again for the tag and release, and stops if either exists.
- **A failure part way publishes nothing.** The release stays a draft, no tag exists and no version is used up. The next attempt removes that unpublished draft.
- **Repository settings,** applied when this workflow was accepted: `main` requires the `linux`, `linux-clang`, `windows` and `release-tools` checks and refuses force-pushes and deletion, a ruleset refuses moving or deleting `v*` tags, and GitHub's immutable releases are on.

## Compilers

There is **one package per OS:** GCC on `ubuntu-22.04` for Linux, and MSVC on `windows-2022` for Windows. `linux-clang` validates only. It runs the same unit, integration and export smoke checks, and uploads no build ([toolchain.md](toolchain.md)). Each job's cache and logs are its own.

## Testing the workflow

- **On every pull request:** `python tools/test_release_tools.py`, and `python tools/release_gate.py validate`.
- **A rehearsal** runs the gate, packaging, smoke test and preparation for real, on any branch: `gh workflow run ci.yml --ref <branch> -f rehearse=true`. It uses version `.0`, which can never be published, and the `publish` job cannot run outside a push to `main`.
- **What no rehearsal can show:** the final publish step, which runs for the first time on a real release. Its commands were checked as far as a draft ([evidence](evidence/release-workflow/README.md)).
