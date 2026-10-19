#!/usr/bin/env bash
# Tests for feature 0000030-context-mode-and-telemetry-mcp-removal.
#
# req-004: setup accepts the three retired flags as no-ops and, on every run,
#          removes stale Context Mode and Telemetry state by command path
#          (ADR-003, ADR-004, ADR-005).
# req-001: a fresh install creates no Context Mode folder or wiring.
# req-002: a fresh install creates no Telemetry folder, sentinel, or wiring.
#
# This file is on the NFR-001 allowlist (tests for REQ-004), so it names the
# retired integrations freely.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP_SH="$FRAMEWORK/setup.sh"
SETUP_PS1="$FRAMEWORK/setup.ps1"

FENCE_BEGIN="BEGIN retired-integrations (0000030)"
FENCE_END="END retired-integrations (0000030)"
RESIDUE_PATTERN='context-mode|context_mode|context mode|structured-telemetry|telemetry|emit_event|backend-url'

yes_no() { if "$@"; then echo "yes"; else echo "no"; fi; }
exists() { [ -e "$1" ]; }
has_text() { grep -q -- "$1" "$2" 2>/dev/null; }

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000030_req004_XXXXXX)
  cp -r "$FRAMEWORK" "$dir/planifest-framework"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

# Content fingerprint of every file in the workspace, outside .git. Lines that
# carry the run timestamp (writtenAt) are left out, because they change on
# every run by design.
fingerprint() {
  (cd "$1" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s ' "$f"
    grep -v '"writtenAt"' "$f" | shasum | cut -d' ' -f1
  done)
}

# Removes the fenced retired-integrations blocks from a file, then prints the rest.
strip_fence() {
  awk -v b="$FENCE_BEGIN" -v e="$FENCE_END" '
    index($0, b) { skip = 1; next }
    index($0, e) { skip = 0; next }
    !skip { print }
  ' "$1"
}

# Writes the stale Claude Code state that 0.28.x setup left behind with both
# integrations enabled, plus hooks a person added by hand.
seed_claude_stale_state() {
  local ws="$1"
  mkdir -p "$ws/.claude/hooks/context-mode" "$ws/.claude/hooks/telemetry" \
           "$ws/.claude/hooks/enforcement" "$ws/plan/.telemetry-failures" \
           "$ws/plan/.telemetry-receipts"
  echo "// stale" > "$ws/.claude/hooks/context-mode/block-grep.mjs"
  echo "// stale" > "$ws/.claude/hooks/telemetry/emit-phase-start.mjs"
  echo "// stale" > "$ws/.claude/hooks/enforcement/check-telemetry-failures.mjs"
  echo "// stale" > "$ws/.claude/hooks/enforcement/check-telemetry-receipts.mjs"
  echo "// stale" > "$ws/.claude/hooks/enforcement/phase-enum.mjs"
  : > "$ws/.claude/telemetry-enabled"
  echo "failure" > "$ws/plan/.telemetry-failures/p1.md"
  echo "{}" > "$ws/plan/.telemetry-receipts/p1.json"
  cat > "$ws/.claude/settings.json" << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Grep", "hooks": [{"type": "command", "command": "node \".claude/hooks/context-mode/block-grep.mjs\" || echo \"[Planifest] did not run\" 1>&2"}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "node \".claude/hooks/context-mode/block-bash.mjs\" || echo \"[Planifest] did not run\" 1>&2"}]},
      {"matcher": "WebFetch", "hooks": [{"type": "command", "command": "node \".claude/hooks/context-mode/block-webfetch.mjs\""}]},
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "PLANIFEST_TELEMETRY_URL=http://localhost:3741 node .claude/hooks/telemetry/resolve-phase.mjs start .claude/hooks/telemetry/emit-phase-start.mjs"}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "node scripts/my-own-bash-guard.mjs"}]},
      {"matcher": "Grep", "hooks": [
        {"type": "command", "command": "node \".claude/hooks/context-mode/block-grep.mjs\""},
        {"type": "command", "command": "echo hand-added-grep-hook"}
      ]}
    ],
    "PostToolUse": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "PLANIFEST_TELEMETRY_URL=http://localhost:3741 node .claude/hooks/telemetry/context-pressure.mjs", "async": true, "timeout": 5000}]},
      {"matcher": "mcp__structured-telemetry-mcp__emit_event", "hooks": [{"type": "command", "command": "node .claude/hooks/telemetry/emit-event-receipt.mjs", "async": true, "timeout": 5000}]},
      {"matcher": "mcp__structured-telemetry-mcp__emit_event", "hooks": [{"type": "command", "command": "echo receipt-by-hand"}]}
    ],
    "Stop": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "PLANIFEST_TELEMETRY_URL=http://localhost:3741 node .claude/hooks/telemetry/resolve-phase.mjs end .claude/hooks/telemetry/emit-phase-end.mjs"}]}
    ],
    "UserPromptSubmit": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/check-telemetry-failures.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/check-telemetry-receipts.mjs\""}]}
    ]
  }
}
JSON
}

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-001 / req-002: fresh install creates no retired integration state ==="

