#!/usr/bin/env node
/**
 * PreToolUse hook for the Claude Code Bash tool: shell-write guard (req-008,
 * ADR-006).
 *
 * gate-write.mjs only sees Write and Edit. This hook reads a Bash command,
 * finds the common shell writers in it, and judges each write target with the
 * shared rules in path-rules.mjs (ADR-004). It blocks exactly when
 * gate-write.mjs would block a Write to the same path (req-009).
 *
 * Writers it finds:
 *   - redirects: >, >>, >|, &>, &>>, and the descriptor forms such as 2>
 *   - tee and tee -a
 *   - sed -i and perl -i, in their suffix and long forms
 *   - the destination of cp, mv, install, and ln, or the -t value
 *   - every argument of rm, touch, and mkdir
 *
 * How it reads a command:
 *   - It splits at ;, &&, ||, |, &, parentheses, and line breaks, and respects
 *     quotes and backslash escapes.
 *   - It skips leading VAR=value assignments and here-document bodies.
 *   - A cd with one literal argument moves a tracked base folder for the
 *     simple commands after it. A relative target is judged against both the
 *     starting folder and the tracked base, and blocks if either blocks. The
 *     tracked base returns to its outer value at ), and a cd doesn't carry
 *     across |, ||, or &.
 *   - A target holding $, a backtick, *, ?, or { is judged by its literal
 *     prefix, so src/*.js is judged as src/.
 *
 * Documented limits. The boot-file Hard Limit (req-012) covers each one:
 *   - It ignores commands named git, so git checkout, git restore, git apply,
 *     and similar writes pass.
 *   - It can't see writes made inside a script, an interpreter one-liner such
 *     as node -e or python -c, a build tool, or a package manager.
 *   - A target with no literal prefix, such as $TARGET, passes with a one-line
 *     warning on stderr.
 *   - A command it can't parse, such as one with an unbalanced quote, passes
 *     with a one-line warning on stderr.
 *   - It doesn't look inside $(...) or backtick substitutions.
 *
 * Receives: the Claude Code PreToolUse JSON on stdin. The command is
 * tool_input.command and the working folder is cwd.
 *
 * Exit codes: 0 = pass, 2 = block. A block reason goes to stderr only, and
 * stdout stays empty (ADR-005). Unexpected errors exit 0 (0000003-ADR-005).
 * Node built-in modules only, and no process spawn.
 */

import { homedir } from "node:os";
import { basename, isAbsolute, resolve } from "node:path";
import { evaluateWrite, resolveRoot, toRootRelative } from "./path-rules.mjs";
import { readStdin } from "./read-stdin.mjs";

const PREFIX = "[Planifest]";

class ParseError extends Error {}

// ---------------------------------------------------------------------------
// Tokeniser
// ---------------------------------------------------------------------------

const SEPARATORS = ["&&", "||", "|&", ";;", ";", "&", "|", "(", ")"];
const REDIRECTS = ["&>>", "&>", "<<<", "<<-", "<<", "<>", "<&", ">>", ">|", ">&", ">", "<"];

// skipSingle: index of the closing single quote for the one at i.
function skipSingle(s, i) {
  const end = s.indexOf("'", i + 1);
  if (end < 0) throw new ParseError("unbalanced single quote");
  return end;
}

// skipDouble: index of the closing double quote for the one at i.
function skipDouble(s, i) {
  for (let j = i + 1; j < s.length; j++) {
    const c = s[j];
    if (c === "\\") j++;
    else if (c === '"') return j;
    else if (c === "`") j = skipBacktick(s, j);
    else if (c === "$" && (s[j + 1] === "(" || s[j + 1] === "{")) j = skipGroup(s, j + 1) - 1;
  }
  throw new ParseError("unbalanced double quote");
}

// skipBacktick: index of the closing backtick for the one at i.
function skipBacktick(s, i) {
  for (let j = i + 1; j < s.length; j++) {
    if (s[j] === "\\") j++;
    else if (s[j] === "`") return j;
  }
  throw new ParseError("unbalanced backtick");
}

// skipHeredocBodies: the index after the here-document bodies that start at
// start. Each entry of heredocs is { delim, strip }, and the list empties.
function skipHeredocBodies(s, start, heredocs) {
  let i = start;
  while (heredocs.length) {
    const { delim, strip } = heredocs.shift();
    for (;;) {
      if (i >= s.length) return s.length;
      let nl = s.indexOf("\n", i);
      if (nl < 0) nl = s.length;
      let line = s.slice(i, nl);
      if (strip) line = line.replace(/^\t+/, "");
      i = nl + 1;
      if (line === delim) break;
    }
  }
  return i;
}

