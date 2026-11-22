# Displays: 1280 × 720 and 1920 × 1080, windowed and fullscreen (M6 plan, item 6)

**What ran:** `project/tests/capture_display.gd`, through the game's real menus, on a private X display of each size with a window manager (Openbox), using the editor's debug build of the branch's code, which is why the window's title says DEBUG. Scripted, not a person; **a look on the owner's own screens is still to come** ([native checks](../../../m6/native-checks/README.md)).

The route at each size: the title as the game opens; Settings; **Display** pressed for fullscreen; the menu walked by keys in fullscreen; back to the title; in the game, one of the longest captions (`abyss.relief`); **back to a window from the pause menu's Settings**; the caption again; the ending's longest line (`ending.innsmouth`, 222 characters). At each stage the run prints the window's mode, size and place, the screen's, the game's own picture size and the scale, and saves a screenshot of the whole screen ([1280 × 720 log](1280x720-display.log), [1920 × 1080 log](1920x1080-display.log)).

## Results

| | 1280 × 720 | 1920 × 1080 |
|---|---|---|
| **The game's own picture** | 480 × 270 at every stage | 480 × 270 at every stage |
| **Window, as the game opens** | 960 × 540, ×2, centred. The project's 1440 × 810 does not fit; the window manager had already squeezed it to 1278 × 695, which the game now replaces with the largest whole multiple that fits | 1440 × 810, ×3, centred: it fits, and is left as it is |
| **Fullscreen** | The whole screen; the picture ×2, 960 × 540, with black bars of 160 and 90 px: **2× with bars, the roadmap's first candidate** | The whole screen, ×4 exactly, no bars |
| **Pixel-art sharpness and shape** | In all 9 screenshots every 2 × 2 block of the picture is one colour, the picture is exactly 16:9, and the bars are black | In all 9, every 3 × 3 or 4 × 4 block is one colour, exactly 16:9 ([pixel check](pixel-check.txt), `tools/check_display_shots.py`) |
| **Settings** | Fits, the Display button with the rest; keys walk it in fullscreen, Display → Restore Defaults → Back and up again | The same |
| **Long captions** | `abyss.relief` on two lines in the caption box, in fullscreen and in a window; the ending's longest line on three lines in its card, with Continue below | The same, larger |
| **Back to a window** | From the pause menu's Settings: 960 × 540, centred, the button reading "Display: Windowed" | 1440 × 810, centred under its title bar |

Screenshots, by size and stage: `1280x720-01-title-window.png` to `-09-ending-longest-window.png`, and the same for `1920x1080`.

## How the game decides (D122)

- **Fullscreen** is the borderless kind: the screen keeps its own mode, so leaving it is instant. It is saved with the other settings, and Restore Defaults returns to a window.
- **The window** takes the largest whole multiple of 480 × 270, at most ×3, that fits the screen's usable area with its frame: when it does not fit; when it comes back from fullscreen; and, the first time in a run, when it is not a whole multiple, as a window manager may already have squeezed it. Later, a window the player has resized or maximized is left alone.
- The rule's arithmetic is plain C++ with native tests (`src/core/window_fit.cpp`); the setting has native and integration tests.

## Not checked here

Windows' display scaling above 100 %, a second monitor, a real GNOME or Windows desktop: those are in the owner's [native-check sheets](../../../m6/native-checks/README.md). Exclusive fullscreen is not offered.
