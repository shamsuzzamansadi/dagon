# Technical Architecture

Status: Phase A, **conditionally approved** by the independent reviewer
(2026-10-28). The round-2 corrections are applied below. Approved decisions
and the remaining validation are tracked in [decisions.md](decisions.md).
Toolchain: see
[toolchain.md](toolchain.md).

## 1. Principles

1. **Godot does the heavy lifting.** Physics (`CharacterBody2D`, `Area2D`),
   cinematics (`AnimationPlayer`), lighting (`PointLight2D`, `CanvasModulate`),
   parallax (`Parallax2D`), audio buses, tweens, scene reload. C++ adds only
   behaviour Godot does not have.
2. **State lives in the level scene.** There are no autoloads and no
   singletons. Restart is `SceneTree::reload_current_scene()`, which rebuilds
   every piece of state from scratch.
3. **Wiring happens in the editor.** References are exported node properties.
   Events are Godot signals connected in the `.tscn`. No event bus, no
   hard-coded scene paths in C++.
4. **Deterministic rules are plain C++.** Movement maths, puzzle sequence and
   story progression live in `src/core/` with no Godot includes, and are
   unit-tested natively. The Godot classes are thin adapters.
5. **No GDScript in shipped code.** GDScript is used only for headless test
   scripts under `project/tests/`, which the export excludes. This is proposed
   decision D4.

## 2. Layers

```
┌───────────────────────── Godot scenes (.tscn) ─────────────────────────┐
│ level.tscn, player.tscn, hud.tscn, title.tscn, ending.tscn             │
│ AnimationPlayer clips · Parallax2D · lights · audio · editor signals   │
└──────────────┬─────────────────────────────────────────────────────────┘
               │ GDExtension classes (src/*.cpp, namespace dagon)
┌──────────────▼─────────────────────────────────────────────────────────┐
│ PlayerController  Interactor  Interactable  StoryTrigger               │
│ PuzzleController  GameDirector  CameraRig  Hud  MenuController         │
└──────────────┬─────────────────────────────────────────────────────────┘
               │ plain C++20, no godot-cpp (src/core/)
┌──────────────▼─────────────────────────────────────────────────────────┐
│ movement.hpp (step function) · sequence_puzzle.hpp · story_progress.hpp│
└────────────────────────────────────────────────────────────────────────┘
```

## 3. Why 9 classes instead of the suggested 4

| Suggested | Proposed | Reason |
|---|---|---|
| PlayerController | **PlayerController** | Same. |
| InteractionSystem | **Interactor**, **Interactable**, **StoryTrigger** | Godot's `Area2D` overlap tracking already *is* the system. What remains is three small nodes, each about 60–100 lines: the player's sensor, the thing you examine, and the volume you walk into. A central "system" class would only duplicate the physics server's bookkeeping. |
| PuzzleController | **PuzzleController** | Same, with the logic in `core::SequencePuzzle`. |
| GameDirector | **GameDirector** | Same. It is kept narrow: story beats, input lock, and the cinematics it starts. It does not drive the camera, UI, audio or puzzle internals. |
| — | **CameraRig**, **Hud**, **MenuController** | Presentation code that would otherwise be GDScript (see D4). If D4 is rejected, these three move to GDScript and the C++ count drops to 6. |

## 4. Scene trees

### 4.1 `scenes/player/player.tscn`
```
Player                 PlayerController (CharacterBody2D)  layer=Player  mask=World
├── CollisionShape2D   CapsuleShape2D
├── Visual             Node2D           (scale.x flipped for facing)
│   └── Sprite         AnimatedSprite2D (idle, walk, jump, fall, flee)
├── Lantern            PointLight2D     (soft gradient texture, warm)
├── LanternFlicker     AnimationPlayer  (looping energy/offset jitter)
├── Interactor         Interactor (Area2D) layer=—  mask=Interactable
│   └── CollisionShape2D CircleShape2D r≈24
└── Footsteps          AudioStreamPlayer2D (AudioStreamRandomizer)
```

