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

case "$platform" in
	linux)
		preset="Linux"
		binary="$out/dagon.x86_64"
		library="$out/libdagon.linux.template_release.x86_64.so"
		;;
	windows)
		preset="Windows"
		binary="$out/dagon.exe"
		library="$out/dagon.windows.template_release.x86_64.dll"
		;;
	*)
		echo "Unknown platform: $platform" >&2
		exit 2
		;;
esac

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
[ -f "$out/dagon.pck" ] || fail "no dagon.pck"
if grep -aq "tests/run_tests" "$out/dagon.pck"; then
	fail "tests were exported into dagon.pck"
fi
echo "export-$platform: created"
ls -la "$out"

host_can_run=no
case "$(uname -s)" in
	Linux) [ "$platform" = "linux" ] && host_can_run=yes ;;
	MINGW* | MSYS* | CYGWIN*) [ "$platform" = "windows" ] && host_can_run=yes ;;
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
grep -h "dagon: extension initialized" "$logs/run-$platform.all" | sort -u
echo "export-$platform: ran exit=0"
