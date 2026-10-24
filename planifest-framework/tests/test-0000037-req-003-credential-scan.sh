#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship.
#
# req-003: an autonomous run scans staged files for credentials before each
#          commit and holds back the commit and push on a match.
#          credential-scan.mjs detects and reports. Skill text enforces the stop.
#
# Verified by: integration
# REGRESSION-CANDIDATE: covers the credential-scan script contract and its enforcement text, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
SCAN="$FW/scripts/credential-scan.mjs"
STD="$FW/standards/autonomous-run-standards.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
SHIP="$FW/skills/planifest-ship-agent/SKILL.md"
NODE_BIN="$(command -v node)"
GIT_BIN="$(command -v git)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A PATH that holds node and git only, so gitleaks is absent unless a test adds it.
BIN="$WORK/bin"
mkdir -p "$BIN"
ln -s "$NODE_BIN" "$BIN/node"
ln -s "$GIT_BIN" "$BIN/git"

# The fixture credential is assembled at run time so this file holds no secret.
SECRET="AKIA""ABCDEFGHIJKLMNOP"

# section <heading-prefix> <file>: prints one `## ` section, heading included.
section() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$2"
}

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# new_repo <name>: creates an empty repository and prints its path.
new_repo() {
  local d="$WORK/$1"
  mkdir -p "$d"
  (cd "$d" && git init -q)
  printf '%s' "$d"
}

# run_scan <dir> <path-var> [args...]: sets OUT and RC.
run_scan() {
  local dir="$1" p="$2"
  shift 2
  OUT="$(cd "$dir" && PATH="$p" "$NODE_BIN" "$SCAN" "$@" 2>&1)"
  RC=$?
}

echo "req-003: credential-scan.mjs behaviour"

assert_equals "yes" "$([ -f "$SCAN" ] && echo yes || echo no)" "req-003: credential-scan.mjs exists"

# Clean staged file, no gitleaks.
R="$(new_repo clean)"
printf 'hello\n' >"$R/a.txt"
(cd "$R" && git add a.txt)
run_scan "$R" "$BIN"
assert_equals "0" "$RC" "req-003: clean staged file exits 0"
assert_contains "scan mode: regex only (gitleaks not found)" "$OUT" "req-003: regex-only mode is announced"

# Staged credential.
R="$(new_repo staged)"
printf 'ok\nkey=%s\n' "$SECRET" >"$R/conf.txt"
(cd "$R" && git add conf.txt)
run_scan "$R" "$BIN"
assert_equals "1" "$RC" "req-003: staged credential exits 1"
assert_contains "conf.txt:2" "$OUT" "req-003: hit prints path and line"
lacks "$SECRET" "$OUT" "req-003: output never prints the secret"

# Credential added after git add, committed with -- path (working tree differs from index).
R="$(new_repo worktree)"
printf 'clean\n' >"$R/w.txt"
(cd "$R" && git add w.txt)
printf 'clean\nkey=%s\n' "$SECRET" >"$R/w.txt"
run_scan "$R" "$BIN" -- w.txt
assert_equals "1" "$RC" "req-003: credential added after git add exits 1 with -- path"
assert_contains "w.txt:2" "$OUT" "req-003: working-tree hit prints path and line"

# Path named after -- but never staged.
R="$(new_repo unstaged)"
printf 'key=%s\n' "$SECRET" >"$R/u.txt"
run_scan "$R" "$BIN" -- u.txt
assert_equals "1" "$RC" "req-003: unstaged path named after -- is scanned"

# Credential in the index only (working tree cleaned afterwards).
R="$(new_repo indexonly)"
printf 'key=%s\n' "$SECRET" >"$R/i.txt"
(cd "$R" && git add i.txt)
printf 'clean\n' >"$R/i.txt"
run_scan "$R" "$BIN"
assert_equals "1" "$RC" "req-003: credential in the index blob alone exits 1"

# Refused file names.
R="$(new_repo names)"
printf 'x\n' >"$R/.env"
printf 'x\n' >"$R/server.pem"
(cd "$R" && git add .env server.pem)
run_scan "$R" "$BIN"
assert_equals "1" "$RC" "req-003: refused file names exit 1"
assert_contains ".env:" "$OUT" "req-003: .env is reported by path"
assert_contains "server.pem:" "$OUT" "req-003: *.pem is reported by path"

