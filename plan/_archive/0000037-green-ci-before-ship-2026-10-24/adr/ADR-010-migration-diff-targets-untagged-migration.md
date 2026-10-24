---
title: "ADR 010: The migration diff check targets the untagged migration"
summary: "The check targets the highest-version re-run-setup migration whose version exceeds every v* tag. It compares that migration's file list with the diff from the highest lower tag to HEAD, in both directions, filtered to setup-delivered files. It skips with a stated reason when the base tag is absent. Backlog 0000199 tracks CI tags."
status: "accepted"
version: "0.1.0"
---
# ADR-010 - The migration diff check targets the untagged migration

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

A re-run-setup migration lists the setup-delivered files that a release changed. A wrong list leaves downstream projects with stale copies (backlog 0000186). The list can omit a changed file, or it can name a file that did not change.

Not every migration maps to one tag range. The 0.34.0 migration covers 0.33.0 and 0.34.0, because 0.33.0 shipped none (0000036 ADR 006). Once a release tag exists, its migration is frozen. A single range cannot describe a migration that covers several releases.

The check must also behave in CI. The workflow fetches no tags, so a shallow checkout has no `v*` refs. Backlog 0000199 tracks the fix. Until it lands, a check that fails on a missing tag would turn every CI run red.

The setup-delivered definition follows what `setup.sh` copies, not the `bundle_templates` or `bundle_standards` lists (0000036 ADR 006).

## Decision

1. The target is the migration that matches `migrate-{version}-rerun-setup*.md` with the highest version.
2. The check compares only when the target's version is higher than every `v*` tag. Otherwise it prints a skip line that says the migration is frozen.
3. The base is the highest `v*` tag below the target's version. The head is `HEAD`. The check runs `git diff --name-only {base}..HEAD` from the repository root.
4. The check filters the diff to setup-delivered files, as `standards/framework-update-policy.md` defines them. It keeps `skills/*/` files that setup copies, `templates/`, `schemas/`, top-level `standards/`, named `bundle_standards` sub-paths, `hooks/enforcement/`, `hooks/adapters/`, and `workflows/`. It drops `standards/reference/` and the git hooks in `hooks/`.
5. The check parses the Background section for backticked paths that start with a setup-delivered folder name. It resolves them against `planifest-framework/`.
6. The comparison runs in both directions. The failure output names each path in the diff but not in the list, and each path in the list but not in the diff.
7. If no `v*` tag exists at all, as in a CI clone, the check prints `SKIP: no v* tags fetched` and exits 0. If the computed base tag doesn't verify with `git rev-parse -q --verify refs/tags/{base}`, it prints `SKIP` with that tag name and exits 0. A fixture case covers each skip.
8. P3 proves the comparison with a fixture repository before the real migration exists. P6 writes `migrate-0.35.0-rerun-setup.md`. The positive path against this repository then runs locally in the post-P6 revalidation with tags present.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Check every migration against its own tag range | Full coverage | A migration that covers several releases has no single range, so the check gives false failures | Frozen migrations cannot be described by one range. |
| Check only list-to-diff (names in the list that did not change) | Catches one defect | Misses a changed file that the list omits | Backlog 0000186 shows both defects occur. |
| Fail when the base tag is absent | Never passes silently | Every CI run fails until backlog 0000199 lands | CI fetches no tags today. |
| Make CI fetch tags in this feature | The check runs in CI | Changes the workflow and widens scope | Backlog 0000199 owns it. |
| Filter by `bundle_templates` and `bundle_standards` | Uses the manifests | Setup's copy-all fallback copies files that no list names | 0000036 ADR 006 rejects this definition. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `tests/test-0000037-req-008-migration-branch-diff.sh`. P6 adds `migrations/migrate-0.35.0-rerun-setup.md`, which the check then targets. |

## Consequences

**Positive:**
- A wrong file list in an unreleased migration fails locally before the release.
- Both directions catch the two defects in backlog 0000186.
- Frozen migrations never produce a false failure.

**Negative:**
- CI cannot run the real comparison until backlog 0000199 lands. The check prints `SKIP` there.
- The Background parser relies on backticked paths. A list written another way reads as empty and fails.
- The positive path against this repository has no test until the P6 migration exists. A fixture check covers the gap.

**Risks:**
- The check passes by skipping in CI without anyone noticing (R-017). Mitigation: each skip line states its cause, either `no v* tags fetched` or the missing tag's name, and the post-P6 revalidation runs the suite locally with tags present.
- The filter drifts from the policy definition if setup changes what it copies. Mitigation: the fixture check covers each kept and dropped folder.

## Governs

- req-008 (FR-008.1 to FR-008.9, AC-008.1 to AC-008.3)

## Related ADRs

- 0000036 ADR 006 - depends-on: the setup-delivered definition.
- 0000036 ADR 007 - related-to: the re-run-setup migration targets the framework source.
- ADR-011 - related-to: the lint covers this suite.

## Supersedes

- None.

## Superseded By

- None.
