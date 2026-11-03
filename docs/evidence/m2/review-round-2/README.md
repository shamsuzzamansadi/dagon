# Evidence: the end of M2 review round 2

Everything here is the developer's. **None of it is a physical keyboard or controller test,** and none of it has been reviewed. The review package, §11, is the summary. The owner's manual testing is separate: see their [acceptance](../owner-acceptance-2026-11-03.md).

| File | What it is | Commit |
|---|---|---|
| [breakage-at-3426d3b.txt](breakage-at-3426d3b.txt) | **57 deliberate breakages, all 57 caught,** with controls before and after | `3426d3b` |
| [breakage-at-8da9a2e.txt](breakage-at-8da9a2e.txt) | The earlier run: 43, with 3 not caught. It begins with a note on how my tooling disturbed it. Superseded | `8da9a2e` |
| [fresh-clone-at-3426d3b.txt](fresh-clone-at-3426d3b.txt) | A fresh clone from GitHub, following the README, with the suite repeated **10 of 10 clean** | `3426d3b` |
| [fresh-clone-at-79981ea-incomplete.txt](fresh-clone-at-79981ea-incomplete.txt) | **Incomplete:** stopped after repeat 5 of 10. Superseded | `79981ea` |
| [windows-run-summary.txt](windows-run-summary.txt) | Text output of four scripted runs of the final Windows build, and a focused test of the old key | `3426d3b` |
| [windows/](windows/) | Screenshots of run 2, all viewed. Real GPU, real window size | `3426d3b` |
| [windows/first-run-unexplained/](windows/first-run-unexplained/) | The two frames discussed below | `3426d3b` |
| [driver/](driver/) | The scripts. `E2E.cs` has no call that can change a keyboard layout | |

## One unexplained event

**What happened.** In the first scripted run of the final build, [shot 14](windows/first-run-unexplained/14-prompt-names-J-no-caption.png) shows the boat's caption fading in, with no prompt, and [shot 15](windows/first-run-unexplained/15-old-key-E-does-nothing.png) shows it bright. The steps before them rebind Interact to J, wait six seconds and press nothing. The run's exit status was clean, and I found this by looking at the frames.

**What it means.** An examine fired once, just before shot 14. A prompt disappears only during the 0.4 s after an examine, and the log has one extra prompt line: `J=6` where a clean run has 5. It came before the script pressed E, so it does not show the old key working.

**What was checked.**

| Check | Result |
|---|---|
| Does the old key examine? A focused test: frames each second, then E twice, then J | **No.** E did nothing both times, and J examined |
| Three more full runs, one idle and two with 9 busy threads, the first run's approximate load | **All correct,** with `J=5`, and the driver reported no physical input during each |
| Could the game do this by itself? | I found no such path: `Interactor` acts only on the `interact` input, which was bound to J alone, with no controller connected |

**What is not known.** The cause is not established, and it did not reproduce. The first run did not yet record physical input, and the game's window had focus on the owner's desktop, so a real J key is possible. I cannot show that it happened. The driver now reports whether any physical input reached the machine during a run, though not what it was. §8 asks the owner to stand beside the boat for a few seconds and confirm that nothing appears by itself. Their acceptance does not list that step, so it is not recorded as checked.

**Also on that run:** its other screenshots were correct, but because of this it is not the one presented as the record.

## Keyboard layout

No layout request was sent by anything in this folder. The focused window's layout read `04090409` before and after every full run. German's key names stay unverified on the real build after the fix, as a stated limit, because the owner asked to keep layout changes out of testing on their active desktop.
