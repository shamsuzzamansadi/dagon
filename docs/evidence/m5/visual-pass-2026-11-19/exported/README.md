# From the exported build

**The real exported Linux release game** of `ea86ae9`, the candidate, built and exported by the local gate (`export_check.sh linux`) and played to the ending by `tools/route_check.py` with window-system keys (XTEST) on a private X display. Its own window, 1440 × 810, nothing added to it. Scripted, not a person playing. **These have no sound:** the private display has no audio device, so the exported game played silently; the clips with sound are the Movie Maker ones one folder up. The X pointer shows where the display left it.

| What | File | Taken |
|---|---|---|
| The captivity and the escape, 19 s | [exported-1-captivity-escape.mp4](exported-1-captivity-escape.mp4) | From when the game logged the prologue's first line, 1.96 s after it started |
| The ritual, 10 s | [exported-2-ritual.mp4](exported-2-ritual.mp4) | From when it logged the ritual's start |
| The walk from the open gate beside the ridge into the reveal, 12 s | [exported-3-gate-to-reveal.mp4](exported-3-gate-to-reveal.mp4), and [six frames](exported-3-frames.png) at 1, 3, 5, 7, 9 and 11.5 s | From when it logged the awakening's end. The reveal starts about 6.1 s in, its first line about 10.8 s in |
| Stills: the captivity with its card; the ritual with its caption; the reveal at the hand | [prologue](route-03-prologue.png), [ritual](route-05-ritual.png), [reveal](route-12-reveal.png) | The route's own screenshots, ImageMagick `import` of the display |

The three takes are from one run of the route (`runs=4 failed=0`); the stills from the run before it on the same exported build (`runs=4 failed=0`). **The route's first attempt on this build failed,** in its first run, climbing to the stone: after a landing at 154 s the next hop did not take him off the ground and the climb, which hops again only on a landing, waited out its 30 s. Nothing on that climb changed in this pass; the two attempts after it, and every route in CI, passed. The takes were made by `~/work/dagon-m4/bin/exported_burst.sh`, which starts `ffmpeg -f x11grab` when the game's log shows each moment.
