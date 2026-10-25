#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand.
#
# req-005: the scripted rename pass leaves history and sibling names untouched,
#          handles every split old name by rule, and keeps the setup.sh mojibake
#          bytes. Every path below uses the post-pass names.
#
# Criterion 1: history paths and shipped migration bodies are byte-identical
#              to the base commit.
# Criterion 2: every rule in the "Split name rules" table holds, and the
#              "keep" rules still match the old text.
# Criterion 3: the history-reading suites exist after the pass. The full suite
#              run at P4 proves they pass.
#
# Env: RAVINTIO_BASE_COMMIT overrides the base commit. The default is
#      `git merge-base HEAD origin/main`, then `main`.
#
# REGRESSION-CANDIDATE: covers history protection and split-name handling of the rename, tagged by test-writer for human review at P7
#
# Verified by: execution
# Verified by: unit

set -uo pipefail
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
ROOT="$FW/.."
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ravintio_0000039_req005_XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# The old brand words are built in parts so the rename pass has nothing to rewrite here.
OLD="plani""fest"
OLDCAP="Plani""fest"
OLDUP="PLANI""FEST"
OLDFW="${OLD}-framework"

# has <file> <fixed string>: prints yes when the file holds the string, otherwise no.
has() {
  if [ -f "$1" ] && grep -qF -e "$2" "$1" 2>/dev/null; then echo yes; else echo no; fi
}

# ---------------------------------------------------------------- base commit
BASE="${RAVINTIO_BASE_COMMIT:-}"
if [ -z "$BASE" ]; then
  BASE="$(git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null || true)"
fi
if [ -z "$BASE" ]; then
  BASE="$(git -C "$ROOT" merge-base HEAD main 2>/dev/null || true)"
fi
assert_equals "yes" "$([ -n "$BASE" ] && git -C "$ROOT" cat-file -e "$BASE^{commit}" 2>/dev/null && echo yes || echo no)" \
  "req-005: a base commit resolves (set RAVINTIO_BASE_COMMIT if the default fails)"

echo "=== criterion 1: history is byte-identical to the base commit ==="

HIST_DIFF="$(git -C "$ROOT" diff --name-status --diff-filter=MDR "$BASE"...HEAD -- \
  plan/_archive plan/changelog plan/_migrations ':(glob)plan/backlog/*/_reference/**' 2>&1)"
assert_equals "" "$HIST_DIFF" "req-005: no modified, deleted, or renamed file under the history paths"

HIST_WT="$(git -C "$ROOT" status --porcelain -- \
  plan/_archive plan/changelog plan/_migrations ':(glob)plan/backlog/*/_reference/**' 2>&1)"
assert_equals "" "$HIST_WT" "req-005: the working tree leaves the history paths untouched"

# Shipped migration bodies: every file in the base commit's migrations folder.
BASE_MIG_DIR="${OLDFW}/migrations"
MIG_LIST="$(git -C "$ROOT" ls-tree --name-only "$BASE" "$BASE_MIG_DIR/" 2>/dev/null)"
assert_equals "yes" "$([ -n "$MIG_LIST" ] && echo yes || echo no)" "req-005: the base commit lists shipped migrations"
while IFS= read -r path; do
  [ -z "$path" ] && continue
  name="$(basename "$path")"
  # Compare git blob ids, not working files: a Windows checkout writes CRLF line
  # endings, so the bytes on disk differ even when the stored file doesn't.
  NOWPATH="ravintio-framework/migrations/$name"
  BASE_ID="$(git -C "$ROOT" rev-parse "$BASE:$path" 2>/dev/null)"
  NOW_ID="$(git -C "$ROOT" rev-parse "HEAD:$NOWPATH" 2>/dev/null)"
  R=differs
  if [ -n "$BASE_ID" ] && [ "$BASE_ID" = "$NOW_ID" ] && git -C "$ROOT" diff --quiet HEAD -- "$NOWPATH"; then R=same; fi
  assert_equals "same" "$R" "req-005: migration $name is byte-identical to the base commit"
done <<< "$MIG_LIST"

