# Decisions Index

> Living document. Index of all ADRs across all features. Updated after every pipeline run.
> Do not archive this file; update it in place.

Last updated: 0000036-pipeline-friction-and-gate-fixes (23 Oct 2026). Adds 12 ADRs for the drift check, the 0.34.0 re-run-setup migration, the `design.md` read rules, `shown()`, the run-mode anchor, the report-only critic default, hard-limit citations, the split step, and commit subjects. ADR-002 narrows 0000003 ADR-005. ADR-009 amends 0000016 ADR-003 and 0000033 ADR-004. Earlier: 0000035 added 16 ADRs, and ADR-015 partly supersedes 0000005 ADR-005. Feature 0000034 recorded no ADRs.

> **Note:** ADR titles for features 0000001–0000010 were inferred from filenames at bootstrap time. Human review recommended for accuracy.

---

## All Architecture Decision Records

### Feature 0000001: context-mode-enforcement-hooks

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | PreToolUse block mechanism | superseded by 0000030-ADR-002 | Hook scripts block tool calls by writing a deny response to stdout; exit code alone is insufficient |
| ADR-002 | Allowlist hardcoded vs configurable | superseded by 0000030-ADR-002 | Allowlist is hardcoded in the script; configuration adds complexity without proportional benefit |
| ADR-003 | Unconditional vs pattern-based blocking | superseded by 0000030-ADR-002 | Pattern-based blocking (Grep/Bash/WebFetch) rather than unconditional; lets non-search tool calls through |
| ADR-004 | Hook script ownership split | superseded by 0000030-ADR-002 | Each hook type (block-grep, block-bash, block-webfetch) is a separate script; no monolithic hook |

### Feature 0000003: hook-based-enforcement

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Three-tier enforcement model | active | Tier 1a (Claude Code native hooks), Tier 1b (other IDE hooks), Tier 2 (instructions only) |
| ADR-002 | Common envelope shape | active | All adapters translate to `{ session_id, cwd, tool_input, event }` before delegating to enforcement |
| ADR-003 | Flag-file deduplication | active | `.orchestrator-active` sentinel prevents duplicate orchestrator activation per session |
| ADR-004 | Two-check gate model | active | gate-write performs (1) sentinel check, (2) component-path allowlist (in order) |
| ADR-005 | Exit-zero failure mode | narrowed by 0000036 ADR-002 | Hooks never exit non-zero on unexpected errors; session must never be blocked by a hook bug. **Narrowed:** 0000036-ADR-002 stops the `design.md` step of the write gate failing open on a non-regular, swapped, or oversize file. Only `EACCES` and `EPERM` still fail open there. |
| ADR-006 | Copy-then-delete archive | superseded by 0000033 ADR-010 | Archive uses explicit copy then delete, not atomic move, to survive partial failures. **Superseded:** 0000033-ADR-010 moves each item with `git mv` through `archive-current.mjs` and deletes only explicit paths, never a glob. |
| ADR-007 | Px prefix convention | active | Every phase response begins with its phase prefix (P0:, P1:, ...) for instant human orientation |
| ADR-008 | Advisory commit-msg hook | active | commit-msg hook rejects AI attribution and >72-char subjects; exit 1 on violation |
| ADR-009 | Anthropic-first skill trust model | active | Skills in `.claude/skills/` are trusted; external skills require explicit `--include-full-skill-library` |
| ADR-010 | Plan-scoped skill lifecycle | active | Skills are loaded JIT per phase, not upfront; prevents context bloat |

### Feature 0000004: tdd-regression-test-quality

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | TDD inner loop as codegen subloop | active | codegen-agent orchestrates test-writer → implementer → refactor per requirement, not per feature |
| ADR-002 | Subagent model tier convention | active | Sub-agents declare `recommended_model: haiku`; codegen-agent retains full model for orchestration |
| ADR-003 | Regression promotion criteria | amended by 0000033 ADR-006 | Tests promoted to regression pack only with human confirmation; `promote-to-regression.sh` is the mechanism. **Amended:** 0000033-ADR-006 keeps human confirmation for `interactive` and `continuous`. In `autonomous`, the agent decides and records each candidate. |

### Feature 0000005: framework-governance

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Library standards directory tree | active | Per-language prefer/avoid lists under `planifest-framework/standards/library-standards/{lang}/` |
| ADR-002 | planifest-overrides sibling directory | active | Project-level overrides live in `planifest-overrides/` (sibling to `planifest-framework/`), never inside the framework |
| ADR-003 | Sentinel-file orchestrator enforcement | active | `plan/.orchestrator-active` sentinel gates all writes to `plan/current/` |
| ADR-004 | Repo instructions via design.md | active | Per-repo instructions (e.g. local-git-only) are embedded in `design.md` Engineering Layer |
| ADR-005 | Markdown migration files | partly superseded by 0000035 ADR-015 | Migrations are documented in `.md` files under `planifest-framework/migrations/`. Its archive-to-folder mechanism is superseded by 0000035 ADR-015: migration files never move, and each project records its runs in `plan/_migrations/` |
| ADR-006 | Two-registry capability skills | active | Capability skills exist in two registries: `planifest-framework/skills-inbox/` (framework) and `planifest-overrides/capability-skills/` (project) |

### Feature 0000006: build-assessment-phase

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Build log as markdown | active | `build-log.md` in `plan/current/` captures P3/P4 cycle details; P8 reads this file |
| ADR-002 | Model tier abstraction | active | Phase skills declare `recommended_model` in frontmatter; orchestrator respects this for sub-agent invocations |
| ADR-003 | Parallelism as skill instructions | active | Parallelism directives belong in SKILL.md, not in code; agent tooling handles scheduling |
| ADR-004 | P8 as separate phase | active | Build assessment (P8) is a distinct phase invoked by P7 (ship), not by P4 (validate) |

