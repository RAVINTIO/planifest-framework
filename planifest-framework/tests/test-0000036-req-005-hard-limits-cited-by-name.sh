#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-005: every hard-limit citation names its rule and its source list as
#          well as its number (ADR-010). The form is
#          `the {name} rule ({source} Hard Limit {N})`, or the plural
#          `the {name} and {name} rules ({source} Hard Limits {N} and {M})`.
#          The dispatch template states the Write-or-Edit rule in both example
#          prompts and in the self-contained prompt rule.
#
# The scan reads planifest-framework/ without tests/, and also docs/ and
# src/*/docs/. It strips each wrapped citation from a line, then fails on any
# `Hard Limits? N` left over, and prints the file and line.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FW/.." && pwd)"
DISPATCH="$FW/standards/agent-dispatch-standards.md"

WORK="$(mktemp -d -t planifest_0000036_req005_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

BARE='Hard Limits? [0-9]+( and [0-9]+)?'
NAME='[A-Za-z][A-Za-z-]*'
SOURCE='[a-z]+( [a-z]+)?'
# Main form: the {name} rule ({source} Hard Limit {N}), and its plural.
WRAPPED="[Tt]he $NAME( and $NAME)? rules? \\($SOURCE $BARE\\)"
# Bracketed form, used by the dispatch sentence req-005 gives verbatim:
# (the {name} rule, {source} Hard Limit {N}).
BRACKETED="\\(the $NAME( and $NAME)? rules?, $SOURCE $BARE\\)"

# bare_citations <path>...: prints one "file:line: text" row per line that
# still holds a hard-limit number once every wrapped citation is stripped.
# -H keeps the file name for a single file operand: GNU grep drops it.
bare_citations() {
  grep -rnHE "$BARE" "$@" 2>/dev/null | while IFS= read -r row; do
    local loc="${row%%:*}"
    local rest="${row#*:}"
    local line="${rest%%:*}"
    local text="${rest#*:}"
    local stripped
    stripped="$(sed -E -e "s/$WRAPPED//g" -e "s/$BRACKETED//g" <<< "$text")"
    if grep -qE "$BARE" <<< "$stripped"; then
      printf '%s:%s: %s\n' "$loc" "$line" "$text"
    fi
  done
}

echo "=== req-005: the scan flags a bare citation with its file and line ==="

FIX="$WORK/fixture.md"
cat > "$FIX" <<'MD'
A pipeline error (Hard Limit 8).
A pipeline error, per the build-log rule (orchestrator Hard Limit 8).
The schema and destructive-operation rules (orchestrator Hard Limits 2 and 3) stay gated.
Make every file change through Write or Edit (the Write-or-Edit rule, boot Hard Limit 8).
The credentials rule (orchestrator Hard Limit 6): credentials never enter context.
Hard Limits 2 and 3 stay human-gated.
## Commit cadence: the commit-cadence rule (orchestrator Hard Limit 7)
## Commit Cadence (Hard Limit 7)
MD
FV="$(bare_citations "$FIX")"
assert_contains "$FIX:1:" "$FV" "req-005: the scan flags a bare Hard Limit 8 and names the file and line"
assert_contains "$FIX:6:" "$FV" "req-005: the scan flags a bare plural citation"
assert_contains "$FIX:8:" "$FV" "req-005: the scan flags a bare heading citation"
assert_equals "0" "$(grep -c "$FIX:2:" <<< "$FV")" "req-005: the scan passes the singular form"
assert_equals "0" "$(grep -c "$FIX:3:" <<< "$FV")" "req-005: the scan passes the plural form"
assert_equals "0" "$(grep -c "$FIX:4:" <<< "$FV")" "req-005: the scan passes the bracketed dispatch form"
assert_equals "0" "$(grep -c "$FIX:5:" <<< "$FV")" "req-005: the scan passes a citation that opens a sentence"
assert_equals "0" "$(grep -c "$FIX:7:" <<< "$FV")" "req-005: the scan passes the heading form"

echo "=== req-005: no bare citation in the framework or the living docs ==="

TARGETS=()
while IFS= read -r p; do TARGETS+=("$p"); done < <(
  find "$FW" -mindepth 1 -maxdepth 1 ! -name tests
  [ -d "$ROOT/docs" ] && echo "$ROOT/docs"
  for d in "$ROOT"/src/*/docs; do [ -d "$d" ] && echo "$d"; done
)
FOUND="$(bare_citations "${TARGETS[@]}")"
if [ -n "$FOUND" ]; then
  echo "  Bare citations:"
  printf '%s\n' "$FOUND" | sed 's/^/    /'
fi
assert_equals "0" "$(grep -c . <<< "$FOUND")" "req-005: every citation names its rule and source"

echo "=== req-005: the Write-or-Edit rule in the dispatch template ==="

SENTENCE="Make every file change through Write or Edit, never through the shell (the Write-or-Edit rule, boot Hard Limit 8)."
PROMPTS="$(grep -F 'prompt: "Requirement:' "$DISPATCH")"
assert_equals "2" "$(grep -c . <<< "$PROMPTS")" "req-005: the dispatch template holds two example prompts"
assert_equals "2" "$(grep -cF "$SENTENCE" <<< "$PROMPTS")" "req-005: both example prompts state the Write-or-Edit rule"
RULE="$(grep -F '**Self-contained prompt rule:**' "$DISPATCH")"
assert_contains "$SENTENCE" "$RULE" "req-005: the self-contained prompt rule lists the Write-or-Edit sentence"

print_summary
