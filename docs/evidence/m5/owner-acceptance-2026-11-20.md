# Owner acceptance of M5, 2026-11-20

**Stated by the owner, in their message on 2026-11-20:**

> I accept Windows build b7303bf as the completed M5 milestone. I playtested artifact 14627487176. In my recorded running route, the ridge reads as Dagon's shoulder, the arm stays connected through the hand landing, and the same wave overtakes the fallen sailor. I'm satisfied with the result.
>
> Record this acceptance against b7303bf and the tested ZIP SHA-256:
> 97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac
>
> Keep the evidence precise. My recording covers the running route. The standing-still capture outcome has scripted coverage. ChatGPT compared the video frames and measured the recorded audio against my earlier clip. Intelligibility by ear remains open for M6.

**In the same message the owner authorized finishing M5 on pull request #6:** marking it ready and squash-merging it into `main` once the required checks pass on its final head, watching `main`'s CI, and cleaning up the merged branch. "This authorization covers the milestone merge only. A new tag or release requires separate approval."

**What this establishes:** the owner accepts M5 as complete, on the build below. It is a milestone acceptance only. **It is not a release acceptance:** no tag or release is authorized, and none is made.

## Which build

| | |
|---|---|
| **Commit** | `b7303bf`, named by the owner |
| **The accepted artifact, named by the owner** | `dagon-windows`, [artifact 14627487176](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136/artifacts/14627487176) of CI push run [44731893136](https://github.com/shamsuzzamansadi/dagon/actions/runs/44731893136), zip SHA-256 `97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac`, the same as GitHub's digest and as the developer's download |
| **Its CI** | Run 44731893136: GCC, Clang, MSVC and the release tools all passed; integration 455/0 from source and on the exported pack; the exported route 4/0 on Linux and Windows; native 127/127; the art check clean |
| **Acceptance fingerprint** | `sha256:1f724cdc2c582c997c9b7b780ff092f4763c0077b5defe9805c6cce37533dc8d` (`python tools/release_gate.py fingerprint --commit b7303bf`). The later commits on the branch are documents only, and leave it unchanged, as does the squash merge |

## What the owner tested, in the owner's words, and no more

| The owner said | On which build |
|---|---|
| In the recorded running route: the ridge reads as Dagon's shoulder, the arm stays connected through the hand landing, and the same wave overtakes the fallen sailor. Satisfied with the result | `b7303bf`, artifact 14627487176, played by the owner |

**The owner's recording covers the running route.** A recording of 2026-11-20, `20261120-1323-59.0729434.mp4`, 1 min 34 s, is on the developer's machine in the Snipping Tool's folder; the developer has not reviewed it, and nothing here rests on the developer's view of it. It is not in the repository.

**The other way the escape ends, standing still until the sea has him, has scripted coverage only,** as the owner says: the recordings and clips of the motion pass ([clips](motion-pass-2026-11-19/README.md)), the exported route's run that waits out the flee, and the tests of the collapse's sea. **No person has played it on this build.**

## ChatGPT's part, and its limits

- **Compared the video frames** and **measured the recorded audio against the owner's earlier clip.** That is what the owner reports, and no more is claimed.
- **It did not listen,** and no judgement by ear of the dialogue or the mix is recorded.

## What this does not establish

- **Intelligibility by ear.** The reveal's dialogue in the full mix has not been judged by anyone listening; the owner says it remains open for M6. "Its head turned. I ran." under the creature's second call stays flagged ([listening package](listening/README.md)).
- **Any manual or listening check beyond the table above.** The developer's checks are scripted or measured, and say so where they are recorded ([package](../../reviews/m5-review-package.md) §6).
- **Approval of the game as finished,** of its art as final, or of anything labelled stable.
- **A release.** `v0.1.0-pre-alpha.1` stays as published at M4; a new tag or release needs the owner's separate approval.
- **Anything on hardware not named,** or with first-time players.

## Open, for M6

- **Playtesting:** two external first-time players, their timings, and first-time duration, all unmeasured.
- **Listening:** the reveal's dialogue in the full mix, by ear.
- **Hardware and input:** all physical PlayStation hardware; individual physical Xbox actions, including disconnecting and reconnecting; key names under German on the real Windows build; native Linux hardware-accelerated rendering; controller vibration by feel.
- **Carried over:** the unresolved M2 J/caption event; the two breakage survivors of M3's revision.