### 4.2 `scenes/level/level.tscn` (the whole game, 4 acts)
```
Level                       Node2D
├── GameDirector            GameDirector
├── Atmosphere              AnimationPlayer   clips: beat_shore, beat_abyss, beat_monolith,
│                                             beat_witness (crossfade ambience, CanvasModulate,
│                                             fog density, post-FX strength)
├── Cinematics              AnimationPlayer   clips: monolith_awaken, dagon_reveal, collapse
├── Tint                    CanvasModulate
├── Backdrop                Node2D
│   ├── Sky                 Parallax2D (scroll_scale ≈ 0)
│   ├── FarRidges           Parallax2D (0.1)
│   ├── DagonLayer          Parallax2D (0.15)
│   │   └── Dagon           Node2D  (Polygon2D/Sprite2D parts, hidden until reveal)
│   ├── MidRocks            Parallax2D (0.4)
│   └── FogBack             Parallax2D + ColorRect(fog shader)
├── Terrain                 Node2D
│   ├── Act1Ground …        StaticBody2D + CollisionPolygon2D + Polygon2D (visual)
│   └── Occluders           LightOccluder2D ×n
├── Props                   Node2D   Interactable instances (lifeboat, fossils, tablets, mural)
├── Monolith                Node2D
│   ├── Puzzle              PuzzleController
│   ├── GlyphWave / GlyphKneel / GlyphEye   Interactable (interaction_id = glyph_*)
│   ├── GlyphLights         PointLight2D ×3  (indicators[] of PuzzleController)
│   └── Gate                StaticBody2D (opened in C++ by GameDirector on Awakened; clip is visual only)
├── Triggers                Node2D   StoryTrigger: enter_abyss, reach_monolith, witness,
│                                    collapse; KillPlane (out_of_bounds). None self-latch;
│                                    GameDirector consumes on acceptance.
├── Checkpoints             Node2D   Marker2D ×4 (one per act)
├── CameraMarks             Node2D   Marker2D targets animated by Cinematics
├── Player                  player.tscn instance
├── CameraRig               CameraRig (Camera2D) limits set per level
├── Audio                   Node     AudioStreamPlayer per ambience layer + stingers
├── ForegroundFog           Parallax2D (scroll_scale > 1) + fog shader
├── Hud                     hud.tscn  (CanvasLayer: Prompt, Caption, Fade, PostFX)
└── PauseMenu               CanvasLayer (process_mode = Always) + MenuController
```

`title.tscn` and `ending.tscn` are separate small scenes. Each is a `Control`
with a `MenuController`. Flow: Title → Level → Ending → Title. The ending scene
is assigned to `GameDirector.ending_scene` as a `PackedScene`. No scene path
is hard-coded in C++.

**Terrain is drawn as polygons rather than a `TileMapLayer`.** The seabed is
organic silhouette work. A polygon pair (visual plus collision) per segment is
fast to draw in the editor and needs no tile art.

**Physics layers:** 1 World, 2 Player, 3 Interactable, 4 Trigger.

## 5. C++ class responsibilities

All classes live in `namespace dagon`. Properties are exported (`ADD_PROPERTY`)
so designers tune them in the inspector. Each class implements
`_get_configuration_warnings()` for missing references.

### PlayerController : CharacterBody2D
- **Owns:** horizontal movement, gravity, jumping (coyote time, jump buffer,
  variable height), facing, animation state, footstep cadence.
- **Exports:** `walk_speed`, `acceleration`, `deceleration`, `air_control`,
  `jump_velocity`, `jump_cut`, `coyote_time`, `jump_buffer_time`,
  `max_fall_speed`, `gravity_scale`, action names (`StringName`), `sprite`,
  `footsteps`.
- **API:** `set_control_enabled(bool)` and `is_control_enabled()`. While
  disabled, input is ignored but gravity still applies. `teleport(Vector2)`
  also clears velocity.
