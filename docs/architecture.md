# Technical Architecture

Status: Phase A, **conditionally approved** by the independent reviewer
(2026-10-28). The round-2 corrections are applied below. Approved decisions
and the remaining validation are tracked in [decisions.md](decisions.md).
Toolchain: see
[toolchain.md](toolchain.md). The menu, settings and save design in §5 ([D26](decisions.md))
came after that approval, and was approved for implementation with the reviewer's corrections included below.

**Status: M1, M2 and M3 are accepted by the owner, M3 on 2026-11-10 at `3980bc3`.** *The owner's revision of 2026-11-09 (D70–D81) added: a prologue mode in `MenuController`; the crossing, the returning sea, breathing and idle pace in `GameDirector`, with the sea's rules in plain C++ (`core::flee`); footsteps in `PlayerController`; and a quiet way out that stops all sound before quitting (`global_state`). Still 11 classes. The completion pass (D87–D93) made the crossing a pushed stone (`GameDirector` drops it and works out the slab's transform itself), gave each prologue picture motion and sound started and stopped by `MenuController`, faded the prologue and the ending before their scene changes, and added a limiter on the Master bus.* Where M3 measured or chose
something this design left open, the section says so, and [decisions.md](decisions.md) §8 lists each one.

## 1. Principles

1. **Godot does the heavy lifting.** Physics (`CharacterBody2D`, `Area2D`),
   cinematics (`AnimationPlayer`), lighting (`PointLight2D`, `CanvasModulate`),
   parallax (`Parallax2D`), audio buses, tweens, scene reload. C++ adds only
   behaviour Godot does not have.
2. **State lives in the level scene.** There are no autoloads and no
   singletons. Restart rebuilds every piece of state from scratch, by
   replacing the world under a small session node rather than reloading the scene (§5, GameSession). The only state that
   outlives a scene or the application is in two files, settings and one save slot (§5, Persistence).
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
│ SettingsMenu  GameSession  + stateless functions: storage              │
└──────────────┬─────────────────────────────────────────────────────────┘
               │ plain C++20, no godot-cpp (src/core/)
┌──────────────▼─────────────────────────────────────────────────────────┐
│ movement.hpp (step function) · sequence_puzzle.hpp · story_progress.hpp│
│ save_data.hpp · settings_data.hpp                                      │
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
| — | **SettingsMenu**, **GameSession** | Added after Phase A for the owner's usability scope ([D26](decisions.md)), making 11 classes. Rebinding has enough states to stay out of MenuController, and the session checkpoint has to outlive the world it restores. |

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

*Built in M3 as `scenes/level/shore.tscn`, the world that `game.tscn` plays in ([D30](decisions.md)), with the accepted art to
x = 640 and greybox beyond. The file keeps its name, because tests, tools and the Shore art refer to it. `scenes/level/level.tscn` is still the
M1 movement test scene, not exported, and it matches the world's collision only as far as x = 980 ([D48](decisions.md)).*

*The tree below is the design. As built: `GameDirector` is the world's last child, so every node it refers to is ready first. There is one
`FarRidges` parallax layer, a nearer `RitualLayer`, and no `MidRocks`, `Audio` or post-FX, which belong to M4 and M5. `Dagon` and `Trench` are plain nodes in world space, and
a far ridge that is part of `Dagon` stands in for the parallax. The stones' indicators are `Polygon2D`s, not lights. A `Background` AnimationPlayer holds the background events, and `Ledges` the two shelves. The `Voice` player is in `hud.tscn`. The act layout is in [D48](decisions.md) and [D56](decisions.md).*

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

`title.tscn` (the main menu, and the main scene) and `ending.tscn` are
separate small scenes. Each is a `Control` with a `MenuController`. Flow: Main menu →
Game → Ending (the epilogue, then the credits) → Main menu. `game.tscn` holds a `GameSession` with the level as its
world, and the `PauseMenu` sits beside it, so the menu survives a restart. The pause menu quits to the
desktop or to the main menu. Quit to Desktop on the main menu exits at once, because there is nothing there to lose.
`settings_menu.tscn` is instanced by both the pause menu and the main menu. The ending scene
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
  in solution order), `stones` (array of paths to the `Interactable`s).
