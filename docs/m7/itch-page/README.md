# itch.io page kit: DAGON, for `v0.2.0-alpha.2`

For the owner, who edits the existing project at **<https://shamsuzzamansadi.itch.io/dagon>**, uploads the files and submits to the jam (M7 plan §3, as approved on 2026-11-27: [record](../../evidence/m7/plan-approval-2026-11-27.md)). Everything here is ready to paste. The build is **`v0.2.0-alpha.2`, published from `b271316`,** the default jam build.

**What could not be checked from here:** itch.io refuses automated reading (jam.md §1), so the field names below follow itch's usual edit page and may differ a little. The jam behind <https://itch.io/jam/417834/add-game> is the owner's link, and was not opened here.

## 1. The edit page, field by field

| Field | Paste or choose |
|---|---|
| Title | `DAGON: Beneath the Black Tide` |
| Project URL | Keep `dagon` |
| Short description or tagline | `The sea has drawn back farther than any tide. Walk out across what it left behind.` |
| Classification | Games |
| Kind of project | Downloadable |
| Release status | In development (it is an alpha) |
| Pricing | The owner's choice: No payments, or $0 or donate |
| Uploads | The three files in §3 |
| Description | **[description.html](description.html):** open it in a browser, select all (Ctrl+A), copy, and paste into the Description box. Headings, lists and links carry over |
| Genre | Adventure |
| Tags | `horror`, `lovecraftian`, `pixel-art`, `2d`, `atmospheric`, `side-scroller`, `short`, `story-rich`, `singleplayer`, `exploration` |
| AI generation disclosure | **Yes.** If it asks which kinds, choose every kind it lists from these: **code, text and dialogue, voice and sound, graphics.** All apply (jam.md §5): the art is drawn by scripts Claude wrote, the sounds are synthesized by code Claude wrote, and the narration is an AI-generated voice |
| Made with | Godot |
| Inputs, if offered | Keyboard, Xbox controller, PlayStation controller |
| Accessibility, if offered | Subtitles, Configurable controls |
| Languages | English |
| Average session, if offered | A few minutes. The length of a first playthrough has not been measured yet; the playtests will tell |
| Mature content | Not needed: no gore and no sexual content. The owner's call |
| Cover image | [images/cover.png](images/cover.png), 630 × 500 |
| Screenshots | [images/](images/), `screenshot-1.png` to `screenshot-5.png`, in that order (§4) |
| Visibility | **Public**, as the last step before submitting (§5) |

## 2. What the description says

[description.html](description.html), written for players, with nothing about what happens past the Abyss:

- **The pitch:** a sailor cast adrift in wartime wakes beside his boat on seabed that should be under the ocean, and walks out across it to find where the sea has gone. A short 2D pixel-art horror game after Lovecraft's *Dagon*, with no combat and no game over, made for GitHub Game Off 2026.
- **SHIFT,** through what the player experiences, in two sentences, as jam.md §4 asks: *"The sea withdraws, and the floor of the ocean becomes the way forward: you cross the exposed seabed on foot, reading what the water hid. When the tide returns, the route you walked out on becomes your escape."*
- **Controls:** keyboard, Xbox and PlayStation, from the README.
- **Downloads, with platform notes:** Windows and Linux on x86-64; the Mac on Apple Silicon only, macOS 11 or later, **signed ad hoc and not notarized,** with the first-launch steps, and that **it has been checked only by automated tests on a GitHub-hosted Apple Silicon Mac, run headless (no window drawn, no sound played), and no one has played it on a Mac.**
- **An alpha,** and that not every controller has been tested on real hardware.
- **The source:** <https://github.com/shamsuzzamansadi/dagon>, MIT for code and CC BY 4.0 for original assets.
- **How it was made, and the use of AI:** jam.md §5, for players: the owner's role; Claude through Claude Code for most code and documents; art from scripts Claude wrote, with no image generators or third-party art; text and font with AI assistance; sounds synthesized by code Claude wrote; **the narration an AI-generated voice,** Chatterbox in a Kokoro stock voice's timbre, watermarked, nobody's voice cloned; ChatGPT as an independent reviewer. Links to jam.md §5 and CREDITS.md.
- **Credits:** Lovecraft's *Dagon* (1919), in the public domain; the Godot Engine.

## 3. The three uploads

Each file is byte for byte the one on the [GitHub release](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.2), downloaded again on 2026-11-27 and checked against `SHA256SUMS.txt` and GitHub's own digests. **Copies for the upload are in `C:\Users\sadi\projects\dagon-itch-upload\`,** with `SHA256SUMS.txt`. Or download them from the links.

