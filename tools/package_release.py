#!/usr/bin/env python3
"""Makes the one release package for an OS from CI's export, and smoke-tests the package itself. Standard library only.

  package  Wraps the exact exported files, with the license and credits. Nothing is rebuilt.
  smoke    Extracts a package into a clean folder and runs it headless, on the OS it is for.

The tar and gzip timestamps are fixed, and gzip stores no file name, so the same export always gives the same bytes,
whenever it is packaged. macOS's export is Godot's own zip of the app, signed as Godot signs it; its entries are copied
as they are, with the permissions they record, under the package's folder (D129).
"""
import argparse
import gzip
import os
import plistlib
import stat
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

PLATFORMS = {
    "linux": {
        "binary": "dagon.x86_64",
        "files": ("dagon.x86_64", "dagon.pck", "libdagon.linux.template_release.x86_64.so"),
        "extension": ".tar.gz",
        "arch": "x86_64",
    },
    "windows": {
        "binary": "dagon.exe",
        "files": ("dagon.exe", "dagon.pck", "dagon.windows.template_release.x86_64.dll"),
        "extension": ".zip",
        "arch": "x86_64",
    },
    "macos": {
        "files": ("dagon.zip",),
        "extension": ".zip",
        "arch": "arm64",
        "library": "libdagon.macos.template_release.arm64.dylib",
    },
}
LEGAL = ("LICENSE", "CREDITS.md")
# The game ends the run itself after this many frames, stopping its sound first (D78). --quit-after is only a backstop:
# the engine shuts down in that frame, before the mixer can let go of a sound still playing.
QUIT_AFTER_FRAMES = "300"
QUIT_BACKSTOP_FRAMES = "1200"


def package_name(platform, version):
    spec = PLATFORMS[platform]
    return f"dagon-{version}-{platform}-{spec['arch']}{spec['extension']}"


def unix_mode(info):
    """The permissions a zip entry records, or, if its zip recorded none, what an app bundle needs."""
    mode = info.external_attr >> 16
    if stat.S_IFMT(mode):  # A Unix zip records the file's type with its permissions.
        return mode
    if info.is_dir():
        return stat.S_IFDIR | 0o755
    executable = "/Contents/MacOS/" in info.filename or info.filename.endswith(".dylib")
    return stat.S_IFREG | (0o755 if executable else 0o644)


def zip_entry(name, mode):
    info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
    info.create_system = 3  # Unix, so that the permissions below are read on extraction.
    info.external_attr = mode << 16
    info.compress_type = zipfile.ZIP_STORED if name.endswith("/") else zipfile.ZIP_DEFLATED
    return info


def package_macos(export, sources, target, folder):
    """Copies the app out of Godot's zip entry by entry, bytes and permissions unchanged, under the package's folder."""
    with zipfile.ZipFile(export / "dagon.zip") as source:
        apps = {name.split("/", 1)[0] for name in source.namelist()}
        if len(apps) != 1 or not next(iter(apps)).endswith(".app"):
            sys.exit(f"::error::The macOS export should hold exactly one app, and holds {sorted(apps)}")
        with zipfile.ZipFile(target, "w") as archive:
            for info in source.infolist():
                archive.writestr(zip_entry(f"{folder}/{info.filename}", unix_mode(info)), source.read(info))
            for path, name in sources:
                archive.writestr(zip_entry(f"{folder}/{name}", stat.S_IFREG | 0o644), path.read_bytes())


def package(platform, version, export_dir, legal_dir, out_dir):
    spec = PLATFORMS[platform]
    export = Path(export_dir)
    present = sorted(path.name for path in export.iterdir() if path.is_file())
    if present != sorted(spec["files"]):
        sys.exit(f"::error::The {platform} export should hold exactly {sorted(spec['files'])}, and holds {present}")
    sources = [(export / name, name) for name in spec["files"]] + [(Path(legal_dir, name), name) for name in LEGAL]
    for source, _ in sources:
        if not source.is_file():
            sys.exit(f"::error::Missing from the {platform} package: {source}")

    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    target = out / package_name(platform, version)
    folder = target.name.removesuffix(spec["extension"])
    if platform == "macos":
        package_macos(export, [(Path(legal_dir, name), name) for name in LEGAL], target, folder)
    elif platform == "linux":
        with open(target, "wb") as raw, gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w") as archive:
                for source, name in sources:
                    info = archive.gettarinfo(source, f"{folder}/{name}")
                    info.mtime = 0
                    info.uid = info.gid = 0
                    info.uname = info.gname = ""
                    info.mode = 0o755 if name == spec["binary"] else 0o644
                    with open(source, "rb") as data:
                        archive.addfile(info, data)
    else:
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
            for source, name in sources:
                info = zipfile.ZipInfo(f"{folder}/{name}", date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, source.read_bytes())
    print(f"packaged {target} ({target.stat().st_size} bytes)")
    return target


def extract(package_path, into, platform=""):
    package_path = Path(package_path)
    if platform == "macos":
        # As a Mac unpacks a download, with the permissions the zip records.
        subprocess.run(["ditto", "-x", "-k", str(package_path), str(into)], check=True)
    elif package_path.name.endswith(".tar.gz"):
        with tarfile.open(package_path) as archive:
            archive.extractall(into, filter="data")
    else:
        with zipfile.ZipFile(package_path) as archive:
            archive.extractall(into)
    folders = [path for path in Path(into).iterdir() if path.is_dir()]
    if len(folders) != 1:
        sys.exit(f"::error::{package_path.name} should hold one folder, and holds {[path.name for path in folders]}")
    return folders[0]


