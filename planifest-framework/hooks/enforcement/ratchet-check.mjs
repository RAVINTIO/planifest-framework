#!/usr/bin/env node
/**
 * PreToolUse hook: ratchet — blocks silent weakening of acceptance criteria
 * and scope during loops/reversals (REQ-018, ADR-007, feature 0000016;
 * approval mechanism amended by ADR-001, feature 0000017).
 * Same family as gate-write.mjs.
 *
 * Root and target (0000035 ADR-007): the hook finds the repository root with
 * resolveRoot and the target with resolveTarget from path-rules.mjs, so it
 * guards plan/current/ from any subfolder. It keeps no path rules of its own.
 *
 * Armed only while a loop or reversal is in flight: a plan/current/loop-state-*.md
 * file with status "active" exists. When disarmed, every write passes.
 *
 * Weakening = removing a "- [ ]" checklist line from an "## Acceptance Criteria"
 * section, or removing a bullet from an "## In Scope" / "## Scope" section, of a
 * plan/current/ markdown artifact. Additions (strengthening) always pass.
 *
 * Human approval path (ADR-001, amends ADR-004): plan/current/.ratchet-approve
 * holds one approval per line in the format `path | reason | timestamp`
 * (pipe-delimited, 3 fields, reason verbatim from the human). A line missing
 * the `|` delimiter or missing a field is malformed and is treated as no
 * approval present for that line (the standard weakening-block applies).
 *
 * The agent MAY write this marker, but only when the human explicitly
 * instructs it in the moment (path + reason + go-ahead, same turn) and the
 * write is committed immediately in its own commit — that gating is an
 * orchestrator-level (chat instruction) concern, not enforced by this hook.
 *
 * Same-uncommitted-changeset backstop (kept from ADR-004, extended by ADR-001):
 * if a matching approval line exists but plan/current/.ratchet-approve itself
 * has uncommitted changes (per `git status --porcelain`), the write is
 * blocked with an EXPLICIT message naming the pending path and instructing
 * the approver to commit the marker first — never a silent block. Best-effort:
 * if git is unavailable/not a repo, this check is skipped (does not block).
 *
 * On consumption, the matched line is removed (file deleted when empty) and
 * the full record (path, reason, timestamp) is copied into the permanent
 * audit log at plan/ratchet-audit-log.md (top-level plan/, not plan/current/,
 * so it survives both per-feature archiving at P7 and framework re-vendoring —
 * see ADR-001 Affected Components). The reason field is capped at 500 chars
 * in the audit log, truncated with a trailing marker if longer.
 *
 * On a block, stdout carries the deny JSON and stderr carries the reason as
 * plain text for Claude Code (0000032 ADR-005).
 *
 * Exit codes: 0 = pass, 2 = block. Unexpected errors exit 0 — hooks never block
 * a session unexpectedly (matching gate-write.mjs contract).
 */

import { execFileSync } from "node:child_process";
import {
  appendFileSync, existsSync, readFileSync, readdirSync,
  unlinkSync, writeFileSync,
} from "node:fs";
import { join, normalize, relative } from "node:path";

import { hookCwd, norm as normPath, resolveRoot, resolveTarget } from "./path-rules.mjs";
import { readStdin } from "./read-stdin.mjs";

const AUDIT_LOG_REL = join("plan", "ratchet-audit-log.md");
const MAX_REASON_LEN = 500;
const TRUNCATE_MARKER = " …[truncated]";

// slashes: p with forward slashes, its case kept. Approval lines match on it.
function slashes(p) {
  return normalize(p).replace(/\\/g, "/");
}

