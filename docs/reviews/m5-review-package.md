# M5 Review Package: Cinematic horror and polish

**To:** ChatGPT (independent reviewer), and the owner for listening and the playtest. **Date:** 2026-11-16, completed 2026-11-18, revised after the independent review on 2026-11-18 (§13), after the owner's playtest of 2026-11-19 (§14), after the owner's second playtest that day, of `59562c6` (§15), after their third, of `ea86ae9` (§16), and with the owner's acceptance of 2026-11-20 (§17).
**Status: accepted by the owner on 2026-11-20 at `b7303bf`, as the completed milestone (§17, [record](../evidence/m5/owner-acceptance-2026-11-20.md)), after an independent review and four playtests by the owner; merged into `main` from #6. A milestone acceptance only: nothing tagged or released.** The owner approved the scope on 2026-11-16 ([plan](../m5-plan.md)). `v0.1.0-pre-alpha.1` is untouched. M6 is not started.

| | |
|---|---|
| **Repository** | https://github.com/shamsuzzamansadi/dagon |
| **Branch and pull request** | `m5/polish`, draft [#6](https://github.com/shamsuzzamansadi/dagon/pull/6) |
| **Base** | `main` at `09d854e` (M4 and the record of its release), CI run [43835351375](https://github.com/shamsuzzamansadi/dagon/actions/runs/43835351375): passed; its release gate found `v0.1.0-pre-alpha.1` already published and published nothing |
| **The tested code and the candidate for the owner** | **`b7303bf`**, CI push run **[44731893136](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136)**: the motion pass (§16), with its evidence scripts, which are not in the build. It replaces `ea86ae9`, which the owner played on 2026-11-19, as they had `59562c6` and `20929cf` before it that day |
| **Acceptance fingerprint of that commit** | `sha256:1f724cdc2c582c997c9b7b780ff092f4763c0077b5defe9805c6cce37533dc8d` (`python tools/release_gate.py fingerprint --commit b7303bf`). The builds the owner played: `ea86ae9`, `sha256:a4f4d974…3304`; `59562c6`, `sha256:cb51c11a…78e6`; `20929cf`, `sha256:17cc0b91…c1bc`. The first submitted, `sha256:76ac6c4e…af61`. `main`'s is `sha256:614f29b6…7f6e`, M4's accepted one |
| **Final HEAD** | A file cannot name its own commit; the pull request names it. Every commit after `b7303bf` is documents only and changes nothing the fingerprint covers |
| **The Windows candidate for the owner** | `dagon-windows` from run 44731893136, artifact 14627487176, zip SHA-256 **`97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`** (§8) |

**What has been verified, by whom.**

| Result | Who or what ran it |
|---|---|
| Native tests, integration tests from source and on the exported pack, on GCC, Clang and MSVC | CI, at `b7303bf` (§6) |
| The exported Linux and Windows release builds, played to the ending with window-system keys | CI, scripted, on the candidate; and, before the review, the developer's run of the Linux one on a private display (§6). Not a person, not a physical keyboard |
| Deliberate breakage of what M5 added | Developer, scripted (§6). Simulated input only |
| How the reveal, the ending's pictures, the far figures, the prologue's raider, the ritual, the emergence, the arm and the sea look and move | **Developer only,** from frames and clips at the game's scale, software-rendered (§2 to §4, §15, §16) |
| What a recogniser hears in the finale's nine lines, from the game's own recording | A local Whisper model, word against script (§5) |
| Levels, peaks, loudness, ducking, the voice against its bed | Measured by the tools in §5 |
| **How any of it sounds** | **Nobody.** The developer cannot hear. No listening by the owner or anyone is recorded for M4's or M5's sound |
| **M5, played** | **The owner, three times on 2026-11-19:** `20929cf` ([record](../evidence/m5/owner-playtest-2026-11-19.md)), five points, addressed in §14; `59562c6` ([record](../evidence/m5/owner-playtest-2026-11-19-59562c6.md)), "the build is better", four visual points, addressed in §15; `ea86ae9` ([record](../evidence/m5/owner-playtest-2026-11-19-ea86ae9.md)), broadly satisfied with the visual fixes, three points in motion, addressed in §16. Not acceptance. The new candidate has been played by the scripts only |
| A first-time player | Nobody, on any build (M6) |
| Independent review | **ChatGPT, 2026-11-18,** of the head first submitted (`cd28f55`): it checked the final head's CI and rehearsal conclusions, the matching fingerprints, the art checker, selected code and the supplied frames. **It did not rerun the Godot integration tests or the exported routes, and did not listen to the audio.** Three findings, addressed in §13 |

## 1. Delivered, item by item

| # | The plan's item | State | Record |
|---|---|---|---|
| 1 | The reveal's composition | **Done.** The straight edge at x = 4544 is gone: the trench's night is carried back behind the Monolith, and the canyon's wall falls away behind it, so the arm crosses open sky to the stone. The creature is redrawn for the size it is seen at, in the Monolith's light, with spray behind and before it | [reveal](../evidence/m5/reveal/README.md), D105, D106, `420ac08` |
| 2 | The creature's animation | **Done,** inside the clip's same 14 s: it stirs, rises with weight, settles as its hand comes down, breathes; the arm turns about its shoulder; the head goes back as it calls and turns with its line; the eye opens; water is heaved up and pours off it. **No line, sound time, camera key or C++ changed** in that commit; after the owner's playtest the head's turn was enlarged and the wide view held 0.8 s longer, within the same 14 s (D114) | [reveal](../evidence/m5/reveal/README.md), D107, D108, `420ac08` |
| 3 | The ending's four pictures | **Done:** the sailor in the boat and the steamer's boat pulling to him; the man at the window, a hand on the glass, joined to its sleeve after the review; an open gold cuff with the eye and waves; the reveal's own crest breaking the sea beside a town. One hand, one light. Lines, order, voice and timing unchanged | [ending](../evidence/m5/ending/README.md), D110, `4e48a97`, `10bf2b3` |
| 4 | The roadmap's remaining M5 art | **Done:** the ritual's stones and figures, the watchers and the distant shape are drawn, on the shapes the clips already move | [figures](../evidence/m5/figures/README.md), D111, `5504431` |
| 5 | Audio and presentation | **Reviewed by measurement; one local change.** In 300 to 4000 Hz the water stood near the reveal's first line, a diagnostic of level, not of intelligibility; the cascade and surge are keyed lower under it. No clipping, no abrupt transition, no overlapping speech, nine finale lines whole. A fresh listening package with timestamps. **Nothing has been heard** | [audio](../evidence/m5/audio/README.md), [listening](../evidence/m5/listening/README.md), D112, `b1cb401` |
| 6 | Validation and handoff | This package; §6 and §8 | |

**The roadmap's M5 row,** item by item, is in [the plan](../m5-plan.md). Of its exit gate: the full playthrough with final content is scripted (§6) and waits for the owner's; GDD §8's checklist on the reveal is the developer's, from frames ([reveal](../evidence/m5/reveal/README.md)); the cinematic regression tests are green; **"audio heard in gameplay" is not met,** and cannot be by the developer.

## 2. What changed, by file

**One C++ change, after the owner's playtest:** the Hud's prompt says what the next press does (`src/hud.cpp`, `src/hud.hpp`, D113). Apart from those two files, `git diff 09d854e -- src SConstruct project/project.godot project/default_bus_layout.tres project/assets/audio project/assets/narration project/narration project/scenes/ui` is empty.

| Where | What |
|---|---|
| `project/scenes/level/shore.tscn` | The canyon wall's outline; the backdrop's place; the creature's nodes (the crest, eye and pupil under the head; a lit image for each part; the ridge's drawing); haze, a surge, two new particle emitters and the old ones reshaped; the reveal clip's new tracks (51 in all, from 33); two volume tracks; drawings under the far figures' shapes |
| `project/assets/reveal`, `abyss`, `cave`, `prologue` | The creature's nine images and a water drop; the trench's backdrop, the canyon wall and a surge; nine small figures; the four ending pictures, the window's again after the review |
| `tools/art/gen_creature.py`, `gen_ending.py`, `gen_figures.py` (new); `gen_reveal.py`, `gen_abyss.py`, `gen_prologue.py`, `generate.py`, `check_art.py` | The art, as code. `gen_creature.py` needs NumPy and SciPy, as `gen_reveal.py` did; `check_art.py`, which CI runs, does not |
| `tools/scene/` (new) | `scene_edit.py`, and the recorded edits of the scene: `wire_reveal_m5.py`, `wire_figures_m5.py`, `wire_audio_m5.py`; after the playtests `stage_turn_m5.py`, `stage_visual_m5.py`, `stage_motion_m5.py` |
| `project/assets/reveal/emerge.gdshader` (new, the motion pass) | **The project's first shader:** the body, head and crest come out from the ridge, and the arm from the shoulder, driven by the clip's own fades (D119, D120). Four maps of distance beside it, data and not artwork; a cap of the body's pixels over the arm's root; and, beside the camera from the level's start, the crest through the shader and one particle, drawn and unseen, so nothing is first drawn in the reveal |
| `project/tests/` | `test_narrative.gd`: two new tests, two updated for the head's children. `test_revision.gd`: the hidden-art check follows parents and, after the review, counts a clip as showing a node only on a true key; three new tests; one updated for the ridge's drawing. `capture_m5.gd`, `record_finale.gd`: evidence, not tests |
| `tools/breakage_m5.py`, `tools/audio/voice_band.py`, `tools/audio/limiter_use.py`, `tools/audio/subtraction_check.py` | New; the last after the review |
| Documents | The plan, D105 to D112, the roadmap's and README's status, the handoff, `docs/evidence/m5/` |

## 3. The reveal

Before and after, as the clip plays: [frames](../evidence/m5/reveal/before-after.png); [every half second](../evidence/m5/reveal/after-every-half-second-1.png) ([2](../evidence/m5/reveal/after-every-half-second-2.png), [3](../evidence/m5/reveal/after-every-half-second-3.png)); clips with sound, [before](../evidence/m5/reveal/reveal-before.mp4) and [after](../evidence/m5/reveal/reveal-after.mp4). The [record](../evidence/m5/reveal/README.md) has what changed, what did not, and GDD §8's checklist.

**Held by the scene's structure and by tests, not by care:** the crest, eye and pupil are children of the head, so they cannot part from it; the arm's keys end at rest, where M3's test finds the hand on the Monolith; the carving's light and its times are untouched; every outcome of the reveal is still the director's, so a missing, looping or stuck clip ends as it did.

## 4. The ending's pictures, and the far figures

[Before and after, with each card up](../evidence/m5/ending/before-after.png); [the window's hand, as first submitted and corrected](../evidence/m5/ending/window-hand-before-after.png); clips with sound, [before](../evidence/m5/ending/ending-before.mp4) and [after](../evidence/m5/ending/ending-after.mp4); the [record](../evidence/m5/ending/README.md) sets each of the owner's five points beside what is drawn. The far figures: [before and after](../evidence/m5/figures/before-after.png).

## 5. Audio

**Measurements and transcripts only; no listening by the developer.** The owner reports that their recording of 2026-11-19 holds all four epilogue voice clips. The figures within 300 to 4000 Hz are a diagnostic of level against what plays beneath, **not a measure of intelligibility, and 6 dB is not a threshold of hearing.** What plays beneath is the mix less the voice; after the review that subtraction was shown to hold, to the sample and to within 0.4 dB on a constant-gain estimate ([check](../evidence/m5/audio/subtraction-check.txt)), except the bed-alone take's figures for the first line, which are estimates. The transcripts, of the voice alone, show the lines are whole, not that they are heard in the mix. The [audio review](../evidence/m5/audio/README.md) has the method, the finding, the one change (D112), GDD §7's Witness row against what plays, and the event list. The [listening package](../evidence/m5/listening/README.md) has the whole game recorded with its sound, the candidate's sound (its epilogue shows the window as first submitted), cut by stage, and **eight places for the owner's ears, each with its time.**

## 6. Tests actually run

| What | Result | On |
|---|---|---|
| CI: GCC, Clang, MSVC, release tools | **Passed.** Integration 455/0, from source and on the exported pack, on GCC 11.4, Clang 18.1.3 and MSVC 19.44; the release tools; the art check | `b7303bf`, push run 44731893136; pull-request run 44731897937 |
| CI: the exported route on Linux and Windows | **`runs=4 failed=0` on both** | the same runs |
| After the motion pass, local, clean tree: debug and release builds, `run_godot_checks.sh`, `export_check.sh linux`, the exported Linux route on a private display, with silent video of the exported game | **Passed on its first attempt:** debug and release builds; integration 455/0 and three smoke runs; `export_check.sh linux`, 455/0 on the exported pack; the exported Linux route `runs=4 failed=0`. Run on `050ec57`, the same game as the candidate by its fingerprint: `b7303bf` changes only the art check's imports. A further route run, `runs=4 failed=0`, with frame rates printed, gave the exported game's silent video ([record](../evidence/m5/motion-pass-2026-11-19/exported/README.md)) | `b7303bf`, native Linux clone |
| After the motion pass: `run_godot_checks.sh` on the working tree before each commit | Integration 454/0 on the first candidate's tree, `d8626f7`, and 455/0 on this one's; clean import, classes, three smoke runs | `d8626f7`, `b7303bf` |
| After the motion pass: CI on `d8626f7` (push run 44724941040, pull-request run 44724948958) and on `050ec57` (push run 44728685433, pull-request run 44728693208) | **Failed, on the art check alone,** on Linux and Windows: its new shoulder check imported `gen_creature.py`, and with it NumPy, which CI does not install for the check (§2). The Clang job and the release tools passed. Fixed in `b7303bf`, the candidate: the shoulder's place is in `tools/art/shoulder.py`, the generated art is unchanged, and the check passes with NumPy and SciPy blocked. The game's fingerprint is the same at `050ec57` and `b7303bf` | `d8626f7`, `050ec57` |
| After the motion pass: the local gate on `d8626f7` and on `050ec57`, with the exported route | Both passed: debug and release builds, integration 454/0 and 455/0, three smoke runs, the export check, the exported route `runs=4 failed=0` on its first attempt each time | `d8626f7`, `050ec57` (the same game as the candidate) |
| After the motion pass: frame times at the game's own pace through the reveal's first 7 s, no shader cached (`record_visual.gd` `emergence-timing`) | `ea86ae9`: one long frame, ~178 ms at 2.6 s, in each of three runs; `d8626f7`: that and ~185 ms at 3.0 s; with the warm-up: **no frame over 100 ms,** two runs. Software renderer | `ea86ae9`, `d8626f7`, `b7303bf` |
| After the motion pass: `tools/art/check_art.py`, with a new check (the shoulder is the body's own pixels and lies over every pixel of the arm that crosses the body at 73 turns across the clip's turn) and the ridge's check widened (the water stands before the whole body, deep enough, with no clear pixel) | `CHECK_ART problems=0` | `b7303bf` |
| After the motion pass, focused: `test_revision.test_the_creature_comes_out_from_the_ridge_and_out_of_one_water`, `…the_arm_comes_out_from_under_the_shoulder` (in the engine, at 5.6, 6.5, 6.95, 7.0 and 10.0 s), `test_narrative.test_the_sea_that_followed_him_comes_on_over_him_and_then_the_screen_fades`, `…the_water_covers_the_whole_view_at_its_height`; the two tests of the screen-space sea replaced | Pass | `b7303bf` |
| After the motion pass: deliberate breakage, `tools/breakage_motion_m5.py`, 9 entries, each putting back one of the faults | **9 caught, 0 not caught, controls held** ([result](../evidence/m5/breakage-motion.txt)): the body fading in whole over the ridge, the water short of the walkway's end, the shoulder never shown or set aside from the arm's root, the arm fading in whole, the shader first drawn in the reveal or its warm-up too clear to be drawn, the sea stopping at the collapse or falling short of a runner | `b7303bf` |
| After the motion pass: Movie Maker recordings of `ea86ae9` and of the pass with sound (the emergence, the escape running, the escape caught), and the emergence with each part in a flat colour | Every stage mark on the same frame in both; the sound identical sample for sample over each whole take; below the waterline, before 271 frames of 271 showed part of the creature, after none | `ea86ae9` and `b7303bf` |
| After the visual pass, local, clean tree: debug and release builds, `run_godot_checks.sh` (clean import, classes, integration, three smoke runs), `export_check.sh linux`, the exported Linux route on a private display, with its stills and short silent video of the exported game | **Passed, the exported route on its second attempt:** debug and release builds; integration 452/0 and three smoke runs; `export_check.sh linux` ok, 452/0 on the exported pack; the exported Linux route `runs=4 failed=0` on its second and third attempts. **Its first attempt failed** in its first run, climbing to the stone, when a hop was not taken after a landing; nothing on that climb changed ([record](../evidence/m5/visual-pass-2026-11-19/exported/README.md)) | `ea86ae9`, native Linux clone, clean tree |
| After the visual pass: `tools/art/check_art.py`, with two new checks: the ridge's top and left edge are the body's, it goes below the walkway farther than the creature rises, and the water covers its foot; the ritual's ground strip is the backdrop's, each kneeler's knee is on the crest, and bowing shows nothing below it | `CHECK_ART problems=0`. The ridge check, run on `59562c6`'s art, fails on all three counts | `a495d42` |
| After the visual pass, focused: `test_revision.test_the_ridge_stands_in_water_and_the_ritual_ground_lies_before_the_kneelers`, new | Passes | `a495d42` |
| After the visual pass: recordings of `59562c6` and of the pass with sound (the captivity and the escape, the ritual, the approach to the reveal) | Every stage mark on the same frame in both; the sound identical sample for sample, the ritual's and the approach's in full, the prologue's over the whole of the shorter take | `59562c6` and `a495d42` |
| After the first playtest, local, clean tree: `run_godot_checks.sh`, `export_check.sh linux`, the exported Linux route | **Passed:** integration 451/0 and three smoke runs; the export check 451/0 on the pack; the route `runs=4 failed=0`, its reading run showing [E] Skip line at the mural while `monolith.first` was said, the press skipping it, then [E] Examine and the mural examined | `59562c6`, native Linux clone, clean tree |
| CI on `ede8c71`, before the candidate | **Failed on one test,** `test_controller.test_examine_works_with_a_controller_at_the_boat_and_the_fish`, 450 of 451 passing on each compiler: it expected Examine at the boat while the boat's own line was said, where the prompt now rightly says Skip line (D113). The expectation is corrected in `59562c6`; the test file is not in the build | `ede8c71`, runs 44517994038 and 44518002808 |
| After the owner's playtest, focused: the three new prompt tests and the staging test, each also run against the old code, where they fail on the prompt and on the camera | Pass on the fix; fail on the old code, on exactly the owner's points | `bde9cae`, `55f3d25` |
| After the owner's playtest: recordings of both builds with sound (the prologue, the mural, the finale) | Every stage mark on the same frame in both; the mural's presses behave alike, the prompt differs as intended; the finale's sound identical, sample for sample, but for 12.0 to 13.9 s of the reveal, where positional sounds follow the camera, 35 to 65 dB below the mix | `20929cf` and `ede8c71` |
| After the review, local, focused: `test_revision` (all), `test_narrative` (all), every test named for the ending | All passed ([record](../evidence/m5/hidden-art-check.txt) for the hidden-art checks) | `10bf2b3`, native Linux clone |
| After the review: one deliberate breakage of the hidden-art check, the head's show key made false | The check as submitted passes it; as tightened, it names all nine of the head's tracks ([record](../evidence/m5/hidden-art-check.txt)) | `10bf2b3` |
| After the review: `tools/art/check_art.py` | `CHECK_ART problems=0`; only `ending_2_listen.png` changed | `10bf2b3` |
| After the review: the ending in the game, frames with each card up, and the finale recorded again with its sound | The hand joined to the sleeve; the sound identical, sample for sample, to the take of 2026-11-16 | `10bf2b3` |
| **Before the review,** local: `run_godot_checks.sh` (integration 446/0, all ok), `export_check.sh linux` (ok, 446/0 on the pack), the exported Linux route (`runs=4 failed=0`), `check_art.py` (0) | Passed. **Not run again in full locally after the review;** CI ran the suite and both routes on the candidate | `5aab2a4`, native Linux clone |
| Deliberate breakage, `tools/breakage_m5.py`, 12 entries, 3 workers | **12 caught, 0 not caught, controls held** ([result](../evidence/m5/breakage.txt)). Not run again: the review's changes are a picture and a stricter test | `d9d3ab6`; `b1cb401` after it adds two volume tracks only |
| The release packaging, rehearsed: both packages built, extracted and run headless on their own OS (main menu, New Game, a save, Continue), version `.0`, which cannot be published | **Run on the pull request's final head,** which has the same fingerprint. Its run is linked in the pull request's description, not here | final head |
| Native unit tests | 127/127 on all three compilers in CI. **Not rerun locally;** the one C++ change, the Hud's, is covered by the integration tests | `b7303bf` |

**Preserved behaviour, and the tests that hold it** (all in the suite above, all passing):

| Asked to be preserved | Held by |
|---|---|
| The gate's movement | `test_puzzle.test_solving_raises_the_drawn_gate_and_then_opens_the_way`; `test_restore` (a closed gate's slab at each beat); the exported route |
| The reveal's sequencing | `test_narrative.test_the_reveal_shows_a_head_body_and_hand_with_highlights_that_appear_in_order`; `…the_hand_rests_on_the_monolith_and_the_head_is_in_frame_at_the_widest_view`; `…the_creature_moves_as_a_body…` (new) |
| Narration completion | `test_narration.test_every_voiced_line_in_a_clip_is_heard_out_before_the_next`; `…every_line_of_the_epilogue_is_spoken…`; and, from the game's own voice-alone recording, nine lines word for word (§5): whole lines, not heard in the mix |
| Pause | `test_cinematics.test_pausing_stops_the_clip_and_the_watchdog`; `…pause_during_a_cinematic_then_quit_to_the_main_menu_then_new_game_starts_clean`; silence while paused, measured |
| Save and Continue | `test_restore.test_a_restored_awakened_world_plays_correctly`; `…each_beat_saved_in_one_process_continues_correctly_in_another`; the exported route Continues from the Awakened save and after the ending |
| Cinematic completion paths | `test_cinematics`: a missing, looping and stuck clip for the awakening, the reveal and the collapse; the watchdog; `…the_reveal_keeps_control_locked_right_up_to_reveal_done` |
| The prompt and the press | `test_narration`: `…at_the_mural_during_the_monolith_line_the_prompt_says_skip_and_the_line_runs_out`, `…a_press_during_the_monolith_line_only_skips_it_then_the_next_examines`, `…the_skip_prompt_names_a_rebound_key_and_a_controller_button`, `…a_stone_press_during_a_story_line_still_presses_the_stone` (now with its prompt) |
| The head's turn, in view | `test_narrative.test_the_head_turns_in_view_as_its_line_begins`; the cinematic contract's tests unchanged and passing |
| The story, controls, collision, narration and mix, through the visual pass | The whole suite and both exported routes; the scene's changes are drawings, their places and two sprites no clip moves (`test_revision.test_the_ridge_stands_in_water…`); the recordings' sound compared sample by sample |
| The ridge in water and along the shoulder's outline; the ritual's ground | `check_art.py`'s ridge and ritual checks; `test_revision.test_the_ridge_stands_in_water_and_the_ritual_ground_lies_before_the_kneelers` |
| No clip moving hidden legacy art | `test_revision.test_no_clip_animates_a_hidden_node_it_never_shows`, tightened, and after the review counting only a true key as showing; `…a_visibility_track_that_only_hides_does_not_count_as_showing`, new; `…every_shape_a_clip_moves_or_fades_draws_something`, new; four breakages |
| Timing | The finale's stage and line marks fall on the same frames on `main` and on M5 ([marks](../evidence/m5/reveal/marks.txt)) |

## 7. Unresolved, and known

1. **Nothing has been heard.** The reveal's level and the mix were left to the owner's ear in M4 and still are. The roadmap does not let audio be called complete until a person hears it in the game.
2. **"Its head turned. I ran."** stands 6.7 dB above its bed within 300 to 4000 Hz, and 4.0 dB below it for half a second under the creature's second call. A diagnostic, not a verdict: measured, left unchanged, and listed for the owner's ear. It was not changed to reach a number.
3. **Across the whole spectrum** the reveal's three lines and the flight's first are within 3 dB of what plays under them, and `listening.py narration` flags them. That bed is mostly below 300 Hz. Whether it troubles the voice is for a listener.
4. **The creature is drawn in blocks of two pixels,** right for the half zoom it is seen whole at, coarser than the stone beside it in the clip's first and last two seconds.
5. **The haze is a smooth fall of colour,** not pixels, as the fog bank past the gate already was.
6. **The waterline is under the caption at half zoom.** What shows the water is above it.
7. **Frame time was not measured.** Fifteen sprites, two polygons and two small particle emitters were added to one scene, and six polygons removed. The visual pass adds two sprites that never move; the motion pass adds two sprites, one shader on four of the creature's drawings, and a wider strip of water, and removes a screen-sized layer.
8. **Amber in the ending's pictures** is the bracelet's gold, a candle and three lamps, beyond the game's rule that it is the lantern's alone; M3's pictures did the same for the bracelet and the candle.
9. **The far figures and the awakening** were looked at in stills only; the awakening's clip was not changed. The collapse was changed in the motion pass and looked at in motion (§16).
10. **No measure of intelligibility** was made. The band figures are level, the transcripts are of the voice alone, and a recogniser would not stand for a listener.
11. **The full recording's epilogue shows the window as first submitted,** and the opening's gun, the mural's prompt, the reveal's end and the last picture as they were before 2026-11-19, the prologue's raider, the ritual and the ridge as they were before the visual pass, and the emergence, the arm and the collapse's sea as they were before the motion pass; the corrected ones are in the clips.
12. **The full-game recording's sound:** its sound is the candidate's except from 12.0 to 13.9 s of the reveal, where positional sounds follow the camera's new hold and differ by 35 to 65 dB below the mix (recordings of both builds compared sample by sample). The playtest's clips are scripted recordings.
13. **The arm still comes in at 5.5 s,** out from the shoulder over 0.45 s, as it came in faded before; and the sea's rush at the collapse is fast, about 400 px/s, so it reaches a runner as far ahead as one can be before the fade (D120, D121). Whether either reads well is for the owner. *(Was: the ridge's right side showing inside the fading body; fixed, D119.)*
14. **The escape's raider is seen from astern,** so its gun is out of frame; the funnel's band, the rail, the portholes and the band above the waterline carry the ship over (D117).
15. **The clips are scaled by three** from the game's 480 × 270, nearest pixel. The exported build's own video has no sound: the private display has no audio device.
16. **Carried, unchanged:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

