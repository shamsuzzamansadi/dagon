# M7 playtest kit: two first-time players, on `v0.2.0-alpha.2`

For the owner, who contacts the players (M7 plan, item 1, as approved on 2026-11-27: [record](../../evidence/m7/plan-approval-2026-11-27.md)). **Everything a player sees is in the three files marked "send",** plus the message below. This page and [measurement.md](measurement.md) are not for players, because they name what the game holds.

| File | For | What |
|---|---|---|
| [invitation.md](invitation.md) | **send** | A short invitation, with the deadline |
| [instructions.md](instructions.md) | **send** | How to get the game, record it with sound and play it. No spoilers |
| [questions.md](questions.md) | **send, after playing** | Five questions, and a few lines about the setup |
| [measurement.md](measurement.md) | the developer | What is measured from each recording, and how |
| [results.md](results.md) | the developer | Each player's measured playtime, where they needed help, and their answers, filled in as recordings arrive |

**Deadline for both players: recordings and answers by Sunday 29 November 2026, 12:00 UTC.**

## The build, the same for both players

**[`v0.2.0-alpha.2`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.2),** published on 2026-11-27 from `b271316`, the build the owner accepted ([record](../../evidence/m6/release-authorization-2026-11-27.md)). It is also the default jam build, so what the players find applies to what is submitted.

| System | File (direct download link) | Size | SHA-256 |
|---|---|---|---|
| **Windows,** 64-bit (x86-64) | [`dagon-v0.2.0-alpha.2-windows-x86_64.zip`](https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-windows-x86_64.zip) | 44.4 MB | `f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148` |
| **Linux,** 64-bit (x86-64) | [`dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz`](https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz) | 35.3 MB | `6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05` |
| macOS, Apple Silicon (arm64), macOS 11 or later | [`dagon-v0.2.0-alpha.2-macos-arm64.zip`](https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-macos-arm64.zip) | 34.6 MB | `9daca1d1f76982248a8ba91029c0dca99cfc8fee3387d411063a09a933cb5586` |

**Verified by the developer on 2026-11-27:** all three downloaded again from these public links into an empty folder, each equal to `SHA256SUMS.txt` and to GitHub's own digest; the tag points at `b271316`. **The downloaded Linux package was played to the ending** by the scripted route check on a private display ([results.md](results.md) gives the run).

**Windows or Linux, preferably.** The owner has tested the Windows package. **No person has run the Mac build yet:** CI has checked it only headless, with no window drawn and no sound played. A player with only a Mac can still play, and the instructions cover it, but they would also be the first person to run it. Their first launch needs extra steps, because the app is not notarized, and if those steps go wrong it says nothing about the game.

**Getting it to them.** The links above download the file straight away and need no GitHub account. **Send the file links, not the release page:** the release notes describe what is in the game. Or download the file yourself and share it some other way, with its SHA-256.

### A message to send with the build

> Here's the game, and the instructions are attached. Please download the file for your computer:
>
> - Windows: https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-windows-x86_64.zip
> - Linux: https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz
> - Mac with Apple Silicon (M1 or later): https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-macos-arm64.zip
>
> Please send me your recording and your answers to the five questions by **Sunday 29 November, 12:00 UTC.** Thank you!

If the player wants to check the file, send its SHA-256 from the table.

## What comes back

From each player, by **29 November, 12:00 UTC:**

- **The recording, with sound,** from the main menu back to the main menu.
- **Their answers** to questions.md.
- Anything else they want to add.

Recordings can be large: 15 minutes at 1080p can be 1 to 2 GB, so a cloud drive link is easiest. Put each player's files where the developer can read them, named player 1 and player 2. No names are needed in the records.

**If you helped a player while they played,** write down when and what you said, as close as you can, and send that too. Measured playtimes count the time either way. Help is recorded beside the time.

**If something comes late:** `v0.2.0-alpha.2` stays the submission build, and the findings are carried forward after the jam (M7 plan §4, as the owner set on 2026-11-27).

## Not for the players

Do not send them this page, measurement.md, results.md, the README, the release page, the roadmap or any clip. Do not describe the story, the ending, the controls beyond what the game shows, or how long it is meant to take. If a player asks for help while playing, give as little as you can, and note when you helped and what you said.
