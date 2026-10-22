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
 * The script rewrites the top-level version and feature lines in place and
 * never appends a line. It replaces components[] only when --component is
 * given. With --create and no product.yml, it builds the file from
 * templates/product.template.yml under max-component-version.
 *
 * Hard Limit 8 carve-out (ADR-011): the script writes only {root}/product.yml.
 * Every argument is untrusted, and every rule runs before product.yml is
 * read. Each value is written as a double-quoted YAML scalar, and no allowed
 * character can end the scalar or start a line. An error message names the
 * argument and the rule and never echoes the raw value.
 *
 * Exit codes:
 *   0 - product.yml written, or it already held the same values
 *   2 - a rule break, an invalid manifest, a version mismatch, or a target
 *       that resolves elsewhere; nothing written, reason on stderr
 *   4 - no product.yml and no --create; nothing written
 *   5 - versionPolicy is external; only feature changed
 */

import {
  closeSync, constants, existsSync, lstatSync, openSync, readFileSync, realpathSync,
  statSync, writeSync,
} from "node:fs";
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

function resolveRootArg(rootArg) {
  let cwd = "";
  try {
    cwd = process.cwd();
  } catch {
    // A deleted working directory leaves cwd empty, and resolveRoot returns null.
  }
  const root = resolveRoot(cwd);
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
    if (!statSync(real).isFile()) fail(2, `${label}: path is not a file`);
    return { id, path };
  });
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
// anywhere else, or a target that is not a regular file, writes nothing.
function checkTarget(target) {
  let st;
  try {
    st = lstatSync(target);
  } catch {
    return false; // absent
  }
  // The root is already a real path, so a link here always resolves elsewhere.
  if (st.isSymbolicLink()) fail(2, "product.yml: is a link that resolves to another path");
  if (!st.isFile()) fail(2, "product.yml: is not a regular file");
  return true;
}

function unquote(v) {
  return v.trim().replace(/^["']|["']$/g, "");
}

// Index of each top-level key line. A key that appears twice is invalid.
function topLevelLines(lines) {
  const found = {};
  lines.forEach((line, i) => {
    const m = line.match(/^([A-Za-z][A-Za-z0-9_-]*):/);
    if (!m) return;
    if (found[m[1]] !== undefined) fail(2, `product.yml: top-level ${m[1]} appears more than once`);
    found[m[1]] = i;
  });
  return found;
}

// Rewrite one top-level scalar in place, keeping any trailing comment.
function setScalar(lines, keys, key, value) {
  const i = keys[key];
  if (i === undefined) fail(2, `product.yml: no top-level ${key} line to rewrite`);
  const m = lines[i].match(/^([A-Za-z][A-Za-z0-9_-]*:[ \t]*)("[^"]*"|'[^']*'|[^\s#]*)(.*)$/);
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
    const abs = join(root, c.path);
    if (!existsSync(abs)) fail(2, `${label}: component.yml not found`);
    let version = null;
    for (const raw of readFileSync(abs, "utf-8").split(/\r?\n/)) {
      const m = raw.replace(/#.*$/, "").trimEnd().match(/^version:\s*(.+)$/);
      if (m) { version = unquote(m[1]); break; }
    }
    if (version === null) fail(2, `${label}: no top-level version field`);
    if (version.length > 32 || !SEMVER_LOOSE_RE.test(version)) fail(2, `${label}: version is not MAJOR.MINOR.PATCH`);
    if (max === null || semverCompare(version, max) > 0) max = version;
  }
  return max;
}

function writeTarget(target, content, create) {
  const flags = create
    ? constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL
    : constants.O_WRONLY | constants.O_TRUNC | (constants.O_NOFOLLOW ?? 0);
  const fd = openSync(target, flags, 0o644);
  try {
    writeSync(fd, content);
  } finally {
    closeSync(fd);
  }
}

const { args, root, components } = validate(process.argv.slice(2));
const featureId = args["--feature-id"];
const version = args["--version"];
const target = join(root, "product.yml");
const exists = checkTarget(target);

if (!exists && !args.create) fail(4, "no product.yml at the root and no --create");

const original = exists ? readFileSync(target, "utf-8") : readFileSync(TEMPLATE, "utf-8");
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
if (updated !== original || !exists) writeTarget(target, updated, !exists);

if (policy === "external") {
  process.stdout.write(`product.yml: feature "${featureId}" (versionPolicy external, version unchanged)\n`);
  process.exit(5);
}
process.stdout.write(`product.yml: version "${version}", feature "${featureId}"\n`);
process.exit(0);
