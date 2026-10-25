---
title: "ADR 008: One scripted rename pass"
summary: "0000039 renames about 590 files and 1,190 paths in one scripted P3 pass. It is a recorded exception to Hard Limit 8. The script lives in the scratchpad, runs once, and lands in one commit."
status: "accepted"
version: "0.1.0"
---
# ADR-008 - One scripted rename pass

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework
**Date:** 2026-10-25

## Context

The rename touches about 590 files and 1,190 paths. Hard Limit 8 says every change to code and project files goes through **Write** or **Edit**. It bars `sed -i`, `cp`, scripts, and interpreter one-liners.

An Edit-only rename at this size has costs. Each file needs a read and at least one edit. Subagents would carry the work in parallel, and each would see only its own slice of the protected list.

The pass also carries three risks:

- The run renames its own skills and hooks while it runs.
- Some old names are split or built at run time, and a blanket replace corrupts them.
- The `setup.sh` heredoc holds mojibake lines that need byte-exact edits.

The human on the loop approved a scripted pass at P0 on 2026-10-25.

## Decision

Run one scripted pass in P3. Record it as an exception to Hard Limit 8. The run doesn't stop for approval, because the human on the loop gave it at P0.

1. **Write** creates the script in the session scratchpad. The script never enters the repo.
2. The script runs `git mv` for every path first. Then it runs a content replace that skips the req-005 protected list.
3. On the `setup.sh` mojibake lines, the script edits bytes exactly. It replaces only the old word and leaves every other byte as it is.
4. The script runs once, and only after two conditions hold:
   - The req-005 protected-name tests and the req-007 guard exist and fail as expected.
   - A dry run in a scratch clone confirms that git detects the moves as renames, as req-001 requires.
5. The pass output, the `setup.sh claude-code` re-run, and the build-log update land in one commit. A resumed session then sees all old names or all new names, never a mix.
6. Every follow-up fix uses **Edit**.

Decision (P2): one scripted pass in the scratchpad, run once, one commit / reason: it is the only method that keeps the protected list in one place and keeps the rename atomic.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Edit only, fanned out to subagents (about 590 files, 1,190 paths) | Keeps Hard Limit 8 with no exception | Very high token cost. Each subagent applies the protected list on its own, so one miss corrupts a split name. Path moves still need a shell. Skills change name mid-run across parallel workers | The cost is high and the protected list gets applied inconsistently. Only the script applies it once |
| Two commits, paths first and then content | Smaller diffs. Git rename detection sees pure moves | A resumed session between the commits sees new paths with old content, so skills and hooks fail to load | A half-renamed tree breaks the run's own tooling. One commit avoids that state |
| Rename in place with a sanctioned framework script | Stays inside the Hard Limit 8 allowlist | The allowlist is a fixed list of scripts. Adding a rename script to it widens a standing rule for a one-off job. The script would ship to every consumer | A one-off job should not become a permanent sanctioned script |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Receives the whole rename in one commit. Hard Limit 8 carries a recorded exception for this feature only |

## Consequences

**Positive:**
- The protected list gets applied identically to every file.
- The tree is never half renamed in a commit, so a resumed session loads working skills and hooks.
- The scratchpad script leaves no sanctioned rename tool in the pack.

**Negative:**
- A script breach of Hard Limit 8 sets a precedent. The human on the loop must treat it as one-off and not copy it.
- The shell guard cannot see inside the script. Review relies on the dry run and the post-pass tests.
- The single commit is large. The human on the loop reviews a diff of about 590 files.

**Risks:**
- A defect in the script corrupts many files at once. The dry run in a scratch clone and the failing-first tests catch this before the real run. Revert is one commit.
- The script misses a split or built name. The req-007 guard fails on any leftover hit, and the fix goes through **Edit**.
- A mojibake line changes beyond the old word. The req-005 suite counts those lines before and after and expects the same number.

## Related ADRs

- ADR-007 - depends-on (the guard must exist and fail before the pass runs)
- ADR-009 - related-to (the pass skips the history paths that ADR-009 protects)
- ADR-002 - related-to (the pass applies the rename map)

## Supersedes

- None.

## Superseded By

- None.
