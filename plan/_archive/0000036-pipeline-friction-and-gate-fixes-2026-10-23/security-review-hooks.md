---
title: "Security Review - enforcement hooks (0000036)"
summary: "P5 review of the req-008, req-009, and req-011 hook changes and the req-010 runner change, with fixture runs on this branch and on main."
status: "draft"
version: "0.1.0"
---
# Security Review - enforcement hooks (0000036)

**Skill:** [security-agent](../../planifest-framework/skills/planifest-security-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Scope:** `git diff main...HEAD -- planifest-framework/hooks/` (`path-rules.mjs`, `ratchet-check.mjs`, `em-dash-guard.mjs`) and `planifest-framework/tests/run-tests.sh`
**Compared against:** `main` at `5c7859a`, cloned into a scratch folder
**Platform:** macOS (Darwin 25.6.0), Node v26.12.0. No Linux host was available, because the Docker daemon wasn't running.

## Summary

Overall risk rating for this area: **Medium**.

The changes strengthen the gate. No finding is Critical or High. The rating comes from a fail-open class in `readDesign` that predates this feature. A regular `design.md` that can't be read still admits every write, enforcement paths included. Finding 2 shows a new way to reach it with no race and no `chmod`. Finding 1 shows a race that this feature adds to the same class.

What the fixtures confirmed:

- A folder, FIFO, or link at `design.md` now blocks. On `main`, a folder admits the write and a FIFO holds the hook until the 5-second limit stops it.
- A permitted name inside an enforcement path now takes the normal route. Case, `hookſ`, backslash, `..`, absolute, and linked-folder variants all block. On `main`, each of them is admitted.
- `shown()` escapes every Cc, Cf, Zl, and Zp code point across U+0000 to U+10FFFF. Its cut never ends inside an escape or a surrogate pair. No crafted value forged a `[Planifest]` line through `ratchet-check.mjs` or `em-dash-guard.mjs`.
- No changed hook exits with a code other than 0 or 2 on the inputs tried.
- NFR-003 holds. No new spawn or import outside `node:`, `./path-rules.mjs`, and `./read-stdin.mjs`.
- The four 0000036 suites for req-008 to req-011 pass: 47, 39, 37, and 43 cases.

Top actions before production:

1. Route an open error after `lstatSync` (`ELOOP`, `EMLINK`, `ENOENT`, `ENOTDIR`) to no design, not to fail open (finding 1).
2. Cap the `design.md` size before the read, and treat an oversize file as no design (finding 2, backlog 0000178).
3. Decide 0000162 and 0000178 together, since both cover the same fail-open line.

## Threat model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A folder at `design.md` admits a `src/` write (EISDIR fails open) | Elevation | High on `main` | Mitigated. `readDesign` returns non-regular and `scopeVerdict` blocks (req-008). |
| A FIFO at `design.md` holds the hook until the tool timeout | DoS | Medium on `main` | Mitigated. `lstatSync` runs first, and the open uses `O_NONBLOCK`. The hook exits in milliseconds. |
| A link at `design.md` points the gate at a design outside `plan/` | Tampering | Low | Mitigated. A link reads as no design (ADR-002). |
| A link or deletion swapped in between `lstatSync` and the open fails the gate open | Elevation | Low | Not mitigated. See finding 1. The `ELOOP` case is new in this feature. |
| A regular `design.md` over Node's string limit fails the gate open, with no race | Elevation | Medium | Not mitigated. Pre-existing. See finding 2 and backlog 0000178. |
| `chmod 000 plan/current/design.md` fails the gate open | Elevation | Medium | Not mitigated. Pre-existing and accepted in ADR-002. Backlog 0000162 tracks it. |
| A linked `plan/` or `plan/current/` folder serves a design from elsewhere | Tampering | Low | Not mitigated. Pre-existing. See finding 3. |
| A permitted name such as `CLAUDE.md` inside an enforcement folder skips the gate | Elevation | Medium on `main` | Mitigated. The name shortcut checks `isEnforcementPath` first (req-009). |
| An enforcement glob below `plan/` or `docs/` stays always permitted | Elevation | Low | Accepted by ADR-003. See finding 4. |
| A crafted criterion or target forges or hides a line of hook output | Spoofing | Medium on `main` | Mitigated. Both hooks print through `shown()` (req-011). |
| A literal backslash or lone surrogate in a value makes printed text ambiguous | Spoofing | Low | Not mitigated. Pre-existing. See finding 5. |
| A `.gitattributes` file, always permitted, hides enforcement diffs from review | Repudiation | Low | Not mitigated. Pre-existing. See finding 6 and backlog 0000179. |
| `em-dash-guard.mjs` exits 1 when `path-rules.mjs` is missing beside it | DoS | Low | Mitigated by setup, which copies every `*.mjs` in `hooks/enforcement/`. See finding 7. |
| A suite inherits `CLAUDE_PROJECT_DIR` and tests the real repository | Tampering | Low | Mitigated. `run-tests.sh` clears the variable (req-010). |

## Findings

### 1. A link swapped in after `lstatSync` fails the gate open

- **Severity:** Low
- **Status:** New for the link case. Pre-existing for a deletion.
- **Location:** `planifest-framework/hooks/enforcement/path-rules.mjs:786-791` and `:846`

`readDesign` calls `lstatSync`, then `openSync` with `O_NOFOLLOW`. If a link replaces the file in that window, the open throws `ELOOP`. The `catch` at `:790` returns `unreadable`, and `evaluateWrite` admits the write at `:846`. That includes enforcement paths.

On `main`, the same swap is followed and read, so the write still meets the design. ADR-002 says this "mirrors today's behaviour", but for a link it doesn't. A deletion in the window gives `ENOENT`, which fails open on both branches.

On Windows, `fs.constants` defines no `O_NOFOLLOW`. A swapped link is then followed, and `fstatSync` sees its regular target. The gate reads that target as the design.

**Reproduction.** The harness wraps `fs.lstatSync` with `syncBuiltinESMExports()`. It swaps the file once, right after the `lstatSync` call on `design.md`. The design lists only `src/allowed/`.

```
node scratchpad/swap.mjs planifest-framework/hooks/enforcement/path-rules.mjs link
mode=link target=src/other/a.js allowed=true
mode=link target=planifest-framework/hooks/enforcement/gate-write.mjs allowed=true

node scratchpad/swap.mjs <main clone>/planifest-framework/hooks/enforcement/path-rules.mjs link
mode=link target=src/other/a.js allowed=false
mode=link target=planifest-framework/hooks/enforcement/gate-write.mjs allowed=false
```

The `rm` mode gives `allowed=true` on both branches. The `fifo` and `dir` modes block on this branch, because `fstatSync` catches them. A live race against `gate-write.mjs` (400 runs per mode) never hit the window, so the attack needs many attempts. It also needs a writer loop, which the shell guard permits under `plan/`.

**Fix.** In `readDesign`, map an open error of `ELOOP`, `EMLINK` (FreeBSD's `O_NOFOLLOW` code), `ENOENT`, or `ENOTDIR` to `non-regular` or `missing`. Keep fail-open for other errors only. Add the swap harness as a suite case. Correct the ADR-002 sentence that says the `ELOOP` side mirrors today.

### 2. An oversize regular `design.md` fails the gate open with no race

- **Severity:** Medium
- **Status:** Pre-existing. Filed as backlog 0000178.
- **Location:** `planifest-framework/hooks/enforcement/path-rules.mjs:789-791` and `:846`

`readFileSync(fd, "utf-8")` throws `ERR_STRING_TOO_LONG` past about 512 MiB. It throws `ERR_FS_FILE_TOO_LARGE` past 2 GiB. The `catch` returns `unreadable`, so every write passes. A sparse file costs no disk space. The shell guard doesn't stop `truncate` on a `plan/` path. Backlog 0000162 names only `EACCES` and `EPERM`, so its fix wouldn't cover this.

**Reproduction.** The design lists only `src/allowed/`. The target is an enforcement path.

```
truncate -s 400M plan/current/design.md   # gate-write.mjs exits 2, 0.13 s
truncate -s 600M plan/current/design.md   # gate-write.mjs exits 0, 0.11 s
truncate -s 3G   plan/current/design.md   # gate-write.mjs exits 0
```

The 3 GiB case also exits 0 on `main`.

**Fix.** Check `fstatSync(fd).size` against a cap before the read, such as 1 MiB. Treat an oversize file as no design, so `scopeVerdict` judges the write.

### 3. A linked `plan/` or `plan/current/` folder serves a design from elsewhere

- **Severity:** Low
- **Status:** Pre-existing
- **Location:** `planifest-framework/hooks/enforcement/path-rules.mjs:780` and `:787`

`lstatSync` and `O_NOFOLLOW` act on the last segment only. A link at `plan/current` or `plan` is followed. A regular `design.md` behind it reads as the design. ADR-002 names a link at `design.md` as non-regular, but a linked folder gets around that intent.

The agent gains no new power, because `plan/` is always permitted. It can write `design.md` there directly. The finding matters only if a later feature treats `design.md` as tamper-evident.

**Reproduction.**

```
mkdir elsewhere; printf '# D\n\n## Component Paths\n\n- src/\n' > elsewhere/design.md
rmdir plan/current; ln -s "$PWD/elsewhere" plan/current
gate-write.mjs on src/a.js   -> rc=0 (branch and main)
```

A FIFO behind a linked folder still blocks on this branch (rc=2). It holds the hook on `main` (rc=142, the 5-second limit).

**Fix.** If the threat model needs it, compare `realpathSync` of `plan/current` with `join(root, "plan", "current")`. Treat a mismatch as non-regular. Otherwise, record the gap in ADR-002.

### 4. Enforcement globs below `plan/` and `docs/` stay always permitted

- **Severity:** Low
- **Status:** Pre-existing, accepted in ADR-003
- **Location:** `planifest-framework/hooks/enforcement/path-rules.mjs:442`

The prefix check now runs before the name check. A path such as `plan/x/hooks/enforcement/gate-write.mjs` or `docs/setup.sh` matches a `**/` entry. It still passes with no design. Upper-case variants such as `Plan/` and `DOCS/` also pass, because `norm()` folds case. On a case-sensitive file system, those are separate folders.

No installed hook or setup script runs from `plan/` or `docs/` today, so nothing executes these files.

**Reproduction.** With no design and no record, `gate-write.mjs` exits 0 for each of these on both branches:

- `plan/x/hooks/enforcement/gate-write.mjs`
- `docs/setup.sh`
- `docs/hooks/adapters/a.mjs`
- `Plan/hooks/enforcement/x.mjs`
- `DOCS/setup.sh`

**Fix.** None needed now. If setup ever installs to a path below `plan/` or `docs/`, apply `isEnforcementPath` before the prefix shortcut too.

### 5. `shown()` leaves a literal backslash and lone surrogates as they are

- **Severity:** Low
- **Status:** Pre-existing
- **Location:** `planifest-framework/hooks/enforcement/path-rules.mjs:124` and `:136-145`

`CONTROL_RE` doesn't match `\` or Cs code points. A value that holds the six characters `\u{202E}` prints the same as a real escaped U+202E. A lone surrogate prints raw, and stderr writes it as U+FFFD. A value can also hold `[Planifest]` text in the middle of its own line. None of these starts a new line, so none forges a hook line.

**Reproduction.**

```
shown("a\\u{202E}b\\nc", 80)       -> a\u{202E}b\nc   (same text as an escaped control)
shown("a\ud800b\udc00c", 80)       -> returned unchanged
```

Every Cc, Cf, Zl, and Zp code point from U+0000 to U+10FFFF came back escaped, with 0 failures over caps 0 to 14. On `main`, the same check fails 1,788 times on cut position.

**Fix.** Escape `\` as `\\`, and escape Cs code points as `\u{D800}`. Both change block text, so update suites that match exact text in the same change (R-003).

Also, `shown(p, NaN)` now returns the whole escaped text, where `main` returned "". No caller passes a computed cap, so this has no effect today. A `Number.isFinite` guard would keep the cap safe.

### 6. A `.gitattributes` file can hide enforcement changes from review

- **Severity:** Low
- **Status:** Pre-existing. Filed as backlog 0000179.
- **Location:** `planifest-framework/hooks/enforcement/path-rules.mjs:58-63`

`.gitattributes` is always permitted in any folder outside the enforcement list. That includes the repository root and `planifest-framework/`. A line such as `planifest-framework/hooks/** -diff linguist-generated` makes `git diff` print `Binary files ... differ` for a hook change. GitHub also collapses generated files by default. An agent with a design that covers the hooks could then land a change that the human on the loop doesn't read. The `.gitattributes` change itself still shows in the diff.

**Reproduction.**

```
echo 'planifest-framework/hooks/** -diff linguist-generated' > .gitattributes
gate-write.mjs on .gitattributes -> rc=0, no design needed
git diff -> Binary files a/planifest-framework/hooks/enforcement/gate-write.mjs and b/... differ
```

**Fix.** Treat `.gitattributes` as a normal path in folders that hold enforcement paths, or add root `.gitattributes` to the enforcement list. Decide at pickup.

### 7. `em-dash-guard.mjs` now depends on `path-rules.mjs` at load

- **Severity:** Low
- **Status:** New
- **Location:** `planifest-framework/hooks/enforcement/em-dash-guard.mjs:43`

The static import runs before the hook's `try`. If `path-rules.mjs` is missing, Node exits 1. Claude Code treats exit 1 as a non-blocking error, so the guard fails open. That doesn't match the 0 or 2 contract.

`setup.sh:344-350` and `:446-452` copy every `*.mjs` in `hooks/enforcement/`. The same gap already exists for `gate-write.mjs`. Only a partial or hand-made install reaches it.

**Reproduction.** Not run. It follows from ES module load order, and setup never produces the partial install.

**Fix.** None needed. If partial installs become a concern, a dynamic `import()` inside the `try` would keep the 0 or 2 contract.

## Checks with no finding

| Check | Result |
|---|---|
| Folder, FIFO, link, and dangling link at `design.md` | Branch rc=2 with the "not a regular file" line from both `gate-write.mjs` and `shell-write-guard.mjs`. `main`: rc=0, rc=142, rc=0, and rc=2 with no line. |
| Swap to a FIFO or a folder after `lstatSync` | Branch blocks, because `fstatSync` sees the new type. `main` holds the hook on the FIFO (rc=142) and admits the folder. |
| `EACCES` on `lstatSync` (`plan/current` mode `600`) | rc=2 with `NO_DESIGN_REASON` alone, on both branches. |
| `O_NONBLOCK` and `O_NOFOLLOW` on macOS and Linux | macOS defines 4 and 256. Linux defines 2048 and 131072. The code reads them from `fs.constants`, so each platform gets its own. A regular file ignores `O_NONBLOCK` on both. |
| Permitted-name variants inside enforcement paths | Branch rc=2 for `CLAUDE.md`, `claude.md`, `Planifest-Framework/HOOKS/Enforcement/Claude.MD`, `hookſ`, `.claude/hooks/enforcement/AGENTS.md`, `.git/hooks/pause.md`, and `.git/.gitignore`. Also rc=2 for `..`, `//`, a trailing slash, a backslash form, absolute, and `//`-rooted forms. Every one is rc=0 on `main`. |
| A linked folder into an enforcement path (`src/link/CLAUDE.md`) | Branch rc=2 from both hooks. `main` rc=0. |
| Names outside enforcement paths | `src/a/CLAUDE.md` and root `CLAUDE.md` stay rc=0, as req-009 requires. |
| Lookalike names (`ＣＬＡＵＤＥ.md`, zero-width space, trailing dot or space, `::$DATA`) | rc=2 on both branches. None matches a permitted name. |
| Forging through `ratchet-check.mjs` with VT, FF, NEL, ESC, CSI (U+009B), and U+202E | Branch: every character escaped, no raw control in stdout or stderr. `main`: raw controls in output. |
| Forging through `em-dash-guard.mjs` with `\n`, `\r`, U+2028, NEL, ESC, U+202E, and U+2066 | Branch: escaped, no new line. `main`: raw `\n` starts a new stderr line. |
| Caps | Both hooks cut a 300-character value to 200 code units. |
| Exit codes on odd input | Non-string `file_path` or `cwd`, NUL bytes, lone surrogates, and 5,000-segment paths all exit 0 or 2. No changed hook exits with another code. |
| NFR-003 | Imports in the five hooks are `node:fs`, `node:path`, `node:os`, `./path-rules.mjs`, and `./read-stdin.mjs`. The only spawn is the known `git` call at `ratchet-check.mjs:150` (backlog 0000128). |
| `run-tests.sh` `unset CLAUDE_PROJECT_DIR` | Test-only. Suites that need a value set it per call. It weakens no hook. |
| Timing | `gate-write.mjs` with a regular design took 80 to 130 ms. `shown()` on a 2,000,000-character bidi string returns in under 1 ms, against 140 ms on `main`. |

## Risk register cross-reference

| Risk | Status after review |
|---|---|
| R-003 (`shown()` text shift breaks suites) | Mitigated. The P4 full run passed (97 feature and 33 regression suites). |
| R-005 (non-regular narrowing opens a gap) | Partly mitigated. Non-regular files and a throwing `lstatSync` block. Open errors after `lstatSync` still fail open (finding 1). Oversize files fail open too (finding 2). |
| R-006 (FIFO stalls the hook) | Mitigated. Verified for a FIFO at `design.md`, behind a linked folder, and swapped in after `lstatSync`. |
| R-007 (permitted names in enforcement paths) | Mitigated. Blocks and admits match req-009 in every variant tried. |
| R-008 (Fast Path admits an enforcement path) | Mitigated. The enforcement check still runs before the record. The req-009 suite's record cases pass. |
| R-009 (cut splits an escape) | Mitigated. 0 failures over every code point. |
| R-010 (new spawn or import) | Mitigated. See NFR-003 above. |
| R-011 (500 ms budget) | Mitigated. 80 to 130 ms per call. |
| R-024 (runner change hides a suite) | Mitigated for the runner. The req-010 suite enforces the per-suite rule. |

## Backlog entries filed

- 0000178: an oversize regular `design.md` fails the write gate open (finding 2).
- 0000179: an always-permitted `.gitattributes` can hide enforcement diffs (finding 6).

## Reproduction harnesses

Every fixture ran under `mktemp -d` with `CLAUDE_PROJECT_DIR` unset. Each harness takes a hooks folder, so the same run covers this branch and the `main` clone.

- `h.sh`: file-type, permission, and permitted-name cases for both write gates.
- `race.sh`: a live swap loop against `gate-write.mjs`.
- `swap.mjs`: a fixed swap right after `lstatSync`, or after `existsSync` on `main`.
- `shown.mjs`: a property check over every code point and caps 0 to 14.
- `forge.mjs`: forging attempts and odd inputs for `ratchet-check.mjs` and `em-dash-guard.mjs`.

The harnesses live in the session scratchpad. They aren't part of the repository.
