#!/usr/bin/env node
/**
 * set-product-release.mjs - set the product.yml release fields at P7, before
 * Step 6 archives design.md (feature 0000035, req-002, req-008, ADR-010,
 * ADR-011).
 *
 * Usage:
 *   node set-product-release.mjs --feature-id <id> --version <MAJOR.MINOR.PATCH>
 *     [--create --product-id <id> --product-name <name>]
 *     [--component "<id>=<path>" ...] [--root <dir>]
 *
 * Behaviour by versionPolicy:
 *   max-component-version - derive the version with the product-version.mjs
 *       rule from the content about to be written. A mismatch with --version
 *       writes nothing and exits 2. A match writes version and feature.
 *   explicit - write version and feature.
 *   external - write feature only and exit 5.
 *
 * The script rewrites the top-level version and feature lines, leaves every
 * other line as it is, and never appends a line. It replaces components[] only when --component is
 * given. With --create and no product.yml, it builds the file from
 * templates/product.template.yml under max-component-version.
 *
 * Hard Limit 8 carve-out (ADR-011): the script writes only {root}/product.yml.
 * Every argument is untrusted, and every rule runs before product.yml is
 * read. Each value is written as a double-quoted YAML scalar, and no allowed
 * character can end the scalar or start a line. An error message names the
 * argument and the rule and never echoes the raw value.
 *
 * File-system hardening (P5 findings P-S03 to P-S08):
 *   - The root comes from the working directory only. CLAUDE_PROJECT_DIR is
 *     cleared for the resolveRoot call.
 *   - product.yml is opened once with O_NOFOLLOW and read through that
 *     descriptor. fstat must show a regular file with one link.
 *   - The new content goes to a temp file in the root, then a rename puts it
 *     in place. A failure removes the temp file.
 *   - Each components[].path read from product.yml meets the --component
 *     path rules.
 *   - Each component.yml is opened once with O_NOFOLLOW and read through
 *     that descriptor. fstat must show a regular file with one link (P-N1).
 *   - An unexpected file-system error exits 2 and names only the operation
 *     and the error code.
 *   - A top-level key line the script can't rewrite exits 2. Any error that
 *     no rule catches exits 2 with a fixed message (P-N2).
 *
 * Exit codes:
 *   0 - product.yml written, or it already held the same values
 *   2 - a rule break, an invalid manifest, a version mismatch, a target
 *       that resolves elsewhere or has more than one link, or a file-system
 *       error; nothing written, reason on stderr
 *   4 - no product.yml and no --create; nothing written
 *   5 - versionPolicy is external; only feature changed
 */

