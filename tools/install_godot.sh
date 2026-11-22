#!/usr/bin/env sh
# Downloads the pinned Godot editor, verifies the official SHA-512, and prints
# the path of the executable to use as $GODOT.
# Usage: tools/install_godot.sh <destination-dir>
set -eu

tag="4.7.2-stable"
dest="$1"
base="https://github.com/godotengine/godot/releases/download/${tag}"

case "$(uname -s)" in
	MINGW* | MSYS* | CYGWIN*)
		archive="Godot_v${tag}_win64.exe.zip"
		executable="Godot_v${tag}_win64_console.exe"
		;;
	Darwin)
		archive="Godot_v${tag}_macos.universal.zip"
		executable="Godot.app/Contents/MacOS/Godot"
		;;
	*)
		archive="Godot_v${tag}_linux.x86_64.zip"
		executable="Godot_v${tag}_linux.x86_64"
		;;
esac

# macOS has shasum and no sha512sum.
check_sha512() {
	if command -v sha512sum > /dev/null 2>&1; then sha512sum -c -; else shasum -a 512 -c -; fi
}

mkdir -p "$dest"
if [ ! -x "${dest}/${executable}" ]; then
	download_dir="$(mktemp -d)"
	trap 'rm -rf "$download_dir"' EXIT
	curl -fsSL --retry 3 -o "${download_dir}/${archive}" "${base}/${archive}"
	curl -fsSL --retry 3 -o "${download_dir}/SHA512-SUMS.txt" "${base}/SHA512-SUMS.txt"
	(cd "$download_dir" && grep " ${archive}\$" SHA512-SUMS.txt | check_sha512 >&2)
	unzip -qo "${download_dir}/${archive}" -d "$dest"
	chmod +x "${dest}/${executable}"
fi
echo "${dest}/${executable}"
