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
 *   - Both sides of the root comparison are real paths, with symbolic links
 *     resolved. A missing target resolves through its nearest existing parent.
 *   - plan/.orchestrator-active and plan/current/design.md are looked up from
 *     the root, not from cwd.
 *   - Comparisons use the 0000009-ADR-005 normalisation: forward slashes and
 *     lower case.
 *
 * Exports:
 *   resolveRoot(cwd)                 real repository root, or null if cwd is unusable
 *   resolveTarget(root, cwd, target)  { kind: inside | outside | unresolvable } for a target
 *   toRootRelative(root, cwd, target) root-relative path, or null when outside the root
 *   hookCwd(input)                   the folder a hook judges from, or null
 *   evaluateWrite(root, relPath)     { allowed, reason?, warning? } for a root-relative path
 *   judgeWrite(cwd, target)          resolveRoot, toRootRelative, and evaluateWrite in one call
 *   unjudgeable(base, target)        a warning when the path is too long to judge, or null
 *   norm(p)                          the shared comparison normalisation
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

/**
 * Applies the gate checks, in order, to a root-relative path:
 *   0. the plan/current/** sentinel check, with the feature-brief.md and
 *      always-permitted basename exemptions (0000005-ADR-003)
 *   1. always-permitted prefixes and basenames
 *   2. design.md existence
 *   3. the component-path check, which warns and allows when design.md has no
 *      parseable paths section
 * Returns { allowed: true }, { allowed: true, warning }, or
 * { allowed: false, reason }. Each string ends with a newline.
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
  if (!existsSync(designPath)) return { allowed: false, reason: NO_DESIGN_REASON };

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