// readDelimiter: the here-document delimiter word that starts at or after k,
// with quotes removed. Returns { delim, end } where end is the index after it.
function readDelimiter(s, k) {
  while (s[k] === " " || s[k] === "\t") k++;
  let delim = "";
  while (k < s.length && !/[\s;&|()<>]/.test(s[k])) {
    const c = s[k];
    if (c === "'" || c === '"') {
      const end = s.indexOf(c, k + 1);
      if (end < 0) throw new ParseError("unbalanced quote in a here-document delimiter");
      delim += s.slice(k + 1, end);
      k = end + 1;
    } else if (c === "\\") {
      delim += s[k + 1] ?? "";
      k += 2;
    } else {
      delim += c;
      k++;
    }
  }
  return { delim, end: k };
}

// skipGroup: index after the bracket that closes the ( or { at i. It skips
// here-document bodies inside the group, so an apostrophe in a commit message
// body isn't read as an open quote.
function skipGroup(s, i) {
  const open = s[i];
  const close = open === "(" ? ")" : "}";
  const heredocs = [];
  let depth = 0;
  for (let j = i; j < s.length; j++) {
    const c = s[j];
    if (c === "\\") j++;
    else if (c === "'") j = skipSingle(s, j);
    else if (c === '"') j = skipDouble(s, j);
    else if (c === "`") j = skipBacktick(s, j);
    else if (s.startsWith("<<<", j)) j += 2; // a here-string, not a here-document
    else if (c === "<" && s[j + 1] === "<") {
      const strip = s[j + 2] === "-";
      const { delim, end } = readDelimiter(s, j + (strip ? 3 : 2));
      heredocs.push({ delim, strip });
      j = end - 1;
    } else if (c === "\n" && heredocs.length) j = skipHeredocBodies(s, j + 1, heredocs) - 1;
    else if (c === open) depth++;
    else if (c === close && --depth === 0) return j + 1;
  }
  throw new ParseError("unbalanced substitution");
}

/**
 * Splits a command line into simple commands and the separators between them.
 * Returns a list of items:
 *   { t: "cmd", tokens }       a simple command
 *   { t: "sep", op }           a separator such as ;, &&, |, (, ), or a line break
 * Each simple command is a list of tokens:
 *   { t: "w", v, dyn, tilde }  a word with quotes removed. dyn is the index in
 *                              v of the first $, backtick, *, ?, or {, or -1.
 *   { t: "r", op, fd }         a redirect operator.
 * Throws ParseError on unbalanced quotes.
 */
function tokenise(s) {
  const items = [];
  let tokens = [];
  let word = null;
  const heredocs = [];
  let expectDelimiter = null;

  const mark = () => {
    if (word.dyn < 0) word.dyn = word.v.length;
  };
  const endWord = () => {
    if (!word) return;
    if (expectDelimiter) {
      heredocs.push({ delim: word.v, strip: expectDelimiter === "<<-" });
      expectDelimiter = null;
    }
    tokens.push(word);
    word = null;
  };
  const endCommand = () => {
    endWord();
    if (tokens.length) items.push({ t: "cmd", tokens });
    tokens = [];
  };
  let i = 0;
  while (i < s.length) {
    const c = s[i];

    if (c === "\\" && s[i + 1] === "\n") { i += 2; continue; }
    if (c === " " || c === "\t" || c === "\r") { endWord(); i++; continue; }
    if (c === "\n") {
      endCommand();
      items.push({ t: "sep", op: "\n" });
      i = skipHeredocBodies(s, i + 1, heredocs);
      continue;
    }
    if (c === "#" && !word) {
      const nl = s.indexOf("\n", i);
      i = nl < 0 ? s.length : nl;
      continue;
    }

    const redirect = REDIRECTS.find((op) => s.startsWith(op, i));
    if (redirect && !(redirect.startsWith("&") && s.startsWith("&&", i))) {
      let fd = "";
      if (word && /^\d+$/.test(word.v) && word.quoted === false) {
        fd = word.v;
        word = null;
      }
      endWord();
      tokens.push({ t: "r", op: redirect, fd });
      if (redirect === "<<" || redirect === "<<-") expectDelimiter = redirect;
      i += redirect.length;
      continue;
    }

    const separator = SEPARATORS.find((op) => s.startsWith(op, i));
    if (separator) {
      endCommand();
      items.push({ t: "sep", op: separator });
      i += separator.length;
      continue;
    }

    if (!word) word = { t: "w", v: "", dyn: -1, tilde: c === "~", quoted: false };

    if (c === "\\") {
      word.v += s[i + 1] ?? "";
      word.quoted = true;
      i += 2;
    } else if (c === "'") {
      const end = skipSingle(s, i);
      word.v += s.slice(i + 1, end);
      word.quoted = true;
      i = end + 1;
    } else if (c === '"') {
      const end = skipDouble(s, i);
      const inner = s.slice(i + 1, end);
      const dollar = inner.search(/[$`]/);
      if (dollar >= 0 && word.dyn < 0) word.dyn = word.v.length + dollar;
      word.v += inner.replace(/\\(["\\$`])/g, "$1");
      word.quoted = true;
      i = end + 1;
    } else if (c === "`") {
      mark();
      const end = skipBacktick(s, i);
      word.v += s.slice(i, end + 1);
      i = end + 1;
    } else if (c === "$" && (s[i + 1] === "(" || s[i + 1] === "{")) {
      mark();
      const end = skipGroup(s, i + 1);
      word.v += s.slice(i, end);
      i = end;
    } else {
      if (c === "$" || c === "*" || c === "?" || c === "{") mark();
      word.v += c;
      i++;
    }
  }
  endCommand();
  return items;
}

