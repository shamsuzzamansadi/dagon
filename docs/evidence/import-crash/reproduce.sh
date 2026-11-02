#!/usr/bin/env sh
# Reproduce the clean-cache headless import crash from this evidence package.
# Usage: reproduce.sh <empty-work-dir> [trials]
# Needs: git, scons 4.9.1, a C++20 compiler, and Godot 4.7.2 as $GODOT (default: godot).
# Writes per-trial stdout, stderr and exit status to <work-dir>/results/.
set -eu
work="$1"
trials="${2:-3}"
godot="${GODOT:-godot}"
here="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$work"
cp -R "$here/spike/." "$work/"
git clone -q --depth 1 --branch 10.0.0-stable https://github.com/godotengine/godot-cpp.git "$work/godot-cpp"
test "$(git -C "$work/godot-cpp" rev-parse HEAD)" = 507ed9d840c01a3c5b2a39af8bb4000bfac30bf5
(cd "$work" && scons -j"$(nproc)" platform=linux target=template_debug > build.log 2>&1)

results="$work/results"
mkdir -p "$results"
"$godot" --version > "$results/godot-version.txt"

run() { # run <name>: one clean-cache import, recording stdout, stderr and exit status
	set +e
	"$godot" --headless --path "$work/project" --import > "$results/$1.stdout" 2> "$results/$1.stderr"
	echo $? > "$results/$1.exit"
	set -e
	echo "$1 exit=$(cat "$results/$1.exit")"
}

i=1
while [ "$i" -le "$trials" ]; do
	rm -rf "$work/project/.godot"
	run "clean-$i"
	i=$((i + 1))
done

i=1
while [ "$i" -le "$trials" ]; do
	rm -rf "$work/project/.godot"
	mkdir -p "$work/project/.godot"
	printf 'res://bin/spike.gdextension\n' > "$work/project/.godot/extension_list.cfg"
	run "preseeded-$i"
	i=$((i + 1))
done

set +e
"$godot" --headless --path "$work/project" --script res://check.gd > "$results/check.stdout" 2> "$results/check.stderr"
echo $? > "$results/check.exit"
set -e
echo "check exit=$(cat "$results/check.exit")"; grep -E "class_exists|sum_steps" "$results/check.stdout" || true
