# The sailor in the prologue's boat, made readable

**The owner's feedback, 2026-11-15:** the gameplay has improved substantially; the main visible problem is that the sailor is hard to tell apart inside the boat in the prologue. (Not yet acceptance of the final M4 build.)

## What changed

| Shot | Before | After |
|---|---|---|
| **The escape** (the second line) | The rower was a 6 × 11 block of dark blue with a 2 × 2 head, on a dark brown boat on dark water: at the game's size, a boat with oars and nobody in it | A seated man in a dark coat and cap, his face lighter, an arm to the oar, **his cap and back caught by the moon**. The boat is drawn about a third larger in the same layer. The moon's light now breaks on the water beneath it, widening toward us, so he is dark against light rather than dark against dark. **He rows:** the two oar frames the scene already swaps each stroke now carry his two poses, leaning forward with his arms out as the blade dips ahead, and leaning back with his hands drawn in as it trails astern |
| **The drift** (the third line) | An 8 × 4 dark lump in the boat | **Slumped forward over his knees, his head hanging, one arm over the side** to the water, the oars shipped, his back caught by the sun; dark against the bright sea. The only motion is the boat's slow drift and its one-pixel bob, as before: no stroke, nothing else |

Drawn by `tools/art/gen_prologue.py` in the same palette (`check_art.py` problems=0). The story, the four lines, their voices and timing, Skip and Continue, and the join into the Shore are unchanged: the after recording reaches each line and the game on the same frame as the before recording. The drift's layer is six rows taller, upward; its waterline stays on the same row of the screen, and its place and bob in `prologue.tscn` move up by those rows.

## Recordings, with sound

Both recorded the same way, by Godot's Movie Maker from the game (`project/tests/record_prologue.gd`, private display, the game's own 480 × 270), and shown at twice that size, the size the game is normally seen at in a window:

- [prologue-before.mp4](prologue-before.mp4): at `e24d726`, the build the owner played. The prologue's art had not changed since.
- [prologue-after.mp4](prologue-after.mp4): with this change.

Stills: [before-after.png](before-after.png) (each row the same moment, before on the left: the escape at two moments of the stroke, then the drift), [poses-close.png](poses-close.png) (the catch, the finish and the drift, close).

**Looked at by the developer only,** as frames. Whether he now reads at a glance on the owner's screen is the owner's to say.
