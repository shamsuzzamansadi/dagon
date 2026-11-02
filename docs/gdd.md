# DAGON: Beneath the Black Tide — Game Design Document

Status: Phase A approved. Entry for GitHub Game Off 2026, theme **SHIFT**
(theme-fit assessed 2026-11-02 in [jam.md](jam.md) §4; the concept and scope
are unchanged).

**How the game expresses SHIFT:**
- *Physical:* the seabed has been displaced from beneath the ocean.
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
| Jump     | Space / A (south)           | Low hop for rocks and narrow crevasses only.   |
| Interact | E / X (west)                | Shown only when a prompt is visible.          |
| Pause    | Esc / Start                 | Resume, restart, quit to title.               |

The lantern is always on and needs no input or fuel. It gives a warm radius of
about 90 px against a cold, dark ambient. Interactable props get a faint rim
highlight so the world stays readable on dim screens.

There is no health and no death. If the player falls out of the world (only a
collision bug can cause that), a safety volume respawns them at the last
checkpoint.

## 4. Structure and pacing (one continuous level)

| Act | Name             | Target time | Beats |
|-----|------------------|-------------|-------|
| I   | The Shore        | 2 min       | Wake beside the overturned lifeboat. Teaches movement, a jump over the oar wreckage and the first interaction. Rotting fish everywhere, and no sea in sight. Silence where surf should be. |
| II  | The Exposed Abyss| 4–5 min     | Cracked black mud, fossils of creatures that should not exist, a whale-sized rib arch. Three **clue tablets** (one glyph each, see §5). A crevasse to hop. A distant shape moves once in the far parallax layer and is never mentioned. The ambience slowly loses its high frequencies. |
| III | The Monolith     | 3–4 min     | A canyon opens and the monolith fills the frame. The camera pulls back on approach. Its mural is partly eroded. Three **glyph stones** at its base form the puzzle. When solved, the inscriptions glow and the mural can be read in full: figures bowing to a vast swimmer. |
| IV  | The Witness      | 2 min       | The player steps onto the ledge behind the monolith. Control locks. Fog lifts, the camera zooms far out, and something rises from the trench water and embraces the monolith. Control returns and the sailor flees left under screen shake and roaring sound until he collapses. Fade to black, epilogue card, credits, title. |

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

- Layered ambience per act, crossfaded: distant wind, wet mud ticks, low drones.
- The usual sea sounds are deliberately absent. Silence is a feature.
- Footsteps on mud/stone, lantern creak, examine "breath" cue, puzzle tones and
  grinding.
- Reveal: a sub-bass swell, then a low-pass sweep that opens up, then a roar
  built from layered processed sources, then silence at the collapse.
- Source: original synthesized or recorded sounds, plus CC0 only, all logged in
  `CREDITS.md`.

## 8. Visual direction

- 480×270 internal resolution, integer-scaled. Muted palette: navy, charcoal,
  slate, sick green. The only warm colour is the lantern.
- Silhouette-first: terrain and props are mostly dark shapes. Detail sits in
  rim light and in the parallax depth layers.
- 4–6 parallax layers, plus a foreground fog layer that drifts across the
  player.
- Dagon is never fully shown. We see an outline against fog, a fin-crest, a
  hand-like limb on the monolith, and one reflected eye-glint. It is scaled
  roughly 30× the player's height.

## 9. Stretch goals (only after M6 is green; time-boxed; never block release)

1. Perception effects: a subtle screen-distortion shader whose strength is
   keyed per act, background silhouettes that change when you look back, and
   brief audio drop-outs.
2. Alternate ending. In the MVP, standing still during the flee leads to the
   single ending; a distinct "succumb" ending would be post-M6.
3. Brightness/gamma setting.
4. Web build.

## 10. Out of scope (post-jam at earliest)

Combat, enemies or monster AI, inventory, saves, dialogue trees, sanity meter,
multiple characters, procedural levels, custom physics or rendering,
multiplayer.
