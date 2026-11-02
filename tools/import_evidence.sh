#!/usr/bin/env sh
# Re-collects the import-workaround evidence on the actual project: clean-cache
# imports without and with the prepared extension list, keeping stdout, stderr
# and exit status per trial. Failed trials are data here, so this never fails.
# Usage: GODOT=/path/to/godot tools/import_evidence.sh <out-dir> [trials]
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT:-godot}"
out="$1"
trials="${2:-3}"
mkdir -p "$out"
"$godot" --version > "$out/godot-version.txt"

trial() { # trial <name>
	"$godot" --headless --path "$root/project" --import > "$out/$1.stdout" 2> "$out/$1.stderr"
	code=$?
	echo "$code" > "$out/$1.exit"
	echo "$1 exit=$code stderr_bytes=$(wc -c < "$out/$1.stderr")"
}

i=1
while [ "$i" -le "$trials" ]; do
	rm -rf "$root/project/.godot"
	trial "clean-unprepared-$i"
	i=$((i + 1))
done
i=1
while [ "$i" -le "$trials" ]; do
	rm -rf "$root/project/.godot"
	sh "$root/tools/prepare_project.sh"
	trial "clean-prepared-$i"
	i=$((i + 1))
done
