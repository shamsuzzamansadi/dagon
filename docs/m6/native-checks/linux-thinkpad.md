# Native check: Ubuntu ThinkPad

**Build:** `dagon-linux`, SHA-256 ____________________ (commit ________). **Date:** ________

## 1. The machine

In a terminal, and paste the output:

```
lsb_release -ds; uname -r; echo "$XDG_SESSION_TYPE"
lspci | grep -i -E 'vga|3d|display'
glxinfo -B 2>/dev/null | grep -E 'OpenGL renderer|OpenGL version'   # sudo apt install mesa-utils, if missing
```

## 2. Get it and start it from a terminal

```
sha256sum dagon-linux.zip            # must equal the build's SHA-256
mkdir dagon && cd dagon && unzip ../dagon-linux.zip && chmod +x dagon.x86_64
./dagon.x86_64 --print-fps 2>&1 | tee dagon-linux-run.log
```

`--print-fps` only prints one frame-rate reading a second to the log. The game also keeps its own log at `~/.local/share/godot/app_userdata/DAGON- Beneath the Black Tide/logs/godot.log`.

**Hardware rendering:** near the top of `dagon-linux-run.log` Godot names the device it draws with ("Using Device: …"). **If it says `llvmpipe`, the run is software rendering, not the check,** and please say so.

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
| Fullscreen on, from Settings → Display: sharp, the right shape, bars if needed rather than stretched | | |
| A long caption (examine anything with a long description) fits, readable | | |
| Menus navigable with keys in fullscreen | | |
| Back to windowed, from Settings → Display again (or the pause menu's Settings): the window returns at a sensible size, centred, nothing off-screen | | |

To try 1280 × 720 on a larger screen, set the display's resolution in Settings → Displays, then put it back.

## 5. Send

This sheet, `dagon-linux-run.log`, and anything that looked wrong, with the time it happened.