// ---------------------------------------------------------------------------
// Writer detection
// ---------------------------------------------------------------------------

const WRITE_REDIRECTS = new Set([">", ">>", ">|", "&>", "&>>", "<>", ">&"]);
const RESERVED = new Set(["if", "then", "else", "elif", "do", "while", "until", "!", "{", "}", "time"]);
const ASSIGNMENT_RE = /^[A-Za-z_][A-Za-z0-9_]*\+?=/;

const isOption = (w) => w.v.length > 1 && w.v.startsWith("-");

// operands: the words that aren't options, honouring -- and options that take
// a value. takesValue(name) says whether an option consumes the next word.
// Returns { operands, values } where values maps option names to their value.
function operands(args, takesValue = () => false) {
  const out = [];
  const values = {};
  let optionsDone = false;
  for (let k = 0; k < args.length; k++) {
    const w = args[k];
    if (optionsDone || !isOption(w)) { out.push(w); continue; }
    if (w.v === "--") { optionsDone = true; continue; }
    const eq = w.v.indexOf("=");
    if (w.v.startsWith("--") && eq > 0) { values[w.v.slice(0, eq)] = { ...w, v: w.v.slice(eq + 1), dyn: w.dyn - eq - 1 }; continue; }
    if (w.v.startsWith("--")) {
      if (takesValue(w.v) && k + 1 < args.length) values[w.v] = args[++k];
      continue;
    }
    // A short-option cluster, read one letter at a time (F4). The first letter
    // that takes a value takes the rest of the cluster, such as -tsrc/ or
    // -vtsrc/, or the next word when the cluster ends there, such as -vt src/.
    for (let p = 1; p < w.v.length; p++) {
      const name = `-${w.v[p]}`;
      if (!takesValue(name)) continue;
      if (p + 1 < w.v.length) {
        values[name] = { ...w, v: w.v.slice(p + 1), dyn: w.dyn < 0 ? -1 : Math.max(0, w.dyn - p - 1) };
      } else if (k + 1 < args.length) {
        values[name] = args[++k];
      }
      break;
    }
  }
  return { operands: out, values };
}

const valueOptions = (...names) => (name) => names.includes(name);

// destination: the -t or --target-directory value, or the last operand.
function destination(args, takesValue, minOperands) {
  const { operands: ops, values } = operands(args, takesValue);
  const target = values["-t"] ?? values["--target-directory"];
  if (target) return [target];
  return ops.length >= minOperands ? [ops[ops.length - 1]] : [];
}

function sedTargets(args) {
  let inPlace = false;
  let scriptGiven = false;
  const files = [];
  let optionsDone = false;
  for (let k = 0; k < args.length; k++) {
    const w = args[k];
    if (optionsDone || !isOption(w)) { files.push(w); continue; }
    if (w.v === "--") { optionsDone = true; continue; }
    if (w.v.startsWith("--in-place")) { inPlace = true; continue; }
    if (w.v === "--expression" || w.v === "--file") { scriptGiven = true; k++; continue; }
    if (w.v.startsWith("--expression=") || w.v.startsWith("--file=")) { scriptGiven = true; continue; }
    if (w.v.startsWith("--")) continue;
    const flags = w.v.slice(1);
    for (let f = 0; f < flags.length; f++) {
      const flag = flags[f];
      if (flag === "i") {
        inPlace = true;
        // BSD sed takes the suffix as its own word: sed -i '' or sed -Ei .bak.
        if (f === flags.length - 1 && k + 1 < args.length && (args[k + 1].v === "" || args[k + 1].v.startsWith("."))) k++;
        break;
      }
      if (flag === "e" || flag === "f") {
        scriptGiven = true;
        if (f === flags.length - 1) k++;
        break;
      }
      if (flag === "l") { if (f === flags.length - 1) k++; break; }
    }
  }
  if (!inPlace) return [];
  return scriptGiven ? files : files.slice(1);
}

