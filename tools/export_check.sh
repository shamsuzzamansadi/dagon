#!/usr/bin/env sh
# Creates a release export and, when the host can run it, runs it headless and
# looks for positive proof that the release extension library loaded.
# Usage: GODOT=/path/to/godot tools/export_check.sh <linux|windows> [log-dir]
# Run the import first (tools/run_godot_checks.sh).
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT:-godot}"
platform="$1"
logs="${2:-$root/build/logs/export}"
mkdir -p "$logs"
logs="$(cd "$logs" && pwd)"
out="$root/build/export/$platform"
rm -rf "$out"
mkdir -p "$out"

# The scene the game must start in.
scene="res://scenes/level/shore.tscn"
stem="dagon"
case "$platform" in
	linux)
		preset="Linux"
		suffix=".x86_64"
		library="libdagon.linux.template_release.x86_64.so"
		;;
	windows)
		preset="Windows"
		suffix=".exe"
		library="dagon.windows.template_release.x86_64.dll"
		;;
	*)
		echo "Unknown platform: $platform" >&2
		exit 2
		;;
esac
binary="$out/$stem$suffix"
library="$out/$library"

fail() {
	echo "export-$platform: FAILED: $1"
	exit 1
}

"$godot" --headless --path "$root/project" --export-release "$preset" "$binary" \
	> "$logs/export-$platform.stdout" 2> "$logs/export-$platform.stderr"
code=$?
echo "$code" > "$logs/export-$platform.exit"
[ "$code" -eq 0 ] || fail "export exit=$code"
[ -f "$binary" ] || fail "no binary at $binary"
[ -f "$library" ] || fail "extension library not bundled: $library"
pack="$out/$stem.pck"
[ -f "$pack" ] || fail "no $stem.pck"
if grep -aq "tests/run_tests" "$pack"; then
	fail "tests were exported into $stem.pck"
fi
if grep -aq "scenes/level/level\.tscn" "$pack"; then
	fail "the greybox development scene was exported into $stem.pck"
fi
grep -aq "assets/shore/" "$pack" || fail "the Shore art is missing from $stem.pck"
echo "export-$platform: created"
ls -la "$out"

host_can_run=no
case "$(uname -s)" in
	Linux) case "$platform" in linux*) host_can_run=yes ;; esac ;;
	MINGW* | MSYS* | CYGWIN*) case "$platform" in windows*) host_can_run=yes ;; esac ;;
esac
if [ "$host_can_run" = "no" ]; then
	echo "export-$platform: NOT RUN on this host"
	exit 0
fi

log_path="$logs/run-$platform.log"
log_arg="$log_path"
if command -v cygpath > /dev/null 2>&1; then
	log_arg="$(cygpath -w "$log_path")"
fi
rm -f "$log_path"
"$binary" --headless --verbose --quit-after 300 --log-file "$log_arg" \
	> "$logs/run-$platform.stdout" 2> "$logs/run-$platform.stderr"
code=$?
echo "$code" > "$logs/run-$platform.exit"
[ "$code" -eq 0 ] || fail "exported game exit=$code"

cat "$logs/run-$platform.stdout" "$logs/run-$platform.stderr" "$log_path" > "$logs/run-$platform.all" 2> /dev/null
if grep -E "^(ERROR|SCRIPT ERROR|USER ERROR)|Cannot get class" "$logs/run-$platform.all" > "$logs/run-$platform.errors"; then
	fail "ERROR lines in the exported game's output"
fi
grep -q "dagon: extension initialized build=release" "$logs/run-$platform.all" || fail "no proof that the release library loaded"
grep -q "Completed load for: '$scene'" "$logs/run-$platform.all" || fail "it did not start in $scene"
grep -h "dagon: extension initialized" "$logs/run-$platform.all" | sort -u
echo "export-$platform: ran exit=0"
