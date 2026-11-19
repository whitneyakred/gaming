# Checkpoint 3 readiness — November 19, 2026

Confirmed by the project owner: the MVP demo is **December 4, 2026**, and includes **co-op**. Preparation branch: `checkpoint-readiness`. This file records work and blockers; it does not certify the release.

## Evidence index

| Checklist item | Evidence | Remaining gate |
|---|---|---|
| Release | [Release notes draft](releases/v0.2.0.md) | Local browser/Windows candidates built; review/merge, tag final commit, publish release and rehearse from tag |
| Fan-out | [Traceability](traceability.md), `node tools/check-traceability.mjs` | Resolve named coverage gaps; no automatic Verified claims |
| Pipeline | [Workflow](../.github/workflows/godot-ci.yml) | Admin must select required checks; link green run and deliberately red PR |
| Observability | [Reliability](reliability.md) | Deploy reviewed logging, collect platform log/metrics evidence |
| Calibration | [Calibration worksheet](estimates/calibration.md) | Team actuals, individual estimates, biggest misses, capacity |
| Charter rule | [AGENTS.md](../AGENTS.md), [originating review](room-error-review.md) | Reviewer validates provenance; merge rule by PR and insert link |
| SLO | [Definition and probe](reliability.md) | 20/20 measured; confirm target and deployment version |
| Degradation | [Production-handler test](../online-service/test/degradation.test.mjs) | See local validation record; API and crew-menu tests pass; recovery-removed test fails as required |

## Team information required

The [reported responsibility breakdown and missing-record procedure](estimates/calibration.md#reported-areas-of-responsibility) now identify whom to ask for each area. Responsibilities do not establish actual hours or equal contributions. When WAR records are unavailable, ask the TA about separately labeled retrospective estimates rather than substituting invented actuals.

1. Each teammate: original estimate ranges by use-case ID, estimate date, WAR entries since that date, actual hours and one sentence explaining the biggest miss. Do not estimate historical actuals from commits.
2. Leiton reports approximately 15 hours per teammate through December 4 (90 gross hours). Teammates should confirm this; identify the hours reserved for integration, rehearsal and fixing bugs.
3. Team: identify which use cases are finished and which unfinished v1.0.0 rows are essential. Co-op and the demo date are confirmed; the entire backlog is not.
4. Reviewer: link the review/PR supporting the charter rule and approve its wording. A local review document is useful provenance, but it does not establish a merged PR.
5. Repository admin: enable required checks and provide the red/green PR evidence. Cloudflare owner: capture deployment identity, logs and metrics.

## Merge protection and release procedure

On GitHub, open **Settings → Rules → Rulesets → Protect Main → Require status checks to pass → Add checks**. Select `Lint & Repo Checks`, `Checkpoint Evidence & Harbor Tests`, `Godot Smoke Tests`, and `Export Windows` after those checks appear. Save the ruleset. Confirm an ordinary contributor cannot merge a deliberately failing draft PR; then repair/close that PR. Record its URL here. The audited ruleset had an empty required-check list.

The GDScript lint/format steps remain advisory and are recorded as debt; the Harbor TypeScript check, dependency-failure test, link check and repository hygiene are blocking. The Godot Smoke Tests job runs a selected regression subset; the three-client co-op regression also runs in CI; exhaustive specification-extension coverage remains separate. Passing CI is not complete gameplay acceptance.

Review and merge the gameplay base and readiness work into the intended release branch before tagging. Do not tag an unreviewed preparation commit merely to meet the version requirement. On the tested release commit:

```sh
git tag -a v0.2.0 -m "Holy Ship Checkpoint 3"
git push origin v0.2.0
```

On GitHub **Releases → Draft a new release**, select `v0.2.0`, generate notes, then replace technical-only wording with the reviewed release notes. Attach/export the build from that commit. Rehearse a solo voyage and a two-player co-op voyage from the tag, including host departure and reconnect/error behavior. Record the tag SHA and deployment SHA; do not assume the current website matches the tag.

## Slack draft — replace pending fields before posting

Checkpoint 3 — Holy Ship:
- Release/demo: PENDING published v0.2.0 URL and SHA
- Fan-out: PENDING merged traceability permalink
- CI gate: PENDING green run, red PR, ruleset evidence
- Observability: PENDING deployed health, metrics and failure-log evidence
- Calibration/December 4 forecast: PENDING completed worksheet permalink
- Review-derived charter rule: PENDING merged PR and originating review
- Measured SLO: PENDING result permalink and confirmed target
- Degradation test: PENDING merged test and red/green run evidence

Post one message in the team Slack channel by November 19, 11:59 p.m. This draft has not been sent.

## Local validation

See [November 19 results and repaired regressions](evidence/validation.md). The previously identified failing suites have been repaired and passed locally; full specification-extension review and remote CI evidence remain pending.

## Prepared local builds

The existing release script exported browser and Windows candidates and passed its deployment dry run. [Build manifest](evidence/build-manifest.json) records hashes. Windows files are `builds/holy-ship-harbor-windows/HolyShip.exe` and `HolyShip.pck`; keep them together. Browser output is `builds/web/`, with deployment assembly in `web-site/dist/`. These are ignored build artifacts, not published releases. The matching Godot runtime successfully loaded the exported pack and used normal Quit via `tools/export_smoke.gd`.
