# M4 plan: Atmosphere

**Status: approved by the owner on 2026-11-10,** who authorized implementation within this scope, in this order, stopping at independent review and owner acceptance. Proposed the same day. From the [roadmap](roadmap.md)'s M4 (atmosphere: the rest of the route in the finished style, ambience, the mix by ear, final narration) and the owner's priorities on accepting M3: **the prologue's spoken narration and continuity first, then the remaining environment art, then audio polish.** M3 is closed and is not reopened; its deferrals are this milestone's input.

**Window:** 11–14 November, then M5 on 15–17 November, by the roadmap's schedule from 9 November. **The owner's target is still completion before 20 November.**

## Work order

| # | Work | Done when | Depends on |
|---|---|---|---|
| **1** | **The prologue spoken in voice A,** all four lines, with `make_audition.py --speak`, each transcribed against the script. The card waits for each voice; Skip and Continue stop it cleanly; the prologue's music and sea duck under it | Every prologue line voiced and word-checked; tests like the epilogue's; a recording of the full prologue with its sound | Nothing: voice A is chosen |
| **2** | **Continuity from the prologue into the Shore:** the last picture, the man waking by his boat on dry seabed, becomes the Shore's first moment, the sailor rising beside that same boat, with no card between that breaks it. The Shore's first lines in voice A (the boat, the fish) | A recording from the last prologue line to the first steps on the Shore; Continue still never shows the prologue | 1 |
| **3** | **Environment art past x = 1440, in the reference section's palette and methods,** in the order a player sees it: the Exposed Abyss's ground, canyon walls and far view; the rib arch; the crossing's ledges, slab and stone; the shelves and tablets; the canyon to the monolith; the trench, gate and stones; the lit mural's panel. Each stretch captured and looked at before the next | No greybox shapes left on the route, the boundary at 1440 gone; captures in evidence; collision unchanged, so the routes and their tests stand | The owner's view of each stretch, as it lands |
| **4** | **Audio polish:** interface sounds and a sound for examining; ambience that changes as the Abyss deepens; the escape's rockfall and the sea given more weight; the reveal's level and the mix set by **the owner's ear**, from a fresh listening package and recording | Measured clean, as now; the owner's listening notes acted on and recorded | The owner's listening |
| **5** | **The rest of the spoken script in voice A,** if 1–4 leave room: the escape's fragments and the story lines; examine lines stay text unless the owner asks | Word-checked like the rest | 1 |
| **6** | **Validation for acceptance:** the integration suite and exported route kept green on GCC, Clang and MSVC; captures; a recording of the whole game with sound; focused breakage of new logic only; a review package; an identified build for the owner | The owner's acceptance of an identified build | The owner; ChatGPT's review |

**Not in M4, by the roadmap:** Dagon's final art and animation, the reveal, collapse and ending clips (M5); the ritual and watcher beyond silhouettes (M5); external playtests, timing against 10–15 minutes and physical controllers (M6).

## Deferred checks, still open and recorded as such

- **Hardware, for M6:** all physical PlayStation hardware; individual physical Xbox actions, including disconnecting and reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering.
- **Playtesting, for M6:** two external first-time players and their timings. Until then, first-time duration and engagement are unmeasured, and no 10–15 minute claim is made.
- **Carried over:** the unresolved M2 J/caption event.

## Risks

1. **Art is the largest piece of work.** If it runs late, the stretches nearest the reveal (canyon, monolith, trench) are finished first, and the Abyss's middle keeps the finished far view over simpler ground, still identified as unfinished.
2. **The mix needs the owner's ear,** and the developer cannot hear. Measurements keep it clean; only listening can make it right.
3. **External playtesters for M6** are needed by 18 November, and are outside the developer's control.
