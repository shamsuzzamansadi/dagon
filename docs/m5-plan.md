# M5 plan: cinematic horror, and the polish carried from M4

**Status: scope approved by the owner on 2026-11-16,** who authorized implementation of M5 within the existing [roadmap](roadmap.md) and the refinements below, stopping at independent review and the owner's playtest and acceptance. **Not authorized:** merging M5, a tag, another release, or any M6 implementation. `v0.1.0-pre-alpha.1` is left as it is. Branch `m5/polish`, from `main` at `09d854e`; a draft pull request.

M4 is closed. What it deferred is this milestone's input: the roadmap's M5 row, its "carried from M4" list, and items 6 and 7 of the art list.

## Work, deliverables and acceptance checks

| # | Work | Deliverable | Checked by |
|---|---|---|---|
| **1** | **The reveal's composition.** The straight boundary beside the arm at x = 4544 goes: one backdrop behind the whole view the camera draws back to, not a patch on one layer. The creature separated from what stands behind it by light, contrast, depth and water | The trench's night carried behind the canyon's end and the Monolith; the canyon's rim reshaped where the arm and the head cross it; haze between the wall and the creature; the creature redrawn for the size it is seen at, lit from one side throughout | Frames of the reveal **as it plays**, every half second, before and after (`project/tests/capture_m5.gd`); `check_art.py`; a check that no column of the widest view shows the clear colour |
| **2** | **The creature's animation,** restrained, inside the existing clip's 14 s: a rise with weight, breathing, the head turning with the line that says so, the hand coming down heavily and settling, water it displaces, sheds and stands in | New tracks and nodes in `dagon_reveal` only. **No change to its length, its lines' times, its sounds' times, the camera, or any C++.** The carving's light and the hand beside the carving stay as they are | The reveal's staging tests unchanged in what they hold; the hidden-node track check (kept); a new check that every part of the head moves together; pause, skip, restore, missing and stuck clip tests; frames |
| **3** | **The ending's four pictures,** in one framing, light and level of detail: the sailor readable in the boat and a restrained sign of rescue; the man at the window, head, shoulders, hands, anxious, no ambiguous marks; a bracelet that is a curved open band with thickness, carrying the eye and the waves; the last crest recognisably the reveal's, with displaced water and scale | `ending_1..4` redrawn by `gen_prologue.py`. **Order, lines, voice and timing unchanged.** What matters in each stands clear of the card | Captures of each picture with its card up; the epilogue's tests; `check_art.py` |
| **4** | **The roadmap's remaining M5 art:** the ritual's figures, the watcher and the distant shape as more than flat silhouettes (art list, item 7) | Drawn on the nodes the background clips already show and move | Captures; the background-event tests; the hidden-node track check |
| **5** | **Audio and presentation.** Review GDD §7's Witness row and the roadmap's M5 audio against what exists. Check the reveal, the escape and the ending for abrupt transitions, clipping, masking and overlapping speech. Fix local problems locally; **the master level is not moved to hide one** | Measurements of the game's own mix; any local fix with its before and after; a compact event-to-sound list for the reveal, escape and ending; **a fresh listening package cut from the actual game, with timestamps for what needs the owner's ear** | `tools/audio/listening.py`; narration transcripts where a line is touched (none planned). **Measurements and transcripts are labelled as such. The developer cannot hear: no listening pass is claimed** |
| **6** | **Validation and handoff** | Full local gate at integration; CI on GCC, Clang and MSVC; exported routes on Linux and Windows; focused breakage of what is new; the whole game recorded with its sound; before-and-after clips of the reveal and the ending; one identified Windows candidate (commit, run, artifact, zip SHA-256); a review report for ChatGPT; the handoff | The owner's playtest and acceptance, after the independent review |

**Preserved, and tested as such:** story, puzzle, collision, progression and the cinematic contract; pause, narration, save and Continue, fallback completion and the return of control; voice A, every spoken line whole, the ducking, and the prologue-to-Shore handover; the gate rising; the check that no clip animates hidden legacy artwork.

## The roadmap's M5 row, item by item

| Roadmap item | State before M5 | In this plan |
|---|---|---|
| Dagon silhouette and animation | Drawn over the clip's shapes in M3 (D84, D90); moves only as a rise, an arm and a pupil | Items 1 and 2 |
| `monolith_awaken`, `dagon_reveal`, `collapse` clips | All exist, under the contract, since M3; the gate fixed in M4 | `dagon_reveal` polished (2). The other two reviewed in captures; changed only if a defect shows |
| Shake | Exists: trauma keyed in the clips | Kept; reviewed against the new motion |
| Baked audio sweeps, story-trigger cues | Reveal music, surge, call, cascade, impact, turn; the awakening's and the flight's sounds (D74, D85, D101) | Item 5: compared with GDD §7's Witness row; a gap is filled or recorded |
| Epilogue | Four pictures, four lines, voiced (D86, D94) | Item 3 |
| Exit: GDD §8 checklist on the reveal | Not done | Run on the captures, by the developer, and stated as the developer's |
| Exit: cinematic regression tests green | Green at `8b30b33` | Kept green |
| Exit: audio heard in gameplay | **Not heard by anyone on record** | **Stays the owner's.** The listening package serves it |
| Controller tuning by feel, with the owner | Not done | **The owner's, with hardware; not claimable by the developer.** Vibration cues unchanged |
| Prerelease `v0.2.0-alpha.1` | — | **Not requested.** No release record is added in M5 without the owner's word |

## Not in M5

New acts, puzzles, enemy behaviour, waits or text to lengthen play. A playable sequence for the missing memory, which is intended. Rewriting or re-recording narration for the pictures' sake. **For M6, still open and unmeasured:** two external first-time players and their timings, so first-time duration against the 10 to 15 minute aspiration is unknown; all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering. Carried: the unresolved M2 J/caption event.

## Risks

1. **The creature is the largest piece,** and is judged by eye at the game's scale. Frames of the whole clip guard against one frame improving at another's cost; only the owner can say it reads.
2. **The mix needs the owner's ear.** Measurements keep it clean. They cannot make it right.
3. **Every change here voids the acceptance fingerprint,** as any change to `project/` does. The candidate is a new build with its own identity; the published pre-alpha is not affected.
