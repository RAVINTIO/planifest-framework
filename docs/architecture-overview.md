# Architecture Overview

> Living document. Reflects current system state. Updated after every pipeline run.
> Do not archive this file; update it in place.

Last updated: 0000035-write-gate-scope-and-path-hardening (22 Oct 2026)

---

## System Summary

Planifest is a CLI tooling framework that enforces a structured design pipeline for agentic coding agents. It installs enforcement hooks into agentic IDEs (Claude Code, Cursor, Windsurf, GitHub Copilot, Codex) that gate writes to `src/` behind a confirmed design document, and provides a suite of pipeline skills (spec, ADR, codegen, validate, security, docs, ship) that guide development from brief to merged PR.

---

## Components

| Component | Type | Purpose | Status |
|-----------|------|---------|--------|
| `setup-hook-integration` | component-pack | setup.sh/ps1 and skill-sync: installs enforcement hooks, commit standards, external skill management, and (0000020) a per-tool flags-used marker into any Planifest-managed project | active |
| `planifest-refresh-setup` | skill (standalone, not a src/ component) | Detects a Planifest install's target tool, reconstructs the setup flags in effect from the flags-used marker or hook wiring, confirms with the human on the loop, and safely re-invokes setup.sh/setup.ps1; see `planifest-framework/skills/planifest-refresh-setup/SKILL.md` | active |

---

## Communication Patterns

```mermaid
flowchart TD
    subgraph IDE["Agentic IDE (Claude Code / Cursor / Windsurf / Copilot / Codex)"]
        Agent["Agent"]
        HookRunner["Hook Runner\n(PreToolUse / UserPromptSubmit)"]
    end

    subgraph Adapters["Hook Adapters (planifest-framework/hooks/adapters/)"]
        CUR["cursor.mjs"]
        CPL["copilot.mjs"]
        WS["windsurf.mjs"]
        CDX["codex.mjs"]
    end

    subgraph Enforcement["Enforcement Scripts (hooks/enforcement/)"]
        GW["gate-write.mjs\n(path allowlist + sentinel check,\nreason on stderr, 0000032)"]
        SWG["shell-write-guard.mjs\n(Bash shell writers judged by\nthe same rules, Claude Code only, 0000032)"]
        PR["path-rules.mjs\n(shared gated-path rules, repository root,\nlink resolution, scope record, 0000032/0000035)"]
        CD["check-design.mjs\n(scope injection)"]
        RC["ratchet-check.mjs\n(criteria/scope weakening block,\narmed while a loop is active,\nshared root rules, 0000035)"]
        ED["em-dash-guard.mjs\n(U+2014 rejected in Planifest prose,\nsentinel bypass, 0000028)"]
        SHE["read-stdin.mjs\n(shared module, always installed)"]
    end

    subgraph Scripts["Scripts (planifest-framework/scripts/, 0000033)"]
        ARC["archive-current.mjs\n(P7 archive by explicit path)"]
        SRC["stream-reconcile.mjs\n(join reconciliation)"]
        RMD["run-mode.mjs\n(effective run mode)"]
        SPR["set-product-release.mjs\n(P7 product.yml update, 0000035)"]
    end

    subgraph Setup["Setup (planifest-framework/)"]
        SH["setup.sh / setup.ps1"]
        SS["skill-sync.sh / skill-sync.ps1"]
    end

    subgraph Skills["Pipeline Skills (P0–P9)"]
        ORCH["planifest-orchestrator\n(P0)"]
        SPEC["planifest-spec-agent\n(P1)"]
        ADR["planifest-adr-agent\n(P2)"]
        CG["planifest-codegen-agent\n(P3)"]
        VAL["planifest-validate-agent\n(P4)"]
        SEC["planifest-security-agent\n(P5)"]
        DOCS["planifest-docs-agent\n(P6)"]
        SHIP["planifest-ship-agent\n(P7–P9)"]
        BA["planifest-build-assessment-agent\n(P8, sub-agent of ship-agent)"]
    end

    Agent -->|"plans Write/Edit"| HookRunner
    Agent -->|"plans Bash"| HookRunner
    Agent -->|"submits prompt"| HookRunner
    HookRunner -->|"stdin JSON"| CUR
    HookRunner -->|"stdin JSON"| CPL
    HookRunner -->|"stdin JSON"| WS
    HookRunner -->|"stdin JSON"| CDX
    CUR -->|"common envelope"| GW
    CUR -->|"common envelope"| CD
    CPL -->|"common envelope"| GW
    CPL -->|"common envelope"| CD
    WS -->|"common envelope"| GW
    WS -->|"common envelope"| CD
    CDX -->|"common envelope"| GW
    CDX -->|"common envelope"| CD
    GW -->|"exit 0 (pass) / exit 2 (block)"| HookRunner
    CD -->|"additionalContext JSON"| HookRunner
    HookRunner -->|"stdin JSON (Write/Edit)"| ED
    ED -->|"exit 0 (pass) / exit 2 (block)"| HookRunner
    HookRunner -->|"stdin JSON (Bash, Claude Code)"| SWG
    SWG -->|"exit 0 (pass) / exit 2 (block, reason on stderr)"| HookRunner
    GW -.->|"imports"| PR
    SWG -.->|"imports"| PR
    RC -.->|"imports"| PR
    SPR -.->|"imports resolveRoot"| PR
    SWG -.->|"imports"| SHE
    GW -.->|"imports"| SHE
    CD -.->|"imports"| SHE
    RC -.->|"imports"| SHE
    ED -.->|"imports"| SHE

    SH -->|"copies skills + writes hook configs"| IDE
    SS -->|"syncs on re-run"| IDE

    ORCH -.->|"calls"| SRC
    ORCH -.->|"calls"| RMD
    SHIP -.->|"calls"| ARC
    SHIP -.->|"calls"| RMD
    SHIP -.->|"calls at P7"| SPR

    ORCH --> SPEC --> ADR --> CG --> VAL --> SEC --> DOCS --> SHIP
```

