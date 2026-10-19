#!/usr/bin/env node
/**
 * archive-current.mjs - archive plan/current/ into plan/_archive/ for P7
 * Step 6, with one git mv or rename per item and no glob delete
 * (feature 0000033, req-012, ADR-010).
 *
 * Usage: node archive-current.mjs --feature-id <id> [--date YYYY-MM-DD] [--root <projectRoot>]
 *
 *   --feature-id  required, matches ^[0-9]{7}-[a-z0-9-]+$ (max 120 chars)
 *   --date        defaults to today (local time)
 *   --root        defaults to the working directory
 *
 * Target directory:
 *   1. If plan/current/.archive-target exists, the script reads the target
 *      from it (the resume case).
 *   2. Otherwise it picks plan/_archive/{feature-id}-{date}/, or the first
 *      free -2, -3, ... suffix, and writes it to .archive-target before it
 *      moves anything.
 *
 * Each entry of plan/current/ (read with a directory listing, never a glob)
 * moves with `git mv` when git tracks it, or is renamed on disk and staged
 * with `git add` when it doesn't. Only these paths are deleted, each by
 * explicit path: .skips, .planifest-session, .feature-id, capability-skills/,
 * and finally .archive-target. Session markers are never touched.
 *
 * Every git call runs as its own child process with an argument array and
 * no shell, so a refused step leaves every earlier step done. A rerun skips
 * entries already in the target and finishes the rest. Each git call sets
 * GIT_LITERAL_PATHSPECS=1, so an entry named `*` is a path, not a glob.
 *
 * Path safety, checked before any change: plan/, plan/current/,
 * plan/_archive/, and the target directory must not be symlinks, and each
 * must resolve inside the real --root. .archive-target must be a regular
 * file, never a symlink, and the script creates it with the "wx" flag.
 * Error messages never print the .archive-target value, and every printed
 * entry name has its control characters replaced.
 *
 * Output, one line per action: `moved: <from> -> <to>`, `removed: <path>`,
 * `skipped: <path> (already archived)`. The last line is `archive-dir: <dir>`.
 *
 * Exit codes:
 *   0 - archive complete
 *   2 - invalid input (feature ID, date, or .archive-target value), or a
 *       symlinked or out-of-root plan/, plan/current/, plan/_archive/, target
 *       directory, or .archive-target; moves nothing
 *   3 - a conflict (source and target both exist) or a leftover entry
 *   other non-zero - a git command failed; git's message is on stderr
 */

import { spawnSync } from "node:child_process";
import {
  lstatSync, mkdirSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync,
  unlinkSync, writeFileSync,
} from "node:fs";
import { basename, dirname, join, relative, resolve, sep } from "node:path";

const ID_RE = /^[0-9]{7}-[a-z0-9-]+$/;
const DATE_RE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
const MAX_LEN = 120;
const CURRENT = "plan/current";
const ARCHIVE_ROOT = "plan/_archive";
const TARGET_FILE = ".archive-target";
const EXPLICIT_DELETES = [".skips", ".planifest-session", ".feature-id", "capability-skills"];

function fail(code, message) {
  process.stderr.write(`archive-current: ${message}\n`);
  process.exit(code);
}

// Sanitise a value before it reaches output: printable ASCII only, capped.
function clean(v) {
  return String(v).replace(/[^\x20-\x7e]/g, "?").slice(0, MAX_LEN);
}

function parseArgs(argv) {
  const get = (flag) => {
    const i = argv.indexOf(flag);
    return i >= 0 ? argv[i + 1] : undefined;
  };
  const now = new Date();
  const today = [now.getFullYear(), now.getMonth() + 1, now.getDate()]
    .map((n, i) => String(n).padStart(i === 0 ? 4 : 2, "0")).join("-");
  return {
    featureId: get("--feature-id"),
    date: get("--date") ?? today,
    root: resolve(get("--root") ?? process.cwd()),
  };
}

const GIT_ENV = { ...process.env, GIT_LITERAL_PATHSPECS: "1" };

function git(root, args) {
  const r = spawnSync("git", args, { cwd: root, encoding: "utf8", env: GIT_ENV });
  if (r.error) fail(1, `git ${args[0]} failed: ${r.error.message}`);
  if (r.status !== 0) {
    process.stderr.write(r.stderr || "");
    process.exit(r.status || 1);
  }
  return r.stdout;
}

const posix = (p) => p.split(sep).join("/");

function validTargetName(name, featureId) {
  if (!name.startsWith(`${featureId}-`)) return false;
  return /^[0-9]{4}-[0-9]{2}-[0-9]{2}(-[0-9]+)?$/.test(name.slice(featureId.length + 1));
}

// lstat that returns null for a missing path, so a dangling symlink counts.
function lstatOrNull(p) {
  try { return lstatSync(p); } catch { return null; }
}

// Exits 2 unless p is absent or a real directory whose realpath is expected.
function checkDir(p, expected, label) {
  const st = lstatOrNull(p);
  if (!st) return;
  if (st.isSymbolicLink() || !st.isDirectory()) fail(2, `${label} must be a directory, not a symlink`);
  if (realpathSync(p) !== expected) fail(2, `${label} resolves outside --root`);
}

