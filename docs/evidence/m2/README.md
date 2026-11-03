# Evidence: M2

Software rendering (`llvmpipe`, from the run's own log) throughout. Nothing here has been seen on a real GPU or the
owner's display. Scripted input, so none of this shows physical keyboards or controllers working.

| File | What it is | How it was made |
|---|---|---|
| `startup-release-build-3x.png` | The standard build's startup, at `c1f1ca6`. **It shows no prompt. See the correction below.** | Linux release export, `--write-movie`, no input. Its log shows `Completed load for: 'res://scenes/level/shore.tscn'` |
| `prompt-3x.png`, `caption-3x.png` | Examining the boat | `tests/capture_m2.gd` |
| `pause-menu-3x.png`, `settings-3x.png`, `reserved-key-3x.png`, `conflict-3x.png`, `quit-confirmation-3x.png` | Each menu screen | Same capture |
| `mutation/` | Deliberate breakage, and what caught it | See its README |
| `review-round-1/` | The regression tests failing on the unfixed code, and breakage of each fix | See the review package, §10 |
| `examine/` | Why Examine did nothing in exported builds, its reproduction, and the same steps after the fix on the real Windows build | See [its README](examine/README.md) |
| `controller/` | The screens for each controller layout, with a named controller and injected events. **Not physical-device images** | `tests/capture_controller.gd` |
| `xbox-feedback-2026-11-03.md` | The owner's physical Xbox feedback, limited to what they exercised | [Record](xbox-feedback-2026-11-03.md) |
| `review-round-2/` | Deliberate breakage of this round's work | See the review package, §11 |

The screens were captured at `24882e3`. Only the three showing the Settings note changed from the earlier capture; the others came
out byte-identical. The startup screenshot is from `c1f1ca6`, and nothing it shows has changed since.

## Correction, 2026-11-03

An earlier version of this table described `startup-release-build-3x.png` as "with the prompt beside the boat". **That was false.** The image shows
no prompt, and I wrote the caption without looking at it. Had I looked, it would have shown the Examine defect before the owner
found it. The image stays as it was, as a record of the defect. The other captures in this table came from `tests/capture_m2.gd`
running from source, where the prompt did work, which is why they showed it.
