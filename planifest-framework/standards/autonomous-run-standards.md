---
title: "Autonomous Run Standards"
version: "1.0.0"
---
# Autonomous Run Standards

Canonical home for the run-mode rules and for what an `autonomous` run still stops for. The orchestrator and every phase skill link here (feature 0000033, ADR-001).

---

## Run modes

`plan/.run-mode` holds one of three values. The human on the loop picks it at P0 (ADR-002).

| Value | Session flags | Stops the mode skips |
|-------|---------------|----------------------|
| `interactive` | none | None. Every phase gate waits for the human on the loop. |
| `continuous` | `continuous_run: true` | The P1 to P6 phase confirmations, as before. Every other stop remains. |
| `autonomous` | `continuous_run: true` and `autonomous_run: true` | Every stop that isn't on the exception list (see `## Exception list`). |

- **Session flags:** `autonomous` sets both `continuous_run: true` and `autonomous_run: true`. Every existing rule that names `continuous_run` therefore also applies in `autonomous`. Behaviour that only `autonomous` has checks `autonomous_run`.
- **Unknown values:** Any value other than the three reads as `interactive`. An absent or unreadable file also reads as `interactive`. An older framework reads `autonomous` as `interactive` too. This amends 0000012-ADR-005, which recognised only `continuous`.
- **Overrides win:** If a file in `planifest-overrides/instructions/` conflicts with the `autonomous` text, the override wins.
- **Choosing the mode:** Only the human on the loop's answer to the P0 run-mode prompt sets `autonomous`. An override that describes hands-off running never counts as choosing `autonomous`. It never writes `autonomous` to `plan/.run-mode`.
- **Reading the mode after P0:** P0 writes the chosen value to the build-log `Run mode` row (req-006). Readers after P0 use that row, because the P9 marker step deletes `plan/.run-mode`.

---

## Exception list

In `autonomous`, only these six items wait for the human on the loop (ADR-003):

1. A schema change or a destructive operation (orchestrator Hard Limits 2 and 3).
2. A gross deviation.
3. Human review of the running result.
4. Promotion beyond the candidate environment.
5. A human-only input, such as a captcha.
6. An exhausted budget, such as the reversal budget or the approach budget (see `## Changing approach`).

**Handling an item:**

- The agent writes what the item needs, such as a migration proposal or a defect report.
- It finishes every piece of work that doesn't depend on the item.
- It records the item in the build log and lists it in the final report.
- It never asks about the item mid-run.
- For human review, the agent lists every page or endpoint for review as a full link.
- For a human-only input, the agent runs the check up to the point that needs the input.

**Gross deviation:** A gross deviation is a change the reversal protocol would class as *altering*. It changes the confirmed problem, the users, or the in-scope list. Every other deviation keeps the design's intent, and the agent records it as *additive*.

**Who classifies:** The fresh-context `planifest-reversal-assessor` classifies a deviation as *altering*. The agent that deviates never classifies its own deviation. If that agent suspects a gross deviation, it files a defect report and the assessor decides.

**Reversal protocol on:** In `autonomous`, an absent `reversal_protocol` toggle key reads as `on`. The assessor is therefore available in every `autonomous` run.

**Decisions are recorded, not asked:** In `autonomous`, a question that isn't an exception-list item becomes a decision. The one-question rule and recommend-then-confirm give way to this rule. The agent takes the option it would have recommended. It records the decision in the build log. It also records it in the requirement, ADR, or design the decision touches.

**Build-log line formats:**

```
Decision (P{N}): {what was decided} / reason: {one line}
Deviation (P{N}, {additive | altering}): {what changed from the confirmed artifact}
Exception waiting (P{N}, {item}): {what the human on the loop must do}
```

**Reversal step 4 in `autonomous`:** Cases (a) altering, (b) a re-exit from P0, and (c) budget exhaustion become exception-list items. Case (d), a cascade larger than 3 artifacts, isn't on the list. The reversal proceeds, and the build log and the final report record it.

**Standing rules in every mode:**

- Merging a PR stays human-only.
- Hard Limits 2 and 3 stay human-gated.
- No override can remove an item from the list.

**Product extension:** A product adds items in `planifest-overrides/exception-list.yml` under an `additional:` key. The file can only add items. An absent file means the six items alone. Copy `planifest-framework/templates/exception-list.template.yml` to start one. The framework never writes the override file.

---

## Gates as loops

In `autonomous`, each P1 to P6 gate runs as a loop under `planifest-loop-runner`. A checker stands in for the human on the loop (ADR-004, execution-plan D-001).