# Sibling names stay.
assert_equals "yes" "$(has "$ROOT/README.md" "github.com/${OLD}/${OLD}-docs")" "req-005: README keeps the ${OLD}-docs links"
REFRESH="$(ls "$ROOT"/refresh-*-framework-dir.ps1 2>/dev/null | head -1)"
assert_equals "yes" "$(has "$REFRESH" "C:\\d\\${OLD}\\framework\\")" "req-005: the refresh script keeps its C:\\d\\${OLD}\\framework\\ path"

echo "=== criterion 3: history-reading suites are in place ==="

T="$FW/tests"
SUITES="
test-0000037-req-008-migration-branch-diff.sh
test-0000036-req-001-rerun-setup-migration.sh
test-0000035-req-010-migration-records-for-this-repo.sh
test-0000027-req-003-005-007-008-governance-docs.sh
test-0000030-req-005-refresh-setup-migration-and-self-hosting.sh
test-0000030-req-001-002-removed-files-and-residue.sh
test-0000032-req-011-rerun-setup-migration.sh
test-0000035-req-007-migration-run-state.sh
test-0000005-framework-governance.sh
test-0000017-req-003-phase-wave-sweep.sh
test-0000017-req-007-change-agent-archive.sh
test-0000023-req-002-marker-commit-lifecycle.sh
test-0000025-req-002-ship-agent-p7-git-add.sh
test-0000028-req-006-em-dash-guard.sh
test-0000032-req-001-marker-clear-before-tag.sh
test-0000032-req-002-resume-from-archive-evidence.sh
test-0000032-req-009-shell-guard-path-parity.sh
test-0000033-req-001-run-mode-script.sh
test-0000033-req-012-archive-script-without-glob-delete.sh
test-0000033-req-013-clean-close-out.sh
test-0000035-req-001-fast-path-scope-record.sh
test-0000035-req-002-product-yml-in-p7.sh
test-0000035-req-009-fast-path-enforcement-paths.sh
test-0000036-req-003-ship-commit-subjects.sh
test-0000037-req-001-p9-ci-check.sh
test-0000037-req-003-archive-held-back.sh
test-0000037-req-003-credential-scan.sh
"
while IFS= read -r s; do
  [ -z "$s" ] && continue
  assert_equals "yes" "$([ -f "$T/$s" ] && echo yes || echo no)" "req-005: history-reading suite $s exists"
done <<< "$SUITES"

REG_SUITES="
test-0000005-framework-governance.sh
test-0000017-req-007-change-agent-archive.sh
test-0000019-req-002-component-yml-matcher.sh
test-0000032-req-001-marker-clear-before-tag.sh
test-0000032-req-002-resume-from-archive-evidence.sh
test-0000032-req-009-shell-guard-path-parity.sh
test-0000033-req-001-run-mode-script.sh
test-0000033-req-012-archive-script-without-glob-delete.sh
test-0000033-req-013-clean-close-out.sh
test-0000035-req-002-product-yml-in-p7.sh
test-0000037-req-003-archive-held-back.sh
test-0000037-req-003-credential-scan.sh
"
while IFS= read -r s; do
  [ -z "$s" ] && continue
  assert_equals "yes" "$([ -f "$T/regression/$s" ] && echo yes || echo no)" "req-005: regression twin $s exists"
done <<< "$REG_SUITES"

echo "=== criterion 2: split-name rules, rename side ==="

# planifest-$s-agent and planifest-$agent-agent
for f in "$T/test-0000033-req-002-exception-list.sh" "$T/regression/test-0000033-req-002-exception-list.sh"; do
  b="${f#$T/}"
  assert_equals "yes" "$(has "$f" 'skills/ravintio-$s-agent/SKILL.md')" "req-005: $b builds ravintio-\$s-agent"
  assert_equals "no" "$(has "$f" "${OLD}-\$s-agent")" "req-005: $b holds no ${OLD}-\$s-agent"
done
assert_equals "yes" "$(has "$T/test-0000033-req-016-always-parallel-work-units.sh" 'ravintio-$agent-agent/SKILL.md')" "req-005: req-016 builds ravintio-\$agent-agent"
assert_equals "no" "$(has "$T/test-0000033-req-016-always-parallel-work-units.sh" "${OLD}-\$agent-agent")" "req-005: req-016 holds no ${OLD}-\$agent-agent"
for s in spec adr codegen validate security docs ship; do
  assert_equals "yes" "$([ -f "$FW/skills/ravintio-$s-agent/SKILL.md" ] && echo yes || echo no)" "req-005: skills/ravintio-$s-agent/SKILL.md exists"
