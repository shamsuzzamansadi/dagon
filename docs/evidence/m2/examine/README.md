# Evidence: why Examine did nothing in exported builds

**Reported by the owner on 2026-11-03:** in the Windows build, under English, German and Bangla keyboard layouts, approaching an examinable
object showed no prompt, and pressing E did nothing. The Settings screen also showed boxes for key names under Bangla.

**Result: two separate defects, both reproduced and both fixed.** The first made Examine dead on every machine, whichever device
pressed the button. The second was only ever about how a key's name was drawn.

## 1. Which build was tested

The owner's `dagon-windows.zip` had SHA-256 `0da315013e87741669d886f892c43721ec8618c27cc17e5391ad563b533a2c51`. That equals the digest GitHub's API
publishes for the `dagon-windows` artifact of CI run 41631600777, at commit `d78f5a6`. The extracted folder was byte-identical to it. That
identifies the download. It cannot prove which copy was launched, though no other copy was present.

Their log shows an NVIDIA GeForce RTX 5060 Ti with OpenGL 3.3.0. They had no `settings.cfg`, so a saved rebinding was not the cause.

## 2. Root cause of the dead Examine

**The export removed the two signal connections from the Interactor to the Hud.** Interaction itself worked: the Interactor found its target.
Nothing was listening.

`shore.tscn` connected `Player/Interactor` to `Hud`. `Player/Interactor` is inside an instanced scene. The text scene keeps such a connection,
so the editor and every test saw it. The export re-packs each scene with `PackedScene.pack()`, which drops a connection starting inside an
instance, unless that instance has Editable Children. No error is logged.

| Evidence | Result | File |
|---|---|---|
| The owner's exact `dagon.pck`, compared with the source scene | Both connections are missing, and the other differences are harmless defaults | [repack-and-compare.txt](repack-and-compare.txt) |
| Re-packing `shore.tscn` by hand | 2 connections before, **0 after** | same |
| The same, with the instance marked editable | **2 after**, which isolates the cause | same |
| Live state in an exported build | `focus: Lifeboat`, `overlaps=1`, `focus_changed connections: []`, `interacted connections: []`, Hud incoming 0 | [live-state-exported.txt](live-state-exported.txt) |
| Live state from source | The same focus, with both connections, and the prompt reading `[E] Examine` | [live-state-source.txt](live-state-source.txt) |
| The integration suite, run on the owner's exact pack | **5 failures,** all about the prompt or caption. It had passed from source. | [suite-on-the-tested-pack.txt](suite-on-the-tested-pack.txt) |

**What was ruled out, by changing one thing at a time, with the pixels of the prompt's text counted in a rendered frame:**

| Build | Prompt pixels | Meaning |
|---|---|---|
| Source scenes, debug library | 128 | The scene and library are fine |
| Source scenes, release library | 128 | The release library is not the cause |
| Export, release template | 0 | The export is |
| Export, debug template | 0 | The template type is not the cause |

The other suspects were checked as well. Physics layers, overlap range and focus are correct in the exported build's live state. Walking and pausing
worked, so input arrived. Once the connections exist, the same E press and the same labels work at the real 1440×810 window (§6). The Hud was simply
never told to show anything.

**Why nothing caught it.** Every test ran from the text scenes. The export check looked for the extension loading and the
right scene, not for a prompt. My own review evidence hid it too: see the correction in [../README.md](../README.md).

## 3. Reproduction on the owner's exact build

Through normal gameplay on Windows, with the owner's artifact and isolated data folders ([driver](driver/repro.ps1), screenshots in
[before/](before/)):

- No prompt and no caption at the boat or the fish, under English, German and Bangla.
- Walking and pausing worked, so input was reaching the game.

**The controller.** The missing connections are independent of the input device, so from the code, a controller would have got the same silence.
This was not observed with a controller.

## 4. The boxes in Settings: a separate defect, not the cause

`keyboard_get_label_from_physical` returns the letter on the player's layout, which under Bangla is a Bangla letter. The pixel font is ASCII-only,
so it drew boxes showing `09BE`, `09A1` and `09C0` for A, D and E ([before/07-bangla-settings.png](before/07-bangla-settings.png)). This has nothing to do
with Examine, which failed under English too.