| File | itch's platform box | Display name to give it | Architecture | Size | SHA-256 |
|---|---|---|---|---|---|
| [`dagon-v0.2.0-alpha.2-windows-x86_64.zip`](https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-windows-x86_64.zip) | **Windows** | `DAGON v0.2.0-alpha.2 – Windows (64-bit)` | x86-64 | 44,411,672 bytes | `f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148` |
| [`dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz`](https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz) | **Linux** | `DAGON v0.2.0-alpha.2 – Linux (64-bit)` | x86-64 | 35,294,343 bytes | `6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05` |
| [`dagon-v0.2.0-alpha.2-macos-arm64.zip`](https://github.com/shamsuzzamansadi/dagon/releases/download/v0.2.0-alpha.2/dagon-v0.2.0-alpha.2-macos-arm64.zip) | **macOS** | `DAGON v0.2.0-alpha.2 – macOS (Apple Silicon)` | arm64 only; macOS 11 or later | 34,625,280 bytes | `9daca1d1f76982248a8ba91029c0dca99cfc8fee3387d411063a09a933cb5586` |

**What each has been checked on.** All three come from CI run 46036924022, which packaged and smoke-tested each one on its own system (GitHub-hosted runners: Windows Server 2022, Ubuntu 22.04, macOS 15.8.2 on arm64). They hold the files that source build run 45038841566 exported and tested ([publication](../../evidence/release-workflow/publication-v0.2.0-alpha.2.md)). **Windows:** the owner tested this package on their own desktop and found no issues ([record](../../evidence/m6/release-authorization-2026-11-27.md)). **Linux:** played to the ending by the scripted route check on a private display, from this very download ([results](../playtest-kit/results.md)); no person has run it on Linux. **Mac:** signed ad hoc, with no Apple developer identity, and **not notarized:** Gatekeeper rejects it, so a player must allow it once (description.html says how). **CI ran it headless on a GitHub-hosted Apple Silicon Mac,** with no window drawn and no sound played: the app started, played New Game to a save, quit and continued from the save in a new process. **No person has run it on a Mac.**

## 4. Cover and screenshots

All six images come from the published Linux package, played with route_check.py's window-system keys on a private display at 1440 × 810. Each is stored as an exact enlargement of the game's own 480 × 270 frame. **They keep the reveal:** nothing from the Monolith, the stones' answer, the gate, or anything after, and nothing from the crossing, whose sky already holds a shape the reveal explains. Each is from the first minutes of play.

| File | What it shows |
|---|---|
| [cover.png](images/cover.png), 630 × 500 | The Shore as the game opens: the stranded boat, the sailor with his lantern and the sea far off under the moon. The title is set in the game's own pixel font. A 315 × 250 window on the frame of `screenshot-1.png`, doubled |
| [screenshot-1.png](images/screenshot-1.png), 1920 × 1080 | The same moment, the whole frame: the cliff, the boat, the sailor and the bare seabed, with the ribs far right |
| [screenshot-2.png](images/screenshot-2.png) | The prologue's first picture and its caption: the war, and the raider that took his ship |
| [screenshot-3.png](images/screenshot-3.png) | Out on the seabed among the ribs, the arm lying by the cliff ahead |
| [screenshot-4.png](images/screenshot-4.png) | In the cave, beside the mark cut into the wall, with the open Abyss beyond |
| [screenshot-5.png](images/screenshot-5.png) | The ritual seen far off where the cave opens, with its caption |

**How they were made:** [source/itch_shots.py](source/itch_shots.py) played the published Linux package from New Game to the first tablet with route_check.py's window-system keys, on a private display, saving a frame about every 0.4 s (171 frames, no errors). `screenshot-2.png` is the prologue frame from the route check's own screenshots of the same package. [source/make_images.py](source/make_images.py) reduces each frame to the game's 480 × 270 picture exactly, refusing any that are not whole 3 × 3 blocks, and enlarges it by whole numbers only.

## 5. Checklist

**Before.**
1. Glance at the jam's [FAQ](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq) for anything new (jam.md §2).

**The project page.**
2. At <https://shamsuzzamansadi.itch.io/dagon>, choose **Edit game**. Fill in §1, paste the description, upload the three files with their platform boxes and display names (§3), add the cover and the five screenshots, and **Save.**
3. Look over the page as a visitor: the cover and screenshots show nothing past the Abyss, and the three downloads are each marked with their system.
4. Set **Visibility** to **Public**, and **Save.**

**Test a download.**
5. In a private browser window, where you are not signed in, open <https://shamsuzzamansadi.itch.io/dagon> and download the Windows file.
6. In PowerShell: `Get-FileHash .\dagon-v0.2.0-alpha.2-windows-x86_64.zip`. It must read `F76538CC776603806010824AB93F0FB0424A5F90184FD0854AF2B98EEFD34148`.
7. Extract it, run `dagon.exe`, see the main menu, and quit. If the Ubuntu ThinkPad is to hand, the same with the Linux file (`sha256sum`, `6631c21b…0e05`).

**Submit.**
8. Open <https://itch.io/jam/417834/add-game>. **Check that the page names GitHub Game Off 2026** before going on.
9. Select **DAGON: Beneath the Black Tide.** Answer the form. **The AI question comes from jam.md §5,** and if it is yes or no, the answer is **yes.** If the form asks for the source repository, use `https://github.com/shamsuzzamansadi/dagon`. Submit.
10. **Save the jam-entry URL** that itch shows afterwards. It is the entry's own page in the jam, usually of the form `itch.io/jam/<jam>/rate/<number>`. Send it to the developer, who records it.

The jam closes **2026-12-01 21:37 UTC.** The internal target is **2026-11-29 21:37 UTC.**
