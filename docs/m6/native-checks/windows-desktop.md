# Native check: Windows desktop

**Build:** `dagon-windows`, SHA-256 ____________________ (commit ________). **Date:** ________

## 1. The machine

Windows version (Settings → System → About), the graphics card (Device Manager → Display adapters), and the screen's resolution and scaling (Settings → System → Display).

## 2. Get it and start it

In PowerShell, in the folder with the zip:

```
Get-FileHash dagon-windows.zip      # must equal the build's SHA-256
Expand-Archive dagon-windows.zip -DestinationPath dagon
.\dagon\dagon.exe --print-fps
```

If Windows says it protected your PC: **More info**, then **Run anyway** (the game is not signed). `--print-fps` only adds one frame-rate reading a second to the game's log, which is at:

`%APPDATA%\Godot\app_userdata\DAGON- Beneath the Black Tide\logs\godot.log`

Near its top Godot names the graphics device it draws with ("Using Device: …"). **Please keep your keyboard layout as it is;** the German key labels are checked separately, in CI.

## 3. Play and note

| Check | What should happen | Result (ok / not, and what you saw) |
|---|---|---|
| The main menu | Appears; keys or mouse move through it | |
| New Game | How to Play, then the prologue, which Esc can skip | |
| A few minutes of play | Walking, jumping, examining; no stutter you notice | |
| Pause | Esc pauses and resumes; sound stops while paused | |
| Settings | A volume change is heard and kept after closing Settings | |
| Quit, and start again | Quit from the pause menu to the main menu and then the desktop; start the game again; **Continue** returns to the last checkpoint | |
| The reveal, if you play that far | Smooth; no visible jump | |

## 4. Displays

| Check | 1280 × 720 | 1920 × 1080 |
|---|---|---|
| The window opens fitting the screen, sharp pixels, no stretching | | |
| Fullscreen on, from Settings: sharp, the right shape, bars if needed rather than stretched | | |
| A long caption (examine anything with a long description) fits, readable | | |
| Menus navigable with keys in fullscreen | | |
| Back to windowed: the window returns at a sensible size, nothing off-screen | | |

To try 1280 × 720 on a larger screen, set the display's resolution in Settings → System → Display, then put it back. Windows' display scaling above 100% changes the window's size on screen: please note your scaling.

## 5. Send

This sheet, the `godot.log` from that run (copy it before starting the game again, which starts a new one), and anything that looked wrong, with the time it happened.
