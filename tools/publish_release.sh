#!/usr/bin/env sh
# Publishes one prepared prerelease. Usage: tools/publish_release.sh <version> <commit> <prepared-dir>
# Runs inside the workflow's publication lock, with its own GITHUB_TOKEN. It never moves or replaces a tag or a
# published release. The release stays a draft until its uploaded files are checked, and the tag only appears
# when it is published, so a failure part way publishes nothing and uses up no version. If the state of the release
# cannot be determined, the preflight fails and this stops.
set -eu
version="$1"
commit="$2"
prepared="$3"

fail() {
	echo "::error::$version was not published: $1"
	exit 1
}

decision="$(python tools/release_gate.py preflight --version "$version")"
case "$decision" in
	create) ;;
	skip) exit 0 ;;
	*) fail "the preflight gave no decision: '$decision'" ;;
esac

gh release create "$version" --draft --prerelease --target "$commit" \
	--title "$(cat "$prepared/TITLE.txt")" --notes-file "$prepared/RELEASE_NOTES.md" \
	"$prepared"/dagon-* "$prepared/SHA256SUMS.txt" "$prepared/PROVENANCE.txt"

check="$(mktemp -d)"
gh release download "$version" --dir "$check"
(cd "$check" && sha256sum -c --quiet SHA256SUMS.txt) || fail "an uploaded file does not match its checksum. It stays an unpublished draft."

gh release edit "$version" --draft=false --prerelease

python tools/release_gate.py verify --version "$version" --commit "$commit"

# Only now, with GitHub reporting the release published, complete and consistent, do its notes name the run that
# published it (D132). Immutable releases lock its files and its tag, not its notes: nothing uploaded changes.
published="$(gh release view "$version" --json isDraft,publishedAt --jq 'if .isDraft then "" else .publishedAt end')"
if [ -z "$published" ]; then
	echo "::error::$version: GitHub does not report it published, so its notes name no publication run"
	exit 1
fi
run="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
notes="$check/RELEASE_NOTES.md"
cp "$prepared/RELEASE_NOTES.md" "$notes"
printf -- '- Published by CI run: %s at %s; GitHub reports it published at %s\n' "$run" "$GITHUB_SHA" "$published" >> "$notes"
gh release edit "$version" --notes-file "$notes"
echo "$version: published by $run; GitHub reports it published at $published"
