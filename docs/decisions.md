# Architecture Decisions

**Review status:** Phase A was **conditionally approved** by the independent
reviewer (ChatGPT) on 2026-10-28, after two rounds. No further full
architecture review is needed unless a material design change emerges. The
round-2 corrections are applied in `architecture.md`, `roadmap.md`, `gdd.md`
and `toolchain.md`. **D25 and D26 (§6) are such a change, and the revised design is
approved for implementation. No further architecture review is needed for its approved classes.**

## 1. Approved decisions

| ID | Decision | Notes |
|---|---|---|
| D1 | Godot 4.7.2 + godot-cpp 10.0.0-stable (`507ed9d`), `api_version=4.7`, `compatibility_minimum="4.7"` | |
| D2 | Our sources compile as C++20 in a cloned SCons env; godot-cpp stays C++17 | **Conditionally accepted for M1 validation; not certified ABI/ODR-safe in general.** See §3. |
| D3 | 9 focused GDExtension classes + 3 plain-C++ core modules | Approved as not excessive. Add no further abstractions. **D26 adds a little** for the owner's usability scope. |
| D4 | C++ for gameplay and presentation; GDScript only for headless tests | Approved. The iteration-speed cost of C++ UI and camera code is accepted. |
| D5 | No autoloads or singletons; restart = `reload_current_scene()` | Plus explicit reset of project-modified engine-global state (architecture §7 rule 8). Still no singleton under D26. From M3, restart replaces the world under a small session node instead of reloading the scene, and still rebuilds all world state. |
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
- The M1 implementation at `3301ae0`: no new blocking findings, and the three earlier findings are resolved. The
  native tests and art check were rerun. Godot integration tests, engine rendering and release exports rely on the
  supplied CI evidence ([package §17](reviews/m1-review-package.md)). This is not M1 acceptance, which is the owner's.

## 4. Remaining validation (open until evidence exists)

Updated 2026-11-02 at the M1 gate. Evidence: [reviews/m1-review-package.md](reviews/m1-review-package.md).

