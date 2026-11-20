# Before and after the owner's playtest of 2026-11-19

**Short clips with the game's sound,** recorded from the game by Godot's Movie Maker on a private display, software-rendered, at twice the game's 480 × 270, 30 frames a second. **Before** is `20929cf`, the build the owner played; **after** is the branch with the fixes. Scripted, not a person playing; **nobody has listened to them.** The [record](../owner-playtest-2026-11-19.md) has what the owner asked and what was done.

**[before-after.png](before-after.png):** a frame from each pair, before on the left.

| Clip | Before | After | What to look for |
|---|---|---|---|
| **1. The opening** (`record_prologue.gd`, 9 s) | [1-opening-before.mp4](1-opening-before.mp4) | [1-opening-after.mp4](1-opening-after.mp4) | The deck gun: into the moon before, trained left on the captured ship after |
| **2. The mural** (`record_mural.gd`, 11 s) | [2-mural-before.mp4](2-mural-before.mp4) | [2-mural-after.mp4](2-mural-after.mp4) | He walks in, jumps the low block, and reaches the mural as "The canyon opens…" is said. **Before:** [E] Examine while it is said; the first press cuts the line and examines nothing. **After:** [E] Skip line while it is said; the first press cuts it, the prompt turns to [E] Examine, and the second press examines; while the mural's own line is said, [E] Skip line again. The presses are the same in both |
| **3. The reveal's end** (`record_finale.gd`, 6.5 s, from 9.5 s of the clip) | [3-reveal-before.mp4](3-reveal-before.mp4) | [3-reveal-after.mp4](3-reveal-after.mp4) | "Its head turned. I ran." at 2.7 s of the clip. **Before:** the camera is leaving and the head goes out of frame. **After:** the head lowers toward him in the wide view, then the camera returns to him; control returns on the same frame in both |
| **4. The last picture** (`record_finale.gd`, 13 s) | [4-last-picture-before.mp4](4-last-picture-before.mp4) | [4-last-picture-after.mp4](4-last-picture-after.mp4) | The moon's road under the moon; the crest on the creature's head; the caption over neither |

Every stage mark of the finale and the prologue falls on the same frame in both builds (the recordings' logs, in `~/work/dagon-m5/notes/owner-1119/rec`).
