# Playtest results, `v0.2.0-alpha.2`

Filled in by the developer as recordings arrive, by the method in [measurement.md](measurement.md). Each figure is marked **measured** (from the recording's own clock) or **the player's word.** Deadline for the players: **2026-11-29 12:00 UTC.**

## Status

| | Player 1 | Player 2 |
|---|---|---|
| Kit sent | Not yet recorded | Not yet recorded |
| Recording received | No | No |
| Answers received | No | No |
| Measured | No | No |

## The scripted route on the published package (not a playtest)

On 2026-11-27, the developer ran `tools/route_check.py` on the published `dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz`, downloaded from the release and checked against its SHA-256. It ran on a private display at 1440 × 810, with Mesa's software renderer and window-system keys: **`runs=4 failed=0`.** The four runs were New Game reading everything, New Game straight through, Continue while waiting for the sea, and Continue after the ending. The driver knows the puzzle and makes one deliberate mistake. It times from the end of the prologue, so How to Play and the prologue are left out.

| Profile | Prologue | To the first ending card | To the menu | By act |
|---|---|---|---|---|
| Reading everything | 34 s, played | **3 min 53 s** | 4 min 44 s | Shore 47 s, Abyss 1 min 59 s, Monolith 36 s, witness and escape 25 s, collapse 6 s, epilogue and credits 51 s |
| Straight through | skipped | **2 min 2 s** | 2 min 6 s | Shore 12 s, Abyss 52 s, Monolith 27 s, witness and escape 25 s, collapse 6 s, epilogue and credits 4 s |

These are close to the Windows CI figures on `b271316` (3 min 52 s and 1 min 56 s; measurement.md). A first-time player's time is what the playtests measure.

## Player 1

Waiting for the recording.

| | Measured from the recording |
|---|---|
| System, input, headphones or speakers, window or full screen | |
| Prologue | |
| **Time to the first ending card** | |
| **Time to the menu** | |
| Paused, in all | |
| By act | |
| Retries | |
| Hesitations | |

**Where they needed help:**

| When | Where in the game | What | Source |
|---|---|---|---|

**Progression blocker:** not yet known.

**Their answers,** in their own words: —

## Player 2

Waiting for the recording. Same layout as player 1.

## Findings

None yet. Any blocker goes to the owner at once, with the specific finding and the smallest proposed fix (measurement.md). Everything else is recorded here for after the jam.
