#!/usr/bin/env node
/**
 * Cline hook adapter — Tier 1 (ADR-001, ADR-002).
 *
 * Translates Cline's native hook envelope to the Planifest common envelope,
 * then delegates to the appropriate shared hook script.
 *
 * Cline PreToolUse envelope shape:
 *   { toolName, toolInput, sessionId?, workspacePath? }
 *
 * Usage: node cline.mjs <script>
 *   e.g.  node cline.mjs gate-write
 */

import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

const SCRIPT_NAME = process.argv[2];

const ADAPTER_DIR = dirname(new URL(import.meta.url).pathname);
const HOOKS_DIR = dirname(ADAPTER_DIR);

async function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.setEncoding("utf-8");
    process.stdin.on("data", (c) => { data += c; });
    process.stdin.on("end", () => resolve(data.replace(/^\uFEFF/, "")));
    process.stdin.resume();
  });
}

try {
  if (!SCRIPT_NAME) process.exit(0);

  const raw = await readStdin();
  const clineInput = JSON.parse(raw);

  // Translate Cline envelope → Planifest common envelope (ADR-002)
  const envelope = {
    session_id: clineInput.sessionId ?? clineInput.session_id,
    cwd: clineInput.workspacePath ?? clineInput.workspace_path ?? clineInput.cwd ?? process.cwd(),
    tool_input: clineInput.toolInput ?? clineInput.tool_input ?? {},
    event: "PreToolUse",
  };

  const scriptPath = join(HOOKS_DIR, "enforcement", `${SCRIPT_NAME}.mjs`);

  if (!existsSync(scriptPath)) process.exit(0);

  const result = spawnSync(process.execPath, [scriptPath], {
    input: JSON.stringify(envelope),
    encoding: "utf-8",
    stdio: ["pipe", "pipe", "pipe"],
  });

  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  process.exit(result.status ?? 0);
} catch {
  process.exit(0);
}
