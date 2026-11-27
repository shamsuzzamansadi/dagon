# Measuring a playtest (the developer; not for players)

From each player's recording, frame by frame where it matters, with times taken from the recording's own clock. **Every figure says whether it was measured from the recording or is the player's own word.** The player is "player 1" or "player 2", with no names. **The developer cannot hear the recordings:** what the player said aloud, and anything about sound, comes from the player's answers, from captions on screen, or from the owner. Results go into [results.md](results.md).

## Actual playtime: three moments, two times

| Moment | How it is found in the recording |
|---|---|
| **New Game** | The frame where the How to Play screen first shows, after New Game is chosen |
| **The first ending card** | The frame where the ending's card, with the epilogue's first picture, first shows after the collapse (the game logs it as "ending card shown") |
| **The return to the menu** | The frame where the main menu first shows again, after the player has chosen Continue on the ending's card and Main Menu from the credits |

**Time to the first ending card** = first ending card − New Game. **Time to the menu** = return to the menu − New Game. It includes however long the player stays on the ending's card and the credits, which is also reported on its own. Both times are reported separately, and both against the 10 to 15 minute aim (GDD §4, R11). The prologue, which the player may watch or skip, is inside both, and its own length is reported beside them. **Pauses count:** the time with the pause menu open is reported on its own, and also subtracted, to give a second figure for each.

**For comparison, the scripted route on `b271316`'s exported game.** `tools/route_check.py` knows the puzzle, and is timed from the end of the prologue, so it leaves out How to Play and the prologue. It is not a playtest.

| Where | Reading everything | Straight through |
|---|---|---|
| Windows, CI run [45038841566](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566) (artifact `logs-windows`) | 3 min 52 s to the first ending card, 4 min 41 s to the menu; prologue 33 s | 1 min 56 s and 1 min 59 s; prologue skipped |
| Linux, the published package, on a private display, 2026-11-27 ([results.md](results.md)) | 3 min 53 s and 4 min 44 s; prologue 34 s | 2 min 2 s and 2 min 6 s; prologue skipped |

## Also from the recording

- **By act:** the Shore, the cave, the Abyss, the Monolith and its stones, the reveal and the escape, the collapse, the epilogue and the credits, with the duration of each.
- **Pauses:** each time the pause menu is open, when and for how long.
- **Retries:** each fall out of the world, checkpoint restart or capture by the sea, with where and when.
- **Hesitations:** any stretch of 10 s or more with the sailor still, or going back over ground already covered, outside cinematics and spoken lines. Where it was, and what the player did next, judged from the picture and the player's own words.
- **Where they needed help:** each time the player asked for help or was given any, with when, where and what. The sources are the recording's captions and picture, the player's answer to question 2, and the owner's note of any help they gave. Each entry says which source it comes from. Also noted: any place the player looked stuck for a minute or more without asking.
- **Skipped lines:** each spoken line cut short, and which.

## A progression blocker

**A progression blocker** is anything that stopped the player going on through the game without outside help or starting again: the game stuck or crashed, a place the sailor could not get past or out of, a puzzle state that could not be finished, or the player giving up. A blocker is brought to the owner straight away, as the owner asked on 2026-11-27, with:

1. **The specific finding:** the time in the recording, what the player did, what the game did, and whether it reproduces on the same build (`v0.2.0-alpha.2`).
2. **The smallest proposed fix:** what changes, its test, and its cost in time against the 29 November target.

A fix becomes `v0.2.0-alpha.3` only with the owner's acceptance of that build and their explicit approval to publish it. Without both, `v0.2.0-alpha.2` stays the submission build.

**Not a blocker, recorded for after the jam:** confusion that the player got past on their own, slowness, a missed clue, a wish. Each of these is recorded with its time and place.

## If a run falls outside 10 to 15 minutes

Say what happened in that run, from the measurements above: where the time went, or where it was saved (a skipped prologue, skipped lines, knowing what to do). The game is not padded for length (AGENTS.md). Anything that would change it goes to the owner as a finding for after the jam, unless the owner asks otherwise.

## The answers

Keep the player's five answers in their own words, and set them against the recording where possible: where they said they were unsure, against where they hesitated; lines they missed, against the lines skipped or played.
