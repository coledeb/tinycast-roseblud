#!/bin/bash
# One open issue per blocked kind: `report.sh open <kind> <title> [<details>]` creates or comments,
# `report.sh close <kind>` closes it once a run goes through again. The title names the base and main
# it failed on, and the sync skips that exact combination until something changes.
set -euo pipefail
action="$1" kind="$2" label="roseblud-$2"
run="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
gh label create "$label" --color d93f0b --description "tinycast-roseblud automation" --force > /dev/null
num=$(gh issue list --label "$label" --state open --json number -q '.[0].number // empty')
if [ "$action" = open ]; then
  title="$3" details="${4:-}"
  body="$title — see [the run log]($run). Nothing was published; \`main\` and the releases stay as they were until the patch in \`.roseblud/patches\` is fixed."
  [ -n "$details" ] && [ -s "$details" ] && body="$body"$'\n\n```\n'"$(tail -n 60 "$details")"$'\n```'
  if [ -n "$num" ]; then
    gh issue edit "$num" --title "$title" > /dev/null
    gh issue comment "$num" --body "$body"
  else
    gh issue create --title "$title" --label "$label" --body "$body"
  fi
elif [ -n "$num" ]; then
  gh issue close "$num" --comment "Went through in [this run]($run)."
fi