for tool in claude-code cursor opencode antigravity; do
  WS=$(make_workspace)
  out=$(cd "$WS" && bash planifest-framework/setup.sh "$tool" 2>&1)
  assert_exit_zero $? "fresh $tool: setup exits 0"
  stale_dirs=$(cd "$WS" && find . -path ./planifest-framework -prune -o -path ./.git -prune -o \
    -type d \( -name context-mode -o -name telemetry -o -name '.telemetry-*' \) -print)
  assert_equals "" "$stale_dirs" "fresh $tool: no context-mode or telemetry folder"
  assert_equals "no" "$(yes_no exists "$WS/.claude/telemetry-enabled")" \
    "fresh $tool: no .claude/telemetry-enabled"
  wired=$(cd "$WS" && find . -path ./planifest-framework -prune -o -path ./.git -prune -o \
    -type f \( -name 'settings.json' -o -name 'hooks.json' -o -name 'opencode.json' \) -print \
    | xargs grep -ilE "$RESIDUE_PATTERN" 2>/dev/null || true)
  assert_equals "" "$wired" "fresh $tool: no settings file wires a retired hook"
  stale_scripts=$(cd "$WS" && find . -path ./planifest-framework -prune -o -path ./.git -prune -o \
    -type f \( -name 'check-telemetry-*.mjs' -o -name 'phase-enum.mjs' \) -print)
  assert_equals "" "$stale_scripts" "fresh $tool: no check-telemetry-*.mjs or phase-enum.mjs copy"
  if [ "$tool" = "claude-code" ]; then
    for ev in PreToolUse UserPromptSubmit; do
      n=$(node -e 'const s=require(process.argv[1]);console.log((s.hooks&&s.hooks[process.argv[2]]||[]).length)' \
        "$WS/.claude/settings.json" "$ev")
      [ "$n" -gt 0 ] && ok=yes || ok=no
      assert_equals "yes" "$ok" "fresh claude-code: $ev enforcement wiring present"
    done
    gm=$(node -e 'const s=require(process.argv[1]);console.log((s.hooks.PreToolUse||[]).filter(g=>["Grep","Bash","WebFetch"].includes(g.matcher)&&!(g.hooks||[]).some(h=>(h.command||"").includes("shell-write-guard"))).length)' \
      "$WS/.claude/settings.json")
    assert_equals "0" "$gm" "fresh claude-code: no Grep, Bash, or WebFetch PreToolUse entry other than the 0000032 shell-write guard"
  fi
  rm -rf "$WS"
done

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-004: each retired flag prints one notice, exits 0, never reaches the marker ==="

