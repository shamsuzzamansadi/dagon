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

## 3. Accepted for M1 by the independent reviewer (2026-11-02)

Each acceptance is limited as stated:
- `StepProbe` ordering **in the current fixture**, with its ordering regression test.
- C++20 for our sources with C++17 godot-cpp **for the tested compiler configurations**.
  This is not universal ABI certification.
- Platform-native export checks.
- The prepared-import workaround with strict failure handling. The root cause stays
  unresolved, and the exceptional result stays in the evidence.

## 4. Remaining validation (open until evidence exists)

Updated 2026-11-02 at the M1 gate. Evidence: [reviews/m1-review-package.md](reviews/m1-review-package.md).

| Item | Status | Evidence so far | Still needed | When |
|---|---|---|---|---|
| D2 on MSVC | **Accepted for tested configurations (§3)** | MSVC 19.44.35229 with `/MT` on both sides; debug library loads in the Windows editor and passes tests; release library loads in the exported game. godot-cpp's public headers have no standard-dependent code. Not a general ABI/ODR guarantee. | — | Done for M1 |
| Desktop export with GDExtension | **Validated headless on both OSes; windowed on Linux (software GL)** | CI run `41412946061`; local windowed run | Owner runs the Windows export on real hardware | M1 gate |
| Import-crash workaround | **Provisional** | Crash occurs on a fresh clone of the game (134 ×6); preparation prevented it every time. Root cause unknown. | Upstream report | Open |
| Headless test reliability | **Partly** | 20/20 local at `7a2f849`, 10/10 at `a9b262c`; 9 consecutive green CI runs with MSVC, only the latest on today's 47 tests | 10 consecutive CI runs on a stable suite | M1–M3 |
| Teleport contact invalidation | **Validated** | Tests 7f and 7g; mutation check | — | Done |
| `StepProbe` observation order | **Validated** | Test and mutation check | — | Done |
| Movement feel, physical input | **Not done** | Synthetic events only | Owner playtest | M1 gate |
| Cinematic re-entrancy contract | Design only | — | M3 regression tests | M3 |
| Theme fit legibility | Design only | jam.md §4 | M3 playtest question | M3 |
| Visual quality (GDD §8) | **Art direction accepted by the owner (D19). The GDD §8 checklist is not passed.** | Shore artwork in the standard build, reviewed from captures | Stop, turn and landing animation, sound, UI styling, second display; then the first M4 review | M4 |

## 5. Decisions at the Shore integration (2026-11-02)

| ID | Decision | Decided by |
|---|---|---|
| D19 | The Shore's art direction is accepted | Owner |
| D20 | The standard build opens the illustrated Shore, on the whole greybox level | Owner; layout by the developer |
| D21 | The sea stays visible, far beyond the stranded boat | Owner |
| D22 | The camera locks to whole pixels by default, with no position smoothing | Developer, to fix a measured defect; open to the owner's feel check |
| D23 | Direction for later milestones: SHIFT through visible events and sound, a planned audio palette, and display support. Recorded, not started. | Owner |

**D19, art direction.** Accepted: the sailor, wooden boat, moonlit sky, coastal palette and
environment. The Stardew Valley and retro-game screenshots the owner shared were examples of care,
readability and visual consistency, not a request to imitate their artwork, palette, perspective or
gameplay. **This acceptance does not close** physical gamepad checks, movement feel, independent code
review, M1 acceptance or M4. Remaining animation limitations are recorded for M4
([shore-preview.md](shore-preview.md)).

**D20, entry scene.** `project/scenes/level/shore.tscn` is the main scene. It has the same collision
polygon, spawn point, camera limits and movement tuning as the greybox, and tests compare them, so
the playable extent stays x = 24 to 1376. Art covers x = 0 to 640; the rest remains greybox. The
greybox `level.tscn` stays as a development and test scene and is excluded from exports. To make the
longer level reachable, the preview's collision wall at x = 620 was removed and the right cliff gained
a cleft. Where M2 and M3 build next (the entry scene or the greybox) is to be settled when M2 starts.

**D21, the distant sea (a small story adaptation).** The GDD and `jam.md` §4 said the sailor wakes with
no sea in sight. The accepted composition shows a thin band of sea far out past wide wet flats, and
the owner kept it, so the documents now match the scene. The premise is unchanged: the sailor wakes on
exposed seabed, where the tide has withdrawn unnaturally far and does not come back. Seeing how far
off the water lies supports the physical shift. There is still no surf at the shoreline: the sea is
heard only faintly, if at all, and thins away as the player moves on (GDD §7).

**D22, camera.** The owner's recording showed the character flickering by 1 game pixel while followed:
the character and a smoothed camera rounded to whole pixels separately. `CameraRig` now keeps a whole
number of pixels from its target unless a scene turns `pixel_lock` off, and the greybox lost its
position smoothing, so both scenes follow rigidly and only the look-ahead slides. Measurements:
[evidence/shore/camera-jitter.txt](evidence/shore/camera-jitter.txt).

**D23, later direction.** Correct gameplay, coherent visuals and bug fixes stay the priority. SHIFT is
carried by the exposed seabed, the player's changing understanding and the turn from exploration to
escape, with no dimension-switching mechanic ([jam.md](jam.md) §4). The audio palette and its checks
are in GDD §7, and the 720p and 1080p requirements in the [roadmap](roadmap.md). This changes GDD §7's
earlier "sea sounds are deliberately absent" to a faint, distant sea that thins away.
