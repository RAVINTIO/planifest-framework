#!/usr/bin/env node
/**
 * skill-drift-check.mjs - compares each source SKILL.md with the active
 * tool's installed copy (feature 0000036 req-002, ADR-005).
 *
 * Setup copies planifest-framework/skills/{skill}/SKILL.md into a tool's
 * skills folder and rewrites four relative paths. This script applies the
 * same rewrites to the source text, strips one leading UTF-8 byte order mark
 * from each side, and compares the bytes. It compares SKILL.md only.
 *
 * It uses Node built-ins only, starts no process, and never writes a file.
 * It warns and never blocks: the orchestrator runs it at session start.
 *
 * It checks each path with lstat before it opens it, and never follows a
 * link (S-3, S-4). Setup copies and never links, so a link at an installed
 * copy or skills folder is stale. So is a FIFO, a device, or a copy over
 * READ_CAP. A source SKILL.md like that can't compare. A marker like that
 * isn't valid.
 *
 * Usage: node skill-drift-check.mjs [--root <dir>]
 *   --root  the project root. The default is the folder that holds
 *           planifest-framework/, found from this script's own path.
 *
 * Exit codes:
 *   0  every installed copy matches (one line on stdout)
 *   1  a copy is stale or missing, or nothing is installed (stderr)
 *   2  the script can't compare (the reason on stderr)
 */

