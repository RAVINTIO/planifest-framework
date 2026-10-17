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
 *   - It skips leading VAR=value assignments and here-document bodies. A body
 *     with no closing delimiter line is read as commands.
 *   - It reads ((...)), $((...)), and $[...] as one unit, so their << and >
 *     are never a here-document or a redirect.
 *   - It tracks the set of folders each simple command may run in, and
 *     judges a relative target against each one. A command joined by && to a
 *     cd with one literal folder runs only in the folder after the cd (N-1).
 *     Any other cd may not have run, so the starting folder stays in the set
 *     (F2). The set returns to its outer value at ), and a cd before or after
 *     | runs in a subshell. pushd acts as cd.
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
 *   - A command it can't parse, such as one with an unbalanced quote or more
 *     than 64 levels of nested quotes and substitutions, passes with a
 *     one-line warning on stderr.
 *   - It doesn't look inside $(...) or backtick substitutions.
 *
 * Receives: the Claude Code PreToolUse JSON on stdin. The command is
 * tool_input.command and the working folder is cwd.
 *
 * Exit codes: 0 = pass, 2 = block. A block reason goes to stderr only, and
 * stdout stays empty (ADR-005). Stderr holds each distinct reason once, at
 * most 20 reasons and 20 warnings, and one line counts any left out. Unexpected errors exit 0 (0000003-ADR-005).
 * Node built-in modules only, and no process spawn.
 */

import { homedir } from "node:os";
import { basename, isAbsolute, resolve } from "node:path";
import { evaluateWrite, resolveRoot, toRootRelative, unjudgeable } from "./path-rules.mjs";
import { readStdin } from "./read-stdin.mjs";

const PREFIX = "[Planifest]";

class ParseError extends Error {}

// ---------------------------------------------------------------------------
// Tokeniser
// ---------------------------------------------------------------------------

const SEPARATORS = ["&&", "||", "|&", ";;", ";", "&", "|", "(", ")"];
const REDIRECTS = ["&>>", "&>", "<<<", "<<-", "<<", "<>", "<&", ">>", ">|", ">&", ">", "<"];

// Quotes, substitutions, and arithmetic nest by recursion. Past this depth the
// command is unjudgeable, so it passes with a warning rather than overflowing
// the stack (F8).
const MAX_NESTING = 64;

function checkDepth(nest) {
  if (nest > MAX_NESTING) throw new ParseError(`nesting deeper than ${MAX_NESTING} levels`);
}

// skipSingle: index of the closing single quote for the one at i.
function skipSingle(s, i) {
  const end = s.indexOf("'", i + 1);
  if (end < 0) throw new ParseError("unbalanced single quote");
  return end;
}

