---
title: "ADR 002: Fast Path scope record as self-authorisation with a visible trail"
summary: "A Fast Path change lists its target paths in plan/.fast-path-scope. Both write gates accept a valid, current record in place of design.md. The record is self-authorisation, so each admitted write prints a stderr notice and the changelog lists every path."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Fast Path scope record as self-authorisation with a visible trail

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

Fast Path is the route for a trivial change with no design (0000033 ADR 009). `gate-write` blocks any gated write when `plan/current/design.md` is absent. A Fast Path change outside `plan/` and `docs/` therefore has no sanctioned way through **Write** or **Edit**. Agents used shell workarounds or hand copies instead (backlog 0000081, 0000125, and 0000062).

At P0 the human on the loop chose a declared scope record over a wider allowlist. The agent that makes the change also writes the record. No human step sits between the two. The P1 design critic asked for a real control or an accepted-risk entry, and the run took both (risk R-005 and R-006).

req-001 holds the record format, staleness, and the workflow step.

The design names data ownership: the Fast Path workflow owns `plan/.fast-path-scope`. `gate-write` and the shell-write guard read it.

## Decision

- **Location:** The record lives at `plan/.fast-path-scope`. The `plan/` prefix is always permitted, so the agent writes it with **Write**.
- **Format:** Line-based UTF-8 text with a fixed order:
  1. `branch: <name>`
  2. `head: <commit>`
  3. `paths:`
  4. one `- <path>` line per target, at least one
- **Path entries:** Each entry is an exact root-relative path or a folder prefix. The record has no glob syntax. Matching uses whole segments and the 0000009 ADR 005 normalisation, as `matchesComponentPath` does.
- **Whole-record rejection:** The record is untrusted input. It is capped at 16 KiB and 64 paths, and each field has a character pattern and a length cap. Any rule break makes the whole record invalid. The gate never repairs a record. An invalid record admits nothing.
- **Gate placement:** `evaluateWrite` reads the record only when `design.md` is absent, after the `plan/current/**` sentinel check. A design always wins over a record.
- **Verdicts:** A valid, current record admits a matching path and blocks every other gated path with exit 2. The block reason names the record and offers the Change Pipeline.
- **Shared rule:** The shell-write guard honours the record through `evaluateWrite` (ADR-001). It holds no copy of the rule.
- **Self-authorisation accepted:** The design records the residual risk as accepted at P0. The run adds two visibility controls:
  - Each admitted write prints one stderr line that names the record and the resolved path, cut to 200 characters. The hook still exits 0.
  - Fast Path step 5 writes a changelog entry that lists every record path. The human on the loop sees the admitted paths there, because Claude Code keeps exit-0 hook output out of the main view.
- **Life of the record:** Fast Path writes a new record before the first change and overwrites any old one. Step 6 removes it with `rm -f` before `git commit`, so no commit holds it. The root `.gitignore` lists it as a second guard. Staleness is bounded by branch and `HEAD` (ADR-003).
- **Limits on what it admits:** A record never admits an enforcement path (ADR-004).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Widen the always-permitted list for Fast Path targets | No new file or parser | Admits writes for every session, not one change. The scope puts any always-permitted change out of scope. | The human on the loop chose the scope record at P0 |
| Require a human to write or sign the record | A real separation of duties | Fast Path stops being fast. An `autonomous` run can't use it at all. | Rejected at P0 in favour of self-authorisation plus visibility |
| A YAML or JSON record | Familiar formats | Needs a parser that Node built-ins don't supply for YAML. JSON permits nesting and types the gate must then reject. | A fixed line grammar lets the gate reject a malformed record whole |
| Glob patterns in path entries | Shorter records | One broad glob admits far more than the change needs (risk R-006). Glob semantics differ by tool. | Exact paths and folder prefixes are enough for a trivial change |
| Delete the record in the Fast Path commit | Matches the brief's wording | The record enters history for one commit. A mid-change `git add -A` can carry it into an earlier commit. | Removing it before `git commit`, plus `.gitignore`, keeps it out of every commit |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `path-rules.mjs` gains the record parser and the admit step in `evaluateWrite`. Both write gates print the notice. `workflows/fast-path.md` gains the record step, the changelog field, and the removal in step 6. The root `.gitignore` gains one line. |

## Consequences

**Positive:**
- A Fast Path change goes through **Write** and **Edit** with no shell workaround, so Hard Limit 8 holds on that route.
- Every admitted path appears in the transcript and in the changelog entry.

**Negative:**
- The record is self-authorisation. An agent can list any non-enforcement path and the gate admits it.
- The changelog shows the admitted paths only after the change. Nothing stops a write before the human on the loop reviews.

**Risks:**
- An agent lists a folder such as `src/` and makes changes wider than Fast Path allows. The changelog list and the stderr notice make this visible, and review at the PR remains the backstop (R-006).
- An agent skips step 5, so the changelog lacks the paths. The stderr notice still records each write in the transcript.

## Related ADRs

- ADR-001 - depends-on. The rule lives in `path-rules.mjs` with no spawn.
- ADR-003 - extends. It bounds the record's staleness.
- ADR-004 - depends-on. It sets the paths the record can never admit.
- ADR-005 - depends-on. The gate matches the record against the resolved `relPath`.
- 0000033 ADR 009 (Fast Path admits no `src/` changes) - related-to. Fast Path still admits changes with no `src/` target.
- 0000009 ADR 005 (path normalisation) - depends-on

## Supersedes

- None

## Superseded By

- None
