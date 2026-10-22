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
 * Usage: node skill-drift-check.mjs [--root <dir>]
 *   --root  the project root. The default is the folder that holds
 *           planifest-framework/, found from this script's own path.
 *
 * Exit codes:
 *   0  every installed copy matches (one line on stdout)
 *   1  a copy is stale or missing, or nothing is installed (stderr)
 *   2  the script can't compare (the reason on stderr)
 */

import { readdirSync, readFileSync, realpathSync, statSync } from "node:fs";
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

const isMissing = (err) => err?.code === "ENOENT" || err?.code === "ENOTDIR";

/** Reads a file, or returns null when it doesn't exist. Any other error can't compare. */
function readOrNull(path) {
  try {
    return readFileSync(path);
  } catch (err) {
    if (isMissing(err)) return null;
    throw new CantCompare(`can't read ${shown(path, NAME_MAX)}: ${err?.code ?? err}`);
  }
}

function isFolder(path) {
  try {
    return statSync(path).isDirectory();
  } catch (err) {
    if (isMissing(err)) return false;
    throw new CantCompare(`can't read ${shown(path, NAME_MAX)}: ${err?.code ?? err}`);
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

/** The source skills: the folders in planifest-framework/skills/ that hold a SKILL.md. */
function sourceSkills(root) {
  const skillsDir = join(root, "planifest-framework", "skills");
  let names;
  try {
    names = readdirSync(skillsDir);
  } catch (err) {
    throw new CantCompare(`can't read the source skills folder ${shown(skillsDir, NAME_MAX)}: ${err?.code ?? err}`);
  }
  const skills = [];
  for (const name of names.sort()) {
    const bytes = isFolder(join(skillsDir, name)) ? readOrNull(join(skillsDir, name, "SKILL.md")) : null;
    if (bytes !== null) skills.push({ name, expected: expectedCopy(bytes) });
  }
  return skills;
}

/** The tools with a valid marker: one that parses and names a tool in the map. */
function markedTools(root) {
  const tools = [];
  for (const [tool, markerDir] of Object.entries(TOOL_MARKER_DIRS)) {
    const bytes = readOrNull(join(root, markerDir, MARKER_FILE));
    if (bytes === null) continue;
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
  const hasSkills = (tool) => TOOL_SKILLS_DIRS[tool] !== null;
  const candidates = (marked.length > 0 ? marked : Object.keys(TOOL_SKILLS_DIRS)).filter(hasSkills);
  const installed = candidates.filter((tool) => isFolder(join(root, TOOL_SKILLS_DIRS[tool])));
  const absent = marked.length > 0 ? candidates.filter((tool) => !installed.includes(tool)) : [];

  const notInstalled = (detail) =>
    `not installed${detail}. Run planifest-framework/setup.sh or planifest-framework/setup.ps1 to install the skills.`;

  if (installed.length === 0) return { code: 1, stdout: [], stderr: [notInstalled("")] };

  const findings = [];
  for (const tool of installed) {
    for (const { name, expected } of skills) {
      const copy = readOrNull(join(root, TOOL_SKILLS_DIRS[tool], name, "SKILL.md"));
      if (copy === null) findings.push(`missing: ${tool}: ${shown(name, NAME_MAX)}`);
      else if (!stripBom(copy).equals(expected)) findings.push(`stale: ${tool}: ${shown(name, NAME_MAX)}`);
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