function loopActive(planCurrent) {
  let entries;
  try { entries = readdirSync(planCurrent); } catch { return false; }
  for (const f of entries) {
    if (!/^loop-state-.*\.md$/.test(f)) continue;
    try {
      const head = readFileSync(join(planCurrent, f), "utf-8").slice(0, 500);
      if (/^status:\s*["']?active["']?\s*$/m.test(head)) return true;
    } catch { /* unreadable state = not armed by it */ }
  }
  return false;
}

/** Extract guarded lines: AC checklist items + scope bullets, per section. */
function guardedLines(text) {
  const lines = [];
  const sections = [
    { re: /^##\s+Acceptance Criteria\s*$/im, item: /^\s*-\s*\[[ x]\]\s*(.+)$/ },
    { re: /^##\s+(In Scope|Scope)\s*$/im, item: /^\s*-\s*(?!\[)(.+)$/ },
  ];
  for (const { re, item } of sections) {
    const m = re.exec(text);
    if (!m) continue;
    const rest = text.slice(m.index + m[0].length);
    const next = rest.search(/^##\s+/m);
    const body = next === -1 ? rest : rest.slice(0, next);
    for (const line of body.split(/\r?\n/)) {
      const im = line.match(item);
      if (im) lines.push(im[im.length - 1].trim());
    }
  }
  return lines;
}

function proposedContent(toolInput, currentText) {
  if (typeof toolInput.content === "string") return toolInput.content; // Write
  if (typeof toolInput.new_string === "string" && typeof toolInput.old_string === "string") {
    if (currentText === null) return null;
    return toolInput.replace_all
      ? currentText.split(toolInput.old_string).join(toolInput.new_string)
      : currentText.replace(toolInput.old_string, toolInput.new_string);
  }
  return null;
}

/**
 * Parses one .ratchet-approve line as `path | reason | timestamp`.
 * Returns null (malformed => no approval) if the delimiter or any of the
 * three fields is missing.
 */
function parseApprovalLine(rawLine) {
  const line = rawLine.replace(/\r$/, "");
  if (line.trim() === "") return null;
  const parts = line.split("|").map((s) => s.trim());
  if (parts.length !== 3) return null; // missing (or extra) '|' delimiter
  const [path, reason, timestamp] = parts;
  if (!path || !reason || !timestamp) return null; // missing a field
  return { path, reason, timestamp };
}

/** Finds the first well-formed line in the marker approving `relPath`. */
function findApproval(markerPath, relPath) {
  if (!existsSync(markerPath)) return null;
  let raw;
  try { raw = readFileSync(markerPath, "utf-8"); } catch { return null; }
  const lines = raw.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const parsed = parseApprovalLine(lines[i]);
    if (!parsed) continue;
    if (slashes(parsed.path) === slashes(relPath)) return { index: i, lines, ...parsed };
  }
  return null;
}

/** Best-effort: true if `absPath` has uncommitted changes (or is untracked). */
function isUncommitted(projectRoot, absPath) {
  try {
    const relToRoot = slashes(relative(projectRoot, absPath));
    const out = execFileSync("git", ["status", "--porcelain", "--", relToRoot], {
      cwd: projectRoot, encoding: "utf-8",
    });
    return out.trim().length > 0;
  } catch {
    return false; // no git / not a repo — backstop skipped, not blocked
  }
}

function truncateReason(reason) {
  if (reason.length <= MAX_REASON_LEN) return reason;
  return reason.slice(0, MAX_REASON_LEN) + TRUNCATE_MARKER;
}

function appendAuditLog(projectRoot, record) {
  const auditPath = join(projectRoot, AUDIT_LOG_REL);
  const entry = `- ${record.timestamp} | ${record.path} | ${truncateReason(record.reason)} `
    + `| consumed ${new Date().toISOString()}\n`;
  try { appendFileSync(auditPath, entry); } catch { /* logging best-effort */ }
}

/**
 * Attempts to consume an approval for `relPath`. Returns one of:
 *   { outcome: "no-approval" }               no matching well-formed line
 *   { outcome: "uncommitted", path }          matched, but marker uncommitted
 *   { outcome: "consumed" }                   matched, committed, now consumed
 */
function consumeApproval(planCurrent, projectRoot, relPath) {
  const markerPath = join(planCurrent, ".ratchet-approve");
  const found = findApproval(markerPath, relPath);
  if (!found) return { outcome: "no-approval" };

  if (isUncommitted(projectRoot, markerPath)) {
    return { outcome: "uncommitted", path: found.path };
  }

  const remaining = found.lines.filter((_, i) => i !== found.index).filter((l) => l.trim() !== "");
  try {
    if (remaining.length === 0) unlinkSync(markerPath);
    else writeFileSync(markerPath, remaining.join("\n") + "\n");
  } catch { /* best-effort — still record the consumption below */ }

  appendAuditLog(projectRoot, found);
  return { outcome: "consumed" };
}

async function main() {
  const raw = await readStdin();
  let input;
  try { input = JSON.parse(raw); } catch { process.exit(0); }

  const toolInput = input?.tool_input ?? input?.toolInput ?? {};
  const filePath = toolInput.file_path ?? toolInput.filePath;
  if (typeof filePath !== "string") process.exit(0);

  // The shared root and target rules (0000035 ADR-007). The cwd is the stdin
  // cwd, then the process working folder, then CLAUDE_PROJECT_DIR (hookCwd).
  const cwd = hookCwd(input);
  if (cwd === null) process.exit(0);
  const projectRoot = resolveRoot(cwd);
  if (!projectRoot) process.exit(0);
  // An outside target passes. An unresolvable one passes too, because
  // gate-write.mjs already blocks it with exit 2.
  const placed = resolveTarget(projectRoot, cwd, filePath);
  if (placed.status !== "inside") process.exit(0);
  const relPath = placed.relPath;
  const planCurrent = join(projectRoot, "plan", "current");

  // Only guard plan/current/ markdown artifacts (not the state/log files
  // themselves). The checks compare the 0000009-ADR-005 form.
  const normRel = normPath(relPath);
  if (!normRel.startsWith("plan/current/") || !normRel.endsWith(".md")) process.exit(0);
  const base = normRel.split("/").pop() ?? "";
  if (/^loop-state-/.test(base) || base === "ratchet-log.md" || base === "build-log.md") process.exit(0);

  // Armed only while a loop is active
  if (!loopActive(planCurrent)) process.exit(0);

  let currentText = null;
  try { currentText = readFileSync(join(projectRoot, relPath), "utf-8"); } catch { process.exit(0); }

  const next = proposedContent(toolInput, currentText);
  if (next === null) process.exit(0);

  const before = guardedLines(currentText);
  const after = new Set(guardedLines(next));
  const removed = before.filter((l) => !after.has(l));
  if (removed.length === 0) process.exit(0); // strengthening or neutral

  const consumption = consumeApproval(planCurrent, projectRoot, relPath);
  if (consumption.outcome === "consumed") process.exit(0);

  let reason;
  if (consumption.outcome === "uncommitted") {
    reason = [
      `Ratchet: an approval for ${consumption.path} exists in plan/current/.ratchet-approve,`,
      "but that marker file itself is uncommitted.",
      `Pending path: ${consumption.path}`,
      "Commit plan/current/.ratchet-approve in its own dedicated commit, then retry this write.",
    ].join("\n");
  } else {
    reason = [
      `Ratchet: this write weakens ${relPath} while a loop is active.`,
      ...removed.map((l) => `  removed: "${l}"`),
      "Loops may strengthen criteria/scope but never weaken them (ADR-007).",
      "If this weakening is intentional, add a line to plan/current/.ratchet-approve:",
      `  ${relPath} | <reason> | <timestamp>`,
      "(ADR-001: the agent may write this only on explicit human instruction, committed",
      "immediately in its own dedicated commit before this write proceeds.)",
    ].join("\n");
  }
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: reason,
    },
  }));
  // Claude Code reads a block reason from stderr, so repeat it as plain text (ADR-005).
  process.stderr.write(reason + "\n");
  process.exit(2);
}

main().catch(() => process.exit(0));
