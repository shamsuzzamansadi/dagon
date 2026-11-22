# The owner's approval of M6's version and target, 2026-11-22

**Stated by the owner, in their message on 2026-11-22,** in answer to the [tag proposal](candidate-v0.2.0-alpha.2.md#the-tag-proposal-for-the-owners-word):

> I approve the proposed M6 version v0.2.0-alpha.2 and its target commit b271316. Please merge the docs-only PR #9 once its checks pass. Keep the release record in candidate state until I report the native Windows and Ubuntu results.

> I'll test New Game → Shore save → Quit to Desktop → relaunch → Continue on both machines and check the fullscreen switch on my Windows monitor.

> For the release notes, describe exactly what the Apple Silicon runner verified and retain the outstanding human checks. Once I confirm publication, use the verified packages from run 45038841566 and put the tag on b271316.

## What this establishes

- **The version is `v0.2.0-alpha.2`, and its target is `b271316`,** M6's squash merge. The packages to publish are the ones `main`'s own run 45038841566 built and tested there, as in the verified candidate (D128). So [`release/v0.2.0-alpha.2.json`](../../../release/v0.2.0-alpha.2.json) names that commit and run as its `source`; from then on `main`'s CI prepares the candidate from them.
- **The record stays `candidate`.** Publishing waits for the owner's native results on Windows and Ubuntu, and then for their confirmation.
- **The notes** say what the Apple Silicon runner verified, and keep every outstanding human check under "Not tested".

## What this does not establish

- **An acceptance of `b271316`'s fingerprint,** `sha256:96c145f4…8135b`, which the gate needs before it publishes. The owner's acceptance of 2026-11-21 covers `a30be86`'s.
- **Any native result.** The owner's runs on the Windows desktop and the Ubuntu ThinkPad, and the fullscreen switch on the Windows monitor, are still to come. Until the owner reports them, they stay deferred.
- **A publication.** Nothing is tagged.
