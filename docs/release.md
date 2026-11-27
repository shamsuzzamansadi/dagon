# Releases

How a milestone prerelease is built, gated and published. The rules come from the owner, 2026-11-03 ([D45, D46](decisions.md)).

**Reaching a milestone publishes nothing.** A prerelease happens when a record in `release/` asks for it, that record has been merged through the normal pull request, and every gate passes on the `main` commit CI has just tested.

## Targets

| Milestone | Version | Promise | If it is not true |
|---|---|---|---|
| M4 (planned for M3; nothing was published at M3) | `v0.1.0-pre-alpha.1` | A usable playable slice, with working controls, interactions, checkpoint persistence and clearly documented limitations | Not published |
| M5 | `v0.2.0-alpha.1` | The intended game is playable from beginning to end, with its principal gameplay and audio connected | Keep the pre-alpha label: `v0.1.0-pre-alpha.N` |
| M7 | `v0.3.0-rc.1` | Intended scope complete, no known release-blocking defects, and final acceptance checks passed | Keep the earlier label |

**`v0.2.0-alpha.1`, M5's alpha, is published** ([https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.1](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.1)), from `a4250f0` (below). **`v0.1.0-pre-alpha.1` is published** ([https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1)), from `760a539`. **The first prerelease moved from M3 to M4.** M3 was accepted as a milestone on 2026-11-10 with no release asked for, and its record stayed `planned`. On 2026-11-15 the owner asked for the first pre-alpha at M4 and accepted its candidate ([record](evidence/m4/owner-acceptance-2026-11-15.md)). The version is the same, never having been used; the promise is the same.

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
| `package-linux`, `package-windows`, `package-macos` | One for each OS the record ships. Packages the run's own export with the license and credits, then extracts the package and runs it headless on its own OS: main menu, New Game with a prompt, a save at the first checkpoint, and Continue from it in a new process. The Mac package is unpacked as a Mac unpacks a download, and its architecture and signature are checked before it runs | No |
| `prepare` | Writes the release notes, `SHA256SUMS.txt` and `PROVENANCE.txt`. The provenance names the game's source commit, the run that built and tested it, and the run that prepared it, as three facts, and no publication: preparing comes before any publication, and a candidate is never published (D132) | No |
| `publish` | Creates a draft, checks the uploaded files against their checksums, and only then publishes. The tag appears at that moment, at the tested commit | Yes |

## Shipping an earlier commit on `main` (D128)

A record usually ships the commit whose `main` push it is merged in. **A record can instead ship an earlier commit on `main`:** its `source` names that commit and `main`'s own push run of it.

```json
"source": {"commit": "<the full commit>", "run": <the id of main's push run of it>}
```

| | What happens |
|---|---|
| **The gate** | Judges that commit's files against the owner's acceptance (its fingerprint), and checks that the run is `main`'s own push run of that commit, that it succeeded, that `linux`, `linux-clang`, `windows` and `release-tools` passed in it, that it still holds the exports and logs, and that the commit is in this commit's history. This commit's own CI must pass too |
| **The packages** | The package job checks that commit out, and packages that run's own exports with that commit's own packaging tool, license and credits: what its own release would have been. Nothing is rebuilt |
| **The provenance and notes** | Name, as separate facts, that commit as the game's source, that run as the source build run, which built and tested it, and this run as what packaged, smoke-tested and prepared it. They never claim a publication (D132) |
| **The tag** | Goes on that commit. `verify` checks it there |

**Only while the run keeps its files:** GitHub keeps a run's artifacts for a limited time (until 18 February 2027 for `a4250f0`'s). After that, the gate names the missing files and nothing is published.

**`v0.2.0-alpha.1` shipped `a4250f0`,** M5's accepted squash merge, from run [44748633376](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376), at the owner's request of 2026-11-21 ([authorization](evidence/m5/release-authorization-2026-11-22.md)). **It was published on 2026-11-22,** tagged on `a4250f0` ([record](evidence/release-workflow/publication-v0.2.0-alpha.1.md)). The rehearsal record shipped the same until then, so that a rehearsal tested this path for real; it now ships the commit being tested, on all three OSes.

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
| Source | For a record that ships an earlier commit: that commit is not in this commit's history, or `main`'s own push run of it did not pass its required jobs, or no longer holds its exports and logs (D128) |
| Owner acceptance | It is not `accepted`, its record does not exist, or it does not state the build tested and what it covers |
| Nothing shipped has changed | This commit's acceptance fingerprint differs from the one accepted |
| Label criteria | Any criterion for the version's label is not `met`, or has no evidence file. **`deferred` is not `met`** |
| Limitations | The notes have no summary, or no known limitations |
| Release candidate | Any check is still deferred |
| Existing state | What exists for the version is not a complete, consistent release, or cannot be determined (below) |
| One at a time | More than one release is requested at once |
| Package | A file is missing or extra, the smoke test fails, there is not exactly one package per OS, or the provenance is incomplete |

