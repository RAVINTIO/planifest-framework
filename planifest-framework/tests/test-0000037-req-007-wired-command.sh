#!/usr/bin/env bash
# Verified by: integration
# test-0000037-req-007-wired-command.sh
# req-007 (ADR-009): run the hook command strings that setup.sh writes into
# .claude/settings.json, verbatim, through bash -c in a fixture workspace.
# The test never rebuilds a command string. A missing entry fails and names the
# hook. A negative fixture proves the test detects a broken wiring.
# Run from any directory: bash planifest-framework/tests/test-0000037-req-007-wired-command.sh

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"; fi
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"

yes_no() { if "$@"; then echo "yes"; else echo "no"; fi; }

WS="$(mktemp -d "${TMPDIR:-/tmp}/planifest_0000037_req007_XXXXXX")"
trap 'rm -rf "$WS"' EXIT

# Native path for JSON payloads (Git Bash needs the Windows form for node).
native_path() { (cd "$1" && (pwd -W 2>/dev/null || pwd)); }

echo "req-007 FR-007.1: run setup.sh for Claude Code into a temporary workspace"
cp -r "$FRAMEWORK" "$WS/planifest-framework"
git init "$WS" >/dev/null 2>&1
SETUP_OUT="$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)"
assert_exit_zero "$?" "req-007 FR-007.1: setup.sh claude-code exits 0"
assert_equals "yes" "$(yes_no test -f "$WS/.claude/settings.json")" "req-007 FR-007.1: .claude/settings.json exists"
SETTINGS="$WS/.claude/settings.json"
WS_N="$(native_path "$WS")"

