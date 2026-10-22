#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-008: evaluateWrite calls lstatSync on plan/current/design.md before it
#          opens it. A folder, FIFO, symbolic link, or other non-regular file
#          reads as no design, and each block on that route gains the "not a
#          regular file" line. A throwing lstatSync reads as no design with no
#          extra line. A regular design.md that can't be read still fails open
#          (ADR-002). The suite also holds the NFR-001 timed case and the
#          NFR-003 source check over five hook files (ADR-001).
#
# Every fixture lives under mktemp -d. The suite uses git to build fixtures.
# Every hook run has a 5-second limit, so a FIFO can't hold the suite.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
SHELL_GUARD="$ENF/shell-write-guard.mjs"

WORK="$(mktemp -d -t planifest_0000036_req008_XXXXXX)"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

GIT=(git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c init.defaultBranch=main)

FX="$WORK/repo"
DESIGN="$FX/plan/current/design.md"
mkdir -p "$FX/plan/current" "$FX/src"
: > "$FX/plan/.orchestrator-active"
"${GIT[@]}" init -q "$FX" >/dev/null 2>&1
"${GIT[@]}" -C "$FX" commit -q --allow-empty -m init --no-verify >/dev/null 2>&1
BRANCH="$(git -C "$FX" rev-parse --abbrev-ref HEAD)"
HEAD_ID="$(git -C "$FX" rev-parse HEAD)"

NO_DESIGN="No confirmed design at plan/current/design.md"
NOT_REGULAR="[Planifest] plan/current/design.md is not a regular file, so the gate treats it as no design."
NOT_LISTED="is not listed in the Fast Path scope record"
ENFORCEMENT="is an enforcement path, so Fast Path never admits it"

IS_ROOT=no
[ "$(id -u 2>/dev/null)" = "0" ] && IS_ROOT=yes

DESIGN_TEXT='# Design

## Component Paths

- src/
'

# reset_design: removes whatever sits at design.md and the scope record.
reset_design() {
  chmod u+rwx "$FX/plan/current" 2>/dev/null
  [ -e "$DESIGN" ] || [ -L "$DESIGN" ] && chmod u+rw "$DESIGN" 2>/dev/null
  rm -rf "$DESIGN" "$FX/plan/.fast-path-scope"
}

# record <head> <path>...: a scope record for the current branch and <head>.
record() {
  local head="$1"
  shift
  {
    printf 'branch: %s\nhead: %s\npaths:\n' "$BRANCH" "$head"
    for p in "$@"; do printf -- '- %s\n' "$p"; done
  } > "$FX/plan/.fast-path-scope"
}

# run_limited <hook> <json>: runs the hook from the fixture under a 5-second
# limit and sets CODE, ERR, OUT, and TIMED_OUT. The limit sets CODE to 124.
run_limited() {
  local errfile="$WORK/stderr.txt" outfile="$WORK/stdout.txt" i=0
  node "$1" >"$outfile" 2>"$errfile" <<< "$2" &
  local pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 50 ]; do
    sleep 0.1
    i=$((i + 1))
  done
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    CODE=124
    TIMED_OUT=yes
  else
    wait "$pid"
    CODE=$?
    TIMED_OUT=no
  fi
  ERR=$(cat "$errfile")
  OUT=$(cat "$outfile")
}

# run_gate <target>: a Write of <target> through gate-write.
run_gate() {
  run_limited "$GATE_WRITE" "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}"
}

# run_guard <command>: <command> through the shell-write guard.
run_guard() {
  run_limited "$SHELL_GUARD" "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}"
}

# in_order <first> <second> <text>: yes when <first> appears in <text> and
# <second> appears after it.
in_order() {
  local rest="${3#*"$1"}"
  [ "$rest" != "$3" ] && [[ "$rest" == *"$2"* ]] && echo yes || echo no
}

# blocks_as_non_regular <label>: both hooks block a write to src/a.js with
# the no-design reason followed by the "not a regular file" line.
blocks_as_non_regular() {
  run_gate "src/a.js"
  assert_equals "no" "$TIMED_OUT" "req-008: gate-write exits on its own with $1 at design.md"
  assert_equals "2" "$CODE" "req-008: gate-write blocks src/a.js with $1 at design.md"
  assert_contains "$NO_DESIGN" "$ERR" "req-008: gate-write gives the no-design reason with $1 at design.md"
  assert_equals "yes" "$(in_order "$NO_DESIGN" "$NOT_REGULAR" "$ERR")" "req-008: gate-write adds the not-a-regular-file line after the reason with $1"
  run_guard "touch src/a.js"
  assert_equals "no" "$TIMED_OUT" "req-008: shell-write-guard exits on its own with $1 at design.md"
  assert_equals "2" "$CODE" "req-008: shell-write-guard blocks src/a.js with $1 at design.md"
  assert_contains "$NO_DESIGN" "$ERR" "req-008: shell-write-guard gives the no-design reason with $1 at design.md"
  assert_equals "yes" "$(in_order "$NO_DESIGN" "$NOT_REGULAR" "$ERR")" "req-008: shell-write-guard adds the not-a-regular-file line after the reason with $1"
}

