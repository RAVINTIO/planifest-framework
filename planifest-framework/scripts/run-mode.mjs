#!/usr/bin/env node
/**
 * run-mode.mjs - print the effective run mode for every reader after P0
 * (feature 0000033, req-001, P5 C2-1).
 *
 * Usage: node run-mode.mjs [--root <projectRoot>] [<build-log path>]
 *
 *   --root           defaults to the working directory
 *   <build-log path> defaults to plan/current/build-log.md. After P7 Step 6,
 *                    the ship agent passes {archive-dir}/build-log.md.
 *
 * Output: one of `interactive`, `continuous`, or `autonomous` on stdout,
 * and exit 0 in every case.
 *
 * Rules:
 *   1. The value comes from plan/.run-mode if present, else from the
 *      `Run mode` row of the build log.
 *   2. `continuous` and `interactive` print as read. An unknown or missing
 *      value prints `interactive`.
 *   3. `autonomous` prints only when git history anchors it. Exactly one
 *      commit added a line starting `Run mode confirmed: autonomous` to the
 *      build log, and no commit removed one. That same commit changed
 *      plan/current/design.md so its Confirmation line reads `yes`. The
 *      working-tree build log holds that line once, unchanged. Otherwise the
 *      script prints `interactive` and writes one reason line to stderr.
 *   4. A symlinked plan/, plan/current/, build-log path component, or
 *      plan/.run-mode prints `interactive`.
 *
 * Threat handled: an errant subagent that rewrites a run-mode record, such
 * as plan/.run-mode or the build-log row, to switch on `autonomous`.
 *
 * Limit: an agent that can commit can still forge one anchored commit. So
 * merging, schema changes, destructive operations, and the credential rule
 * never depend on the run mode. They stay human-gated in every mode.
 *
 * Every git call runs with an argument array, no shell, and
 * GIT_LITERAL_PATHSPECS=1. Reads stop at 1 MB per file. Printed reasons
 * have their control characters replaced.
 */

import { spawnSync } from "node:child_process";
import { lstatSync, readFileSync, realpathSync } from "node:fs";
import { isAbsolute, relative, resolve, sep } from "node:path";

const MODES = ["interactive", "continuous", "autonomous"];
const DEFAULT_LOG = "plan/current/build-log.md";
const DESIGN = "plan/current/design.md";
const RUN_MODE_FILE = "plan/.run-mode";
const LINE_PREFIX = "Run mode confirmed: autonomous";
const CONFIRM_RE = /^\+Human confirmed this design before proceeding:\s*yes\b/i;
const MAX_BYTES = 1024 * 1024;
const GIT_ENV = { ...process.env, GIT_LITERAL_PATHSPECS: "1" };

function clean(v) {
  return String(v).replace(/[^\x20-\x7e]/g, "?").slice(0, 200);
}

function done(mode, reason) {
  if (reason) process.stderr.write(`run-mode: ${clean(reason)}\n`);
  process.stdout.write(`${mode}\n`);
  process.exit(0);
}

function lstatOrNull(p) {
  try { return lstatSync(p); } catch { return null; }
}

// True when any existing component from root down to rel is a symlink.
function hasSymlink(root, rel) {
  let cur = root;
  for (const part of rel.split("/").filter(Boolean)) {
    cur = resolve(cur, part);
    const st = lstatOrNull(cur);
    if (!st) return false;
    if (st.isSymbolicLink()) return true;
  }
  return false;
}

// Reads a regular file up to MAX_BYTES, or returns null.
function readSmall(abs) {
  const st = lstatOrNull(abs);
  if (!st || !st.isFile() || st.size > MAX_BYTES) return null;
  try { return readFileSync(abs, "utf8"); } catch { return null; }
}

function git(root, args) {
  const r = spawnSync("git", args, {
    cwd: root, encoding: "utf8", env: GIT_ENV, maxBuffer: 64 * MAX_BYTES,
  });
  if (r.error || r.status !== 0) return null;
  return r.stdout;
}

function parseArgs(argv) {
  let root = process.cwd();
  let log = DEFAULT_LOG;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--root") root = argv[++i] ?? root;
    else log = argv[i];
  }
  return { root: resolve(root), log };
}

function rowValue(text) {
  for (const line of text.split("\n")) {
    const m = /^\|\s*Run mode\s*\|([^|]*)\|/.exec(line);
    if (m) return m[1].replace(/`/g, "").trim();
  }
  return null;
}

// Returns null when anchored, else a reason string.
function checkAnchor(root, logRel, logText) {
  const lines = logText.split("\n").filter((l) => l.startsWith(LINE_PREFIX));
  if (lines.length !== 1) return `expected one "${LINE_PREFIX}" line in the build log, found ${lines.length}`;
  const out = git(root, [
    "log", "--follow", "-M", "-p", "--unified=0", "--no-color", "--no-ext-diff",
    "--format=commit %H", "--", logRel,
  ]);
  if (out === null) return "git log failed for the build log";
  const adders = [];
  let sha = null;
  for (const l of out.split("\n")) {
    if (l.startsWith("commit ")) { sha = l.slice(7).trim(); continue; }
    if (l.startsWith("+++") || l.startsWith("---")) continue;
    if (l.startsWith(`-${LINE_PREFIX}`)) return "a commit removed or edited the confirmation line";
    if (l.startsWith(`+${LINE_PREFIX}`)) adders.push({ sha, line: l.slice(1) });
  }
  if (adders.length !== 1) return `expected one commit adding the confirmation line, found ${adders.length}`;
  const [{ sha: anchor, line }] = adders;
  if (line !== lines[0]) return "the confirmation line differs from the anchored commit";
  const design = git(root, [
    "show", "--format=", "-p", "--unified=0", "--no-color", "--no-ext-diff", anchor, "--", DESIGN,
  ]);
  if (design === null) return "git show failed for the anchor commit";
  if (!design.split("\n").some((l) => CONFIRM_RE.test(l))) {
    return "the anchor commit did not set the design Confirmation line to yes";
  }
  return null;
}

function main() {
  const { root, log } = parseArgs(process.argv.slice(2));
  const logAbs = resolve(root, log);
  const logRel = relative(root, logAbs).split(sep).join("/");
  if (logRel.startsWith("..") || isAbsolute(logRel)) done("interactive", "the build-log path is outside --root");

  for (const rel of ["plan", "plan/current", RUN_MODE_FILE, logRel]) {
    if (hasSymlink(root, rel)) done("interactive", `refused a symlink on ${rel}`);
  }

  let value = null;
  if (lstatOrNull(resolve(root, RUN_MODE_FILE))) {
    value = (readSmall(resolve(root, RUN_MODE_FILE)) ?? "").trim();
  }
  const logText = readSmall(logAbs);
  if (value === null && logText !== null) value = rowValue(logText);

  if (value === "continuous" || value === "interactive") done(value);
  if (!MODES.includes(value)) done("interactive");

  if (logText === null) done("interactive", "autonomous has no readable build log to anchor it");
  try {
    if (!realpathSync(logAbs).startsWith(realpathSync(root) + sep)) {
      done("interactive", "the build log resolves outside --root");
    }
  } catch {
    done("interactive", "the build log could not be resolved");
  }
  const reason = checkAnchor(root, logRel, logText);
  if (reason) done("interactive", `autonomous not anchored: ${reason}`);
  done("autonomous");
}

main();