function perlTargets(args) {
  let inPlace = false;
  let scriptGiven = false;
  const files = [];
  let optionsDone = false;
  for (let k = 0; k < args.length; k++) {
    const w = args[k];
    if (optionsDone || !isOption(w)) { files.push(w); continue; }
    if (w.v === "--") { optionsDone = true; continue; }
    const flags = w.v.slice(1);
    for (let f = 0; f < flags.length; f++) {
      const flag = flags[f];
      if (flag === "i") { inPlace = true; break; } // the rest of the cluster is the suffix
      if (flag === "e" || flag === "E") {
        scriptGiven = true;
        if (f === flags.length - 1) k++;
        break;
      }
      // -l and -0 take optional digits, and the cluster goes on after them (F4).
      if (flag === "l") { while (/[0-7]/.test(flags[f + 1] ?? "")) f++; continue; }
      if (flag === "0") { while (/[0-9a-fA-FxX]/.test(flags[f + 1] ?? "")) f++; continue; }
      if (flag === "d") { if (/[:t]/.test(flags[f + 1] ?? "")) break; continue; }
      if ("IMmxCF".includes(flag)) break; // these take the rest of the cluster
    }
  }
  if (!inPlace) return [];
  return scriptGiven ? files : files.slice(1);
}

/** The words a simple command's name and arguments write to. */
function commandTargets(name, args) {
  switch (name) {
    case "tee":
      return operands(args).operands;
    case "sed":
      return sedTargets(args);
    case "perl":
      return perlTargets(args);
    case "cp":
    case "mv":
      return destination(args, valueOptions("-t", "--target-directory", "-S", "--suffix"), 1);
    case "install": {
      const takes = valueOptions("-t", "--target-directory", "-m", "--mode", "-o", "--owner", "-g", "--group", "-S", "--suffix");
      if (args.some((w) => w.v === "-d" || w.v === "--directory")) return operands(args, takes).operands;
      return destination(args, takes, 1);
    }
    case "ln":
      return destination(args, valueOptions("-t", "--target-directory", "-S", "--suffix"), 2);
    case "rm":
      return operands(args).operands;
    case "touch":
      return operands(args, valueOptions("-d", "-r", "-t", "--date", "--reference")).operands;
    case "mkdir":
      return operands(args, valueOptions("-m", "--mode")).operands;
    default:
      return [];
  }
}

/**
 * Splits one simple command into its write targets and its words.
 * Returns { targets: [{ writer, word }], words }.
 */
function analyse(tokens) {
  const targets = [];
  const words = [];
  for (let k = 0; k < tokens.length; k++) {
    const tok = tokens[k];
    if (tok.t === "w") { words.push(tok); continue; }
    const arg = tokens[k + 1];
    if (!arg || arg.t !== "w") continue;
    k++;
    if (!WRITE_REDIRECTS.has(tok.op)) continue;
    // A descriptor duplicate, such as >&2 or 2>&1, writes no file.
    if (tok.op === ">&" && /^(\d+|-)$/.test(arg.v)) continue;
    targets.push({ writer: `${tok.fd}${tok.op}`, word: arg });
  }

  let start = 0;
  while (start < words.length && (RESERVED.has(words[start].v) || ASSIGNMENT_RE.test(words[start].v))) start++;
  const rest = words.slice(start);
  if (!rest.length) return { targets, name: "", args: [] };
  const name = basename(rest[0].v);
  const args = rest.slice(1);
  // Git writes are a documented limit, so only its redirects are judged.
  if (name !== "git") {
    for (const word of commandTargets(name, args)) targets.push({ writer: name, word });
  }
  return { targets, name, args };
}

// ---------------------------------------------------------------------------
// Judging
// ---------------------------------------------------------------------------

function expandTilde(word, text) {
  if (!word.tilde) return text;
  if (text === "~") return homedir();
  if (text.startsWith("~/")) return homedir() + text.slice(1);
  return null; // ~user, which the hook doesn't expand
}