def run_headless(binary, work, name, autostart=""):
    log = Path(work, f"{name}.log")
    environment = dict(os.environ, DAGON_STORAGE_DIR=Path(work, "storage").as_posix(), DAGON_AUTOSTART=autostart, DAGON_QUIT_AFTER_FRAMES=QUIT_AFTER_FRAMES)
    result = subprocess.run(
        [str(binary), "--headless", "--verbose", "--quit-after", QUIT_BACKSTOP_FRAMES, "--log-file", str(log)],
        env=environment,
        cwd=binary.parent,
        capture_output=True,
        text=True,
        errors="replace",
        timeout=300,
    )
    text = result.stdout + result.stderr + (log.read_text(errors="replace") if log.exists() else "")
    if result.returncode != 0:
        sys.exit(f"::error::{name}: the packaged game exited with {result.returncode}\n{text[-1500:]}")
    errors = [line for line in text.splitlines() if line.startswith(("ERROR", "SCRIPT ERROR", "USER ERROR"))]
    if errors:
        sys.exit(f"::error::{name}: the packaged game logged errors: {errors[:3]}")
    return text


def require(text, proof, name):
    if proof not in text:
        sys.exit(f"::error::{name}: no proof in the packaged game's output: {proof}")


def macos_app(folder, package_path):
    """The app in an unpacked macOS package, checked as a Mac would check it before running it. Returns its executable."""
    present = sorted(path.name for path in folder.iterdir())
    apps = [name for name in present if name.endswith(".app")]
    if len(apps) != 1 or sorted(set(present) - set(apps)) != sorted(LEGAL):
        sys.exit(f"::error::{Path(package_path).name} should hold one app, {LEGAL[0]} and {LEGAL[1]}, and holds {present}")
    app = folder / apps[0]
    with open(app / "Contents" / "Info.plist", "rb") as info:
        executable = app / "Contents" / "MacOS" / plistlib.load(info)["CFBundleExecutable"]
    if not os.access(executable, os.X_OK):
        sys.exit(f"::error::{executable.name} lost its executable bit in the package")
    library = app / "Contents" / "Frameworks" / PLATFORMS["macos"]["library"]
    for path in (executable, library):
        archs = subprocess.run(["lipo", "-archs", str(path)], capture_output=True, text=True).stdout.split()
        if archs != ["arm64"]:
            sys.exit(f"::error::{path.name} should be built for arm64 alone, and is built for {archs}")
    # Apple Silicon runs nothing whose signature does not hold, so a broken one would stop every player.
    check = subprocess.run(["codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)], capture_output=True, text=True)
    if check.returncode != 0:
        sys.exit(f"::error::The app's signature does not hold after packaging: {(check.stdout + check.stderr).strip()}")
    print(f"macOS: {app.name} is arm64, its signature holds, and {executable.name} is executable")
    return executable


def smoke(platform, package_path):
    spec = PLATFORMS[platform]
    with tempfile.TemporaryDirectory(prefix="dagon-package-smoke.") as work:
        folder = extract(package_path, work, platform)
        if platform == "macos":
            binary = macos_app(folder, package_path)
        else:
            expected = sorted(spec["files"] + LEGAL)
            present = sorted(path.name for path in folder.iterdir())
            if present != expected:
                sys.exit(f"::error::{Path(package_path).name} should hold exactly {expected}, and holds {present}")
            binary = folder / spec["binary"]
            if platform == "linux" and not os.access(binary, os.X_OK):
                sys.exit(f"::error::{binary.name} lost its executable bit in the package")
        Path(work, "storage").mkdir()

        start = run_headless(binary, work, "start")
        require(start, "dagon: extension initialized build=release", "start")
        require(start, "Completed load for: 'res://scenes/ui/title.tscn'", "start")

        new_game = run_headless(binary, work, "new_game", "new_game")
        require(new_game, "dagon: session start beat=0 persisted=0", "new_game")
        require(new_game, "dagon: prompt: [E] Examine", "new_game")
        save = Path(work, "storage", "save.dat")
        if not save.is_file() or "checkpoint=" not in save.read_text(errors="replace"):
            sys.exit("::error::new_game: the packaged game wrote no save at its first checkpoint")
        print("saved: " + " ".join(save.read_text(errors="replace").split()))

        # A new process, on that save.
        resumed = run_headless(binary, work, "continue", "continue")
        require(resumed, "dagon: save status=0", "continue")
        require(resumed, "dagon: session start beat=0 persisted=0", "continue")
    print(f"smoke passed: {Path(package_path).name} starts, runs New Game with a prompt, saves at its first checkpoint, quits, and continues from that save in a new process")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    package_parser = commands.add_parser("package")
    package_parser.add_argument("--platform", required=True, choices=PLATFORMS)
    package_parser.add_argument("--version", required=True)
    package_parser.add_argument("--export-dir", required=True)
    package_parser.add_argument("--out", required=True)
    smoke_parser = commands.add_parser("smoke")
    smoke_parser.add_argument("--platform", required=True, choices=PLATFORMS)
    smoke_parser.add_argument("--package", required=True)
    args = parser.parse_args()
    if args.command == "package":
        package(args.platform, args.version, args.export_dir, ".", args.out)
    else:
        smoke(args.platform, args.package)


if __name__ == "__main__":
    main()
