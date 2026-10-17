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
 *   - A cd with one literal argument moves the base folder for the simple
 *     commands after it on the same line.
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

// skipGroup: index after the bracket that closes the ( or { at i.
function skipGroup(s, i) {
  const open = s[i];
  const close = open === "(" ? ")" : "}";
  let depth = 0;
  for (let j = i; j < s.length; j++) {
    const c = s[j];
    if (c === "\\") j++;
    else if (c === "'") j = skipSingle(s, j);
    else if (c === '"') j = skipDouble(s, j);
    else if (c === "`") j = skipBacktick(s, j);
    else if (c === open) depth++;
    else if (c === close && --depth === 0) return j + 1;
  }
  throw new ParseError("unbalanced substitution");
}

/**
 * Splits a command line into simple commands. Each simple command is a list
 * of tokens:
 *   { t: "w", v, dyn, tilde }  a word with quotes removed. dyn is the index in
 *                              v of the first $, backtick, *, ?, or {, or -1.
 *   { t: "r", op, fd }         a redirect operator.
 * Throws ParseError on unbalanced quotes.
 */
function tokenise(s) {
  const commands = [];
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
    if (tokens.length) commands.push(tokens);
    tokens = [];
  };
  const skipHeredocBodies = (start) => {
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
  };

  let i = 0;
  while (i < s.length) {
    const c = s[i];

    if (c === "\\" && s[i + 1] === "\n") { i += 2; continue; }
    if (c === " " || c === "\t" || c === "\r") { endWord(); i++; continue; }
    if (c === "\n") {
      endCommand();
      i = heredocs.length ? skipHeredocBodies(i + 1) : i + 1;
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
    if (separator) { endCommand(); i += separator.length; continue; }

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
  return commands;
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
    if (takesValue(w.v) && k + 1 < args.length) { values[w.v] = args[++k]; continue; }
    // A short value option with its value attached, such as -tsrc/.
    const short = w.v.slice(0, 2);
    if (!w.v.startsWith("--") && w.v.length > 2 && takesValue(short)) {
      values[short] = { ...w, v: w.v.slice(2), dyn: w.dyn - 2 };
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
        // BSD sed takes the suffix as its own word: sed -i '' or sed -i .bak.
        if (flags.length === 1 && k + 1 < args.length && (args[k + 1].v === "" || args[k + 1].v.startsWith("."))) k++;
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
      if ("IMmlx0Cd".includes(flag)) break; // these take the rest of the cluster
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

/**
 * Judges a whole command line from cwd.
 * Returns { blocks: [string], warnings: [string] }.
 */
function judgeCommand(cwd, command) {
  const blocks = [];
  const warnings = [];
  const root = resolveRoot(cwd);
  if (!root) return { blocks, warnings };

  let commands;
  try {
    commands = tokenise(command);
  } catch (err) {
    if (!(err instanceof ParseError)) throw err;
    warnings.push(`${PREFIX} Warning: shell-write-guard could not parse the command (${err.message}). Command allowed.\n`);
    return { blocks, warnings };
  }

  let base = resolve(cwd);
  for (const tokens of commands) {
    const { targets, name, args } = analyse(tokens);

    for (const { writer, word } of targets) {
      if (word.v === "") continue;
      const literal = expandTilde(word, word.dyn >= 0 ? word.v.slice(0, word.dyn) : word.v);
      if (!literal) {
        warnings.push(`${PREFIX} Warning: shell-write-guard could not judge '${word.v}' (no literal prefix). Command allowed.\n`);
        continue;
      }
      if (base === null && !isAbsolute(literal)) {
        warnings.push(`${PREFIX} Warning: shell-write-guard could not judge '${word.v}' after a cd it can't follow. Command allowed.\n`);
        continue;
      }
      const relPath = toRootRelative(root, base, literal);
      if (relPath === null) continue; // outside the repository root
      const result = evaluateWrite(root, relPath);
      if (result.warning) warnings.push(result.warning);
      if (!result.allowed) {
        const reason = result.reason.replace(/^\[Planifest\]\s*/, "").trim();
        blocks.push(
          `${PREFIX} Shell write blocked: '${writer}' writes '${relPath || "."}'. ${reason} ` +
          "Make the change through the Write or Edit tool once the design covers the path.\n",
        );
      }
    }

    if (name === "cd") {
      const ops = args.filter((w) => w.v !== "--");
      if (ops.length === 0) base = homedir();
      else if (ops.length === 1 && ops[0].dyn < 0 && ops[0].v !== "-") {
        const dir = expandTilde(ops[0], ops[0].v);
        base = dir === null ? null : base === null ? (isAbsolute(dir) ? dir : null) : resolve(base, dir);
      } else base = null;
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
