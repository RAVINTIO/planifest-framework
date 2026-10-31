---
title: "Backlog Entry: 0000320 - agent identity and repository security settings"
summary: "Give the agent its own GitHub account, protect main with independent review and CI, turn on secret and code scanning, and have P0 check these under a regulated profile."
status: "open"
---
# Backlog Entry: 0000320 - agent identity and repository security settings

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000286, 0000280, 0000303, 0000295

---

## Problem

Today the agent commits and pushes under the developer's own GitHub account. An auditor can't tell agent work from human work. The same person can then raise and approve a change, which breaks separation of duties.

Framework also gives consumer repos no guidance on repository settings. A regulated repo needs branch protection, secret scanning, and code scanning. Nothing in Framework checks that a repo has them.

RAVINTIO Zero backlog 0000323 and Zero commit `8eac2f5` ("keep one approval and add an agent account") address the same gap.

## Suggested Action

- Give the agent its own GitHub account with the Write role. Commits and pull requests then name the agent as author.
- Protect `main` with branch protection or a ruleset:
  - required review by someone other than the author
  - required CI checks before merge
  - no direct pushes
- Turn on secret scanning, push protection, and code scanning rules.
- Under a regulated profile, have P0 check these settings with `gh api`. If a setting is missing, P0 names it and stops.
- Ship this as guidance for consumer repos, in `ravintio-framework/project-operations.md` or a new standard.
- Apply the same split to Atlassian (0000295). The agent uses its own Atlassian account, so Jira history shows which changes it made.

## Wanted outcome

- Every agent commit and pull request names the agent account.
- No one can merge their own pull request into `main`.
- Under a regulated profile, P0 reports each missing repository setting by name.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. Account setup is a human task, and the P0 check depends on the regulated profile work.