- **API:** `submit(id: StringName)`. Glyph `Interactable.interacted` connects
  here in the editor. Also `reset()`, `is_solved()`, and `restore_solved()`, which goes
  straight to the stable state, emits nothing, and works before `_ready`.
- **Signals:** `step_accepted(index)`, `failed`, `solved`.
- States: `Idle → Progress(n) → Solved`. A wrong input enters `Rejecting`
  (ignores input for `reset_delay`) and then returns to `Idle`. `Solved` is
  terminal and ignores everything after it.
- **Time** accumulates in `_process`, so the lockout stops while the game is paused.
- **Feedback without audio:** the lit stones, and captions connected to `Hud.show_caption` in the scene, with their text as
  bound arguments. A stone's own caption stays empty, or it would replace that text. The stones are disabled during the lockout, so
  the prompt goes away and comes back with them. After solving they stay disabled.
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
- **Exports (additional):** `flee_timeout` (s, default 12), `kill_plane_path`, `puzzle_path`, `mural_path`, `mural_solved_line`, `background_path`,
  `background_triggers`, and `awakened_visuals` (what the Awakened beat shows, such as the lit mural).
- **Signals:** `checkpoint_reached(index)` for savable beats only, once finalized. `beat_changed`, `cinematic_started`,
  `cinematic_finalized`, `overlap_rechecked`, `background_event_started`, `player_respawned`. `contract_error` repeats each `push_error` of this contract, so a test can count them and read what they say.
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
| Monolith | `reach_monolith` trigger | Checkpoint 2 | `beat_monolith`, and the line `monolith.first`, on the way in only | — |
| Awakened | `PuzzleSolved` | Checkpoint 3. **Open the gate:** gate `collision_layer = 0`, deferred. | glow, rumble, gate visual | `monolith_awaken` |
| Witness | `witness` trigger | Control locked | Dagon rises | `dagon_reveal` |
| Fleeing | `RevealDone`, raised by the reveal's finalizer **on every exit path**: normal completion, missing clip, looping clip refused, watchdog | Control unlocked. Start the flee timer. The sailor turns to face left, as the cue to run. **Rock comes down across the way back:** `Rockfall` gets its collision layer, deferred, and shows. The clip only drops it into view, so it is there with no clip. | `beat_fleeing`: shake, roar (fire-and-forget) | — |
| Ended | `collapse` trigger **or** `FleeTimeout`, which since D73 means the returning sea has reached him, or the 30 s fallback | Control locked. After the collapse cinematic: `reset_global_state()`, then the scene changes to `ending_scene`, from the deferred step ([D50](decisions.md)) | fade to black, inside the clip | `collapse` |

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
  0. If it is no longer in the tree, it does nothing. If the beat is Ended, it changes scene and stops ([D50](decisions.md)).
  1. If `clip == dagon_reveal`, process `RevealDone`.
  2. Process the pending internal event, if any.
  3. **Overlap checks wait for fresh physics data.** The Director records
     `recheck_after = Engine::get_physics_frames()`. Its own
     `_physics_process` runs the checks once
     `Engine::get_physics_frames() >= recheck_after + 3`, which guarantees at
     least one completed physics step and an up-to-date overlap list. The
     checks are:
     - the current beat's awaited trigger, via `is_player_inside()`;
     - the pending out-of-bounds recovery (below).

  Each step stops if it started a new cinematic.

  **The frame arithmetic, measured in M3 ([D49](decisions.md)).** This design first said `+ 2`. On 4.7.2, a body moved in the physics phase of
  frame F is in the overlap list at F + 2, but one moved in the idle phase of F, which is where a clip ends, is only there at F + 3, because that
  frame's server step has already gone by. So `+ 2` was one frame short for the case that matters most, and two tests failed on it. Measurements:
  [overlap-latency.txt](evidence/m3/overlap-latency.txt).

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
- A puzzle solved before its beat, which the layout should make impossible, is rejected like anything else, and the
  recheck on entering the Monolith beat takes it up, so nobody is left with a solved puzzle and a story that cannot move.
