# Owner acceptance of M3, 2026-11-10

**Stated by the owner, in their message on 2026-11-10:**

> I accept M3 at commit 3980bc3f116d334fa8fe5403fa5747df6ea4beb3 as the completed, agreed milestone, with the documented
> M4/M5 and hardware/playtesting deferrals. This is milestone acceptance, not approval of the game as a finished release.
> Do not invent item-by-item manual passes beyond my stated feedback.

**What this establishes:** the owner accepts M3, as the agreed milestone, at `3980bc3`, with the deferrals documented in the [handoff](../../handoff.md), the [roadmap](../../roadmap.md) and the [review package](../../reviews/m3-review-package.md)'s §0.

**What it does not establish:**

- **Approval of the game as a finished release.** The owner said so in as many words.
- **Any release.** The record [`release/v0.1.0-pre-alpha.1.json`](../../../release/v0.1.0-pre-alpha.1.json) stays `planned`, its owner acceptance and its criteria `pending`. Publishing would need the owner to ask for it.
- **Any individual manual check as passed.** The owner's stated feedback is in the [playtest records](owner-playtest-2026-11-09.md) and the [listening package](listening/README.md)'s record of who evaluated what: the owner played builds with sound and chose voice A on 2026-11-10. Nothing beyond that is recorded as checked by hand.
- **A judgment of the sound or the voiced ending by ear,** which the owner has not stated.

## Which build

| | |
|---|---|
| **Commit** | `3980bc3f116d334fa8fe5403fa5747df6ea4beb3`, named by the owner |
| **Its CI** | [42810508953](https://github.com/shamsuzzamansadi/dagon/actions/runs/42810508953) (push) and [42810519222](https://github.com/shamsuzzamansadi/dagon/actions/runs/42810519222) (pull request), both passed |
| **The Windows build named for the playtest** | `dagon-windows`, artifact 13762666724 of the push run, zip SHA-256 `cc9b813bbec12d5e6537bfa00bf9cc1bfd003b76fb0cb7672df29b78d4a6ccd9` |
| **Acceptance fingerprint** | `sha256:892b1072136b806ee25340c4cc3f8cefaa36880ae5d7399bd70e6e42f744e453` (`python tools/release_gate.py fingerprint --commit 3980bc3`). Documents-only commits and the squash merge leave it unchanged |

**The acceptance names the commit, not a file.** Which zip the owner ran is not recorded, and is not inferred.

## The review at the time of acceptance

ChatGPT completed a limited follow-up review of `3980bc3` ([record](review-chatgpt-at-3980bc3.md)). It found no new blocking code defect in the areas it reviewed. It did not rerun the Godot integration or exported-route tests, and did not evaluate the soundtrack by ear.

## Deferred, and not passed

- **To M4 and M5:** the greybox art past x = 1440, the creature's own animation, the rest of the script in voice A, the final mix by ear, interface sounds. Listed in the [roadmap](../../roadmap.md).
- **Hardware:** all physical PlayStation hardware; individual physical Xbox actions, including disconnecting and reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering.
- **Playtesting:** first-time duration and engagement, with two external first-time players, for M6.
- **Carried over:** the unresolved M2 J/caption event.
