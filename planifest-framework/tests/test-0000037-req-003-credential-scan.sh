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

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;;
  *) IS_WIN=no ;;
esac

# A PATH that holds node and git only, so gitleaks is absent unless a test adds it.
# Under Git Bash a link is a copy of node.exe or git.exe under a name with no
# extension. The copy cannot start (git needs its install folder), so the scan
# gets the runner PATH there. The runner has no gitleaks.
BIN="$WORK/bin"
if [ "$IS_WIN" = "yes" ]; then
  BIN="$PATH"
else
  mkdir -p "$BIN"
  ln -s "$NODE_BIN" "$BIN/node"
  ln -s "$GIT_BIN" "$BIN/git"
fi

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
if [ "$IS_WIN" = "yes" ]; then
  # Node starts gitleaks without a shell, so it finds only gitleaks.exe. A shell
  # script stand-in is never found, and the scan stays in regex-only mode.
  echo "  SKIP (windows): the gitleaks stand-in is a shell script, and node starts only a gitleaks.exe without a shell"
else
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
fi

# Every content rule, run on a fixture. Each secret is assembled at run time.
echo "req-003: every content rule runs on a fixture"
PAD36="$(printf '%036d' 0)"
rule_case() {
  local rule="$1" text="$2"
  printf 'x %s\n' "$text" >"$WORK/rc.txt"
  run_scan "$WORK" "$BIN" --file rc.txt
  assert_equals "1" "$RC" "req-003: rule $rule matches its fixture"
  assert_contains "rc.txt:1 $rule" "$OUT" "req-003: rule $rule reports path, line, and rule"
  lacks "$text" "$OUT" "req-003: rule $rule prints no matched value"
}
rule_case "aws-access-key" "AKIA""ABCDEFGHIJKLMNOP"
rule_case "aws-temporary-key" "ASIA""ABCDEFGHIJKLMNOP"
rule_case "private-key-block" "-----BEGIN ""RSA PRIVATE KEY""-----"
rule_case "private-key-block" "-----BEGIN ""PGP PRIVATE KEY BLOCK""-----"
rule_case "private-key-block" "-----BEGIN ""PRIVATE KEY""-----"
for P in ghp gho ghs ghu ghr; do
  rule_case "github-token" "${P}""_${PAD36}"
done
rule_case "slack-token" "xo""xb-1234567890"
rule_case "github-pat" "github""_pat_$(printf '%022d' 0)"
rule_case "api-secret-key" "sk""-$(printf '%024d' 0)"
rule_case "google-api-key" "AI""za$(printf '%035d' 0)"

# Every refused file name, run on a staged fixture, in upper and lower case.
echo "req-003: every refused file name runs on a fixture"
R="$(new_repo allnames)"
NAMES=".env .env.local .ENV.prod id_rsa Id_Rsa.bak id_rsa.pub a.p12 b.key c.pem KEY.PEM .npmrc credentials.json d.keystore .netrc"
for N in $NAMES; do printf 'x\n' >"$R/$N"; done
(cd "$R" && git add -f -- $NAMES)
run_scan "$R" "$BIN"
assert_equals "1" "$RC" "req-003: all refused file names exit 1"
for N in $NAMES; do
  assert_contains "$N:1 refused-file-name:" "$OUT" "req-003: refused name $N is reported"
done

