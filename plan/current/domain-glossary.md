---
title: "Domain Glossary - Human-on-the-loop run mode"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - Human-on-the-loop run mode

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Version:** 0.32.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Human on the loop | The person who sets intent at P0, reviews the result after P9, and merges. In `autonomous`, no gate waits for them unless an item is on the exception list. | human in the loop (the older, narrower role) | planifest-framework |
| Run mode | The value in `plan/.run-mode` that says how much of the run waits for the human. It is `interactive`, `continuous`, or `autonomous`. Unknown values read as `interactive`. | | planifest-framework |
| `interactive` | The default run mode. Every phase gate waits for the human. Behaviour is unchanged by this feature. | | planifest-framework |
| `continuous` | The run mode that skips the per-phase confirmation at P1 to P6. Other stops remain. Behaviour is unchanged by this feature. | | planifest-framework |
| `autonomous` | The new run mode. The run goes from confirmed design to a raised PR, and only exception-list items wait. An older framework reads it as `interactive`. | | planifest-framework |
| Exception list | The items that wait for the human in `autonomous`: schema and destructive changes, a gross deviation, human review of the running result, promotion beyond the candidate environment, a human-only input, and an exhausted budget. A product can add items in an override. | exception-list item | planifest-framework |
| Gross deviation | A change the reversal protocol would class as altering. It changes the confirmed problem, users, or in-scope list. | | planifest-framework |
| Approach | One distinct attempt at clearing a gate. When a cap is reached, the run tries a different approach, up to 3 per gate. The fourth becomes an exception. | | planifest-framework |
| Fresh-context checker | A REJECT-default subagent with no memory of the work. It stands in for the human at a phase gate in `autonomous`. | verifier | planifest-framework |
| Gate as a loop | A phase gate run under `planifest-loop-runner` with a fresh-context checker, instead of a human confirmation. | | planifest-framework |
| Reversal budget | The count of governed reversals of an upstream artifact. It stays at 2. | | planifest-framework |
| Final report | The one report at the end of P9. It lists what shipped, every decision and deviation, the version, the PR and its CI result, and every exception waiting. | | planifest-framework |
| Touchpoint | A point where a run waits for the human. The build log counts them, and the P8 report flags any outside the exception list. | human touchpoint | planifest-framework |
| Real fork | A P0 question whose answer needs the human's judgement or changes what gets built. P0 asks only these. | | planifest-framework |
| Derivable item | A P0 item the orchestrator can work out, such as adoption mode, version, stack, NFRs, risks, the component split, or the feature ID. It goes into the design draft for one confirmation. | | planifest-framework |
| Record sampling | The discovery step that reads recent rows when a design depends on existing records. It states how often each relied-on value is usable. | sample existing records | planifest-framework |
| Release budget | The `planifest-overrides/release-budget.yml` file. It holds a target and a ceiling in size points for one release. | | planifest-framework |
| Size points | The unit of release sizing. Small is 1, medium is 2, and large is 3. | | planifest-framework |
| Stream | One independent requirement moving through P1 to P4 as its own subagent track, with a state file under `plan/current/streams/`. | parallel stream | planifest-framework |
| `parallel_streams` | The loop toggle that turns streams on. It defaults to `on` in `autonomous` and `off` otherwise. | | planifest-framework |
| Join | A point where streams or batches meet again. The orchestrator owns every join. | | planifest-framework |
| Join owner | The orchestrator, in its role as the single owner of every join. | | planifest-framework |
| Reconciliation | The check after each join that a stream or a requirement consumes every artifact another stream declares. | | planifest-framework |
| Close-out | The P7 to P9 sequence that archives the run, writes the report, tags, and ends with a clean working tree. | | planifest-framework |
| Archive script | `scripts/archive-current.mjs`. It moves tracked items with `git mv`, removes markers by explicit path, and prints what it moved. | | planifest-framework |
| Lightweight track | The route for a change with no `src/` component. It is Fast Path with its prerequisite relaxed and its four criteria kept. | | planifest-framework |
| Candidate environment | The environment P9 deploys to. Promotion beyond it is an exception-list item. | | planifest-framework |