## What an owner's acceptance covers

**An acceptance covers a fingerprint: a hash of the files that make up the game, and of the files that decide how it is built, exported and packaged.** Get it with `python tools/release_gate.py fingerprint --commit <the commit they tested>`.

| | Files |
|---|---|
| **Changing these voids the acceptance** | `src/`, `project/` apart from `project/tests/`, `SConstruct`, `methods.py`, the `godot-cpp` version, `.gitmodules`, `.gitattributes`, everything in `.github/workflows/`, and `tools/` `run_godot_checks.sh`, `export_check.sh`, `prepare_project.sh`, `test_storage.sh`, `package_release.py`, `install_godot.sh`, `install_export_templates.sh` and `extract_templates.py` |
| **Changing these does not** | Documents, `LICENSE`, `CREDITS.md`, `release/`, `project/tests/`, `tests/`, `tools/art/`, and the other release tools, including the gate and publisher, which do not change what is inside a package |

**This is deliberately conservative.** Nothing tries to judge whether a change matters, so even a comment in a workflow voids the acceptance. A new fingerprint needs a new statement from the owner, which can be a short one when the change does not touch the game. It survives a squash merge and a documents-only commit with no new playthrough.

**What this does not establish:**

- **That the bytes are the ones the owner played,** unless they tested `main`'s own artifact. The same files went in, and `main`'s CI built and tested them. The record states which build they actually ran.
- **Anything outside the repository.** GitHub can update a runner image, and with it GCC or MSVC, and `actions/*@vN` can move within a major version, with the fingerprint unchanged. The compilers are recorded in `PROVENANCE.txt`, and Clang's version is checked. The Godot download is pinned by SHA-512, which the fingerprint covers through the install scripts.
- **The two text files in each package that are not covered:** `LICENSE` and `CREDITS.md` can change without voiding an acceptance. The in-game Credits screen is in `project/`, so it is covered.
- **Anything the owner did not state.** Deferred checks stay deferred, and appear in the notes under "Not tested".

**M2's acceptance** ([record](evidence/m2/owner-acceptance-2026-11-03.md)) was given for `3426d3b`, whose fingerprint under this definition is `sha256:b90b33cc3166d3cb4e1bbda900475f75427df54677b0a6d29f8a93124a48aa60`. No release was planned for M2. The fingerprint at `main` has already moved on, because this workflow changed files it covers, and M3 changes it again, so M3 needs its own acceptance.

## What already exists for a version

Each `main` push asks GitHub what exists for every record in `release/`. **A tag alone does not mean a release exists,** and an unanswered question does not mean nothing does.

| What it finds | What happens |
|---|---|
| No tag and no published release | The record's state and gates decide |
| **A complete, consistent release:** published, marked as a prerelease, its tag at the commit the release recorded as its target, with both packages, `SHA256SUMS.txt` and `PROVENANCE.txt` uploaded | Skipped, with a notice. **The tag is checked against the release's own recorded target, never `main`'s latest commit,** so main can move on freely |
| A tag with no published release, a tag that disagrees with the release, a target that is not a commit, a published release with no tag, a release that is not a prerelease, or missing or unfinished files | **CI fails on every `main` push, naming the specific problem, until a person resolves it.** Nothing moves or deletes a tag or a published release. Use a new version, or put it right by hand |
| GitHub or the remote does not answer: a network failure, a failed login, a refused request, any status but a 404, or a repository the token cannot see | **CI fails, saying the state could not be determined.** Nothing is packaged or published. It is never read as "absent" or as success |

**The retry policy for a failed publish.** A draft stays private and creates no tag, so a failure part way publishes nothing and uses up no version. On the next attempt, inside the lock, an unpublished draft is removed and the release is created again, **only if no tag exists and nothing is published for that version.** It looks at the draft again first, and refuses to delete anything else. If a tag or a published release exists beside the draft, it stops and leaves everything alone. Only the `publish` job can see drafts, because seeing them needs write access.

## Authentication, races and immutability

