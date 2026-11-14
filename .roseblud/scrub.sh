#!/bin/bash
# Keeps this fork's pushes from touching other repositories' issues. GitHub turns `#123`, `GH-123`,
# `owner/repo#123` and issue / PR URLs in a commit message into a "referenced this issue" event on
# that issue, under the name of whoever pushed the commit, once per new commit SHA. sermelipharo's
# commits cite upstream issues, and every rebuild re-pushes them with new SHAs, so each sync would
# post again on abue-ammar/tinycast's issues (abue-ammar/tinycast issue 1594, 2026-11-05).
#
# usage: scrub.sh            rewrites every commit in HEAD that is not in upstream's main, then checks
#        scrub.sh --check [<range>]   only checks (default range: upstream's main..HEAD)
# The rewrite keeps trees, authors and dates; only messages (and so SHAs) change.
set -euo pipefail
UPSTREAM=https://github.com/abue-ammar/tinycast.git
cd "$(git rev-parse --show-toplevel)"

# The words stay readable ("issue 1594"); only the link syntax goes.
FILTER='
  s{https?://(?:www\.)?github\.com/([\w.-]+/[\w.-]+)/issues/(\d+)\S*}{$1 issue $2}gi;
  s{https?://(?:www\.)?github\.com/([\w.-]+/[\w.-]+)/pull/(\d+)\S*}{$1 PR $2}gi;
  s{https?://(?:www\.)?github\.com/([\w.-]+/[\w.-]+)/discussions/(\d+)\S*}{$1 discussion $2}gi;
  s{\b([\w.-]+/[\w.-]+)#(\d+)\b}{$1 issue $2}g;
  s{\b([\w-]+)#(\d+)\b}{$1 issue $2}g;
  s{(?<![\w&])#(\d+)\b}{issue $1}g;
  s{\bGH-(\d+)\b}{issue $1}gi;
'
LEFT='github\.com/[^[:space:]]+/(issues|pull|discussions)/[0-9]|(^|[^[:alnum:]_&])#[0-9]|[^[:space:]]#[0-9]|GH-[0-9]'

boundary() {
  git fetch -q --no-tags "$UPSTREAM" +main:refs/roseblud/upstream
  git merge-base HEAD refs/roseblud/upstream
}

check() {
  local range="$1" found
  found="$(git log --format='%h %s%n%b' "$range" | grep -nEi "$LEFT" || true)"
  [ -z "$found" ] && return 0
  echo "commit messages in $range still reference issues; GitHub would post on them:" >&2
  echo "$found" >&2
  exit 1
}

if [ "${1:-}" = --check ]; then
  check "${2:-$(boundary)..HEAD}"
  exit 0
fi

git diff --quiet HEAD && git diff --cached --quiet || { echo "scrub.sh needs a clean tree" >&2; exit 1; }
FROM="$(boundary)"
export FILTER
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'perl -pe "$FILTER"' -- "$FROM..HEAD" > /dev/null
git for-each-ref --format='%(refname)' refs/original | xargs -r -n1 git update-ref -d
check "$FROM..HEAD"
echo "commit messages since ${FROM:0:7} carry no issue references"
