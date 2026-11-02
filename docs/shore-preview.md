# The Shore artwork

The accepted art direction, and what the standard build opens. It began as a bounded art test on branch
`preview/shore-art`. On 2026-11-02 the owner accepted its overall direction: the sailor, wooden boat,
moonlit sky, coastal palette and environment ([D19](decisions.md)).

**This is not M4, and accepting the direction closes no other check.** Physical gamepad checks, movement
feel, independent code review, M1 acceptance and the full first M4 deliverable all remain open.

## What the standard build contains

The entry scene is `project/scenes/level/shore.tscn`. It keeps the M1 test level's whole collision, so
nothing about where you can walk was shortened ([D20](decisions.md)).

| | Greybox `level.tscn` | Standard build `shore.tscn` | The former preview |
|---|---|---|---|
| Role | Development and test scene, not exported | Main scene | Separate build, now removed |
| Walkable extent | x = 24 to 1376 | **x = 24 to 1376, the same polygon** | x = 24 to 620 |
| Rock, slope, trench, steps | All | **All** | Rock and slope only |
| Illustrated | Nothing | x = 0 to 640 | x = 0 to 640 |
| Past the art | n/a | Greybox ground on a dark backdrop | A wall |
| Camera limits | 0 to 1400 | 0 to 1400 | 0 to 640 |
| Character | Polygon silhouette | Animated sailor, same capsule and tuning | Animated sailor |

So the difference from M1 is what you see, not how far you can go. The trench (x = 640 to 710) and the
steps (x = 900 to 980) are playable but still greybox.

## Direction

- **Pixel scale:** one art pixel is one 480×270 game pixel, shown at a whole-number window scale
  (3× by default). Nothing is scaled or rotated, so all assets share one grid.
- **Palette:** 32 colours in `tools/art/palette.py`; `tools/art/check_art.py` fails on any other colour.

| Ramp | Colours | Used for |
|---|---|---|
| Cold | `0a0e18` … `dfe6e6` (10) | Sky, haze, moonlight, the sailor's coat and trousers |
| Teal | `12262e` … `7fa89a` (5) | Sea, weed, the scarf: a restrained accent |
| Earth | `13141c` … `6e6864` (6) | Mud and rock, kept cold |
| Wood | `261c1d` … `958069` (5) | The boat, muted |
| Skin | `6e4a3f`, `b58a6d` | Face and hands |
| Amber | `8a4f1d` … `ffe9a8` (4) | The lantern only |

- **Value plan:** the wet flats stay a mid value, so a dark coat reads against them. Distant shapes sit
  closer to the sky's value; near shapes have the strongest contrast. Fog, bloom and particles are not
  used, so that the forms have to work by themselves.
- **Assets:** drawn by Python scripts in `tools/art/` that place pixels and shapes directly. They are
  deterministic and need only Pillow: `python tools/art/generate.py`. There are no third-party assets,
  no image generators and no concept art.
- **Sailor:** head and coat are hand-placed pixels; legs and arms come from a small rig. Each planted
  foot moves back exactly 4 px per frame, and the game advances one frame per 4 px walked, so the
  foot stays still in the world at any speed.
- **The sea:** it stays visible, a thin band far beyond the stranded boat, because the tide has withdrawn
  unnaturally far ([D21](decisions.md)).

## What changed at integration

Only `terrain.png` changed, in 646 of its 172,800 pixels; every other image is an exact rename
([comparison](evidence/shore/terrain-diff.txt)).

- **The rock.** Its rounded shoulders left the feet in the air by up to 5 px at its corners. Its whole top
  is now drawn on its collision top, y = −14, and the collision did not move. `check_art.py` compares
  the drawn ground with the scene's collision, column by column.
- **The right cliff.** The preview's collision wall at x = 620 is gone, because the level continues. A dark
  cleft in the cliff's foot shows where the ground carries on.
- **The camera.** It no longer flickers by a pixel, in this scene or the greybox ([D22](decisions.md)).

**Unchanged:** movement tuning and the collision capsule, which tests compare with the greybox.

## Status of the artwork

| Complete enough for now | Placeholder or absent |
|---|---|
| Sailor: idle (8 frames), walk (8), jump and fall (1 each) | No stop, turn or landing animation |
| Lifeboat: hull, rim, thwarts, planks, oar, rope, stove-in plank | Fish and shoreline props are minimal |
| Sky, moon, clouds, stars, headland, sea, moving highlights | No audio |
| Wet flats, tide pools, stakes, distant wreck | No caption or prompt UI |
| Ground, rock, framing cliffs, foreground stones | Everything past x = 640 is greybox |
| Lantern light on the ground and boat | |

## Known limitations, for M4

None of these blocks the merge. Each stays open until someone decides on it.

1. **The walk is brisk.** At the preserved 70 px/s, a 27 px figure covers about 2.6 body heights per
   second, about 2.2 full gait cycles per second. Feet do not slide, but it reads as a hurried stride. If
   you want a heavier walk, the fix is a lower `walk_speed`. That stays your decision, after you have
   played it.
2. **Secondary motion is slight.** The lantern sways by a pixel, and the coat does not move.
3. **The stop is abrupt:** the character goes straight from stride to idle.
4. **Turning mirrors the whole sprite,** so the lantern changes hands and the moonlit edge changes sides.
5. **The sailor is about 10% of screen height.** That follows from the existing camera and collision. A
   larger character means an integer camera zoom and recomposing the view.
6. **The capsule can overhang the rock's corners.** The drawn surface now matches the collision, but the
   capsule's round bottom can rest up to 4 px past an edge, sinking by up to 1.5 px (2 px once drawn). Art
   cannot fix that without changing the capsule, so a test holds it to this limit.
7. **The art ends abruptly.** Past x = 640 is a flat backdrop, meeting the cliff at a straight vertical
   edge. The cleft is only a placeholder way through: the sailor is drawn in front of the rock, including
   when jumping there.
8. **My captures use software rendering (llvmpipe).** I have not seen this on a real GPU or your
   display, and perceived darkness depends on the display.

## If the sailor doesn't meet the bar later

I can tune the rig further, but it will not match a skilled pixel animator's judgment. The specific
asset that would benefit most is **the sailor's animation set**: about 30–40 frames of idle, walk, stop,
turn, jump and land, in this palette and 32×32 frame. A commission could replace `sailor.png` directly,
with no code changes, but nothing is commissioned without your approval.
