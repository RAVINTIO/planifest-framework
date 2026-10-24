---
title: "ADR 005: GUTD reads the last merged PR's checks and keeps pull_request only"
summary: "GUTD gains a read-only step 5 that picks the merged PR with the newest mergedAt and reads its checks without waiting. The workflow keeps its pull_request trigger."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - GUTD reads the last merged PR's checks and keeps pull_request only

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

GUTD checks out `main`, pulls, and reports untracked files. After PR #62 merged red, nothing in GUTD showed it.

CI runs on `pull_request` only (0000031 ADR 003). No `main` run exists, so a `gh run list --branch main` call returns nothing useful. `gh pr list` sorts by creation date, so the first entry is not always the last merged.

## Decision

`planifest-overrides/instructions/custom-003-git-up-to-date-shorthand.md` gains step 5, after the untracked-files report.

- It runs `gh pr list --state merged --base main --limit 10 --json number,url,title,mergedAt` and picks the entry with the newest `mergedAt`.
- It reads that PR's checks with `gh pr checks {number} --json name,bucket,link`. It judges from the JSON and uses the bucket mapping from ADR-002.
- It is read-only and does not wait. A pending check reads `pending`.
- The report says "the last merged PR's checks" with the PR number and URL. It never says "main is green" or "main is red".
- With no merged PR, it reports "no merged PR to check". With `gh` missing, signed out, or invalid JSON, it reports "CI status could not be read" and names `gh auth login`.
- Steps 1 to 4 do not change. A red or unreadable check does not undo the pull.

The workflow trigger stays `pull_request` only. This keeps 0000031 ADR 003.

## Amended (P5)

The lookup requests `--json number,url,mergedAt` and no `title`. GUTD never reads a PR title, so the override asks for none. The decision text above stays for history.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add a `push` trigger on `main` and read the `main` run | The report could say "main is green" | Reverses 0000031 ADR 003, doubles CI minutes, and adds a Windows run per merge | The decision is not this feature's to reverse |
| Read `gh run list --branch main` with no trigger change | No workflow edit | Returns no run, so the report is always unknown | Gives no signal |
| Wait for pending checks in GUTD | Fewer pending results | GUTD is a quick sync check | The wait defeats its purpose |
| Take the first entry of the merged list | Shorter step | The list sorts by creation date, so it can pick the wrong PR | Newest `mergedAt` is correct |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The GUTD override gains step 5. The generated `CLAUDE.md` copy refreshes on a setup re-run. |

## Consequences

**Positive:**
- A red merged PR shows the next time the human on the loop sends GUTD.
- The workflow and its CI cost stay unchanged.

**Negative:**
- The report covers the PR's run, not the merge commit on `main`. A merge conflict resolution that breaks `main` goes unseen.
- GUTD needs `gh` signed in to give a result.

**Risks:**
- A future `push` trigger makes the lookup redundant but not wrong. The design records this assumption.
- If the 10 entry limit misses a late-merged older PR, the report names the wrong PR. The limit is large enough for normal use.

## Related ADRs

- ADR-002 - depends-on (bucket mapping)
- 0000031 ADR 003 - depends-on (`pull_request` only)

## Governs

req-002

## Supersedes

- None

## Superseded By

- None
