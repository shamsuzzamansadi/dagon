# Key names under the German layout, on the shipped Windows build (M6 plan, item 5)

**Deferred since M2** ([D44](../../../decisions.md)): key names under German on the real build, left unverified because the owner asked to keep layout changes off their active desktop. **Checked here on a throwaway CI runner instead, never on a person's desktop.** Automated: window messages to the game's window, not a person's keyboard. A real German keyboard stays the owner's choice.

**What ran:** `tools/layout_check.py`, in CI's job on `77d5302`, push run [44786112032](https://github.com/shamsuzzamansadi/dagon/actions/runs/44786112032), on `windows-2022`, against that run's own `dagon-windows` export. The game drew through ANGLE on Microsoft's software renderer ("Microsoft Basic Render Driver"), on the runner's 1024 × 768 desktop, where the window opened fitted at 960 × 540.

**How:** the game starts with its keys moved onto keys whose letters differ between the layouts: Move Left on the key a US keyboard calls Z, Jump on its semicolon key, Examine on its Y, Move Right left on D (a settings file written before the launch). Then the script asks the game's own window to change its input language, as the language bar does (`WM_INPUTLANGCHANGEREQUEST`), and reads the language back from the game's thread before going on. Then Settings from the main menu, the main menu's Controls, How to Play, the first prompt at the boat, and the pause menu's Settings and Controls, each screenshotted. The game logs the key names Settings shows and the layout it read them through, and the prompt's text, so the check compares text, not pixels. **US first, as the control, then German.**

## Results

| | US (the control) | German |
|---|---|---|
| The game's thread, as read back | `0x0409` | **`0x0407`**, switched from `0x0409` |
| Settings, main menu and pause menu: Move Left, Move Right, Jump, Examine | Z, D, Semicolon, Y, "US (en)" | **Y, D, Ö, Z**, "German (de)" |
| The first prompt | [Y] Examine | **[Z] Examine** |
| How to Play and both Controls screens | "Walk: Z and D", "Jump: Semicolon", "Examine: Y" | **"Walk: Y and D", "Jump: Ö", "Examine: Z"** (screenshots) |
| The taskbar's language | none shown (one input language) | **DEU** |
| Result | `LAYOUT_RESULT layout=us failed=0` | `LAYOUT_RESULT layout=de failed=0` |

Screenshots `us-01-settings.png` to `us-06-controls-pause-menu.png` and the same for `de`; the check's own notes in `us-route.log` and `de-route.log`. In the CI console the Ö shows as a replacement character, an encoding of the console only: the game's log holds `Y D Ö Z`, and the check compared it.

**These screenshots predate [D124](../../../decisions.md):** Settings' row still reads "Interact" in them; it now reads "Examine", as every other screen does.

## Linux

The same check runs on the exported Linux build in CI and passed for US here and on the runner. **German could not be set on Linux:** Xvfb, on the developer's machine and on GitHub's runner alike, reports `setxkbmap`'s change as made and keeps the US keymap, as an uploaded keymap does too; the check saw that and failed, as it should. So on Linux CI runs only the US control. The naming rule itself is the same code on both platforms, with layouts simulated in `test_settings`.
