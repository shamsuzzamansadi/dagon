# Deliberate breakage

Each change was made in a scratch clone, and the named check had to fail. The suite passed 47 of 47
before and after. The camera files were recorded at `4436339`, the others at `c8a577b`.

| File | Change | Caught by |
|---|---|---|
| `greybox-m1-camera.txt`, `shore-m1-camera.txt` | The M1 camera restored: smoothing on, pixel lock off | `test_camera_holds_the_character_still_on_screen`, and the turning test |
| `greybox-lock-off.txt`, `shore-lock-off.txt` | Pixel lock off, no smoothing | `test_camera_slides_one_way_when_turning`: the camera jumps 48 px |
| `rock-old-art-check.txt`, `rock-old-art-tests.txt` | The preview's rock art restored | `check_art.py` (21 problems) and `test_feet_rest_on_the_drawn_rock` |
| `shore-wall-620.txt` | The preview's wall at x = 620 restored | `test_shore_has_the_whole_greybox_level` and the crossing test, stuck at x = 613.9 |
| `main-scene-greybox.txt` | Main scene set back to the greybox | `test_the_game_starts_in_the_shore` |
| `backdrop-removed.txt` | The opaque backdrop past the art removed | `test_art_ends_where_the_greybox_begins` |

**This caught a gap in my own tests.** On the first run, pixel lock off with no smoothing passed all 47
tests, because the turning test checked only the direction of the slide. It now also limits the step
per frame (`4436339`).
