# `v0.2.0-alpha.2`, the M6 candidate: as `main`'s CI prepared it, and the tag proposal

**A candidate, not a release.** Nothing is tagged or published for M6. Checked by the developer on 2026-11-22.

## The merge and `main`'s CI

| | |
|---|---|
| **#7's last head** | `85aedf6`: `617b297` from `m6/macos` (the README for players, the Mac build, D129, D130) and one commit of documents. Push run [45036602284](https://github.com/shamsuzzamansadi/dagon/actions/runs/45036602284) and pull-request run [45036606328](https://github.com/shamsuzzamansadi/dagon/actions/runs/45036606328): every job passed, `macos` included |
| **Before it, on `617b297`** | Push run [45012866751](https://github.com/shamsuzzamansadi/dagon/actions/runs/45012866751) and the three-platform packaging rehearsal [45012877847](https://github.com/shamsuzzamansadi/dagon/actions/runs/45012877847), every job passed ([review package](../../reviews/m6-review-package.md) §8) |
| **The squash merge** | [`b271316`](https://github.com/shamsuzzamansadi/dagon/commit/b271316371532074eb2c5fb312afa7c0a2d822c4), 2026-11-22, at the owner's authorization of 2026-11-21 ([record](owner-acceptance-2026-11-21.md)). Its tree is `85aedf6`'s exactly. `m6/stabilization` and `m6/macos` are deleted |
| **`main`'s CI on it** | Push run [45038841566](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566): every job passed; the release gate found `v0.1.0-pre-alpha.1` and `v0.2.0-alpha.1` already published, prepared `v0.2.0-alpha.2` as a candidate, and skipped publishing |

## The candidate artifact

`release-candidate-v0.2.0-alpha.2`, artifact [14761047666](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566/artifacts/14761047666) of run 45038841566, `sha256:8bbd25367ad8addec2a7c0c6626f3895578cf49f6c64ea64018bbdc2431da360`. GitHub keeps it until 2026-12-06; the run's own exports, which a release would ship (D128), until 2027-02-20.

| Package | SHA-256 |
|---|---|
| `dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz` | `6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05` |
| `dagon-v0.2.0-alpha.2-macos-arm64.zip` | `9daca1d1f76982248a8ba91029c0dca99cfc8fee3387d411063a09a933cb5586` |
| `dagon-v0.2.0-alpha.2-windows-x86_64.zip` | `f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148` |

**Checked, by the developer, on the downloaded artifact:** its hash equals GitHub's digest; `sha256sum -c SHA256SUMS.txt` passes for all three packages, and the notes' table carries the same hashes; `PROVENANCE.txt` names source commit `b271316` and run 45038841566, and the fingerprint `sha256:96c145f475ab1b890f9f4363d96e0a028c5bf3c8cb6111f8f97174561ee8135b`; the Windows and Linux packages hold exactly the game's three files, `LICENSE` and `CREDITS.md`, the Mac package `DAGON.app`, `LICENSE` and `CREDITS.md`; the notes list all seven deferred checks under "Not tested" and say that no owner acceptance covers this build. Each package was smoke-tested by that run on a GitHub-hosted runner of its system, macOS 15.8.2 on arm64 for the Mac: start, New Game to a save, quit, and Continue in a new process. **No person has launched any of them.**

## The tag proposal, for the owner's word

- **Version `v0.2.0-alpha.2`,** an alpha, as the record names it. The roadmap names no version for M6.
- **The tag on `b271316`,** M6's squash merge, and the packages `main`'s own run 45038841566 built and tested there, for Linux, Windows and macOS on Apple Silicon (D128), as in this candidate. The record would name that commit and run as its `source`, as `v0.2.0-alpha.1`'s does.
- **What publishing needs from the owner,** which the gate reports as remaining: an acceptance that covers `b271316`'s fingerprint, `sha256:96c145f4…8135b`. The owner's acceptance of 2026-11-21 covers `a30be86`'s, `sha256:14e30e9c…b4f04f`; the merge adds the README and the Mac build's files to it. Either the owner launches the candidate's packages and says what they saw, or the owner accepts that fingerprint knowingly on CI's evidence alone, with no person having played the merged build on any system, or any Mac build.
- **Also open against the roadmap's M6 exit gate:** "release candidate artifacts from CI launched on real Windows and Linux". CI launched them on hosted runners; the native runs on the owner's machines are among the deferred checks.
- **The notes keep every outstanding human check** under "Not tested", as the owner asked on 2026-11-21.

**Approved by the owner on 2026-11-22: the version and its target, `b271316`** ([record](release-approval-2026-11-22.md)). The record now names `b271316` and run 45038841566 as its `source`, and stays `candidate` until the owner reports their native Windows and Ubuntu results. After their confirmation, a pull request of records only sets it to `publish`, with the owner's statement, and `main`'s CI on its merge publishes and tags `b271316`.

**The same packages, again.** A publication packages the run's exports anew. Packaging is deterministic: repackaged here from run 45038841566's exports and `b271316`'s license and credits, the Linux package's SHA-256 is the candidate's exactly. The Windows zip repackaged here holds the same files, compressed to the same bytes, and differs only in one header byte per entry, the system it was made on, which Python writes as Windows on a Windows machine. The release packages Windows on the same `windows-2022` runner as the candidate. At publication, the published hashes are checked against the candidate's above; a difference stops it.

**Reproduced by CI from the source.** Once the record named `b271316` and run 45038841566 as its `source`, `main`'s CI packaged that run's exports afresh. On `757997e` (#9) it failed in `prepare`, "Prepare the notes, checksums and provenance": no record of the macOS version the Mac package was smoke-tested on. The package job never passed `--facts` for a record with a source; fixed in #10 (D131), after a rehearsal of exactly this path passed (run 45053961776). On `43fb485` (#10), `main`'s run [45056251635](https://github.com/shamsuzzamansadi/dagon/actions/runs/45056251635) passed every job, and its candidate, artifact 14768167080, holds **the same three packages byte for byte** as artifact 14761047666, with the notes' new Mac line, and the Mac smoke test recorded in the provenance.

**The provenance's wording, corrected at the owner's request of 2026-11-22.** That candidate's provenance said "Packaged, smoke-tested and published by" run 45056251635, and nothing was published. From #12 (D132) the provenance and the notes give three separate facts, the game source commit `b271316`, the source build run 45038841566, and the run that packaged, smoke-tested and prepared the candidate, and say they record no publication. The run that publishes is added to the release's notes only after GitHub reports the release published; the files are not touched. A regression check keeps a prepared provenance from claiming a publication. On `96d159f` (#12), `main`'s run [45065005116](https://github.com/shamsuzzamansadi/dagon/actions/runs/45065005116) passed every job, and its candidate, artifact 14771387993, **holds the three archives the owner tests, byte for byte, with the SHA-256 above,** and the same `SHA256SUMS.txt`. Checked by the developer on the downloaded artifact.

**Accepted and authorized by the owner on 2026-11-27** ([record](release-authorization-2026-11-27.md)): the candidate from `b271316`, to be published from run 45038841566. The owner tested the Windows package extensively and found no issues; the Ubuntu native run stays untested. #11 sets the record to `publish`.

## The owner's native checks

From artifact [14761047666](https://github.com/shamsuzzamansadi/dagon/actions/runs/45038841566/artifacts/14761047666), downloaded as `release-candidate-v0.2.0-alpha.2.zip`. The owner's route on each machine: New Game, the save at the Shore, Quit to Desktop, relaunch, Continue; and on the Windows monitor, the fullscreen switch. The frame log (D123) is set as in the [native-check sheets](../../m6/native-checks/README.md). New Game over an earlier save asks first: "Start a new game? This replaces your saved game."

**Windows, in PowerShell,** in the folder with the download:

```
Expand-Archive release-candidate-v0.2.0-alpha.2.zip -DestinationPath candidate
cd candidate
Get-FileHash dagon-v0.2.0-alpha.2-windows-x86_64.zip   # F76538CC776603806010824AB93F0FB0424A5F90184FD0854AF2B98EEFD34148
Expand-Archive dagon-v0.2.0-alpha.2-windows-x86_64.zip -DestinationPath .
$env:DAGON_FRAME_LOG = "50"
.\dagon-v0.2.0-alpha.2-windows-x86_64\dagon.exe --print-fps
```

To relaunch, the last line again in the same window. The log is `%APPDATA%\Godot\app_userdata\DAGON- Beneath the Black Tide\logs\godot.log`, begun again at each start, so it is copied before the relaunch.

**Ubuntu, in a terminal,** in the folder with the download:

```
unzip release-candidate-v0.2.0-alpha.2.zip -d candidate && cd candidate
sha256sum dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz   # 6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05
tar -xzf dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz && cd dagon-v0.2.0-alpha.2-linux-x86_64
DAGON_FRAME_LOG=50 ./dagon.x86_64 --print-fps 2>&1 | tee run-1.log
DAGON_FRAME_LOG=50 ./dagon.x86_64 --print-fps 2>&1 | tee run-2.log   # the relaunch
```

Near the top of each log Godot names the device it draws with ("Using Device: …"); `llvmpipe` would mean software rendering, not the native check.