- **Signals:** `jumped`, `landed`, `footstep`.
- **Velocity has a single owner (review finding 5).**
  `CharacterBody2D::velocity` is the only stored velocity. `core::MoveState`
  holds only timers and flags: coyote timer, jump-buffer timer, `was_on_floor`,
  `jump_active`. Each physics frame:
  1. Read `v = velocity`. Read the floor contact as `Unknown` if
     `contact_stale_` is set; otherwise as `Grounded` or `Airborne` from
     `is_on_floor()`. These are the post-collision results of the previous
     `move_and_slide()`, so ceiling bonks and wall stops are already applied.
  2. Call `v' = core::step(state, params, input, v, contact, dt)`. This also
     updates the timers and returns `jumped` and `landed` events.
  3. Set `velocity = v'`, call `move_and_slide()`, then clear
     `contact_stale_`.

  `landed` means `contact == Grounded && !state.was_on_floor`, evaluated in
  step 2.
- **`teleport(p)`** sets `global_position = p` and `velocity = 0`, resets
  `state = MoveState{}`, and **sets `contact_stale_ = true` (review round 2,
  item 3)**.
  - `is_on_floor()` still holds the result of the last `move_and_slide()`
    before the teleport, so it must not be trusted until a fresh one has run.
  - `core::step` treats `Unknown` contact exactly as airborne for
    eligibility: it does not allow a grounded jump, does not refresh coyote
    time, does not emit `landed`, and leaves `was_on_floor` false. Gravity and
    the jump-buffer timer run normally.
  - `contact_stale_` is cleared only by the player's own `move_and_slide()`,
    so it works whether `teleport` is called before or after the player's
    physics step in a frame (for example, from a kill-plane signal).
  - **Jump buffering is preserved.** A jump pressed in mid-air after a
    teleport is buffered like any other. If real contact arrives within
    `jump_buffer_time`, the buffered jump fires on that genuine landing. That
    is valid; a jump granted by stale contact is not.

### Interactable : Area2D
- **Exports:** `interaction_id` (`StringName`), `prompt` (`"Examine"`),
  `caption` (multiline `String`, may be empty), `one_shot`, `enabled`,
  `cooldown` (s, default 0.4).
- **API:** `bool try_interact()`. Returns false if the object is disabled,
  already consumed, or cooling down. That return value is the single guard
  against duplicate activation. `bool is_available()` is the same check
  without side effects.
- **Signal:** `interacted(interaction_id: StringName)`.

### Interactor : Area2D (child of Player)
- Tracks overlapping `Interactable`s through `area_entered`/`area_exited`.
  Candidates are stored as `ObjectID`s.
- **Focus is recomputed every physics frame (review finding 8).** Each frame it
  drops candidates that no longer resolve, then picks the nearest one where
  `is_available()` is true. `focus_changed` is emitted only when the result
  differs from last frame. A focused object that is disabled, consumed or
  freed therefore loses focus within one frame, with no extra signals.
  Cost: fewer than 5 candidates in practice.
- On a press, focus is revalidated before calling `try_interact()`.
- Handles the `interact` action in `_unhandled_input` (`is_action_pressed`,
  not echo). It then calls `set_input_as_handled()`, so a press cannot reach
  two consumers and menus get the input first.
- Inert while the owning player's control is disabled.
- **Signals:** `focus_changed(target: Object /*Interactable or null*/)`,
  `interacted(target: Object)`. The Hud listens to both.

### StoryTrigger : Area2D
- **Exports:** `trigger_id`, `enabled`.
- Emits `triggered(trigger_id)` every time a `PlayerController` body enters
  while `enabled` is true.
- `bool is_player_inside()` checks `get_overlapping_bodies()`.
- **It never latches itself (review finding 2).** Consumption is the
  Director's decision; see "Trigger eligibility" under GameDirector.
- Monitoring stays on for the whole level, so the overlap list is always
  current.

### PuzzleController : Node
- Wraps `core::SequencePuzzle`.
- **Exports:** `solution` (`PackedStringArray` of interaction ids),
  `reset_delay` (1.0 s), `indicators` (array of node paths to lights or sprites,
  in solution order).
- **API:** `submit(id: StringName)`. Glyph `Interactable.interacted` connects
  here in the editor. Also `reset()` and `is_solved()`.
