---
title: "Requirement: req-004 - shell-write-guard"
summary: "A Bash PreToolUse hook holds shell writes to the same design gate as Write and Edit, registered for Claude Code by both setup scripts."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - shell-write-guard

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-004
**Priority:** should-have

## User Story

As the human on the loop, I see shell writes held to the same design gate as **Write** and **Edit**, so that auto mode cannot bypass the gate.

## Functional Requirements

### The hook (AC-8)

- A new hook, `planifest-framework/hooks/enforcement/shell-write-guard.mjs`, runs on Claude Code's Bash PreToolUse event. It reads stdin through `read-stdin.mjs` and stays a dependency-free Node ES module.
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
- A `cd` with one literal argument changes the base folder for the simple commands after it in the same command line. Write targets resolve against that base.
- The hook resolves each target through `toRootRelative` and decides it through `evaluateWrite`, both from `path-rules.mjs` (req-003).
- If any target gets a block result, the hook exits 2. It writes a plain-text reason to stderr that names the writer, the root-relative target, and the reason from `evaluateWrite`. It writes nothing to stdout.
- The block reason tells the agent to make the change through **Write** or **Edit** once the design covers the path.

### Parse failures and limits (AC-8)

- The hook can't parse a command when its quotes don't balance. It then writes a one-line warning to stderr and exits 0.
- When a writer's target holds `$`, a backtick, `*`, `?`, or `{`, the hook judges the literal prefix before the first such character. For `src/*.js` it judges `src/`. If the target has no literal prefix, it writes a one-line warning to stderr and exits 0.
- A command that parses and holds no writer exits 0 with no output, even if it holds `$(...)` or backticks elsewhere.
- The hook ignores commands whose name is `git`. Writes made by `git checkout`, `git restore`, `git apply`, and similar are a documented limit.
- The hook can't see writes made inside a script, an interpreter one-liner such as `node -e` or `python -c`, a build tool, or a package manager. These are a documented limit.
- The hook's header comment lists each limit. The boot-file rule below covers the gap.

### Same rules as gate-write (AC-9)

- The hook and `gate-write.mjs` share `path-rules.mjs`. Neither file holds its own copy of the always-permitted lists, the sentinel check, or the component-path parser.
- For any root-relative path, the hook blocks exactly when `gate-write.mjs` blocks a **Write** to the same path. With no `design.md`, every gated path blocks. With `design.md`, the component-path check applies.
- A target outside the repository root passes, by the req-003 root rule.
- Read-only commands pass, even when they name gated paths.

### Fail-open and latency (NFRs)

- The hook exits 0 with no output on each of these inputs:
  - stdin that isn't valid JSON
  - JSON with no `command`
  - JSON whose `command` isn't a string
- Any unexpected error exits 0 (ADR-005).
- Each call finishes in under 200 ms on the CI runners.

### Setup registration (AC-10)

- `install_enforcement_hooks` in `planifest-framework/setup.sh` adds a `PreToolUse` group `{matcher: "Bash", hooks: [{type: "command", command: "node \".claude/hooks/enforcement/shell-write-guard.mjs\""}]}`.
- Before it adds the group, the remove-then-re-add filter drops any `Bash` group whose command contains `shell-write-guard`. Groups that the human on the loop added for `Bash` stay in place.
- `Merge-EnforcementHookSettings` in `planifest-framework/setup.ps1` adds the same `Bash` group with the same filter. It uses the `node $HooksDir/shell-write-guard.mjs` command form that file already uses for `gate-write.mjs`.
- Only the Claude Code install path reaches these two functions, so no other tool gains the hook.
- Both setup scripts already copy every `*.mjs` file in `hooks/enforcement/`. That copies `shell-write-guard.mjs` and `path-rules.mjs` with no change to the copy step.
- `planifest-framework/tests/test_setup.sh` and `planifest-framework/tests/test_setup.ps1` assert the registration and the idempotence.

### Migration (AC-11)