check_retired_flag() {
  local label="$1"; shift
  local WS out rc
  WS=$(make_workspace)
  out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code --strict-orchestrator "$@" 2>&1)
  rc=$?
  assert_exit_zero $rc "$label: setup exits 0"
  local n
  n=$(printf '%s\n' "$out" | grep -c -- "$label was removed in 0.29.0 and has no effect")
  assert_equals "1" "$n" "$label: exactly one removal notice"
  assert_equals "no" "$(yes_no has_text "$label" "$WS/.claude/.planifest-setup-flags")" \
    "$label: install marker holds no retired flag"
  assert_equals "yes" "$(yes_no has_text "--strict-orchestrator" "$WS/.claude/.planifest-setup-flags")" \
    "$label: install marker still records the live flag"
  assert_equals "no" "$(yes_no grep -qiE "$RESIDUE_PATTERN|backendUrl" "$WS/planifest-overrides/setup-config/claude-code.md")" \
    "$label: setup-config override holds no retired flag or URL"
  assert_equals "no" "$(yes_no exists "$WS/.claude/hooks/context-mode")" "$label: no context-mode folder"
  assert_equals "no" "$(yes_no exists "$WS/.claude/hooks/telemetry")" "$label: no telemetry folder"
  assert_equals "no" "$(yes_no exists "$WS/.claude/telemetry-enabled")" "$label: no telemetry sentinel"
  rm -rf "$WS"
}

check_retired_flag "--context-mode-mcp" --context-mode-mcp
check_retired_flag "--structured-telemetry-mcp" --structured-telemetry-mcp
# An unvalidated value: the old parser exited 1 on anything but a plain URL.
check_retired_flag "--backend-url" --backend-url 'not a url; echo injected'

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-004: re-run on a stale Claude Code install removes only stale state ==="

WS=$(make_workspace)
seed_claude_stale_state "$WS"
out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
assert_exit_zero $? "stale claude-code: setup exits 0"

for p in .claude/hooks/context-mode .claude/hooks/telemetry \
         .claude/hooks/enforcement/check-telemetry-failures.mjs \
         .claude/hooks/enforcement/check-telemetry-receipts.mjs \
         .claude/hooks/enforcement/phase-enum.mjs \
         .claude/telemetry-enabled plan/.telemetry-failures plan/.telemetry-receipts; do
  assert_equals "no" "$(yes_no exists "$WS/$p")" "stale claude-code: $p removed"
  assert_contains "$p" "$out" "stale claude-code: removal of $p is reported"
done

SETTINGS="$WS/.claude/settings.json"
assert_equals "no" "$(yes_no grep -qiE "$RESIDUE_PATTERN" "$SETTINGS")" \
  "stale claude-code: settings.json has no stale entry"
assert_equals "yes" "$(yes_no has_text "node scripts/my-own-bash-guard.mjs" "$SETTINGS")" \
  "stale claude-code: hand-added Bash hook kept"
assert_equals "yes" "$(yes_no has_text "echo hand-added-grep-hook" "$SETTINGS")" \
  "stale claude-code: hand-added hook in a mixed group kept"
assert_equals "no" "$(yes_no has_text "echo receipt-by-hand" "$SETTINGS")" \
  "stale claude-code: group with the emit_event matcher removed"
for h in gate-write ratchet-check em-dash-guard auto-trigger-orchestrator check-orchestrator-presence check-design; do
  assert_equals "yes" "$(yes_no has_text "$h.mjs" "$SETTINGS")" "stale claude-code: $h still wired"
  assert_equals "yes" "$(yes_no exists "$WS/.claude/hooks/enforcement/$h.mjs")" "stale claude-code: $h.mjs still installed"
done
assert_equals "yes" "$(yes_no exists "$WS/.claude/hooks/enforcement/read-stdin.mjs")" \
  "stale claude-code: shared read-stdin.mjs still installed"
assert_contains "block-grep.mjs" "$out" "stale claude-code: removed entry reported by command path"
assert_equals "0" "$(find "$WS/.claude" -name '*.planifest-tmp*' | wc -l | tr -d ' ')" \
  "stale claude-code: no temporary settings file left behind"

