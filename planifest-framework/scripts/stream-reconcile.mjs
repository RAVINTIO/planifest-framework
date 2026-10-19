#!/usr/bin/env node
/**
 * stream-reconcile.mjs - deterministic join reconciliation over
 * plan/current/streams/ (feature 0000033, req-017, ADR-014). A verifier, not
 * dispatch control: the orchestrator's skill text calls it after every join
 * and before the gate check. No hook runs it (0000006-ADR-003 still holds).
 *
 * Usage: node stream-reconcile.mjs [planCurrentDir]   (default: plan/current)
 *
 * Reads every *.md file under {planCurrentDir}/streams/: stream state files
 * (kind: stream) and join records (kind: join). For each row in a file's
 * "## Declares" table (artifact ID | defining file | consumer), it checks:
 *   1. The row names a consumer.
 *   2. The consumer differs from the producer. A stream can't consume its own
 *      artifact, and that includes a requirement the stream itself carries.
 *   3. A stream or join consumer lists the artifact ID in "## Consumes". A
 *      requirement consumer has {planCurrentDir}/requirements/{req-id}-*.md,
 *      and that file names the artifact ID.
 *   4. The artifact ID appears in at least one changed file of the consumer,
 *      other than its defining file. A stream's changed files come from
 *      `git log --name-only --format= --grep "Stream: {stream-id}"
 *      {start-commit}..HEAD`. A join record's are the paths in its "## Files
 *      changed" section that git also shows changed in
 *      `git log --name-only --format= {start-commit}..HEAD`, so a join record
 *      needs a valid start-commit too. A requirement consumer uses the unit
 *      whose `requirements` list holds it. Files under streams/ never count.
 *
 * Check 4 reads a changed file only when its realpath sits inside the repo
 * root, lstat shows a regular file (no symlink, FIFO, or device), and it is
 * 1 MB or smaller. If no readable file uses the artifact, the finding names
 * each skipped file and why. Every git call sets GIT_LITERAL_PATHSPECS=1,
 * and every output line has its control characters replaced.
 *
 * Exit codes: 0 = clean, 1 = findings (one line per artifact on stdout).
 * An absent streams/ directory exits 0 with no output.
 */

import { execFileSync } from "node:child_process";
import { closeSync, existsSync, lstatSync, openSync, readSync, readdirSync, realpathSync } from "node:fs";
import { basename, isAbsolute, join, relative, resolve, sep } from "node:path";

const dir = resolve(process.argv[2] ?? join(process.cwd(), "plan", "current"));
const streamsDir = join(dir, "streams");

if (!existsSync(streamsDir)) process.exit(0);

const MAX_READ = 1024 * 1024;
const GIT_ENV = { ...process.env, GIT_LITERAL_PATHSPECS: "1" };

// Reads a regular file of at most MAX_READ bytes. Returns { text } or { skip }.
function readSafe(p) {
  let st;
  try { st = lstatSync(p); } catch { return { text: null }; }
  if (!st.isFile()) return { skip: "not a regular file" };
  if (st.size > MAX_READ) return { skip: "over 1 MB" };
  const buf = Buffer.alloc(st.size);
  const fd = openSync(p, "r");
  try { readSync(fd, buf, 0, st.size, 0); } finally { closeSync(fd); }
  return { text: buf.toString("utf-8") };
}

const read = (p) => readSafe(p).text ?? null;

