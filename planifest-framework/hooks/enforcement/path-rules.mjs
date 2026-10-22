/**
 * Shared path rules for the write gates (req-006, ADR-004).
 *
 * gate-write.mjs and the Bash shell guard both import this module, so they
 * judge every path the same way. Neither hook keeps a copy of these rules.
 *
 * PLACEMENT (0000028-ADR-002): this module lives in hooks/enforcement/. Every
 * install that copies gate-write.mjs copies every *.mjs in this folder, so the
 * import always resolves.
 *
 * Constraints (ADR-004):
 *   - Node built-in modules only, and no process spawn.
 *   - The repository root is the nearest folder that holds
 *     planifest-framework/, else the nearest that holds .git. The walk starts
 *     at CLAUDE_PROJECT_DIR when it names a folder and finds a marker, and
 *     at cwd otherwise. With no marker, the root is cwd.
 *     A marker inside plan/ or docs/ of a higher marked folder never counts,
 *     because those prefixes are always permitted and anyone can plant one.
 *     Nor does a marker with an always-permitted basename, such as
 *     claude.md, in its path below a higher marked folder (0000035 ADR-008).
 *     A cwd that no longer exists walks up to its nearest existing folder
 *     (0000035 ADR-006).
 *   - Both sides of the root comparison are real paths. A target resolves
 *     one segment at a time through symbolic links, with a 40-hop limit, and
 *     a resolution error for a path inside the root blocks (0000035 ADR-005).
 *   - plan/.orchestrator-active, plan/current/design.md, and
 *     plan/.fast-path-scope are looked up from the root, not from cwd.
 *   - Comparisons use the 0000009-ADR-005 normalisation: forward slashes and
 *     lower case.
 *
 * Exports:
 *   resolveRoot(cwd)                 real repository root, or null if cwd is unusable
 *   resolveTarget(root, cwd, target) { status: inside | outside | unresolvable } for a target
 *   toRootRelative(root, cwd, target) root-relative path, or null when outside the root
 *   hookCwd(input)                   the folder a hook judges from, or null
 *   evaluateWrite(root, relPath)     { allowed, reason?, warning?, notice? } for a root-relative path
 *   judgeWrite(cwd, target)          resolveRoot, resolveTarget, and evaluateWrite in one call
 *   unjudgeable(base, target)        a warning when the path is too long to judge, or null
 *   norm(p)                          the shared comparison normalisation
 *   parseScopeRecord(text)           the Fast Path scope record fields, or { error }
 *   readGitState(root)               { branch, head } read from .git files, or { error }
 *   isEnforcementPath(relPath)       whether FAST_PATH_ENFORCEMENT_PATHS covers relPath
 *   FAST_PATH_ENFORCEMENT_PATHS      paths no scope record admits (0000035 ADR-004)
 */

import { existsSync, lstatSync, readFileSync, readlinkSync, realpathSync, statSync } from "node:fs";
import { dirname, isAbsolute, join, normalize, parse, relative, resolve, sep } from "node:path";

// Always-permitted: planning and doc artefacts and Planifest internal files.
export const ALWAYS_PERMITTED_PREFIXES = ["plan/", "docs/"];
export const ALWAYS_PERMITTED_FILES = [
  "claude.md", "agents.md", ".planifest-session", ".skips", ".feature-id",
  ".gitignore", ".gitattributes", ".claudeignore", ".cursorignore",
  ".windsurfignore", ".clineignore", ".cursorindexingignore",
  "pause.md",
];

// Headings that introduce the component paths list in design.md (0000003-ADR-004).
const PATHS_SECTION_RE = /^##\s+(Component Paths|Scope)\s*$/im;

// Folders whose presence marks a repository root (ADR-004).
const ROOT_MARKERS = ["planifest-framework", ".git"];

const SENTINEL_REASON =
  "[Planifest] No orchestrator sentinel at plan/.orchestrator-active. " +
  "Load the planifest-orchestrator skill and complete Phase 0 before " +
  "writing plan artefacts.\n";