## 8. The build for the owner

**One candidate:** `dagon-windows` from CI **push** run [44731893136](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136), commit `b7303bf`, artifact 14627487176: https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136/artifacts/14627487176. Zip SHA-256 **`97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`**. Linux, the same run: `dagon-linux`, `bbf8858ea174cb8346d92544d2ea5d2ab6a9b6de386e9197c800769712327505`. Both zips downloaded and hashed; they match GitHub's digests. The pack's ten new or changed images match the generated art wherever they show, its shader is present, and the screen-space sea's image is gone: checked by loading them from the downloaded Windows pack.

**It replaces `ea86ae9`** (run 44575980858, Windows zip `1a8dc273…e67e`), which the owner played on 2026-11-19. What a player meets that differs: the creature coming out from the ridge and out of one water, the arm out from the shoulder, and the sea at the collapse (§16).

**`ea86ae9` replaced `59562c6`** (run 44519096516, Windows zip `f8cf8ecf…8c4`). What a player met that differed: the captivity's and the escape's pictures, the ritual's figures, and the ridge, with the water at its foot (§15).

**`59562c6` replaced `20929cf`** (run 44412125349, Windows zip `3e5f8d65…0ca8`), which the owner played first on 2026-11-19. What a player met that differed: the raider's gun, the prompt during a line, the reveal's last seconds and the last picture (§14).

