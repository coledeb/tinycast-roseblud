#!/bin/bash
# Prints a release's notes: this fork's changes, then sermelipharo's notes for <tag>, or upstream's
# while their release of it is blocked. The closing marker says which, so roseblud-release.yml can
# refresh the notes once theirs exist.
# usage: notes.sh <tag>   (CHANGES= overrides .roseblud/CHANGES.md; needs GH_TOKEN)
set -euo pipefail
TAG="${1:?tag}" VERSION="${1#v}"
BASE_REPO_NAME=sermelipharo/tinycast-space UPSTREAM_REPO=abue-ammar/tinycast
REPO="${GITHUB_REPOSITORY:-coledeb/tinycast-roseblud}"
cd "$(git rev-parse --show-toplevel)"
CHANGES="${CHANGES:-.roseblud/CHANGES.md}"

if BODY="$(gh release view "$TAG" -R "$BASE_REPO_NAME" --json body -q .body 2> /dev/null)"; then
  FROM="$BASE_REPO_NAME"
  SOURCE="[Tinycast $VERSION · Space Edition](https://github.com/$BASE_REPO_NAME/releases/tag/$TAG) rebuilt with"
else
  FROM="$UPSTREAM_REPO"
  SOURCE="Upstream [Tinycast $VERSION](https://github.com/$UPSTREAM_REPO/releases/tag/$TAG) with sermelipharo's [\`.space/patches\`](https://github.com/$BASE_REPO_NAME/tree/main/.space/patches) (their release of it is blocked) and"
  # Bare #123 would resolve against this repository, so it points at upstream, as sermelipharo does.
  BODY="$(gh release view "$TAG" -R "$UPSTREAM_REPO" --json body -q .body |
    perl -pe 's{(^|[\s(])#(\d+)\b}{$1\[#$2\](https://github.com/abue-ammar/tinycast/pull/$2)}g')"
fi

# This fork's builds are self-signed, so upstream's Developer ID / notarization entries would mislead.
BODY="$(grep -viE '^\s*[-*].*(developer id|notari[sz])' <<< "$BODY" || true)"

# This fork's own changes lead, above the install marker, so the update window shows them too.
echo "## What's new in Roseblud Edition"
echo
cat "$CHANGES"
echo
echo "$SOURCE this fork's [\`.roseblud/patches\`](https://github.com/$REPO/tree/main/.roseblud/patches)."
echo
sed '/<!-- tinycast:install -->/,$d' <<< "$BODY"
echo
echo "<!-- tinycast:install -->"
echo "Download \`Tinycast-$VERSION.dmg\`, drag Tinycast to Applications, then run \`xattr -dr com.apple.quarantine /Applications/Tinycast.app\` once — the build is self-signed. Installed copies update themselves from this repository."
echo
echo "<!-- roseblud:notes-from $FROM -->"
