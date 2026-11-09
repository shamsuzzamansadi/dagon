# The replacement voice audition

**Status: for the owner's listening decision. No voice is approved.** The earlier voice, Kokoro's `am_michael`, was rejected by the owner as noticeably synthetic, and its samples are [kept for the record](../narration/rejected-am_michael/), out of the game. **The developer cannot hear, so neither candidate has been listened to by anyone on the project.** Measurements only.

Three lines, as asked: the Shore, the cave and the ending. Their words come from `project/narration/script.txt`, so they match the captions exactly.

| Line | Stands for |
|---|---|
| `shore.talisman` | A Shore observation |
| `cave.carving` | A cave and clue observation |
| `ending.innsmouth` | The ending |

## The candidates

| | A | B |
|---|---|---|
| **Performance by** | Chatterbox, Resemble AI, MIT licence | Chatterbox |
| **Speaking in the timbre of** | Kokoro-82M stock voice `am_onyx`: lower, American | Kokoro-82M stock voice `bm_george`: older, British |
| **Settings** | Restrained: exaggeration 0.3, guidance 0.25 | Exaggeration 0.35, guidance 0.35 |
| **Pace** | 12.5 to 13.8 characters a second | 11.4 to 14.3 characters a second |
| **In the game** | **Yes,** under its captions | No. The files are here: [B/](B/) |

Both are set to -24 dB RMS, with peaks between -3 and -9 dBFS. The first pass at A spoke at about 16 characters a second, too brisk for a tired man, and was regenerated slower. All of it is reproducible with `tools/audio/make_audition.py`.

## Source and rights

- **Chatterbox** is MIT-licensed, run locally on this machine's processor. Nothing was bought.
- **The timbre** comes from Kokoro-82M's stock voices (Apache-2.0), themselves synthetic. **No real person's voice was cloned or imitated.** Chatterbox only takes a timbre from what it is given, and it was given Kokoro, never a recording of a person.
- **Watermark:** Chatterbox marks everything it makes with Resemble AI's imperceptible Perth watermark. It was left in place. That is how the tool is meant to be used, and it is a disclosure in itself.
- **Disclosure:** AI-generated voice, recorded in `CREDITS.md` and [jam.md](../../../jam.md) §5. Declare it on the submission form.
- **What I cannot settle:** Kokoro's training data includes, by its own account, synthetic audio from closed providers' models. Chatterbox's model card does not list its training data. The owner should weigh both before choosing either.

## A third choice: a person

The one way to be sure the narrator does not sound synthetic. `python tools/audio/import_recordings.py --sheet` prints every line to read. Recordings named by line ID, as `shore.talisman.wav` and so on, go in a folder, and `python tools/audio/import_recordings.py FOLDER` trims and levels them and puts them in the game. The reader's permission and credit go in `CREDITS.md` first. Nothing else changes, as the game plays whatever is there under the same captions.

## What I need from the owner

1. Listen to A in the game: the talisman on the Shore, the carving in the cave, and the epilogue's third line. Then B's files.
2. **Natural? Clear? The right feeling: tired, uneasy, close?**
3. **A, B, a person, or neither?** Once a direction is chosen, the whole epilogue is narrated, all four lines, and then the rest of the script.
