---
title: "Risk Register - write gate scope and path hardening"
summary: "Technical, operational, security, and compliance risks for 0000035 with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - write gate scope and path hardening

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Version:** 0.33.0
**Overall Risk Level:** medium

> Every entry is specific to this feature. R-001 to R-004 come from the Risks section of `design.md`. R-005 onward are added by the spec agent.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | Resolving each path segment through links adds file-system calls to every hook call. | medium | low | The 500 ms latency target on a 10-hop chain, the existing `MAX_PATH_CHARS` and `MAX_PATH_SEGMENTS` limits, and a suite timing check on CI. | open |
| R-002 | security | A scope record left by an interrupted Fast Path keeps admitting writes to its paths. | medium | medium | The record stores the branch and `HEAD` commit. The gate ignores it once either changes. The next Fast Path overwrites it. | open |
| R-003 | operational | A downstream project sees six old migrations as pending after refresh. | high | low | Each scan finds nothing on a compliant project, and the migrator writes a record with outcome `applied` and both counts at `0` (req-007 FR-007.2). The pending list in resume detection names each one. | open |
| R-004 | operational | Ten stories in one run exceed the three-story rule. | medium | medium | The run uses parallel work by file ownership across three streams, as the build order in the execution plan sets. Stream 01 holds six requirements in sequence. The orchestrator owns every join. | open |
| R-005 | security | The scope record acts as self-authorisation. The agent that makes the change also writes the list of paths the gate then admits. | medium | high | Accepted risk. The human on the loop chose self-authorisation at P0 over a wider allowlist. Visibility control: each write admitted through the record prints a one-line stderr notice that names the record. The notice reaches the agent and the session transcript, not the main view of the human on the loop. The human on the loop sees the admitted paths in the Fast Path changelog entry, which lists the record's paths. Enforcement paths stay gated whatever the record lists (0000033 ADR 009, req-009), including hook wiring files, tool-local settings files such as `.claude/settings.local.json`, `planifest-framework/setup/`, and `.git/`. The branch and `HEAD` binding bounds staleness only. It is not a security control, because the agent that writes the record also reads both values. | accepted |
| R-006 | security | A record entry that is broad, such as `src/` or a glob, admits more than the change needs. | medium | high | Accepted with R-005. Req-001 lists exact paths or folder prefixes only, with no globs, and the record grammar rejects a malformed entry. The stderr notice on each admitted write records in the transcript what the record let through. The Fast Path changelog entry lists every record path for the human on the loop. The gate does not resolve record entries through links. | accepted |
| R-007 | technical | The gate must read the `HEAD` commit and branch without spawning git (0000032 ADR 004). Reading `.git/HEAD` and the ref file can fail on packed refs or a detached `HEAD`. | medium | medium | Parse `.git/HEAD` and fall back to `.git/packed-refs`. A detached `HEAD` compares the stored hash. If neither source reads, the gate treats the record as stale and blocks. | open |
| R-008 | technical | In a git worktree, `.git` is a file that points at the real git folder. A reader that expects a folder finds no `HEAD` and treats every record as stale. | low | medium | Read the `gitdir:` line when `.git` is a file. Add a suite case with a `.git` file. The project rules already say not to use worktrees, which lowers the likelihood. | open |
| R-009 | technical | The `markedRoot` trust rule for planted markers also rejects a real `.git` in a nested repo under an always-permitted name. | low | medium | Distrust a marker only below an always-permitted basename, as US-006 states. Add a suite case for a genuine root beside the planted one. | open |
| R-010 | operational | Fail-closed path resolution blocks a legitimate write, for example through a healthy link that the hop limit or a permission error rejects. | medium | medium | Block only for paths inside the repo root. Every block exits 2 with a reason on stderr that names the path and the cause. Set the hop limit above any link depth the repo uses, and test a 10-hop chain. | open |
| R-011 | technical | Errors outside path resolution must still fail open (0000003 ADR 005). A broad catch in the new code could turn an unexpected error into a block, or a block into a pass. | medium | medium | Scope the fail-closed branch to resolution errors only. Add suite cases for both sides of the line. | open |
| R-012 | security | With `CLAUDE_PROJECT_DIR` unset and the working directory deleted, the nearest existing parent may be above the repo root. The gate then judges a `src/` write as outside the repo and allows it. | low | high | Req-004 checks `CLAUDE_PROJECT_DIR` first, then takes the nearest existing folder as the root and walks up from it to find a marker. If that folder holds no marker, it becomes the root. A resolution error on it, such as `EACCES`, blocks inside the root. A suite case covers a deleted cwd with no marker above it. | open |
| R-013 | operational | Downstream projects re-run six old migrations whose scans were written for older layouts. A scan reports false findings or fails. | medium | medium | P3 runs each scan in this repo first (req-010). The migrator presents findings and records nothing until the human on the loop confirms. A scan that can't run leaves the migration pending. | open |
| R-014 | operational | A record that can't be read counts as pending, so a damaged or hand-edited record makes the migrator rescan and possibly rewrite it. | low | low | A re-run gives the same result (idempotence). The migrator reports the unreadable record before it rescans. | open |
| R-015 | operational | Moving six files out of `_done/` breaks links and references to the old paths in docs, skills, and tests. | medium | low | Search the repo for `migrations/_done` before the move, update each reference, and add a suite check that `_done/` is absent. | open |
| R-016 | technical | The `product.yml` update moves ahead of the Step 6 archive. If the run stops between the update and the commit, `product.yml` names a release that never shipped. | low | medium | The update and the archive share one commit. A stale value stays until the next P7 corrects it, and a second run gives the same result. | open |
| R-017 | compliance | `product.yml` and `component.yml` versions drift, which breaks an `explicit` version policy. | low | medium | The close-out suite checks `product.yml` against the tag and feature. The ship agent checks `component.yml` at the same step. | open |
| R-018 | technical | `ratchet-check.mjs` takes on the `path-rules.mjs` import, so a fault in the shared rules now affects the ratchet as well as the write gates. | low | medium | The existing ratchet suite stays in place. Add subfolder cases. Keep the ratchet's own fail-open behaviour for unexpected errors. | open |
| R-019 | operational | The shell-write guard misses the scope record rule, so a shell write passes where **Write** is blocked, or the reverse. | medium | medium | Both hooks call the same function in `path-rules.mjs`. A suite runs the same cases through both. Hard Limit 8 still applies, and parser gaps are out of scope (0000119). | open |
| R-020 | security | The Hard Limit 8 carve-out lets `set-product-release.mjs` write a root file that no write gate judges. A wrong root or a crafted argument would then write past the gate. | low | high | Accepted with mitigation. The script validates every argument by pattern and length, and exits 2 on any break (req-008 Input Validation). `--root` must match the real path that `resolveRoot` returns. That can be a nested folder with its own `planifest-framework/`, which is the root `gate-write` already uses there. The single target is `{root}/product.yml`, and a real-path check refuses a link elsewhere. Values go in only as double-quoted scalars. The req-008 suite tests each rule, and the boot templates name the sanctioned scripts. | accepted |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | Claude Code passes `CLAUDE_PROJECT_DIR` to hooks. Backlog 0000118 has not checked this in a live session. | The deleted-cwd fix falls back to the nearest existing parent only (see R-012). | open |
| A-002 | The scans in the six older migrations still run against today's layout. | A scan reports false findings, and P3 brings them to the human on the loop (see R-013). | open |
| A-003 | No existing records need reading. `discovery.md` Record Samples reads None. | A hidden record format would conflict with the new `plan/_migrations/` layout. | open |
| A-004 | Hooks run on Node 18 or later, so `fs.realpathSync` and `fs.lstatSync` behave as the design expects. | Link resolution differs by platform, and the suites fail on one runner. | open |
| A-005 | Git state for the scope record can be read from `.git/HEAD`, loose refs, `commondir`, and `packed-refs` without a spawn. | A reftable repository can't use Fast Path writes, because the gate ignores the record and fails closed (see R-007). | open |
