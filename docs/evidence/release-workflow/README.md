# Evidence: the release workflow and Clang coverage

| File | What it is |
|---|---|
| [local-clang-18.1.3.txt](local-clang-18.1.3.txt) | A local build with Clang 18.1.3 in its own clone, at the commit before this work plus the `SConstruct` change: no warnings, the unit and integration tests, and the export smoke. **Local availability does not replace the CI job** |
| [breakage-of-the-release-tools.txt](breakage-of-the-release-tools.txt) | 49 deliberate breakages of the gate, the packager, the publisher and the workflow rules. Two slipped through at first, because a test took its expected list from the code under test and another could not see a varying timestamp. Both tests were corrected, and all 49 are now caught |
