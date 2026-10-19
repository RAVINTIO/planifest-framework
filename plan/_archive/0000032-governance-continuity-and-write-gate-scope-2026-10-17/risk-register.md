---
title: "Risk Register - Governance continuity and write-gate scope"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - Governance continuity and write-gate scope

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Version:** 0.31.0
**Overall Risk Level:** low (medium at P1, lowered after the P5 fix rounds)

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The shell-write guard blocks a read-only command that mentions a gated path, such as `grep -r foo src/` or `cat src/a.js > /tmp/out`. | medium | medium | A false-positive corpus test must pass with zero blocks. The guard fails open with a stderr warning when it can't parse a command. | open |
| R-002 | security | The shell-write guard misses a real write to a gated path, for example through a script, a variable, or a git command. | high | low | A detection corpus covers every AC-8 writer form. The boot file states that code changes go through **Write** or **Edit**. The limits are documented. | accepted |
| R-003 | operational | Moving the marker deletion to after P8 changes resume behaviour for downstream runs already between P7 and P9 when they upgrade to 0.31.0. | low | medium | Resume Detection step 2a stops and asks the human on the loop when no matching archive exists. | open |
| R-004 | operational | Running `setup.sh` or `setup.ps1` twice adds a second Bash PreToolUse entry for the shell-write guard. | medium | low | The AC-10 setup tests run setup twice and assert exactly one registration. | open |
| R-005 | technical | Resolving the repository root adds work to each `gate-write.mjs` and shell-write guard call, and pushes a call over the 200 ms target. | low | medium | ADR-004 walks the folder tree with no git spawn. The hook suites time each call against the NFR. Each hook adds about 20 ms over Node start-up. | mitigated |
| R-006 | technical | Adding stderr block reasons breaks a consumer of hook stdout, such as the Windsurf adapter relay or `ratchet-check.mjs`'s JSON output. | low | medium | AC-7 keeps all existing stdout output. Tests assert stderr is not empty on each block path while existing stdout assertions stay. | open |
| R-007 | security | `gate-write.mjs` passing every target outside the repository root lets an agent write anywhere else on disk with no Planifest check. | medium | low | Accepted by design (AC-6). Planifest governs the repository only. The tool's own permission system governs paths outside it. | accepted |

## Assumptions Logged as Risks

Each assumption carries likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | Claude Code shows a PreToolUse block reason from stderr when a hook exits 2. | AC-7 fixes nothing for Claude Code. The agent still sees `No stderr output`. | open |
| A-002 | Claude Code passes the Bash command as `tool_input.command` to a PreToolUse hook. | The shell-write guard never sees a command and always passes. | open |
| RA-003 | Gitignored session markers aren't needed. | The sentinel still can't cover the Step 11 confirmation, so that step runs with no active run. | open |
