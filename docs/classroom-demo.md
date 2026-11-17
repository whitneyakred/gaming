# Classroom demo: 60 students in 15 crews

The classroom build uses protocol `holy-ship-coop-12`. It targets a **one-hour,
60-player session** on the existing Cloudflare Free plan. It does not promise
unlimited daily multiplayer, and no paid service or billing upgrade is required
by these changes. Everyone must reload the website after deployment. Existing
version-11 voyage saves remain readable.

## What changed

- A shared campus IP can attempt 240 hosts/hour, 1,200 joins/minute, and 600
  uncached list requests/minute. Each sailor still gets only 8 host attempts/hour
  and 20 join attempts/minute within that IP. These limits count attempts,
  including incorrect passwords. Admission, source identity, four-player
  capacity and short-lived single-use tickets remain authoritative.
- Public listings have a five-second edge cache. Directory shards also reuse
  their results for five seconds and invalidate that local cache on changes.
  Passwords, tickets, identities and admission responses are never cached.
  Full/ended cached rooms are rejected immediately when joining.
- The browser refreshes discovery every 30–35 seconds, throttles manual refresh
  to five seconds, and backs off failed requests to at most one/minute.
- Captains target 10 world snapshots/second, uploaded **once per crew** using a
  host-only transport envelope. Godot broadcast RPCs alone still send separate
  uploads, so this optimization is implemented below the RPC layer. The relay
  forwards the same packet to all guests. During the scene handshake or for
  exceptionally large snapshots, the existing targeted/chunked path is used.
- Guests send changed movement, mouse and blocked/focus state immediately.
  Unchanged controls refresh every half second. Local prediction and smooth
  remote interpolation remain active. Host acknowledgements advance for held
  inputs between refreshes; the stale-input watchdog stops controls after 1.5s.
- Receiving guests retain only the newest broadcast snapshot, avoiding a queue
  of obsolete world states after a frame stall. Reliable gameplay actions remain
  on the existing RPC path. Empty voyages skip snapshot encoding/compression.
- WebSocket heartbeats are sent every ten seconds and handled by Cloudflare's
  hibernation auto-response API. Liveness checks include its heartbeat timestamp.
- Room housekeeping/lease renewal runs every 120 seconds instead of 30; directory
  leases last 180 seconds. Normal close/leave events still end sessions promptly.
  A silently broken connection can take up to roughly three minutes to disappear
  from discovery. Clients detect missing responses sooner (20 seconds).
- Directory cleanup no longer scans expired rows on every publication. Cleanup
  alarms are scheduled only when needed. Request gates write counters, but no
  longer rewrite their cleanup alarm on every request. Expiry cleanup is atomic
  and deletes in bounded batches. Gameplay packets never read/write SQLite.

## Free-tier budget

Cloudflare documents 100,000 Durable Object request units/day, with incoming
WebSocket messages counted at 20:1. Workers have a separate shared 100,000
requests/day allowance. DO duration is 13,000 GB-seconds/day and SQL writes are
100,000 rows/day. Other projects/activity on the account consume these budgets.

For 15 crews / 45 guests, at target rates:

| Gameplay | Before | Classroom build |
|---|---:|---:|
| Captain uploads/second | 900 | 150 |
| Guest uploads/second, unchanged controls | 900 | 90 |
| Gameplay request units/hour | 324,000 | 43,200 |
| Gameplay units/hour with 4 inputs/s per guest | — | 59,400 |

The four-input scenario allows regular changes on top of the refresh budget.
Add heartbeats (conservatively 1,080 units/hour), room alarms, directory updates,
admission, reconnects and any unrelated account usage. Plan around **60–70k
DO request units for a busy one-hour class**, starting with adequate quota.
This is a workload estimate, not a hard cap: repeated actions, rapid input
changes, oversized/chunked worlds, reconnect storms or additional classes can
consume more. Fifteen continuously active rooms alone would use approximately
6,750 GB-seconds/hour at 128 MB per room, before other object activity; hibernation
can reduce that. Do not assume a two-hour session fits the duration allowance.

