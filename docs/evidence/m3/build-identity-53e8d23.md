# Which build each Windows zip is

Two SHA-256 values were in circulation for "the" Windows build of `53e8d23`. Checked on 2026-11-09 from the artifacts themselves and the CI logs.

| Zip SHA-256 | Artifact | CI run, event | What that run checked out |
|---|---|---|---|
| `b379c5faaa21cb719f903574caa0d8081668287561bfde6a96b0cfe9e24036f3` | `dagon-windows` 13697420499 | [42664240869](https://github.com/shamsuzzamansadi/dagon/actions/runs/42664240869), push | `53e8d232d2668f86fb1c714008c909ab3a07e2c7` itself |
| `34102e74f7b48b9b4a119bf56fe3d364ed2008bf31505ee02b31d5b625016ce3` | `dagon-windows` 13696991414 | [42664251414](https://github.com/shamsuzzamansadi/dagon/actions/runs/42664251414), pull request | GitHub's merge commit `6de4c32`, "Merge 53e8d23 into 15ba96c" |

**The two are the same game, built twice.** `6de4c32`'s tree is byte-for-byte `53e8d23`'s (`d7809078b2174fabb23b11a0185ffe83da749495`), as `main` was already its ancestor. Inside the zips:

- `dagon.exe`, the engine's template, is identical.
- `dagon.pck` holds the same 190 files. 180 are identical, including every texture, sound, script and the narration. The other 10 are the scenes the export converts to binary, each the same size in both, differing in bytes the conversion does not keep stable.
- `dagon.windows.template_release.x86_64.dll`, the game's code, was compiled separately in each run, from the same source.

**The handoff named the push run's zip; the owner downloaded the pull-request run's.** Both were built from `53e8d23`. Neither proves which one a given recording shows: a recording of play cannot be tied to a zip, so the owner's recording is evidence of what was seen, not of which file was run.

**From here on, one build is named for each playtest:** the push run's `dagon-windows` artifact for the commit under review, with its zip SHA-256. The pull-request run's artifact is built from the same source, and its checksum will differ.
