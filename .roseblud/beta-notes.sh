#!/bin/bash
# Prints a beta release's notes, laid out like upstream's beta notes: upstream's "What's Changed" for
# the same tag, then an install block with the channel, version, bundle id and commit, as upstream's does.
# usage: beta-notes.sh <tag> <commit>   (needs GH_TOKEN)
set -euo pipefail
TAG="${1:?tag}" SHA="${2:?commit}" VERSION="${1#v}"
UPSTREAM_REPO=abue-ammar/tinycast
REPO="${GITHUB_REPOSITORY:-coledeb/tinycast-roseblud}"
cd "$(git rev-parse --show-toplevel)"

# Bare #123 would resolve against this repository, so it points at upstream, as notes.sh does.
BODY="$(gh release view "$TAG" -R "$UPSTREAM_REPO" --json body -q .body |
  perl -pe 's{(^|[\s(])#(\d+)\b}{$1\[#$2\](https://github.com/abue-ammar/tinycast/pull/$2)}g')"
# This fork's builds are self-signed, so upstream's Developer ID / notarization entries would mislead.
BODY="$(sed '/<!-- tinycast:install -->/,$d' <<< "$BODY" | { grep -viE '^\s*[-*].*(developer id|notari[sz])' || true; })"

{
  echo "Beta of [Tinycast Roseblud Edition](https://github.com/$REPO#what-roseblud-adds): this fork's \`main\`,"
  echo "which already carries upstream [Tinycast Beta $VERSION](https://github.com/$UPSTREAM_REPO/releases/tag/$TAG),"
  echo "with sermelipharo's [\`.space/patches\`](https://github.com/sermelipharo/tinycast-space/tree/main/.space/patches)"
  echo "and this fork's [\`.roseblud/patches\`](https://github.com/$REPO/tree/main/.roseblud/patches) on top."
  echo
  echo "$BODY"
  echo
  echo "<!-- tinycast:install -->"
  echo
  echo "**Channel:** beta · **Version:** $VERSION · **Bundle ID:** \`com.tinycast.app\`"
  echo "Built from $SHA."
  echo
  echo "Already on Roseblud Edition? Settings → About → *Update Channel* → *Beta*, and it updates itself to"
  echo "each beta and to any newer release. Otherwise download \`Tinycast-$VERSION.dmg\`, drag Tinycast to"
  echo "Applications, then run \`xattr -dr com.apple.quarantine /Applications/Tinycast.app\` once — the build"
  echo "is self-signed. Betas share your data and settings with the stable app."
  echo
  echo "<!-- roseblud:notes-from $UPSTREAM_REPO -->"
}
