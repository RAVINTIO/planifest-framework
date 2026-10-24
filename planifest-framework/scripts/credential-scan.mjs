#!/usr/bin/env node
// credential-scan.mjs - scans files for credentials and reports path and line.
//
// Usage:
//   node credential-scan.mjs [-- {path} ...]   staged mode
//   node credential-scan.mjs --file {path}     file mode (PR text)
//
// Staged mode scans, for every path in the commit, the index blob and the
// working-tree file. Paths come from `git diff --cached --name-only` plus any
// path named after `--`. The script detects and reports. It never stops a commit.
//
//   node credential-scan.mjs --safe-paths {out-file} -- {path} ...   safe-paths mode
//
// Safe-paths mode scans each listed path, in its index blob and its working-tree
// file, with the staged-mode rules. It writes to {out-file} only the paths with
// no hit, NUL-separated, as the caller gave them, with no escaping. A commit then
// names that file with `--pathspec-from-file={out-file} --pathspec-file-nul`.
// It prints the `{path}:{line} {rule}` lines of held-back paths. A path that is
// absent from the working tree is a deletion and is safe. Paths and the out-file
// resolve from the starting directory.
//
// Exit codes: 0 clean, 1 at least one match, 2 the scan could not run.
// Safe-paths mode keeps these codes. At exit 1 the out-file still holds the safe
// paths. At exit 2 the out-file is empty or absent.
// The script never prints matched text. Node built-ins only (0000037 ADR-001).

import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, join, relative, resolve, sep } from 'node:path';

const MAX_PATH_LENGTH = 200;

// P8 credential guard rules (0000033 P5). One list for every caller.
const NAME_RULES = [
  ['refused-file-name:.env', (n) => n.startsWith('.env')],
  ['refused-file-name:pem', (n) => n.endsWith('.pem')],
  ['refused-file-name:key', (n) => n.endsWith('.key')],
  ['refused-file-name:id_rsa', (n) => n.startsWith('id_rsa')],
  ['refused-file-name:p12', (n) => n.endsWith('.p12')],
  ['refused-file-name:.npmrc', (n) => n === '.npmrc'],
  ['refused-file-name:credentials.json', (n) => n === 'credentials.json'],
  ['refused-file-name:keystore', (n) => n.endsWith('.keystore')],
  ['refused-file-name:.netrc', (n) => n === '.netrc'],
];

const CONTENT_RULES = [
  ['aws-access-key', /AKIA[0-9A-Z]{16}/],
  // The character class means the pattern text in this file does not match its own rule.
  ['aws-temporary-key', /ASIA[0-9A-Z]{16}/],
  // A bounded class keeps the match linear on one long line.
  ['private-key-block', new RegExp('-----BEGIN [A-Z ]{0,40}PRIVATE KEY')],
  ['github-token', /gh[pousr]_[A-Za-z0-9]{36}/],
  ['slack-token', /xox[baprs]-/],
  ['github-pat', /github_pat_[A-Za-z0-9_]{20,}/],
  ['api-secret-key', /sk-[A-Za-z0-9_-]{20,}/],
  ['google-api-key', /AIza[0-9A-Za-z_-]{35}/],
];

class ScanError extends Error {}

function safePath(p) {
  return p.replace(/[^A-Za-z0-9\-_./ ]/g, '?').slice(0, MAX_PATH_LENGTH);
}

function fail(reason) {
  console.log(`scan could not run: ${reason}`);
  process.exit(2);
}

function git(args) {
  try {
    return execFileSync('git', args, {
      encoding: 'buffer',
      stdio: ['ignore', 'pipe', 'pipe'],
      maxBuffer: Infinity,
    });
  } catch (err) {
    throw new ScanError(`git ${args[0]} failed`, { cause: err });
  }
}

function gitleaksAvailable() {
  const probe = spawnSync('gitleaks', ['version'], { stdio: 'ignore' });
  return !probe.error;
}