# F-01: a NUL byte or UTF-16 does not skip the content rules.
echo "req-003: NUL bytes and UTF-16 do not hide a credential"
mkfix() {
  SECRET="$SECRET" KIND="$1" OUTFILE="$2" "$NODE_BIN" -e '
    const fs = require("fs");
    const s = "key=" + process.env.SECRET + "\n";
    const k = process.env.KIND;
    let b;
    if (k === "nul") b = Buffer.concat([Buffer.from(s), Buffer.from([0])]);
    else if (k === "nulfirst") b = Buffer.concat([Buffer.from([0]), Buffer.from(s)]);
    else if (k === "le") b = Buffer.concat([Buffer.from([0xff, 0xfe]), Buffer.from(s, "utf16le")]);
    else if (k === "lenobom") b = Buffer.from(s, "utf16le");
    else if (k === "be") b = Buffer.concat([Buffer.from([0xfe, 0xff]), Buffer.from(s, "utf16le").swap16()]);
    else if (k === "badle") b = Buffer.from([0xff, 0xfe, 0x41, 0x00, 0x42]);
    else if (k === "bigline") b = Buffer.from("-----BEGIN ".repeat(95000));
    else if (k === "bigblob") b = Buffer.from(s + "a".repeat(1500000) + "\n");
    fs.writeFileSync(process.env.OUTFILE, b);
  '
}
for K in nul nulfirst le lenobom be; do
  mkfix "$K" "$WORK/fx-$K.txt"
  run_scan "$WORK" "$BIN" --file "fx-$K.txt"
  assert_equals "1" "$RC" "req-003: a $K file with a credential exits 1"
  assert_contains "fx-$K.txt:1 aws-access-key" "$OUT" "req-003: a $K file reports the rule"
done
mkfix badle "$WORK/fx-badle.txt"
run_scan "$WORK" "$BIN" --file fx-badle.txt
assert_equals "2" "$RC" "req-003: an undecodable UTF-16 file exits 2, not 0"

# F-02: one 1 MB line scans in linear time.
mkfix bigline "$WORK/fx-bigline.txt"
T0=$SECONDS
run_scan "$WORK" "$BIN" --file fx-bigline.txt
T1=$SECONDS
assert_equals "0" "$RC" "req-003: a 1 MB single line with no key exits 0"
assert_equals "yes" "$([ $((T1 - T0)) -lt 5 ] && echo yes || echo no)" "req-003: a 1 MB single line scans in under 5 seconds"

# F-03: an index blob over 1 MB is still scanned.
R="$(new_repo bigblob)"
mkfix bigblob "$R/big.txt"
(cd "$R" && git add big.txt)
printf 'clean\n' >"$R/big.txt"
run_scan "$R" "$BIN"
assert_equals "1" "$RC" "req-003: a credential in an index blob over 1 MB exits 1"
assert_contains "big.txt:1 aws-access-key" "$OUT" "req-003: the large index blob hit is reported"

# F-13: a run from a subdirectory reads the working-tree copy.
R="$(new_repo subdir)"
mkdir -p "$R/sub"
printf 'clean\n' >"$R/sub/s.txt"
(cd "$R" && git add sub/s.txt)
printf 'key=%s\n' "$SECRET" >"$R/sub/s.txt"
run_scan "$R/sub" "$BIN"
assert_equals "1" "$RC" "req-003: a working-tree credential is found when run from a subdirectory"
assert_contains "sub/s.txt:1" "$OUT" "req-003: the subdirectory hit reports the root-relative path"
run_scan "$R/sub" "$BIN" -- s.txt
assert_equals "1" "$RC" "req-003: a -- path is read relative to the subdirectory"

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
assert_contains 'Credential scan (P{N}): held back {path}' "$STD_SEC" "req-003: standard names the held-back log line"
assert_contains 'git restore --staged -- {path}' "$STD_SEC" "req-003: standard takes a held-back file out of the index"
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

echo "req-003: a held-back file stays staged and shows in the clean-tree check"
R="$(new_repo heldback)"
mkdir -p "$R/docs"
printf 'key %s\n' "$SECRET" >"$R/docs/leak.md"
(cd "$R" && git add docs/leak.md)
run_scan "$R" "$BIN" -- docs/leak.md
assert_equals "1" "$RC" "req-003: the scan holds back a staged file with a credential"
lacks "$SECRET" "$OUT" "req-003: the held-back report prints no matched value"
CLEAN="$(cd "$R" && git status --porcelain --untracked-files=all -- plan/ docs/ ':(glob)src/**/docs/**')"
assert_contains "docs/leak.md" "$CLEAN" "req-003: the held-back file shows in the clean-tree check"
assert_equals "A " "$(printf '%s' "$CLEAN" | cut -c1-2)" "req-003: the held-back file stays staged"

print_summary
