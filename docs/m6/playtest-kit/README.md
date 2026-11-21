# M6 playtest kit: two first-time players

For the owner, who contacts the players (M6 plan, item 1). **Everything a player sees is in the three files marked "send";** this page and [measurement.md](measurement.md) are not for players, as they name what the game holds.

| File | For | What |
|---|---|---|
| [invitation.md](invitation.md) | **send** | A short invitation |
| [instructions.md](instructions.md) | **send** | How to get the game, record it with sound, and play it, spoiler-free |
| [questions.md](questions.md) | **send, after playing** | Five questions, and a few lines about the setup |
| [measurement.md](measurement.md) | the developer | What is measured from each recording, and how |

## The baseline build, the same for both players

**`main` at `a4250f0`,** "M5: Cinematic horror and polish (#6)", built by `main`'s CI, push run [44748633376](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376), which passed: integration 455/0 from source and on the exported pack on GCC, Clang and MSVC; the exported game played to the ending on Linux and Windows.

| | Windows | Linux |
|---|---|---|
| **Artifact** | `dagon-windows`, [14634174839](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376/artifacts/14634174839) | `dagon-linux`, [14635725186](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376/artifacts/14635725186) |
| **Zip SHA-256** | `caed3727a00acfd12bf2b5009688608c94d0a342a6e7e92bf7a092cf47b3cbae` | `d0c77bd88c9deb8e503c6aad4ba5399a411681c1c207e98dc8d7b6ec63eee6de` |
| **In the zip** | `dagon.exe`, `dagon.pck`, `dagon.windows.template_release.x86_64.dll` | `dagon.x86_64`, `dagon.pck`, `libdagon.linux.template_release.x86_64.so` |

**Verified by the developer:** both zips downloaded and hashed, and each hash equals GitHub's own digest. **It is the game the owner accepted:** the same fingerprint as `b7303bf`, `sha256:1f724cdc…3dc8d`; the executables are byte for byte the accepted build's; of the 367 files in the game's pack, 357 are byte for byte the same, and the other 10 are the scenes Godot converts to binary at export, from source scenes that are identical. **The downloaded Linux build itself was played to the ending** by the route check on a private display, with window-system keys: `runs=4 failed=0` (reading everything, playing straight through, continuing and waiting for the sea, continuing after the ending). A first attempt had failed in its first run, the sailor hopping in place from 206 s: the developer had started another game on a private display at that moment, which very likely took the keyboard's focus; the rerun, alone, passed. The Windows build was played to the ending by `main`'s CI.

**Getting it to the players.** GitHub lets only a signed-in account download an artifact, and keeps these until 18 February 2027. Download the zip yourself and share the file (a cloud drive link, for example), with its SHA-256 from the table, so the player can check it (instructions.md says how). The game runs on 64-bit Windows and on 64-bit Linux; there is no macOS build.

## What the players see, and what they do not

**Both players play the baseline above, `a4250f0`, and nothing later,** so their recordings and times compare with each other. Changes made on the M6 branch since, which a player would see and which **are not in their build**, by the commit that first has each:

| Commit | What changed on screen | Record |
|---|---|---|
| `0cb97e0` | Settings has a Display button (window or fullscreen); a window too big for its screen opens fitted | D122 |
| `c1811ca` | Settings' key row reads "Examine", not "Interact" | D124 |
| `2ff6cf2` | The distant shape: gone from the Shore's sky by the cliff, seen behind the far cliff in the Abyss | D125 |
| `1229ae6` | **The cave's mouth and exit follow the rock** (no straight edges); **Continue after the ending stands him clear of the kneeling statue** | D126, D127 |

So in a player's recording the cave still shows its straight edges, the triangle still hangs by the Shore's cliff, and Continue after the ending puts him in front of the statue: that is the baseline, not a regression.

## What comes back

From each player: **the recording, with sound,** from the main menu to the main menu again; **the answers** to questions.md; and anything they said they wanted to add. Recordings can be large (a 15-minute recording at 1080p can be 1 to 2 GB); a cloud drive link is easiest. Put each player's files where the developer can read them and name them player 1 and player 2; no names are needed in the records.

## Not for the players

Do not send this page, measurement.md, the README, the roadmap or any clip. Do not describe the story, the ending, the controls beyond what the game shows, or how long it is meant to take. If a player asks for help while playing, help them as little as you can, and note when and what.
