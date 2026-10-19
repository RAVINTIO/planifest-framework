#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-017: the orchestrator owns every join between streams or batches. After
#          each join and before the gate check, scripts/stream-reconcile.mjs
#          reports each declared artifact with no consumer, a self-consumer,
#          or no use in the consumer's changed files. The fixtures run in
#          temporary git repos, and one reproduces the four unused masthead
#          faces of 0000006.
#
# REGRESSION-CANDIDATE: covers the join owner rule and the stream reconciliation script, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
RECONCILE="$FRAMEWORK/scripts/stream-reconcile.mjs"
DISPATCH="$FRAMEWORK/standards/agent-dispatch-standards.md"
ORCH="$FRAMEWORK/skills/planifest-orchestrator/SKILL.md"

SCRATCH=$(mktemp -d -t planifest_0000033_req017_XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

# section <file> <heading-prefix>: body of a "## " section up to the next "## ".
section() {
  awk -v h="$2" 'index($0, h) == 1 {f=1; print; next} f && /^## /{exit} f' "$1" 2>/dev/null
}

# line_of <file> <fixed-string>: first line number holding the string, or 0.
line_of() {
  local n
  n=$(grep -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1)
  echo "${n:-0}"
}

# yes_if <label> <command...>: passes when the command exits zero.
yes_if() {
  local label="$1"; shift
  assert_equals "yes" "$("$@" >/dev/null 2>&1 && echo yes || echo no)" "$label"
}

# make_repo <dir>: an empty git repo with one initial commit. Prints its HEAD.
make_repo() {
  local r="$1"
  mkdir -p "$r/plan/current/requirements" "$r/src"
  git -C "$r" init -q
  git -C "$r" config user.email test@example.com
  git -C "$r" config user.name test
  git -C "$r" config commit.gpgsign false
  echo "root" > "$r/README.md"
  git -C "$r" add -A
  git -C "$r" commit -q -m init
  git -C "$r" rev-parse HEAD
}

# stream_commit <repo> <stream-id> <path> <content>: one commit with the trailer.
stream_commit() {
  mkdir -p "$(dirname "$1/$3")"
  printf '%s\n' "$4" > "$1/$3"
  git -C "$1" add -A
  git -C "$1" commit -q -m "feat: work for $2" -m "Stream: $2"
}

# state <repo> <stream-id> <start> <reqs> <declares-rows> <consumes-lines>
state() {
  mkdir -p "$1/plan/current/streams"
  cat > "$1/plan/current/streams/$2.md" <<EOF
---
stream-id: $2
kind: stream
start-commit: $3
status: at-join
phase: P3
requirements: [$4]
stories: [US-001]
id-blocks: "req-001 to req-009"
updated: 2026-10-19T00:00:00Z
---
# Stream State: $2

## Phase history

| Phase | Start | End | Subagents | Result |
|-------|-------|-----|-----------|--------|

## Files changed

## Declares

| Artifact ID | Defined in | Consumer |
|-------------|------------|----------|
$5

## Consumes

$6

## Next step

Join at P3.
EOF
}

run() {
  (cd "$1" && node "$RECONCILE" "${2:-plan/current}" 2>&1)
}

echo "=== req-017: the script exists ==="
yes_if "req-017: scripts/stream-reconcile.mjs exists" test -f "$RECONCILE"

echo "=== req-017: clean pair of streams ==="
R="$SCRATCH/clean"
START=$(make_repo "$R")
cat > "$R/plan/current/requirements/req-001-faces.md" <<'EOF'
# req-001
Uses rule-token-gutter from the rules stream.
EOF
stream_commit "$R" stream-01-faces src/faces.css ".face-alpha-serif { } /* gutter: rule-token-gutter */"
stream_commit "$R" stream-02-rules src/rules.css "h1 { font: face-alpha-serif; } .rule-token-gutter { }"
state "$R" stream-01-faces "$START" "req-001" \
  "| face-alpha-serif | src/faces.css | stream-02-rules |" \
  "- rule-token-gutter"
state "$R" stream-02-rules "$START" "req-002" \
  "| rule-token-gutter | src/rules.css | req-001 |" \
  "- face-alpha-serif"
OUT=$(run "$R"); EX=$?
assert_exit_zero "$EX" "req-017: the clean fixture exits 0"
assert_equals "" "$OUT" "req-017: the clean fixture prints nothing"

echo "=== req-017: declared artifact with no consumer ==="
R="$SCRATCH/noconsumer"
START=$(make_repo "$R")
stream_commit "$R" stream-01-faces src/faces.css ".face-orphan-mono { }"
state "$R" stream-01-faces "$START" "req-001" "| face-orphan-mono | src/faces.css |  |" ""
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: a declared artifact with no consumer exits 1"
assert_contains "face-orphan-mono" "$OUT" "req-017: the no-consumer finding names the artifact"

echo "=== req-017: a stream that names itself as consumer ==="
R="$SCRATCH/self"
START=$(make_repo "$R")
stream_commit "$R" stream-01-faces src/faces.css ".face-self-sans { } .x { font: face-self-sans; }"
state "$R" stream-01-faces "$START" "req-001" "| face-self-sans | src/faces.css | stream-01-faces |" "- face-self-sans"
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: a self-consumer exits 1"
assert_contains "face-self-sans" "$OUT" "req-017: the self-consumer finding names the artifact"

echo "=== req-017: reproduction of 0000006 (four unused masthead faces) ==="
R="$SCRATCH/repro-0000006"
START=$(make_repo "$R")
stream_commit "$R" stream-01-faces src/faces.css \
  ".masthead-face-didone {} .masthead-face-grotesk {} .masthead-face-slab {} .masthead-face-script {}"
stream_commit "$R" stream-02-rules src/rules.css "h1 { font-family: serif; }"
ROWS="| masthead-face-didone | src/faces.css | stream-02-rules |
| masthead-face-grotesk | src/faces.css | stream-02-rules |
| masthead-face-slab | src/faces.css | stream-02-rules |
| masthead-face-script | src/faces.css | stream-02-rules |"
state "$R" stream-01-faces "$START" "req-001" "$ROWS" ""
state "$R" stream-02-rules "$START" "req-002" "" \
  "- masthead-face-didone
- masthead-face-grotesk
- masthead-face-slab
- masthead-face-script"
git -C "$R" add -A && git -C "$R" commit -q -m "plan: stream state" -m "Stream: stream-02-rules"
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: the 0000006 fixture exits 1"
COUNT=$(grep -c "masthead-face-" <<< "$OUT")
assert_equals "4" "$COUNT" "req-017: the 0000006 fixture prints four findings"
for f in didone grotesk slab script; do
  assert_contains "masthead-face-$f" "$OUT" "req-017: the 0000006 fixture reports masthead-face-$f"
done

# join <repo> <join-id> <start> <declares-rows> <consumes-lines> <files-lines>
join_record() {
  mkdir -p "$1/plan/current/streams"
  cat > "$1/plan/current/streams/$2.md" <<EOF
---
join-id: $2
kind: join
start-commit: $3
---
# Join: $2

## Declares

| Artifact ID | Defined in | Consumer |
|-------------|------------|----------|
$4

## Consumes

$5

## Files changed

$6
EOF
}

echo "=== req-017: changed files outside the repo or not regular (security review) ==="
R="$SCRATCH/outside-link"
START=$(make_repo "$R")
echo "face-outside-link" > "$SCRATCH/outside.txt"
stream_commit "$R" stream-01-faces src/faces.css ".face-outside-link { }"
ln -s "$SCRATCH/outside.txt" "$R/src/link.css"
git -C "$R" add -A && git -C "$R" commit -q -m "feat: link" -m "Stream: stream-02-rules"
state "$R" stream-01-faces "$START" "req-001" "| face-outside-link | src/faces.css | stream-02-rules |" ""
state "$R" stream-02-rules "$START" "req-002" "" "- face-outside-link"
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: a changed file that links outside the repo doesn't count as a use"
assert_contains "skipped src/link.css" "$OUT" "req-017: the finding names the skipped symlink"

R="$SCRATCH/oversize"
START=$(make_repo "$R")
stream_commit "$R" stream-01-faces src/faces.css ".face-oversize { }"
mkdir -p "$R/src"
{ head -c 1100000 /dev/zero | tr '\0' 'a'; echo " face-oversize"; } > "$R/src/big.css"
git -C "$R" add -A && git -C "$R" commit -q -m "feat: big" -m "Stream: stream-02-rules"
state "$R" stream-01-faces "$START" "req-001" "| face-oversize | src/faces.css | stream-02-rules |" ""
state "$R" stream-02-rules "$START" "req-002" "" "- face-oversize"
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: a changed file over 1 MB doesn't count as a use"
assert_contains "skipped src/big.css" "$OUT" "req-017: the finding names the skipped oversize file"

R="$SCRATCH/join-outside"
START=$(make_repo "$R")
echo "face-join-outside" > "$SCRATCH/join-outside.txt"
stream_commit "$R" stream-01-faces src/faces.css ".face-join-outside { }"
state "$R" stream-01-faces "$START" "req-001" "| face-join-outside | src/faces.css | join-p3-01 |" ""
join_record "$R" join-p3-01 "$START" "" "- face-join-outside" "- $SCRATCH/join-outside.txt"
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: a join's listed path outside the repo doesn't count as a use"

echo "=== req-017: a join's changed files come from git (security review) ==="
R="$SCRATCH/join-reqfile"
make_repo "$R" > /dev/null
printf '# req-001\nUses face-join-req.\n' > "$R/plan/current/requirements/req-001-faces.md"
git -C "$R" add -A && git -C "$R" commit -q -m "plan: req"
START=$(git -C "$R" rev-parse HEAD)
stream_commit "$R" stream-01-faces src/faces.css ".face-join-req { }"
state "$R" stream-01-faces "$START" "req-001" "| face-join-req | src/faces.css | join-p3-01 |" ""
join_record "$R" join-p3-01 "$START" "" "- face-join-req" "- plan/current/requirements/req-001-faces.md"
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: a join listing a file git didn't change in its range doesn't count as a use"

R="$SCRATCH/join-clean"
START=$(make_repo "$R")
stream_commit "$R" stream-01-faces src/faces.css ".face-join-ok { }"
mkdir -p "$R/src" && echo "h1 { font: face-join-ok; }" > "$R/src/use.css"
git -C "$R" add -A && git -C "$R" commit -q -m "feat: batch use"
state "$R" stream-01-faces "$START" "req-001" "| face-join-ok | src/faces.css | join-p3-01 |" ""
join_record "$R" join-p3-01 "$START" "" "- face-join-ok" "- src/use.css"
OUT=$(run "$R"); EX=$?
assert_exit_zero "$EX" "req-017: a join whose listed file git changed in its range exits 0"
assert_equals "" "$OUT" "req-017: a clean join prints nothing"

echo "=== req-017: control characters never reach output (security review) ==="
R="$SCRATCH/ansi"
START=$(make_repo "$R")
stream_commit "$R" stream-01-faces src/faces.css ".face-ansi { }"
state "$R" stream-01-faces "$START" "req-001" "| face-ansi"$'\e[2J'" | src/faces.css |  |" ""
OUT=$(run "$R"); EX=$?
assert_equals "1" "$EX" "req-017: an artifact ID with an ANSI escape still reports a finding"
assert_equals "absent" "$([[ "$OUT" == *$'\e'* ]] && echo present || echo absent)" \
  "req-017: an ANSI escape in an artifact ID never reaches output"

echo "=== req-017: git pathspecs are literal ==="
yes_if "req-017: stream-reconcile.mjs sets GIT_LITERAL_PATHSPECS=1" \
  grep -q 'GIT_LITERAL_PATHSPECS: "1"' "$RECONCILE"
yes_if "req-017: archive-current.mjs sets GIT_LITERAL_PATHSPECS=1" \
  grep -q 'GIT_LITERAL_PATHSPECS: "1"' "$FRAMEWORK/scripts/archive-current.mjs"

echo "=== req-017: absent streams/ directory ==="
R="$SCRATCH/absent"
make_repo "$R" > /dev/null
OUT=$(run "$R"); EX=$?
assert_exit_zero "$EX" "req-017: an absent streams/ directory exits 0"
assert_equals "" "$OUT" "req-017: an absent streams/ directory prints nothing"

echo "=== req-017: dispatch standards ==="
PS=$(line_of "$DISPATCH" "## Parallel Streams")
JR=$(line_of "$DISPATCH" "## Joins and Reconciliation")
yes_if "req-017: ## Joins and Reconciliation sits after ## Parallel Streams" \
  test "$JR" -gt "$PS" -a "$PS" -gt 0
JOINS=$(section "$DISPATCH" "## Joins and Reconciliation")
for needle in "orchestrator owns every join" "Declares" "Consumes" "join-{phase}-{nn}.md" \
  "stream-reconcile.mjs" "0000006-ADR-003" "verifier" "called from skill text"; do
  assert_contains "$needle" "$JOINS" "req-017: Joins and Reconciliation names $needle"
done

TEMPLATE=$(section "$DISPATCH" "## Agent Dispatch Template")
SKELETONS=$(grep -c 'Confirm: files modified, what changed.*Declares.*Consumes' <<< "$TEMPLATE")
assert_equals "2" "$SKELETONS" "req-017: both skeleton prompts name Declares and Consumes"

echo "=== req-017: orchestrator ==="
PC=$(section "$ORCH" "## Phase Conventions")
assert_contains "stream-reconcile.mjs" "$PC" "req-017: Phase Conventions names stream-reconcile.mjs"
ADS=$(section "$ORCH" "## Agent Dispatch Standards")
assert_contains "## Joins and Reconciliation" "$ADS" "req-017: Agent Dispatch Standards names ## Joins and Reconciliation"

print_summary
