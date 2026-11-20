# M6 plan: stabilization

**Approved by the owner on 2026-11-20,** as drafted that day, with these specifics: target window **21 to 27 November**; schedule risks flagged early; the playtest kit first and the listening kit early; the reveal heard in the full mix before any transcript or isolated voice; 720p and 1080p, windowed and fullscreen; the native Linux check on the owner's Ubuntu ThinkPad and the Windows check on the owner's desktop; physical Xbox and PlayStation results left pending until someone tests the actual hardware. **Stop for the owner's review before merging M6, publishing `v0.2.0-alpha.1`, or starting M7.**

From the [roadmap](roadmap.md): M6's row ("fixes from at least 2 external playtests, timing (10–15 min), performance, release workflow, native runs on Windows and Linux, usability verification"), its exit gate ("release candidate artifacts from CI launched on real Windows and Linux; GDD §8 checklist on every scene; M6 verification passed"), "M6 verification", the timing follow-up (R11), and what M5's acceptance left open ([record](evidence/m5/owner-acceptance-2026-11-20.md)).

**Who can do what.** **D:** the developer can run it, on scripts, private displays, CI and measurements. **P:** it needs a person playing or listening. **H:** it needs a physical device or a real machine the developer does not have. Where a check is split, both are named, and nothing a script did is recorded as a person's.

## Work, deliverables and checks

| # | Work | Deliverable | Who |
|---|---|---|---|
| **1** | **Two first-time playtests, with their timings.** The owner contacts the players. One verified baseline build for both | The kit: the baseline build, an invitation, spoiler-free instructions for recording with sound, five questions afterwards (**D**). Two sessions (**P**). For each player, from the recording: **time from New Game to the first ending card, and to the return to the menu, separately;** pauses, retries, where they hesitated, whether they needed help; and, if a run falls outside 10 to 15 minutes, what happened in it (**D**) | **D, P** |
| **2** | **Timing against 10 to 15 minutes,** decided on the playtests. Scripted today: 4 min 55 s reading everything, 2 min 13 s going straight through | The playtest times beside the scripted ones. **Options and their cost before any gameplay is added;** per R11, density (an interaction, a reason to look, a beat of story the owner approves), never longer walks, waits or text | **D** proposes, **owner** decides |
| **3** | **Listening: the reveal's dialogue in the full mix, by ear,** open from M5; "Its head turned. I ran." under the creature's second call first | The listening kit, sent early: **the reveal in the full mix first, with no text;** a sheet for what the owner understood, on headphones and on speakers; the transcript and the isolated voice only after (**D**). The listening (**P**). If a line is not understood: a local change to what plays beneath it, offered as a build to hear, never decided by measurement alone | **D, P** |
| **4** | **Physical controllers** | Checklists for Xbox and PlayStation, each action, disconnecting and reconnecting, vibration by feel (**D**). **Results pending until someone tests the actual hardware** (**H**). Simulated-input and label tests rerun, which are not a hardware check (**D**) | **D, H** |
| **5** | **German key labels on the real Windows build,** without touching the owner's layout | A CI job on a throwaway Windows runner with a German layout: Controls and the prompts, screenshotted (**D**). A real keyboard, only if the owner chooses (**H**) | **D, H** |
| **6** | **Displays: 1280 × 720 and 1920 × 1080, windowed and fullscreen** | A fullscreen setting, saved like the others; a window that fits the screen it opens on; captures and checks of **pixel-art sharpness, aspect ratio, long captions, menu navigation, and switching back to windowed** at both sizes (**D**). A look on the owner's screens (**H**) | **D, H** |
| **7** | **Native runs and the release workflow** | The packaging rehearsal and hashed downloads (**D**). **Prepared checks for the owner's Ubuntu ThinkPad,** with hardware rendering confirmed from the game's own log, **and for the owner's Windows desktop** (**D**). The runs (**H**) | **D, H** |
| **8** | **Performance** | Frame times through every act on the exported build, first-draw stalls traced and fixed (**D**, software renderer). The same log from the owner's machines (**H**) | **D, H** |
| **9** | **M6 verification:** settings and saves, rebinding, menu focus, quit, relaunch and Continue, display usability | A matrix of each item against the test or route that holds it, gaps filled with tests (**D**). The owner's pass over the menus (**P**) | **D, P** |
| **10** | **GDD §8 on every scene** | The checklist scene by scene from captures, stated as the developer's view (**D**). The owner's eye in play (**P**) | **D, P** |
| **11** | **Carried:** the M2 examine event (an examine with no input posted, once, on a loaded machine) and M3's two breakage survivors ("the slab comes down again for each weight", "standing still makes footsteps") | A reproduction attempt for the first, closed or recorded as not reproduced; a test for each survivor, or a recorded reason none can catch it (**D**) | **D** |
| **12** | **Validation and handoff** | Full local gate and exported routes; CI on GCC, Clang and MSVC; focused breakage of what M6 adds; the review package; **one identified M6 candidate; automated results, human observations and outstanding checks kept apart;** a stop for the owner's review (**D**) | **D** |

## Schedule, 21 to 27 November

| Day | Developer | Depends on |
|---|---|---|
| 20–21 | The playtest kit and the baseline build; the listening kit; native-check sheets | — |
| 21–23 | Displays and fullscreen (6); frame times (8); the verification matrix (9); German labels in CI (5); the carried items (11); the visual review (10) | — |
| as soon as they can | — | **Two first-time players** (1), the owner's listening (3), the owner's machines (7) |
| 24–26 | Fixes from the playtests and the listening; timing options (2) for the owner's choice | The playtest recordings |
| 26–27 | The M6 candidate, its validation and the review package (12) | — |

## Schedule risks, flagged now

1. **The players' lead time decides M6** (R23). If both recordings are not in by about 25 November, there is no time to act on them before 27 November; the owner chooses then between a later M6 and a smaller gate.
2. **If first-time play is well under 10 minutes,** the options will cost content work that could reach M7's dates; they come to the owner first, with their cost.
3. **The hardware rows stay open** without the controllers and the owner's machines, and are recorded as open, not passed.
4. **The fullscreen and window-fitting work touches C++ settings,** the first C++ change since the Hud's in M5; it is small but has to be tested across both platforms in CI.
5. **M7 is 28 to 29 November and the jam closes 1 December, 21:37 UTC;** M6 slipping past 27 November takes from M7 and the buffer.

## What the owner provides

Two first-time players and their recordings; the listening, on headphones and speakers; the controllers when available; the Ubuntu ThinkPad and the Windows desktop for the native checks; decisions on the 720p presentation and on gameplay options. **`v0.2.0-alpha.1` is not published** without the owner's separate word.

## Not in M6

New acts, puzzles, enemies, or waits or walks to lengthen play (R11); art redesign; new story, except a beat the owner approves under item 2; anything labelled stable or 1.0. Stretch work only after M6 is green, and time-boxed.
