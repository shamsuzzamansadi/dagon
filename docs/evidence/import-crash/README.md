# Evidence: headless import crash on a clean cache (Godot 4.7.2)

> **Update 2026-11-02:** the actual game project does **not** show this crash,
> while this probe still does when re-run the same day. See
> [docs/evidence/m1/import/](../m1/import/) and `docs/toolchain.md` §5. Everything
> below describes the probe only.

Collected on 2026-10-28, before the jam, as a toolchain check. `spike/` holds
the throwaway probe that produced it. The probe is **not part of the game**
and is not built by the project's SConstruct.

## Environment

- WSL2, kernel 6.6.87.2-microsoft-standard-WSL2, Ubuntu 24.04, GCC 13.3.0
- Godot `4.7.2.stable.official.ed1daf0bf`, official Linux binary (stripped)
- godot-cpp 10.0.0-stable `507ed9d`, `api_version=4.7`, SCons 4.9.1
- Probe: one `Node` subclass compiled as C++20, plus `spike.gdextension`
  (`compatibility_minimum = "4.7"`, `reloadable = false`)

## Package layout

```
spike/SConstruct             builds src/*.cpp into project/bin/ (C++20 over godot-cpp's C++17)
spike/src/                   spike.hpp, spike.cpp, register_types.cpp
spike/project/               project.godot, check.gd, main.gd, main.tscn, export_presets.cfg
spike/project/bin/spike.gdextension
reproduce.sh                 full reproduction (below)
results-2026-10-28/          output of one reproduce.sh run
gdb-segv-then-abort.log      debugger session
clean-import-*.log           the original combined-output logs
```

`godot-cpp/` is not included. `reproduce.sh` clones it at the pinned commit
and verifies the hash.

**Layout note:** the package holds the probe as it was **after** the export
attempt, with `main.gd`, `main.tscn`, `export_presets.cfg` and
`run/main_scene` in `project.godot`. The first four trials in the table below
ran before those files existed. The fifth, both gdb sessions, the pre-seeded
trials and the `reproduce.sh` run all used this exact layout.

## Reproduction

```sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 \
  sh docs/evidence/import-crash/reproduce.sh /tmp/empty-dir 3
```

For each trial it records stdout, stderr and the exit status in separate files
(`<trial>.stdout`, `.stderr`, `.exit`).

**Run on 2026-10-28** (same environment; results in `results-2026-10-28/`):

| Trial | Exit | stderr |
|---|---|---|
| clean-1..3 | 134, 134, 134 | `Aborted (core dumped)`, the message printed by the invoking `sh` for a SIGABRT death. **Godot itself wrote nothing to stderr.** |
| preseeded-1..3 | 0, 0, 0 | empty |
| check.gd after pre-seeded import | 0 | empty; stdout: `class_exists=true`, `sum_steps=9 __cplusplus=202002 has_signal=true` |

The earlier interactive trials ran under zsh, which does not write that
message into the redirected file. That is why those stderr captures were
empty.

## Observed results (manual trials before the script existed)

| Condition | Trials | Exit codes |
|---|---|---|
| Clean `.godot/`, extension present (outside debugger) | 5 (separate runs, same day; one with `--verbose`) | 134, 134, 134, 134, 134 |
| Same, under gdb | 2 | SIGSEGV then SIGABRT (see below) |
| Clean `.godot/`, extension file moved away | 1 | 0 |
| Second import on a populated `.godot/` | 1 | 0 |
| Clean `.godot/` pre-seeded with `extension_list.cfg` (below) | 3 | 0, 0, 0 |
| After a pre-seeded import: `--script res://check.gd` | 1 | 0 (class registered, `sum_steps=9`, `__cplusplus=202002`) |

Pre-seeding used:
```sh
mkdir -p project/.godot
printf 'res://bin/spike.gdextension\n' > project/.godot/extension_list.cfg
```

## Debugger output

The full log is `gdb-segv-then-abort.log`. Command:
```sh
gdb -batch -ex "handle SIGSEGV stop print pass" -ex "handle SIGABRT stop print" \
    -ex run -ex "bt 6" -ex continue -ex "bt 12" -ex continue \
    --args Godot_v4.7.2-stable_linux.x86_64 --headless --path project --import
```

1. The first fatal event is **SIGSEGV on thread 1** at `0x1c7ae9f`. Every frame
   is inside the stripped Godot binary, and there is no symbol for any frame.
2. With the signal passed on, an in-binary handler (`0x4fa292`, called on top
   of the faulting frames via `<signal handler called>`) calls `abort()`, which
   raises **SIGABRT**.
3. 134 = 128 + 6 (SIGABRT). This is the exit code the shell reports. That
   resolves the earlier SIGSEGV-versus-134 discrepancy.
4. The handler wrote **nothing to stderr** in the non-debugger run (stderr
   was empty).

## What this does and does not show

- **Supported:** a clean-cache headless import with this extension present
  crashed in 8 of 8 trials (5 manual, 3 scripted). Pre-seeding
  `extension_list.cfg` prevented the observed crash in 6 of 6 (3 manual,
  3 scripted).
- The debugger log supports the SIGSEGV → handler → `abort()` → 134 chain.
  The reviewer inspected the log but has not reproduced the crash.
- **Not shown:** the root cause.
  - An engine-only stack at the moment of the fault does **not** exclude
    earlier memory corruption caused by extension code.
  - "The crash is triggered by discovering the extension mid-session" is a
    **hypothesis**, consistent with the pre-seed result but not demonstrated.
  - The reviewer has not independently reproduced any of this.
- **Not filed upstream yet.** There is no issue URL. Next steps: reproduce with
  a debug-symbol Godot build or the template's unmodified example class, then
  file the issue.
