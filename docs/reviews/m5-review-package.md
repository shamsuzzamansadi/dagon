# M5 Review Package: Cinematic horror and polish

**To:** ChatGPT (independent reviewer), and the owner for listening and the playtest. **Date:** 2026-11-16, completed 2026-11-18.
**Status: implemented, for independent review and the owner's playtest. Not accepted, not merged, nothing tagged or released.** The owner approved the scope on 2026-11-16 ([plan](../m5-plan.md)). `v0.1.0-pre-alpha.1` is untouched. M6 is not started.

| | |
|---|---|
| **Repository** | https://github.com/shamsuzzamansadi/dagon |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6) |
| **Base** | `main` at `09d854e` (M4 and the record of its release), CI run [43835351375](https://github.com/shamsuzzamansadi/dagon/actions/runs/43835351375): passed; its release gate found `v0.1.0-pre-alpha.1` already published and published nothing |
| **The tested code and the candidate for the owner** | **`5aab2a4`**, CI push run **[43904143559](https://github.com/shamsuzzamansadi/dagon/actions/runs/43904143559)**. The game itself last changed at `b1cb401`; `5aab2a4` adds evidence only |
| **Acceptance fingerprint of that commit** | `sha256:76ac6c4e42ad47297ffc71d8610fb5aaa56b59cb84cf6beb787b7d51b144af61` (`python tools/release_gate.py fingerprint --commit 5aab2a4`; the same at `b1cb401`). `main`'s is `sha256:614f29b6…7f6e`, M4's accepted one |
| **Final HEAD** | A file cannot name its own commit; the pull request and the handoff name it. Every commit after `5aab2a4` is documents only and changes nothing the fingerprint covers |
| **The Windows candidate for the owner** | `dagon-windows` from run 43904143559, artifact 14246287757, zip SHA-256 **`2f052d978b9deef480bd25e90e00895d349df0ec18236d85891664ca7b9c0418`** (§8) |

**What has been verified, by whom.**

| Result | Who or what ran it |
|---|---|
| Native tests, integration tests from source and on the exported pack, on GCC, Clang and MSVC | CI, at `5aab2a4` (§6) |
| The exported Linux and Windows release builds, played to the ending with window-system keys | CI, scripted; and the developer's run of the Linux one on a private display (§6). Not a person, not a physical keyboard |
| Deliberate breakage of what M5 added | Developer, scripted (§6). Simulated input only |
| How the reveal, the ending's pictures and the far figures look | **Developer only,** from frames at the game's scale, software-rendered (§2 to §4) |
| What a recogniser hears in the finale's nine lines, from the game's own recording | A local Whisper model, word against script (§5) |
| Levels, peaks, loudness, ducking, the voice against its bed | Measured by the tools in §5 |
| **How any of it sounds** | **Nobody.** The developer cannot hear. No listening by the owner or anyone is recorded for M4's or M5's sound |
| **M5, played** | **Nobody yet** but the scripts |
| A first-time player | Nobody, on any build (M6) |
| Independent review | Not yet done: this package asks for it |

## 1. Delivered, item by item

| # | The plan's item | State | Record |
|---|---|---|---|
| 1 | The reveal's composition | **Done.** The straight edge at x = 4544 is gone: the trench's night is carried back behind the Monolith, and the canyon's wall falls away behind it, so the arm crosses open sky to the stone. The creature is redrawn for the size it is seen at, in the Monolith's light, with spray behind and before it | [reveal](../evidence/m5/reveal/README.md), D105, D106, `420ac08` |
| 2 | The creature's animation | **Done,** inside the clip's same 14 s: it stirs, rises with weight, settles as its hand comes down, breathes; the arm turns about its shoulder; the head goes back as it calls and turns with its line; the eye opens; water is heaved up and pours off it. **No line, sound time, camera key or C++ changed** | [reveal](../evidence/m5/reveal/README.md), D107, D108, `420ac08` |
| 3 | The ending's four pictures | **Done:** the sailor in the boat and the steamer's boat pulling to him; the man at the window, a hand on the glass; an open gold cuff with the eye and waves; the reveal's own crest breaking the sea beside a town. One hand, one light. Lines, order, voice and timing unchanged | [ending](../evidence/m5/ending/README.md), D110, `4e48a97` |
| 4 | The roadmap's remaining M5 art | **Done:** the ritual's stones and figures, the watchers and the distant shape are drawn, on the shapes the clips already move | [figures](../evidence/m5/figures/README.md), D111, `5504431` |
| 5 | Audio and presentation | **Reviewed by measurement; one local change.** The reveal's first line was masked in its own band by the water; the cascade and surge are keyed lower under it. No clipping, no abrupt transition, no overlapping speech, nine finale lines whole. A fresh listening package with timestamps. **Nothing has been heard** | [audio](../evidence/m5/audio/README.md), [listening](../evidence/m5/listening/README.md), D112, `b1cb401` |
| 6 | Validation and handoff | This package; §6 and §8 | |

**The roadmap's M5 row,** item by item, is in [the plan](../m5-plan.md). Of its exit gate: the full playthrough with final content is scripted (§6) and waits for the owner's; GDD §8's checklist on the reveal is the developer's, from frames ([reveal](../evidence/m5/reveal/README.md)); the cinematic regression tests are green; **"audio heard in gameplay" is not met,** and cannot be by the developer.

## 2. What changed, by file

**No C++ changed.** `git diff 09d854e -- src SConstruct project/project.godot project/default_bus_layout.tres project/assets/audio project/assets/narration project/narration project/scenes/ui` is empty.

| Where | What |
|---|---|
| `project/scenes/level/shore.tscn` | The canyon wall's outline; the backdrop's place; the creature's nodes (the crest, eye and pupil under the head; a lit image for each part; the ridge's drawing); haze, a surge, two new particle emitters and the old ones reshaped; the reveal clip's new tracks (51 in all, from 33); two volume tracks; drawings under the far figures' shapes |
| `project/assets/reveal`, `abyss`, `cave`, `prologue` | The creature's nine images and a water drop; the trench's backdrop, the canyon wall and a surge; nine small figures; the four ending pictures |
| `tools/art/gen_creature.py`, `gen_ending.py`, `gen_figures.py` (new); `gen_reveal.py`, `gen_abyss.py`, `gen_prologue.py`, `generate.py`, `check_art.py` | The art, as code. `gen_creature.py` needs NumPy and SciPy, as `gen_reveal.py` did; `check_art.py`, which CI runs, does not |
| `tools/scene/` (new) | `scene_edit.py`, and the three recorded edits of the scene: `wire_reveal_m5.py`, `wire_figures_m5.py`, `wire_audio_m5.py` |
| `project/tests/` | `test_narrative.gd`: two new tests, two updated for the head's children. `test_revision.gd`: the hidden-art check follows parents; two new tests; one updated for the ridge's drawing. `capture_m5.gd`, `record_finale.gd`: evidence, not tests |
| `tools/breakage_m5.py`, `tools/audio/voice_band.py`, `tools/audio/limiter_use.py` | New |
| Documents | The plan, D105 to D112, the roadmap's and README's status, the handoff, `docs/evidence/m5/` |

## 3. The reveal

Before and after, as the clip plays: [frames](../evidence/m5/reveal/before-after.png); [every half second](../evidence/m5/reveal/after-every-half-second-1.png) ([2](../evidence/m5/reveal/after-every-half-second-2.png), [3](../evidence/m5/reveal/after-every-half-second-3.png)); clips with sound, [before](../evidence/m5/reveal/reveal-before.mp4) and [after](../evidence/m5/reveal/reveal-after.mp4). The [record](../evidence/m5/reveal/README.md) has what changed, what did not, and GDD §8's checklist.

**Held by the scene's structure and by tests, not by care:** the crest, eye and pupil are children of the head, so they cannot part from it; the arm's keys end at rest, where M3's test finds the hand on the Monolith; the carving's light and its times are untouched; every outcome of the reveal is still the director's, so a missing, looping or stuck clip ends as it did.

## 4. The ending's pictures, and the far figures

[Before and after, with each card up](../evidence/m5/ending/before-after.png); clips with sound, [before](../evidence/m5/ending/ending-before.mp4) and [after](../evidence/m5/ending/ending-after.mp4); the [record](../evidence/m5/ending/README.md) sets each of the owner's five points beside what is drawn. The far figures: [before and after](../evidence/m5/figures/before-after.png).

## 5. Audio

**Measurements and transcripts only; no listening.** The [audio review](../evidence/m5/audio/README.md) has the method, the finding, the one change (D112), GDD §7's Witness row against what plays, and the event list. The [listening package](../evidence/m5/listening/README.md) has the whole game recorded with its sound at the candidate's game, cut by stage, and **eight places for the owner's ears, each with its time.**

## 6. Tests actually run

| What | Result | On |
|---|---|---|
| Integration suite, editor build, GCC, local | **446 passed, 0 failed** | `5aab2a4`, native Linux clone |
| `tools/run_godot_checks.sh`: clean import, classes, integration, three smoke runs | All ok, no unexpected errors | `5aab2a4` |
| `tools/export_check.sh linux` | Ok: the release extension loaded; New Game and Continue ran; integration on the exported pack 446/0 | `5aab2a4` |
| The exported Linux release build, played to the ending by `tools/route_check.py` on a private display | **`ROUTE_RESULT runs=4 failed=0`: New Game reading everything, New Game direct, Continue and wait out the flight, Continue after the ending** | `5aab2a4` |
| `tools/art/check_art.py` | `CHECK_ART problems=0`, 16 more images in the palette check | `5aab2a4` |
| Deliberate breakage, `tools/breakage_m5.py`, 12 entries, 3 workers | **12 caught, 0 not caught, controls held** ([result](../evidence/m5/breakage.txt)) | `d9d3ab6`; `b1cb401` after it adds two volume tracks only |
| CI: GCC, Clang, MSVC, release tools | **Passed.** Integration 446/0, from source and on the exported pack, on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the release tools | `5aab2a4`, push run 43904143559 |
| CI: the exported route on Linux and Windows | **`runs=4 failed=0` on both** | the same run |
| The release packaging, rehearsed: both packages built, extracted and run headless on their own OS (main menu, New Game, a save, Continue), version `.0`, which cannot be published | **Run on the pull request's final head,** which has the same fingerprint. Its run is linked in the pull request's description, not here | final head |
| Native unit tests | 127/127 on all three compilers in CI. **Not rerun locally:** no C++ changed | the same run |

**Preserved behaviour, and the tests that hold it** (all in the suite above, all passing):

| Asked to be preserved | Held by |
|---|---|
| The gate's movement | `test_puzzle.test_solving_raises_the_drawn_gate_and_then_opens_the_way`; `test_restore` (a closed gate's slab at each beat); the exported route |
| The reveal's sequencing | `test_narrative.test_the_reveal_shows_a_head_body_and_hand_with_highlights_that_appear_in_order`; `…the_hand_rests_on_the_monolith_and_the_head_is_in_frame_at_the_widest_view`; `…the_creature_moves_as_a_body…` (new) |
| Narration completion | `test_narration.test_every_voiced_line_in_a_clip_is_heard_out_before_the_next`; `…every_line_of_the_epilogue_is_spoken…`; and, from the game's own recording, nine lines word for word (§5) |
| Pause | `test_cinematics.test_pausing_stops_the_clip_and_the_watchdog`; `…pause_during_a_cinematic_then_quit_to_the_main_menu_then_new_game_starts_clean`; silence while paused, measured |
| Save and Continue | `test_restore.test_a_restored_awakened_world_plays_correctly`; `…each_beat_saved_in_one_process_continues_correctly_in_another`; the exported route Continues from the Awakened save and after the ending |
| Cinematic completion paths | `test_cinematics`: a missing, looping and stuck clip for the awakening, the reveal and the collapse; the watchdog; `…the_reveal_keeps_control_locked_right_up_to_reveal_done` |
| No clip moving hidden legacy art | `test_revision.test_no_clip_animates_a_hidden_node_it_never_shows`, tightened; `…every_shape_a_clip_moves_or_fades_draws_something`, new; three breakages |
| Timing | The finale's stage and line marks fall on the same frames on `main` and on M5 ([marks](../evidence/m5/reveal/marks.txt)) |

