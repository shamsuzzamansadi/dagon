# The owner's authorization of M5's alpha, `v0.2.0-alpha.1`, from `a4250f0`

M5 was accepted on 2026-11-20 as a milestone only, with no release ([acceptance](owner-acceptance-2026-11-20.md)). This records the owner's later word on releasing it, limited to what the owner said.

## What the owner said

**On 2026-11-21, in a message while M6 was in progress:**

> Keep the M5 and M6 releases tied to their respective source commits. The planned M5 alpha was v0.2.0-alpha.1, and the accepted M5 merge was a4250f0. Verify the live tags and release record. If that alpha is still unpublished, publish it from the accepted M5 source through the verified release workflow, and check that the tag and package provenance identify a4250f0.

**Then, on 2026-11-22, in answer to the developer's question.** The developer had reported that the alpha label's third criterion, "its principal audio is connected and has been heard in gameplay", had no evidence on record: the M5 plan said "Not heard by anyone on record", and the owner's M5 acceptance left intelligibility by ear open. It asked how the M5 release should go ahead, with three options. **The owner chose "I heard it in play".** The text of that option, written by the developer and chosen by the owner, was:

> You state you heard the game's main audio (music, effects, narration, the reveal) while playing the M5 build b7303bf with sound. I record that in your words, keep the reveal's intelligibility by ear open, and publish v0.2.0-alpha.1 from a4250f0.

The options not chosen were to publish M5 as `v0.1.0-pre-alpha.2`, the rule in [release.md](../../release.md) for when the alpha's promise does not hold, or to hold the release until the owner's listening sheet was in.

## What this establishes

- **The owner heard the M5 build's main audio in play,** on `b7303bf`, with sound: music, effects, narration and the reveal. **That is what "heard in gameplay" rests on,** and nothing more: it is not a judgement of the mix, of the levels, or of any line's intelligibility.
- **The owner authorizes publishing `v0.2.0-alpha.1` from `a4250f0`,** M5's squash merge, through the release workflow, with the tag and the packages' provenance naming `a4250f0`.

## What it does not establish

- **The reveal's dialogue by ear.** Its intelligibility in the full mix stays open, as the owner left it in M5; the owner's [listening sheet](../../m6/listening-kit/listening-sheet.md) is pending. "Its head turned. I ran.", over the creature's second call, stays flagged.
- **Anything about M6,** whose changes are not in `a4250f0`.
- **Any check not named here.** The deferred checks in the release record stay deferred.

## The build

| | |
|---|---|
| **What the owner played** | `b7303bf`, `dagon-windows` artifact 14627487176 of CI run 44731893136, zip SHA-256 `97ef6bd1e621e54875b213a41dd5189afca4554f7277a769ac10c2cf689a71ac` ([acceptance](owner-acceptance-2026-11-20.md)) |
| **What is released** | `main` at `a4250f060ee7cb8051f9ffef9a976bf68f58d630`, M5's squash merge, as built and tested by `main`'s own push run [44748633376](https://github.com/shamsuzzamansadi/dagon/actions/runs/44748633376): its own exports, packaged by its own packaging tool, with the tag on that commit ([D128](../../decisions.md)) |
| **Fingerprint** | `sha256:1f724cdc2c582c997c9b7b780ff092f4763c0077b5defe9805c6cce37533dc8d`, the same for both: the files the owner played are the files released. They are not the same bytes: `main`'s CI built them again |
