# Checkpoint 3 readiness — November 19, 2026

Holy Ship, Team 13. MVP demo: **December 4, 2026**, including solo and co-op. [TA message](ta-checkpoint-message.md).

## Evidence index

| Checklist item | Current evidence | Remaining action |
|---|---|---|
| Release | [Published v0.2.0 and Windows download](https://github.com/whitneyakred/gaming/releases/tag/v0.2.0), [build identity](releases/v0.2.0.md) | Human solo/co-op rehearsal from this exact download |
| Fan-out | [Traceability](traceability.md); local paths/headings and 48 UC IDs checked | Partial coverage and specification differences remain named; team must reconcile unfinished scope |
| Pipeline | [Four green checks](https://github.com/whitneyakred/gaming/actions/runs/44632691797), [required-check ruleset](https://github.com/whitneyakred/gaming/rules/26707729), [intentional red PR #103](https://github.com/whitneyakred/gaming/pull/103) | Capture blocked merge evidence after the demonstration checks finish; never merge #103 |
| Observability | [Reliability](reliability.md), [sanitized platform failure log](evidence/platform-failure-log.json) | Existing live evidence is preserved; the service was not redeployed for this release |
| Calibration | [Recovered coarse estimates and capacity forecast](estimates/calibration.md) | Individual estimates, WAR actuals, completed/remaining classifications and biggest misses |
| Charter rule | [AGENTS.md](../AGENTS.md), [originating review](room-error-review.md), [merged #102](https://github.com/whitneyakred/gaming/pull/102) | No additional merge needed |
| SLO | [Definition](reliability.md), [20/20 measurement](evidence/harbor-slo.json) | Adopted 19/20 within two seconds target; sample is not a monthly uptime claim |
| Degradation | [Production-handler test](../online-service/test/degradation.test.mjs), [menu recovery test](../tests/harbor_degradation_suite.gd), green CI above | Recovery-removed negative test remains part of CI |

## Release and link preservation

PR #104 merged into systems-revamp at `a74b40a67c6eab1849952f7e15eaf77f39c09cab`. Its tree exactly matches the passing PR head `5dd8a50acade19216855450d78f02b8f9b80bb12`. The annotated v0.2.0 tag points to that merge. The release includes the unmodified CI Windows ZIP and checksum; packaged startup and normal Quit passed.

Do not move or replace v0.2.0. Earlier links pinned to `343afb5599e0067be34e5bd05d49c425f6b0bcb4` and older CI runs remain valid historical evidence. The team's calibration link follows systems-revamp and displays current documentation. The live browser deployment was not changed and is not claimed to match the tag.

## Pipeline demonstration

Whitney's active Protect Main ruleset now requires Lint & Repo Checks, Checkpoint Evidence & Harbor Tests, Godot Smoke Tests and Export Windows, plus one approval, on the default branch. It does not protect systems-revamp.

PR #103 intentionally omits a script UID and must never be merged. Its target was corrected from systems-revamp to protected main, keeping the same URL, and a content-identical commit triggered fresh checks. The [required Lint & Repo Checks job failed](https://github.com/whitneyakred/gaming/actions/runs/44634819810/job/135950501390) on that corrected target. Capture the failed-check and blocked-merge UI together; no merge attempt was made. Reviewer approval can independently block a PR; include the failed required check in the evidence rather than claiming an approval block alone proves the check gate. Close #103 without merging after the TA has reviewed the evidence; the closed URL will remain available.

## What only the team can supply

1. Run the published Windows download through the solo/co-op classroom demo. Record who tested, when, and the tag. Earlier successful rehearsal is useful but predates the tag.
2. Transfer existing WAR/estimate records into the calibration worksheet, if Whitney has collected them elsewhere. Each finished case needs person, estimate range/date, actual hours/source, ratio and biggest miss. The supplied 2–3-hour summary cannot be allocated across unidentified cases automatically.
3. Classify remaining MVP work. Reported capacity is 90 hours; a proposed 18-hour reserve leaves 72 usable hours. The worksheet gives sensitivity scenarios, not a fabricated calibrated yes/no.
4. Post the updated TA message or a follow-up in the same Slack thread. Nothing here has been sent to Slack.

## Validation limits

CI covers selected game regressions and three-client co-op, not every specification extension. GDScript style checks remain advisory. [Validation record](evidence/validation.md) preserves details. These gaps are disclosed; this file does not certify full assignment completion.