# settings_command FILE EVENT MATCHER SCRIPT [MODE]
# Prints the command of the entry for SCRIPT under EVENT and MATCHER, read with
# node (FR-007.6). MODE bare rewrites it to a bare .mjs path with no node prefix.
# MODE wrongdir rewrites it to a folder that does not exist. Prints nothing when
# the entry is missing.
settings_command() {
  node -e '
    const [file, event, matcher, script, mode] = process.argv.slice(1);
    const s = JSON.parse(require("fs").readFileSync(file, "utf8"));
    for (const entry of (s.hooks && s.hooks[event]) || []) {
      if (entry.matcher !== matcher) continue;
      for (const h of entry.hooks || []) {
        if (typeof h.command !== "string" || !h.command.includes(script)) continue;
        let c = h.command;
        if (mode === "bare") c = c.replace(/^node\s+/, "").replace(/"/g, "");
        if (mode === "wrongdir") c = c.replace("hooks/enforcement", "hooks/no-such-dir");
        process.stdout.write(c);
        process.exit(0);
      }
    }
  ' "$@"
}

# payload KIND ARGS...: print a JSON hook payload built by node.
payload() {
  node -e '
    const [kind, cwd, arg] = process.argv.slice(1);
    let p;
    if (kind === "write") p = { cwd, tool_name: "Write", tool_input: { file_path: arg, content: "x" } };
    else if (kind === "bash") p = { cwd, tool_name: "Bash", tool_input: { command: arg } };
    else p = { cwd, prompt: arg };
    process.stdout.write(JSON.stringify(p));
  ' "$@"
}

OUT=""
ERR=""
CODE=0
# run_wired COMMAND PAYLOAD: run COMMAND verbatim through bash -c in the workspace.
run_wired() {
  local cmd="$1" input="$2" errfile="$WS/.stderr"
  OUT="$(cd "$WS" && printf '%s' "$input" | bash -c "$cmd" 2>"$errfile")"
  CODE=$?
  ERR="$(cat "$errfile")"
}

# wired_command NAME EVENT MATCHER SCRIPT: set CMD, or fail the suite naming NAME (FR-007.5).
CMD=""
wired_command() {
  local name="$1"
  CMD="$(settings_command "$SETTINGS" "$2" "$3" "$4")"
  if [ -z "$CMD" ]; then
    echo "  FAIL: req-007 FR-007.5: settings.json has no entry for hook $name"
    ((FAIL++)) || true
    return 1
  fi
  echo "  PASS: req-007 FR-007.5: settings.json has an entry for hook $name"
  ((PASS++)) || true
  return 0
}

# -----------------------------------------------------------------------
echo ""
echo "req-007 FR-007.5: a missing entry fails and names the hook"
MISSING_OUT="$(wired_command "no-such-hook" PreToolUse Write no-such-hook.mjs; echo "rc=$?")"
assert_contains "no entry for hook no-such-hook" "$MISSING_OUT" "req-007 FR-007.5: failure names the missing hook"
assert_contains "rc=1" "$MISSING_OUT" "req-007 FR-007.5: a missing entry returns failure and never skips"
# The probe above ran in a subshell, so its failure count did not reach this shell.

# -----------------------------------------------------------------------
echo ""
echo "req-007 AC-007.1: gate-write command, verbatim"
if wired_command "gate-write" PreToolUse Write gate-write.mjs; then
  assert_contains "gate-write.mjs" "$CMD" "req-007 AC-007.1: the entry runs gate-write.mjs"
  run_wired "$CMD" "$(payload write "$WS_N" "$WS_N/src/a.js")"
  assert_equals "2" "$CODE" "req-007 AC-007.1: violating Write to src/ with no design exits 2"
  run_wired "$CMD" "$(payload write "$WS_N" "$WS_N/plan/notes.md")"
  assert_equals "0" "$CODE" "req-007 AC-007.1: clean Write to plan/ exits 0"
fi

echo ""
echo "req-007 AC-007.2: shell-write-guard command, verbatim"
if wired_command "shell-write-guard" PreToolUse Bash shell-write-guard.mjs; then
  assert_contains "shell-write-guard.mjs" "$CMD" "req-007 AC-007.2: the entry runs shell-write-guard.mjs"
  run_wired "$CMD" "$(payload bash "$WS_N" "echo x > src/a.js")"
  assert_equals "2" "$CODE" "req-007 AC-007.2: violating Bash 'echo x > src/a.js' with no design exits 2"
  run_wired "$CMD" "$(payload bash "$WS_N" "ls")"
  assert_equals "0" "$CODE" "req-007 AC-007.2: clean Bash 'ls' exits 0"
fi

echo ""
echo "req-007 AC-007.3: auto-trigger-orchestrator command, verbatim"
TRIGGER_TEXT="Load the planifest-orchestrator skill"
if wired_command "auto-trigger-orchestrator" UserPromptSubmit '.*' auto-trigger-orchestrator.mjs; then
  assert_equals "yes" "$(yes_no test -d "$WS/planifest-framework")" "req-007 FR-007.4: fixture workspace holds planifest-framework/"
  assert_equals "no" "$(yes_no test -e "$WS/plan/.orchestrator-active")" "req-007 FR-007.4: fixture workspace has no orchestrator sentinel"
  run_wired "$CMD" "$(payload prompt "$WS_N" "hello")"
  assert_equals "0" "$CODE" "req-007 AC-007.3: verbatim command exits 0"
  assert_contains "$TRIGGER_TEXT" "$OUT" "req-007 AC-007.3: stdout contains '$TRIGGER_TEXT' (exit 0 alone proves nothing)"

  echo ""
  echo "req-007 AC-007.3: negative fixtures prove the test detects a broken wiring"
  BARE="$(settings_command "$SETTINGS" UserPromptSubmit '.*' auto-trigger-orchestrator.mjs bare)"
  assert_equals "yes" "$(yes_no test -n "$BARE")" "req-007 AC-007.3: bare-path fixture was built"
  assert_equals "no" "$([[ "$BARE" == node* ]] && echo yes || echo no)" "req-007 AC-007.3: bare-path fixture has no node prefix"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      # Git Bash runs a bare .mjs path through its #!/usr/bin/env node line, with no
      # execute bit needed, so the path runs and exits 0. The wrong-directory fixture still runs.
      echo "  SKIP (windows): Git Bash runs a bare .mjs path through its node shebang, so the missing node prefix does not fail"
      ;;
    *)
      run_wired "$BARE" "$(payload prompt "$WS_N" "hello")"
      assert_equals "yes" "$(yes_no test "$CODE" -ne 0)" "req-007 AC-007.3: bare .mjs path with no node prefix exits non-zero (got $CODE)"
      ;;
  esac

  WRONG="$(settings_command "$SETTINGS" UserPromptSubmit '.*' auto-trigger-orchestrator.mjs wrongdir)"
  assert_equals "yes" "$(yes_no test -n "$WRONG")" "req-007 AC-007.3: wrong-directory fixture was built"
  run_wired "$WRONG" "$(payload prompt "$WS_N" "hello")"
  assert_equals "yes" "$(yes_no test "$CODE" -ne 0)" "req-007 AC-007.3: wrong directory exits non-zero (got $CODE)"
fi

print_summary
