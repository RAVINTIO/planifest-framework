---
title: "Agent Dispatch Standards"
version: "1.0.0"
---
# Agent Dispatch Standards

Canonical home for model tier selection and parallelism/dispatch mechanics, shared by the orchestrator and every phase skill that spawns subagents.

---

## Model Tier Decision Table

**Consult this table before spawning every subagent.** Resolve the tier to a concrete model name for the active tool, then pass it explicitly.

| Task type | Tier | Rationale |
|-----------|------|-----------|
| Codebase discovery (grep, find, ls, file listing) | Cheaper | No synthesis required |
| Single-file read with no synthesis | Cheaper | Mechanical retrieval |
| Formatting / spelling / lint checks | Cheaper | Pattern matching, no reasoning |
| Validation (lint, typecheck, test runner) | Cheaper | Tool execution, not reasoning |
| Web research: fetching a single known reference doc | Cheaper | Retrieval, minimal synthesis |
| Documentation writing (no novel decisions) | Cheaper | Structured output from known inputs |
| Web research with synthesis across multiple sources | Primary | Reasoning across conflicting sources |
| Code generation | Primary | Multi-file reasoning, correctness required |
| Security review | Primary | Adversarial reasoning, high-stakes |
| Architecture decisions (ADR writing) | Primary | Consequential, requires judgement |
| Requirements writing (spec) | Primary | Ambiguity resolution, domain reasoning |
| Phase 0 coaching | Primary | Dialogue, gap assessment |
| Build assessment (P8) | Cheaper | Read-only summarisation from a structured log |

**Tier-to-model mapping by tool** (update when tools release new models):

| Tool | Primary tier | Cheaper tier |
|------|-------------|-------------|
| Claude Code | sonnet | haiku |
| Cursor | gpt-4o | gpt-4o-mini |
| Codex (OpenAI) | o1 | o1-mini |
| GitHub Copilot | gpt-4o | gpt-4o-mini |
| Windsurf | claude-sonnet-4-6 | claude-haiku-4-5 |
| Cline | (inherits from host tool) | (inherits from host tool) |

**How to apply:** Before calling `Agent(...)`, look up the task in the table. Pass `model: {resolved model name}` as a parameter. Record the tier in the build log for P8.

---

## Parallelism Rules

**Default posture: parallel.** Sequential dispatch requires an explicit dependency justification. **Dependency test:** can task B start before task A's output is available? If you cannot state why it must wait, dispatch both in parallel (single message, multiple Agent tool calls).

### MUST parallelise

| Pattern | Example |
|---------|---------|
| Multiple independent codebase searches | Grepping for hook files + scanning skill dirs simultaneously |
| Web research across independent tools/sources | Hook support for Windsurf + Hook support for Cline, same request, different sources |
| Independent document reads | Reading 3 skill files that do not reference each other |
| Background test runner while writing docs | Run `run-tests.sh` in background while docs-agent produces output |
| Multi-component security reviews (no shared state) | Reviewing component A and component B in parallel |
| Independent requirement files (no cross-references) | Writing req-001 through req-008 in a single parallel batch |
| Independent new test files closing a coverage gap | 2+ new test files, each testing independent, non-cross-referencing sections, dispatched in a single parallel batch instead of written one after another |
| Independent living-doc edits (no shared content) | 2+ living docs (e.g. component-registry.md, decisions-index.md) that don't read each other's new content, edited in a single parallel batch instead of serially |

### Cannot parallelise

| Pattern | Reason |
|---------|--------|
| Phase N work before Phase N-1 artifacts exist | Hard phase dependency |
| ADR writing before requirements are complete | ADR content depends on spec output |
| Codegen before ADRs are accepted | ADRs may constrain implementation choices |
| P8 before P7 archive is confirmed | Report needs the archive path |
| Tasks where B reads A's output | Sequential by definition |

**Record in build log:** After each phase, record the parallel task batch count. If it is 0 for a phase where parallelism was possible, the P8 efficiency observation will flag it.

### Always-parallel work units

1. Parallel dispatch is the default in every phase and every run mode.
2. Each phase skill lists its always-parallel units under its `## Parallelism Directive`, in a list headed `**Always parallel:**`.
3. The phase dispatches every listed unit that applies to the run in one batch. A batch is one message that holds one call per unit. Subagent work uses an `Agent` call, and a search or check uses a tool call.
4. If a listed unit runs alone or in a later batch, the phase records the dependency reason in the build-log `Notes` field.