echo ""
echo "=== req-004 / NFR-002: second run prints no removals and changes no file ==="
before=$(fingerprint "$WS")
out2=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
assert_exit_zero $? "second run: setup exits 0"
after=$(fingerprint "$WS")
assert_equals "$before" "$after" "second run: no file content changes"
removed_lines=$(printf '%s\n' "$out2" | grep -ciE "$RESIDUE_PATTERN" || true)
assert_equals "0" "$removed_lines" "second run: clean-up prints nothing when nothing is found"
rm -rf "$WS"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-004: Tier 1 (cursor) and opencode clean-up ==="

WS=$(make_workspace)
mkdir -p "$WS/.cursor/hooks/telemetry" "$WS/.cursor/hooks/enforcement"
echo "// stale" > "$WS/.cursor/hooks/telemetry/emit-phase-start.mjs"
echo "// stale" > "$WS/.cursor/hooks/enforcement/check-telemetry-failures.mjs"
echo "// stale" > "$WS/.cursor/hooks/enforcement/phase-enum.mjs"
cat > "$WS/.cursor/settings.json" << 'JSON'
{"hooks":{"PreToolUse":[
  {"matcher":"Skill","hooks":[{"type":"command","command":"node .cursor/hooks/telemetry/emit-phase-start.mjs spec"}]},
  {"matcher":"Read","hooks":[{"type":"command","command":"echo cursor-hand-added"}]}
]}}
JSON
out=$(cd "$WS" && bash planifest-framework/setup.sh cursor 2>&1)
assert_exit_zero $? "stale cursor: setup exits 0"
for p in .cursor/hooks/telemetry .cursor/hooks/enforcement/check-telemetry-failures.mjs .cursor/hooks/enforcement/phase-enum.mjs; do
  assert_equals "no" "$(yes_no exists "$WS/$p")" "stale cursor: $p removed"
done
assert_equals "no" "$(yes_no grep -qiE "$RESIDUE_PATTERN" "$WS/.cursor/settings.json")" \
  "stale cursor: settings.json has no stale entry"
assert_equals "yes" "$(yes_no has_text "echo cursor-hand-added" "$WS/.cursor/settings.json")" \
  "stale cursor: hand-added hook kept"
assert_equals "yes" "$(yes_no has_text "cursor.mjs gate-write" "$WS/.cursor/settings.json")" \
  "stale cursor: adapter gate-write registration kept"
rm -rf "$WS"

WS=$(make_workspace)
mkdir -p "$WS/.opencode/hooks/telemetry" "$WS/.opencode/hooks/enforcement"
echo "// stale" > "$WS/.opencode/hooks/telemetry/emit-phase-end.mjs"
echo "// stale" > "$WS/.opencode/hooks/enforcement/check-telemetry-receipts.mjs"
out=$(cd "$WS" && bash planifest-framework/setup.sh opencode 2>&1)
assert_exit_zero $? "stale opencode: setup exits 0"
assert_equals "no" "$(yes_no exists "$WS/.opencode/hooks/telemetry")" "stale opencode: telemetry folder removed"
assert_equals "no" "$(yes_no exists "$WS/.opencode/hooks/enforcement/check-telemetry-receipts.mjs")" \
  "stale opencode: check-telemetry-receipts.mjs removed"
assert_equals "yes" "$(yes_no exists "$WS/.opencode/hooks/enforcement/gate-write.mjs")" \
  "stale opencode: gate-write.mjs still installed"
rm -rf "$WS"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-004 / NFR-004: malformed settings.json stays byte-identical, exit 0 ==="

