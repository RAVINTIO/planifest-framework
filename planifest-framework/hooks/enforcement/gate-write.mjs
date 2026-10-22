#!/usr/bin/env node
/**
 * PreToolUse hook: plan compliance write gate.
 *
 * Judges a Write or Edit target with the shared rules in path-rules.mjs
 * (req-006, ADR-004). This hook keeps no copy of those rules.
 *   - A target outside the repository root passes with no output.
 *   - A target that can't be resolved inside the root blocks with exit 2
 *     and names the cause (0000035 ADR-005 and ADR-006).
 *   - Inside the root, path-rules.mjs applies the sentinel check for
 *     plan/current/, the always-permitted paths, the design.md existence
 *     check, and the component-path check, in that order.
 *
 * Receives: JSON on stdin conforming to the Planifest common envelope (ADR-002)
 * or the raw Claude Code PreToolUse hook input. The target is
 * tool_input.path or tool_input.file_path.
 *
 * Exit codes: 0 = pass, 2 = block (DD-004, ADR-005)
 * On a block, the reason goes to stdout for the stdout adapters and the same
 * text goes to stderr for Claude Code (0000032 ADR-005).
 * Silent on unexpected errors. Always exit 0 on non-enforcement failures (ADR-005).
 */

import { hookCwd, judgeWrite } from "./path-rules.mjs";
import { readStdin } from "./read-stdin.mjs";

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);

  // Support both common envelope (ADR-002) and raw Claude Code hook input.
  // The stdin cwd, then process.cwd(), then CLAUDE_PROJECT_DIR (0000035 ADR-006).
  const cwd = hookCwd(input);
  const toolInput = input?.tool_input ?? input;
  const rawTarget = toolInput?.path ?? toolInput?.file_path ?? "";

  // No string target path = pass (not a file-writing tool call)
  if (!rawTarget || typeof rawTarget !== "string" || cwd === null) process.exit(0);

  const result = judgeWrite(cwd, rawTarget);

  if (result.warning) process.stderr.write(result.warning);
  if (!result.allowed) {
    // Stdout stays as it was for the stdout adapters. Claude Code reads stderr (ADR-005).
    process.stdout.write(result.reason);
    process.stderr.write(result.reason);
    process.exit(2);
  }

  process.exit(0);
} catch {
  // Never block the session on unexpected errors (ADR-005).
  process.exit(0);
}
