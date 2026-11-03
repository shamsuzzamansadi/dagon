# DAGON: Beneath the Black Tide — Game Design Document

Status: Phase A approved. Entry for GitHub Game Off 2026, theme **SHIFT**
(theme-fit assessed 2026-11-02 in [jam.md](jam.md) §4; the concept and scope
are unchanged). **Scope change, 2026-11-02:** a main menu and one checkpoint save slot
(§11, [D25](decisions.md)).

**How the game expresses SHIFT:**
- *Physical:* the seabed has been displaced from beneath the ocean, which now lies
  unnaturally far off, beyond the stranded boat.
- *Interpretive:* solving the glyphs restores the mural's meaning, turning
  apparent ruins into evidence of worship (§5).
- *Perceptual:* the reveal changes what the landscape is and how big the sailor
  is, and exploration becomes escape (§4, Act IV).

## 1. Pitch

A shipwrecked sailor wakes on a stretch of seabed that should be under the
ocean. He walks inland across a dead, exposed abyss, reads the carvings of
something that worshipped here, wakes a monolith, and witnesses what it was
built for. 10–15 minutes, one continuous side-scrolling level, no combat.

Source: H. P. Lovecraft, *Dagon* (written 1917, published 1919). The text is in
the public domain. We take the premise and story beats only. We do not use
designs, music or presentation from any adaptation. Visual references (INSIDE,
LIMBO) are for restraint and pacing only. We do not reuse their art, mechanics
or layouts.

## 2. Pillars

1. **Scale over shock.** Horror comes from finding out how big everything is,
   not from things jumping at the camera. There is one large reveal.
2. **Read the world.** The story is told by props, terrain, sound and a few
   one-line examine texts. There is no dialogue.
3. **Never stuck.** No death, no fail state, no softlock. Every obstacle can
   always be crossed in both directions.

## 3. Player verbs

| Verb     | Default input (KB / pad)    | Notes                                         |
|----------|-----------------------------|-----------------------------------------------|
| Walk     | A/D, ←/→ / left stick, d-pad | Slow, heavy pace (~70 px/s at 480×270).       |
| Jump     | Space / south (Xbox A, PlayStation Cross) | Low hop for rocks and narrow crevasses only.   |
| Interact | E / west (Xbox X, PlayStation Square) | Shown only when a prompt is visible, and the prompt names the button for the device in use. |
| Pause    | Esc / Start (Xbox Menu, PlayStation Options) | Resume, Restart Checkpoint, Settings, Controls, Quit to Main Menu, Quit to Desktop. |
| Back     | Esc / east (Xbox B, PlayStation Circle) | In menus. Cannot be rebound (§11). |

The lantern is always on and needs no input or fuel. It gives a warm radius of
about 90 px against a cold, dark ambient. Interactable props get a faint rim
highlight so the world stays readable on dim screens.

There is no health and no death. If the player falls out of the world (only a
collision bug can cause that), a safety volume respawns them at the last
checkpoint.

## 4. Structure and pacing (one continuous level)

| Act | Name             | Target time | Beats |
|-----|------------------|-------------|-------|
| I   | The Shore        | 2 min       | Wake on exposed seabed beside the stranded lifeboat. Teaches movement, a jump onto the boulder and the first interaction. Rotting fish on the mud, and the sea only a thin band far beyond the boat: the tide has drawn back unnaturally far and does not return ([D21](decisions.md)). No surf where it should be, only a faint, far-off sea that thins away as the player moves on. |
| II  | The Exposed Abyss| 4–5 min     | Cracked black mud, fossils of creatures that should not exist, a whale-sized rib arch. Three **clue tablets** (one glyph each, see §5). A crevasse to hop. A distant shape moves once in the far parallax layer and is never mentioned. The ambience slowly loses its high frequencies. |
| III | The Monolith     | 3–4 min     | A canyon opens and the monolith fills the frame. The camera pulls back on approach. Its mural is partly eroded. Three **glyph stones** at its base form the puzzle. When solved, the inscriptions glow and the mural can be read in full: figures bowing to a vast swimmer. |
| IV  | The Witness      | 2 min       | The player steps onto the ledge behind the monolith. Control locks. Fog lifts, the camera zooms far out, and something rises from the trench water and embraces the monolith. Control returns and the sailor flees left under screen shake and roaring sound until he collapses. Fade to black, epilogue card, credits, main menu. |

There is one ending (MVP). The epilogue text is original and written in the
first-person, after-the-fact voice of the source.