// skipDouble: index of the closing double quote for the one at i.
function skipDouble(s, i, nest = 0) {
  checkDepth(nest);
  for (let j = i + 1; j < s.length; j++) {
    const c = s[j];
    if (c === "\\") j++;
    else if (c === '"') return j;
    else if (c === "`") j = skipBacktick(s, j);
    else if (isArithmetic(s, j)) j = skipArithmetic(s, j + 1, nest + 1) - 1;
    else if (c === "$" && (s[j + 1] === "(" || s[j + 1] === "{")) j = skipGroup(s, j + 1, nest + 1) - 1;
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

// isArithmetic: whether s holds $(( or $[ at i (F5).
function isArithmetic(s, i) {
  return s[i] === "$" && (s.startsWith("((", i + 1) || s[i + 1] === "[");
}

// skipArithmetic: index after the arithmetic that opens with the (( or [ at i.
// Arithmetic is one unit, so its << and > are never a here-document or a
// redirect (F5).
function skipArithmetic(s, i, nest = 0) {
  checkDepth(nest);
  const open = s[i];
  const close = open === "(" ? ")" : "]";
  let depth = 0;
  for (let j = i; j < s.length; j++) {
    const c = s[j];
    if (c === "\\") j++;
    else if (c === "'") j = skipSingle(s, j);
    else if (c === '"') j = skipDouble(s, j, nest + 1);
    else if (c === "`") j = skipBacktick(s, j);
    else if (c === open) depth++;
    else if (c === close && --depth === 0) return j + 1;
  }
  throw new ParseError("unbalanced arithmetic");
}

// skipHeredocBodies: the index after the here-document bodies that start at
// start. Each entry of heredocs is { delim, strip }, and the list empties.
// A body with no closing delimiter line isn't skipped. Its lines are read as
// commands, so a missing delimiter can't hide a write (F5).
function skipHeredocBodies(s, start, heredocs) {
  let i = start;
  while (heredocs.length) {
    const { delim, strip } = heredocs.shift();
    const bodyStart = i;
    for (;;) {
      if (i >= s.length) {
        heredocs.length = 0;
        return bodyStart;
      }
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
function skipGroup(s, i, nest = 0) {
  checkDepth(nest);
  const open = s[i];
  const close = open === "(" ? ")" : "}";
  const heredocs = [];
  let depth = 0;
  for (let j = i; j < s.length; j++) {
    const c = s[j];
    if (c === "\\") j++;
    else if (c === "'") j = skipSingle(s, j);
    else if (c === '"') j = skipDouble(s, j, nest + 1);
    else if (c === "`") j = skipBacktick(s, j);
    else if (isArithmetic(s, j)) j = skipArithmetic(s, j + 1, nest + 1) - 1;
    else if (j > i && open === "(" && s.startsWith("((", j)) j = skipArithmetic(s, j, nest + 1) - 1;
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

    // An arithmetic command, such as ((x <<= 2)) or for ((...)), is one word.
    if (!word && s.startsWith("((", i)) {
      const end = skipArithmetic(s, i);
      tokens.push({ t: "w", v: s.slice(i, end), dyn: 0, tilde: false, quoted: true });
      i = end;
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
    } else if (isArithmetic(s, i)) {
      mark();
      const end = skipArithmetic(s, i + 1);
      word.v += s.slice(i, end);
      i = end;
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
 * Returns { targets: [{ writer, word }], name, args, negated }, where negated
 * says a ! came before the name.
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
  const negated = words.slice(0, start).some((w) => w.v === "!");
  const rest = words.slice(start);
  if (!rest.length) return { targets, name: "", args: [], negated };
  const name = basename(rest[0].v);
  const args = rest.slice(1);
  // Git writes are a documented limit, so only its redirects are judged.
  if (name !== "git") {
    for (const word of commandTargets(name, args)) targets.push({ writer: name, word });
  }
  return { targets, name, args, negated };
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

// A cd before or after one of these runs in a subshell, so it doesn't move the
// base for the commands after it (F2).
const NO_CARRY_AFTER = new Set(["|", "|&", "&"]);
const NO_CARRY_BEFORE = new Set(["|", "|&"]);

// These separators keep the folder set of the command before them. Any other
// separator may follow a command whose cd didn't run, so the set widens to
// every folder the list has reached (N-1).
const KEEP_BASES = new Set(["&&", "|", "|&"]);

// The commands that change the folder. pushd with one folder acts as cd, and
// popd returns to some folder the command has already reached.
const CD_NAMES = new Set(["cd", "pushd", "popd"]);

// Past this many possible folders, a relative target can't be judged, so it
// blocks. An absolute target is still judged.
const MAX_BASES = 64;

// cdTarget: the base folder after a cd with these args, or null when the hook
// can't follow it.
function cdTarget(base, args) {
  const ops = args.filter((w) => w.v !== "--");
  if (ops.length === 0) return homedir();
  if (ops.length !== 1 || ops[0].dyn >= 0 || ops[0].v === "-") return null;
  if (/^[+-]\d+$/.test(ops[0].v)) return null; // pushd +N rotates the stack
  const dir = expandTilde(ops[0], ops[0].v);
  if (dir === null) return null;
  if (base === null) return isAbsolute(dir) ? dir : null;
  return resolve(base, dir);
}

/**
 * Judges a whole command line from cwd.
 * Returns { blocks: [string], warnings: [string] }.
 *
 * The hook keeps the set of folders the next command may run in, and judges a
 * relative target against each one. A command joined by && to a cd with one
 * literal folder runs only if the cd succeeded, so the set becomes the folders
 * after the cd alone (N-1). Any other cd may not have run, so it adds its
 * folders to the set and keeps the old ones (F2). These cases keep the old ones:
 *   - a cd after ||, after !, or with an argument the hook can't follow
 *   - a command after ;, a line break, ||, or & (the set widens to every
 *     folder the list has reached)
 *   - a command after ), where the set returns to its value before (
 * A cd before or after |, or before &, runs in a subshell and changes nothing.
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
    if (!(err instanceof ParseError) && !(err instanceof RangeError)) throw err;
    const why = err instanceof RangeError ? "nesting too deep" : err.message;
    warnings.push(`${PREFIX} Warning: shell-write-guard could not parse the command (${why}). Command allowed.\n`);
    return { blocks, warnings };
  }

  // judge: the block reason for literal from base, or null when it passes.
  // A repeated target reuses its first judgement.
  const seen = new Map();
  const judge = (writer, base, literal) => {
    const key = `${writer}\0${base}\0${literal}`;
    if (!seen.has(key)) seen.set(key, judgeOnce(writer, base, literal));
    return seen.get(key);
  };
  const judgeOnce = (writer, base, literal) => {
    const tooLong = unjudgeable(base, literal);
    if (tooLong) {
      warnings.push(tooLong.replace("Write allowed.", "Command allowed."));
      return null;
    }
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
  // bases: the folders the next command may run in. null is a folder the hook
  // can't follow. reached: every folder the current list may have reached.
  // everSeen: every folder the whole command may have reached, for popd.
  let bases = new Set([start]);
  let reached = new Set([start]);
  const everSeen = new Set([start]);
  let overflow = false; // too many folders to judge, so relative targets block
  const outer = [];
  for (let n = 0; n < items.length; n++) {
    const item = items[n];
    if (item.t === "sep") {
      if (item.op === "(") {
        outer.push({ bases, reached });
        reached = new Set(bases);
      } else if (item.op === ")" && outer.length) {
        ({ bases, reached } = outer.pop());
      } else if (!KEEP_BASES.has(item.op)) {
        bases = new Set(reached);
      }
      continue;
    }
    const { targets, name, args, negated } = analyse(item.tokens);

    for (const { writer, word } of targets) {
      if (word.v === "") continue;
      const literal = expandTilde(word, word.dyn >= 0 ? word.v.slice(0, word.dyn) : word.v);
      if (!literal) {
        warnings.push(`${PREFIX} Warning: shell-write-guard could not judge '${word.v}' (no literal prefix). Command allowed.\n`);
        continue;
      }
      if (overflow && !isAbsolute(literal)) {
        blocks.push(
          `${PREFIX} Shell write blocked: '${writer}' writes '${word.v}', and the command may run in more than ` +
          `${MAX_BASES} folders, too many to judge. Use an absolute path, or fewer cd steps that may fail.\n`,
        );
        continue;
      }
      const from = isAbsolute(literal) ? [start] : [...bases];
      // A folder too long to judge leaves doubt, so the starting folder is
      // judged as well (F7).
      if (!from.includes(start) && from.some((base) => base !== null && unjudgeable(base, literal))) from.push(start);
      let blocked = false;
      for (const base of from) {
        if (base === null) continue;
        const reason = judge(writer, base, literal);
        if (reason) { blocks.push(reason); blocked = true; }
      }
      if (!blocked && from.includes(null)) {
        warnings.push(`${PREFIX} Warning: shell-write-guard could not judge '${word.v}' after a cd it can't follow. Command allowed.\n`);
      }
    }

    if (CD_NAMES.has(name) && !overflow) {
      const before = items[n - 1];
      const after = items[n + 1];
      const carries =
        !(before?.t === "sep" && NO_CARRY_BEFORE.has(before.op)) &&
        !(after?.t === "sep" && NO_CARRY_AFTER.has(after.op));
      if (carries) {
        const moved = name === "popd" ? [...everSeen] : [...bases].map((base) => cdTarget(base, args));
        for (const base of moved) { reached.add(base); everSeen.add(base); }
        // The next command runs only if this cd succeeded.
        const sure =
          name !== "popd" && !negated &&
          after?.t === "sep" && after.op === "&&" &&
          !(before?.t === "sep" && before.op === "||") &&
          moved.every((base) => base !== null);
        bases = sure ? new Set(moved) : new Set([...bases, ...moved]);
        if (reached.size > MAX_BASES || everSeen.size > MAX_BASES) overflow = true;
      }
    }
  }
  return { blocks, warnings };
}

// At most this many distinct reasons, and the same number of warnings, reach
// stderr. One summary line counts the rest (F11).
const MAX_REASONS = 20;

// capped: the distinct lines, at most MAX_REASONS of them, and a summary line
// when more were left out.
function capped(lines, noun) {
  const distinct = [...new Set(lines)];
  let out = distinct.slice(0, MAX_REASONS).join("");
  const rest = distinct.length - MAX_REASONS;
  if (rest > 0) out += `${PREFIX} ${rest} more ${noun} not shown.\n`;
  return out;
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
  process.stderr.write(capped(warnings, "warnings"));
  if (blocks.length) {
    process.stderr.write(capped(blocks, "blocked writes"));
    process.exit(2);
  }
  process.exit(0);
} catch {
  // Never block the session on unexpected errors (0000003-ADR-005).
  process.exit(0);
}
