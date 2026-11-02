"""Extracts the desktop export templates from a Godot .tpz archive.

Usage: extract_templates.py <archive.tpz> <destination-dir>
Only the named files are written, by base name, so archive paths cannot escape
the destination.
"""

import pathlib
import sys
import zipfile

WANTED = {
    "version.txt",
    "linux_debug.x86_64",
    "linux_release.x86_64",
    "windows_debug_x86_64.exe",
    "windows_release_x86_64.exe",
    "windows_debug_x86_64_console.exe",
    "windows_release_x86_64_console.exe",
}


def main() -> int:
    archive, destination = sys.argv[1], pathlib.Path(sys.argv[2])
    destination.mkdir(parents=True, exist_ok=True)
    found = set()
    with zipfile.ZipFile(archive) as tpz:
        for info in tpz.infolist():
            name = pathlib.PurePosixPath(info.filename).name
            if name in WANTED:
                target = destination / name
                target.write_bytes(tpz.read(info))
                target.chmod(0o755)
                found.add(name)
    missing = WANTED - found
    if missing:
        print("Missing from archive: " + ", ".join(sorted(missing)), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
