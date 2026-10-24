# Component Registry

**Last updated:** 0000037-green-ci-before-ship (24 Oct 2026)
**Maintained by:** planifest-docs-agent

---

## Registry

| ID | Name | Type | Domain | Status | Summary | Docs |
|----|------|------|--------|--------|---------|------|
| `setup-hook-integration` | Setup Hook Integration | component-pack | developer-tooling | active | setup.sh/ps1, skill-sync, and hook adapters (copilot, cursor, windsurf, codex): installs and configures enforcement hooks, commit standards, and external skill management into any Planifest-managed project. Writes a `.planifest-setup-flags` marker recording the flags used at install time (0000020). Registers `shell-write-guard.mjs` on a Claude Code `Bash` PreToolUse matcher, once per install (0000032). `setup.ps1` runs under Windows PowerShell 5.1 as well as PowerShell 7, with a `ConvertTo-PlanifestHashtable` helper in place of `ConvertFrom-Json -AsHashtable`, and checks the `git config core.hooksPath` exit code so a failed call warns and never reports the guardrails as active (0000037). | [purpose](../src/setup-hook-integration/docs/purpose.md) |
| `planifest-framework` | Planifest Framework | component-pack | developer-tooling | active | Core standards, skills, hooks, and setup scripts enforcing the confirmed-design pipeline. Recent changes: ship-agent PR output omits the AI-attribution footer by default and its P7 archive commit stages `plan/current/` explicitly (0000025), setup scripts track active flags in a versioned `planifest-overrides/setup-config/{tool}.md`, the Scope Lock Challenge defaults to always-drafted, batch-presented answers, a new `em-dash-guard.mjs` PreToolUse hook rejects em dashes in Planifest prose (0000028), boot files (CLAUDE.md/AGENTS.md) are regenerated from the current template on every setup run (0000029), CI runs the test suite on Linux and macOS and `test_setup.ps1` under PowerShell 7 on Windows (0000031), and the session markers are cleared in P9 before the tag, with a blocking context clear after P9 (0000032). The shared `path-rules.mjs` module now holds the gated-path rules for `gate-write.mjs` and a new Bash `shell-write-guard.mjs` hook (0000032), and `plan/.run-mode` gains an `autonomous` value with a declared exception list, gates that run as loops with fresh-context checkers, a P0 that asks only real forks, a release budget, a Fast Path for changes with no `src/` target, parallel streams with join reconciliation, and three new scripts (`archive-current.mjs`, `stream-reconcile.mjs`, `run-mode.mjs`) (0000033). Version 0.33.0 (0000035): the write gates resolve links and `..` two ways, find the root when `cwd` is gone, and distrust planted markers. Fast Path writes pass through a `plan/.fast-path-scope` record that never admits an enforcement path. `ratchet-check.mjs` shares the root rules. A new `set-product-release.mjs` sets `product.yml` at P7, and the Write-or-Edit rule (boot Hard Limit 8) names seven sanctioned scripts. Migration files never move, and each project records its runs in `plan/_migrations/`. Version 0.34.0 (0000036): a new `skill-drift-check.mjs` script warns when an installed skill differs from its source, and the orchestrator runs it in Resume Detection. A non-regular `design.md` reads as no design, permitted names skip enforcement paths, and the hooks escape control characters in their output through `shown()`. Hard limits are cited by name and source. A new migration, `migrate-0.34.0-rerun-setup.md`, tells projects to re-run setup for 0.33.0 and 0.34.0. Version 0.35.0 (0000037): P9 polls the PR's checks and, in `autonomous`, fixes a red check up to three times, and reuses an open draft PR. The GUTD shorthand reads the last merged PR's checks. A new `credential-scan.mjs` script runs before every `autonomous` commit and scans PR text from files, with a scan-then-commit procedure that holds back matched files. Post-P6 revalidation runs after the P6 commit. Each acceptance criterion gains a `Verified by` field, and P3 runs a requirement-ID scan. A portability lint, a wired-command test, and a migration branch-diff test join the suite. The suite runs on Windows under Git Bash in seven shards and `setup.ps1` runs under Windows PowerShell 5.1. `run-tests.sh` reads `PLANIFEST_SHARD_INDEX` and `PLANIFEST_SHARD_COUNT`. A new migration, `migrate-0.35.0-rerun-setup.md`, tells projects to re-run setup. | [component.yml](../planifest-framework/component.yml) |

---

## Status Key

| Status | Meaning |
|--------|---------|
| `active` | In production / installed in target environments |
| `in-progress` | Pipeline in flight |
| `deprecated` | Superseded; pending removal |
| `planned` | On roadmap; not yet in a pipeline |

---

## Notes

- This registry is updated by the docs-agent at the end of each feature pipeline.
- Each `ID` corresponds to a directory under `src/` containing a `component.yml` manifest.
- Add new components here when a new feature pipeline completes Phase 6.
