---
title: "Requirement: req-010 - version-bump"
summary: "The rename release carries version 0.37.0 in the product manifest, the pack manifest, and the about page."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - version-bump

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-004
**Priority:** must-have

## User Story

As a human on the loop, I see version 0.37.0 in `product.yml`, the pack manifest, and `docs/about.md`, so that I can tell the rename release apart from 0.36.0.

## Functional Requirements
- The release is 0.37.0, a minor bump from 0.36.0. The human on the loop set it at P0 on 2026-10-25.
- P6 writes 0.37.0 to `product.yml`, `ravintio-framework/component.yml`, and the `docs/about.md` frontmatter and table.
- `node ravintio-framework/scripts/product-version.mjs` derives 0.37.0 from the component manifests after P6.
- No live file names 1.0.0 as this release. Old-name reads go at 1.0.0, per the design.
- The second criterion runs `git grep -n '1\.0\.0' -- . ':!plan/_archive' ':!plan/changelog' ':!plan/_migrations' ':!plan/current'`. Every hit must name 1.0.0 as the removal point for old-name reads, or be a version field of a third-party file. A hit that names 1.0.0 as the current release fails.
- Split step: this requirement came from the split of req-004 at its fourth criterion. req-004's version criteria moved here once the P1 critic loop closed.

## Acceptance Criteria
- [ ] After P6, `product.yml`, `ravintio-framework/component.yml`, and `docs/about.md` each read 0.37.0, and `product-version.mjs` prints 0.37.0. Verified by: integration
- [ ] After P6, no live file outside history names 1.0.0 as the current release. Verified by: execution

## Dependencies
- req-001 (pack-paths-and-identifiers) renames `component.yml` into `ravintio-framework/`.
- req-004 (brand-prose) is the requirement this one split from.