WS=$(make_workspace)
seed_claude_stale_state "$WS"
printf '{ "hooks": { "PreToolUse": [ broken\n' > "$WS/.claude/settings.json"
sum_before=$(shasum "$WS/.claude/settings.json" | cut -d' ' -f1)
out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
assert_exit_zero $? "malformed: setup exits 0"
sum_after=$(shasum "$WS/.claude/settings.json" | cut -d' ' -f1)
assert_equals "$sum_before" "$sum_after" "malformed: settings.json byte-identical"
assert_contains ".claude/settings.json is not valid JSON" "$out" "malformed: file named in output"
assert_contains "JSON" "$(printf '%s\n' "$out" | grep 'not valid JSON' | head -1)" "malformed: parse error printed"
assert_contains "Setup complete." "$out" "malformed: rest of install finishes"
assert_equals "yes" "$(yes_no exists "$WS/CLAUDE.md")" "malformed: boot file still written"
assert_equals "no" "$(yes_no exists "$WS/.claude/hooks/telemetry")" "malformed: stale folders still removed"
rm -rf "$WS"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-004 / NFR-004: Node missing skips clean-up with a warning, exit 0 ==="

NO_NODE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
if PATH="$NO_NODE_PATH" command -v node >/dev/null 2>&1; then
  echo "  SKIP: node is on the system PATH ($NO_NODE_PATH), cannot simulate a missing Node"
else
  WS=$(make_workspace)
  seed_claude_stale_state "$WS"
  out=$(cd "$WS" && PATH="$NO_NODE_PATH" bash planifest-framework/setup.sh claude-code 2>&1)
  assert_exit_zero $? "no node: setup exits 0"
  assert_contains "stale entries may remain" "$out" "no node: warning printed"
  rm -rf "$WS"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== P5 F1: malformed opencode.json stays byte-identical, exit 0 ==="

WS=$(make_workspace)
printf '{ "plugins": [ broken\n' > "$WS/opencode.json"
sum_before=$(shasum "$WS/opencode.json" | cut -d' ' -f1)
out=$(cd "$WS" && bash planifest-framework/setup.sh opencode 2>&1)
assert_exit_zero $? "malformed opencode.json: setup exits 0"
assert_equals "$sum_before" "$(shasum "$WS/opencode.json" | cut -d' ' -f1)" \
  "malformed opencode.json: file byte-identical"
assert_contains "opencode.json is not valid JSON" "$out" "malformed opencode.json: warning names the file"
assert_contains "Setup complete." "$out" "malformed opencode.json: rest of install finishes"
rm -rf "$WS"

WS=$(make_workspace)
printf '{\n  "theme": "dark",\n  "plugins": ["other-plugin"]\n}\n' > "$WS/opencode.json"
out=$(cd "$WS" && bash planifest-framework/setup.sh opencode 2>&1)
assert_exit_zero $? "valid opencode.json: setup exits 0"
reg=$(node -e 'const j=require(process.argv[1]);console.log(j.theme+" "+j.plugins.join(","))' "$WS/opencode.json")
assert_equals "dark other-plugin,.opencode/plugins/@planifest/opencode-hooks/index.ts" "$reg" \
  "valid opencode.json: plugin appended, other keys kept"
assert_equals "0" "$(find "$WS" -maxdepth 1 -name '*.planifest-tmp*' | wc -l | tr -d ' ')" \
  "valid opencode.json: no temporary file left behind"
rm -rf "$WS"

if PATH="$NO_NODE_PATH" command -v node >/dev/null 2>&1; then
  echo "  SKIP: node is on the system PATH ($NO_NODE_PATH), cannot simulate a missing Node"
else
  WS=$(make_workspace)
  printf '{ "plugins": [ broken\n' > "$WS/opencode.json"
  sum_before=$(shasum "$WS/opencode.json" | cut -d' ' -f1)
  out=$(cd "$WS" && PATH="$NO_NODE_PATH" bash planifest-framework/setup.sh opencode 2>&1)
  assert_exit_zero $? "opencode without node: setup exits 0"
  assert_equals "$sum_before" "$(shasum "$WS/opencode.json" | cut -d' ' -f1)" \
    "opencode without node: malformed opencode.json byte-identical"
  assert_contains "opencode.json" "$(printf '%s\n' "$out" | grep '^  !' || true)" \
    "opencode without node: warning names opencode.json"
  rm -rf "$WS"

  WS=$(make_workspace)
  out=$(cd "$WS" && PATH="$NO_NODE_PATH" bash planifest-framework/setup.sh opencode 2>&1)
  assert_exit_zero $? "opencode without node, fresh: setup exits 0"
  assert_equals "yes" "$(yes_no has_text "opencode-hooks/index.ts" "$WS/opencode.json")" \
    "opencode without node, fresh: opencode.json created with the plugin"
  rm -rf "$WS"
