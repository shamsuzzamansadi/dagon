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
. "$root/tools/test_storage.sh"

# The scene the game must start in, and the world it plays in.
scene="res://scenes/ui/title.tscn"
world="res://scenes/level/shore.tscn"
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
grep -aq "assets/ui/" "$pack" || fail "the UI assets are missing from $stem.pck"
grep -aq "narration/script.txt" "$pack" || fail "the narration script is missing from $stem.pck"
grep -aq "assets/narration/" "$pack" || fail "the narration samples are missing from $stem.pck"
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

# run_exported <name> [environment assignment]: runs the exported game headless and collects its output.
run_exported() {
	name="$1"
	log_path="$logs/$name.log"
	log_arg="$log_path"
	if command -v cygpath > /dev/null 2>&1; then
		log_arg="$(cygpath -w "$log_path")"
	fi
	rm -f "$log_path"
	env DAGON_AUTOSTART="${2:-}" "$binary" --headless --verbose --quit-after 300 --log-file "$log_arg" \
		> "$logs/$name.stdout" 2> "$logs/$name.stderr"
	code=$?
	echo "$code" > "$logs/$name.exit"
	[ "$code" -eq 0 ] || fail "$name: exported game exit=$code"
	cat "$logs/$name.stdout" "$logs/$name.stderr" "$log_path" > "$logs/$name.all" 2> /dev/null
	if grep -E "^(ERROR|SCRIPT ERROR|USER ERROR)|Cannot get class" "$logs/$name.all" > "$logs/$name.errors"; then
		fail "$name: ERROR lines in the exported game's output"
	fi
}

# The exported game, with nothing done to it: it must start in the main menu.
run_exported "run-$platform"
all="$logs/run-$platform.all"
grep -q "dagon: extension initialized build=release" "$all" || fail "no proof that the release library loaded"
grep -q "Completed load for: '$scene'" "$all" || fail "it did not start in $scene"
grep -h "dagon: extension initialized" "$all" | sort -u

# New Game in the exported game. This is the build that ships, so a prompt here means the whole path works.
run_exported "run-$platform-new-game" new_game
all="$logs/run-$platform-new-game.all"
grep -q "Completed load for: '$world'" "$all" || fail "New Game did not load $world"
grep -q "dagon: session start beat=0 persisted=0" "$all" || fail "New Game did not start a session at the first checkpoint"
grep -q "dagon: introduction shown" "$all" || fail "New Game did not show the introduction"
grep -q "dagon: prompt: \[E\] Examine" "$all" || fail "the exported game showed no prompt beside the boat"
save_file="$test_storage_dir/save.dat"
grep -q "beat=shore" "$save_file" 2> /dev/null || fail "New Game wrote no save in the exported game"

# A new process, on that save: Continue in the exported game.
run_exported "run-$platform-continue" continue
all="$logs/run-$platform-continue.all"
grep -q "dagon: session start beat=0 persisted=0" "$all" || fail "Continue did not start from the save"
echo "export-$platform: new game and continue ran"

# Export rewrites scenes, so the integration tests also run on the exported pack.
pack_arg="$pack"
if command -v cygpath > /dev/null 2>&1; then
	pack_arg="$(cygpath -m "$pack")"
fi
rm -f "$test_storage_dir/save.dat" "$test_storage_dir/save.bak" "$test_storage_dir/settings.cfg"
DAGON_TEST_PACK="$pack_arg" "$godot" --headless --path "$root/project" --fixed-fps 60 --script res://tests/run_tests.gd \
	> "$logs/integration-$platform-pack.stdout" 2> "$logs/integration-$platform-pack.stderr"
code=$?
echo "$code" > "$logs/integration-$platform-pack.exit"
grep -q "^PACK mounted" "$logs/integration-$platform-pack.stdout" || fail "the exported pack was not mounted for the tests"
grep -E "^(FAIL|     |RESULT)" "$logs/integration-$platform-pack.stdout" | grep -vE "^     +\[" | head -40
[ "$code" -eq 0 ] || fail "integration tests failed on the exported pack"
grep -qE "^RESULT passed=[0-9]+ failed=0" "$logs/integration-$platform-pack.stdout" || fail "no clean result from the exported pack"
echo "export-$platform: ran exit=0"