## 7. Unresolved, and known

1. **Nothing has been heard.** The reveal's level and the mix were left to the owner's ear in M4 and still are. The roadmap does not let audio be called complete until a person hears it in the game.
2. **"Its head turned. I ran."** stands 6.7 dB above its bed in the voice's band, and 4.0 dB below it for half a second under the creature's second call. Measured, left, listed for the owner's ear.
3. **Across the whole spectrum** the reveal's three lines and the flight's first are within 3 dB of what plays under them, and `listening.py narration` flags them. That bed is mostly below 300 Hz. Whether it troubles the voice is for a listener.
4. **The creature is drawn in blocks of two pixels,** right for the half zoom it is seen whole at, coarser than the stone beside it in the clip's first and last two seconds.
5. **The haze is a smooth fall of colour,** not pixels, as the fog bank past the gate already was.
6. **The waterline is under the caption at half zoom.** What shows the water is above it.
7. **Frame time was not measured.** Fifteen sprites, two polygons and two small particle emitters were added to one scene, and six polygons removed.
8. **Amber in the ending's pictures** is the bracelet's gold, a candle and three lamps, beyond the game's rule that it is the lantern's alone; M3's pictures did the same for the bracelet and the candle.
9. **The far figures, the awakening and the collapse** were looked at in stills only. The awakening's and the collapse's clips were not changed: no defect was seen in them.
10. **Carried, unchanged:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## 8. The build for the owner