// A cd before one of these runs in a subshell or may not run, so it doesn't
// move the base for the commands after it (F2).
const NO_CARRY_AFTER = new Set(["|", "|&", "&", "||"]);
const NO_CARRY_BEFORE = new Set(["|", "|&"]);

// cdTarget: the base folder after a cd with these args, or null when the hook
// can't follow it.
function cdTarget(base, args) {
  const ops = args.filter((w) => w.v !== "--");
  if (ops.length === 0) return homedir();
  if (ops.length !== 1 || ops[0].dyn >= 0 || ops[0].v === "-") return null;
  const dir = expandTilde(ops[0], ops[0].v);
  if (dir === null) return null;
  if (base === null) return isAbsolute(dir) ? dir : null;
  return resolve(base, dir);
}

/**
 * Judges a whole command line from cwd.
 * Returns { blocks: [string], warnings: [string] }.
 *
 * A relative target is judged against two bases: the hook's cwd and the base
 * a tracked cd leads to. It blocks if either judgement blocks, so a cd that
 * never runs can't move a write out of the gate (F2). The tracked base
 * returns to its outer value at ), and a cd doesn't carry across |, ||, or &.
 */
function judgeCommand(cwd, command) {
  const blocks = [];
  const warnings = [];
  const root = resolveRoot(cwd);
  if (!root) return { blocks, warnings };

  let items;
  try {
    items = tokenise(command);
  } catch (err) {
    if (!(err instanceof ParseError)) throw err;
    warnings.push(`${PREFIX} Warning: shell-write-guard could not parse the command (${err.message}). Command allowed.\n`);
    return { blocks, warnings };
  }

  // judge: the block reason for literal from base, or null when it passes.
  const judge = (writer, base, literal) => {
    const relPath = toRootRelative(root, base, literal);
    if (relPath === null) return null; // outside the repository root
    const result = evaluateWrite(root, relPath);
    if (result.warning) warnings.push(result.warning);
    if (result.allowed) return null;
    const reason = result.reason.replace(/^\[Planifest\]\s*/, "").trim();
    return (
      `${PREFIX} Shell write blocked: '${writer}' writes '${relPath || "."}'. ${reason} ` +
      "Make the change through the Write or Edit tool once the design covers the path.\n"
    );
  };

  const start = resolve(cwd);
  let tracked = start;
  const outer = [];
  for (let n = 0; n < items.length; n++) {
    const item = items[n];
    if (item.t === "sep") {
      if (item.op === "(") outer.push(tracked);
      else if (item.op === ")" && outer.length) tracked = outer.pop();
      continue;
    }
    const { targets, name, args } = analyse(item.tokens);

    for (const { writer, word } of targets) {
      if (word.v === "") continue;
      const literal = expandTilde(word, word.dyn >= 0 ? word.v.slice(0, word.dyn) : word.v);
      if (!literal) {
        warnings.push(`${PREFIX} Warning: shell-write-guard could not judge '${word.v}' (no literal prefix). Command allowed.\n`);
        continue;
      }
      const bases = [start];
      if (!isAbsolute(literal) && tracked !== null && tracked !== start) bases.push(tracked);
      let blocked = false;
      for (const base of bases) {
        const reason = judge(writer, base, literal);
        if (reason) { blocks.push(reason); blocked = true; }
      }
      if (!blocked && tracked === null && !isAbsolute(literal)) {
        warnings.push(`${PREFIX} Warning: shell-write-guard could not judge '${word.v}' after a cd it can't follow. Command allowed.\n`);
      }
    }

    if (name === "cd") {
      const before = items[n - 1];
      const after = items[n + 1];
      const carries =
        !(before?.t === "sep" && NO_CARRY_BEFORE.has(before.op)) &&
        !(after?.t === "sep" && NO_CARRY_AFTER.has(after.op));
      if (carries) tracked = cdTarget(tracked, args);
    }
  }
  return { blocks, warnings };
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

try {
  const input = JSON.parse(await readStdin());
  const command = input?.tool_input?.command;
  if (typeof command !== "string" || !command) process.exit(0);
  const cwd = typeof input?.cwd === "string" && input.cwd ? input.cwd : process.cwd();

  const { blocks, warnings } = judgeCommand(cwd, command);
  for (const w of warnings) process.stderr.write(w);
  if (blocks.length) {
    for (const b of blocks) process.stderr.write(b);
    process.exit(2);
  }
  process.exit(0);
} catch {
  // Never block the session on unexpected errors (0000003-ADR-005).
  process.exit(0);
}