const NO_DESIGN_REASON =
  "[Planifest] No confirmed design at plan/current/design.md. " +
  "Complete Phase 0 first.\n";
const UNPARSEABLE_WARNING =
  "[Planifest] Warning: Could not parse component paths from " +
  "plan/current/design.md. Ensure a '## Component Paths' section exists. " +
  "Write allowed.\n";

// Paths past these limits are too long to judge. Resolving one through the
// file system can take tens of seconds, which outlasts the hook timeout (F7).
export const MAX_PATH_CHARS = 4096;
export const MAX_PATH_SEGMENTS = 256;

const tooLong = (p) =>
  p.length > MAX_PATH_CHARS || p.split(/[\\/]+/).length > MAX_PATH_SEGMENTS;

/**
 * A one-line warning when target, resolved against base, is over
 * MAX_PATH_CHARS characters or MAX_PATH_SEGMENTS segments. The limits apply
 * to the resolved path, so a long raw path that normalises to a short one is
 * judged (N-3). Returns null for a path the rules can judge. Resolving is
 * string work only and makes no file-system call.
 */
export function unjudgeable(base, target) {
  if (typeof target !== "string") return null;
  const resolved = typeof base === "string" ? resolve(base, target) : normalize(target);
  if (!tooLong(resolved)) return null;
  return (
    `[Planifest] Warning: the path '${target.slice(0, 80)}...' is too long to judge ` +
    `(over ${MAX_PATH_CHARS} characters or ${MAX_PATH_SEGMENTS} segments). Write allowed.\n`
  );
}

export function norm(p) {
  return normalize(p).replace(/\\/g, "/").toLowerCase();
}

function isDirectory(p) {
  try {
    return statSync(p).isDirectory();
  } catch {
    return false;
  }
}

// A path resolution error: realpathSync failed on a path the walk reached.
// code is the error code, and reached is the real path the walk got to before
// the error, with the rest of the path appended as text (0000035 ADR-005).
class ResolutionError extends Error {
  constructor(code, reached) {
    super(code);
    this.code = code;
    this.reached = reached;
  }
}

// nearestExisting: walks up from the absolute path p with statSync to the
// nearest path that exists, or the nearest folder when wantFolder is set.
// Only ENOENT and ENOTDIR count as missing. Any other error, such as EACCES,
// stops the walk at that path, so a permission error can't move the result
// (0000035 ADR-006). Returns { stop, missing }, where missing holds the
// segments below stop, nearest first.
function nearestExisting(p, wantFolder = false) {
  const missing = [];
  let current = p;
  for (;;) {
    try {
      const stats = statSync(current);
      if (!wantFolder || stats.isDirectory()) return { stop: current, missing };
    } catch (err) {
      if (err?.code !== "ENOENT" && err?.code !== "ENOTDIR") return { stop: current, missing };
    }
    const parent = dirname(current);
    if (parent === current) return { stop: current, missing };
    missing.unshift(relative(parent, current));
    current = parent;
  }
}

// The most links one resolution follows, the Linux MAXSYMLINKS value
// (0000035 ADR-005).
export const MAX_LINK_HOPS = 40;

const segmentsOf = (p) => p.split(/[\\/]+/).filter(Boolean);

/**
 * realPathOf: the real path the absolute path p names, found one segment at
 * a time (0000035 ADR-005).
 *   - lstatSync checks each existing segment. A link puts its text in place
 *     of the segment. Relative text resolves against the link's real folder,
 *     and absolute text restarts the walk at its own root.
 *   - A .. moves to the real parent of the path resolved so far. It never
 *     collapses as text before the segments to its left resolve.
 *   - From the first ENOENT or ENOTDIR, the rest of the path appends as text,
 *     with any .. among it collapsed. A dangling link resolves to its target.
 * Throws a ResolutionError for a link loop, a chain past MAX_LINK_HOPS, a
 * path past the length limits after a substitution, or any other error.
 * p is never collapsed as text first, so it must not pass through resolve().
 */
