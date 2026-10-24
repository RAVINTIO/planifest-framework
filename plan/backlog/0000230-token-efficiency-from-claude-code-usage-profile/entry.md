---
title: "Backlog Entry: 0000230 - token efficiency from a Claude Code usage profile"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000230 - token efficiency from a Claude Code usage profile

**Source feature:** rapid-prototypes `0000008-claude-usage-observability` (usage analysis of this repo)
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Context, not output, drives most of this repo's Claude Code usage. Cache reads and cache writes take about 76% of the estimated cost. Most of that context comes from subagents running on Opus, large Bash results, and long sessions.

The human is on a Max plan with weekly and 5-hour limits. Cost below is an API-equivalent estimate, so it measures allowance used, not money charged.

### Measured evidence

Source: Claude Code OpenTelemetry for this repo, 2026-10-17 19:00 BST to 2026-10-24 about 08:00 BST.

| Measure | Value |
|---------|-------|
| Estimated cost | $351.41 |
| Requests | 6,430 |
| Sessions | 7 |
| User prompts | 277 |
| Cost per request | $0.0547 ($351.41 / 6,430) |
| Cost split (estimated) | cache read 43.9%, cache write 32.6%, output 21.7%, input 1.9% |
| Context share of cost | 78.4% (43.9 + 32.6 + 1.9) |
| Context tokens per request | median 94,713, p90 276,014, max 758,581 |
| Compactions | 1 |

**Model mix**

| Model | Requests | Cost | Share of cost |
|-------|----------|------|---------------|
| `claude-opus-5-5` | 4,850 | $307.70 | 87.6% |
| `claude-sonnet-5-5` | 1,509 | $43.47 | 12.4% |
| `claude-haiku-5-5` | 71 | $0.25 | 0.1% |

**Query source**

| Source | Requests | Cost | Share of cost |
|--------|----------|------|---------------|
| `agent:builtin:general-purpose` (subagents) | 3,825 | $183.45 | 52.2% |
| `repl_main_thread` (main thread) | 1,319 | $128.65 | 36.6% |
| `agent_summary` (subagent progress summaries) | 1,088 | $30.00 | 8.5% |
| `agent:builtin:Explore` and `agent:builtin:fork` | 133 | $5.72 | 1.6% |

All subagent types together cost 53.8% (52.2 + 0.8 + 0.8). Adding progress summaries gives 62.3%. Sessions completed 216 subagents, with an average prompt of 2,795 bytes.

**Top tools by bytes returned into context**

| Tool | Calls | Result bytes | Average | Largest |
|------|-------|--------------|---------|---------|
| Bash | 4,051 | 15,851,777 | 3,913 | 29,697 |
| Read | 456 | 3,683,077 | 8,076 | 75,153 |
| Edit | 2,129 | 339,777 | 159 | 366 |
| Agent | 212 | 234,260 | 1,105 | 1,105 |

Bash returned 78.3% of all tool result bytes (15,851,777 / 20,233,405). Read returned 18.2%. Five Read results exceeded 50 KB.

**Top sessions**

| Session | Requests | Cost | Largest context (tokens) |
|---------|----------|------|--------------------------|
| `c8bb348c` | 1,979 | $114.10 | 528,550 |
| `c5f55d96` | 1,580 | $90.62 | 625,165 |
| `786ae7f1` | 1,517 | $72.95 | 758,581 |
| `92bb4392` | 1,143 | $61.47 | 414,989 |

These four sessions cost $339.14, which is 96.5% of the total.

### What in this repo drives it

- `planifest-framework/standards/agent-dispatch-standards.md` maps the Claude Code tiers to `claude-sonnet-4-6` and `claude-haiku-4-5`. Its dispatch skeleton passes `model: "claude-haiku-4-5"`. Haiku served only 71 requests, and Opus took 87.6% of cost. The model names that skills pass probably don't take effect, so subagents inherit Opus.
- `planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md` makes decomposition the default in every phase. Each subagent pays to cache its own starting context.
- `planifest-framework/tests/run-tests.sh` runs 116 test files and prints a header per suite. The suites print a `PASS` line per check. The refactor skill runs the full suite after every requirement (`planifest-framework/skills/planifest-refactor/SKILL.md` lines 19 and 45).
- `planifest-framework/skills/planifest-orchestrator/SKILL.md` is 77,393 bytes and 823 lines. The `auto-trigger-orchestrator` hook loads it at the start of every session. Phase 0 and Adoption Modes take lines 239 to 588 and 768 to 818.
- `planifest-framework/skills/planifest-ship-agent/SKILL.md` is 42,158 bytes.
- The orchestrator's Context Hygiene section makes mid-run compaction advisory (line 235). The window shows one compaction across sessions of up to 1,979 requests.

## Suggested Action

Paste the recommendation prompt below into a Claude Code session in this repo. Run it as its own feature through the pipeline.

### Recommendation prompt

