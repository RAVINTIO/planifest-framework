---
title: "Backlog Entry: 0000330 - a regulated postmortem with an impact assessment"
summary: "Port Zero's postmortem skill, widen its triggers, add a fishbone pass, and add an impact section that names affected requirements, controls, risks, and test evidence."
status: "open"
---
# Backlog Entry: 0000330 - a regulated postmortem with an impact assessment

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000085, 0000284, 0000285, 0000331

---

## Problem

Framework has no postmortem. P8 (`ravintio-build-assessment-agent`) reports efficiency only. `defect-report.template.md` handles live reversal petitions, not root causes.

RAVINTIO Zero has a `ravintio-postmortem` skill. It writes an evidence timeline and a 5 whys chain that ends at a process gap, never a person. Its triggers are these:

- a failed CI run
- a `Blocked:` stop
- a Zero P2 Implement self-correction that a test should have caught
- an escaped defect
- a human request

The owner wants this approach but wants Framework to go further. A regulated team must know what a failure touched, not only why it happened. Zero's record says nothing about requirements, controls, risks, or test evidence that the failure undermines.

## Suggested Action

Port Zero's skill as `ravintio-postmortem`. In Framework terms, the self-correction trigger becomes a P3 or P4 self-correction that a P3 test should have caught. Then extend it:

- **More triggers:**
  - a failed deploy or a rollback
  - a granted reversal
  - a gate passed with known findings
  - an escaped defect after release
- **Fishbone pass:** keep the 5 whys. Add a pass over fixed categories: method, standard, tooling, input spec, environment, and measurement. Fixed categories let 0000335 count them across records.
- **Impact section:**
  - affected requirements and acceptance criteria
  - affected organisation controls, by the IDs from 0000285
  - affected risk register entries, with the ISO 14971 harm link (0000284)
  - test evidence the failure invalidates
  - the revalidation scope
  - a regulatory significance call for data integrity, patient safety, and financial reporting
- **Record:** write each record outside `plan/current/`, for example `plan/quality/postmortems/`. Never overwrite one. A correction is a new record that links the old one.

Each action becomes a CAPA record under 0000331. The postmortem records evidence and links to the organisation's QMS. It never claims compliance.

## Wanted outcome

- Every trigger in the list produces one postmortem record.
- Every record has a timeline with cited evidence, a 5 whys chain, a fishbone pass, and an impact section.
- No 5 whys chain ends at a person or an agent.
- A test proves the skill refuses to overwrite an existing record.

## Open questions

- 0000279 section 2 proposes moving 0000085 to RAVINTIO Insight. The owner's strategy of 2026-10-31 keeps postmortems in Framework. Close 0000279's proposal for 0000085 at pickup.
- If 0000085 and this entry ship together, this entry supersedes 0000085's scope. Should 0000085 close as superseded?

## Why Deferred

The human asked for it during the Zero comparison review. It needs its own design and depends on decisions in 0000331.
