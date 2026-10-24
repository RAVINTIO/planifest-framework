---
title: "ADR 003: Credential scan is one script and skill text enforces the stop"
summary: "One Node script scans the index blob and the working-tree file for every committed path and exits 0, 1, or 2. A standing rule in autonomous-run-standards.md enforces the stop. The feature adds no hook."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Credential scan is one script and skill text enforces the stop

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The P8 credential guard in the ship skill greps staged files, but only at ship time. An `autonomous` run commits and pushes many times before then. A credential can reach the remote earlier.

The framework commit form is `git commit -m ... -- {path}`. It commits the working-tree content and ignores the index. A scan of the index alone misses a change made after `git add`.

The design lists no new hook. Orchestrator Hard Limit 6 forbids credentials in context, and exception item 7 covers a sighting.

## Decision

Add `planifest-framework/scripts/credential-scan.mjs`. It detects and reports. It never stops a commit.

- **Sources.** For every path in the commit, it reads the index blob with `git show :{path}` and the working-tree file. A match in either counts. Paths come from `git diff --cached --name-only` plus any path after `--`.
- **Rules.** It applies the P8 refused file names and content regex. If `gitleaks` is on PATH, it also runs it.
- **Exit codes.** `0` is clean. `1` is at least one match. `2` means the scan could not run, and callers treat it as a match.
- **Output.** It prints `{path}:{line}` and the rule name. It never prints the matched text.
- **Enforcement.** A new standing rule in `planifest-framework/standards/autonomous-run-standards.md` orders every `autonomous` commit to run the script first and to stop on exit `1` or `2`. Orchestrator Hard Limit 7 points to that rule.
- **One list.** The P8 guard and the Step 10b guard call the script in place of inline `grep`.

On a match, the agent runs no `git commit` and no `git push` for that change. The files stay staged. The agent writes `Exception waiting (P{N}, 7)`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Git `pre-commit` hook that runs the scan | Stops the commit mechanically | Needs install in every consumer repository, and `--no-verify` or an agent's own `git` call skips it | The design lists no new hook, and the hook adds a setup surface |
| `PreToolUse` hook on Bash that blocks `git commit` | Covers the agent's shell calls | Must parse commit commands, which the shell guard already treats as heuristic, and only some tools run it | Parsing is fragile and coverage is partial |
| Scan the index only | Simpler script | Misses a change made after `git add` when `-- {path}` commits the working tree | Defeats the purpose |
| Keep inline `grep` in each guard | No new file | Two pattern lists drift, and BSD and GNU `grep` differ | One script keeps one list |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | New script. New standing rule in the autonomous standard. Edits to the ship skill guards, orchestrator Hard Limit 7, and Resume Detection. |

## Consequences

**Positive:**
- A credential stops before the commit, not at ship time.
- The check reads what the commit will contain.
- One pattern list serves all callers.

**Negative:**
- A rule in skill text depends on the agent following it. Nothing blocks a `git commit` that skips the script.
- A false positive stops an `autonomous` run until the human on the loop clears it (R-003).

**Risks:**
- Without `gitleaks`, only the regex runs, so some secrets pass (R-008). The output states the scan mode.
- A held-back staged file shows in the clean-tree checks. The orchestrator Resume Detection text must rescan it before any commit.

## Related ADRs

- ADR-001 - depends-on (Node built-ins only)
- ADR-002 - related-to (fix commits run the scan)
- ADR-004 - related-to (`--file` mode reuses the script)
- 0000033 D-003 - related-to (exception handling)

## Governs

req-003

## Supersedes

- None

## Superseded By

- None
