# Frame times through every act, on the exported build (M6 plan, item 8)

**What ran:** the exported Linux release game, built and exported here from the branch with the frame log ([D123](../../../decisions.md); the game is `1f68ceb`'s but for the long-frame line, which gained the renderer's time after this run), played by `tools/route_check.py` on a private X display, 1440 × 810, with `DAGON_FRAME_LOG=50`: all four runs, `runs=4 failed=0` ([result](linux-route-result.txt)). **Measured on Mesa's software renderer (llvmpipe), not a graphics card,** and scripted, not a person playing. Report by `tools/frame_report.py`: [linux-route-report.md](linux-route-report.md).

## Results

| | Frames a second, lowest / median | Longest frame | Frames over 33 ms |
|---|---|---|---|
| **In play, every act** (the Shore after its first frame, the Abyss, the Monolith, the awakening, the reveal, the flight, the collapse) | 112–154 / 128–179 | **21.5 ms, once,** as the long caption about the arm on the Shore first appeared (consistent with its letters being drawn for the first time); otherwise at most 15.5 ms | **0** |
| The prologue and the ending | 230–300 / 310–331 | 13.4 ms | 0 |
| **Three changes of scene**, one long frame each | — | 66 ms, 53–56 ms, 37–56 ms | 1 each |

The three long frames, all at a change of scene, none in play:

1. **The prologue handing over to the game:** 66 ms in the run that let the prologue play through. Traced in six more runs of a build with timings added and then removed (three with the prologue skipped, three played through): **61–72 ms, of which building the game takes under 1 ms, adding it to the tree (every node's setup) about 10 ms, and the renderer's own work under 1 ms;** the remaining 45–60 ms is spent outside both, before the frame reaches the screen. **Inferred, not measured directly:** in llvmpipe, which compiles code of its own for each drawing state it meets for the first time. (In the route's run that skipped the prologue at once, the same frame was 31.5 ms.) Hiding parts of the world in turn: the particles about 13 ms of it, the reveal's warm-up about 10 ms (it holds a particle too), the two lights nothing measurable. **A warm-up beneath the title** (one plain, one vertex-coloured and one clipping polygon, a particle, the reveal's shader) **moved about 27 ms to the title's first frame but took only about 6 ms off the handover,** as the software renderer's states depend on more than which shaders are drawn. **Not kept.** Whether this frame is long on a graphics card is for the owner's machines to say, which the native-check sheets now log.
2. **The ending back to the main menu:** 53–56 ms, after Main Menu is pressed; the title scene is loaded again then (not traced further).
3. **Continue into the game:** 37–56 ms; the same setup and first drawing of the world as the first, presumably (not traced further).

## What this does and does not show

- **No stall in play** on this machine's software renderer, through every act, in all four runs. **The stalls M5 found and fixed, 130 to 190 ms at the reveal's first sprays and shader (D119), stay gone:** the reveal's longest frame here is 10.7 ms.
- **On a graphics card** the numbers will differ: frames far faster, and the cost of a first draw spent elsewhere (in the driver's compiler rather than llvmpipe's). **The owner's machines, with `DAGON_FRAME_LOG=50`** ([sheets](../../../m6/native-checks/README.md)), are the measure for players; CI's Windows runner also draws in software (Microsoft's Basic Render Driver through ANGLE).
- Godot's `--print-fps` gives one average a second; Movie Maker steps a fixed time whatever a frame costs (see the project's notes on both). This log times each real frame.
