# Planifest Tests

This directory contains integration tests for the confirmed design framework setup scripts (`setup.sh` and `setup.ps1`).

These tests verify that running the setup process for an AI coding agent (like Claude Code or Cursor) correctly generates the expected folders, copies the skill files, and creates necessary configuration (like boot files or rules).

## Running the Tests

To run the tests, execute the scripts from the root of the repository or from within this directory. The scripts will create an isolated, temporary workspace, run the setup process inside it, and clean up afterward.

### PowerShell (Windows)

```powershell
# From the repository root
& .\planifest-framework\tests\test_setup.ps1
```

### Bash (macOS / Linux / WSL)

```bash
# From the repository root
./planifest-framework/tests/test_setup.sh
```

## How It Works

1. **Isolation**: The test script automatically generates a temporary directory (e.g., `planifest_test_XXXXXX`).
2. **Context Creation**: The entire `planifest-framework` source is copied into the temporary directory to simulate a real project environment.
3. **Execution**: The respective setup script (`setup.sh` or `setup.ps1`) is called for various target tools (e.g., `claude-code`, `cursor`).
4. **Validation**: The test script checks if the expected tool-specific files and folders are created:
   - Tool-specific skill folders (e.g., `.claude/skills` or `.cursor/skills`).
   - Copied `SKILL.md` files (e.g., `planifest-orchestrator/SKILL.md`).
   - Boot files for tools that require them (e.g., `CLAUDE.md`).
   - Workflows/Commands for tools that support them (e.g., `/feature-pipeline`).
5. **Cleanup**: Even if a test fails, `finally` blocks ensure the temporary folder is deleted, leaving your actual workspace unaffected.

## Adding New Tests

If you add a new setup target (e.g., a new AI coding tool) to `setup.sh`/`setup.ps1`, you should verify it by adding a section to both `test_setup.sh` and `test_setup.ps1`. 

A basic template for a new test block:

```powershell
Write-Host "--- Testing: [tool-name] ---"
& .\planifest-framework\setup.ps1 [tool-name]

if (-not (Test-Path ".[tool-dir]\skills")) {
    throw "FAIL: .[tool-dir]\skills directory not created"
}
```

## Windows skip table

A suite that cannot run under Git Bash on `windows-latest` returns exit 0 early on Windows only. It prints `SKIP (windows): {reason}` first. Each guard tests the platform (`uname -s` reports `MINGW*`, `MSYS*`, or `CYGWIN*`). Each guard has one row here, and each row has one guard.

| Suite | Reason | Date |
|-------|--------|------|
| `test-0000025-req-004-setup-config-relocation.sh` | Check (e) only: `chmod 555` does not block writes on NTFS, so the unwritable-folder case cannot be built. The other checks in the suite run. | 2026-10-24 |