function realPathOf(p) {
  let resolved = parse(p).root;
  let pending = segmentsOf(p.slice(resolved.length));
  let hops = 0;
  let chain = new Set(); // links followed since the last ordinary segment
  const fail = (code, rest) => new ResolutionError(code, join(resolved, ...rest));

  while (pending.length) {
    const segment = pending.shift();
    if (segment === ".") continue;
    if (segment === "..") {
      resolved = dirname(resolved); // resolved is real, so this is its real parent
      continue;
    }
    const next = join(resolved, segment);
    let stats;
    try {
      stats = lstatSync(next);
    } catch (err) {
      if (err?.code === "ENOENT" || err?.code === "ENOTDIR") return join(next, ...pending);
      throw fail(err?.code ?? "an unknown error", [segment, ...pending]);
    }
    if (!stats.isSymbolicLink()) {
      resolved = next;
      chain = new Set();
      continue;
    }
    if (chain.has(next)) throw fail("link loop", [segment, ...pending]);
    chain.add(next);
    hops += 1;
    if (hops > MAX_LINK_HOPS) throw fail(`more than ${MAX_LINK_HOPS} links`, [segment, ...pending]);
    let text;
    try {
      text = readlinkSync(next);
    } catch (err) {
      throw fail(err?.code ?? "an unknown error", [segment, ...pending]);
    }
    if (isAbsolute(text)) {
      resolved = parse(resolve(text)).root;
      pending = [...segmentsOf(text.slice(parse(text).root.length)), ...pending];
    } else {
      pending = [...segmentsOf(text), ...pending];
    }
    if (tooLong(join(resolved, ...pending))) throw fail("too long to judge after its links", pending);
  }
  return resolved;
}

// absoluteText: target placed against the real folder base without
// collapsing any .. as text, so realPathOf resolves it as the system would.
const absoluteText = (base, target) => (isAbsolute(target) ? target : base + sep + target);

// planted: whether the marked folder at rel, a path relative to a higher
// marked folder, is distrusted. Its first segment is plan or docs (F1), or
// any of its segments, its own name included, is an always-permitted
// basename such as claude.md (0000035 ADR-008). An agent can plant a marker
// under plan/ and move the folder to src/claude.md, so neither may be a root.
function plantedAt(rel) {
  const segments = norm(rel).split("/");
  if (ALWAYS_PERMITTED_PREFIXES.some((prefix) => prefix === segments[0] + "/")) return true;
  return segments.some((segment) => ALWAYS_PERMITTED_FILES.includes(segment));
}

