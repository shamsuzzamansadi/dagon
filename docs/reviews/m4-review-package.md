# M4 Review Package: Atmosphere

**To:** ChatGPT (independent reviewer), and the owner for listening and the playtest. **Date:** 2026-11-13.
**Status: complete for review, not accepted.** The owner approved [the plan](../m4-plan.md) on 2026-11-10 and authorized its implementation, stopping here: no merge, tag, release or itch.io submission, and M5 not started.

| | |
|---|---|
| **Repository** | https://github.com/shamsuzzamansadi/dagon |
| **Branch and pull request** | `m4/atmosphere`, draft [#4](https://github.com/shamsuzzamansadi/dagon/pull/4) |
| **Base** | `main` at `ad6df8c` (M3, squash-merged), CI run [42817688574](https://github.com/shamsuzzamansadi/dagon/actions/runs/42817688574) |
| **The tested code and the build for the owner** | **`4fcdd6be78033e17b01d1576c088a9465e32ca52`**, CI run **[43503636921](https://github.com/shamsuzzamansadi/dagon/actions/runs/43503636921)** (push) |
| **Acceptance fingerprint of that commit** | `sha256:024a966bb1515d5708a7490af2b15765f12e92a351781ce412a2af913e631c5c` (`python tools/release_gate.py fingerprint --commit 4fcdd6b`) |
| **Final HEAD** | A file cannot name its own commit; the pull request and the handoff name it. Every commit after `4fcdd6b` adds only documents and evidence |
| **The Windows build for the owner** | `dagon-windows` from run 43503636921, zip SHA-256 **`1ec506451d71dd0072473f8fe6cd15d691b9e2aa9487ed19e67f8e9883aded8a`** (§8) |

**What has been verified, by whom.**

| Result | Who or what ran it |
|---|---|
| Native tests, integration tests from source and on the exported pack, on GCC, Clang and MSVC | CI, at `4fcdd6b` |
| The exported Linux and Windows release builds, played to the ending with window-system keys, and timed | CI, scripted; and the developer's run of the Linux one on a private display (§6). Not a person, not a physical keyboard |
| Deliberate breakage of M4's new logic | Developer, scripted (§6). Simulated input only |
| How each stretch of the art looks | **Developer only,** from captures at the game's scale, software-rendered (§3) |
| What the voice recogniser hears in each recording | A local Whisper model, word against script (§4) |
| Levels, peaks, loudness and ducking | Measured by `make_sounds.py` and `listening.py` (§5) |
| **How any of it sounds** | **Nobody yet.** The developer cannot hear. The owner has not heard M4's voice lines, sounds or mix |
| **The new art, played** | **Nobody yet** but the scripts |
| A first-time player | Nobody, on any build (M6) |
| Independent review | Not yet done |

## 1. Delivered, item by item

| # | The plan's item | State | Record |
|---|---|---|---|
| 1 | The prologue spoken in voice A | Done: four lines, each word-checked; the voice measured above its music and sea | [narration](../evidence/m4/narration/README.md), [prologue](../evidence/m4/prologue/README.md), D95, D96 |
| 2 | Continuity from the prologue into the Shore; its first lines voiced | Done: How to Play before the prologue; the last picture is the Shore as the game opens on it; he gets up beside his boat (`shore_wake`); the boat and the fish spoken. Continue and Restart never show the prologue or the waking | [opening](../evidence/m4/opening/README.md), D97 to D99 |
| 3 | Environment art past x = 1440, in route order | **Done: no greybox shape left on the route,** in seven stretches. Collision unchanged. What still shows as a flat shape is M5's: the creature and the ritual's far figures | [art](../evidence/m4/art/README.md), D100 |
| 4 | Audio polish | **Made and measured, not heard:** interface sounds, an examine sound, three Abyss beds in walking order, weight for the rock and both seas. The reveal's level and the mix wait for the owner's ear, as the plan says | [audio](../evidence/m4/audio/README.md), [listening](../evidence/m4/listening/README.md), D101 |
| 5 | The rest of the spoken script in voice A | **Done for every story line:** ten more, 22 in all. Examine lines stay text, as the plan says. The reveal's lines are spaced so each is heard out | [narration](../evidence/m4/narration/README.md), D102 |
| 6 | Validation for acceptance | This package; §6 and §8 | |

## 2. The schedule

The window was 11 to 14 November. Items 1 to 6 are complete on 13 November. **What remains is not the developer's to do:** the owner's listening, which sets the mix (item 4's last step), the independent review, and the owner's acceptance. The owner's target of completion before 20 November stands; M5 has not started.

## 3. The art (item 3)

Each stretch was drawn by `tools/art/gen_abyss.py` from the scene's own shapes, in the reference section's palette and methods, captured from the game at its own 480 × 270, and looked at, with the way in and out of it, before the next.

| Stretch | Commit | What to look at |
|---|---|---|
| A. The Abyss's ground and far view | `622ca0e` | The seam at 1440 gone; the Abyss open to the sky |
| B. The rib arch | `cdb1ba6` | Bone, snapped from the spine, behind the carving |
| C. The crossing | `a9bbd3c` | The ledges, the post, the slab and boulder moving as the puzzle moves them |
| D. The shelves, tablets and props | `b5bd3b2` | The procession relief; the footprint, seen on the way to it |
| E. The canyon, stones, gate and trench | `5ed5c01` | Lit and unlit signs (`e3` against `f2`); the trench behind the reveal |
| F. The mural | `c8cb324` | Faint fragments, then the whole carving lit |
| G. The flight | `27d918f` | The falling rock, the sea following him, the sea closing over him, the fog's edge |

**How it is checked.** `tools/art/check_art.py` holds every image to the 32-colour palette, and the Abyss's ground to the collision column by column (3080 columns). The greybox shapes are hidden, not deleted, because the tests and the clips still read and move them: a drawing on a moving thing is the child of the shape the director or clip already moves.

**Known in the art:**

- At the reveal, **a straight seam runs up beside the creature's arm at x = 4544.** Left of it is the Shore's sky layer, fixed to the screen, which covers only part of it when the camera draws back; the greybox had the same seam. The reveal's composition belongs to M5, with the creature's final art.
- The trench is on screen only during the reveal. Its sky has no ordered dither: at the camera's half size, dithering folded into shapes that were not there.
- The tide's front is still the vertical face of the shape the director moves; its foam breaks ragged ahead of it.
- Software rendering only. Nobody has seen the art on a GPU or a real screen.

## 4. Narration (items 1, 2 and 5)

22 lines in voice A: every story line in the script, and four things he can examine (the boat, the fish, the talisman, the carving in the cave). Each take was chosen from several by pace, and each recording was transcribed by a local recogniser and compared with the script: **all 22 word for word**, Innsmouth's recorded exception aside ([transcripts](../evidence/m4/narration/transcripts.txt)). A transcript says which words are heard, not whether they sound right.

**For the owner's ear:** three lines are quicker than the voice's range, with no slower take: the crossing (14.7 characters a second), the stones answering (14.2), and the reveal's first line (14.6). The prologue's escape line is 15.1. More takes are cheap.

**The reveal's recognition line was cut off** 2.6 s in by the next line, as its caption already was: found from the clip's timings while voicing it. The lines were respaced (D102), and a test now holds every clip: a voiced line ends before its clip's next line.

## 5. Sound (item 4)

Synthesized by `tools/audio/make_sounds.py`, as in M3. Only the new and changed files were made again ([measurements](../evidence/m4/audio/measurements.txt): 46 files, no clipping, loop seams or DC offset).

**The mix in play** was recorded with everything in it and measured ([listening package](../evidence/m4/listening/README.md)):

| Check | Result |
|---|---|
| Clipping | None: true peak −1.0 dBTP, at the Master bus's limiter |
| Loudness by stage | The reveal −17.4 LUFS, running −18.3, the stones answering −19.9, the prologue −21.5, the Shore −21.3, the seabed −26.8 |
| Clicks; while paused; the main menu | None; silence; silence |
| Sudden changes | The menu's knocks from silence and the resume, expected. **A 20 ms drop at the cut into the game,** not in a second recording of the same build with the tool item 2 used; cause not established |

**Nothing here is a listening judgment.** The plan gives the reveal's level and the mix to the owner's ear. That is the one step of item 4 that is not done.

## 6. Tests and results

| Check | Result | On |
|---|---|---|
| Integration suite | **439 passed, 0 failed** | `4fcdd6b`, GCC debug, native Linux clone |
| `tools/run_godot_checks.sh` | clean import, classes, integration, three smoke runs: all ok | `4fcdd6b` |
| `tools/export_check.sh linux` | ok: the release extension loaded, new game and Continue ran | `4fcdd6b` |
| The exported route, `tools/route_check.py`, private display | `ROUTE_RESULT runs=4 failed=0`: reading everything, 295 s to the end of the credits; direct, 134 s; waiting out the flee; Continue after the ending | `4fcdd6b` |
| Native unit tests | 127 of 127, in CI | `4fcdd6b`; M4 changed nothing under `src/core` |
| CI: GCC, Clang, MSVC, the release tools | Passed. Integration 439/0 on each compiler; the exported route `runs=4 failed=0` on Linux and on Windows; native tests 127/127 | `4fcdd6b` |
| Deliberate breakage of M4's new logic ([entries](../../tools/breakage_m4.py), [result](../evidence/m4/breakage.txt)) | 16 of 17 caught at `e24d726`, controls held; the survivor had no effect but on `is_waking()`, and is caught at `d0d0606` once that is checked | `e24d726`, `d0d0606` |
| `check_art.py` | problems=0 | each art commit |
| `make_sounds.py --check` | 46 files, problems=0 | `6eea116` |

**Defects found while building, and fixed:**

- The menu's accept sound tried to play after a scene-changing press had taken the menu out of the tree (27 tests failed on it). Such a press is now silent.
- The two new ambience beds were imported without looping; the existing ambience test caught it.
- The reveal's recognition line was cut off by the next; the new timing test holds it.
- An incremental import crashed the editor once at shutdown (signal 11) and left one recording without its import file. A clean import, as the checks script always does, had no crash. Not investigated further: it is Godot's import step, not the game.

## 7. Known issues, deferred checks and limits

- **Nothing in M4 has been heard.** The voice lines, the new sounds and the mix are measured only.
- **The art has been looked at by the developer only,** software-rendered.
- **A 20 ms drop in the sound at the cut from the prologue into the game,** in one of two recordings of the same build; cause not established (§5, [record](../evidence/m4/listening/README.md)).
- The reveal's seam (§3). The creature, its animation, the reveal, collapse and ending clips, and the ritual and watcher beyond silhouettes are **M5's**, by the roadmap.
- **Examine lines past the Shore and the cave are text,** by the plan, unless the owner asks.

**Unchanged, and not passed:** all physical PlayStation hardware; individual physical Xbox actions, including disconnecting and reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering; two external first-time players and their timings (M6); the unresolved M2 J/caption event; the two breakage survivors of M3's revision, which the reviewer considered non-blocking.

**For the reviewer's judgment:**

1. **D100 to D102:** do they stay inside the approved plan? In particular, G (the flight's rock and seas) was not listed in item 3's text but is in M3's deferral of "art past x = 1440" and in the plan's "no greybox shapes left on the route".
2. **Hidden, not deleted:** greybox shapes stay in the scene, invisible, because tests and clips read them. Is that a debt worth paying down in M5?
3. **Interface sounds from `MenuController`:** focus the menu sets itself is silent by a flag around its own focus calls. Is there a path that moves focus without going through them?
4. **D102's respacing of the reveal:** M5 redoes the reveal. Is a timing test the right guard until then?

## 8. The builds

**Windows, for the owner:** [`dagon-windows`](https://github.com/shamsuzzamansadi/dagon/actions/runs/43503636921/artifacts/14075713434) from run [43503636921](https://github.com/shamsuzzamansadi/dagon/actions/runs/43503636921), the push run of `4fcdd6b`. Zip SHA-256 **`1ec506451d71dd0072473f8fe6cd15d691b9e2aa9487ed19e67f8e9883aded8a`**. The pull request's run builds the same source, and its zip's checksum will differ ([why](../evidence/m3/build-identity-53e8d23.md)).

**Linux:** [`dagon-linux`](https://github.com/shamsuzzamansadi/dagon/actions/runs/43503636921/artifacts/14076400232) from the same run, zip SHA-256 `61412ac01aefe247d4292f8c7b4a044f45d3cf63e04dbd67cf5b07cde6779f5e`.

## 9. The owner's checklist

**Use exactly the Windows build named in §8, with its checksum.** Extract the whole zip into a new, empty folder and run `dagon.exe`. Please do not change your system's keyboard layout for this check.

1. **Listen first:** the [whole-game recording](../evidence/m4/listening/README.md) and its excerpts. **Does the reveal's loudness feel right? Is the voice too quick anywhere? Do the new menu and examine sounds, the deeper Abyss, the rock and the sea sit right?** Your notes set the mix; nothing else will.
2. **New Game, and let the prologue play** into the Shore without pressing anything: is the join felt?
3. **Walk the Abyss to the Monolith slowly.** Does each stretch read: the ribs, the crossing, the shelves and tablets, the canyon, the stones, the mural lit?
4. **The reveal and the flight:** are all three of the reveal's lines heard out? Do the rock and the sea feel heavy?
5. **Continue,** after quitting mid-game: no prologue, no waking.

**Please report:** that you used this build; anything wrong; and your answers to 1, 3 and 4.

## 10. What happens next

The independent review, the owner's listening and playtest, then the owner's decision. Changes they ask for are made on this branch. Then, only on the owner's acceptance: CI on GCC, Clang and MSVC, squash merge, CI on `main`, and the branch deleted. M5 starts after that, not before.
