---
stream-id: "{{stream-nn-slug}}"
kind: stream
start-commit: "{{HEAD commit when the stream starts}}"
status: active
phase: P1
requirements: [{{req-NNN, req-NNN}}]
stories: [{{US-NNN, US-NNN}}]
id-blocks: "{{req-NNN to req-NNN, ADR-NNN to ADR-NNN, backlog NNNNNNN to NNNNNNN}}"
updated: "{{ISO-8601 UTC}}"
---
# Stream State: {{stream-id}}

> Path: `plan/current/streams/stream-{nn}-{slug}.md`. The orchestrator writes and
> commits this file when the stream starts, at every phase change, and at every
> join (0000033 ADR-013). Resume Detection step 6b reads it. Stream mechanics:
> `standards/agent-dispatch-standards.md` `## Parallel Streams`.
>
> `status` is `active`, `at-join`, `blocked`, or `done`. `phase` is `P1` to `P4`.

## Phase history

| Phase | Start | End | Subagents | Result |
|-------|-------|-----|-----------|--------|
| {{P1}} | {{ISO-8601 UTC}} | {{ISO-8601 UTC}} | {{n}} | {{at-join \| blocked: reason}} |

## Files changed

- {{path changed by this stream's commits}}

## Declares

Each artifact this stream produced for another unit to use. The consumer is a
stream ID or a requirement ID. See `## Joins and Reconciliation` in
`standards/agent-dispatch-standards.md`.

| Artifact ID | Defined in | Consumer |
|-------------|------------|----------|
| {{distinctive-artifact-id}} | {{path}} | {{stream-id \| req-NNN}} |

## Consumes

Each artifact from another unit that this stream used, by artifact ID.

- {{distinctive-artifact-id}}

## Next step

{{The next action for this stream, precise enough to resume from a fresh session.}}
