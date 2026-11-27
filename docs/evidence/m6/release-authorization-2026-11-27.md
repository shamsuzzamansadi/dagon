# The owner's acceptance of the M6 candidate, and authorization of `v0.2.0-alpha.2`, 2026-11-27

The owner approved the version and its target on 2026-11-22 and kept the record a candidate until their native results ([approval](release-approval-2026-11-22.md)). This records their word on publishing, limited to what the owner said.

## What the owner said

**First, on 2026-11-27,** a message whose results were still a template's placeholders:

> Windows desktop — [save and Continue result; what the monitor showed during the fullscreen switch].
> Ubuntu ThinkPad — [save and Continue result; “Using Device” line].

The developer published nothing on it, recorded no result from it, and asked for the observations in the owner's own words.

**Then, the same day:**

> accept the M6 candidate from b271316 and authorize publication of v0.2.0-alpha.2 from source build run 45038841566. I tested the Windows candidate extensively and found no issues. Record the Windows display switches, post-ending Continue, and same-session Shore Continue shown in my recordings. Keep the Ubuntu native run and any other unverified checks listed as untested. Proceed with PR #11 after its required checks pass, then verify the tag target and all three published package hashes.

## What this establishes

- **The owner accepts the M6 candidate from `b271316`,** fingerprint `sha256:96c145f475ab1b890f9f4363d96e0a028c5bf3c8cb6111f8f97174561ee8135b`, and **authorizes publishing `v0.2.0-alpha.2`** from its source build run 45038841566, tagged on `b271316`.
- **The build the owner tested:** the candidate's Windows package, `dagon-v0.2.0-alpha.2-windows-x86_64.zip`, SHA-256 `f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148`, from artifact 14761047666 of run 45038841566 ([candidate](candidate-v0.2.0-alpha.2.md)).
- **The owner's statements about it, on their Windows desktop:** they tested it extensively and found no issues; their recordings show **the display switches, Continue after the ending, and Continue at the Shore within one session.**

## What this does not establish

- **The recordings themselves, by anyone else.** The developer has not seen them; the three results above are the owner's statements about them.
- **The native run on the owner's Ubuntu laptop,** its display switch, and its graphics device: no result was given. It stays untested, as the owner asked.
- **Frame times on either of the owner's machines,** and which graphics device the Windows run used: none were reported.
- **Continue after quitting to the desktop and starting the game again, by a person:** the owner named Continue within one session. CI's smoke test of each package does it, headless.
- **Every other check still open:** two first-time players and the length of a first playthrough; the reveal's dialogue by ear; physical controllers; any play of the Mac build by a person.