import { closeSync, constants, fstatSync, lstatSync, openSync, readdirSync, readSync, realpathSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { shown } from "../hooks/enforcement/path-rules.mjs";

/** Tool name to skills folder. Matches TOOL_SKILLS_DIR in setup/{tool}.sh. */
export const TOOL_SKILLS_DIRS = Object.freeze({
  "claude-code": ".claude/skills",
  cursor: ".cursor/skills",
  codex: ".agents/skills",
  antigravity: ".gemini/skills",
  copilot: ".github/skills",
  windsurf: ".windsurf/skills",
  cline: ".clinerules/skills",
  opencode: null,
});

/** Tool name to the folder that holds its .planifest-setup-flags marker. */
const TOOL_MARKER_DIRS = Object.freeze({
  ...Object.fromEntries(
    Object.entries(TOOL_SKILLS_DIRS)
      .filter(([, dir]) => dir !== null)
      .map(([tool, dir]) => [tool, dirname(dir)]),
  ),
  opencode: ".opencode",
});

/** Setup's path rewrites, in setup.sh copy_skills() order. */
export const REWRITES = Object.freeze([
  ["../templates/", "./assets/templates/"],
  ["../standards/", "./references/"],
  ["../standards/reference/", "./references/reference/"],
  ["../schemas/", "./assets/schemas/"],
]);

const MARKER_FILE = ".planifest-setup-flags";
const BOM = Buffer.from([0xef, 0xbb, 0xbf]);
const NAME_MAX = 200;

/** Raised when the script can't compare. main() turns it into exit 2. */
class CantCompare extends Error {}

/** The largest file the script reads, as run-mode.mjs caps its reads (S-3). */
export const READ_CAP = 1024 * 1024;

// O_NOFOLLOW refuses a link swapped in after lstat. O_NONBLOCK keeps a FIFO
// swapped in after lstat from stalling the open. Windows defines neither.
const OPEN_FLAGS = constants.O_RDONLY | (constants.O_NOFOLLOW ?? 0) | (constants.O_NONBLOCK ?? 0);

const isMissing = (err) => err?.code === "ENOENT" || err?.code === "ENOTDIR";
const cantRead = (path, err) => new CantCompare(`can't read ${shown(path, NAME_MAX)}: ${err?.code ?? err}`);

/**
 * The kind of one path, from lstat, so a link is never followed. One of
 * "missing", "link", "folder", "file", "oversize" (a file over READ_CAP), or
 * "other" (a FIFO, device, socket, or anything else).
 */
function kindOf(path) {
  let st;
  try {
    st = lstatSync(path);
  } catch (err) {
    if (isMissing(err)) return "missing";
    throw cantRead(path, err);
  }
  if (st.isSymbolicLink()) return "link";
  if (st.isDirectory()) return "folder";
  if (st.isFile()) return st.size > READ_CAP ? "oversize" : "file";
  return "other";
}

/**
 * The kind of root/parts[0]/.../parts[n-1]. Each step is checked with lstat,
 * so a linked folder on the way reads as "link". A non-folder on the way
 * reads as "missing", as ENOTDIR does.
 */
function kindUnder(root, parts) {
  let path = root;
  for (let i = 0; i < parts.length; i++) {
    path = join(path, parts[i]);
    const kind = kindOf(path);
    if (i === parts.length - 1 || kind === "missing" || kind === "link") return kind;
    if (kind !== "folder") return "missing";
  }
  return "folder";
}

/**
 * Reads root/parts... only when every step is a real folder and the file is a
 * regular file of READ_CAP bytes or fewer. Returns { kind, bytes }, where
 * bytes is set only when kind is "file". Any read error other than "no such
 * file" can't compare.
 */
function readSafe(root, parts) {
  const kind = kindUnder(root, parts);
  if (kind !== "file") return { kind };
  const path = join(root, ...parts);
  let fd;
  try {
    fd = openSync(path, OPEN_FLAGS);
  } catch (err) {
    if (isMissing(err)) return { kind: "missing" };
    if (err?.code === "ELOOP" || err?.code === "EMLINK") return { kind: "link" };
    throw cantRead(path, err);
  }
  try {
    const st = fstatSync(fd);
    if (!st.isFile()) return { kind: "other" };
    if (st.size > READ_CAP) return { kind: "oversize" };
    // Read one byte past the cap, so a file that grew after fstat still reads as oversize.
    const buf = Buffer.allocUnsafe(READ_CAP + 1);
    let total = 0;
    for (;;) {
      const n = readSync(fd, buf, total, buf.length - total, null);
      if (n === 0) break;
      total += n;
      if (total === buf.length) return { kind: "oversize" };
    }
    return { kind: "file", bytes: buf.subarray(0, total) };
  } catch (err) {
    throw cantRead(path, err);
  } finally {
    closeSync(fd);
  }
}

function stripBom(bytes) {
  return bytes.subarray(0, 3).equals(BOM) ? bytes.subarray(3) : bytes;
}

/**
 * The bytes setup would install for a source SKILL.md. Latin-1 maps each byte
 * to one character and back, so the rewrites never change non-ASCII bytes.
 */
export function expectedCopy(sourceBytes) {
  let text = stripBom(sourceBytes).toString("latin1");
  for (const [from, to] of REWRITES) text = text.replaceAll(from, to);
  return Buffer.from(text, "latin1");
}

function parseArgs(argv) {
  if (argv.length === 0) return { root: resolve(dirname(fileURLToPath(import.meta.url)), "..", "..") };
  if (argv.length === 2 && argv[0] === "--root" && argv[1] !== "") return { root: resolve(argv[1]) };
  throw new CantCompare("usage: node skill-drift-check.mjs [--root <dir>]");
}

const SOURCE_REASONS = Object.freeze({
  link: "is a link",
  other: "isn't a regular file",
  oversize: `is over ${READ_CAP} bytes`,
});

/**
 * The source skills: the folders in planifest-framework/skills/ that hold a
 * SKILL.md. A linked skills folder, a linked skill folder, or a source
 * SKILL.md that is a link, not a regular file, or over the cap can't compare.
 */
function sourceSkills(root) {
  const skillsDir = join(root, "planifest-framework", "skills");
  const dirKind = kindOf(skillsDir);
  if (dirKind !== "folder") {
    const reason = dirKind === "missing" ? "ENOENT" : SOURCE_REASONS[dirKind] ?? "isn't a folder";
    throw new CantCompare(`can't read the source skills folder ${shown(skillsDir, NAME_MAX)}: ${reason}`);
  }
  let names;
  try {
    names = readdirSync(skillsDir);
  } catch (err) {
    throw new CantCompare(`can't read the source skills folder ${shown(skillsDir, NAME_MAX)}: ${err?.code ?? err}`);
  }
  const skills = [];
  for (const name of names.sort()) {
    const parts = ["planifest-framework", "skills", name, "SKILL.md"];
    const { kind, bytes } = readSafe(root, parts);
    if (kind === "missing") continue;
    if (kind === "file") {
      skills.push({ name, expected: expectedCopy(bytes) });
      continue;
    }
    // A linked skill folder reads as "link" before its SKILL.md is reached.
    const folderLinked = kindOf(join(skillsDir, name)) === "link";
    const what = folderLinked ? join(skillsDir, name) : join(root, ...parts);
    throw new CantCompare(`the source ${shown(what, NAME_MAX)} ${SOURCE_REASONS[kind]}`);
  }
  return skills;
}

/**
 * The tools with a valid marker: a regular file within the cap that parses
 * and names a tool in the map. A linked, non-regular, or oversize marker
 * isn't valid.
 */
function markedTools(root) {
  const tools = [];
  for (const [tool, markerDir] of Object.entries(TOOL_MARKER_DIRS)) {
    const { kind, bytes } = readSafe(root, [...markerDir.split("/"), MARKER_FILE]);
    if (kind !== "file") continue;
    let marker;
    try {
      marker = JSON.parse(stripBom(bytes).toString("utf8"));
    } catch {
      continue;
    }
    const named = marker?.tool;
    if (typeof named === "string" && Object.hasOwn(TOOL_SKILLS_DIRS, named) && !tools.includes(named)) {
      tools.push(named);
    }
  }
  return tools;
}

/**
 * Runs the check. Returns { code, stdout, stderr } with output as line arrays.
 * Throws CantCompare when it can't compare.
 */
export function check(root) {
  const skills = sourceSkills(root);
  const marked = markedTools(root);

  if (marked.length > 0 && marked.every((tool) => TOOL_SKILLS_DIRS[tool] === null)) {
    return { code: 0, stdout: [`skill-drift-check: ${marked.join(", ")} installs no skills.`], stderr: [] };
  }

  // With a valid marker, check the marked tools. With none, check every skills folder that exists.
  // Setup copies and never links, so a linked skills folder counts as
  // installed, and every skill in it is stale. The script never follows it.
  const hasSkills = (tool) => TOOL_SKILLS_DIRS[tool] !== null;
  const dirParts = (tool) => TOOL_SKILLS_DIRS[tool].split("/");
  const candidates = (marked.length > 0 ? marked : Object.keys(TOOL_SKILLS_DIRS)).filter(hasSkills);
  const folderKinds = Object.fromEntries(candidates.map((tool) => [tool, kindUnder(root, dirParts(tool))]));
  const installed = candidates.filter((tool) => folderKinds[tool] === "folder" || folderKinds[tool] === "link");
  const absent = marked.length > 0 ? candidates.filter((tool) => !installed.includes(tool)) : [];

  const notInstalled = (detail) =>
    `not installed${detail}. Run planifest-framework/setup.sh or planifest-framework/setup.ps1 to install the skills.`;

  if (installed.length === 0) return { code: 1, stdout: [], stderr: [notInstalled("")] };

  const findings = [];
  for (const tool of installed) {
    for (const { name, expected } of skills) {
      // A link at the copy or its folder, a FIFO, a device, or a copy over the cap is stale.
      const { kind, bytes } =
        folderKinds[tool] === "link" ? { kind: "link" } : readSafe(root, [...dirParts(tool), name, "SKILL.md"]);
      if (kind === "missing") findings.push(`missing: ${tool}: ${shown(name, NAME_MAX)}`);
      else if (kind !== "file" || !stripBom(bytes).equals(expected)) findings.push(`stale: ${tool}: ${shown(name, NAME_MAX)}`);
    }
  }
  const stderr = absent.map((tool) => notInstalled(`: ${tool}`));

  if (findings.length > 0) {
    stderr.push(...findings, "Run the planifest-refresh-setup skill to refresh the installed skills.");
  }
  if (stderr.length > 0) return { code: 1, stdout: [], stderr };

  return {
    code: 0,
    stdout: [`skill-drift-check: ${skills.length} skills match source for ${installed.join(", ")}.`],
    stderr: [],
  };
}

function main() {
  let result;
  try {
    result = check(parseArgs(process.argv.slice(2)).root);
  } catch (err) {
    const reason = err instanceof CantCompare ? err.message : `unexpected error: ${shown(err?.message ?? err, NAME_MAX)}`;
    process.stderr.write(`skill-drift-check: can't compare: ${reason}\n`);
    process.exitCode = 2;
    return;
  }
  for (const line of result.stdout) process.stdout.write(`${line}\n`);
  for (const line of result.stderr) process.stderr.write(`${line}\n`);
  process.exitCode = result.code;
}

// Node loads the main module by its real path, so compare real paths. An
// import, such as the suite's, doesn't run main().
function isMain() {
  try {
    return import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
  } catch {
    return false;
  }
}

if (isMain()) main();
