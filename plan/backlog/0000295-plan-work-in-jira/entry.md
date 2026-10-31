---
title: "Backlog Entry: 0000295 - drive Framework from Jira through the Atlassian MCP"
summary: "Make Jira the source of truth for planning, with statuses that drive the phases. Jira is the first of the project management and issue tracking tools that will drive Framework."
status: "open"
---
# Backlog Entry: 0000295 - drive Framework from Jira through the Atlassian MCP

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-31

---

## Context

The human decided on 2026-10-31 that Framework will be driven by project management and issue tracking tools from now on. Jira is the first. Framework will never get initiatives, so this entry has no initiative mapping.

This entry moved from RAVINTIO Zero, where it was filed as Zero backlog entry 0000279 on 2026-10-31 and then removed. The human settled its design questions during that filing. This copy keeps those decisions and drops the parts that only applied to Zero's initiatives.

## Problem

Framework plans all work in files under `plan/`. Backlog entries live in `plan/backlog/`, and each run's brief, requirements, and design live in `plan/current/`.

A team that tracks work in Jira can't see or shape that plan where it already works. Framework has no link to Jira, and no skill reads from or writes to it.

## Suggested Action

- Add a setup flag, `--jira-planning`. With the flag, the skills plan in Jira. Without it, all work stays in `plan/` as it does today.
- Record the flag in `plan/state/{tool}.md` like any other setup flag, so `ravintio-refresh-setup` keeps it.
- Design the integration so another issue tracking tool can follow Jira behind the same config.
- Use Atlassian's official remote MCP server to read and write Jira issues. It signs in with OAuth, so no API token reaches the repo or the agent's context.
  - At pickup, confirm the server's current name, tools, and plan requirements before design, because Atlassian's MCP offering is new.
  - Community servers that take an API token may follow later, behind the same config.
- Never put Jira credentials in the repo or in context.

### Default Jira structure

| Framework record | Jira item |
|------------------|-----------|
| Feature, one PR and one release | Story |
| A group of related features | Epic, owned by the human. The skills read the Epic but don't create it. |
| The feature's user stories and requirements | Acceptance criteria on the Story |
| Code generation units | Sub-tasks, if wanted |
| Backlog entry | Story, Task, or Bug in the backlog. At pickup, it closes into the feature's Story or becomes it. |

The default needs no level above Epic, so it works on every Jira plan.

### Records in Jira and in the repo

- With the flag, Jira is the only source of truth for planning records. `plan/` keeps no copy of them, so nothing needs two-way sync.
- P0 writes the design as a draft User Story. Confirming the design moves the Story out of draft.
- At confirmation, `plan/current/design.md` becomes a brief summary. It holds the Story link and key, the feature id, the version, and the component fields that `gate-write`, `check-design`, and `shell-write-guard` read, in their current format. The rest of the design lives on the Story.
- Approvals stay in the repo, such as a migration proposal or an approved destructive schema change. A commit there goes through review, and a Jira field edit doesn't.
- ADRs, the build log, the archive, `docs/`, and the changelog stay in the repo. Each Story links to its feature's ADRs.

### Jira drives the phases

With the flag, Jira statuses replace the internal phase gates. The orchestrator picks up only issues in a ready status. When a phase group finishes, the agent moves the issue to the next ready status. A human can also move an issue into a ready status.

Default statuses:

| Jira status | Framework phases that pick it up | On finish, the agent moves it to |
|-------------|----------------------------------|----------------------------------|
| Ready to analyse | P0 Discovery | Ready to design |
| Ready to design | P1 Requirements and P2 Architecture Decisions | Ready to implement |
| Ready to implement | P3 Code Generation to P6 Documentation | Ready to ship |
| Ready to ship | P7 Archive to P9 Ship | Done |
| Any status | A stop | Blocked, with the stop message as a comment |

- **Gated runs:** the agent moves a finished issue to a review status, and a human moves it on to the next ready status. That move replaces the gate confirmation in chat.
- **Continuous runs:** the agent moves the issue to the next ready status itself.
- **Claiming:** on pickup, the agent assigns itself and moves the issue to an in-progress status, so two sessions can't take the same issue.
- **Order:** the orchestrator picks the highest-ranked ready issue.
- **Transitions:** a Jira workflow can forbid some moves. The config names the allowed transitions as well as the statuses. Setup checks that each one exists on the project.

### Configuration

- Keep the Jira config per repo, in a tracked file.
  - It names the Jira instance (site URL) and the space (project key) the repo works in.
  - It sets the issue types, statuses, and transitions for everyone. A team that wants another mapping changes it through a reviewed commit.
  - A developer's local, untracked file can override only fields that change no shared Jira data, such as the board or filter they view.
- Before every Jira read or write, the skills check that the MCP connection is on the tracked instance and the issue is in the tracked space. On a mismatch, the skill stops and names both values. It never writes to another instance or space.

## Wanted outcome

With `--jira-planning`, the human plans and tracks Framework work in Jira instead of in `plan/`. Tests check these conditions:

- Setup accepts `--jira-planning` and records it in `plan/state/{tool}.md`.
- Without the flag, Framework behaves as it does today.
- With the flag, P0 writes the design as a draft Story, and the feature's user stories and requirements become its acceptance criteria.
- With the flag, `design.md` holds only the summary fields, and `gate-write`, `check-design`, and `shell-write-guard` behave exactly as they do today.
- The orchestrator picks up only issues in a configured ready status, claims each one, and moves it to the configured next status when a phase group finishes.
- Setup fails when a configured status or transition is missing from the Jira project.
- The tracked config sets the mapping, and the default applies when it sets none.
- A local file can't change an issue type, status, transition, instance, or space.
- A Jira call on an instance or space other than the tracked ones stops with a message that names both values.
- ADRs stay in the repo, and each Story links to its feature's ADRs.
- No Jira credential appears in a tracked file.

## Why Deferred

The human asked for it on 2026-10-31. It sets the direction for Framework and needs its own design.
