---
title: "Backlog Entry: 0000298 - put ravintio-overrides/ on the enforcement list"
summary: "Policy files in ravintio-overrides/ can be written by an agent through a self-authorised Fast Path record and by P0 skill intake."
status: "open"
---
# Backlog Entry: 0000298 - put ravintio-overrides/ on the enforcement list

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Priority:** urgent
**Suggested route:** Change Pipeline
**Related:** 0000288

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 looked at who can change policy files. Framework targets regulated industries, such as those that follow GAMP 5. There, the human sets policy and the agent follows it.

## Problem

`ravintio-overrides/` holds the policy for a repository:

- loop toggles and the release budget
- the exception list and doc checks
- `instructions/`, which setup appends to the boot file, for example `custom-005-p9-push-and-raise-pr.md`, which lets the agent push and raise PRs
- `capability-skills/` and `setup-config/`

`templates/loop-toggles.template.yml` (line 4) says the framework and its agents never write there. No hook enforces that rule:

- **Fast Path.** `ravintio-framework/workflows/fast-path.md` line 70 calls the scope record "self-authorisation". Its example on line 76 lists `ravintio-overrides/instructions/review.md`. `FAST_PATH_ENFORCEMENT_PATHS` in `hooks/enforcement/path-rules.mjs` doesn't list `ravintio-overrides/`, so the gate admits it.
- **P0 skill intake.** `skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md` line 211 has the agent move a skill into `ravintio-overrides/capability-skills/{name}/` once the human answers "permanent". The human chooses, but the agent writes.

## Suggested Action

- Add `ravintio-overrides/` to `FAST_PATH_ENFORCEMENT_PATHS`.
- Replace the Fast Path example path with one outside `ravintio-overrides/`.
- Change P0 skill intake to tell the human which folder to create, rather than writing it.
- Add a test that a Fast Path record listing `ravintio-overrides/` doesn't admit the write.

## Wanted outcome

Only a human changes `ravintio-overrides/`. The template's promise matches what the hooks enforce.

## Open questions

- With a confirmed design, should `gate-write` also block `ravintio-overrides/` when a component path covers it? 0000297 asks the same question for every enforcement path.

## Why Deferred

The human asked for it on 2026-10-31. It changes the enforcement list and a P0 procedure, so it needs the Change Pipeline.
