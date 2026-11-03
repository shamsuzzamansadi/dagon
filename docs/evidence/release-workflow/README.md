# Evidence: the release workflow and Clang coverage

| What | Result | Where |
|---|---|---|
| A local build with Clang 18.1.3, in its own clone | No warnings in project or third-party code. 83 test cases, 994 assertions, 195 integration tests, and the export smoke with 195 on the pack. **Local availability does not replace the CI job** | [local-clang-18.1.3.txt](local-clang-18.1.3.txt) |
| Deliberate breakage of the gate, packager, publisher and workflow rules, at the final tools | 105 changes, all caught, with controls before and after. Four slipped through along the way. One test took its expected list from the code under test, one could not see a varying timestamp, one page-404 case was untested, and one breakage was badly chosen and changed nothing, so it was replaced | [breakage-of-the-release-tools.txt](breakage-of-the-release-tools.txt) |
| The publisher's commands, on a temporary draft in the real repository, under an unpublishable version | The draft pointed at the given commit and created no tag, its files downloaded and verified, and deleting it left no release and no tag. Done by hand, with the owner's login, on 2026-11-03, before the review below | No file |

**What a rehearsal found, which no local test did:** `prepare` crashed on the rehearsal's own `.0` version. Reading that code also showed that notes for an unaccepted candidate would have said the owner's acceptance applied. Both are fixed, with tests.

## Review round 1

**Reported by the reviewer (ChatGPT) on `a7859c2`, relayed by the owner.** The reviewer ran the 47 release-tool tests and the record validation. The Godot integration tests, Windows gameplay and actual release publication were not independently rerun. **The fixes below have not been reviewed.**

All three findings reproduced on the unfixed code: [before-the-fixes.txt](review-round-1-before-the-fixes.txt).

| Finding | Reproduced | Fix |
|---|---|---|
| 1. The acceptance fingerprint omitted build and export configuration | Yes: a workflow, `export_check.sh`, `run_godot_checks.sh` and `package_release.py` could all change with the fingerprint unchanged | They are all covered now, with the rest of the build and export inputs. A test fails if a listed input stops existing, because a renamed path would otherwise drop out silently |
| 2. A tag alone counted as a published release | Yes: a tag with no release passed as "already published" | Complete releases are skipped, inconsistent ones fail with the specific problem, and unanswered questions fail. The tag is checked against the release's recorded target |
| 3. Linux package bytes varied with the time of packaging | Yes: the gzip header held the current time, and the file name | The gzip time is fixed, and no name is stored. Tested under two clock values and two sets of source file times |

**Found while reproducing finding 2, and fixed:** the publisher ran `gh release view ... || echo none`, so a network or login failure read as "no release exists".

**Also corrected:** `docs/release.md` said the repository protections were applied. None are. They stay planned until this workflow is accepted, and the document now says what that leaves open.

**Limits of the tests:** the API tests use a local stand-in for GitHub's API, with real HTTP requests and a real bare git remote. They establish how the tools respond to each answer, not that GitHub gives those exact answers. The first real publish is the first time the write path runs.
