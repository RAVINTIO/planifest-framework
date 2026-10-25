---
title: "Backlog Entry: 0000020 - Decompose the orchestrator skill"
summary: "ravintio-orchestrator/SKILL.md is 12,204 words — 39% of the entire skills corpus — loaded in full before any work begins; make it a router with phase detail loaded on demand."
status: "open"
---
# Backlog Entry: 0000020 - Decompose the orchestrator skill

**Source feature:** N/A — independent framework review, corrected second edition (filed ad-hoc via chat, not part of the phased pipeline)
**Source phase:** N/A (filed ad-hoc via chat)
**Date filed:** 2026-07-31
**Reference:** `_reference/` — REQ-005 in the corrected recommendations; finding 1 in the corrected review

---

## Problem

`ravintio-framework/skills/ravintio-orchestrator/SKILL.md` is 83,699 bytes, 12,204 words, roughly 21k tokens, loaded in full before work begins.

The distribution matters more than the absolute figure. Across all twenty skills, `SKILL.md` files total 30,968 words. The orchestrator alone is **39% of that**. The next largest is `ravintio-codegen-agent` at 2,521 words; the median skill is 772 words. This is not systemic bloat — it is one file.

Long instruction sets degrade instruction adherence, which is precisely the failure mode the framework exists to prevent.

Two aggravating details:

- The file contains a "Framework Index (JIT Loading)" section describing deferred loading, while its own `references/` directory contains nothing but `.gitkeep`.
- **All twenty skills have an empty `references/` directory.** The JIT-loading mechanism is documented in the framework and implemented nowhere in the skills layer. There is currently nothing to decompose into — the scaffolding is part of the work.

## Suggested Action

Reduce `SKILL.md` to a router under 1,500 words: hard limits, the phase table and the routing rules stay always-loaded; each phase's detail moves into `references/` and is loaded at phase entry. Add a test asserting that no `SKILL.md` exceeds 1,500 words, with a recorded exemption mechanism rather than a silent bypass — that single assertion is sufficient, and a full standards-document-plus-hook budget apparatus is not warranted when exactly one skill breaches the limit.

## Why Deferred

Filed from an external review rather than an in-flight pipeline feature.

**Depends on 0000019.** Do not attempt this against a one-test regression pack.

**Risk is medium, not extreme.** The phase skills are already separate, separately described and separately loadable, so this is prose relocation plus load instructions at phase boundaries, not a rearchitecture. The two things that make it safe are a populated regression pack and a full pipeline run compared before and after.

One thing not yet verified at filing time: whether the 12,204 words are genuinely phase-separable. Reading `SKILL.md` in full should confirm or refute that before committing to the 1,500-word target.