```text
Reduce the context cost of Claude Code sessions in this repo. Propose each change below as a diff. Wait for my approval before you apply any of them.

Do not weaken any quality gate. Keep every hook, critic, security review, cross-model review, TDD loop, and test assertion. If a change would remove or soften a gate, say so and drop it.

Evidence: a one-week usage profile (backlog 0000230). Context is 78.4% of estimated cost. Opus takes 87.6% of cost. Subagents take 53.8%, plus 8.5% for their progress summaries. Bash returns 78.3% of tool result bytes. Four long sessions take 96.5% of cost.

Changes, in order of expected saving:

1. Make subagent model tiers take effect.
   File: planifest-framework/standards/agent-dispatch-standards.md (tier-to-model table and Agent Dispatch Template). Also check planifest-framework/skills/planifest-orchestrator/SKILL.md lines 675 and 721.
   Reason: the table names claude-sonnet-4-6 and claude-haiku-4-5, and the skeleton passes model "claude-haiku-4-5". Haiku served 71 of 6,430 requests, so these names probably don't take effect and subagents inherit Opus.
   Change: use the model values that the Claude Code Agent tool accepts (sonnet, haiku, opus). Keep the tier per task type as it stands. Add a test that the skeleton and table use only accepted values.

2. Cut test runner output.
   Files: planifest-framework/tests/run-tests.sh, planifest-framework/skills/planifest-refactor/SKILL.md (lines 19 and 45), planifest-framework/skills/planifest-validate-agent/SKILL.md, and the TDD loop in planifest-framework/skills/planifest-codegen-agent/SKILL.md.
   Reason: Bash averages 3,913 bytes per call over 4,051 calls, and the largest result is 29,697 bytes. Each result is cached and re-read on every later turn.
   Change: add a quiet mode to run-tests.sh that prints only FAIL lines, the failed-suite list, and the totals. Make the skills use it. On a failure, rerun only the failing suite in full. Leave CI output unchanged.

3. Split the orchestrator skill so a session loads only what its phase needs.
   File: planifest-framework/skills/planifest-orchestrator/SKILL.md (77,393 bytes, loaded by the auto-trigger-orchestrator hook in every session). Then planifest-framework/skills/planifest-ship-agent/SKILL.md (42,158 bytes).
   Reason: the median request carries 94,713 tokens of context. Five Read results exceeded 50 KB. A session at P3 still carries the P0 text.
   Change: move Phase 0 (lines 239 to 588) and Adoption Modes (lines 768 to 818) into reference files loaded at P0. List them in the Framework Index. Move each suite assertion that greps the moved text to the new file. Keep every rule word for word.

4. Reset context at phase gates.
   File: the Context Hygiene section of planifest-framework/skills/planifest-orchestrator/SKILL.md (line 235).
   Reason: four sessions ran 1,143 to 1,979 requests and reached 414,989 to 758,581 tokens of context. The window shows one compaction.
   Change: after each passed phase gate, recommend /compact or a new session, because plan/current/ and pause.md hold the resume state. Keep it non-blocking.

5. Set a size floor for subagent decomposition.
   Files: planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md and the Agent Dispatch Template in planifest-framework/standards/agent-dispatch-standards.md.
   Reason: 216 subagents completed. Each one caches its own starting context, and progress summaries cost $30.00.
   Change: dispatch a subagent only when the unit needs its own reads or many tool calls. Do small independent units as parallel tool calls in the main thread. Keep the parallel critics and scope-lock drafts as they are.

6. Read large files in parts.
   File: planifest-framework/templates/standard-boot.md (the source of CLAUDE.md), then re-run setup.
   Reason: Read averages 8,076 bytes per call, and the largest is 75,153 bytes.
   Change: add one directive. For a file over about 20 KB, search it or read the section you need with an offset and limit.

For each change, report the files touched and the tests you ran. Also say which numbers in the profile you expect it to move.
```

### Expected effect

These figures are rough estimates.

- **Change 1:** subagents cost $183.45. Sonnet cost $43.47 in all, so at least $139.73 of subagent cost ran on Opus ($183.45 - $43.47 - $0.25). Sonnet costs about half of Opus per token. Moving that work saves between $69.87 (half of $139.73) and $91.73 (half of $183.45). That is 19.9% to 26.1% of $351.41.
- **Changes 2 to 6:** these cut context tokens per request. The profile can't attribute cost to single tool results or skills, so it gives no figure for these. Expect the median and p90 context per request to fall.

### How to measure

1. Re-run the same per-repo measures from rapid-prototypes `0000008-claude-usage-observability` for one week after the changes land.
2. Compare these values with the baseline above:
   - context tokens per request (median 94,713, p90 276,014)
   - subagent share of cost (53.8%) and Opus share of cost (87.6%)
   - Bash result bytes per call (3,913)
   - cost per request ($0.0547)
3. If Opus still takes most subagent cost, change 1 didn't take effect. Check the model each subagent ran on.

## Why Deferred

The analysis ran in another repo, rapid-prototypes, during its feature `0000008`. The changes touch this repo's skills, standards, and tests, so they need their own run here.
