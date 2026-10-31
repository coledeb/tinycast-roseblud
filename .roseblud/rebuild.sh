#!/bin/bash
# Rebuilds HEAD as <base> + .roseblud/patches. The fork's own files are carried over from the current
# checkout, every patch lands as its own commit, then one commit holds .roseblud and the rewrites.
# <base> is a commit of sermelipharo/tinycast-space: already upstream Tinycast + .space/patches.
# With ROSEBLUD_CHECK=1 (the Linux job) nothing is derived, so it only proves every patch applies.
# With ROSEBLUD_REFRESH=1 (the sync) each patch is re-cut from its commit against this base.
# usage: rebuild.sh <base-sha> <subject of the final commit>
set -euo pipefail
BASE="${1:?base sha}" SUBJECT="${2:?subject}"
cd "$(git rev-parse --show-toplevel)"

# Everything that exists only in this fork and is not a patch.
OWN=(.roseblud docs/plans .github/workflows/roseblud-sync.yml .github/workflows/roseblud-release.yml)
keep="$(mktemp -d)"
present=()
for path in "${OWN[@]}"; do [ -e "$path" ] && present+=("$path"); done
tar -cf "$keep/own.tar" "${present[@]}"

git checkout -q --detach "$BASE"
rm -rf .roseblud docs/plans
tar -xf "$keep/own.tar"
rm -rf "$keep"
echo "$BASE" > .roseblud/BASE

# What a patch's sources need regenerated, as .space/apply.sh does for its own patches.
derive() {
  [ "${ROSEBLUD_CHECK:-}" = 1 ] && return
  if ! git diff --quiet HEAD -- Scripts/raycast-runtime/src; then
    echo "rebuilding the extension runtime bundle"
    (cd Scripts/raycast-runtime && npx --yes pnpm@10 install --frozen-lockfile --silent && node build.mjs)
  fi
  if [ -n "$(git status --porcelain --untracked-files=all -- Tinycast | grep -E '^(\?\?|A ) ')" ]; then
    command -v xcodegen > /dev/null || brew install --quiet xcodegen
    echo "regenerating the Xcode project for added sources"
    xcodegen generate --quiet
  fi
}

# Subject from the file name, body from the patch's row in .roseblud/README.md.
commit_patch() {
  local name="${1##*/}" body
  name="${name%.patch}"
  body="$(grep -F "| \`patches/$name.patch\` |" .roseblud/README.md | sed -E 's/^\| `[^`]+` \| (.*) \|$/\1/' || true)"
  git add -A -- . ':(exclude)'{.roseblud,docs/plans} ':(exclude,glob).github/workflows/roseblud-*.yml'
  git commit -q -m "tinycast-roseblud ${name%%-*}: $(echo "${name#*-}" | tr '-' ' ')" ${body:+-m "$body"}
}

shopt -s nullglob
for patch in .roseblud/patches/*.patch; do
  echo "applying ${patch##*/}"
  git apply --3way --whitespace=nowarn "$patch"
  derive
  commit_patch "$patch"
  if [ "${ROSEBLUD_REFRESH:-}" = 1 ]; then
    git diff --no-color --binary --full-index HEAD~1 HEAD -- . \
      ':(exclude)Tinycast.xcodeproj' ':(exclude)Tinycast/Resources/RaycastRuntime.generated.js' > "$patch"
  fi
done

# Rewrites rather than patches: these lines are sermelipharo's, and they edit them.
# The updater, About and Changelog links read this fork's releases, signed with this fork's leaf.
{ grep -rlF --include='*.swift' 'sermelipharo/tinycast-space' Tinycast || true; } | while read -r file; do
  echo "rewriting repository in $file"
  sed -i.bak 's#sermelipharo/tinycast-space#coledeb/tinycast-roseblud#g' "$file"
  rm -f "$file.bak"
done
if [ -f Tinycast/Windows/About/AboutView.swift ]; then
  sed -i.bak 's/"✨ Space Edition"/"🌹 Roseblud Edition"/; s/Space Edition"/Roseblud Edition"/g' \
    Tinycast/Windows/About/AboutView.swift
  rm -f Tinycast/Windows/About/AboutView.swift.bak
fi
# The README: this fork's intro and CHANGES.md on top of sermelipharo's, whose links point here.
if [ -f README.md ]; then
  grep -qxF '<!-- roseblud:changes -->' .roseblud/README.intro.md || {
    echo "README.intro.md lost its changes marker" >&2
    exit 1
  }
  perl -pi -e 's#sermelipharo/tinycast-space/(releases|issues)#coledeb/tinycast-roseblud/$1#g' README.md
  {
    awk -v changes=.roseblud/CHANGES.md \
      '$0 == "<!-- roseblud:changes -->" { while ((getline line < changes) > 0) print line; next } { print }' \
      .roseblud/README.intro.md
    cat README.md
  } > README.md.new
  mv README.md.new README.md
fi
# The launcher's prompt in Raycast's brighter grey; fails loudly once upstream reshapes those lines.
perl -0pi -e 's/(Text\(searchPrompt\)\s*\n\s*\.font\(metrics\.typography\.searchField\)\s*\n\s*\.foregroundStyle\(Theme\.Colors\.)textTertiary\)/${1}textSecondary)/ or die "search prompt colour not found\n"' \
  Tinycast/Palette/RootPaletteView.swift

git add -A
git commit -q -m "$SUBJECT" -m "This fork's .roseblud and rewrites; each patch is its own commit below."