**The perceptual shift in Act IV.** The camera pulls back until the sailor is
tiny. A far-background shape the player has walked past turns out to be part of
the creature. The player has walked right for the whole game and now runs left,
back over the same ground.

**Flee rules (still one ending):**
- The way right is the trench edge, a solid rock wall, so moving the wrong way
  just presses against it.
- Running left reaches the collapse point in about 8–10 s.
- If the player waits or keeps pushing the wrong way, the sailor collapses
  where he stands after 12 s (tunable).
- Both cases play the same collapse and the same ending.

## 5. Monolith puzzle

**The idea.** The monolith's mural tells a three-panel story. Erosion has
destroyed the order. The player restores it by pressing the three glyph
stones in the order the story happens.

| Glyph  | Image                 | Story meaning           | Order |
|--------|-----------------------|-------------------------|-------|
| Wave   | Rising water lines    | The waters rise         | 1     |
| Kneel  | Bowing figure         | The faithful bow        | 2     |
| Eye    | Open eye above a hand | He looks upon them      | 3     |

**Before and after (the interpretive shift).** The same mural, examined in the
same place, reads differently:
- *Before solving:* dim and fragmentary. Its caption describes worn, meaningless
  carvings, and the player can take it for ruins.
- *After solving:* lit and legible. Its caption describes figures bowing to a
  vast swimmer. The caption swap is part of the Awakened beat's essential
  outcome, so a missing clip cannot leave the mural unchanged.

**Clues.** The three Act II tablets each show one glyph, with a short examine
line ("The waters rose first…", "…and they bowed…", "…and He saw them.").
The mural's surviving fragments show the same order faintly. A player who
skipped the tablets can still solve it.

**Rules**
- Press a stone (Interact). Correct next stone: it lights teal with a soft tone.
- Pressing a stone that is **already lit** in the current attempt does
  nothing. There is no penalty and no reset.
- Wrong unlit stone: every stone goes dark with a grinding sound. There is a
  1 s lockout, during which presses are ignored, then progress resets to zero.
- Because lit stones cannot be pressed again, a complete attempt is always an
  order of the three distinct stones, of which there are 3! = 6. A wrong press
  ends an attempt immediately. A player who remembers what failed needs at
  most 3 failed attempts (2 wrong first stones, then 1 wrong second stone).
  Trial and error therefore always finishes the puzzle.
- Once solved, the stones stay lit and stop reacting. It cannot be un-solved.
- The level has no one-way drops between the tablets and the monolith, so
  backtracking to the clues is always possible.

## 6. Interactions (MVP list)

| Act | Object                | One-shot | Purpose                 |
|-----|-----------------------|----------|-------------------------|
| I   | Lifeboat              | no       | Tutorial, situation     |
| I   | Fish carcass heap     | no       | Wrongness               |
| II  | Fossil A, Fossil B    | no       | Escalation              |
| II  | Clue tablets ×3       | no       | Puzzle clues            |
| II  | Footprint (webbed)    | no       | Dread                   |
| III | Mural                 | no       | Text changes after solve |
| III | Glyph stones ×3       | no       | Puzzle input            |

Examine text is one or two short lines. It shows as a caption that fades after
about 4 s and never pauses the game.

## 7. Audio direction

**Status: planned. The build has no audio yet.** Direction from the owner, 2026-11-02: original,
cohesive audio with a Lovecraftian atmosphere, tied to environments and story triggers.

**Sound communicates the world's change.** Familiar coastal sounds thin out or disappear as unnatural
resonances emerge. Avoid a constant generic horror loop and repeated loud jump scares.

| Group | Small palette |
|---|---|
| Environmental beds | Distant sea, exposed shore wind, sparse coastal details, wet mud ticks. Layered per area and crossfaded. |
| Player and objects | Footsteps by surface (mud, stone), landing, boat wood and rope, lantern creak, stone interaction, examine "breath" cue, puzzle tones and grinding. |
| Story cues | Discovery, puzzle completion, reveal, escape. |
| Music and drones | Restrained music or low drones, spatial placement, deliberate silence. |

| Where | How it should change |
|---|---|
| The Shore | No surf where it should be. A faint sea far off, wind, a few coastal details. |
| The Exposed Abyss | The sea and coastal details thin out, the ambience slowly loses its high frequencies, and low drones begin. |
| The Monolith | Unnatural resonances take over. The puzzle's tones belong to them. |
| The Witness | A sub-bass swell, then a low-pass sweep that opens up, then a roar built from layered processed sources, then silence at the collapse. |

