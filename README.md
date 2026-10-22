# Planifest

Planifest is a specification-first framework for agentic coding tools. It requires an agent to produce a complete, reviewable execution plan — validated against templates and schemas — before it generates code.

It treats the human as product owner and architect, and the agent as the implementer working within constraints the human sets.

The framework is LLM-agnostic and tool-agnostic. It works with any model (Claude, GPT, Gemini, etc.) and any agentic coding tool (Claude Code, Cursor, Codex, Antigravity, GitHub Copilot, etc.), and supports the [Agent Skills specification](https://agentskills.io/specification).

---

## Rationale

Agile's preference for iterating over heavy upfront planning is a judgement call tuned to a specific bottleneck: when implementation takes weeks or months, a detailed plan goes stale before it ships, so small reversible steps beat big upfront documents. Agentic coding tools don't remove that bottleneck — they move it. Implementation itself is now cheap and fast, so waste shows up earlier: as *plausible-but-wrong output* built on unstated assumptions, rather than as a plan that aged out before delivery.

Planifest applies agile's own underlying instinct to that new bottleneck - don't do work that won't survive contact with reality. Three mechanisms follow from that:

1. **The plan is the reviewable artifact.** When an agent writes the code, the prompt and plan largely determine the output. Planifest makes the plan explicit and reviewable, so architectural choices are visible before code exists.
2. **Context is recorded per component.** Each component keeps a manifest, and each feature keeps its execution plans and ADRs. This gives an agent (or a human) the historical context to modify a component — or the specification to rebuild it.
3. **Gaps trigger questions, not guesses.** If the feature brief has gaps, the agent is instructed to stop and ask rather than fill them with assumptions.

Whether this trade-off pays off depends on the work — see [Limitations](#limitations-and-non-goals).

---

## How it works: the iteration loop

1. **Human writes a feature brief** — what to build, why, and within what constraints.
2. **Agent interrogates** — the orchestrator skill assesses the brief and asks questions until the context is complete.
3. **Agent plans** — it generates an execution plan and an ADR (Architectural Decision Record).
4. **Agent builds** — code generation → validation → security checks → documentation updates.
5. **Human reviews** — the pull request is the backstop.

Every artifact the agent produces follows a template, so output is consistent across tools, models, and teams.

---

## Repository structure

```
repo/
├── planifest-framework/   ← The framework (drop in, don't modify per-project)
│   ├── skills/            ← Agent instructions — orchestrator + phase skills
│   ├── templates/         ← File format templates for every artifact
│   ├── schemas/           ← JSON Schema validation definitions
│   └── standards/         ← Code quality standards
│
├── plan/                  ← Feature briefs, execution plans, ADRs, risk registers,
│                            scope docs. Organised by feature. Everything that
│                            describes WHAT to build and WHY.
│                            See plan/feature-structure.md for the canonical layout.
│                            A typical feature produces five Phase 1 artifacts by
│                            default (execution plan, requirements, scope, risk
│                            register, domain glossary); OpenAPI spec, cost model,
│                            SLO definitions, and operational model are added only
│                            when their trigger condition applies (see
│                            planifest-framework/workflows/feature-pipeline.md).
│
├── src/                   ← Code (organised by component). Implementation, tests,
│                            config, manifests. Each component has a component.yml.
│
└── docs/                  ← Living documentation — component registry, architecture
                             overview, decisions index, dependency graph. Generated
                             by the docs-agent; read by agents and humans.
```

---

## Getting started

See **[getting-started.md](planifest-framework/getting-started.md)** for step-by-step setup instructions.

**Quick start:**

```bash
# macOS/Linux
./planifest-framework/setup.sh <tool>

# Windows
.\planifest-framework\setup.ps1 <tool>
```

Where `<tool>` is `claude-code`, `cursor`, `codex`, `antigravity`, `copilot`, or `all`.

The setup script copies skills into the directory your tool auto-discovers, adds YAML frontmatter, and creates a boot file. See [tool-setup-reference.md](planifest-framework/tool-setup-reference.md) for details on each tool.

---

## Key principles

**Specification before code.** The agent does not write code until the spec is complete. If the spec has gaps, it stops and asks.

**Human decides, agent executes.** The human chooses the architecture, the stack, the data ownership, and the scope. The agent implements within those constraints.

**Decompose big initiatives.** Split into features (small enough for one agent session) and waves (sequential iteration loop runs). This is how Planifest manages context at scale.

**Everything is traced.** Every agent-produced artifact records the skill that produced it, the tool it ran in, and the model that generated it.

**The PR gate is the backstop.** Regardless of tool or model, a human reviews the output before it ships.

---

## The framework

| Folder | Contents |
|--------|----------|
| [skills/](planifest-framework/skills/) | Agent instructions — the orchestrator and every phase and sub-agent skill |
| [templates/](planifest-framework/templates/) | File format templates for every artifact the pipeline produces, each with a guide where applicable |
| [schemas/](planifest-framework/schemas/) | Shared type definitions and the domain document envelope |
| [standards/](planifest-framework/standards/) | Code quality, API design, database, deployment, infrastructure, monorepo, observability, testing, and backend/frontend stack-evaluation standards |
| [setup/](planifest-framework/setup/) | Per-tool boot file templates — a `.sh` and `.ps1` pair for each supported tool |
| [hooks/](planifest-framework/hooks/) | Git hooks, the CI workflow, and the enforcement adapters they wire up |
| [workflows/](planifest-framework/workflows/) | Agent workflow definitions: fast-path, feature-pipeline, change-pipeline, retrofit |
| [scripts/](planifest-framework/scripts/) | Deterministic tooling: consistency checks, version derivation, regression promotion, skill sync |
| [tests/](planifest-framework/tests/) | Per-feature test scripts plus the promoted regression pack |
| [external-skills/](planifest-framework/external-skills/) | Vendored third-party capability skills, available for a pipeline run to load alongside the Planifest skills |
| [migrations/](planifest-framework/migrations/) | The framework's migrations, applied by the `planifest-migrator` skill. Files never move. Each project keeps its run state in `plan/_migrations/`. |
| [skills-inbox/](planifest-framework/skills-inbox/) | Drop-in intake point for a new capability skill, processed at the next Phase 0 |

---

## Hard limits

These apply regardless of tool, model, or configuration:

1. **Requirement gaps are surfaced, then resolved or explicitly deferred, before codegen begins** — every deferral is recorded in that feature's `plan/current/scope.md` Deferred section, so the claim is checkable, not just asserted
2. **No direct schema modification** — migration proposal required, human approves
3. **Destructive schema operations require human approval**
4. **Data is owned by one component** — never write to another component's data
5. **Code and documentation are written together** — never one without the other
6. **Credentials are never in the agent's context** — capabilities only

---

## Limitations and non-goals

Planifest is a deliberate trade-off: it exchanges upfront ceremony for traceability and reviewability. That trade-off is not always worth making.

- **Overhead is real.** For small changes, prototypes, or exploratory work, the full pipeline is disproportionate. The fast-path workflow reduces this, but doesn't eliminate it.
- **It depends on review discipline.** The PR gate is only a backstop if humans actually read the plans and the diffs. Planifest structures the review; it can't perform it.
- **Plans don't prevent all bad output.** A complete specification reduces assumption-driven errors; it doesn't guarantee correct code. Validation and security skills catch classes of problems, not all of them.
- **No comparative benchmarks yet.** We have not published measurements comparing outcomes with and without the framework. Claims about quality improvement are, at this stage, based on design rationale and our own use.
- **It's not a project management method.** Planifest structures agent sessions, not teams. It sits alongside whatever delivery process you already use.
- **The plan/docs parity check is a presence check, not a correspondence guarantee.** CI and the shipped git hooks confirm that some file under `plan/`, `docs/`, or a component's `component.yml` also changed alongside `src/` — they do not verify that file's content actually corresponds to the code change. Reviewers still need to check correspondence themselves at the PR gate.

---

## Status

Planifest is under active development. Template and skill formats may change between versions; check the [roadmap](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p014-planifest-roadmap.md) for planned changes and deferred items.

## Contributing

Issues and pull requests are welcome. Agent skills, templates, and per-tool setup files are the areas most likely to benefit from outside contributions — particularly support for additional agentic tools.

---

## Documentation

`planifest-docs` contains human documentation — architecture notes, research, and the project roadmap. Agents don't need these; they work from the skills and templates in `planifest-framework/`. Available as a [git repository](https://github.com/planifest/planifest-docs) and a [GitHub Pages site](https://planifest.github.io/planifest-docs/).

| Document | Purpose |
|----------|---------|
| [Master Plan](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p001-planifest-master-plan.md) | Architecture overview |
| [Product Concept](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p002-planifest-product-concept.md) | Vision and commercial model |
| [Functional Decisions](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p003-planifest-functional-decisions.md) | Decision log with rationale |
| [Pathway to Agentic Development](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p004-the-pathway-to-agentic-development.md) | Background and rationale |
| [Agentic Tool Runbook](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p010-planifest-agentic-tool-runbook.md) | Per-tool setup guides |
| [Pipeline](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p015-planifest-pipeline.md) | Pipeline phase descriptions |
| [Roadmap](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p014-planifest-roadmap.md) | Deferred items and future features |

---

## Licence

[Apache License 2.0](LICENSE.txt) — chosen over MIT primarily for its explicit patent grant.
