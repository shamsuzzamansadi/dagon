# Owner's Linux playtest

**Source:** `Screen Recording 2026-11-02 134057.mp4`, supplied by the project owner to ChatGPT. It is not
committed to the repository. The developer (Claude) has not seen it, so nothing here is measured from it.

## Established

| Item | Basis |
|---|---|
| A human ran the Linux executable | The owner's report |
| A, D, Left Arrow, Right Arrow and Space worked correctly | The owner's confirmation |
| The executable running, and traversal through the illustrated Shore and the greybox | ChatGPT's inspection of sampled frames |
| Environment: WSL Ubuntu 24.04 | Visible in the recording |
| Renderer: Mesa llvmpipe (LLVM 20.1.2, 256 bits) | The run's renderer log |
| A V-Sync warning | Observed, and recorded without drawing a conclusion from it |

**This is a human Linux run with software rendering.** It is not native Linux GPU validation.

## Not established

- **Which build.** The exact artifact and commit are unconfirmed, and are not inferred from timestamps or
  appearance. The owner accepts this limitation for M1. Later milestone playtests identify the exact artifact or run.
- **Physical gamepad.** Untested. Deferred to M6, before release.
- **Native Linux hardware-accelerated rendering.** Not validated. Deferred to M6, before release.
- **Measurements.** No speed, jump height or camera jitter was measured from this session.

## Effect on M1

The owner accepted M1 with documented deferrals ([the review package, §16](../../reviews/m1-review-package.md)). That
does not mean every manual check passed.
