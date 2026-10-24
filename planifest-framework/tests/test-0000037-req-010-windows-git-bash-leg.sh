#!/usr/bin/env bash
# Static tests for feature 0000037-green-ci-before-ship, req-010: Windows Git Bash leg.
#
# Verified by: integration
#
# req-010: the test-suite job adds windows-latest with shell bash (ADR-013, ADR-014).
# req-010: the job keeps fail-fast false, contents read, no secrets, and the pull_request trigger.
# req-010: the consumer workflow at planifest-framework/hooks/planifest.yml has no mention of the leg.
# req-010: the skip table in planifest-framework/tests/README.md exists with its header row.
#
# Cap rule (ADR-014): the first pass kept timeout-minutes 10. P3 measured a Git Bash
# run over 10 minutes (about 38 suites), so the job uses the expression named in
# WINDOWS_CAP_EXPR and the Windows leg is sharded four ways (second fallback).
# req-010: a test of the shard selection in run-tests.sh runs against dummy suites.
# req-010: every SKIP (windows) guard has a skip table row, and every row has a guard.
#
# No YAML library is available, so the tests extract each job block with awk and grep it.

set -uo pipefail

# A direct run may inherit a CI shard. Each check below sets its own.
unset PLANIFEST_SHARD_INDEX PLANIFEST_SHARD_COUNT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FRAMEWORK/.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/planifest.yml"
CONSUMER_WORKFLOW="$FRAMEWORK/hooks/planifest.yml"
TESTS_README="$SCRIPT_DIR/README.md"

# Set to "20" when ADR-014 decision 2 applies. Leave "10" until P3 measures.
CAP_BRANCH="20"
WINDOWS_CAP_EXPR="\\\$\\{\\{ matrix\\.os == 'windows-latest' && 20 \\|\\| 10 \\}\\}"

job_block() {
  awk -v id="  $1:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$WORKFLOW"
}

has() { grep -Eq -- "$1" <<<"$2"; }
yes_no() { if has "$1" "$2"; then echo "yes"; else echo "no"; fi; }

SUITE="$(job_block test-suite)"

echo "== req-010: matrix and shell =="
assert_equals "yes" "$([ -n "$SUITE" ] && echo yes || echo no)" "req-010: workflow has a test-suite job"
assert_equals "yes" "$(yes_no 'os:.*windows-latest' "$SUITE")" "req-010: matrix os holds windows-latest"
assert_equals "yes" "$(yes_no 'os:.*ubuntu-latest' "$SUITE")" "req-010: matrix os still holds ubuntu-latest"
assert_equals "yes" "$(yes_no 'os:.*macos-latest' "$SUITE")" "req-010: matrix os still holds macos-latest"
assert_equals "yes" "$(yes_no 'shell:[[:space:]]*bash' "$SUITE")" "req-010: the run step sets shell bash"
assert_equals "yes" "$(yes_no 'run:[[:space:]]*bash planifest-framework/tests/run-tests\.sh' "$SUITE")" "req-010: the step runs bash planifest-framework/tests/run-tests.sh"

echo "== req-010: job posture =="
assert_equals "yes" "$(yes_no 'fail-fast:[[:space:]]*false' "$SUITE")" "req-010: strategy keeps fail-fast false"
assert_equals "yes" "$(yes_no 'contents:[[:space:]]*read' "$SUITE")" "req-010: permissions keep contents read"
if [ "$CAP_BRANCH" = "20" ]; then
  assert_equals "yes" "$(yes_no "timeout-minutes:[[:space:]]*$WINDOWS_CAP_EXPR\$" "$SUITE")" "req-010: job uses the 20-minute windows expression (ADR-014)"
else
  assert_equals "yes" "$(yes_no 'timeout-minutes:[[:space:]]*10$' "$SUITE")" "req-010: job keeps timeout-minutes 10 (ADR-014, 10 branch)"
fi
assert_equals "no" "$(yes_no 'secrets\.' "$SUITE")" "req-010: job references no secrets"
assert_equals "yes" "$(yes_no '^  pull_request:' "$(cat "$WORKFLOW")")" "req-010: workflow keeps the pull_request trigger"
assert_equals "no" "$(yes_no 'pull_request_target' "$(cat "$WORKFLOW")")" "req-010: workflow never uses pull_request_target"

