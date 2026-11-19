# Local responsiveness and prompt disconnects

Companion to [the multiplayer system guide](multiplayer-system.md). This describes
the current implementation, not a proposed design. Updated November 18, 2026.

## Local movement and station controls

Previously, guests waited for the captain's next snapshot and interpolated their
own player toward it. This added a round trip to the feeling of movement. Sail
angles also jumped directly to each snapshot value.

`NetworkSession._physics_process()` now calls `_predict_local()` for the local
guest each physics frame. It calls the same `player.move_crew()` movement method
used by the host, including its collision and movement-lock rules. Sail trim
and helm angles also react immediately when that player owns the station.
Ownership itself is still confirmed by the host; taking a station is not guessed.

Changed controls send immediately; unchanged controls refresh every 0.5 seconds.
The sequence number is the client's physics-frame number. The host accepts only
increasing sequences and advances its acknowledgement while simulating held
input between refreshes. Snapshots include that acknowledgement as crew[id].ack.
World snapshots target 10 Hz. The current protocol is holy-ship-coop-13.

Each guest retains at most 120 predicted frames, with position, sail trim and
wheel angle. `_reconcile_local()` discards frames through the acknowledgement
and compares the matching predicted position with the host's position. The
remaining movement is kept, rather than resetting the player to an old snapshot.

Small position errors are corrected exponentially at rate 12 per second in
`_predict_local()`. The same adjustment shifts retained prediction records so
the next acknowledgement compares positions in the corrected space. Large
errors over 150 world/design pixels, boarding changes and station changes reset
the prediction history. Those resets deliberately favor host correctness over
concealing a genuine teleport or movement-state change.

Local sail/helm drift is corrected exponentially at rate 8 per second, preserving
adjustments made since the acknowledged input. Ship and remote crew positions
use the timestamped playback buffer described below. Remote station angles
add exponential easing at rate 18 per second. Local player positions are
excluded from remote-player playback.

Opening the map retains an occupied station and its keyboard controls. Map
clicks are not forwarded as held gameplay mouse input. Walking without a station
remains blocked by the map in the online input path. Station UI and camera focus
belong to the local operator; the shared station state still belongs to the host.

This is bounded local prediction with acknowledgement-based correction, not a
deterministic rollback simulation or a replacement for authority. WebSockets
still deliver ordered traffic, the host still samples input, and poor connections
can still cause corrections. Inventory, catches, chest transfers, cooking and
station ownership remain authoritative. Do not make those optimistic merely to
hide latency: doing so can duplicate items or show a catch the host rejected.

### Files and tuning points

- `scripts/network/network_session.gd`: prediction history, input sending,
  acknowledgements, reconciliation, interpolation, and reset on leaving.
- `scripts/network/snapshot_buffer.gd`: playback delay, bounded history, clock
  adjustment, transition handling and local underrun counter.
- `scripts/player.gd`: movement and movement-lock rules shared by prediction
  and host simulation.
- `scripts/sailing/ship_motion.gd`: clamps for sail and helm values.
- `scripts/network/harbor_peer.gd`: bounded queues and congestion behavior.

Keep host and guest movement speeds/clamps consistent. Raising snapshot rate
increases relay traffic; it is not the first fix for responsiveness. Test start,
stop, reversal, diagonal motion, deck collisions, swimming, boarding, station
entry/exit and reconnect when changing these values. Host physics and guest
presentation are different, so always inspect a guest as well as the captain.

## Normal exit versus lost connection

Normal exits now have explicit notifications instead of relying only on timeout:

1. `HarborPeer._close()` sends a WebSocket `leave` control message before closing.
2. On Web, `HarborService` installs a `pagehide` handler for browser Back, reload
   and tab close. It sends a one-time `navigator.sendBeacon()` POST to
   `/api/crews/{room_id}/leave`. If queuing the beacon fails, it attempts a
   keepalive fetch. Normal in-game leaving invokes this handler too.
3. The body contains the original connection ticket. The room keeps only its
   hash on the socket attachment and accepts it solely for that connection's
   departure. It is not the persistent sailor token or a room-wide permission.
4. `VoyageRoom.depart()` marks the attachment departed before asynchronous
   cleanup. `sessions()` excludes departed sockets immediately, freeing both
   capacity and the duplicate-identity check. Remaining peers receive
   `peer_left`, and the directory is updated. Host departure ends the room.
5. Repeated notifications are harmless. A late notification from an old page
   cannot remove the same sailor's new connection because it has a new ticket.

The departure endpoint can also cancel a not-yet-used ticket. Leaving while a
connection is being established therefore does not leave that ticket reserving
a guest slot until its normal expiration. Do not log tickets or beacon bodies.

No new repeating timer or faster polling was added. A departure adds a small
number of messages/requests once at exit. Simply switching tabs does not fire
this departure path; `visibilitychange` is intentionally not used to kick players.

Browser lifecycle delivery is best effort. A crash, power loss or lost internet
can prevent all exit messages from reaching the service. Existing safeguards
remain: ten-second client heartbeats, a 20-second client silence timeout,
120-second room housekeeping alarms with a 60-second socket-silence threshold,
and 180-second directory leases. These are not exact UI deadlines. Browsers
showing Browse crews refresh about every 30–35 seconds;
**Refresh crews** fetches sooner, and opening Browse fetches a fresh list.

## Testing and observed results

Local relay, in two terminals from `online-service/`:

```powershell
npm.cmd run dev
```

```powershell
npm.cmd run check
npm.cmd test
```