// markedRoot: the nearest trusted marked folder at or above start, a real
// path, or null when no folder holds a marker. A folder holding
// planifest-framework/ beats one holding only .git (a .git file counts, for
// worktrees). A folder that sits inside plan/ or docs/ of a higher marked
// folder, or below an always-permitted basename, is never a root (F1,
// 0000035 ADR-008). The walk goes on past a distrusted marker.
function markedRoot(start) {
  // Every marked folder from start up to the file-system root, nearest first.
  const marked = [];
  let dir = start;
  for (;;) {
    const framework = isDirectory(join(dir, "planifest-framework"));
    const git = existsSync(join(dir, ".git"));
    if (framework || git) marked.push({ dir, framework, git });
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  const planted = (candidate) =>
    marked.some(({ dir: above }) => {
      if (above === candidate.dir) return false;
      const rel = relative(above, candidate.dir);
      if (!rel || rel.startsWith("..") || isAbsolute(rel)) return false;
      return plantedAt(rel);
    });
  const trusted = marked.filter((m) => !planted(m));

  const framework = trusted.find((m) => m.framework);
  if (framework) return framework.dir;
  const git = trusted.find((m) => m.git);
  return git ? git.dir : null;
}

/**
 * The repository root for cwd, as a real path (ADR-004, findings F1, N-4,
 * and N-5).
 *   1. The marked root found by walking up from CLAUDE_PROJECT_DIR, when the
 *      variable names a folder and the walk finds a marker. The variable is a
 *      starting point, never the root itself (N-4). It wins over cwd because
 *      an agent can change cwd with cd but can't change the hook's
 *      environment.
 *   2. The marked root found by walking up from the nearest existing folder
 *      at or above cwd. A cwd that no longer exists still finds its
 *      repository this way (0000035 ADR-006).
 *   3. The real path of that nearest existing folder.
 * Each walk takes the nearest folder holding planifest-framework/, then the
 * nearest holding .git (N-5). Returns null, and never throws, when cwd is not
 * a non-empty string. It also returns null when the walk from cwd stops at a
 * path whose real path can't be resolved, because no root is then known.
 */
export function resolveRoot(cwd) {
  try {
    if (typeof cwd !== "string" || !cwd) return null;
    const projectDir = process.env.CLAUDE_PROJECT_DIR;
    if (projectDir && isDirectory(projectDir)) {
      const fromProject = markedRoot(realpathSync(projectDir));
      if (fromProject) return fromProject;
    }
    const start = realpathSync(nearestExisting(resolve(cwd), true).stop);
    return markedRoot(start) ?? start;
  } catch {
    return null;
  }
}

// within: the path of abs relative to root, with forward slashes and its
// original case, or null when abs is outside root. Matches whole segments.
function within(root, abs) {
  const normRoot = norm(root).replace(/\/$/, "");
  const normAbs = norm(abs);
  if (normAbs === normRoot) return "";
  const rootPrefix = normRoot + "/";
  if (!normAbs.startsWith(rootPrefix)) return null;
  return abs.replace(/\\/g, "/").slice(rootPrefix.length);
}

/**
 * Resolves target from cwd through every link and places it against root
 * (0000035 ADR-005). Returns one of:
 *   { status: "inside", relPath }       relPath has forward slashes and its original case
 *   { status: "outside" }               outside root, or too long to judge (F7)
 *   { status: "unresolvable", reason }  a resolution error for a path inside root
 * cwd goes through the same resolution, and a relative target resolves
 * against its real path. A resolution error counts as unresolvable when the
 * target as text, or the real path reached before the error, lies inside
 * root. Otherwise the target is outside. The reason shows the first 80
 * characters of target and never prints link text.
 */
export function resolveTarget(root, cwd, target) {
  if (typeof target !== "string" || !target || typeof cwd !== "string") return { status: "outside" };
  if (unjudgeable(cwd, target)) return { status: "outside" }; // no slow file-system walk (F7)
  const textAbs = resolve(cwd, target);
  let abs;
  try {
    const base = realPathOf(isAbsolute(cwd) ? cwd : resolve(cwd));
    abs = realPathOf(absoluteText(base, target));
  } catch (err) {
    if (!(err instanceof ResolutionError)) throw err;
    if (within(root, textAbs) === null && within(root, err.reached) === null) return { status: "outside" };
    return {
      status: "unresolvable",
      reason:
        `[Planifest] Can't resolve the path '${target.slice(0, 80)}' inside the repository root ` +
        `(${err.code}). Write blocked, because the gate can't judge where it lands.\n`,
    };
  }
  const relPath = within(root, abs);
  return relPath === null ? { status: "outside" } : { status: "inside", relPath };
}

/**
 * The target's path relative to root, with forward slashes and its original
 * case. Returns null when the target is outside root or can't be resolved.
 * Kept for existing callers. The gates call resolveTarget.
 */
export function toRootRelative(root, cwd, target) {
  try {
    const result = resolveTarget(root, cwd, target);
    return result.status === "inside" ? result.relPath : null;
  } catch {
    return null;
  }
}

/**
 * The working folder a hook judges from (0000035 ADR-006): the stdin cwd
 * field when it is a non-empty string, then process.cwd(), then
 * CLAUDE_PROJECT_DIR. Returns null when none is usable, and the hook passes.
 */
export function hookCwd(input) {
  if (typeof input?.cwd === "string" && input.cwd) return input.cwd;
  try {
    return process.cwd();
  } catch {
    const projectDir = process.env.CLAUDE_PROJECT_DIR;
    return typeof projectDir === "string" && projectDir ? projectDir : null;
  }
}

function isAlwaysPermitted(relPath) {
  const n = norm(relPath);
  const base = n.split("/").pop() ?? "";
  if (ALWAYS_PERMITTED_FILES.includes(base)) return true;
  return ALWAYS_PERMITTED_PREFIXES.some((prefix) => n.startsWith(prefix));
}

function extractComponentPaths(content) {
  const match = PATHS_SECTION_RE.exec(content);
  if (!match) return null;

  const afterHeading = content.slice(match.index + match[0].length);
  const paths = [];

  for (const line of afterHeading.split("\n")) {
    if (/^##\s/.test(line)) break; // stop at the next h2
    // Match "- path", "* path", "- `path`", and "| path |" table rows.
    const m = line.match(/^[\s*\-|]+`?([^\s`|,{}]+)`?/);
    if (m?.[1] && !m[1].startsWith("{") && m[1].includes("/")) {
      paths.push(m[1].replace(/\/$/, "")); // strip a trailing slash before comparison
    }
  }

  return paths.length ? paths : null;
}

function matchesComponentPath(relPath, componentPaths) {
  const normTarget = norm(relPath);
  return componentPaths.some((cp) => {
    const normCp = norm(cp);
    return normTarget === normCp || normTarget.startsWith(normCp + "/");
  });
}

// ---------------------------------------------------------------------------
// Fast Path scope record (0000035 ADR-002 and ADR-003)
// ---------------------------------------------------------------------------

export const FAST_PATH_SCOPE_FILE = "plan/.fast-path-scope";
const SCOPE_MAX_BYTES = 16 * 1024;
const SCOPE_MAX_PATHS = 64;
const GIT_FILE_MAX_BYTES = 4 * 1024;
const PACKED_REFS_MAX_BYTES = 4 * 1024 * 1024;

const BRANCH_RE = /^[A-Za-z0-9._/-]{1,255}$/;
const HEAD_RE = /^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$/;
const SCOPE_PATH_RE = /^[A-Za-z0-9._@+ /-]{1,512}$/;
const REF_RE = /^refs\/[A-Za-z0-9._/-]{1,255}$/;
const DETACHED = "(detached)";

// Paths a Fast Path scope record never admits (0000035 ADR-004, 0000033
// ADR 009). workflows/fast-path.md names the same entries, and a suite
// checks both directions. An entry ending in / covers that folder and
// everything below it. Any other plain entry covers that file and anything
// below it. An entry that starts with **/ matches at any depth: **/name
// matches a last segment, and **/a/b/ matches a segment pair.
export const FAST_PATH_ENFORCEMENT_PATHS = Object.freeze([
  // Framework enforcement
  "planifest-framework/hooks/",
  "planifest-framework/scripts/",
  "planifest-framework/setup/",
  "planifest-framework/standards/autonomous-run-standards.md",
  // Setup scripts and every installed hook or adapter folder
  "**/setup.sh",
  "**/setup.ps1",
  "**/hooks/enforcement/",
  "**/hooks/adapters/",
  // Git hooks and config
  ".git/",
  // Hook wiring files that setup.sh and setup.ps1 write
  ".claude/settings.json",
  ".cursor/settings.json",
  ".clinerules/hooks.json",
  ".windsurf/hooks.json",
  ".github/hooks/",
  ".codex/config.toml",
  "opencode.json",
  ".opencode/plugins/@planifest/opencode-hooks/",
  // Tool-local settings files, which can also register or turn off hooks
  ".claude/settings.local.json",
  "opencode.jsonc",
]);

/**
 * Whether relPath matches an entry in FAST_PATH_ENFORCEMENT_PATHS. Matching
 * compares norm(relPath) with norm(entry), so it ignores case.
 */
export function isEnforcementPath(relPath) {
  const target = norm(relPath || ".");
  const segments = target.split("/");
  return FAST_PATH_ENFORCEMENT_PATHS.some((raw) => {
    const entry = norm(raw);
    if (entry.startsWith("**/")) {
      const rest = entry.slice(3);
      if (!rest.endsWith("/")) return segments[segments.length - 1] === rest;
      return `/${target}/`.includes(`/${rest}`);
    }
    const bare = entry.replace(/\/$/, "");
    return target === bare || target.startsWith(bare + "/");
  });
}

// readCapped: the UTF-8 text of file, or null when it is missing, larger than
// max bytes, or unreadable. The size check runs before the read.
function readCapped(file, max) {
  try {
    const stats = statSync(file);
    if (!stats.isFile() || stats.size > max) return null;
    return readFileSync(file, "utf-8");
  } catch {
    return null;
  }
}

const validBranch = (b) => b === DETACHED || (BRANCH_RE.test(b) && !b.includes("..") && !b.startsWith("-"));

// validScopePath: whether p is a root-relative path the record may list. No
// glob, no backslash, no drive letter, and no empty, . or .. segment.
function validScopePath(p) {
  if (!SCOPE_PATH_RE.test(p) || p.startsWith("/")) return false;
  const segments = p.replace(/\/$/, "").split("/");
  return segments.every((s) => s !== "" && s !== "." && s !== "..");
}

/**
 * Parses the scope record text. Returns { branch, head, paths } or
 * { error } when any line breaks the grammar. The error names the line
 * number and the rule, never a raw value. Blank and # lines are skipped.
 */
export function parseScopeRecord(text) {
  const expected = ["branch", "head", "paths"];
  const record = { paths: [] };
  let step = 0;
  const lines = text.split(/\r?\n/);
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    const at = `line ${n + 1}`;
    if (line.trim() === "" || line.startsWith("#")) continue;
    if (step < expected.length) {
      const key = expected[step];
      if (key === "paths") {
        if (!/^paths:\s*$/.test(line)) return { error: `${at}: expected 'paths:'` };
      } else {
        const m = line.match(new RegExp(`^${key}: (.*?)\\s*$`));
        if (!m) return { error: `${at}: expected '${key}: <value>'` };
        if (key === "branch" && !validBranch(m[1])) return { error: `${at}: the branch breaks the allowed pattern` };
        if (key === "head" && !HEAD_RE.test(m[1])) return { error: `${at}: the head is not a 40 or 64 character hex commit` };
        record[key] = m[1];
      }
      step += 1;
      continue;
    }
    const m = line.match(/^- (.*)$/);
    if (!m) return { error: `${at}: expected '- <path>'` };
    if (!validScopePath(m[1])) return { error: `${at}: the path breaks the allowed pattern` };
    record.paths.push(m[1]);
    if (record.paths.length > SCOPE_MAX_PATHS) return { error: `${at}: more than ${SCOPE_MAX_PATHS} paths` };
  }
  if (step < expected.length) return { error: `the record ends before '${expected[step]}'` };
  if (!record.paths.length) return { error: "the record lists no paths" };
  return record;
}

/**
 * Reads the current branch and HEAD commit from the git files at or above
 * root, with no process spawn (0000035 ADR-003). Returns { branch, head } or
 * { error } when any step fails, such as a reftable store, an unborn branch,
 * or a file over its size limit.
 */
export function readGitState(root) {
  let dir = root;
  let dotGit = null;
  for (;;) {
    try {
      statSync(join(dir, ".git"));
      dotGit = join(dir, ".git");
      break;
    } catch { /* keep climbing */ }
    const parent = dirname(dir);
    if (parent === dir) return { error: "no .git found" };
    dir = parent;
  }

  let gitDir = dotGit;
  try {
    if (!statSync(dotGit).isDirectory()) {
      const text = readCapped(dotGit, GIT_FILE_MAX_BYTES);
      const m = text?.match(/^gitdir: (.+?)\s*$/m);
      if (!m) return { error: "the .git file has no readable gitdir line" };
      gitDir = resolve(dirname(dotGit), m[1]);
    }
  } catch {
    return { error: "the .git entry can't be read" };
  }

  const headText = readCapped(join(gitDir, "HEAD"), GIT_FILE_MAX_BYTES);
  if (headText === null) return { error: "HEAD can't be read" };
  const headLine = headText.trim();
  if (HEAD_RE.test(headLine)) return { branch: DETACHED, head: headLine.toLowerCase() };
  const refMatch = headLine.match(/^ref: (.+)$/);
  if (!refMatch || !REF_RE.test(refMatch[1]) || refMatch[1].includes("..")) return { error: "HEAD holds no readable ref" };
  const ref = refMatch[1];
  const branch = ref.startsWith("refs/heads/") ? ref.slice("refs/heads/".length) : ref;

  const commonText = readCapped(join(gitDir, "commondir"), GIT_FILE_MAX_BYTES);
  const commonDir = commonText === null ? gitDir : resolve(gitDir, commonText.trim());

  for (const folder of [gitDir, commonDir]) {
    const value = readCapped(join(folder, ...ref.split("/")), GIT_FILE_MAX_BYTES)?.trim();
    if (value !== undefined) {
      return HEAD_RE.test(value) ? { branch, head: value.toLowerCase() } : { error: "the branch ref can't be read" };
    }
  }
  const packed = readCapped(join(commonDir, "packed-refs"), PACKED_REFS_MAX_BYTES);
  if (packed !== null) {
    for (const line of packed.split(/\r?\n/)) {
      if (line.startsWith("#") || line.startsWith("^")) continue;
      const space = line.indexOf(" ");
      if (space > 0 && line.slice(space + 1).trim() === ref) {
        const value = line.slice(0, space);
        return HEAD_RE.test(value) ? { branch, head: value.toLowerCase() } : { error: "the packed ref can't be read" };
      }
    }
  }
  return { error: "the branch has no commit" };
}

// Each hook process reads the record and the git state at most once per root.
const scopeCache = new Map();

/**
 * The scope record state for root: { status: "absent" }, { status: "ignored",
 * why }, or { status: "current", paths }.
 */
function loadScope(root) {
  if (scopeCache.has(root)) return scopeCache.get(root);
  const state = readScope(root);
  scopeCache.set(root, state);
  return state;
}

function readScope(root) {
  const file = join(root, ...FAST_PATH_SCOPE_FILE.split("/"));
  let stats;
  try {
    stats = statSync(file);
  } catch {
    return { status: "absent" };
  }
  if (!stats.isFile() || stats.size > SCOPE_MAX_BYTES) {
    return { status: "ignored", why: `it is not a file of at most ${SCOPE_MAX_BYTES} bytes` };
  }
  let text;
  try {
    text = readFileSync(file, "utf-8");
  } catch {
    return { status: "ignored", why: "it can't be read" };
  }
  const record = parseScopeRecord(text);
  if (record.error) return { status: "ignored", why: `it is invalid (${record.error})` };
  const git = readGitState(root);
  if (git.error) return { status: "ignored", why: `the git state can't be read (${git.error})` };
  if (record.branch !== git.branch) return { status: "ignored", why: "its branch differs from the current branch" };
  if (record.head.toLowerCase() !== git.head) return { status: "ignored", why: "its head differs from the current HEAD commit" };
  return { status: "current", paths: record.paths };
}

// scopeVerdict: the gate result for relPath when design.md is absent.
function scopeVerdict(root, relPath) {
  const scope = loadScope(root);
  if (scope.status === "absent") return { allowed: false, reason: NO_DESIGN_REASON };
  // The enforcement list runs before the record match (0000035 ADR-004).
  if (isEnforcementPath(relPath)) {
    return {
      allowed: false,
      reason:
        `[Planifest] Path '${relPath.slice(0, 200)}' is an enforcement path, so Fast Path never admits it, ` +
        `whatever ${FAST_PATH_SCOPE_FILE} lists (0000033 ADR 009). Use the Change or Feature Pipeline.\n`,
    };
  }
  if (scope.status === "ignored") {
    return {
      allowed: false,
      reason: NO_DESIGN_REASON + `[Planifest] The gate ignored ${FAST_PATH_SCOPE_FILE}: ${scope.why}.\n`,
    };
  }
  if (matchesComponentPath(relPath, scope.paths.map((p) => p.replace(/\/$/, "")))) {
    return {
      allowed: true,
      notice: `[Planifest] Fast Path: admitted '${relPath.slice(0, 200)}' through ${FAST_PATH_SCOPE_FILE}.\n`,
    };
  }
  return {
    allowed: false,
    reason:
      `[Planifest] Path '${relPath}' is not listed in the Fast Path scope record ${FAST_PATH_SCOPE_FILE}. ` +
      "Add it to the record, or take the Change Pipeline.\n",
  };
}

/**
 * Applies the gate checks, in order, to a root-relative path:
 *   0. the plan/current/** sentinel check, with the feature-brief.md and
 *      always-permitted basename exemptions (0000005-ADR-003)
 *   1. always-permitted prefixes and basenames
 *   2. design.md existence. With no design.md, a current Fast Path scope
 *      record admits a listed path and blocks the rest (0000035 ADR-002).
 *      A stale or invalid record admits nothing, and no record admits a
 *      path in FAST_PATH_ENFORCEMENT_PATHS (0000035 ADR-004).
 *   3. the component-path check, which warns and allows when design.md has no
 *      parseable paths section
 * Returns { allowed: true }, { allowed: true, warning }, { allowed: true,
 * notice } for a write the scope record admits, or { allowed: false, reason }.
 * Each string ends with a newline.
 */
export function evaluateWrite(root, relPath) {
  const normRel = norm(relPath || ".");
  const base = normRel.split("/").pop() ?? "";

  const isPlanCurrent = normRel.startsWith("plan/current/") || normRel === "plan/current";
  const isFeatureBrief = normRel.endsWith("feature-brief.md");
  const isAlwaysPermittedBasename = ALWAYS_PERMITTED_FILES.includes(base);
  if (isPlanCurrent && !isFeatureBrief && !isAlwaysPermittedBasename) {
    if (!existsSync(join(root, "plan", ".orchestrator-active"))) {
      return { allowed: false, reason: SENTINEL_REASON };
    }
  }

  if (isAlwaysPermitted(relPath)) return { allowed: true };

  const designPath = join(root, "plan", "current", "design.md");
  if (!existsSync(designPath)) return scopeVerdict(root, relPath);

  let designContent;
  try {
    designContent = readFileSync(designPath, "utf-8");
  } catch {
    return { allowed: true }; // can't read design.md, so fail open (0000003-ADR-005)
  }

  const componentPaths = extractComponentPaths(designContent);
  if (!componentPaths) return { allowed: true, warning: UNPARSEABLE_WARNING };

  if (!matchesComponentPath(relPath, componentPaths)) {
    return {
      allowed: false,
      reason:
        `[Planifest] Path '${relPath}' is not covered by the confirmed design. ` +
        "Add it to the '## Component Paths' section of plan/current/design.md first.\n",
    };
  }

  return { allowed: true };
}

/**
 * Judges a write to target from cwd. A target outside the repository root,
 * or a cwd that can't be used, returns { allowed: true, outside: true }. A
 * path too long to judge returns { allowed: true, warning } before any
 * file-system walk (F7). A target that can't be resolved inside the root
 * returns { allowed: false, reason } (0000035 ADR-005). Otherwise returns the
 * evaluateWrite result with the root and relPath added.
 */
export function judgeWrite(cwd, target) {
  const tooLongWarning = typeof cwd === "string" ? unjudgeable(cwd, target) : null;
  if (tooLongWarning) return { allowed: true, warning: tooLongWarning };
  const root = resolveRoot(cwd);
  if (!root) return { allowed: true, outside: true };
  const placed = resolveTarget(root, cwd, target);
  if (placed.status === "unresolvable") return { allowed: false, reason: placed.reason, root };
  if (placed.status === "outside") return { allowed: true, outside: true };
  const { relPath } = placed;
  return { ...evaluateWrite(root, relPath), root, relPath };
}