// Returns the target directory relative to root, in posix form.
function readTarget(root, featureId) {
  const p = join(root, CURRENT, TARGET_FILE);
  if (!lstatSync(p).isFile()) fail(2, `${TARGET_FILE} must be a regular file, not a symlink`);
  const raw = readFileSync(p, "utf8").trim().replace(/\/+$/, "");
  if (!raw || raw.length > MAX_LEN) fail(2, `invalid ${TARGET_FILE} value`);
  const abs = resolve(root, raw);
  if (dirname(abs) !== resolve(root, ARCHIVE_ROOT) || !validTargetName(basename(abs), featureId)) {
    fail(2, `${TARGET_FILE} must name plan/_archive/${featureId}-{date}[-N]`);
  }
  return posix(relative(root, abs));
}

function pickTarget(root, featureId, date) {
  const base = `${ARCHIVE_ROOT}/${featureId}-${date}`;
  if (!lstatOrNull(join(root, base))) return base;
  for (let n = 2; ; n++) {
    if (!lstatOrNull(join(root, `${base}-${n}`))) return `${base}-${n}`;
  }
}

// Refuses symlinks on every directory the script moves into or out of.
function checkPaths(root) {
  const real = realpathSync(root);
  checkDir(join(root, "plan"), join(real, "plan"), "plan/");
  checkDir(join(root, CURRENT), join(real, CURRENT), `${CURRENT}/`);
  checkDir(join(root, ARCHIVE_ROOT), join(real, ARCHIVE_ROOT), `${ARCHIVE_ROOT}/`);
  return real;
}

const isTracked = (root, path) => git(root, ["ls-files", "--", path]).trim() !== "";
const hasUntracked = (root, path) =>
  git(root, ["ls-files", "--others", "--exclude-standard", "--", path]).trim() !== "";

function main() {
  const { featureId, date, root } = parseArgs(process.argv.slice(2));
  if (!featureId || featureId.length > MAX_LEN || !ID_RE.test(featureId)) {
    fail(2, `invalid --feature-id: ${clean(featureId ?? "(missing)")}`);
  }
  if (!DATE_RE.test(date)) fail(2, `invalid --date: ${clean(date)}`);
  const currentAbs = join(root, CURRENT);
  if (!lstatOrNull(currentAbs)) fail(2, `${CURRENT}/ not found under --root`);
  const real = checkPaths(root);

  const targetFileAbs = join(currentAbs, TARGET_FILE);
  const resuming = lstatOrNull(targetFileAbs) !== null;
  const target = resuming ? readTarget(root, featureId) : pickTarget(root, featureId, date);
  const targetAbs = join(root, target);
  checkDir(targetAbs, join(real, target), "the archive target directory");

  const entries = readdirSync(currentAbs).filter(
    (e) => e !== TARGET_FILE && !EXPLICIT_DELETES.includes(e),
  );

  // Check every entry before any change, so a conflict changes nothing.
  for (const e of entries) {
    if (lstatOrNull(join(targetAbs, e))) {
      fail(3, `conflict: ${CURRENT}/${clean(e)} and ${target}/${clean(e)} both exist. Resolve it by hand, then rerun.`);
    }
  }

  if (!resuming) writeFileSync(targetFileAbs, `${target}\n`, { flag: "wx" });
  mkdirSync(targetAbs, { recursive: true });

  // Entries a stopped run already moved.
  const done = readdirSync(targetAbs).filter((e) => !entries.includes(e));
  for (const e of done) {
    if (hasUntracked(root, `${target}/${e}`)) git(root, ["add", "--", `${target}/${e}`]);
    console.log(`skipped: ${CURRENT}/${clean(e)} (already archived)`);
  }

  for (const e of entries) {
    const from = `${CURRENT}/${e}`;
    const to = `${target}/${e}`;
    if (isTracked(root, from)) {
      git(root, ["mv", "--", from, to]);
    } else {
      renameSync(join(root, from), join(root, to));
    }
    if (hasUntracked(root, to)) git(root, ["add", "--", to]);
    console.log(`moved: ${CURRENT}/${clean(e)} -> ${target}/${clean(e)}`);
  }

  for (const e of EXPLICIT_DELETES) {
    const path = `${CURRENT}/${e}`;
    if (!lstatOrNull(join(root, path))) continue;
    git(root, ["rm", "-r", "--cached", "--ignore-unmatch", "-q", "--", path]);
    rmSync(join(root, path), { recursive: true, force: true });
    console.log(`removed: ${path}`);
  }

  git(root, ["rm", "--cached", "--ignore-unmatch", "-q", "--", `${CURRENT}/${TARGET_FILE}`]);
  unlinkSync(targetFileAbs);

  const leftover = readdirSync(currentAbs);
  if (leftover.length > 0) {
    fail(3, `leftover entry in ${CURRENT}/: ${leftover.map(clean).join(", ")}`);
  }
  console.log(`archive-dir: ${target}`);
}

main();