**It replaces `5aab2a4`** (run 43904143559, Windows zip `2f052d97…0418`), which has the window's hand as first submitted. Nothing else a player meets differs between the two.

It is the push run's, not the pull-request run's, which builds a merge commit with another checksum (D93). **It is not a release:** no record in `release/` asks for one, and none is added.

## 9. What still needs a person

| Who | What |
|---|---|
| **The owner** | **Listen:** the eight places in the [listening package](../evidence/m5/listening/README.md), above all the reveal and the one change to it |
| **The owner** | **Look, in play:** does the creature read, and stand apart from what is behind it; is the seam gone at your display's size; does its motion have weight without being busy; do the hand and the carving still belong together |
| **The owner** | **The ending:** is the sailor readable in the boat; is the rescue shown enough and not too much; does the man at the window read as him, and as anxious; does the bracelet read as a bracelet; does the crest read as the creature's; do the four belong together |
| **The owner** | Controller vibration and feel at the awakening, the hand and the fall, on hardware: the roadmap's "tuning by feel". Cues unchanged |
| **The owner** | **The visual pass, in play:** the captivity's gun and guard and the escape's ship in motion; the ritual's figures, with and without the caption; the ridge in the water and its edge into the rising shoulder |
| **The owner** | **The motion pass, in play:** the shoulder coming out of the ridge and the water; the arm from the shoulder to the hand through the camera's move and the landing; the sea into the collapse, running and caught. Whether what is fixed is what you saw |
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
| Story, puzzle, collision, progression, contract intact | One C++ change, the Hud's prompt; the suite and the exported routes pass | — |
| The four pictures | Each of the five points is answered in the drawing | Whether each reads to the owner |
| The second playtest's four visual points | Each answered in the drawing and looked at in the game at its scale, the ritual also with the Hud hidden; the ridge's edge is the body's, checked | Whether each reads to the owner, in play |
| The third playtest's three points in motion | Each reproduced on recordings of `ea86ae9` and changed; looked at frame by frame and in clips at normal speed; measured where it can be (the waterline, the arm under the shoulder) | Whether each is what the owner saw, and whether it now reads, in play |
| Audio checked; no master change to hide a local problem | Checked by measurement; one local change; master untouched | **Everything about how it sounds** |
| A playable candidate | Identified in §8 | The owner's playtest |

