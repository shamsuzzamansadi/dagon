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
| `shore.talisman` | M3 | 9.8 s | 13.7 chars/s | the audition's | Word for word |
| `cave.carving` | M3 | 12.2 s | 12.5 chars/s | the audition's | Word for word |
| `ending.found` | M3 | 15.3 s | 12.7 chars/s | seed 9 | Word for word |
| `ending.listen` | M3 | 5.6 s | 14.3 chars/s | seed 7 | Word for word |
| `ending.innsmouth` | M3 | 16.1 s | 13.8 chars/s | the audition's | Word for word except the name, heard as "Insemouth": the exception recorded in M3, **for the owner's ear** |
| `ending.rising` | M3 | 8.0 s | 15.2 chars/s | seed 7 | Word for word |

Every file is at −24.0 dB RMS, with peaks between −2.9 and −5.9 dBFS. The full transcripts, with the time each word is said, are in [transcripts.txt](transcripts.txt), made by `python tools/audio/check_narration.py --words`.

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

## Still captions

Everything else in `project/narration/script.txt`. The M4 plan speaks the Shore's first lines next, then, as the schedule allows, the story lines. What is left at the end of M4 is listed in the handoff and the review package, for M5.
