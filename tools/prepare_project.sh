#!/usr/bin/env sh
# Pre-seed Godot's extension list before the first import (docs/toolchain.md §5).
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/project/.godot"
printf 'res://bin/dagon.gdextension\n' > "$root/project/.godot/extension_list.cfg"
