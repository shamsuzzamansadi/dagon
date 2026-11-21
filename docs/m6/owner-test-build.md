# M6 owner-test build

For the owner, on the Windows desktop and the Ubuntu ThinkPad. **Not the playtest baseline:** both first-time players stay on `a4250f0` ([kit](playtest-kit/README.md)). **Not the M6 candidate,** which is named after the human checks (handoff, [review package](../reviews/m6-review-package.md) §7).

## The build

| | |
|---|---|
| **Source** | `m6/stabilization` at **`a30be86`**, which holds every M6 game change through `1229ae6`; `a30be86` itself changes two documents only. Acceptance fingerprint `sha256:14e30e9c7a601075231f27ebbb9cca4a72373302b63d600c8601d97c17b4f04f`, the same for `1229ae6`, `a30be86` and `7402879` |
| **CI** | Push run [44913367672](https://github.com/shamsuzzamansadi/dagon/actions/runs/44913367672), every job passed: integration 460/0 from source and on the exported pack on GCC, Clang and MSVC; native 135/135; the art check clean; the exported game played to the ending on Linux and Windows (`runs=4 failed=0`); `desktop-checks` on both builds (German key names on Windows, the Display setting across a relaunch, M2's examine) |
| **Windows** | `dagon-windows`, artifact [14711113002](https://github.com/shamsuzzamansadi/dagon/actions/runs/44913367672/artifacts/14711113002): zip SHA-256 `c138e0d43d3963882b0697ad54f7d686c44726b1bd240cccaccaa594b5211c9a`; in it `dagon.exe`, `dagon.pck`, `dagon.windows.template_release.x86_64.dll` |
| **Linux** | `dagon-linux`, artifact [14710923427](https://github.com/shamsuzzamansadi/dagon/actions/runs/44913367672/artifacts/14710923427): zip SHA-256 `2e281dc2b803c1848782bdfc8839797f4fe3dea36575c0d63a6859d19469f83b`; in it `dagon.x86_64`, `dagon.pck`, `libdagon.linux.template_release.x86_64.so` |

GitHub lets only a signed-in account download these, until 19 February 2027.

**Verified by the developer:** both zips downloaded and hashed, each equal to GitHub's own digest. Of the 367 files in the Windows pack, the one that differs from the baseline's, apart from the 10 scenes Godot converts at export, is the cave's front texture (D126). **The downloaded Linux build** was played to the ending on a private display by the route check, with window-system keys: `runs=4 failed=0` (reading everything, straight through, continuing and waiting for the sea, continuing after the ending). From a post-ending save (`beat=awakened`, `checkpoint=Awakened`), Continue stood the sailor clear of the kneeling statue, and walking right reached the reveal 3.9 s after Continue, with no errors logged. All of that is automated: no person has played this build yet.

## The checklist, in this order

**On every sheet and log:** "owner-test `a30be86`", the device, and the zip's SHA-256. Name the files by build and device, as below.

1. **Listen first.** The [listening kit](listening-kit/README.md)'s step 1: the full mix on headphones, then on speakers, and the [listening sheet](listening-kit/listening-sheet.md). Open nothing else in that folder, and no review screenshots, until the sheet is done. Step 3's Continue walks straight into the reveal, captions and all, so do step 3 after the sheet.
2. **Windows desktop.** Before starting, keep a copy of the post-ending save, in PowerShell:
   `Copy-Item "$env:APPDATA\Godot\app_userdata\DAGON- Beneath the Black Tide\save.dat" "$env:USERPROFILE\Desktop\dagon-post-ending-save.dat"`
   Then start the game as in the [Windows sheet](native-checks/windows-desktop.md) §2, frame log and all, and fill in its §4, at 1280 × 720 and 1920 × 1080:
   - the window opens fitted, with sharp pixels;
   - Settings → Display turns fullscreen on and off;
   - quit to the desktop and start again: the game opens in the mode you left it in, for both fullscreen and windowed;
   - Settings' key row reads **Examine**, the word the prompts use.

   Copy `godot.log` as `owner-test-a30be86-windows-godot.log` before each new start, because each start replaces it.
3. **In play, on Windows.**
   - **Continue first,** because New Game replaces the save. Continue from the existing post-ending save: the sailor stands just right of the kneeling statue, clear of it, and answers the keys at once; walking right, the gate is open. If the save was replaced, put the copy back over `save.dat` with the game closed.
   - **New Game:** walk through the cave's mouth from the Shore: the cliff meets the cave's roof along a rough, rocky line, with no straight vertical edge and no dark block beside the cliff's foot.
   - **The cave's exit:** the rock rib's own edge meets the sky, with no strip of wall with a straight edge.
   - **Near the Abyss crossing:** the distant shape stands behind the far cliff, and the Shore's sky by its cliff is clear of it.
4. **Ubuntu ThinkPad,** by the [Linux sheet](native-checks/linux-thinkpad.md). The frame-time log, from the folder with the zip:

   ```
   sha256sum dagon-linux.zip     # must be 2e281dc2b803c1848782bdfc8839797f4fe3dea36575c0d63a6859d19469f83b
   mkdir dagon-owner-test && cd dagon-owner-test && unzip ../dagon-linux.zip && chmod +x dagon.x86_64
   DAGON_FRAME_LOG=50 ./dagon.x86_64 --print-fps 2>&1 | tee owner-test-a30be86-thinkpad.log
   ```

   `grep -m1 "Using Device" owner-test-a30be86-thinkpad.log` names the graphics device. If it says `llvmpipe`, the run used software rendering, so please say so. **Controllers:** for whichever you have, the [controller sheet](controller-checks/README.md), with the build, the device and the operating system in its header.

## Results, tied to build and device

Nothing here is recorded as checked until the owner reports it. If the M6 candidate's fingerprint differs from this build's, the developer will say which results need repeating on it.

| Check | Build | Device | Result |
|---|---|---|---|
| Listening sheet | The [kit](listening-kit/README.md)'s file, recorded at `a4250f0` | Headphones, speakers | pending |
| Displays, Display setting across a relaunch, Examine | owner-test `a30be86` | Windows desktop | pending |
| Continue after the ending, the cave, the distant shape | owner-test `a30be86` | Windows desktop | pending |
| Native run and frame log | owner-test `a30be86` | Ubuntu ThinkPad | pending |
| Controllers | owner-test `a30be86` | as reported | pending |