# =============================================================================
echo ""
echo "=== req-008: a non-regular design.md with no scope record ==="

reset_design
mkdir -p "$DESIGN"
blocks_as_non_regular "a folder"

reset_design
if mkfifo "$DESIGN" 2>/dev/null; then
  blocks_as_non_regular "a FIFO"
else
  echo "  SKIP: req-008: mkfifo is not available, so the FIFO case can't run"
fi

reset_design
printf '%s' "$DESIGN_TEXT" > "$WORK/real-design.md"
if ln -s "$WORK/real-design.md" "$DESIGN" 2>/dev/null && [ -L "$DESIGN" ]; then
  blocks_as_non_regular "a symbolic link to a design that lists src/"
else
  echo "  SKIP: req-008: symbolic links are not available, so the link case can't run"
fi

# =============================================================================
echo ""
echo "=== req-008: a folder at design.md takes the scope record route ==="

reset_design
mkdir -p "$DESIGN"
record "$HEAD_ID" "src/a.js" ".claude/settings.json"

run_gate "src/a.js"
assert_equals "0" "$CODE" "req-008: a current record still admits src/a.js with a folder at design.md"
assert_contains "Fast Path: admitted" "$ERR" "req-008: the admit prints the Fast Path notice"
assert_equals "no" "$([[ "$ERR" == *"$NOT_REGULAR"* ]] && echo yes || echo no)" "req-008: the admit carries no not-a-regular-file line"

run_gate "src/b.js"
assert_equals "2" "$CODE" "req-008: a current record blocks unlisted src/b.js with a folder at design.md"
assert_equals "yes" "$(in_order "$NOT_LISTED" "$NOT_REGULAR" "$ERR")" "req-008: the not-listed reason comes before the not-a-regular-file line"
run_guard "touch src/b.js"
assert_equals "2" "$CODE" "req-008: shell-write-guard blocks unlisted src/b.js with a folder at design.md"
assert_equals "yes" "$(in_order "$NOT_LISTED" "$NOT_REGULAR" "$ERR")" "req-008: shell-write-guard gives the not-listed reason, then the not-a-regular-file line"

run_gate ".claude/settings.json"
assert_equals "2" "$CODE" "req-008: a record never admits an enforcement path with a folder at design.md"
assert_equals "yes" "$(in_order "$ENFORCEMENT" "$NOT_REGULAR" "$ERR")" "req-008: the enforcement-path reason comes before the not-a-regular-file line"

# =============================================================================
echo ""
echo "=== req-008: a folder at design.md with a stale scope record ==="

reset_design
mkdir -p "$DESIGN"
record "0000000000000000000000000000000000000000" "src/a.js"
run_gate "src/a.js"
assert_equals "2" "$CODE" "req-008: a stale record admits nothing with a folder at design.md"
assert_equals "yes" "$(in_order "$NO_DESIGN" "The gate ignored plan/.fast-path-scope" "$ERR")" "req-008: the stale block names why the record was ignored"
assert_equals "yes" "$(in_order "The gate ignored plan/.fast-path-scope" "$NOT_REGULAR" "$ERR")" "req-008: the stale block ends with the not-a-regular-file line"

# =============================================================================
echo ""
echo "=== req-008: lstatSync throws EACCES ==="

reset_design
printf '%s' "$DESIGN_TEXT" > "$DESIGN"
chmod 600 "$FX/plan/current"
if [ "$IS_ROOT" = "yes" ]; then
  echo "  SKIP: req-008: the EACCES case can't run as root"
elif [ -x "$FX/plan/current" ]; then
  echo "  SKIP: req-008: this file system ignores mode 600 on a folder"
else
  run_gate "src/a.js"
  assert_equals "2" "$CODE" "req-008: an unsearchable plan/current blocks src/a.js as no design"
  assert_contains "$NO_DESIGN" "$ERR" "req-008: the EACCES block gives the no-design reason"
  assert_equals "no" "$([[ "$ERR" == *"$NOT_REGULAR"* ]] && echo yes || echo no)" "req-008: the EACCES block carries no not-a-regular-file line"
fi
chmod 755 "$FX/plan/current"

# =============================================================================
echo ""
echo "=== req-008: a regular design.md ==="

