# `v0.2.0-alpha.2`, the M6 candidate: the alpha label's criteria

**A candidate, not a release.** The roadmap names no version for M6; its exit gate asks for release-candidate artifacts from CI, launched on real Windows and Linux. `release/v0.2.0-alpha.2.json` is in `candidate` state: `main`'s CI packages it and never publishes it. The version is the developer's proposal, and publishing it needs the owner's word ([acceptance](owner-acceptance-2026-11-21.md)).

The label's promise ([release.md](../../release.md)): **the intended game is playable from beginning to end, with its principal gameplay and audio connected.** Each line says who or what established it, and on which build.

## 1. Playable from beginning to end (`playable_start_to_end`)

| Evidence | Who or what | Build |
|---|---|---|
| **"Owner playtest satisfactory"** for the route played: New Game through the running escape, all four epilogue panels, the credits and the return to the main menu | **The owner,** on Windows ([record](../../m6/owner-test-build.md)) | The owner-test build, `a30be86` |
| The exported game, played from New Game to the ending card, through the credits and back to the main menu, four ways, `ROUTE_RESULT runs=4 failed=0`, on Linux and Windows, with window-system key events | CI, scripted, on every M6 head | Each M6 head, the candidate's included |
| The downloaded owner-test Linux build, the same four runs, and Continue from a post-ending save | The developer, scripted | `a30be86` |

**Not established:** play by a first-time player; a person playing the standing-still ending, or Continue after the credits; **any play of the Mac build by a person.** On the Mac, CI runs the packaged app headless: it starts, New Game reaches the first checkpoint and saves, and a new process continues from that save.

## 2. Principal gameplay connected (`principal_gameplay_connected`)

| Evidence | Who or what | Build |
|---|---|---|
| The integration tests, from source and on the exported pack, on GCC, Clang, MSVC and Apple Clang; the native tests on each | CI | The candidate |
| The routes above reach every act in order; Continue resumes at each savable checkpoint (`test_restore`) | CI and the developer, scripted | The candidate, and `a30be86` |

## 3. Principal audio connected and heard in gameplay (`principal_audio_heard`)

| Evidence | Who or what | Build |
|---|---|---|
| **Heard in play:** the owner stated on 2026-11-22 that they heard the game's main audio (music, effects, narration and the reveal) while playing the M5 build with sound ([authorization](../m5/release-authorization-2026-11-22.md)). **M6 changed no sound, no line and no mix:** `git diff a4250f0` touches nothing under `project/assets/audio`, `project/assets/narration` or `project/narration`, nor the bus layout | The owner; the diff | `b7303bf`; M6 |
| Connected: every sound and line plays at its moment, held by the integration tests | CI | The candidate |

**Not established:** any judgement of the mix by ear; **the intelligibility of the reveal's dialogue,** which stays open; the owner's listening sheet is pending.