- `out_of_bounds` is not a story event and is never consumed.
  - Outside cinematics, it calls `player.teleport(active checkpoint)`
    immediately. The active checkpoint of the final sequence is the Awakened one.
  - **During a cinematic it is not lost (M3 follow-up).** Gravity still
    applies, so the player can fall into the kill plane while control is
    locked. The Director sets `recovery_pending = true`.
  - After finalization, on the physics-fresh re-check above, it teleports if
    `recovery_pending` is set **or** the kill plane reports
    `is_player_inside()`, then clears the flag.

### CameraRig : Camera2D
- Follows a `target` Node2D with a look-ahead in the facing direction. `pixel_lock`, on by
  default, keeps the camera a whole number of pixels from the target, so the two cannot round
  apart and flicker on screen. Position smoothing would defeat it and is not used; `lock_speed`
  slides the look-ahead ([D22](decisions.md)). The level limits use Camera2D's built-in limits.
- `set_target(Node2D)` lets cinematic clips retarget the camera to a
  `CameraMarks` marker, and clips reach it through `aim_at(path)`, since a method track can hold a path.
  Clips also key `zoom` and the limits directly.
- Screen shake: `add_trauma(amount)` gives a decaying `offset` in whole pixels, from two sines, which is enough for a greybox.
  Clips can call it through method tracks. It stops while the game is paused.
- `restore_view(target)` puts the target, zoom, limits and shake back as the scene set them, whatever a clip left behind.

### Hud : CanvasLayer
- Connects itself to the Interactor in code, from the exported `interactor_path` ([D37](decisions.md)). The export drops scene
  connections that start inside an instanced scene.
- Shows and hides the prompt label: the button for the device in use, then `Interactable.prompt`. The session tells it
  which device that is (`set_input_device`), because the Hud pauses with the world and so cannot watch input itself.
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
- **Owns the active input device ([D40](decisions.md)),** in `_input`, because it keeps running while paused. It passes the device
  on to `GameSession`, and from there to the Hud. A disconnection of that device hands back to the keyboard, and a reconnection
  changes nothing until the controller is used. Going between scenes, it sets the device on the new scene before that scene enters the tree.
- Bound methods for Button `pressed`: `new_game`, `continue_game`, `resume`,
  `restart_checkpoint`, `open_settings`, `open_controls`, `open_credits`, `quit_to_main_menu`,
  `quit_game`, `back`.
- In Pause mode it toggles `SceneTree.paused` on the `pause` action. Its
  `process_mode` is Always, so the menu stays responsive while movement, timers and clips
  stop.
- **Focus:** a control always has focus while a menu is open, for keyboard and gamepad.
  Returning from a submenu gives focus back to the control that opened it. If focus is ever lost, the next press
  returns it to a visible control on the active screen, and inside a conflict's choice during a conflict, without
  changing anything else.
- **Back** (`ui_cancel`: Esc, gamepad east) closes one level, and the input is marked
  as handled so that one press cannot do two things. At the pause root it resumes. At the main menu
  root it does nothing, so nobody quits by accident. In a confirmation it cancels.
