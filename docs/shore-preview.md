# Shore art-direction preview

One bounded art test, authorized by the owner ahead of M4 (2026-11-02). **It is not M4 and does not
replace the greybox:** the normal build still starts in `level.tscn`. Built on branch
`preview/shore-art`, so M1's `main` stays as it is for review.

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

## What was and wasn't changed

- **Unchanged:** movement tuning, the collision capsule, and the greybox ground points (x = 24–540).
  Tests compare all three. The world ends at x = 640 here, with a wall at x = 620.
- **Added, off unless a scene enables it:** sprite control on `PlayerController` (already in its design)
  and `pixel_lock` on `CameraRig`. Neither is enabled in `level.tscn`.

## Status of the artwork

| Completed for this preview | Remaining placeholder or absent |
|---|---|
| Sailor: idle (8 frames), walk (8), jump and fall (1 each) | No stop, turn or landing animation |
| Lifeboat: hull, rim, thwarts, planks, oar, rope, stove-in plank | Fish and shoreline props are minimal |
| Sky, moon, clouds, stars, headland, sea, moving highlights | No audio |
| Wet flats, tide pools, stakes, distant wreck | No caption or prompt UI in this scene |
| Ground, boulder, framing cliffs, foreground stones | The rest of the game is still greybox |
| Lantern light on the ground and boat | |

## Known limitations

1. **The walk is brisk.** At the preserved 70 px/s, a 27 px figure covers about 2.6 body heights per
   second, about 2.2 full gait cycles per second. Feet do not slide, but it reads as a hurried stride. If
   you want a heavier walk, the fix is a lower `walk_speed`, which is your decision.
2. **Secondary motion is slight.** The lantern sways by a pixel, and the coat does not move.
3. **The stop is abrupt:** the character goes straight from stride to idle.
4. **Turning mirrors the whole sprite,** so the lantern changes hands and the moonlit edge changes sides.
5. **He is about 10% of screen height.** That follows from the existing camera and collision. A
   larger character means an integer camera zoom and recomposing the view.
6. **Rock and collision are not identical:** the boulder's rounded shoulders sit on a rectangular
   collision, so the feet can be up to a few pixels off at its corners.
7. **My captures use software rendering (llvmpipe).** I have not seen this on a real GPU or your
   display, and perceived darkness depends on the display.

## If the sailor doesn't meet the bar

I can tune the rig further, but it will not match a skilled pixel animator's judgment. The specific
asset that would benefit most is **the sailor's animation set**: about 30–40 frames of idle, walk, stop,
turn, jump and land, in this palette and 32×32 frame. A commission could replace `sailor.png` directly,
with no code changes. The environment and boat do not need this.

## Open design question

The GDD and `jam.md` §4 say the sailor wakes with "no water in sight", and this brief asks for a distant
sea. The preview keeps the sea far out past wide wet flats, which I think strengthens the physical shift:
the tide has drawn impossibly far back. If you keep it, I will update those two lines.
