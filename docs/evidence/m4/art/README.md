# M4 environment art: captures by stretch

The route past x = 1440, in the order a player meets it, each stretch captured from the game at its own 480 × 270 as it was finished (`project/tests/capture_m4.gd`, on a private display, software-rendered). The `-sheet` images show a stretch's captures at twice that size. **They show what is drawn and where. They cannot show motion or timing,** and nobody but the developer has looked at them yet.

Collision is unchanged throughout: `tools/art/check_art.py` compares the drawn ground with the collision column by column, and the route's tests stand as they were.

| Stretch | What changed | Captures | Commit |
|---|---|---|---|
| **A. The Abyss's ground and far view** | The seabed drawn from the reference section's end to the trench, its mud carried across x = 1440 without a seam, drying crust going black and wet, then worn flags toward the Monolith; rock where the collision has a block to climb. The Abyss opened to the sky: the plain and its far ridges carried on, and a far cliff, on which the watcher stands and behind which the distant shape rises. The flat backdrop, the rim, the blocky ridges and the greybox ground are hidden (D100) | `a1` to `a3`, [sheet](a-sheet.png) | `622ca0e` |

**Known in these captures, and next in order:** the rib arch, the fossil, the ledges, slab, stone and everything past them are still greybox shapes here; each has its own stretch below as it lands.
