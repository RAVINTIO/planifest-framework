#!/usr/bin/env bash
# Tests for feature 0000030 req-003: telemetry and context-mode text removed
# from Planifest-owned skills, templates, standards and living docs (NFR-001).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FRAMEWORK/.." && pwd)"

PATTERN='telemetry|context-mode|context_mode|structured-telemetry|emit_event|telemetry-standards|PLANIFEST_TELEMETRY'

has_text() {
  local file="$1" needle="$2" msg="$3"
  assert_equals "yes" "$(grep -qF -- "$needle" "$file" && echo yes || echo no)" "$msg"
}

# Strip allowlisted regions from a file and print the remainder.
# Allowlist: the refresh-setup BEGIN/END fenced note and decisions-index
# superseded rows plus the 0000030 section.
filtered() {
  local f="$1"
  case "$f" in
    */decisions-index.md)
      awk '/^### Feature 0000030/{skip=1} /^### Feature /&&!/^### Feature 0000030/{skip=0}
           !skip && !/superseded/ {print}' "$f" ;;
    *)
      awk '/BEGIN retired-integrations \(0000030\)/{skip=1; next}
           /END retired-integrations \(0000030\)/{skip=0; next}
           !skip {print}' "$f" ;;
  esac
}

FILES=()
for f in "$FRAMEWORK"/skills/planifest-{adr-agent,change-agent,codegen-agent,design-critic,docs-agent,loop-runner,orchestrator,refresh-setup,reversal-assessor,scope-lock-agent,security-agent,ship-agent,spec-agent,validate-agent,verify-by-execution}/SKILL.md; do
  FILES+=("$f")
done
FILES+=(
  "$FRAMEWORK/templates/build-log.template.md"
  "$FRAMEWORK/templates/standard-boot.md"
  "$ROOT/README.md"
  "$FRAMEWORK/getting-started.md"
  "$FRAMEWORK/pipeline-reference.md"
  "$FRAMEWORK/project-operations.md"
  "$FRAMEWORK/tool-setup-reference.md"
  "$FRAMEWORK/standards/reference/backend-stack-evaluation.md"
  "$FRAMEWORK/standards/agent-dispatch-standards.md"
  "$ROOT/refresh-planifest-framework-dir.ps1"
  "$FRAMEWORK/component.yml"
  "$ROOT/src/setup-hook-integration/component.yml"
  "$ROOT/docs/about.md"
  "$ROOT/docs/architecture-overview.md"
  "$ROOT/docs/component-registry.md"
  "$ROOT/docs/dependency-graph.md"
  "$ROOT/docs/decisions-index.md"
)
for f in "$ROOT"/src/setup-hook-integration/docs/*.md; do FILES+=("$f"); done

echo "req-003: no telemetry or context-mode text in Planifest-owned files"
for f in "${FILES[@]}"; do
  rel="${f#$ROOT/}"
  if [ ! -f "$f" ]; then
    assert_equals "exists" "missing" "req-003: $rel exists"
    continue
  fi
  hits=$(filtered "$f" | grep -iE "$PATTERN" | head -3)
  assert_equals "" "$hits" "req-003: $rel has no telemetry or context-mode text"
done

echo "req-003: deleted files are gone"
for rel in planifest-framework/standards/telemetry-standards.md \
  docs/0008b--feature--structured-telemetry-framework-integration.md \
  docs/0008c--feature--structured-telemetry-mcp-changes.md; do
  assert_equals "gone" "$([ -e "$ROOT/$rel" ] && echo present || echo gone)" "req-003: $rel deleted"
done

echo "req-003: orchestrator keeps the product id hard-stop"
ORCH="$FRAMEWORK/skills/planifest-orchestrator/SKILL.md"
has_text "$ORCH" "No declared product id found" "req-003: orchestrator keeps product id hard-stop prompt"
has_text "$ORCH" "hard-stop" "req-003: orchestrator still says hard-stop"
prompt=$(grep -A6 'No declared product id found' "$ORCH")
assert_equals "" "$(printf '%s' "$prompt" | grep -i telemetry)" "req-003: product id prompt does not mention telemetry"

echo "req-003: refresh-setup note is fenced"
RS="$FRAMEWORK/skills/planifest-refresh-setup/SKILL.md"
has_text "$RS" "BEGIN retired-integrations (0000030)" "req-003: refresh-setup has BEGIN marker"
has_text "$RS" "END retired-integrations (0000030)" "req-003: refresh-setup has END marker"

echo "req-003: decisions index has 0000030 section"
has_text "$ROOT/docs/decisions-index.md" "### Feature 0000030: context-mode-and-telemetry-mcp-removal" "req-003: decisions-index lists feature 0000030"

print_summary
