#!/bin/bash
# Release build + Scripts/run-tests.sh, stricter than sermelipharo's .space/gate.sh:
# - the runner's exit status counts: a crash, a dispatch failure or a missing summary blocks;
# - a harness that keeps failing is waived only when the same harness exists on <base> and fails
#   there too with an ordinary FAILED verdict. A harness <base> lacks (this fork's own) never is.
# usage: gate.sh <base-sha>
set -uo pipefail
UP="${1:?base sha}"
cd "$(git rev-parse --show-toplevel)"
TMP="${RUNNER_TEMP:-$(mktemp -d)}"
retries=3

echo "::group::xcodebuild"
if ! xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
  -derivedDataPath "$TMP/gate-dd" ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- build > "$TMP/gate-build.log" 2>&1; then
  echo "::endgroup::"
  grep -E 'error:' "$TMP/gate-build.log" | head -40
  tail -40 "$TMP/gate-build.log"
  echo "::error::build failed"
  exit 1
fi
echo "::endgroup::"

# Runs the suite (or one harness) in $1, logging to $2; prints the failed harness names.
# Status: 0 passed, 1 a FAILED verdict naming harnesses, 2 no such harness, 3 anything else.
suite() {
  local dir="$1" log="$2" status names
  shift 2
  (cd "$dir" && ./Scripts/run-tests.sh "$@") > "$log" 2>&1
  status=$?
  names=$(sed 's/\x1b\[[0-9;]*m//g' "$log" | sed -n 's/.*harness(es) failed in [0-9]*s: //p')
  if [ $status = 0 ] && grep -q 'harness(es) passed in' "$log"; then return 0; fi
  if [ $status = 1 ] && [ -n "$names" ]; then echo "$names"; return 1; fi
  if [ $status = 2 ] && grep -q '^No harness named' "$log"; then return 2; fi
  return 3
}

failed=$(suite . "$TMP/gate-tests.log")
status=$?
cat "$TMP/gate-tests.log"
case $status in
  0) exit 0 ;;
  1) ;;
  *)
    echo "::error::the test runner exited without a verdict (status $status); see the log above"
    exit 1
    ;;
esac

# Upstream has timing-based harnesses (fixed sleeps around async work) that miss on a loaded runner.
still=()
for t in $failed; do
  passed=0
  for _ in $(seq $retries); do suite . "$TMP/gate-retry.log" "$t" > /dev/null && { passed=1; break; }; done
  [ $passed = 1 ] && echo "::warning::$t is flaky: failed in the full run, passed on a retry" || still+=("$t")
done
[ ${#still[@]} -eq 0 ] && exit 0

wt="$TMP/gate-upstream"
git worktree add --force --detach "$wt" "$UP" > /dev/null
# Judge <base> with this fork's runner: <base>'s own may lack its fixes (0106: a crash there gave
# no verdict, so a harness crashing on both sides could never be waived).
cp Scripts/run-tests.sh "$wt/Scripts/run-tests.sh"
regressions=()
for t in "${still[@]}"; do
  verdict=pass
  for _ in $(seq $retries); do
    suite "$wt" "$TMP/gate-base.log" "$t" > /dev/null
    case $? in
      0) ;;
      1) verdict=fail; break ;;
      2) verdict=absent; break ;;
      *) verdict=unknown; break ;;
    esac
  done
  case $verdict in
    fail) echo "::warning::$t fails on ${UP:0:7} too — not ours, ignored" ;;
    absent) echo "::error::$t exists only in this fork and fails" && regressions+=("$t") ;;
    unknown) echo "::error::$t gave no verdict on ${UP:0:7}, so its failure here can't be waived" && regressions+=("$t") ;;
    *) regressions+=("$t") ;;
  esac
done
git worktree remove --force "$wt"
[ ${#regressions[@]} -eq 0 ] && exit 0
echo "::error::the patches break: ${regressions[*]}"
exit 1