No upgrade is automatically enabled by the game. Free-plan exhaustion can make
online play unavailable. Reduced usage is not a guarantee that a whole day of
classes or arbitrary public traffic will stay within Free.

## Repeatable checks

From `online-service/`, start a **local** emulator in one terminal:

```powershell
npm run dev -- --port 8787 --persist-to ../.godot/classroom-worker-state
```

In a second terminal in that same directory:

```powershell
npm run check
node --test --test-concurrency=1 test/*.test.mjs
$env:CLASSROOM_SECONDS = "300"
npm run test:classroom
```

The load test creates 15 rooms / 60 WebSockets on one IP, sends 2 KB host
snapshots at 10 Hz and guest controls at 4 Hz, verifies room isolation, checks
deliveries/disconnects, and reports latency and projected request units to
`.godot/classroom-load-report.json`. It refuses a non-local target unless
`ALLOW_LIVE_LOAD=yes` is explicitly set. Do not use production for routine load
testing: that would spend the class's daily allowance. Longer local runs can use
`CLASSROOM_SECONDS=3600` or more (maximum 7200).

Godot regression runners:

- `tests/classroom_policy.gd`: immediate control transitions and transport rules.
- `tests/voyage_saves.gd`: including a version-11 resume fixture.
- `tests/network_smoke.gd`: three actual instances, roles `--test-host`,
  `--test-alpha`, `--test-beta`, with `--relay-test`.
- `tests/classroom_session.gd`: four actual instances, roles
  `--class-role host`, `one`, `two`, `three`. Exercises held-input prediction,
  snapshot delivery and actual transport packet rates with a full crew.

For each Godot instance, use `--headless --path . --script <runner> --
--settings-test --harbor-url http://127.0.0.1:8787 <role flags>` from the project
root. These use test settings/saves. Run role groups together, not overlapping
separate runs of the same suite. The four-person runner logs prediction correction
and requires regular snapshots and a bounded upload rate.

## Before class

Validation on November 16, 2026: the final five-minute local transport run held
60 connections in 15 crews with zero errors, sent 93,780 messages, and delivered
124,200 guest snapshots. Its measured rate projects to 56,208 gameplay request
units/hour. Input-to-snapshot latency on the local test machine was 77 ms median,
137 ms p95 and 150 ms p99; these are **not internet/campus latency predictions**.
An actual four-instance Godot run passed with 9.99 host packets/s, 2.67–2.68 guest
packets/s and under four pixels maximum prediction correction in its movement
scenario. The three-instance gameplay suite, 16 API checks, 8 input/transport
policy checks, 15 save checks and 61 menu-flow checks also passed. This was not a
one-hour endurance test or a test of 60 concurrently rendered browser games.

1. Check remaining **Workers and Durable Objects** usage in the Cloudflare
   dashboard on the day. Don't spend the allowance on a live load test first.
2. Rehearse one full crew on the actual school Wi-Fi; localhost cannot validate
   campus filtering, congestion, WAN latency or 60 laptops' graphics performance.
3. Have everyone load the game before the demo starts. Use fifteen captains and
   crew names such as `Table 01` to avoid confusion. Each student uses their own
   device/browser profile; tabs in the same profile share a sailor identity.
4. Captains keep the game tab foregrounded and their laptops awake/plugged in.
   The captain still runs the world; this is not a dedicated-server service.
5. Avoid clearing browser data: the captain's browser owns the voyage saves.
   If the school's network blocks multiplayer, Sail solo remains the fallback.

Sources:
- https://developers.cloudflare.com/durable-objects/platform/pricing/
- https://developers.cloudflare.com/workers/platform/limits/
- https://developers.cloudflare.com/durable-objects/best-practices/websockets/
- https://developers.cloudflare.com/workers/runtime-apis/cache/
