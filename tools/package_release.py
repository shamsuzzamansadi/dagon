#!/usr/bin/env python3
"""Makes the one release package for an OS from CI's export, and smoke-tests the package itself. Standard library only.

  package  Wraps the exact exported files, with the license and credits. Nothing is rebuilt.
  smoke    Extracts a package into a clean folder and runs it headless, on the OS it is for.

The timestamps inside are fixed, so the same export always gives the same package.
"""
import argparse
import os
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
    },
    "windows": {
        "binary": "dagon.exe",
        "files": ("dagon.exe", "dagon.pck", "dagon.windows.template_release.x86_64.dll"),
        "extension": ".zip",
    },
}
LEGAL = ("LICENSE", "CREDITS.md")
QUIT_AFTER_FRAMES = "300"


def package_name(platform, version):
    return f"dagon-{version}-{platform}-x86_64{PLATFORMS[platform]['extension']}"


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
    if platform == "linux":
        with tarfile.open(target, "w:gz") as archive:
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


def extract(package_path, into):
    package_path = Path(package_path)
    if package_path.name.endswith(".tar.gz"):
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
    environment = dict(os.environ, DAGON_STORAGE_DIR=Path(work, "storage").as_posix(), DAGON_AUTOSTART=autostart)
    result = subprocess.run(
        [str(binary), "--headless", "--verbose", "--quit-after", QUIT_AFTER_FRAMES, "--log-file", str(log)],
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


def smoke(platform, package_path):
    spec = PLATFORMS[platform]
    with tempfile.TemporaryDirectory(prefix="dagon-package-smoke.") as work:
        folder = extract(package_path, work)
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
        if not save.is_file():
            sys.exit("::error::new_game: the packaged game wrote no save")

        resumed = run_headless(binary, work, "continue", "continue")
        require(resumed, "dagon: session start", "continue")
    print(f"smoke passed: {Path(package_path).name} starts, runs New Game with a prompt, saves, and continues")


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
