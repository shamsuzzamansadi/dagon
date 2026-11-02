> **CLOSED (2026-10-28).** This is the round-1 response, kept for the record. The reviewer conditionally approved Phase A in round 2; see `../decisions.md`. Its "7 days" wording and import-crash description are superseded by `../roadmap.md` and `../evidence/import-crash/README.md`.

# Phase A Review — Developer Response (Round 1)

**To:** ChatGPT (independent reviewer)
**Date:** 2026-10-28
**Scope of changes:** only the documents and sections these findings touch.
No unrelated edits. No gameplay code exists yet.

All 8 findings are **accepted**. Three corrections differ from the fix you
proposed; the reasoning is given in each case. One finding (7) was
investigated further, and the fix now removes the exception altogether.

| # | Your severity | My assessment | Status |
|---|---|---|---|
| 1 | Major | Confirmed. The gate was opened only by `monolith_awaken`. | Fixed in design |
| 2 | Major | Confirmed, and I would rate it **Blocker**. In the planned layout the `collapse` trigger lies on the outbound path, so it would *always* be spent before the flee: a guaranteed softlock, not an edge case. | Fixed in design |
| 3 | Major | Confirmed. | Fixed (stricter rule than proposed) |
| 4 | Major | Confirmed. Widened to all engine-global state. | Fixed (broader than proposed) |
| 5 | Major | Confirmed. | Fixed in design |
| 6 | Major | Confirmed. | Fixed in design |
| 7 | Major, M1 gate | Confirmed. Root cause investigated and the exception removed. | Fixed, with evidence |
| 8 | Minor | Confirmed. | Fixed (simpler mechanism than proposed) |

## Details

**1. Gameplay outcomes vs presentation** (architecture §5, GameDirector)
- Every beat now has an *essential outcome* applied in C++ and made
  idempotent. For Awakened, the outcome is gate `collision_layer = 0`
  (deferred) plus a checkpoint advance. Clips are visual and audio only.
- `finalize_cinematic()` applies the outcome if it has not been applied,
  restores the camera (target, zoom, shake) and sets the beat's control state.
  Every exit path goes through it.
- Tests: missing, looping and timed-out clips each lead to an open gate, a
  restored camera and the correct control state.

**2. Trigger eligibility** (StoryTrigger, GameDirector)
- `StoryTrigger` no longer latches. It emits on every entry while enabled.
- The Director disables a trigger only after `StoryProgress` *accepts* the
  event. A rejection consumes nothing.
- On beat entry, the Director checks `is_player_inside()` on the awaited
  trigger, which handles a player already overlapping it.
- Monitoring stays on, so the overlap list is current.
- Regression tests:
  - an outbound crossing of `collapse` is not consumed and fires later in
    Fleeing;
  - a player already inside the awaited trigger when the beat begins fires it.

**3. Pointer lifetime** (§7 rule 3, D7)
- I did not adopt "raw pointers for explicitly permanent children". That
  still relies on a judgement that the next scene edit can silently break.
- Rule now: **no raw node pointer is kept past the current call.** All cached
  references are `NodeRef<T>`, a small `ObjectID` wrapper whose `get()`
  returns `T*` or null. The lookup cost is negligible at our node counts.
- Tweens are created only with `Node::create_tween()` (node-bound), and the
  previous tween is killed before a new one starts.

**4. Global state across reload** (§7 rule 8)
- `SceneTree.paused` is not the only global. AudioServer bus
  volume/mute/effect parameters, `Input` mouse mode and `Engine.time_scale`
  also survive a reload.
- `dagon::reset_global_state()` resets that complete list. It runs before
  every transition (start, restart, quit to title, ending) and defensively in
  `GameDirector::_ready`, with a debug warning if anything was dirty.
- Clips may not mutate AudioServer; low-pass sweeps are baked into the
  assets.
- Tests: pause → restart and pause → title → start both end unpaused.

**5. Single velocity owner** (PlayerController, `core::step`)
- `CharacterBody2D::velocity` is the only stored velocity. `MoveState` holds
  only timers and flags.
- Each frame reads the post-collision `velocity` and `is_on_floor()` from the
  previous `move_and_slide()`, passes them to `step()`, writes the result back,
  then calls `move_and_slide()`. Ceiling and wall corrections therefore flow
  back automatically.
- `teleport` zeroes velocity and resets `MoveState{}`, which is airborne with
  no coyote time and no buffered jump. A stale `is_on_floor()` cannot grant a
  jump.
- Test: M1 criterion 7f.

**6. Cinematic contract**
- The Director records `expected_clip` and ignores `animation_finished` for any
  other name.
- It refuses missing or non-`LOOP_NONE` clips, with an error followed by
  immediate finalize.
- A watchdog (clip length + 2 s) is accumulated in the Director's own
  `_process`, so it pauses with the tree and needs no SceneTree timer whose
  callback could outlive the node. It covers interrupted, replaced and stalled
  clips.
- Only the Director plays on `cinematics`. Nothing waits on `atmosphere`.

**7. Import abort, with new evidence**
- Under gdb the crash is a **SIGSEGV on the main thread after `main`
  returns**. Every frame is in the stripped engine binary, and **none is in
  the extension `.so`**.
- The trigger is the first filesystem scan *discovering* the extension
  partway through the session.
- Pre-seeding `.godot/extension_list.cfg` before the first import gives a
  clean import with **exit 0 in 3/3 runs**, compared with 134 in 3/3 without
  it. The extension still loads and runs afterwards (class registered, method
  result correct).
- CI policy: seed the file, run **one** import, and fail on **any** non-zero
  exit. There is no exception and no retry, and both logs are kept as
  artifacts.
- The upstream engine crash remains an open issue, to be reported with the
  spike as a minimal repro.
- This supersedes the original workaround and your proposed narrowed
  exception: no exit code is tolerated.

**8. Stale focus**
- Instead of adding availability-change signals, the Interactor **recomputes
  focus every physics frame**. Each frame it prunes candidates whose
  `ObjectID` no longer resolves and picks the nearest `is_available()`
  candidate. It emits `focus_changed` only on change.
- Focus is revalidated again on the interact press.
- With fewer than 5 candidates this costs nothing, and it removes a class of
  missed-event bugs rather than patching one.
- Tests: disable the focused object, and free the focused object.

## Requests for round 2

1. Please re-check the corrected sections of `architecture.md`: §5
   PlayerController, Interactor, StoryTrigger, GameDirector, Hud and
   MenuController, plus §7 rules 3 and 8. Can you construct a sequence that
   still double-fires a beat, leaves the gate closed, or leaves control
   locked?
2. Your review did not cover the questions in the original brief. Before the
   gate closes I would still like your view on these:
   - **D3/D4:** 9 classes and no GDScript. Over-engineered for 7 days?
   - **D2:** any ABI or ODR hazard in linking C++20 translation units against
     a C++17-built godot-cpp on MSVC 2022?
   - Reliability of a headless `CharacterBody2D` test under
     `--fixed-fps 60` with injected `InputEventAction`s.
   - Schedule: what would you cut first?

   If you have no concerns on these, please say so explicitly, so silence is
   not mistaken for approval.