**Not claimed:** that M5 is complete. It is implemented and validated as far as scripts, frames and measurements go.

## 11. For the reviewer

1. Is the reveal's clip still safe under the cinematic contract, with 18 more tracks and two more emitters? Anything a clip now does that an outcome depends on?
2. `tools/scene/wire_reveal_m5.py` bakes the keys. Do the arm's and head's keys agree with their pivots, and end at rest?
3. Is the tightened hidden-art check right to name `Rockfall` and `Tide` as shown by the director, or does that hide a case? *Answered by the review:* the exemptions stand; the check now needs a true key (§13).
4. Is measuring the voice against its bed in 300 to 4000 Hz a fair way to find masking, and is 6 dB there a defensible stopping point without a listener? *Answered by the review:* a diagnostic only, and not a threshold (§13).
5. Anything in the frames or clips that reads wrongly at the game's scale: the creature's coarser pixels at full zoom, the haze, the bracelet's sheared mark, the sailor in the boat.

## 12. Reproducing it

```
git clone --recurse-submodules https://github.com/shamsuzzamansadi/dagon && cd dagon && git checkout b7303bf
scons platform=linux && tools/prepare_project.sh
GODOT=<godot 4.7.2> sh tools/run_godot_checks.sh build/logs/checks
python tools/art/check_art.py
# Frames and recordings need a real window, on a private display (docs/toolchain.md §6a):
godot --path project --resolution 1440x810 --fixed-fps 60 --script res://tests/capture_m5.gd -- <out>
godot --path project --resolution 960x540 --write-movie <out.avi> --fixed-fps 30 --script res://tests/record_finale.gd
godot --path project --resolution 1440x810 --fixed-fps 60 --script res://tests/capture_visual.gd -- <out> [prologue|ritual|approach]
DAGON_RECORD_SCENE=approach godot --path project --write-movie <out.avi> --fixed-fps 30 --script res://tests/record_visual.gd
# The motion pass: emergence, emergence-parts, escape-run, escape-caught; <out>/f.png writes lossless frames and a WAV
DAGON_RECORD_SCENE=emergence godot --path project --write-movie <out>/f.png --fixed-fps 30 --script res://tests/record_visual.gd
```

