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

Updated 2026-11-02 at the M1 gate. Evidence: [reviews/m1-review-package.md](reviews/m1-review-package.md).

| Item | Status | Evidence so far | Still needed | When |
|---|---|---|---|---|
| D2 on MSVC | **Validated on CI, reviewer judgment pending** | MSVC 19.44.35229 with `/MT` on both sides; debug library loads in the Windows editor and passes tests; release library loads in the exported game. godot-cpp's public headers have no standard-dependent code. Not a general ABI/ODR guarantee. | Review | M1 gate |
| Desktop export with GDExtension | **Validated headless on both OSes; windowed on Linux (software GL)** | CI run `41408640443`; local windowed run | Owner runs the Windows export on real hardware | M1 gate |
| Import-crash workaround | **Provisional** | Crash occurs on a fresh clone of the game (134 ×4); preparation prevented it every time. Root cause unknown. | Upstream report | Open |
| Headless test reliability | **Partly** | 20/20 local; 3 green CI runs | 10 consecutive CI runs | M1–M3 |
| Teleport contact invalidation | **Validated** | Tests 7f and 7g; mutation check | — | Done |
| `StepProbe` observation order | **Validated** | Test and mutation check | — | Done |
| Movement feel, physical input | **Not done** | Synthetic events only | Owner playtest | M1 gate |
| Cinematic re-entrancy contract | Design only | — | M3 regression tests | M3 |
| Theme fit legibility | Design only | jam.md §4 | M3 playtest question | M3 |
| Visual quality (GDD §8) | Not started | Greybox only | First M4 review | M4 |