fi

# Run the opencode tool script on its own, outside setup.sh: it must still
# leave a malformed file alone and exit 0.
WS=$(make_workspace)
printf 'not json at all\n' > "$WS/opencode.json"
sum_before=$(shasum "$WS/opencode.json" | cut -d' ' -f1)
out=$(cd "$WS" && bash planifest-framework/setup/opencode.sh 2>&1)
assert_exit_zero $? "opencode.sh alone, malformed: exits 0"
assert_equals "$sum_before" "$(shasum "$WS/opencode.json" | cut -d' ' -f1)" \
  "opencode.sh alone, malformed: file byte-identical"
rm -rf "$WS"

# PowerShell twin (static: pwsh is not installed in CI)
OPENCODE_PS1="$FRAMEWORK/setup/opencode.ps1"
assert_equals "no" "$(yes_no grep -q 'ConvertTo-Json.*| *Set-Content \$OpenCodeJson' "$OPENCODE_PS1")" \
  "opencode.ps1: no direct Set-Content onto opencode.json"
assert_equals "yes" "$(yes_no grep -q 'Write-SettingsFile' "$OPENCODE_PS1")" \
  "opencode.ps1: writes through the atomic Write-SettingsFile helper"
assert_equals "yes" "$(yes_no grep -q 'is not valid JSON' "$OPENCODE_PS1")" \
  "opencode.ps1: warns and skips on a malformed file"
assert_equals "yes" "$(yes_no grep -q 'catch' "$OPENCODE_PS1")" \
  "opencode.ps1: a parse failure is caught, not thrown"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== P5 F2: setup.ps1 clean-up deletes links, not their targets (static) ==="

ps1_fenced=$(awk -v b="$FENCE_BEGIN" -v e="$FENCE_END" 'index($0,b){s=1} s{print} index($0,e){s=0}' "$SETUP_PS1")
assert_equals "0" "$(printf '%s\n' "$ps1_fenced" | grep -c 'Remove-Item -Path' || true)" \
  "setup.ps1 clean-up: no Remove-Item -Path (wildcards, follows links)"
assert_contains "Remove-Item -LiteralPath" "$ps1_fenced" "setup.ps1 clean-up: deletes by -LiteralPath"
assert_contains "ReparsePoint" "$ps1_fenced" "setup.ps1 clean-up: checks for a link or junction"
assert_contains ".Delete()" "$ps1_fenced" "setup.ps1 clean-up: removes a link itself, without recursing"
assert_contains 'Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue' "$ps1_fenced" \
  "setup.ps1 clean-up: finds dangling links with Get-Item, not Test-Path"
assert_equals "0" "$(printf '%s\n' "$ps1_fenced" | grep -c 'Test-Path \$full' || true)" \
  "setup.ps1 clean-up: no Test-Path on the delete target"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== P5 F3: clean-up never deletes outside the project through a link ==="

# A stale path that is itself a link: the link goes, the folder it points to stays.
WS=$(make_workspace)
OUTSIDE=$(mktemp -d -t planifest_0000030_outside_XXXXXX)
mkdir -p "$OUTSIDE/target" "$WS/plan"
echo "keep me" > "$OUTSIDE/target/sentinel.txt"
ln -s "$OUTSIDE/target" "$WS/plan/.telemetry-failures"
out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
assert_exit_zero $? "linked leaf: setup exits 0"
assert_equals "yes" "$(yes_no exists "$OUTSIDE/target/sentinel.txt")" \
  "linked leaf: file behind the link survives"