---

## Governance Loops (0000016)

The pipeline has an optional loop layer, entirely toggle-gated via `planifest-overrides/loop-toggles.yml` (absent = all off; zero-config behaviour identical to pre-0000016):

| Loop | Seam | Verifier | Deterministic guard |
|------|------|----------|--------------------|
| P0 completeness | P0 exit | Gate checklist re-evaluated per coaching round | 2-rounds-per-gap escalation |
| Design critic | End of P1/P2 | Fresh-context `planifest-design-critic` (REJECT-default) + `scripts/consistency-check.mjs` | Cap 3, no-progress halt |
| Governed reversal | P3–P6 blocked by upstream P0–P6 artifact | Fresh-context `planifest-reversal-assessor` (DENY-default) | Budget 2/feature, cascade >3 human gate, ratchet-check.mjs on writes |
| Verify-by-execution | P4 after CI | `planifest-verify-by-execution` (runs the software) | Feeds existing P4 cap-5 loop |
| Cross-model review | End of P6, strictly pre-P7-archive | Fresh-context reviewer on a different model id (REJECT-default) | Cap 3; blocks P7 on cap-without-approval |

Shared mechanics (state file, append-only run log, stop rules, escalation format) live in `planifest-loop-runner`. P7 remains the lock line: no loop or reversal touches archived state (`plan/backlog/` is the governed home for deferred work instead).

---

## Shared hook modules (0000028)

Hook files import their shared helper by relative path instead of carrying their own copy. `read-stdin.mjs` lives in `hooks/enforcement/`, which installs unconditionally, so every hook that imports it finds it on every install. A helper with an always-installed caller belongs in that tree. The reverse placement would leave an always-installed hook importing an absent module, which fails at ESM module-load time before the hook's own `try/catch` runs and so defeats the exit-zero invariant.

Self-modification sequencing (ADR-004) governs how such a change is applied to hooks that are executing the build doing the editing. Rewire one caller, commit, re-run `setup.sh` for that edit alone, then assert a real side effect. Exit 0 proves nothing here by design.

---

## Continuous integration (0000031)

`.github/workflows/planifest.yml` runs four jobs on every pull request to `main`.

| Job | Runner | What it checks |
|-----|--------|----------------|
| `validate-branch` | `ubuntu-latest` | A change under `src/` also touches `plan/`, `docs/`, or a `component.yml` |
| `self-description-check` | `ubuntu-latest` | The README matches the repository structure (0000019) |
| `test-suite` | `ubuntu-latest` and `macos-latest`, `fail-fast: false` | `run-tests.sh` passes. On failure, the log lists each failed suite by file name. |
| `setup-powershell` | `windows-latest`, PowerShell 7 | `test_setup.ps1` passes, including the live `.planifest-setup-flags` marker checks |

