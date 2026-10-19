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
 *   5. Merges: if any merge commit differs from one of its parents in the
 *      build log, the script prints `interactive`. A merge that leaves the
 *      build log alone is fine. Merges never carry the anchor.
 *   6. History follows the build log across a rename. If the given path has
 *      no history yet, such as between P7 Step 6 and the P7 commit, the
 *      script reads the history of plan/current/build-log.md instead.
 *
 * Threat: an errant or confused subagent that rewrites a run-mode record,
 * such as plan/.run-mode or the build-log row, to switch on `autonomous`.
 *
 * What the script checks: the anchor in rule 3, read from git objects only.
 * Every git call ignores textconv drivers, external diff tools, replace refs,
 * the system git config, and every inherited GIT_* variable.
 *
 * Limits: An agent with shell access can still forge history, so this script
 * is an integrity check, not a security boundary. Merging, schema changes,
 * destructive operations, and credentials never depend on the run mode. They
 * stay human-gated in every mode.
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
// A clean copy of the environment with every inherited GIT_* variable removed.
const GIT_ENV = Object.fromEntries(
  Object.entries(process.env).filter(([k]) => !k.toUpperCase().startsWith("GIT_")),
);
Object.assign(GIT_ENV, {
  GIT_LITERAL_PATHSPECS: "1", GIT_NO_REPLACE_OBJECTS: "1", GIT_CONFIG_NOSYSTEM: "1",
});
// Flags for every git log or show call: diffs come from raw blobs only.
const DIFF_FLAGS = ["--no-textconv", "--no-ext-diff", "--no-color"];

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
  const r = spawnSync("git", ["--no-replace-objects", ...args], {
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
  // Rule 5: refuse when a merge brought any change to the build log.
  for (const p of new Set([logRel, DEFAULT_LOG])) {
    const merges = git(root, ["log", "--merges", "--full-history", "--format=%H", "--", p]);
    if (merges === null) return "git log failed listing merges";
    if (merges.trim()) return `a merge commit changed ${p}, so the anchor is ambiguous`;
  }
  // Rule 6: follow renames, and fall back to the plan/current path.
  const logPatch = (p) => git(root, [
    "log", "--follow", "-M", "-p", "--unified=0", ...DIFF_FLAGS, "--format=commit %H", "--", p,
  ]);
  let out = logPatch(logRel);
  if (out !== null && !out.trim() && logRel !== DEFAULT_LOG) out = logPatch(DEFAULT_LOG);
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
    "show", "--format=", "-p", "--unified=0", ...DIFF_FLAGS, anchor, "--", DESIGN,
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