- **Signals:** `step_accepted(index)`, `failed`, `solved`.
- States: `Idle → Progress(n) → Solved`. A wrong input enters `Rejecting`
  (ignores input for `reset_delay`) and then returns to `Idle`. `Solved` is
  terminal and ignores everything after it.
- `core::SequencePuzzle::submit(id)` returns:

  | Situation | Result | Effect |
  |---|---|---|
  | `id` is the next stone in the solution | `Accepted`, or `Solved` on the last one | Progress advances |
  | `id` was already accepted in this attempt (a repeated press) | `Ignored` | None, no penalty |
  | Any other known `id` | `Rejected` | Enter `Rejecting`, then reset |
  | State is `Rejecting` or `Solved` | `Ignored` | None |
  | Unknown `id` | `Ignored` | The adapter calls `push_error` (wiring bug) |

### GameDirector : Node
- Wraps `core::StoryProgress`. The beats are `Shore → Abyss → Monolith →
  Awakened → Witness → Fleeing → Ended`. Transitions are strictly forward;
  duplicate and out-of-order events are rejected and logged (debug builds).
- **Exports:** `player`, `camera_rig`, `hud`, `atmosphere` (AnimationPlayer),
  `cinematics` (AnimationPlayer), `story_triggers` (array of StoryTrigger
  paths), `checkpoints` (array of Marker2D paths), `monolith_gate`
  (CollisionObject2D), `ending_scene` (`PackedScene`).
- **Exports (additional):** `flee_timeout` (s, default 12).
- **Inputs:**
  - `triggered` from every node in `story_triggers`. The Director connects
    these itself in `_ready`, because it already holds the list.
  - `on_puzzle_solved()` from PuzzleController.
  - Two internal events: `RevealDone` and `FleeTimeout`.

**Gameplay outcomes are separate from presentation (review finding 1).** Every
gameplay consequence of a beat is applied in C++. Clips are visual and audio
only, and nothing a clip does can be required for progress.

| Beat | Entered by event | Essential outcome (C++, idempotent) | Presentation | Locking cinematic |
|---|---|---|---|---|
| Shore | (start) | Checkpoint 0 | `beat_shore` | — |
| Abyss | `enter_abyss` trigger | Checkpoint 1 | `beat_abyss` | — |
| Monolith | `reach_monolith` trigger | Checkpoint 2 | `beat_monolith` | — |
| Awakened | `PuzzleSolved` | Checkpoint 3. **Open the gate:** gate `collision_layer = 0`, deferred. | glow, rumble, gate visual | `monolith_awaken` |
| Witness | `witness` trigger | Control locked | Dagon rises | `dagon_reveal` |
| Fleeing | `RevealDone`, raised by the reveal's finalizer **on every exit path**: normal completion, missing clip, looping clip refused, watchdog | Control unlocked. Start the flee timer. | `beat_fleeing`: shake, roar (fire-and-forget) | — |
| Ended | `collapse` trigger **or** `FleeTimeout` | Control locked. After the collapse cinematic: `reset_global_state()`, then `change_scene_to_packed(ending_scene)` | fade to black, inside the clip | `collapse` |

**Flee behaviour (single ending):**
- After the reveal, the way right (towards the trench) is a solid rock wall,
  so moving the wrong way just presses against it.
- The flee timer accumulates in the Director's `_process`, so it pauses with
  the tree. If the player waits or goes the wrong way for `flee_timeout`, the
  sailor collapses where he stands.
- Reaching the `collapse` trigger ends the flee sooner.
- Both routes lead to the same Ended beat and the same ending. No new ending
  is added.

**Cinematic contract (review findings 6 and round 2 item 4):**
- Only the Director plays clips on `cinematics`. Nothing waits on
  `atmosphere`.
- **Active-cinematic record:** `{clip, generation, beat}`. `generation` is a
  counter that only increases.