echo "== req-010: consumer copy unchanged =="
assert_equals "no" "$(yes_no 'windows-latest' "$(cat "$CONSUMER_WORKFLOW")")" "req-010: consumer workflow does not mention windows-latest"
assert_equals "no" "$(yes_no 'run-tests\.sh' "$(cat "$CONSUMER_WORKFLOW")")" "req-010: consumer workflow does not mention run-tests.sh"

echo "== req-010: skip table =="
assert_equals "yes" "$(yes_no '^## Windows skip table' "$(cat "$TESTS_README")")" "req-010: tests README has a Windows skip table section"
assert_equals "yes" "$(yes_no '^\|[[:space:]]*Suite[[:space:]]*\|[[:space:]]*Reason[[:space:]]*\|[[:space:]]*Date[[:space:]]*\|' "$(cat "$TESTS_README")")" "req-010: skip table has Suite, Reason, and Date columns"

echo "== req-010: shard entries in the workflow (ADR-014 second fallback) =="
assert_equals "4" "$(grep -cE '^[[:space:]]+shard:[[:space:]]*[0-9]+[[:space:]]*$' <<<"$SUITE")" "req-010: the test-suite job holds four shard entries"
assert_equals "4" "$(grep -cE '^[[:space:]]+-[[:space:]]*os:[[:space:]]*windows-latest' <<<"$SUITE")" "req-010: four include entries run on windows-latest"
assert_equals "yes" "$(yes_no 'PLANIFEST_SHARD_INDEX:' "$SUITE")" "req-010: the step sets PLANIFEST_SHARD_INDEX"
assert_equals "yes" "$(yes_no 'PLANIFEST_SHARD_COUNT:' "$SUITE")" "req-010: the step sets PLANIFEST_SHARD_COUNT"
assert_equals "no" "$(yes_no 'os:[[:space:]]*\[[^]]*windows-latest' "$SUITE")" "req-010: windows-latest is not in the plain os list, only in the shard includes"

echo "== req-010: shard selection in run-tests.sh =="
FIX="$(mktemp -d "${TMPDIR:-/tmp}/planifest-shard.XXXXXX")"
trap 'rm -rf "$FIX"' EXIT
mkdir -p "$FIX/regression"
cp "$SCRIPT_DIR/run-tests.sh" "$FIX/run-tests.sh"
for n in a b c d e; do printf '#!/usr/bin/env bash\necho "dummy %s"\nexit 0\n' "$n" > "$FIX/test-$n.sh"; done
for n in r1 r2 r3; do printf '#!/usr/bin/env bash\necho "dummy %s"\nexit 0\n' "$n" > "$FIX/regression/test-$n.sh"; done

ran_names() { grep -E '^--- test-.*\.sh ---$' <<<"$1" | sed -E 's/^--- (test-.*\.sh) ---$/\1/' | tr '\n' ' '; }

ALL_OUT="$(env -u PLANIFEST_SHARD_INDEX -u PLANIFEST_SHARD_COUNT bash "$FIX/run-tests.sh" 2>&1)"
assert_equals "test-a.sh test-b.sh test-c.sh test-d.sh test-e.sh test-r1.sh test-r2.sh test-r3.sh " "$(ran_names "$ALL_OUT")" "req-010: with no shard variables every suite runs in order"
assert_equals "no" "$(yes_no 'Shard' "$ALL_OUT")" "req-010: with no shard variables no shard line prints"

S2_OUT="$(PLANIFEST_SHARD_INDEX=2 PLANIFEST_SHARD_COUNT=4 bash "$FIX/run-tests.sh" 2>&1)"
assert_equals "test-b.sh test-r1.sh " "$(ran_names "$S2_OUT")" "req-010: shard 2 of 4 runs positions 2 and 6 of the feature-plus-regression list"
assert_equals "yes" "$(yes_no 'Shard 2 of 4' "$S2_OUT")" "req-010: the runner prints one line naming the shard"
assert_equals "1" "$(grep -c 'Shard 2 of 4' <<<"$S2_OUT")" "req-010: the shard line prints once"