**Provenance.** Prefer original recordings, synthesis or purpose-made audio; third-party sound is CC0
only. Log every sound in `CREDITS.md`. Never describe stock or generated audio as personally recorded
or composed, and keep any AI-use disclosure accurate (`jam.md` §5). Do not copy recognizable film or
game music. Nothing is purchased or commissioned without the owner's approval.

**To deliver at the audio milestones** (M4 for beds and player sounds, M5 for story cues): a compact
event-to-sound list and a demonstration of the mix in gameplay, checked for loop seams, abrupt
transitions, clipping, repeated-trigger stacking, and whether important cues stay audible. The
transition beyond the Shore must also be coherent in sound. Separate music and effects volume settings
are prepared in M2 and connected when audio exists (§11). Until then, Settings says "This build has no audio yet."
That note is removed when audio is connected.

**Audio is not marked complete until a person has heard it in gameplay.**

## 8. Visual direction and acceptance

**Quality bar (project owner, 2026-11-02):** the finished game should feel *made
with love*: visually coherent, carefully composed, atmospheric, and pleasant to
control. A working prototype is an intermediate milestone, not the final
presentation. Passing automated checks says nothing about any of this.

**Identity.** Cinematic coastal horror with its own look. It takes restraint and
pacing from cinematic games, but no assets, compositions or recognizable designs.
- 480×270 internal resolution, integer-scaled.
- Palette: charcoal, slate, muted navy, restrained sickly teal. Warm amber lantern
  light is the only warm colour. The accepted Shore palette (`tools/art/palette.py`) also
  has muted wood and skin; amber stays the lantern's alone.
- Clear separation between foreground, playable ground and distant scenery, using
  4–6 parallax layers and a foreground fog layer.
- Deliberate negative space and scale contrast.
- Organic, weathered silhouettes, not visibly repeated geometric primitives.
- Dagon is never fully shown: an outline against fog, a fin-crest, a hand-like limb
  on the monolith, one reflected eye-glint, roughly 30× the player's height.

**In the details:**
- *Composition:* important views have a clear focal point. Terrain, light and framing
  guide attention. No empty stretches filled only with repeated rocks. Jumps, walkable
  surfaces and interactables are visually understandable.
- *Character and movement:* the sailor reads as a character at gameplay resolution.
  Walking, stopping, jumping and landing feel intentional, with no foot sliding, jitter
  or abrupt animation changes. Restrained secondary motion (lantern, coat) where it
  adds character.
- *Light and atmosphere:* keep detail and navigation instead of crushing to black. Fog
  creates depth without hiding the screen. No excessive glow, particles, distortion or
  constant camera shake. Sound and animation follow the same mood.
- *UI:* consistent typography, spacing, alignment and restrained transitions. Captions
  are readable at target window sizes. Prompts and menus feel part of the same game.
  No debug labels or overlays in normal release gameplay.

**Art direction (2026-11-02).** The owner accepted the Shore's direction ahead of M4
([D19](decisions.md)), and it is what the standard build opens. That sets the look. It does
not complete the deliverable below: stop, turn and landing animation, sound, and caption and
prompt styling are still to come ([shore-preview.md](shore-preview.md)). The art currently stops at the
cliff opening, and everything past it is unfinished greybox. Later environments arrive through the planned
milestones in the same style, with no redesign, and M4 and M5 make that transition coherent in picture and
sound.

**Prove it before decorating (first M4 deliverable).** One short, playable section of
the Shore, brought close to final quality, sets the character treatment, terrain and
prop language, palette, light, depth, camera behaviour, ambient motion and sound, and
caption and prompt styling. It is a polish pass on existing gameplay: no new level or
mechanic. It goes to visual review before the treatment spreads through the level;
independent work continues meanwhile. Prefer fewer well-composed scenes and reusable,
consistent assets over a lot of rough content.

**That section must demonstrate:** cohesive composition, readable lighting, a convincing
animated sailor, restrained effects, and consistent UI. It is judged on actual gameplay
captures, not only a selected still. Any asset-production limitation is named, not
treated as finished.

**Visual evidence required for that review:**
- At least three in-engine screenshots and a 20–30 s gameplay recording showing
  movement and camera, at normal viewing size and at native resolution.
- Debug overlays off, and a statement of what remains unfinished.
- Concept art or generated illustrations may guide production, but are never presented
  as proof of the rendered game's quality.

