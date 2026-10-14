#!/usr/bin/env bash
# OpenCode - tool configuration (Tier 2: Bun/TS plugin shim)
# https://opencode.ai
#
# Registers the @planifest/opencode-hooks plugin in opencode.json.
# Requires: Bun runtime (bundled with OpenCode).

# This file lives in planifest-framework/setup/, so the framework root is one
# level up and the project root two levels up.
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENCODE_JSON="$PROJECT_ROOT/opencode.json"
PLUGIN_SRC="$SCRIPT_DIR/hooks/adapters/opencode"
PLUGIN_DEST="$PROJECT_ROOT/.opencode/plugins/@planifest/opencode-hooks"

echo ""
echo "  Setting up OpenCode (Tier 2: plugin shim)"

# Verify Bun is available
if ! command -v bun &>/dev/null; then
  echo "  ! Warning: bun not found in PATH. The @planifest/opencode-hooks plugin"
  echo "    requires Bun (bundled with OpenCode). Ensure opencode is installed and"
  echo "    bun is in your PATH before using enforcement hooks."
fi

# Copy plugin source
mkdir -p "$PLUGIN_DEST"
cp "$PLUGIN_SRC/index.ts" "$PLUGIN_DEST/index.ts"
cp "$PLUGIN_SRC/package.json" "$PLUGIN_DEST/package.json"
echo "  + .opencode/plugins/@planifest/opencode-hooks/"

# Copy shared hook scripts for the plugin to delegate to
HOOKS_DEST="$PROJECT_ROOT/.opencode/hooks"
mkdir -p "$HOOKS_DEST/enforcement"

for script in "$SCRIPT_DIR/hooks/enforcement/"*.mjs; do
  [ -f "$script" ] || continue
  cp "$script" "$HOOKS_DEST/enforcement/$(basename "$script")"
  echo "  + .opencode/hooks/enforcement/$(basename "$script")"
done

# Register plugin in opencode.json (idempotent). If the file exists but is not
# valid JSON, or Node.js is missing, it is left byte-identical and setup carries
# on with a warning. Every write goes to a temporary file in the same folder,
# then is renamed into place, so a crash can never leave a truncated file.
# setup.sh passes its shared Node helpers in PLANIFEST_SETTINGS_JS_HELPERS.
PLUGIN_REF=".opencode/plugins/@planifest/opencode-hooks/index.ts"

if [ -e "$OPENCODE_JSON" ] || [ -L "$OPENCODE_JSON" ]; then
  if ! command -v node >/dev/null 2>&1; then
    echo "  ! opencode.json not checked (Node.js not found) - left unchanged, register $PLUGIN_REF by hand"
  elif [ -z "${PLANIFEST_SETTINGS_JS_HELPERS:-}" ]; then
    echo "  ! opencode.json not checked (run planifest-framework/setup.sh opencode) - left unchanged"
  else
    PLANIFEST_OPENCODE_JSON="$OPENCODE_JSON" PLANIFEST_PLUGIN_REF="$PLUGIN_REF" \
    node -e "$PLANIFEST_SETTINGS_JS_HELPERS"'
      const sf = process.env.PLANIFEST_OPENCODE_JSON, ref = process.env.PLANIFEST_PLUGIN_REF;
      const j = readSettings(sf, "opencode.json", "plugin registration");
      if (j === null) process.exit(0);
      if (!j || typeof j !== "object" || Array.isArray(j) ||
          (j.plugins !== undefined && !Array.isArray(j.plugins))) {
        console.log("  ! opencode.json is not valid JSON (no plugins list) - left unchanged, skipped plugin registration");
        process.exit(0);
      }
      const plugins = j.plugins || [];
      if (plugins.includes(ref)) {
        console.log("  - opencode.json (plugin already registered)");
        process.exit(0);
      }
      j.plugins = plugins.concat([ref]);
      if (writeSettings(sf, j) !== false) console.log("  ~ opencode.json (plugin registered)");
    ' || echo "  ! opencode.json registration did not finish - check the file"
  fi
else
  oc_tmp=""
  if oc_tmp=$(mktemp "$PROJECT_ROOT/.opencode.json.planifest-tmp-XXXXXX") &&
     printf '{\n  "plugins": [\n    "%s"\n  ]\n}\n' "$PLUGIN_REF" > "$oc_tmp" &&
     chmod "$(printf '%o' $(( 0666 & ~0$(umask) )))" "$oc_tmp" &&
     mv -f "$oc_tmp" "$OPENCODE_JSON"; then
    echo "  + opencode.json (created with plugin registration)"
  else
    [ -n "$oc_tmp" ] && rm -f "$oc_tmp"
    echo "  ! could not create opencode.json - register $PLUGIN_REF by hand"
  fi
fi

echo "  [Planifest] OpenCode hooks installed."
echo "  Note: Run 'bun build' in .opencode/plugins/@planifest/opencode-hooks/ if"
echo "  OpenCode requires a compiled dist/index.js rather than the TypeScript source."
