#!/usr/bin/env sh
# Downloads the Godot export templates, verifies the official SHA-512, and
# installs only the desktop templates this project exports with.
# Usage: tools/install_export_templates.sh
set -eu

version="4.7.2"
tag="${version}-stable"
archive="Godot_v${tag}_export_templates.tpz"
base="https://github.com/godotengine/godot/releases/download/${tag}"

case "$(uname -s)" in
	MINGW* | MSYS* | CYGWIN*) dest="${APPDATA}/Godot/export_templates/${version}.stable" ;;
	*) dest="${HOME}/.local/share/godot/export_templates/${version}.stable" ;;
esac

python_bin="$(command -v python || command -v python3)"
script_dir="$(cd "$(dirname "$0")" && pwd)"

download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT

echo "Downloading ${archive}"
curl -fsSL --retry 3 -o "${download_dir}/${archive}" "${base}/${archive}"
curl -fsSL --retry 3 -o "${download_dir}/SHA512-SUMS.txt" "${base}/SHA512-SUMS.txt"

(cd "$download_dir" && grep " ${archive}\$" SHA512-SUMS.txt | sha512sum -c -)

"$python_bin" -I "${script_dir}/extract_templates.py" "${download_dir}/${archive}" "$dest"
echo "Installed to ${dest}"
ls -la "$dest"