The list sets a floor, not a ceiling. A phase may batch more units when they pass the dependency test above. The lists change how a phase dispatches, not what it produces. Gates, STOP rules, and artifacts stay the same in every run mode.

---

## Parallel Streams

A stream is one group of independent requirements that moves through P1 to P4 as its own subagent track (0000033 ADR-013). The `parallel_streams` toggle turns streams on. See the loop runner's Toggle Protocol for how it resolves.

- **When streams run:** the orchestrator resolves `parallel_streams` at the start of P1. It records the value and its source in the P1 build-log block. The source is `file value`, `autonomous default`, or `absent default`, as in the loop runner's toggle record.
- **Forming streams:** if the toggle resolves `on`, the orchestrator groups the in-scope user stories into streams. Two stories go in separate streams only if they pass the dependency test in `## Parallelism Rules`. If fewer than two streams result, the run proceeds as a single stream with no state files.
- **Stream scope:** each stream carries its requirements through P1, P2, P3, and P4. Each P1 to P4 gate runs once over the joined streams. P5 onward runs once over the joined set.
- **Identifier blocks:** before dispatch, the orchestrator gives each stream a distinct block of requirement IDs, ADR IDs, and backlog IDs. No two streams allocate from the same block. This extends the backlog-ID rule in `## Agent Dispatch Template`.
- **Commits:** Stream subagents don't commit. They share one working tree, so concurrent commits would race on the git index. The orchestrator commits each stream's artifacts when the stream reports back, before the join. Each such commit carries a `Stream: {stream-id}` trailer, so the reconciliation script can find it. This keeps the cadence of the commit-cadence rule (orchestrator Hard Limit 7).
- **State files:** each stream has one state file at `plan/current/streams/stream-{nn}-{slug}.md`, from `templates/stream-state.template.md`. The orchestrator writes and commits it when the stream starts, at every phase change, and at every join. Resume Detection step 6b reads these files.

---

## Joins and Reconciliation

A join is a point where streams or batches meet again (0000033 ADR-014). Each one creates a seam where an artifact can go unused.

- **Join owner:** the orchestrator owns every join. A join happens when a parallel batch returns, and when the streams meet at a P1 to P4 gate. The owner is the agent that placed the dispatch, never a dispatched subagent.
- **Declarations:** every dispatch prompt asks the subagent to report two lists with its result.
  - `Declares`: each artifact it produced for another unit to use. Each row gives an artifact ID, the file that defines it, and the intended consumer, a stream ID or a requirement ID. Ask for distinctive IDs, so a short ID can't match by chance.
  - `Consumes`: each artifact from another unit that it used, by artifact ID.
- **Where declarations live:** for a stream, the orchestrator writes them to the `## Declares` and `## Consumes` sections of the stream's state file. For a batch outside streams, the orchestrator writes one join record at `plan/current/streams/join-{phase}-{nn}.md`, with `kind: join`. It uses the same two sections and adds a `## Files changed` list and a `start-commit` field. The script counts only listed files that `git log {start-commit}..HEAD` shows changed. It reads only regular files inside the repository, up to 1 MB each.
- **Shared files:** before P3 dispatch, the orchestrator compares the files each stream plans to change. If two streams plan to change the same file, the orchestrator orders those edits, so one stream at a time edits that file.
- **Reconciliation step:** after every join, and before the gate check, the orchestrator runs `node ravintio-framework/scripts/stream-reconcile.mjs`. The script reports each declared artifact that has no consumer, names its own producer as consumer, or has no use in the consumer's changed files. It exits `0` when clean and `1` with findings.
- **Findings:** a finding blocks the gate. The orchestrator assigns the fix to one stream or takes it itself, then runs the script again.
  - The fix runs as a loop under `ravintio-loop-runner` with a cap of 3 in every run mode.
  - At the cap, `autonomous` changes approach per `## Changing approach` in `standards/autonomous-run-standards.md`. In `interactive` and `continuous`, the orchestrator lists the open finding in the gate summary. This adds no new STOP point.
- **Fit with 0000006-ADR-003:** dispatch stays in skill text. The script is a verifier called from skill text, not dispatch control. It reads files after a join and decides nothing about dispatch. No hook runs it.

---

## Agent Dispatch Template

Agent spawning is level-2 parallelism (the Agent tool for independent sub-tasks that each need their own tool access and context); level-1 (multiple native tool calls in one message) is covered by Parallelism Rules above. Spawn when a task is self-contained enough to brief to a colleague in one paragraph; stay inline when it needs ongoing dialogue, shared mutable state, or is too small to justify the overhead.