import {
  closeSync, constants, fchmodSync, fstatSync, fsyncSync, linkSync, lstatSync, openSync,
  readFileSync, realpathSync, renameSync, statSync, unlinkSync, writeFileSync,
} from "node:fs";
import { randomBytes } from "node:crypto";
import { dirname, join, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { resolveRoot } from "../hooks/enforcement/path-rules.mjs";

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const TEMPLATE = join(SCRIPT_DIR, "..", "templates", "product.template.yml");
const POLICIES = ["max-component-version", "explicit", "external"];
const SEMVER_LOOSE_RE = /^[0-9]+\.[0-9]+\.[0-9]+$/;
const MAX_COMPONENTS = 64;

// Each rule: the whole value must match, within the length cap (req-008).
const RULES = {
  "--feature-id": { re: /^[0-9]{7}-[a-z0-9-]+$/, max: 80, rule: "^[0-9]{7}-[a-z0-9-]+$" },
  "--version": {
    re: /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/,
    max: 32,
    rule: "strict MAJOR.MINOR.PATCH",
  },
  "--product-id": { re: /^[a-z0-9][a-z0-9-]*$/, max: 64, rule: "^[a-z0-9][a-z0-9-]*$" },
  "--product-name": { re: /^[A-Za-z0-9 .-]+$/, max: 80, rule: "^[A-Za-z0-9 .-]+$" },
};
const COMPONENT_ID = { re: /^[a-z0-9][a-z0-9-]*$/, max: 64 };
const COMPONENT_PATH = { re: /^[A-Za-z0-9._/-]+$/, max: 256 };
const VALUE_FLAGS = ["--feature-id", "--version", "--product-id", "--product-name", "--root"];

function fail(code, message) {
  process.stderr.write(`set-product-release: ${message}\n`);
  process.exit(code);
}

// An unexpected file-system error exits 2. The message names the operation
// and the error code, never a path or a stack trace (P-S07).
function fsFail(operation, err) {
  const code = err && typeof err.code === "string" && /^[A-Z0-9_]+$/.test(err.code) ? err.code : "unknown error";
  fail(2, `${operation}: failed (${code})`);
}

function fsCall(operation, fn) {
  try {
    return fn();
  } catch (err) {
    return fsFail(operation, err);
  }
}

// Printable ASCII only, for values read from files rather than arguments.
function clean(v) {
  return String(v).replace(/[^\x20-\x7e]/g, "?").slice(0, 64);
}

function parseArgs(argv) {
  const args = { components: [], create: false };
  const seen = new Set();
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    if (flag === "--create") {
      if (seen.has(flag)) fail(2, "--create: appears more than once");
      seen.add(flag);
      args.create = true;
    } else if (flag === "--component") {
      if (i + 1 >= argv.length) fail(2, "--component: needs a value");
      args.components.push(argv[++i]);
    } else if (VALUE_FLAGS.includes(flag)) {
      if (seen.has(flag)) fail(2, `${flag}: appears more than once`);
      if (i + 1 >= argv.length) fail(2, `${flag}: needs a value`);
      seen.add(flag);
      args[flag] = argv[++i];
    } else {
      fail(2, `argument ${i + 1}: unknown argument`);
    }
  }
  return args;
}

function checkValue(flag, value) {
  const { re, max, rule } = RULES[flag];
  if (value.length > max) fail(2, `${flag}: longer than ${max} characters`);
  if (!re.test(value)) fail(2, `${flag}: does not match ${rule}`);
}

function insideRoot(root, real) {
  return real === root || real.startsWith(root.endsWith(sep) ? root : root + sep);
}

// The root comes from the working directory only. resolveRoot honours
// CLAUDE_PROJECT_DIR, which a caller can set on the command line, so the
// variable is cleared for this call (P-S03).
function rootForCwd(cwd) {
  const saved = process.env.CLAUDE_PROJECT_DIR;
  delete process.env.CLAUDE_PROJECT_DIR;
  try {
    return resolveRoot(cwd);
  } finally {
    if (saved !== undefined) process.env.CLAUDE_PROJECT_DIR = saved;
  }
}

function resolveRootArg(rootArg) {
  let cwd = "";
  try {
    cwd = process.cwd();
  } catch {
    // A deleted working directory leaves cwd empty, and resolveRoot returns null.
  }
  const root = rootForCwd(cwd);
  if (!root) fail(2, "--root: no repository root found for the working directory");
  if (rootArg !== undefined) {
    let real;
    try {
      real = realpathSync(rootArg);
    } catch {
      fail(2, "--root: path does not resolve");
    }
    if (real !== root) fail(2, "--root: must equal the repository root for the working directory");
  }
  let framework = false;
  try {
    framework = statSync(join(root, "planifest-framework")).isDirectory();
  } catch {
    framework = false;
  }
  if (!framework) fail(2, "--root: the root holds no planifest-framework/ folder");
  return root;
}

function checkComponents(root, values) {
  if (values.length > MAX_COMPONENTS) fail(2, `--component: more than ${MAX_COMPONENTS} given`);
  const ids = new Set();
  return values.map((value, n) => {
    const label = `--component ${n + 1}`;
    const eq = value.indexOf("=");
    if (eq < 0) fail(2, `${label}: needs the form {id}={path}`);
    const id = value.slice(0, eq);
    const path = value.slice(eq + 1);
    if (id.length > COMPONENT_ID.max) fail(2, `${label}: id longer than ${COMPONENT_ID.max} characters`);
    if (!COMPONENT_ID.re.test(id)) fail(2, `${label}: id does not match ^[a-z0-9][a-z0-9-]*$`);
    if (ids.has(id)) fail(2, `${label}: id repeats an earlier --component id`);
    ids.add(id);
    checkComponentPath(root, label, path);
    return { id, path };
  });
}