## 13. The independent review, and what was done

**ChatGPT, 2026-11-18,** reviewed the head first submitted, `cd28f55`. **It checked:** the final head's CI and the packaging rehearsal's conclusions, that the fingerprints match, the art checker, selected code, and the frames supplied. **It did not** rerun the Godot integration tests or the exported routes, **and did not listen to the audio.** Its three findings, and what was done:

| Finding | Done | Evidence |
|---|---|---|
| **The window's raised hand stands apart from the arm:** in `gen_ending.py` the hand ends near row 83 and the sleeve begins near row 98 | The forearm ends in a cuff at row 108, below the window's bar; the wrist comes out of it into a hand a little larger, flat on the lower pane beside his ear, two rows clear of the bar. Regenerated, and looked at in the ending in the game, at its scale, with the card up. The other three pictures are unchanged, byte for byte | [close-up, before and after](../evidence/m5/ending/window-hand-before-after.png), [record](../evidence/m5/ending/README.md), `10bf2b3` |
| **The hidden-art check takes any `:visible` track as showing its node,** even one whose every key is false | A clip shows a node only by an enabled `:visible` track with a key, within the clip, that sets true. A new focused check on a made-up clip holds that a track of false keys, a true key after the clip's end and one on a disabled track excuse nothing, and that the `Rockfall` exemption covers only that node. The `Rockfall` and `Tide` exemptions, and the tests of the director showing them, are kept. The scene passes; with the head's show key made false, the old check passes and the new one fails | [record](../evidence/m5/hidden-art-check.txt), `10bf2b3` |
| **The audio evidence claims too much:** the 300 to 4000 Hz comparison is a diagnostic, 6 dB is not an auditory threshold, the subtraction of separate takes needs sample alignment and compatible processing, and transcripts of the voice alone do not show it is understood in the mix | **Alignment and processing established** for the takes behind every figure, by a new tool: the takes are the same to the sample until the voice begins, mix and voice correlate best at a lag of 0 for every line on both channels, the voice's gain in the mix is 0.983 to 1.009, the limiter never reached its ceiling in the mix or the voice take, so what could be left moves a figure by at most 0.4 dB, on a constant-gain estimate. **The bed-alone take did reach the ceiling inside the first line,** so its two figures there are labelled estimates. The records now call the band figures a diagnostic, 6 dB a prompt to listen, and the transcripts proof of whole lines only. **"Its head turned. I ran." stays flagged for the owner's ear and unchanged** | [audio review](../evidence/m5/audio/README.md), [check](../evidence/m5/audio/subtraction-check.txt), [before the change](../evidence/m5/audio/subtraction-check-before.txt), D112, `20929cf` |

