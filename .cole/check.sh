#!/bin/bash
# Dry-runs this checkout's .cole/patches on a throwaway worktree of <base> (default: sermelipharo's
# current main), so a patch can be checked before it is pushed. Leaves the checkout untouched.
# usage: check.sh [<base-sha>]
set -euo pipefail
REMOTE=https://github.com/sermelipharo/tinycast-space.git
SRC="$(git rev-parse --show-toplevel)"
cd "$SRC"
BASE="${1:-$(git ls-remote "$REMOTE" refs/heads/main | cut -f1)}"
git cat-file -e "$BASE^{commit}" 2> /dev/null || git fetch -q --no-tags "$REMOTE" main
export GIT_AUTHOR_NAME=check GIT_AUTHOR_EMAIL=check@localhost
export GIT_COMMITTER_NAME=check GIT_COMMITTER_EMAIL=check@localhost

WT="$(mktemp -d)"
git worktree add -q --detach "$WT" HEAD
trap 'git -C "$SRC" worktree remove --force "$WT"' EXIT
own=(.cole FORK.md .github/workflows/cole-*.yml)
[ -d docs/plans ] && own+=(docs/plans)
tar -cf - "${own[@]}" | tar -xf - -C "$WT"
cd "$WT"
# rebuild.sh carries the fork's files over from a clean checkout, as on CI.
git add -A && git commit -qm check --allow-empty --no-verify
COLE_CHECK=1 .cole/rebuild.sh "$BASE" check
echo "every patch in .cole/patches applies on ${BASE:0:7}"