| Item | Status | Evidence so far | Still needed | When |
|---|---|---|---|---|
| D2 on MSVC | **Accepted for tested configurations (§3)** | MSVC 19.44.35229 with `/MT` on both sides; debug library loads in the Windows editor and passes tests; release library loads in the exported game. godot-cpp's public headers have no standard-dependent code. Not a general ABI/ODR guarantee. | — | Done for M1 |
| Desktop export with GDExtension | **Validated headless on both OSes. Launched by the owner on Windows, and on Linux with software rendering** | CI run `41432275970`; owner's [Windows](evidence/m1/windows-playtest-2026-11-02-standard-build.md) and [Linux](evidence/m1/linux-playtest-2026-11-02.md) sessions, commits unconfirmed | Native Linux hardware-accelerated rendering validation (deferred, D29) | M6 |
| Import-crash workaround | **Provisional** | Crash occurs on a fresh clone of the game (134 ×6); preparation prevented it every time. Root cause unknown. | Upstream report | Open |
| Headless test reliability | **Partly** | 20/20 local at `7a2f849`, 10/10 at `a9b262c`; 9 consecutive green CI runs with MSVC, only the latest on today's 47 tests | 10 consecutive CI runs on a stable suite | M1–M3 |
| Teleport contact invalidation | **Validated** | Tests 7f and 7g; mutation check | — | Done |
| `StepProbe` observation order | **Validated** | Test and mutation check | — | Done |
| Movement feel, physical input | **Positive general feedback from the owner; A, D, Left Arrow, Right Arrow and Space worked on Linux. Physical gamepad untested.** | [Owner's sessions](reviews/m1-review-package.md) | Physical gamepad testing (deferred, D29) | M6 |
| Cinematic re-entrancy contract | **Implemented, not yet reviewed.** Regression tests pass | [M3 package](reviews/m3-review-package.md) | Independent review; the owner's acceptance | M3 |
| Theme fit legibility | **Built in greybox, not yet tried on a person** | jam.md §4 | M3 playtest question, in the package's manual check | M3 |
| Visual quality (GDD §8) | **Art direction accepted by the owner (D19). The GDD §8 checklist is not passed.** | Shore artwork in the standard build, reviewed from captures and played by the owner | Stop, turn and landing animation, sound, UI styling, second display; then the first M4 review | M4 |
| Settings, rebinding, save and restore | **Built. M2 accepted for its beats. M3 extends it to every savable beat, not yet reviewed** | Architecture §5, [M3 package](reviews/m3-review-package.md) | M3 review and acceptance; M6 verification | M3, M6 |

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
[evidence/shore/camera-jitter.txt](evidence/shore/camera-jitter.txt). The owner later reported that the
camera generally felt fine ([session](evidence/m1/windows-playtest-2026-11-02-standard-build.md)); that
session's commit is unconfirmed, and jitter was not measured in it.

**D23, later direction.** Correct gameplay, coherent visuals and bug fixes stay the priority. SHIFT is
carried by the exposed seabed, the player's changing understanding and the turn from exploration to
escape, with no dimension-switching mechanic ([jam.md](jam.md) §4). The audio palette and its checks
are in GDD §7, and the 720p and 1080p requirements in the [roadmap](roadmap.md). This changes GDD §7's
earlier "sea sounds are deliberately absent" to a faint, distant sea that thins away.

## 6. Usability scope (2026-11-02)

Planned only. Requesting these does not accept M1 or start M2.

| ID | Decision | Decided by |
|---|---|---|
| D24 | M2 gains a pause menu with Settings, persistent settings and keyboard rebinding | Owner |
| D25 | **Scope change.** M3 gains a main menu and one persistent checkpoint save slot | Owner |
| D26 | How that persists without an autoload, and what it adds to the code | Developer's design, **approved for implementation by the reviewer. Not built.** |
| D27 | Quitting, the final sequence and the ending | Owner |
| D28 | What comes first if the schedule is tight | Owner |
| D29 | M1 is accepted by the owner with documented deferrals | Owner |

**D24, M2 usability.** The pause menu has Resume, Restart Checkpoint, Settings and Quit to Desktop, and
M3 adds Quit to Main Menu (D27). This replaces the GDD's earlier "resume, restart, quit to title".
Requirements: [roadmap](roadmap.md).

**D25, the save slot.** GDD §10 excluded saves, and this reverses that deliberately, so that Continue works
after the application is closed and reopened. It stays small: one slot, restored at the last safe
checkpoint, with no multiple slots and no saving at an arbitrary position. Player-facing rules: GDD §11.

**D26, design (architecture §5).** Reviewed by the owner with ChatGPT on 2026-11-02, as relayed by the owner.
The overall design is acceptable in principle: separate settings and progress, plain-C++ validation, stateless
storage functions, a single restore path, and no singleton. **This is design approval with the corrections
below, not implementation certification.** Nothing here is built.

- **New Game (correction).** It writes the fresh save first. If that fails, the player stays in the menu with an
  error and a Retry option. It never transitions through a path that reads the old save.
- **Two checkpoints (correction).** The active session checkpoint is kept apart from the last successfully
  persisted one. Restart Checkpoint restores the session checkpoint, even after an autosave failure. Continue after
  a relaunch restores the last valid disk save. The session checkpoint is a small value owned by a scene,
  `GameSession`. A scene reload would destroy that value, so restart replaces the world under that node instead.
- **Backup (correction).** A usable backup survives an interrupted replacement, and recovery never overwrites a
  valid backup with a corrupt primary file.
- **Test storage (correction).** Isolation covers every entry point, including scenes that load settings or saves
  in `_ready`. Each test run has a unique directory, including subprocess tests, and cleanup cannot touch real
  player files.
- **Failure paths (correction).** Each behaviour above gets a focused failure-path test when persistence is
  implemented.
- **One restore path.** `GameDirector` restores from a checkpoint value it is given. It reads no file, applies C++
  essential outcomes and never plays a clip, which follows D12.
- **Additions to D3:** two classes (`SettingsMenu`, `GameSession`), two plain-C++ modules (`save_data`,
  `settings_data`) and one file of stateless functions (`storage`).
- **Engine-global state:** `InputMap` joins the list in architecture §7 rule 8, and `reset_global_state()`
  must keep the player's volumes and bindings.

**Final design review (2026-11-02, relayed by the owner).** The revised design is approved for implementation. A
scene-owned session checkpoint that survives world replacement is a reasonable scoped exception to literal scene reload
(D5), with no singleton, and the planned 11 classes are acceptable. No further architecture review is needed for these
approved classes. During M3, world replacement must remove the old world's active signals and callbacks and give the new
director its checkpoint before it enters the tree, and tests must verify restart after an autosave failure, pause reset,
and repeated restart without duplicate events.

**D27, quitting and the ending.**
- M3 adds Quit to Main Menu, once the main menu exists.
- Quitting during the reveal or escape may resume from the preceding safe checkpoint and replay that unfinished
  sequence.
- The last checkpoint stays after the ending. The menu explains that Continue resumes before the final sequence,
  and does not imply a post-ending world state.
- Quitting or returning to the main menu makes the checkpoint behaviour clear, and never implies that unsaved
  progress has been persisted.

**D28, priority.** Gameplay progression, correctness, basic menus, safe checkpoint persistence, readable visuals, and
essential environmental and story audio come ahead of optional display features and additional decorative polish.
If the schedule slips, the specific tradeoff is flagged early. Requested key rebinding and save support are never
removed silently.

**D29, M1 acceptance (2026-11-02).** Accepted by the owner for progression to M2, based on the independent technical
review, the supplied CI evidence and the owner's Windows and Linux playtests. This is not a statement that every manual
check passed ([package §16](reviews/m1-review-package.md)).
- **Deferred to M6, before release:** physical gamepad testing, which is untested today, and native Linux
  hardware-accelerated rendering validation. The Linux run used software rendering.
- **Accepted limitation:** the exact provenance of the recorded builds stays unconfirmed, and is not inferred from
  timestamps or appearance. Later milestone playtests identify the exact artifact or run.
- **The review's limits still stand:** Godot integration tests, engine rendering and release exports rely on supplied CI
  evidence, not independent reruns ([package §17](reviews/m1-review-package.md)).

## 7. M2 implementation choices (2026-11-02, for the M2 review)

| ID | Choice | Why |
|---|---|---|
| D30 | M2 builds in the entry scene, `shore.tscn`. `level.tscn` stays the art-free movement test scene. | Settles the question left open in D20. The player meets menus and interaction in the scene the build opens, and the greybox keeps testing movement alone. |
| D31 | `GameDirector` starts in M2 with only the session checkpoint and kill plane | No extra class just for M2, keeping the approved count of 11. M3 adds `StoryProgress`, cinematics and moves the session checkpoint to `GameSession`. |
| D32 | One rebindable key per gameplay action. The Left and Right arrows always move and Esc always pauses, and those three cannot be assigned elsewhere. The Up and Down arrows can be rebound. | Swapping two keys can never leave an action unbound, and nobody can lock themselves out. The cost is that Left and Right cannot be used for jump or interact. Up and Down stay free because menus use their own actions, and a test shows that rebinding them leaves navigation and Back working. |
| D33 | `reset_global_state()` leaves volumes and bindings alone | They change only through Settings, so they are already the player's. Re-reading the file would undo a change that could not be saved, which the player was told lasts until they quit. Changes the wording of architecture §7 rule 8. |
| D34 | An original pixel font, drawn by `tools/art/gen_ui.py` | The engine's default font is not readable on a 480x270 canvas. This is UI groundwork, not the M4 styling pass. |
| D35 | The project defines `ui_accept` and `ui_cancel` itself | The engine's defaults for these have no gamepad buttons in 4.7.2, so a controller could neither press nor back out. |
| D36 | **Scope change by the owner (2026-11-03):** the main menu, New Game, Continue with one persistent save slot, Settings, Controls, Credits, Quit to Main Menu and a short introduction move from M3 into M2, before the merge. | The owner's Windows test showed that a build which opens straight into the world explains nothing. D25, D26 and D27 apply unchanged. See the roadmap for what stays in M3. |
| D37 | **No scene connection may start inside an instanced scene.** The Hud connects to the Interactor in code, from an exported path. | The cause of the Examine failure: the editor's text scene keeps such a connection, but the export re-packs scenes and silently drops it unless the node has Editable Children. Every test passed, because they all ran from the text scenes. Code is explicit, and it needs no editor flag that a later edit could clear. |
| D38 | **The integration suite also runs against the exported pack,** with `ProjectSettings.load_resource_pack` in `tools/export_check.sh`. | A test of the source scenes cannot see what the export changes. This check fails on the D37 defect, and the source suite does not. |
| D39 | **Prompts and Controls name buttons for the device in use.** Keyboard: the current key. Recognized Xbox: A, B, X, Menu. Recognized PlayStation: Cross, Circle, Square, Options. Anything else: bottom, right and left face button, and Start. Bindings stay positional, so Interact is the west button on every controller. Recognition uses the driver's name, then the USB vendor id, and never guesses. | One label cannot be right for every controller: PlayStation's Cross is the south button, which is Jump, so a bare "X" tells a PlayStation player to press the wrong button. A wrong brand's letter is worse than a position, so an unknown controller gets the position. |
| D40 | **The menu in charge tracks the active device, and passes it on.** Only a key press, a button press or a stick past half deflection changes it. A disconnection hands back to the keyboard. A reconnection changes nothing until the controller is used. | `MenuController` keeps running while paused and exists in every scene that has a world or a menu, so no singleton is needed. `GameSession` keeps the value across world replacement. Triggers do not count, because some drivers report an untouched trigger at full deflection. |
| D41 | `DAGON_TEST_CONTROLLER` stands in for the driver's name, also in release builds. | Godot cannot create a device from a script, so this is how tests exercise each layout. Like `DAGON_STORAGE_DIR`, it is harmless for a local game. It proves label logic only, never a physical controller. |
| D42 | **M2 prepares audio and does not implement it.** The Music and Effects sliders, their saved values and their buses stay, and Settings shows "This build has no audio yet." until audio is connected, when the note and its tests are removed. Environmental audio, footsteps, object and interaction sounds and story cues stay in M4 and M5. | Owner's clarification, 2026-11-03. Working sliders in a silent build otherwise read as a fault. Describe M2 as "volume controls and buses prepared", never "audio implemented". Audio is not complete until it has been heard and checked in gameplay. |
| D43 | **Repository workflow (owner, 2026-11-03).** `main` is the sole long-lived stable branch. Work happens on temporary feature branches. After review, CI and owner acceptance, each is squash-merged into `main` as one meaningful commit. CI is verified on the resulting `main` commit, then the remote and local branch are deleted and stale remote-tracking references pruned. | Unrelated local work and unique unmerged changes are never discarded. A squash leaves no ancestry, so check the pull request's merged state and included changes, not `git branch --merged`. `preview/shore-art`, fully contained in `main`, was removed under this rule. |
| D44 | **M2 acceptance (2026-11-03).** Accepted by the owner for merge, based on their manual testing, the completed review and the required automated checks. This is not a statement that every manual check passed, and the build was not named ([record](evidence/m2/owner-acceptance-2026-11-03.md)). | **Deferred to M6:** all physical PlayStation hardware, the individual Xbox actions, including disconnect and reconnect, key names under German on the real build, and native Linux hardware-accelerated rendering. **The review's limits stand:** ChatGPT's results stop at `79981ea`, and exclude the Godot integration tests and Windows gameplay. |
| D45 | **Milestone prereleases are published by automation, when a merged record in `release/` passes every gate** ([release.md](release.md)). Reaching a milestone publishes nothing. Authorized by the owner, 2026-11-03: GitHub prereleases only, as `v0.1.0-pre-alpha.N`, `v0.2.0-alpha.N` and `v0.3.0-rc.N`. | Publishing from a job in the same CI run means the packages are the very files that run tested, with no rebuild and no second test run. An owner's acceptance is tied to a fingerprint of the game's files and of everything that decides how it is built, exported and packaged, so it survives a squash and document changes, and is voided by any change to those. No stable or 1.0 version can be expressed. |
| D46 | **Clang 18.1.3 validates on Linux, alongside GCC and MSVC, and all three must pass** before a merge or a prerelease. There is one package per OS: GCC for Linux, MSVC for Windows. | A second compiler on the same OS finds non-portable code before it matters. Linux stays built on `ubuntu-22.04` for the older glibc. Clang runs the existing unit, integration and export smoke checks, and skips the art and storage-path checks, which do not depend on the compiler. |
| D47 | **The release workflow and Clang job are accepted, and `main` is protected (owner, 2026-11-04).** Pull requests required with no approving reviews, the `linux`, `linux-clang`, `windows` and `release-tools` checks required, linear history, no force-push or deletion, rules applying to administrators, and squash merging only. `v*` tags cannot be updated or deleted, and can be created. Immutable releases are on. | Based on the reviewer's follow-up at `effa099` and the owner's acceptance ([evidence](evidence/release-workflow/README.md)). Approving reviews stay off because one account cannot approve its own pull requests. No tag or release exists yet, so the first publication stays unproven ([release.md](release.md#before-the-first-real-publication)). |

## 8. M3 implementation choices (2026-11-04, for the M3 review)

| ID | Choice | Why |
|---|---|---|
| D48 | **The four acts grow in `shore.tscn`, to x = 4544.** Everything up to x = 980 is M1's, point for point. The way right ends in a solid wall at x = 4520. Act II: fossils, tablets, a rib arch, a crevasse 26 px wide and 18 deep, and two steps up to a plateau. Act III: `reach_monolith` at 3620, `collapse` at 3760, the mural, then the stones at 3990, 4080 and 4170, in an order that does not spell the answer, and the gate at 4300. Act IV: `witness` at 4420. `level.tscn` is left as M1's movement test scene. | `collapse` sits 660 px from `witness`, which is 9.4 s at 70 px/s, inside the GDD's 8–10 s and under the 12 s timeout. Stones 90 px apart mean only one is ever in reach, so a repeated press can never land on another. A wider crevasse left too small a window to clear with a hop. |
| D49 | **Overlap rechecks wait 3 physics frames, not 2.** Measured on 4.7.2, as architecture §5 asked ([evidence](evidence/m3/overlap-latency.txt)). | A clip ends in the idle phase, after that frame's server step, so a move made then is only in the overlap list three frames on. With 2, the recheck read a stale list: two tests failed on it, one of them firing a trigger for a player who had already left. |
| D50 | **The scene change to the ending happens in the deferred step, not in the finalizer.** | The tree takes the current scene out at once. With a missing clip, finalization runs inside a physics callback (`body_entered`), where removing a body is an error. The outcome is still applied on every exit path, and only once. The ending is instantiated first, so the active device can be set on it before it enters the tree, as the main menu is. |
| D51 | **The exported route runs outside the game, in `tools/route_check.py`, on both shipping builds in CI.** The build is run as shipped, with its own window, and keys arrive from the window system: XTEST under Xvfb on Linux, window messages on Windows. It reads the log for what a player sees. `application/run/flush_stdout_on_print` is on, so the log can be read as it happens. On a desktop it refuses to run: it needs a named private X display, or `--windows-ci` on a CI runner. | No test driver ships in the game. A release template cannot run a script, so the integration suite on the pack (D38) runs in a debug process, and only this exercises the release library through a full playthrough. The owner asked that their desktop not be disturbed without arrangement. The flush setting has no cost, as the game prints nothing without `--verbose`. |
| D52 | **The save format does not change, and stays version 1.** `LAST_BUILT_BEAT` is gone, as no beat is unbuilt now. | Every M3 outcome follows from the beat, as D26 asked. M2's saves still load, which is tested byte for byte. A later version's file is refused as before, and left alone. |
| D53 | **Tests of a broken clip silence the engine's error line, and check a `contract_error` signal.** | The runner fails a test on any logged error, and the check script fails the run on any `ERROR` line. `Engine.print_error_messages` silences both. Allowing listed errors instead would have needed a second mechanism for no better proof. |
| D54 | **Greybox feedback is visual and in captions.** The stones' indicators are polygons, and each result shows a caption, through scene connections. | M3 has no audio, by plan (M4, M5), and the puzzle must still read without its grinding and tones. |
| D55 | **`checkpoint_reached` is emitted only for savable beats, and `beat_changed` for all of them.** | The session filtered out the others anyway, and a save must wait until a beat has finalized, which is a different moment from entering it at Awakened. |

**Later changes to earlier decisions:**
- **D30:** the entry scene is now the main menu, `title.tscn`. `shore.tscn` is the world that `game.tscn` plays in.
- **D31:** `GameDirector` now also holds `StoryProgress`, and the session checkpoint has moved to `GameSession`, because the save needed them. Cinematics followed in M3.
- **D20:** the Shore's collision is the same as `level.tscn`'s only up to x = 980 now, as the acts carry on from there (D48).
- **D29:** the owner has since tried a physical Xbox controller, with positive feedback for the controls they exercised
  ([record](evidence/m2/xbox-feedback-2026-11-03.md)). Everything else about physical controllers stays pending, including all
  PlayStation hardware. Testing a controller on Windows says nothing about Xbox or PlayStation console platforms, which are not targets.
