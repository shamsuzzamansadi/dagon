# Evidence: M2

Software rendering (`llvmpipe`, from the run's own log) throughout. Nothing here has been seen on a real GPU or the
owner's display. Scripted input, so none of this shows physical keyboards or controllers working.

| File | What it is | How it was made |
|---|---|---|
| `startup-release-build-3x.png` | The standard build's startup, with the prompt beside the boat | Linux release export, `--write-movie`, no input. Its log shows `Completed load for: 'res://scenes/level/shore.tscn'` |
| `prompt-3x.png`, `caption-3x.png` | Examining the boat | `tests/capture_m2.gd` |
| `pause-menu-3x.png`, `settings-3x.png`, `reserved-key-3x.png`, `conflict-3x.png`, `quit-confirmation-3x.png` | Each menu screen | Same capture |
| `mutation/` | Deliberate breakage, and what caught it | See its README |
| `review-round-1/` | The regression tests failing on the unfixed code, and breakage of each fix | See the review package, §10 |

The screens were captured at `24882e3`. Only the three showing the Settings note changed from the earlier capture; the others came
out byte-identical. The startup screenshot is from `c1f1ca6`, and nothing it shows has changed since.
