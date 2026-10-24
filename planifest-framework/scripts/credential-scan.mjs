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
// Exit codes: 0 clean, 1 at least one match, 2 the scan could not run.
// The script never prints matched text. Node built-ins only (0000037 ADR-001).

import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, join } from 'node:path';

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
  // Split so that this file does not match its own rule.
  ['private-key-block', new RegExp('-----BEGIN .*PRIVATE KEY' + '-----')],
  ['github-token', /ghp_[A-Za-z0-9]{36}/],
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
    return execFileSync('git', args, { encoding: 'buffer', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch (err) {
    throw new ScanError(`git ${args[0]} failed`, { cause: err });
  }
}

function gitleaksAvailable() {
  const probe = spawnSync('gitleaks', ['version'], { stdio: 'ignore' });
  return !probe.error;
}

// Content hits: [{line, rule}] for a Buffer. Binary content is skipped.
function contentHits(buf) {
  if (buf.includes(0)) return [];
  const hits = [];
  buf
    .toString('utf8')
    .split('\n')
    .forEach((text, i) => {
      for (const [rule, re] of CONTENT_RULES) {
        if (re.test(text)) hits.push({ line: i + 1, rule });
      }
    });
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
  const out = { file: null, extra: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--file') {
      out.file = argv[++i];
      if (!out.file) throw new ScanError('--file needs a path');
    } else if (a === '--') {
      out.extra = argv.slice(i + 1);
      break;
    } else {
      throw new ScanError(`unknown argument ${safePath(a)}`);
    }
  }
  return out;
}

// collectSources(): [{path, buf}] for each index blob and working-tree file.
function collectSources(args) {
  if (args.file) {
    if (!existsSync(args.file)) throw new ScanError(`file not found: ${safePath(args.file)}`);
    return [{ path: args.file, buf: readFileSync(args.file) }];
  }
  const staged = git(['diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z'])
    .toString('utf8')
    .split('\0')
    .filter(Boolean);
  const paths = [...new Set([...staged, ...args.extra])];
  const sources = [];
  for (const p of paths) {
    let indexBuf = null;
    try {
      indexBuf = execFileSync('git', ['show', `:${p}`], { stdio: ['ignore', 'pipe', 'ignore'] });
    } catch {
      indexBuf = null; // not in the index
    }
    if (indexBuf) sources.push({ path: p, buf: indexBuf });
    if (existsSync(p)) sources.push({ path: p, buf: readFileSync(p) });
  }
  return sources;
}

function main() {
  let args;
  let sources;
  let useGitleaks;
  try {
    args = parseArgs(process.argv.slice(2));
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
        if (test(basename(path))) add(path, 1, rule);
      }
      for (const h of contentHits(buf)) add(path, h.line, h.rule);
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
