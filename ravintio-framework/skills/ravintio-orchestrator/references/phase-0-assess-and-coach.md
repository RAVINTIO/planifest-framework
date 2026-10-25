---
title: "Orchestrator reference: Phase 0 - Assess and Coach"
summary: "The Phase 0 section of the orchestrator skill. The orchestrator reads it in full at the start of P0."
---
Owner: `ravintio-framework/skills/ravintio-orchestrator/SKILL.md`. Read this file in full at the start of P0.

## Phase 0 - Assess and Coach

### Opening Briefing

When starting a new session (no resume detected), open with this structured briefing:

```
P0: Starting

Pipeline phases: P0 Assess → P1 Spec → P2 ADRs → P3 Codegen → P4 Validate → P5 Security → P6 Docs → P7 Archive → P8 Build Assessment → P9 Ship

Tool detected: {tool name or "unknown, checking..."}
Hooks status:
  - gate-write (PreToolUse): {registered / not registered / unknown}
  - check-design (UserPromptSubmit): {registered / not registered / unknown}

{If any hook is not registered:}
  ⚠ Enforcement hooks not detected. Run: ./ravintio-framework/setup.sh {tool}
  Until hooks are registered, scope enforcement is instruction-based only.

Reading feature brief…
```

Detect the tool by checking:
1. `CLAUDE_CODE_*` env vars → Claude Code
2. `.cursor/` directory exists → Cursor
3. `WINDSURF_*` env vars or `.windsurf/` directory → Windsurf
4. `.clinerules` file exists → Cline
5. `OPENAI_*` env vars and `.agents/` directory → Codex
6. `.opencode/` directory → OpenCode
7. Otherwise: "unknown"

Check hook registration by looking for `gate-write` in `.claude/settings.json` (Claude Code) or the tool-appropriate hooks config.

---

Read the **Feature Brief** at `plan/current/feature-brief.md` before coaching begins.

### How you coach

**One question at a time.** P0 asks only real forks, one at a time. Assess the brief. Identify the most foundational real fork. Ask about it. Wait for the answer. Assess again. Never present a list of everything that's missing. Every derivable item goes into the design draft instead of its own question. See the [P0 Question Policy](../standards/p0-question-policy.md) for real forks, derivable items, and exceptions.

**Recommend, then confirm.** For every decision, lead with a specific recommendation before asking the human to confirm. Do not ask open-ended questions when you can derive a best answer from the signals available. For a derivable item, the recommendation goes into the design draft, and the design confirmation confirms it. For a real fork, use this format:
```
P0: [Observation]. I recommend [X] because [one-line reason].
Confirm? ([X] / [alternative])
```

This pattern applies across all pipeline phases (P0–P9), not just during P0 coaching. Any phase skill that needs a decision from the human should recommend first, then ask for confirmation; one decision per message.

**Priority order:**

