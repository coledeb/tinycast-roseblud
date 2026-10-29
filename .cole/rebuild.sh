#!/bin/bash
# Rebuilds HEAD as <base> + .cole/patches. The fork's own files are carried over from the current
# checkout, every patch lands as its own commit, then one commit holds .cole and the rewrites.
# <base> is a commit of sermelipharo/tinycast-space: already upstream Tinycast + .space/patches.
# With COLE_CHECK=1 (the Linux job) nothing is derived, so it only proves every patch applies.
# With COLE_REFRESH=1 (the sync) each patch is re-cut from its commit against this base.
# usage: rebuild.sh <base-sha> <subject of the final commit>
set -euo pipefail
BASE="${1:?base sha}" SUBJECT="${2:?subject}"
cd "$(git rev-parse --show-toplevel)"

# Everything that exists only in this fork and is not a patch.
OWN=(.cole FORK.md docs/plans .github/workflows/cole-sync.yml .github/workflows/cole-release.yml)
keep="$(mktemp -d)"
present=()
for path in "${OWN[@]}"; do [ -e "$path" ] && present+=("$path"); done
tar -cf "$keep/own.tar" "${present[@]}"

git checkout -q --detach "$BASE"
rm -rf .cole docs/plans
tar -xf "$keep/own.tar"
rm -rf "$keep"
echo "$BASE" > .cole/BASE

# What a patch's sources need regenerated, as .space/apply.sh does for its own patches.
derive() {
  [ "${COLE_CHECK:-}" = 1 ] && return
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

# Subject from the file name, body from the patch's row in .cole/README.md.
commit_patch() {
  local name="${1##*/}" body
  name="${name%.patch}"
  body="$(grep -F "| \`patches/$name.patch\` |" .cole/README.md | sed -E 's/^\| `[^`]+` \| (.*) \|$/\1/' || true)"
  git add -A -- . ':(exclude)'{.cole,FORK.md,docs/plans} ':(exclude,glob).github/workflows/cole-*.yml'
  git commit -q -m "tinycast-cole ${name%%-*}: $(echo "${name#*-}" | tr '-' ' ')" ${body:+-m "$body"}
}

shopt -s nullglob
for patch in .cole/patches/*.patch; do
  echo "applying ${patch##*/}"
  git apply --3way --whitespace=nowarn "$patch"
  derive
  commit_patch "$patch"
  if [ "${COLE_REFRESH:-}" = 1 ]; then
    git diff --no-color --binary --full-index HEAD~1 HEAD -- . \
      ':(exclude)Tinycast.xcodeproj' ':(exclude)Tinycast/Resources/RaycastRuntime.generated.js' > "$patch"
  fi
done

# Rewrites rather than patches: these lines are sermelipharo's, and they edit them.
# The updater, About and Changelog links read this fork's releases, signed with this fork's leaf.
{ grep -rlF --include='*.swift' 'sermelipharo/tinycast-space' Tinycast || true; } | while read -r file; do
  echo "rewriting repository in $file"
  sed -i.bak 's#sermelipharo/tinycast-space#coledeb/tinycast-space#g' "$file"
  rm -f "$file.bak"
done
FORK_LINE='> **This is a fork.** Read [FORK.md](FORK.md) first for remotes, current goal and fork decisions.'
if ! grep -qxF "$FORK_LINE" AGENTS.md; then
  { head -n 2 AGENTS.md; printf '%s\n\n' "$FORK_LINE"; tail -n +3 AGENTS.md; } > AGENTS.md.new
  mv AGENTS.md.new AGENTS.md
fi

git add -A
git commit -q -m "$SUBJECT" -m "This fork's .cole, FORK.md and rewrites; each patch is its own commit below."
