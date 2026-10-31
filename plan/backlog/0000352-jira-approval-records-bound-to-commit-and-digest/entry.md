---
title: "Backlog Entry: 0000352 - Jira approval records bound to commit and digest"
summary: "Take gate approvals from Jira's changelog, bind each one to a commit SHA and artefact digests, and write the record to plan/current/approvals/."
status: "open"
---
# Backlog Entry: 0000352 - Jira approval records bound to commit and digest

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline. Needs an ADR. Sits under 0000286.
**Related:** 0000286, 0000289, 0000295

---

## Problem

The agent writes every `Gate accepted: P{N}` line in the build log. The line names no approver, and nothing binds it to the artefacts the approver saw. Entry 0000286 asks for approvals from a source the agent can't forge. With `--jira-planning` (0000295), Jira can be that source.

## Suggested Action

1. Before it moves an issue to a review status, the agent commits and pushes the phase artefacts.
2. The agent posts an approval request comment on the Story. The comment names these values:
   - the commit SHA
   - each artefact path with its SHA-256
   - one manifest digest over all of them
3. A human moves the issue on. Jira's changelog records the approver accountId and the time, and users can't edit it.
4. The agent reads the changelog through the MCP server. It writes `plan/current/approvals/P{N}.md` with these fields:
   - approver accountId and name
   - time and transition ID
   - Story key
   - commit SHA and manifest digest
5. That record replaces the agent-written `Gate accepted: P{N}` line.
6. Each later gate re-reads the artefacts and hashes them again. A mismatch needs fresh approval.
7. P7 exports the approval records into the archive.

Enforce human-only moves in Jira itself:

- Add a workflow condition that limits review transitions to an approvers group. The group excludes the agent account.
- Add a validator that rejects an approver who is the Story's maker.

Schema and destructive approvals stay in the repo, under Hard Limits 3 and 4.

## Wanted outcome

Every gate approval traces to a Jira changelog entry by a named human, bound to one commit and digest. Tests check these conditions:

- A gate fails when an artefact's hash no longer matches its approval record.
- An approval record from the agent account fails the gate.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It needs an ADR on approval identity and depends on 0000295.