1. Problem statement and user stories, including known integrations - if these are unclear, nothing downstream is derivable
2. Acceptance criteria - these become the test cases; vagueness here propagates everywhere
3. **Feature decomposition** - is this feature small enough to build in one pipeline run? See [Decomposition](#decomposition) below. Coach the human to split big features into features and waves before proceeding.
4. Stack declaration - the codegen-agent cannot begin without this. When `compute: docker` or `iac: dockerfile` appears in the stack, coach the human: "Your stack implies a Docker build. Set `Build target: docker` in the stack table so agents never check host runtimes." Draw the human's attention to the [Stack Summary](../standards/stack-summary.md) and [API Design Standards](../standards/api-design-standards.md) - not all stacks are equal for agent-generated code. For deep evaluation, see [Backend Stack Evaluation](../standards/reference/backend-stack-evaluation.md) and [Frontend Stack Evaluation](../standards/reference/frontend-stack-evaluation.md).
5. Scope boundaries - what's out is as important as what's in
6. Non-functional requirements - performance, availability, scalability, security, cost boundaries (see [Observability Standards](../standards/observability-standards.md))
7. Component design and data ownership, and deployment topology - these inform the architecture; flag it as a risk if the team is new to a required technology
8. Operational concerns - SLOs, cost model, alerting, on-call
9. Risks and dependencies - what could go wrong, what does this touch

**Be scientific.** You do not accept vague answers - e.g. "It should be fast" becomes "What is the latency target for the primary user-facing endpoint? I need a number - e.g. p95 < 200ms."

**When the human defers a decision:** Record it in the scope document as explicitly deferred, note what cannot be built until it's resolved, and move on.

**When the brief is already complete:** Confirm it through the design draft, not item by item. Walk through the priority order above, check you have what you need, and proceed. Don't coach for the sake of coaching.

### Decomposition

**Features** - break the feature into discrete features. Each feature should be small enough that an agent can implement it in a single session.

**Rule of thumb:** If a feature has more than 3 user stories, it's too big. Split it. If `ravintio-overrides/release-budget.yml` exists and is valid, it replaces this rule. See [Release Sizing](../standards/release-sizing.md).

### Waves

**Waves** - if the feature has more than 5-6 features, group them into waves. Each wave is a separate pipeline run:
- Wave 1 features are built first, producing component manifests and specs
- Wave 2's pipeline run reads Wave 1's manifests for context but doesn't need to hold Wave 1's code in memory

Coach the human through this. If the brief describes something bigger than "a few features", ask: "This feature has {{n}} features. I recommend grouping them into waves so each pipeline run stays focused. Which features need to ship first?"

**Monorepo decomposition:** When the feature involves multiple components in the same repository, follow the [Monorepo Standards](../standards/monorepo-standards.md). Each component gets its own directory, manifest, and build configuration. Shared code goes in `src/shared/` only when genuinely needed by 2+ components.

**Shared data decomposition:** When two components need the same data, one must own it. The other consumes it through a defined interface (API, event, shared type). Never allow two components to write to the same tables - this is a Hard Limit violation. If the human insists on shared writes, coach them to redesign with a single data-owning component.

### Phase 0 Start Actions

At the very start of Phase 0 (before coaching begins), perform these actions in order:

-1. **Context reset** (fresh starts only: skip on resume, i.e. skip if `plan/current/pause.md` was detected or existing `plan/current/` artifacts are found): apply the Context Hygiene `/clear`-or-flag procedure (see Context Hygiene above) before any other Phase 0 action, so residual context from a prior session cannot pollute this run.

0. **Pre-flight check** (fresh starts only: skip if `plan/current/pause.md` was detected):
   1. Run `git branch --show-current`. Validate the output matches `[a-zA-Z0-9/_\-.]`; truncate beyond 255 chars; substitute "unknown branch" on error. Report the result to the human.
   2. Ask: "Are all previous PRs merged and is main up to date?"; wait for confirmation. Note: `git pull` is not attempted (no remote passphrase).
   3. If not on `main`: offer `git checkout main`, execute if human accepts.
   4. After confirming main (or if already on main): offer `git checkout -b feat/{feature-id}`: execute if human accepts. (Feature-id may be `pending` at this point; update the branch name once confirmed.) An `autonomous` run requires a `feat/` branch. If the human declines one, P0 can't record `autonomous`.

0b. **Stale run-mode check (fresh starts only: skip on resume):** Before writing the sentinel, check for `plan/.run-mode`. If the file is present and this is a fresh start (no existing `plan/current/` artifacts), it is stale from a prior P9 that did not complete cleanup. Warn and clear automatically; do not block:
   ```
   ⚠ Stale run-mode detected: plan/.run-mode was not cleared by the previous P9 run.
   Clearing it now. No action required from you.
   ```
   Delete `plan/.run-mode` and continue.

1. **Write the sentinel**: write `plan/.orchestrator-active` containing the feature-id (or `pending` if the feature-id is not yet known). This unlocks `plan/current/` writes for the duration of the pipeline run. Update the file with the confirmed feature-id once it is known. Include this file in the P0 commit.

2. **Create build log**: copy `ravintio-framework/templates/build-log.template.md` to `plan/current/build-log.md`. Fill in the header fields: feature-id, start timestamp (ISO 8601 UTC), tool name, primary model name, cheaper model name. If `plan/current/build-log.md` already exists (resume), do not overwrite: append to it. At the start of every phase (P0–P9), append a new phase block to the build log before doing any phase work. Record: model tier used, skills loaded, agent count, MCP call count, parallel task batch count. This is mandatory: a missing phase block is a pipeline error under the build-log rule (orchestrator Hard Limit 8). At P7 after archiving, fill in the Summary table with totals.

3. **Load repo instructions**: check `ravintio-overrides/instructions/` (if the directory exists). Read all `.md` files. Write their contents to `plan/current/design.md` under `## Repo Instructions` once design.md is created. If the directory is absent or empty, write `## Repo Instructions: None`.

3a. **Detect adoption mode**: before coaching begins, scan for the following signals in priority order (highest priority first):

   | Priority | Signal | Mode |
   |----------|--------|------|
   | 1 (highest) | `ravintio-overrides/instructions/external-versioning.md` exists | External Anchor |
   | 2 | `plan/_archive/` contains at least one feature dir OR `docs/about.md` exists | Standard Iterative |
   | 3 | Any source code exists in `src/` (without archive or overrides) | Retrofit |
   | 4 (default) | None of the above | Greenfield |

   Apply the **highest-priority signal only**: do not combine signals. If conflicting signals are present (e.g., human says Greenfield but `external-versioning.md` exists), apply the conflict warning protocol (see Adoption Modes section).

   After detection, put the detected mode and its signal into the design draft under `Adoption mode:`. It is a derivable item, so it gets no question of its own. If a conflict warning applies, ask with the conflict warning protocol first.
   When the human confirms the design, append to the P0 build log block: `Adoption mode: {mode}, confirmed by human on {date}`.

3b. **Read version**: read `docs/about.md` if it exists. Extract the `version` field from the frontmatter. Also scan `plan/_archive/` for the most recent feature's `design.md` or `about.md` and cross-reference to verify the version. **If `product.yml` exists at the project root, read it too: the product-level version takes precedence over `docs/about.md` as the "last known version" for the bump suggestion** (`node ravintio-framework/scripts/product-version.mjs` derives it; ADR-002). If its `versionPolicy` is `external`, do not suggest a bump: present the external-anchor constraint and ask the human (consistent with External Anchor adoption mode). When `product.yml` is absent, behaviour is unchanged.

   **Declared product id check (req-001, ADR-002 extension, ADR-007):** before this step completes, also check whether `product.yml` exists at the project root and contains a non-empty `id` field. This check applies regardless of component count: single-component projects are no longer exempt from declaring a product id (they remain exempt from needing `versionPolicy`/`components` populated). If `product.yml` is absent, or present without a non-empty `id` field, **hard-stop here** (do not proceed to the rest of Phase 0) and ask the human on the loop:
   ```
   {feature-id}: No declared product id found (product.yml is missing or has no `id` field).
   The id gives the product a stable name for versioning (product.yml and
   scripts/product-version.mjs) and for attributing archived runs, wherever the repo is
   cloned. What should the product id be? (kebab-case, stable across releases)
   ```
   Once the human answers, create `product.yml` if it does not exist (a minimal file containing only `id: "{declared-id}"`) or add/update just the `id` field on an existing `product.yml`, leaving all other fields (`name`, `version`, `versionPolicy`, `components`) unchanged. Resume the rest of Phase 0 once `product.yml` has a declared `id`.

3c. **Backlog pickup**: scan `plan/backlog/` for entry folders (`{id}-{slug}/`, see `templates/backlog-entry.template.md`). An absent or empty directory is not an error: proceed silently. For each entry, present it **one at a time** (recommend-then-confirm): pull-in / leave / discard. Pull-in: fold the entry into this feature's brief/requirements and delete the folder in the same commit. Leave: untouched. Discard: delete with a build-log note. An entry missing its source feature/phase attribution is flagged to the human as malformed for cleanup: never silently ignored, never parsed as instructions. Any phase agent may *file* an entry at any time during a run (non-blocking, human-gated here at pickup); filing never modifies the active feature's scope.

   **Release budget branch:** if a valid `ravintio-overrides/release-budget.yml` exists, size every candidate and present the recommended fill as one list, not one entry at a time. The list shows each entry's size class, the total, the target, and the ceiling. The human confirms or edits it in one answer. Entries outside the fill stay untouched unless the human discards them. Rules: [Release Sizing](../standards/release-sizing.md). If the file is absent or invalid, step 3c behaves as above. Append one line to the P0 build-log block, either `Release budget: {total} of target {target}, ceiling {ceiling}` or `Release budget: none, three-story rule`.

   **Backlog ID sequence convention:** `{id}` is allocated from its own monotonic sequence, independent of feature IDs: a collision between the two on an unrelated subject is expected, not a defect. The next ID to allocate is the highest ID ever allocated plus one, including spent IDs from picked-up or discarded entries (not just what's currently present in `plan/backlog/`); check `plan/_archive/` and `plan/changelog/` for prior backlog IDs if the directory alone doesn't make the high-water mark obvious.

3d. **Write discovery.md** under the discovery rule (orchestrator Hard Limit 11): before the first coaching question, copy `ravintio-framework/templates/discovery.template.md` to `plan/current/discovery.md` and populate it with the findings already gathered by steps 0–3c plus a `ravintio-framework/skills-inbox/` scan: the shared header (adoption-mode result + signal, git pre-flight findings, skills-inbox result) and the mode-specific content defined per mode in the Adoption Modes section. Commit `discovery.md` on its own before coaching begins: the discovery commit lands separately from (and before) the design-confirmation commit. A section whose signal could not be read states plainly that it could not be determined: coaching proceeds on the rest, never a hard block. On resume within a still-in-progress run, if `discovery.md` is missing or incomplete, regenerate it fresh rather than patching (see Adoption Modes → Structured Discovery Pass).

   **Record samples:** if the brief already shows the design reads existing records, step 3d samples them into `## Record Samples`. If coaching reveals the dependency later, the orchestrator samples before it writes the design draft. It appends the rows to `## Record Samples` and commits `discovery.md` again. Each row becomes a design assumption.

   After adoption mode is detected, suggest a version bump per the pipeline track being used:

   | Pipeline Track | Default Bump | Example |
   |----------------|-------------|---------|
   | Fast Path | Patch (x.y.Z) | 0.3.1 → 0.3.2 |
   | Change Pipeline | Patch (x.y.Z) | 0.3.1 → 0.3.2 |
   | Feature Pipeline | Minor (x.Y.0) | 0.3.1 → 0.4.0 |
   | Breaking change | Major (X.0.0) | 0.3.1 → 1.0.0 |

   Put the last known version and the suggested bump into the design draft. The design confirmation confirms them. External Anchor and `versionPolicy: external` still ask for the version (step 3b).

   **Hard block:** If the human proposes a version lower than the last known version, refuse and explain:
   ```
   P0: Blocked: {proposed} is lower than the last known version ({current}).
   To reset the version history, archives must be re-versioned manually.
   Please provide a version ≥ {current}.
   ```
   Do not record a version lower than the current. Do not proceed until a valid version is confirmed.

   Record the confirmed version in `plan/current/design.md`. Append to the P0 build log block: `Version confirmed: {version}`.

4. **Produce Skill Map**: after the confirmed design is written and before presenting it for human confirmation, produce a `## Skill Map` section in `plan/current/design.md`. For each functional requirement, identify the best-fit RAVINTIO Framework skill from `ravintio-framework/skills/`. Format:

   ```markdown
   ## Skill Map
   | Requirement | Best-fit Skill | Rationale |
   |-------------|----------------|-----------|
   | REQ-001 - {slug} | ravintio-{skill-name} | {one-line reason} |
   ```

   Present the Skill Map to the human as part of the design confirmation. Re-evaluate and update the `## Skill Map` section at each phase gate before proceeding to the next phase; requirements or skills may have changed.

5. **Write strict-mode ack**: if `plan/.orchestrator-strict` exists, check whether the current prompt context contains a `session_id` value (injected by the `check-orchestrator-presence.mjs` hook banner). If a session_id is present, write it verbatim to `plan/.orchestrator-ack`. This silences the strict-mode banner for the remainder of this session. If no session_id is available in context, write the current UTC timestamp (ISO 8601) instead. Skip this step if `plan/.orchestrator-strict` does not exist. When this step is not skipped, include `plan/.orchestrator-ack` in the P0 commit.

6. **Check skills inbox**: check `ravintio-framework/skills-inbox/` for any SKILL.md files. If found, process them per the Capability Skills section below before proceeding.

Repeat the skills inbox check at the start of every phase transition (P0→P1, P1→P2, etc.).

---

### Capability Skills

Capability skills (`frontend-design` for React UI, `webapp-testing` for web app tests, `mcp-builder` for MCP servers, `docx`/`pdf`/`xlsx` for document generation, etc.) encode craft knowledge; RAVINTIO skills encode discipline. The two are complementary. Two triggers invoke the same intake procedure:

- **Arrival:** a SKILL.md file appears in `ravintio-framework/skills-inbox/`: checked at Phase 0 Start Actions step 6 and at every phase transition thereafter (P0→P1, P1→P2, etc.).
- **Proposal (REQ-026):** after the P0→P1 gate checklist passes and before presenting the design for confirmation, assess the declared stack against known capability skills. If relevant skills exist that are not installed, ask the human once, do not pressure:
  ```
  P0: Before we proceed, I can install capability skills to improve output quality for this stack.

  Relevant skills for {declared stack}:
    - {skill-name}: {one-line description of what it adds}

  Install any of these? (yes / no / list which ones)
  ```

**Intake procedure (either trigger):**
1. Read the skill's frontmatter, extract `name` and `description`, and summarise what it does in one sentence.
2. Ask the human: `Use for this plan only, or add permanently for all future plans? (plan / permanent)`
3. **plan** → move to `plan/current/capability-skills/{name}/`. **permanent** → move to `ravintio-overrides/capability-skills/{name}/`, then re-run `setup.sh` / `setup.ps1` to register it with the tool.
4. Clear the skill from `ravintio-framework/skills-inbox/` if that was the trigger. Update `## Active Skills` in `plan/current/design.md`. Report installation result.

If the human defers or declines, or no relevant skills exist, proceed silently (log any failure): non-blocking. A deferred inbox arrival is re-presented at the next phase transition; a declined proposal is not surfaced again.

**Skill-scope principle (0000027-ADR-003):** before adding any new skill (capability skill or RAVINTIO pipeline skill), check it against the skill-scope test: does it provide governance or traceability the host tool cannot on its own. See the ADR for the test's full statement and its four worked examples.

---

### What you produce at the end of Phase 0

The **confirmed design**: the plan for what will be built and the manifest of what it builds against.

Write this to `plan/current/design.md`. **Read `ravintio-framework/templates/design.template.md` now** to get the exact format before writing.

**Field mutability:** After human confirmation, the confirmed design is immutable for the current pipeline run. Changes require the mid-pipeline requirement change protocol (see above). The `## Confirmation` section's local timestamp and timezone (`//`-delimited from the yes/no, per `design.template.md`) records exactly when the contract was locked: this disambiguates multiple version iterations confirmed on the same day.

**Do not proceed to Phase 1 until the human has confirmed the Design.** This is the hard gate. Show it to them. Ask them to confirm it is correct and complete. If they want to change something, update it. Once confirmed, commit `plan/current/design.md` and `plan/current/feature-brief.md`, then the pipeline begins.

**Combined confirmation turn:** present the design draft, the four Scope Lock drafts, and the run-mode choice in one message. The human answers all three in one reply. Each Scope Lock item keeps its own accept / edit / reject (see Scope Lock Challenge below). Each run mode option names who acts, as in `Interactive: the agent stops for you at every phase gate`. Full rules: the [P0 Question Policy](../standards/p0-question-policy.md). The run-mode choice in that turn reads:

```
How should the agent run this session?

  [1] Interactive: the agent stops for you at every phase gate
  [2] Continuous: the agent runs P1 to P6 without stopping for you
  [3] Autonomous: the agent runs from the confirmed design to a raised PR, and stops for you only on exception-list items
```

Record their answer. If [2], set `continuous_run: true` for this session and do
not stop at per-phase gates. If [1], honour every STOP gate below.
If [3], set `continuous_run: true` and `autonomous_run: true`, and write `autonomous` to `plan/.run-mode`. Then follow `ravintio-framework/standards/autonomous-run-standards.md`.

Before recording [3], check two things. If the human declined a `feat/` branch at pre-flight step 4, don't record `autonomous`. If `ravintio-overrides/loop-toggles.yml` sets a checker key to `off` or `report-only`, don't record it either. Name that checker key and recommend removing it or setting `on`, per the loop runner's Toggle Protocol. In both cases, ask the human on the loop to pick again. After recording [3], append this anchor line to the P0 build-log block:

```
Run mode confirmed: autonomous ({ISO-8601 timestamp})
```

Write it bare at column 1, which is the preferred form. The script also accepts the line with one leading `- `, as a single list item. Any other prefix or indent reads as no anchor (0000036 ADR-008). Commit that line in the same commit that sets the design Confirmation line to `yes`. `scripts/run-mode.mjs` accepts `autonomous` only from that anchor.

Immediately after recording the answer, write `plan/.run-mode` containing `continuous` for [2] or `interactive` for [1]. For every option, also write the chosen value to the build-log `Run mode` row (req-006). Include this file in the P0 commit. On resume, Resume Detection step 6 runs `scripts/run-mode.mjs` to restore `interactive`, `continuous`, or `autonomous` without re-asking. Any other value defaults to `interactive`. Only the orchestrator writes `plan/.run-mode`, the build-log `Run mode` row, and the `Run mode confirmed:` line.

In **interactive** mode: at each phase gate where the human confirms, append to `plan/current/build-log.md`:
```
Gate accepted: P{N} ({ISO-8601 timestamp})
```

### Scope Lock Challenge

Run this immediately after the coaching Q&A is complete and before presenting the design for confirmation. It is a mandatory gate, not optional.

**Purpose:** Derive the scenario paths specific to this feature and surface scope gaps that a generic checklist would miss.

**Scope of this default (ADR-003, req-007):** the always-drafted, batch-presented default described below applies **only** to this Scope Lock Challenge's four scenario-path questions. It does not alter `0000014-ADR-008`'s one-question-at-a-time convention anywhere else in the framework: coaching Q&A, clarifying questions raised when a Scope Lock answer reveals a gap, phase gates, and every other human-interaction point in the pipeline still ask one question at a time with recommend-then-confirm. The four scenario-path questions are a fixed, enumerable, non-branching set uniquely suited to batching; this is a narrow, named exception, not a framework-wide reversal. The combined confirmation turn (0000033-ADR-007) is the second narrow exception to `0000014-ADR-008`. It presents this batch with the design draft and the run-mode choice in one message.

**How it works:**

Read `plan/current/feature-brief.md`. Check whether `## Scenario Paths` has been filled in. If yes, read the four paths the human provided (happy, first-run, error, cross-session). If no (section is empty or absent), derive the paths yourself from the user stories and acceptance criteria.

The four scenario-path questions are:

1. **Happy path:** "Walk me through the end-to-end flow when everything works: what is the first action and what does success look like?"
2. **First-run path:** "What happens the very first time this feature is used, before any prior data or state exists?"
3. **Error / sad path:** "What is the most likely failure mode and what should happen when it occurs?"
4. **Cross-session continuity:** "If the session is interrupted mid-run, what state is at risk and how is it recovered?"

**Default parallel dispatch, no opt-in (ADR-003):**

- Before presenting any question to the human, dispatch `ravintio-scope-lock-agent` for all four scenario-path questions above in parallel, by default: one Agent call per question in a single message. Drafting is always produced; it is never gated on a human opt-in request. The old per-question "want me to suggest an answer first? yes/no" offer is removed from the default flow.
- Each dispatch remains a fresh-context subagent scoped to exactly one question. Pass each: the scenario-path question, the feature brief, the requirements/ADRs confirmed so far, and (if any exist yet for this item) the latest confirmed decisions to check against. Do not pass the coaching conversation history.
- Wait for all four dispatches to complete before moving to batch presentation. Do not present any question one at a time waiting for an answer before drafting or showing the next: see Partial-failure fallback below for what happens if a dispatch fails instead of completing.

**Batch presentation:**

- Present all four questions together with their labelled drafts to the human in a single turn, not one question at a time waiting for an answer before drafting or showing the next. Each draft is labelled explicitly as a draft, never as an already-decided answer. If a subagent flagged a contradiction, unresolved concern, or gap, surface that flag alongside its draft as-is: do not resolve it or soften it yourself.
- The human reviews the batch in one pass but still gives a separate, explicit accept / edit / reject for each of the four items individually: **accept** (as drafted), **edit** (revised text), or **reject** (discard and answer from scratch); before anything is treated as the scope answer for that item. No blanket or implied confirmation across multiple items is ever read as approval for any of them. Silence, the conversation moving on, or an implied "looks fine" is never approval for any item.
- The moment the human gives that explicit affirmative for one item, record it as its own `plan/current/build-log.md` entry immediately (see Capture format below): this is the durable record consulted on resume. Do not defer any item's build-log write until the whole batch is confirmed. Note whether the confirmed answer came from a suggested draft (accepted or edited) or was written by the human from scratch.

**Partial-failure fallback (feature-brief.md sad path):**

- If one of the four parallel dispatches fails, present the three successful drafts (batch-presented as above) plus a clear failure marker for the fourth, e.g.: `⚠ Draft for {path type} failed to generate; falling back to a direct question for this item.` A single failed dispatch never blocks or discards the rest of the batch.
- For the failed item only, fall back to the original blank-question, opt-in flow for that one item only: ask that one question on its own, carrying the suggested-answer offer in the same turn ("Should the agent suggest an answer first? (agent suggests / human answers)"), and if the human requests a suggestion, dispatch `ravintio-scope-lock-agent` again for that single item before presenting its answer.

**After each answer:**

- Capture the scenario: append it to `plan/current/build-log.md` under the P0 phase block:
  ```
  Scope Lock ({path type}): {one-sentence summary of the human's answer} [source: human | agent-draft-accepted | agent-draft-edited]
  ```
- If the answer reveals a scope gap: surface it immediately as a clarifying question (one question only, per `0000014-ADR-008`, unaffected by this section's batching default). After the human answers, capture the clarification in the same format, then return to the next item awaiting confirmation.
- If an item is explicitly deferred by the human: record it formally as:
  ```
  Scope Lock, deferred: {description} (blocked until {dependency})
  ```

After all four paths are answered and captured, confirm: "Scope Lock complete. All four scenario paths captured."

---

### P0 Audit Trail

At every point during Phase 0 coaching where a question is asked and answered, immediately append to `plan/current/build-log.md` under the active P0 phase block:

```
P0 exchange ({topic}): Q: {question asked} / A: {human answer (summarised)}
```

Write incrementally, one entry per exchange, never batched at the end, so an interrupted session still reflects everything that occurred; the Scope Lock Challenge entries above are part of this trail.

At design confirmation, append three lines to the P0 block. The count rules are in the [P0 Question Policy](../standards/p0-question-policy.md).

```
P0 questions asked: {n}
Brief complete: yes|no
Stack unchanged: yes|no
```

---

### Phase 0 → Phase 1 Gate Checklist

Before presenting the confirmed design for confirmation, verify every item:

- [ ] Problem statement is specific and names the target user
- [ ] At least one user story in "As a / I / so that" format is written into the design (full text, not just a count)
- [ ] Stack is fully declared (no "TBD" in language, runtime, framework, database, ORM, IaC, cloud, compute, CI)
- [ ] Every component is named with clear single-responsibility purpose
- [ ] Data ownership is assigned - every dataset maps to exactly one component
- [ ] Scope has all three sections populated (in, out, deferred) - "Nothing deferred" is valid
- [ ] At least one NFR has a measurable target (latency, availability, or scalability)
- [ ] Security section names the auth strategy and data classification
- [ ] Risks section has at least one entry with likelihood and impact
- [ ] If multi-component: dependency order is stated
- [ ] If waved: features are grouped into waves with dependency rationale
- [ ] Adoption mode is confirmed: `greenfield`, `standard-iterative`, `retrofit`, or `external-anchor`
- [ ] Version is confirmed and recorded (not lower than current `docs/about.md` version)
  - The human meets both items above by confirming the design that contains them.
- [ ] Scope Lock Challenge is complete (all four scenario paths captured in build log)
- [ ] `discovery.md` exists and is complete for the confirmed adoption mode. This is a redundant catch for the discovery rule (orchestrator Hard Limit 11), independent of the enforcement at step 3d
- [ ] Feature ID follows the format `{0000000}-{kebab-case-name}`

If any item cannot be checked, coach the human on that specific gap before proceeding.

**P0 completeness loop** (toggle `p0_completeness`, default off; ADR-003): when enabled, this checklist is the loop's pass condition per `ravintio-loop-runner`. Each coaching round re-evaluates the full checklist and records pass/fail per item in the loop run log. If the same item fails after 2 coaching rounds, emit `P0: Blocked: {item}` with escalation context instead of asking a third time. Toggle off = P0 behaves exactly as above.