| Gate | Pass condition | Checker |
|------|----------------|---------|
| P1 | The orchestrator's P1 gate condition | `planifest-design-critic` over the P1 artifacts |
| P2 | The orchestrator's P2 gate condition | `planifest-design-critic` over the P1 and P2 artifacts |
| P3 | Every requirement reaches GREEN | The P4 CI run that follows P3 |
| P4 | CI passes and acceptance criteria verify | The validate loop, then `planifest-verify-by-execution` |
| P5 | The orchestrator's P5 gate condition | A fresh-context re-review of each fixed finding |
| P6 | Zero drift and every expected artifact | The cross-model review gate |

- **Why P3 uses P4:** The P4 CI run is deterministic. It checks the P3 output more strongly than a fresh-context read would.
- **Fresh context:** A fresh-context checker never shares context with the agent that made the artifact (0000016 ADR-006).
- **Existing caps stay:** Each loop keeps its cap. P4 validate keeps 5, and the other loops keep 3.
- **Toggle defaults:** An absent key for a checker reads as `on` in `autonomous`. See the loop runner's Toggle Protocol.
- **No stop:** A gate that passes moves straight to the next phase. A gate that fails follows `## Changing approach`.
- **Gate record:** The orchestrator writes the gate summary to the build log in place of presenting it.

## Changing approach

In `autonomous`, a cap or a no-progress halt starts a new approach rather than a stop (ADR-005).

1. When a loop hits its iteration cap or the no-progress rule, the agent records the attempts and starts a new approach.
2. A new approach states how it differs from each earlier approach, such as a new root-cause hypothesis or a new method. Restating an earlier approach doesn't count as a new one.
3. The iteration counter restarts at 1 for each approach. The approach counter never restarts.
4. The approach counter belongs to one loop instance. At P1, P2, P4, P5, and P6 the instance is the phase gate. At P3 it is each requirement's TDD loop.
5. Each loop instance allows up to 3 approaches. If it needs a fourth, the loop escalates as an exhausted budget, which is an exception-list item. The agent writes an `Exception waiting` build-log line and carries on with work that doesn't depend on the loop.
6. The reversal budget stays at 2 per feature. Its exhaustion is an exception-list item in `autonomous`.
7. If a new approach would change the confirmed design, the agent files a defect report. The fresh-context reversal assessor classes it, never the agent that filed it.

The loop-state file holds the approach counter as a budget counter, so no agent resets it (loop runner Hard Limit 3).

## Visibility

The build log is the human on the loop's view of a run. Two line formats feed it.

| Line | Run mode | Format |
|------|----------|--------|
| Progress | Every run mode | `Progress: P{N} {done \| blocked} at {End}: {one-line summary}` |
| Touchpoint | `autonomous` only | `Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item \| outside list}]` |

Plain-text forms, for copying:

```
Progress: P{N} {done | blocked} at {End}: {one-line summary}
Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item | outside list}]
```

- **`{End}` value:** The progress line reuses the phase block's `End` value. It never takes a second timestamp.
- **When:** Each phase from P1 to P9 writes one progress line at its gate. P7 to P9 write theirs to the archived build log, as the ship agent's other P7 to P9 entries do.
- **Touchpoint:** A touchpoint is any point after the P0 confirmation turn where the run asks the human on the loop something or waits for them. An exception item listed in the final report isn't a touchpoint.
- **Run mode source:** Every reader after P0 takes the run mode from the build-log Header's `Run mode` row. No reader uses `plan/.run-mode` after the P9 marker step deletes it.
- **P8 audit:** In `autonomous`, the build assessment counts touchpoints and flags each one outside the exception list.
- **No push notification:** The run sends no push notification. The build log is the only visibility channel.

---

## Final report

In `autonomous`, the ship agent writes one final report in place of the P9 Step 11 message (ADR-006). The report is the only output of P7 to P9 that addresses the human on the loop. It has these parts, in order:

1. **What shipped:** a short summary from the feature brief and the changelog.
2. **Decisions and deviations:** every `Decision` and `Deviation` line from the build log, including each P7 regression-candidate decision.
3. **Version:** the version from the Step 9 tag.
4. **PR:** the PR URL and its CI result, from `gh pr checks`. If CI hasn't finished, the result reads `pending`. If a `local-git-only` override applies, this part holds the PR title and description instead.
5. **Clean tree:** the clean-tree result of the scoped `git status --porcelain` check at the end of P9 (req-013). It names each file left over or committed, or reads `clean`.
6. **Exceptions waiting:** every `Exception waiting` line from the build log. If there are none, the part reads `none`.

The report ends with this line: "Next: the human on the loop reviews and merges the PR." No mode merges the PR. Step 12 runs after the report.
