# Evidence: the release workflow and Clang coverage

| What | Result | Where |
|---|---|---|
| A local build with Clang 18.1.3, in its own clone | No warnings in project or third-party code. 83 test cases, 994 assertions, 195 integration tests, and the export smoke with 195 on the pack. **Local availability does not replace the CI job** | [local-clang-18.1.3.txt](local-clang-18.1.3.txt) |
| Deliberate breakage of the gate, packager, publisher and workflow rules | 52 changes, all caught. Two slipped through at first, because one test took its expected list from the code under test, and another could not see a varying timestamp. Both tests were corrected | [breakage-of-the-release-tools.txt](breakage-of-the-release-tools.txt) |
| The publisher's commands, on a temporary draft in the real repository, under an unpublishable version | The draft pointed at the given commit and created no tag, its files downloaded and verified, and deleting it left no release and no tag | Done by hand, with the owner's login, on 2026-11-03 |

**What a rehearsal found, which no local test did:** `prepare` crashed on the rehearsal's own `.0` version. Reading that code also showed that notes for an unaccepted candidate would have said the owner's acceptance applied. Both are fixed, with tests.

**What has not run:** the final publish step, `gh release edit --draft=false`, and the check of the tag after it. They run for the first time on a real release. If that step fails, nothing else is published, and the failure is reported on that commit.
