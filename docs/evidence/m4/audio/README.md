# M4 audio polish (item 4): what changed, and what has only been measured

**Status: made and measured by the developer, who cannot hear. Nobody has listened to any of it yet.** Item 4 of [the plan](../../../m4-plan.md) ends with the owner's ear: the reveal's level and the mix are set from the owner's listening notes. Until then this is a measured first version of each change, not a mixed or approved one.

Every sound is synthesized by [`tools/audio/make_sounds.py`](../../../../tools/audio/make_sounds.py), as in M3 ([D74](../../../decisions.md)), with fixed seeds. Only the files below were made again (`--only`); every other sound is byte for byte as it was, and was measured as it stands.

## What changed

| Where | What plays now | Files |
|---|---|---|
| **Menus**: title, pause, prologue and ending cards, settings | A soft low knock on moving between choices, a fuller one on choosing, a falling pair on going back. Only the player's own moves are heard: the menu putting focus somewhere itself, on the way into a screen, is silent | `effects/ui_move.ogg`, `ui_accept.ogg`, `ui_back.ogg` |
| **Examining** anything with a line | A breath drawn in and a palm laid on stone, short and quiet, under the voice. Pushing or pressing something is heard only as the thing itself | `effects/examine.ogg` |
| **The Abyss as it deepens** | Three beds instead of one played three times: the open mud as before; further out, where the mud goes black, a lower, heavier wind, nearer groans and a slow swell beneath, as if the ground were lifted; then the canyon, enclosed, wind thin on the rim far above, stone ticking, water seeping with a long echo, which leads into the Monolith's drone | `ambience/abyss_deep.ogg` (on `Sound/AbyssMid`), `ambience/canyon.ogg` (on `Sound/AbyssFar`) |
| **The rock coming down** | A deep blow first, then the crack and scatter, then the wall settling in a rumble. Its first version had almost no low end | `effects/rock_fall_1` to `3.ogg` |
| **The sea following him** | The churn as before, with a deep, slow heave under it, each surge pressing on | `ambience/tide_roar.ogg` |
| **The sea closing over him** | It rises, then lands: a deep blow at the top, the water heavier | `effects/sea_rush.ogg` |

## Measured

From `make_sounds.py`'s own report ([measurements.txt](measurements.txt)), on the files as written. **Measurement only:** a level says how loud a file is, not whether it sounds right or sits right in the mix.

| File | Length | Peak | RMS | Loop seam |
|---|---|---|---|---|
| `ambience/abyss_deep.ogg` | 31.0 s | −14.4 dBFS | −28.0 dB | 1.84, under the 3.0 limit |
| `ambience/canyon.ogg` | 24.0 s | −18.3 dBFS | −30.0 dB | 0.41 |
| `effects/ui_move.ogg` | 0.07 s | −24.1 dBFS | −36.2 dB | |
| `effects/ui_accept.ogg` | 0.32 s | −16.0 dBFS | −28.5 dB | |
| `effects/ui_back.ogg` | 0.22 s | −19.7 dBFS | −32.0 dB | |
| `effects/examine.ogg` | 0.45 s | −22.2 dBFS | −38.1 dB | |
| `effects/rock_fall_1` to `3.ogg` | 2.6 s | −3.9 to −4.0 dBFS | −17.8 to −19.5 dB | |
| `ambience/tide_roar.ogg` | 12.0 s | −6.6 dBFS | −20.0 dB | 0.18 |
| `effects/sea_rush.ogg` | 4.5 s | −3.0 dBFS | −18.9 dB | |

All 46 files: `SOUNDS files=46 problems=0` (nothing near clipping, no loop seam, no DC offset). The slow swell and heave are timed to divide their loops exactly, so neither jumps at the seam. The Master bus's limiter at −1 dB ([D91](../../../decisions.md)) is unchanged.

**Still to come, and not done:** the game's real mix with these in it, measured from a recording of play (`listening.py check`), and the listening package cut from that recording (`listening.py excerpts`) for the owner. One recording is made after item 5, as new voice lines change the mix too.

## Tested

- `test_pause_menu.gd`: moving, choosing and going back are each heard; the menu's own focus on opening, on Settings and on the way back is not.
- `test_narrative.gd`: examining the mural is heard; pressing a stone is not heard as examining.
- `test_revision.gd`: the Abyss's three beds are the open mud, the deeper mud and the canyon, in the order he walks them.

The tests check which sound starts, with each stream swapped for long silence. They cannot hear anything either.