`test/departure.test.mjs` checks immediate slot release, same-identity rejoin,
wrong-ticket protection, repeated old notifications, explicit socket leave and
host listing removal. The relay suite also checks admission, capacity and packet
identity/routing. The combined suite passed 11 tests when this change shipped.

For the browser navigation regression, use isolated test crews, not a real crew:

```powershell
$env:HARBOR_TEST_URL = 'https://holy-ship.pages.dev'
$env:DEPARTURE_CHECK = '1'
node test/browser-pair.mjs
```

This launches separate Chromium profiles, hosts and joins, navigates the guest
away, verifies occupancy after one second, then reloads in the same profile and
rejoins. The deployed test passed with the guest slot released by that one-second
check. This is an observed result, not a guarantee for every network or browser.
The script currently uses the Windows Chrome executable path; adjust it when
running on another development machine.

`tests/network_smoke_suite.gd` additionally checks immediate predicted guest
movement before a host response, shared gameplay and reconnect inventory. See
[multiplayer-testing.md](multiplayer-testing.md) for the three-process setup.
Real Mac/hotspot and high-latency play sessions remain important subjective
checks: passing a scripted connection test does not prove movement feels ideal.

## Shipping related changes

Export the game and deploy Pages for changes to GDScript or menu/game assets.
Deploy the harbor Worker for relay code changes. For changes spanning both,
deploy the backend and matching game as described in the
[release guide](online-services-setup.md), then have players reload.
Both game and Worker must use matching protocol identifiers. The smoothing
addition keeps protocol 13 and supports older protocol-13 snapshots without
timestamps. Have every player reload for consistent behavior. See the main
multiplayer guide for save-version compatibility.


## Historical context: November 15 / protocol 6

Guest fishing runs locally at 60 Hz. Reliable batches of six hold/release inputs
are sent at 10 Hz; the host replays the seeded fight and alone awards catches.
Snapshots do not overwrite the local tension bar. Stale, duplicate and excessively
fast input is rejected. Bite timing includes 750 ms transport grace.

Host departure marks the room ended before closing guest sockets. The directory
keeps a three-minute hidden tombstone so late guest disconnects cannot republish
the listing. Normal departure is immediate; crashes still rely on timeout cleanup.

Hosts now select one of three dated local saves. Browser storage is synchronous
localStorage; desktop saves use atomic files. Autosave runs every 20 seconds and
on normal exit/page navigation. Old native single saves migrate once. Protocols
1–6 load. See [save slots](save-slots.md) for persistence and capacity details.


## Historical context: world survival / protocol 8

The bounded seeded world, shared sharks, health, death and sinking rules are
implemented in [world survival](world-survival.md). That release introduced protocol 8. The current protocol is 13;
the game and harbor must match.


## Guest smoothing update — November 18, 2026

Guest ship movement now uses a bounded 150 ms snapshot playback buffer with
host monotonic timestamps. Remote crew positions use that same timeline.
Playback gently adjusts its clock for drift; duplicate/out-of-order snapshots
are ignored, teleports and gaps over 500 ms reset it, and outages hold the last
host pose rather than extrapolating through land. At most 12 snapshots remain
in memory. SnapshotBuffer.underruns counts frames that exhaust the buffer for
local diagnostics; it sends no telemetry. Older hosts without timestamps use
the existing 10 Hz sequence as a fallback.

Walking, helm angle and sail trim remain locally predicted. Helm/trim drift is
now corrected exponentially at 8 per second, with matching corrections to the
prediction history, instead of a visible 25% jump when a packet arrives.
Ownership transitions discard pending control corrections. Remote boarding,
respawns and station transitions bypass positional blending across different
coordinate spaces. Ship physics/collision authority remains with the host;
this pass does not predict the boat through shore collisions.

The snapshot frequency (10 Hz), immediate changed inputs, unchanged-input
refresh (0.5 s), room fan-out, heartbeat and discovery rates are unchanged.
The only wire addition is a timestamp in the existing compressed snapshot.
There are no added HTTP requests, telemetry uploads or database operations.
This is compatible with protocol 13; deploy all peers for consistent behavior.

Free-plan limits are account-wide, not a per-crew guarantee. Cloudflare's
Durable Objects pricing lists 5 million SQL rows read/day, 100,000 rows
written/day and 100,000 request units/day; incoming WebSocket messages use a
20:1 billing ratio. Gameplay packet forwarding does not access SQL/KV, but
admission, discovery, request gates, alarms and room lifecycle do. Fifty or
more players can still exhaust request or duration allowances over long
sessions. Check the dashboard before and after a realistic class-length test;
this change does not claim unlimited free hosting or modify the account plan.
Source: https://developers.cloudflare.com/durable-objects/platform/pricing/

Regression commands (replace `godot` with your Godot executable):

```powershell
godot --headless --path . --script res://tests/network_smoothing.gd -- --settings-test
godot --headless --path . --script res://tests/classroom_policy.gd -- --settings-test
```

The smoothing suite checks uneven arrivals at 30/60/144 FPS, stalled streams,
stale packets, teleports, reset, and immediate local helm input with gradual
correction. Real WAN/browser play remains necessary to judge perceived latency.

Validation: three local ENet peers passed 49 existing multiplayer smoke checks
(host 28, guests 13 and 8). The traffic-policy suite passed 8 checks, menu
flow passed 61, and shore-recovery and playtest-UI suites passed. These are
local/synthetic checks, not a 50-player production load or real WAN benchmark.
