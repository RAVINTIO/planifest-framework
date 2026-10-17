---
title: "Requirement: req-008 - shell-writer-detection"
summary: "A Bash PreToolUse hook finds common shell writers aimed at gated paths and blocks them with a stderr reason, failing open on commands it can't parse."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - shell-writer-detection

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-004
**Priority:** should-have

## User Story

As the human on the loop, I want the shell guard to catch the common shell writers aimed at gated paths, so that auto mode cannot bypass the design gate through Bash.

## Functional Requirements

### The hook (AC-8)

- A new hook, `planifest-framework/hooks/enforcement/shell-write-guard.mjs`, runs on Claude Code's Bash PreToolUse event. It reads stdin through `read-stdin.mjs` and stays a dependency-free Node ES module (ADR-006).
- The hook reads the command from `tool_input.command` and the working folder from `cwd`. If `cwd` is absent, it uses `process.cwd()`.
- The hook splits the command into simple commands at `;`, `&&`, `||`, `|`, `&`, and line breaks. It respects single quotes, double quotes, and backslash escapes, so an operator inside quotes isn't a split point.
- The hook skips leading `VAR=value` assignments before it reads a simple command's name.
- The hook skips the body of a here-document, from the line after `<<WORD` or `<<'WORD'` up to the closing `WORD` line.
- The hook finds write targets in these forms:

  | Writer | Targets |
  |--------|---------|
  | `>`, `>>`, `>\|`, `&>`, `&>>`, and the same with a file-descriptor number, such as `2>` | the word after the operator |
  | `tee`, `tee -a` | every argument that isn't an option |
  | `sed -i`, `sed -i.bak`, `sed -i ''`, `sed --in-place` | every file argument after the script |
  | `perl -i`, `perl -pi -e`, `perl -i.bak` | every file argument after the script |
  | `cp`, `mv`, `install` | the last argument that isn't an option, or the value of `-t` or `--target-directory` |
  | `ln` | the last argument that isn't an option when there are two or more, or the value of `-t` |
  | `rm`, `touch`, `mkdir` | every argument that isn't an option |

- A redirect to a file-descriptor duplicate, such as `>&2` or `2>&1`, isn't a write target. A redirect to `/dev/null` is outside the repository and passes.
- A `cd` with one literal argument changes the base folder for the simple commands after it in the same command line. Write targets resolve against that base. A command joined to the `cd` by `&&` resolves against the new base alone. After any `cd` that may not have run, targets also resolve against the starting folder (ADR-006).
- The hook resolves each target through `toRootRelative` and decides it through `evaluateWrite`, both from `path-rules.mjs` (req-006). Req-009 holds that decision to parity with `gate-write.mjs`.
- If any target gets a block result, the hook exits 2. It writes a plain-text reason to stderr that names the writer, the root-relative target, and the reason from `evaluateWrite`. It writes nothing to stdout (ADR-005).
- The block reason tells the agent to make the change through **Write** or **Edit** once the design covers the path.

### Parse failures and limits (AC-8)

- The hook can't parse a command when its quotes don't balance. It then writes a one-line warning to stderr and exits 0.
- When a writer's target holds `$`, a backtick, `*`, `?`, or `{`, the hook judges the literal prefix before the first such character. For `src/*.js` it judges `src/`. If the target has no literal prefix, it writes a one-line warning to stderr and exits 0.
- A command that parses and holds no writer exits 0 with no output, even if it holds `$(...)` or backticks elsewhere.
- The hook ignores commands whose name is `git`. Writes made by `git checkout`, `git restore`, `git apply`, and similar are a documented limit.
- The hook can't see writes made inside a script, an interpreter one-liner such as `node -e` or `python -c`, a build tool, or a package manager. These are a documented limit.
- The hook's header comment lists each limit. The boot-file rule in req-012 covers the gap.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-008-shell-writer-detection.sh`, runs the hook with JSON on stdin and checks exit code, stdout, and stderr. It builds fixtures under `mktemp -d` and runs `git init` inside them.
- The suite holds the detection corpus below and runs it with no `design.md`. Req-009 reuses the same corpus for its `design.md` runs.

**Detection corpus.** Each command must exit 2 with a non-empty stderr.