**Not done after the review:** the breakage campaign of `tools/breakage_m5.py` and the full local gate were not run again (CI ran the suite and both exported routes on the candidate), and the whole game was not recorded again.

## 14. The owner's playtest of 2026-11-19, and what was done

**The owner personally played `20929cf`** (artifact 14478607459) on Windows. **Not acceptance;** final acceptance is pending. The [record](../evidence/m5/owner-playtest-2026-11-19.md) has the owner's five points with the times in their recording; the [clips](../evidence/m5/playtest-2026-11-19/README.md), before and after with the game's sound, show each change.

| # | The owner's point | Done |
|---|---|---|
| 1 | The raider's deck gun pointed into the moon | Trained left over the bow on the captured ship, clear of the moon, dark with the moon along its top. Guard, ships and timing unchanged (`c415efa`, D115) |
| 2 | At the mural, [E] Examine showed while `monolith.first` was said, and the line ended at 3.8 s | Reproduced: a press during a story line has always only skipped it; left alone, the line runs its length. **The prompt now says Skip line while a press would only skip,** with the rebound key's or the controller's label, and the focus's own prompt otherwise. Skipping and the stones unchanged. Three focused tests, failing on the old Hud (`bde9cae`, D113) |
| 3 | The camera was leaving the head as "Its head turned. I ran." came up | The head lowers 0.16 rad toward the sailor from 11.4 to 12.5 s, and the wide view holds to 12.8 s; the line, the sounds' times, the 14 s, the return of control and the escape are unchanged; positional sounds follow the camera, so 12.0 to 13.9 s sounds very slightly different, 35 dB or more below the mix. A test holds it, failing on the old scene (`55f3d25`, D114) |
| 4 | The last picture's reflection and the crest's base | The moon's road under the moon; the crest, still the reveal's own, stands on the head. Looked at in the game with the caption up (`c415efa`, D115) |
| 5 | The audio evidence's wording | The 0.4 dB is called a constant-gain estimate; the limiter caveat stays; the second creature call stays flagged for listening; the master level is unchanged (`ede8c71`) |

