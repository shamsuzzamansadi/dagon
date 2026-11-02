# Toolchain, Dependencies and Build Plan

First verified 2026-10-28; updated at M1 (2026-11-02). Each item says how it was verified. "Unverified" items
have a named validation step.

## 1. Pinned versions

| Component | Pin | Verification |
|---|---|---|
| Godot engine | **4.7.2-stable** (released 2026-08-18) | GitHub releases API: newest stable 4.x. Installed locally: `godot --version` → `4.7.2.stable.official.ed1daf0bf`. |
| godot-cpp | **10.0.0-stable**, commit `507ed9d840c01a3c5b2a39af8bb4000bfac30bf5` | Tag ref through the GitHub API. This is the same commit the official template's submodule points to. |
| GDExtension API target | `api_version=4.7`, `compatibility_minimum = "4.7"` | `tools/godotcpp.py` at the pin: `supported_api_versions = ["4.3" … "4.7"]`. `gdextension/extension_api-4-7.json` is present. |
| Project template | godot-cpp-template @ `d36f9d03e9e0` (2026-10-04) | Layout and SConstruct read from GitHub. |
| SCons | **4.9.1** (pip) | Built the spike locally. The template CI action defaults to 4.4.0, so we override it to 4.9.1. |
| Python | 3.x (3.13 local) | Needed only for SCons. |
| Linux compiler | GCC 13.3 (Ubuntu 24.04, local). CI: see the M1 package | The real project builds and loads. Clang 18 is available but untested. |
| Windows compiler | **MSVC 2022 (19.44.35229 observed), on the pinned `windows-2022` runner** | `windows-2025` was tried first: it ships MSVC 19.51 (VS 2026), which SCons up to 4.9.1 does not detect, and godot-cpp then **silently falls back to MinGW**. A CI matrix confirmed this on 2026-11-02. CI now builds with `require_msvc=yes`, which fails instead of falling back. Results are in the M1 review package. |
| Unit-test framework | doctest **v2.5.3** (single header, vendored) | GitHub releases API. |
| Export templates | 4.7.2 `.tpz` (1.28 GB) | **Downloaded 2026-11-02; official SHA-512 verified** (`tools/install_export_templates.sh`). Only the desktop templates are kept. |
| Emscripten (web, stretch) | 3.1.62 (template's pin) | Not evaluated. See §6. |

godot-cpp has been **versioned independently** of Godot since v10.
"godot-cpp 10" says nothing about which Godot it targets. That comes from
`api_version`.

## 2. C++ standard

godot-cpp hard-codes C++17 (`tools/common_compiler_flags.py`: `-std=c++17` or
`/std:c++17`). We compile **our** sources as C++20 in a cloned environment, and
godot-cpp's static library stays C++17:

```python
env = SConscript("godot-cpp/SConstruct", {"api_version": "4.7"})
own = env.Clone()
own.Replace(CXXFLAGS=[f for f in own["CXXFLAGS"] if f not in ("-std=c++17", "/std:c++17")])
own.Append(CXXFLAGS=["/std:c++20"] if own.get("is_msvc", False) else ["-std=c++20"])
```

**Evidence (Linux/GCC 13.3):** a throwaway spike with a `Node` subclass that
used `std::span`, a `std::integral` concept and designated initializers built
cleanly against godot-cpp 10.0.0 / api 4.7 (`template_debug` and
`template_release`, 0 warnings). It loaded in headless Godot 4.7.2: class
registered, bound method returned the expected value, signal present, and
`__cplusplus == 202002`.

**Status (reviewer, round 2):** conditionally accepted for M1 validation.
**It is not certified as ABI/ODR-safe in general.**

- **Shared-header check (done 2026-10-28):** godot-cpp's public headers
  (`include/`, `gen/include/`) contain no code that depends on
  `__cplusplus` or `_MSVC_LANG`. The only standard check is
  `static_assert(__cplusplus >= 201703L)`. The standard library's own headers
  still differ between `-std` modes. That is the residual risk, mitigated by
  using one compiler and toolset per build.
- **Consistency by construction:** our env is a `Clone()` of godot-cpp's, so
  every other flag is identical: runtime library (`use_static_cpp`), debug and
  optimisation settings, defines. Only the `-std` flag differs.
- **Validated on MSVC 19.44.35229 in CI (latest: run `41412946061`):** debug and release builds,
  `/MT` on both sides, extension loading in the Windows editor (debug library), and in the
  exported game (release library). Accepted by the reviewer for the tested compiler
  configurations; not a universal ABI guarantee.
- A `static_assert(__cplusplus >= 202002L)` in one source file catches a
  silent fallback. MSVC needs `/Zc:__cplusplus`, which godot-cpp already adds.

## 3. Build commands

Linux:
```sh
git clone --recurse-submodules https://github.com/shamsuzzamansadi/dagon.git && cd dagon
python3 -m venv .venv && .venv/bin/pip install scons==4.9.1
.venv/bin/scons platform=linux target=template_debug   -j$(nproc)
.venv/bin/scons platform=linux target=template_release -j$(nproc)
.venv/bin/scons unit_tests            # native doctest binary, runs the tests
sh tools/prepare_project.sh           # before the first Godot launch
```

Windows (x64 Native Tools prompt, VS 2022; with VS 2026, SCons 4.11.1 is needed for
detection, which we have not validated end to end):
```bat
py -m venv .venv && .venv\Scripts\pip install scons==4.9.1
.venv\Scripts\scons platform=windows target=template_debug
.venv\Scripts\scons platform=windows target=template_release
.venv\Scripts\scons unit_tests
```

`unit_tests` is a separate SCons environment that compiles `src/core/*.cpp` and
`tests/unit/*.cpp` with C++20 and no godot-cpp, under `-Werror` or `/WX`.
`show_flags=yes` prints the exact compiler version and effective flags.
Set `SCONS_CACHE` to a directory to reuse objects between clean builds.

A full godot-cpp build takes 86 s wall-clock on 12 cores (spike). CI uses
godot-cpp's cache actions.

## 4. Library layout

```
project/bin/dagon.gdextension
project/bin/linux/libdagon.linux.template_{debug,release}.x86_64.so
project/bin/windows/dagon.windows.template_{debug,release}.x86_64.dll
```

Single precision only, x86_64 only. The editor loads the `template_debug`
library: the spike's `.gdextension` had only `debug`/`release` keys and the
4.7.2 editor loaded it. We do not ship a separate `editor` target.

## 5. Known toolchain issue: clean-cache import crash (provisional workaround)

The full evidence, commands and logs are in
[evidence/import-crash/](evidence/import-crash/README.md).

**Observed on the probe** (`docs/evidence/import-crash/`, a throwaway project
with one `Node` subclass):
- On a clean `.godot/`, with the extension present, `godot --headless --import`
  exited 134 in 12 of 12 trials (5 manual, 3 via `reproduce.sh`, and 4 as same-day
  controls on 2026-11-02).
- Under gdb the first fatal event is a SIGSEGV inside the stripped engine
  binary. A signal handler in the binary then calls `abort()`, so the shell
  sees 128 + SIGABRT(6) = 134. Godot wrote nothing to stderr.
- Pre-seeding `.godot/extension_list.cfg` prevented the crash in 9 of 9 trials.
- The crash persisted when each of these was changed on the probe: renderer,
  `config/features`, main scene, export presets, all scripts and scenes removed.

**Observed on the actual game project (2026-11-02,
[evidence/m1/import/](evidence/m1/import/README.md)):**
- **A fresh clone crashes the same way:** 6 of 6 clean-cache imports **without**
  preparation exited 134. With it, 3 of 3 exited 0, and the real checks then pass.
- The one exception is the working copy on `/mnt/c`, which exited 0 even when
  unprepared. An early note in commit `b94e742` wrongly generalized from that.

**Not established:**
- The root cause. The filesystem alone does not explain the exception, because the
  probe crashes on `/mnt/c` too. An engine-only stack does not rule out corruption
  caused by an extension, though the crash now occurs with two different ones.
- Behaviour on Windows and in interactive editor sessions.
- No upstream issue has been filed yet; the fresh-clone reproduction is a good
  basis for one. A debug-symbol engine build would make it far more useful.

**Provisional workaround, used identically for local clean checkouts and CI.**
It is run once after cloning, before the first Godot launch.

`tools/prepare_project.sh`:
```sh
#!/usr/bin/env sh
# Pre-seed Godot's extension list before the first import (docs/toolchain.md §5).
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/project/.godot"
printf 'res://bin/dagon.gdextension\n' > "$root/project/.godot/extension_list.cfg"
```

`tools/prepare_project.ps1`:
```powershell
# Pre-seed Godot's extension list before the first import (docs/toolchain.md §5).
$root = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force "$root\project\.godot" | Out-Null
[IO.File]::WriteAllText("$root\project\.godot\extension_list.cfg", "res://bin/dagon.gdextension`n")
```

`.godot/` stays generated and untracked. The scripts only write this one file.

**CI policy:** run the prepare script, then **one** import. **Any** non-zero
exit fails the job. Both stdout and stderr are kept as artifacts. The M1
review package will include the script, the commands, the debugger output and
the results again, re-run on the real project.

## 6. Export requirements

- Desktop export needs the 4.7.2 export templates (`linux_release.x86_64`,
  `windows_release_x86_64.exe`, …) under
  `~/.local/share/godot/export_templates/4.7.2.stable/`. CI downloads and
  caches the `.tpz` and checks it against `SHA512-SUMS.txt` from the release.
- `export_presets.cfg` is **hand-written and committed**. M1 corrected the earlier
  claim that the editor must generate it: a preset with `include_filter` and
  `exclude_filter` plus the options we set is accepted, and Godot uses defaults
  for the rest. `exclude_filter="tests/*"` keeps tests out, and
  `tools/export_check.sh` checks the `.pck` for that.
- CI exports each platform on its own runner, so cross-export from Linux is not
  used or validated. `application/modify_resources=false`, so the Windows exe has
  no custom icon or metadata yet (M7).
- Godot bundles the GDExtension library for the target platform. Validated on both
  OSes by `tools/export_check.sh`: the exported game runs headless and must print the
  `build=release` proof line, exit 0, with no ERROR lines.
- Web (stretch only): GDExtension on web needs the web build of the library
  (`*.web.template_release.wasm32.nothreads.wasm`) and extension support in
  the web export. Not evaluated. Time-boxed to half a day after M6, and only if
  the jam allows.

## 7. Useful verified CLI flags (Godot 4.7.2 `--help`)

`--headless`, `--import`, `--script <path>` (editor/debug builds only),
`--quit-after <n>` (available in release templates), `--fixed-fps <fps>`
(deterministic frame stepping for integration tests),
`--export-release/--export-debug <preset> <path>`, `--dump-extension-api`.
