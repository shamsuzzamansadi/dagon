#!/usr/bin/env sh
# Publishes one prepared prerelease. Usage: tools/publish_release.sh <version> <commit> <prepared-dir>
# Runs inside the workflow's publication lock, with its own GITHUB_TOKEN. It never moves or replaces a tag or a
# published release. The release stays a draft until its uploaded files are checked, and the tag only appears
# when it is published, so a failure part way publishes nothing and uses up no version.
set -eu
version="$1"
commit="$2"
prepared="$3"

fail() {
	echo "::error::$version was not published: $1"
	exit 1
}

if [ -n "$(git ls-remote --tags origin "refs/tags/$version")" ]; then
	fail "the tag already exists. A release is never replaced: use a new version."
fi
draft="$(gh release view "$version" --json isDraft --jq .isDraft 2> /dev/null || echo none)"
case "$draft" in
	false) fail "a published release already has this version. A release is never replaced: use a new version." ;;
	true)
		echo "Removing an unpublished draft left by a failed attempt."
		gh release delete "$version" --yes
		;;
esac

gh release create "$version" --draft --prerelease --target "$commit" \
	--title "$(cat "$prepared/TITLE.txt")" --notes-file "$prepared/RELEASE_NOTES.md" \
	"$prepared"/dagon-* "$prepared/SHA256SUMS.txt" "$prepared/PROVENANCE.txt"

check="$(mktemp -d)"
gh release download "$version" --dir "$check"
(cd "$check" && sha256sum -c --quiet SHA256SUMS.txt) || fail "an uploaded file does not match its checksum. It stays an unpublished draft."

gh release edit "$version" --draft=false --prerelease

tagged="$(git ls-remote --tags origin "refs/tags/$version" | cut -f1)"
[ "$tagged" = "$commit" ] || fail "the published tag points at '$tagged', not the tested commit $commit. Investigate before anything else."
gh release view "$version" --json url,isPrerelease,isDraft --jq '"published \(.url) prerelease=\(.isPrerelease) draft=\(.isDraft)"'
