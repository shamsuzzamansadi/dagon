# Handoff: current state

Changing task state only. The lasting rules are in [AGENTS.md](../AGENTS.md). **Check this against `git log`, the pull requests and CI before relying on it.** M5's step-by-step record is in the [M5 package](reviews/m5-review-package.md); M4's in `git show 09d854e:docs/handoff.md` and the [M4 package](reviews/m4-review-package.md).

**Last updated:** 2026-11-20. **M5 is accepted by the owner, on 2026-11-20 at `b7303bf`, as the completed milestone, and merged into `main` by the squash merge of [#6](https://github.com/shamsuzzamansadi/dagon/pull/6).** A milestone acceptance only: nothing tagged or released since `v0.1.0-pre-alpha.1`. **M6 is in progress** on `m6/stabilization`, draft [#7](https://github.com/shamsuzzamansadi/dagon/pull/7), under the [plan](m6-plan.md) the owner approved on 2026-11-20, target 21 to 27 November. The [playtest kit](m6/playtest-kit/README.md), the [listening kit](m6/listening-kit/README.md) and the [native-check sheets](m6/native-checks/README.md) are with the owner.

## Where things are

| | |
|---|---|
| **Milestones** | M1 to M5 accepted ([roadmap](roadmap.md)). M5: [record](evidence/m5/owner-acceptance-2026-11-20.md), [package](reviews/m5-review-package.md) §17 |
| **The accepted build** | `b7303bf`, `dagon-windows`, artifact [14627487176](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136/artifacts/14627487176) of push run 44731893136, zip SHA-256 `97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`. Fingerprint `sha256:1f724cdc2c582c997c9b7b780ff092f4763c0077b5defe9805c6cce37533dc8d`, unchanged by the documents after it and by the squash merge |
| **What the owner tested** | The running route on that build, recorded: the ridge reads as Dagon's shoulder, the arm stays connected through the hand landing, the same wave overtakes the fallen sailor. The standing-still ending has scripted coverage only. ChatGPT compared the owner's video frames and measured the recorded audio against the owner's earlier clip; it did not listen |
| **Branch** | `main` only. `m5/polish` is merged and deleted |
| **Releases** | Only [`v0.1.0-pre-alpha.1`](https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.1.0-pre-alpha.1), at `760a539`, untouched. **`v0.2.0-alpha.1`, M5's planned prerelease, needs the owner's separate approval;** none is made |

## Open

**Waiting on people:** two first-time players and their recordings (the owner contacts them); the owner's listening sheet; the owner's native checks on the Ubuntu ThinkPad and the Windows desktop; controllers, whose results stay pending until someone tests the actual hardware. **Developer, meanwhile:** displays and fullscreen, frame times, the verification matrix, German key labels in CI, the visual review, the carried items.

**Open from M5, as the owner said:** the intelligibility of the reveal's dialogue by ear, in the full mix ("Its head turned. I ran." under the second call stays flagged, [listening package](evidence/m5/listening/README.md)).

**For M6, unmeasured:** two external first-time players and their timings, so **first-time duration is unknown;** controller vibration by feel; all physical PlayStation hardware; individual physical Xbox actions, including reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering; displays at 1280 × 720 and 1920 × 1080, windowed and fullscreen. **Carried:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.

**Known, recorded** ([package](reviews/m5-review-package.md) §7): the band figures are a diagnostic; the creature's two-pixel blocks at full zoom; frame time not measured beyond the reveal's first-draw stalls; amber in the ending's pictures beyond the lantern; the full-game recording predates the changes of 2026-11-18 to 11-20.

## Owner feedback, and review, in order

- **2026-11-04 to 11-10:** M3's playtests and acceptance ([records](evidence/m3/)).
- **2026-11-15:** three reports on M4's candidates, then acceptance of `8b30b33` and the first pre-alpha release ([acceptance](evidence/m4/owner-acceptance-2026-11-15.md)).
- **2026-11-16:** approved M5's scope.
- **2026-11-18:** ChatGPT's independent review of `cd28f55`.
- **2026-11-19:** the owner played `20929cf`, `59562c6` and `ea86ae9` ([records](evidence/m5/)), with five points, four visual points and three points in motion, addressed in turn.
- **2026-11-20:** the owner played `b7303bf` and accepted M5 ([record](evidence/m5/owner-acceptance-2026-11-20.md)); authorized the squash merge and the branch's clean-up, and no tag or release.

## Working resources

Outside the repository and outside `/tmp`.

| What | Where |
|---|---|
| The native clone | `~/work/dagon-m4/clone`, on `main` after the merge. The folder's name is M4's. **The Windows working copy follows `main`;** work is done in the clone and pushed |
| Helpers, `$W` = `~/work/dagon-m4` | `bin/env.sh` (source it), `xns.sh` (private X display, docs/toolchain.md §6a), `integration_point.sh <name>` and its `_v` and `_m` forms with silent video of the exported game, `focus.sh <name>`; `notes/` |
| M5's working files, `~/work/dagon-m5` | `bin/` (`recp.sh` for lossless Movie Maker takes, `timing.sh` for frame times at the game's own pace), `notes/` (the passes' takes, sheets and scripts), the accepted candidate's zips |
| Rebuildable environments | `~/.cache/dagon-m4/S`: `venv`, `tts`, the private X server |
| Pushing from the clone | `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin <branch>` |

## Next concrete action

**The developer's M6 items** (plan items 4 to 11) while the playtests and the listening are pending; then the playtests' measurements and options for the owner; then the M6 candidate and a stop for the owner's review. **Merging M6, publishing `v0.2.0-alpha.1` and starting M7 need the owner's word.**
