---
title: "Backlog Entry: 0000289 - a tamper-evident audit trail"
summary: "Make the build log, approvals, and evidence records provable after the fact, with a hash chain or signed commits, and label each record by who produced it."
status: "open"
---
# Backlog Entry: 0000289 - a tamper-evident audit trail

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

`plan/current/build-log.md` is plain Markdown that any agent can rewrite. Git history helps, but a branch can be rebased or squashed before review. Several entries show records that agents wrote or changed with no control to catch it:

- 0000227: an agent estimated loop-state timestamps.
- 0000141: an agent can write a migration record that stops a needed migration.
- 0000225 and 0000238: subagents changed files through Bash, past Hard Limit 8.

The strategy asks for tamper-evident or attributable evidence. It also asks the trust model to tell apart four kinds of record: agent narrative, tool measurements, source-system records, and human decisions.

## Suggested Action

- Label every build-log and evidence record with its kind: `agent`, `tool`, `source-system`, or `human`.
- Chain records by hash, so a later edit breaks the chain. A script checks the chain at each gate and at P7.
- Take timestamps only from the system clock or the source system, never from an agent.
- Support signed commits and tags, with verification at P9, when policy turns it on.
- Record each blocked or detected bypass of Hard Limit 8. This gives the detective control that 0000119 may need.

## Wanted outcome

An auditor can check that the archived build log and evidence weren't changed after the run. A test proves the chain check fails when someone edits an earlier record.

## Why Deferred

Filed from the 0000279 differentiation review. It needs an ADR on hash chain against signing. It also links to 0000119.
