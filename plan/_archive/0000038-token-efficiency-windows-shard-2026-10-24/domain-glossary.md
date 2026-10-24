---
title: "Domain Glossary - token efficiency and Windows shard fix"
summary: "Terms used by feature 0000038."
status: "active"
version: "0.1.0"
---
# Domain Glossary - token efficiency and Windows shard fix

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Version:** 0.36.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Warm-up call | One untimed hook call before the timed call. It warms disk caches and leaves the Node process fresh each time | none | planifest-framework |
| Timed call | The single hook call that must finish under 200 ms. It never retries | none | planifest-framework |
| Quiet mode | The `run-tests.sh --quiet` mode. It prints only `FAIL` lines, the failed-suite list, and the totals | none | planifest-framework |
| Failed-suite list | The list of suites that exited non-zero, including those with no `FAIL` line | none | planifest-framework |
| Tier | The class of model a task type needs. Primary or cheaper | model tier | planifest-framework |
| Accepted model value | One of `sonnet`, `opus`, `haiku`, or `fable`, the values the Claude Code Agent tool accepts | none | planifest-framework |
| Dispatch skeleton | The `Agent({...})` example in the agent dispatch standard | Agent Dispatch Template | planifest-framework |
| Size floor | The rule that a subagent runs only for a unit that needs its own reads or many tool calls | none | planifest-framework, planifest-overrides |
| Reference file | A file that holds moved orchestrator text. The orchestrator loads it on demand | none | planifest-framework |
| Phase gate | The check that ends a pipeline phase | gate | planifest-framework |
| Reset prompt | The advisory prompt to run `/compact` or open a new session after a passed gate | none | planifest-framework |
| Resume state | `plan/current/` and the build log, which let a new session carry on | none | planifest-framework |
| Context tokens per request | Tokens a request carries as input, including cache reads and writes. The 0000230 baseline median is 94,713 | none | planifest-framework |
| Human on the loop | The person who reviews and merges. Use this term in place of "user" or "developer" | none | planifest-framework |
