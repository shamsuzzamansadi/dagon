# Import-workaround evidence on the actual project (2026-11-02)

Godot `4.7.2.stable.official.ed1daf0bf`, WSL2 on Linux 6.6. Each row is a
clean-cache `--headless --import`. The `.exit`, `.stdout` and `.stderr` of every
trial are in the subfolders. Reproduce with `tools/import_evidence.sh`.

| Project | Filesystem | Unprepared | Prepared (`tools/prepare_project.sh`) |
|---|---|---|---|
| **Actual game, fresh clone** | ext4 (native) | **134 in all 6 trials** (4 here, then one each on clones of `e49aae3` and `7a2f849`) | 0, 0, 0 |
| Actual game, working copy | 9p (`/mnt/c`) | 0, 0, 0, 0, 0, 0 | 0, 0, 0, 0, 0, 0 |
| Probe (control) | ext4 | 134, 134, 134 | 0, 0, 0 |
| Probe (control) | 9p (`/mnt/c`) | 134, 134, 134 | not run |

In addition, `tools/run_godot_checks.sh` runs one prepared clean import on each
check run: exit 0 on the fresh clone and in the working copy.

## What this supports

- The crash **does occur on the actual project** on a fresh clone on a native
  filesystem, and preparing the extension list prevented it in every trial.
- The prepare step is therefore needed for clean checkouts, not just for the probe.

## What it does not establish

- **The root cause.** The working copy on `/mnt/c` is the only case that exits 0
  when unprepared. The filesystem alone does not explain this, because the probe
  crashes on both. Other differences were not isolated.
- That the prepare step is a fix. It is a provisional workaround; any non-zero
  import exit fails the run.
- Behaviour on Windows, or in an interactive editor session. CI reports the
  prepared import only.
- No upstream issue has been filed.

## Correction

Commit `b94e742` says this crash "does not reproduce on this project". That came
from testing only the working copy and was **wrong**. It was found by the fresh
clone run and corrected here. History was not rewritten.
