# DAGON: Beneath the Black Tide

A short 2D cinematic horror game for [GitHub Game Off 2026](https://itch.io/jam/game-off-2026)
(theme: SHIFT). A shipwrecked sailor wakes on a stretch of seabed that should be
under the ocean. Godot 4.7 with gameplay in C++20 through GDExtension.

**Status: M1 and M2 are accepted by the owner, with documented deferrals. M3 is implemented and awaiting independent follow-up review. It is not accepted by the owner,** who has played it and found it functional but too brief, too passive and not atmospheric enough ([record](docs/evidence/m3/owner-playtest-2026-11-09.md)). A revision answering that is on the M3 branch. The game opens on a main menu, with New Game, Continue
from one checkpoint save, Settings with key rebinding, Controls and Credits. New Game begins with a short, skippable prologue. Play starts on the Shore, in its accepted art direction: a
sailor you can walk and jump with, on exposed seabed beside a stranded boat, with the sea far off. You can examine things, pause, and
use a controller, with buttons named for the device in use.

On the M3 branch, the whole route can be played: the prologue, Shore, Exposed Abyss, Monolith, Witness, the escape and the ending. There are clue tablets, side routes, a slab to bring down across a gap, a distant ritual, a three-stone puzzle, placeholder cinematics,
the sea coming back after you in the escape, a save at each checkpoint, and optional controller vibration. **The Shore and the stretch from the cave entrance to the first tablet are finished art. Past x = 1440 it is unfinished greybox,** a stated boundary. The cinematics are placeholders. **There is a first sound pass across the route: ambience, footsteps, effects, breathing and music in four places. It is synthesized, not final, and has not been listened to by the developer.** Three narration lines have an AI voice for the owner's audition, not approved; the rest of the
narration is captions. It is shorter than the finished game is meant to be. See
[docs/roadmap.md](docs/roadmap.md), [docs/reviews/m3-review-package.md](docs/reviews/m3-review-package.md) and [docs/shore-preview.md](docs/shore-preview.md).

## Play the current build

Nothing is released yet. Milestone prereleases will appear under [Releases](https://github.com/shamsuzzamansadi/dagon/releases) when they pass their gates ([docs/release.md](docs/release.md)). Until then, builds come from CI, and downloading them needs a GitHub account.

1. Open the [CI runs for `main`](https://github.com/shamsuzzamansadi/dagon/actions/workflows/ci.yml?query=branch%3Amain)
   and choose the newest run with a green check.
2. Under **Artifacts**, download `dagon-windows` (or `dagon-linux`).
3. Extract the whole zip into one folder. The files must stay together.
4. **Windows:** run `dagon.exe`. The build is not code-signed, so SmartScreen may warn you; choose
   **More info**, then **Run anyway**. **Linux:** run `chmod +x dagon.x86_64`, then `./dagon.x86_64`.

The game opens in a 1440×810 window, on the main menu: choose **New Game**, or **Continue** to carry on
from your last checkpoint. To quit, close the window, or use **Quit to Desktop**.

## Controls

| Action | Keyboard | Xbox controller | PlayStation controller | Other controllers |
|---|---|---|---|---|
| Walk | A / D, ← / → | Left stick, D-pad | Left stick, D-pad | Left stick, D-pad |
| Jump | Space | A | Cross | Bottom face button |
| Examine, when a prompt shows. Again, to skip what is being said | E | X | Square | Left face button |
| Pause | Esc | Menu | Options | Start |
| Menus: move | Arrow keys | Left stick, D-pad | Left stick, D-pad | Left stick, D-pad |
| Menus: confirm | Enter, Space | A | Cross | Bottom face button |
| Menus: back | Esc | B | Circle | Right face button |

The controller columns are the same physical buttons, by position. The prompt and the Controls screen use the names for the
device you are using, and an unrecognized controller is described by position.

In Settings you can change the keyboard keys for walking, jumping and examining. The Left and Right arrows always move
and Esc always pauses. Controller buttons are fixed. Narration has its own volume, and subtitles and controller vibration can each be switched off. They are on by default. The Music and Effects sliders are saved and set on their own buses, ready
for the audio planned in M4 and M5. The only audio so far is three narration samples, and Settings says so.

All of this is checked by automated tests with simulated input for each layout. In human tests, A, D, the Left and Right arrows and
Space have worked, and the owner reports that the Xbox controller controls they tried worked, without listing them. Individual Xbox
actions are not recorded as passed, and all PlayStation hardware is still untested. Both stay deferred to M6. Testing a controller on Windows says nothing about Xbox or PlayStation console platforms,
which are not targets.

## Scenes

| Scene | Use |
|---|---|
| `project/scenes/ui/title.tscn` | **Entry scene:** the main menu, which is what the standard build opens. |
| `project/scenes/level/game.tscn` | The session: the world, which it can replace, and the pause menu. |
| `project/scenes/level/shore.tscn` | The world: all four acts, despite the name. Art from x = 0 to 640, greybox from there to x = 4544. |
| `project/scenes/ui/ending.tscn` | The epilogue, line by line, and the credits, which lead back to the main menu. |
| `project/narration/script.txt` | Every spoken line and its caption, by line ID. The one source for both. |
| `project/scenes/level/level.tscn` | M1's movement test scene, with the same collision up to x = 980. Not exported. Run it with `godot --path project res://scenes/level/level.tscn`, or open it in the editor. |

The art is regenerated by `python tools/art/generate.py`, which needs Pillow.

## Build from a clean checkout

You need Git, Python 3, Godot **4.7.2-stable**, and a C++20 compiler. Versions
and the reasoning behind them are in [docs/toolchain.md](docs/toolchain.md).

### Linux (GCC 11 or newer)

```sh
git clone --recurse-submodules https://github.com/shamsuzzamansadi/dagon.git
cd dagon
python3 -m venv .venv && .venv/bin/pip install scons==4.9.1
.venv/bin/scons platform=linux target=template_debug
.venv/bin/scons platform=linux target=template_release
.venv/bin/scons unit_tests
sh tools/prepare_project.sh
```

### Windows (Visual Studio 2022 with C++ tools)

```bat
git clone --recurse-submodules https://github.com/shamsuzzamansadi/dagon.git
cd dagon
py -m venv .venv
.venv\Scripts\pip install scons==4.9.1
.venv\Scripts\scons platform=windows target=template_debug
.venv\Scripts\scons platform=windows target=template_release
.venv\Scripts\scons unit_tests
powershell -ExecutionPolicy Bypass -File tools\prepare_project.ps1
```

If the build prints `g++` rather than MSVC, SCons did not detect Visual Studio and
fell back to MinGW. SCons 4.9.1 detects VS 2022 but not VS 2026. Add `require_msvc=yes`
to make that an error.

**Run the prepare script before opening the project in Godot for the first
time.** It works around a crash seen on a clean cache (details in
[docs/toolchain.md](docs/toolchain.md) §5). Then open `project/project.godot`
in Godot, or run it directly:

```sh
godot --path project
```

## Run the checks

These scripts are used both locally and in CI. On Windows, run them from Git
Bash. `GODOT` is the path to the Godot 4.7.2 executable (on Windows, the
`_console.exe` one). `tools/install_godot.sh` can fetch it, verified by checksum.

```sh
GODOT=/path/to/godot sh tools/run_godot_checks.sh    # import, extension load, integration, smoke on both scenes
python tools/art/check_art.py                        # palette, foot sliding, drawn ground on the collision
sh tools/install_export_templates.sh                 # 1.28 GB download, SHA-512 verified
GODOT=/path/to/godot sh tools/export_check.sh linux  # or: windows
python3 tools/route_check.py build/export/linux/dagon.x86_64 build/logs/route --display :77  # on a private X display: docs/toolchain.md
```

Logs go to `build/logs/`, with a separate stdout, stderr and exit status for
each step. These scripts give every Godot process one unique storage folder, so they cannot touch your own
settings or save. The test runner refuses to start without one: to run it by hand, set `DAGON_STORAGE_DIR` to a folder
whose path contains `dagon-test-`.

## How this was made

- **AI-assisted development.** The source code, tests, CI and documents are
  written mainly by Claude (Anthropic) through Claude Code, under the project
  owner's direction. The Shore's pixel art is drawn by Python scripts that Claude
  wrote and tuned, with no image generators or third-party art. ChatGPT (OpenAI)
  acts as an independent reviewer. The owner makes the decisions and does the
  playtesting. Details: [docs/jam.md](docs/jam.md) §5.
- **Before the jam.** Planning documents and a toolchain probe were written on
  2026-10-28, and the empty repository was created that day. No game code was
  written before the jam started (log: [docs/jam.md](docs/jam.md) §6).
- **Starting point.** The build files derive from the official
  [godot-cpp-template](https://github.com/godotengine/godot-cpp-template).

## License

Code is under the [MIT License](LICENSE). Original game assets are under CC BY
4.0. Third-party components and asset provenance are listed in
[CREDITS.md](CREDITS.md).