**One candidate:** `dagon-windows` from CI **push** run [43904143559](https://github.com/shamsuzzamansadi/dagon/actions/runs/43904143559), commit `5aab2a4`, artifact 14246287757: https://github.com/shamsuzzamansadi/dagon/actions/runs/43904143559/artifacts/14246287757. Zip SHA-256 **`2f052d978b9deef480bd25e90e00895d349df0ec18236d85891664ca7b9c0418`**. Linux, the same run: `dagon-linux`, `478f021a84572e977c2d24efc2df71ab4409b3db20ab2cdb9e233283aff5bc29`.

It is the push run's, not the pull-request run's, which builds a merge commit with another checksum (D93). **It is not a release:** no record in `release/` asks for one, and none is added.

## 9. What still needs a person

| Who | What |
|---|---|
| **The owner** | **Listen:** the eight places in the [listening package](../evidence/m5/listening/README.md), above all the reveal and the one change to it |
| **The owner** | **Look, in play:** does the creature read, and stand apart from what is behind it; is the seam gone at your display's size; does its motion have weight without being busy; do the hand and the carving still belong together |
| **The owner** | **The ending:** is the sailor readable in the boat; is the rescue shown enough and not too much; does the man at the window read as him, and as anxious; does the bracelet read as a bracelet; does the crest read as the creature's; do the four belong together |
| **The owner** | Controller vibration and feel at the awakening, the hand and the fall, on hardware: the roadmap's "tuning by feel". Cues unchanged |
| **The owner** | Acceptance of an identified build, or what to change |
| **M6, unchanged and unmeasured** | Two external first-time players and their timings: **first-time duration is unknown,** and no 10 to 15 minute claim is made. All physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering |

## 10. Assessment against what a player sees, by the developer

Green CI shows the game still works. It does not show any of this:

| The owner asked | The developer's view, from frames and measurements | Open |
|---|---|---|
| The seam beside the arm removed | **Gone in every frame of the clip;** a test holds the backdrop behind every view | The owner's eye, in play |
| The creature apart from its background | Dark against a lighter sky and haze on its left, lit along its top and right, mist at its foot. **Much improved in stills** | Whether it is enough, and whether it is still restrained |
| Restrained animation with weight, breathing, water | All present in frames. **Motion cannot be judged from frames** | The owner's eye. Breathing is 4 px each 3.3 s: it may be too slight to notice, or right |
| The carving and the hand | Unchanged: the same place, the same light, the same line | — |
| Story, puzzle, collision, progression, contract intact | No C++ changed; the suite and the exported routes pass | — |
| The four pictures | Each of the five points is answered in the drawing | Whether each reads to the owner |
| Audio checked; no master change to hide a local problem | Checked by measurement; one local change; master untouched | **Everything about how it sounds** |
| A playable candidate | Identified in §8 | The owner's playtest |

**Not claimed:** that M5 is complete. It is implemented and validated as far as scripts, frames and measurements go.

## 11. For the reviewer

1. Is the reveal's clip still safe under the cinematic contract, with 18 more tracks and two more emitters? Anything a clip now does that an outcome depends on?
2. `tools/scene/wire_reveal_m5.py` bakes the keys. Do the arm's and head's keys agree with their pivots, and end at rest?
3. Is the tightened hidden-art check right to name `Rockfall` and `Tide` as shown by the director, or does that hide a case?
4. Is measuring the voice against its bed in 300 to 4000 Hz a fair way to find masking, and is 6 dB there a defensible stopping point without a listener?
5. Anything in the frames or clips that reads wrongly at the game's scale: the creature's coarser pixels at full zoom, the haze, the bracelet's sheared mark, the sailor in the boat.

## 12. Reproducing it

```
git clone --recurse-submodules https://github.com/shamsuzzamansadi/dagon && cd dagon && git checkout 5aab2a4
scons platform=linux && tools/prepare_project.sh
GODOT=<godot 4.7.2> sh tools/run_godot_checks.sh build/logs/checks
python tools/art/check_art.py
# Frames and recordings need a real window, on a private display (docs/toolchain.md §6a):
godot --path project --resolution 1440x810 --fixed-fps 60 --script res://tests/capture_m5.gd -- <out>
godot --path project --resolution 960x540 --write-movie <out.avi> --fixed-fps 30 --script res://tests/record_finale.gd
```
