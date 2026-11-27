#!/usr/bin/env sh
# Publishes v0.2.0-alpha.2 by hand, as the owner chose on 2026-11-27, after CI's publish job in run 46036924022 was
# refused by GitHub (HTTP 403, "Resource not accessible by integration") while creating the draft. The same steps as
# tools/publish_release.sh, in the same order, on the files that run prepared, with the owner's gh login (to which the
# owner added the workflow scope). Never moves, replaces or deletes a tag or a published release.
# Run from the clone, on main: sh ~/work/dagon-m6/bin/publish-by-hand-v0.2.0-alpha.2.sh
set -eu
version=v0.2.0-alpha.2
commit=b271316371532074eb2c5fb312afa7c0a2d822c4
prepared="$HOME/work/dagon-m6/prepared-404ee5e/dl"
prepared_by="https://github.com/shamsuzzamansadi/dagon/actions/runs/46036924022"
export GITHUB_REPOSITORY=shamsuzzamansadi/dagon
GH_TOKEN="$(gh auth token)"
export GH_TOKEN

fail() {
	echo "ERROR: $version: $1"
	exit 1
}

# The archives the owner tested, from artifact 14761047666, and nothing else.
(cd "$prepared" && sha256sum -c --quiet - <<EOF
f76538cc776603806010824ab93f0fb0424a5f90184fd0854af2b98eefd34148  dagon-v0.2.0-alpha.2-windows-x86_64.zip
6631c21b3d79b3cf1eb3305d9c622e230e59deaddcf160f5b24150c922680e05  dagon-v0.2.0-alpha.2-linux-x86_64.tar.gz
9daca1d1f76982248a8ba91029c0dca99cfc8fee3387d411063a09a933cb5586  dagon-v0.2.0-alpha.2-macos-arm64.zip
EOF
) || fail "the prepared archives are not the ones the owner tested; nothing was created"
(cd "$prepared" && sha256sum -c --quiet SHA256SUMS.txt) || fail "the prepared files do not match their checksums; nothing was created"

decision="$(python3 tools/release_gate.py preflight --version "$version")"
[ "$decision" = create ] || fail "the preflight did not decide to create: '$decision'"

gh release create "$version" --draft --prerelease --target "$commit" \
	--title "$(cat "$prepared/TITLE.txt")" --notes-file "$prepared/RELEASE_NOTES.md" \
	"$prepared"/dagon-* "$prepared/SHA256SUMS.txt" "$prepared/PROVENANCE.txt"
echo "$version: draft created"

check="$(mktemp -d "$HOME/work/dagon-m6/publish-check.XXXXXX")"
gh release download "$version" --dir "$check"
(cd "$check" && sha256sum -c --quiet SHA256SUMS.txt) || fail "an uploaded file does not match its checksum. It stays an unpublished draft."
echo "$version: the draft's files match their checksums"

gh release edit "$version" --draft=false --prerelease
python3 tools/release_gate.py verify --version "$version" --commit "$commit"

published="$(gh release view "$version" --json isDraft,publishedAt --jq 'if .isDraft then "" else .publishedAt end')"
[ -n "$published" ] || fail "GitHub does not report it published, so its notes name no publication"
notes="$check/RELEASE_NOTES.md"
cp "$prepared/RELEASE_NOTES.md" "$notes"
printf -- '- Published by hand, with the owner'"'"'s GitHub login, from the files CI run %s prepared, after that run'"'"'s own publish job was refused by GitHub (HTTP 403); GitHub reports it published at %s\n' "$prepared_by" "$published" >> "$notes"
gh release edit "$version" --notes-file "$notes"
echo "$version: published; GitHub reports it published at $published"
