# Owner's Windows recording: measurements

**Source:** `Screen Recording 2026-11-02 094037.mp4`, supplied by the project owner. It is 30.4 s,
1464×870, 30 fps, and is not committed to the repository. Measured by extracting every frame and
tracking the placeholder's pixels. This is a partial gameplay check, and the measurements describe
this one session only.

## Which build

**Not confirmed.** The recording cannot show its commit. If the filename's 09:40:37 is the owner's
local time (UTC+1), then the latest finished CI run at that moment was `23ae9aa`
(run 41414005143, 08:36:59 UTC), but any earlier artifact is also possible. The M1 builds look
identical on screen.

## Shown

| Observation | Measured | Expected |
|---|---|---|
| Game launches and runs on Windows at 3× scale | 1440×810 client area with stair-stepped 3-px pixels | 480×270 × 3 |
| Walking speed, camera at its limit | 70.4 px/s (t = 23.0–25.6 s) | 70 px/s |
| Right-wall stop | Body centre 450.3, wall 456 on screen | About 6 px half-width |
| Jumps on flat ground | Peak 23–27 px, airtime 0.40–0.50 s | Up to 25.8 px and 0.54 s at full hold |
| Facing follows direction | Marker flips side at each direction change | |
| Left-to-right crossing | Rock, slope, trench and steps all crossed; stops at the right wall | |
| Camera follow and level limit | Sailor held near screen centre, then moves on screen once the camera reaches its limit | |

## Defect found: camera jitter

**During steady walking, the character's screen position flickers by 1 game pixel (3 screen
pixels).** In the recording's follow section (t = 4.0–22.4 s, 553 frames), its position changed by
±1 px on 161 frame transitions; most of the others were 0.

This is not a recording artefact: the M1 engine capture, which has no screen recorder in the path,
shows the same flicker on 88 of 600 frames at 60 fps. The player and the smoothed camera are each
rounded to whole pixels separately, so their difference alternates.

It is cosmetic, and movement itself is unaffected, but it conflicts with the GDD §8 requirement for
stable camera motion. It was missed in the M1 frame inspection.

**Status:** fixed in both scenes after this recording (`54c1f7e`,
[measurements](../shore/camera-jitter.txt), software rendering). In a
[later session](windows-playtest-2026-11-02-standard-build.md) the owner reported that the camera
generally felt fine. That session's commit is unconfirmed, and jitter was not measured on that display.

## Not shown or not established

- **Input device.** Video cannot show whether a keyboard or gamepad was used, so no mapping is confirmed.
- **Movement feel.** That needs the owner's own judgment.
- **Walking left over obstacles.** Leftward movement is brief (about 29 px at the end, plus short turns).
- **Gamepad, all mappings, real-GPU visual correctness.** Still open.
- **Audio.** The recording's audio track is silent (−91 dB). The build has no audio yet, so this is expected.