- **Restart Checkpoint** asks `GameSession` to rebuild the world at the session checkpoint.
- **Quitting** states what will happen (see Persistence), from the pause menu, in both forms.
- `_ready` applies the saved settings, so they take effect before the player can act.
- Every scene transition (`new_game`, `continue_game`, `quit_to_main_menu`, and
  the Director's ending) and `restart_checkpoint` first call
  `dagon::reset_global_state()` (review finding 4). See §7 rule 8.

### Narration (`src/narration.*`, `src/core/narration.*`, in `Hud` and `MenuController`)
**One script, `project/narration/script.txt`:** each line is `id|optional or story|words`. The game shows those words, and the voice tool (`tools/audio/make_audition.py --speak`, since the owner's choice of voice) speaks them, so they cannot drift apart; `tools/audio/check_narration.py` transcribes each recording and compares it with the script. An `Interactable` names a `line_id`, and takes its caption from the script. A line's audio, if it has any, is `res://assets/narration/<id>.ogg`. A line with no file is a text line, so nothing depends on audio being there.

**Rules, in plain C++ and unit-tested:**
- `decide_line`: there is no queue. Nothing speaking: start. The same line: ignored, never restarted. A story line replaces anything. An optional line replaces an optional one, and is dropped during a story line.
- `line_seconds`: a caption lasts through its audio and 0.8 s, and never less than its reading time at 15 characters a second. With no audio, the reading time, and never less than the minimum.

**`Hud::say(id)`** does both together, on a child `AudioStreamPlayer` on the `Narration` bus. `hide_caption` stops both. **`show_caption(text)`** is for feedback the player has just caused, such as a stone's response: it replaces anything, and is not a line. Time runs on a tween bound to the Hud, and the player pauses with it, so a pause holds both, and leaving the world stops both.

**Skipping:** the `interact` action. `Hud::_unhandled_input` runs before the Interactor's, as it comes later in the tree. If something is being said, the press is used up as a skip, unless it would start a different optional line on something else in reach, in which case it passes through and replaces it. So a skip can never also examine.

**Subtitles off** hides only a line that is really being heard. Text lines, feedback, prompts and the epilogue's card always show.

**Who starts a line:** the player, by examining. A clip's method track at its moment (`Hud.say`), which cannot happen on restore, as no clip plays then. And `GameDirector` on the way into the Monolith beat only, which a restored world does not pass through. **So restoring speaks nothing.**

**The epilogue:** `MenuController` in Ending mode shows `ending_lines` one at a time on the card, each with its audio if any and over its own picture (`panels_path`), as the prologue does, moving on by itself after `line_seconds`. Both are fully spoken, the prologue since M4: the card waits for each recording, and Continue, Skip and the credits each stop the one playing. Continue moves on at once, and goes to the credits after the last, so nobody is made to wait.

### Controller vibration (`src/haptics.*`)
Stateless, with three named cues, each under a second. `GameDirector::haptic_cue(name)` plays one on the device in use, if it is a controller and the setting is on, and clips call it through a method track at their moment. **It alone stops them,** on `NOTIFICATION_PAUSED`, on a change of device, and on leaving the tree, and a cue is never resumed. A new cue replaces the last, as `Input` holds one per device. A paused or stopped clip cannot reach its key, so a stale cue cannot fire. Tests read `Input.get_joy_vibration_strength`, which proves requests only, and says nothing about feel or hardware.

### Background events (`GameDirector`, `Background` AnimationPlayer)
Presentation only. A `StoryTrigger` in `background_triggers`, whose id names a clip on `Background`, plays it once in this world, and is spent. **Nothing depends on one, and no state is saved.** During a cinematic, or while another is playing, the trigger stays armed for the next crossing.
- **A world rebuilt at or after a trigger's `spent_from_beat`** treats it as already past, and it never plays. All three are set to the Monolith.
- **So after Restart or Continue:** at the Shore or Abyss, they lie ahead and play when reached, once. At the Monolith or later, never.
- They are built to be seen without precise timing. The ritual lasts 13 s and starts in the right half of the view, and a test holds a walking player to at least 6 s with its watcher on screen.

### Input labels (`src/input_labels.*`, `src/core/controller_labels.*`)
Stateless, and no class. The plain-C++ half decides a controller's family from the driver's name and USB vendor id, and names
buttons for each family, so it is unit-tested without Godot. The Godot half asks the `Input` singleton and builds the text for the
prompt and Controls. Bindings stay positional: Interact is the west button on every controller ([D39](decisions.md)). Only the
name changes. `DAGON_TEST_CONTROLLER` stands in for the driver's name ([D41](decisions.md)).

### SettingsMenu : Control (M2)
- Music volume, effects volume, keyboard bindings, Restore Defaults, Back. The volumes are stored
  and set on the `Music` and `Effects` buses, and do nothing audible until audio exists. `AudioNote`, a plain
  `Label` below them, says so. It cannot take focus or clicks, and is removed when audio is connected ([D42](decisions.md)).
- **Rebindable:** one keyboard key each for `move_left`, `move_right`, `jump` and `interact`
  ([D32](decisions.md)). Gamepad mappings are fixed for the jam.
- **No way to get trapped:** the `ui_*` actions and `pause` cannot be rebound, so menu navigation
  and Back always work, whatever the gameplay bindings are. The Left and Right arrows stay on movement and Esc
  stays on pause, and those three cannot be assigned elsewhere. Up and Down can be rebound, and still navigate
  menus, because menus use their own actions.
- **Capture:** the next key press becomes the binding. Esc or gamepad Back cancels with no change, and Esc
  cannot be bound. While capturing, the menu consumes all input.
- **Conflicts:** the row explains which action already has the key and offers Swap or Cancel, so no
  action can end up without a key.
- Restore Defaults can always be reached from keyboard and gamepad.
- **If a write fails,** the player is told, the change still applies, and the menu keeps it until a later write
  succeeds or the player quits. The warning shows for as long as something is unsaved, including on reopening.
  Capture and conflict text replaces it, and it returns when they end. A good write removes it.

### GameSession : Node
The root of `game.tscn`. Its children are the world, an instance of the level from an exported `PackedScene`, and the
`PauseMenu`.
- **It owns one small value, the session checkpoint:** the latest safe checkpoint reached this session, as a
  `core::SaveData` value with no node references. It also remembers what was last written to disk. No singleton is
  needed, because this lives and dies with the scene.
- `GameDirector` emits `checkpoint_reached` once a beat has finalized. The session updates its checkpoint first and
  then tries the write, so a failed write cannot lose it.
- **Restart Checkpoint** frees the world, instantiates a fresh one and gives it the session checkpoint. It reads no
  file, so it works after a failed autosave. A scene reload would destroy the value, so it is not used here, but every
  piece of world state is still rebuilt from scratch, as D5 intends.
- **Replacing the world (review requirement):** the old world's active signals and callbacks are removed, and the new
  director has its checkpoint before it enters the tree.
- It starts from a value the main menu sets on the new instance, passed with `change_scene_to_node`. With none, as
  when a developer runs the scene directly, it starts at Shore. It never reads the save.
- It keeps the active input device across world replacement, and gives each new world's Hud the device at once.

### Persistence

Settings and progress are separate files, so replacing or losing one never affects the other.

| File | Holds | Written |
|---|---|---|
| `settings.cfg` | Version, volumes, keyboard bindings | When the player changes a setting |
| `save.dat` | Version, story beat, checkpoint id | At a safe checkpoint |

**No autoload.** `storage` is a file of stateless functions. Every path starts from one function,
`storage_root()`, which returns `user://` unless `DAGON_STORAGE_DIR` is set (§8, test storage). Parsing, validation and
serialization are plain C++ in `core::settings_data` and `core::save_data`, so they are unit-tested without Godot.

**Two different checkpoints:**

| | Session checkpoint | Last persisted save |
|---|---|---|
| Lives in | `GameSession`, in memory | `save.dat`, or `save.bak` |
| Updated | Whenever a safe checkpoint is reached | When a write succeeds |
| Used by | Restart Checkpoint | Continue after a relaunch |

They differ only after a failed write, and the next checkpoint tries again.

**What can be saved.** Only stable progress: never a node reference, a position between checkpoints or clip
state. The checkpoint id is the stable name of its `Marker2D`, and must be the one that belongs to the beat.

| Beat | Saved? | Continue restores |
|---|---|---|
| Shore | Yes, by New Game | Checkpoint 0 |
| Abyss | Yes | Checkpoint 1, with `enter_abyss` consumed |
| Monolith | Yes | Checkpoint 2, with `reach_monolith` also consumed |
| Awakened | Yes, once `monolith_awaken` has finalized | Checkpoint 3, with the puzzle solved, stones lit and inert, the mural lit with its second caption and the gate open |
| Witness, Fleeing, Ended | Never | The Awakened save. An unfinished reveal or escape replays ([D27](decisions.md)). |

- A save is written only with no active cinematic and with control enabled. Closing during a cinematic
  returns to the previous checkpoint.
- A solved puzzle follows from the beat, and a partial attempt is not kept. Any one-shot outcome must follow from
  the beat too, or the format gains a field and a new version.
- **M3 did not change the format, so it is still version 1** ([D52](decisions.md)). What changed is which beats exist: an M2 save still loads, and a build
  from before M3 reads an M3 save at Monolith or Awakened as "from another version".
- The Awakened save stays after the ending. Whenever the save's beat is Awakened, the main menu says Continue resumes
  before the final sequence. No "finished" state exists, so nothing implies a post-ending world.

**The one restore path.** `GameDirector` is given a checkpoint value before it enters the tree, and reads no file. In
`_ready`:
1. `StoryProgress::restore(beat)`, which accepts savable beats only.
2. Apply each reached beat's essential outcome, idempotently as in D12, and consume its trigger. **No clip or
   cue plays.** Atmosphere is set to that beat's end state.
3. `player.teleport(checkpoint)`. The existing physics-fresh overlap check then runs as usual.

| Action | Where the checkpoint value comes from | Reads the save? |
|---|---|---|
| New Game | A fresh Shore value, once a fresh save has been written | No |
| Continue | What the main menu already loaded and validated | Main menu only |
| Restart Checkpoint | The session checkpoint | No |

**New Game** writes the fresh save first, after its confirmation. The scene changes only if that succeeds. If it fails,
the player stays in the menu with an error and a Retry option, and the old save is neither changed nor read.

**Safe replacement.** Once a save exists, at least one valid file is on disk at every moment:
1. Write `save.tmp`, close it, read it back and validate it. On failure, stop: nothing else has changed.
2. If `save.dat` is valid, copy it to `save.bak.tmp`, validate that, and move it over `save.bak`. **If `save.dat` is
   corrupt, leave `save.bak` alone,** so a corrupt primary never overwrites a valid backup.
3. Move `save.tmp` over `save.dat`.

Loading tries `save.dat`, then `save.bak`, and never changes a file. Leftover temporary files are ignored. The Hud
shows its "saved" notice only after step 3. Rename behaviour on Windows is tested, not assumed.

**Quitting says what will happen.** Quit to Desktop and Quit to Main Menu confirm, after retrying a failed write once:
- Latest checkpoint saved: Continue resumes from the last saved checkpoint, and anything since then is not kept.
- Latest checkpoint not saved: it could not be saved, and Continue resumes from the earlier save, or there is no save.

Closing the window shows no dialog, and the save on disk stands.

| Situation | Behaviour |
|---|---|
| No save | Continue unavailable; New Game asks nothing |
| Corrupt or truncated, usable backup | Continue uses the backup; neither file changes until the next save |
| Corrupt, no usable backup | Explained; Continue unavailable; New Game asks first; the file stays until it is replaced |
| Other version | Explained as incompatible, then the same. No migration during the jam. |
| Autosave fails | No "saved" notice, a short message, and play continues. Restart Checkpoint still uses the session checkpoint. |
| New Game's write fails | Stays in the menu with an error and Retry; no scene change |
| Missing or invalid settings | Defaults for whatever is invalid |

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
  `enum class Event`, `std::optional<Beat> apply(Event)`, and a `restore(Beat)` that accepts
  savable beats only.
- `save_data.hpp/.cpp` and `settings_data.hpp/.cpp`: versioned text formats. `parse` reports Ok, Corrupt or
  Incompatible, and validation refuses unknown beats, mismatched checkpoints, reserved keys, duplicate
  keys and actions with no key.

## 6. Signal and wiring map

```
Interactor.focus_changed ─────────► Hud.on_focus_changed (connected in code, Hud._ready, D37)
Interactor.interacted ────────────► Hud.on_interacted (connected in code, Hud._ready, D37)
Input.joy_connection_changed ─────► MenuController (connected in code, _ready)
MenuController ───────────────────► GameSession.set_active_device ► GameDirector ► Hud (direct calls)
GlyphX.interacted(id) ────────────► PuzzleController.submit(id)
PuzzleController.solved ──────────► GameDirector.on_puzzle_solved
PuzzleController.step_accepted, failed, solved ► Hud.show_caption (bound text, in the scene)
StoryTrigger.triggered(id) ───────► GameDirector (connected in code, _ready, from story_triggers)
Cinematics.animation_finished ────► GameDirector (connected in code, _ready)
PlayerController.footstep ────────► Footsteps.play
GameDirector.checkpoint_reached ──► GameSession (connected in code when it creates the world)
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

**A scene connection may not start inside an instanced scene ([D37](decisions.md)).** The text scene keeps it and every test from the
source sees it, but the export re-packs scenes and silently drops it, unless the instance has Editable Children. Connect those
in code from an exported path. A connection between a scene's own nodes survives, and the suite on the exported pack ([D38](decisions.md))
catches any that do not.

## 7. Ownership and lifetime rules (godot-cpp)

1. **Nodes are owned by the scene tree.** C++ never `delete`s a node. `memnew`
   is used only when the result is immediately `add_child`'d. We do not expect
   to need runtime node creation in the MVP, apart from `GameSession` instancing the
   world from a `PackedScene`.
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
   to a node instance, which is what makes a restart from a fresh instance correct.
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
   - `InputMap` keyboard bindings (M2)
   - The subtitle and vibration switches, as metadata on the `Engine` singleton (M3). Set only by `apply_settings`, like the volumes
   - Controller vibration (M3). Stopped by `GameDirector`, as above, and not by `reset_global_state`, as it alone knows the device

   Rules:
   - `dagon::reset_global_state()` restores pause, time scale and mouse mode. Volumes and key
     bindings change only through Settings and are left alone, so a scene transition never loses
     them, even if they could not be saved ([D33](decisions.md)). `MenuController::_ready` applies the
     saved ones when a scene loads.
   - It runs before every scene transition, and again (with a debug-build
     warning if anything was dirty) in `GameDirector::_ready`.
   - Rule for presentation: clips must not mutate AudioServer. Low-pass
     sweeps are baked into the audio assets or use per-player volume only.
   - Any new global must be added to this list and to the function.

## 8. Testing strategy

| Level | What | How | Runs in |
|---|---|---|---|
| Unit | `core::step`, `SequencePuzzle`, `StoryProgress`, `save_data`, `settings_data`, `narration` | doctest, native binary (`scons unit_tests`) | CI Linux + Windows |
| Extension load | All 11 classes registered, with key methods and signals bound | `godot --headless --script res://tests/check_classes.gd` | CI Linux |
| Integration | M1: spawn and land; walk distance; jump arc; wall stop; teleport contact invalidation (roadmap M1 7f). M2: focus gained and lost; focused object disabled or freed → focus cleared, no crash; double press → 1 event; Interactable `one_shot`; pausing stops gameplay and the menu still responds; focus and one-level Back; rebinding conflicts, capture cancel, defaults, persistence, corrupt settings. M3: puzzle right, wrong, repeated press and reset; trigger re-entry → 1 beat; **outbound crossing of `collapse` → not consumed, fires later in Fleeing**; player already inside the awaited trigger at beat entry → fires; cinematic lock and unlock; **missing clip, looping clip and watchdog timeout → gate open, camera restored, correct control state, `RevealDone` raised once**; **already-overlapping next trigger during finalization → next cinematic keeps its lock and camera**; **duplicate completion/finalization → outcome applied once**; **stale completion (older generation) → no effect on the newer cinematic**; **entering the kill plane while control is locked → recovered after finalization**; flee timeout → Ended; pause → Restart Checkpoint → unpaused; pause → Quit to Main Menu → New Game → unpaused; ending → main menu → New Game → unpaused; restart resets state; **save and restore at each savable beat: correct world, no clip or cue replayed, consumed triggers stay consumed, never stuck**; **saving refused during a cinematic**; **save written by one process and continued by another, in the same unique test directory**; **New Game with a failed write → stays in the menu, old save unchanged and unread**; **autosave failure → Restart Checkpoint returns to the session checkpoint, Continue after a relaunch to the last valid disk save, and the quit text says so**; **every on-disk state an interrupted replacement can leave → a usable save loads, and a corrupt primary never overwrites a valid backup**; **repeated restart → pause reset, no duplicate events, nothing left from the old world**; **every scene that reads files in `_ready` uses the test directory**; missing, corrupt and incompatible saves; New Game confirmation; Continue's text for an Awakened save; wiring check | Hand-rolled headless SceneTree runner (~80 lines, no GUT); rules below | CI Linux |
| Smoke | Main scene and greybox scene each run 600 frames with no `ERROR:` lines | `--headless --quit-after 600` piped through grep | CI Linux and Windows |
| Exported pack | The whole integration suite again, on the exported `dagon.pck` (D38). A test of source scenes cannot see what the export changes. | `DAGON_TEST_PACK`, in `tools/export_check.sh` | CI Linux and Windows |
| Exported route | The release build as shipped, in its own window, played from New Game to the ending and back to the main menu with real window-system keys: reading everything on the way, then directly, then by waiting out the flee, and Continue afterwards. It reports time per act. It reads what a player sees from `--verbose`, and has no code of its own in the build ([D51](decisions.md)). | `tools/route_check.py` | CI Linux, under Xvfb, with XTEST keys. CI Windows, with window messages |
| Export | Linux and Windows release exports build. The Linux export runs `--quit-after 300` with exit 0 and no errors. | `--export-release` | CI Linux (export); Windows run is manual or on a Windows runner |
| Manual | Feel, readability, pacing, a full playthrough on Windows and Linux, menus and rebinding on a physical keyboard and controller, quit and relaunch, and audio, which is not complete until a person has heard it in gameplay | Checklist per milestone | Human |

Reports always state which of these levels actually ran.

**Headless integration-test rules (review round 2, item 7):**
- **A test that sets out to cause an engine error** names it with `h.expect_error(text)`, because the runner fails a test on any logged error. Any other error still fails it, and so does
  expecting one that never comes. `tools/run_godot_checks.sh` ignores only those messages, and only in the integration step.
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
- **Test storage is isolated at every entry point,** because `user://` is shared with the real game on the same
  machine.
  - Every path comes from `storage_root()`, so scenes that read files in `_ready` are covered too.
  - `tools/run_godot_checks.sh` and `tools/export_check.sh` create one unique directory per run, named `dagon-test-*`
    and outside `user://`. They set `DAGON_STORAGE_DIR` for every Godot process they start, including
    subprocess tests and smoke runs. Each test uses its own subdirectory.
  - The test runner refuses to start without that directory.
  - Cleanup deletes only inside a path it has checked is this run's directory, and never through `user://`. A check
    compares the listing of the real `user://` before and after a run, apart from the engine's own logs.
  - Rebinding tests restore the InputMap.
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
- `ci.yml` uploads the standard builds, which open the main menu, as the artifacts `dagon-windows`
  and `dagon-linux`.

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
│   ├── settings_menu.*  game_session.*  storage.*  global_state.*  input_labels.*
│   └── core/  movement.*  sequence_puzzle.*  story_progress.*  save_data.*  settings_data.*  controller_labels.*
├── tests/unit/             # doctest.h (vendored v2.5.3) + test_*.cpp
├── project/
│   ├── project.godot  export_presets.cfg
│   ├── bin/dagon.gdextension
│   ├── default_bus_layout.tres
│   ├── scenes/{level,player,ui}/   assets/{shore,ui,audio}/   shaders/
│   └── tests/              # headless GDScript tests (excluded from export)
├── tools/                  # prepare_project.{sh,ps1} (toolchain §5); art/ asset-generation scripts
├── docs/                   # this documentation
└── .github/workflows/      # ci.yml, release.yml
```
