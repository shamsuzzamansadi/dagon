# Architecture Decisions

**Review status:** Phase A was **conditionally approved** by the independent
reviewer (ChatGPT) on 2026-10-28, after two rounds. No further full
architecture review is needed unless a material design change emerges. The
round-2 corrections are applied in `architecture.md`, `roadmap.md`, `gdd.md`
and `toolchain.md`.

## 1. Approved decisions

| ID | Decision | Notes |
|---|---|---|
| D1 | Godot 4.7.2 + godot-cpp 10.0.0-stable (`507ed9d`), `api_version=4.7`, `compatibility_minimum="4.7"` | |
| D2 | Our sources compile as C++20 in a cloned SCons env; godot-cpp stays C++17 | **Conditionally accepted for M1 validation; not certified ABI/ODR-safe in general.** See §3. |
| D3 | 9 focused GDExtension classes + 3 plain-C++ core modules | Approved as not excessive. Add no further abstractions. |
| D4 | C++ for gameplay and presentation; GDScript only for headless tests | Approved. The iteration-speed cost of C++ UI and camera code is accepted. |
| D5 | No autoloads or singletons; restart = `reload_current_scene()` | Plus explicit reset of project-modified engine-global state (architecture §7 rule 8). |
| D6 | Plain-C++ rules with thin Godot adapters; vendored doctest; hand-rolled headless runner | |
| D7 | `NodeRef<T>` (an `ObjectID` wrapper) for every stored node reference; node-bound tweens; `callable_mp` | Revised in round 1. |
| D8 | Editor-wired signals with a wiring test; the Director connects its own `story_triggers` in code | |
| D9 | Compatibility renderer, 480×270, integer scaling | |
| D10 | Polygon terrain | |
| D11 | Complete greybox gameplay (M3) before atmosphere (M4) | |
| D12 | Clips are presentation only. Gameplay outcomes are applied in C++. Generation-guarded, deferred cinematic finalization. | Revised in rounds 1 and 2. |
| D13 | Non-modal examine captions | |
| D14 | MIT code; CC BY 4.0 original assets; third-party CC0/OFL only | |
| D15 | Linux + Windows CI, no secrets, manual itch upload by the owner | |
| D16 | Desktop first; web is a stretch goal after M6 | |
| D17 | Director-owned trigger consumption (consume only on acceptance) | Round 1 |
| D18 | Per-physics-frame interaction focus selection | Round 1 |

## 2. Reviewer answers to the open technical questions (round 2)

- **D3/D4:** approved. Nine focused classes are not excessive. C++ UI and
  camera code has an iteration-speed cost but is acceptable. Avoid additional
  abstractions.
- **D2:** C++17 godot-cpp linked with our C++20 sources is *conditionally*
  accepted for M1 validation, not certified as universally ABI/ODR-safe.
  Required:
  - a consistent MSVC toolset and compatible runtime and debug settings;
  - a check of shared-header differences;
  - the actual compiler version recorded (`windows-latest` is not a pin);
  - both debug and release builds validated, including runtime extension
    loading.
- **Headless tests:** approved for regressions. Required:
  - an explicitly fixed physics tick rate;
  - a defined injection-then-observation order;
  - all actions released between tests;
  - tolerances and bounded waits.

  Simulated actions do not verify physical controller mappings. Do not claim
  that `--fixed-fps` alone guarantees deterministic physics. The rules are in
  architecture §8.
- **Scope:** cut stretch work first, then optional props, extra layers,
  elaborate effects and animation variety. Keep the playable loop, readable
  clues, the reveal and the export checks.

## 3. Remaining validation (open until evidence exists)

| Item | Evidence so far | Validation step | When |
|---|---|---|---|
| D2 on MSVC | None. GCC 13.3 Linux probe only. Shared headers checked: godot-cpp's public headers have no `__cplusplus`-dependent code paths (only `static_assert(__cplusplus >= 201703L)`). The standard library headers themselves still differ by mode. | CI: MSVC debug and release builds with the `cl` version logged; our env is a clone of godot-cpp's, so runtime (`/MT` vs `/MD`) and debug flags match by construction, and the log verifies it; Windows runtime extension load (roadmap M1 #6) | M1 |
| Desktop export with GDExtension | None | Templates downloaded and checksum-verified; Linux export runs headless; Windows export created and run natively by a human | M1 |
| Import-crash workaround | Pre-seed prevented the crash 3/3 (probe project only) | Re-run on the real project, locally and in CI; collect a debug-symbol backtrace if time allows; file upstream and link the issue URL | M1 |
| Headless test reliability | None | M1 integration tests run repeatedly (≥ 10 consecutive CI runs with no flake) | M1–M3 |
| Teleport contact invalidation | Design only | M1 tests 7f and 7g | M1 |
| Cinematic re-entrancy contract | Design only | M3 regression tests (architecture §8) | M3 |
| Theme fit | Theme not announced | jam.md §4 | G0 (Nov 1–2) |
