# M7 plan: publication prep, with the two playtests and the listening check first

**Drafted on 2026-11-27 for the owner's review. Nothing of M7 is implemented until the owner approves it.** Roadmap scope for M7: itch page assets, README, CREDITS, licences, release notes, AI disclosure text (jam.md §5), tag; exit gate: the owner uploads and submits, and the downloaded build is verified on both systems.

**Deadlines (UTC).** Internal submission target **2026-11-29 21:37**. Hard deadline **2026-12-01 21:37**. 30 November to the deadline is buffer: only fixes to upload or packaging problems, no features.

**Starting point.** [`v0.2.0-alpha.2`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.2), published and verified on 2026-11-27, from `b271316`. If M7 changes no game file, it is the build submitted.

## 1. Two first-time playtests (first)

- **Status:** the kit is ready since M6 ([kit](m6/playtest-kit/README.md)); no player has played yet.
- **For the owner to decide: which build.** The kit gives `a4250f0`, the owner's choice for comparable times. Neither player has played, so both could play `v0.2.0-alpha.2` instead and still compare with each other, and what they find would apply to the build submitted. `a4250f0` lacks M6's fixes, such as the cave's edges, the statue after Continue and fullscreen. **Proposed: `v0.2.0-alpha.2`;** updating the kit's links, hashes and differences table takes about an hour.
- **The owner:** finds the two players, shares the build and the instructions, and collects their recordings with sound and their five answers. **By 29 November, about 12:00 UTC,** to leave time for fixes.
- **The developer:** timings and the places they got stuck, from each recording, as [measurement](m6/playtest-kit/measurement.md) says. The developer cannot hear the recordings' sound. Then the findings, with severity and a cost for each fix.
- **What gets fixed in time:** only small, contained fixes that land with CI and the owner's acceptance by the evening of 29 November. Nothing is padded for length: scripted on `b271316`, it takes 3 min 52 s to the ending card reading everything and 1 min 56 s straight through, after the prologue. Everything else is recorded for after the jam.

## 2. Listening check of the reveal's dialogue, in the full mix (first)

- **Status:** the kit is ready ([kit](m6/listening-kit/README.md)). It was recorded at `a4250f0`, and M6 changed no sound, line or mix, so it holds for `v0.2.0-alpha.2`. The owner's sheet is pending.
- **The owner:** about 15 minutes. Step 1 on headphones, then on speakers; step 2 only after sending the sheet.
- **If a line is not understood:** the developer proposes one targeted change to the mix, such as lowering the music and the second call under the third line, and renders before and after takes from the game for the owner's ear. The owner decides. The developer cannot judge it by ear. Captions show every line meanwhile.

## 3. Publication prep (the roadmap's M7 scope)

- **The developer:** an itch page kit with:
  - a spoiler-free description, and the theme's interpretation in one or two sentences (jam.md §4);
  - the controls;
  - the downloads, with system notes: Windows and Linux x86-64; the Mac on Apple Silicon, signed ad hoc and not notarized;
  - the known limitations and what was not tested;
  - the AI disclosure text from jam.md §5;
  - the credits and licences;
  - a cover image and screenshots, captured from the exported build on a private display;
  - an upload checklist.

  README and CREDITS are checked against the build submitted.
- **The owner:** creates the itch page, uploads the build, answers the form's AI question from jam.md §5, and submits.
- **"Downloaded build verified on both systems":** CI's smoke test of each package on Windows and Linux runners, plus the owner's own launch of the itch download on Windows, and on Ubuntu if that run is done.

## 4. The release, if M7 changes the game

- **The version.** release.md names `v0.3.0-rc.1` for M7, but the gate refuses a release candidate with deferred checks, and some cannot be done by 29 November: the Mac by a person, PlayStation hardware, perhaps the players. The options:
  1. **No game change:** submit `v0.2.0-alpha.2` as published, with no new tag.
  2. **Small accepted fixes:** a new alpha, `v0.2.0-alpha.3`.
  3. **`v0.3.0-rc.1`:** only if every deferred check is done, or the owner takes it out of scope in so many words.

  **Proposed: 1, or 2 if fixes are accepted.**
- **How it is published (D134):** the normal CI path. If the 403 of D133 recurs, the documented fallback by hand, after checking the live tag and release state, and only once the owner has authorized that specific release. **M7 leaves `.github/workflows` alone,** so the tagged commit changes no workflow file, which avoids the suspected trigger and tests it.

## 5. The other checks, carried with their actual status

| Check | Status | What it needs |
|---|---|---|
| Ubuntu native run: its display switch, graphics device ("Using Device") and frame log | Untested | The owner's ThinkPad, about 20 minutes ([sheet](m6/native-checks/linux-thinkpad.md)) |
| Frame times on the owner's machines | None reported | `DAGON_FRAME_LOG=50`, during the native runs |
| Continue after Quit to Desktop and a relaunch, by a person | Untested by a person; CI's smoke test of each package does it, headless | The owner, about 2 minutes on Windows |
| Windows display switches; Continue after the ending; Continue at the Shore within one session | The owner's statement on 2026-11-27, from their recordings of the candidate; not reviewed by anyone else | Nothing |
| Physical Xbox controller | The owner's feedback of 2026-11-03: the controls tried worked; no individual row recorded; disconnecting and reconnecting (X17, X18) untested | The owner's controller, about 15 minutes ([sheet](m6/controller-checks/README.md)) |
| PlayStation hardware; vibration by feel | Untested | A PlayStation controller, if anyone has one |
| The Mac build, by a person | Untested; CI's headless checks on Apple Silicon only | An Apple Silicon Mac, if the owner has one or can borrow one |
| German key labels on Windows | Passed in CI on the shipped Windows build of `77d5302`, run 44786112032 ([evidence](evidence/m6/layouts/README.md)) | Nothing; the owner's keyboard layout is left alone |
| M2's examine without its caption | Unresolved; not reproduced in more than a hundred CI repeats | Nothing; stays recorded |
| M3's two breakage survivors | Closed in M6: tests now fail under both breakages | Nothing |
| Length of a first playthrough (10–15 minutes aimed) | Unknown | The two playtests |

## 6. What needs the owner's time, hardware or word

| | When | About |
|---|---|---|
| Choose the players' build | Now | One answer |
| Find, brief and collect the two players | By 29 Nov, about 12:00 UTC | Their sessions, 15 to 25 minutes each, and the setup |
| The listening sheet: headphones and speakers | 28 Nov | 15 minutes |
| Choose the fixes, and the version (§4) | 29 Nov | Answers |
| Accept the build submitted | 29 Nov | One check |
| The itch page, upload, AI question, submission | By 29 Nov 21:37 UTC | About 30 minutes |
| If there is time: the Ubuntu run, the relaunch Continue, the Xbox sheet | Any time | 20, 2 and 15 minutes |
| A Mac or a PlayStation controller, only if available | Any time | — |

## 7. Schedule

| When (UTC) | What |
|---|---|
| 27 Nov | This plan, for the owner's review |
| 28 Nov | The players play; the listening sheet. The developer: the kit, if the build changes; the itch page kit, screenshots and cover; the recordings analysed as they arrive |
| 29 Nov, to 12:00 | Findings, and the owner's choice of fixes |
| 29 Nov, to 21:37 | The fixes, CI, the candidate and the owner's acceptance; publication; the owner uploads and submits |
| 30 Nov – 1 Dec 21:37 | Buffer: upload and packaging fixes only |

**If the players cannot play by 29 November:** submit `v0.2.0-alpha.2` with the page, and keep their findings for after the jam, since the buffer allows no features. Or the owner chooses otherwise.
