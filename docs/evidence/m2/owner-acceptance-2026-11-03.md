# Owner acceptance of M2, 2026-11-03

**Stated by the owner, in their message on 2026-11-03:**

> I have manually tested the current build and it looks correct to me. I accept M2 for merge based on my manual testing, the
> completed review and the required automated checks.

**What this establishes:** the owner accepts M2 for merge, and the build they tested looked correct to them.

**What it does not establish:**

- Which checks they ran. The message does not list them, so **no individual step or Xbox row of the [manual check](../../reviews/m2-review-package.md) is recorded as passed.**
- Anything about PlayStation hardware, which nobody has tried.
- Anything about Xbox or PlayStation console platforms, which are not targets.
- Anything about audio, because this build has none. M2 delivers volume controls and buses prepared.

## Which build

**The message says "the current build", and names no run or commit.** This record does not infer one from screenshots or from appearance. These are the facts that could be checked on the machine:

| Fact | Detail |
|---|---|
| The download | `dagon-windows.zip`, written at 18:39 CET, SHA-256 `cbfca7c95e25852e5c7a45438806751a0e8df637d093bd7f1e34253d0fa2a434`. That equals GitHub's digest for `dagon-windows` from CI run [41682543058](https://github.com/shamsuzzamansadi/dagon/actions/runs/41682543058), commit `3426d3b` |
| The extracted copy | `dagon.exe`, `dagon.pck` and the `.dll`, written at 18:40, are byte-identical to that artifact |
| The game's real data folder | Logs of sessions starting between 18:41 and 18:43, and a save written at 18:43. The developer's scripted runs used isolated folders, so these are not theirs. The logs do not name a build |

**This is consistent with the owner having tested `3426d3b`. It identifies the download, and shows that a build ran. It does not prove which copy was launched.**

## The review, at the time of acceptance

ChatGPT reviewed the round 1 fixes at `d78f5a6`, and the Examine wiring, exported-pack coverage, menu, session and save paths and controller labels at `79981ea`, where it also ran the native tests and the art check. It did not rerun the Godot integration tests or Windows gameplay. **It has not reviewed `3426d3b`,** which adds the Settings note and stronger tests. The owner decided not to wait for another approval round.

## Carried to M6, and not passed

- **All physical PlayStation hardware.**
- **Physical Xbox actions not individually reported,** including disconnecting and reconnecting (X17, X18 in the manual check). The owner's earlier [Xbox feedback](xbox-feedback-2026-11-03.md) has the same limit.
- **Key names under German on the real build,** left unverified at the owner's request to keep layout changes off their active desktop.
- **Native Linux hardware-accelerated rendering.** The Linux runs used software rendering.

**One open observation:** an examine that fired once by itself in a scripted run, and did not reproduce ([record](review-round-2/README.md)). It is not known to be a defect. If a caption ever appears with no key pressed, that is a bug report.