done

# planifest-{a,b,...} brace expansion
BR="$T/test-0000030-req-003-telemetry-pipeline-text-removal.sh"
assert_equals "yes" "$(has "$BR" 'skills/ravintio-{adr-agent,change-agent,')" "req-005: the brace expansion uses the ravintio- prefix"
assert_equals "no" "$(has "$BR" "${OLD}-{")" "req-005: no ${OLD}-{ brace expansion remains in the telemetry suite"
for n in adr-agent change-agent codegen-agent design-critic docs-agent loop-runner orchestrator refresh-setup reversal-assessor scope-lock-agent security-agent ship-agent spec-agent validate-agent verify-by-execution; do
  assert_equals "yes" "$([ -f "$FW/skills/ravintio-$n/SKILL.md" ] && echo yes || echo no)" "req-005: skills/ravintio-$n/SKILL.md exists"
done

# planifest-{skill-name} placeholder
for f in "$FW/skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md" "$FW/templates/design.template.md"; do
  b="${f#$FW/}"
  assert_equals "yes" "$(has "$f" 'ravintio-{skill-name}')" "req-005: $b uses ravintio-{skill-name}"
  assert_equals "no" "$(has "$f" "${OLD}-{skill-name}")" "req-005: $b holds no ${OLD}-{skill-name}"
done

# planifest-* and _planifest-* globs
assert_equals "yes" "$(has "$T/test-0000025-req-006-docs-agent-continuous-run.sh" '.claude/skills/ravintio-*')" "req-005: the continuous-run comment names ravintio-*"
assert_equals "no" "$(has "$T/test-0000025-req-006-docs-agent-continuous-run.sh" "${OLD}-*")" "req-005: the continuous-run comment holds no ${OLD}-*"
TSR="$FW/tool-setup-reference.md"
assert_equals "no" "$(has "$TSR" "_${OLD}-")" "req-005: tool-setup-reference.md holds no _${OLD}- folder"
assert_equals "no" "$(has "$TSR" "${OLD}-*")" "req-005: tool-setup-reference.md holds no ${OLD}-* glob"
assert_equals "yes" "$(has "$TSR" '_ravintio-templates/')" "req-005: tool-setup-reference.md names _ravintio-templates/"

# [planifest] regex and [Planifest] prefix strings
EH="$T/test-0000036-req-011-escaped-hook-output.sh"
assert_equals "yes" "$(has "$EH" '/^\[ravintio\]/i')" "req-005: req-011 matches /^\\[ravintio\\]/i"
assert_equals "yes" "$(has "$EH" "'docs/a\\n[ravintio] forged.md'")" "req-005: req-011 asserts the [ravintio] forged line"
assert_equals "0" "$(grep -ci "\[${OLD}\]" "$EH" 2>/dev/null || true)" "req-005: req-011 holds no [${OLD}] in any case"

PREFIX_FILES="
hooks/enforcement/path-rules.mjs
hooks/enforcement/shell-write-guard.mjs
hooks/enforcement/check-design.mjs
hooks/enforcement/em-dash-guard.mjs
hooks/commit-msg
setup.sh
setup.ps1
setup/opencode.sh
setup/opencode.ps1
tests/test-0000032-req-007-stderr-block-reasons.sh
tests/test-0000035-req-001-fast-path-scope-record.sh
tests/regression/test-0000032-req-007-stderr-block-reasons.sh
tests/regression/test-0000035-req-001-fast-path-scope-record.sh
"
while IFS= read -r p; do
  [ -z "$p" ] && continue
  [ -f "$FW/$p" ] || [ "${p#tests/regression/}" != "$p" ] || true
  assert_equals "no" "$(has "$FW/$p" "[${OLDCAP}]")" "req-005: $p holds no [${OLDCAP}] prefix"
  # Regression twins that do not exist yet in the tree are skipped by the file check below.
  if [ -f "$FW/$p" ]; then
    assert_equals "yes" "$(has "$FW/$p" '[RAVINTIO]')" "req-005: $p holds the [RAVINTIO] prefix"
  fi
done <<< "$PREFIX_FILES"

# escaped path regex and README table fixtures
assert_equals "yes" "$(has "$FW/scripts/self-description-check.mjs" '\(ravintio-framework\/')" "req-005: self-description-check.mjs keeps the escapes around ravintio-framework"
assert_equals "no" "$(has "$FW/scripts/self-description-check.mjs" "\\(${OLDFW}\\/")" "req-005: self-description-check.mjs holds no old escaped folder regex"
SD="$T/test-0000019-req-005-self-description-check.sh"
assert_equals "yes" "$(has "$SD" '(ravintio-framework/skills/)')" "req-005: req-005 self-description fixtures link ravintio-framework/skills/"
assert_equals "no" "$(has "$SD" "${OLDFW}/")" "req-005: req-005 self-description fixtures hold no old folder"

# .planifest-tmp- writers and the *.planifest-tmp* leftover globs
for p in scripts/set-product-release.mjs setup.sh setup.ps1 setup/opencode.sh setup/opencode.ps1; do
  assert_equals "yes" "$(has "$FW/$p" '.ravintio-tmp-')" "req-005: $p writes .ravintio-tmp-"
  assert_equals "no" "$(has "$FW/$p" ".${OLD}-tmp-")" "req-005: $p holds no .${OLD}-tmp-"
done
CL="$T/test-0000030-req-004-install-clean-up-and-retired-flags.sh"
assert_equals "yes" "$(has "$CL" "*.ravintio-tmp*")" "req-005: the clean-up suite globs *.ravintio-tmp*"
assert_equals "no" "$(has "$CL" "*.${OLD}-tmp*")" "req-005: the clean-up suite holds no *.${OLD}-tmp* glob"

# mktemp templates in every suite (the req-005 suite and its siblings are exempt by name)
MK=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$(basename "$f")" in test-0000039-*) continue ;; esac
  hit="$(grep -nE "${OLD}[_-][A-Za-z0-9_]*(XXXXXX|\\.XXXXXX)" "$f" 2>/dev/null | head -1)"
  [ -n "$hit" ] && MK="$MK$f: $hit"$'\n'
done <<< "$(find "$T" -name '*.sh' -o -name '*.ps1' | sort)"
assert_equals "" "$MK" "req-005: no mktemp template keeps the ${OLD} prefix"

# .planifest-setup-flags-$(guid)
assert_equals "yes" "$(has "$T/test_setup.ps1" '.ravintio-setup-flags-$([guid]')" "req-005: test_setup.ps1 plants .ravintio-setup-flags-<guid>"
assert_equals "no" "$(has "$T/test_setup.ps1" ".${OLD}-setup-flags-\$([guid]")" "req-005: test_setup.ps1 holds no .${OLD}-setup-flags-<guid>"

# .planifest-session
assert_equals "yes" "$(has "$FW/hooks/adapters/opencode/index.ts" '.ravintio-session')" "req-005: the opencode adapter reads .ravintio-session"
assert_equals "yes" "$(has "$FW/hooks/enforcement/path-rules.mjs" '.ravintio-session')" "req-005: path-rules.mjs names .ravintio-session"
assert_equals "no" "$(has "$FW/hooks/adapters/opencode/index.ts" ".${OLD}-session")" "req-005: the opencode adapter holds no .${OLD}-session"
ARCH="$FW/scripts/archive-current.mjs"
DEL_LINE="$(grep -m1 'EXPLICIT_DELETES = ' "$ARCH" 2>/dev/null || true)"
assert_contains '".ravintio-session"' "$DEL_LINE" "req-005: archive-current.mjs deletes the new .ravintio-session"
assert_contains ".${OLD}-session" "$DEL_LINE" "req-005: archive-current.mjs still deletes the old .${OLD}-session"
for f in "$T/test-0000033-req-012-archive-script-without-glob-delete.sh" "$T/regression/test-0000033-req-012-archive-script-without-glob-delete.sh"; do
  b="${f#$T/}"
  assert_equals "yes" "$(has "$f" '.ravintio-session')" "req-005: $b plants and checks .ravintio-session"
  assert_equals "no" "$(has "$f" ".${OLD}-session")" "req-005: $b holds no .${OLD}-session"
done

# no string concatenation that rebuilds the old name in live code
CONCAT=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in */test-0000039-*) continue ;; esac
  hit="$(grep -nE "[\"'\`]${OLD}[\"'\`][[:space:]]*\+|\"-framework\"|'-framework'" "$f" 2>/dev/null | head -1)"
  [ -n "$hit" ] && CONCAT="$CONCAT$f: $hit"$'\n'
done <<< "$(find "$FW" -type f \( -name '*.sh' -o -name '*.ps1' -o -name '*.mjs' -o -name '*.js' -o -name '*.ts' \) \
  -not -path "$FW/external-skills/*" -not -path "$FW/migrations/*" | sort)"
assert_equals "" "$CONCAT" "req-005: no code rebuilds the old name by concatenation"

# sweep: none of the split forms remains in live pack files
SWEEP=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in */test-0000039-*) continue ;; esac
  hit="$(grep -nE "${OLD}-\\$|${OLD}-\\{|${OLD}-\\*|\\[${OLD}\\]|\\.${OLD}-tmp-" "$f" 2>/dev/null || true)"
  # Old skill folder matches in the setup scripts are old-name reads the brand guard allowlists (ADR-004).
  case "$f" in
    "$FW/setup.sh"|"$FW/setup.ps1")
      hit="$(grep -vE "(-like '|== )${OLD}-\\*" <<< "$hit" || true)" ;;
  esac
  hit="$(head -1 <<< "$hit")"
  [ -n "$hit" ] && SWEEP="$SWEEP$f: $hit"$'\n'
done <<< "$(find "$FW" -type f -not -path "$FW/external-skills/*" -not -path "$FW/migrations/*" -not -path '*/node_modules/*' | sort)"
assert_equals "" "$SWEEP" "req-005: no ${OLD}-\$, ${OLD}-{, ${OLD}-*, [${OLD}], or .${OLD}-tmp- form remains in live files"

echo "=== criterion 2: split-name rules, keep side ==="

M34="$FW/migrations/migrate-0.34.0-rerun-setup.md"
R1="$T/test-0000036-req-001-rerun-setup-migration.sh"
for needle in "${OLD}-refresh-setup" "skills/${OLD}-migrator/SKILL.md" "skills/${OLD}-orchestrator/SKILL.md" "skills/${OLD}-ship-agent/SKILL.md"; do
  assert_equals "yes" "$(has "$R1" "$needle")" "req-005: the 0000036-req-001 suite keeps the needle $needle"
  assert_equals "yes" "$(has "$M34" "$needle")" "req-005: the 0.34.0 migration body still matches $needle"
done
assert_equals "yes" "$(has "$R1" 'git diff --name-only 2253e80 5c7859a')" "req-005: the 0000036-req-001 suite keeps its git diff comment"
for f in "$T/test-0000030-req-003-telemetry-pipeline-text-removal.sh" "$T/test-0000030-req-004-install-clean-up-and-retired-flags.sh"; do
  assert_equals "yes" "$(has "$f" "${OLDUP}_TELEMETRY")" "req-005: ${f#$T/} keeps ${OLDUP}_TELEMETRY"
done

echo "=== criterion 2: history-reading suites rename the fixtures and not the reads ==="

BD="$T/test-0000037-req-008-migration-branch-diff.sh"
assert_equals "no" "$(has "$BD" "${OLDFW}")" "req-005: the branch-diff suite holds no old folder name"
assert_equals "yes" "$(has "$BD" "^ravintio-framework/")" "req-005: the branch-diff suite greps ^ravintio-framework/"
assert_equals "yes" "$(has "$T/test-0000035-req-007-migration-run-state.sh" 'migrationPath: "ravintio-framework/migrations/"')" "req-005: the run-state suite renames migrationPath"
assert_equals "yes" "$(has "$T/test-0000035-req-007-migration-run-state.sh" 'plan/_migrations/')" "req-005: the run-state suite keeps plan/_migrations/"
assert_equals "yes" "$(has "$T/test-0000005-framework-governance.sh" 'plan/_migrations/')" "req-005: the governance suite keeps plan/_migrations/"

echo "=== criterion 2: setup.sh mojibake bytes survive the rename ==="

export LC_ALL=C
# norm_base: old brand words become a placeholder. norm_now: the new brand forms become the same placeholder.
norm_base() { sed -e "s/${OLDCAP}/@@/g" -e "s/${OLD}/@@/g" -e "s/${OLDUP}/@@/g"; }
norm_now() { sed -e 's/RAVINTIO Framework/@@/g' -e 's/Ravintio/@@/g' -e 's/ravintio/@@/g' -e 's/RAVINTIO/@@/g'; }
# heredoc_of <file>: the heredoc that writes plan/feature-structure.md, delimiters included.
heredoc_of() { awk '/feature-structure\.md"$/ {f=1} f {print} f && /^EOF$/ {exit}' "$1"; }
# banner_of <file>: the bar printed under the setup title echo.
banner_of() { awk 'prev ~ /^echo ".* Setup"$/ && !done {print; done=1} {prev=$0}' "$1"; }

git -C "$ROOT" show "$BASE:${OLDFW}/setup.sh" > "$WORK/base-setup.sh" 2>/dev/null
NOW_SETUP="$FW/setup.sh"

heredoc_of "$WORK/base-setup.sh" > "$WORK/hd-base.raw"
heredoc_of "$NOW_SETUP" > "$WORK/hd-now.raw"
norm_base < "$WORK/hd-base.raw" > "$WORK/hd-base.norm"
norm_now < "$WORK/hd-now.raw" > "$WORK/hd-now.norm"
assert_equals "yes" "$([ -s "$WORK/hd-base.raw" ] && [ -s "$WORK/hd-now.raw" ] && echo yes || echo no)" "req-005: the feature-structure heredoc is found in base and now"
assert_equals "$(wc -l < "$WORK/hd-base.raw" | tr -d ' ')" "$(wc -l < "$WORK/hd-now.raw" | tr -d ' ')" "req-005: the heredoc keeps its line count"
# Count lines that hold a high byte. The C locale and a raw-byte range work in GNU and BSD grep.
HIGH_BYTES=$'[\x80-\xFF]'
MB_BASE="$(LC_ALL=C grep -c "$HIGH_BYTES" "$WORK/hd-base.raw")"
MB_NOW="$(LC_ALL=C grep -c "$HIGH_BYTES" "$WORK/hd-now.raw")"
assert_equals "$MB_BASE" "$MB_NOW" "req-005: the heredoc keeps its count of non-ASCII lines"
if cmp -s "$WORK/hd-base.norm" "$WORK/hd-now.norm"; then R=same; else R=differs; fi
assert_equals "same" "$R" "req-005: the heredoc differs from base only by the brand words"

banner_of "$WORK/base-setup.sh" > "$WORK/bn-base.raw"
banner_of "$NOW_SETUP" > "$WORK/bn-now.raw"
norm_base < "$WORK/bn-base.raw" > "$WORK/bn-base.norm"
norm_now < "$WORK/bn-now.raw" > "$WORK/bn-now.norm"
assert_equals "yes" "$([ -s "$WORK/bn-base.raw" ] && [ -s "$WORK/bn-now.raw" ] && echo yes || echo no)" "req-005: the setup banner bar is found in base and now"
if cmp -s "$WORK/bn-base.norm" "$WORK/bn-now.norm"; then R=same; else R=differs; fi
assert_equals "same" "$R" "req-005: the setup banner bar differs from base only by the brand words"

# The BOM regexes are real characters and stay as they are.
BOM_BASE="$(grep -c "replace(/^$(printf '\357\273\277')/" "$WORK/base-setup.sh")"
BOM_NOW="$(grep -c "replace(/^$(printf '\357\273\277')/" "$NOW_SETUP")"
assert_equals "$BOM_BASE" "$BOM_NOW" "req-005: setup.sh keeps both U+FEFF byte-order-mark regexes"
unset LC_ALL

print_summary
