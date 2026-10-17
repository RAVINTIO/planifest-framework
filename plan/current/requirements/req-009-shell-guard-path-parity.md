---
title: "Requirement: req-009 - shell-guard-path-parity"
summary: "The shell guard and gate-write share one path-rules module, so they gate exactly the same paths, and the guard passes read-only commands and fails open on bad input."
status: "draft"
version: "0.1.0"
---
# Requirement: req-009 - shell-guard-path-parity

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-004
**Priority:** should-have

## User Story

As the human on the loop, I want the shell guard to gate exactly the paths that **Write** and **Edit** gate, so that the two gates never disagree and read-only commands never block.

## Functional Requirements

### Same rules as gate-write (AC-9)

- The hook and `gate-write.mjs` share `path-rules.mjs` (ADR-004). Neither file holds its own copy of the always-permitted lists, the sentinel check, or the component-path parser.
- For any root-relative path, the hook blocks exactly when `gate-write.mjs` blocks a **Write** to the same path. With no `design.md`, every gated path blocks. With `design.md`, the component-path check applies.
- A target outside the repository root passes, by the req-006 root rule.
- Read-only commands pass, even when they name gated paths.

### Fail-open and latency (NFRs)

- The hook exits 0 with no output on each of these inputs:
  - stdin that isn't valid JSON
  - JSON with no `command`
  - JSON whose `command` isn't a string
- Any unexpected error exits 0 (ADR-005).
- Each call finishes in under 200 ms on the CI runners.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-009-shell-guard-path-parity.sh`, runs the hook and `gate-write.mjs` with JSON on stdin and checks exit code, stdout, and stderr. It builds fixtures under `mktemp -d` and runs `git init` inside them.
- The suite runs the req-008 detection corpus with a `design.md` whose component paths don't cover `src/`, and again with one that covers `src/`.
- The suite runs the false-positive corpus below with no `design.md`.

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

### Verified by

- Every command in the req-008 detection corpus exits 2 with a `design.md` whose component paths don't cover `src/`.
- With a `design.md` whose component paths cover `src/`, commands 1, 7, 12, and 18 of the detection corpus exit 0.
- Every command in the false-positive corpus exits 0 with an empty stderr, with no `design.md`.
- A writer aimed at a path outside the fixture, such as `echo x > /tmp/elsewhere.txt`, exits 0.
- For each of `src/a.js`, `README.md`, `plan/current/x.md` without a sentinel, and `docs/a.md`, the hook's exit code matches `gate-write.mjs`'s exit code for a **Write** to the same path.
- Neither `shell-write-guard.mjs` nor `gate-write.mjs` defines the always-permitted lists. Both import `path-rules.mjs`.
- The hook exits 0 with no output on malformed stdin, on JSON with no `command`, and on a non-string `command`.
- Each hook call completes in under 200 ms, timed in the suite.

## Acceptance Criteria

- [ ] The shell guard and `gate-write.mjs` both import `path-rules.mjs`, and their exit codes match for the same path, with and without the sentinel. With no `design.md` the guard blocks, and with one it applies the component-path check.
- [ ] Every command in the false-positive corpus exits 0 with an empty stderr, and a write outside the repository passes.
- [ ] The guard exits 0 with no output on malformed or incomplete input, and each call completes in under 200 ms.

## Dependencies

- Req-006: `path-rules.mjs` and the repository root rule.
- Req-008: the hook and its detection corpus.
- ADR-004 records the shared module. ADR-005 records the fail-open rule. ADR-006 records the guard's approach.
- The 0000031 CI jobs run the new suite on Linux.
