# GDD §8 on every scene: the developer's view (M6 plan, item 10)

**Read this first if you have not yet done the listening (item 3):** the two screenshots of the reveal show its captions, so they are in [after-listening/](after-listening/), and this page does not quote them.

**Whose view:** the developer's, from screenshots, against the [GDD's](../../../gdd.md) §8 visual acceptance checklist. **Not the owner's eye in play,** which item 10 still asks for, and which alone can judge motion and feel. Screenshots cannot show camera motion or animation (checklist items 3 and 7, in part); for those this page points to M5's clips and the owner's recordings.

**What was captured:** the exported Linux release game, built here from the branch, played by `tools/route_check.py` on a private display at 1440 × 810, `runs=4 failed=0`, with a screenshot at each of the route's moments. They are stored here at the game's own 480 × 270: every 3 × 3 block of each capture was one colour, so nothing is lost. **That build predates two changes made since:** Settings' "Interact" now reads "Examine" (D124), and the distant shape's fix below; the Shore's screenshot still shows the old placement.

**The checklist** (GDD §8): 1, player, ground and important props immediately distinguishable; 2, one coherent style; 3, camera stable and intentional; 4, no unintended seams, clipping, stretching or repetition; 5, text readable and aligned; 6, mood without an explanatory paragraph; 7, considered both in a still and in play; 8, performance and regression checks pass.

## Scene by scene

| Scene | Screenshot | The developer's view | Findings |
|---|---|---|---|
| Main menu | [01](01-main-menu.png), [18](18-main-menu-after-the-ending.png) | The Shore's art behind one panel; the focused button outlined; the save's status in words below (1, 2, 5, 6) | — |
| How to Play | [02](02-introduction.png) | One panel, the keys as bound, Begin focused (5) | — |
| The prologue | [03](03-prologue.png) | Illustrated panels; a caption card along the bottom with Continue and Skip; the ship's lamp the one warm light (2, 5, 6) | — |
| The Shore | [03](03-boat-caption.png) | The sailor, the boat and the ground read at once; the prompt above the caption, both centred (1, 5, 6) | **F1, fixed:** the dark triangle in the sky by the cliff |
| The passage under the cliff | [04](04-abyss.png) | The checkpoint notice at the top; the carving on the wall readable (1, 5) | **F2, open:** a straight vertical edge where the cave begins |
| The Abyss, the ritual seen far off | [05](05-ritual.png) | The figures small and dark against the sky, as D111 intends; the caption names what is seen (6) | **F2, open:** a straight vertical edge where the cave ends |
| The crossing | [05b](05b-the-stone.png), [05c](05c-the-slab-down.png) | Ledges, the stone, the raised slab and the carving that explains them all in one view; the prompt names the action (1, 6) | Now with the distant shape behind the far cliff (F1) |
| The canyon and the Monolith | [06](06-monolith.png) | The canyon opens on the Monolith; the eye stone on the slab is the focal point (6) | — |
| The stones | [07](07-wrong-stone.png), [08](08-first-stone.png), [09](09-second-stone.png) | Each stone's glyph readable at gameplay size; a lit stone teal; prompt and result line together (1, 5) | The Monolith's face is the brightest large area in the game; read as intended, no action |
| The awakening and the gate | [10](10-awakening.png), [11](11-gate-open.png) | The carving lights; the checkpoint notice (5, 6) | — |
| The reveal and the flight | [after-listening](after-listening/) | The creature's head, arm and back fill the view, never all of it; the sailor small below; captions on one line, centred (1, 6) | — |
| The collapse | [14](14-collapse.png) | The fallen sailor, the sea's foam edge coming on, the light failing (6) | — |
| The epilogue | [15](15-epilogue-first-line.png), [16](16-epilogue-whole.png) | Illustrated panels; the longest line on three rows of its card, Continue below it (5, 6) | — |
| Credits | [17](17-credits.png) | Fits its panel; Main Menu focused (5) | — |
| Continue after the ending | [19](19-continue-after-the-ending.png) | Back before the final sequence, at the gate | **F3, minor:** the sailor stands right in front of a dark kneeling figure |
| Settings, Controls, pause; 720p and 1080p | [displays](../displays/README.md), [layouts](../layouts/README.md) | Every block one colour, 16:9, bars where needed; long captions fit; menus by keys | — |

**Across all scenes:** item 2, one palette and one typeface, panels and captions alike, through every act; item 5, no text clipped or off-centre in any screenshot; item 6, no scene leans on an explanatory paragraph: captions are one or two lines, the epilogue's three. **Items 3 and 7 in motion** are outside what stills show: M5's before/after clips and the owner's recording of `b7303bf` cover the reveal, the hand and the sea; the rest of the game in motion is the owner's to judge in play. **Item 8:** the gate passes (459, then 460 with F1's test), frame times show no frame over 33 ms in play ([frames](../frames/README.md)), and the art check passes with Pillow alone (`CHECK_ART problems=0`).

## Findings

**F1. The distant shape was drawn in the wrong place. Fixed.** M5's distant shape (D111), the dark back with the reveal's spines along its top, is meant to rise from behind the far cliff in the Abyss and shift there, before anyone knows what it is. Its drawing sat 1000 px to the left of the shape the clip moves: **over the Shore's near cliff, from the first screen, as a hard-edged dark triangle with its cut-off base showing in the sky, and missing from the Abyss.** The generator (`tools/art/gen_figures.py`) places it at the shape's own (0, −220); the scene had (−1000, −220), from M5's merge. Now (0, −220). Before and after: the Shore's start, [before](distant-shape-before-shore-start.png) and [after](distant-shape-after-shore-start.png); the Abyss by the crossing, [before](distant-shape-before-abyss-2100.png) and [after](distant-shape-after-abyss-2100.png). A test now holds that every drawing a clip moves lies over its shape (`test_every_drawing_lies_over_the_clear_shape_it_belongs_to`); it failed for this drawing alone before the fix. **For the owner's eye in play:** the shape is now seen in the Abyss, where it was never seen before; the Shore loses the triangle.

**F2. The cave is a rectangle. Open, for the owner.** The dark cave between the Shore and the Abyss is drawn inside a plain rectangular clip (`CaveView`, x 640 to 1050, since M3), so where it begins, across the Shore's cliff, and where it ends, against the Abyss's sky, it shows **a straight vertical edge from the top of the screen to the ground.** Against the GDD's "no unintended seams" and "organic, weathered silhouettes". **Option:** give the clip's two sides the cliff's own outline and the cave wall's, a change to one polygon and its check; about one to two hours with captures at both edges. Every build the owner has played has had it.

**F3. Continuing after the ending puts the sailor in front of a dark figure. Minor, open.** At the Awakened checkpoint, where Continue resumes after the ending, the sailor stands in front of one of the kneeling figures by the gate. His lantern and coat keep him readable, but he is the least distinct there of any screenshot. **Option:** move the checkpoint's marker a few pixels clear of the figure. A save names the checkpoint, not a place, so no save changes; the tests that stand him there would follow. Small.

**Recorded, no action:** the creature's left side is a long, nearly straight outline in the flight's view; it is the body's own shape, not a seam.