// Texts to scan for one Buffer. Nothing is skipped. NUL bytes are removed, which
// also turns ASCII UTF-16 without a BOM into plain text. A UTF-16 BOM adds a
// properly decoded copy when the body has an even length. An odd-length BOM file
// is binary, so only the NUL-stripped text is scanned. Exit 2 stays for read errors.
function textsFor(buf) {
  const texts = [Buffer.from(buf.filter((b) => b !== 0)).toString('utf8')];
  const le = buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xfe;
  const be = buf.length >= 2 && buf[0] === 0xfe && buf[1] === 0xff;
  if (le || be) {
    const body = buf.subarray(2);
    if (body.length % 2 === 0) {
      texts.push((be ? Buffer.from(body).swap16() : body).toString('utf16le'));
    }
  }
  return texts;
}

// Content hits: [{line, rule}] for a Buffer.
function contentHits(buf, name) {
  const hits = [];
  for (const whole of textsFor(buf)) {
    whole.split('\n').forEach((text, i) => {
      for (const [rule, re] of CONTENT_RULES) {
        if (re.test(text)) hits.push({ line: i + 1, rule });
      }
    });
  }
  return hits;
}

// gitleaks over one buffer. Returns [{line, rule}]. Exit 1 is a finding.
function gitleaksHits(buf, name) {
  const dir = mkdtempSync(join(tmpdir(), 'cred-scan-'));
  try {
    const target = join(dir, 'target');
    const report = join(dir, 'report.json');
    writeFileSync(target, buf);
    const run = spawnSync(
      'gitleaks',
      ['detect', '--no-git', '--source', target, '--no-banner', '--redact',
        '--report-format', 'json', '--report-path', report],
      { stdio: 'ignore' },
    );
    if (run.error) throw new ScanError(`gitleaks did not run for ${safePath(name)}`);
    if (run.status === 0) return [];
    if (run.status !== 1) throw new ScanError(`gitleaks exited ${run.status} for ${safePath(name)}`);
    let line = 1;
    try {
      const found = JSON.parse(readFileSync(report, 'utf8'));
      if (Array.isArray(found) && found[0] && Number.isInteger(found[0].StartLine)) {
        line = found[0].StartLine;
      }
    } catch {
      // The finding stands without a line number. Report line 1.
    }
    return [{ line, rule: 'gitleaks' }];
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const out = { file: null, extra: [], safeOut: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--file') {
      out.file = argv[++i];
      if (!out.file) throw new ScanError('--file needs a path');
    } else if (a === '--safe-paths') {
      out.safeOut = argv[++i];
      if (!out.safeOut || out.safeOut === '--') throw new ScanError('--safe-paths needs an out-file');
    } else if (a === '--') {
      out.extra = argv.slice(i + 1);
      break;
    } else {
      throw new ScanError(`unknown argument ${safePath(a)}`);
    }
  }
  if (out.safeOut && out.file) throw new ScanError('--safe-paths and --file cannot be combined');
  return out;
}

// Hits for one source: [{line, rule}]. One list of rules for every mode.
function hitsFor({ path, buf }, useGitleaks) {
  const found = [];
  for (const [rule, test] of NAME_RULES) {
    if (test(basename(path).toLowerCase())) found.push({ line: 1, rule });
  }
  found.push(...contentHits(buf, path));
  if (useGitleaks) found.push(...gitleaksHits(buf, path));
  return found;
}