The `test-suite` and `setup-powershell` jobs are repository-only (0000031-ADR-002). The consumer copy at `planifest-framework/hooks/planifest.yml` doesn't carry them. Both declare `permissions: contents: read` and `timeout-minutes: 10` (0000031-ADR-003). Windows PowerShell 5.1 has no CI coverage (0000031-ADR-001).

A red check doesn't block a merge until branch protection marks it as required. Only the human on the loop can change that setting.

---

## Run lifecycle and write gate scope (0000032)

### Session markers and close-out

The orchestrator writes three committed session markers at P0:

- `plan/.orchestrator-active`
- `plan/.orchestrator-ack`
- `plan/.run-mode`

Since 0000032-ADR-002, P7 no longer touches them. A new P9 step, "Clear session markers", runs after P8 and before the Step 9 tag. It stages the archive, deletes the markers, and commits both together. It then runs `git ls-files` on the three paths and stops before the tag if any path is still tracked. Hooks therefore treat P8 and P9 as part of the run, and the tag never carries a marker.

Resume Detection in the orchestrator reads archive evidence to finish an interrupted close-out:

- Step 2a fires when the sentinel is present and `plan/current/` is empty. With no `build-report.md` in the matching archive, it resumes at P8. With one, it resumes at the P9 marker step.
- Step 2b fires when the sentinel is gone from disk but still committed. It applies the same archive rule.
- If no archive matches, or the sentinel ID fails its format check, either step stops and asks the human on the loop. Neither step deletes a marker or starts fresh.

### Blocking context clear after P9

Ship Step 12 asks the human on the loop to run `/clear` or start a new session (0000032-ADR-003). The orchestrator refuses new work in the same session until that happens. In the next session, `auto-trigger-orchestrator.mjs` says no Planifest run is active, and the agent must triage the request before it acts. A ship Hard Limit makes every P9 handover note route each next step through a track.

### Shared path rules and repository root

`hooks/enforcement/path-rules.mjs` holds every gated-path rule (0000032-ADR-004). `gate-write.mjs` and `shell-write-guard.mjs` import it, so the two gates can't disagree about a path. It sits in `hooks/enforcement/`, so every install that copies `gate-write.mjs` copies it too.

The module finds the repository root with a marker walk that spawns no process:

1. It walks up from `CLAUDE_PROJECT_DIR`, then from `cwd`, and takes the first walk that finds a marker.
2. In each walk, the nearest folder holding `planifest-framework/` wins. Failing that, the nearest folder holding `.git` wins.
3. A marked folder inside `plan/` or `docs/` of a higher marked folder is never the root.
4. With no marker found, the root is `cwd`.