S1_OUT="$(PLANIFEST_SHARD_INDEX=1 PLANIFEST_SHARD_COUNT=4 bash "$FIX/run-tests.sh" 2>&1)"
S3_OUT="$(PLANIFEST_SHARD_INDEX=3 PLANIFEST_SHARD_COUNT=4 bash "$FIX/run-tests.sh" 2>&1)"
S4_OUT="$(PLANIFEST_SHARD_INDEX=4 PLANIFEST_SHARD_COUNT=4 bash "$FIX/run-tests.sh" 2>&1)"
UNION="$(ran_names "$S1_OUT")$(ran_names "$S2_OUT")$(ran_names "$S3_OUT")$(ran_names "$S4_OUT")"
assert_equals "8" "$(tr ' ' '\n' <<<"$UNION" | grep -c '^test-')" "req-010: the four shards run eight suite slots in total"
assert_equals "8" "$(tr ' ' '\n' <<<"$UNION" | grep '^test-' | sort -u | wc -l | tr -d ' ')" "req-010: the four shards cover every suite exactly once"

ONE_OUT="$(PLANIFEST_SHARD_INDEX=2 bash "$FIX/run-tests.sh" 2>&1)"
assert_equals "8" "$(ran_names "$ONE_OUT" | tr ' ' '\n' | grep -c '^test-')" "req-010: an index without a count runs every suite"
EMPTY_OUT="$(PLANIFEST_SHARD_INDEX= PLANIFEST_SHARD_COUNT= bash "$FIX/run-tests.sh" 2>&1)"
assert_equals "8" "$(ran_names "$EMPTY_OUT" | tr ' ' '\n' | grep -c '^test-')" "req-010: empty shard variables run every suite"

echo "== req-010: a nested runner does not inherit the shard =="
# A suite that runs run-tests.sh on a fixture must see no shard variables, so the
# runner unsets both after it reads them.
NEST="$(mktemp -d "${TMPDIR:-/tmp}/planifest-nest.XXXXXX")"
cp "$SCRIPT_DIR/run-tests.sh" "$NEST/run-tests.sh"
printf '#!/usr/bin/env bash\necho "nested-index=[${PLANIFEST_SHARD_INDEX-unset}] nested-count=[${PLANIFEST_SHARD_COUNT-unset}]"\nexit 0\n' > "$NEST/test-a.sh"
NEST_OUT="$(PLANIFEST_SHARD_INDEX=1 PLANIFEST_SHARD_COUNT=2 bash "$NEST/run-tests.sh" 2>&1)"
assert_equals "yes" "$(yes_no 'nested-index=\[unset\] nested-count=\[unset\]' "$NEST_OUT")" "req-010: a suite run by a sharded runner sees no shard variables"
rm -rf "$NEST"

echo "== req-010: every skip guard has a skip table row =="
# One row per guard and one guard per row (the README says so). A guard is a
# line that prints SKIP (windows): in a test-*.sh suite or its regression copy.
GUARDED="$(grep -lE '^[[:space:]]*(echo|printf).*SKIP \(windows\):' "$SCRIPT_DIR"/test-*.sh "$SCRIPT_DIR"/regression/test-*.sh 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u)"
ROWS="$(grep -E '^\|[[:space:]]*`?test-' "$TESTS_README" | sed -E 's/^\|[[:space:]]*`?([^`| ]+)`?.*/\1/' | sort -u)"
MISSING=""
for g in $GUARDED; do grep -qxF "$g" <<<"$ROWS" || MISSING="$MISSING $g"; done
assert_equals "" "$MISSING" "req-010: every suite with a SKIP (windows) guard has a skip table row"
EXTRA=""
for r in $ROWS; do grep -qxF "$r" <<<"$GUARDED" || EXTRA="$EXTRA $r"; done
assert_equals "" "$EXTRA" "req-010: every skip table row names a suite with a SKIP (windows) guard"

print_summary
