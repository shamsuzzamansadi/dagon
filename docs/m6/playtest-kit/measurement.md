# Measuring a playtest (the developer; not for players)

From each player's recording, frame by frame where it matters, with times from the recording's own clock. **Every figure says whether it is measured from the recording or is the player's word.** The player is "player 1" or "player 2"; no names.

## The three moments, and the two times

| Moment | How it is found in the recording |
|---|---|
| **New Game** | The frame the How to Play screen first shows, after New Game is chosen |
| **The first ending card** | The frame the ending's card, with the epilogue's first picture, first shows after the collapse (the game logs it as "ending card shown") |
| **The return to the menu** | The frame the main menu first shows again, after the player has chosen Continue on the ending's card and Main Menu from the credits |

**Time to the first ending card** = first ending card − New Game. **Time to the menu** = return to the menu − New Game; it includes however long the player stays on the ending's card and the credits, which is reported on its own too. Both are reported, separately, and both against the 10 to 15 minute target (GDD §4, R11). The prologue, which the player may watch or skip, is within both, and its own length is reported beside them.

For comparison, the scripted route on the baseline's own Linux build, which knows the puzzle (`tools/route_check.py`, timed from the end of the prologue, so without How to Play and the prologue): **reading everything, 4 min 3 s to the first ending card and 4 min 56 s to the menu, with a 36 s prologue before it; straight through, 2 min 7 s and 2 min 11 s, the prologue skipped.** Scripted, not a playtest.

## Also from the recording

- **By act:** the Shore, the cave, the Abyss, the Monolith and its stones, the reveal and the escape, the collapse, the epilogue and the credits, each's duration.
- **Pauses:** each time the pause menu is open, its time and length.
- **Retries:** each fall out of the world, checkpoint restart or caught-by-the-sea, with where and when.
- **Hesitations:** any stretch of 10 s or more with the sailor still, or going back over ground already covered, outside cinematics and spoken lines; where it was, and what the player did next, from the picture and what they said.
- **Help:** whether the player asked for help or was given any, when, and what, from the recording and the player's word.
- **Skipped lines:** each spoken line cut short, and which.
- **What the player said aloud,** where it bears on the above, quoted with its time.

## If a run falls outside 10 to 15 minutes

Say what happened in that run, from the measurements above: where the time went, or where it was saved (a skipped prologue, skipped lines, knowing what to do). **Then options and their cost for the owner, before any gameplay is added** (M6 plan, item 2).

## The answers

The player's five answers, kept in their own words, and set against the recording where they can be: where they said they were unsure, against where they hesitated; lines they missed, against the lines skipped or played.