- A new file, `planifest-framework/migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md`, follows the layout of `migrate-remove-context-mode-and-telemetry.md`. It has a header block, then the "Background", "What This Migration Does", and "Migrator Instructions" sections.
- The migration tells the migrator to do these steps:
  1. Confirm that `planifest-framework/component.yml` reports `0.31.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first.
  2. Re-run setup for each tool the project uses, with its usual flags. `planifest-refresh-setup` rebuilds those flags.
  3. For Claude Code, check that `.claude/settings.json` holds exactly one `Bash` group that runs `shell-write-guard.mjs`.
  4. Archive the migration to `migrations/_done/`.
- The migration's "Background" names both gains: the Bash hook, and block reasons on stderr from req-003.

### Boot-file rule

- `planifest-framework/templates/standard-boot.md` and `planifest-framework/templates/cursor-boot.md` each gain a Hard Limit: code changes go through **Write** or **Edit**, never through Bash. The rule says the shell guard is a heuristic and can't see writes made inside scripts.
- The "Hook Enforcement" section of the same template gains a `shell-write-guard` bullet (PreToolUse: Bash, Claude Code only).
- In that section, the `gate-write` bullet states that paths outside the repository are never gated. The closing paragraph states that block reasons go to stderr.
- Setup regenerates every boot file from the template (0000029-ADR-001), so this repository's `CLAUDE.md` gains the rule when setup runs.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-004-shell-write-guard.sh`, runs the hook with JSON on stdin and checks exit code, stdout, and stderr. It builds fixtures under `mktemp -d` and runs `git init` inside them.
- The suite holds two fixed corpora, listed below. Each runs once with no `design.md`. The detection corpus also runs with a `design.md` whose component paths don't cover `src/`.

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

**False-positive corpus.** Each command must exit 0 with an empty stderr.

1. `cat src/a.js`
2. `grep -rn 'foo' src/`
3. `grep '>' src/a.js`
4. `ls -la src`
5. `sed -n '1,5p' src/a.js`
6. `sed 's/a/b/' src/a.js`
7. `head -20 src/a.js | wc -l`
8. `find src -name '*.js'`
9. `diff src/a.js src/b.js`
10. `git diff src/`
11. `git log -- src/a.js`
12. `node src/index.js > /dev/null 2>&1`
13. `node src/index.js >&2`
14. `echo "a > src/b"`
15. `perl -ne 'print' src/a.js`
16. `test -f src/a.js && echo yes`
17. `wc -l src/a.js > /tmp/out.txt`
18. `cat src/a.js | tee /tmp/copy.txt`
19. `echo x > plan/notes.md`
20. `echo x > docs/a.md`
21. `git commit -m "$(cat <<'EOF'` with a body line that mentions `> src/a.js`, then `EOF` and `)"`

## Acceptance Criteria

- [ ] Every command in the detection corpus exits 2 with a non-empty stderr and an empty stdout, with no `design.md`.
- [ ] Every command in the detection corpus exits 2 with a `design.md` whose component paths don't cover `src/`.
- [ ] With a `design.md` whose component paths cover `src/`, commands 1, 7, 12, and 18 of the detection corpus exit 0.
- [ ] Every command in the false-positive corpus exits 0 with an empty stderr, with no `design.md`.
- [ ] A writer aimed at a path outside the fixture, such as `echo x > /tmp/elsewhere.txt`, exits 0.
- [ ] `echo x > "src/a.js` (unbalanced quote) exits 0 and writes a warning to stderr.
- [ ] `echo x > $TARGET` and `echo x > "$DIR/a"` each exit 0 and write a warning to stderr.
- [ ] With no `design.md`, `rm src/*.js` and `cp a src/$NAME` each exit 2, because their literal prefix `src/` is a gated path.
- [ ] `git checkout -- src/a.js` exits 0 with no output.
- [ ] For each of `src/a.js`, `README.md`, `plan/current/x.md` without a sentinel, and `docs/a.md`, the hook's exit code matches `gate-write.mjs`'s exit code for a **Write** to the same path.
- [ ] Neither `shell-write-guard.mjs` nor `gate-write.mjs` defines the always-permitted lists. Both import `path-rules.mjs`.
- [ ] The hook exits 0 with no output on malformed stdin, on JSON with no `command`, and on a non-string `command`.
- [ ] Each hook call completes in under 200 ms, timed in the suite.
- [ ] After `setup.sh claude-code` runs twice, `.claude/settings.json` holds exactly one `PreToolUse` group with matcher `Bash` whose command runs `shell-write-guard.mjs`.
- [ ] After `setup.ps1 claude-code` runs twice, the same check holds.
- [ ] A `Bash` group the human on the loop added before setup survives both setup runs.
- [ ] After `setup.sh claude-code`, `.claude/hooks/enforcement/shell-write-guard.mjs` exists.
- [ ] `planifest-framework/migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md` exists outside `_done/`. It names version `0.31.0`, `shell-write-guard`, and re-running setup.
- [ ] `templates/standard-boot.md` holds the Hard Limit that code changes go through **Write** or **Edit**, and a `shell-write-guard` bullet.
- [ ] `templates/cursor-boot.md` holds the same Hard Limit.
- [ ] After `setup.sh claude-code`, the generated `CLAUDE.md` holds the same Hard Limit.

## Dependencies

- Req-003: `path-rules.mjs`, the repository root rule, and the stderr block-reason rule.
- The 0000031 CI jobs run `test_setup.ps1` on Windows and the new suite on Linux.
- The ship step bumps `planifest-framework/component.yml` to `0.31.0`, which the migration checks for.