// Safe-paths mode. The out-file is emptied first, so an error never leaves stale
// content. It is written again at the end with the safe paths only.
function runSafePaths(args) {
  const start = process.cwd();
  const outFile = resolve(start, args.safeOut);
  try {
    writeFileSync(outFile, '');
  } catch {
    throw new ScanError(`could not write the out-file ${safePath(args.safeOut)}`);
  }
  const top = git(['rev-parse', '--show-toplevel']).toString('utf8').trim();
  const useGitleaks = gitleaksAvailable();
  console.log(useGitleaks ? 'scan mode: regex and gitleaks' : 'scan mode: regex only (gitleaks not found)');
  const indexed = new Set(
    git(['-C', top, 'ls-files', '--cached', '-z']).toString('utf8').split('\0').filter(Boolean),
  );
  const safe = [];
  const report = [];
  const seen = new Set();
  for (const given of args.extra) {
    const abs = resolve(start, given);
    const rel = relative(top, abs).split(sep).join('/');
    const sources = [];
    // An absent working-tree file is a deletion. The commit then holds no content.
    if (existsSync(abs)) {
      let buf;
      try {
        if (statSync(abs).isDirectory()) throw new Error('directory');
        buf = readFileSync(abs);
      } catch {
        throw new ScanError(`could not read ${safePath(given)}`);
      }
      sources.push({ path: rel, buf });
      // `:./` reads the blob by literal path, so a name that starts with `:` works.
      if (indexed.has(rel)) sources.push({ path: rel, buf: git(['-C', top, 'show', `:./${rel}`]) });
    }
    let held = false;
    for (const src of sources) {
      for (const h of hitsFor(src, useGitleaks)) {
        held = true;
        const key = `${given}:${h.line}:${h.rule}`;
        if (seen.has(key)) continue;
        seen.add(key);
        report.push(`${safePath(given)}:${h.line} ${h.rule}`);
      }
    }
    if (!held) safe.push(given);
  }
  try {
    writeFileSync(outFile, safe.map((p) => `${p}\0`).join(''));
  } catch {
    throw new ScanError(`could not write the out-file ${safePath(args.safeOut)}`);
  }
  for (const line of report) console.log(line);
  process.exit(report.length > 0 ? 1 : 0);
}

// collectSources(): [{path, buf}] for each index blob and working-tree file.
function collectSources(args) {
  if (args.file) {
    if (!existsSync(args.file)) throw new ScanError(`file not found: ${safePath(args.file)}`);
    try {
      return [{ path: args.file, buf: readFileSync(args.file) }];
    } catch {
      throw new ScanError(`could not read ${safePath(args.file)}`);
    }
  }
  // Git prints root-relative paths. Resolve the paths after `--` against the
  // starting directory, then work from the repository root so every read agrees.
  const start = process.cwd();
  const top = git(['rev-parse', '--show-toplevel']).toString('utf8').trim();
  const extras = args.extra.map((p) => relative(top, resolve(start, p)).split(sep).join('/'));
  process.chdir(top);
  const staged = git(['diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z'])
    .toString('utf8')
    .split('\0')
    .filter(Boolean);
  const indexed = new Set(
    git(['ls-files', '--cached', '-z']).toString('utf8').split('\0').filter(Boolean),
  );
  const paths = [...new Set([...staged, ...extras])];
  const sources = [];
  for (const p of paths) {
    // A path outside the index is skipped. Any other read error stops the scan.
    if (indexed.has(p)) sources.push({ path: p, buf: git(['show', `:./${p}`]) });
    if (existsSync(p)) {
      try {
        sources.push({ path: p, buf: readFileSync(p) });
      } catch {
        throw new ScanError(`could not read ${safePath(p)}`);
      }
    }
  }
  return sources;
}

function main() {
  let args;
  let sources;
  let useGitleaks;
  try {
    args = parseArgs(process.argv.slice(2));
    if (args.safeOut) runSafePaths(args);
    sources = collectSources(args);
    useGitleaks = gitleaksAvailable();
  } catch (err) {
    fail(err instanceof ScanError ? err.message : 'unexpected error');
  }

  console.log(useGitleaks ? 'scan mode: regex and gitleaks' : 'scan mode: regex only (gitleaks not found)');

  const seen = new Set();
  const report = [];
  const add = (path, line, rule) => {
    const key = `${path}:${line}:${rule}`;
    if (seen.has(key)) return;
    seen.add(key);
    report.push(`${safePath(path)}:${line} ${rule}`);
  };

  try {
    for (const { path, buf } of sources) {
      for (const [rule, test] of NAME_RULES) {
        if (test(basename(path).toLowerCase())) add(path, 1, rule);
      }
      for (const h of contentHits(buf, path)) add(path, h.line, h.rule);
      if (useGitleaks) {
        for (const h of gitleaksHits(buf, path)) add(path, h.line, h.rule);
      }
    }
  } catch (err) {
    for (const line of report) console.log(line);
    fail(err instanceof ScanError ? err.message : 'unexpected error');
  }

  for (const line of report) console.log(line);
  process.exit(report.length > 0 ? 1 : 0);
}

main();
