# DAGON: Beneath the Black Tide

A short 2D cinematic horror game for [GitHub Game Off 2026](https://itch.io/jam/game-off-2026)
(theme: SHIFT). A shipwrecked sailor wakes on a stretch of seabed that should be
under the ocean. Godot 4.7 with gameplay in C++20 through GDExtension.

**Status: M1 foundation.** A small greybox you can walk and jump in. There is no
interaction, story, puzzle or final art yet. See [docs/roadmap.md](docs/roadmap.md).

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Walk | A / D, ← / → | Left stick, D-pad |
| Jump | Space | South button (A / Cross) |

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
GODOT=/path/to/godot sh tools/run_godot_checks.sh    # import, extension load, integration, smoke
sh tools/install_export_templates.sh                 # 1.28 GB download, SHA-512 verified
GODOT=/path/to/godot sh tools/export_check.sh linux  # or: windows
```

Logs go to `build/logs/`, with a separate stdout, stderr and exit status for
each step.

## How this was made

- **AI-assisted development.** The source code, tests, CI and documents are
  written mainly by Claude (Anthropic) through Claude Code, under the project
  owner's direction. ChatGPT (OpenAI) acts as an independent reviewer. The owner
  makes the decisions and does the playtesting. Details:
  [docs/jam.md](docs/jam.md) §5.
- **Before the jam.** Planning documents and a toolchain probe were written on
  2026-10-28, and the empty repository was created that day. No game code was
  written before the jam started (log: [docs/jam.md](docs/jam.md) §6).
- **Starting point.** The build files derive from the official
  [godot-cpp-template](https://github.com/godotengine/godot-cpp-template).

## License

Code is under the [MIT License](LICENSE). Original game assets are under CC BY
4.0. Third-party components and asset provenance are listed in
[CREDITS.md](CREDITS.md).