### Feature 0000007: agent-optimisation

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Explicit build target field | active | `design.md` Engineering Layer has a `Build target:` field; agents use it to select Docker vs host toolchain |
| ADR-002 | Telemetry guidance centralised | superseded by 0000030-ADR-002 | All telemetry envelope docs live in `telemetry-standards.md`; skill files reference it rather than duplicating |
| ADR-003 | Optimise-agent suggestion-only | active | planifest-optimise-agent produces suggestions only, never modifies code; human decides what to apply |
| ADR-004 | Setup manifest for managed directories | active | `.planifest-manifest` tracks installed paths for idempotent re-run cleanup |
| ADR-005 | Locale-tagged language quirks files | active | `quirks.md` files include locale tag (`en-GB`) so agents apply the correct language variant |

### Feature 0000008: context-mode-plugin-routing-rules

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Plugin as canonical source for routing rules | superseded by 0000030-ADR-002 | Context-mode plugin is the source of truth for which tools to block; framework hook scripts read from it |
| ADR-002 | No per-tool routing rules fallback | superseded by 0000030-ADR-002 | If the plugin is absent, hooks pass through silently rather than applying a hard-coded fallback list |

### Feature 0000009: framework-rail-tightening

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | External skills opt-in flag | active | `--include-full-skill-library` required to install external skills; default install is framework skills only |
| ADR-002 | Attribution.txt per skill | active | Each external skill must include `attribution.txt`; missing file is a hard skip, not a silent install |
| ADR-003 | Auto-trigger hook plus fallback | active | `UserPromptSubmit` hook auto-triggers orchestrator; non-hook tools rely on manual skill load as fallback |
| ADR-004 | Skill map in design.md | active | `design.md` Engineering Layer includes a Skill Map table: requirement → skill → rationale |
| ADR-005 | gate-write Windows path normalisation | active | gate-write uses `norm()` (normalise + forward-slash + lowercase) for all path comparisons; avoids POSIX/Win mismatch |
| ADR-006 | Pause-resume via pause.md | active | `pause.md` in `plan/current/` is always permitted by gate-write; enables session pause/resume at any phase |

### Feature 0000010: framework-quality-improvements

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Agent tool in allowedTools | active | `Agent` tool must be in `allowedTools` for multi-agent features; not assumed present by default |
| ADR-002 | Skill name field as canonical identifier | active | `name:` frontmatter field in SKILL.md is the canonical skill identifier; descriptions are secondary |
| ADR-003 | Input validation section conditional | active | OpenAPI spec section in spec-agent output is conditional on the feature including an API; omit for non-API features |

### Feature 0000011: setup-parity-and-consistency

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Hook deny response format | active | Copilot/Codex use `{ permissionDecision, permissionDecisionReason }` JSON deny; Claude Code uses exit 2 + stdout message |
| ADR-002 | Workspace hook config write strategy | active | Tool-specific hook configs (`.cursor/hooks.json`, `.codex/hooks.json`) are written by setup scripts using merge-not-overwrite |
| ADR-003 | Hook adapter architecture | active | All adapters are delegating (translate envelope → call enforcement script); no inline enforcement logic in adapters |

### Feature 0000012: docs-restructure-commit-directives

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Three-file documentation architecture | active | Framework docs split into `getting-started.md` (entry point), `pipeline-reference.md` (deep reference), `project-operations.md` (operational guide); no single monolithic file |
| ADR-002 | Formal P9 Ship phase | active | Ship is a discrete phase (P9) separate from Archive (P7); pipeline is exactly P0–P9; no phase beyond P9 |
| ADR-003 | Ship-agent orchestrates P7–P9 | active | ship-agent owns the complete close-out sequence: P7 Archive, P8 Build Assessment (sub-agent), P9 Ship |
| ADR-004 | P9 human push/PR decision protocol | amended by 0000033 ADR-006 | P9 always presents a push/PR choice to the human; agent never pushes without awareness; local-git-only defaults to PR description output. **Amended:** 0000033-ADR-006 keeps the protocol for `interactive` and `continuous`. In `autonomous`, the agent takes Option [1] without asking, unless `local-git-only` applies. |
| ADR-005 | Run-mode sentinel file | amended by 0000033 ADR-002 | `plan/.run-mode` written at P0 persists the run mode across session boundaries; any value other than `continuous` defaults to `interactive`. **Amended:** 0000033-ADR-002 adds `autonomous` as a third value. Unknown values still read as `interactive`, and P0 also writes the mode to a build-log Run mode row. |
| ADR-006 | Retroactive tags via Planifest migration | active | Historical release tags applied through a migration file, not a script; human-confirmed per tag; tags are local-only until human pushes |

### Feature 0000023: framework-pipeline-fixes

