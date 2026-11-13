# Narration in voice A, during M4

**Voice A is the owner's choice of 2026-11-10** ([D94](../../../decisions.md)): Chatterbox performing in the timbre of Kokoro's stock voice `am_onyx`, with the settings of the [audition](../../m3/voice-audition/README.md), unchanged. Its source, rights, watermark and disclosure are recorded there and in `CREDITS.md`.

**The developer cannot hear.** Everything here is a measurement or a machine's transcript. A transcript says which words a recogniser hears. It does not say whether a line sounds right, natural or well paced: **that is for the owner's ear.**

## Which lines are spoken

This table is the list. A line not in it is a caption only. The integration suite holds the game to the same list (`VOICED` in `project/tests/test_narration.gd`): a recording that is not named there fails it, and so does a named line with no recording.

| Line | Since | Length | Pace | Take | Transcript against the script |
|---|---|---|---|---|---|
| `prologue.raider` | M4 | 7.4 s | 14.5 chars/s | seed 9 | Word for word |
| `prologue.escape` | M4 | 7.9 s | 15.1 chars/s | seed 8 | Word for word; "rowed" heard as "rode", which sound the same |
| `prologue.drift` | M4 | 8.0 s | 13.2 chars/s | seed 10 | Word for word |
| `prologue.dry` | M4 | 3.7 s | 12.7 chars/s | seed 7 | Word for word |
| `shore.boat` | M4 | 5.8 s | 12.7 chars/s | seed 7 | Word for word |
| `shore.fish` | M4 | 5.5 s | 14.3 chars/s | seed 7 | Word for word |
| `shore.talisman` | M3 | 9.8 s | 13.7 chars/s | the audition's | Word for word |
| `cave.carving` | M3 | 12.2 s | 12.5 chars/s | the audition's | Word for word |
| `ending.found` | M3 | 15.3 s | 12.7 chars/s | seed 9 | Word for word |
| `ending.listen` | M3 | 5.6 s | 14.3 chars/s | seed 7 | Word for word |
| `ending.innsmouth` | M3 | 16.1 s | 13.8 chars/s | the audition's | Word for word except the name, heard as "Insemouth": the exception recorded in M3, **for the owner's ear** |
| `ending.rising` | M3 | 8.0 s | 15.2 chars/s | seed 7 | Word for word |
| `abyss.ritual` | M4 | 5.4 s | 12.9 chars/s | seed 7 | Word for word |
| `abyss.crossing` | M4 | 5.9 s | 14.7 chars/s | seed 7 | Word for word |
| `abyss.watcher` | M4 | 5.5 s | 12.3 chars/s | seed 8 | Word for word |
| `monolith.first` | M4 | 6.5 s | 13.3 chars/s | seed 8 | Word for word |
| `story.awakened` | M4 | 4.7 s | 14.2 chars/s | seed 9 | Word for word |
| `story.reveal` | M4 | 3.6 s | 14.6 chars/s | seed 8 | Word for word |
| `story.recoil` | M4 | 3.8 s | 12.8 chars/s | seed 7 | Word for word |
| `story.run` | M4 | 2.0 s | 11.5 chars/s | seed 8 | Word for word |
| `flee.back` | M4 | 2.2 s | 11.4 chars/s | seed 9 | Word for word; the trailing "Don't..." is heard as "Don't." |
| `flee.sea` | M4 | 2.5 s | 13.1 chars/s | seed 9 | Word for word |

Twenty-two lines: every story line in the script, and the four optional lines above. Every file is at −24.0 dB RMS, with peaks between −2.0 and −8.1 dBFS. The full transcripts, with the time each word is said, are in [transcripts.txt](transcripts.txt), made by `python tools/audio/check_narration.py --words`.

## How the prologue's takes were chosen

The four lines were first spoken with the default seed, 7. All four were heard word for word, but two were brisk for this voice, whose settings aim at 11 to 14 characters a second: the raider line at 15.4 and the escape line at 16.3. Three more takes of the first three lines were made, with seeds 8, 9 and 10, into a folder outside the game (`make_audition.py --into`), and each was transcribed. **For each line, the slowest take that was heard word for word was kept.** Nothing about the voice was changed.

| Line | Seed 7 | Seed 8 | Seed 9 | Seed 10 | Kept |
|---|---|---|---|---|---|
| `prologue.raider` | 15.4 | 17.4 | **14.5** | 14.6 | 9 |
| `prologue.escape` | 16.3 | **15.1** | 15.8 | 15.9 | 8 |
| `prologue.drift` | 14.3 | 13.5 | 14.1 | **13.2** | 10 |
| `prologue.dry` | **12.7** | | | | 7 |

Characters a second. All thirteen takes were heard word for word, "rowed" as "rode" in each take of the escape line.

**For the owner's ear:** the escape line is still the quickest of the four, at 15.1, about the pace of the epilogue's last line (15.2). If it sounds hurried, more takes are cheap.

## The Shore's first lines

The boat and the fish, the first two things he can look at. Three takes of each, seeds 7, 8 and 9, all six heard word for word. The slowest of each was kept, both seed 7: the boat at 12.7 characters a second (13.9 and 12.7 for the others), the fish at 14.3 (14.5 and 14.6).

## The story lines (item 5)

Every line the game says by itself, rather than because he examined something: the ritual and the watcher, the crossing, the first sight of the Monolith, the stones answering, the reveal's three lines and the flight's two ([D102](../../../decisions.md)). Three takes of each, seeds 7, 8 and 9, thirty in all, each transcribed. Twenty-nine were heard word for word; seed 9 of the crossing was heard with "the" for "a", and was not used.

**Which take was kept:** of those heard word for word, the slowest within this voice's 11 to 14 characters a second, or, where none was, the one nearest it; and each must be heard out before the next line of its clip.

| Line | Seed 7 | Seed 8 | Seed 9 | Kept |
|---|---|---|---|---|
| `abyss.ritual` | **12.9** | 13.5 | 14.2 | 7 |
| `abyss.crossing` | **14.7** | 15.0 | 16.7, a word wrong | 7 |
| `abyss.watcher` | 12.9 | **12.3** | 12.4 | 8 |
| `monolith.first` | 16.0 | **13.3** | 13.9 | 8 |
| `story.awakened` | 15.3 | 14.3 | **14.2** | 9 |
| `story.reveal` | 15.6 | **14.6** | 14.8 | 8 |
| `story.recoil` | **12.8** | 13.0 | 13.7 | 7 |
| `story.run` | 10.2 | **11.5** | 10.7 | 8 |
| `flee.back` | 12.9 | 8.7 | **11.4** | 9 |
| `flee.sea` | 9.7 | 10.6 | **13.1** | 9 |

Characters a second. **For the owner's ear:** three are quicker than the range (the crossing, the stones answering, the reveal's first line), none of their takes slower; and the two flight lines are short and broken by design. More takes are cheap.

**The reveal's lines are spaced so each is heard out.** A story line replaces whatever is being said, and in the reveal "The carving. The same arm, round the same stone." came 2.6 s before "Its head turned. I ran.": too soon for its voice, and too soon even to read it. The reveal line now comes at 4.3 s instead of 4.6, still after the creature has risen, and the recognition at 8.2 s instead of 9.6, a second after the arm lands on the stone and while he is still reeling; the run line is where it was, with the head turning. Each has about four seconds. `test_narration.gd` now holds every clip to this: a voiced line must end, with 0.2 s to spare, before the next line of its clip.

## Still captions

What he examines, past the boat, the fish and the talisman, and the carving in the cave: the plan keeps those as text unless the owner asks.
