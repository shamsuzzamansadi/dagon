# M6 native checks: the owner's Ubuntu ThinkPad and Windows desktop

For the owner (M6 plan, item 7; the roadmap's exit gate: "release candidate artifacts from CI launched on real Windows and Linux"). **The runs are the owner's; the developer has neither machine and records nothing here as passed until the owner reports it.**

| Sheet | Machine |
|---|---|
| [linux-thinkpad.md](linux-thinkpad.md) | The owner's Ubuntu ThinkPad: the first native Linux run with hardware rendering |
| [windows-desktop.md](windows-desktop.md) | The owner's Windows desktop |

**Which build.** Each sheet can be run now on the playtest baseline (`a4250f0`, [kit](../playtest-kit/README.md)) for an early reading, and **must be run on the M6 candidate,** which the handoff will name with its artifact and SHA-256. Write the build's SHA-256 at the top of what you send.

**What comes back:** the filled sheet, and the game's own log from that run (each sheet says where it is). The log records the graphics device the game used and, with `--print-fps`, one frame-rate reading a second; nothing else is collected, and the log holds no personal data beyond the folder names in its paths.

**The displays** (plan item 6), at 1280 × 720 and 1920 × 1080, windowed and fullscreen, are in each sheet's last part. The fullscreen setting is being added in M6; on the baseline, skip what the game does not have yet and say so.

**Controllers** are not in these sheets: their results stay pending until someone tests the actual hardware (plan item 4), with a sheet of their own.
