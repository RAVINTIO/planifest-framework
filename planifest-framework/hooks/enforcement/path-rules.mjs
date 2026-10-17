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
 *   - The repository root is CLAUDE_PROJECT_DIR when it names a folder.
 *     Otherwise it is the outermost folder at or above cwd that holds
 *     planifest-framework/, then the nearest folder that holds .git, then cwd.
 *     A marker inside plan/ or docs/ of a higher marked folder never counts,
 *     because those prefixes are always permitted and anyone can plant one.
 *   - Both sides of the root comparison are real paths, with symbolic links
 *     resolved. A missing target resolves through its nearest existing parent.
 *   - plan/.orchestrator-active and plan/current/design.md are looked up from
 *     the root, not from cwd.
 *   - Comparisons use the 0000009-ADR-005 normalisation: forward slashes and
 *     lower case.
 *
 * Exports:
 *   resolveRoot(cwd)                 real repository root, or null if cwd is unusable
 *   toRootRelative(root, cwd, target) root-relative path, or null when outside the root
 *   evaluateWrite(root, relPath)     { allowed, reason?, warning? } for a root-relative path
 *   judgeWrite(cwd, target)          resolveRoot, toRootRelative, and evaluateWrite in one call
 *   norm(p)                          the shared comparison normalisation
 */

import { existsSync, readFileSync, realpathSync, statSync } from "node:fs";
import { dirname, isAbsolute, join, normalize, relative, resolve } from "node:path";

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

// realPathOf: the real path of p, or of its nearest existing parent with the
// missing segments appended. p must be absolute.
function realPathOf(p) {
  const missing = [];
  let current = p;
  while (!existsSync(current)) {
    const parent = dirname(current);
    if (parent === current) return p;
    missing.unshift(relative(parent, current));
    current = parent;
  }
  return join(realpathSync(current), ...missing);
}

/**
 * The repository root for cwd, as a real path (ADR-004, security finding F1).
 *   1. CLAUDE_PROJECT_DIR, when it is set and names a folder.
 *   2. The outermost folder at or above cwd that holds planifest-framework/.
 *   3. The nearest folder at or above cwd that holds .git (a .git file counts,
 *      for worktrees).
 *   4. The real path of cwd.
 * A folder that sits inside plan/ or docs/ of a higher marked folder is never
 * a root. Those prefixes are always permitted, so a marker planted there must
 * not move the root. Returns null, and never throws, when cwd is missing or
 * unreadable.
 */
export function resolveRoot(cwd) {
  try {
    if (typeof cwd !== "string" || !cwd || !isDirectory(cwd)) return null;
    const projectDir = process.env.CLAUDE_PROJECT_DIR;
    if (projectDir && isDirectory(projectDir)) return realpathSync(projectDir);

    const start = realpathSync(cwd);
    // Every marked folder from cwd up to the file-system root, nearest first.
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
        const first = norm(rel).split("/")[0];
        return ALWAYS_PERMITTED_PREFIXES.some((prefix) => prefix === first + "/");
      });
    const trusted = marked.filter((m) => !planted(m));

    const frameworks = trusted.filter((m) => m.framework);
    if (frameworks.length) return frameworks[frameworks.length - 1].dir;
    const git = trusted.find((m) => m.git);
    if (git) return git.dir;
    return start;
  } catch {
    return null;
  }
}

/**
 * The target's path relative to root, with forward slashes and its original
 * case. Returns null when the target is outside root or can't be resolved.
 * Relative targets resolve against the real path of cwd. The comparison
 * resolves .. segments first and matches whole path segments.
 */
export function toRootRelative(root, cwd, target) {
  try {
    if (typeof target !== "string" || !target) return null;
    const base = realPathOf(resolve(cwd));
    const abs = realPathOf(isAbsolute(target) ? resolve(target) : resolve(base, target));
    const absSlashed = abs.replace(/\\/g, "/");
    const normRoot = norm(root).replace(/\/$/, "");
    const normAbs = norm(abs);
    if (normAbs === normRoot) return "";
    const rootPrefix = normRoot + "/";
    if (!normAbs.startsWith(rootPrefix)) return null;
    return absSlashed.slice(rootPrefix.length);
  } catch {
    return null;
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
 * or a cwd that can't be used, returns { allowed: true, outside: true }.
 * Otherwise returns the evaluateWrite result with the root and relPath added.
 */
export function judgeWrite(cwd, target) {
  const root = resolveRoot(cwd);
  if (!root) return { allowed: true, outside: true };
  const relPath = toRootRelative(root, cwd, target);
  if (relPath === null) return { allowed: true, outside: true };
  return { ...evaluateWrite(root, relPath), root, relPath };
}
