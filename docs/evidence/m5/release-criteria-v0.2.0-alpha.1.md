# `v0.2.0-alpha.1`: the alpha label's criteria, on `a4250f0`

The label's promise ([release.md](../../release.md)): **the intended game is playable from beginning to end, with its principal gameplay and audio connected.** `tools/release_gate.py` needs each of the three criteria below marked met, with this evidence. Each line says who or what established it, and on which build. **The build released is `a4250f0`,** M5's squash merge, whose files are the ones the owner accepted at `b7303bf` (fingerprint `sha256:1f724cdc…3dc8d`).

## 1. The intended game is playable from beginning to end (`playable_start_to_end`)

| Evidence | Who or what | Build |
|---|---|---|
| The exported game, played from New Game to the ending card, through the credits and back to the main menu, four ways: reading everything, straight through, continuing and waiting for the sea, continuing after the ending. `ROUTE_RESULT runs=4 failed=0` on Linux and on Windows, with window-system key events | CI, scripted: `main`'s push run [44748633376](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376) | `a4250f0`, the exports released |
| The same four runs on the Linux build downloaded from that run, on a private display: `runs=4 failed=0` | The developer, scripted ([playtest kit](../../m6/playtest-kit/README.md)) | `a4250f0`, the Linux zip released |
| The owner accepted M5 "as the completed M5 milestone", having playtested it; their recording covers the running route | The owner ([acceptance](owner-acceptance-2026-11-20.md)) | `b7303bf`, the same files |
| The owner played M5's earlier candidates three times on 2026-11-19; the first recording holds all four of the epilogue's voiced lines | The owner ([records](owner-playtest-2026-11-19.md)) | `20929cf`, `59562c6`, `ea86ae9` |

**Not established:** play by a first-time player (M6, pending); a person playing the standing-still ending (scripted only).

## 2. Its principal gameplay is connected (`principal_gameplay_connected`)

| Evidence | Who or what | Build |
|---|---|---|
| Walking, jumping, examining, the crossing, the stone puzzle and its gate, the reveal, the flight, its two endings, checkpoints, Continue, settings and rebinding, each held by the integration tests: 455 passed, 0 failed, from source and on the exported pack, on GCC, Clang and MSVC; the native tests | CI, run 44748633376 | `a4250f0` |
| The routes above reach every act in order, and Continue resumes at each savable checkpoint | CI and the developer, scripted | `a4250f0` |

## 3. Its principal audio is connected and has been heard in gameplay (`principal_audio_heard`)

| Evidence | Who or what | Build |
|---|---|---|
| **Heard in play:** the owner stated, on 2026-11-22, that they heard the game's main audio, music, effects, narration and the reveal, while playing the M5 build with sound ([authorization](release-authorization-2026-11-22.md)) | **The owner** | `b7303bf`, the same files |
| Connected: every sound and line plays at its moment, held by the integration tests; a local speech recogniser found the finale's nine lines whole in the game's own recording, with no clipping and no overlapping speech by measurement | CI, and the developer's tools ([M5 audio](audio/README.md)) | `a4250f0`, and M5's candidates |
| The owner's recordings of M5's candidates carry the game's sound, and ChatGPT compared their audio with an earlier clip: **a signal check, not listening** | ChatGPT, on the owner's recordings | M5's candidates |

**Not established:** any judgement of the mix, the levels or the voice by ear; **the intelligibility of the reveal's dialogue in the full mix,** which stays open, with "Its head turned. I ran." flagged; the owner's listening sheet is pending (M6).
