# The owner's playtest of 2026-11-19

**Recorded as relayed to the developer on 2026-11-19.** The owner's points are summarised, limited to what was said. **This is an owner playtest, not acceptance:** final acceptance of M5 is pending.

## The build

The owner personally played **`dagon-windows`, artifact 14478607459, from `20929cf`** (push run [44412125349](https://github.com/shamsuzzamansadi/dagon/actions/runs/44412125349), zip SHA-256 `3e5f8d657ac813633e3f8ea67ad4c0bcd4d0e81c32725d1c3ef4c9eb77e00ca8`), on Windows.

The owner's timestamps refer to their recording `20261119-1024-22.2170049.mp4`. The developer worked from `Screen Recording 2026-11-19 112917.mp4`, 4 min 52 s, in which the events below fall at the owner's timestamps; it looked at its frames and measured its sound's level around the Monolith, and did not listen to it. **Corrected later the same day:** this record first said that no file of the owner's name was on the machine. It was, in the Snipping Tool's own folder, and it is byte for byte the same file as the screen recording used. Neither recording is in the repository.

## The owner's points

| # | At | The owner asked |
|---|---|---|
| 1 | 0:06, the opening | Turn the raider's deck gun toward the open water and the captured ship on screen-left; keep the muzzle clear of the moon so the silhouette reads at game size. Keep the guard, the ships' places and the prologue's timing |
| 2 | 2:59 to 3:04, the Monolith | The recording shows [E] Examine while the story voice is speaking, and the 6.46 s line ends after about 3.8 s. Reproduce approaching the mural while `monolith.first` is speaking, both letting it finish and pressing at the mural. Make the prompt say what the next press will do, also for a rebound key or a controller. Keep deliberate skipping and the stones' input. Add a focused regression check |
| 3 | 3:36 to 3:38, the reveal | By the time "Its head turned. I ran." is on screen, the camera is already leaving the head. If the turn is hard to read in motion, restage it within the clip's duration. Keep the return of control and the escape's timing |
| 4 | 4:35 to 4:48, the last picture | Align the moon's reflection with the moon, and join the crest's base to the creature's back. Check with the caption at game size. Keep the four pictures, their narration and the intended gap in the sailor's memory |
| 5 | Audio evidence | Describe the 0.4 dB figure as a constant-gain estimate; keep the limiter caveat. **The owner's recording has all four epilogue voice clips.** Keep the second creature call flagged for listening, and leave the master level alone on the strength of these measurements |

## What was found and done

| # | Found | Done | Evidence |
|---|---|---|---|
| 1 | The barrel ran up and right from the mount, its muzzle on the moon's disc | Trained left over the bow toward the captured ship, a little down, above the rail, dark against the sky with the moon along its top; a breech behind the mount. Mount, guard, both ships and the lamp unchanged; no scene or timing changed | `c415efa`; [clips and frames](playtest-2026-11-19/README.md) |
| 2 | **Reproduced in the recording and in the game.** `monolith.first` began at about 2:59.2 and the mural's prompt appeared about 2.8 s later, reading [E] Examine; the voice stops at about 3:03.0, 3.8 s in, and about a second later the mural's caption appears, as a press there does. A press during a story line has always only skipped it; the prompt did not say so. **Left alone at the mural, the line runs its whole length** in both builds. Pressing there cuts it and examines nothing, in both | The prompt now asks the same question as the press: **"[E] Skip line"** while a press would only cut the line short, and the focus's own prompt otherwise, with the rebound key's or the controller's own label. Skipping, the stones during speech and the rest of the rule are unchanged (C++, `Hud`) | `bde9cae`; three focused tests in `test_narration`, which fail with the old Hud on the prompt alone; an older controller test, which expected Examine at the boat while its own line was said, brought up to date in `59562c6` after CI failed on it; [clips](playtest-2026-11-19/README.md) |
| 3 | The head turned 0.055 rad, about 3°, by 12.2 s, and the camera began to leave its wide view at 12.0 s; at 12.5 s the head was out of frame | The head lowers toward the sailor by 0.16 rad, about 9°, from 11.4 to 12.5 s; the wide view holds to 12.8 s and is back on the sailor at 13.8 s as before. The line at 12.2 s, every sound's time, the clip's 14 s and the return of control are unchanged; in recordings of both builds every stage falls on the same frame. The sound is the same, sample for sample, but from 12.0 to 13.9 s of the reveal, where positional sounds follow the camera's new hold: 35 to 65 dB below the mix | `55f3d25`, `tools/scene/stage_turn_m5.py`; `test_narrative.test_the_head_turns_in_view_as_its_line_begins`, which fails on the old scene |
| 4 | The moon's road lay 70 px right of the moon; the crest's sloping foot stood over open sea | The road runs under the moon, over the lifted swell and never over the creature; the crest, still the reveal's own image, is sunk 12 px and the head rises under it to meet it, rounding into the back. Looked at in the game with the caption up. The pictures, lines and their order are unchanged | `c415efa` |
| 5 | — | The subtraction tool and the audio record call the 0.4 dB a constant-gain estimate; the limiter caveat stays. "Its head turned. I ran." stays flagged for listening. **The master level is unchanged** | `ede8c71`; [audio review](audio/README.md) |

**Not claimed:** that anyone has listened to the game's sound, the owner's report that the recording holds the four epilogue voice clips aside; or that M5 is accepted.
