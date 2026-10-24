#!/usr/bin/env bash
# Verified by: integration
# test-0000038-req-004-installed-reference-links.sh
# req-004 fix: the orchestrator reference files moved out of SKILL.md keep their
# source links (../standards/x.md). In an install they sit beside the bundled
# standards, so setup must rewrite those links to ./x.md and ./reference/x.md.
# The test installs into a temporary project and resolves every relative link.
# pwsh is not assumed, so setup.ps1 gets a static check for the same rewrites.
# Run from any directory: bash planifest-framework/tests/test-0000038-req-004-installed-reference-links.sh

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"; fi
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"

WS="$(mktemp -d "${TMPDIR:-/tmp}/planifest_0000038_req004_links_XXXXXX")"
trap 'rm -rf "$WS"' EXIT

echo "req-004 links: run setup.sh claude-code into a temporary project"
cp -r "$FRAMEWORK" "$WS/planifest-framework"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash planifest-framework/setup.sh claude-code >/dev/null 2>&1)
assert_exit_zero "$?" "req-004 links: setup.sh claude-code exits 0"

SKILL="$WS/.claude/skills/planifest-orchestrator"

# broken_links FILE: print each relative markdown link target that does not resolve.
broken_links() {
  local file="$1" dir target path
  dir="$(dirname "$file")"
  grep -o '](\([^)]*\))' "$file" | sed 's/^](//;s/)$//' | while IFS= read -r target; do
    path="${target%%#*}"
    case "$path" in
      ""|http://*|https://*|mailto:*) continue ;;
    esac
    # setup bundles only top-level standards. A ./reference/ link is by design
    # unbundled, so it must name a file in the source standards/reference/ folder.
    case "$path" in
      ./reference/*) [ -e "$FRAMEWORK/standards/reference/${path#./reference/}" ] || echo "$target"; continue ;;
    esac
    [ -e "$dir/$path" ] || echo "$target"
  done
}

for name in phase-0-assess-and-coach.md adoption-modes.md; do
  f="$SKILL/references/$name"
  assert_equals "yes" "$([ -f "$f" ] && echo yes || echo no)" "req-004 links: installed $name exists"
  BROKEN="$(broken_links "$f")"
  assert_equals "" "$BROKEN" "req-004 links: every relative link in installed $name resolves"
  LEFT="$(grep -c '\.\./standards/' "$f" || true)"
  assert_equals "0" "$LEFT" "req-004 links: no ../standards/ remains in installed $name"
done

BROKEN="$(broken_links "$SKILL/SKILL.md")"
assert_equals "" "$BROKEN" "req-004 links: every relative link in installed SKILL.md resolves"

echo "req-004 links: source reference files keep their ../standards/ links"
SRC_LEFT="$(grep -c '\.\./standards/' "$FRAMEWORK/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md" || true)"
assert_equals "yes" "$([ "$SRC_LEFT" -gt 0 ] && echo yes || echo no)" "req-004 links: source phase-0 file is unchanged"

echo "req-004 links: setup.ps1 holds both reference rewrites (static check, pwsh not run)"
PS1="$FRAMEWORK/setup.ps1"
assert_equals "yes" "$(grep -q "'\\\\.\\\\./standards/reference/', './reference/'" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 rewrites ../standards/reference/ to ./reference/"
assert_equals "yes" "$(grep -q "'\\\\.\\\\./standards/', './'" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 rewrites ../standards/ to ./"
# Windows PowerShell 5.1 reads UTF-8 with no BOM as ANSI, which garbles the arrows in the moved text.
REF_READ='Get-Content -Path $destRef -Raw -Encoding UTF8'
SKILL_READ='Get-Content -Path $skillMdPath -Raw -Encoding UTF8'
assert_equals "yes" "$(grep -qF -- "$REF_READ" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 reads each reference file as UTF-8"
assert_equals "yes" "$(grep -qF -- "$SKILL_READ" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 reads each SKILL.md as UTF-8"

# Windows PowerShell 5.1 adds a BOM for Set-Content -Encoding UTF8, which sits ahead of the frontmatter.
REF_WRITE='WriteAllText($destRef, $refContent, (New-Object System.Text.UTF8Encoding $false))'
SKILL_WRITE='WriteAllText($skillMdPath, $skillContent, (New-Object System.Text.UTF8Encoding $false))'
BOM_WRITE='Set-Content -Path $destRef'
BOM_SKILL_WRITE='Set-Content -Path $skillMdPath'
assert_equals "yes" "$(grep -qF -- "$REF_WRITE" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 writes each reference file without a BOM"
assert_equals "yes" "$(grep -qF -- "$SKILL_WRITE" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 writes each SKILL.md without a BOM"
assert_equals "no" "$(grep -qF -- "$BOM_WRITE" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 does not use Set-Content for reference files"
assert_equals "no" "$(grep -qF -- "$BOM_SKILL_WRITE" "$PS1" && echo yes || echo no)" "req-004 links: setup.ps1 does not use Set-Content for SKILL.md"

print_summary