## 15. The owner's second playtest of 2026-11-19, of `59562c6`, and the visual pass

**The owner personally played `59562c6`** (artifact 14526884514) and said the build is better. **Not acceptance;** the owner asked for this focused visual pass before M5 is presented for acceptance. The [record](../evidence/m5/owner-playtest-2026-11-19-59562c6.md) has the four points with the times in their recording; the [clips and stills](../evidence/m5/visual-pass-2026-11-19/README.md), before and after with the game's sound, show each change, and the [exported build's own](../evidence/m5/visual-pass-2026-11-19/exported/README.md) show the candidate as it ships.

| # | The owner's point | Done |
|---|---|---|
| 1 | The captivity: the gun's base to meet the deck; the figure right of the moon to have a head, shoulders and planted feet | The gun, still trained left, on a pedestal through the rail to a base on the deck; the guard at an opening in the rail with cap, head, shoulders, greatcoat and boots apart; the raider given a ship's bow, an anchor, a band above the waterline and a funnel (`758007d`, D117) |
| 2 | The escape: the cropped hull read as a wall or a cliff; a recognizable hull carried over from the captivity; its contact with the water; the rower readable | The same raider from astern: counter stern and rudder, rail, the funnel with its band, a mast, empty davits with their falls, white along its waterline and its reflection; the lamp, boat and oars where they were (`758007d`, D117) |
| 3 | The ritual: heads, bowed torsos and kneeling poses readable, the watcher told apart, still distant and unsettling; the picture to tell it without the caption | Four hooded figures kneeling bowed toward the marked stone, knees on the crest; a watcher facing us with a pale face, a pointed hood and a crooked staff; a strip of the backdrop's ground hides what the clip's bow takes below the crest. Looked at with the Hud hidden (`a495d42`, D118) |
| 4 | The approach: the ridge, his shoulder, embedded in water, and its contour followed into the rising shoulder; one take of the approach, the last still moment and the first movement; timing, dialogue and cues kept | The ridge's edge is the body's own up its left and over its top, and it goes below the walkway; water past the walkway at its foot, which it rises out of. The clip, lines and sounds untouched. The take is clip 3 (`a495d42`, D116) |