// The component path rules, shared by --component and by each
// components[].path read from product.yml (P-S08). The file is opened once
// with O_NOFOLLOW and read through that descriptor. fstat must show a
// regular file with one link, so a hard link to a file outside the root
// fails (P-N1). Returns the file text.
function checkComponentPath(root, label, path) {
  if (path.length > COMPONENT_PATH.max) fail(2, `${label}: path longer than ${COMPONENT_PATH.max} characters`);
  if (!COMPONENT_PATH.re.test(path)) fail(2, `${label}: path does not match ^[A-Za-z0-9._/-]+$`);
  if (path !== "component.yml" && !path.endsWith("/component.yml")) {
    fail(2, `${label}: path must be component.yml or end in /component.yml`);
  }
  if (path.startsWith("/")) fail(2, `${label}: path must not start with /`);
  const segments = path.split("/");
  if (segments.includes("..")) fail(2, `${label}: path must not hold a .. segment`);
  if (segments.includes("")) fail(2, `${label}: path must not hold an empty segment`);
  let real;
  try {
    real = realpathSync(join(root, path));
  } catch {
    fail(2, `${label}: path names no existing file`);
  }
  if (!insideRoot(root, real)) fail(2, `${label}: path resolves outside the root`);
  let fd;
  try {
    fd = openSync(real, constants.O_RDONLY | (constants.O_NOFOLLOW ?? 0) | (constants.O_NONBLOCK ?? 0));
  } catch (err) {
    if (err && err.code === "ELOOP") fail(2, `${label}: path is a link that resolves to another path`);
    return fsFail(`${label}: open`, err);
  }
  try {
    const fst = fsCall(`${label}: stat`, () => fstatSync(fd));
    if (!fst.isFile()) fail(2, `${label}: path is not a file`);
    if (fst.nlink !== 1) fail(2, `${label}: path has more than one hard link`);
    return fsCall(`${label}: read`, () => readFileSync(fd, "utf-8"));
  } finally {
    closeSync(fd);
  }
}

function validate(argv) {
  const args = parseArgs(argv);
  for (const flag of ["--feature-id", "--version"]) {
    if (args[flag] === undefined) fail(2, `${flag}: required`);
    checkValue(flag, args[flag]);
  }
  for (const flag of ["--product-id", "--product-name"]) {
    if (args[flag] !== undefined) checkValue(flag, args[flag]);
  }
  const root = resolveRootArg(args["--root"]);
  const components = checkComponents(root, args.components);
  if (args.create) {
    if (args["--product-id"] === undefined) fail(2, "--create: needs --product-id");
    if (args["--product-name"] === undefined) fail(2, "--create: needs --product-name");
    if (components.length < 2) fail(2, "--create: needs at least two --component arguments");
  }
  return { args, root, components };
}

// The target must be {root}/product.yml itself. A link that resolves
// anywhere else, a hard link (P-S04), or a target that is not a regular file
// writes nothing. The file is opened once and read through that descriptor,
// so the checked file is the read file (P-S05). Returns null when absent.
function readTarget(target) {
  let st;
  try {
    st = lstatSync(target);
  } catch (err) {
    if (err && err.code === "ENOENT") return null;
    return fsFail("product.yml: stat", err);
  }
  // The root is already a real path, so a link here always resolves elsewhere.
  if (st.isSymbolicLink()) fail(2, "product.yml: is a link that resolves to another path");
  if (!st.isFile()) fail(2, "product.yml: is not a regular file");
  let fd;
  try {
    fd = openSync(target, constants.O_RDONLY | (constants.O_NOFOLLOW ?? 0) | (constants.O_NONBLOCK ?? 0));
  } catch (err) {
    if (err && err.code === "ELOOP") fail(2, "product.yml: is a link that resolves to another path");
    return fsFail("product.yml: open", err);
  }
  try {
    const fst = fsCall("product.yml: stat", () => fstatSync(fd));
    if (!fst.isFile()) fail(2, "product.yml: is not a regular file");
    if (fst.nlink !== 1) fail(2, "product.yml: has more than one hard link");
    if (fst.dev !== st.dev || fst.ino !== st.ino) fail(2, "product.yml: changed while the script read it");
    const text = fsCall("product.yml: read", () => readFileSync(fd, "utf-8"));
    return { text, mode: fst.mode & 0o777 };
  } finally {
    closeSync(fd);
  }
}