- `start_cinematic(name)`:
  - If a cinematic is already active: `push_error` and return `false`. **The
    active cinematic is left untouched, not finalized.** Only a bug can reach
    this, because events are not applied during cinematics (see below).
  - Otherwise: increment `generation`, record the active cinematic, set the
    deadline to clip length + 2 s, lock control, and play.
  - Missing clip, or `loop_mode != LOOP_NONE`: `push_error`, then
    `finalize_cinematic(generation)` on the cinematic just recorded.
- `animation_finished(name)` leads to `finalize_cinematic(active.generation)`
  only if a cinematic is active and `name == active.clip`. Anything else is
  ignored.
- The watchdog in `_process` checks the deadline of the *active* generation
  only, and pauses with the tree.
- **`finalize_cinematic(gen)`**:
  1. If there is no active cinematic, or `gen != active.generation`, return.
     Stale and duplicate completions have no effect.
  2. If the clip is still playing (the watchdog path), stop the player, so a
     leftover method track cannot move the camera afterwards.
  3. Apply the beat's essential outcome (idempotent), restore the camera
     (target = player, default zoom, no shake), set control to the beat's
     state, and clear the active record.
  4. `call_deferred("_after_cinematic", finished_clip)`. **It never processes
     story events synchronously**, so a beat started next cannot be
     overwritten by this finalizer. `call_deferred` only guarantees that the
     call runs after the current one, in the same frame's deferred flush. It
     does **not** wait for a new physics frame.
- **`_after_cinematic(clip)`** runs in this order:
  1. If `clip == dagon_reveal`, process `RevealDone`.
  2. Process the pending internal event, if any.
  3. **Overlap checks wait for fresh physics data.** The Director records
     `recheck_after = Engine::get_physics_frames()`. Its own
     `_physics_process` runs the checks once
     `Engine::get_physics_frames() >= recheck_after + 2`, which guarantees at
     least one completed physics step and an up-to-date overlap list. The
     checks are:
     - the current beat's awaited trigger, via `is_player_inside()`;
     - the pending out-of-bounds recovery (below).

  Each step stops if it started a new cinematic. Exact frame arithmetic is
  verified in M3.

**Events during a cinematic:** while a cinematic is active, `process_event`
does not touch `StoryProgress`.
- Trigger events are dropped and **not consumed**. Rule 3 of
  `_after_cinematic` re-checks them.
- Internal or signal events (`PuzzleSolved`) go into a single `pending` slot.
  More than one pending event is a logic error and is reported with
  `push_error`.

This is a guard plus one deferred step, not an event framework.

**Trigger eligibility (review finding 2):**
- `core::StoryProgress::apply(event)` either accepts or rejects. A rejection
  changes nothing, and the trigger stays armed.
- Only on acceptance does the Director set that trigger's `enabled = false`.
- On entering a beat with no cinematic, and in `_after_cinematic`, the
  Director checks the awaited trigger with `is_player_inside()`. This covers a
  player who is already standing in it.
- Example: crossing the `collapse` trigger on the way out (beat = Monolith)
  is rejected and consumes nothing. It fires on the return (beat = Fleeing).
- `out_of_bounds` is not a story event and is never consumed.
  - Outside cinematics, it calls `player.teleport(active checkpoint)`
    immediately.
  - **During a cinematic it is not lost (M3 follow-up).** Gravity still
    applies, so the player can fall into the kill plane while control is
    locked. The Director sets `recovery_pending = true`.
  - After finalization, on the physics-fresh re-check above, it teleports if
    `recovery_pending` is set **or** the kill plane reports
    `is_player_inside()`, then clears the flag.

### CameraRig : Camera2D
- Follows a `target` Node2D with a look-ahead in the facing direction.
  Smoothing uses Camera2D's built-in position smoothing, and the level limits
  use Camera2D's built-in limits.
- `set_target(Node2D)` lets cinematic clips retarget the camera to a
  `CameraMarks` marker. Clips also key `zoom` directly.
- Screen shake: `add_trauma(amount)` gives a decaying, noise-driven `offset`.
  Clips can call it through method tracks.

### Hud : CanvasLayer
- Shows and hides the prompt label (`Interactable.prompt` + action glyph).
- Shows captions (fade in, hold ~4 s, fade out with a Tween; a new caption
  replaces the old one).
