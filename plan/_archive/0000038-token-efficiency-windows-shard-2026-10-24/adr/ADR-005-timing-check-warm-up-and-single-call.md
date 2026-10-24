---
title: "ADR 005: Timing checks make one untimed warm-up and one timed call"
summary: "Each timed hook check runs one untimed warm-up call and then one timed call that must finish under 200 ms. No check retries. The req-009 best-of-three loop is removed."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Timing checks make one untimed warm-up and one timed call

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

PR #64 Windows shard 1 failed once at 203 ms against a 200 ms limit. There is one usable sample, and the likely cause is a cold first call (assumption A-002). The three timed suites differ:

- `req-003` and `req-007` time one call through `run_node` and `under_200`.
- `req-009` times the best of three runs per command (lines 298 to 324). Best-of-three is a retry, because a slow run is thrown away.

The design keeps the 200 ms limit and bans retries. A retry hides a real slow hook.

## Decision

1. Every timed check makes one untimed warm-up call with the same command and input, then one timed call.
2. The timed call passes only when it finishes in under 200 ms. A call at 200 ms or more fails the check.
3. No check retries, loops, or takes a best result.
4. The warm-up is a fresh Node process, as the timed call is. It warms disk caches only. The hook never runs in-process.
5. The pattern lives in each suite's existing helper. `run_node` in `req-003` and `req-007` gains the warm-up, so `under_200` needs no change. `req-009` replaces its best-of-three loop with the same warm-up plus one call.
6. The regression copies in `planifest-framework/tests/regression/` change with the originals in the same commit.
7. A unit test uses a hook stub that sleeps past 200 ms and checks that the check fails once and the stub runs exactly twice (warm-up and timed).
8. If the timed call still fails on warm calls in CI, the hook needs a speed fix under P4. P3 does not raise the limit.

Decision (P2): one untimed warm-up and one timed call under 200 ms, no retry, in all three suites and their regression copies / reason: it removes the cold-start sample and keeps the limit and the no-retry rule.

Decision (P2): the pattern goes into each suite's helper, not a shared file / reason: the suites run alone and the three helpers already differ.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Raise the limit to 300 ms | Fewer red checks | Weakens a gate | The constraint bans it |
| Keep best-of-three | Already in `req-009` | A retry that hides a slow hook | The constraint bans retries |
| Retry once on failure | Cheap | Same hiding | Same ban |
| Run the hook in-process | Faster | Not what users run | Tests the wrong thing |
| Shared timing helper file | One copy | New file in the test helpers and a wider change | Not needed for three suites |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Three suites, three regression copies, one new test |

## Consequences

**Positive:**
- A red timing check now means a slow warm hook.
- The retry in `req-009` is gone, so the three suites follow one rule.

**Negative:**
- Each timed check costs one more Node start, so the suites run slightly longer.
- The warm-up hides cold-start cost on the first real call.

**Risks:**
- If warm calls on Windows also pass 200 ms, the check stays red and the hook needs work. The design records this as A-002.
- Real sessions still pay the cold start. The fresh-process rule keeps that cost visible in the warm call.

## Related ADRs

- The Git Bash cap that feature 0000037 set - related-to (the Windows legs are where the failure showed)

## Supersedes

- None.

## Superseded By

- None.