- **Only the run's own `GITHUB_TOKEN`.** No secrets are stored or used, and the token is never printed. The gate reads with a read-only token. Only the `publish` job has `contents: write`, and it only runs for a push to `main`.
- **One publication at a time:** the `release-publication` concurrency group, which never cancels one in progress. Inside it, the publisher asks again what exists. If an earlier run has just published this version, a later one skips it.
- **Repository settings, chosen by the owner on 2026-11-04** ([D47](decisions.md)). For `main`: pull requests are required, with no approving reviews, because this is a single-account repository. The `linux`, `linux-clang`, `windows` and `release-tools` checks are required, and must come from GitHub Actions. History must be linear, force-pushes and deletion are refused, and the rules apply to administrators. Only squash merging is allowed. A ruleset with no bypass refuses updating or deleting `v*` tags, and does not restrict creating them, so a release can still create its tag. Immutable releases are on.
- **GitHub holds the live state, not this file.** Read it with `gh api repos/shamsuzzamansadi/dagon/branches/main/protection`, `gh api repos/shamsuzzamansadi/dagon/rulesets` and `gh api repos/shamsuzzamansadi/dagon/immutable-releases`.
- **What these settings do not do.** An administrator can still change them. A required check is only as good as the job behind it, and a branch need not be up to date with `main` to merge, which keeps checks from running again for no reason while one branch is in progress.

## Compilers

There is **one package per OS:** GCC on `ubuntu-22.04` for Linux, MSVC on `windows-2022` for Windows, and, from M6, Apple Clang on `macos-15` for macOS on Apple Silicon ([D129](decisions.md)). A record names the OSes it ships in `platforms`; one that names none, such as `v0.1.0-pre-alpha.1`'s and `v0.2.0-alpha.1`'s, shipped Linux and Windows, and is checked for those two. `linux-clang` validates only. It runs the same unit, integration and export smoke checks, and uploads no build ([toolchain.md](toolchain.md)). Each job's cache and logs are its own.

## Testing the workflow

- **On every pull request:** `python tools/test_release_tools.py`, and `python tools/release_gate.py validate`.
- **A rehearsal** runs the gate, packaging, smoke test and preparation for real, on any branch: `gh workflow run ci.yml --ref <branch> -f rehearse=true`. It uses version `.0`, which can never be published, and the `publish` job cannot run outside a push to `main`.
- **A rehearsal also asks GitHub what exists, with its read-only token,** so those requests run for real.

## A commit that changes workflow files

**`v0.2.0-alpha.2`'s commit, `b271316`, changes `.github/workflows`, and the publish job's token was refused when it created the draft** (HTTP 403, run 46036924022; nothing was created). An Actions token cannot hold the `workflows` permission; the earlier releases' commits changed no workflow file. The cause is probable, not proven. At the owner's choice it was published by hand, with the owner's login, by `publish_release.sh`'s steps on the files that run prepared ([D133](decisions.md), [record](evidence/release-workflow/publication-v0.2.0-alpha.2.md)). **Before a later version whose commit changes workflow files, the owner decides how it is published.**

## The first real publication

**`v0.1.0-pre-alpha.1` was published by this workflow on 2026-11-15** ([evidence](evidence/release-workflow/first-publication-v0.1.0-pre-alpha.1.md)). The write path, the tag created under the active ruleset, immutable releases and the target kept after publishing were all observed once, with no protection changed. **Still unproven:** removing a failed draft on a retry, and the ruleset refusing to move or delete a tag (not attempted). What was written before it, kept as the record of what was open:

**No tag or release has ever been made by this workflow.** Whoever runs the first release should watch its `publish` job, because these are still unproven:

- **The write path has not run from the workflow:** creating a draft and uploading to it, removing a failed draft, publishing, and the check after publishing. Local tests run those requests against a stand-in for the API, and the commands were checked once by hand as far as a draft ([evidence](evidence/release-workflow/README.md)). A failure before publishing publishes nothing, and is reported on that commit.
- **The tag rules and immutable releases have not met a real publication.** The ruleset does not restrict creating a tag, and the workflow publishes a draft, which is the order immutable releases expect. That comes from how they are configured and documented. It has not been observed.
- **The consistency check assumes GitHub keeps the commit as a release's target after publishing.** That has been seen on a draft only. If it does not, the release would publish and `verify` would then report it as inconsistent, and so would the gate on every later `main` push.
- **A mistake in a published release cannot be repaired in place.** Immutable releases lock its files and tag, and the tag rules refuse moving or deleting it, so a correction is a new version. Resolving an inconsistent state needs a person, and possibly a change to the settings.
