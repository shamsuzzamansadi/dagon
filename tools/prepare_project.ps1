# Pre-seed Godot's extension list before the first import (docs/toolchain.md §5).
$root = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force "$root\project\.godot" | Out-Null
[IO.File]::WriteAllText("$root\project\.godot\extension_list.cfg", "res://bin/dagon.gdextension`n")