**Visual acceptance checklist (before calling any scene polished):**
1. Player, ground and important props are immediately distinguishable.
2. Shapes, lighting and UI follow one coherent style.
3. Camera motion is stable and intentional.
4. No unintended seams, clipping, stretched textures or distracting repetition.
5. Text is readable and properly aligned.
6. The scene communicates mood without an explanatory paragraph.
7. It looks considered both in a still screenshot and during play.
8. Performance and gameplay regression checks still pass.

## 9. Stretch goals (only after M6 is green; time-boxed; never block release)

1. Perception effects: a subtle screen-distortion shader whose strength is
   keyed per act, background silhouettes that change when you look back, and
   brief audio drop-outs.
2. Alternate ending. In the MVP, standing still during the flee leads to the
   single ending; a distinct "succumb" ending would be post-M6.
3. Brightness/gamma setting.
4. Web build.

## 10. Out of scope (post-jam at earliest)

Combat, enemies or monster AI, inventory, multiple save slots, saving at an
arbitrary position, dialogue trees, sanity meter, multiple characters, procedural
levels, custom physics or rendering, multiplayer.

## 11. Menus, settings and saving

**Status: all of this is implemented in M2, accepted by the owner, for the beats that exist so far.** Added by
the owner on 2026-11-02 and brought forward on 2026-11-03 ([D24, D25, D36](decisions.md)). Saving is an intentional scope change:
this document excluded it before.

| Screen | Options | Milestone |
|---|---|---|
| Pause | Resume, Restart Checkpoint, Settings, Controls, Quit to Main Menu, Quit to Desktop | M2 |
| Settings | Music volume, effects volume, keyboard bindings, Restore Defaults, Back, and a temporary note that there is no audio yet | M2 |
| Main menu, on launch | New Game, Continue, Settings, Controls, Credits, Quit to Desktop | M2 |
| Controls | Movement, jumping, examining, pausing and menus, on keyboard with the current keys and on controller. Starting a new game shows a short version for the device in use | M2 |
| Credits | Attribution and licenses, from the project's records | M2 |

**Menus.** Every menu works with keyboard and controller, a control always has focus, and Back closes one level.
Pausing stops gameplay while the menu stays responsive.

**Controllers.** Buttons are fixed, and bound by position. The prompt and Controls follow the device in use: the current key on
a keyboard, A, B, X and Menu on a recognized Xbox controller, Cross, Circle, Square and Options on a recognized PlayStation
controller, and the button's position on anything else. Disconnecting hands back to the keyboard.

**Rebinding.** One keyboard key for each gameplay action can be changed. If a key is already in use, the game says
which action has it and lets the player swap or cancel, so no action is left without a key. Restore Defaults is
always reachable. Menu navigation, Back, the Esc pause key and the Left and Right arrows for movement cannot be
rebound, so nobody can lock themselves out. The Up and Down arrows can be rebound, and still navigate menus. Gamepad
mappings are fixed for the jam.

**Settings** persist between runs and are stored separately from game progress. The volumes do nothing audible
until audio exists, and a short note in Settings says so until then.

**One checkpoint save slot.**
- Continue restores the last safe checkpoint, including after the application has been closed and reopened.
- It keeps stable progress only: the story beat, whether the puzzle is solved, and which checkpoint. It never
  keeps a position between checkpoints or a moment inside a cutscene, and an unfinished puzzle attempt is not
  kept.
- What the player has completed stays completed. A solved puzzle stays solved, an open gate stays open, and
  one-shot events do not replay. Pillar 3 applies: restoring can never leave the player stuck.
- Restart Checkpoint returns to the latest checkpoint reached this session, even if it could not be written to disk.
  Continue after a relaunch uses the last valid save on disk.
- Quitting during the reveal or escape resumes from the checkpoint before it, and that unfinished sequence replays.
- The last checkpoint stays after the ending. The menu explains that Continue resumes before the final sequence. It
  never implies a world after the ending.
- A brief notice shows when checkpoint progress has actually been saved.
- Quit to Desktop and Quit to Main Menu say plainly what Continue will resume from. They never imply that unsaved
  progress has been kept, and they say so if the latest checkpoint could not be saved.
- A missing, corrupt or incompatible save is explained and never crashes the game. Continue is simply
  unavailable.
- New Game asks for confirmation before replacing existing progress. If the fresh save cannot be written, the player
  stays in the menu with an error and Retry. The old save is never loaded instead.
