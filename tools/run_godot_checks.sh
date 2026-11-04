#!/usr/bin/env sh
# Runs the Godot checks: clean-cache import, extension load, integration tests, smoke.
# Usage: GODOT=/path/to/godot tools/run_godot_checks.sh [log-dir]
# Each step saves <step>.stdout, <step>.stderr and <step>.exit. Any non-zero exit,
# any ERROR line, or a missing success line fails the run.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT:-godot}"
logs="${1:-$root/build/logs/godot}"
mkdir -p "$logs"
logs="$(cd "$logs" && pwd)"
failures=0
. "$root/tools/test_storage.sh"

# step <name> <required-stdout-pattern or ""> <args...>
# Errors the integration tests set out to cause. The test runner's own trap fails a test on any error it did not name.
tested_errors='^ERROR: (GameDirector: (cinematic|more than one event)|PuzzleController: a stone submitted)'
expected_errors='^$'
step() {
	name="$1"
	required="$2"
	shift 2
	"$godot" --headless --path "$root/project" "$@" > "$logs/$name.stdout" 2> "$logs/$name.stderr"
	code=$?
	echo "$code" > "$logs/$name.exit"
	result="ok"
	if [ "$code" -ne 0 ]; then
		result="FAILED exit=$code"
	elif grep -hE "^(ERROR|SCRIPT ERROR|USER ERROR)|Parse Error|Cannot get class" "$logs/$name.stdout" "$logs/$name.stderr" | grep -vE "$expected_errors" > "$logs/$name.errors"; then
		result="FAILED: ERROR lines in output"
	elif [ -n "$required" ] && ! grep -qE "$required" "$logs/$name.stdout"; then
		result="FAILED: missing '$required'"
	fi
	echo "$name: $result"
	if [ "$result" != "ok" ]; then
		failures=$((failures + 1))
	fi
}

"$godot" --version > "$logs/godot-version.txt"
echo "godot: $(cat "$logs/godot-version.txt")"

# A clean cache is what the workaround is for, and what a fresh checkout has.
rm -rf "$root/project/.godot"
sh "$root/tools/prepare_project.sh"

step import "" --import
step check_classes "^CHECK_CLASSES classes=[0-9]+ problems=0" --script res://tests/check_classes.gd
expected_errors="$tested_errors"
step integration "^RESULT passed=[0-9]+ failed=0" --fixed-fps 60 --script res://tests/run_tests.gd
expected_errors='^$'
step smoke "dagon: extension initialized" --verbose --fixed-fps 60 --quit-after 600
step smoke_greybox "dagon: extension initialized" --verbose --fixed-fps 60 --quit-after 600 res://scenes/level/level.tscn
step smoke_game "dagon: prompt: \\[E\\] Examine" --verbose --fixed-fps 60 --quit-after 600 res://scenes/level/game.tscn

grep -E "^(PASS|FAIL|     )" "$logs/integration.stdout" || true
grep -hE "^(RESULT|CHECK_CLASSES)" "$logs/check_classes.stdout" "$logs/integration.stdout" || true
grep -h "dagon: extension initialized" "$logs/smoke.stdout" || true
grep -h "Completed load for: 'res://scenes/\(ui/title\|level/level\|level/game\)" "$logs/smoke.stdout" "$logs/smoke_greybox.stdout" "$logs/smoke_game.stdout" || true

exit "$failures"
