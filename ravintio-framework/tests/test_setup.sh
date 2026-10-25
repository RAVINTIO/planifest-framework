#!/usr/bin/env bash
set -euo pipefail

echo "Running setup.sh tests..."

# Create a temporary test workspace
TEST_DIR=$(mktemp -d -t ravintio_test_XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

# Copy the framework into the test workspace
FRAMEWORK_SRC=$(cd "$(dirname "$0")/.." && pwd)
cp -r "$FRAMEWORK_SRC" "$TEST_DIR/ravintio-framework"

cd "$TEST_DIR"

echo "--- Testing: claude-code ---"
./ravintio-framework/setup.sh claude-code

if [ ! -d ".claude/skills" ]; then
    echo "FAIL: .claude/skills directory not created"
    exit 1
fi

if [ ! -f ".claude/skills/ravintio-orchestrator/SKILL.md" ]; then
    echo "FAIL: SKILL.md not copied for claude-code"
    exit 1
fi

if [ ! -f "CLAUDE.md" ]; then
    echo "FAIL: CLAUDE.md boot file not created"
    exit 1
fi

if [ ! -f ".claude/commands/feature-pipeline.md" ]; then
    echo "FAIL: Workflow command not created for claude-code"
    exit 1
fi

echo "--- Testing: cursor ---"
./ravintio-framework/setup.sh cursor

if [ ! -d ".cursor/skills" ]; then
    echo "FAIL: .cursor/skills directory not created"
    exit 1
fi

if [ ! -f ".cursor/skills/ravintio-orchestrator/SKILL.md" ]; then
    echo "FAIL: SKILL.md not copied for cursor"
    exit 1
fi

# req-010 (feature 0000032): setup registers shell-write-guard.mjs for the Bash
# tool exactly once, and a Bash group the human on the loop added survives.
echo "--- Testing: req-010 shell-write-guard registration ---"
REG_DIR="$TEST_DIR/req-010"
mkdir -p "$REG_DIR/.claude"
cp -r "$FRAMEWORK_SRC" "$REG_DIR/ravintio-framework"
cat > "$REG_DIR/.claude/settings.json" <<'JSON'
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo human-bash-hook"}]}]}}
JSON
(cd "$REG_DIR" && ./ravintio-framework/setup.sh claude-code >/dev/null && ./ravintio-framework/setup.sh claude-code >/dev/null)

REG_RESULT=$(node -e '
  const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf-8"));
  const bash = (s.hooks?.PreToolUse || []).filter((g) => g.matcher === "Bash");
  const has = (g, text) => (g.hooks || []).some((h) => (h.command || "").includes(text));
  const guard = bash.filter((g) => has(g, "shell-write-guard.mjs")).length;
  const human = bash.filter((g) => has(g, "human-bash-hook")).length;
  process.stdout.write(guard + " " + human);
' "$REG_DIR/.claude/settings.json")

if [ "$REG_RESULT" != "1 1" ]; then
    echo "FAIL: req-010: expected one shell-write-guard Bash group and one human Bash group after two runs, found '$REG_RESULT'"
    exit 1
fi
echo "  PASS: req-010: two setup.sh runs leave one shell-write-guard Bash group"
echo "  PASS: req-010: the human Bash group survives both runs"

if [ ! -f "$REG_DIR/.claude/hooks/enforcement/shell-write-guard.mjs" ]; then
    echo "FAIL: req-010: .claude/hooks/enforcement/shell-write-guard.mjs not installed"
    exit 1
fi
echo "  PASS: req-010: shell-write-guard.mjs is installed"

if [ -f ".cursor/settings.json" ] && [[ "$(cat .cursor/settings.json)" == *"shell-write-guard"* ]]; then
    echo "FAIL: req-010: cursor settings register shell-write-guard, which is Claude Code only"
    exit 1
fi
echo "  PASS: req-010: cursor settings don't register shell-write-guard"

echo "SUCCESS: All setup.sh tests passed."

