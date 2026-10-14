# Recommendations - 0000030-context-mode-and-telemetry-mcp-removal

Suggested improvements for future iterations, based on what this run built and found.

## Improvements

| # | Recommendation | Evidence |
|---|---|---|
| 1 | Add a CI job that runs `planifest-framework/tests/run-tests.sh`, and a Windows job that runs `setup.ps1` under PowerShell 5.1 and 7 | `.github/workflows/planifest.yml` runs no tests. P5 F2 and F5 changed PowerShell code that nothing has run live |
| 2 | Narrow the setup clean-up to the file names Planifest shipped, and remove a folder only when it is empty | P5 F6, and the implementation notes in `adr/ADR-004-clean-up-always-on-path-matched-fail-open.md` |
| 3 | Restore a direct test of the P0 `product.yml` `id` hard-stop that doesn't go through hooks | `test-0000024-req-001-declared-product-id.sh` was deleted in P3, because every section used the telemetry hooks |
| 4 | Decide whether the retired-flag notice and the clean-up can be dropped in a later major version | ADR-003 and ADR-004 keep removed path names in setup indefinitely |
| 5 | Give parallel agents a way to commit that doesn't contend for one git index | In P3 two agents' deletions landed in another agent's commit, because all three shared one index |

## Deferred Items

None. `scope.md` defers nothing.

## Tech Debt

Each row is already filed in `plan/backlog/`, so this table points to the entries instead of creating duplicates.

| Item | Backlog entry |
|---|---|
| `setup.sh all` stops at roo-code, and `TOOL_*` variables carry over between tools | 0000087 |
| opencode PowerShell setup passes a null skills folder | 0000088 |
| `test-0000010` depends on the working directory | 0000089 |
| Setup clean-up removes user files in stale hook folders | 0000090 |
| CI runs no tests and no PowerShell | 0000091 |