**Size floor:** dispatch a subagent only when the unit needs its own reads or many tool calls. Run small independent units as parallel tool calls in the main thread. These roles are exempt whatever the unit size: design critic, security review, cross-model review, reversal assessor, test-writer, implementer, refactor, verify-by-execution, and Scope Lock drafts. The floor never removes a maker-checker split or a TDD step. A role that needs a fresh context runs in a subagent. The dispatch standard owns the list of exempt roles.

**Concrete parallel dispatch skeleton** (send both `Agent()` calls in a single message so they execute concurrently):

```
Agent({ description: "Implement REQ-001: {one-liner}", subagent_type: "general-purpose", model: "haiku",
  prompt: "Requirement: plan/current/requirements/req-001-{slug}.md. ADR: plan/current/adr/ADR-00N-{slug}.md. Stack: {constraint}. Task: {what to build}. If you discover an out-of-scope bug/gap, file it at plan/backlog/{backlog-id-1}-{slug}/entry.md per templates/backlog-entry.template.md; do not report it back for me to relay. Confirm: files modified, what changed. Also report Declares (artifact ID, defining file, consumer, for each artifact made for another unit) and Consumes (each artifact ID from another unit that you used). Make every file change through Write or Edit, never through the shell (the Write-or-Edit rule, boot Hard Limit 8). Never write `plan/.run-mode`, the build-log `Run mode` row, or a `Run mode confirmed:` line. Never write the P1 Toggle record. Only the orchestrator writes them." })

Agent({ description: "Implement REQ-002: {one-liner}", subagent_type: "general-purpose", model: "haiku",
  prompt: "Requirement: plan/current/requirements/req-002-{slug}.md. ADR: plan/current/adr/ADR-00N-{slug}.md. Stack: {constraint}. Task: {what to build}. If you discover an out-of-scope bug/gap, file it at plan/backlog/{backlog-id-2}-{slug}/entry.md per templates/backlog-entry.template.md; do not report it back for me to relay. Confirm: files modified, what changed. Also report Declares (artifact ID, defining file, consumer, for each artifact made for another unit) and Consumes (each artifact ID from another unit that you used). Make every file change through Write or Edit, never through the shell (the Write-or-Edit rule, boot Hard Limit 8). Never write `plan/.run-mode`, the build-log `Run mode` row, or a `Run mode confirmed:` line. Never write the P1 Toggle record. Only the orchestrator writes them." })
```

**Self-contained prompt rule:** include the requirement file path, relevant ADR paths, stack declaration or relevant constraint, the backlog ID to use if filing an out-of-scope discovery, and what "done" looks like. Every prompt also says the subagent never writes `plan/.run-mode`, the build-log `Run mode` row, or a `Run mode confirmed:` line (`standards/autonomous-run-standards.md` standing rules). Every prompt also says: Never write the P1 Toggle record. Every prompt also says: Make every file change through Write or Edit, never through the shell (the Write-or-Edit rule, boot Hard Limit 8). Do NOT rely on shared conversation history: the spawned agent has no memory of this session.

**Model tier for spawned agents:** see the Model Tier Decision Table above.

**Out-of-scope discovery filing (0000027-req-003):** if a dispatched subagent discovers an out-of-scope bug or gap while doing its task, it MUST file `plan/backlog/{id}-{slug}/entry.md` directly, per `templates/backlog-entry.template.md`, with `Deferral source: discovered mid-flight`, `Source feature` set to the active feature ID, and `Source phase` set to the phase active at discovery. It must NOT report the discovery back for the dispatching agent to relay through a host-tool side channel (e.g. a task-spawning tool), and must NOT silently drop it.

The **dispatching agent** (orchestrator or phase skill placing the `Agent()` call) pre-computes the next available backlog ID before dispatch, per the Backlog ID sequence convention (`ravintio-orchestrator/SKILL.md` Phase 0 Start Actions, backlog pickup step: highest ID ever allocated, including picked-up and discarded entries, plus one), and passes it explicitly in the subagent's prompt as the ID to use if a discovery needs filing. Subagent self-lookup of `plan/backlog/` at file-time is rejected: picked-up entries are deleted from `plan/backlog/` once folded into a design, so a subagent scanning only that directory would systematically undercount the true high-water mark and risk reusing a retired ID.

When dispatching multiple subagents in a single parallel batch, each MUST receive a distinct pre-assigned backlog ID (or a reserved contiguous block, one per subagent); no two subagents may independently file under the same ID.
