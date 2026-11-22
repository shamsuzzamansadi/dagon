# Owner acceptance of M6, 2026-11-21

**Stated by the owner, in their message on 2026-11-21,** after playing the owner-test build `a30be86` on Windows ([record](../../m6/owner-test-build.md)):

> I'm satisfied with my Windows playtest of a30be86. I authorize you to finish M6 on draft PR #7, squash-merge it into main, and publish the next roadmap prerelease once the final checks and packaging rehearsal pass. Before merging, update the README and add a native macOS Apple Silicon build target.

> Record my Windows run as satisfactory for the route I played. Carry the outstanding first-time playtests, listening-by-ear results, controller and native hardware checks, and manual post-ending Continue check forward as pending. Keep the two external players on their agreed baseline so their timings remain comparable.

**In the same message, in a second version the owner introduced as ChatGPT's** ("According for ChatGPT:"):

> This is my final M6 decision. I accept M6 with the outstanding human checks carried forward. [...] Carry the listening sheet, display-switch observation, post-credits Continue check, remaining hardware checks and two first-time sessions forward as pending. The two external players stay on a4250f0. These are accepted M6 deferrals.

**Then, in a later message that day, the owner changed what is released:**

> Keep the M5 and M6 releases tied to their respective source commits. [...] Continue PR #7 as M6 stabilization, including the player-facing README and native macOS Apple Silicon build. Before tagging M6, check the current roadmap and release record for its exact designation. If they specify only CI release-candidate artifacts, produce and verify those artifacts and bring me the public tag proposal. Keep the outstanding human checks visible in the release notes.

## What this establishes

- **M6 is accepted as a milestone,** with the outstanding human checks carried forward as accepted deferrals.
- **The owner's playtest:** the owner played the owner-test build `a30be86` on Windows on 2026-11-21. Their verdict, **"owner playtest satisfactory"**, covers the route they played: New Game through the running escape, all four epilogue panels, the credits and the return to the main menu. They were satisfied with the visuals and gameplay and asked for no changes from that run.
- **The merge of #7 is authorized,** after the README and a native macOS Apple Silicon build are added and the final checks and packaging rehearsal pass.
- **No M6 tag.** The roadmap names no version for M6. Its exit gate asks for release-candidate artifacts from CI, launched on real Windows and Linux. Under the later message, M6 gets CI release-candidate artifacts and a tag proposal for the owner, not a release.

## Which build

| | |
|---|---|
| **The build the owner played** | The owner-test build: `a30be86`, `dagon-windows`, artifact [14711113002](https://github.com/shamsuzzamansadi/dagon/actions/runs/44913367672/artifacts/14711113002) of push run 44913367672, zip SHA-256 `c138e0d43d3963882b0697ad54f7d686c44726b1bd240cccaccaa594b5211c9a`. Fingerprint `sha256:14e30e9c7a601075231f27ebbb9cca4a72373302b63d600c8601d97c17b4f04f` |
| **What M6 merges** | That game, plus what the owner asked for before the merge: the README for players, and the native macOS Apple Silicon build. The Mac build adds a few lines to the project's files that every build carries, so **the merged fingerprint differs from the one played:** the GDExtension's list of libraries, a macOS export preset, the import of the textures Apple Silicon needs, and an Apple-only way of reading and writing numbers in the settings file. **No person has played the merged build,** on any system |

## What this does not establish

- **Any check carried forward:** the two first-time players' sessions and timings, who stay on `a4250f0`; the owner's listening sheet; the display switch as the monitor showed it; Continue after the credits, by a person; physical controllers; the native runs on the owner's Windows desktop and Ubuntu ThinkPad. They are listed in the [owner-test record](../../m6/owner-test-build.md) and in the candidate's release notes.
- **The Mac build, by a person.** Its checks are CI's, on a GitHub-hosted Apple Silicon runner ([review package](../../reviews/m6-review-package.md)).
- **A release.** Nothing is tagged for M6 without the owner's word on the proposal.
