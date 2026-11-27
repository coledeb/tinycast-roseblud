#!/bin/bash
# Prints a release's notes: this fork's changes since its previous release (CHANGES.md entries added or
# reworded since that release's CHANGES.md, with the whole list folded below), then sermelipharo's notes for <tag>, or upstream's
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

# The previous release here: the highest released vX.Y.Z below this tag. Its CHANGES.md is read from its
# tag, so entries it already listed are not announced again.
PREV="$(gh release list -R "$REPO" -L 100 --json tagName -q '.[].tagName' |
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | { cat; echo "$TAG"; } | sort -uV | grep -B1 -xF "$TAG" | grep -vxF "$TAG" || true)"
PREV_CHANGES="$(mktemp)"
trap 'rm -f "$PREV_CHANGES"' EXIT
[ -n "$PREV" ] && gh api -H "Accept: application/vnd.github.raw" \
  "repos/$REPO/contents/.roseblud/CHANGES.md?ref=$PREV" > "$PREV_CHANGES" 2> /dev/null || : > "$PREV_CHANGES"

# CHANGES.md entries (a "- " line and its indented continuation lines) not in the previous one, verbatim.
NEW="$(awk '
  function flush() { if (entry != "" && !(FILENAME_OF_ENTRY == 2 && (norm in seen))) { if (FILENAME_OF_ENTRY == 1) seen[norm] = 1; else printf "%s", entry } entry = ""; norm = "" }
  FNR == 1 { flush(); file++ }
  /^- / { flush(); FILENAME_OF_ENTRY = file }
  entry != "" || /^- / { entry = entry $0 "\n"; line = $0; gsub(/[ \t]+/, " ", line); sub(/^ /, "", line); norm = norm " " line }
  END { flush() }
' "$PREV_CHANGES" "$CHANGES")"

# This fork's own changes lead, above sermelipharo's notes.
echo "## What's new in Roseblud Edition"
echo
if [ ! -s "$PREV_CHANGES" ]; then
  cat "$CHANGES"
else
  if [ -n "$NEW" ]; then
    echo "Since [$PREV](https://github.com/$REPO/releases/tag/$PREV):"
    echo
    echo "$NEW"
  else
    echo "Nothing new from this fork since [$PREV](https://github.com/$REPO/releases/tag/$PREV); this release brings the changes below."
  fi
  echo
  echo "<details>"
  echo "<summary>Everything Roseblud Edition adds</summary>"
  echo
  cat "$CHANGES"
  echo
  echo "</details>"
fi
echo
echo "$SOURCE this fork's [\`.roseblud/patches\`](https://github.com/$REPO/tree/main/.roseblud/patches)."
echo
sed '/<!-- tinycast:install -->/,$d' <<< "$BODY"
echo
echo "<!-- tinycast:install -->"
echo "Download \`Tinycast-$VERSION.dmg\`, drag Tinycast to Applications, then run \`xattr -dr com.apple.quarantine /Applications/Tinycast.app\` once — the build is self-signed. Installed copies update themselves from this repository."
echo
echo "<!-- roseblud:notes-from $FROM -->"