function section(text, heading) {
  // Returns the body of "## {heading}" up to the next "## " heading.
  const re = new RegExp(`^##\\s+${heading}\\s*$`, "im");
  const m = re.exec(text);
  if (!m) return "";
  const rest = text.slice(m.index + m[0].length);
  const next = rest.search(/^##\s+/m);
  return next === -1 ? rest : rest.slice(0, next);
}

function frontMatter(text) {
  const m = /^\uFEFF?---\r?\n([\s\S]*?)\r?\n---/.exec(text);
  const fm = {};
  if (!m) return fm;
  for (const line of m[1].split(/\r?\n/)) {
    const kv = /^([A-Za-z][\w-]*):\s*(.*)$/.exec(line);
    if (!kv) continue;
    let v = kv[2].trim().replace(/^["']|["']$/g, "");
    if (/^\[.*\]$/.test(v)) {
      v = v.slice(1, -1).split(",").map((s) => s.trim().replace(/^["']|["']$/g, "")).filter(Boolean);
    }
    fm[kv[1]] = v;
  }
  return fm;
}

const strip = (s) => s.trim().replace(/^`|`$/g, "").trim();
// Replaces control and non-ASCII characters before a value reaches output.
const clean = (s) => String(s).replace(/[^\x20-\x7e]/g, "?");
const isPlaceholder = (s) => s.includes("{{");

function tableRows(body) {
  // Data rows of a markdown table, skipping the header and separator rows.
  const rows = body.split(/\r?\n/).filter((l) => l.trim().startsWith("|"));
  return rows
    .slice(rows.length > 1 && /^\|[\s:|-]+\|?$/.test(rows[1].trim()) ? 2 : 0)
    .map((l) => l.trim().replace(/^\||\|$/g, "").split("|").map(strip))
    .filter((cells) => !cells.some(isPlaceholder));
}

function listItems(body) {
  // Bullet items, or the first cell of table rows, as plain IDs.
  const bullets = body.split(/\r?\n/)
    .map((l) => /^\s*[-*]\s+(.+)$/.exec(l))
    .filter(Boolean)
    .map((m) => strip(m[1]));
  const cells = tableRows(body).map((c) => c[0]);
  return [...bullets, ...cells].filter((s) => s && !isPlaceholder(s));
}

function gitRoot() {
  try {
    return execFileSync("git", ["rev-parse", "--show-toplevel"], { cwd: dir, encoding: "utf-8", env: GIT_ENV, stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch { return null; }
}

const root = gitRoot() ?? process.cwd();
const realRoot = realpathSync(root);
const toRepoPath = (p) => relative(root, isAbsolute(p) ? p : join(root, p)).split("\\").join("/");
const streamsRel = toRepoPath(streamsDir);

// ---- load units ------------------------------------------------------------
const units = [];
for (const f of readdirSync(streamsDir).filter((n) => n.endsWith(".md")).sort()) {
  const text = read(join(streamsDir, f)) ?? "";
  const fm = frontMatter(text);
  const kind = fm.kind === "join" ? "join" : "stream";
  const id = fm["stream-id"] || fm["join-id"] || basename(f, ".md");
  units.push({
    file: f,
    id,
    kind,
    startCommit: typeof fm["start-commit"] === "string" ? fm["start-commit"] : "",
    requirements: Array.isArray(fm.requirements) ? fm.requirements : fm.requirements ? [fm.requirements] : [],
    declares: tableRows(section(text, "Declares")),
    consumes: listItems(section(text, "Consumes")),
    filesChanged: listItems(section(text, "Files changed")),
  });
}
const byId = new Map(units.map((u) => [u.id, u]));

// ---- changed files per unit -------------------------------------------------
const changedCache = new Map();
function gitChanged(unit, grepArgs) {
  const out = execFileSync("git", ["log", "--name-only", "--format=", ...grepArgs,
    `${unit.startCommit}..HEAD`],
    { cwd: root, encoding: "utf-8", env: GIT_ENV, stdio: ["ignore", "pipe", "ignore"] });
  return [...new Set(out.split(/\r?\n/).map((s) => s.trim()).filter(Boolean))];
}

function changedFiles(unit) {
  if (changedCache.has(unit.id)) return changedCache.get(unit.id);
  let files = { list: [], error: null };
  if (!/^[0-9a-f]{7,40}$/i.test(unit.startCommit)) {
    files.error = `${unit.kind} ${unit.id} has no valid start-commit`;
  } else if (unit.kind === "join") {
    // A join's listed files count only where git shows them changed.
    try {
      const inGit = new Set(gitChanged(unit, []));
      files.list = unit.filesChanged.map(toRepoPath).filter((p) => inGit.has(p));
    } catch {
      files.error = `git log failed for join ${unit.id}`;
    }
  } else {
    const escaped = unit.id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    try {
      files.list = gitChanged(unit, ["-E", "--grep", `^Stream: ${escaped}$`]);
    } catch {
      files.error = `git log failed for stream ${unit.id}`;
    }
  }
  files.list = files.list.filter((p) => p !== streamsRel && !p.startsWith(`${streamsRel}/`));
  changedCache.set(unit.id, files);
  return files;
}

function requirementFile(reqId) {
  const reqDir = join(dir, "requirements");
  if (!existsSync(reqDir)) return null;
  const hit = readdirSync(reqDir).find((n) => n === `${reqId}.md` || n.startsWith(`${reqId}-`));
  return hit ? join(reqDir, hit) : null;
}

// Reads a repo-relative changed file only when its realpath sits inside the repo.
function readChanged(p) {
  let real;
  try { real = realpathSync(join(root, p)); } catch { return { text: null }; }
  if (real !== realRoot && !real.startsWith(realRoot + sep)) return { skip: "outside the repo" };
  return readSafe(join(root, p));
}

// ---- checks -----------------------------------------------------------------
const findings = [];
for (const producer of units) {
  for (const row of producer.declares) {
    const [artifact = "", definedIn = "", consumer = ""] = row;
    if (!artifact) continue;
    const reasons = [];
    let owner = null;

    // 1. a consumer is named
    if (!consumer || /^(-|none|n\/a)$/i.test(consumer)) {
      reasons.push("no consumer named");
    // 2. the consumer is not the producer
    } else if (consumer === producer.id || (producer.kind === "stream" && producer.requirements.includes(consumer))) {
      reasons.push(`self-consumer: ${producer.id} can't consume its own artifact`);
    } else if (byId.has(consumer)) {
      // 3. a stream or join consumer lists it in Consumes
      owner = byId.get(consumer);
      if (!owner.consumes.includes(artifact)) reasons.push(`${consumer} doesn't list it in ## Consumes`);
    } else if (/^req-\d+/i.test(consumer)) {
      // 3. a requirement consumer's file names it
      const reqFile = requirementFile(consumer);
      if (!reqFile) reasons.push(`no requirements/${consumer}-*.md file`);
      else if (!(read(reqFile) ?? "").includes(artifact)) reasons.push(`requirements file for ${consumer} doesn't name it`);
      owner = units.find((u) => u.requirements.includes(consumer))
        ?? (producer.kind === "join" ? producer : null);
      if (!owner) reasons.push(`no stream or join record carries ${consumer}`);
    } else {
      reasons.push(`unknown consumer ${consumer}`);
    }

    // 4. the consumer's changed files use it
    if (owner) {
      const { list, error } = changedFiles(owner);
      const defining = definedIn ? toRepoPath(definedIn) : null;
      const skipped = [];
      const used = list
        .filter((p) => p !== defining)
        .some((p) => {
          const r = readChanged(p);
          if (r.skip) skipped.push(`skipped ${p}: ${r.skip}`);
          return (r.text ?? "").includes(artifact);
        });
      if (error) reasons.push(error);
      else if (!used) reasons.push(`no changed file of ${owner.id} uses it`, ...skipped);
    }

    if (reasons.length) findings.push(`${producer.file}: ${artifact}: ${reasons.join(", ")}`);
  }
}

if (findings.length) {
  for (const f of findings) console.log(clean(f));
  process.exit(1);
}
process.exit(0);
