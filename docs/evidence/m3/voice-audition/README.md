# The replacement voice audition

**Status: the owner chose candidate A on 2026-11-10** ([D94](../../../decisions.md)), from the [listening package](../listening/README.md)'s matched samples. A now speaks six lines in the game: the talisman, the carving and all four lines of the epilogue. **The choice is of a voice. Whether the finished narration and the mix work is the owner's to judge by ear;** the developer cannot hear. The earlier voice, Kokoro's `am_michael`, was rejected by the owner as noticeably synthetic, and its samples are [kept for the record](../narration/rejected-am_michael/), out of the game.

## The epilogue in voice A

Made with `python tools/audio/make_audition.py --models DIR --speak A ending.found ending.listen ending.rising`, trimmed and levelled like the rest, and checked by transcribing each with a local speech recogniser (Whisper `small.en`) against the script:

| Line | Length | Pace | Take | Transcript against the script |
|---|---|---|---|---|
| `ending.found` | 15.3 s | 12.7 chars/s | seed 9 | Word for word. Seed 7 was heard as "a steamer **foul** me", seed 8 as "adrift **in** raving"; both discarded |
| `ending.listen` | 5.6 s | 14.3 chars/s | seed 7 | Word for word |
| `ending.innsmouth` | 16.0 s | 12.5 chars/s | the audition's | Word for word except the name, heard as "Insemouth": a recogniser's guess at a rare name, or the voice. **For the owner's ear** |
| `ending.rising` | 8.0 s | 15.2 chars/s | seed 7 | Word for word |

All six lines sit between −23.7 and −24.2 LUFS. A transcript says which words a machine hears; it does not say whether the voice sounds right.

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