# gitleaks on PATH.
FAKE="$WORK/fakebin"
mkdir -p "$FAKE"
ln -s "$NODE_BIN" "$FAKE/node"
ln -s "$GIT_BIN" "$FAKE/git"
printf '#!/bin/sh\nexit 0\n' >"$FAKE/gitleaks"
chmod +x "$FAKE/gitleaks"
R="$(new_repo gl-clean)"
printf 'hello\n' >"$R/a.txt"
(cd "$R" && git add a.txt)
run_scan "$R" "$FAKE"
assert_equals "0" "$RC" "req-003: clean file with gitleaks present exits 0"
assert_contains "scan mode: regex and gitleaks" "$OUT" "req-003: gitleaks mode is announced"

printf '#!/bin/sh\nexit 1\n' >"$FAKE/gitleaks"
run_scan "$R" "$FAKE"
assert_equals "1" "$RC" "req-003: a gitleaks finding exits 1"

# Exit 2 when the scan cannot run.
NOREPO="$WORK/norepo"
mkdir -p "$NOREPO"
run_scan "$NOREPO" "$BIN"
assert_equals "2" "$RC" "req-003: outside a repository exits 2"
assert_contains "scan could not run:" "$OUT" "req-003: exit 2 prints the reason"

# Path sanitising.
R="$(new_repo sanitise)"
printf 'key=%s\n' "$SECRET" >"$R/a\$b.txt"
(cd "$R" && git add -- 'a$b.txt')
run_scan "$R" "$BIN"
assert_contains 'a?b.txt:1' "$OUT" "req-003: unsafe path characters print as ?"

echo "req-003: enforcement text"

STD_SEC="$(section '## Pre-commit credential scan' "$STD")"
assert_contains "credential-scan.mjs" "$STD_SEC" "req-003: standard orders the script"
assert_contains "index blob" "$STD_SEC" "req-003: standard names the index blob"
assert_contains "working-tree file" "$STD_SEC" "req-003: standard names the working-tree file"
assert_contains 'exit `1` or `2`' "$STD_SEC" "req-003: standard stops on exit 1 or 2"
assert_contains "no \`git commit\` and no \`git push\`" "$STD_SEC" "req-003: standard holds back commit and push"
assert_contains "stay staged" "$STD_SEC" "req-003: standard keeps files staged"
assert_contains 'Credential scan (P{N}): held back {n} file(s)' "$STD_SEC" "req-003: standard names the held-back log line"
assert_contains 'Exception waiting (P{N}, 7): credential sighting in {path}:{line}' "$STD_SEC" "req-003: standard names the exception line"
assert_contains 'Credential scan (P{N}): clean ({scan mode})' "$STD_SEC" "req-003: standard names the clean log line"

HL7="$(grep -n '^7\. \*\*Commit after every' "$ORCH")"
assert_contains "autonomous-run-standards.md" "$HL7" "req-003: Hard Limit 7 points to the standard"
RESUME="$(section '## Resume Detection' "$ORCH")"
assert_contains "held-back staged file" "$RESUME" "req-003: Resume Detection covers a held-back staged file"
assert_contains "credential-scan.mjs" "$RESUME" "req-003: Resume Detection reruns the scan"

SHIP_TXT="$(cat "$SHIP")"
assert_contains "node planifest-framework/scripts/credential-scan.mjs" "$SHIP_TXT" "req-003: ship skill calls the script"
lacks "grep -lE" "$SHIP_TXT" "req-003: ship skill holds no inline grep pattern list"
GUARD="$(awk '/^\*\*P8 credential guard/ { on = 1 } on && /^- \*\*No leftovers/ { exit } on { print }' "$SHIP")"
assert_contains "credential-scan.mjs" "$GUARD" "req-003: P8 guard calls the script"
assert_contains "by path only" "$GUARD" "req-003: P8 guard reports by path only"
assert_contains "stays uncommitted" "$GUARD" "req-003: P8 guard leaves the file uncommitted"
STEP10B="$(awk '/^### Step 10b/ { on = 1 } on && /^## / { exit } on { print }' "$SHIP")"
assert_contains "credential-scan.mjs" "$STEP10B" "req-003: Step 10b guard calls the script"

print_summary
