---
title: "Backlog Entry: 0000060 - P7 cross-reference check cannot detect the link breakage it exists to prevent"
summary: "The ship-agent's pre-archive cross-reference check searches for the literal string plan/current/ in files outside the archive. The archive move re-parents every file one directory deeper, breaking relative links inside the moved folder — which the check never examines. A downstream archive shipped with ten dead links while the check reported success."
status: "open"
---
# Backlog Entry: 0000060 - P7 cross-reference check cannot detect the link breakage it exists to prevent

**Source feature:** filed from downstream repo `rapid-prototypes`, feature `0000002-backlog-reframe`
**Source phase:** P1 (found while specifying an unrelated requirement)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-08-08

---

## Problem

`skills/ravintio-ship-agent/SKILL.md:39` defines the pre-archive check:

> *"**Cross-reference check (run first, before Step 1):** Before writing the changelog, search the repo for links pointing at `plan/current/...` — `docs/*.md` (especially `docs/decisions-index.md`'s ADR links), `src/*/docs/*.md`, and any other living doc. Update every found reference to the post-archive path… A moved folder with stale incoming links silently breaks navigation for the next reader."*

Two properties make it unable to detect the common case:

1. **It matches a string, not a link.** It looks for the literal text `plan/current/`. A relative link such as `../../.claude/skills/x/SKILL.md` or `../backlog/y/entry.md` contains no such string and is invisible to it.
2. **It searches the wrong side.** It scans *incoming* references from `docs/`, `src/*/docs/` and other living docs — files that do not move. It never examines links *inside* `plan/current/`, which is the folder being re-parented.

Step 6.3 recursively copies `plan/current/` to `plan/_archive/{feature-id}-{date}/`, pushing every file one directory deeper — and two deeper for anything in a subdirectory such as `requirements/`. Every relative link pointing outside the folder is invalidated by exactly that shift. Those are the links the check cannot see.

**Observed impact.** Feature `0000001-prototype-folder-selection` in the downstream repo `rapid-prototypes` passed this check at P7 and shipped its archive with **ten broken relative links**:

| Broken form | Files | Correct after the move |
|---|---|---|
| `../../.claude/skills/…/SKILL.md` | `domain-glossary.md`, `execution-plan.md`, `scope.md`, `risk-register.md`, `iteration-log.md` | `../../../.claude/skills/…` |
| `../../../.claude/skills/…/SKILL.md` | `requirements/req-001…`, `req-002…`, `req-003…` | `../../../../.claude/skills/…` (one deeper again) |
| `../backlog/…/entry.md` | `recommendations.md` (×3) | `../../backlog/…` |

Every one was correct when written and broken by the move. None was reported. They were found by accident a feature later, while specifying an unrelated requirement.

**This is not caused by unusual downstream usage — though the precise link forms above were the downstream author's.** To be exact: the `../../.claude/skills/…` paths in that archive were written by the downstream orchestrator, not copied verbatim from a template. What the framework's own templates emit is the same *shape* of link and it is broken too:

`templates/requirement.template.md:9`, and likewise `execution-plan.template.md` and `iteration-log.template.md`:

```markdown
**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
```

From `plan/current/requirements/req-001.md` that resolves to `plan/skills/…`; from the archived `plan/_archive/{feature}-{date}/requirements/req-001.md` it resolves to `plan/_archive/{feature}-{date}/skills/…`. **Neither exists.** The template link is wrong in both locations, before archiving and after.

So the universality claim holds by a stronger route than originally stated: every project that instantiates these templates emits relative `**Skill:**` back-references that do not resolve, and the archive move changes only *how* wrong they are. The cross-reference check sees none of it in either case, because none of these links contains the string `plan/current/`.

Two distinct defects are therefore in scope, and the second may be the easier win:

- the check cannot detect relative-link breakage (this entry), and
- the templates emit relative `**Skill:**` links that never resolve from where the file actually lives.

**Worse than an ordinary bug:** the check exists specifically to prevent this, so it passing is read as assurance that navigation survived. Silence from a check that cannot fail is indistinguishable from a clean result.

## Suggested Action

Replace the string search with link resolution, run against the archive destination:

1. After the copy in Step 6.3 — or against simulated destination paths before it — walk every `.md` file in the new archive directory.
2. Extract each relative link, resolve it against the filesystem from its *post-move* location.
3. Repair the depth, or fail loudly, on anything that does not resolve.

Roughly fifteen lines of Node, and it converts a check that cannot detect the failure into one that cannot miss it. Keep the existing incoming-reference sweep as well — it catches a real, different case.

**Evidence the fix works.** The downstream repo ran precisely this at the *next* feature's P7 and it immediately caught a live break — a `../backlog/…` link in that run's own `recommendations.md` that would have re-parented to `plan/_archive/backlog/…`. Corrected before the move; that archive shipped with zero broken links, against ten for the feature before it.

Consider applying the walk repository-wide rather than only to the archive. The same downstream check surfaced `plan/feature-structure.md → ../templates/`, a pre-existing break in framework-shipped scaffolding unrelated to archiving, which the same routine would catch.

## Why Deferred

Filed from a downstream repo that does not maintain this framework. The fix belongs to `skills/ravintio-ship-agent/SKILL.md` and possibly a small companion script under `scripts/`, neither of which the filing project modifies.

The downstream project is not blocked — it repaired its ten links by hand and now runs the resolution check manually at P7. But it will recur at every archive, in every project, until this is fixed here.

Related, filed from the same downstream analysis: `0000061-component-manifest-path-inconsistent-with-framework-self-manifest`.
