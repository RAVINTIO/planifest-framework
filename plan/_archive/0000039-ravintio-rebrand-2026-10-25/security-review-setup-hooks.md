# Security Report - 0000039-ravintio-rebrand (setup and hooks)

Scope: `ravintio-framework/setup.sh`, `ravintio-framework/setup.ps1`, `ravintio-framework/hooks/`, and `ravintio-framework/scripts/`. The consumer migration helper is out of scope. A separate reviewer covers it.

Overall risk rating: **Medium**. One Medium finding needs a fix before ship. The rest are Low.

## Threat model (STRIDE)

| ID | Threat | Category | Severity | Mitigation |
|---|---|---|---|---|
| S-01 | The old-manifest prune deletes any folder a `.planifest-manifest` line names, if its last segment starts with `planifest-`. It never checks that the folder sits inside the tool's skills folder. | Tampering | Medium | Not mitigated. See finding S-01. |
| S-02 | The rename dropped the old names from `FAST_PATH_ENFORCEMENT_PATHS`. A leftover `.opencode/plugins/@planifest/opencode-hooks/` plugin or `.github/workflows/planifest.yml` is no longer an enforcement path. | Elevation | Low | Partly mitigated. Setup refuses to run while the old pack exists, and the migration renames the workflow (R-017). |
| S-03 | `.planifest-setup-flags` sets `INCLUDE_FULL_SKILL_LIBRARY` and `STRICT_ORCHESTRATOR` from a file in the consumer repo. | Tampering | Low | Mitigated. Setup matches two fixed strings with `grep -F` and sets booleans only. Nothing from the file reaches a shell, a path, or `eval`. The worst outcome is that setup installs the vendored skills or turns on strict mode. |
| S-04 | The old ignore-block strip and the boot-file marker strip rewrite a consumer file in place. | Tampering | Low | Mitigated in practice. See finding S-04. |
| S-05 | The em dash guard accepts the old sentinel `<!-- planifest-em-dash-allow -->`. | Elevation | Low | Accepted by design (ADR-004). The guard is a style rule and the sentinel was already agent-writable. |
| S-06 | `archive-current.mjs` deletes `plan/current/.planifest-session`. | Tampering | Low | Mitigated. The name is fixed and sits under `plan/current/`. Node `rmSync` removes a link, not its target. |
| S-07 | The OpenCode plugin reads `PLANIFEST_SESSION_ID` as a fallback session ID. | Spoofing | Low | Mitigated. The trust level matches `RAVINTIO_SESSION_ID`. The plugin no longer reads `.claude/.planifest-session`, so strict mode asks for one new acknowledgement. That is a usability cost, not a security cost. |
| S-08 | The old-pack stop check runs before any write. | Denial of service | Low | Mitigated. Both scripts stop with exit 1 and name the migration. `setup.sh` tests `-d` and `setup.ps1` tests any item. A plain file called `planifest-framework` stops `setup.ps1` but not `setup.sh`. This parity gap has no security effect. |

## Findings

### S-01 Medium: old-manifest prune deletes folders outside the skills folder

Files:

- `ravintio-framework/setup.sh`, `migrate_old_manifest`, lines 299 to 316, test at line 305.
- `ravintio-framework/setup.ps1`, lines 1317 to 1331, test at line 1321.