**Fix:** a label the font cannot draw falls back to the key's name on a US keyboard. A letter the font can draw is still shown, so the
player's own layout is respected where possible.

## 5. The fix, and what stops it coming back

- The Hud connects itself in code, from an exported path ([D37](../../../decisions.md)).
- The integration suite also runs on the exported pack ([D38](../../../decisions.md)), and the export check now requires a prompt in the exported build.
- Putting the original bug back fails the export check while the source suite passes (review package, §11). That is the exact gap this closes.

## 6. After the fix: the same steps on the real Windows build

Artifact `dagon-windows` from CI run [41650858792](https://github.com/shamsuzzamansadi/dagon/actions/runs/41650858792), commit `8da9a2e`, SHA-256
`3914191ea0a4e8e419bd63fbb4ecdb168162b59bd863cee39b4d497314790a22`, which matched GitHub's digest. Isolated data folders, and input posted as window messages to the game
only. I looked at every screenshot in [after/](after/). The run's text output is in [windows-run-summary.txt](windows-run-summary.txt).

| Step | Result | Screenshots |
|---|---|---|
| Launch | Main menu. New Game focused, Continue disabled, "No saved game yet." | `01` |
| Controls, Credits, Settings from the main menu | All open and return | `02`–`04` |
| New Game | The save is written, and How to Play shows | `05` |
| Prompt and caption at the boat | `[E] Examine`, then the boat's caption | `06`, `07` |
| Prompt and caption at the fish | `[E] Examine`, then the fish's caption | `08`, `09` |
| Pause, Restart Checkpoint, then again at the boat | Prompt and caption both work | `10`–`12` |
| Rebind Interact to J | `[J] Examine`, no caption. E does nothing. J shows the boat's, then the fish's caption. | `13`–`17` |
| Controls from the pause menu | Shows J | `18` |
| Walk and hop to the checkpoint past the trench | "Checkpoint saved", and `save.dat` holds `beat=abyss checkpoint=PastTheTrench` | `19` |
| Quit to Main Menu | The confirmation says what is kept, with Cancel focused. Continue is focused afterwards. | `20`, `21` |
| Quit to Desktop | Exit code 0 | |
| Relaunch | Continue is focused, and Continue returns to the checkpoint. J has survived. Restart returns to the checkpoint. | `23`–`26` |
| **Bangla layout: the game's own thread read `F0C00845`,** and no layout request was sent | `[E] Examine`, the caption on E, and A, D, E in Settings with no boxes | `current-layout-*` |

**Limits of this run:**

- **The keys were window messages, not a physical keyboard.** That reaches the game's real input path, but says nothing about hardware.
- **German and English after the fix:** I sent layout requests in one run, but only recorded the layout of the window that had focus, which was not the game. So
  those two are not proven by a read-back. German's letters for A, D and E match English, so the font fallback does not come into it, and this is low risk.
  The owner's check under German closes it.
- **Controller:** nothing here pressed a controller. Controller input on this build is covered only by the suite on the exported pack, with
  injected events, on Windows CI, and by the owner's manual checks. The one real observation: with a controller attached to this machine, the
  driver reported `XInput Controller`, vendor 1118 (`0x045E`), and the game classified it as Xbox.

## 7. Side effects of this investigation, disclosed

- **The driver changed the machine's keyboard layout.** Posting a layout request to the game window changed the system-wide input language to Bangla during the first
  reproduction. I restored it and checked it then. A later run with that technique measured the wrong window, so it could not confirm a clean restore. Afterwards, the focused application read Bangla, and I
  cannot tell whether that was the owner's choice or this. I stopped sending layout requests, did not try to correct it, and reported it to the owner. The
  driver kept here sends none: [e2e-current-layout.ps1](driver/e2e-current-layout.ps1) only reads. [repro.ps1](driver/repro.ps1) is kept as it ran, so **do not rerun its layout loop on a machine in use.**
- **The owner's real settings were not touched.** Every run used isolated `APPDATA` and `DAGON_STORAGE_DIR` folders.
