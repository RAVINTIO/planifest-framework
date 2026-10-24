# Design-Critic Verdict (P2, iteration 1)
**Mode:** on (autonomous default, approach 1)
**Mechanical check:** exit 1. Three criteria-count warnings (req-003, req-004, req-006) and three errors:
- `adr/ADR-004-quiet-mode-failure-detection.md`: references ADR-014 but no such file exists in adr/
- `adr/ADR-005-timing-check-warm-up-and-single-call.md`: references ADR-014 but no such file exists in adr/
- `adr/ADR-007-rerun-setup-migration-0-36-0.md`: references ADR-010 but no such file exists in adr/

The three references name feature 0000037 ADRs. The check reads them as local. A mechanical failure is an automatic REJECT on the affected ADRs.

**Overall:** REJECT

## Targeted tests

| Test | Result | Evidence |
|------|--------|----------|
| No ADR weakens a gate, hook, critic, review, TDD loop, or assertion | pass, with one caveat | ADR-006 names nine exempt fresh-context roles and bans removing a maker-checker or TDD step. ADR-005 keeps the 200 ms limit. ADR-004 caveat: see finding 3. |
| ADR-002 byte budget | pass | `SKILL.md` is 77,635 bytes, identical at `5966840`. Phase 0 (lines 239 to 588) is 33,261 bytes. Adoption Modes (lines 768 to 818) is 4,673 bytes. Remainder is 39,701, so the margin to 41,500 is 1,799. The ADR states about 39,900 and about 1,600. Both are conservative. |
| ADR-004 hung suite surfaces | fail | See finding 2. |
| ADR-003 every `model:` place listed | partial | See finding 4. |
| ADR-007 file list complete | partial | See finding 5. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every ADR names a test: ADR-002 rule 4 to 6 and size test, ADR-003 rule 5, ADR-004 rule 7, ADR-005 rule 7, ADR-006 rule 8. |
| 2 Traceability | pass | Each ADR maps to a requirement in its Context. ADR-001 covers all seven. |
| 3 Real alternatives | pass | Each ADR holds four or five alternatives with rejection reasons. ADR-001 was not re-checked beyond its stack decision. |
| 4 Honest consequences | pass | Each ADR has a hurting negative. ADR-004 names a silent long suite, but gives no mitigation (finding 2). |
| 5 Scope boundaries | pass | Unchanged from P1 approval. |
| 6 Risks and mitigations | fail | ADR-004 risk "suite prints FAIL as test data" lets the test writer "adjust any suite found" with no bar on changing assertions (finding 6). |
| 7 NFRs measurable | pass | 41,500 bytes, 200 ms, and the model value set are all checkable. |
| 8 Internal consistency | fail | Mechanical failure. ADR-003 says "every `model:` line" while skills use `recommended_model:` (finding 4). |
| 9 Split step | pass | Each over-three requirement carries `Split step: keep`. |

## Findings (severity-ordered)
1. [major] `adr/ADR-004-quiet-mode-failure-detection.md`, `adr/ADR-005-timing-check-warm-up-and-single-call.md`, `adr/ADR-007-rerun-setup-migration-0-36-0.md`: the cross-feature references `0000037 ADR-014` and `0000037 ADR-010` fail the mechanical check. Reword them as `feature 0000037, ADR 014` or similar so the token `ADR-NNN` does not appear.
2. [major] `adr/ADR-004-quiet-mode-failure-detection.md`: a hung suite can stay hidden. Quiet mode prints nothing until a suite ends, and the runner has no timeout. If a CI job timeout or the human ends the whole runner, the failed-suite list never prints and the capture file is lost. Default mode would show which suite was running. Decision 6 only covers a timeout that ends the suite and not the runner. Add a `trap` on `INT` and `TERM` that prints the running suite name and its captured `FAIL:` lines before exit, with no timeout added.
3. [minor] `adr/ADR-004-quiet-mode-failure-detection.md`: the summary says a failed suite shows its `FAIL` lines, but rule 5 forbids a suite header. State that the suite-name prefix on each `FAIL` line is the only suite marker, and that the trap in finding 2 follows the same format.
4. [major] `adr/ADR-003-claude-code-model-values.md`: the list of places is nearly complete but not exact. Standard line 35 (also holds the text "or latest Sonnet"), lines 124 and 127 (two skeleton calls), ship-agent line 186, and `pipeline-reference.md` line 111 are covered. Two gaps remain. First, the test reads "every `model:` line in SKILL.md" while eight skills carry `recommended_model:` and ship-agent line 186 is an indented `model:` in a code block. State the exact pattern and that `recommended_model:` is included. Second, `pipeline-reference.md` is edited but the test does not read it, so it can drift again. Add it to the test sources.
5. [minor] `adr/ADR-007-rerun-setup-migration-0-36-0.md`: `pipeline-reference.md` is listed "if setup delivers it". `setup.sh` has no copy of it. Remove it from the list now and say the P6 recheck confirms. The rest of the list matches the changes in ADR-002 to ADR-006 and req-007. The tier-table edit in the dispatch standard is covered.
6. [minor] `adr/ADR-004-quiet-mode-failure-detection.md`: the P3 scan may adjust suites that print `FAIL:` as data. Say the change may alter only the printed text and never an assertion or an exit path.
7. [minor] `adr/ADR-002-orchestrator-reference-files.md`: the only guard against a skipped P0 reference read is a wording test. Add the read to the `Phase 0 to Phase 1 Gate Checklist` or the P0 start log line, so a skip shows in the build log.