The prune reads each line of `.claude/skills/.planifest-manifest` (or the tool's own skills folder). It removes the folder with `rm -rf` or `Remove-Item -Recurse` when three checks pass:

- the line is not empty.
- the path is a directory.
- its basename matches `planifest-*`.

Nothing checks where the folder sits. An absolute path, a `..` path, or a path through a linked parent all pass. The old setup wrote absolute paths, so a manifest from a moved clone or another machine points outside the repo.

Proof in a `mktemp -d` scratch repo with the current pack: the manifest held `$V/planifest-victim` (a folder outside the repo) and `$S/.claude/skills/../../planifest-victim2`. `setup.sh claude-code` printed `removed old skill` for both, and both folders were gone.

The link check stops a link as the last segment. It does not stop a linked parent such as `.claude/skills/link/planifest-x`.

Context: the pre-existing `.ravintio-manifest` prune (formerly the `.planifest-manifest` prune on `main`) has no checks at all. The new code is stricter than the code it replaces. The one-time read still widens the delete surface for every consumer that upgrades, so fix it now.

Exact fix for `setup.sh`: replace the test at line 305 with a containment check on the real parent path.

```bash
local skills_real
skills_real="$(cd "$1" 2>/dev/null && pwd -P)" || return 0
...
    local name parent_real
    name="$(basename "$dir_path")"
    parent_real="$(cd "$(dirname "$dir_path")" 2>/dev/null && pwd -P)" || continue
    if [ -n "$dir_path" ] && [ "$parent_real" = "$skills_real" ] && [[ "$name" == planifest-* ]] && [ -d "$skills_real/$name" ]; then
      if [ -L "$skills_real/$name" ]; then rm -f "$skills_real/$name"; else rm -rf "$skills_real/$name"; fi
```

Exact fix for `setup.ps1`: resolve the parent with `(Get-Item -LiteralPath (Split-Path -Parent $oldDirPath) -Force).FullName` and compare it, case-insensitively, with `(Get-Item -LiteralPath $skillsDir -Force).FullName`. Skip the line on a mismatch or on a resolve error. Then act on `Join-Path $skillsDir (Split-Path -Leaf $oldDirPath)`. Also refuse the entry if any parent segment between the repo root and the skills folder is a reparse point.

Add a test to `test-0000039-req-002-runtime-names.sh` and `test_setup.ps1`. Each test lists one absolute path outside the repo and one `..` path, and asserts that both folders survive.

File a backlog entry for the same containment check on the `.ravintio-manifest` prune (`setup.sh` lines 1105 to 1115, `setup.ps1` lines 1335 to 1345).

### S-02 Low: old names left the Fast Path enforcement list

File: `ravintio-framework/hooks/enforcement/path-rules.mjs`, lines 498 to 525.

The rename swapped each entry rather than adding the new name beside the old one. Two installed old paths can outlive the upgrade:

- `.opencode/plugins/@planifest/opencode-hooks/`. `setup/opencode.sh` installs the new plugin and registers it in `opencode.json`. It never removes the old plugin or its registration. OpenCode keeps loading the old plugin, and a Fast Path scope record can now admit a write to it.
- `.github/workflows/planifest.yml`, if the migration did not run or skipped it. The new `ravintio.yml` still enforces the `fix(fast-path)` rule, so the CI gate holds.

Exact fix: add `".opencode/plugins/@planifest/opencode-hooks/"` and `".github/workflows/planifest.yml"` to `FAST_PATH_ENFORCEMENT_PATHS`. Mark each one with `// old-name read, removed at 1.0.0` per ADR-004. Have `setup/opencode.sh` and `setup/opencode.ps1` drop the old plugin reference from `opencode.json`.

### S-04 Low: in-place rewrite of ignore and boot files

Files:

- `ravintio-framework/setup.sh` lines 266 to 279 (`strip_old_ignore_block`) and lines 326 to 338 (boot marker strip).
- `ravintio-framework/setup.ps1` lines 1160 to 1173 and lines 1186 to 1192.

`cat "$tmp" > "$file"` writes through a link to wherever it points. The append code that follows (`>>`) already behaves the same way, so the rename adds no new exposure. The strip also removes every line from the header to the next blank line. A human line placed directly under the old header block, with no blank line between, would go with it.

Exact fix (optional): skip the strip when `[ -L "$file" ]`, and stop the skip at the first line that is not a known old rule.

## Dependency audit

The OpenCode `package.json` changed name, description, and keywords only. It declares no dependencies and no install scripts. The diff adds no new tool. `credential-scan.mjs` has zero changed lines, and nothing in it skips a path by framework name.

## Secrets management

No credential appears in the diff. The credential scanner ran in regex mode over all 576 added or changed paths outside `external-skills/` and reported nothing. A second pattern search over added lines found no AWS key, private key, GitHub, Slack, OpenAI, or Google key. The four vendored `external-skills/` hits that the human on the loop cleared stay cleared. Nothing new turned up.

## Authentication and authorisation review

Not applicable. The feature has no API.

`gate-write` and `shell-write-guard` changed in message text and paths only. `ROOT_MARKERS` now holds `ravintio-framework` and `.git`. An unmigrated repo cannot run the new hooks, because setup refuses to install them. So the change does not move the root. `ALWAYS_PERMITTED_FILES` dropped `.planifest-session`, which narrows the always-permitted set. `ratchet-check.mjs` and `read-stdin.mjs` have zero changed lines. `check-orchestrator-presence.mjs` changed banner text only.

## Input validation review

The three consumer-controlled inputs this feature adds are `.planifest-setup-flags`, `.planifest-manifest`, and the old ignore and boot blocks. Setup validates the flags file well (fixed-string match). It does not validate the manifest (S-01).

## Network policy

No change. Setup and the hooks make no network calls.

## Infrastructure as Code review

Not applicable. The pack ships no IaC. `hooks/ravintio.yml` changed in names and messages only. Its logic and permissions match the old `planifest.yml`.

## Risk register cross-reference

| Risk | Status in implementation |
|---|---|
| R-011 old consumer markers | Mitigated for the flags file, session marker, ignore blocks, and boot blocks. The manifest read has the S-01 gap. |
| R-012 setup before migration | Mitigated by the stop check in both scripts. |
| R-013 `PLANIFEST_*` loses effect | Only `PLANIFEST_SESSION_ID` keeps a fallback, as the design states. |
| R-016 orphan skill folders | Mitigated by the old-manifest prune, subject to S-01. |
| R-017 old workflow | Out of scope here (migration). S-02 covers the enforcement-path side. |

## Summary

Overall risk rating: Medium.

Top actions before production:

1. Fix S-01 in both `setup.sh` and `setup.ps1`, and add the two survival tests.
2. Add the two old paths to `FAST_PATH_ENFORCEMENT_PATHS` and drop the old OpenCode plugin registration (S-02).
3. File a backlog entry for the containment check on the `.ravintio-manifest` prune.