function unquote(v) {
  return v.trim().replace(/^["']|["']$/g, "");
}

// Index of each top-level key line. A key that appears twice is invalid.
// The map has no prototype, so a key such as constructor is an ordinary key.
function topLevelLines(lines) {
  const found = Object.create(null);
  lines.forEach((line, i) => {
    const m = line.match(/^([A-Za-z][A-Za-z0-9_-]*):/);
    if (!m) return;
    if (found[m[1]] !== undefined) fail(2, `product.yml: top-level ${clean(m[1])} appears more than once`);
    found[m[1]] = i;
  });
  return found;
}

// Rewrite one top-level scalar in place, keeping any trailing comment. A line
// that holds a line terminator, such as a lone CR or U+2028, fails the match
// and exits 2 (P-N2).
function setScalar(lines, keys, key, value) {
  const i = keys[key];
  if (i === undefined) fail(2, `product.yml: no top-level ${key} line to rewrite`);
  const m = lines[i].match(/^([A-Za-z][A-Za-z0-9_-]*:[ \t]*)("[^"]*"|'[^']*'|[^\s#]*)(.*)$/);
  if (!m) fail(2, `product.yml: the top-level ${key} line holds a character the script can't rewrite`);
  lines[i] = `${m[1]}"${value}"${m[3]}`;
}

// Replace the components: block with one entry per --component.
function setComponents(lines, keys, components) {
  const start = keys.components;
  if (start === undefined) fail(2, "product.yml: no top-level components line to rewrite");
  if (!/^components:\s*$/.test(lines[start])) fail(2, "product.yml: components is not a block list");
  let end = start + 1;
  while (end < lines.length && (lines[end] === "" || /^[\s-]/.test(lines[end]))) end++;
  while (end > start + 1 && lines[end - 1].trim() === "") end--;
  const entries = components.flatMap(({ id, path }) => [`  - id: "${id}"`, `    path: "${path}"`]);
  lines.splice(start + 1, end - start - 1, ...entries);
}

function parseManifest(lines) {
  const doc = { versionPolicy: null, components: [] };
  let inComponents = false;
  let current = null;
  for (const raw of lines) {
    const line = raw.replace(/#.*$/, "").trimEnd();
    if (!line.trim()) continue;
    if (/^components:\s*$/.test(line)) { inComponents = true; current = null; continue; }
    if (/^[A-Za-z]/.test(line)) inComponents = false;
    if (inComponents) {
      const idMatch = line.match(/^\s*-\s*id:\s*(.+)$/);
      if (idMatch) { current = { id: unquote(idMatch[1]), path: null }; doc.components.push(current); continue; }
      const pathMatch = line.match(/^\s*path:\s*(.+)$/);
      if (pathMatch && current) current.path = unquote(pathMatch[1]);
    } else {
      const m = line.match(/^versionPolicy:\s*(.+)$/);
      if (m) doc.versionPolicy = unquote(m[1]);
    }
  }
  return doc;
}

function semverCompare(a, b) {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);
  for (let i = 0; i < 3; i++) if (pa[i] !== pb[i]) return pa[i] - pb[i];
  return 0;
}

// The product-version.mjs max-component-version rule, applied to the
// content about to be written.
function deriveVersion(root, components) {
  if (components.length === 0) fail(2, "product.yml: max-component-version needs a non-empty components list");
  let max = null;
  for (const c of components) {
    const label = `component ${clean(c.id ?? "(unnamed)")}`;
    if (!c.path) fail(2, `${label}: components[] entry has no path`);
    const text = checkComponentPath(root, label, c.path);
    let version = null;
    for (const raw of text.split(/\r?\n/)) {
      const m = raw.replace(/#.*$/, "").trimEnd().match(/^version:\s*(.+)$/);
      if (m) { version = unquote(m[1]); break; }
    }
    if (version === null) fail(2, `${label}: no top-level version field`);
    if (version.length > 32 || !SEMVER_LOOSE_RE.test(version)) fail(2, `${label}: version is not MAJOR.MINOR.PATCH`);
    if (max === null || semverCompare(version, max) > 0) max = version;
  }
  return max;
}

// Write the content to a temp file in the root, flush it, then put it in
// place (P-S06). The temp file has a random name and an exclusive create, so
// a planted file or link at that name fails the write. An update renames over
// product.yml. A create links the temp file to product.yml, which fails if a
// file appeared there meanwhile. Any failure removes the temp file and
// leaves product.yml as it was.
function writeTarget(target, content, create, mode) {
  const tmp = join(dirname(target), `.product.yml.planifest-tmp-${randomBytes(8).toString("hex")}`);
  let created = false;
  try {
    const fd = openSync(tmp, "wx", mode);
    created = true;
    try {
      fchmodSync(fd, mode);
      writeFileSync(fd, content);
      fsyncSync(fd);
    } finally {
      closeSync(fd);
    }
    if (create) {
      linkSync(tmp, target);
      unlinkSync(tmp);
    } else {
      renameSync(tmp, target);
    }
    created = false;
  } catch (err) {
    if (created) {
      try {
        unlinkSync(tmp);
      } catch {
        // The temp file is already gone.
      }
    }
    fsFail("product.yml: write", err);
  }
}

function main() {
  const { args, root, components } = validate(process.argv.slice(2));
  const featureId = args["--feature-id"];
  const version = args["--version"];
  const target = join(root, "product.yml");
  const current = readTarget(target);
  const exists = current !== null;

  if (!exists && !args.create) fail(4, "no product.yml at the root and no --create");

  const original = exists ? current.text : fsCall("product template: read", () => readFileSync(TEMPLATE, "utf-8"));
  const eol = original.includes("\r\n") ? "\r\n" : "\n";
  const lines = original.split(eol);
  const keys = topLevelLines(lines);

  if (!exists) {
    setScalar(lines, keys, "id", args["--product-id"]);
    setScalar(lines, keys, "name", args["--product-name"]);
    setScalar(lines, keys, "versionPolicy", "max-component-version");
  }
  if (components.length > 0) setComponents(lines, keys, components);

  const policy = parseManifest(lines).versionPolicy;
  if (!POLICIES.includes(policy)) fail(2, `product.yml: unknown versionPolicy (expected ${POLICIES.join(" | ")})`);

  if (policy === "max-component-version") {
    const derived = deriveVersion(root, parseManifest(lines).components);
    if (semverCompare(derived, version) !== 0) {
      fail(2, `--version: ${version} differs from the derived version ${derived}`);
    }
  }
  if (policy !== "external") setScalar(lines, keys, "version", version);
  setScalar(lines, keys, "feature", featureId);

  const updated = lines.join(eol);
  if (updated !== original || !exists) writeTarget(target, updated, !exists, exists ? current.mode : 0o644);

  if (policy === "external") {
    process.stdout.write(`product.yml: feature "${featureId}" (versionPolicy external, version unchanged)\n`);
    process.exit(5);
  }
  process.stdout.write(`product.yml: version "${version}", feature "${featureId}"\n`);
  process.exit(0);
}

// Every exit is 0, 2, 4, or 5 (ship skill Step 5b). An error that no rule
// caught exits 2 with a fixed message, never a stack trace or a path (P-N2).
try {
  main();
} catch (err) {
  fsFail("unexpected error", err);
}