assert_equals "no" "$(yes_no test -L "$WS/plan/.telemetry-failures")" "linked leaf: the link is removed"
rm -rf "$WS" "$OUTSIDE"

# A parent folder that is a link out of the project: nothing under it is deleted.
WS=$(make_workspace)
OUTSIDE=$(mktemp -d -t planifest_0000030_outside_XXXXXX)
mkdir -p "$OUTSIDE/.telemetry-failures"
echo "keep me" > "$OUTSIDE/.telemetry-failures/sentinel.txt"
ln -s "$OUTSIDE" "$WS/plan"
out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
assert_exit_zero $? "linked parent: setup exits 0"
assert_equals "yes" "$(yes_no exists "$OUTSIDE/.telemetry-failures/sentinel.txt")" \
  "linked parent: folder outside the project is not deleted"
assert_contains "plan/.telemetry-failures resolves outside the project" "$out" \
  "linked parent: refusal is reported"
rm -rf "$WS" "$OUTSIDE"

# PowerShell twin (static)
ps1_fenced=$(awk -v b="$FENCE_BEGIN" -v e="$FENCE_END" 'index($0,b){s=1} s{print} index($0,e){s=0}' "$SETUP_PS1")
assert_contains "resolves outside the project" "$ps1_fenced" \
  "setup.ps1 clean-up: refuses a path whose parent is a link"
sh_fenced=$(awk -v b="$FENCE_BEGIN" -v e="$FENCE_END" 'index($0,b){s=1} s{print} index($0,e){s=0}' "$SETUP_SH")
assert_contains "pwd -P" "$sh_fenced" "setup.sh clean-up: resolves the parent folder physically"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== P5 F4: a failed delete warns and setup carries on, exit 0 ==="

if [ "$(id -u)" = "0" ]; then
  echo "  SKIP: running as root, a read-only folder cannot block a delete"
else
  WS=$(make_workspace)
  LOCKED="$WS/.claude/hooks/telemetry"
  mkdir -p "$LOCKED"
  echo "// stale" > "$LOCKED/emit-phase-start.mjs"
  chmod 555 "$LOCKED"
  trap 'chmod 755 "$LOCKED" 2>/dev/null' EXIT
  out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
  assert_exit_zero $? "undeletable folder: setup exits 0"
  assert_contains "could not remove .claude/hooks/telemetry" "$out" "undeletable folder: warning printed"
  assert_contains "Setup complete." "$out" "undeletable folder: rest of install finishes"
  chmod 755 "$LOCKED"
  trap - EXIT
  rm -rf "$WS"
fi

# PowerShell twin (static)
ps1_fenced=$(awk -v b="$FENCE_BEGIN" -v e="$FENCE_END" 'index($0,b){s=1} s{print} index($0,e){s=0}' "$SETUP_PS1")
assert_contains "could not remove" "$ps1_fenced" "setup.ps1 clean-up: a failed delete warns"
assert_contains "catch" "$(printf '%s\n' "$ps1_fenced" | sed -n '/foreach (\$p in \$stale)/,$p')" \
  "setup.ps1 clean-up: each delete is wrapped in try/catch"
ws_fn=$(sed -n '/^function Write-SettingsFile/,/^}/p' "$SETUP_PS1")
assert_contains "catch" "$ws_fn" "setup.ps1 Write-SettingsFile: a failed rename is caught"
assert_contains 'Remove-Item -LiteralPath $tmp' "$ws_fn" "setup.ps1 Write-SettingsFile: temporary file removed on failure"
assert_contains "left unchanged" "$ws_fn" "setup.ps1 Write-SettingsFile: failure warns, original untouched"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== P5 F5: a rewritten settings file keeps its mode, temp file is exclusive ==="

