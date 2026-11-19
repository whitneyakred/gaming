# Harbor reliability evidence

## Specification

`ROB-HARBOR-unavailable`: If a room service call rejects, the Harbor API shall return HTTP 503, `Cache-Control: no-store`, and JSON error text `The harbor is unavailable. Please try again shortly.` It shall not expose exception details, identities or tickets. When host/join receives that error, the crew menu shall show that guidance, release its busy state and remain offline so the player can retry.

`PER-HARBOR-discovery` (proposed acceptance target; team confirmation required): at least 95% of 20 consecutive synthetic crew-discovery requests shall return HTTP success and a JSON crews array within 2 seconds. The window is one recorded 20-request run, spaced one second after each response. The SLI is good responses / all attempts, including timeouts and parse errors. The error budget is one bad request per run. This intentionally measures a small demo-readiness window, not monthly uptime.

Run `node tools/measure-harbor.mjs https://holy-ship.pages.dev docs/evidence/harbor-slo.json` from the repository root. The output records UTC timestamps, counts, durations and the local source commit (not the deployed commit). It exits nonzero when the proposed target is missed. Record the deployed version separately. A cached discovery response can pass while a backend is broken; this does not measure joining, room RPCs, WebSockets, school Wi-Fi or game frame rate.

## Dependency failure and mutation

Current measurement: [20/20 good discovery requests](evidence/harbor-slo.json), November 19, 2026. This meets the proposed target for that sample only. Target approval and deployment identity are pending.

`node --test online-service/test/degradation.test.mjs` runs the production API handler with a throwing room-service binding. It checks the attempted external call, response status, safe error body, cache prevention and sanitized log event. Node substitutes only the Cloudflare base class; this is a boundary unit test, not a deployed Cloudflare runtime test.

Set `HARBOR_REMOVE_RECOVERY=1` and rerun: the test must fail. This changes only the loaded in-memory source, never the production file. Clear that variable and rerun: the test must pass. Do not count an import or syntax error as the required red result.

`godot --headless --path . --script res://tests/harbor_degradation.gd -- --settings-test` supplies the API failure response to the real host flow and checks the actual crew-menu label, offline state and cleared busy state. It passed locally. Together these tests cover the boundary exception and player-facing recovery; they do not simulate a real Cloudflare outage end to end.

## Deployed observability evidence still required

The existing Worker configuration enables sampled logs. The new failure event is `harbor_dependency_failure` with status 503; it intentionally contains no request URL, user identity, body, password, ticket or exception text. After deployment, open the Harbor service in Cloudflare Workers & Pages and inspect its logs and request/error metrics. Record a platform log event and timestamp from a controlled failure in a preview deployment. Do not deliberately break live players' rooms.

`/api/health` reports process/protocol health only; it does not exercise dependencies. Link both the health response and platform metrics in the checkpoint evidence. Sampling may omit a single failure; use a preview with full log sampling for this exercise. The local mocked test cannot substitute for a platform log-stream capture.