- Tweens are always created with `Node::create_tween()`, which binds them to
  the Hud, so they die with it. They are never created with
  `SceneTree::create_tween()`. The previous tween is `kill()`ed before a new
  one starts.
- `fade_to_black(duration)`/`fade_from_black(duration)`, then emits
  `fade_finished`.
- Exposes the post-FX `ColorRect` shader parameter `strength` for Atmosphere
  clips (stretch).

### MenuController : Control
- `mode` = Title | Pause | Ending.
- Bound methods for Button `pressed`: `start_game`, `resume`, `restart`,
  `quit_to_title`, `quit_game`.
- In Pause mode it toggles `SceneTree.paused` on the `pause` action and grabs
  focus for gamepad navigation.
- Every scene transition (`start_game`, `restart`, `quit_to_title`, and the
  Director's ending) first calls `dagon::reset_global_state()` (review finding
  4). See §7 rule 8.

### Plain-C++ core (`src/core/`, no Godot headers)
- `movement.hpp/.cpp`: `MoveParams`, `MoveState` (timers and flags only, no
  velocity), `MoveInput`, `Vec2`, and
  `enum class FloorContact { Airborne, Grounded, Unknown }`, and
  `StepResult step(MoveState&, const MoveParams&, const MoveInput&, Vec2 velocity, FloorContact contact, float dt)`,
  which returns the new velocity plus events (jumped, landed). `Unknown` is
  airborne for eligibility (see PlayerController `teleport`).
- `sequence_puzzle.hpp/.cpp`: `SequencePuzzle` (N-step, string ids), with
  `submit(id, now)` returning `Accepted | Rejected | Solved | Ignored`.
  Time is passed in, so tests need no clock.
- `story_progress.hpp/.cpp`: `StoryProgress`, with `enum class Beat`,
  `enum class Event`, and `std::optional<Beat> apply(Event)`.

## 6. Signal and wiring map

```
Interactor.focus_changed ─────────► Hud.show_prompt / hide_prompt
Interactor.interacted ────────────► Hud.show_caption(target.caption)
GlyphX.interacted(id) ────────────► PuzzleController.submit(id)
PuzzleController.solved ──────────► GameDirector.on_puzzle_solved
StoryTrigger.triggered(id) ───────► GameDirector (connected in code, _ready, from story_triggers)
Cinematics.animation_finished ────► GameDirector (connected in code, _ready)
PlayerController.footstep ────────► Footsteps.play
```

The ending no longer depends on `Hud.fade_finished`. The fade is part of the
`collapse` clip, and the scene change is the Ended beat's essential outcome,
applied in `finalize_cinematic`.

```
```

All of these except the ones marked "connected in code" are editor
connections stored in the `.tscn`. An integration test asserts that every expected trigger
id and connection exists, so a renamed node fails CI instead of failing
silently.

## 7. Ownership and lifetime rules (godot-cpp)

1. **Nodes are owned by the scene tree.** C++ never `delete`s a node. `memnew`
   is used only when the result is immediately `add_child`'d. We do not expect
   to need runtime node creation in the MVP.
2. **Resources and other `RefCounted` objects are always held in `Ref<T>`**
   (RAII). `Tween`s live in a `Ref<Tween>` member and are `kill()`ed before
   being replaced.
3. **No raw node pointer is kept past the current call (review finding 3).**
   Any node can be freed independently of its parent, so being a descendant
   proves nothing.
   - Every cached node reference is a `NodeRef<T>`: a ~15-line wrapper around
     `ObjectID` whose `get()` returns `T*` or `nullptr` through
     `ObjectDB::get_instance()` and `Object::cast_to<T>`. Callers null-check
     every `get()`.
   - Exported references are `NodePath`s, resolved into `NodeRef`s in `_ready`
     and listed in `_get_configuration_warnings()`.
   - This is one uniform rule instead of a judgement about which children are
     "permanent". The lookup cost is negligible at our node counts.