WS=$(make_workspace)
seed_claude_stale_state "$WS"
chmod 600 "$WS/.claude/settings.json"
out=$(cd "$WS" && bash planifest-framework/setup.sh claude-code 2>&1)
assert_exit_zero $? "0600 settings: setup exits 0"
assert_contains "block-grep.mjs" "$out" "0600 settings: clean-up rewrote the file"
mode=$(node -e 'console.log((require("fs").statSync(process.argv[1]).mode & 0o777).toString(8))' "$WS/.claude/settings.json")
assert_equals "600" "$mode" "0600 settings: mode 0600 kept after the rewrite"
assert_equals "0" "$(find "$WS/.claude" -name '*.planifest-tmp*' | wc -l | tr -d ' ')" \
  "0600 settings: no temporary file left behind"
rm -rf "$WS"

for f in "$SETUP_SH" "$SETUP_PS1"; do
  name=$(basename "$f")
  helper=$(sed -n '/^function writeSettings/,/^}/p' "$f")
  assert_contains "randomBytes" "$helper" "$name writeSettings: temporary name is random"
  assert_contains "wx" "$helper" "$name writeSettings: temporary file is created exclusively"
  assert_contains "statSync(sf).mode" "$helper" "$name writeSettings: copies the target's mode"
  assert_contains "unlinkSync(tmp)" "$helper" "$name writeSettings: removes the temporary file on failure"
done
ws_fn=$(sed -n '/^function Write-SettingsFile/,/^}/p' "$SETUP_PS1")
assert_contains "CreateNew" "$ws_fn" "setup.ps1 Write-SettingsFile: temporary file is created exclusively"
assert_contains "NewGuid" "$ws_fn" "setup.ps1 Write-SettingsFile: temporary name is random"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== req-004: setup.sh and setup.ps1 parity (static) ==="

for f in "$SETUP_SH" "$SETUP_PS1"; do
  name=$(basename "$f")
  assert_equals "yes" "$(yes_no has_text "# $FENCE_BEGIN" "$f")" "$name: opening fence marker present"
  assert_equals "yes" "$(yes_no has_text "# $FENCE_END" "$f")" "$name: closing fence marker present"
  b=$(grep -c -- "$FENCE_BEGIN" "$f"); e=$(grep -c -- "$FENCE_END" "$f")
  assert_equals "$b" "$e" "$name: fence markers are balanced"
  fenced=$(awk -v b="$FENCE_BEGIN" -v e="$FENCE_END" 'index($0,b){s=1} s{print} index($0,e){s=0}' "$f")
  for needle in "--context-mode-mcp" "--structured-telemetry-mcp" "--backend-url" \
                "was removed in 0.29.0 and has no effect" \
                "mcp__structured-telemetry-mcp__emit_event" \
                "check-telemetry-failures.mjs" "check-telemetry-receipts.mjs" "phase-enum.mjs" \
                "telemetry-enabled" ".telemetry-failures" ".telemetry-receipts" \
                "not valid JSON" "stale entries may remain" "writeSettings("; do
    assert_contains "$needle" "$fenced" "$name: fenced block handles $needle"
  done
  # writeSettings is the shared helper that writes a temporary file, then renames it
  assert_equals "yes" "$(yes_no grep -q 'renameSync(tmp, sf)' "$f")" \
    "$name: settings writes go through a temporary file then a rename"
done
assert_equals "yes" "$(yes_no grep -q 'Move-Item -LiteralPath \$tmp' "$SETUP_PS1")" \
  "setup.ps1: PowerShell-native settings writes also go through a temporary file"

echo ""
echo "=== NFR-001: no residue outside the fenced blocks in the setup and adapter files ==="

for f in "$SETUP_SH" "$SETUP_PS1" "$FRAMEWORK"/setup/*.sh "$FRAMEWORK"/setup/*.ps1 \
         "$FRAMEWORK/hooks/adapters/cursor.mjs" "$FRAMEWORK/hooks/adapters/cline.mjs" \
         "$FRAMEWORK/hooks/adapters/opencode/index.ts"; do
  rel="${f#"$FRAMEWORK"/}"
  hits=$(strip_fence "$f" | grep -inE "$RESIDUE_PATTERN" || true)
  assert_equals "" "$hits" "$rel: no residue outside the fence"
done

print_summary
