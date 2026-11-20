# Controller check: Xbox and PlayStation (M6 plan, item 4)

For whoever has the controller: the owner, or someone the owner asks. **Every result stays pending until someone tests the actual hardware,** and only what is written in this sheet is recorded as checked. M2's manual check is the base ([M2 package](../../reviews/m2-review-package.md) §8); its rows X1 to X18 are kept, with their numbers.

**Build:** `dagon-windows` or `dagon-linux`, SHA-256 ____________________ (commit ________). **Date:** ________

**Controller(s):** model and how connected (USB or Bluetooth), Windows or Linux: ____________________

Buttons by position. **Xbox:** A (bottom), B (right), X (left), Y (top), Menu, View. **PlayStation:** Cross (bottom), Circle (right), Square (left), Triangle (top), Options, Create/Share.

Start with the controller connected and a fresh game if you can (no save), keyboard untouched.

## Menus, prompts and play

| # | Where | Press | What should happen | Xbox | PlayStation |
|---|---|---|---|---|---|
| X1 | Main menu | Left stick down, then D-pad down | The highlight moves one item each | | |
| X2 | On Controls | Bottom (A / Cross) | Controls opens; the controller section reads Jump: A / Cross, Examine: X / Square, Pause: Menu / Options, and bottom to confirm, right for Back | | |
| X3 | Controls | Right (B / Circle) | Back on the main menu, Controls highlighted | | |
| X4 | On New Game | Bottom. If it asks about replacing your save: D-pad right, then bottom | How to Play shows **only** the controller section, naming your controller's buttons | | |
| X5 | Begin | Bottom | The prologue starts; **right (B / Circle) skips it**; play starts and the sailor does **not** jump | | |
| X6 | Beside the boat | Nothing | The prompt reads **`[X] Examine`** (Xbox) or **`[Square] Examine`** (PlayStation) | | |
| X7 | Beside the boat | Left (X / Square) | The boat's line, spoken, with its caption | | |
| X8 | Walk right to the next thing | Left stick, then left button | The prompt stays your button; the next line | | |
| X9 | Anywhere | Bottom | The sailor jumps, with no line | | |
| X10 | Beside something | Top, both shoulder buttons, View / Create | Nothing happens | | |
| X11 | Playing | Menu / Options | Pauses, with Resume highlighted | | |
| X12 | Paused | Bottom on Resume. Then pause and press Menu / Options. Then pause and press right | Each resumes, with no jump and no line | | |
| X13 | Paused | Left | Nothing happens, and no line afterwards | | |
| X14 | Beside the boat | A keyboard key, then a controller button | The prompt switches to your key, then back to your button | | |
| X15 | Pause → Settings, on **Examine** | Bottom, read the message, then right | "Press a key for Examine. Esc or B cancels." (Circle on PlayStation); right cancels only the capture, and a second right leaves Settings | | |
| X16 | Paused, on Quit to Main Menu | Bottom, then right | The confirmation has Cancel highlighted, and right cancels it | | |
| X17 | Beside the boat | **Unplug it or switch it off,** while walking if you can | The prompt becomes your key, the game does not pause, and **the sailor does not keep walking** | | |
| X18 | After X17 | Reconnect, wait, then press a button | The prompt stays on your key until you press, then reads your button; left examines | | |

## Vibration, by feel (M6)

With Settings → Controller vibration **On** (the default). Each is a short shudder, under a second, never a long rumble.

| # | Moment | What should happen | Xbox | PlayStation |
|---|---|---|---|---|
| V1 | The stones solved and the gate opening | A light shudder | | |
| V2 | The reveal, about 7 seconds into it | A stronger one | | |
| V3 | The collapse at the end of the run | A shudder | | |
| V4 | The reveal and the collapse again with Settings → Controller vibration **Off** (Continue from the main menu resumes just before the reveal) | Nothing | | |

## The ending

| # | Where | Press | What should happen | Xbox | PlayStation |
|---|---|---|---|---|---|
| E1 | The ending's card, when Continue shows | Bottom | On to the credits | | |
| E2 | Credits | Bottom on Main Menu | The main menu; your controller still works there | | |
| E3 | The ending's card | Right | Nothing (there is nowhere to go back to) | | |

## Send

This sheet, and for anything marked not ok: what you pressed, what happened, and roughly when. **Simulated input in the tests is not a hardware check:** those tests rerun on every commit (`test_controller.gd`, with the driver's name stood in for, D41) and are recorded separately.