ADR files: [plan/_archive/0000023-framework-pipeline-fixes-2026-08-02/adr/](../plan/_archive/0000023-framework-pipeline-fixes-2026-08-02/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Restore continuous_run exception for P1-P3 gates | accepted | Restores the `continuous_run: true` exception to P1/P2/P3 STOP rules, matching P4-P6; root-caused the regression to commit `42ae808` (feature 0000021, a word-count trim pass), correcting backlog 0000031's "pre-existing, not introduced by 0000022" claim |

---

## Status Definitions

| Status | Meaning |
|--------|---------|
| active | Decision stands; implementation follows it |
| superseded | Replaced by a later ADR (reference provided in the ADR body) |
| amended | Core decision unchanged but conditions or scope updated |

---

### Feature 0000014: improve-adoption-mode-selection

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Four Adoption Mode Taxonomy | accepted | Replace three-mode model with four signal-driven modes: Greenfield, Standard Iterative, Retrofit, External Anchor |
| ADR-002 | Signal Conflict Priority Order | accepted | External Anchor > Standard Iterative > Retrofit > Greenfield: highest-priority signal wins when multiple signals present |
| ADR-003 | docs/about.md as Canonical Version Source | accepted | `docs/about.md` with YAML frontmatter is the single source of truth for the current project version |
| ADR-004 | Version Bump Rules by Pipeline Track | accepted | Fast Path/Change Pipeline → patch; Feature Pipeline → minor; breaking change → major; human always confirms |
| ADR-005 | Version Regression Hard Block | accepted | Orchestrator refuses versions lower than current recorded version; hard block, not a warning |
| ADR-006 | Resumable Migration with Progress File | accepted | Migrations track state in `migrations/_progress/{name}.json` so they can resume across sessions |
| ADR-007 | Derived Scope Lock Scenarios over Fixed Checklist | accepted | Orchestrator generates scenario questions specific to the feature from requirements, not a generic checklist |
| ADR-008 | One-Question-at-a-Time as Framework-Wide Instruction | amended by 0000033 ADR-007 | Every phase skill states the one-question rule explicitly; recommend-then-confirm pattern throughout. **Amended:** 0000033-ADR-007 makes the P0 combined confirmation turn the second named exception. The rule still governs every real fork. |
| ADR-009 | Incremental P0 Audit Trail Writes | accepted | Build log is appended after each coaching exchange, not batched at the end of P0 |
| ADR-010 | docs/ Lifecycle Ownership | accepted | Docs-agent (P6) owns living docs updates; ship-agent (P7) owns docs/about.md creation as a blocking step |

### Feature 0000015: pipeline-session-cleanup

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Interrupted P9 Detection Signal | superseded by 0000032 ADR-002 | Combined signal: `.orchestrator-active` present AND `plan/current/` empty uniquely identifies an interrupted P9. **Superseded:** 0000032-ADR-002 keeps the signal but reads it as an unfinished P8 or P9. Resume Detection step 2a resumes from archive evidence and never starts fresh. |
| ADR-002 | New Session Recommendation Not Block | superseded by 0000032 ADR-003 | Post-P9 advisory message recommends a new session but does not enforce it; human retains control. **Superseded:** 0000032-ADR-003 makes ship Step 12 a blocking context clear. The orchestrator refuses new work in the same session. |
| ADR-003 | Stale Run-Mode Warn-and-Clear at P0 | accepted | Stale `plan/.run-mode` at fresh P0 start is auto-cleared with a visible warning; no blocking |
| ADR-004 | Run-Mode Deletion Owned by P9 | amended by 0000032 ADR-002 | P9 (ship-agent Step 6) deletes `plan/.run-mode`; P0 handles the recovery case only. **Amended:** 0000032-ADR-002 keeps P9 as the owner but moves the deletion out of Step 6. A P9 marker step now deletes all three session markers after P8 and before the Step 9 tag. |

### Feature 0000016: pipeline-governance-and-loop-engineering

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Backlog Folder Instead of Editable Post-Archive Lifecycle | accepted | Deferred work lives in `plan/backlog/{id}-{slug}/`, surfaced at the next P0; P7 stays the lock line: bug-bounty-hunter PR #4's editable-P7–P9 design rejected |
| ADR-002 | product.yml with versionPolicy | amended by 0000026 ADR-001 | Root `product.yml` aggregates one release version across components (`max-component-version` \| `explicit` \| `external`); single-component projects keep component.yml behaviour. **Amended:** 0000026 ADR-001 changes `components[]` under `max-component-version` from a cached `{id, version}` to a `{id, path}` pointer, read live by `product-version.mjs` at derivation time: eliminates the P9 sync-drift risk the cached copy created |
| ADR-003 | Loop Toggles in planifest-overrides/loop-toggles.yml | amended by 0000033 ADR-004 and 0000036 ADR-009 | Per-loop `off \| report-only \| on`; user-owned directory so agents cannot self-enable; absent = all off, except `design_critic`. **Amended:** 0000033-ADR-004 reads an absent key as `on` for five named keys in `autonomous` only, and checkers start at `on`, not `report-only`. **Amended:** 0000036-ADR-009 reads an absent `design_critic` key, or an absent file, as `report-only` outside `autonomous`. |
| ADR-004 | Single-Use Marker File for Approved Weakening | amended by 0000017 ADR-001 | Human-created `plan/current/.ratchet-approve` (path per line, consumed on use) is the only path past the ratchet; agents prohibited from writing it. **Amended:** 0000017 ADR-001 permits the agent to write the marker on explicit in-the-moment human instruction, extends the format to `path \| reason \| timestamp`, and keeps the same-changeset backstop with an explicit approver message. |
| ADR-005 | Cascade Threshold of 3 Artifacts | amended by 0000033 ADR-003 | A reversal invalidating >3 downstream artifacts always stops for the human, regardless of run mode. **Amended:** 0000033-ADR-003 lets an additive cascade over 3 artifacts proceed in `autonomous` with a build-log record. An altering reversal still waits as a gross deviation. |
| ADR-006 | Verifiers as Fresh-Context REJECT-Default Subagents | accepted | Critic, assessor, and cross-model reviewer never share context with the maker; approval requires cited positive evidence |
| ADR-007 | Deterministic Caps, Budget, and Ratchet Enforcement | accepted | Iteration caps (3 default, P4 keeps 5), reversal budget (2/feature), and weakening blocks are enforced by hooks + control flow over git-tracked state, never skill prose alone |
| ADR-008 | Cross-Model Review Gate at End of P6, Pre-Archive | accepted | The second-model review runs while implementation is live and editable; the brief's original "before P9" placement was structurally self-contradictory and is corrected |

### Feature 0000017: ratchet-forgery-detection-and-telemetry-schema-spec

ADR files: [plan/_archive/0000017-ratchet-forgery-detection-and-telemetry-schema-spec-2026-07-26/adr/](../plan/_archive/0000017-ratchet-forgery-detection-and-telemetry-schema-spec-2026-07-26/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Ratchet-Approve: Agent Write on Explicit Instruction | accepted | Amends 0000016 ADR-004: agent may write `.ratchet-approve` only when the human states path, reason, and go-ahead in the same turn; format `path \| reason \| timestamp`; immediate dedicated commit; backstop kept with an explicit approver-facing message; consumption copied to `plan/ratchet-audit-log.md` |
| ADR-002 | Cross-Platform Hook Runtime Unification (.sh → .mjs) | partly superseded by 0000030-ADR-002 | The 3 context-mode hooks become `.mjs` (Node-only): removes `jq` and the Git Bash/WSL requirement entirely; missing Node surfaces a message at setup and runtime while failing open |
| ADR-003 | Scope Lock Suggested Answers via On-Demand Subagent | superseded by 0000025 ADR-003 | The orchestrator always offers "want me to suggest an answer?" at each Scope Lock question but only dispatches `planifest-scope-lock-agent` on explicit request; drafts are usage-only, consistency-checked, flagged, and never self-confirming. **Superseded:** 0000025-ADR-003 reverses the never-pre-draft, offer-then-opt-in default for the Scope Lock Challenge specifically, replacing it with default parallel drafting and batch presentation; per-item explicit accept/edit/reject and immediate build-log capture are unchanged |
| ADR-004 | Structured P0 Discovery Pass and discovery.md Lifecycle | accepted | Every adoption mode runs a structured discovery pass before coaching, writing to `plan/current/discovery.md`: fresh each run, archived at P7; partial failures noted inline, never a hard block |

### Feature 0000018: telemetry-emission-consistency

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Unify Telemetry Gating by Removing the --context-mode-mcp Coupling | superseded by 0000030-ADR-002 | Removes the `--context-mode-mcp` AND-condition from telemetry hook installation: `--structured-telemetry-mcp` alone becomes sufficient, closing the exact gap that caused 0000017's telemetry loss |
| ADR-002 | Telemetry Failure Detection and Interactive Recovery | superseded by 0000030-ADR-002 | Hook-driven emission stays fire-and-forget (ADR-005, 0000003, unchanged) but now writes a durable failure marker on error, checked by the orchestrator at phase-start checkpoints; agent-driven emission stops and asks immediately inline. Human is asked once per distinct root cause per run |
| ADR-003 | discovery.md Elevated to Hard Limit Status | accepted | discovery.md's existence-and-completeness requirement elevated to Hard Limit status, matching the pattern of the build-log rule (orchestrator Hard Limit 8): a self-audit finding from this feature's own P0 |

### Feature 0000019: self-description-and-session-hygiene-fixes

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Repository self-description check is a separate script | accepted | `self-description-check.mjs` is a new, repository-scoped script wired into CI, deliberately not folded into `consistency-check.mjs`: different subject (repo self-description vs. `plan/current/`), different lifecycle (every PR vs. per-feature), different caller |
| ADR-002 | context_pressure telemetry events map to phase: "orchestrator" | superseded by 0000030-ADR-002 | Fixes an unconditional HTTP 400 (invalid `phase` enum value `"monitoring"`) discovered live during this feature's own P0; maps to `"orchestrator"` as the semantically closest existing value, consistent with context hygiene being framed as an orchestrator responsibility |

### Feature 0000020 - setup-refresh-skill

ADR files: [plan/_archive/0000020-setup-refresh-skill-2026-08-01/adr/](../plan/_archive/0000020-setup-refresh-skill-2026-08-01/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Hardcoded, non-extensible deletion allowlist | accepted, hardened in P5 | The refresh skill's deletion capability is restricted to exactly `CLAUDE.md`/`AGENTS.md`. Originally a SKILL.md-prose-only rule; a P5 security finding (no deterministic backstop, unlike gate-write.mjs for writes) led to extracting the allowlist into `refresh-delete-boot-files.sh`/`.ps1`, hardcoded in code |
| ADR-002 | Single marker file, dual purpose | accepted | `.planifest-setup-flags` serves as both the install-time flag record (written by setup.sh/setup.ps1) and the refresh skill's retry/recovery cache, not two separate files, avoiding a synchronisation problem between overlapping state |
| ADR-003 | Mandatory human confirmation gate | accepted | The refresh skill always halts for explicit confirmation before any destructive action, in every run, including all-high-confidence runs; no bypass exists |
| ADR-004 | Explicit tool selection, not auto-resolved | accepted | The target tool is always named by the human on the loop or asked for up front; multiple installed tools is normal input, not an ambiguity to guess through. Corrected mid-P0 after an early draft conflated this with a failure condition |
| ADR-005 | No automatic retry on setup failure | accepted | On a failed setup re-invocation the skill stops, investigates the likely cause, and reports; retry is always a fresh, human-initiated invocation, never automatic |

### Feature 0000024: declared-product-id-for-telemetry

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | product.yml Extended to Single-Component Projects as Declared Product ID Home | partly superseded by 0000030-ADR-007 (rationale only) | `product.yml`'s `id` field becomes the canonical declared `product_id` for telemetry across all projects, including single-component ones; extends (does not supersede) 0000016 ADR-002, whose versioning-only decision remains fully in force |

### Feature 0000025: pipeline-gate-and-config-fixes-and-ship-agent-fixes

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Ship-agent PR Footer Default-Off with Opt-In Toggle | accepted | The hardcoded AI-attribution footer is removed from the P9 PR description template by default (both `gh pr create` and human-push paths); restorable only via a `planifest-overrides/instructions/` opt-in file, consistent with the existing `local-git-only` override pattern |
| ADR-002 | Setup-Config Overrides Precedence | accepted | The new tracked `planifest-overrides/setup-config/{tool}.md` file is source of truth for setup flags; the existing gitignored `.planifest-setup-flags` marker becomes a local cache reconciled to match it on setup/refresh; `.orchestrator-strict` explicitly out of scope (separate concern) |
| ADR-003 | Scope Lock Default Drafted, Batch-Presented | accepted | Scope Lock Challenge now dispatches `planifest-scope-lock-agent` for all four scenario-path questions in parallel by default and presents them together for one batch accept/edit/reject pass: supersedes 0000017-ADR-003's opt-in-per-question default; explicitly scoped against 0000014-ADR-008's one-question-at-a-time convention, which is unchanged everywhere else |

### Feature 0000026: context-hook-and-telemetry-backstop-fixes

ADR files: [plan/_archive/0000026-context-hook-and-telemetry-backstop-fixes-2026-08-08/adr/](../plan/_archive/0000026-context-hook-and-telemetry-backstop-fixes-2026-08-08/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | product.yml components[] as Path Pointers, Not Cached Versions | accepted | Amends 0000016-ADR-002: under `versionPolicy: max-component-version`, `components[]` holds `{id, path}` pointers to each component's own `component.yml` instead of a cached `{id, version}`; `product-version.mjs` reads the live version at derivation time, closing the sync-drift gap that surfaced during this feature's own ship review |

### Feature 0000027: backlog-batch-governance-tooling-fixes

ADR files: [plan/_archive/0000027-backlog-batch-governance-tooling-fixes-2026-08-08/adr/](../plan/_archive/0000027-backlog-batch-governance-tooling-fixes-2026-08-08/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Telemetry emit_event Receipt Backstop | superseded by 0000030-ADR-002 | Extends the `check-telemetry-failures.mjs` hook family with a new `emit-event-receipt.mjs` (PostToolUse, matched on the `emit_event` MCP tool call) writing a durable receipt per successful call, and `check-telemetry-receipts.mjs` (sibling hook) cross-referencing build-log's per-phase "Telemetry: emitted" claims against those receipts: closes the remaining half of backlog 0000044 not already covered by 0000026 |
| ADR-002 | Framework Update Policy as a New P0 Step | accepted | Adds a dedicated P0 Start Actions step (Resume Detection 1a) detecting a `planifest-framework/` dependency update and gating on human confirmation of both the update and its provenance, documented in `standards/framework-update-policy.md`: deliberately not an extension of `planifest-migrator` (different I/O shape) nor a new standalone skill (disproportionate to the mechanism's actual complexity) |
| ADR-003 | Skill-Scope Principle: Does This Skill Earn Its Place | accepted | Records the governance test (does this skill provide governance or traceability the host tool cannot) with `planifest-test-writer`/`implementer`/`refactor`/`verify-by-execution` as worked examples (three retain, one retain-marginal); referenced from the orchestrator's Capability Skills guidance for future skill additions |
| ADR-004 | Minimal Default Phase 1 Artifact Set | accepted | Names execution plan, requirements, scope, risk register, and domain glossary as the always-produced Phase 1 set; OpenAPI/Operational Model/SLO Definitions/Cost Model each gated by an explicit, checkable trigger condition: reflected identically in `feature-pipeline.md` and `planifest-spec-agent`, closing the "documentation theatre" gap from backlog 0000021 |

### Feature 0000028: telemetry-hardening-and-enforcement-fixes

ADR files: [plan/_archive/0000028-telemetry-hardening-and-enforcement-fixes-2026-08-08/adr/](../plan/_archive/0000028-telemetry-hardening-and-enforcement-fixes-2026-08-08/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Network-Level Retry Semantics for Telemetry Emission | superseded by 0000030-ADR-002 | A telemetry emission failure is retried only when it is network-level, identified by `!err.name.startsWith("http_")`; an HTTP 4xx or 5xx means a listener answered and rejected the event and is never retried. Budget: 2 retries, 3 attempts total, fixed 300ms gaps, on top of the unchanged 3s per-attempt abort. Retry exhaustion writes the durable marker exactly as before, so a genuinely-down backend still surfaces. Narrows the definition of failure rather than adding a queue, which NFR-002 forbids |
| ADR-002 | Shared Module Placement and Install Topology | partly superseded by 0000030-ADR-002 | Each duplicated helper becomes one module inside the existing `hooks/enforcement/` and `hooks/telemetry/` trees, never a new top-level `shared/` directory that would need its own install glob in all three `setup.sh` paths. Placement follows install condition: `enforcement/` installs unconditionally, `telemetry/` only under `--structured-telemetry-mcp`, so any helper with an enforcement caller lives in `enforcement/` and is imported cross-directory. `read-stdin.mjs` was moved to `enforcement/` mid-implementation for exactly this reason, and its copy count was 13, not the 7 first recorded. Tier 1's telemetry glob widened from `emit-phase-*.mjs` to `*.mjs` in both `setup.sh` and `setup.ps1`, a latent bug independent of the extraction. No commit may contain a caller importing a module absent from that same commit |
| ADR-003 | Em Dash Guard Attachment Point and Bypass | accepted | The guard is a `PreToolUse(Write, Edit)` hook, `hooks/enforcement/em-dash-guard.mjs`, sibling to `gate-write.mjs` rather than a modification of it, so a defect in one cannot disable the other. A git hook was rejected because the character would already be on disk by commit time. Scoped to five prefixes: `plan/current/`, `docs/`, and `planifest-framework/` skills, templates and standards. Since Claude Code offers no per-call skip flag, the bypass is an in-content sentinel comment, visible in the artifact's own diff, reusable and writable by either party, deliberately unlike `.ratchet-approve`, which guards a commitment being weakened rather than a single character of punctuation |
| ADR-004 | Self-Modification Sequencing for Hook Extraction and Reinstall | accepted | When a feature rewrites the hooks executing its own build, rewire one caller at a time: edit, commit, re-run `setup.sh` for that edit alone, then assert a real side effect (event received, marker written, process spawned), never merely that the process returned. Exit 0 is uninformative by design (NFR-001), so a hook broken mid-edit degrades to a silent no-op, and an ESM import of a missing module fails before the hook's own try/catch runs. One `setup.sh` re-run at the end was rejected because it collapses good straight to multiply-broken with no way to bisect. A separate worktree was rejected outright by repo instruction |

### Feature 0000029: context-mode-removal-and-boot-file-regeneration-fix

ADR files: [plan/_archive/0000029-context-mode-removal-and-boot-file-regeneration-fix-2026-08-09/adr/](../plan/_archive/0000029-context-mode-removal-and-boot-file-regeneration-fix-2026-08-09/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Boot Files Are Disposable Build Outputs | accepted | `write_boot_file`/`Write-PlanifestBootFile` overwrite the boot file unconditionally on every setup run; the skip-if-exists guard protected hand-editing, a workflow the framework does not support, while silently blocking template fixes from ever reaching installed repos. Durable customization belongs exclusively in `planifest-overrides/instructions/`, re-applied every run |
| ADR-002 | Boot Templates Never Name Third-Party MCP Plugins | accepted | Removes the unconditional third-party plugin instruction from `templates/standard-boot.md` (shipped into 6 of 9 tools' boot files) after the plugin injected a fabricated system-reminder instructing the agent to conceal a change from the human. Standing rule: boot-file text is trusted instruction text and never endorses a named third-party plugin; tool availability belongs to host-tool configuration, not template prose. The opt-in hook path was untouched at the time |

### Feature 0000030: context-mode-and-telemetry-mcp-removal

ADR files: [plan/_archive/0000030-context-mode-and-telemetry-mcp-removal-2026-10-14/adr/](../plan/_archive/0000030-context-mode-and-telemetry-mcp-removal-2026-10-14/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stack Unchanged | accepted | The feature removes code and keeps the declared stack: Bash, PowerShell, Node `.mjs` hooks, Markdown, and GitHub Actions |
| ADR-002 | Remove the Context Mode and Telemetry MCP Integrations Completely | accepted | Both optional MCP integrations leave the framework entirely, including pipeline text, and their earlier ADRs become superseded |
| ADR-003 | Retired Flags Stay Accepted as No-Ops | accepted | Setup keeps accepting `--context-mode-mcp`, `--structured-telemetry-mcp`, and `--backend-url`, prints a one-line notice, and never records them |
| ADR-004 | Setup Clean-Up Is Always On, Path-Matched, and Fails Open | accepted | Every setup run removes stale integration state by exact path match, writes atomically, and never blocks the install |
| ADR-005 | Setup Takes Ownership of Retiring Telemetry State | accepted | `setup-hook-integration` owns removal of every stale artifact, including the `plan/.telemetry-*` folders the old hooks wrote |
| ADR-006 | Self-Hosting Order and Migration Last | accepted | This repo removes its own wiring in one final step, entries before files, and the downstream migration file is the last P3 commit |
| ADR-007 | Keep the Product ID Hard-Stop With a New Rationale | accepted | The P0 hard-stop on `product.yml` `id` stays, now justified by versioning and archive attribution rather than telemetry |

### Feature 0000031: ci-test-and-powershell-coverage

ADR files: [plan/_archive/0000031-ci-test-and-powershell-coverage-2026-10-16/adr/](../plan/_archive/0000031-ci-test-and-powershell-coverage-2026-10-16/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | CI platform matrix | accepted | The suite runs on `ubuntu-latest` and `macos-latest` with `fail-fast: false`, and `test_setup.ps1` runs under PowerShell 7 on `windows-latest`. Windows PowerShell 5.1 and Git Bash on Windows are not tested. |
| ADR-002 | New CI jobs stay repository-only | accepted | The suite and Windows jobs go in this repository's workflow only, never in the consumer copy at `planifest-framework/hooks/planifest.yml`. Extends 0000019-ADR-001. |
| ADR-003 | CI job security posture | accepted | New jobs keep the `pull_request` trigger and set `permissions: contents: read`, no secrets, and `timeout-minutes: 10` |

### Feature 0000032: governance-continuity-and-write-gate-scope

ADR files: [plan/_archive/0000032-governance-continuity-and-write-gate-scope-2026-10-17/adr/](../plan/_archive/0000032-governance-continuity-and-write-gate-scope-2026-10-17/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stack and enforcement approach | accepted | Hooks stay dependency-free Node ES modules that read stdin through `read-stdin.mjs` and fail open. Setup stays in Bash and PowerShell, and tests stay in Bash suites. |
| ADR-002 | Session markers cleared in P9 before the tag | amended by 0000033 ADR-011 | The three session markers stay committed. A P9 step deletes and commits them with the archive after P8 and before the Step 9 tag. Resume Detection steps 2a and 2b resume an interrupted close-out from archive evidence. Supersedes 0000015-ADR-001 and amends 0000015-ADR-004. **Amended:** 0000033-ADR-011 makes that marker-step commit the run's closing archive commit, which must carry the P8 `build-report.md`. |
| ADR-003 | Blocking context clear after P9 | accepted | Ship Step 12 asks for `/clear` or a new session and refuses new work in the same session. The auto-trigger hook says no run is active and requires triage. Handover notes route every next step through a track. Supersedes 0000015-ADR-002. |
| ADR-004 | Shared path rules and repository root | extended by 0000035 ADR-005 to ADR-008 | `path-rules.mjs` holds the gated-path rules for `gate-write.mjs` and the shell guard. The root is the nearest `planifest-framework/` folder, else the nearest `.git`, found by a walk from `CLAUDE_PROJECT_DIR` or `cwd`. Targets outside the root pass. **Extended:** 0000035 adds link resolution, the lookup for a deleted `cwd`, `ratchet-check.mjs` as a third importer, and distrust of planted markers. |
| ADR-005 | Block reasons on stderr | accepted | Every enforcement hook that exits 2 writes a plain-text reason to stderr, where Claude Code reads it. Existing stdout stays byte for byte for the adapters. |
| ADR-006 | Heuristic Bash shell-write guard | accepted | `shell-write-guard.mjs` runs on Claude Code's Bash PreToolUse event. It finds common shell writers, judges their targets with `path-rules.mjs`, and fails open on anything it can't parse. A boot-file Hard Limit covers its gaps. |

### Feature 0000033: human-on-the-loop-run-mode

ADR files: [plan/_archive/0000033-human-on-the-loop-run-mode-2026-10-19/adr/](../plan/_archive/0000033-human-on-the-loop-run-mode-2026-10-19/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stack unchanged, new detail in standards files | accepted | The declared stack of Markdown skills and Node `.mjs` scripts stays. New autonomous, sizing, and dispatch detail goes into standards files that the skills link to. |
| ADR-002 | Autonomous as a third run-mode value | accepted | `plan/.run-mode` gains `autonomous`, which sets both `continuous_run` and `autonomous_run`. Unknown values still read as `interactive`. P0 also writes a build-log Run mode row. Amends 0000012-ADR-005. |
| ADR-003 | Declared exception list | accepted | In `autonomous`, only six declared items wait for the human on the loop. Every other question becomes a recorded decision. A product can add items in `planifest-overrides/exception-list.yml` but can't remove any. Amends 0000016-ADR-005. |
| ADR-004 | Gates as loops with fresh checkers | amended by 0000036 ADR-009 | In `autonomous`, every P1 to P6 gate runs as a loop under `planifest-loop-runner` with a named checker. Five toggle keys read as `on` when absent. Amends 0000016-ADR-003. **Amended:** 0000036-ADR-009 reads an absent `design_critic` key as `report-only` outside `autonomous`. The `autonomous` default of `on` is unchanged. |
| ADR-005 | Approach budget per loop instance | accepted | A loop that hits its cap or the no-progress rule starts a new approach. Each loop instance allows 3 approaches, and a fourth becomes an exhausted-budget exception. The reversal budget stays at 2. |
| ADR-006 | Ship without asking in autonomous | accepted | In `autonomous`, P7 to P9 ask nothing. P9 always raises the PR, as a draft when an exception waits. Merging stays human-only. Amends 0000012-ADR-004 and 0000004-ADR-003. |
| ADR-007 | P0 real forks and one confirmation turn | accepted | P0 asks only real forks. The design, the Scope Lock batch, and the run mode confirm in one turn, which is the second named exception to 0000014-ADR-008. |
| ADR-008 | Release budget in size points | accepted | A product sets a target and a ceiling in size points in `planifest-overrides/release-budget.yml`. P0 sizes each candidate and recommends a fill. An absent or invalid file keeps the three-story rule. |
| ADR-009 | Fast Path admits no-src changes | extended by 0000035 ADR-004 | Fast Path's prerequisite relaxes to admit a change with no `src/` target. Its four criteria stay word for word. **Extended:** 0000035-ADR-004 makes the enforcement path rule a concrete list in code. |
| ADR-010 | Archive script replaces glob delete | accepted | P7 Step 6 runs `archive-current.mjs`, which moves each item with `git mv` and deletes only four sentinels by explicit path. `plan/current/.archive-target` lets a stopped archive resume. Supersedes 0000003-ADR-006. |
| ADR-011 | Close-out commit and leftovers | accepted | The P8 build report reaches git in the 0000032 P9 marker-step commit. P8 and P9 each end with a scoped clean-tree check. Leftovers are committed by explicit path in `autonomous`. Amends 0000032-ADR-002. |
| ADR-012 | Revalidate after P6 | accepted | After its last P6 edit, the docs agent reruns the P4 check set or a smaller command declared in `planifest-overrides/doc-checks.yml`. A failure enters a loop capped at 5 that fixes the doc edit, never the check. |
| ADR-013 | Parallel streams toggle and state | accepted | A `parallel_streams` loop toggle, on by default in `autonomous`, moves independent requirements through P1 to P4 as separate streams. Each stream keeps a committed state file. |
| ADR-014 | Orchestrator owns joins and a reconcile script | accepted | The orchestrator owns every join between streams or batches. It runs `scripts/stream-reconcile.mjs` after each join and before the gate check. A finding blocks the gate and enters a fix loop capped at 3. |
| ADR-015 | Data ownership of run state and overrides | accepted | `planifest-framework` owns `plan/.run-mode`, `plan/current/` with its `streams/` folder, and `plan/current/.archive-target`. The human on the loop owns the `planifest-overrides/` files, which the framework only reads. |

### Feature 0000035: write-gate-scope-and-path-hardening

ADR files: [plan/_archive/0000035-write-gate-scope-and-path-hardening-2026-10-22/adr/](../plan/_archive/0000035-write-gate-scope-and-path-hardening-2026-10-22/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stack unchanged, gate code on Node built-ins with no spawn | accepted | Every new gate rule lives in `path-rules.mjs` on `node:fs` and `node:path` only. The module imports no `node:child_process`, and a suite source check asserts it. |
| ADR-002 | Fast Path scope record as self-authorisation | accepted | A Fast Path change lists its targets in `plan/.fast-path-scope`. Both write gates accept a valid, current record when `design.md` is absent. Each admitted write prints a stderr notice, and the changelog lists every path. |
| ADR-003 | Scope record staleness from git files | accepted | The record stores its branch and `HEAD`. The gate reads both from `.git` files with no spawn. It ignores the record when either differs or git state can't be read. |
| ADR-004 | Fast Path enforcement path list | accepted | `FAST_PATH_ENFORCEMENT_PATHS` covers hook folders, hook wiring, tool-local settings, setup scripts, the CI workflow, and `.git/`. A scope record never admits a match. Matching folds case and NFKC lookalikes. Extends 0000033-ADR-009. |
| ADR-005 | Links resolved segment by segment, fail closed | accepted | `resolveTarget` walks each segment through links, with a 40-hop limit. `resolveTargetBoth` also judges the placement with `..` collapsed as text. A resolution error inside the root blocks with exit 2. |
| ADR-006 | Root lookup when `cwd` is deleted | accepted | `resolveRoot` checks `CLAUDE_PROJECT_DIR` first, then walks from the nearest existing parent of `cwd`. Hooks fall back from stdin `cwd` to `process.cwd()` to `CLAUDE_PROJECT_DIR`. |
| ADR-007 | ratchet-check uses the shared path rules | accepted | `ratchet-check.mjs` imports `resolveRoot` and `resolveTargetBoth` from `path-rules.mjs`, so it finds `plan/current/` from any subfolder. It passes an unresolvable target and leaves that block to `gate-write.mjs`. |
| ADR-008 | Distrust markers under always-permitted names | accepted | `markedRoot` ignores a `.git` or `planifest-framework` marker below an always-permitted name. The walk goes on to the next trusted marker. |
| ADR-010 | `product.yml` set in P7 by a script | accepted | The ship agent runs `set-product-release.mjs` after P7 Step 5 and before Step 6. The script applies each `versionPolicy` and exits 0, 2, 4, or 5. The ship agent owns `product.yml`. |
| ADR-011 | Sanctioned scripts in the Write-or-Edit rule (boot Hard Limit 8) | accepted | Both boot templates carry one `Sanctioned scripts:` sentence that names seven fixed framework scripts. Each counts only with the arguments its skill step shows. No other script counts. |
| ADR-012 | Acceptance-criteria limit and warning | accepted | `consistency-check.mjs` allows up to 10 criteria per requirement. From 4 to 10 it warns and exits 0. Above 10 it reports a finding. The brief template still asks for 3. |
| ADR-015 | Migration files never move | accepted | Every migration stays at the top level of `planifest-framework/migrations/`, and the old completed-migrations folder goes away. Supersedes the archive step of 0000005-ADR-005. |
| ADR-016 | Per-project migration run records | accepted | Each project records each run at `plan/_migrations/{stem}.md`. The frontmatter holds six fields and one outcome: `applied`, `not applicable`, or `skipped`. |
| ADR-017 | Migration records owned by the migrator | accepted | `planifest-migrator` is the only writer of `plan/_migrations/`. Orchestrator resume detection reads the records and never writes them. |
| ADR-018 | Pending means no readable record | accepted | A migration is pending when its record is missing or can't be read. Resume detection reads only top-level migration files and ignores orphan records. |
| ADR-019 | Records come from scans, never seeded | accepted | No record is seeded from the old completed-migrations folder. Each record comes from a scan. A scan with findings writes no record until the human on the loop answers every batch. |

### Feature 0000036: pipeline-friction-and-gate-fixes

ADR files: [plan/current/adr/](../plan/current/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stack unchanged, gate and hook output code on Node built-ins with no spawn | accepted | No new language, runtime, or library. The new gate rules live in `path-rules.mjs` on `node:fs` and `node:path`. The changed hooks add no spawn, and `ratchet-check.mjs` keeps its one `git` spawn. A suite checks the source of the five files. |
| ADR-002 | A non-regular design.md reads as no design | accepted | `evaluateWrite` calls `lstatSync` on `design.md` before any read. A folder, FIFO, link, other non-regular file, swapped file, or file over 1 MiB reads as no design. Only `EACCES` and `EPERM` fail open. Narrows 0000003-ADR-005 for this step only. |
| ADR-003 | The always-permitted file-name shortcut skips enforcement paths | accepted | The file-name shortcut applies only when `isEnforcementPath(relPath)` is false. A permitted name inside an enforcement path goes to the `design.md` step. The `plan/` and `docs/` prefix shortcut is unchanged. Extends 0000033-ADR-009. |
| ADR-004 | shown() cuts at whole units, and two more hook outputs use it | accepted | `shown(p, max)` builds its output from whole units, so a cut never ends inside an escape or a surrogate pair. `ratchet-check.mjs` and `em-dash-guard.mjs` quote their targets through it at a cap of 200. Extends 0000032-ADR-004. |
| ADR-005 | Drift check is a warn-only Node script | accepted | `scripts/skill-drift-check.mjs` compares `SKILL.md` text only, after it applies setup's four path rewrites. It finds the active tool from the setup marker. It exits 0, 1, or 2, writes nothing, and never blocks. |
| ADR-006 | Setup-delivered files follow what setup copies | accepted | A setup-delivered file is one that `setup.sh` or `setup.ps1` copies or writes. The definition follows setup, copy-all fallback included. A release that changes one ships a re-run-setup migration. |
| ADR-007 | The 0.34.0 migration targets the framework source too | accepted | `migrate-0.34.0-rerun-setup.md` names every project with an installed setup, this repo included. P6 re-runs setup here after the last change and then writes the `applied` record. **Departs from** the 0.31.0 migration, whose `**Target:**` line names a downstream project only. |
| ADR-008 | Run-mode anchor as a bare line or one list item | accepted | An anchor matches `^(- )?Run mode confirmed: autonomous (<UTC timestamp>)$` as a whole line. Every other prefix or trailing text is no anchor. The one-commit rule, the removal rule, and the read cap stay strict. |
| ADR-009 | Design critic reads as report-only by default | accepted | Outside `autonomous`, an absent `design_critic` key or an absent `loop-toggles.yml` reads as `report-only`. `autonomous` keeps `on`. An explicit value wins. Amends 0000016-ADR-003 and 0000033-ADR-004. |
| ADR-010 | Hard limits cited by name and source | accepted | Every citation reads `the {name} rule ({source} Hard Limit {N})`. No list renumbers. Headings and the dispatch template use the same form. A suite fails on a bare citation. |
| ADR-011 | Split step before a fourth criterion | accepted | Before an agent adds a fourth criterion, it asks whether the requirement holds two concerns. Yes means a split by addition only. An existing criterion moves only when no loop is active or the human on the loop gives an approve line. Extends 0000035-ADR-012. |
| ADR-012 | Commit subjects without placeholders | accepted | No commit subject template holds `{`, `}`, `<`, or `>`. The P7 archive, P9 marker, and P9 final report subjects name the phase and action. The feature ID moves to a second `-m` message. |

---

*Template: decisions-index.template.md*