1. `echo x > src/a.js`
2. `echo x >> src/a.js`
3. `printf x 2> src/err.log`
4. `make &> src/build.log`
5. `printf x | tee src/a.js`
6. `printf x | tee -a /tmp/ok.txt src/a.js`
7. `sed -i 's/a/b/' src/a.js`
8. `sed -i.bak 's/a/b/' src/a.js`
9. `sed -i '' 's/a/b/' src/a.js`
10. `perl -pi -e 's/a/b/' src/a.js`
11. `perl -i.bak -pe 's/a/b/' src/a.js`
12. `cp /tmp/a.js src/a.js`
13. `cp -r /tmp/dir src/`
14. `cp -t src/ /tmp/a.js`
15. `mv /tmp/a.js src/a.js`
16. `install -m 644 /tmp/a.js src/a.js`
17. `ln -s /tmp/a.js src/a.js`
18. `rm src/a.js`
19. `rm -rf src`
20. `touch src/new.js`
21. `mkdir -p src/new`
22. `cd src && echo x > a.js`
23. `ls; echo x > src/a.js`
24. `cat > src/a.js <<'EOF'` with a body line and `EOF`
25. `echo x > {root}/src/a.js`, with the absolute fixture path
26. `FOO=1 touch src/a.js`

### Verified by

- Every command in the detection corpus exits 2 with a non-empty stderr and an empty stdout, with no `design.md`.
- `echo x > "src/a.js` (unbalanced quote) exits 0 and writes a warning to stderr.
- `echo x > $TARGET` and `echo x > "$DIR/a"` each exit 0 and write a warning to stderr.
- With no `design.md`, `rm src/*.js` and `cp a src/$NAME` each exit 2, because their literal prefix `src/` is a gated path.
- `git checkout -- src/a.js` exits 0 with no output.
- With no `design.md`, each of these exits 2 (security finding F2): `false && cd /tmp; echo hi > src/x.js`, `(cd /tmp); echo hi > src/x.js`, `cd /tmp | true; echo hi > src/x.js`, `cd /tmp || true; echo hi > src/x.js`, and `cd /tmp & echo hi > src/x.js`.
- `cd /tmp && echo hi > x.txt` and `cd /tmp && echo hi > src/x.js` each exit 0, because they write under `/tmp` (security finding N-1).
- With a design that covers `src/app/` and `build/`, each of these exits 0 with no stderr (security finding N-1): `cd /tmp && touch x`, `cd build && make > log.txt`, `cd src/app && npm test > test.log`, `cd src/app && sed -i "" s/a/b/ index.js`, and `cd ~ && touch .foo`.
- With the same design, a write after a `cd` the hook can't prove ran still exits 2. Examples are `cd src/app && true; echo hi > index.js`, `true || cd src/app && echo hi > index.js`, `! cd src/app && echo hi > index.js`, `(cd src/app) && echo hi > index.js`, and `cd src/other || true; echo hi > build/x`.
- With the same design, a relative write after seven `cd` steps that may fail exits 2 with a reason that names too many folders. The same steps followed by `ls` exit 0.
- Short-option clusters find their targets and exit 2: `cp -vt src/ /tmp/a`, `ln -sft src/ /tmp/a`, `perl -lpi -e … src/x`, `perl -0777 -pi -e … src/x`, `sed -Ei … src/x`, and `sed -Ei '' … src/x` (security finding F4).
- An arithmetic `<<` in `((…))`, `$((…))`, `$[…]`, or `for ((…))` doesn't hide the next line's write. An unterminated here-document body is judged as commands. `((x > 3))` and `$[2 > 1]` aren't redirects (security finding F5).
- With no `design.md`, `((echo hi > src/other/x); true)`, `((echo hi > src/other/x) )`, and `((true) && echo hi > src/other/x)` each exit 2, because Bash reads them as subshells. `((x = (1 + 2) * 3))` stays arithmetic (security finding N-2).
- 20,000 nested `"$(` and 65 nested levels each exit 0 with a one-line warning. 20 nested levels still parse and judge the writer (security finding F8).
- A target repeated 10,000 times blocks with one reason and under 10 KB of stderr. 10,000 distinct targets print 20 reasons and a summary line that counts the other 9,980 (security finding F11).

## Acceptance Criteria

- [ ] With no `design.md`, every command in the detection corpus exits 2 with a non-empty stderr reason and an empty stdout. The corpus covers redirects, `tee`, in-place edits, `cp`, `mv`, `install`, `ln`, `rm`, `touch`, `mkdir`, and a `cd` base change.
- [ ] A target with an expansion is judged by its literal prefix. A command the hook can't parse, or a target with no literal prefix, exits 0 with a stderr warning.
- [ ] Git commands pass with no output, and the hook's header comment lists each documented limit.

## Dependencies

- Req-006: `path-rules.mjs` and the repository root rule.
- Req-007: the stderr block-reason rule.
- ADR-006 records the heuristic detection approach and its limits. ADR-005 records the stderr rule.
- The 0000031 CI jobs run the new suite on Linux.
