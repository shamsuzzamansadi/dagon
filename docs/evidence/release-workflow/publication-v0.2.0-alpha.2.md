# The publication of `v0.2.0-alpha.2`, M6's alpha, from `b271316`

**Published on 2026-11-27, by hand, with the owner's GitHub login,** from the files CI run [46036924022](https://github.com/shamsuzzamansadi/dagon/actions/runs/46036924022) prepared, after that run's own publish job was refused by GitHub. At the owner's acceptance and authorization of 2026-11-27 ([record](../m6/release-authorization-2026-11-27.md)), and the owner's choice of how to publish, the same day: <https://github.com/shamsuzzamansadi/dagon/releases/tag/v0.2.0-alpha.2>. The first release with a Mac package.

## How

| Step | What happened |
|---|---|
| The record | [`release/v0.2.0-alpha.2.json`](../../../release/v0.2.0-alpha.2.json), `state: publish`, source `b271316` and `main`'s own push run of it, [45038841566](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566), in [#11](https://github.com/shamsuzzamansadi/dagon/pull/11). The gate, run locally against GitHub before the merge: "has passed every gate, and will be published from `b271316`…, as built by CI run 45038841566, and tagged there" |
| The merge | #11's required checks passed on its head, `e936c3f`, push and pull request; squash merge into `main`: `404ee5e` |
| `main`'s CI | Run 46036924022: every check job passed; the gate passed; the three packages were made from run 45038841566's exports and smoke-tested on their own systems; the notes, checksums and provenance were prepared (artifact 15220055087). **`release / publish`, step "Publish the prerelease", failed:** `HTTP 403: Resource not accessible by integration (https://api.github.com/repos/shamsuzzamansadi/dagon/releases)`, from `gh release create`, the draft's creation. The job's token had `Contents: write`, as in `v0.2.0-alpha.1`'s publish job. **Nothing was created:** no tag, no release, no draft |
| The probable cause | **Not proven.** `b271316` changes `.github/workflows/ci.yml` and `release.yml` (M6's Mac build); `760a539` and `a4250f0`, the two earlier releases' commits, change no workflow file, and both published from the same workflow. GitHub refuses a token without the `workflows` permission some operations on commits that change workflow files, and an Actions token can never hold that permission. The repository's settings were read and found unchanged: the tag ruleset (update, deletion, non-fast-forward; last changed 2026-11-04), immutable releases on, the token's default read with `contents: write` granted to the job. No GitHub documentation found states this case for creating a release |
| The owner's choice | Of four options the developer gave (by hand with the owner's login; a stored token for the publish job; a tag pushed over SSH for CI to complete; hold), **the owner chose "By hand, your login"**, and added the `workflow` scope to their GitHub CLI login |
| By hand | [`publish-by-hand-v0.2.0-alpha.2.sh`](v0.2.0-alpha.2/publish-by-hand-v0.2.0-alpha.2.sh), the steps of `tools/publish_release.sh` in their order, on artifact 15220055087's files: those archives checked first against the three the owner tested, then against `SHA256SUMS.txt`; the live tag and release state read (none); the preflight ("create"); the draft created and its files uploaded, downloaded again and checked; published; `verify`; one line added to the notes saying how it was published. [Its output](v0.2.0-alpha.2/publish-by-hand-v0.2.0-alpha.2.log) |

## Verified afterwards, by the developer

| | |
|---|---|
| **The release** | Published at 2026-11-27T17:39:08Z (GitHub's time), a prerelease, immutable, named "DAGON: Beneath the Black Tide v0.2.0-alpha.2"; target `b271316371532074eb2c5fb312afa7c0a2d822c4`. `verify`: "complete, consistent and at `b271316`" |
| **The tag** | `v0.2.0-alpha.2` → commit `b271316371532074eb2c5fb312afa7c0a2d822c4`, read from the remote |
| **Files** | The three packages, `SHA256SUMS.txt` and `PROVENANCE.txt`, downloaded from the public download links into a new, empty folder; `sha256sum -c SHA256SUMS.txt` OK; each package equal to GitHub's own digest |
| **SHA-256, the accepted candidate's** | Windows `f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148`, Linux `6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05`, macOS `9daca1d1f76982248a8ba91029c0dca99cfc8fee3387d411063a09a933cb5586`: **each downloaded package byte for byte the one in artifact 14761047666, which the owner tested** |
| **Provenance** | Game source commit `b271316…`; source build run 45038841566; packaged, smoke-tested and prepared by CI run 46036924022 at `404ee5e`; no publication claimed (D132) |
| **The notes** | The prepared notes, and one last line: "Published by hand, with the owner's GitHub login, from the files CI run 46036924022 prepared, after that run's own publish job was refused by GitHub (HTTP 403); GitHub reports it published at 2026-11-27T17:39:08Z". Under "Not tested", the six checks still outstanding, the Ubuntu native run among them |
| **Earlier releases** | `v0.1.0-pre-alpha.1` and `v0.2.0-alpha.1`: untouched |

**Not established by any of this:** anything a person checked on this build beyond the owner's own statements in the [record](../m6/release-authorization-2026-11-27.md); the release notes list what was not tested. **Open for the workflow:** how a later version whose commit changes workflow files is to be published (D133).