4. **Signal connections use `callable_mp(this, &T::method)`.** Godot
   disconnects them automatically when either object is freed. No manual
   bookkeeping.
5. **No static mutable state** in extension code. Every piece of state belongs
   to a node instance, which is what makes restart via scene reload correct.
6. **No exceptions.** godot-cpp builds with exceptions disabled by default.
   Errors use `ERR_FAIL_*` macros or `push_error`, and the game continues in a
   degraded state where possible.
7. Editor safety: gameplay `_process`/`_physics_process` return early when
   `Engine::is_editor_hint()` is true.
8. **Engine-global state survives a scene reload (review finding 4).** The
   complete list of global state we may touch:
   - `SceneTree.paused`
   - AudioServer bus volume, mute and effect parameters
   - `Input` mouse mode
   - `Engine.time_scale`

   Rules:
   - `dagon::reset_global_state()` restores all of it to project defaults.
   - It runs before every scene transition, and again (with a debug-build
     warning if anything was dirty) in `GameDirector::_ready`.
   - Rule for presentation: clips must not mutate AudioServer. Low-pass
     sweeps are baked into the audio assets or use per-player volume only.
   - Any new global must be added to this list and to the function.

## 8. Testing strategy

| Level | What | How | Runs in |
|---|---|---|---|
| Unit | `core::step`, `SequencePuzzle`, `StoryProgress` | doctest, native binary (`scons unit_tests`) | CI Linux + Windows |
| Extension load | All 9 classes registered, with key methods and signals bound | `godot --headless --script res://tests/check_classes.gd` | CI Linux |
| Integration | M1: spawn and land; walk distance; jump arc; wall stop; teleport contact invalidation (roadmap M1 7f). M2: focus gained and lost; focused object disabled or freed → focus cleared, no crash; double press → 1 event; Interactable `one_shot`. M3: puzzle right, wrong, repeated press and reset; trigger re-entry → 1 beat; **outbound crossing of `collapse` → not consumed, fires later in Fleeing**; player already inside the awaited trigger at beat entry → fires; cinematic lock and unlock; **missing clip, looping clip and watchdog timeout → gate open, camera restored, correct control state, `RevealDone` raised once**; **already-overlapping next trigger during finalization → next cinematic keeps its lock and camera**; **duplicate completion/finalization → outcome applied once**; **stale completion (older generation) → no effect on the newer cinematic**; **entering the kill plane while control is locked → recovered after finalization**; flee timeout → Ended; pause → restart and pause → title → start → unpaused; reload resets state; wiring check | Hand-rolled headless SceneTree runner (~80 lines, no GUT); rules below | CI Linux |
| Smoke | Main scene runs 600 frames with no `ERROR:` lines | `--headless --quit-after 600` piped through grep | CI Linux |
| Export | Linux and Windows release exports build. The Linux export runs `--quit-after 300` with exit 0 and no errors. | `--export-release` | CI Linux (export); Windows run is manual or on a Windows runner |
| Manual | Feel, readability, pacing, audio mix, a full playthrough on Windows and Linux | Checklist per milestone | Human |

Reports always state which of these levels actually ran.

**Headless integration-test rules (review round 2, item 7):**
- **Fixed physics tick:** `physics/common/physics_ticks_per_second = 60` in
  `project.godot`, run with `--fixed-fps 60`, and a test asserts both the tick
  rate and that one probe step equals one physics tick. Neither is claimed to
  make physics fully deterministic; they only make frame counting reproducible.
  *M1 change:* `max_physics_steps_per_frame = 1` was **not** set as first
  planned. It is a shipped-game setting, and it would slow the game down on
  machines below 60 FPS. `--fixed-fps` already gives one step per frame in tests.
- **Observation point (M1 follow-up):** `SceneTree.physics_frame` is emitted
  *before* the nodes' `_physics_process` callbacks, so awaiting it does not
  mean the player has finished the step being measured.
  - Tests observe through a test-only `StepProbe` node
    (`project/tests/step_probe.gd`), with `process_physics_priority = 1000` so
    it runs after every gameplay node. It emits `stepped(physics_frame)` at the
    end of each tick.
  - `test_probe_observes_after_player_step` proves the ordering: within one
    tick, the position at `physics_frame` is the old one and the position at
    `stepped` includes that tick's movement. Reversing the priority makes this
    test fail (`docs/evidence/m1/mutation/probe-order.txt`).
