# Plan: Library Standards — Versioning Policy & Avoid Lists

## Context

The framework's `code-quality-standards.md` is strong on structure and patterns but says nothing about *which libraries to use*, which versions to target, or which libraries to avoid. Agents scaffolding `package.json` / `pyproject.toml` / `go.mod` today apply their own judgment — they may reach for deprecated libraries (e.g. `moment`, `request`), skip strict TypeScript config, or pin to outdated majors. This plan adds a `library-standards.md` that codifies the version policy and per-stack avoid/prefer lists, then wires it into the relevant skills.

---

## What changes

### 1. New file: `ravintio-framework/standards/library-standards.md`

Three sections:

**§1 Version Policy**
- Always target the latest stable release at time of scaffold.
- No `^latest` ranges — pin to exact or tilde in package manifests; lockfiles commit exact resolution.
- When upgrading, consult the library's changelog for breaking changes before proceeding.
- Peer dependencies must satisfy the version range declared by their consumer.

**§2 Per-stack library standards** — prefer/avoid table per stack, seeded from content already in `reference/backend-stack-evaluation.md` and `reference/frontend-stack-evaluation.md`. Initial coverage:

| Stack | Prefer | Avoid |
|---|---|---|
| TypeScript (all) | `zod` (validation), `vitest` (tests) | `joi`, `yup`, `mocha`, `jasmine` |
| React 19 | `TanStack Query`, `zustand`, `react-hook-form`, `shadcn/ui` + `tailwind v4` | `redux` (unless justified), `moment`, `lodash` (prefer native), class components |
| Node.js backend | `fastify` or `hono`, `drizzle` or `prisma` | `express` (unless legacy), `sequelize`, `typeorm`, `request` (deprecated) |
| Python | `pydantic` v2, `fastapi`, `httpx`, `pytest` | `flask` (unless justified), `requests`, `unittest` |
| Go | `chi` or `echo`, `pgx`, `testify` | `gorilla/mux` (archived), `gorm` (prefer sqlc or pgx) |

**§3 How agents use this document**
- Before scaffolding any dependency manifest, scan the applicable stack section and cross-reference every library choice against the avoid list.
- If an avoided library is the only option for a requirement, record the exception in `src/{component-id}/docs/quirks.md`.

---

### 2. Modify: `ravintio-framework/skills/ravintio-codegen-agent/SKILL.md`

- Add `library-standards.md` to `bundle_standards` frontmatter array.
- Add a pre-scaffold step: *"Check `library-standards.md` for the component's declared stack. Confirm every dependency is on the prefer list or not on the avoid list. Flag any avoid-list match and substitute the preferred alternative."*

---

### 3. Modify: `ravintio-framework/skills/ravintio-validate-agent/SKILL.md`

- Add `library-standards.md` to `bundle_standards` frontmatter array.
- Add a library audit check alongside lint/typecheck/test/build: *"Scan the installed dependency manifest against the avoid list in `library-standards.md`. Fail and report substitutions if avoid-list libraries are present."*

---

### 4. Modify: `ravintio-framework/skills/ravintio-orchestrator/SKILL.md`

- Add `library-standards.md` to `bundle_standards` frontmatter array.
- Reference during stack selection so the orchestrator can surface library preferences when coaching on stack choice.

---

## Files to create/modify

| Action | Path |
|---|---|
| **Create** | `ravintio-framework/standards/library-standards.md` |
| **Modify** | `ravintio-framework/skills/ravintio-codegen-agent/SKILL.md` |
| **Modify** | `ravintio-framework/skills/ravintio-validate-agent/SKILL.md` |
| **Modify** | `ravintio-framework/skills/ravintio-orchestrator/SKILL.md` |

## Out of scope

- `ravintio-implementer` and `ravintio-refactor` — inherit from codegen-agent, don't directly scaffold dependency manifests.
- Automated version freshness checks querying npm/PyPI at runtime — deferred.
- An ADR — recommended but not blocking.

---

## Verification

1. Read `library-standards.md` and confirm consistency with existing reference evaluations.
2. Inspect each modified SKILL.md — confirm `library-standards.md` in `bundle_standards`.
3. Confirm codegen-agent has the pre-scaffold check step in the correct phase.
4. Confirm validate-agent has the library audit check in the CI loop.
5. Run `setup.ps1` to sync — confirm `library-standards.md` appears in `.claude/skills/ravintio-codegen-agent/references/`.