## 16. The owner's third playtest of 2026-11-19, of `ea86ae9`, and the motion pass

**The owner personally played `ea86ae9`** (artifact 14556713598), was broadly satisfied with the visual fixes, and named three issues in motion. **Not acceptance;** the owner asked for one focused pass before accepting M5. The [record](../evidence/m5/owner-playtest-2026-11-19-ea86ae9.md) has the points and what was found; the [clips and stills](../evidence/m5/motion-pass-2026-11-19/README.md), uninterrupted, before and after with the game's sound, show each with its timestamps; the [exported build's own](../evidence/m5/motion-pass-2026-11-19/exported/README.md) show the candidate's game as it ships.

| # | The owner's point | Found | Done |
|---|---|---|---|
| 1 | Dagon emerging: the internal edge at 3.0 to 4.3 s, the waterline as the body rises, the same submerged shape becoming the shoulder | The ridge's straight right side stood as an edge inside the fading body to about 4.2 s; past the walkway's end the creature went on down past the water, which lay behind it, in every frame of the reveal; at the game's own pace, a long frame at 2.6 s, the first spray drawn, after which the clip jumped ahead | The body, head and crest come out of the fog from the ridge outward, through a shader driven by the clip's unchanged fade; the water runs before the whole creature, so nothing of it shows below the waterline; the shader and a particle drawn unseen from the level's start, so the reveal does not stall (`d8626f7`, `b7303bf`, D119) |
| 2 | The detached hand: the first frame the connection breaks, and its cause; one connected limb through the camera's move and the landing | The arm was never joined: a separate drawing over the body, ending in a straight cut lit like an outer edge, which met the body's sloping outline only at its lower corner, from its first frame at 5.5 s; and for its first 0.45 s it faded in whole, the half-seen hand dark against the pale stone with the forearm lost against the night | The root rounded about the shoulder, with the body's own pixels laid over it wherever it crosses the body; its fade-in brings it out from the shoulder to the hand. Checked at the top of the swing, just before contact and at the landing (`d8626f7`, D120) |
| 3 | The advancing sea, running and caught: where the leading edge comes from, how it moves, where the water is at the cut to the collapse | At the collapse the sea stopped dead; caught, he fell out of it and lay beside a still wall of water; 2.5 s in, a second sea in the screen's own space rose from the bottom of the screen | The same sea comes on from where the flee left it, at the flee's pace, then rushes over him and rises to fill the view; the second sea is gone; both outcomes and the flee's rule unchanged (`d8626f7`, D121) |

No line, sound, haptic cue, camera key, collision or outcome changed, and the clips' lengths are unchanged; the recordings' sound is identical sample for sample before and after.

## 17. The owner's acceptance, 2026-11-20

**The owner played `b7303bf`** (`dagon-windows`, artifact 14627487176, zip SHA-256 `97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`) **and accepted it as the completed M5 milestone.** In the owner's words: in their recorded running route, the ridge reads as Dagon's shoulder, the arm stays connected through the hand landing, and the same wave overtakes the fallen sailor; they are satisfied with the result. The [record](../evidence/m5/owner-acceptance-2026-11-20.md) has the owner's words in full.

| Covered | By whom or what |
|---|---|
| The running route on `b7303bf`, with the three points of the motion pass | The owner, playing, recorded |
| The standing-still ending: the sea has him and goes on over him | Scripts only: the recordings and clips of §16, the exported route's run that waits out the flee, and the tests |
| The owner's video frames, and the recorded audio measured against the owner's earlier clip | ChatGPT, as the owner reports. It did not listen |
| **The intelligibility of the reveal's dialogue by ear** | **Nobody. Open for M6,** as the owner said |

**A milestone acceptance only.** The owner authorized the squash merge of #6 and the branch's clean-up; a new tag or release, such as `v0.2.0-alpha.1`, needs the owner's separate approval. `v0.1.0-pre-alpha.1` is untouched.