- **Order within a test step:** inject, then await N `StepProbe.stepped`
  signals, then observe. Never inject and observe in the same tick.
- **Injection method:**
  - `Input.action_press` / `action_release` for **polled** input (the
    movement axis and jump state in `_physics_process`, M1).
  - `Input.parse_input_event()` with `InputEventAction` press and release
    events for **event-path** input (`Interactor._unhandled_input` delivery
    and `set_input_as_handled` consumption, M2). Polled-state injection does
    not exercise the event callback path.
- **Isolation:** at the end of each test (pass or fail), release every action
  in the project's InputMap, then reload the scene or reset the fixture.
- **Assertions use tolerances** (positions ±2 px, velocities ±1 %) and
  **bounded waits**: `wait_until(cond, max_frames)` fails with a message
  instead of hanging.
- **Scope limit:** simulated actions test game logic. They do **not** verify
  physical keyboard or controller mappings, which are checked manually.

## 9. CI (GitHub Actions)

- `ci.yml` runs on push and PR.
  - `build` matrix: linux and windows, each with template_debug and
    template_release. It uses godot-cpp's own `setup-godot-cpp` and cache
    actions with `scons-version: 4.9.1`.
  - `unit` job: Linux and Windows.
  - `godot-tests` job (Linux): downloads the pinned Godot 4.7.2 Linux binary
    and checks it against `SHA512-SUMS.txt`. It runs
    `tools/prepare_project.sh`, then **one** import, where any non-zero exit
    fails the job (see toolchain §5). Finally it runs the extension-load,
    integration and smoke tests. Logs are uploaded as artifacts.
  - `windows-load` job: on the Windows runner, downloads the pinned
    `Godot_v4.7.2-stable_win64.exe.zip` (SHA-512 checked), runs
    `tools/prepare_project.ps1` and the import, then the extension-load check
    against the MSVC-built debug library. This is the D2 runtime validation.
  - Every build job prints the exact compiler version (`cl` banner or
    `g++ --version`) into its log.
- `release.yml` runs on a `v*` tag or by hand. It builds release libraries,
  downloads and caches the export templates with a SHA-512 check, exports
  Linux and Windows, runs the Linux export smoke test, zips both, uploads them
  as artifacts, and attaches them to a GitHub Release. itch.io upload with
  butler stays manual (no secrets needed in CI).
- Action pins: GitHub-owned actions at major versions matching the template
  (`actions/checkout@v7`, `actions/upload-artifact@v7`). Third-party actions
  are pinned by commit SHA.
- No compiled binaries are committed. `project/bin/*/` is gitignored, and only
  `dagon.gdextension` is tracked.

## 10. Repository layout

```
dagon/
├── SConstruct              # template-derived + C++20 env + unit_tests alias
├── methods.py              # from template
├── godot-cpp/              # submodule @ 507ed9d (10.0.0-stable)
├── src/
│   ├── register_types.{hpp,cpp}
│   ├── player_controller.{hpp,cpp}  interactor.*  interactable.*  story_trigger.*
│   ├── puzzle_controller.*  game_director.*  camera_rig.*  hud.*  menu_controller.*
│   └── core/  movement.*  sequence_puzzle.*  story_progress.*
├── tests/unit/             # doctest.h (vendored v2.5.3) + test_*.cpp
├── project/
│   ├── project.godot  export_presets.cfg
│   ├── bin/dagon.gdextension
│   ├── scenes/{level,player,ui}/   assets/{art,audio,fonts}/   shaders/
│   └── tests/              # headless GDScript tests (excluded from export)
├── tools/                  # prepare_project.{sh,ps1} (toolchain §5); asset-generation scripts
├── docs/                   # this documentation
└── .github/workflows/      # ci.yml, release.yml
```
