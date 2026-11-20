# From the exported build

**The real exported Linux release game,** built and exported by the local gate from `050ec57` (`export_check.sh linux`), whose game is the candidate's, `b7303bf`: the same fingerprint, `sha256:1f724cdc…3dc8d`. Played by `tools/route_check.py` with window-system keys (XTEST) on a private X display; its own window, 1440 × 810, nothing added to it. Scripted, not a person playing. **These have no sound:** the private display has no audio device; the clips with sound are the Movie Maker ones one folder up. The X pointer shows where the display left it. The game ran with Godot's `--print-fps`, which only prints to its log.

| What | File | Taken from |
|---|---|---|
| The walk from the open gate beside the ridge, the emergence, the arm and the hand's landing, 24 s | [exported-1-gate-to-hand.mp4](exported-1-gate-to-hand.mp4) | When the game logged the awakening's end. The reveal begins about 6.5 s in, dated by its first line, which shows at 10.8 s: the ridge stirs at about 8.0 s, the body comes out from it from about 9.5 s, the arm from about 12.0 s, the hand lands at about 13.5 s |
| The sea, running, through the collapse, 17 s | [exported-2-sea-running.mp4](exported-2-sea-running.mp4) | When the first take ended, about 3.5 s after the flee began: the sea behind him at the edge of the view, the collapse about 6 s in, the sea going on over him and up until the screen fades |
| The sea, caught, through the collapse, 12 s | [exported-3-sea-caught.mp4](exported-3-sea-caught.mp4) | When the game logged the flee's start, in the route's run that waits for the sea: the sea comes on at about 2.5 s, has him at about 4.4 s, goes on over him, rushes and rises |

The route, in the same run: `runs=4 failed=0`.

**Frame rates in that run,** from `--print-fps`, one reading a second: 124 to 160 through the walk and the whole reveal; no second under 60 in any of the four runs. Without the capture, in a run before it: 128 to 156 through the reveal.

**A jump that was the capture's, not the game's.** The two takes made before this one started ffmpeg the moment the reveal began. Each showed the still ridge for about 2.4 s, then jumped at once to the reveal's first line. The game's own frame rates in the runs above show no stall, and a take started before the reveal, this one, shows no jump: for its first seconds after starting, the capture on this machine did not keep up with the window. The stalls the game itself had on a first draw, 130 to 190 ms, were measured another way and are gone (D119, the [clips' record](../README.md)).
