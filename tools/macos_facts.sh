#!/usr/bin/env sh
# Describes the macOS app CI built, from the app itself and the Mac that built it: its architectures, the minimum macOS
# it asks for, how it is signed, and what Gatekeeper and notarization say. One fact a line, as
# "MACOS_FACT <name>: <value>", which the release's provenance and notes quote (D128). Facts only: it judges nothing,
# and the package's smoke test is what fails on a broken signature.
# Usage: tools/macos_facts.sh <folder holding the unpacked app> <out file>
set -u
dir="$1"
out="$2"
app="$(find "$dir" -maxdepth 1 -name '*.app' -type d)"
if [ -z "$app" ]; then
	echo "no app in $dir" >&2
	exit 1
fi
plist="$app/Contents/Info.plist"
executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
binary="$app/Contents/MacOS/$executable"
library="$(find "$app/Contents" -name 'libdagon.macos.template_release.arm64.dylib' | head -n 1)"

: > "$out"
fact() {
	printf 'MACOS_FACT %s: %s\n' "$1" "$2" >> "$out"
}
minos() {
	vtool -show-build "$1" 2> /dev/null | awk '$1 == "minos" { print $2; exit }'
}
one_line() {
	tr '\n' ' ' | sed 's/  */ /g; s/ *$//'
}

fact "App" "$(basename "$app")"
fact "Bundle identifier" "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")"
fact "Architectures, game" "$(lipo -archs "$binary")"
fact "Architectures, extension" "$(lipo -archs "$library")"
fact "Minimum macOS, Info.plist" "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$plist" 2> /dev/null || echo none)"
fact "Minimum macOS, game executable" "$(minos "$binary")"
fact "Minimum macOS, extension" "$(minos "$library")"
fact "Built on" "macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion)), $(uname -m)"
fact "Xcode" "$(xcodebuild -version | one_line)"
fact "macOS SDK" "$(xcrun --show-sdk-version)"
fact "Signature" "$(codesign -dv "$app" 2>&1 | grep -E '^(Signature|TeamIdentifier)=' | one_line)"
if codesign --verify --deep --strict "$app" 2> /dev/null; then
	fact "Signature check" "codesign --verify --deep --strict: valid"
else
	fact "Signature check" "codesign --verify --deep --strict: not valid"
fi
fact "Gatekeeper" "$(spctl --assess --type execute -vv "$app" 2>&1 | one_line)"
fact "Notarization" "$(xcrun stapler validate "$app" 2>&1 | one_line)"
cat "$out"