Feature 0000035 hardens these rules. The section on [write gate path hardening](#write-gate-path-hardening-0000035) describes the changes.

The module looks up the sentinel and `plan/current/design.md` from the root. A target outside the root passes with no output. A target too long to judge, over 4096 characters or 256 segments, passes with a warning on stderr.

### Block reasons on stderr

Every enforcement hook that exits 2 writes a plain-text reason to stderr, where Claude Code reads it (0000032-ADR-005). The covered hooks are `gate-write.mjs`, `ratchet-check.mjs`, `em-dash-guard.mjs`, and `shell-write-guard.mjs`. The existing hooks keep their stdout byte for byte, so the Windsurf, Copilot, and Codex adapters still relay it.

### Bash shell-write guard

`shell-write-guard.mjs` runs on Claude Code's Bash PreToolUse event (0000032-ADR-006). It finds common shell writers:

- redirects
- `tee`
- `sed -i` and `perl -i`
- the destination of `cp`, `mv`, `install`, and `ln`
- every argument of `rm`, `touch`, and `mkdir`

It judges each target with `toRootRelative` and `evaluateWrite` from `path-rules.mjs`. It tracks the folders each command may run in after `cd`, `pushd`, and `popd`, and judges a relative target against each one. If it can't parse a command or a target, it writes a warning to stderr and allows it. It ignores `git` and can't see writes made inside scripts or interpreters. A boot-file Hard Limit in `standard-boot.md` and `cursor-boot.md` covers those gaps: code changes go through **Write** or **Edit**, never Bash.

`setup.sh` and `setup.ps1` register the guard on a `Bash` PreToolUse matcher for Claude Code only. Each removes any earlier `shell-write-guard` group before it adds one, so a re-run leaves exactly one. Other tools rely on the boot-file rule alone. The 0.31.0 migration tells downstream projects to re-run setup.

---

## Run modes and autonomous runs (0000033)

`plan/.run-mode` now holds one of three values: `interactive`, `continuous`, or `autonomous`. An unknown value reads as `interactive`, so an older framework treats `autonomous` as `interactive` (0000033-ADR-002). `scripts/run-mode.mjs` prints the effective mode for every reader after P0. It prints `autonomous` only when git history anchors the confirmation. Otherwise it prints `interactive` and gives the reason on stderr.

### Exception list and standing rules

In `autonomous`, the run stops for the human on the loop only on a declared exception list (0000033-ADR-003). The standing rules live in `standards/autonomous-run-standards.md`.

- Schema and destructive changes.
- A gross deviation, meaning a change the reversal protocol would class as altering the confirmed problem, users, or scope.
- Human review of the running result.
- Promotion beyond the candidate environment.
- A human-only input.
- An exhausted budget.

A product adds items through `planifest-overrides/` using `templates/exception-list.template.yml`. Merging pull requests stays human-only in every mode. The ship agent ships without asking and ends P9 with one final report.

### Gates as loops

In `autonomous`, every phase gate runs as a loop under `planifest-loop-runner` with a fresh-context checker (0000033-ADR-004). Existing caps stay. At a cap, the run tries a different approach, up to 3 approaches per loop instance (0000033-ADR-005). The fourth becomes an exception. The reversal budget stays at 2 per feature. Each phase writes a one-line progress entry to the build log, and the P8 report flags the human-touchpoint count.

### P0 questions and release sizing

`standards/p0-question-policy.md` limits P0 to real forks (0000033-ADR-007). Adoption mode, version, stack, and similar items go into the design draft for one confirmation. The design, the Scope Lock batch, and the run mode confirm in one turn. The build log records the question count. When a design depends on existing records, discovery samples recent rows and the design states the usable rate as an assumption. `standards/release-sizing.md` sizes each requirement as small (1), medium (2), or large (3). P0 fills the release from the backlog up to the target in `planifest-overrides/release-budget.yml` (0000033-ADR-008). Without that file, the three-story rule applies.

### Fast Path for changes with no src target

Fast Path now admits a change with no `src/` target (0000033-ADR-009). Its four criteria are unchanged, and the orchestrator's track table says so.

### Parallel streams and join reconciliation

Parallel dispatch is the default in every phase (`standards/agent-dispatch-standards.md`). Independent requirements move through P1 to P4 as separate streams. Each stream has a state file under `plan/current/streams/`, from `templates/stream-state.template.md`. The `parallel_streams` toggle in `loop-toggles.yml` defaults to `on` in `autonomous` and `off` otherwise (0000033-ADR-013). The orchestrator owns every join. After each join, `scripts/stream-reconcile.mjs` checks that every artifact one stream declares is consumed by another stream or by a requirement (0000033-ADR-014).

### Close-out and scripts

`scripts/archive-current.mjs` runs the P7 archive (0000033-ADR-010). It moves each tracked item with `git mv`, removes markers by explicit path, and prints what it moved. Each step is a separate command, so a resumed run repeats only unfinished steps. It never uses a glob delete. The P8 build report goes into the archive commit, which is the 0000032 marker-step commit (0000033-ADR-011). P8 and P9 end with a scoped `git status --porcelain` check. In `autonomous`, the run commits any leftover file. In other modes, the P9 gate summary lists leftovers and asks. After P6, the docs agent reruns the P4 check set, or a smaller command declared in `templates/doc-checks.template.yml` (0000033-ADR-012). Every two-option prompt names the actor in each option.

---

## Write gate path hardening (0000035)

### Real targets, two ways

`path-rules.mjs` now judges where a write lands, not the text of the path (0000035-ADR-005). `resolveTarget` walks the target one segment at a time through symbolic links. A `..` moves to the real parent of the path resolved so far. The walk follows at most 40 links.

The **Write** and **Edit** tools collapse `..` as text before the system follows links, so the two methods can land on different files. `resolveTargetBoth` returns both placements:

- the physical placement, which matches how the kernel resolves a shell path
- the text placement, with `..` collapsed against `cwd` first

`gate-write.mjs` and `ratchet-check.mjs` judge both placements and block if either one blocks. `shell-write-guard.mjs` keeps the physical walk only.

A link loop, a chain past 40 links, or a resolution error blocks with exit 2 when the path lies inside the root. Errors outside path resolution still fail open (0000003-ADR-005).

### Root lookup without a cwd

`resolveRoot` no longer needs the working folder to exist (0000035-ADR-006). It checks `CLAUDE_PROJECT_DIR` first. It then walks up from the nearest existing parent of `cwd`. Each hook takes the stdin `cwd`, then `process.cwd()`, then `CLAUDE_PROJECT_DIR`.

### Planted markers

`markedRoot` distrusts a `.git` or `planifest-framework` marker that sits below an always-permitted name, such as `plan/w/.git` (0000035-ADR-008). The walk goes on to the next trusted marker above, so a moved folder can't become a new root.

### Fast Path scope record

A Fast Path change lists its target paths in `plan/.fast-path-scope` (0000035-ADR-002). Both write gates accept a valid, current record when `design.md` is absent. The record stores the branch and `HEAD` it was written at. The gate reads both from `.git` files with no spawn, and ignores a stale record (0000035-ADR-003).

The record is self-authorisation, so the gates add two controls:

- Each admitted write prints one stderr notice that names the record and the path.
- The Fast Path changelog entry lists every record path.

`FAST_PATH_ENFORCEMENT_PATHS` lists the paths a record never admits (0000035-ADR-004). The list covers hook folders, hook wiring, tool-local settings, setup scripts, the CI workflow, and `.git/`. `fast-path.md` names the same entries, and a suite checks both lists match. Fast Path removes the record before its commit, and `.gitignore` lists it.

### ratchet-check shares the root rules

`ratchet-check.mjs` imports `resolveRoot` and `resolveTargetBoth` from `path-rules.mjs` (0000035-ADR-007). It finds `plan/current/` from any subfolder. It passes an unresolvable target, because `gate-write.mjs` already blocks it.

### product.yml at P7

The ship agent sets `product.yml` `version` and `feature` in P7, after Step 5 and before Step 6 archives `design.md` (0000035-ADR-010). It runs `scripts/set-product-release.mjs`, which applies each `versionPolicy`. The script exits 0, 2, 4, or 5. It writes only `{root}/product.yml`, through a temp file and a rename. It imports `resolveRoot` from `path-rules.mjs` and clears `CLAUDE_PROJECT_DIR` for that call.

### Hard Limit 8 sanctioned scripts

Hard Limit 8 now names the fixed framework scripts that skill steps run to write files (0000035-ADR-011). Both `standard-boot.md` and `cursor-boot.md` carry one `Sanctioned scripts:` sentence. It names seven scripts:

- `archive-current.mjs`
- `set-product-release.mjs`
- `promote-to-regression.sh`
- `refresh-delete-boot-files.sh` and `refresh-delete-boot-files.ps1`
- `setup.sh` and `setup.ps1`

Each script counts only with the arguments its skill step shows. No other script counts.

### Migration run state

Migration files never move (0000035-ADR-015). Every migration sits at the top level of `planifest-framework/migrations/`, and the old completed-migrations folder is gone. Each project records each run at `plan/_migrations/{stem}.md` (0000035-ADR-016). A record holds one outcome: `applied`, `not applicable`, or `skipped`.

A migration is pending when its record is missing or can't be read (0000035-ADR-018). Orchestrator resume detection reads the records, and the migrator is their only writer (0000035-ADR-017). Each record comes from a scan, never from seeding (0000035-ADR-019).

### Acceptance-criteria limit

`consistency-check.mjs` allows up to 10 acceptance criteria per requirement (0000035-ADR-012). From 4 to 10 it prints a warning and exits 0.

---

## Data Ownership

No components own persistent data. Planifest operates on local filesystem artifacts (plan/ files, skill SKILL.md files) written and read during pipeline execution. No databases. New in 0000016 (all plain markdown/YAML, git-tracked): `plan/backlog/` entries (orchestrator-owned, filed by any phase agent), `product.yml` (ship-agent writes, orchestrator reads), and `plan/current/` loop-state/run-log/defect-report/revision-log artifacts (orchestrator-owned). New in 0000020 (local, gitignored, not version-tracked): `<tool-dir>/.planifest-setup-flags`, owned by `setup-hook-integration`, written on every successful install and read/updated by `planifest-refresh-setup`. New in 0000025 (git-tracked, additive to the 0000020 marker, not a replacement): `planifest-overrides/setup-config/{tool}.md`, one file per AI tool, written by `setup.sh`/`setup.ps1` alongside the existing gitignored marker so the flags in effect at install time are versioned and reviewable, not only locally cached.

Clarified in 0000033: `planifest-framework` owns `plan/.run-mode`, `plan/current/`, and `plan/current/streams/`. The human on the loop owns `planifest-overrides/` (exception list, release budget, doc checks), and the framework only reads it (0000033-ADR-015).

New in 0000035 (plain Markdown and text):

- `plan/_migrations/` run records: owned by `planifest-migrator`, read by orchestrator resume detection, git-tracked, never archived (0000035-ADR-017).
- `plan/.fast-path-scope`: owned by the Fast Path workflow, read by `gate-write.mjs` and the shell-write guard, gitignored and removed before each Fast Path commit.
- `product.yml`: the ship agent owns it and writes it only through `set-product-release.mjs`. `product-version.mjs` reads it.

Clarified in 0000032: `planifest-framework` owns the three committed session markers, `plan/.orchestrator-active`, `plan/.orchestrator-ack`, and `plan/.run-mode`. The orchestrator writes them at P0, and the ship skill deletes them in the P9 marker step. Hooks read them only.

---

## External Dependencies

| Dependency | Type | Components That Use It |
|-----------|------|----------------------|
| Node.js (built-ins only: fs, path, child_process, os, url, crypto) | Runtime | All hook adapters, enforcement scripts, and `scripts/` (`crypto` in `set-product-release.mjs` only, 0000035) |
| Bash | Runtime | setup.sh, test scripts, hook install scripts |
| PowerShell 7+ | Runtime | setup.ps1, test_setup.ps1, PowerShell hook scripts |
| GitHub Actions hosted runners | CI | `ubuntu-latest`, `macos-latest`, and `windows-latest` jobs in `.github/workflows/planifest.yml` (0000031) |
| git (core.hooksPath) | CLI | setup.sh/ps1 (commit-msg hook installation) |

---

## Key Architectural Decisions

Reference `docs/decisions-index.md` for the full ADR list.

- **ADR-001 (0000003):** Three-tier enforcement model: Claude Code (Tier 1a), other IDEs (Tier 1b), instructions-only (Tier 2)
- **ADR-002 (0000003):** Common envelope shape: all adapters normalise to `{ session_id, cwd, tool_input, event }` before delegating
- **ADR-005 (0000003):** Exit-zero failure mode: hooks never block on unexpected errors (NFR-003)
- **ADR-003 (0000011):** Hook adapter architecture: delegating pattern; adapters translate envelopes, enforcement logic lives only in shared scripts
- **ADR-003 (0000018):** discovery.md elevated to Hard Limit status: matches build-log.md's Hard Limit 8 enforcement pattern
- **ADR-001 (0000020):** Hardcoded, non-extensible deletion allowlist for the refresh skill, enforced in a dedicated script, not prose alone (P5 security finding)
- **ADR-002 (0000020):** Single marker file (`.planifest-setup-flags`) serves as both install-time record and refresh retry cache, not two separate files
- **ADR-003 (0000020):** Mandatory human confirmation gate before any refresh action, regardless of flag-reconstruction confidence
- **ADR-004 (0000020):** Tool selection is explicit input to the refresh skill, never silently auto-resolved when multiple installs are present
- **ADR-005 (0000020):** No automatic retry on a failed setup re-invocation; retry is always human-initiated
- **ADR-001 (0000024):** `product.yml` extended to single-component projects as the declared product id home (stable name for versioning and for attributing archived runs): extends, not supersedes, 0000016 ADR-002's versioning-only scope
- **ADR-001 (0000025):** Ship-agent PR footer defaults off; restorable only via a `planifest-overrides/instructions/` opt-in file
- **ADR-002 (0000025):** `planifest-overrides/setup-config/{tool}.md` (tracked) is source of truth over the gitignored `.planifest-setup-flags` marker; reconciled on setup/refresh; `.orchestrator-strict` explicitly out of scope
- **ADR-003 (0000025):** Scope Lock Challenge defaults to always-drafted, batch-presented answers: supersedes **ADR-003 (0000017)**, scoped narrowly against `0000014-ADR-008`'s one-question-at-a-time convention (unchanged everywhere else)
- **ADR-002 (0000028):** Shared hook modules live inside the existing `hooks/enforcement/` tree, which installs unconditionally, never in a new top-level `shared/` directory
- **ADR-003 (0000028):** The em dash guard attaches as a `PreToolUse(Write, Edit)` sibling of `gate-write.mjs`, not a git hook, with a reusable in-content sentinel as the bypass so the exemption is visible in the artifact's own diff
- **ADR-004 (0000028):** Self-modification sequencing: when editing the hooks running the build, rewire one caller at a time and verify a real side effect, because exit 0 cannot distinguish a working hook from a silently broken one
- **ADR-002 (0000030):** The retired hook and MCP integrations are removed from the framework. Setup ignores their flags and a re-run cleans up the old install.
- **ADR-003 (0000030):** Setup still accepts the three retired integration flags. Each prints a one-line notice, is never written to the install marker, and never fails a refresh.
- **ADR-004 (0000030):** The clean-up runs on every setup run. It matches on command path, skips a malformed settings file byte-identical, writes through a temporary file, and always exits 0.
- **ADR-005 (0000030):** `setup-hook-integration` owns removal of the stale state the deleted hooks wrote, including the two `plan/` marker folders.
- **ADR-002 (0000032):** Session markers stay committed and are cleared in a P9 step after P8 and before the tag. An interrupted close-out resumes from archive evidence. Supersedes **ADR-001 (0000015)** and amends **ADR-004 (0000015)**.
- **ADR-003 (0000032):** P9 ends with a blocking context clear, and the next session must triage first. Supersedes **ADR-002 (0000015)**.
- **ADR-004 (0000032):** One module, `path-rules.mjs`, holds the gated-path rules and the repository-root walk. Targets outside the root pass.
- **ADR-005 (0000032):** Every enforcement hook that exits 2 writes its reason to stderr and keeps its existing stdout.
- **ADR-006 (0000032):** A heuristic Bash shell-write guard, registered for Claude Code only, fails open and is backed by a boot-file Hard Limit.
- **ADR-002 (0000033):** `autonomous` is a third `plan/.run-mode` value. Unknown values still read as `interactive`.
- **ADR-003 (0000033):** An autonomous run stops only on a declared exception list. A product can add items in an override.
- **ADR-004 (0000033):** In `autonomous`, every gate runs as a loop with a fresh-context checker.
- **ADR-005 (0000033):** A loop that hits its cap tries up to 3 different approaches before it becomes an exception.
- **ADR-007 (0000033):** P0 asks only real forks and confirms the design, Scope Lock batch, and run mode in one turn.
- **ADR-008 (0000033):** The release budget counts size points, not stories.
- **ADR-009 (0000033):** Fast Path admits a change with no `src/` target.
- **ADR-010 (0000033):** `archive-current.mjs` replaces the glob delete in the P7 archive.
- **ADR-013 (0000033):** Parallel streams use a `parallel_streams` toggle and per-stream state files.
- **ADR-014 (0000033):** The orchestrator owns joins and runs `stream-reconcile.mjs` after each.
- **ADR-002 (0000035):** A Fast Path scope record at `plan/.fast-path-scope` stands in for `design.md`, with a stderr notice on each admitted write.
- **ADR-004 (0000035):** A scope record never admits a path in `FAST_PATH_ENFORCEMENT_PATHS`.
- **ADR-005 (0000035):** The gates resolve links segment by segment and judge both placements. A resolution error inside the root fails closed.
- **ADR-006 (0000035):** The root lookup works when `cwd` no longer exists.
- **ADR-007 (0000035):** `ratchet-check.mjs` uses the shared root and target rules.
- **ADR-008 (0000035):** Root markers under always-permitted names are not trusted.
- **ADR-010 (0000035):** `set-product-release.mjs` sets `product.yml` at P7.
- **ADR-011 (0000035):** Hard Limit 8 names seven sanctioned scripts.
- **ADR-015 (0000035):** Migration files never move. Supersedes the archive step of **ADR-005 (0000005)**.
- **ADR-016 (0000035):** Each project records migration runs in `plan/_migrations/`.

---

*Template: architecture-overview.template.md*