reset_design
printf '%s' "$DESIGN_TEXT" > "$DESIGN"
run_gate "src/a.js"
assert_equals "0" "$CODE" "req-008: control, a regular design that lists src/ admits src/a.js"
run_guard "touch src/a.js"
assert_equals "0" "$CODE" "req-008: control, shell-write-guard admits src/a.js under a regular design"
run_gate "lib/a.js"
assert_equals "2" "$CODE" "req-008: control, a regular design still blocks a path it doesn't cover"
assert_equals "no" "$([[ "$ERR" == *"$NOT_REGULAR"* ]] && echo yes || echo no)" "req-008: a regular design gives no not-a-regular-file line"

# NFR-001: one gate-write call with a regular design.md stays under 500 ms.
ELAPSED=$(node --input-type=module -e "
import { spawnSync } from 'node:child_process';
const input = JSON.stringify({ cwd: process.argv[1], tool_name: 'Write', tool_input: { file_path: 'src/a.js' } });
spawnSync(process.execPath, [process.argv[2]], { input });
const start = process.hrtime.bigint();
spawnSync(process.execPath, [process.argv[2]], { input });
process.stdout.write(String(Number((process.hrtime.bigint() - start) / 1000000n)));
" "$(native "$FX")" "$(native "$GATE_WRITE")")
assert_equals "yes" "$([ -n "$ELAPSED" ] && [ "$ELAPSED" -lt 500 ] && echo yes || echo no)" "req-008: NFR-001, gate-write with a regular design.md finishes under 500 ms (took ${ELAPSED} ms)"

# A regular design.md that can't be read still fails open (0000003 ADR 005).
chmod 000 "$DESIGN"
if [ "$IS_ROOT" = "yes" ]; then
  echo "  SKIP: req-008: the mode 000 case can't run as root"
elif [ -r "$DESIGN" ]; then
  echo "  SKIP: req-008: this file system ignores mode 000"
else
  run_gate "lib/a.js"
  assert_equals "0" "$CODE" "req-008: a regular design.md with mode 000 still fails open"
fi
chmod 644 "$DESIGN"

# =============================================================================
echo ""
echo "=== req-008: NFR-003 source check over five hook files ==="

SOURCE_CHECK=$(node --input-type=module -e "
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
const dir = process.argv[1];
const allowed = (s) => s.startsWith('node:') || s === './path-rules.mjs' || s === './read-stdin.mjs';
const problems = [];
for (const name of ['path-rules.mjs', 'gate-write.mjs', 'shell-write-guard.mjs', 'em-dash-guard.mjs', 'ratchet-check.mjs']) {
  const src = readFileSync(join(dir, name), 'utf-8');
  const specs = [...src.matchAll(/^\s*(?:import|export)\b[^;]*?from\s*[\"']([^\"']+)[\"']/gm)].map((m) => m[1]);
  specs.push(...[...src.matchAll(/^\s*import\s*[\"']([^\"']+)[\"']/gm)].map((m) => m[1]));
  for (const s of specs) if (!allowed(s)) problems.push(name + ' imports ' + s);
  if (/\bimport\s*\(/.test(src) || /\brequire\s*\(/.test(src)) problems.push(name + ' loads a module at run time');
  const cp = specs.filter((s) => s === 'node:child_process' || s === 'child_process');
  if (name !== 'ratchet-check.mjs') {
    if (cp.length) problems.push(name + ' imports node:child_process');
    continue;
  }
  // ratchet-check.mjs keeps its one git spawn by name (backlog 0000128).
  const cpImports = [...src.matchAll(/import\s*\{([^}]*)\}\s*from\s*[\"'](?:node:)?child_process[\"']/g)].map((m) => m[1].trim());
  if (cpImports.length !== 1 || cpImports[0] !== 'execFileSync') problems.push('ratchet-check.mjs imports more than execFileSync from node:child_process');
  if (cp.length !== 1) problems.push('ratchet-check.mjs imports node:child_process more than once');
  // A method call such as re.exec() is not a spawn, so a leading dot excludes it.
  const calls = [...src.matchAll(/(?<![.\w])(execFileSync|execSync|exec|spawn|spawnSync|fork|execFile)\s*\(/g)];
  const git = [...src.matchAll(/\bexecFileSync\s*\(\s*[\"']git[\"']/g)];
  if (calls.length !== 1 || git.length !== 1) problems.push('ratchet-check.mjs spawns something other than its one git call');
}
process.stdout.write(problems.length ? problems.join('; ') : 'ok');
" "$(native "$ENF")")
assert_equals "ok" "$SOURCE_CHECK" "req-008: NFR-003, the five hook files import only node: modules, path-rules.mjs, and read-stdin.mjs, with one git spawn"
assert_equals "no" "$(grep -q 'child_process' "$ENF/path-rules.mjs" && echo yes || echo no)" "req-008: path-rules.mjs imports no node:child_process (0000035 ADR 001)"

print_summary
